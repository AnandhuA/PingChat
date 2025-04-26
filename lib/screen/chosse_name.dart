import 'package:flutter/material.dart';

class ChosseName extends StatelessWidget {
  const ChosseName({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            TextField(decoration: InputDecoration(hintText: "Enter name")),
            ElevatedButton(onPressed: () {}, child: Text("Save")),
          ],
        ),
      ),
    );
  }
}
