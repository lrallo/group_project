import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/widgets/impact_dialog.dart'; 
import 'package:provider/provider.dart';
import 'package:project_app/providers/TrainingProvider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _hasImpactPermission = false;
  
  // Controller solo per i dati manuali
  final TextEditingController _walkController = TextEditingController();
  final TextEditingController _bikeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  Future<void> _loadSettingsData() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _hasImpactPermission = sp.getBool('impact_permission') ?? false; //gli do la variabile salvata nella sp durante il login
      
      // Pre-compiliamo i campi con i valori attuali salvati in memoria
      double walk = sp.getDouble('maxWalk') ?? 15.0; // NOTA: uso la chiave 'maxWalk' allineata col Provider
      double bike = sp.getDouble('maxBike') ?? 50.0; // NOTA: uso la chiave 'maxBike' allineata col Provider
      
      _walkController.text = walk.toString();
      _bikeController.text = bike.toString();
      
      _isLoading = false; 
    });
  }

  // Salvataggio ESCLUSIVO per i dati manuali
  Future<void> _saveManualSettings() async {
    // tryParse controlla che l'utente abbia inserito numeri validi
    double? walkValue = double.tryParse(_walkController.text);
    double? bikeValue = double.tryParse(_bikeController.text);

    if (walkValue == null || bikeValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci dei numeri validi per i chilometri!'), backgroundColor: Colors.red),
      );
      return; 
    }
    
    // DELEGHIAMO IL SALVATAGGIO AL PROVIDER! (Sia per lo stato che per le SharedPreferences)
    await Provider.of<TrainingProvider>(context, listen: false).setManualMetrics(walkValue, bikeValue);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Metriche manuali aggiornate!'), backgroundColor: Colors.green),
    );
  }

  // Gestione dello switch IMPACT
  Future<void> _toggleImpactPermission(bool newValue) async {

    if (newValue == true) { // da OFF a ON
      await showImpactPermissionDialog( // apre il popup di consenso a impact
        context: context,
        onSuccess: () async { 
          // 1. Aggiorna SUBITO il permesso nel provider e nelle SharedPreferences
          await Provider.of<TrainingProvider>(context, listen: false).changePermission(true);

          // 2. Scarica i dati direttamente
          // (n.b. non serve prima svuotare la sp dai dati precedenti)
          int status = await Provider.of<TrainingProvider>(context, listen: false).getTrainingData();

          if (status == 200) { // se va a buon fine, rebuildo la UI
            setState(() { _hasImpactPermission = true; });
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dati IMPACT sincronizzati!'), backgroundColor: Colors.green),
            );
          } else {
            // Se fallisce, rimettiamo a false per sicurezza
            await Provider.of<TrainingProvider>(context, listen: false).changePermission(false);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Errore di connessione a IMPACT.'), backgroundColor: Colors.red),
            );
          }
        },
        onError: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Errore di connessione a IMPACT.'), backgroundColor: Colors.red),
          );
        },
        onDecline: () {}
      );
    } else { // da ON a OFF
    // 1.notifico la UI che lo stato è cambiato
      setState(() { 
        _hasImpactPermission = false; 
      });
    if (mounted) { 

      await Provider.of<TrainingProvider>(context, listen: false).switchToManual(); //tolgo le metriche che non servono più e aggiorno la variabile del provider

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IMPACT scollegato. Inserisci le metriche manualmente.'), backgroundColor: Colors.orange),
      );
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Impostazioni App', style: TextStyle(color: Color(0xFF1B365D), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B365D)),
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B365D))) // se si sta caricando mostro il simbolo di download
          : SingleChildScrollView( 
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sincronizzazione IMPACT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54)),
                  const SizedBox(height: 15),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: SwitchListTile( // widget che unisce un interrutore switch e un titolo con sottotitolo
                      title: const Text('Collega server IMPACT', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Calcola automaticamente il tuo livello in base agli allenamenti passati.'),
                      activeColor: const Color(0xFF1B365D),
                      value: _hasImpactPermission,  // stato attuale dell'iterrutore
                      onChanged: _toggleImpactPermission, //funzione runnata quando l'utente tocca l'interrutore
                    ),
                  ),

                  // il pulsante è in OFF
                  if (!_hasImpactPermission) ...[
                    const SizedBox(height: 40),
                    const Text("Parametri Sforzo Manuale", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54)),
                    const SizedBox(height: 10),
                    const Text(
                      'Imposta i tuoi limiti di chilometri giornalieri. Verranno usati per dividere le tappe.',
                      style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: _walkController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Sforzo Massimo a Piedi (Km)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.directions_walk),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _bikeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Sforzo Massimo in Bici (Km)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.directions_bike),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B365D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saveManualSettings, // Salva i dati tramite il Provider
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text('SALVA METRICHE MANUALI', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      ),
    );
  }

  @override
  void dispose() {   // quando l'utente chiude la pagina e torna nella HomePage
  // Libera la memoria del telefono distruggendo i TextEditingController. Se non lo facessi, l'app consumerebbe sempre più RAM a ogni apertura delle impostazion
    _walkController.dispose();
    _bikeController.dispose();
    super.dispose();
  }
}