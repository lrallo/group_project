import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:project_app/models/training.dart';

class ImpactService{

  static String baseUrl = 'https://impact.dei.unipd.it/bwthw/';
  static String pingEndpoint = 'gate/v1/ping/';
  static String tokenEndpoint = 'gate/v1/token/';
  static String refreshEndpoint = 'gate/v1/refresh/';
  static String exerciseEndpoint = 'data/v1/exercise/patients/';
  static String exerciseDaterangeEndpoint = 'data/v1/exercise/patients/';
  

  static String patientUsername = 'Jpefaq6m58';


  static Future<int> getAndStoreTokens(String username, String password ) async {
    final url = ImpactService.baseUrl + ImpactService.tokenEndpoint;
    final body = {'username': username, 'password': password};

    try {
      //Get the response
      print('Calling: $url');
      final response = await http.post(Uri.parse(url), body: body);

      //If response is OK, decode it and store the tokens. Otherwise do nothing.
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        final sp = await SharedPreferences.getInstance();
        await sp.setString('access', decodedResponse['access']);
        await sp.setString('refresh', decodedResponse['refresh']);
      } 
      
      return response.statusCode;

    } catch (e) { // SE NON C'È CONNESSIONE A INTERNET O IL SERVER IMPACT NON È RAGGIUNGIBILE
      print('Network Error in getAndStoreTokens (Offline): $e');
      return 500; 
    }
  } //_getAndStoreTokens
  
  
  
  //This method allows to refresh the stored JWT in SharedPreferences
  static Future<int> refreshTokens() async {
    //Create the request
    final url = ImpactService.baseUrl + ImpactService.refreshEndpoint;
    final sp = await SharedPreferences.getInstance();
    final refresh = sp.getString('refresh');

    
    if (refresh == null) { //  utente mai loggato o ha fatto logout
      return 401; 
    }

    try { //c'è connessione a internet
      final body = {'refresh': refresh};
      final response = await http.post(Uri.parse(url), body: body);

      if (response.statusCode == 200) { // token valido (Login < 24h fa), Access Token aggiornato con successo
        // Token valido (< 24h) aggiornato con successo
        final decodedResponse = jsonDecode(response.body);
        await sp.setString('access', decodedResponse['access']);
        await sp.setString('refresh', decodedResponse['refresh']);
        return 200; 
      } else { // Token scaduto (Login > 24h) 
        await sp.remove('access');
        await sp.remove('refresh');
        return 401; 
      }
    } catch (e) { //nessuna connessione a internet o server IMPACT non raggiungibile
      
      print('Network Error (Offline): $e');
      return 500; 
    }
    
  } //_refreshTokens


  

  static Future<List<Training>?> getHistoricalExerciseData(DateTime startDate, DateTime endDate) async {
  List<Training> result = [];
  DateTime currentStart = startDate;
  
  //1. prendi l'access token da SharedPreferences
  final sp = await SharedPreferences.getInstance();
  var access = sp.getString('access');
 
  // 2.verifico che ci sia un access token salvato, altrimenti non posso fare richieste a IMPACT e ritorno null 
  if (access == null) { 
    print('No access token found. User might not be logged in.');
    return null; 
  }

  // 3. se access token è scaduto, refreshalo
  if(JwtDecoder.isExpired(access)){
    int refreshResult = await refreshTokens();
    if (refreshResult==200){
      access = sp.getString('access'); // prendo il nuovo access token appena salvato
      print('Access token refreshed successfully.');
    } else {
      print('Failed to refresh access token. Status code: $refreshResult');
      return null; // se non riesco a refreshare, significa che il refresh token è scaduto, ritorno null cosi l'utente viene reindirizzato al login
    }
  }
  // 4. fai richieste a blocchi di 7 giorni finché non arrivi alla data finale desiderata
  while (currentStart.isBefore(endDate) || currentStart.isAtSameMomentAs(endDate)) {
    // Aggiungo 6 giorni per avere un blocco di 7 giorni inclusivi
    DateTime currentEnd = currentStart.add(const Duration(days: 6)); 
    
    // Mi assicuro di non superare la data finale desiderata
    if (currentEnd.isAfter(endDate)) {
      currentEnd = endDate;
    }
    
    // Formatto le date in stringhe per la richiesta
    String chunkStartStr = DateFormat('yyyy-MM-dd').format(currentStart);
    String chunkEndStr = DateFormat('yyyy-MM-dd').format(currentEnd);
    print('Richiesta dati a IMPACT dal $chunkStartStr al $chunkEndStr...');
    // Url: /data/v1/exercise/patients/{username}/daterange/start_date/{start_date}/end_date/{end_date}/
    final url = '$baseUrl$exerciseDaterangeEndpoint$patientUsername/daterange/start_date/$chunkStartStr/end_date/$chunkEndStr/';
    final headers = {HttpHeaders.authorizationHeader: 'Bearer $access'};

    // 4. ottieni la risposta dal server
    final response = await http.get(Uri.parse(url), headers: headers);
    print('Response status: ${response.statusCode}');
  
    if (response.statusCode == 200) {
      // 5. faccio il parsing della risposta e ritorno i dati in formato training
      final decodedResponse = jsonDecode(response.body); // decodifico la risposta JSON
      for (var dayData in decodedResponse['data']) {  //itero su ogni giorno (se ci sono) in cui ci sono stati allenamenti
        String date = dayData['date']; // Prendo la data di questo specifico giorno
        // per ogni allenamento di quel giorno creo un oggetto Training e lo aggiungo alla lista dei risultati
        for (var exercise in dayData['data']) { //itero su ogni allenamento di quel giorno (se ci sono) e creo un oggetto Training, che aggiungo alla lista dei risultati
          result.add( Training.fromJson(date, exercise), );
        }//for
      }//for
    }//if
    currentStart = currentEnd.add(const Duration(days: 1)); // sposto la data di inizio del blocco al giorno dopo la fine del blocco attuale per evitare sovrapposizioni
  }//while
  return result;
  }//_getHistoricalExerciseData
  
}//ImpactService

