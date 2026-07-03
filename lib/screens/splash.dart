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


    if (result == 200) { // se il refresh token NON è scaduto, l'utente avevafatto il login meno di 24h fa
      // carico le metriche dalla sp al provider
      await Provider.of<TrainingProvider>(context, listen: false).loadLocalMetrics(); 
      if (!context.mounted) return;
      Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
     
    } else {            // se il refresh token è scaduto (utente aveva fatto il login da + di 24h), o non c'è (l'utente non ha mai fato login), richiedi le credenziali, per chiedere nuovi token
      Navigator.of(context) 
        .pushReplacement(MaterialPageRoute(builder: ((context) => LoginPage())));
    }
  } //_checkLogin

}



