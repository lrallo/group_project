// file: lib/providers/TrainingProvider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:project_app/algorithms/performance_analyzer.dart';
import 'package:project_app/services/impact_service.dart';
import 'package:project_app/models/training.dart';  
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/models/performanceMetrics.dart';

class TrainingProvider extends ChangeNotifier { 
  PerformanceMetrics? userMetrics; 
  bool _isLoading = false;
  bool get isLoading => _isLoading; // variabile che permette di avvisare la UI quando sono in fase di caricamento, in modo da mostrare la rotellina
  
  bool impactPermission = false; // variabile che indica se l'utente ha dato il permesso di accedere ai dati di IMPACT
  


  // funzione che AGGIORNA la variabile del provider e della sp
  Future<void> changePermission(bool value) async {
  impactPermission = value;
  final sp = await SharedPreferences.getInstance();
  await sp.setBool('impact_permission', value);
  notifyListeners();
}


// metodo che CARICA LE VECCHIE METRICHE se l'utente ha fatto il login meno di 24h fa (da usare in splash)
Future<void> loadLocalMetrics() async {
  // 1. accedo alla sp
  final sp = await SharedPreferences.getInstance();
  impactPermission = sp.getBool('impact_permission') ?? false; 
  
  double? walk = sp.getDouble('maxWalk');
  double? bike = sp.getDouble('maxBike');
  
  if (walk != null && bike != null) {
    if (impactPermission == true) { // se l'utente aveva dato il permesso a IMPACT, carico anche le altre metriche nella sp
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




  // Funzione per DATI DA IMPACT
  Future<int> getTrainingData() async {
    _isLoading = true;
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
      _isLoading = false;
      notifyListeners();
    } 
  } 

  

  // funzione che SE l'utente aveva dato il consenso a IMPACT, elimina le vecchie metriche dalla sp e richiama getTrainingData 
  Future<int> updateImpactMetrics() async {
    final sp = await SharedPreferences.getInstance();
    bool? permission = sp.getBool('impact_permission'); // carico il permesso che era stato salvato

    if (permission == true){ // UTENTE AVEVA DATO IL PERMESSO A IMPACT
      changePermission(true); //aggiorno la variabile del provider

      // 1. Pulisco le chiavi relative a IMPACT in modo che non creino conflitti
      await sp.remove('maxWalk');
      await sp.remove('maxBike');
      await sp.remove('analysisWindow');
      await sp.remove('activeDays');
      await sp.remove('dailyWalkMap');
      await sp.remove('dailyBikeMap');

      // 2. recupero i dati e riaggiorno la SP
      int status = await getTrainingData();
      notifyListeners();
      return status;

    } else if (permission==false){ // UTENTE NON AVEVA DATO IL PERMESSO, mantengo i dati che ci sono e gli carico nel provider
      // carico i dati dalla sp al provider
      changePermission(false); // aggiorno la variabile del provider
      double? walk = sp.getDouble('maxWalk');
      double? bike = sp.getDouble('maxBike');
      if (walk != null && bike != null) {
        userMetrics = PerformanceMetrics(
          maxWalkEffortKm: walk,
          maxBikeEffortKm: bike,
          // gli altri campi saranno null
        );
        notifyListeners();
      }
      return 200; 
    }else{
      print('errore critico in updateImpactMetrics');
      return 500;
    }
  }



  // metodo per quando l'utente toglie il permesso a IMPACT
  Future<void> switchToManual() async {
  final sp = await SharedPreferences.getInstance();
  
  impactPermission = false;// Impostiamo il permesso a false
  await sp.setBool('impact_permission', false);

  // Recuperiamo i vecchi dati manuali salvati (o usiamo un default di sicurezza)
  double walk = sp.getDouble('maxWalk') ?? 15.0;
  double bike = sp.getDouble('maxBike') ?? 50.0;

  // Puliamo solo i dati specifici di IMPACT per non salvare dati in piu
  await sp.remove('analysisWindow');
  await sp.remove('activeDays');
  await sp.remove('dailyWalkMap');
  await sp.remove('dailyBikeMap');

  // Ricreiamo l'oggetto metrics con i soli dati manuali
  userMetrics = PerformanceMetrics(
    maxWalkEffortKm: walk,
    maxBikeEffortKm: bike,
  );

  notifyListeners(); // La UI passerà istantaneamente ai box manuali compilati!
}

  // Funzione per DATI MANUALI  
Future<void> setManualMetrics(double walkLimit, double bikeLimit) async {
    final sp = await SharedPreferences.getInstance();
    
    // 1. Pulisco i dati precedenti
    // (n.b. se la chiave non esiste, non da errore, semplicemente non fa nulla)
    await sp.remove('analysisWindow');
    await sp.remove('activeDays');
    await sp.remove('dailyWalkMap');
    await sp.remove('dailyBikeMap');
    
    // 2. Salvo i nuovi dati 
    await sp.setDouble('maxWalk', walkLimit); 
    await sp.setDouble('maxBike', bikeLimit);

    // 3. aggiorno la variabile del permesso
    await sp.setBool('impact_permission', false);

    // 3. Aggiorno lo stato del Provider
    impactPermission = false;
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

  // PULIZIA DEI DATI DEL PROVIDER (es. quando l'utente fa logout)
  // n.b. la usiamo mai questa funzione ??
    void clearData() {
    userMetrics = null;
    _isLoading = false;
    impactPermission = false;
   
    notifyListeners();//avviso che lo stato di caricamento è cambiato, così la UI può aggiornarsi
  }
}