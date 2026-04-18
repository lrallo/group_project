import 'package:flutter/material.dart';



class TrainingBody extends StatelessWidget {
  const TrainingBody({super.key});  //inizializzo semplicemente con 'SchermataSearch()'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Sfondo leggermente grigio per far risaltare le card
      appBar: AppBar(
        title: const Text(
          'PROFILO ALLENAMENTO',
          style: TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, ),
        ),
        backgroundColor: const Color(0xFF1B365D), // Blu scuro del design
        centerTitle: true,
        elevation: 0,
      ),

      body: SingleChildScrollView( //rende il suo child (Padding) scorrevole
        child: Padding(
          padding: const EdgeInsets.all(16.0), //lascia uno spazio di 16 in tutti i lati
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, //ordina ai children di occupare tutta la larghezza della colonna
            children: [
              _buildStatsCard(),
              const SizedBox(height: 20),
              _buildUploadCard(),
            ],
          ),
        ),
      )
    );
  } //build
}//TrainingBody


// Card principale con il livello di allenamento
  Widget _buildStatsCard() {
    return Card(  //crea un riquadro con gli angoli arrotondati
      elevation: 4, //profondita dell'ombra
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), //rotondità riquadro
      child: Padding( 
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0), //lascio spazio dai bordi del riquadro
        child: Column(
          children: [
            // Sostituisci questo Stack con un pacchetto come fl_chart per un vero grafico a ciambella
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: CircularProgressIndicator(
                    value: 0.7, // Esempio di riempimento
                    strokeWidth: 20,
                    backgroundColor: Colors.green[600],
                    color: const Color(0xFF1B365D),
                  ),
                ),
                const Icon(
                  Icons.directions_run,
                  size: 50,
                  color: Color(0xFF1B365D),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(    //n.b. parte che sarà NON STATICA, dipende dai dati caricati 
              "LIVELLO: MEDIO-ALTO",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "(Stima basata su attività passate)",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            //n.b. parte che sarà NON STATICA, dipende dai dati caricati 
            _buildStatRow("DISTANZA/SETT:", "85km"), 
            const SizedBox(height: 8),
            _buildStatRow("DISLIVELLO/SETT:", "1500m"),
          ],
        ),
      ),
    );
  }


  // creo un Widget per scrivere le statistiche tutte con lo stesso formato
  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Card inferiore per il caricamento dei dati  - PARTE NON STATICA !! qui ci sarà il collegamento al server e l'output verrà salvato nello stato dell'app
  Widget _buildUploadCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16), ),
      clipBehavior: Clip.antiAlias, //smussa i bordi (eliminabile)
      child: Column(
        children: [
          // Header blu scuro della card
          Container(
            width: double.infinity,
            color: const Color(0xFF1B365D),
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              "CARICA NUOVI DATI\nALLENAMENTO",
              textAlign: TextAlign.center,
              style: TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, ),
            ),
          ),

          // Area bottoni
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadButton(Icons.upload_file, "Fitbit", Color(0xFF1B365D) ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget riutilizzabile per i bottoni di upload
  Widget _buildUploadButton(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        // Logica per gestire l'upload del file o l'integrazione API
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
