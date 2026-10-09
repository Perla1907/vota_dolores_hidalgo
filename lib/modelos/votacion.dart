import 'package:vota_dolores_hidalgo/modelos/opcion_votacion.dart';

class Votacion {

  final String pregunta;
  final List<OpcionVotacion> opciones;
  final DateTime fechaCierre;
  final Set<String> votantes = {};

  Votacion ({
    required this.pregunta,
    required this.opciones,
    required this.fechaCierre
  });
}