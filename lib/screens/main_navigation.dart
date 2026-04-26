import 'package:flutter/material.dart';
import 'package:frontend_app/screens/historial_screen.dart';
import 'package:frontend_app/screens/mapa_screen.dart';
import 'dashboard.dart';
import 'clientes_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _indiceActual = 0;

  // Aquí agregaremos la pantalla del Carrito más adelante
  final List<Widget> _pantallas = [
    const DashboardScreen(),
    const ClientesScreen(),
    const MapaScreen(),
    const HistorialScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _indiceActual,
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'), 
        ],
      ),
    );
  }
}