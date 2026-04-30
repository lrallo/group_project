
import 'package:flutter/material.dart';
import '/providers/DBTrips_provider.dart';
import '/providers/DBTrips_provider.dart';
import 'package:provider/provider.dart';
import 'package:project_app/services/exportGpx.dart';


class TripStagesScreen extends StatelessWidget {
  final int indexTrips;  // indice del viaggio selezionato nella lista dei viaggi caricati, che ci serve per accedere alla lista delle tappe di quel viaggio nel provider
  const TripStagesScreen({super.key, required this.indexTrips});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('PIANIFICAZIONE TAPPE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B3B5A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      
      body:  Center(
        child: Consumer<DBtrips>(
          builder: (context, dbTrips, child) {
            Trip trip=dbTrips.TripList[indexTrips]; // prendo il viaggio selezionato dalla lista dei viaggi caricati, usando l'indice passato in input al costruttore
            List<dayTrip> stages=trip.dayTripsList ?? []; // aggiorno la lista delle tappe con i dati del provider, così se per qualche motivo non erano state caricate correttamente prima, ora le prendo direttamente da lì (nella maggior parte dei casi però non dovrebbe essere necessario, perché quando arriviamo qui le tappe dovrebbero essere già caricate nella variabile dayTrips del viaggio)
            return
        Column(
            children: [
              // Header verde scuro con i totali
              Container(
                width: double.infinity,
                color: const Color(0xFF1B3B5A),
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  '${trip.title}\n(${trip.distance.toStringAsFixed(0)}km, +${trip.elevationPos.toStringAsFixed(0)}m)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              
              // Lista delle tappe
              Expanded( // Usa Expanded per far sì che la ListView prenda tutto lo spazio disponibile
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: stages.length, // numero di tappe
                  itemBuilder: (context, indexStages) { // iteriamo sulla lista delle tappe del viaggio selezionato, per ogni tappa creiamo una card che mostra le informazioni principali (numero della tappa, distanza, dislivello) e un'iconina che rappresenta l'attività (walk o bike)
                    final stage = stages[indexStages];  // prendo la tappa corrente dalla lista delle tappe del viaggio selezionato
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // La "Timeline" laterale (il pallino con la riga)
                          Column(
                            children: [
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A7C59),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                              // Disegna la riga solo se non è l'ultimo elemento
                              if (indexStages < stages.length - 1)
                                Container(
                                  width: 2,
                                  height: 60, // Altezza fissa per la linea (puoi aggiustarla)
                                  color: const Color(0xFF1B3B5A),
                                ),
                            ],
                          ),
                          const SizedBox(width: 15),
                          
                          // La Card della Tappa
                          Expanded( 
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              ),
                              child: Row( 
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'GIORNO ${indexStages + 1}:',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${stage.dayDistance.toStringAsFixed(0)}km | +${stage.dayElevationPos.toStringAsFixed(0)}m | -${stage.dayElevationNeg.toStringAsFixed(0)}m',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  // --- pulsante per scaricare la singola tappa -- //
                                  IconButton(
                                    icon: const Icon(
                                      Icons.download_rounded, // Icona di download
                                      color: Color(0xFF1B3B5A),
                                      size: 28,
                                    ),
                                    onPressed: () async {
                                      // Richiama la funzione passandogli la tappa corrente (stage)
                                      await exportStageGpx(stage);
                                      
                                      // Mostra un feedback visivo all'utente
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Esportazione di ${stage.title} avviata!'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
          
              // Pulsanti in basso (Esporta Tappe / chiudi viaggio)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // -- pulsante ESPORTA TAPPE --//
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          // 1. Mostriamo uno SnackBar per avvisare l'utente che stiamo elaborando
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Preparazione dei file in corso...')),
                          );

                          // 2. Chiamiamo la funzione passando la lista delle tappe e il titolo
                          await exportAllStagesGpx(stages, trip.title);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Color(0xFF1B3B5A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('ESPORTA TAPPE', style: TextStyle(color: Color(0xFF1B3B5A))),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // -- pulsante CHIUDI --//
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Torna indietro alla home
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3B5A),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('CHIUDI', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        }//consumer
      ),
      ),
    );
  }
}