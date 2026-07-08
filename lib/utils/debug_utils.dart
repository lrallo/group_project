import 'package:shared_preferences/shared_preferences.dart';       

// Funzione usata solo per ispezionare il contenuto della shearpreference quando era necessario durante il debug
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


 