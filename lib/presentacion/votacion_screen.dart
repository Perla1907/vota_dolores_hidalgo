import 'package:flutter/material.dart';
import '../modelos/opcion_votacion.dart';
import '../modelos/votacion.dart';
import '../modelos/resultado_opcion.dart';
import '../logica/resultado_voto.dart';
import '../logica/servicio_votacion.dart';

class VotacionScreen extends StatefulWidget {
  const VotacionScreen({super.key});
  @override
  State<VotacionScreen> createState() => _VotacionScreenState();
}


class _VotacionScreenState extends State<VotacionScreen> {
  late final Votacion _votacion;
  late final ServicioVotacion _servicio;
  bool _yaVote = false;
  final String _idUsuario = 'invitado-' + DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _votacion = Votacion(
      pregunta: 'Que obra prioritaria debe realizar el municipio este ano?',
      opciones: [
        OpcionVotacion(id: 'jardin', texto: 'Rehabilitacion del Jardin Principal'),
        OpcionVotacion(id: 'biblioteca', texto: 'Nueva Biblioteca Digital'),
        OpcionVotacion(id: 'alumbrado', texto: 'Alumbrado en el Barrio de Analco'),
        OpcionVotacion(id: 'parque', texto: 'Parque Infantil en la Colonia Guanajuato'),
      ],
      fechaCierre: DateTime.now().add(const Duration(days: 7)),
    );
    _servicio = ServicioVotacion(_votacion);
  }

  void _votar(String idOpcion) {
    final resultado = _servicio.registrarVoto(idUsuario: _idUsuario, idOpcion: idOpcion);
    if (resultado == ResultadoVoto.exitoso) {
      setState(() => _yaVote = true);
    } else if (resultado == ResultadoVoto.usuarioYaVoto) {
      _mensaje('Ya registramos tu voto en este plebiscito.');
    } else if (resultado == ResultadoVoto.votacionCerrada) {
      _mensaje('Esta votacion ya cerro.');
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  void _verGanador() {
    final ganadores = _servicio.determinarGanador();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ganador',
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              title: const Text('Resultado del plebiscito'),
              content: Text(
                ganadores.length == 1
                    ? 'La opcion ganadora es:\n\n' + ganadores.first.texto
                    : 'Hay un empate entre:\n\n' + ganadores.map((g) => g.texto).join('\n'),
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultados = _servicio.obtenerResultados();
    return Scaffold(
      appBar: AppBar(title: const Text('Plebiscito Vecinal - Dolores Hidalgo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_votacion.pregunta, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...resultados.map((r) => _BarraOpcion(
                resultado: r,
                puedeVotar: !_yaVote,
                onVotar: () => _votar(r.opcion.id),
              )),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _verGanador,
            icon: const Icon(Icons.emoji_events),
            label: const Text('Ver resultado del plebiscito'),
          ),
        ],
      ),
    );
  }
}

class _BarraOpcion extends StatelessWidget {
  final ResultadoOpcion resultado;
  final bool puedeVotar;
  final VoidCallback onVotar;
  const _BarraOpcion({required this.resultado, required this.puedeVotar, required this.onVotar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(resultado.opcion.texto, style: const TextStyle(fontWeight: FontWeight.w600))),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: resultado.porcentaje),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, valor, _) => Text(valor.toStringAsFixed(0) + '%'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 18,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: resultado.porcentaje / 100),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, valor, _) => Container(
                      height: 18,
                      width: constraints.maxWidth * valor,
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          if (puedeVotar)
            OutlinedButton(onPressed: onVotar, child: const Text('Votar por esta opcion')),
        ],
      ),
    );
  }
}

