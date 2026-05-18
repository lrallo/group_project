import 'package:shared_preferences/shared_preferences.dart';

// Chiama questa funzione quando vuoi controllare i dati 
// (ad esempio associandola a un bottone temporaneo o nell'initState)
Future<void> printAllSharedPreferences() async {
  print('--- INIZIO LETTURA SHARED PREFERENCES ---');
  
  final sp = await SharedPreferences.getInstance(); // dizionario chiave-valore 
  final keys = sp.getKeys(); // Recupera tutte le chiavi salvate

  if (keys.isEmpty) {
    print('Le SharedPreferences sono vuote.');
  } else {
    for (String key in keys) {
      // sp.get(key) recupera il valore della rispettiva chiave
      print('Chiave: $key | Valore: ${sp.get(key)}'); 
    }
  }
  
  print('--- FINE LETTURA SHARED PREFERENCES ---');
}



Future<void> printTokens() async {
  final sp = await SharedPreferences.getInstance();
  String? accessToken = sp.getString('access_token');
  String? refreshToken = sp.getString('refresh_token');

  print('Access Token: $accessToken');
  print('Refresh Token: $refreshToken');
}