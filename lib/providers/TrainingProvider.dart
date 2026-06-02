// file: lib/providers/TrainingProvider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:project_app/algorithms/performance_analyzer.dart';
import 'package:project_app/services/impact_service.dart';
import 'package:project_app/models/training.dart';  
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/models/performanceMetrics.dart';

class TrainingProvider extends ChangeNotifier { 
  PerformanceMetrics? userMetrics; 
  bool _isLoading = false;
  bool get isLoading => _isLoading; 

  Future<int> getTrainingData() async {
    _isLoading = true;
    notifyListeners();

    try {
      DateTime endDate = DateTime.now().subtract(const Duration(days: 1)); 
      DateTime startDate = endDate.subtract(const Duration(days: 60)); 
      
      List<Training>? rawData = await ImpactService.getHistoricalExerciseData(startDate, endDate);
      
      if (rawData == null) return 401; 

      // Generazione metriche
      userMetrics = PerformanceAnalyzer.analyze(rawData);

      // Salvataggi critici per l'app offline e il TripProvider
      final sp = await SharedPreferences.getInstance();
      await sp.setDouble('maxWalk', userMetrics!.maxWalkEffortKm); //km di camminata sostenibile in un giorno di viaggio a tappe
      await sp.setDouble('maxBike', userMetrics!.maxBikeEffortKm);
      await sp.setInt('analysisWindow', userMetrics!.analysisWindowDays);
      await sp.setInt('activeDays', userMetrics!.activeDays);
      await sp.setString('fitnessLevel', userMetrics!.fitnessLevel);
      await sp.setString('dailyWalkMap', jsonEncode(userMetrics!.dailyWalkEffort));//salvo la mappa giorno->km di camminata per mostrare i dettagli all'utente, e per eventuali calcoli futuri
      await sp.setString('dailyBikeMap', jsonEncode(userMetrics!.dailyBikeEffort));
      print('\n---- Metriche salvate nella memoria locale (SharedPreferences) ----');
      return 200; 
      
    } catch (e) {
      print('Errore critico in getTrainingData: $e');
      return 500;
    } finally {
      _isLoading = false;
      notifyListeners();
    } 
  } 

  void clearData() {
    userMetrics = null;
    _isLoading = false;
    notifyListeners();
  }
}