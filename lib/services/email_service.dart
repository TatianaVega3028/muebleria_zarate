import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_generator_service.dart';

/// Servicio para enviar correos electrónicos con notas de venta en PDF
class EmailService {
  static const String _gmailUser = 'muebleriaespinozacorp@gmail.com';
  static const String _gmailAppPassword = 'kpqulzguxuqufazg';

  /// Envía un correo con la nota de venta en PDF al cliente
  static Future<bool> enviarNotaVenta({
    required String userEmail,
    required String pedidoId,
    required Map<String, dynamic> pedido,
  }) async {
    try {
      print('📧 Iniciando envío de correo a: $userEmail');

      // 1. Generar el PDF
      final pdfBytes = await PdfGeneratorService.generarNotaVenta(
        pedidoId: pedidoId,
        pedido: pedido,
        userEmail: userEmail,
      );

      // 2. Configurar servidor SMTP de Gmail
      final smtpServer = gmail(_gmailUser, _gmailAppPassword);

      // 3. Preparar datos del pedido
      final productos = pedido['productos'] as List;
      final total = pedido['total'] as double;
      final direccion = pedido['direccion'] as String;
      final telefono = pedido['telefono'] as String;
      final metodoPago = pedido['metodoPago'] as String;
      final fecha = DateTime.now();

      // 4. Crear lista de productos para el email
      String productosTexto = '';
      for (var p in productos) {
        productosTexto +=
            '• ${p['nombre']} x${p['cantidad']} - S/.${p['subtotal'].toStringAsFixed(2)}\n';
      }

      // 5. Crear el mensaje de correo
      final message = Message()
        ..from = Address(_gmailUser, 'Mueblería Zárate')
        ..recipients.add(userEmail)
        ..subject =
            'Confirmación de Pedido #${pedidoId.substring(0, 8).toUpperCase()} - Mueblería Zárate'
        ..html =
            '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #6D4C41; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background-color: #f9f9f9; padding: 20px; border: 1px solid #ddd; }
    .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
    .highlight { background-color: #fff3cd; padding: 10px; border-left: 4px solid #ffc107; margin: 15px 0; }
    .product-list { background: white; padding: 10px; border-radius: 4px; white-space: pre-line; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🪑 Mueblería Zárate</h1>
      <p>Confirmación de Pedido</p>
    </div>
    
    <div class="content">
      <h2>¡Gracias por tu compra!</h2>
      
      <p>Tu pedido ha sido registrado exitosamente. A continuación encontrarás los detalles:</p>
      
      <div class="highlight">
        <p><strong>📦 Número de Pedido:</strong> #${pedidoId.substring(0, 8).toUpperCase()}</p>
        <p><strong>📅 Fecha:</strong> ${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}</p>
        <p><strong>💰 Total:</strong> S/.${total.toStringAsFixed(2)}</p>
      </div>
      
      <h3>Detalles de Entrega</h3>
      <p><strong>📍 Dirección:</strong> $direccion</p>
      <p><strong>📞 Teléfono:</strong> $telefono</p>
      <p><strong>💳 Método de Pago:</strong> $metodoPago</p>
      
      <h3>Productos (${productos.length})</h3>
      <div class="product-list">$productosTexto</div>
      
      <p><strong>📎 Adjunto:</strong> Encontrarás tu nota de venta en PDF adjunta a este correo.</p>
      
      <p>Nos pondremos en contacto contigo pronto para coordinar la entrega.</p>
    </div>
    
    <div class="footer">
      <p>Mueblería Zárate - Muebles de calidad para tu hogar</p>
      <p>📧 muebleriaespinozacorp@gmail.com | 📞 (01) 234-5678</p>
      <p style="font-size: 10px; color: #999;">Este es un correo automático, por favor no responder.</p>
    </div>
  </div>
</body>
</html>
        '''
        ..attachments = [];

      // 5.1. Guardar PDF temporalmente para usar FileAttachment
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'NotaVenta_${pedidoId.substring(0, 6).toUpperCase()}.pdf';
      final pdfFile = File('${tempDir.path}/$fileName');
      await pdfFile.writeAsBytes(pdfBytes);

      // 5.2. Adjuntar el archivo PDF
      message.attachments.add(FileAttachment(pdfFile));

      // 6. Enviar el correo
      final sendReport = await send(message, smtpServer);
      print('✅ Correo enviado exitosamente: ${sendReport.toString()}');

      // 7. Limpiar archivo temporal
      try {
        if (await pdfFile.exists()) {
          await pdfFile.delete();
        }
      } catch (e) {
        print('⚠️ No se pudo eliminar archivo temporal: $e');
      }

      return true;
    } catch (e) {
      print('❌ Error al enviar correo: $e');
      return false;
    }
  }
}
