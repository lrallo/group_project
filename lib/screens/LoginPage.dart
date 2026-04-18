import 'package:flutter/material.dart';
import '/screens/HomePage.dart';

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);//costruttore
  // variabili
  static const routename = 'Login Page';
  final TextEditingController passwordController=TextEditingController(); // istanzio una variabile di classe TextEditingController
  final TextEditingController emailController=TextEditingController(); // final: è una variabile creata durante l'esecuzione dell'app
  static const String correctEmail = 'admin';
  static const String correctPassword = '1234'; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usiamo SingleChildScrollView per evitare errori quando appare la tastiera
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
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
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  labelText: 'Email',
                  hintText: 'esempio@mail.it',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Campo Password
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
              const SizedBox(height: 40),

              // Bottone Login
              SizedBox(
                width: double.infinity, // Prende tutta la larghezza
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ACCEDI', style: TextStyle(fontSize: 16, color: Colors.white)),
                  onPressed: () {
                    if (emailController.text == correctEmail && passwordController.text == correctPassword) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  HomePage()));  // creo la HomePage solo se sia psw che gmail sono giusto
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Credenziali errate! Riprova.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
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