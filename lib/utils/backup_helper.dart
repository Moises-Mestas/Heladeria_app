import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // <-- NUEVO: Para manejar los "bytes"
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:permission_handler/permission_handler.dart'; 
import '../db/database_helper.dart';

class BackupHelper {
  
  static Future<bool> _solicitarPermisos() async {
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted || await Permission.manageExternalStorage.isGranted;
  }

  // --- EXPORTAR DATOS ---
  static Future<String> exportarBackup(bool expClientes, bool expProductos, bool expEntregas) async {
    try {
      bool tienePermiso = await _solicitarPermisos();
      if (!tienePermiso) {
        return 'Permiso denegado. No se puede guardar el backup sin acceso al almacenamiento.';
      }

      final db = await DatabaseHelper.instance.database;
      Map<String, dynamic> backupData = {};

      if (expClientes) backupData['clientes'] = await db.query('clientes');
      if (expProductos) backupData['productos'] = await db.query('productos');
      if (expEntregas) {
        backupData['entregas'] = await db.query('entregas');
        backupData['detalle_entregas'] = await db.query('detalle_entregas');
      }

      String jsonString = jsonEncode(backupData);
      final fecha = DateTime.now().toIso8601String().split('T').first;

      // 1. Convertimos el texto JSON a Bytes (Lo que pide Android)
      Uint8List fileBytes = Uint8List.fromList(utf8.encode(jsonString));

      // 2. Le pasamos los bytes a la ventana para que lo guarde
      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Elige dónde guardar tu backup',
        fileName: 'heladeria_backup_$fecha.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: fileBytes, // <-- ¡LA SOLUCIÓN AL ERROR ESTÁ AQUÍ!
      );

      if (outputFile != null) {
        // Como ya le pasamos los bytes, Android ya escribió el archivo. 
        // No necesitamos hacer file.writeAsString() manualmente.
        return '¡Backup guardado correctamente en tu celular!';
      } else {
        return 'Exportación cancelada.';
      }
    } catch (e) {
      return 'Error técnico: $e';
    }
  }

  // --- IMPORTAR DATOS ---
  static Future<String> importarBackup() async {
    try {
      bool tienePermiso = await _solicitarPermisos();
      if (!tienePermiso) {
        return 'Permiso denegado. No se pueden leer archivos sin acceso al almacenamiento.';
      }

      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        // En Android moderno, a veces necesitamos leer los bytes directos desde el result
        // para evitar errores de ruta de acceso.
        String jsonString;
        if (result.files.single.bytes != null) {
           jsonString = utf8.decode(result.files.single.bytes!);
        } else {
           File file = File(result.files.single.path!);
           jsonString = await file.readAsString();
        }

        Map<String, dynamic> backupData = jsonDecode(jsonString);
        final db = await DatabaseHelper.instance.database;

        await db.transaction((txn) async {
          if (backupData.containsKey('clientes')) {
            for (var item in backupData['clientes']) {
              await txn.insert('clientes', item, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          if (backupData.containsKey('productos')) {
            for (var item in backupData['productos']) {
              await txn.insert('productos', item, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          if (backupData.containsKey('entregas')) {
            for (var item in backupData['entregas']) {
              await txn.insert('entregas', item, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          if (backupData.containsKey('detalle_entregas')) {
            for (var item in backupData['detalle_entregas']) {
              await txn.insert('detalle_entregas', item, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        });

        return '¡Backup restaurado con éxito!';
      }
      return 'Importación cancelada.';
    } catch (e) {
      return 'Error al importar: El archivo no es válido o está dañado.';
    }
  }
}