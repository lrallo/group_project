import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_app/providers/TrainingProvider.dart';
import 'package:project_app/screens/LoginPage.dart';

// Funzione async che mostra un dialog per chiedere all'utente il permesso
Future<void> showImpactPermissionDialog({
  // INPUT della funzione:
  required BuildContext context,   // context della pagina da cui viene chiamata la funzione, serve per mostrare il dialog
  // CALLBACKS della funzione:
  required VoidCallback onSuccess, // funzione da eseguire se l'utente accetta di dare il permesso
  required VoidCallback onError,   // funzione da eseguire se c'è un errore nel recuperare i dati IMPACT
  required VoidCallback onDecline, // funzione da eseguire se l'utente rifiuta di dare il permesso
}) async {
  return showDialog<void>( // Funzione che Dice a Flutter di oscurare lo sfondo della pagina corrente e di "spingere" sopra lo schermo una nuova area vuota in cui comparirà qualcosa.
    context: context,
    barrierDismissible: false, // Impedisce la chiusura cliccando fuori
    builder: (BuildContext dialogContext) { // parametro che richiede uan funzione che ritorni un Widget da mostrare nell'area del dialog
      bool isFetching = false; // variabile che indica se stiamo scaricando i dati IMPACT, inizialmente è false

      return StatefulBuilder( //permette di aggiornare solo lo stato del dialog (il pop-up), senza dover aggiornare tutta la pagina
        builder: (context, setDialogState) {
          return AlertDialog( // widget che mostra un dialog (pop-up) con titolo, contenuto e bottoni
            title: const Text('Accesso ai dati IMPACT'),
            content: isFetching // TRUE: se stiamo scaricando i dati, mostriamo un indicatore di caricamento, altrimenti mostriamo il messaggio di richiesta permesso
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF1B365D)),
                      SizedBox(height: 16),
                      Text('Sincronizzazione dati in corso...'),
                    ],
                  )
                : const Text(  // FALSE: se non stiamo scaricando i dati, mostriamo il messaggio di richiesta permesso
                    'Vuoi permettere all\'app di accedere ai tuoi dati di allenamento dal server IMPACT per personalizzare la tua esperienza?'),
            actions: isFetching     // parametro che vuole la lista dei bottoni da mostrare in basso nel dialog
                ? []        // TRUE: se stiamo scaricando i dati, non mostriamo bottoni
                : <Widget>[ // FALSE: se non stiamo scaricando i dati, mostriamo i bottoni "No" e "Sì"
                    TextButton(
                      child: const Text('No'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // Chiude dialog
                        onDecline(); // Esegue l'azione personalizzata
                      },
                    ),
                    TextButton(
                      child: const Text('Sì'),
                      onPressed: () async {
                        setDialogState(() {
                          isFetching = true;
                        });

                        int status = await Provider.of<TrainingProvider>(context, listen: false).getTrainingData();

                        if (!context.mounted) return;
                        Navigator.of(dialogContext).pop(); // Chiude dialog di caricamento

                        if (status == 200) {
                          onSuccess(); 
                        } else if (status == 401) { // se il refresh token è scaduto, o non c'è (l'utente non ha mai fato login), richiedi le credenziali, per chiedere nuovi token
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sessione scaduta. Effettua il login di nuovo.'), backgroundColor: Colors.orange),
                          );
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => LoginPage()), 
                            (Route<dynamic> route) => false 
                          ); 
                        } else {
                          onError(); 
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