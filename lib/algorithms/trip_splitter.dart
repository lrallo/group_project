import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:project_app/models/trip.dart';

// Funzione che prende in input i dati GPX di un viaggio e i KM DI SFORZO MASSIMI 
// (calcolati in base all'utente) e ritaglia il percorso in tappe giornaliere.
Future<void> calculateAndCut(Trip trip, double maxDayEffortKm) async { 
  List<dayTrip> generatedStages = [];           // lista che conterrà le tappe generate dal taglio del viaggio complessivo
  Gpx gpxData = trip.gpxData;                   // dati GPX del viaggio complessivo
  String activity = trip.activity.toLowerCase();// 'walk' o 'bike', convertito in minuscolo per evitare problemi di confronto

  double elevationDivisor = 100.0; // 100m D+ equivalgono a 1 km flat aggiuntivo

  print('\n---- INIZIO ALGORITMO CALCOLO TAPPE ----');
  print('Attività: $activity | Limite sforzo giornaliero utente: $maxDayEffortKm km');
  
  double totDist = 0.0;   // Distanza totale del viaggio (in km)
  double totElePos = 0.0; // Dislivello positivo totale del viaggio (in m)
  double totEleNeg = 0.0; // Dislivello negativo totale del viaggio (in m)

  List<Wpt> currentStagePoints = []; // Lista dei punti GPX della tappa corrente, li salvo per creare il nuovo file GPX della tappa
  double currentDayEffort = 0.0; 
  double currentStageDist = 0.0; 
  double currentStageElePos = 0.0; 
  double currentStageEleNeg = 0.0; 

  final Distance distanceFormatter = const Distance(); 

  for (var track in gpxData.trks) { // Itero su ogni track (in genere ce n'è uno solo)
    for (var segment in track.trksegs) { // Itero su ogni segmento della track (in genere ce n'è uno solo)
      for (int i = 0; i < segment.trkpts.length; i++) {
      var currentPoint = segment.trkpts[i]; 

      // 0. Inizializzazione del primissimo punto in assoluto
      if (i == 0) {
        currentStagePoints.add(currentPoint);
        if (totDist == 0.0) { 
          trip.distanceProfile.add(0.0);
          trip.elevationProfile.add(currentPoint.ele ?? 0.0);
        }
        continue; // Salto al prossimo ciclo
      }

      var prevPoint = segment.trkpts[i-1]; 

      // 1. Calcolo della DISTANZA 
      // USO funzione della libreria latlong2 per calcolare la distanza tra due punti GPS 
      double meters = distanceFormatter(
        LatLng(prevPoint.lat ?? 0, prevPoint.lon ?? 0),
        LatLng(currentPoint.lat ?? 0, currentPoint.lon ?? 0),
      );
      double d = meters / 1000.0;
      // calcolo DISLIVELLO
      double eleDiff = (currentPoint.ele ?? 0) - (prevPoint.ele ?? 0);

      double segmentEffort = 0.0; //sforzo equivalente del segmento corrente (punto i-1 -> punto i) in km
      if (eleDiff > 0) { // SALITA
        segmentEffort = d + (eleDiff / elevationDivisor);

      } else if (eleDiff < 0) { // DISCESA
        segmentEffort = (activity.contains('bike') || activity.contains('bici')) 
            ? (d * 0.4)  
            : (d * 0.9); 

      } else { // IN PIANO
        segmentEffort = d;
      }

      // 2. LOGICA DI TAGLIO PREVENTIVO 
      if (currentDayEffort + segmentEffort > maxDayEffortKm) { // Se sforo, CHIUDO LA TAPPA ADESSO (senza il segmento corrente)
        
        trip.cutDistances.add(totDist); // salvo la distanza in cui avviene il taglio (km)
        int stageNum = generatedStages.length + 1; // numero della tappa ccorrente
        print("  Tappa $stageNum chiusa a ${currentDayEffort.toStringAsFixed(1)} km di sforzo (Preventivo).");
        
        Gpx stageGpx = Gpx();                        // Creo un nuovo oggetto GPX per la tappa corrente                 
        var stageTrk = Trk(name: 'Tappa $stageNum'); // Creo un nuovo oggetto Trk per la tappa corrente
        stageTrk.trksegs.add(Trkseg(trkpts: currentStagePoints)); // Aggiungo i punti della tappa corrente al nuovo Trkseg
        stageGpx.metadata = gpxData.metadata; // Copio i metadati del viaggio complessivo al nuovo GPX della tappa
        stageGpx.trks.add(stageTrk); // Aggiungo il nuovo Trk al nuovo GPX della tappa

        // Creo un nuovo oggetto dayTrip per la tappa corrente e lo aggiungo alla lista delle tappe generate
        generatedStages.add(dayTrip(
          'Tappa $stageNum', 
          activity,
          stageGpx, 
          stageNum,
          currentStageDist, 
          currentStageElePos, 
          currentStageEleNeg 
        ));
        
        // Inizializzo le variabili per la NUOVA TAPPA
        // la nuova tappa deve partire da prevPoint verso currentPoint per non creare buchi nella mappa!
        currentStagePoints = [prevPoint, currentPoint]; 
        currentDayEffort = segmentEffort; // il nuovo sforzo della tappa corrente parte dal segmento che ha fatto sforare la tappa precedente
        currentStageDist = d; 
        currentStageElePos = eleDiff > 0 ? eleDiff : 0.0;
        currentStageEleNeg = eleDiff < 0 ? eleDiff.abs() : 0.0; 

      } else {
        // Se NON sforo, accumulo i dati nella tappa corrente tranquillamente
        currentStagePoints.add(currentPoint);
        currentDayEffort += segmentEffort; 
        currentStageDist += d; 
        if (eleDiff > 0) currentStageElePos += eleDiff;
        if (eleDiff < 0) currentStageEleNeg += eleDiff.abs();
      }

      // 3. Aggiornamento dei totali globali del viaggio (non sono influenzati dai tagli)
      totDist += d;
      if (eleDiff > 0) totElePos += eleDiff;
      if (eleDiff < 0) totEleNeg += eleDiff.abs();

      trip.distanceProfile.add(totDist);                 
      trip.elevationProfile.add(currentPoint.ele ?? 0.0);
    
     }
    }
  }

  // --- GESTIONE DELL'ULTIMA TAPPA (Rimanenza) ---
  if (currentStagePoints.length > 1) {
    int stageNum = generatedStages.length + 1;
    Gpx finalGpx = Gpx(); 
    var finalTrk = Trk(name: 'Stage $stageNum');
    finalTrk.trksegs.add(Trkseg(trkpts: currentStagePoints)); 
    
    finalGpx.metadata = gpxData.metadata; 
    finalGpx.trks.add(finalTrk); 

    generatedStages.add(dayTrip(
      'Final Stage', 
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