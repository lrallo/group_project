import 'package:flutter/material.dart';

class Tripsbody extends StatelessWidget {
  const Tripsbody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'I MIEI VIAGGI SALVATI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF1B365D), // Blu scuro
        centerTitle: true,
        elevation: 0,
      ),
      // Mostriamo direttamente la lista senza TabBarView
      body: _buildViaggiList(),
    );
  }

  // Costruisce la lista principale
  Widget _buildViaggiList() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildNuovoViaggioCard(),
        const SizedBox(height: 20),
        _buildTripCard("Giro delle Dolomiti", "150km | +3000m", Colors.green[800]!),
        const SizedBox(height: 12),
        _buildTripCard("Via Francigena", "220km | +4500m", Colors.brown[400]!),
        const SizedBox(height: 12),
        _buildTripCard("Via Francigena", "220km | +4500m", Colors.brown[400]!),
        const SizedBox(height: 12),
        _buildTripCard("Via Francigena", "220km | +4500m", Colors.brown[400]!),
      ],
    );
  }

  // Card per l'upload del GPX 
  Widget _buildNuovoViaggioCard() {
    return InkWell(
      onTap: () {
        // Logica per aprire il file picker e passare alla schermata 3
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1B365D), // Blu scuro
            width: 2,
            style: BorderStyle.solid, 
          ),
        ),
        child: const Column(
          children: [
            Text(
              "NUOVO VIAGGIO",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Icon(
              Icons.upload_file,
              size: 40,
              color: Color(0xFF1B365D),
            ),
            SizedBox(height: 12),
            Text(
              "Carica file GPX per dividere\nun nuovo percorso",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card per i singoli viaggi già salvati
  Widget _buildTripCard(String title, String stats, Color imageColorPlaceholder) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            // Immagine segnaposto
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 70,
                height: 50,
                color: imageColorPlaceholder,
                child: const Icon(
                  Icons.landscape,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}