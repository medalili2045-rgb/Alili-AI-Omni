import 'package:flutter/material.dart';
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: Center(child: Text('Alili Omni', style: TextStyle(color: Colors.white, fontSize: 24))),
    ),
  ));
}
