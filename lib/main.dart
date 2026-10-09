import 'package:flutter/material.dart';
import 'package:vota_dolores_hidalgo/presentacion/votacion_screen.dart';

void main() => runApp(const VotaDoloresApp());

class VotaDoloresApp extends StatelessWidget {
  const VotaDoloresApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vota Dolores Hidalgo',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const VotacionScreen(),
    );
  }
}
