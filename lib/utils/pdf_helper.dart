import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // <-- ¡Este es el correcto!
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/cliente.dart';

class PdfHelper {
  static Future<void> generarComprobante({
    required Cliente cliente,
    required List<Map<String, dynamic>> productos,
    required double total,
  }) async {
    final pdf = pw.Document();
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6, // Tamaño pequeño tipo recibo
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('RECIBO DE HELADOS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Divider(),
              pw.Text('Cliente: ${cliente.nombre}'),
              pw.Text('Dirección: ${cliente.direccion}'),
              pw.Text('Congeladora: #${cliente.codigoCongeladora}'),
              pw.Text('Fecha: $fecha'),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Producto', 'Cant', 'Subt'],
                data: productos.map((p) => [
                  p['nombre'],
                  p['cantidad'].toString(),
                  'S/ ${(p['precio'] * p['cantidad']).toStringAsFixed(2)}'
                ]).toList(),
              ),
              pw.Divider(),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('TOTAL: S/ ${total.toStringAsFixed(2)}', 
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('¡Gracias por su compra!', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic))),
            ],
          );
        },
      ),
    );

    // Abre el menú de compartir del celular para elegir WhatsApp
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'comprobante_${cliente.nombre}.pdf');
  }
}