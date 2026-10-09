class OpcionVotacion {

  final String id;
  final String texto;
  int votos;

  OpcionVotacion({
    required this.id,
    required this.texto,
    this.votos = 0
  });
}