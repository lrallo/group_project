import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:project_app/models/trip.dart';
import 'package:gpx/gpx.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class GpxService{

  // --- IMPORT ---
  static Future<Trip?> pickGpx(String selectedActivity) async{

    // 1. salvo il file caricato nella variabile result
    FilePickerResult? result = await FilePicker.platform.pickFiles( 
          type: FileType.custom,
          allowedExtensions: ['gpx'],
          withData: true,
          allowMultiple: false,
        );
    print('File picker chiuso, lettura del file in corso...');

    if (result != null) { // se l'utente ha selezionato un file
      String fileName = result.files.single.name;
      try {
        // 2. leggo il contenuto del file e lo converto in una stringa e poi in un oggetto Gpx
        String contenutoXml = utf8.decode(result.files.single.bytes!); 
        Gpx gpxData = GpxReader().fromString(contenutoXml); 
        print('File GPX letto correttamente, creazione dell\'oggetto  Trip...');
        return Trip(fileName, selectedActivity, gpxData);

      } catch (e) {
        print("Errore nella lettura del GPX: $e");
        return null; // Gestione dell'errore (file corrotto, ecc.)
      }
    }
    return null; // L'utente ha chiuso il picker senza scegliere file
  } //pickGpx

  // --- EXPORT ---
  static Future<void> exportStageGpx(dayTrip stage) async {
  try {
    // 1. Converte l'oggetto GPX della tappa in una stringa formattata (XML)
    final gpxString = GpxWriter().asString(stage.gpxData, pretty: true); //asString prende l'istanza dell'oggetto gpx e lo trasforma in una stringa di testo in formato XML

    // 2. Pulisce il titolo per il nome del file
    final fileName = '${stage.title.replaceAll(' ', '_')}_stage${stage.stageNumber}.gpx';
    
    if (kIsWeb) {
      // ---------------------------------------------------------
      // AMBIENTE WEB (Emulatore Chrome)
      // ---------------------------------------------------------
      // Sul web non abbiamo accesso alle cartelle. Quindi convertiamo
      // la nostra stringa di testo in un array di Byte (dati grezzi).
      final bytes = utf8.encode(gpxString);

      // Creiamo un "Blob" (un pacchetto di dati grezzi gestito dal browser)
      final blob = html.Blob([bytes], 'application/gpx+xml');
      
      // Generiamo un URL temporaneo che punta a questi dati
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Creiamo un link invisibile (anchor tag <a>), gli assegnamo l'URL e il nome file, e simuliamo un "click"
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
        
      // Puliamo la memoria
      html.Url.revokeObjectUrl(url);
      
      print("Download web avviato per: $fileName");

    } else {
      // ---------------------------------------------------------
      // AMBIENTE MOBILE (Android / iOS)
      // ---------------------------------------------------------
      // Ottiene la cartella temporanea del telefono
      final directory = await getTemporaryDirectory(); 
      final filePath = '${directory.path}/$fileName'; 
      
      // Scrive il file fisicamente sul disco del telefono
      final file = File(filePath); 
      await file.writeAsString(gpxString); 

      // Apre la finestra di dialogo nativa per salvare o condividere il file
      await Share.shareXFiles(
        [XFile(filePath)], 
        text: 'Ecco il file GPX della tappa: ${stage.title}'
      );
    }
  } catch (e) {
    print("Errore durante l'esportazione del file GPX: $e");
  }
} //exportStageGpx







// funzione per esportare tutte le stages di un trip //

static Future<void> exportAllStagesGpx(List<dayTrip> stages, String tripTitle) async {
  try {
    if (kIsWeb) {
      // ---------------------------------------------------------
      // AMBIENTE WEB (Emulatore Chrome)
      // ---------------------------------------------------------
      for (var stage in stages) {
        final gpxString = GpxWriter().asString(stage.gpxData, pretty: true);
        final fileName = '${tripTitle.replaceAll(' ', '_')}_stage${stage.stageNumber}.gpx';
        
        final bytes = utf8.encode(gpxString);
        final blob = html.Blob([bytes], 'application/gpx+xml');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
          
        html.Url.revokeObjectUrl(url);
        
        // Ritardo di 200ms tra un download e l'altro per evitare
        // che Chrome blocchi i popup/download multipli
        await Future.delayed(const Duration(milliseconds: 200)); 
      }
      print("Download web avviato per tutte le tappe di: $tripTitle");

    } else {
      // ---------------------------------------------------------
      // AMBIENTE MOBILE (Android / iOS)
      // ---------------------------------------------------------
      final directory = await getTemporaryDirectory();
      List<XFile> filesToShare = []; // Lista che conterrà tutti i nostri file

      for (var stage in stages) {
        final gpxString = GpxWriter().asString(stage.gpxData, pretty: true);
        final fileName = '${tripTitle.replaceAll(' ', '_')}_stage${stage.stageNumber}.gpx';
        final filePath = '${directory.path}/$fileName';
        
        // Scrive fisicamente ogni singolo file sul disco
        final file = File(filePath);
        await file.writeAsString(gpxString);
        
        // Aggiunge il file alla lista di quelli da condividere
        filesToShare.add(XFile(filePath)); 
      }

      // Condivide tutti i file IN UN SOLO COLPO
      await Share.shareXFiles(
        filesToShare,
        text: 'Ecco tutte le tappe del viaggio: $tripTitle'
      );
    }
  } catch (e) {
    print("Errore durante l'esportazione di tutte le tappe: $e");
  }
}

}//GpxService
