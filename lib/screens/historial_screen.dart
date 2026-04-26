import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../db/database_helper.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Map<String, dynamic>> _entregas = [];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  // Llama a la consulta SQL que creamos antes
  Future<void> _cargarHistorial() async {
    final data = await DatabaseHelper.instance.getHistorialEntregas();
    setState(() {
      _entregas = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Entregas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _entregas.isEmpty
          ? const Center(child: Text('No hay registros de entregas aún.'))
          : ListView.builder(
              itemCount: _entregas.length,
              itemBuilder: (context, index) {
                final entrega = _entregas[index];
                
                // Formateamos la fecha para que sea legible
                final fechaNativa = DateTime.parse(entrega['fecha']);
                final fechaFormateada = DateFormat('dd/MM/yyyy - hh:mm a').format(fechaNativa);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.receipt_long, color: Colors.white),
                    ),
                    title: Text(
                      entrega['cliente_nombre'], 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    subtitle: Text('Congeladora #${entrega['codigo_congeladora']}\n$fechaFormateada'),
                    trailing: Text(
                      'S/ ${entrega['total'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.blue
                      ),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}