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

  @override
  Widget build(BuildContext context) {
    // Se non ci sono dati, mostriamo un messaggio vuoto
    if (dataMap == null || dataMap!.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF1B365D)),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 30),
              const Text("Nessuna attività registrata in questo periodo.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Ordino cronologicamente le date
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
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1B365D)),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
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
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text("${value.toInt()} km", style: const TextStyle(fontSize: 10, color: Colors.grey));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < sortedDates.length) {
                            String dateStr = sortedDates[index];
                            List<String> parts = dateStr.split('-');
                            if (parts.length == 3) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text("${parts[2]}/${parts[1]}", style: const TextStyle(fontSize: 10)),
                              );
                            }
                          }
                          return const Text('');
                        },
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