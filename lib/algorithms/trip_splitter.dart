// file: lib/algorithms/trip_splitter.dart
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:project_app/models/trip.dart';

// Funzione che prende in input i dati GPX di un viaggio e i KM DI SFORZO MASSIMI 
// (calcolati in base all'utente) e ritaglia il percorso in tappe giornaliere.
Future<void> calculateAndCut(Trip trip, double maxDayEffortKm) async { 
  List<dayTrip> generatedStages = [];
  Gpx gpxData = trip.gpxData;
  String activity = trip.activity.toLowerCase();

  double elevationDivisor = 100.0; // 100m D+ equivalgono a 1 km flat aggiuntivo

  print('\n---- INIZIO ALGORITMO CALCOLO TAPPE ----');
  print('Attività: $activity | Limite sforzo giornaliero utente: $maxDayEffortKm km');
  
  double totDist = 0.0; 
  double totElePos = 0.0; 
  double totEleNeg = 0.0; 

  List<Wpt> currentStagePoints = []; 
  double currentDayEffort = 0.0; 
  double currentStageDist = 0.0; 
  double currentStageElePos = 0.0; 
  double currentStageEleNeg = 0.0; 

  final Distance distanceFormatter = const Distance(); 

  for (var track in gpxData.trks) { 
    for (var segment in track.trksegs) { 
      for (int i = 0; i < segment.trkpts.length; i++) { 
        var currentPoint = segment.trkpts[i];
        currentStagePoints.add(currentPoint); 
        
        if (i > 0) {
          var prevPoint = segment.trkpts[i-1];
          double segmentEffort = 0.0;

          // 1. Calcolo Distanza (in km)
          double meters = distanceFormatter(
            LatLng(prevPoint.lat ?? 0, prevPoint.lon ?? 0),
            LatLng(currentPoint.lat ?? 0, currentPoint.lon ?? 0),
          );
          double d = meters / 1000.0;
          totDist += d;          
          currentStageDist += d; 

          // 2. Calcolo Dislivello e Sforzo Equivalente
          double eleDiff = (currentPoint.ele ?? 0) - (prevPoint.ele ?? 0);
          
          if (eleDiff > 0) { // Salita
            totElePos += eleDiff;
            currentStageElePos += eleDiff;
            // Sforzo = distanza piana + compensazione salita
            segmentEffort = d + (eleDiff / elevationDivisor);

          } else { // Discesa
            totEleNeg += eleDiff.abs();
            currentStageEleNeg += eleDiff.abs();
            
            // "Sconto Discesa": In bici si fa molta meno fatica in discesa (30% dello sforzo in piano)
            // A piedi, la discesa causa comunque affaticamento muscolare (90% dello sforzo in piano)
            segmentEffort = (activity.contains('bike') || activity.contains('bici')) 
                ? (d * 0.3) 
                : (d * 0.9); 
          }

          currentDayEffort += segmentEffort;

          // 3. Taglio della Tappa
          if (currentDayEffort >= maxDayEffortKm) {
            int stageNum = generatedStages.length + 1;
            print("  Tappa $stageNum chiusa a ${currentDayEffort.toStringAsFixed(1)} km di sforzo.");
            
            Gpx stageGpx = Gpx(); 
            var stageTrk = Trk(name: 'Tappa $stageNum');
            stageTrk.trksegs.add(Trkseg(trkpts: currentStagePoints)); 
            
            stageGpx.metadata = gpxData.metadata; 
            stageGpx.trks.add(stageTrk); 

            generatedStages.add(dayTrip(
              'Tappa $stageNum', 
              activity,
              stageGpx, 
              stageNum,
              currentStageDist, 
              currentStageElePos, 
              currentStageEleNeg 
            ));
            
            // Resetto le variabili per la tappa successiva (mantenendo l'ultimo punto per continuità)
            currentStagePoints = [currentPoint]; 
            currentDayEffort = 0.0; 
            currentStageDist = 0.0; 
            currentStageElePos = 0.0;
            currentStageEleNeg = 0.0; 
          } 
        }
      }
    }
  }

  // --- GESTIONE DELL'ULTIMA TAPPA (Rimanenza) ---
  if (currentStagePoints.length > 1) {
    int stageNum = generatedStages.length + 1;
    Gpx finalGpx = Gpx(); 
    var finalTrk = Trk(name: 'Tappa $stageNum');
    finalTrk.trksegs.add(Trkseg(trkpts: currentStagePoints)); 
    
    finalGpx.metadata = gpxData.metadata; 
    finalGpx.trks.add(finalTrk); 

    generatedStages.add(dayTrip(
      'Tappa Finale', 
      activity,
      finalGpx, 
      stageNum,
      currentStageDist, 
      currentStageElePos, 
      currentStageEleNeg 
    ));
    print("  Ultima tappa aggiunta con i chilometri rimanenti.");
  }

  // Aggiorno l'oggetto Trip genitore
  trip.distance = totDist;
  trip.elevationPos = totElePos;
  trip.elevationNeg = totEleNeg; 
  trip.dayTripsList = generatedStages; 

  print('Analisi completata. Distanza reale totale: ${totDist.toStringAsFixed(2)} Km');
  print('---- FINE ALGORITMO ----\n');
}