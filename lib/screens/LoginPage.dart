import 'package:flutter/material.dart';
import '/screens/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/services/impact_service.dart';
import 'package:project_app/screens/onboarding.dart';
import 'package:project_app/providers/TrainingProvider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key); //costruttore
  // variabili
  static const routename =
      'Login Page'; // variabile statica che permette di identificare la pagina, utile per la navigazione tra le pagine

  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // oggetto di tipo TextEditingController che permette di controllare il testo inserito dall'utente nel campo username
  // permette di leggere in ogni momento il testo inserito dall'utente

  final ImpactService impact =
      ImpactService(); //instanzio Impact per poter usare i suoi metodi

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            // EdgeInsets.only permette di specificare padding diversi per ogni lato
            left: 24.0,
            right: 24.0,
            top: 50,
            bottom: 20,
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment
                .center, //allineo i widget al centro della colonna
            children: [
              // Logo app:
              Image.asset('assets/logo_smartstage.png', height: 200),
              const SizedBox(height: 20),

              const Text(
                'Welcome to your tailor-made sustainable travel assistant',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),

              const SizedBox(height: 40),

              // Campo Email
              TextField(
                // widget che permette di inserire testo e salvarlo
                controller:
                    userController, // instanza di TextEditingController che permette di leggere il testo inserito dall'utente, e dare un errore se l'utente non inserisce nulla o un formato diverso dal testo
                decoration: InputDecoration(
                  // stile del campo di testo
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
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
                  child: const Text(
                    'LOGIN',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),

                  onPressed: () async {
                    // --- CONTROLLO CHE I PULSANTI SIANO COMPILATI ---
                    if (userController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            content: Text("You must enter credentials!"), // Il messaggio in inglese che volevi
                          ),
                        );
                      return; // Esce dalla funzione senza fare la chiamata al server
                    }
                    // ---------------------------------

                    // 1. chiedo i token a Impact
                    final result = await ImpactService.getAndStoreTokens(
                      userController.text,
                      passwordController.text,
                    ); 
                    
                    // 2. accedo alla sp e controllo se è il primo login
                    final sp = await SharedPreferences.getInstance();
                    final alreadyLogged = sp.getBool('already_logged');

                    // ==========================================
                    // CASO 1: UTENTE ONLINE E CREDENZIALI CORRETTE
                    // ==========================================
                    if (result == 200) { 
                      
                      if (alreadyLogged == null || alreadyLogged == false) { // Primo accesso in assoluto -> Onboarding
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Onboarding()));
                        
                      } else { // utente loggato > 24 h fa, aggiorno metriche,  --> HomePage
  
                        int status = await Provider.of<TrainingProvider>(context, listen: false).updateMetrics();

                        if (status == 200) {
                          // Aggiornamento ok -> HomePage
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
                        } else { 
                          // Aggiornamento fallito (e.g. Offline o Server Error) -> HomePage con avviso
                          await Provider.of<TrainingProvider>(context, listen: false).loadLocalMetrics();
                          
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..removeCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text("Network glitch: couldn't sync new data. Loading your offline metrics."),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
                        }
                      }
                    } 
                    // ==========================================
                    // CASO 2: CREDENZIALI ERRATE
                    // ==========================================
                    else if (result == 401) {
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            content: Text("Username or password incorrect"),
                          ),
                        );
                    } 
                    // ==========================================
                    // CASO 3: OFFLINE (ERRORE 500)
                    // ==========================================
                    else { 
                      if (alreadyLogged == true) { 
                        // Utente Loggato > 24h fa ma offline, carico vecchie metriche, alert, --> HomePage
                        await Provider.of<TrainingProvider>(context, listen: false).loadLocalMetrics();
                        
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..removeCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 4),
                              content: Text("You are offline. Proceeding with your last saved metrics."),
                            ),
                          );
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
                        
                      } else {
                        // Nuovo utente ma offline --> alert, rimane in LoginPage
                        ScaffoldMessenger.of(context)
                          ..removeCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 3),
                              content: Text("You are offline. An internet connection is required for your first login."),
                            ),
                          );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ), //style
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Enter your fitness tracker credentials to begin your journey with SmartStage.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
