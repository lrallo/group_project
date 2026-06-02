import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/screens/HomePage.dart';

class ManualEffortScreen extends StatefulWidget {
  const ManualEffortScreen({Key? key}) : super(key: key);

  @override
  State<ManualEffortScreen> createState() => _ManualEffortScreenState();
}

class _ManualEffortScreenState extends State<ManualEffortScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _walkController = TextEditingController();
  final TextEditingController _bikeController = TextEditingController();

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      final sp = await SharedPreferences.getInstance();
      
      // Salviamo i dati inseriti dall'utente
      await sp.setDouble('maxWalkEffortKm', double.parse(_walkController.text));
      await sp.setDouble('maxBikeEffortKm', double.parse(_bikeController.text));
      
      // Ora l'onboarding è completato definitivamente
      await sp.setBool('onboarding_completed', true);

      if (!mounted) return;
      
      // Andiamo alla HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Manuale'),
        backgroundColor: const Color(0xFF1B365D),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Poiché non hai collegato IMPACT, inserisci i tuoi parametri di sforzo massimo per personalizzare l\'app:',
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 30),
                  
                  // Campo Walk
                  TextFormField(
                    controller: _walkController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: 'Max Walk Effort (Km)',
                      hintText: 'Es: 15',
                      prefixIcon: const Icon(Icons.directions_walk),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Inserisci un valore';
                      if (double.tryParse(value) == null) return 'Inserisci un numero valido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Campo Bike
                  TextFormField(
                    controller: _bikeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: 'Max Bike Effort (Km)',
                      hintText: 'Es: 50',
                      prefixIcon: const Icon(Icons.directions_bike),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Inserisci un valore';
                      if (double.tryParse(value) == null) return 'Inserisci un numero valido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B365D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)
                        ),
                      ),
                      onPressed: _saveAndContinue,
                      child: const Text('SALVA E INIZIA', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}