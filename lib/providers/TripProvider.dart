// file: lib/providers/TripProvider.dart
import 'package:flutter/material.dart';
import 'package:project_app/algorithms/trip_splitter.dart';
import 'package:project_app/models/trip.dart';
import 'package:project_app/services/gpx_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripProvider extends ChangeNotifier { 
  List<Trip> tripList = [];  // DB dei viaggi caricati (meglio camelCase per le variabili)

  // Nota: ho tolto userMaxEffort dai parametri, perché ce lo andiamo a pescare da soli dalla memoria locale!
  Future<bool> addTrip(String selectedActivity) async {
    print('Inizio utilizzo di File Picker (gpx_services) ...');
    Trip? toAdd = await GpxService.pickGpx(selectedActivity);

    if (toAdd != null) {
      print("Oggetto Trip creato, recupero prestazioni utente...");
      
      // 1. Recupero la performance calcolata in precedenza (Offline)
      final sp = await SharedPreferences.getInstance();
      double maxEffort = 20.0; // Valore di default di sicurezza (es. utente sedentario)
      
      if (selectedActivity.toLowerCase() == 'walk') {
        maxEffort = sp.getDouble('maxWalk') ?? 15.0; // maxWalk è la chiave salvata nel TrainingProvider
      } else if (selectedActivity.toLowerCase() == 'bike') {
        maxEffort = sp.getDouble('maxBike') ?? 40.0; // maxBike è la chiave salvata nel TrainingProvider
      }

      print("Limite calcolato per $selectedActivity: $maxEffort km di sforzo");

      // 2. Calcola le tappe tagliando il file GPX
      await calculateAndCut(toAdd, maxEffort); 

      // 3. Aggiungi il viaggio alla lista
      tripList.add(toAdd); 
      
      // 4. Notifica la UI
      notifyListeners();
      return true; 
    } else {
      print("Errore o annullamento: Viaggio non caricato.");
      return false; 
    }
  }
  
  @override
  String toString() {
    return ' ${tripList.map((trip) => trip.toString()).join('\n')}';
  }

  // metodo per eliminare tutti i dati, se l'utente fa il logout
  void clearData() {
    tripList.clear(); // Svuota la lista dei viaggi
    notifyListeners();
  }
}