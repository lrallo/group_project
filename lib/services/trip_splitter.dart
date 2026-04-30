// file: trip_splitter.dart
import 'package:flutter/material.dart';

import '/providers/DBTrips_provider.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';

// TABELLA dei livelli di performance e sforzo giornaliero associato (in km) 
//n.b. sono "km di sforzo", non km totali, quindi tengono conto anche del dislivello (es. 10 km con 1000 m di dislivello positivo equivalgono a 20 km di sforzo)
const Map<int, double> walkEffortTable = {
  1: 15.0,  // Principiante: 15 km sforzo al giorno
  2: 20.0,
  3: 25.0,
  4: 30.0,
  5: 35.0,  // Intermedio: 35 km sforzo al giorno
  6: 40.0,
  7: 45.0,
  8: 50.0,
  9: 55.0,
  10: 60.0  // Atleta Elite: 60 km sforzo al giorno
};


// Tabella per il Cicloturismo (Bike)
const Map<int, double> bikeEffortTable = {
  1: 40.0,  // Principiante: 40 km sforzo al giorno
  2: 55.0,
  3: 70.0,
  4: 85.0,
  5: 100.0, // Intermedio: 100 km sforzo al giorno
  6: 120.0,
  7: 140.0,
  8: 160.0,
  9: 180.0,
  10: 200.0 // Atleta Elite: 200 km sforzo al giorno
};



// Funzione che prende in input i dati GPX di un viaggio e l'attività (walk o bike) e restituisce una lista di dayTrip, ovvero i singoli giorni del viaggio, con distanza e dislivello di ogni giorno

Future<void> calculateAndCut(Trip trip, int performanceLevel) async { //n.b. in input prenderà anche la performance score
  List<dayTrip> generatedStages = [];
  Gpx gpxData = trip.gpxData;
  String activity = trip.activity;

  double? maxDayEffortScore = 0.0 ; 
  double elevationDivisor = 100.0;

  // --- SELETTORE ATTIVITÀ ---
  if (activity == 'walk') {
    maxDayEffortScore = walkEffortTable[performanceLevel]; // se per qualche motivo il livello di performance non è presente nella tabella, assegno un valore di default (es. 25 km di sforzo al giorno)
    elevationDivisor = 100.0; // 100m D+ = 1 km sforzo a piedi
  } else if (activity == 'bike') {
    maxDayEffortScore = bikeEffortTable[performanceLevel] ; 
    elevationDivisor = 100.0; // Puoi cambiarlo a 120.0 o 150.0 se i tester ciclisti si lamentano che le salite pesano troppo nel calcolo!
  } else {
    print("Errore: Attività non riconosciuta!");
  }





  print("Inizio analisi del file GPX per attività: $activity..., l'effort score giornaliero massimo per il livello di performance dell'utente( $performanceLevel su 10) è: $maxDayEffortScore km");
  
  // 1. Prepariamo delle variabili per i nostri calcoli
  double totDist = 0.0; //distanza totale accumulata
  double totEle_pos = 0.0; //dislivello totale accumulato
  double totEle_neg = 0.0; //dislivello negativo totale accumulato

  // Variabili per la tappa CORRENTE che stiamo costruendo
  List<Wpt> currentStagePoints = []; //lista dei punti che fanno parte della tappa corrente
  double currentDayEffort = 0.0; //sforzo accumulato nella tappa corrente, calcolato come distanza + dislivello convertito in "km di sforzo" (es. 1000 m di dislivello positivo equivalgono a 10 km di sforzo)
  double currentStageDist = 0.0; //distanza accumulata nella tappa corrente
  double currentStageElePos = 0.0; //dislivello positivo accumulato nella tappa corrente
  double currentStageEleNeg = 0.0; //dislivello negativo accumulato nella tappa corrente

  final Distance distance = const Distance(); // è una classe della libreria latlong2 che ci permette di calcolare la distanza tra due punti geografici (latitudine e longitudine)


  // 2. CALCOLO LA DISTANZA E IL DISLIVELLO TOTALE DEL VIAGGIO (n.b. non è salvato da nessuna parte nei file .gpx)
  // (Di solito c'è una sola traccia e un solo segmento, ma è bene ciclare tutto)

  for (var track in gpxData.trks) { 
    for (var segment in track.trksegs) { //itero su tutti i segmenti (trksegs) di ogni traccia
      for (int i = 0; i < segment.trkpts.length; i++) { //itero su tutti i punti (trkpts) di ogni segmento
        var currentPoint = segment.trkpts[i];

        currentStagePoints.add(currentPoint); //aggiungo il punto corrente alla lista dei punti della tappa corrente
        
        if (i > 0) {
          var prevPoint = segment.trkpts[i-1];
          double segmentEffort = 0.0;

           
        
           // calcolo DISTANZA:  //
        
          double meters = distance(
            LatLng(prevPoint.lat?? 0, prevPoint.lon?? 0),
            LatLng(currentPoint.lat ?? 0, currentPoint.lon ?? 0),
            );
          double d = meters / 1000.0;
          totDist += d;          // aggiorno la distanza totale del viaggio
          currentStageDist += d; // aggiorno la distanza della tappa corrente
          

          //  calcolo DISLIVELLO:  //
          double eleDiff = (currentPoint.ele ?? 0) - (prevPoint.ele ?? 0);
          if (eleDiff>0) { //salita
            totEle_pos += eleDiff;
            currentStageElePos += eleDiff;
            //modificare se si vuole dare piu peso alle salite in bici rispetto a piedi, es. con un moltiplicatore di 0.8 o 0.9 per le bici, e 1.0 per le camminate
            segmentEffort = d + (eleDiff / elevationDivisor);

          } else{ //discesa
            totEle_neg += eleDiff.abs();
            currentStageEleNeg += eleDiff.abs();
            // Applichiamo lo "sconto discesa"
            segmentEffort = (activity == 'bike') ? (d * 0.3) : (d * 0.9); // per le bici, le discese pesano solo per il 30% del loro valore in km di sforzo, per le camminate per il 90%
          }


           currentDayEffort += segmentEffort;

           // controllo se ho superato lo sforrzo giornaliero massimo //  se lo sforzo accumulato nella tappa corrente ha superato il massimo sforzo giornaliero associato al livello di performance dell'utente, allora chiudo la tappa corrente e ne apro una nuova
           if (currentDayEffort > maxDayEffortScore!) {
            print("  Sforzo giornaliero massimo superato: ${currentDayEffort.toStringAsFixed(2)} km di sforzo (max per il livello di performance dell'utente: $maxDayEffortScore km). Creo una nuova tappa...");
            
            //calcolo il numero della tappa corrente
            int stageNumn=generatedStages.length + 1;
            // 1. creo il GPX della tappa corrente
            Gpx stageGpx = Gpx(); // creo un nuovo oggetto Gpx per la tappa corrente
            var stageTrk = Trk(name: 'Tappa ${generatedStages.length + 1}');// creo una traccia per la tappa, con un nome tipo "Tappa 1", "Tappa 2", ecc.
            stageTrk.trksegs.add(Trkseg(trkpts: currentStagePoints)); // aggiungo i punti della tappa alla traccia
            
            stageGpx.metadata = gpxData.metadata; //copio i metadati del viaggio complessivo (es. nome, autore, ecc.) nella tappa
            stageGpx.trks.add(stageTrk); // aggiungo la traccia alla tappa

            // 2. creo l'oggetto dayTrip della tappa corrente,"), e lo aggiungo alla lista generatedStage
            
            generatedStages.add(dayTrip(
              'Tappa ${generatedStages.length + 1}', // titolo della tappa, es. "Tappa 1", "Tappa 2", ecc.
              activity,
              stageGpx, // dati GPX della tappa
              stageNumn,
              currentStageDist, // distanza della tappa
              currentStageElePos, // dislivello positivo della tappa
              currentStageEleNeg // dislivello negativo della tappa
            ));
            
            // 3. resetto le variabili della tappa corrente per iniziare a costruire la tappa successiva
            currentStagePoints = [currentPoint]; // la tappa successiva inizia dal punto corrente
            currentDayEffort = 0.0; 
            currentStageDist = 0.0; 
            currentStageElePos = 0.0;
            currentStageEleNeg = 0.0; 
           } //if 
      
      }// if
      }
      }// fine ciclo su tracce, segmenti e punti
    }// fine ciclo su tracce, segmenti e punti

    // --- GESTIONE DELL'ULTIMA TAPPA (RIMANENZA) ---
  if (currentStagePoints.length > 1) {
    int stageNumn=generatedStages.length + 1;
    Gpx finalGpx = Gpx(); 
    var finalTrk = Trk(name: 'Tappa ${generatedStages.length + 1}');
    finalTrk.trksegs.add(Trkseg(trkpts: currentStagePoints)); 
    
    finalGpx.metadata = gpxData.metadata; 
    finalGpx.trks.add(finalTrk); 

    generatedStages.add(dayTrip(
      trip.title, 
      activity,
      finalGpx, 
      stageNumn,
      currentStageDist, 
      currentStageElePos, 
      currentStageEleNeg 
    ));
    
    print("  Ultima tappa aggiunta con i chilometri rimanenti del percorso!");
  }
  // --aggiorno le informazioni complessive del viaggio con i totali calcolati:
  trip.distance = totDist;
  trip.elevationPos = totEle_pos;
  trip.elevationNeg = totEle_neg; 
  trip.dayTripsList = generatedStages; // salvo la lista delle tappe generate nella variabile dayTrips del viaggio complessivo, così poi possiamo accedervi direttamente da lì quando vogliamo mostrare le tappe all'utente (es. nella schermata TripStagesScreen)

  print('analisi completata. Distanza totale: ${totDist.toStringAsFixed(2)} Km, Dislivello positivo totale: ${totEle_pos.toStringAsFixed(2)} m, Dislivello negativo totale: ${totEle_neg.toStringAsFixed(2)} m');
  print('Riassunto delle tappe generate:');
  for (var stage in generatedStages) {
    print('  ${stage.title} - Distanza: ${stage.dayDistance.toStringAsFixed(2)} km, Dislivello positivo: ${stage.dayElevationPos.toStringAsFixed(2)} m, Dislivello negativo: ${stage.dayElevationNeg.toStringAsFixed(2)} m');
  } 
}//  calculateAndCut

