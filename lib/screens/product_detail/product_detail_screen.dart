import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../services/productos_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final ProductosService service = ProductosService();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: FutureBuilder<Producto?>(
        future: service.obtenerProductoPorId(productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar el producto: ${snapshot.error}'));
          }
          final producto = snapshot.data;
          if (producto == null) {
            return const Center(child: Text('Producto no encontrado'));
          }

          final fotos = producto.fotos;
          final imageUrl = (fotos.isNotEmpty) ? fotos.first : null;
          final precioStr = producto.precio.toStringAsFixed(2);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                if (fotos.isNotEmpty)
                  SizedBox(
                    height: 320,
                    child: PageView(
                      children: fotos.map((url) {
                        return CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 80),
                        );
                      }).toList(),
                    ),
                  )
                else
                  Container(
                    height: 240,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.chair, size: 80, color: Colors.grey)),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(producto.titulo ?? 'Sin título', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('S/ $precioStr', style: const TextStyle(fontSize: 20, color: Colors.green)),
                    const SizedBox(height: 12),
                    Text(producto.descripcion ?? 'Sin descripción', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    Text('Medidas: Alto ${producto.medidas?['alto'] ?? '-'} x Ancho ${producto.medidas?['ancho'] ?? '-'} x Fondo ${producto.medidas?['fondo'] ?? '-'}'),
                    const SizedBox(height: 12),
                    Text(producto.stock > 0 ? 'En stock: ${producto.stock}' : 'Agotado', style: TextStyle(color: producto.stock > 0 ? Colors.black : Colors.red)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (producto.stock > 0)
                            ? () {
                                
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto agregado al carrito (prototipo)')));
                              }
                            : null,
                        child: const Text('Agregar al carrito'),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}