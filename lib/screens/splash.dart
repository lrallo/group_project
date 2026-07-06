import 'package:flutter/material.dart';
import 'package:project_app/screens/LoginPage.dart';
import 'package:project_app/screens/HomePage.dart';
import 'package:project_app/services/impact_service.dart';
import 'package:project_app/providers/TrainingProvider.dart';
import 'package:provider/provider.dart';


class Splash extends StatelessWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () => _checkRefresh(context));
    return Scaffold(
        body: Center(
            child: Image.asset(
      'assets/logo_smartstage.png',
      scale: 4,
    )));
  }

  
  // Method for checking if the user has still valid tokens (refresh token scaduto o mai fatto il login)
  void _checkRefresh(BuildContext context) async {
    final result = await ImpactService.refreshTokens(); // provo a fare il refresh


    if (result == 200) { // CASO 1: ONLINE E LOGIN < 24h fa: Andiamo in HomePage caricando i dati
      
      await Provider.of<TrainingProvider>(context, listen: false).loadLocalMetrics(); 
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
      
    } else if (result == 401) { // CASO 2: ONLINE ma MAI LOGGATO O LOGIN > 24h fa: Andiamo in LoginPage
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: ((context) => LoginPage())));
    

    } else { // CASO 3: OFFLINE ma utente già loggato
      // 1. carico le metriche dalla sp
      await Provider.of<TrainingProvider>(context, listen: false).loadLocalMetrics();
      if (!context.mounted) return;
      // 2. avviso l'utente che è offline e che i dati non sono aggiornati
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WARNING: Couldn\'t sync latest fitness tracker data. Go to Settings to manually update metrics.'),
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          duration: Duration(seconds: 5),
        ),
      );
      // 3. reindirizzo alla HomePage, anche se i dati non sono aggiornati
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
      
      
    }
  }

}



