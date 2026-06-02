// file: lib/screens/trainingBody.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_app/providers/TrainingProvider.dart'; 
import 'package:project_app/utils/debug_utils.dart'; 
import 'package:project_app/screens/LoginPage.dart'; 

class TrainingBody extends StatelessWidget {
  const TrainingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], 
      body: SingleChildScrollView( 
        child: Padding(
          padding: const EdgeInsets.all(16.0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              _buildStatsCard(context), // Passiamo il context per leggere il Provider
              const SizedBox(height: 20),
              _buildUploadCard(context),
            ],
          ),
        ),
      )
    );
  }

  // Card con Statistiche Reali
  Widget _buildStatsCard(BuildContext context) {
    // Osserviamo i cambiamenti del Provider
    final provider = Provider.of<TrainingProvider>(context);
    final metrics = provider.userMetrics;

    return Card(
      elevation: 4, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
      child: Padding( 
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0), 
        child: metrics == null 
        ? _buildEmptyState() // Se i dati non sono stati ancora scaricati
        : Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: CircularProgressIndicator(
                    // Mostriamo la "costanza": quanto è stato attivo? (es. 4 giorni su 10 = 0.4)
                    value: metrics.activeDays / metrics.analysisWindowDays, 
                    strokeWidth: 20,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF1B365D),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fitness_center, size: 30, color: Color(0xFF1B365D)),
                    Text(
                      "${metrics.activeDays}/${metrics.analysisWindowDays}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Text("Giorni Attivi", style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(    
              "PROFILO: ${metrics.fitnessLevel.toUpperCase()}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
            ),
            const SizedBox(height: 4),
            Text(
              "Le tue stime di Endurance per i viaggi:",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            
            // Plottiamo le stime di endurance ("Quanti km al giorno riesci a sopportare")
            _buildStatRow("Max a Piedi / Tappa:", "${metrics.maxWalkEffortKm.toStringAsFixed(1)} km"), 
            const SizedBox(height: 8),
            _buildStatRow("Max in Bici / Tappa:", "${metrics.maxBikeEffortKm.toStringAsFixed(1)} km"),
          ],
        ),
      ),
    );
  }

  // Widget mostrato quando non ci sono dati caricati nello stato
  Widget _buildEmptyState() {
    return const Column(
      children: [
        Icon(Icons.query_stats, size: 80, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          "Nessun dato di allenamento in memoria.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          "Usa il pulsante qui sotto per sincronizzare IMPACT.",
          textAlign: TextAlign.center,
        )
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distanzia le scritte
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildUploadCard(BuildContext context) {
    // [IL CODICE RIMANE IDENTICO A PRIMA]
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16) ),
      clipBehavior: Clip.antiAlias, 
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF1B365D),
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              "CARICA NUOVI DATI\nALLENAMENTO",
              textAlign: TextAlign.center,
              style: TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16 ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadButton(context, Icons.sync, "Sincronizza", const Color(0xFF1B365D)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context, IconData icon, String label, Color color) {
    // Gestione del caricamento con rotella integrata nel pulsante (Opzionale)
    final isLoading = Provider.of<TrainingProvider>(context).isLoading;

    return InkWell(
      onTap: isLoading ? null : () async {
         int status = await Provider.of<TrainingProvider>(context, listen: false).getTrainingData();
          if (status == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dati caricati e analizzati!'), backgroundColor: Colors.green),
            );
          } else if (status == 401) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sessione scaduta. Effettua il login di nuovo.'), backgroundColor: Colors.orange),);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginPage()), 
              (Route<dynamic> route) => false
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Errore nel caricamento. Riprova.'), backgroundColor: Colors.red),);
          }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLoading ? Colors.grey[300] : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isLoading ? Colors.grey : color, width: 2),
            ),
            child: isLoading 
              ? const SizedBox(height: 30, width: 30, child: CircularProgressIndicator())
              : Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isLoading ? Colors.grey : color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}