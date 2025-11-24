import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/carrito_item.dart';
import '../../services/carrito_service.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  // ----- PALETA DE COLORES MEJORADA -----
  static const Color primaryColor = Color(0xFF6D4C41);
  static const Color secondaryColor = Color(0xFF4E342E);
  static const Color accentColor = Color(0xFFA1887F);
  static const Color lightColor = Color(0xFFD7CCC8);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);

  final carritoService = CarritoService();
  final _formKey = GlobalKey<FormState>();

  String direccion = "";
  String telefono = "";
  String _metodoPago = "Efectivo";
  String _tipoEmpaquetado = "Simple";
  bool _isLoading = false;
  bool _userLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  // ---------------------------------------------------------------------
  //  VERIFICAR AUTENTICACIÓN
  // ---------------------------------------------------------------------
  void _checkAuthentication() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _userLoggedIn = user != null;
    });
    
    if (_userLoggedIn) {
      _cargarDatosUsuario();
    }
  }

  // ---------------------------------------------------------------------
  //  CARGAR DIRECCIÓN Y TELÉFONO DEL USUARIO
  // ---------------------------------------------------------------------
  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          direccion = doc["direccion"] ?? "";
          telefono = doc["telefono"] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Error cargando datos de usuario: $e");
    }
  }

  // ---------------------------------------------------------------------
  //  CÁLCULOS - ACTUALIZADOS PARA USAR EL NUEVO SERVICE
  // ---------------------------------------------------------------------
  double get subtotal => carritoService.subtotal;

  double get costoEmpaquetado {
    double costo = 0;
    switch (_tipoEmpaquetado) {
      case "Doble":
        costo = 5;
        break;
      case "Completo":
        costo = 10;
        break;
    }
    return costo * carritoService.totalCantidadProductos;
  }

  double get igv => carritoService.calcularIgv(costoEmpaquetado);
  double get envio => carritoService.envio;
  double get totalFinal => carritoService.calcularTotal(costoEmpaquetado: costoEmpaquetado);

  // ---------------------------------------------------------------------
  //  ACCIONES DEL CARRITO - ACTUALIZADAS
  // ---------------------------------------------------------------------

  void _incrementar(CarritoItem item) {
    setState(() => carritoService.incrementar(item.id));
  }

  void _decrementar(CarritoItem item) {
    setState(() => carritoService.decrementar(item.id));
  }

  void _eliminarProducto(CarritoItem item) {
    setState(() => carritoService.eliminar(item.id));
  }

  void _vaciarCarrito() {
    if (carritoService.estaVacio) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Vaciar carrito",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("¿Seguro que deseas eliminar todos los productos del carrito?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              carritoService.limpiar();
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Vaciar"),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  //  DIALOGO PARA INICIAR SESIÓN
  // ---------------------------------------------------------------------
  void _mostrarDialogoInicioSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Iniciar Sesión",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Debes iniciar sesión para realizar una compra"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar el diálogo
              Navigator.pushNamed(context, '/login'); // Navegar al login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Iniciar Sesión"),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  //  GUARDAR PEDIDO EN FIRESTORE
  // ---------------------------------------------------------------------
  Future<void> _finalizarCompra() async {
    if (!_userLoggedIn) {
      _mostrarDialogoInicioSesion();
      return;
    }

    if (direccion.isEmpty || telefono.isEmpty) {
      _alerta("Completa tus datos de entrega", Colors.orange);
      return;
    }

    // Usar el nuevo método para validar si puede proceder al checkout
    if (!carritoService.puedeProcederCheckout) {
      _alerta("El carrito está vacío", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    // Usar el método de resumen del nuevo service para mayor precisión
    final resumen = carritoService.obtenerResumenPedido(costoEmpaquetado: costoEmpaquetado);

    final pedido = {
      "productos": carritoService.items
          .map((p) => {
                "id": p.id,
                "nombre": p.nombre,
                "precio": p.precio,
                "cantidad": p.cantidad,
                "subtotal": p.precio * p.cantidad,
                "foto": p.imagen,
              })
          .toList(),
      "subtotal": resumen['subtotal']!,
      "costoEmpaquetado": resumen['costoEmpaquetado']!,
      "tipoEmpaquetado": _tipoEmpaquetado,
      "igv": resumen['igv']!,
      "envio": resumen['envio']!,
      "total": resumen['total']!,
      "direccion": direccion,
      "telefono": telefono,
      "metodoPago": _metodoPago,
      "estado": "Pendiente",
      "fecha": FieldValue.serverTimestamp(),
    };

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(user.uid)
          .collection("Pedidos")
          .add(pedido);

      // Usar el nuevo método para reiniciar el carrito
      carritoService.reiniciarCarrito();
      _alerta("🎉 Pedido registrado con éxito", Colors.green);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _alerta("Error al registrar pedido", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _alerta(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ---------------------------------------------------------------------
  //  UI GENERAL
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "Carrito de Compras", 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          )
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!carritoService.estaVacio && _userLoggedIn)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
                onPressed: _vaciarCarrito,
              ),
            )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Si el carrito está vacío - usando el nuevo getter
    if (carritoService.estaVacio) {
      return _buildCarritoVacio();
    }

    // Si hay productos pero el usuario no está logueado
    if (!_userLoggedIn) {
      return _buildUsuarioNoLogueado();
    }

    // Usuario logueado con productos en el carrito
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildListaProductos(),
            const SizedBox(height: 24),
            _seccion("📦 Datos de entrega", _buildDatosEntrega()),
            const SizedBox(height: 16),
            _seccion("💳 Método de pago", _buildMetodoPago()),
            const SizedBox(height: 16),
            _seccion("🎁 Tipo de empaquetado", _buildEmpaquetado()),
            const SizedBox(height: 16),
            _seccion("🧾 Resumen del pedido", _buildResumen()),
            const SizedBox(height: 24),
            _buildBotonFinalizar(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  //  PANTALLA: USUARIO NO LOGUEADO
  // ---------------------------------------------------------------------
  Widget _buildUsuarioNoLogueado() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: lightColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                size: 60,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Inicia sesión para continuar",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Tienes ${carritoService.items.length} producto(s) en tu carrito",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Inicia sesión para proceder con la compra",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Regresar"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navegar a la pantalla de login
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Iniciar sesión"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Navegar a la pantalla de registro
                Navigator.pushNamed(context, '/register');
              },
              child: Text(
                "¿No tienes cuenta? Regístrate",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _vaciarCarrito,
              child: Text(
                "Vaciar carrito",
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  //  PANTALLA: CARRITO VACÍO
  // ---------------------------------------------------------------------
  Widget _buildCarritoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: lightColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Tu carrito está vacío",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Agrega productos para continuar",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Seguir comprando"),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  //  SECCIÓN ESTILIZADA
  // ---------------------------------------------------------------------
  Widget _seccion(String titulo, Widget contenido) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          contenido,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  //  LISTA DE PRODUCTOS MEJORADA
  // ---------------------------------------------------------------------
  Widget _buildListaProductos() {
    return Column(
      children: carritoService.items.map((item) {
        final subtotalItem = item.cantidad * item.precio;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // IMAGEN DEL PRODUCTO
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: item.imagen,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.chair_outlined,
                          color: Colors.grey,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // INFORMACIÓN DEL PRODUCTO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "S/. ${item.precio.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Subtotal: S/. ${subtotalItem.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // CONTROLES DE CANTIDAD Y ELIMINAR
                Column(
                  children: [
                    // CONTROLES DE CANTIDAD
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => _decrementar(item),
                            icon: Icon(Icons.remove, size: 18, color: primaryColor),
                            padding: const EdgeInsets.all(4),
                          ),
                          Text(
                            "${item.cantidad}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _incrementar(item),
                            icon: Icon(Icons.add, size: 18, color: primaryColor),
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // BOTÓN ELIMINAR
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () => _eliminarProducto(item),
                        icon: Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------
  //  DATOS DE ENTREGA MEJORADOS
  // ---------------------------------------------------------------------
  Widget _buildDatosEntrega() {
    return Column(
      children: [
        _itemEntrega("Dirección", direccion, Icons.location_on_outlined),
        const SizedBox(height: 12),
        _itemEntrega("Teléfono", telefono, Icons.phone_iphone_outlined),
      ],
    );
  }

  Widget _itemEntrega(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : "No registrado",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // MÉTODO DE PAGO MEJORADO
  // ---------------------------------------------------------------------
  Widget _buildMetodoPago() {
    return Column(
      children: [
        _radioPago("Efectivo", Icons.money_outlined),
        _radioPago("Yape / Plin", Icons.phone_android_outlined),
        _radioPago("Tarjeta de crédito/débito", Icons.credit_card_outlined),
      ],
    );
  }

  Widget _radioPago(String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _metodoPago == value ? primaryColor : Colors.grey.shade300,
          width: _metodoPago == value ? 1.5 : 1,
        ),
      ),
      child: RadioListTile(
        value: value,
        groupValue: _metodoPago,
        activeColor: primaryColor,
        title: Row(
          children: [
            Icon(icon, color: _metodoPago == value ? primaryColor : Colors.grey),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: _metodoPago == value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        onChanged: (v) => setState(() => _metodoPago = v!),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // EMPAQUETADO MEJORADO
  // ---------------------------------------------------------------------
  Widget _buildEmpaquetado() {
    return Column(
      children: [
        _radioEmpaque("Simple (Gratis)", "Simple", Icons.inventory_2_outlined),
        _radioEmpaque("Doble (+S/.5)", "Doble", Icons.layers_outlined),
        _radioEmpaque("Completo (+S/.10)", "Completo", Icons.card_giftcard_outlined),
      ],
    );
  }

  Widget _radioEmpaque(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _tipoEmpaquetado == value ? primaryColor : Colors.grey.shade300,
          width: _tipoEmpaquetado == value ? 1.5 : 1,
        ),
      ),
      child: RadioListTile(
        value: value,
        groupValue: _tipoEmpaquetado,
        activeColor: primaryColor,
        title: Row(
          children: [
            Icon(icon, color: _tipoEmpaquetado == value ? primaryColor : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: _tipoEmpaquetado == value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        onChanged: (v) => setState(() => _tipoEmpaquetado = v!),
      ),
    );
  }

  // ---------------------------------------------------------------------
  //  RESUMEN DEL PEDIDO MEJORADO
  // ---------------------------------------------------------------------
  Widget _buildResumen() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _rowResumen("Subtotal", subtotal),
          _rowResumen("Empaquetado", costoEmpaquetado),
          _rowResumen("IGV (18%)", igv),
          _rowResumen("Envío", envio),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          _rowResumen("TOTAL", totalFinal, bold: true),
        ],
      ),
    );
  }

  Widget _rowResumen(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            "S/. ${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: bold ? primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BOTÓN FINALIZAR COMPRA MEJORADO
  // ---------------------------------------------------------------------
  Widget _buildBotonFinalizar() {
    return _isLoading
        ? Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 16),
                const Text(
                  "Procesando pedido...",
                  style: TextStyle(color: primaryColor),
                ),
              ],
            ),
          )
        : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finalizarCompra,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: primaryColor.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    "Finalizar compra",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "S/. ${totalFinal.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}