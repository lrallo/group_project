import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/DBTrips_provider.dart';
import 'package:dotted_border/dotted_border.dart'; //bordo tratteggiato per la card di upload del GPX
import 'package:file_picker/file_picker.dart';
import 'package:gpx/gpx.dart';
import 'dart:convert'; // Serve per trasformare i byte in testo (utf8)
import 'package:flutter/foundation.dart' show kIsWeb; // Serve per verificare se siamo su web o su mobile, perché la gestione dei file è diversa

class Tripsbody extends StatefulWidget { // StatefulWidget perché dobbiamo gestire lo stato della selezione dell'attività (walk/bike) e abilitare/disabilitare il tasto di upload
  const Tripsbody({super.key});
  @override
  State<Tripsbody> createState() => _TripsbodyState();
}

class _TripsbodyState extends State<Tripsbody> {
  String? selectedActivity;

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
                    // Se isReadyToUpload è false, onTap è null (disabilita il tap)
                    onTap: isReadyToUpload //IF isReadyToUpload is true, then execute the function:
                        ? () async {
                            print("Apertura selettore file gpx per la modalità: $selectedActivity");
                            
                            FilePickerResult? result = await FilePicker.platform.pickFiles( //apre la finestra del pc per selezionare un file GPX e lo salva su result
                              type: FileType.custom, // Diciamo al picker che vogliamo file specifici
                              allowedExtensions: ['gpx'],
                              withData: true, // Limitiamo la selezione ai file GPX
                            );

                            if (result != null) {      // L'utente ha selezionato un file
                              String fileName = result.files.single.name;
                              print("File caricato con successo: $fileName");

                              try {
                                String contenutoXml = utf8.decode(result.files.single.bytes!);
                                Gpx gpxData = GpxReader().fromString(contenutoXml);
                                String nuovoId = DateTime.now().millisecondsSinceEpoch.toString();

                                Trip newTrip = Trip(
                                  nuovoId,
                                  fileName,          
                                  selectedActivity!,
                                  gpxData,           
                                );

                                Provider.of<DBtrips>(context, listen: false).addTrip(newTrip); 

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Percorso caricato nella tua lista!')),
                                );
                                print('Viaggio aggiunto correttamente!'); 
                                print('stato attuale del DB: ${DBtrips().toString().toString()}');

                              } catch (e) {
                                // Aggiunto un blocco try-catch per sicurezza, nel caso il file sia corrotto
                                print("Errore durante la lettura del file: $e");
                              }
                            } else { //
                              print("Selezione file annullata");
                            }
                          } 
                        : null, //ELSE disabilita il tap
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
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(), // Effetto scorrimento morbido
                  itemCount: 4, // Numero di viaggi finti (sostituisci con la lunghezza della tua lista reale)
                  itemBuilder: (context, index) {
                    // Qui chiameresti i dati dal tuo provider DBtrips
                    // Esempio fittizio basato sull'immagine:
                    if (index == 0) {
                      return _buildTripCard("Giro delle Dolomiti", "150km | +3000m");
                    }
                    return _buildTripCard("Via Francigena", "220km | +4500m");
                  },
                ),
              ),
          ],
        ),
      ),
      );
  }

  // Metodo helper per creare le singole card dei viaggi
  Widget _buildTripCard(String title, String subtitle) {
    return Container(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          // Placeholder per l'immagine del paesaggio
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey[300],
              child: const Icon(Icons.landscape, color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }
}