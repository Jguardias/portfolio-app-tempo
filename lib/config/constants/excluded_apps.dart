/// Apps que Tempo nunca debe monitorear ni mostrar para configurar:
/// launchers, teclados, Ajustes, teléfono y la propia Tempo.
class ExcludedApps {
  /// Debe ser IGUAL al applicationId de android/app/build.gradle.kts.
  static const String ownPackage = 'com.tempoapp.bienestar';

  static const Set<String> _packages = {
    ownPackage,
    'com.android.settings',
    'com.android.systemui',
    'com.android.phone',
    'com.android.server.telecom',
    'com.android.dialer',
    'com.google.android.dialer',
    'com.samsung.android.dialer',
    'com.android.emergency',
    'com.android.packageinstaller',
    'com.google.android.packageinstaller',
    'com.android.permissioncontroller',
    'com.google.android.permissioncontroller',
    'com.miui.home',
    'com.samsung.android.honeyboard',
    'com.touchtype.swiftkey',
  };

  static bool isExcluded(String packageName) {
    if (_packages.contains(packageName)) return true;
    return packageName.contains('launcher') ||
        packageName.contains('inputmethod') ||
        packageName.contains('systemui');
  }
}