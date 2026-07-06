import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ElevationProfileChart extends StatelessWidget {
  final List<double> distanceProfile;
  final List<double> elevationProfile;
  final List<double> cutDistances;
  final int? selectedStageIndex; // <-- NUOVO PARAMETRO

  const ElevationProfileChart({
    super.key,
    required this.distanceProfile,
    required this.elevationProfile,
    required this.cutDistances,
    this.selectedStageIndex, // <-- AGGIUNTO AL COSTRUTTORE
  });

  @override
  Widget build(BuildContext context) {
    if (distanceProfile.isEmpty || elevationProfile.isEmpty) {
      return const SizedBox.shrink(); 
    }

    // --- LOGICA DI CALCOLO DEL TRATTO DA EVIDENZIARE ---
    List<FlSpot> highlightSpots = [];
    
    if (selectedStageIndex != null) {
      // Calcoliamo dove inizia e finisce la tappa in termini di chilometri (Asse X)
      // Sfruttiamo il vettore cutDistances che contiene i punti di taglio
      double startKm = 0.0;
      double endKm = double.infinity;

      if (selectedStageIndex == 0) {
        // Tappa 1: parte da 0 km e arriva al primo taglio
        startKm = 0.0;
        endKm = cutDistances.isNotEmpty ? cutDistances[0] : double.infinity;
      } else {
        // Tappe intermedie/finali: partono dal taglio precedente
        startKm = cutDistances[selectedStageIndex! - 1];
        // Se non è l'ultima tappa, finiscono al taglio successivo, altrimenti vanno fino alla fine (infinity)
        endKm = selectedStageIndex! < cutDistances.length 
            ? cutDistances[selectedStageIndex!] 
            : double.infinity;
      }

      // Filtriamo i punti globali prendendo solo quelli che cadono nel range della tappa selezionata
      for (int i = 0; i < distanceProfile.length; i++) {
        if (distanceProfile[i] >= startKm && distanceProfile[i] <= endKm) {
          highlightSpots.add(FlSpot(distanceProfile[i], elevationProfile[i]));
        }
      }
    }
    // ---------------------------------------------------

    return Container(
      height: 180, 
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
      color: Colors.white,
      child: LineChart(
        LineChartData(
          // --- AGGIUNGI QUESTO BLOCCO PER COMPORTAMENTO ED ETICHETTE AL TOCCO ---
          lineTouchData: LineTouchData(
            enabled: true, // Attiva esplicitamente l'interazione al tocco/scorrimento
            handleBuiltInTouches: true, // Gestisce in automatico il drag del dito
            touchTooltipData: LineTouchTooltipData(
              // Puoi cambiare lo sfondo del quadratino che appare al tocco
              getTooltipColor: (LineBarSpot touchedSpot) => const Color(0xFF1B365D).withOpacity(0.9),
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  // Personalizziamo il testo dentro il pop-up quando l'utente scorre
                  return LineTooltipItem(
                    'Distanza: ${touchedSpot.x.toStringAsFixed(1)} km\n',
                    const TextStyle(color: Colors.white, fontSize: 12),
                    children: [
                      TextSpan(
                        text: 'Elevation: ${touchedSpot.y.toStringAsFixed(0)} m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            // Personalizzazione della linea verticale che segue il dito durante lo scorrimento
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((spotIndex) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: const Color(0xFF4A7C59), // Colore della linea verticale di tracciamento
                    strokeWidth: 2,
                  ),
                  FlDotData(
                    show: true, // Mostra un pallino sulla linea altimetrica dove si trova il dito
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 6,
                      color: const Color(0xFF1B365D),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                );
              }).toList();
            },
          ),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          
          extraLinesData: ExtraLinesData(
            verticalLines: cutDistances.map((cutDist) {
              return VerticalLine(
                x: cutDist,
                color: Colors.grey.withOpacity(0.4), // Linee di taglio più discrete
                strokeWidth: 1.5,
                dashArray: [5, 5],
              );
            }).toList(),
          ),

          // LISTA DELLE LINEE DA DISEGNARE
          lineBarsData: [
            // 1. LINEA DI SFONDO (Tutto il viaggio completo)
            LineChartBarData(
              spots: List.generate(distanceProfile.length, (index) {
                return FlSpot(distanceProfile[index], elevationProfile[index]);
              }),
              isCurved: true,
              // Se c'è qualcosa evidenziato, spegniamo un po' lo sfondo (opacità 0.3) altrimenti resta normale
              color: selectedStageIndex != null 
                  ? const Color(0xFF4A7C59).withOpacity(0.3) 
                  : const Color(0xFF4A7C59),
              barWidth: 2.5,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: selectedStageIndex == null, // Mostra l'ombra sotto solo se non stiamo evidenziando nulla
                color: const Color(0xFF4A7C59).withOpacity(0.1),
              ),
            ),

            // 2. LINEA DI HIGHLIGHT (Appare solo se highlightSpots ha elementi)
            if (highlightSpots.isNotEmpty)
              LineChartBarData(
                spots: highlightSpots,
                isCurved: true,
                color: Colors.orangeAccent, // Colore acceso per l'effetto "illuminato"
                barWidth: 5, // Più spessa per l'effetto "in rilievo"
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                shadow: const Shadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3), // Crea un effetto di sollevamento 3D
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.orangeAccent.withOpacity(0.2), // Bagliore sotto la tappa selezionata
                ),
              ),
          ],
        ),
      ),
    );
  }
}