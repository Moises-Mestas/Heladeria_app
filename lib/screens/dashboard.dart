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

  // --- NUEVO: Ventanita rápida solo para sumar stock ---
  void _mostrarDialogoAbastecer(Producto producto) {
    final cantidadController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Abastecer: ${producto.nombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock actual: ${producto.stockActual} unidades', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: cantidadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '¿Cuántos llegaron?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add_shopping_cart, color: Colors.green),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                // int.tryParse evita que la app explote si dejas el campo vacío o pones letras
                int? cantidadIngresada = int.tryParse(cantidadController.text);
                
                if (cantidadIngresada != null && cantidadIngresada > 0) {
                  // Hacemos la matemática: Stock Viejo + Lo que acaba de llegar
                  producto.stockActual += cantidadIngresada;
                  
                  // Guardamos el producto actualizado en la BD
                  await DatabaseHelper.instance.updateProducto(producto);
                  _cargarProductos();
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('¡Stock sumado! Ahora tienes ${producto.stockActual} unidades xd')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Sumar Stock'),
            ),
          ],
        );
      },
    );
  }

  // Sirve tanto para CREAR como para EDITAR (Nombre y Precio)
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
              // Si estamos editando, tal vez ya no queramos tocar el stock por aquí, 
              // pero lo dejamos por si necesitas hacer una corrección manual.
              TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock Total (Cant.)'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final productoFormulario = Producto(
                  id: esEdicion ? productoAEditar.id : null,
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
                        // --- NUEVO BOTÓN: Abastecer ---
                        IconButton(
                          icon: const Icon(Icons.add_box, color: Colors.green),
                          tooltip: 'Abastecer (Sumar Stock)',
                          onPressed: () => _mostrarDialogoAbastecer(producto),
                        ),
                        // Botón Editar
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          tooltip: 'Editar Datos',
                          onPressed: () => _mostrarDialogoProducto(productoAEditar: producto),
                        ),
                        // Botón Eliminar
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: 'Eliminar',
                          onPressed: () => _confirmarEliminar(producto),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoProducto(),
        icon: const Icon(Icons.add),
        label: const Text('Añadir Nuevo Helado'),
      ),
    );
  }
}