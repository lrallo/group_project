import 'package:flutter/material.dart';
import '/screens/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/services/impact_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // libreria per jsdondecode
import 'package:project_app/screens/onboarding.dart';


class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);//costruttore
  // variabili
  static const routename = 'Login Page';
  
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ImpactService impact = ImpactService(); //instanzio Impact per poter usare i suoi metodi
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usiamo SingleChildScrollView per evitare errori quando appare la tastiera
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 50,
            bottom: 20,
          ),
          
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo app: 
              Image.asset('assets/logo_smartstage.png', height: 200),
              const SizedBox(height: 20),
              
              const Text('Welcome to your tailor-made sustainable travel assistant', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              
              const SizedBox(height: 40),
          
              // Campo Email
              TextField(
                controller: userController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: 'Username',
                  hintText: 'Enter your username',
                ),
              ),

              const SizedBox(height: 20),
          
              // Campo Password
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: 'Password',
                  hintText: 'Enter your password',
                ),
              ),
          
              const SizedBox(height: 40),
          
              // Bottone Login
              SizedBox(
                width: double.infinity, // Prende tutta la larghezza
                height: 55,
                child: ElevatedButton(
                  child: const Text('ACCEDI', style: TextStyle(fontSize: 16, color: Colors.white)),
                  
                  onPressed: () async {
                    
                    // check if credentials are correct
                    final result = await impact.getAndStoreTokens(userController.text, passwordController.text);
                    // If correct, store the username and password in SharedPreferences
                    // and navigate to the Exposure screen (pushReplacement to remove the login screen from the stack)
                    if (result == 200) {
                      final sp = await SharedPreferences.getInstance();
                      // SALVO LE CREDENZIALI DELL'UTENTE IN SHARED PREFERENCES 
                      await sp.setString('username', userController.text); 
                      await sp.setString('password', passwordController.text);

                      final onboarding_completed = await sp.getBool('onboarding_completed');
                      if(onboarding_completed == null || onboarding_completed == false){ // se l'onboarding non è mai stato fatto o non è stato completato
                        Navigator.pushReplacement( context, MaterialPageRoute( builder: (context) => Onboarding(), ),);
                      }else{ //l'onboarding era già stato completato
                        Navigator.pushReplacement( context, MaterialPageRoute( builder: (context) => const HomePage(), ), );}

                    } else {
                      // If incorrect, show a SnackBar with an error message
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.all(8),
                            duration: Duration(seconds: 2),
                            content:Text("username or password incorrect")
                            ));
                    }
                  },//onPressed
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),//style
                ),
              ),
              
              const SizedBox(height: 20),
              const Text(
                "Inserisci le tue credenziali per iniziare la sessione",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      
      ),
    );
  }
}


