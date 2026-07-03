import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_app/providers/TripProvider.dart';
import 'package:project_app/models/trip.dart';
import 'package:dotted_border/dotted_border.dart'; //bordo tratteggiato per la card di upload del GPX
import 'package:flutter/foundation.dart' show kIsWeb; // Serve per verificare se siamo su web o su mobile, perché la gestione dei file è diversa
import 'package:project_app/screens/trip_stages_screen.dart'; // Importiamo la schermata delle tappe per poterci navigare quando clicchiamo su un viaggio nella lista
import 'package:shared_preferences/shared_preferences.dart'; // Per accedere alla memoria locale e recuperare i valori di maxEffortWalk e maxEffortBike calcolati dal provider di training, così da passarli al provider dei viaggi quando carichiamo un nuovo percorso, in modo che possa calcolare le tappe in base al livello di performance dell'utente


class Tripsbody extends StatefulWidget { // StatefulWidget perché dobbiamo gestire lo stato della selezione dell'attività (walk/bike) e abilitare/disabilitare il tasto di upload
  const Tripsbody({super.key});
  @override
  State<Tripsbody> createState() => _TripsbodyState();
}

class _TripsbodyState extends State<Tripsbody> {
  String? selectedActivity; //inizializzato come Null

  @override
  Widget build(BuildContext context) {
    bool isReadyToUpload = selectedActivity != null; // Il tasto di upload è abilitato solo se è stata selezionata un'attività

    return Scaffold(
        backgroundColor: Colors.grey[100],
        
        // Mostriamo direttamente la lista senza TabBarView
        body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // --- WIDGET CONTENITORE TRATTEGGIATO ---
            DottedBorder(
              color: const Color(0xFF1B3B5A), // Colore del tratteggio
              strokeWidth: 2,                 // Spessore
              dashPattern: const [8, 4],      // Lunghezza tratto, lunghezza spazio
              borderType: BorderType.RRect,   // Rettangolo arrotondato
              radius: const Radius.circular(15),
              padding: const EdgeInsets.all(20), // Spazio interno dal bordo
              child: Column(
                mainAxisSize: MainAxisSize.min, // Occupa solo lo spazio necessario
                children: [
                  
                  // --- TASTO CENTRALE: NEW TRIP ---
                  GestureDetector(
                    onTap: () async { 
                        // SE  non è stata selezionata un'attività, mostro un messaggio di errore e non apro il file picker
                        if (!isReadyToUpload) {
                          print("Tasto premuto, ma nessuna attività selezionata!");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Seleziona prima un\'attività (walk o bike)!'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return; // IMPORTANTE: Esce dalla funzione onTap, così non va avanti a caricare il file.
                        }else{
                          // SE è stata selezionata un'attività, procedo con l'apertura del file picker
                          print("Apertura selettore file gpx per la modalità: $selectedActivity");
                          
                          // chiamo il metodo addTrip del provider, che si occuperà di aprire il file picker, leggere il file, creare l'oggetto Trip, calcolare le tappe e aggiungere tutto al DB (lista dei viaggi) del provider
                          bool success = await Provider.of<TripProvider>(context, listen: false).addTrip(selectedActivity!); 
                          
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Percorso caricato nella tua lista!'),
                                backgroundColor: Colors.green,
                              ),);
                           
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Errore nel caricamento del percorso. Riprova!'),
                                backgroundColor: Colors.redAccent,
                              ),);
                          }

                          print('Stato attuale del DB:\n${Provider.of<TripProvider>(context, listen: false).tripList.toString()}');
                          
                          // riaggiorno la variabile di stato isReadyToUpload, così se l'utente vuole caricare un altro file deve prima scegliere se è walk o bike
                          isReadyToUpload = false;
                          //riabilito il tasto di upload resettando la selezione dell'attività, così se l'utente vuole caricare un altro file deve prima scegliere se è walk o bike
                          setState(() {
                            selectedActivity = null;
                          });

                        } },
                    
                    

                    child: Opacity(
                      // Abbassiamo l'opacità se il tasto è disabilitato per dare feedback visivo
                      opacity: isReadyToUpload ? 1.0 : 0.4, 
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          // Bordo solido interno, ma puoi anche toglierlo se preferisci solo quello tratteggiato esterno
                          border: Border.all(color: const Color(0xFF1B3B5A), width: 1.5), 
                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: const Column(
                          children: [
                            Icon(Icons.upload_file, size: 50, color: Color(0xFF1B3B5A)),
                            SizedBox(height: 10),
                            Text(
                              'New Trip',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                color: Color(0xFF1B3B5A)
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                                'Carica file GPX per dividere\nun nuovo percorso',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                                )
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20), // Spazio tra upload e i tasti di scelta

                  // --- TASTI IN BASSO IN RIGA: BY WALK / BY BIKE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Tasto Walk
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedActivity = 'walk'; // Aggiorna lo stato con l'attività selezionata, questo abiliterà il tasto di upload se era disabilitato
                            });
                          },
                          icon: const Icon(Icons.directions_walk, size: 18),
                          label: const Text('By Walk'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            // Colore pieno se selezionato, sbiadito se non selezionato
                            backgroundColor: selectedActivity == 'walk' 
                                ? Colors.orange 
                                : Colors.orange.shade200,
                            foregroundColor: selectedActivity == 'walk'
                                ? Colors.white
                                : Colors.black54, // Testo più scuro se disabilitato
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      
                      // Tasto Bike
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedActivity = 'bike';
                            });
                          },
                          icon: const Icon(Icons.directions_bike),
                          label: const Text('By Bike'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            // Colore pieno se selezionato, sbiadito se non selezionato
                            backgroundColor: selectedActivity == 'bike' 
                                ? const Color(0xFF4A7C59) 
                                : const Color(0xFF4A7C59).withOpacity(0.4),
                            foregroundColor: selectedActivity == 'bike'
                                ? Colors.white
                                : Colors.black54,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Spazio tra il riquadro e la lista

              // 2. LISTA SCORREVOLE DEI VIAGGI
              // Usiamo Expanded per dire alla ListView di prendersi tutto lo spazio rimasto
              // 1. Accedi al provider DBtrips
                       
            Expanded( 
              child: Consumer<TripProvider>(
                builder: (context, dbTrips, child) {
                  final tripsList = dbTrips.tripList;

                  if (tripsList.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nessun viaggio caricato. Carica un file GPX per iniziare!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: tripsList.length,
                      itemBuilder: (context, index) { //itero sulla lista dei viaggi caricati, per ogni viaggio creo una card con le informazioni principali (nome del file, distanza totale, dislivello totale) e un'iconina che rappresenta l'attività (walk o bike)
                        Trip trip = tripsList[index];
                        return _buildTripCard(context,  trip);
                      },
                    );
                  }
                },
                
              ),
            ),
          ],
        ),
      ),
      );
  }

  // Metodo helper per creare le singole card dei viaggi
  Widget _buildTripCard(BuildContext context, Trip trip) {
    String formattedSubtitle = "${trip.distance.toStringAsFixed(0)}km | +${trip.elevationPos.toStringAsFixed(0)}m"; // Formatta il sottotitolo con la distanza e il dislivello
    IconData activityIcon = trip.activity == 'bike' ? Icons.directions_bike : Icons.directions_walk;
    // Formattiamo la data di importazione in un formato leggibile
    String day = trip.importDate.day.toString().padLeft(2, '0');
    String month = trip.importDate.month.toString().padLeft(2, '0');
    String year = trip.importDate.year.toString();
    String hour = trip.importDate.hour.toString().padLeft(2, '0');
    String minute = trip.importDate.minute.toString().padLeft(2, '0');
    String displayDate = "$day/$month/$year - $hour:$minute";

    return GestureDetector( 
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripStagesScreen(
              indexTrips: Provider.of<TripProvider>(context, listen: false).tripList.indexOf(trip)
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row( 
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // --- PARTE SINISTRA: Testi ---
            Expanded( 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title, 
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis, 
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formattedSubtitle, 
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Caricato il: $displayDate',
                    style: TextStyle(
                      fontSize: 11, 
                      color: Colors.grey[400], 
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            // --- PARTE DESTRA: Icona Attività (Grande) + Cestino (Piccolo e Grigio) ---
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Icona Attività (Walk/Bike) - PIÙ GRANDE E IN RISALTO
                Container(
                  width: 55,  // Dimensione aumentata
                  height: 55, // Dimensione aumentata
                  decoration: BoxDecoration(
                    color: trip.activity == 'bike' 
                        ? const Color(0xFF4A7C59).withOpacity(0.15) 
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14), // Bordi più morbidi
                  ),
                  child: Icon(
                    activityIcon, 
                    size: 32, // Icona più grande
                    color: trip.activity == 'bike' ? const Color(0xFF4A7C59) : Colors.orange,
                  ),
                ),
                
                const SizedBox(width: 10), // Spazio tra i due elementi
                
                // 2. Bottone Cestino - PIÙ PICCOLO E DISCRETO
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      // Mostriamo il Pop-up di conferma prima di eliminare
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Elimina viaggio'),
                          content: Text('Sei sicuro di voler eliminare "${trip.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('ANNULLA', style: TextStyle(color: Colors.grey)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                Provider.of<TripProvider>(context, listen: false).removeTrip(trip);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Viaggio eliminato'),
                                    backgroundColor: Colors.redAccent,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Text('ELIMINA', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: 35,  // Dimensione ridotta
                      height: 35, // Dimensione ridotta
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15), // Sfondo grigio opaco/tenue
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline, 
                        color: Colors.grey, // Icona grigia
                        size: 20, // Icona più piccola
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      );
  }
}