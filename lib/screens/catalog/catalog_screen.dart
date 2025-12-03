// lib/screens/catalog/catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/productos_service.dart';
import '../../models/producto.dart';
import '../../models/carrito_item.dart';
import '../../services/carrito_service.dart';
import '../product_detail/product_detail_screen.dart';
import '../carrito/carrito_screen.dart';
import '../../services/favoritos_service.dart';
import '../../screens/catalog/favoritos_page.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with RouteAware {
  final ProductosService _service = ProductosService();
  final CarritoService _carritoService = CarritoService();
  final ScrollController _scrollController = ScrollController();

  String selectedCategory = '';
  String searchQuery = '';
  List<Producto>? searchResults;
  bool searching = false;
  bool refreshing = false;

  final List<String> _categorias = [
    'Todas',
    'Sala',
    'Dormitorio',
    'Cocina',
    'Oficina',
    'Accesorios',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  // 🔥🔥🔥 CUANDO EL USUARIO REGRESA A ESTA PANTALLA → AUTOMÁTICAMENTE REFRESCA
  @override
  void didPopNext() {
    setState(() {
      searchResults = null;
      searchQuery = '';
    });
  }

  Future<void> _refresh() async {
    setState(() => refreshing = true);
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() => refreshing = false);
  }

  Future<void> _doSearch(String q) async {
    setState(() {
      searching = true;
      searchQuery = q;
      searchResults = null;
    });

    try {
      final results = await _service.searchAdvanced(q);
      if (!mounted) return;
      setState(() => searchResults = results);
    } catch (_) {
      if (mounted) setState(() => searchResults = []);
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  void _agregarAlCarrito(Producto p) {
    _carritoService.agregar(
      CarritoItem(
        id: p.id,
        nombre: p.titulo,
        precio: p.precio,
        imagen: p.fotos.isNotEmpty ? p.fotos.first : '',
        cantidad: 1,
      ),
    );

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color.fromARGB(255, 56, 55, 54),
        content: Text('${p.titulo} agregado al carrito 🛒'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF795548);
    const background = Color(0xFFF9F5F3);

    final width = MediaQuery.of(context).size.width;
    final crossAxis = width > 1000
        ? 4
        : (width > 800 ? 3 : (width > 600 ? 2 : 2));

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: brown,
        elevation: 3,
        title: const Text(
          'Catálogo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          //Lo del icono de favoritos//
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritosPage()),
              );
            },
          ),

          //icono carrito//
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CarritoScreen()),
                  ).then((_) => setState(() {}));
                },
              ),
              if (_carritoService.totalCantidadProductos > 0)
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
                      _carritoService.totalCantidadProductos > 99
                          ? '99+'
                          : _carritoService.totalCantidadProductos.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: brown,
        onRefresh: _refresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
                  prefixIcon: const Icon(Icons.search, color: brown),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  searchQuery = value.trim();
                  if (searchQuery.isEmpty) {
                    setState(() => searchResults = null);
                  } else {
                    _doSearch(searchQuery);
                  }
                },
              ),
            ),

            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                itemCount: _categorias.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categorias[i];
                  final selected =
                      (selectedCategory.isEmpty && cat == 'Todas') ||
                      selectedCategory == cat;

                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) => setState(
                      () => selectedCategory = (cat == 'Todas' ? '' : cat),
                    ),
                    selectedColor: brown,
                    backgroundColor: const Color(0xFFD7CCC8),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.brown[800],
                      fontWeight: FontWeight.w500,
                    ),
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

    // Aplicar filtro de categoría a los resultados de búsqueda
    final filteredResults = selectedCategory.isEmpty
        ? searchResults!
        : searchResults!.where((p) => p.categoria == selectedCategory).toList();

    if (filteredResults.isEmpty) {
      return const Center(
        child: Text('No se encontraron resultados en esta categoría'),
      );
    }

    return _buildGrid(filteredResults, crossAxis, brown);
  }

  Widget _buildStreamGrid(int crossAxis, Color brown) {
    return StreamBuilder<List<Producto>>(
      stream: _service.streamProductos(
        categoria: selectedCategory.isEmpty ? null : selectedCategory,
      ),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final productos = snap.data!;
        return _buildGrid(productos, crossAxis, brown);
      },
    );
  }

  Widget _buildGrid(List<Producto> productos, int crossAxis, Color brown) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        controller: _scrollController,
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: p.id),
          ),
        );
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null)
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, size: 48),
                        ),
                      )
                    else
                      Container(
                        color: Colors.brown[50],
                        child: const Icon(
                          Icons.chair,
                          size: 48,
                          color: Colors.brown,
                        ),
                      ),

                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: brown.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          'S/ $precioStr',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    //corazon//
                    Positioned(
                      right: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: () {
                          FavoritosService().toggleFavorito(p);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: ValueListenableBuilder(
                            valueListenable:
                                FavoritosService().favoritosNotifier,
                            builder: (context, favoritos, _) {
                              final esFavorito = FavoritosService().esFavorito(
                                p.id,
                              );

                              return Icon(
                                esFavorito
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: esFavorito ? Colors.red : Colors.grey,
                                size: 24,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, color: brown),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.categoria,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      Text(
                        p.stock > 0 ? 'Disponible' : 'Agotado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: p.stock > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Agregar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size.fromHeight(38),
                        elevation: 2,
                      ),
                      onPressed: p.stock > 0
                          ? () => _agregarAlCarrito(p)
                          : null,
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
