import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import 'reportes_screen.dart';
import 'cliente_detalle_screen.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Map<String, dynamic>> _entregasTodas = [];
  List<Map<String, dynamic>> _entregasFiltradas = []; 
  
  // Variables para guardar los filtros activos
  final TextEditingController _buscadorController = TextEditingController();
  DateTimeRange? _rangoFechas;
  String _filtroIdExacto = '';

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final data = await DatabaseHelper.instance.getHistorialEntregas();
    setState(() {
      _entregasTodas = data;
      _entregasFiltradas = data;
    });
  }

  // --- LÓGICA MAESTRA DE FILTROS ---
  void _aplicarFiltros() {
    final textoGeneral = _buscadorController.text.toLowerCase();

    setState(() {
      _entregasFiltradas = _entregasTodas.where((entrega) {
        // 1. Filtro de Texto (Nombre)
        final nombre = entrega['cliente_nombre'].toString().toLowerCase();
        bool pasaTexto = nombre.contains(textoGeneral);

        // 2. Filtro de ID de Congeladora
        bool pasaId = true;
        if (_filtroIdExacto.isNotEmpty) {
          pasaId = entrega['codigo_congeladora'].toString() == _filtroIdExacto;
        }

        // 3. Filtro de Rango de Fechas
        bool pasaFecha = true;
        if (_rangoFechas != null) {
          final fechaNativa = DateTime.parse(entrega['fecha']);
          // Ajustamos el fin para que cubra todo ese día hasta las 23:59:59
          final finAjustado = _rangoFechas!.end.add(const Duration(hours: 23, minutes: 59));
          pasaFecha = fechaNativa.isAfter(_rangoFechas!.start) && fechaNativa.isBefore(finAjustado);
        }

        // Retorna TRUE solo si cumple TODOS los filtros activos a la vez
        return pasaTexto && pasaId && pasaFecha;
      }).toList();
    });
  }

  // --- VENTANAS DE FILTROS ---
  Future<void> _seleccionarRangoFechas() async {
    final resultado = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023), // Año de inicio
      lastDate: DateTime.now(),
      helpText: 'Selecciona el rango de fechas',
    );

    if (resultado != null) {
      setState(() => _rangoFechas = resultado);
      _aplicarFiltros();
    }
  }

  void _dialogoFiltroID() {
    final idController = TextEditingController(text: _filtroIdExacto);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar por ID Congeladora'),
        content: TextField(
          controller: idController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Ingresa el ID exacto'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _filtroIdExacto = ''); // Limpiar el filtro de ID
              _aplicarFiltros();
              Navigator.pop(context);
            },
            child: const Text('Quitar filtro'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _filtroIdExacto = idController.text);
              _aplicarFiltros();
              Navigator.pop(context);
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  // Abrir vista detallada (que ya habíamos creado)
  void _abrirDetallesCliente(int clienteId) async {
    final cliente = await DatabaseHelper.instance.getClientePorId(clienteId);
    final totalEntregas = await DatabaseHelper.instance.contarEntregasCliente(clienteId);

    if (cliente != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ClienteDetalleScreen(cliente: cliente, totalEntregas: totalEntregas)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.bar_chart), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportesScreen()))),
        ],
      ),
      body: Column(
        children: [
          // 1. BARRA DE BÚSQUEDA GENERAL
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 5),
            child: TextField(
              controller: _buscadorController,
              onChanged: (val) => _aplicarFiltros(),
              decoration: InputDecoration(
                labelText: 'Buscar tienda...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),

          // 2. BOTONES DE FILTROS AVANZADOS (Fechas e ID)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón de Fecha
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarRangoFechas,
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text(
                      _rangoFechas == null 
                        ? 'Fechas' 
                        : '${DateFormat('dd/MM').format(_rangoFechas!.start)} - ${DateFormat('dd/MM').format(_rangoFechas!.end)}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _rangoFechas == null ? Colors.grey.shade700 : Colors.blue,
                      side: BorderSide(color: _rangoFechas == null ? Colors.grey.shade400 : Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botón de ID
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _dialogoFiltroID,
                    icon: const Icon(Icons.tag, size: 18),
                    label: Text(
                      _filtroIdExacto.isEmpty ? 'ID Cong.' : 'ID: $_filtroIdExacto',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _filtroIdExacto.isEmpty ? Colors.grey.shade700 : Colors.blue,
                      side: BorderSide(color: _filtroIdExacto.isEmpty ? Colors.grey.shade400 : Colors.blue),
                    ),
                  ),
                ),
                // Botón para limpiar todos los filtros (solo aparece si hay algo activo)
                if (_rangoFechas != null || _filtroIdExacto.isNotEmpty || _buscadorController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.filter_alt_off, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _rangoFechas = null;
                        _filtroIdExacto = '';
                        _buscadorController.clear();
                      });
                      _aplicarFiltros();
                    },
                  ),
              ],
            ),
          ),
          
          const Divider(),

          // 3. LISTA DE RESULTADOS
          Expanded(
            child: _entregasFiltradas.isEmpty
                ? const Center(child: Text('No se encontraron entregas con esos filtros.'))
                : ListView.builder(
                    itemCount: _entregasFiltradas.length,
                    itemBuilder: (context, index) {
                      final entrega = _entregasFiltradas[index];
                      final fechaNativa = DateTime.parse(entrega['fecha']);
                      final fechaFormateada = DateFormat('dd/MM/yyyy - hh:mm a').format(fechaNativa);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          onTap: () => _abrirDetallesCliente(entrega['cliente_id']),
                          leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.receipt_long, color: Colors.white)),
                          title: Text(entrega['cliente_nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Congeladora #${entrega['codigo_congeladora']}\n$fechaFormateada'),
                          trailing: Text('S/ ${entrega['total'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}