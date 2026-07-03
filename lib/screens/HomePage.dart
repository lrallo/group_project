import 'package:flutter/material.dart';
import 'package:project_app/screens/trainingBody.dart';
import 'package:project_app/screens/tripsBody.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/screens/LoginPage.dart';
import 'package:provider/provider.dart';
import 'package:project_app/providers/TrainingProvider.dart';
import 'package:project_app/providers/TripProvider.dart';
import 'package:project_app/screens/settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePage> {
  int selectedIndex = 0; //inizializza l'indice selezionato a 0 (Training)
  String _nickname = "";

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _nickname = sp.getString('nickname') ?? "Viaggiatore"; // Fallback se non c'è
    });
  }
 

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
            selectedIndex == 0 ? 'I viaggi di $_nickname' : 'Allenamento',
            style: TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, ),
          ),
          backgroundColor: const Color(0xFF1B365D),
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),

      drawer: Drawer( 
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1B365D), 
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.account_circle, size: 60, color: Colors.white),
                  const SizedBox(height: 10),
                  Text('Ciao, $_nickname!', style: const TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),

            ListTile( 
              leading: const Icon(Icons.settings),
              title: const Text('Impostazioni'),
              onTap: () async { 
                // 1. chiudo il drawer prima di navigare alla pagina delle impostazioni
                Navigator.pop(context); 
                // 2. navigo alla pagina delle impostazioni 
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                // 3. quando torno alla HomePage, ricarico il nickname dalla sp, e rifaccio il setState
                _loadNickname(); 
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
            ),
        ],
      ),
    )
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
          // --Bottone NO --
          TextButton(
            child: const Text('No'),
            onPressed: () { // Chiudiamo l'alert dialog e torno alla HomePage senza fare nulla
              Navigator.of(dialogContext).pop(); 
            },
          ),

          // --Bottone YES --
          TextButton(
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              // 1. Chiudiamo l'alert dialog
              Navigator.of(dialogContext).pop();

              // 2. Svuotiamo i Provider (listen: false è OBBLIGATORIO nei bottoni)
              Provider.of<TrainingProvider>(context, listen: false).clearData();
              Provider.of<TripProvider>(context, listen: false).clearData();

              // 3. Accediamo alle SharedPreferences e PULIAMO TUTTO DEFINITIVAMENTE
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