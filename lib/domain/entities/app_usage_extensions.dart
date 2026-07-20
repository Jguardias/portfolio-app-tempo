import 'package:tempo/domain/entities/app_usage.dart';

extension AppUsageDisplay on AppUsage {

  String get avgLabel => isCompulsive ? "Ritmo inquieto" : "Sesión promedio"; 
  
  bool get isCompulsive {
    final avgSeconds = totalTimeInForeground.inSeconds / (launchCount > 0 ? launchCount : 1);
    return avgSeconds < 45 && launchCount > 15;
  }

  String get avgText {
    final avgSeconds = totalTimeInForeground.inSeconds / (launchCount > 0 ? launchCount : 1);
    if (isCompulsive) return "${avgSeconds.round()} seg/sesión";
    if (totalTimeInForeground.inSeconds < 60) return "Uso ligero";
    return "${(avgSeconds / 60).toStringAsFixed(1)} min/sesión";
  }

  String get formattedDuration {
    final seconds = totalTimeInForeground.inSeconds;
    return seconds < 60 ? "$seconds seg" : "${totalTimeInForeground.inMinutes} min";
  }
}