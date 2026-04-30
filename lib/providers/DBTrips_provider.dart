import 'package:flutter/material.dart';
import 'package:gpx/gpx.dart';
import 'package:project_app/services/trip_splitter.dart';


// --- CHANGE NOTIFIER  --- contiene la lista dei viaggi
class DBtrips extends ChangeNotifier { 
  List<Trip> TripList = []; 
 

  // N.B. QUESTA DEVE SEMPLICEMENTE SOVRASCRIVERE .add  (sempre col future!!) della lista, perché è la funzione che viene chiamata quando l'utente carica un nuovo viaggio, e in quel momento vogliamo che venga calcolato il dayTrip di quel viaggio e salvato nella variabile dayTrips del viaggio stesso (vedere trip_splitter.dart)
  @ override
  Future<void> add(Trip toAdd) async {
    // calcolo i dayTrip del viaggio (vedere trip_splitter.dart) e li salvo nella variabile dayTrips del viaggio:
    await calculateAndCut(toAdd, 1); // 5 verrà sostituito con la performance dell'utente
    TripList.add(toAdd); // aggiungo il viaggio alla lista dei viaggi
    notifyListeners();  // Notifica i listener che la lista è stata aggiornata
  }
  
  

  @override
  String toString() {
    return ' ${TripList.map((trip) => trip.toString()).join('\n')}';
  }
}

// --- TRIP  --- rappresenta un viaggio complessivo, che contiene una lista di dayTrip (tappe)
class Trip {
  String title;    // Titolo del viaggio
  Gpx gpxData;    // Dati GPX del viaggio, inizializzato come null o con un costruttore vuoto
  String activity; // Salverà 'walk' o 'bike'
  double distance = 0.0; 
  double elevationPos = 0.0; 
  double elevationNeg = 0.0;
  List<dayTrip>? dayTripsList; // Lista dei dayTrip associati a questo viaggio, inizializzata come vuota
  // Costruttore (obbligatori title, activity e gpxData)
  late DateTime importDate;

  Trip( this.title, this.activity, this.gpxData){
    importDate = DateTime.now(); //registra la data e l'ora esatta in cui l'oggetto viene creato
  }

  @override  //metodo che ci serve solo per il debug, per stampare in modo leggibile le informazioni di un viaggio quando facciamo print(trip)
  String toString() {
    return 'Trip title: $title, activity: $activity, distance: ${distance.toStringAsFixed(2)} km, | +: ${elevationPos.toStringAsFixed(0)} m, | -: ${elevationNeg.toStringAsFixed(0)} m,  Stages: ${dayTripsList!.length}';
  }
}


// --- dayTrip  --- rappresenta una tappa di un viaggio, ovvero un giorno del viaggio complessivo, con distanza e dislivello di quel giorno. Contiene anche tutte le informazioni del viaggio complessivo (title, activity, gpxData) perché estende la classe Trip
class dayTrip extends Trip {
  int stageNumber;
  double dayDistance; 
  double dayElevationPos; 
  double dayElevationNeg;
  
 
  dayTrip(
    String title, 
    String activity, 
    Gpx gpxData, 
    this.stageNumber,
    this.dayDistance, 
    this.dayElevationPos, 
    this.dayElevationNeg) 
      : super(title, activity, gpxData);

  @override
  String toString() {
    return 'dayTrip{ title: $title, stageNumber: $stageNumber, activity: $activity, dayDistance: $dayDistance, dayElevationPos: $dayElevationPos, dayElevationNeg: $dayElevationNeg}';
  }
}