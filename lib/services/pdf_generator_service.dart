import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Servicio para generar PDFs de notas de venta

class PdfGeneratorService {
  /// Genera un PDF de nota de venta
  ///
  /// [pedidoId] - ID del pedido
  /// [pedido] - Datos completos del pedido
  /// [userEmail] - Email del cliente
  ///
  /// Retorna los bytes del PDF generado
  static Future<Uint8List> generarNotaVenta({
    required String pedidoId,
    required Map<String, dynamic> pedido,
    required String userEmail,
  }) async {
    final pdf = pw.Document();

    // Obtener fecha formateada
    final fecha = DateTime.now();
    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    final horaStr =
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ENCABEZADO
              _buildHeader(pedido, pedidoId, fechaStr, horaStr),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // INFORMACIÓN DEL CLIENTE
              _buildClientInfo(userEmail, pedido),
              pw.SizedBox(height: 20),

              // TABLA DE PRODUCTOS
              _buildProductsTable(pedido),
              pw.SizedBox(height: 20),

              // RESUMEN DE TOTALES
              _buildTotalsSection(pedido),

              pw.Spacer(),

              // PIE DE PÁGINA
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Construye el encabezado del PDF
  static pw.Widget _buildHeader(
    Map<String, dynamic> pedido,
    String pedidoId,
    String fecha,
    String hora,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Información de la empresa
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'MUEBLERÍA ZÁRATE',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.brown700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Muebles de calidad para tu hogar',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 8),
            pw.Text('RUC: 10200573094', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(
              'Dirección: Jr. Ica 805, Huancayo',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Teléfono: 985590000',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),

        // Información del documento
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.brown700, width: 2),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'NOTA DE VENTA',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.brown700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'N° ${pedido['codigoPedido'] ?? pedidoId.substring(0, 8).toUpperCase()}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Fecha: $fecha', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Hora: $hora', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  /// Construye la información del cliente
  static pw.Widget _buildClientInfo(String email, Map<String, dynamic> pedido) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DATOS DEL CLIENTE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.brown700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [pw.Expanded(child: _buildInfoRow('Email:', email))],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow(
                  'Dirección:',
                  pedido['direccion'] ?? 'No especificada',
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: _buildInfoRow(
                  'Teléfono:',
                  pedido['telefono'] ?? 'No especificado',
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: _buildInfoRow(
                  'Método de Pago:',
                  pedido['metodoPago'] ?? 'No especificado',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye una fila de información
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  /// Construye la tabla de productos
  static pw.Widget _buildProductsTable(Map<String, dynamic> pedido) {
    final productos = pedido['productos'] as List<dynamic>;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Encabezado de la tabla
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.brown700),
          children: [
            _buildTableHeader('PRODUCTO'),
            _buildTableHeader('CANT.'),
            _buildTableHeader('PRECIO UNIT.'),
            _buildTableHeader('SUBTOTAL'),
          ],
        ),

        // Filas de productos
        ...productos.map((producto) {
          return pw.TableRow(
            children: [
              _buildTableCell(producto['nombre'] ?? 'Producto'),
              _buildTableCell(
                '${producto['cantidad'] ?? 1}',
                align: pw.TextAlign.center,
              ),
              _buildTableCell(
                'S/. ${(producto['precio'] ?? 0.0).toStringAsFixed(2)}',
                align: pw.TextAlign.right,
              ),
              _buildTableCell(
                'S/. ${(producto['subtotal'] ?? 0.0).toStringAsFixed(2)}',
                align: pw.TextAlign.right,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Construye un encabezado de tabla
  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  /// Construye una celda de tabla
  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: align,
      ),
    );
  }

  /// Construye la sección de totales
  static pw.Widget _buildTotalsSection(Map<String, dynamic> pedido) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal:', pedido['subtotal'] ?? 0.0),
              pw.SizedBox(height: 4),
              _buildTotalRow(
                'Empaquetado (${pedido['tipoEmpaquetado'] ?? 'Simple'}):',
                pedido['costoEmpaquetado'] ?? 0.0,
              ),
              pw.SizedBox(height: 4),
              _buildTotalRow('IGV (18%):', pedido['igv'] ?? 0.0),
              pw.SizedBox(height: 4),
              _buildTotalRow('Envío:', pedido['envio'] ?? 0.0),
              pw.Divider(thickness: 1),
              _buildTotalRow(
                'TOTAL:',
                pedido['total'] ?? 0.0,
                isBold: true,
                fontSize: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construye una fila de total
  static pw.Widget _buildTotalRow(
    String label,
    double value, {
    bool isBold = false,
    double fontSize = 10,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          'S/. ${value.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Construye el pie de página
  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 8),
        pw.Text(
          'Gracias por su compra',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.brown700,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Este documento es una nota de venta electrónica',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          'Para consultas: ventas@muebleriazarate.com',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
