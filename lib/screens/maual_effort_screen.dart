import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/screens/HomePage.dart';
import 'package:provider/provider.dart';
import 'package:project_app/providers/TrainingProvider.dart';

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
    if (_formKey.currentState!.validate()) { //se i dati sono validi, procedo a salvarli
      double walkValue = double.parse(_walkController.text); // Converto il testo in double
      double bikeValue = double.parse(_bikeController.text);
      
    // 1. Chiamo il provider che salva le metriche su sp e provider
    await Provider.of<TrainingProvider>(context, listen: false)
          .setManualMetrics(walkValue, bikeValue);
    // 2. Imposto il permesso a false nel provider e nella sp
    await Provider.of<TrainingProvider>(context, listen: false)
          .changePermission(false); // Imposto il permesso a false
    
    // 3. Imposto already_logged come true nella sp
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('already_logged', true);

    if (!mounted) return;
    
    // 3. Vai alla HomePage
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
                    'Set the maximum distance you feel comfortable covering each day. We\'ll use these limits to split your routes into perfect stages.',
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 30),
                  
                  // Campo Walk
                  TextFormField(
                    controller: _walkController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Max Walk Effort (Km)',
                      hintText: 'Es: 15',
                      prefixIcon: const Icon(Icons.directions_walk),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter a value';
                      if (double.tryParse(value) == null) return 'Enter a valid number';
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Max Bike Effort (Km)',
                      hintText: 'Es: 50',
                      prefixIcon: const Icon(Icons.directions_bike),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter a value';
                      if (double.tryParse(value) == null) return 'Enter a valid number';
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
                      child: const Text('SAVE AND CONTINUE', style: TextStyle(color: Colors.white, fontSize: 16)),
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