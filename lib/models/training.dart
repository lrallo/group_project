
// file: lib/models/training.dart
import 'package:intl/intl.dart';

class Training {
  final DateTime timestamp;
  final String activityName;
  final double calories;
  final double distance; 
  final int steps;
  final double elevationGain;
  final int averageHR;
  final double activeDuration; // <-- AGGIUNTO per stimare la distanza in bici

  // Getter comodo per raggruppare i dati nell'algoritmo (es. "2026-05-22")
  String get dateString => DateFormat('yyyy-MM-dd').format(timestamp);

  Training({
    required this.timestamp,
    required this.activityName,
    required this.calories,
    required this.distance,
    required this.steps,
    required this.elevationGain,
    required this.averageHR,
    required this.activeDuration,
  });

  factory Training.fromJson(String date, Map<String, dynamic> json) {
    double parsedDistance = (json['distance'] as num?)?.toDouble() ?? 0.0;
    int parsedSteps = json['steps'] as int? ?? 0;
    double parsedActiveDuration = (json['activeDuration'] as num?)?.toDouble() ?? 0.0;

    String actName = (json['activityName'] as String?)?.toLowerCase() ?? '';

    // 1. Pulizia Corsa/Camminata: calcoliamo dai passi se la distanza è mancante
    if (parsedDistance == 0.0 && parsedSteps > 0) {
      parsedDistance = (parsedSteps * 0.762) / 1000.0; 
    }

    // 2. Pulizia Bici (auto_detected): calcoliamo dal tempo stimando 20 km/h di media
    if (parsedDistance == 0.0 && (actName.contains('bici') || actName.contains('bike')) && parsedActiveDuration > 0) {
       // activeDuration è in millisecondi. In ore: ms / 3600000
       parsedDistance = (parsedActiveDuration / 3600000.0) * 20.0;
    }

    return Training(
      timestamp: DateFormat('yyyy-MM-dd HH:mm:ss').parse('$date ${json["time"]}'),
      activityName: json['activityName'] ?? 'Sconosciuta',
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      distance: parsedDistance,
      steps: parsedSteps,
      elevationGain: (json['elevationGain'] as num?)?.toDouble() ?? 0.0,
      averageHR: json['averageHeartRate'] as int? ?? 0,
      activeDuration: parsedActiveDuration,
    );
  }
}