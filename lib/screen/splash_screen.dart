import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ping_chat/main.dart';
import 'package:ping_chat/repo/shared_repo.dart';
import 'package:ping_chat/screen/choose_name.dart';
import 'package:ping_chat/screen/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navigatetologin();
  }

  navigatetologin() async {
    String? name = await SharedRepo.getName();
    log("splash $name");

    if (name == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChooseName()),
      );
    } else {
      server.setName(name);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(name: name)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Icon(Icons.chat_bubble_outlined)));
  }
}
