import 'package:flutter_test/flutter_test.dart';
import 'package:vota_dolores_hidalgo/logica/resultado_voto.dart';
import 'package:vota_dolores_hidalgo/logica/servicio_votacion.dart';
import 'package:vota_dolores_hidalgo/modelos/opcion_votacion.dart';
import 'package:vota_dolores_hidalgo/modelos/votacion.dart';

Votacion _createVotacionDePrueba({DateTime? fechaCierre}) {
  return Votacion(
    pregunta: "Pregunta de prueba", 
    opciones: [
      OpcionVotacion(id: "op1", texto: "Opcion 1"), 
      OpcionVotacion(id: "op2", texto: "Opcion 2"),
    ],

    fechaCierre: fechaCierre ?? DateTime.now().add(const Duration(days: 7))
  );
}

void main() {
  test("registrar un voto válido incrementanda el contador de esa opcion", () {
    final votacion = _createVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    final resultado = servicio.registrarVoto(idUsuario: 'user1', idOpcion: "op1");

    expect(resultado, ResultadoVoto.exitoso);
    expect(votacion.opciones[0].votos, 1);
  });

  test("Vota por una opción que no existe regresa opcionInvalida", () {
    final votacion = _createVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    final resultado = servicio.registrarVoto(idUsuario: "user1", idOpcion: "no-existe");

    expect(resultado, ResultadoVoto.opcionInvalida);
  });

  test("Un mismo usuario no puede votar dos veces", () {
    final votacion = _createVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    servicio.registrarVoto(idUsuario: "user1", idOpcion: "op1");
    final segundoIntento = servicio.registrarVoto(idUsuario: "user1", idOpcion: "op2");

    expect(segundoIntento, ResultadoVoto.usuarioYaVoto);
    expect(votacion.opciones[1].votos, 0); // op2 no debio incrementarse

  });

  test("calcula el porcentaje de cada opcion correctamente", () {
    final votacion = _createVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);
    servicio.registrarVoto(idUsuario: "u1", idOpcion: "op1");
    servicio.registrarVoto(idUsuario: "u2", idOpcion: "op1");
    servicio.registrarVoto(idUsuario: "u3", idOpcion: "op1");
    servicio.registrarVoto(idUsuario: "u4", idOpcion: "op2");

    final resultados = servicio.obtenerResultados();

    final op1 = resultados.firstWhere((r) => r.opcion.id == "op1");
    final op2 = resultados.firstWhere((r) => r.opcion.id == "op2");
    expect(op1.porcentaje, 75.0);
    expect(op2.porcentaje, 25.0);
  });

  test("Si no hay ningun voto, todos los porcentajes son 0", () {
    final votacion = _createVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    final resultados = servicio.obtenerResultados();

    expect(resultados.every((r) => r.porcentaje == 0), true);
  });

  test("determinarGanador regresa la opcion con mas votos", () {
    final votacion = _createVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    servicio.registrarVoto(idUsuario: "u1", idOpcion: "op1");
    servicio.registrarVoto(idUsuario: "u2", idOpcion: "op1");
    servicio.registrarVoto(idUsuario: "u3", idOpcion: "op2");

    final ganadores = servicio.determinarGanador();

    expect(ganadores.length, 1);
    expect(ganadores.first.id, "op1");
  });

  test("Si hay empate, determinarGanador regresa mas de una opcion", () {
    final votacion = _createVotacionDePrueba();
    final servicio = ServicioVotacion(votacion);

    servicio.registrarVoto(idUsuario: "u1", idOpcion: "op1");
    servicio.registrarVoto(idUsuario: "u2", idOpcion: "op2");
    servicio.registrarVoto(idUsuario: "u3", idOpcion: "op3");

    final ganadores = servicio.determinarGanador();

    expect(ganadores.length, 2);
  });

  test("No se puede votar si la votacion ya cerro", () {
    final votacionCerrada = _createVotacionDePrueba(
      fechaCierre: DateTime(2000, 1, 1), // una fecha muy en el pasado
    );

    final servicio = ServicioVotacion(votacionCerrada);

    final resultado = servicio.registrarVoto(idUsuario: "user1", idOpcion: "op1");

    expect(resultado, ResultadoVoto.votacionCerrada);
    expect(votacionCerrada.opciones[0].votos, 0);
  });

  test("Si la votacion sigue abierta, el voto se registra normalmente", () {
    final votacionAbierta = _createVotacionDePrueba(
      fechaCierre: DateTime.now().add(const Duration(days: 11)),
    );

    final servicio = ServicioVotacion(votacionAbierta);

    final resultado = servicio.registrarVoto(idUsuario: "user1", idOpcion: "op1");

    expect(resultado, ResultadoVoto.exitoso);
  });

  test("Simulación completa: varios vecinos votan y se determina un ganador", () {

    final votacion = Votacion(
      pregunta: "Qué obra prioritaria debe realizar el municipio?", 
      opciones: [
        OpcionVotacion(id: 'jardin', texto: 'Rehabilitacion del Jardin Principal'),
        OpcionVotacion(id: 'biblioteca', texto: 'Nueva Biblioteca Digital'),
        OpcionVotacion(id: "alumbrado", texto: "Alumbrado en el Barrio Analco"),
      ], 
      fechaCierre: DateTime.now().add(const Duration(days: 3)),
    );

    final servicio = ServicioVotacion(votacion);
    servicio.registrarVoto(idUsuario: "vecino1", idOpcion: "jardin");
    servicio.registrarVoto(idUsuario: "vecino2", idOpcion: "jardin");
    servicio.registrarVoto(idUsuario: "vecino3", idOpcion: "biblioteca");
    servicio.registrarVoto(idUsuario: "vecino1", idOpcion: "alumbrado"); // repetido: no debe contar

    final resultados = servicio.obtenerResultados();
    final totalVotos = resultados.fold<double>(0, (s, r) => s + r.opcion.votos);
    final ganadores = servicio.determinarGanador();

    expect(totalVotos, 3); // el intento repetido de vecino1 no debio contar
    expect(ganadores.length, 1);
    expect(ganadores.first.id, "jardin");
  });
}