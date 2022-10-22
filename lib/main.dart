import 'package:flutter/material.dart';
import 'package:omegleclone/home.dart';
import 'package:provider/provider.dart';

import 'Provider/webrtc_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WebRTCService()),
      ],
      child: MaterialApp(
        title: 'Omegle Clone',
        theme: ThemeData(
          primarySwatch: Colors.cyan,
        ),
        home: const Home(),
      ),
    );
  }
}
