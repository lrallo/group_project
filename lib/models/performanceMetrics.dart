// file: lib/models/performanceMetrics.dart

class PerformanceMetrics {
  // Metriche per l'algoritmo di split (Quanti km/giorno sopporta l'utente)
  final double maxWalkEffortKm; 
  final double maxBikeEffortKm;
  
  // Metriche di Costanza e Analisi
  final int? analysisWindowDays; // Finestra temporale dinamica calcolata
  final int? activeDays; // In quanti di questi giorni si è allenato?
  
  // Metriche di Sforzo
  final double? totalWalkEffort;
  final double? totalBikeEffort;
  
  // Dati grezzi per futuri grafici (es. fl_chart)
  final Map<String, double>? dailyWalkEffort;
  final Map<String, double>? dailyBikeEffort;

  PerformanceMetrics({
    required this.maxWalkEffortKm, // required significa che il costruttore deve ricevere un valore per questo parametro
    required this.maxBikeEffortKm,
    this.analysisWindowDays, //il costruttore non deve per forza ricevere un valore per questi parametri, perché possono essere nulli se i dati sono manuali
    this.activeDays,
    this.totalWalkEffort,
    this.totalBikeEffort,
    this.dailyWalkEffort,
    this.dailyBikeEffort,
  });
}