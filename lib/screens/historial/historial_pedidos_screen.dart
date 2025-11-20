import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HistorialPedidosScreen extends StatefulWidget {
  const HistorialPedidosScreen({super.key});

  @override
  State<HistorialPedidosScreen> createState() => _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState extends State<HistorialPedidosScreen> {
  String filtroEstado = 'Todos';
  String searchQuery = '';
  bool _userLoggedIn = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  //  VERIFICAR AUTENTICACIÓN
  // ---------------------------------------------------------------------
  void _checkAuthentication() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _userLoggedIn = user != null;
    });
  }

  // ---------------------------------------------------------------------
  //  UI PRINCIPAL
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F3),
      appBar: AppBar(
        title: const Text(
          "Historial de Pedidos",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF795548),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _userLoggedIn ? _buildHistorialContent() : _buildUsuarioNoLogueado(),
    );
  }

  // ---------------------------------------------------------------------
  //  CONTENIDO PARA USUARIO NO LOGUEADO
  // ---------------------------------------------------------------------
  Widget _buildUsuarioNoLogueado() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFD7CCC8).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 70,
                color: const Color(0xFF8D6E63),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              "Inicia sesión para ver tu historial",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4E342E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Accede a tu cuenta para revisar todos tus pedidos anteriores y su estado actual",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8D6E63),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navegar a la pantalla de login
                  Navigator.pushNamed(context, 'auth/login_screen');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF795548),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Iniciar sesión",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Navegar a la pantalla de registro
                Navigator.pushNamed(context, 'auth/register_screen');
              },
              child: const Text(
                "¿No tienes cuenta? Regístrate aquí",
                style: TextStyle(
                  color: Color(0xFF795548),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  //  CONTENIDO PARA USUARIO LOGUEADO
  // ---------------------------------------------------------------------
  Widget _buildHistorialContent() {
    final user = FirebaseAuth.instance.currentUser;
    
    // Consulta mejorada para asegurar el orden correcto
    final pedidosRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .collection('Pedidos')
        .orderBy('fecha', descending: true);

    return Column(
      children: [
        // 🔍 BUSCADOR MEJORADO
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Buscar por producto...",
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF795548).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search, color: Color(0xFF795548)),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF795548), width: 1.5),
              ),
            ),
            onChanged: (value) {
              setState(() => searchQuery = value.trim().toLowerCase());
            },
          ),
        ),

        // 🏷️ FILTRO DE ESTADO MEJORADO
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF795548).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, 
                        size: 18, color: const Color(0xFF795548)),
                    const SizedBox(width: 6),
                    const Text(
                      "Filtrar por:",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: filtroEstado,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: const Color(0xFF795548)),
                    items: [
                      'Todos',
                      'Pendiente',
                      'En Proceso',
                      'Completado',
                      'Cancelado'
                    ].map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(color: Color(0xFF5D4037)),
                      ),
                    )).toList(),
                    onChanged: (value) => setState(() => filtroEstado = value!),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 📄 LISTA DE PEDIDOS MEJORADA
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: pedidosRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (snapshot.hasError) {
                return _buildErrorState();
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              List<QueryDocumentSnapshot> pedidos = snapshot.data!.docs;

              // FILTRO POR ESTADO
              if (filtroEstado != 'Todos') {
                pedidos = pedidos
                    .where((p) {
                      final estado = p['estado'] ?? 'Pendiente';
                      return estado == filtroEstado;
                    })
                    .toList();
              }

              // FILTRO POR BÚSQUEDA
              if (searchQuery.isNotEmpty) {
                pedidos = pedidos.where((p) {
                  try {
                    final productos = List<Map<String, dynamic>>.from(p['productos'] ?? []);
                    final productosStr = productos
                        .map((e) => (e['nombre'] ?? '').toLowerCase())
                        .join(" ");
                    return productosStr.contains(searchQuery);
                  } catch (e) {
                    return false;
                  }
                }).toList();
              }

              if (pedidos.isEmpty) {
                return _buildEmptyStateWithFilters();
              }

              // Ordenar por fecha de forma adicional para asegurar el orden
              pedidos.sort((a, b) {
                try {
                  final fechaA = (a['fecha'] as Timestamp).toDate();
                  final fechaB = (b['fecha'] as Timestamp).toDate();
                  return fechaB.compareTo(fechaA); // Más reciente primero
                } catch (e) {
                  return 0;
                }
              });

              return ListView.builder(
                itemCount: pedidos.length,
                padding: const EdgeInsets.all(16),
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final p = pedidos[index];
                  return _buildPedidoItem(p, index);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPedidoItem(QueryDocumentSnapshot p, int index) {
    try {
      final productos = List<Map<String, dynamic>>.from(p['productos'] ?? []);
      final estado = p['estado'] ?? 'Pendiente';
      final total = (p['total'] ?? 0).toDouble();
      
      // Manejo seguro de la fecha
      DateTime fecha;
      try {
        if (p['fecha'] is Timestamp) {
          fecha = (p['fecha'] as Timestamp).toDate();
        } else if (p['fecha'] is String) {
          fecha = DateTime.parse(p['fecha']);
        } else {
          fecha = DateTime.now();
        }
      } catch (e) {
        fecha = DateTime.now();
      }

      final direccion = p['direccion'] ?? 'Sin dirección';
      final telefono = p['telefono'] ?? 'Sin teléfono';
      final tipoEmpaquetado = p['tipoEmpaquetado'] ?? 'No registrado';
      final costoEmpaquetado = (p['costoEmpaquetado'] ?? 0).toDouble();
      final metodoPago = p['metodoPago'] ?? 'Desconocido';
      final igv = (p['igv'] ?? 0).toDouble();
      final envio = (p['envio'] ?? 0).toDouble();

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          
          // 🧾 CABECERA MEJORADA
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF795548).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: const Color(0xFF795548),
              size: 24,
            ),
          ),

          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pedido #${index + 1}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${_getDiaSemana(fecha.weekday)} ${fecha.day}/${fecha.month}/${fecha.year}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4E342E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${_formatHora(fecha)}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8D6E63),
                ),
              ),
            ],
          ),

          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Text(
                  "S/. ${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6D4C41),
                  ),
                ),
                const Spacer(),
                _buildEstadoBonito(estado),
              ],
            ),
          ),

          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F5F3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🛒 PRODUCTOS CON FOTOS
                  _buildSeccionTitulo("Productos comprados"),
                  const SizedBox(height: 12),

                  if (productos.isEmpty)
                    _buildEmptyProductos()
                  else
                    ...productos.map((prod) => _buildProductoItem(prod)).toList(),

                  const SizedBox(height: 16),

                  // 📌 INFORMACIÓN DEL PEDIDO
                  _buildSeccionTitulo("Información del pedido"),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRowMejorada("Dirección", direccion),
                        _buildInfoRowMejorada("Teléfono", telefono),
                        _buildInfoRowMejorada("Empaquetado", tipoEmpaquetado),
                        _buildInfoRowMejorada("Costo empaquetado", "S/. ${costoEmpaquetado.toStringAsFixed(2)}"),
                        _buildInfoRowMejorada("Método de pago", metodoPago),
                        _buildInfoRowMejorada("IGV", "S/. ${igv.toStringAsFixed(2)}"),
                        _buildInfoRowMejorada("Envío", "S/. ${envio.toStringAsFixed(2)}"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔢 TOTAL MEJORADO
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFF795548).withOpacity(0.1),
                          const Color(0xFF5D4037).withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total del pedido",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4E342E),
                          ),
                        ),
                        Text(
                          "S/. ${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4E342E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    } catch (e) {
      return _buildErrorPedidoItem();
    }
  }

  Widget _buildProductoItem(Map<String, dynamic> prod) {
    final fotoUrl = prod['foto']?.toString() ?? '';
    final nombre = prod['nombre']?.toString() ?? 'Producto';
    final cantidad = prod['cantidad']?.toString() ?? '0';
    final precio = (prod['precio'] ?? 0).toDouble();
    final subtotal = (prod['subtotal'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGEN DEL PRODUCTO
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: fotoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: fotoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF795548),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildPlaceholderIcon(),
                    )
                  : _buildPlaceholderIcon(),
            ),
          ),

          // INFORMACIÓN DEL PRODUCTO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4E342E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _buildInfoRowMejorada("Cantidad", cantidad),
                _buildInfoRowMejorada("Precio unitario", "S/. ${precio.toStringAsFixed(2)}"),
                _buildInfoRowMejorada("Subtotal", "S/. ${subtotal.toStringAsFixed(2)}"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.chair_outlined,
        color: Colors.grey,
        size: 30,
      ),
    );
  }

  Widget _buildEmptyProductos() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Text(
          "No hay información de productos",
          style: TextStyle(
            color: Color(0xFF8D6E63),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPedidoItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Error al cargar la información del pedido",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: const Color(0xFF795548)),
          const SizedBox(height: 16),
          const Text(
            "Cargando pedidos...",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8D6E63),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: const Color(0xFF8D6E63)),
          const SizedBox(height: 16),
          const Text(
            "Error al cargar los pedidos",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF5D4037),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF795548).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 50,
              color: const Color(0xFF8D6E63),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No hay pedidos",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Realiza tu primer pedido para comenzar",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8D6E63),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithFilters() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF795548).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 50,
              color: const Color(0xFF8D6E63),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            filtroEstado != 'Todos' 
                ? "No hay pedidos con estado '$filtroEstado'"
                : "No se encontraron pedidos",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Intenta con otros filtros o términos de búsqueda",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8D6E63),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF795548).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5D4037),
        ),
      ),
    );
  }

  /// 📌 Fila de información key-value MEJORADA
  Widget _buildInfoRowMejorada(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$title:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF5D4037),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF6D4C41),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Badge para ESTADO MEJORADO
  Widget _buildEstadoBonito(String estado) {
    Color bg, text;
    IconData icon;

    switch (estado.toLowerCase()) {
      case "completado":
        bg = const Color(0xFFE8F5E8);
        text = const Color(0xFF2E7D32);
        icon = Icons.check_circle;
        break;

      case "en proceso":
        bg = const Color(0xFFFFF8E1);
        text = const Color(0xFFF57C00);
        icon = Icons.autorenew;
        break;

      case "pendiente":
        bg = const Color(0xFFE3F2FD);
        text = const Color(0xFF1565C0);
        icon = Icons.schedule;
        break;

      case "cancelado":
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC62828);
        icon = Icons.cancel;
        break;

      default:
        bg = Colors.grey.shade200;
        text = Colors.grey.shade700;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 6),
          Text(
            estado,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  String _getDiaSemana(int dia) {
    final dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return dias[dia];
  }

  String _formatHora(DateTime fecha) {
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}