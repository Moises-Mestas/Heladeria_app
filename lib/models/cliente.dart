class Cliente {
  int? id;
  String nombre;
  String direccion;
  String telefono;
  double? latitud;
  double? longitud;
  int codigoCongeladora;

  Cliente({
    this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    this.latitud,
    this.longitud,
    required this.codigoCongeladora,
  });

  // Convierte un objeto Cliente a un Map para guardarlo en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'latitud': latitud,
      'longitud': longitud,
      'codigo_congeladora': codigoCongeladora,
    };
  }

  // Convierte un Map (que viene de SQLite) a un objeto Cliente
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nombre: map['nombre'],
      direccion: map['direccion'],
      telefono: map['telefono'],
      latitud: map['latitud'],
      longitud: map['longitud'],
      codigoCongeladora: map['codigo_congeladora'],
    );
  }
}