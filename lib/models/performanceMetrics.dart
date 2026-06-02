// file: lib/models/performanceMetrics.dart

class PerformanceMetrics {
  // Metriche per l'algoritmo di split (Quanti km/giorno sopporta l'utente)
  final double maxWalkEffortKm; 
  final double maxBikeEffortKm;
  
  // Metriche di Costanza e Analisi
  final int analysisWindowDays; // Finestra temporale dinamica calcolata
  final int activeDays; // In quanti di questi giorni si è allenato?
  final String fitnessLevel; // Es: "Sedentario", "Attivo", "Atleta"
  
  // Metriche di Sforzo
  final double totalWalkEffort;
  final double totalBikeEffort;
  
  // Dati grezzi per futuri grafici (es. fl_chart)
  final Map<String, double> dailyWalkEffort;
  final Map<String, double> dailyBikeEffort;

  PerformanceMetrics({
    required this.maxWalkEffortKm,
    required this.maxBikeEffortKm,
    required this.analysisWindowDays,
    required this.activeDays,
    required this.fitnessLevel,
    required this.totalWalkEffort,
    required this.totalBikeEffort,
    required this.dailyWalkEffort,
    required this.dailyBikeEffort,
  });
}