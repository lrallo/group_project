import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/TripProvider.dart';
import 'providers/TrainingProvider.dart';
import 'package:project_app/screens/splash.dart';


void main() {
  runApp(MyApp());
} //main

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TripProvider>(
          create: (context) => TripProvider(),
        ),
        ChangeNotifierProvider<TrainingProvider>(
          create: (context) => TrainingProvider(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 60, 54, 244)),
          useMaterial3: true,
        ),
        home:  Splash(),
      ),
    );
  } //build
}//MyApp



