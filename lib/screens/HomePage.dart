import 'package:flutter/material.dart';
import 'package:project_app/screens/trainingBody.dart';
import 'package:project_app/screens/tripsBody.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/screens/LoginPage.dart';
import 'package:project_app/screens/profile.dart';
import 'package:provider/provider.dart';
import 'package:project_app/providers/TrainingProvider.dart';
import 'package:project_app/providers/TripProvider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePage> {
  int selectedIndex = 0; //inizializza l'indice selezionato a 0 (Training)

  // List of pages
  final List<Widget> pages = [
    Tripsbody(),
    TrainingBody(),
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
            icon: Icon(Icons.terrain_outlined),
            selectedIcon: Icon(Icons.terrain),
            label: "Trips",
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: "Training",
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
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color(0xFF1B365D), // Blu scuro
              ),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),

            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Profile()));
              },
            ),

            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                // 1. Chiudiamo prima il Drawer laterale per fare pulizia a schermo
                Navigator.pop(context); // tolgo dlla stack del navigator il Drawer, in questo modo si chiude il Drawer e vedo la HomePage, invece di vedere il Drawer sovrapposto alla LoginPage dopo il logout
                // 2. Mostriamo il pop-up di conferma
                _showLogoutConfirmation(context);
              },
            ),
          ],//children
          ),)
    );
  }
}

void _showLogoutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Conferma Logout'),
        content: const Text('Sei sicuro di voler uscire? Tutti i tuoi dati locali verranno cancellati.'),
        actions: [
          // Bottone NO
          TextButton(
            child: const Text('No'),
            onPressed: () {
              // Se l'utente schiaccia 'No', chiudiamo semplicemente il dialog e torniamo alla HomePage senza fare altre azioni
              Navigator.of(dialogContext).pop(); 
            },
          ),
          // Bottone YES
          TextButton(
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              // 1. Chiudiamo l'alert dialog
              Navigator.of(dialogContext).pop();

              // 2. Svuotiamo i Provider (listen: false è OBBLIGATORIO nei bottoni)
              Provider.of<TrainingProvider>(context, listen: false).clearData();
              Provider.of<TripProvider>(context, listen: false).clearData();

              // 3. Accediamo alle SharedPreferences e puliamo tutto
              final sp = await SharedPreferences.getInstance();
              await sp.clear(); 

              // 4. Controllo di sicurezza prima di usare il context dopo un 'await'
              if (!context.mounted) return;

              // 5. Reindirizziamo alla LoginPage cancellando tutta la cronologia
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginPage()), 
                (Route<dynamic> route) => false
              );
            },
          ),
        ],
      );
    },
  );
}