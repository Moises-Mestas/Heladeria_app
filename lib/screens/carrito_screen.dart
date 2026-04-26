import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/producto.dart';
import '../models/cliente.dart';
import '../utils/pdf_helper.dart';
class CarritoScreen extends StatefulWidget {
  final Cliente cliente; // Necesitamos saber a quién le entregamos
  const CarritoScreen({super.key, required this.cliente});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  List<Producto> _productos = [];
  Map<int, int> _seleccionados = {}; // ID del producto -> Cantidad

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    final list = await DatabaseHelper.instance.getTodosLosProductos();
    setState(() => _productos = list);
  }

  double get _totalVenta {
    double total = 0;
    _seleccionados.forEach((id, cant) {
      final p = _productos.firstWhere((prod) => prod.id == id);
      total += p.precio * cant;
    });
    return total;
  }

void _confirmarEntrega() async {
    if (_seleccionados.isEmpty) return;

    List<Map<String, dynamic>> itemsParaBD = [];
    // Creamos esta lista extra para que el PDF tenga los NOMBRES de los helados
    List<Map<String, dynamic>> itemsParaPdf = [];

    _seleccionados.forEach((id, cant) {
      final p = _productos.firstWhere((prod) => prod.id == id);
      itemsParaBD.add({'id': id, 'cantidad': cant, 'precio': p.precio});
      itemsParaPdf.add({'nombre': p.nombre, 'cantidad': cant, 'precio': p.precio});
    });

    // 1. Guardar en Base de Datos y descontar stock
    await DatabaseHelper.instance.procesarEntrega(
      widget.cliente.id!,
      itemsParaBD,
      _totalVenta,
    );

    // 2. Generar y compartir PDF
    await PdfHelper.generarComprobante(
      cliente: widget.cliente,
      productos: itemsParaPdf,
      total: _totalVenta,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Entrega: ${widget.cliente.nombre}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _productos.length,
              itemBuilder: (context, index) {
                final p = _productos[index];
                int cant = _seleccionados[p.id] ?? 0;

                return ListTile(
                  title: Text(p.nombre),
                  subtitle: Text('S/ ${p.precio.toStringAsFixed(2)} | Stock: ${p.stockActual}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: cant > 0 ? () => setState(() => _seleccionados[p.id!] = cant - 1) : null,
                      ),
                      Text('$cant', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: cant < p.stockActual ? () => setState(() => _seleccionados[p.id!] = cant + 1) : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue.shade50),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL A COBRAR:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('S/ ${_totalVenta.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _seleccionados.isEmpty ? null : _confirmarEntrega,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: const Text('CONFIRMAR ENTREGA'),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}