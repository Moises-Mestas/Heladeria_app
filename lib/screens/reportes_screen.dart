import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  int _totalEntregas = 0;
  double _ingresosTotales = 0.0;
  List<Map<String, dynamic>> _productosBajoStock = [];

  @override
  void initState() {
    super.initState();
    _generarReporte();
  }

  Future<void> _generarReporte() async {
    // 1. Calculamos ingresos y entregas desde el historial
    final historial = await DatabaseHelper.instance.getHistorialEntregas();
    double ingresos = 0;
    for (var entrega in historial) {
      ingresos += entrega['total'];
    }

    // 2. Buscamos productos que tengan menos de 10 en stock (para que sepas qué reponer)
    final db = await DatabaseHelper.instance.database;
    final bajoStock = await db.rawQuery('SELECT * FROM productos WHERE stock_actual <= 10');

    setState(() {
      _totalEntregas = historial.length;
      _ingresosTotales = ingresos;
      _productosBajoStock = bajoStock;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte General'),
        backgroundColor: Colors.indigo.shade300,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de Ingresos
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('INGRESOS TOTALES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 10),
                    Text(
                      'S/ ${_ingresosTotales.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    Text('En $_totalEntregas entregas realizadas', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Sección de Alertas de Stock
            const Text(
              '⚠️ Alertas de Stock Bajo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: _productosBajoStock.isEmpty
                  ? const Center(child: Text('¡Todo tu stock está en buen nivel!'))
                  : ListView.builder(
                      itemCount: _productosBajoStock.length,
                      itemBuilder: (context, index) {
                        final prod = _productosBajoStock[index];
                        return ListTile(
                          leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          title: Text(prod['nombre']),
                          trailing: Text(
                            'Quedan: ${prod['stock_actual']}',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}