import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ImpactService{

  static String baseUrl = 'https://impact.dei.unipd.it/bwthw/';
  static String pingEndpoint = 'gate/v1/ping/';
  static String tokenEndpoint = 'gate/v1/token/';
  static String refreshEndpoint = 'gate/v1/refresh/';

  static String stepsEndpoint = 'data/v1/steps/patients/';

  static String patientUsername = 'Jpefaq6m58';


  Future<int> getAndStoreTokens(String username, String password ) async {

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
  Future<int> refreshTokens() async {
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


  


}//Impact