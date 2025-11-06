import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/productos_service.dart';
import '../../models/producto.dart';
import '../../models/carrito_item.dart';
import '../product_detail/product_detail_screen.dart';
import '../carrito/carrito_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ProductosService _service = ProductosService();

  String selectedCategory = '';
  String searchQuery = '';
  List<Producto>? searchResults;
  bool searching = false;
  bool refreshing = false;
  bool destacadosOnly = false;

  final List<CarritoItem> _carrito = [];

  final List<String> _categorias = [
    'Todas',
    'Sala',
    'Dormitorio',
    'Cocina',
    'Oficina',
    'Accesorios',
  ];

  // 👉 Controlador para mantener la posición del scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => refreshing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => refreshing = false);
  }

  Future<void> _doSearch(String q) async {
    setState(() {
      searching = true;
      searchQuery = q;
      searchResults = null;
    });
    try {
      final results = await _service.searchByTitle(q);
      if (!mounted) return;
      setState(() {
        searchResults = results;
      });
    } catch (_) {
      if (mounted) setState(() => searchResults = []);
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  void _agregarAlCarrito(Producto p) {
    final existente = _carrito.indexWhere((item) => item.id == p.id);
    if (existente >= 0) {
      setState(() => _carrito[existente].cantidad++);
    } else {
      setState(() {
        _carrito.add(CarritoItem(
          id: p.id,
          nombre: p.titulo,
          precio: p.precio,
          imagen: p.fotos.isNotEmpty ? p.fotos.first : '',
        ));
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${p.titulo} agregado al carrito 🛒'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brown = const Color(0xFF795548);
    final width = MediaQuery.of(context).size.width;
    final crossAxis = width > 800 ? 3 : (width > 600 ? 3 : 2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: brown,
        title: const Text(
          'Catálogo - Mueblería Zárate',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined, color: Colors.white),
            onPressed: () async {
              final q = await showSearch<String>(
                context: context,
                delegate: _ProductSearchDelegate(initialQuery: searchQuery),
              );
              if (q != null && q.isNotEmpty) _doSearch(q);
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            tooltip: 'Ver carrito',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CarritoScreen(
                    carrito: _carrito,
                    onClear: () => setState(() {}),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: brown,
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                scrollDirection: Axis.horizontal,
                itemCount: _categorias.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categorias[i];
                  final selected = (selectedCategory.isEmpty && cat == 'Todas') ||
                      selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => selectedCategory = (cat == 'Todas' ? '' : cat));
                    },
                    selectedColor: brown,
                    backgroundColor: const Color(0xFFD7CCC8),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.brown[800],
                      fontWeight: FontWeight.w500,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  );
                },
              ),
            ),

            Expanded(
              child: searching
                  ? const Center(child: CircularProgressIndicator())
                  : (searchQuery.isNotEmpty
                      ? _buildSearchList(crossAxis, brown)
                      : _buildStreamGrid(crossAxis, brown)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchList(int crossAxis, Color brown) {
    if (searchResults == null) {
      return const Center(child: Text('Realiza una búsqueda'));
    }
    if (searchResults!.isEmpty) {
      return const Center(child: Text('No se encontraron resultados'));
    }
    return _buildGrid(searchResults!, crossAxis, brown);
  }

  Widget _buildStreamGrid(int crossAxis, Color brown) {
    return StreamBuilder<List<Producto>>(
      stream: _service.streamProductos(
        categoria: selectedCategory.isEmpty ? null : selectedCategory,
      ),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error al cargar productos: ${snap.error}'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final productos = snap.data ?? [];
        if (productos.isEmpty) {
          return const Center(child: Text('No hay productos disponibles.'));
        }

        final filtrados = destacadosOnly
            ? productos.where((p) => p.destacado == true).toList()
            : productos;

        return _buildGrid(filtrados, crossAxis, brown);
      },
    );
  }

  Widget _buildGrid(List<Producto> productos, int crossAxis, Color brown) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        controller: _scrollController, // ✅ Mantiene posición
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: productos.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxis,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, i) => _productCard(productos[i], brown),
      ),
    );
  }

  Widget _productCard(Producto p, Color brown) {
    final imageUrl = (p.fotos.isNotEmpty) ? p.fotos.first : null;
    final precioStr = p.precio.toStringAsFixed(2);

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)));
      },
      child: Card(
        elevation: 4,
        color: Colors.white,
        shadowColor: brown.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null)
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 48),
                      )
                    else
                      Container(
                        color: Colors.brown[50],
                        child: const Icon(Icons.chair, size: 48, color: Colors.brown),
                      ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: brown.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'S/ $precioStr',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: brown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.categoria,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                      Text(
                        p.stock > 0 ? 'Disponible' : 'Agotado',
                        style: TextStyle(
                          fontSize: 12,
                          color: p.stock > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (p.stock > 0)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart,
                            size: 18, color: Color(0xFF6A1B9A)),
                        label: const Text(
                          'Agregar',
                          style: TextStyle(
                            color: Color(0xFF6A1B9A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          side: const BorderSide(color: Colors.white, width: 2), // ✅ borde blanco
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size.fromHeight(38),
                          foregroundColor: const Color(0xFF6A1B9A), // ✅ texto morado
                        ),
                        onPressed: () => _agregarAlCarrito(p),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSearchDelegate extends SearchDelegate<String> {
  final String initialQuery;
  _ProductSearchDelegate({this.initialQuery = ''})
      : super(searchFieldLabel: 'Buscar productos...');

  @override
  String get searchFieldLabel => 'Buscar productos...';

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.search),
            title: Text('Buscar por nombre o categoría...'),
          ),
        ],
      );
    }
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.search),
          title: Text('Buscar: $query'),
          onTap: () => close(context, query),
        ),
      ],
    );
  }
}
