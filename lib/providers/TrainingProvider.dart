// file: lib/providers/TrainingProvider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:project_app/algorithms/performance_analyzer.dart';
import 'package:project_app/services/impact_service.dart';
import 'package:project_app/models/training.dart';  
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/models/performanceMetrics.dart';

class TrainingProvider extends ChangeNotifier { 
  PerformanceMetrics? userMetrics;// metriche utente
  bool isLoading = false;        // variabile che indica se il provider sta caricando i dati da IMPACT
  bool impactPermission = false; // variabile che indica se l'utente ha dato il permesso di accedere ai dati di IMPACT
  


  // funzione che AGGIORNA la variabile sia nel provider che nella sp
  Future<void> changePermission(bool value) async {
  impactPermission = value;
  final sp = await SharedPreferences.getInstance();
  await sp.setBool('impact_permission', value);
  notifyListeners();
}




  // Funzione per DATI DA IMPACT
  Future<int> getTrainingData() async {
    isLoading = true;
    notifyListeners(); //avviso che lo stato di caricamento è cambiato, così la UI può aggiornarsi

    try {
      // 1. Seleziono le date per l'analisi: ultimi 30 giorni
      DateTime endDate = DateTime.now().subtract(const Duration(days: 1)); 
      DateTime startDate = endDate.subtract(const Duration(days: 29)); // 30 giorni totali, incluso il giorno di fine (endDate)
      // 2. Recupero i dati facendo una richiesta al Server Impact, restituisce una lista di oggetti Training 
      List<Training>? rawData = await ImpactService.getHistoricalExerciseData(startDate, endDate);
      
      if (rawData == null) return 401; // se non c'è l'acces token salvato o il refresh è scaduto, bisogna reindirizzare l'utente al login

      // 3. analizzo i dati per calcolare le metriche di performance dell'utente
      userMetrics = PerformanceAnalyzer.analyze(rawData);

      // 4. salvo le metriche nella memoria locale per poterla usare in seguito, anche in offline e senza dover rifare la richiesta al server
      final sp = await SharedPreferences.getInstance();
      await sp.setDouble('maxWalk', userMetrics!.maxWalkEffortKm); //km di camminata sostenibile in un giorno di viaggio a tappe
      await sp.setDouble('maxBike', userMetrics!.maxBikeEffortKm);
      await sp.setInt('analysisWindow', userMetrics!.analysisWindowDays ?? 0);
      await sp.setInt('activeDays', userMetrics!.activeDays ?? 0);
      await sp.setString('dailyWalkMap', jsonEncode(userMetrics!.dailyWalkEffort));//salvo la mappa giorno->km di camminata per mostrare i dettagli all'utente, e per eventuali calcoli futuri
      await sp.setString('dailyBikeMap', jsonEncode(userMetrics!.dailyBikeEffort));
      print('\n---- Metriche salvate nella memoria locale (SharedPreferences) ----');
      return 200; 
      
    } catch (e) {
      print('Errore critico in getTrainingData: $e');
      return 500;
    } finally {
      isLoading = false;
      notifyListeners();
    } 
  } 


// ------ FUNZIONI PER GESTIRE I DATI MANUALI E IMPACT ------


// metodo che CARICA LE VECCHIE METRICHE dalla memoria locale (usata se l'utente ha fatto il LOGIN MENO DI 24h FA, hp che non siano cambiate molto)
Future<void> loadLocalMetrics() async {
  // 1. accedo alla sp
  final sp = await SharedPreferences.getInstance();
  impactPermission = sp.getBool('impact_permission') ?? false; // assegno alla variabile del provider il valore salvato nella sp, se non c'è lo imposto a false
  
  double? walk = sp.getDouble('maxWalk');
  double? bike = sp.getDouble('maxBike');
  
  if (walk != null && bike != null) {
    if (impactPermission == true) { 
      // --- CASO UTENTE IMPACT: Carichiamo anche le altre metriche ---
      int? window = sp.getInt('analysisWindow');
      int? active = sp.getInt('activeDays');
      
      Map<String, double>? dailyWalk;
      Map<String, double>? dailyBike;

      // Leggiamo le stringhe JSON salvate
      String? walkMapStr = sp.getString('dailyWalkMap');
      String? bikeMapStr = sp.getString('dailyBikeMap');

      // Se esistono, le decodifichiamo da String a Map<String, double>
      if (walkMapStr != null) {
        Map<String, dynamic> decoded = jsonDecode(walkMapStr);
        dailyWalk = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
      if (bikeMapStr != null) {
        Map<String, dynamic> decoded = jsonDecode(bikeMapStr);
        dailyBike = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }

      // Popoliamo il PerformanceMetrics completo
      userMetrics = PerformanceMetrics(
        maxWalkEffortKm: walk,
        maxBikeEffortKm: bike,
        analysisWindowDays: window,
        activeDays: active,
        dailyWalkEffort: dailyWalk,
        dailyBikeEffort: dailyBike,
      );
    } else {
      // --- CASO UTENTE MANUALE: Carichiamo solo i km base ---
      userMetrics = PerformanceMetrics(
        maxWalkEffortKm: walk,
        maxBikeEffortKm: bike,
      );
    }
  }
  notifyListeners();
}


  // metodo che aggiorna le metriche dell'utente (sia manuali che IMPACT)
  // usata in settings_screen e manual_effort_screen o se l'utente riaccede col permesso ma offline
  Future<int> updateMetrics() async {
    final sp = await SharedPreferences.getInstance();
    bool? permission = sp.getBool('impact_permission'); // carico il permesso che era stato salvato

    if (permission == true){ // UTENTE AVEVA DATO IL PERMESSO A IMPACT
      // 1. aggiorno anche la variabile del provider
      impactPermission = true; // aggiorno la variabile del provider

      // 2. recupero i dati e sovrascrivo la SP
      int status = await getTrainingData();

      notifyListeners();
      return status;

    } else if (permission==false){ // UTENTE NON AVEVA DATO IL PERMESSO, mantengo i dati che ci sono e gli carico nel provider
      // carico i dati dalla sp al provider
      await loadLocalMetrics(); // carico i dati dalla sp al provider
      notifyListeners();
      return 200; 
    }else{
      print('errore critico in updateImpactMetrics');
      return 500;
    }
  }

  

  // ---- FUNZIONI PER GESTIRE IL PASSAGGIO DA IMPACT A MANUALE --
  Future<void> switchToManual() async {

  // 1. Aggiorno la variabile del provider e della sp
  await changePermission(false); // Aggiorno la variabile del provider e della sp

  // 2. Recuperiamo i vecchi dati manuali salvati (o usiamo un default di sicurezza)
  final sp = await SharedPreferences.getInstance();
  double rawWalk = sp.getDouble('maxWalk') ?? 15.0;
  double rawBike = sp.getDouble('maxBike') ?? 50.0;
  // teniamo solo 2 cifre dopo la virgola
  double walk = double.parse(rawWalk.toStringAsFixed(1));
  double bike = double.parse(rawBike.toStringAsFixed(1));

  // 3. Puliamo solo i dati specifici di IMPACT per non salvare dati in piu
  await sp.remove('analysisWindow');
  await sp.remove('activeDays');
  await sp.remove('dailyWalkMap');
  await sp.remove('dailyBikeMap');

  // 4. Ricreo l'oggetto metrics con i soli dati manuali
  userMetrics = PerformanceMetrics(
    maxWalkEffortKm: walk,
    maxBikeEffortKm: bike,
  );
  notifyListeners(); // La UI passerà istantaneamente ai box manuali compilati!
}


// Funzione per DATI MANUALI  (usata in settings_screen e manual_effort_screen)
Future<void> setManualMetrics(double walkLimit, double bikeLimit) async {
    final sp = await SharedPreferences.getInstance();
    // n.b. non serve cancellare le chiavi sulla sp, perchè vengono cancellate quando l'utente schiaccia il pulsante "switch ""
    
    // 1. Sovrascrivo i nuovi dati 
    await sp.setDouble('maxWalk', walkLimit); 
    await sp.setDouble('maxBike', bikeLimit);

    // 2. sovrascrivo i dati nel provider
    userMetrics = PerformanceMetrics(
      maxWalkEffortKm: walkLimit,
      maxBikeEffortKm: bikeLimit,
      analysisWindowDays: null,
      activeDays: null,   
      totalWalkEffort: null,
      totalBikeEffort: null,
      dailyWalkEffort: null,  
      dailyBikeEffort: null,
    );
    notifyListeners(); // La UI (TrainingBody) cambierà istantaneamente!
  }


  // PULIZIA DEI DATI DEL PROVIDER 
    Future<void> clearTrainingProvider() async {
    userMetrics = null;
    isLoading = false;
    impactPermission = false;
    notifyListeners();//avviso che lo stato di caricamento è cambiato, così la UI può aggiornarsi
  }
}