import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_app/providers/TrainingProvider.dart'; 
import 'package:project_app/widgets/chart_card.dart'; 

class TrainingBody extends StatelessWidget {
  const TrainingBody({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold è l'impalcatura base di una pagina visiva.
    return Scaffold(
      backgroundColor: Colors.grey[100], // Sfondo grigio chiaro per far risaltare le Card bianche
      
      // Consumer si "sintonizza" sul TrainingProvider. 
      // Quando nel provider chiami notifyListeners(), SOLO la UI dentro questo builder si ricarica, 
      // risparmiando batteria e risorse rispetto a ricaricare l'intera app.
      body: Consumer<TrainingProvider>(
        builder: (context, provider, child) {
          
          // STATO 1: Caricamento in corso
          if (provider.isLoading) {
             return const Center(child: CircularProgressIndicator(color: Color(0xFF1B365D)));
          }

          final metrics = provider.userMetrics;

          // STATO 2: Nessun dato (l'utente non ha impostato nulla)
          if (metrics == null) {
            return const Center(
              child: Text("No activity data available.\nGo to Settings to update.", textAlign: TextAlign.center)
            );
          }

          // STATO 3: Dati presenti. 
          // SingleChildScrollView permette alla pagina di scorrere (scroll) in verticale
          // se lo schermo del telefono è troppo piccolo per mostrare tutto.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            
            // Column ordina i suoi "figli" (children) uno sotto l'altro.
            child: Column(
              // crossAxisAlignment.stretch obbliga tutti i figli ad allargarsi per riempire tutta la larghezza dello schermo.
              crossAxisAlignment: CrossAxisAlignment.stretch, 
              children: [
                const SizedBox(height: 5), // SizedBox crea uno spazio vuoto (in questo caso alto 10 pixel)
                
                // 1. Badge di stato (Il riquadro a pillola centrale)
                _buildStatusBadge(
                  provider.impactPermission ? "Fitness Tracker Connected" : "Manual Activity Limits", 
                  provider.impactPermission ? Colors.green : const Color(0xFF1B365D)
                ),
                const SizedBox(height: 15),

                // 2. Titolo Descrittivo
                const Text(
                  "Your maximum daily distances:", 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B365D))
                ),
                const SizedBox(height: 15),

                // 3. ROW PER LE DUE CARD (Camminata e Bici)
                // Row ordina i figli da sinistra a destra sulla stessa riga.
                Row(
                  children: [
                    // Expanded è fondamentale nelle Row: dice al widget figlio di "espandersi"
                    // prendendosi tutto lo spazio disponibile. Avendo due Expanded uguali, si dividono lo schermo al 50%.
                    Expanded(
                      // Card crea un riquadro bianco con una leggera ombra (elevation) dietro.
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        // Padding aggiunge spazio vuoto INTERNAMENTE, in modo che il contenuto non tocchi i bordi della Card.
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                          child: _buildStatItem(
                            Icons.directions_walk, 
                            "${metrics.maxWalkEffortKm.toStringAsFixed(1)} km", 
                            "By walk",
                            Colors.orange, // Colore assegnato alla camminata
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16), // Spazio orizzontale tra le due Card
                    
                    // Seconda Card (Bici) con il suo Expanded
                    Expanded(
                      child: Card(
                        elevation: 4, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                          child: _buildStatItem(
                            Icons.directions_bike, 
                            "${metrics.maxBikeEffortKm.toStringAsFixed(1)} km", 
                            "By bike",
                            const Color(0xFF4A7C59), // Colore assegnato alla bici
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // 4. SEZIONE GRAFICI 
                if (provider.impactPermission) ...[
                  const SizedBox(height: 40),
                  
                  const Text(
                    "Workout summary:", 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B365D))
                  ),
                  const SizedBox(height: 20),
                  
                  ChartCard(
                    title: "Walked Km (Last 30 days)", 
                    icon: Icons.directions_walk, 
                    dataMap: metrics.dailyWalkEffort,
                    barColor: Colors.orange // Colore coerente per la camminata
                  ),
                  const SizedBox(height: 20),
                  
                  ChartCard(
                    title: "Cycled Km (Last 30 days)", 
                    icon: Icons.directions_bike, 
                    dataMap: metrics.dailyBikeEffort,
                    barColor: const Color(0xFF4A7C59) // Colore coerente per la bici
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

  // FUNZIONE HELPER: Genera il badge "a pillola" al centro
  Widget _buildStatusBadge(String title, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        // BoxDecoration ci permette di impostare colori di sfondo, angoli arrotondati e bordi di un Container.
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), // Rende il colore molto trasparente per lo sfondo
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)) // Bordo dello stesso colore ma un po' più scuro
        ),
        // mainAxisSize.min dice alla Row di NON allargarsi per tutto lo schermo, 
        // ma di abbracciare strettamente l'icona e il testo.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title, 
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)
            ),
          ],
        ),
      ),
    );
  }

  // FUNZIONE HELPER: Genera la stat interna (Icona + Numero + Testo)
  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        // Container che fa da quadrato pastello dietro l'icona
        Container(
          width: 60,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 32, color: color),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1B365D))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
      ],
    );
  }
}