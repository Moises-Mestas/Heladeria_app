import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/cliente.dart';
import 'package:geolocator/geolocator.dart';
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
    setState(() {
      _clientes = clientesDB;
    });
  }

  // --- NUEVA FUNCIÓN PARA EL GPS ---
  Future<Position> _obtenerUbicacionActual() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      return Future.error('El GPS está desactivado.');
    }

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

    // Si todo está bien, toma la ubicación con alta precisión
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _mostrarDialogoNuevoCliente() {
    final nombreController = TextEditingController();
    final direccionController = TextEditingController();
    final congeladoraController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar Tienda/Cliente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre de la Tienda o Persona'),
                ),
                TextField(
                  controller: direccionController,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                TextField(
                  controller: congeladoraController,
                  decoration: const InputDecoration(labelText: 'Nro. de Congeladora (ej. 15)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // 1. Obtenemos la ubicación real del celular
                  Position posicion = await _obtenerUbicacionActual();

                  // 2. Creamos el cliente con las coordenadas de tu GPS
                  final nuevoCliente = Cliente(
                    nombre: nombreController.text,
                    direccion: direccionController.text,
                    telefono: 'Sin registrar', 
                    codigoCongeladora: int.parse(congeladoraController.text),
                    latitud: posicion.latitude,   // <-- Usamos la latitud real
                    longitud: posicion.longitude, // <-- Usamos la longitud real
                  );
                  
                  // 3. Lo guardamos en SQLite local
                  await DatabaseHelper.instance.insertCliente(nuevoCliente);
                  _cargarClientes();
                  
                  // Verificamos que la pantalla siga abierta antes de cerrarla y mostrar el mensaje
                  if (context.mounted) {
                    Navigator.pop(context); // Cierra la ventanita
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tienda y ubicación guardadas xd')),
                    );
                  }

                } catch (e) {
                  // Si falla el GPS, te avisa en la pantalla
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
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
        title: const Text('Mis Clientes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _clientes.isEmpty
          ? const Center(child: Text('No has registrado ninguna congeladora.'))
          : ListView.builder(
              itemCount: _clientes.length,
              itemBuilder: (context, index) {
                final cliente = _clientes[index];
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CarritoScreen(cliente: cliente)),
                    );
                  },
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.store, color: Colors.white),
                  ),
                  title: Text(cliente.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(cliente.direccion),
                  trailing: Chip(
                    label: Text('Congeladora #${cliente.codigoCongeladora}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevoCliente,
        icon: const Icon(Icons.add_business),
        label: const Text('Nuevo Cliente'),
      ),
    );
  }
}