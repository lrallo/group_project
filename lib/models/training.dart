
import 'package:intl/intl.dart';

class Training {
  // this class models the single heart rate data point
  final DateTime timestamp;
  final int calories; 
  final int distance;
  final int elevationGain;
  final String activityName;
  final int averageHR; 
  final int Vo2Max;
  

  Training({required this.timestamp, required this.calories, required this.distance, required this.elevationGain, required this.activityName, required this.averageHR, required this.Vo2Max});

  Training.fromJson(String date, Map<String, dynamic> json)
    : timestamp = DateFormat( 'yyyy-MM-dd HH:mm:ss', ).parse('$date ${json["time"]}'),
      calories = json["calories"],
      distance = json["distance"],
      elevationGain = json["elevationGain"],
      activityName = json["activityName"],
      averageHR = json["averageHR"],
      Vo2Max = json["Vo2Max"];

  @override
  String toString() {
    return 'Training{timestamp: $timestamp, \n calories: $calories, \n distance: $distance, \n elevationGain: $elevationGain, \n activityName: $activityName, \n averageHR: $averageHR, \n Vo2Max: $Vo2Max}';
  }
}