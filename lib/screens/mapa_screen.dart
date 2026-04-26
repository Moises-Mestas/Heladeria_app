import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../db/database_helper.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  Set<Marker> _markers = {};
  
  // Posición inicial (Juliaca)
  static const CameraPosition _posicionInicial = CameraPosition(
    target: LatLng(-15.4965, -70.1333),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _cargarMarcadores();
  }

  Future<void> _cargarMarcadores() async {
    final clientes = await DatabaseHelper.instance.getTodosLosClientes();
    
    setState(() {
      _markers = clientes.where((c) => c.latitud != null).map((cliente) {
        return Marker(
          markerId: MarkerId(cliente.id.toString()),
          position: LatLng(cliente.latitud!, cliente.longitud!),
          infoWindow: InfoWindow(
            title: cliente.nombre,
            snippet: 'Congeladora #${cliente.codigoCongeladora}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      }).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación de Congeladoras')),
      body: GoogleMap(
        initialCameraPosition: _posicionInicial,
        markers: _markers,
        myLocationEnabled: true, // Muestra tu punto azul actual
      ),
    );
  }
}