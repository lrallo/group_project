
// file: lib/algorithms/performance_analyzer.dart
import 'package:project_app/models/training.dart';
import 'package:project_app/models/performanceMetrics.dart';

class PerformanceAnalyzer {
  static PerformanceMetrics analyze(List<Training> trainings) {
    print(' \n---- Inizio analisi prestazioni su ${trainings.length} allenamenti...  ----');
    
    if (trainings.isEmpty) {
      return PerformanceMetrics(
        maxWalkEffortKm: 15.0, // Endurance base di sicurezza
        maxBikeEffortKm: 40.0,
        analysisWindowDays: 1,
        activeDays: 0,
        fitnessLevel: "Sedentario",
        totalWalkEffort: 0.0,
        totalBikeEffort: 0.0,
        dailyWalkEffort: {},
        dailyBikeEffort: {},
      );
    }

    Map<String, double> dailyWalkMap = {};
    Map<String, double> dailyBikeMap = {};
    double totalWalk = 0.0;
    double totalBike = 0.0;

    // 1. Calcolo dinamico della finestra di analisi
    DateTime minDate = trainings.first.timestamp;
    DateTime maxDate = trainings.first.timestamp;

    for (var t in trainings) {
      print('\nAnalizzando allenamento: ${t.activityName} del ${t.timestamp} - Distanza: ${t.distance} km, Elevazione: ${t.elevationGain} m');
      if (t.timestamp.isBefore(minDate)) minDate = t.timestamp;
      if (t.timestamp.isAfter(maxDate)) maxDate = t.timestamp;

      double sessionEffort = t.distance + (t.elevationGain / 100.0);
      String dateKey = t.dateString;
      String act = t.activityName.toLowerCase();
      print('Session Effort calcolato: $sessionEffort ');

      if (act.contains('bici') || act.contains('bike')) {
        totalBike += sessionEffort;
        dailyBikeMap[dateKey] = (dailyBikeMap[dateKey] ?? 0.0) + sessionEffort;
      } else {
        totalWalk += sessionEffort;
        dailyWalkMap[dateKey] = (dailyWalkMap[dateKey] ?? 0.0) + sessionEffort;
      }
      print('Totale Walk Effort finora: $totalWalk km, Totale Bike Effort finora: $totalBike km');
    }
    

    // Giorni totali trascorsi tra il primo e l'ultimo allenamento (+1 per includere gli estremi)
    int analysisWindow = maxDate.difference(minDate).inDays + 1;
    // Quanti giorni unici hanno almeno un allenamento?
    int activeDays = {...dailyWalkMap.keys, ...dailyBikeMap.keys}.length;

    // 2. Calcolo Medie
    double avgDailyWalk = totalWalk / analysisWindow;
    double avgDailyBike = totalBike / analysisWindow;
    double overallDailyEffort = avgDailyWalk + (avgDailyBike * 0.4); // La bici pesa un po' meno per definire il "livello"

    // 3. Assegnazione di un Livello descrittivo per l'UI
    String fitnessProfile = "Sedentario";
    if (overallDailyEffort > 12) fitnessProfile = "Atleta Elite";
    else if (overallDailyEffort > 8) fitnessProfile = "Atleta";
    else if (overallDailyEffort > 4) fitnessProfile = "Molto Attivo";
    else if (overallDailyEffort > 1.5) fitnessProfile = "Attivo";

    // 4. Stima della "Sopportazione" (Endurance) in un viaggio a tappe
    // Formula evidence-based: Baseline minima + (carico cronico medio * fattore di spinta 2.5)
    double maxWalkEndurance = 10.0 + (avgDailyWalk * 2.5);
    double maxBikeEndurance = 30.0 + (avgDailyBike * 2.5);

    print('\n---- Analisi completata ----');
    print('Finestra di analisi: $analysisWindow giorni, Giorni attivi: $activeDays');
    print('Sforzo medio giornaliero: Walk ${avgDailyWalk.toStringAsFixed(2)} km, Bike ${avgDailyBike.toStringAsFixed(2)} km');
    print('Livello di fitness stimato: $fitnessProfile');  
    print('Endurance stimata: Walk ${maxWalkEndurance.toStringAsFixed(2)} km, Bike ${maxBikeEndurance.toStringAsFixed(2)} km');
    print('mappa sforzo giornaliero (Walk): $dailyWalkMap');
    print('mappa sforzo giornaliero (Bike): $dailyBikeMap');
    return PerformanceMetrics(
      maxWalkEffortKm: maxWalkEndurance, // km di camminata sostenibile in un giorno di viaggio a tappe
      maxBikeEffortKm: maxBikeEndurance,
      analysisWindowDays: analysisWindow,
      activeDays: activeDays, // giorni con almeno un allenamento
      fitnessLevel: fitnessProfile, 
      totalWalkEffort: totalWalk,// km totali di camminata nella window
      totalBikeEffort: totalBike,
      dailyWalkEffort: dailyWalkMap, // mappa giorno -> km di camminata
      dailyBikeEffort: dailyBikeMap, // mappa giorno -> km di bici
    );
    
  }// analyze
}