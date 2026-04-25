import 'package:flutter/material.dart';
import 'package:gpx/gpx.dart';


// ChangeNotifier 
class DBtrips extends ChangeNotifier {
  List<Trip> TripList = []; 

  void addTrip(Trip toAdd) {
    TripList.add(toAdd);
    notifyListeners(); // Notifica i listener che la lista è stata aggiornata
  }

  @override
  String toString() {
    return 'DBtrips{ TripList: $TripList}';
  }
}

class Trip {
  final String ID; // ID univoco del viaggio
  String title;    // Titolo del viaggio
  
  Gpx gpxData; // Dati GPX del viaggio, inizializzato come null o con un costruttore vuoto
  String activity; // Salverà 'walk' o 'bike'

  int distance = 0; 
  int elevation = 0; 

  List<dynamic> dayTrips = []; // Sostituisci dynamic con dayTrip quando lo avrai creato

  // Costruttore aggiornato
  Trip(this.ID, this.title, this.activity, this.gpxData);

  @override
  String toString() {
    return 'Trip{ID: $ID, title: $title, activity: $activity, distance: $distance, elevation: $elevation, dayTrips: $dayTrips}';
  }

}




class dayTrip extends Trip{
  final String date; // Data del giorno specifico
  int dayDistance = 0; 
  int dayElevation = 0; 

  dayTrip(String ID, String title, String activity, Gpx gpxData, this.date) : super(ID, title, activity, gpxData);
}