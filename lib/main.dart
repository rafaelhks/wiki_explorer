import 'package:flutter/material.dart';
import 'home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wikipedia Explorer',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: WikipediaExplorer(),
    );
  }
}