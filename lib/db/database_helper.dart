import 'package:frontend_app/models/producto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cliente.dart';

class DatabaseHelper {
  // Instancia única (Singleton) para no abrir la BD múltiples veces
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('heladeria_v2.db'); 
    return _database!;
  }

Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 1, // 👈 Incrementa la versión cada vez que cambies el esquema
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // 👈 Maneja migraciones
    );
  }

   Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        direccion TEXT,
        telefono TEXT,
        latitud REAL,
        longitud REAL,
        codigo_congeladora INTEGER UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        stock_actual INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS entregas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS detalle_entregas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entrega_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        FOREIGN KEY (entrega_id) REFERENCES entregas (id),
        FOREIGN KEY (producto_id) REFERENCES productos (id)
      )
    ''');
  }
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS detalle_entregas');
    await db.execute('DROP TABLE IF EXISTS entregas');
    await db.execute('DROP TABLE IF EXISTS productos');
    await db.execute('DROP TABLE IF EXISTS clientes');
    await _createDB(db, newVersion);
  }
  Future<int> insertCliente(Cliente cliente) async {
    final db = await instance.database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<List<Cliente>> getTodosLosClientes() async {
    final db = await instance.database;
    final result = await db.query('clientes');
    return result.map((map) => Cliente.fromMap(map)).toList();
  }


  Future<int> insertProducto(Producto producto) async {
    final db = await instance.database;
    return await db.insert('productos', producto.toMap());
  }

  Future<List<Producto>> getTodosLosProductos() async {
    final db = await instance.database;
    final result = await db.query('productos');
    return result.map((map) => Producto.fromMap(map)).toList();
  }

Future<List<Map<String, dynamic>>> getHistorialEntregas() async {
    final db = await instance.database;
    // Usamos un JOIN para traer el nombre del cliente junto con la entrega
    return await db.rawQuery('''
      SELECT e.*, c.nombre as cliente_nombre, c.codigo_congeladora 
      FROM entregas e 
      JOIN clientes c ON e.cliente_id = c.id 
      ORDER BY e.fecha DESC
    ''');
  }
// --- MÉTODO PARA PROCESAR LA ENTREGA COMPLETA ---
  Future<void> procesarEntrega(int clienteId, List<Map<String, dynamic>> carrito, double total) async {
    final db = await instance.database;
    final fecha = DateTime.now().toIso8601String();

    // Iniciamos una transacción para que, si algo falla, no se guarde nada a medias
    await db.transaction((txn) async {
      // 1. Insertar la cabecera de la Entrega
      int entregaId = await txn.insert('entregas', {
        'cliente_id': clienteId,
        'fecha': fecha,
        'total': total,
      });

      // 2. Procesar cada ítem del carrito
      for (var item in carrito) {
        int productoId = item['id'];
        int cantidad = item['cantidad'];
        double precioUnitario = item['precio'];

        // Insertar en Detalle de Entregas
        await txn.insert('detalle_entregas', {
          'entrega_id': entregaId,
          'producto_id': productoId,
          'cantidad': cantidad,
          'precio_unitario': precioUnitario,
        });

        // 3. ¡EL DESCUENTO! Actualizar el stock del helado
        await txn.execute('''
          UPDATE productos 
          SET stock_actual = stock_actual - ? 
          WHERE id = ?
        ''', [cantidad, productoId]);
      }
    });
  }
}