import 'package:flutter/material.dart';
import 'package:ping_chat/screen/splash_screen.dart';
import 'package:ping_chat/server.dart';

final server = Server();
void main() {
  server.startServer();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
    );
  }
}
