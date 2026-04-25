import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/producto.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Producto> _productos = [];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  // Trae los productos de SQLite
  Future<void> _cargarProductos() async {
    final productosDB = await DatabaseHelper.instance.getTodosLosProductos();
    setState(() {
      _productos = productosDB;
    });
  }

  // Ventana emergente para agregar un nuevo helado
  void _mostrarDialogoNuevoProducto() {
    final nombreController = TextEditingController();
    final precioController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuevo Helado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del Helado'),
              ),
              TextField(
                controller: precioController,
                decoration: const InputDecoration(labelText: 'Precio (S/)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock Inicial (Cant.)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevoProducto = Producto(
                  nombre: nombreController.text,
                  precio: double.parse(precioController.text),
                  stockActual: int.parse(stockController.text),
                );
                await DatabaseHelper.instance.insertProducto(nuevoProducto);
                _cargarProductos(); // Refrescamos la lista
                Navigator.pop(context); // Cerramos la ventana
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Inventario'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _productos.isEmpty
          ? const Center(child: Text('No hay helados en el inventario aún.'))
          : ListView.builder(
              itemCount: _productos.length,
              itemBuilder: (context, index) {
                final producto = _productos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.icecream, color: Colors.white),
                    ),
                    title: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Precio: S/ ${producto.precio.toStringAsFixed(2)}'),
                    trailing: Chip(
                      label: Text('Stock: ${producto.stockActual}'),
                      backgroundColor: producto.stockActual < 10 ? Colors.redAccent : Colors.greenAccent,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevoProducto,
        icon: const Icon(Icons.add),
        label: const Text('Añadir Helado'),
      ),
    );
  }
}