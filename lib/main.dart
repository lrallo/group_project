import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/screens/LoginPage.dart';
import '/providers/DBTrips_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/screens/HomePage.dart';


void main() {
  runApp(MyApp());
} //main

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DBtrips(),
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 60, 54, 244)),
          useMaterial3: true,
        ),
        home: FutureBuilder(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {

            if (snapshot.hasData) { //se sono stati caricati i dati
              final sp = snapshot.data!; //accedo alla memoria

              if (sp.getBool('isUserLogged') != null ) { //se è presente la chiave isUserLogged significa che l'utente ha già effettuato il login, mando direttamente nella homepage
                return HomePage();
              } else { //se l'utente non ha già effettuato il login in precedenza
                return LoginPage();

              } //if-else

            }else{ //se i dati non sono stati caricati
              return Scaffold( 
                body: Center(
                  child: CircularProgressIndicator()),
              );
            }
                
          
          },
        )
      ),
    );
  } //build
}//MyApp