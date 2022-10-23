import 'package:flutter/material.dart';
import 'package:omegleclone/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Omegle Clone',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: const Home(),
    );
  }
}
