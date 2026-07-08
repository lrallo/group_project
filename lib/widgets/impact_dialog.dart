import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_app/providers/TrainingProvider.dart';

// Funzione async che mostra un dialog per chiedere all'utente il permesso
Future<void> showImpactPermissionDialog({
  // INPUT della funzione:
  required BuildContext context,   // context della pagina da cui viene chiamata la funzione, serve per dire a Flutter dove mostrare il dialog

  // CALLBACKS della funzione:
  required VoidCallback onSuccess, // funzione da eseguire se l'utente accetta di dare il permesso
  required Function(int) onError,   // funzione da eseguire se .getTrainingData restituisce 401 o 500
  required VoidCallback onDecline, // funzione da eseguire se l'utente rifiuta di dare il permesso
}) 

async {
  return showDialog<void>( // Funzione nativa di Flutter che dice a Flutter di oscurare lo sfondo della pagina corrente e di "spingere" sopra lo schermo una nuova area vuota in cui comparirà qualcosa.
    context: context,
    barrierDismissible: false, // Impedisce la chiusura cliccando fuori
    builder: (BuildContext dialogContext) { // parametro che richiede uan funzione che ritorni un Widget da mostrare nell'area del dialog
      bool isFetching = false; // variabile che indica se stiamo scaricando i dati IMPACT, inizialmente è false

      return StatefulBuilder( //permette di aggiornare solo lo stato del dialog (il pop-up), senza dover aggiornare tutta la pagina
        builder: (context, setDialogState) {
          return AlertDialog( // widget che mostra un dialog (pop-up) con titolo, contenuto e bottoni
            title: const Text('Connect Fitness Tracker'), // titolo del dialog
            content: isFetching // TRUE: se stiamo scaricando i dati, mostriamo un indicatore di caricamento, altrimenti mostriamo il messaggio di richiesta permesso
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF1B365D)),
                      SizedBox(height: 16),
                      Text('Syncing data from your fitness tracker...'),
                    ],
                  )
                : const Text(  // FALSE: se non stiamo scaricando i dati, mostriamo il messaggio di richiesta permesso
                    'Would you like to allow SmartStage to access your activity history from your fitness tracker? This helps us personalize your daily stage limits.\n\nIf you decline, you can still use the app, but you will need to manually input your maximum effort metrics.'),
            
            actions: isFetching     // parametro che vuole la lista dei bottoni da mostrare in basso nel dialog
                ? []        // TRUE: se stiamo scaricando i dati, non mostriamo bottoni
                : <Widget>[ // FALSE: se non stiamo scaricando i dati, mostriamo i bottoni "No" e "Sì"
                    TextButton(
                      child: const Text('Not now'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // Chiude dialog
                        onDecline(); // Esegue l'azione personalizzata
                      },
                    ),
                    TextButton(
                      child: const Text('Yes, connect'), 
                      onPressed: () async {
                        setDialogState(() {
                          isFetching = true; // Aggiorna lo stato del dialog per mostrare l'indicatore di caricamento
                        });

                        // 1. Facciamo la chiamata di rete
                        int status = await Provider.of<TrainingProvider>(context, listen: false).getTrainingData();

                        // 2. Assicuriamoci che i context siano ancora validi PRIMA di fare qualsiasi cosa con la UI
                        if (!context.mounted || !dialogContext.mounted) return;

                        // 3. Chiudiamo il dialog
                        Navigator.of(dialogContext).pop(); 

                        // 4. Gestiamo i risultati
                        if (status == 200) {
                          onSuccess(); 
                        } else  { 
                          onError(status);
                        }
                      },
                    ),
                  ],
          );
        },
      );
    },
  );
}