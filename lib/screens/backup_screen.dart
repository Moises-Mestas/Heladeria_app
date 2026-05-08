import 'package:flutter/material.dart';
import '../utils/backup_helper.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _expClientes = true;
  bool _expProductos = true;
  bool _expEntregas = true;
  bool _cargando = false;

  void _generarExportacion() async {
    if (!_expClientes && !_expProductos && !_expEntregas) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un dato para exportar.'))
      );
      return;
    }

    setState(() => _cargando = true);
    // Ahora recibimos el mensaje que nos manda el Helper
    String mensaje = await BackupHelper.exportarBackup(_expClientes, _expProductos, _expEntregas);
    setState(() => _cargando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  void _cargarImportacion() async {
    setState(() => _cargando = true);
    String mensaje = await BackupHelper.importarBackup();
    setState(() => _cargando = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copias de Seguridad'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Exportar Datos (Crear Backup)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text('Elige qué información deseas guardar en la memoria de tu celular:'),
                  CheckboxListTile(
                    title: const Text('Tiendas / Clientes'),
                    value: _expClientes,
                    onChanged: (val) => setState(() => _expClientes = val!),
                  ),
                  CheckboxListTile(
                    title: const Text('Inventario de Helados'),
                    value: _expProductos,
                    onChanged: (val) => setState(() => _expProductos = val!),
                  ),
                  CheckboxListTile(
                    title: const Text('Historial de Entregas'),
                    value: _expEntregas,
                    onChanged: (val) => setState(() => _expEntregas = val!),
                  ),
                  ElevatedButton.icon(
                    onPressed: _generarExportacion,
                    icon: const Icon(Icons.save),
                    label: const Text('Elegir carpeta y Guardar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                  
                  const Divider(height: 40, thickness: 2),

                  const Text('Importar Datos (Restaurar)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text('Busca el archivo .json en tus carpetas para restaurar tu información.'),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _cargarImportacion,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Buscar archivo de Backup'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}