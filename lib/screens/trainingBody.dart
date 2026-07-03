import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_app/providers/TrainingProvider.dart'; 
import 'package:project_app/widgets/chart_card.dart'; // Importa il nuovo widget!

class TrainingBody extends StatelessWidget {
  const TrainingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], 
      body: Consumer<TrainingProvider>(
        builder: (context, provider, child) {
          
          if (provider.isLoading) {
             return const Center(child: CircularProgressIndicator(color: Color(0xFF1B365D)));
          }

          final metrics = provider.userMetrics;

          if (metrics == null) {
            return const Center(
              child: Text("Nessun dato di allenamento disponibile.\nVai nelle Impostazioni.")
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Titolo e Colore dinamici in base alla provenienza dei dati
                _buildTitleCard(
                  provider.impactPermission ? "Dati Analizzati da IMPACT" : "Metriche Manuali", 
                  provider.impactPermission ? Colors.green : Colors.orange
                ),
                const SizedBox(height: 20),

                // 2. Questa Card si vede SEMPRE (sia in manuale che con IMPACT)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(Icons.directions_walk, "${metrics.maxWalkEffortKm.toStringAsFixed(1)} km", "Max daily trekking effort"),
                        _buildStatItem(Icons.directions_bike, "${metrics.maxBikeEffortKm.toStringAsFixed(1)} km", "Max daily bike effort"),
                      ],
                    ),
                  ),
                ),
                
                // 3. Sezioni aggiuntive visibili SOLO se IMPACT è attivo
                if (provider.impactPermission) ...[
                  const SizedBox(height: 40),
                  
                  // Titolo per il riassunto
                  const Text(
                    "Workout summary", 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B365D))
                  ),
                  const SizedBox(height: 20),
                  
                  // Grafici (ora usano il widget esterno)
                  ChartCard(
                    title: "Walked Km (Last 30 days)", 
                    icon: Icons.directions_walk, 
                    dataMap: metrics.dailyWalkEffort,
                    barColor: Colors.green
                  ),
                  const SizedBox(height: 20),
                  
                  ChartCard(
                    title: "Cycled Km (Last 30 days)", 
                    icon: Icons.directions_bike, 
                    dataMap: metrics.dailyBikeEffort,
                    barColor: Colors.blue
                  ),
                  const SizedBox(height: 40),
                ]
              ],
            ),
          );
        },
      )
    );
  }

  Widget _buildTitleCard(String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Text(
        title, 
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 40, color: const Color(0xFF1B365D)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B365D))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}