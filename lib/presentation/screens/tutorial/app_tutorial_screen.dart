import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/infrastructure/services/tempo_background_service.dart';
import 'package:usage_stats/usage_stats.dart';

class SlideInfo {
  final String title;
  final String caption;
  final int slideType; // 0: Bienvenida, 1: Notificaciones, 2: Estadísticas, 3: Overlay
  final String? hint; // Instrucción extra que se muestra mientras falte el permiso
  final Future<bool> Function()? checkPermission;
  final Future<void> Function()? requestPermission;

  SlideInfo({
    required this.title,
    required this.caption,
    required this.slideType,
    this.hint,
    this.checkPermission,
    this.requestPermission,
  });
}

class AppTutorialScreen extends StatefulWidget {
  static const name = 'app-tutorial-screen';
  const AppTutorialScreen({super.key});

  @override
  State<AppTutorialScreen> createState() => _AppTutorialScreenState();
}

class _AppTutorialScreenState extends State<AppTutorialScreen> with WidgetsBindingObserver {
  final PageController pageViewController = PageController();
  int currentPage = 0;

  bool notificationsGranted = false;
  bool usageGranted = false;
  bool overlayGranted = false;

  // Evita reiniciar el servicio en la primera verificación al abrir la pantalla
  bool _firstCheckDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();

    pageViewController.addListener(() {
      final page = pageViewController.page?.round() ?? 0;
      if (page != currentPage) {
        setState(() {
          currentPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pageViewController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<bool> _areNotificationsEnabled() async {
    return await Permission.notification.isGranted;
  }

  Future<void> _requestNotifications() async {
    // Si Android ya bloqueó el diálogo (rechazado varias veces), ir directo a Ajustes
    final currentStatus = await Permission.notification.status;
    if (currentStatus.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    final status = await Permission.notification.request();

    // Si tras pedirlo quedó bloqueado de forma permanente, abrir Ajustes
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _checkPermissions() async {
    final isNotifications = await _areNotificationsEnabled();
    final isUsage = await UsageStats.checkUsagePermission() ?? false;
    final isOverlay = await Permission.systemAlertWindow.isGranted;

    if (!mounted) return;

    // Las notificaciones pasaron de denegadas a concedidas: reiniciar el servicio
    // para que vuelva a publicar la notificación "Tempo Activo".
    final notificationsJustGranted =
        _firstCheckDone && !notificationsGranted && isNotifications;

    setState(() {
      notificationsGranted = isNotifications;
      usageGranted = isUsage;
      overlayGranted = isOverlay;
    });

    _firstCheckDone = true;

    if (notificationsJustGranted) {
      try {
        await restartBackgroundService();
      } catch (e) {
        debugPrint("[Tutorial] No se pudo reiniciar el servicio: $e");
      }
    }
  }

  Future<void> _onFinishTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_open', false);
    if (mounted) {
      context.go('/');
    }
  }

  /// Indica si el permiso del tipo de slide indicado ya fue concedido
  bool _isGrantedForType(int slideType) {
    switch (slideType) {
      case 1:
        return notificationsGranted;
      case 2:
        return usageGranted;
      case 3:
        return overlayGranted;
      default:
        return true;
    }
  }

  /// Evalúa si el usuario puede avanzar desde la página actual
  bool _canAdvanceCurrentPage() => _isGrantedForType(currentPage);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final slides = <SlideInfo>[
      SlideInfo(
        title: "Bienvenido a Tempo",
        caption: "Toma el control de tu tiempo digital y evita distracciones innecesarias con pausas conscientes.",
        slideType: 0,
      ),
      SlideInfo(
        title: "Notificaciones",
        caption: "Tempo funciona en segundo plano para avisarte a tiempo. Necesitamos que permitas las notificaciones para que esto funcione correctamente.",
        slideType: 1,
        hint: "Si el permiso fue rechazado antes, te llevaremos a Ajustes: activa las notificaciones de Tempo y regresa a la app.",
        checkPermission: _areNotificationsEnabled,
        requestPermission: _requestNotifications,
      ),
      SlideInfo(
        title: "Permiso de Uso",
        caption: "Necesitamos acceso a las estadísticas para medir el tiempo real que dedicas a tus aplicaciones.",
        slideType: 2,
        hint: "Si te aparece una lista de aplicaciones, busca \"Tempo\", tócala y activa el permiso. Luego regresa a la app.",
        checkPermission: () async => usageGranted,
        requestPermission: () async => UsageStats.grantUsagePermission(),
      ),
      SlideInfo(
        title: "Ventana Flotante",
        caption: "Requerimos permiso para mostrar la ventana flotante sobre tus apps e invitarte a hacer pausas.",
        slideType: 3,
        hint: "Si te aparece una lista de aplicaciones, busca \"Tempo\", tócala y activa \"Permitir mostrar sobre otras apps\". Luego regresa a la app.",
        checkPermission: () async => overlayGranted,
        requestPermission: () async {
          await Permission.systemAlertWindow.request();
        },
      ),
    ];

    final isLastPage = currentPage == slides.length - 1;
    final canAdvance = _canAdvanceCurrentPage();
    final allPermissionsGranted = notificationsGranted && usageGranted && overlayGranted;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: pageViewController,
              // Deshabilita el deslizamiento táctil si no ha concedido el permiso del paso actual
              physics: canAdvance
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: slides.length,
              itemBuilder: (context, index) {
                final slide = slides[index];
                final isPermissionSlide = slide.requestPermission != null;
                final bool isGranted = _isGrantedForType(slide.slideType);
                final Color buttonFg = isGranted ? Colors.white : cs.onPrimary;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SlideIllustration(slideType: slide.slideType),

                      const SizedBox(height: 40),
                      Text(
                        slide.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        slide.caption,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),

                      if (isPermissionSlide) ...[
                        const SizedBox(height: 25),

                        // Instrucción de qué hacer en la lista / ajustes
                        if (!isGranted && slide.hint != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    slide.hint!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: cs.onSurface,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await slide.requestPermission!();
                            await _checkPermissions();
                          },
                          icon: Icon(
                            isGranted ? Icons.check_circle_rounded : Icons.security_rounded,
                            color: buttonFg,
                          ),
                          label: Text(
                            isGranted ? "Permiso Concedido" : "Conceder Permiso Requerido",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: buttonFg,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isGranted ? Colors.green : cs.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        if (!isGranted) ...[
                          const SizedBox(height: 12),
                          Text(
                            "Debes otorgar este permiso para continuar",
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ]
                      ]
                    ],
                  ),
                );
              },
            ),

            // Puntos de paginación (Dots)
            Positioned(
              left: 30,
              bottom: 30,
              child: Row(
                children: List.generate(
                  slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 8),
                    height: 8,
                    width: currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: currentPage == index ? cs.primary : cs.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Botón de navegación (Siguiente / Comenzar)
            Positioned(
              right: 20,
              bottom: 20,
              child: ElevatedButton(
                onPressed: isLastPage
                    ? (allPermissionsGranted ? _onFinishTutorial : null)
                    : (canAdvance
                        ? () {
                            pageViewController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isLastPage ? "Comenzar" : "Siguiente",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SlideIllustration extends StatelessWidget {
  final int slideType;

  const _SlideIllustration({required this.slideType});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primaryColor = cs.primary;

    IconData icon;
    List<Color> gradientColors;

    switch (slideType) {
      case 0:
        icon = Icons.hourglass_bottom_rounded;
        gradientColors = [primaryColor.withValues(alpha: 0.25), primaryColor.withValues(alpha: 0.05)];
        break;
      case 1:
        icon = Icons.notifications_active_rounded;
        gradientColors = [Colors.orange.withValues(alpha: 0.25), Colors.orange.withValues(alpha: 0.05)];
        break;
      case 2:
        icon = Icons.bar_chart_rounded;
        gradientColors = [Colors.blue.withValues(alpha: 0.25), Colors.blue.withValues(alpha: 0.05)];
        break;
      case 3:
        icon = Icons.layers_rounded;
        gradientColors = [Colors.purple.withValues(alpha: 0.25), Colors.purple.withValues(alpha: 0.05)];
        break;
      default:
        icon = Icons.timer;
        gradientColors = [cs.surfaceContainerHighest, cs.surface];
    }

    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: cs.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 60,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}