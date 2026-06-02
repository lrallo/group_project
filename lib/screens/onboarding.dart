import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_app/screens/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/utils/debug_utils.dart'; // importa la funzione per stampare tutte le SharedPreferences
import 'package:provider/provider.dart';
import 'package:project_app/providers/TrainingProvider.dart';
import 'package:project_app/screens/maual_effort_screen.dart';
import 'package:project_app/screens/LoginPage.dart';

class Onboarding extends StatefulWidget {
  Onboarding({Key? key}) : super(key: key);

  @override
  State<Onboarding> createState() => _OnboardingState();
}


class _OnboardingState extends State<Onboarding> {
 
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = sp.getString('name') ?? '';
      _surnameController.text = sp.getString('surname') ?? ''; 
      _dateController.text = sp.getString('dob') ?? ''; 
      _selectedGender = sp.getString('gender'); 
    });
  }

  // Funzione per mostrare il date picker e aggiornare il campo data
  Future<void> _selectDate(BuildContext context) async {
  DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime(2000),
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),);
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });}
  }

  Future<void> _setOnboardingCompleted() async {
  final sp = await SharedPreferences.getInstance();
  await sp.setBool('onboarding_completed', true);
  }

  // funzione che salva i dati dell'onboarding e mostra il pop-up per la sincronizzazione con IMPACT
  Future<void> _submitForm() async { 
    if (_formKey.currentState!.validate()) { // se il form è valido
    // 1. Salvo i dati dell'onboarding nella SharedPreferences
      final sp = await SharedPreferences.getInstance();
      await sp.setString('name', _nameController.text);
      await sp.setString('surname', _surnameController.text);
      await sp.setString('gender', _selectedGender!);
      await sp.setString('dob', _dateController.text);
      await sp.setBool('onboarding_completed', true);
      printAllSharedPreferences();// stampo tutte le SharedPreferences per debug
      
    // 2. Mostro il pop-up per chiedere l'autorizzazione a IMPACT
      await _showImpactPermissionDialog(context);
    }
  }


  Future<void> _showImpactPermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Impedisce la chiusura cliccando fuori
      builder: (BuildContext dialogContext) {
        // Usiamo un flag locale per gestire il caricamento DENTRO il pop-up
        bool isFetching = false; 

        return StatefulBuilder( // widget che ci permette di aggiornare lo stato SOLO del dialog senza rifare il build dell'intera pagina
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Accesso ai dati IMPACT'),
              
              // Se isFetching è true, mostriamo la rotella. Altrimenti il testo normale.
              content: isFetching
                  ? const Column(
                      mainAxisSize: MainAxisSize.min, // Adatta l'altezza al contenuto
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Sincronizzazione dati in corso...'),
                      ],
                    )
                  : const Text(
                      'Vuoi permettere all\'app di accedere ai tuoi dati di allenamento dal server IMPACT per personalizzare la tua esperienza?'),
              
              
              actions: isFetching
                  ? []        // se stiamo scaricando (iFetching=true), non mostriamo bottoni
                  : <Widget>[
                      TextButton(
                        child: const Text('No'),
                        onPressed: () {
                          // 1. chiude il dialog
                          Navigator.of(dialogContext).pop(); 
                          // 2. naviga alla schermata Manual Effort
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ManualEffortScreen()),
                          );
                        },
                      ),
                      TextButton(
                        child: const Text('Sì'),
                        onPressed: () async {
                          // 1. Modifichiamo lo stato del DIALOG per mostrare il caricamento
                          setDialogState(() {
                            isFetching = true;
                          });
                          // 2. Chiamiamo il provider (che sotto il cofano imposterà anche il suo _isLoading)
                          int status = await Provider.of<TrainingProvider>(context, listen: false).getTrainingData();
                          
                          // 3. Controllo sicurezza (buona pratica Flutter) 
                          // Deve essere fatto prima di usare context per navigare
                          if (!context.mounted) return;

                          // 4. Chiudo il pop-up di caricamento 
                          Navigator.of(dialogContext).pop();

                          // 5. Gestiamo la navigazione in base all'esito UNA SOLA VOLTA
                          if (status == 200) {
                            print('Dati iniziali caricati con successo al primo avvio!');
                            Navigator.pushReplacement( 
                              context, 
                              MaterialPageRoute(builder: (context) => const HomePage()) 
                            );
                          } else if (status == 401) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sessione scaduta. Effettua il login di nuovo.'), backgroundColor: Colors.orange),
                            );
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => LoginPage()), 
                              (Route<dynamic> route) => false 
                            ); 
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Errore di connessione a IMPACT. Potrai sincronizzare i dati più tardi.. Riprova.'), backgroundColor: Colors.red),
                            );
                            Navigator.pushReplacement( 
                              context, 
                              MaterialPageRoute(builder: (context) => const ManualEffortScreen()) 
                            );
                          }
                        },
                      ),
                    ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SafeArea widget to avoid system UI overlaps
      body: SafeArea(
        child: Stack(
          children: [Padding(
            padding: const EdgeInsets.all(
                16.0),
            child: 
            SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                
                // import the logo image from assets folder (make sure to add the folder in pubspec.yaml)
                Image.asset(
                  'assets/logo_smartstage.png',
                  scale: 4,
                  ),
                const SizedBox(
                      height: 30,
                    ),
                    
                const Text(
                  'Let\'s know you better',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 30),
                ),
                const SizedBox(
                  height: 25,
                ),
                
                Form(
                  key: _formKey,
                  child: Column(
                    children:[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelText: 'Name',
                          hintText: 'Enter your name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      
                      TextFormField(
                        controller: _surnameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelText: 'Surname',
                          hintText: 'Enter your surname',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your surname';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),

                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Sex', border: OutlineInputBorder()),
                        value: _selectedGender,
                        items: ['M', 'F', 'Other'].map((gender){
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedGender = value),
                        validator: (value) => value == null ? 'Choose gender' : null,
                      ),
                      const SizedBox(
                        height: 20,
                      ),

                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: InputDecoration(labelText: 'Date of birth', border: OutlineInputBorder()),
                        onTap: () => _selectDate(context),
                        validator: (value) => value == null || value.isEmpty ? 'Pick a date' : null,
                        
                      ),
                      
                      SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _submitForm, // quando premo "Save", salvo i dati e mostro il pop-up per la sincronizzazione con IMPACT
                        child: Text('Save'),
                      ),
                    ]),
                ),   
                ],
                ),    
              ),
            ),

            Positioned(
              bottom: 16,
              right: 16,
              child: TextButton(
                onPressed: () async {
                  // 1. Imposto onboarding_completed a true per saltare l'onboarding in futuro
                  await _setOnboardingCompleted(); // imposto onboarding_completed a true per saltare l'onboarding in futuro
                  // 2. Stampo il contenuto della SharedPreferences per debug
                  await _showImpactPermissionDialog(context);
                },
                child: Text(
                  'Skip',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
                  ),]
        ),
      ),);
  }
}




