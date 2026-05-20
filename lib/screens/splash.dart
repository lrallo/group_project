import 'package:flutter/material.dart';
import 'package:project_app/screens/LoginPage.dart';
import 'package:project_app/screens/HomePage.dart';
import 'package:project_app/services/impact_service.dart';


class Splash extends StatelessWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () => _checkLogin(context));
    return Scaffold(
        body: Center(
            child: Image.asset(
      'assets/logo_smartstage.png',
      scale: 4,
    )));
  }

  
  // Method for checking if the user has still valid tokens (refresh token scaduto o mai fatto il login)
  void _checkLogin(BuildContext context) async {
    final result = await ImpactService.refreshTokens();
    if (result == 200) { // se il refresh token NON è scaduto
      Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
    } else {            // se il refresh token è scaduto, o non c'è (l'utente non ha mai fato login), richiedi le credenziali, per chiedere nuovi token
      Navigator.of(context) 
        .pushReplacement(MaterialPageRoute(builder: ((context) => LoginPage())));
    }
  } //_checkLogin

}



