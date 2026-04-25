class Producto {
  int? id;
  String nombre;
  double precio;
  int stockActual;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.stockActual,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'stock_actual': stockActual,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      precio: map['precio'],
      stockActual: map['stock_actual'],
    );
  }
}