// file: lib/widgets/chart_card.dart
// file: lib/widgets/chart_card.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, double>? dataMap;
  final Color barColor;

  const ChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.dataMap,
    required this.barColor,
  });

  // NUOVA FUNZIONE: Crea l'intestazione con l'icona nel riquadro colorato
  Widget _buildHeader() {
    return Row(
      children: [
        // Riquadro pastello per l'icona (stile uniformato con TrainingBody)
        Container(
          padding: const EdgeInsets.all(8), // Spazio interno tra l'icona e il bordo del riquadro
          decoration: BoxDecoration(
            color: barColor.withOpacity(0.15), // Usa il colore specifico (arancione o verde)
            borderRadius: BorderRadius.circular(10), // Angoli arrotondati
          ),
          child: Icon(icon, color: barColor, size: 20), // Icona colorata
        ),
        const SizedBox(width: 12),
        Expanded(
          // FITTEDBOX PROTEGGE IL TITOLO SE È TROPPO LUNGO
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // Font rimpicciolito
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Caso 1: Se non ci sono dati, mostriamo un messaggio vuoto
    if (dataMap == null || dataMap!.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(), // Inseriamo la nuova intestazione
              const SizedBox(height: 30),
              const Center(
                child: Text("Nessuna attività registrata in questo periodo.", style: TextStyle(color: Colors.grey))
              ),
            ],
          ),
        ),
      );
    }

    // Caso 2: Abbiamo dati. Ordino cronologicamente le date
    List<String> sortedDates = dataMap!.keys.toList()..sort();
    
    // Genero i dati per le barre
    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 0; i < sortedDates.length; i++) {
      double yValue = dataMap![sortedDates[i]]!;
      if (yValue > maxY) maxY = yValue;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: yValue,
              color: barColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        )
      );
    }

    // Aggiungo un piccolo buffer sull'asse Y per estetica
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 10;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeader(), // Inseriamo la nuova intestazione anche qui
            const SizedBox(height: 30),
            
            SizedBox(
              height: 200, 
              width: double.infinity,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    
                    // --- ASSE Y (Sinistra) - Teniamo i km rimpiccioliti ---
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45, 
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4, 
                            child: Text(
                              "${value.toInt()} km", 
                              style: const TextStyle(fontSize: 9, color: Colors.blueGrey) 
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // --- ASSE X (Sotto) ----
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false, 
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY / 4) > 0 ? (maxY / 4) : 1,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}