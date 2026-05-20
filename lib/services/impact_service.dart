import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:io';
import 'package:project_app/models/training.dart';

class ImpactService{

  static String baseUrl = 'https://impact.dei.unipd.it/bwthw/';
  static String pingEndpoint = 'gate/v1/ping/';
  static String tokenEndpoint = 'gate/v1/token/';
  static String refreshEndpoint = 'gate/v1/refresh/';
  static String exerciseEndpoint = 'data/v1/exercise/patients/';
  

  static String patientUsername = 'Jpefaq6m58';


  static Future<int> getAndStoreTokens(String username, String password ) async {

    //Create the request
    final url = ImpactService.baseUrl + ImpactService.tokenEndpoint;
    final body = {'username': username, 'password': password};

    //Get the response
    print('Calling: $url');
    final response = await http.post(Uri.parse(url), body: body);

    //If response is OK, decode it and store the tokens. Otherwise do nothing.
    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('access', decodedResponse['access']);
      await sp.setString('refresh', decodedResponse['refresh']);
    } //if

    //Just return the status code
    return response.statusCode;
  } //_getAndStoreTokens
  
  
  
  //This method allows to refresh the stored JWT in SharedPreferences
  static Future<int> refreshTokens() async {
    //Create the request
    final url = ImpactService.baseUrl + ImpactService.refreshEndpoint;
    final sp = await SharedPreferences.getInstance();
    final refresh = sp.getString('refresh');
    if (refresh != null) {
      final body = {'refresh': refresh};

      // 1. Get the response
      print('Calling: $url');
      final response = await http.post(Uri.parse(url), body: body);

      //If the response is OK, set the tokens in SharedPreferences to the new values
      if (response.statusCode == 200) {
        // 2. Decode the response and store the new tokens in SharedPreferences
        final decodedResponse = jsonDecode(response.body);
        final sp = await SharedPreferences.getInstance();
        await sp.setString('access', decodedResponse['access']);
        await sp.setString('refresh', decodedResponse['refresh']);
      } //if

      //Just return the status code
      return response.statusCode;
    }
    return 401;
  } //_refreshTokens


  static Future<List<Training>> getExerciseData(String day) async {
    List<Training> result = [];
    //1. prendi l'access token da SharedPreferences
    final sp = await SharedPreferences.getInstance();
    var access = sp.getString('access');

    //2. se access token è scaduto, refreshalo
    if(JwtDecoder.isExpired(access!)){
      await ImpactService.refreshTokens();
      access = sp.getString('access');
    }//if

    //3. ottieni la risposta dal server
    final url = ImpactService.baseUrl + ImpactService.exerciseEndpoint + ImpactService.patientUsername + '/day/${day}/';
    final headers = {HttpHeaders.authorizationHeader: 'Bearer $access'};

    print('Calling: $url');
    final response = await http.get(Uri.parse(url), headers: headers);
    
    
    
    if (response.statusCode == 200) {
      // 4. faccio il parsing della risposta e ritorno i dati in formato training
      print('Response: ${response.body}');
      final decodedResponse = jsonDecode(response.body);
      for (var i = 0; i < decodedResponse['data']['data'].length; i++) { //itero su ciascun allenamento della giornata
        result.add( //aggiungo alla lista trainings un nuovo oggetto Training, usando il costruttore fromJson definito nel modello
          Training.fromJson(
            decodedResponse['data']['date'],
            decodedResponse['data']['data'][i],
          ),
        );
      } //for
    } //if

    //Return the result
    print(' ');
    print('Returning ${result.length} trainings');
    for (var training in result) {
      print(training.toString());
    }
    return result;

  } //_getTrainingData
}//Impact