import 'package:flutter/material.dart';
import 'package:project_app/screens/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/widgets/impact_dialog.dart';
import 'package:project_app/screens/maual_effort_screen.dart';
import 'package:project_app/providers/TrainingProvider.dart';
import 'package:provider/provider.dart';


class Onboarding extends StatefulWidget { 
  const Onboarding({Key? key}) : super(key: key);
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> { 
  final PageController _pageController = PageController(); 
  // instanza di un oggetto PageController che permette di controllare un istanza di PageView, 
  // un widget che permette di scorrere tra più pagine

  int _currentPage = 0; // indice della pagina corrente

  final TextEditingController _nicknameController = TextEditingController(); 

  // Mappa con scritte e immagini per le pagine di onboarding
  final List<Map<String, String>> onboardingData = [
    {
      "title": "WELCOME TO SMARTSTAGE",
      "text": "Discover sustainable travel through multi-day trekking and cycling adventures",
      "image": "assets/onboarding_1.jpg" // Sostituisci con le tue illustrazioni
    },
    {
      "title": "KNOW YOUR LEVEL",
      "text": "Connect your training data or input your daily effort to get personalized stage recommendations.",
      "image": "assets/onboarding_2.jpg"
    },
    {
      "title": "PERSONALIZED STAGES",
      "text": "Upload your GPX file and let SmartStage split your journey into daily stages based on your effort level.",
      "image": "assets/onboarding_3.jpg"
    },
  ];


  // Funzione finale che salva il nome e chiama IMPACT
  Future<void> _finishOnboarding() async {

    String nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      nickname = "Viaggiatore"; // Fallback di sicurezza
    }
    // 1. Salvo il nickname 
    final sp = await SharedPreferences.getInstance();
    await sp.setString('nickname', nickname);
    
    if (!mounted) return; //se !mounted è true, significa che l'utente ha chiuso la pagina di onboarding prima che la funzione finisse, 
    // dico a flutter di non fare più setState o navigazioni, altrimenti crasha l'app

    // imposto already_logged come true
    await sp.setBool('already_logged', true);
    
    // 2. Apro il dialog per chiedere il permesso di accedere ai dati IMPACT
    await showImpactPermissionDialog(
      context: context,
      onSuccess: () async { //utente schiaccia SI e .getTrainignData da 200
        Provider.of<TrainingProvider>(context, listen: false).changePermission(true);// aggiorno variabile della sp e del provider
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
      },
      onError: () async { //utente schiaccia SI ma .getTrainignData un errore diverso da 401
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore connessione a IMPACT.'), backgroundColor: Colors.red),
        );
        Provider.of<TrainingProvider>(context, listen: false).changePermission(false);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ManualEffortScreen()));
      },
      onDecline: () async {// utente schiaccia NO
        Provider.of<TrainingProvider>(context, listen: false).changePermission(false); //aggiorno la variabile della sp e del provider
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ManualEffortScreen()));
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // PARTE CENTRALE: Le pagine che scorrono
            Expanded( // Widget che prende tutto lo spazio disponibile, così il PageView occupa tutto lo spazio tra l'header e il footer
              child: PageView.builder( // costruttore widget PageView (permette di scorrere tra più pagine)
                controller: _pageController, //oggeto di PageController che permette di tenere conto di "dove" si trova l'utente nelle pagine
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) { // funzione chiamata ogni volta che lo scorrimento termina e la pagina cambia, value=indice della pagina diventata visibile
                  // ogni volta che l'utente cambia pagina, aggiorno lo stato del widget con l'indice della pagina corrente
                  setState(() {
                    _currentPage = value; 
                  });
                }, 
                itemCount: onboardingData.length, // numero di pagine 
                itemBuilder: (context, index) { // costruttore di ogni pagine, dato l'indice
                  return Padding(
                    padding: const EdgeInsets.all(70.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start, // Allinea gli elementi partendo dall'alto
                      children: [
                        
                        const SizedBox(height: 30), // Un piccolo margine superiore

                        // 1. TITOLO IN ALTO
                        Text(
                          onboardingData[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32, // Font size ingrandito (prima era 24)
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B365D),
                            height: 1.2, // Migliora la spaziatura tra le righe se il titolo va a capo
                          ),
                        ),
                        
                        const SizedBox(height: 40),

                        // 2. IMMAGINE CENTRALE   (Expanded= "prendi tutto lo spazio che rimane")
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              onboardingData[index]["image"]!,
                              fit: BoxFit.contain, // Mantiene le proporzioni rendendola il più grande possibile
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),

                        // 3. TESTO DESCRITTIVO SOTTO L'IMMAGINE
                        Text(
                          onboardingData[index]["text"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // 4. TESTO in basso (Mostrato solo nella prima pagina)
                        if (index == 0)
                          TextField(
                            controller: _nicknameController, // controller
                            decoration: InputDecoration( // stile del campo di testo
                              labelText: 'Come ti chiami?',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.person),
                              // Opzionale: un hint se vuoi guidare l'utente
                              hintText: 'Inserisci il tuo nickname',
                            ),
                          ),
                          
                        // Se non devo mostarare il TextField della prima pagina, aggiungo un margine inferiore per uniformità
                        if (index != 0) const SizedBox(height: 30), 
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // PARTE INFERIORE: Pallini e Bottoni
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
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
                              const SnackBar(content: Text('Inserisci un nickname per continuare!')),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('START', style: TextStyle(color: Colors.white)),
                        )
                      : TextButton( // se non siamo all'ultima pagina, mostro il bottone "Next"
                        onPressed: () {
                          // Validazione manuale e diretta
                          if (_currentPage == 0 && _nicknameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Inserisci un nickname per continuare!')),
                            );
                            return; 
                          }
                          
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
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
    );
  }

  // Widget helper per disegnare i pallini
  Container buildDot(int index, BuildContext context) {
    return Container(
      height: 10,
      width: _currentPage == index ? 25 : 10, // Si allunga se è la pagina corrente
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _currentPage == index ? const Color(0xFF1B365D) : Colors.grey.shade300,
      ),
    );
  }
}