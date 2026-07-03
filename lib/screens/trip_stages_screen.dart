
import 'package:flutter/material.dart';
import 'package:project_app/services/gpx_services.dart';
import '../providers/TripProvider.dart';
import 'package:provider/provider.dart';
import 'package:project_app/models/trip.dart';
import 'package:project_app/widgets/elevation_profile_chart.dart'; // Aggiungi questo import


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
        child: Consumer<TripProvider>( // parte della UI che si ribuilda ad ogni notifyListeners() del provider
          builder: (context, tripProvider, child) {
            Trip trip=tripProvider.tripList[indexTrips];  // accedo alla variabile del provider per prendere l'indice del viaggio selezionato
            List<dayTrip> stages=trip.dayTripsList ?? []; // prendo la lista delle tappe del viaggio selezionato, se non c'è nulla uso una lista vuota
            return Column(
              children: [
                // ------- TITOLO DEL VIAGGIO (con possibilità di modifica) ----
                GestureDetector( // widget che rileva il tocco sul titolo del viaggio, per permettere la modifica del titolo
                  onTap: () {
                    
                    showDialog( // widget che mostra un pop-up con un TextField per inserire il nuovo titolo del viaggio
                      context: context,
                      builder: (contextDialog) {
                        TextEditingController titleController = TextEditingController(text: trip.title);

                        return AlertDialog(
                          title: const Text('Modifica Titolo Viaggio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          content: TextField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              hintText: 'Inserisci il nuovo titolo',
                              border: OutlineInputBorder(),
                            ),
                          ),

                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(contextDialog), // Chiudi senza salvare
                              child: const Text('ANNULLA', style: TextStyle(color: Colors.grey)),
                            ),
                            // -- pulsante SALVA -- //
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3B5A)),
                              onPressed: () async {
                                // metodo del provider per aggiornare il titolo e chiamare notifyListeners() 
                                tripProvider.updateTripTitle(
                                  indexTrips,          // indice del viaggio selezionato
                                  titleController.text // Il nuovo titolo digitato
                                );
                                
                                Navigator.pop(contextDialog); // Chiudi il pop-up
                              },
                              child: const Text('SALVA', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        );
                      },
                    );
                  },// onTap
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF1B3B5A),
                    padding: const EdgeInsets.only(bottom: 20, top: 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                trip.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.edit, color: Colors.white70, size: 18), // Iconcina intuitiva
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '(${trip.distance.toStringAsFixed(0)}km, +${trip.elevationPos.toStringAsFixed(0)}m)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),


                // --------GRAFICO DEL PROFILO ALTIMETRICO----------
                ElevationProfileChart(
                  distanceProfile: trip.distanceProfile,
                  elevationProfile: trip.elevationProfile,
                  cutDistances: trip.cutDistances,
                  selectedStageIndex: tripProvider.selectedStageIndex, // Passiamo l'indice selezionato
                ),
                // ----------------------------------------
                

                // ---- Lista delle tappe -----
                Expanded( // Usa Expanded per far sì che la ListView prenda tutto lo spazio disponibile
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: stages.length, // numero di tappe
                    itemBuilder: (context, indexStages) { // iteriamo sulla lista delle tappe del viaggio selezionato, per ogni tappa creiamo una card che mostra le informazioni principali (numero della tappa, distanza, dislivello) e un'iconina che rappresenta l'attività (walk o bike)
                      final stage = stages[indexStages];  // prendo la tappa corrente dalla lista delle tappe del viaggio selezionato
                   
                      final isSelected = tripProvider.selectedStageIndex == indexStages; // variabile booleana che indica se la tappa corrente è selezionata
                      
                      return GestureDetector( // Rileva il tocco sulla card
                        onTap: () {
                          if (isSelected) { // se l'utente tocca su una card già selezionata
                            tripProvider.selectStage(null); // deseleziono la tappa
                          } else { // la tappa non è selezionata
                            tripProvider.selectStage(indexStages); //seleziono la tappa
                          }
                        },

                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          // SUGGERIMENTO UX: Puoi cambiare leggermente il colore di sfondo della card 
                          // o aggiungere un bordo colorato se isSelected è true, così l'utente vede il feedback anche sulla lista!
                          child: Card(
                            
                            color: isSelected ? Colors.blue[50] : Colors.white, //colore sfondo leggermente diverso se la tappa è selezionata
                            elevation: isSelected ? 4 : 1, // Più ombra se selezionata
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: isSelected 
                                  ? const BorderSide(color: Color(0xFF1B3B5A), width: 2) // Bordo scuro se selezionata
                                  : BorderSide.none, // se non è selezionata, nessun bordo
                            ),
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
                                        await GpxService.exportStageGpx(stage);
                                        
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
                        ),
                      );
                    },// itemBuilder
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
                            await GpxService.exportAllStagesGpx(stages, trip.title);
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