import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import '../db/database_helper.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _cargarMarcadores();
  }

  Future<void> _cargarMarcadores() async {
    final clientes = await DatabaseHelper.instance.getTodosLosClientes();
    
    setState(() {
      // Filtramos los clientes que sí tienen coordenadas guardadas
      _markers = clientes.where((c) => c.latitud != null).map((cliente) {
        return Marker(
          point: LatLng(cliente.latitud!, cliente.longitud!),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              // Cuando toques el icono, saldrá un mensaje abajo
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${cliente.nombre} - Congeladora #${cliente.codigoCongeladora}'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
          ),
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicación de Congeladoras'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FlutterMap(
        options: const MapOptions(
          // Centrado en Juliaca por defecto
          initialCenter: LatLng(-15.4965, -70.1333), 
          initialZoom: 14.0,
        ),
        children: [
          // Esta capa es la que dibuja las calles gratis desde internet
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.heladeria.app',
          ),
          // Esta capa dibuja tus pines rojos
          MarkerLayer(
            markers: _markers,
          ),
        ],
      ),
    );
  }
}