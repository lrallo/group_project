import 'package:flutter/material.dart';
import 'package:project_app/services/impact_service.dart';
import 'package:project_app/models/training.dart';  
import 'package:intl/intl.dart';




// --- CHANGE NOTIFIER  --- 
class TrainingProvider extends ChangeNotifier { 
  List<Training> trainings = [];  // DB delle sessioni di addestramento caricati 
  
  

  void getTrainingData() async {

     // 1. prendo la data di ieri
    DateTime showDate = DateTime.now().subtract(const Duration(days: 1)); //prendo la data di ieri
    String formattedDate = DateFormat('yyyy-MM-dd').format(showDate);

    print('Getting data of $formattedDate');
    // 2. mostro una schermata di caricamento (non implementata in questo snippet, ma si può fare con un booleano isLoading e un CircularProgressIndicator)
    
    // 3. prendo il training usando ImpactService
    trainings = await ImpactService.getExerciseData(formattedDate); // prendi il training del giorno 1 giugno 2024 (questo è un esempio, poi si dovrà prendere il training del giorno corrente)

    // altri passaggi per calcolare le performance dell'utente

    // Notifico
    notifyListeners();
    } 
  }
  // 1. prende il training usando ImpactService
  // 2 lo trasforma in un oggetto Training e calcola le performance dell'utente
  // 2. aggiungi il training alla lista dei training del provider
  // 3. notifica i listener, in modo che le schermate (Consumer) si aggiornino con il nuovo livello di performance dell'utente

