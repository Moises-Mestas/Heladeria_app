import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../db/database_helper.dart';
import '../models/cliente.dart';
import 'carrito_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Cliente> _clientes = [];

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    final clientesDB = await DatabaseHelper.instance.getTodosLosClientes();
    setState(() => _clientes = clientesDB);
  }

  Future<Position> _obtenerUbicacionActual() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) return Future.error('El GPS está desactivado.');

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return Future.error('Permiso de ubicación denegado.');
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      return Future.error('Permisos denegados permanentemente.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Sirve para CREAR y EDITAR
  void _mostrarDialogoCliente({Cliente? clienteAEditar}) {
    final esEdicion = clienteAEditar != null;
    final nombreController = TextEditingController(text: esEdicion ? clienteAEditar.nombre : '');
    final direccionController = TextEditingController(text: esEdicion ? clienteAEditar.direccion : '');
    final telefonoController = TextEditingController(text: esEdicion ? clienteAEditar.telefono : '');
    final congeladoraController = TextEditingController(text: esEdicion ? clienteAEditar.codigoCongeladora.toString() : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(esEdicion ? 'Editar Cliente' : 'Registrar Tienda/Cliente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre de la Tienda')),
                TextField(controller: direccionController, decoration: const InputDecoration(labelText: 'Dirección')),
                TextField(controller: telefonoController, decoration: const InputDecoration(labelText: 'Teléfono (Opcional)'), keyboardType: TextInputType.phone),
                TextField(controller: congeladoraController, decoration: const InputDecoration(labelText: 'Nro. de Congeladora'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Mantenemos las coordenadas viejas si estamos editando
                  double? lat = clienteAEditar?.latitud;
                  double? lng = clienteAEditar?.longitud;

                  // Si es un cliente nuevo, prendemos el GPS y sacamos las coordenadas actuales
                  if (!esEdicion) {
                    Position posicion = await _obtenerUbicacionActual();
                    lat = posicion.latitude;
                    lng = posicion.longitude;
                  }

                  final clienteFormulario = Cliente(
                    id: esEdicion ? clienteAEditar.id : null,
                    nombre: nombreController.text,
                    direccion: direccionController.text,
                    telefono: telefonoController.text.isEmpty ? 'Sin registrar' : telefonoController.text,
                    codigoCongeladora: int.parse(congeladoraController.text),
                    latitud: lat,
                    longitud: lng,
                  );
                  
                  if (esEdicion) {
                    await DatabaseHelper.instance.updateCliente(clienteFormulario);
                  } else {
                    await DatabaseHelper.instance.insertCliente(clienteFormulario);
                  }
                  
                  _cargarClientes();
                  if (mounted) Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(esEdicion ? 'Cliente actualizado xd' : 'Tienda y ubicación guardadas')),
                  );

                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Diálogo de confirmación para eliminar
  void _confirmarEliminar(Cliente cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cliente?'),
        content: Text('Estás a punto de borrar a "${cliente.nombre}". Esta acción no se puede deshacer y no borrará su historial de entregas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteCliente(cliente.id!);
              _cargarClientes();
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
      body: _clientes.isEmpty
          ? const Center(child: Text('No has registrado ninguna congeladora.'))
          : ListView.builder(
              itemCount: _clientes.length,
              itemBuilder: (context, index) {
                final cliente = _clientes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    onTap: () {
                      // Al tocar el cuerpo de la tarjeta, abrimos el carrito
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CarritoScreen(cliente: cliente)));
                    },
                    leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.store, color: Colors.white)),
                    title: Text(cliente.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${cliente.direccion}\nCongeladora #${cliente.codigoCongeladora}'),
                    isThreeLine: true,
                    // Botones de Editar y Eliminar
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _mostrarDialogoCliente(clienteAEditar: cliente),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _confirmarEliminar(cliente),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCliente(), // Sin parámetros crea uno nuevo
        icon: const Icon(Icons.add_business),
        label: const Text('Nuevo Cliente'),
      ),
    );
  }
}