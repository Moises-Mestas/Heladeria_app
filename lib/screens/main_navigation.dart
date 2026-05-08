import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'clientes_screen.dart';
import 'mapa_screen.dart';
import 'historial_screen.dart';
import 'backup_screen.dart'; // <-- IMPORTAMOS LA NUEVA PANTALLA

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _indiceActual = 0;

  final List<Widget> _pantallas = [
    const DashboardScreen(),
    const ClientesScreen(),
    const MapaScreen(),
    const HistorialScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- NUEVO: AppBar y Menú Lateral (Drawer) ---
      appBar: AppBar(
        title: const Text('Heladería App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade700),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.icecream, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text('Gestión Heladería', style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Copia de Seguridad'),
              subtitle: const Text('Importar / Exportar Datos'),
              onTap: () {
                Navigator.pop(context); // Cierra el menú lateral primero
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupScreen()));
              },
            ),
          ],
        ),
      ),
      // ----------------------------------------------
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
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }
}