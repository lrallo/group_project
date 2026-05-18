import 'package:flutter/material.dart';
import 'package:project_app/algorithms/trip_splitter.dart';
import 'package:project_app/models/trip.dart';
import 'package:project_app/services/gpx_services.dart';


// --- CHANGE NOTIFIER  --- 
class TripProvider extends ChangeNotifier { 
  List<Trip> TripList = [];  // DB dei viaggi caricati 

  Future<bool> addTrip(String selectedActivity) async {

    // 1. prendi il viaggio da aggiungere e calcola le tappe
    print('Inizio utilizzo di File Picker (gpx_services) ...');
    Trip? toAdd = await GpxService.pickGpx(selectedActivity);

    if (toAdd !=null) {
      print("Oggetto Trip creato, inizio calcolo tappe...");
      // 2. calcola le tappe e aggiungi le tappe alla lista del viaggio dayTripsList
      await calculateAndCut(toAdd, 5); // 5 verrà sostituito con l'effettiva performance dell'utente
      // 3. aggiungi il viaggio alla lista  dei viaggi del provider
      print('calcolo tappe completato, aggiungo il viaggio alla lista dei viaggi');
      TripList.add(toAdd); 
      // 4. notifica i listener, in modo che le schermate (Consumer) che stanno ascoltando vengano rebuildate
      notifyListeners();
      return true; // ritorna true se il viaggio è stato aggiunto correttamente 

    } else {
      print("Errore: Viaggio non caricato correttamente.");
      return false; // Esce dalla funzione se il viaggio non è stato caricato
    }
  }
  
  @override
  String toString() {
    return ' ${TripList.map((trip) => trip.toString()).join('\n')}';
  }
}


