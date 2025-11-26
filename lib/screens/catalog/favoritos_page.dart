import 'package:flutter/material.dart';
import '../../services/favoritos_service.dart';
import '../../models/producto.dart';
import '../product_detail/product_detail_screen.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({Key? key}) : super(key: key);

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  @override
  Widget build(BuildContext context) {
    // 🎨 Tus colores (mismos del catálogo)
    const brown = Color(0xFF795548);
    const background = Color(0xFFF9F5F3);

    final List<Producto> lista = FavoritosService().favoritos;

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: brown,
        elevation: 3,
        title: const Text(
          "Mis Favoritos",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: lista.isEmpty
          ? const Center(
              child: Text(
                "Aún no tienes favoritos",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.separated(
              itemCount: lista.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.grey,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final p = lista[index];

                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(productId: p.id),
                      ),
                    );
                  },

                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (p.fotos.isNotEmpty)
                        ? Image.network(
                            p.fotos.first,
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 65,
                            height: 65,
                            color: Colors.brown,
                            child: const Icon(Icons.chair, color: Colors.white),
                          ),
                  ),

                  title: Text(
                    p.titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: brown,
                    ),
                  ),

                  subtitle: Text(
                    "S/ ${p.precio.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),

                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        FavoritosService().eliminar(p.id);
                      });
                    },
                  ),
                );
              },
            ),
    );
  }
}
