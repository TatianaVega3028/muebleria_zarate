import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../services/productos_service.dart';
import '../../services/carrito_service.dart';
import '../../models/carrito_item.dart';
import '../carrito/carrito_screen.dart';
import 'product_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductosService _service = ProductosService();
  final CarritoService _carrito = CarritoService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF795548);
    const Color backgroundColor = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Detalle del producto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 3,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CarritoScreen()),
                  ).then((_) => setState(() {}));
                },
              ),
              if (_carrito.totalCantidadProductos > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _carrito.totalCantidadProductos > 99
                          ? '99+'
                          : _carrito.totalCantidadProductos.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
      body: FutureBuilder<Producto?>(
        future: _service.obtenerProductoPorId(widget.productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar el producto'));
          }

          final producto = snapshot.data;
          if (producto == null) {
            return const Center(child: Text('Producto no encontrado'));
          }

          final fotos = producto.fotos;
          final precioStr = producto.precio.toStringAsFixed(2);

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (fotos.isNotEmpty)
                          SizedBox(
                            height: 300,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: PageView(
                                children: fotos.map((url) {
                                  return CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        const Center(child: CircularProgressIndicator()),
                                    errorWidget: (_, __, ___) =>
                                        const Icon(Icons.broken_image, size: 80),
                                  );
                                }).toList(),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: const Center(
                              child: Icon(Icons.chair, size: 80, color: Colors.white),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto.titulo ?? 'Sin título',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'S/ $precioStr',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                producto.descripcion ?? 'Sin descripción',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 12),
                              Text(
                                'Medidas: Alto ${producto.medidas?['alto'] ?? '-'} cm × '
                                'Ancho ${producto.medidas?['ancho'] ?? '-'} cm × '
                                'Fondo ${producto.medidas?['fondo'] ?? '-'} cm',
                                style: const TextStyle(fontSize: 15, color: Colors.black54),
                              ),

                              const SizedBox(height: 12),
                              Text(
                                producto.stock > 0 ? 'En stock: ${producto.stock}' : 'Agotado',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: producto.stock > 0 ? Colors.black87 : Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add_shopping_cart),
                                  label: const Text(
                                    'Agregar al carrito',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: producto.stock > 0
                                      ? () {
                                          _carrito.agregar(CarritoItem(
                                            id: producto.id,
                                            nombre: producto.titulo,
                                            precio: producto.precio,
                                            imagen: producto.fotos.isNotEmpty
                                                ? producto.fotos.first
                                                : '',
                                            cantidad: 1,
                                          ));
                                          setState(() {});

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${producto.titulo} agregado al carrito 🛒'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // -------------------------
                // 🟫 PRODUCTOS SIMILARES
                // -------------------------
                FutureBuilder<List<Producto>>(
                  future: _service.obtenerProductosPorCategoria(producto.categoria),
                  builder: (context, similarSnapshot) {
                    if (!similarSnapshot.hasData) return const SizedBox();

                    final similares = similarSnapshot.data!
                        .where((p) => p.id != producto.id)
                        .toList();

                    if (similares.isEmpty) return const SizedBox();

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Productos similares",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            height: 260,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: similares.length,
                              itemBuilder: (_, i) {
                                final prod = similares[i];

                                return SizedBox(
                                  width: 170,
                                  height: 260,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(productId: prod.id),
                                        ),
                                      ).then((_) => setState(() {}));
                                    },
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 3,
                                      child: Column(
                                        children: [
                                          // ---------------- IMAGEN ----------------
                                          SizedBox(
                                            height: 120,
                                            width: double.infinity,
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                              child: CachedNetworkImage(
                                                imageUrl: prod.fotos.isNotEmpty ? prod.fotos.first : "",
                                                fit: BoxFit.cover,
                                                errorWidget: (_, __, ___) =>
                                                    const Center(child: Icon(Icons.broken_image, size: 48)),
                                              ),
                                            ),
                                          ),
  
                                          // -------------- CONTENIDO ----------------
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    prod.titulo,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    "S/ ${prod.precio.toStringAsFixed(2)}",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
  
                                                  const Spacer(),
  
                                                  // ---------------- BOTÓN (NO NAVEGA) ----------------
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        _carrito.agregar(CarritoItem(
                                                          id: prod.id,
                                                          nombre: prod.titulo,
                                                          precio: prod.precio,
                                                          imagen: prod.fotos.isNotEmpty ? prod.fotos.first : '',
                                                          cantidad: 1,
                                                        ));
                                                        setState(() {});
  
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text('${prod.titulo} agregado al carrito 🛒'),
                                                            behavior: SnackBarBehavior.floating,
                                                          ),
                                                        );
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.brown,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        "Agregar",
                                                        style: TextStyle(fontSize: 13),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
