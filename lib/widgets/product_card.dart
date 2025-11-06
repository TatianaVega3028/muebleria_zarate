import 'package:flutter/material.dart';
import '../models/producto.dart';

class ProductCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Image.network(producto.fotos.first, fit: BoxFit.cover, width: double.infinity)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(producto.titulo, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('S/. ${producto.precio}'),
            ),
          ],
        ),
      ),
    );
  }
}
