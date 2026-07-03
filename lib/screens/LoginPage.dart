import 'package:flutter/material.dart';
import '/screens/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/services/impact_service.dart';
import 'package:project_app/screens/onboarding.dart';
import 'package:project_app/providers/TrainingProvider.dart';
import 'package:provider/provider.dart';



class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);//costruttore
  // variabili
  static const routename = 'Login Page'; // variabile statica che permette di identificare la pagina, utile per la navigazione tra le pagine
  
  final TextEditingController userController = TextEditingController(); 
  final TextEditingController passwordController = TextEditingController();
  // oggetto di tipo TextEditingController che permette di controllare il testo inserito dall'utente nel campo username
  // permette di leggere in ogni momento il testo inserito dall'utente
  
  final ImpactService impact = ImpactService(); //instanzio Impact per poter usare i suoi metodi
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea( 
        child: Padding(
          padding: const EdgeInsets.only( // EdgeInsets.only permette di specificare padding diversi per ogni lato
            left: 24.0,
            right: 24.0,
            top: 50,
            bottom: 20,
          ),
          
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, //allineo i widget al centro della colonna
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
              TextField( // widget che permette di inserire testo e salvarlo
                controller: userController, // instanza di TextEditingController che permette di leggere il testo inserito dall'utente, e dare un errore se l'utente non inserisce nulla o un formato diverso dal testo
                decoration: InputDecoration( // stile del campo di testo
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
          
              // BOTTONE LOGIN
              SizedBox(
                width: double.infinity, // Prende tutta la larghezza disponibile
                height: 55,
                child: ElevatedButton(
                  child: const Text('ACCEDI', style: TextStyle(fontSize: 16, color: Colors.white)),
                  
                  onPressed: () async {
                    
                    // 1. chiedo i token a Impact, usando le credenziali, e li salvo nella sp
                    final result = await ImpactService.getAndStoreTokens(userController.text, passwordController.text); // userController.text contiene il testo inserito dall'utente
                    
                    
                    if (result == 200) {
                      // 2. accedo alla sp
                      final sp = await SharedPreferences.getInstance();
                      // 3. controllo se è il primo login
                      final alreadyLogged = await sp.getBool('already_logged'); 
                      
                      if(alreadyLogged==null ){ // se è il PRIMO LOGIN dell'utente
                        Navigator.pushReplacement( context, MaterialPageRoute( builder: (context) => Onboarding(), ),);

                      }else if (alreadyLogged==true){ // se l'utente si era già loggato, ma ultimo accesso + di 24h fa, riaggiorno i dati impact

                        int status = await Provider.of<TrainingProvider>(context, listen: false).updateImpactMetrics();

                        if (status==200){ //aggiornamento andato a buon fine
                          Navigator.pushReplacement( context, MaterialPageRoute( builder: (context) => const HomePage(), ), );
                        }else{
                          ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.all(8),
                            duration: Duration(seconds: 2),
                            content:Text("An error occurred, please try again later")
                            ));
                        }

                        }else{ //se alreadyLogged==false per qualche strano motivo, mando all'Onboarding
                        Navigator.pushReplacement( context, MaterialPageRoute( builder: (context) => Onboarding(), ),);

                        }
                        

                    } else if (result == 401) {
                      // se le credenziali sono errate
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.all(8),
                            duration: Duration(seconds: 2),
                            content:Text("username or password incorrect")
                            ));
                    
                    } else {
                      // se c'è un errore generico
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.all(8),
                            duration: Duration(seconds: 2),
                            content:Text("An error occurred, please try again later")
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


