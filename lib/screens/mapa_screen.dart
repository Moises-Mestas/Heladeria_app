import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- Nueva librería
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

  // Función mágica que abre la app de Google Maps
  Future<void> _abrirEnGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps')),
        );
      }
    }
  }

  Future<void> _cargarMarcadores() async {
    final clientes = await DatabaseHelper.instance.getTodosLosClientes();
    
    setState(() {
      _markers = clientes.where((c) => c.latitud != null).map((cliente) {
        return Marker(
          point: LatLng(cliente.latitud!, cliente.longitud!),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              // Ventanita que sube desde abajo al tocar el pin
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.store, size: 40, color: Colors.blue),
                      const SizedBox(height: 10),
                      Text(cliente.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Congeladora #${cliente.codigoCongeladora}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Cierra la ventanita
                            _abrirEnGoogleMaps(cliente.latitud!, cliente.longitud!); // Abre G-Maps
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('Abrir en Google Maps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      )
                    ],
                  ),
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
          initialCenter: LatLng(-15.4965, -70.1333), 
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.heladeria.app',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}