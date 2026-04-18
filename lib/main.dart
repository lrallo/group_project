import 'package:flutter/material.dart';
import '/screens/LoginPage.dart';


void main() {
  runApp(MyApp());
} //main

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 60, 54, 244)),
        useMaterial3: true,
      ),
      home: LoginPage(),
    );
  } //build
}//MyApp