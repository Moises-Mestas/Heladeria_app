import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- Nueva librería
import '../models/cliente.dart';

class ClienteDetalleScreen extends StatelessWidget {
  final Cliente cliente;
  final int totalEntregas;

  const ClienteDetalleScreen({super.key, required this.cliente, required this.totalEntregas});

  // Reutilizamos la misma función mágica
  Future<void> _abrirEnGoogleMaps(BuildContext context, double lat, double lng) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double lat = cliente.latitud ?? -15.4965;
    final double lng = cliente.longitud ?? -70.1333;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles: ${cliente.nombre}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.store, size: 40, color: Colors.blue),
                    title: Text(cliente.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    subtitle: Text(cliente.direccion),
                  ),
                  const Divider(),
                  Text('❄️ Congeladora ID: #${cliente.codigoCongeladora}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('📦 Entregas Totales Realizadas: $totalEntregas', 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ubicación de la tienda:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                // ¡Nuevo botón aquí!
                if (cliente.latitud != null)
                  ElevatedButton.icon(
                    onPressed: () => _abrirEnGoogleMaps(context, lat, lng),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Navegar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: cliente.latitud == null
                ? const Center(child: Text('No se guardaron coordenadas para este cliente.'))
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(lat, lng),
                      initialZoom: 16.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.heladeria.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(lat, lng),
                            width: 60,
                            height: 60,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}