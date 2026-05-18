import 'package:flutter/material.dart';




// --- CHANGE NOTIFIER  --- 
class TrainingProvider extends ChangeNotifier { 
  // ? List<Training> TrainingList = [];  // DB delle sessioni di addestramento caricati 
  // ? List<Performance> PerformanceList = []; // DB delle performance dell'utente, calcolate a partire dai training caricati, che serviranno per personalizzare i viaggi consigliati all'utente
  // creo una lista con tutti i training caricati

  // ? Future<bool> addTraining() async { 
  // 1. prende il training usando ImpactService
  // 2 lo trasforma in un oggetto Training e calcola le performance dell'utente
  // 2. aggiungi il training alla lista dei training del provider
  // 3. notifica i listener, in modo che le schermate (Consumer) si aggiornino con il nuovo livello di performance dell'utente
}
