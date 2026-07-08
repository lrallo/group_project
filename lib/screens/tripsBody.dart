import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_app/providers/TripProvider.dart';
import 'package:project_app/models/trip.dart';
import 'package:dotted_border/dotted_border.dart'; //bordo tratteggiato per la card di upload del GPX
import 'package:flutter/foundation.dart' show kIsWeb; // Serve per verificare se siamo su web o su mobile, perché la gestione dei file è diversa
import 'package:project_app/screens/trip_stages_screen.dart'; // Importiamo la schermata delle tappe per poterci navigare quando clicchiamo su un viaggio nella lista


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
            Expanded(
              flex: 1, // Il riquadro tratteggiato occupa 1/3 dello spazio verticale disponibile
              child: DottedBorder(
                color: const Color(0xFF1B365D), // Colore del tratteggio
                strokeWidth: 2,                 // Spessore
                dashPattern: const [8, 4],      // Lunghezza tratto, lunghezza spazio
                borderType: BorderType.RRect,   // Rettangolo arrotondato
                radius: const Radius.circular(16),
                padding: const EdgeInsets.all(12), // Spazio interno dal bordo
                child: Column(
                  mainAxisSize: MainAxisSize.max, // Occupa solo lo spazio necessario
                  mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente i figli
                  children: [
                    
                    // --- TASTO CENTRALE: NEW TRIP ---
                    Expanded(
                      child: GestureDetector(
                        onTap: () async { 
                            // SE  non è stata selezionata un'attività, mostro un messaggio di errore e non apro il file picker
                            if (!isReadyToUpload) {
                              print("The button is pressed, but no activity is selected!");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Select an activity (walk or bike) first!'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return; // IMPORTANTE: Esce dalla funzione onTap, così non va avanti a caricare il file.
                            }else{
                              // SE è stata selezionata un'attività, procedo con l'apertura del file picker
                              print("Opening GPX file picker for mode: $selectedActivity");
                              
                              // chiamo il metodo addTrip del provider, che si occuperà di aprire il file picker, leggere il file, creare l'oggetto Trip, calcolare le tappe e aggiungere tutto al DB (lista dei viaggi) del provider
                              bool success = await Provider.of<TripProvider>(context, listen: false).addTrip(selectedActivity!); 
                              
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Trip uploaded to your list!'),
                                    backgroundColor: Colors.green,
                                  ),);
                               
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error uploading the trip. Please try again!'),
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
                            decoration: BoxDecoration(
                              color: Colors.white,
                              // Bordo solido interno, ma puoi anche toglierlo se preferisci solo quello tratteggiato esterno
                              border: Border.all(color: const Color(0xFF1B365D), width: 1.5), 
                              borderRadius: BorderRadius.circular(12),
                            ),
                                    
                            child: const Center(

                              child:  FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.upload_file, size: 40, color: Color(0xFF1B365D)),
                                      SizedBox(height: 8),
                                      Text(
                                        'New Trip',
                                        style: TextStyle(
                                          fontSize: 12, 
                                          fontWeight: FontWeight.bold, 
                                          color: Color(0xFF1B365D)
                                        ),
                                      ),
                                          
                                      SizedBox(height: 4),
                                      Text(
                                            'Upload the GPX file for your next trip',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              
                    const SizedBox(height: 10), // Spazio tra upload e i tasti di scelta
              
                    // --- TASTI IN BASSO IN RIGA: BY WALK / BY BIKE ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Tasto Walk
                        Expanded(
                          child: SizedBox(
                            height: 40, 
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() { selectedActivity = 'walk'; });
                              },
                              icon: const Icon(Icons.directions_walk, size: 16), // Icona leggermente più piccola
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('By Walk', style: TextStyle(fontSize: 13)), // Testo leggermente più piccolo
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 5), 
                                backgroundColor: selectedActivity == 'walk' 
                                    ? Colors.orange 
                                    : Colors.orange.shade200,
                                foregroundColor: selectedActivity == 'walk'
                                    ? Colors.white
                                    : Colors.black54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 15),
                        
                        // Tasto Bike
                        Expanded(
                          child: SizedBox(
                            height: 40, 
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() { selectedActivity = 'bike'; });
                              },
                              icon: const Icon(Icons.directions_bike, size: 16),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('By Bike', style: TextStyle(fontSize: 13)),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 5), 
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10), // Spazio tra il riquadro e la lista

            // 2. LISTA SCORREVOLE DEI VIAGGI
                       
            Expanded(  // Usiamo Expanded per dire alla ListView di prendersi tutto lo spazio rimasto
              flex: 2, // La lista occupa 2/3 dello spazio verticale disponibile
              child: Consumer<TripProvider>(
                builder: (context, dbTrips, child) {
                  final tripsList = dbTrips.tripList;

                  if (tripsList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 30.0, left: 10.0, right: 10.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Icona decorativa molto sbiadita
                            Icon(Icons.explore_outlined, size: 50, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            
                            // 2. Titolo 
                            const Text(
                              'Ready for a new adventure?',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
                            ),
                            const SizedBox(height: 15),
                            
                            // 3. Istruzioni Step 1
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icona numerica color pesca chiaro invece che arancione forte
                                Icon(Icons.looks_one, color: Colors.orange.shade300, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText( // Widget che permette di mettere alcune parole in grassetto, prende un oggetto TextSpan
                                    text: TextSpan(
                                      
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),// Stile base per tutto il blocco: grigio medio
                                      children: const [ //lista di altri TextSpan, che possono avere stili diversi
                                        TextSpan(text: 'Choose if you want to travel '),
                                        // Grassetto ma grigio scuro, per non "urlare"
                                        TextSpan(text: 'By Walk', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                                        TextSpan(text: ' or '),
                                        TextSpan(text: 'By Bike', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                                        TextSpan(text: ' using the buttons above.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 15),
                            
                            // 4. Istruzioni Step 2
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.looks_two, color: Colors.orange.shade300, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                                      children: const [
                                        TextSpan(text: 'Tap on '),
                                        TextSpan(text: 'New Trip', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                                        TextSpan(text: ' to upload a '),
                                        TextSpan(text: '.gpx file', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                                        TextSpan(text: ' from your device.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // ... resto del codice ListView.builder ...
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

  // Metodo per creare le singole card dei viaggi
  Widget _buildTripCard(BuildContext context, Trip trip) {
    String formattedSubtitle = "${trip.distance.toStringAsFixed(0)}km | +${trip.elevationPos.toStringAsFixed(0)}m"; // Formatta il sottotitolo con la distanza e il dislivello
    IconData activityIcon = trip.activity == 'bike' ? Icons.directions_bike : Icons.directions_walk;
    // Formattiamo la data di importazione in un formato leggibile
    String day = trip.importDate.day.toString().padLeft(2, '0'); //.padLeft(2, '0') serve a garantire che il giorno sia sempre rappresentato con due cifre, aggiungendo uno zero davanti se necessario (es. 01, 02, ..., 09, 10, ...).
    String month = trip.importDate.month.toString().padLeft(2, '0');
    String year = trip.importDate.year.toString();
    String hour = trip.importDate.hour.toString().padLeft(2, '0');
    String minute = trip.importDate.minute.toString().padLeft(2, '0');
    String displayDate = "$day/$month/$year - $hour:$minute";

    return GestureDetector( // widget che permette di rilevare il tap sulla card, così da navigare alla schermata delle tappe del viaggio selezionato
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis, 
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formattedSubtitle, 
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'uploaded on: $displayDate',
                    style: TextStyle(
                      fontSize: 10, 
                      color: Colors.grey[400], 
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            // --- PARTE DESTRA: Icona Attività  + Cestino  ---
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Icona Attività (Walk/Bike) 
                Container(
                  width: 45, 
                  height: 45, 
                  decoration: BoxDecoration(
                    color: trip.activity == 'bike' 
                        ? const Color(0xFF4A7C59).withOpacity(0.15) 
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10), 
                  ),
                  child: Icon(
                    activityIcon, 
                    size: 24,
                    color: trip.activity == 'bike' ? const Color(0xFF4A7C59) : Colors.orange,
                  ),
                ),
                
                const SizedBox(width: 5), // Spazio tra i due elementi
                
                // 2. Bottone Cestino 
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      // Mostriamo il Pop-up di conferma prima di eliminare
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Trip'),
                          content: Text('Are you sure you want to delete "${trip.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
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
                                    content: Text('Trip deleted'),
                                    backgroundColor: Colors.redAccent,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Text('DELETE', style: TextStyle(color: Colors.white)),
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
                        borderRadius: BorderRadius.circular(8),
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