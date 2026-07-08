import 'package:flutter/material.dart';
import 'package:project_app/screens/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/widgets/impact_dialog.dart';
import 'package:project_app/screens/maual_effort_screen.dart';
import 'package:project_app/providers/TrainingProvider.dart';
import 'package:provider/provider.dart';
import 'package:project_app/screens/LoginPage.dart';


class Onboarding extends StatefulWidget { 
  const Onboarding({Key? key}) : super(key: key);
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> { 
  final PageController _pageController = PageController(); 
  // instanza di un oggetto PageController che permette di controllare un istanza di PageView, un widget che permette di scorrere tra più pagine

  int _currentPage = 0; // indice della pagina corrente, variabile privata 

  final TextEditingController _nicknameController = TextEditingController(); 

  // Mappa con scritte e immagini per le pagine di onboarding
  final List<Map<String, String>> onboardingData = [
    {
      "title": "WELCOME TO SMARTSTAGE",
      "text": "Discover sustainable travel through multi-day trekking and cycling adventures",
      "image": "assets/onboarding_1.jpg" // Sostituisci con le tue illustrazioni
    },
    {
      "title": "CONNECT FITNESS TRACKER",
      "text": "Sync your fitness tracker or input your daily effort manually to get personalized stage recommendations.",
      "image": "assets/onboarding_2.jpg"
    },
    {
      "title": "PERSONALIZED STAGES",
      "text": "Upload your GPX file and let SmartStage split your journey into daily stages based on your effort level.",
      "image": "assets/onboarding_3.jpg"
    },
  ];


  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Limita la larghezza massima a 600 pixel

          child: SafeArea(
            child: Column(
              children: [
                // PARTE CENTRALE: Le pagine che scorrono
                Expanded( // Widget che prende tutto lo spazio disponibile, così il PageView occupa tutto lo spazio tra l'header e il footer
                  child: PageView.builder( // costruttore widget PageView (permette di scorrere tra più pagine)
            
                    controller: _pageController, //oggeto di PageController che permette di tenere conto di "dove" si trova l'utente nelle pagine
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (value) { 
                      // ogni volta che l'utente cambia pagina, aggiorno lo stato del widget con l'indice della pagina corrente
                      setState(() {
                        _currentPage = value; 
                      });
                    }, 
                    itemCount: onboardingData.length, // numero di pagine 
                    itemBuilder: (context, index) { // --- COSTRUTTORE DELLE PAGINE ---
                      return SingleChildScrollView(
                        child: Padding(
                            padding: EdgeInsets.only(
                              left: 24.0,
                              right: 24.0,
                              top: 10.0,
                              // Se la tastiera è aperta, aggiunge spazio sotto, altrimenti aggiunge 20 pixel
                              bottom: MediaQuery.of(context).viewInsets.bottom + 20.0, 
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start, // Allinea gli elementi partendo dall'alto
                              children: [
                                
                                const SizedBox(height: 20), // Un piccolo margine superiore
                          
                                // 1. TITOLO IN ALTO
                                Text(
                                  onboardingData[index]["title"]!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24, // Font size ingrandito (prima era 24)
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B365D),
                                    height: 1.2, // Migliora la spaziatura tra le righe se il titolo va a capo
                                  ),
                                ),
                                
                                const SizedBox(height: 20),
                          
                                // 2. IMMAGINE CENTRALE   
                               ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 250), // Altezza MASSIMA
                                child: Center(
                                  child: Image.asset(
                                    onboardingData[index]["image"]!,
                                    fit: BoxFit.contain, // l'immagine mantenga le proporzioni
                                  ),
                                ),
                              ),
                                
                                const SizedBox(height: 20),
                          
                                // 3. TESTO DESCRITTIVO SOTTO L'IMMAGINE
                                Text(
                                  onboardingData[index]["text"]!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    height: 1.4,
                                  ),
                                ),
                                
                                const SizedBox(height: 25),
                                
                                // 4. TESTO in basso (Mostrato solo nella prima pagina)
                                if (index == 0)
                                  TextField(   
                                    controller: _nicknameController, // controller, variabile che salva il testo inserito
                                    decoration: InputDecoration( // stile del campo di testo
                                      labelText: 'What\'s your nickname?', // Etichetta del campo
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.person),
                                      // Opzionale: un hint se vuoi guidare l'utente
                                      hintText: 'Enter your nickname',
                                    ),
                                  ),
                                  
                                // Se non devo mostarare il TextField della prima pagina, aggiungo un margine inferiore per uniformità
                                if (index != 0) const SizedBox(height: 10), 
                              ],
                            ),
                          ),
            
                      );
                    },
                  ),
                ),
                
                // PARTE INFERIORE: Pallini e Pulsanti SKIP / NEXT / START
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, //allineo in modo che il primo widget sia a sinistra e l'ultimo a destra, e gli altri siano distribuiti uniformemente
                    children: [
            
                      // Bottone SKIP (Mostrato solo se non siamo all'ultima pagina)
                      _currentPage == onboardingData.length - 1
                          ? const SizedBox(width: 50) // se siamo all'ultima pagina
                          : TextButton(
                            onPressed: () {
                              // Se siamo sulla prima pagina e il testo è vuoto, fermati
                              if (_currentPage == 0 && _nicknameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Enter a nickname to continue!')),
                                );
                                return; // non permette di saltare l'onboarding senza inserire il nickname
                              }
                              _finishOnboarding();
                            },
                            child: const Text('Skip', style: TextStyle(color: Colors.grey)),
                          ),
                      
                      // PALLINI (Dots Indicator)
                      Row(
                        children: List.generate( // lista di pallini, uno per ogni pagina
                          onboardingData.length,
                          (index) => buildDot(index, context),
                        ),
                      ),
            
                      // Bottone START / NEXT
                      _currentPage == onboardingData.length - 1
                          ? ElevatedButton( // se siamo all'ultima pagina, mostro il bottone "START"
                              onPressed: _finishOnboarding, // Avvia la logica finale
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B365D),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('START', style: TextStyle(color: Colors.white)),
                            )
                          : TextButton( // se non siamo all'ultima pagina, mostro il bottone "Next"
                            onPressed: () {
                              // Validazione manuale e diretta
                              if (_currentPage == 0 && _nicknameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Enter a nickname to continue!')),);
                                return; 
                                }
            
                              _pageController.nextPage( // passa alla pagina successiva 
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn, // animazione
                              );
                            },
                            child: const Text('Next', style: TextStyle(color: Color(0xFF1B365D), fontWeight: FontWeight.bold)),
                          ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  

  // Funzione finale che salva il nome e chiama IMPACT
  Future<void> _finishOnboarding() async {
    String nickname = _nicknameController.text.trim();
    
    // 1. Salvo il nickname 
    final sp = await SharedPreferences.getInstance();
    await sp.setString('nickname', nickname);
    
    if (!mounted) return; 

    // 2. Apro il dialog per chiedere il permesso di accedere ai dati IMPACT
    await showImpactPermissionDialog(
      context: context,
      onSuccess: () async { //utente schiaccia SI e .getTrainignData da 200
        
        await sp.setBool('already_logged', true); // imposto already_logged come true
        Provider.of<TrainingProvider>(context, listen: false).changePermission(true);// aggiorno variabile della sp e del provider
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
      },
      onError: (status) async { // utente schiaccia si ma .getTrainingData restituisce 401 o 500
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fitness tracker session expired, please check your internet connection and log in again.'), backgroundColor: Colors.red),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
      },
      onDecline: () async {// utente schiaccia NO
        Provider.of<TrainingProvider>(context, listen: false).changePermission(false); //aggiorno la variabile della sp e del provider
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ManualEffortScreen()));
      }
    );
  }


  // Widget helper per disegnare i pallini
  Container buildDot(int index, BuildContext context) {
    return Container(
      height: 10,
      width: _currentPage == index ? 25 : 10, // Se la pagina in cui ci troviamo è quella di questo pallino, il pallino è più largo
      margin: const EdgeInsets.only(right: 5),// distanza tra i pallini
      decoration: BoxDecoration( // stile visivo
        borderRadius: BorderRadius.circular(20),
        color: _currentPage == index ? const Color(0xFF1B365D) : Colors.grey.shade300,
      ),
    );
  }
}