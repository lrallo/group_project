import 'package:flutter/material.dart';
import 'package:project_app/screens/trainingBody.dart';
import 'package:project_app/screens/tripsBody.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/screens/LoginPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePage> {
  int selectedIndex = 0; //inizializza l'indice selezionato a 0 (Training)

  // List of pages
  final List<Widget> pages = [
    TrainingBody(),
    Tripsbody(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,

        // When user taps an item
        onDestinationSelected: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },

        destinations: [
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: "Training",
          ),
          NavigationDestination(
            icon: Icon(Icons.terrain_outlined),
            selectedIcon: Icon(Icons.terrain),
            label: "Trips",
          ),
        ],
      ),

      appBar: AppBar(
          title: Text(
            selectedIndex == 0 ? 'MY TRAINING' : 'MY TRIPS',
            style: TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, ),
          ),
          backgroundColor: const Color(0xFF1B365D), // Blu scuro
          centerTitle: true,
          elevation: 0,
        ),

      drawer: Drawer( 
        child:ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(child: Text('Menu')),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () => _toLoginPage(context),
            ),
          ],//children
          ),)
    );
  }
}

void _toLoginPage(BuildContext context) async {
  final sp = await SharedPreferences.getInstance(); //accedo alla memoria

  await sp.remove('isUserLogged'); //rimuovo la chiave isUserLogged dalla memoria, in questo modo alla prossima apertura dell'app l'utente non sarà più loggato
  
  Navigator.pop(context); //torno alla pagina precedente (LoginPage)
  Navigator.of( context).pushReplacement( //sostituisco la pagina corrente (HomePage) con la LoginPage, in questo modo l'utente non potrà tornare alla HomePage premendo il tasto indietro
    MaterialPageRoute(builder: (context) => LoginPage()),
  );
}