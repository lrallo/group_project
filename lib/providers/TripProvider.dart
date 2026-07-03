// file: lib/providers/TripProvider.dart
import 'package:flutter/material.dart';
import 'package:project_app/algorithms/trip_splitter.dart';
import 'package:project_app/models/trip.dart';
import 'package:project_app/services/gpx_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripProvider extends ChangeNotifier { 
  List<Trip> tripList = [];  // DB dei viaggi caricati 
  int? selectedStageIndex; // Indice della tappa selezionata nella schermata delle tappe

  Future<bool> addTrip(String selectedActivity) async {
    print('Inizio utilizzo di File Picker (gpx_services) ...');
    Trip? toAdd = await GpxService.pickGpx(selectedActivity); // Chiede all'utente di selezionare un file GPX e crea un oggetto Trip, oppure ritorna null se l'utente annulla

    if (toAdd != null) {
      print("Oggetto Trip creato, recupero prestazioni utente...");
      
      // 1. Recupero la performance calcolata in precedenza (anche Offline)
      final sp = await SharedPreferences.getInstance();
      double? maxEffort ; // variabile che non può essere null, l'utente è obbligato a dare l'accesos a IMPACT o scrivere manualmente il maxEffort
      
      if (selectedActivity.toLowerCase() == 'walk') {
        maxEffort = sp.getDouble('maxWalk') ?? 15.0; // se non c'è il valore salvato, uso un default di 15 km
      } else if (selectedActivity.toLowerCase() == 'bike') {
        maxEffort = sp.getDouble('maxBike') ?? 40.0; // se non c'è il valore salvato, uso un default di 40 km
      }

      print("Limite calcolato per $selectedActivity: $maxEffort km di sforzo");

      // 2. Calcola le tappe tagliando il file GPX
      await calculateAndCut(toAdd, maxEffort!); 

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

  // Metodo per AGGIORNARE IL TITOLO di un viaggio 
  void updateTripTitle(int index, String newTitle) {
    if (index >= 0 && index < tripList.length) { // controllo che l'indice sia valido
      tripList[index].title = newTitle; // aggiorno il titolo del viaggio
      notifyListeners(); 
    }
  }


  // Metodo per SELEZIONARE/deselezionare una tappa
  void selectStage(int? index) {
    selectedStageIndex = index;
    notifyListeners(); // Aggiorna la UI ovunque venga letto questo valore
  }

  
  @override
  String toString() {
    return ' ${tripList.map((trip) => trip.toString()).join('\n')}';
  }

  // metodo per eliminare tutti i dati, se l'utente fa il logout
  void clearData() {
    tripList.clear(); // Svuota tutta la lista dei viaggi
    notifyListeners();
  }

  // Metodo per rimuovere un viaggio dalla lista
  void removeTrip(Trip tripToRemove) {
    tripList.remove(tripToRemove);
    notifyListeners(); // Aggiorna la UI rimuovendo la card
  }
}