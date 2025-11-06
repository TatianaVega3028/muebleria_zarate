import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/carrito_item.dart';
import '../product_detail/product_detail_screen.dart';

class CarritoScreen extends StatefulWidget {
  final List<CarritoItem> carrito;
  final VoidCallback onClear;

  const CarritoScreen({
    super.key,
    required this.carrito,
    required this.onClear,
  });

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  Color get brown => const Color(0xFF795548);

  double get total =>
      widget.carrito.fold(0, (sum, item) => sum + item.precio * item.cantidad);

  void _incrementar(CarritoItem item) {
    setState(() => item.cantidad++);
  }

  void _decrementar(CarritoItem item) {
    setState(() {
      if (item.cantidad > 1) {
        item.cantidad--;
      } else {
        widget.carrito.remove(item);
      }
    });
  }

  void _eliminarProducto(CarritoItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('¿Deseas eliminar este producto del carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() => widget.carrito.remove(item));
              Navigator.pop(ctx);
            },
            child: Text('Eliminar', style: TextStyle(color: brown)),
          ),
        ],
      ),
    );
  }

  void _vaciarCarrito() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Seguro que deseas eliminar todos los productos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() => widget.carrito.clear());
              widget.onClear();
              Navigator.pop(ctx);
            },
            child: Text('Vaciar', style: TextStyle(color: brown)),
          ),
        ],
      ),
    );
  }

  void _finalizarCompra() {
    if (widget.carrito.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Text(
          '¿Deseas finalizar tu compra por un total de S/. ${total.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error: Debes iniciar sesión para comprar.')),
                );
                return;
              }

              final pedido = {
                'productos': widget.carrito.map((item) => {
                  'id': item.id,
                  'nombre': item.nombre,
                  'precio': item.precio,
                  'cantidad': item.cantidad,
                }).toList(),
                'total': total,
                'fecha': FieldValue.serverTimestamp(),
                'estado': 'Pendiente',
              };

              try {
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(user.uid)
                    .collection('Pedidos')
                    .add(pedido);

                Navigator.pop(ctx); // Cierra el diálogo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Compra finalizada con éxito ✅')),
                );
                setState(() => widget.carrito.clear());
                widget.onClear();
              } catch (e) {
                Navigator.pop(ctx); // Cierra el diálogo
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al guardar el pedido: $e')),
                );
              }
            },
            child: Text('Confirmar', style: TextStyle(color: brown)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: brown,
        title: const Text(
          'Carrito de Compras',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.carrito.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Vaciar carrito',
              onPressed: _vaciarCarrito,
            ),
        ],
      ),
      body: widget.carrito.isEmpty
          ? const Center(
              child: Text(
                'Tu carrito está vacío 🛒',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: widget.carrito.length,
                    itemBuilder: (context, index) {
                      final item = widget.carrito[index];
                      return _buildItemCard(item, context);
                    },
                  ),
                ),
                _buildResumenCompra(),
              ],
            ),
    );
  }

  Widget _buildItemCard(CarritoItem item, BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Imagen que lleva al detalle del producto
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(productId: item.id),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imagen.isNotEmpty
                    ? Image.network(
                        item.imagen,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.brown[100],
                        child:
                            const Icon(Icons.chair, size: 40, color: Colors.brown),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Detalles del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'S/. ${item.precio.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: brown,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Botón eliminar individual
            IconButton(
              icon: const Icon(Icons.delete_forever),
              color: Colors.red[400],
              tooltip: 'Eliminar producto',
              onPressed: () => _eliminarProducto(item),
            ),

            // Controles de cantidad
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: brown,
                  onPressed: () => _decrementar(item),
                ),
                Text(
                  '${item.cantidad}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: brown,
                  onPressed: () => _incrementar(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCompra() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.15),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Total: S/. ${total.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: brown,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.payment, color: Colors.white),
            label: const Text(
              'Finalizar compra',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            onPressed: _finalizarCompra,
          ),
        ],
      ),
    );
  }
}