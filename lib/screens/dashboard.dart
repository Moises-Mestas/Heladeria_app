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

  Future<void> _cargarProductos() async {
    final productosDB = await DatabaseHelper.instance.getTodosLosProductos();
    setState(() => _productos = productosDB);
  }

  // Sirve tanto para CREAR como para EDITAR
  void _mostrarDialogoProducto({Producto? productoAEditar}) {
    final esEdicion = productoAEditar != null;
    final nombreController = TextEditingController(text: esEdicion ? productoAEditar.nombre : '');
    final precioController = TextEditingController(text: esEdicion ? productoAEditar.precio.toString() : '');
    final stockController = TextEditingController(text: esEdicion ? productoAEditar.stockActual.toString() : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(esEdicion ? 'Editar Helado' : 'Nuevo Helado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: precioController, decoration: const InputDecoration(labelText: 'Precio (S/)'), keyboardType: TextInputType.number),
              TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock (Cant.)'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final productoFormulario = Producto(
                  id: esEdicion ? productoAEditar.id : null, // Mantenemos el ID si estamos editando
                  nombre: nombreController.text,
                  precio: double.parse(precioController.text),
                  stockActual: int.parse(stockController.text),
                );

                if (esEdicion) {
                  await DatabaseHelper.instance.updateProducto(productoFormulario);
                } else {
                  await DatabaseHelper.instance.insertProducto(productoFormulario);
                }
                
                _cargarProductos();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Diálogo de confirmación para eliminar
  void _confirmarEliminar(Producto producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: Text('Estás a punto de borrar "${producto.nombre}". Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteProducto(producto.id!);
              _cargarProductos();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Inventario'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: _productos.isEmpty
          ? const Center(child: Text('No hay helados en el inventario aún.'))
          : ListView.builder(
              itemCount: _productos.length,
              itemBuilder: (context, index) {
                final producto = _productos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.icecream, color: Colors.white)),
                    title: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('S/ ${producto.precio.toStringAsFixed(2)}  |  Stock: ${producto.stockActual}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón Editar
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _mostrarDialogoProducto(productoAEditar: producto),
                        ),
                        // Botón Eliminar
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _confirmarEliminar(producto),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoProducto(), // Si no le pasamos nada, crea uno nuevo
        icon: const Icon(Icons.add),
        label: const Text('Añadir Helado'),
      ),
    );
  }
}