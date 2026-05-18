
import 'package:gpx/gpx.dart';

// --- TRIP  --- rappresenta un viaggio complessivo, che contiene una lista di dayTrip (tappe)
class Trip {
  String title;    // Titolo del viaggio
  Gpx gpxData;    // Dati GPX del viaggio, inizializzato come null o con un costruttore vuoto
  String activity; // Salverà 'walk' o 'bike'
  double distance = 0.0; 
  double elevationPos = 0.0; 
  double elevationNeg = 0.0;
  List<dayTrip>? dayTripsList; // Lista dei dayTrip associati a questo viaggio, inizializzata come vuota
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
  int stageNumber; //numero della tappa
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