import 'package:flutter/material.dart';
import '../models/carrito_item.dart';

class CarritoService with ChangeNotifier {
  // Singleton
  static final CarritoService _instance = CarritoService._internal();
  factory CarritoService() => _instance;
  CarritoService._internal();

  final List<CarritoItem> _carrito = [];

  // Configuración de precios y límites
  static const double _envioGratisMinimo = 150.0;
  static const double _costoEnvio = 10.0;
  static const double _igvPorcentaje = 0.18;

  List<CarritoItem> get items => List.unmodifiable(_carrito);
  
  // Verificar si el carrito está vacío
  bool get estaVacio => _carrito.isEmpty;

  // Agregar producto al carrito con validaciones mejoradas
  void agregar(CarritoItem item) {
    if (item.cantidad <= 0) {
      throw ArgumentError('La cantidad debe ser mayor a 0');
    }

    final index = _carrito.indexWhere((i) => i.id == item.id);
    
    if (index >= 0) {
      _carrito[index].cantidad += item.cantidad;
    } else {
      // Crear una nueva instancia para evitar problemas de referencia
      _carrito.add(CarritoItem(
        id: item.id,
        nombre: item.nombre,
        precio: item.precio,
        imagen: item.imagen,
        cantidad: item.cantidad,
      ));
    }
    notifyListeners();
  }

  // Agregar una unidad de un producto
  void agregarUnidad(String productId) {
    final index = _carrito.indexWhere((i) => i.id == productId);
    if (index >= 0) {
      _carrito[index].cantidad++;
      notifyListeners();
    }
  }

  // Eliminar item completo del carrito
  void eliminar(String productId) {
    _carrito.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  // Limpiar todo el carrito
  void limpiar() {
    _carrito.clear();
    notifyListeners();
  }

  // Incrementar cantidad con validación
  void incrementar(String productId) {
    final index = _carrito.indexWhere((i) => i.id == productId);
    if (index >= 0) {
      _carrito[index].cantidad++;
      notifyListeners();
    }
  }

  // Decrementar cantidad con manejo de eliminación
  void decrementar(String productId) {
    final index = _carrito.indexWhere((i) => i.id == productId);
    if (index >= 0) {
      if (_carrito[index].cantidad > 1) {
        _carrito[index].cantidad--;
      } else {
        _carrito.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Actualizar cantidad específica con validaciones
  void actualizarCantidad(String productId, int nuevaCantidad) {
    if (nuevaCantidad < 0) {
      throw ArgumentError('La cantidad no puede ser negativa');
    }

    final index = _carrito.indexWhere((i) => i.id == productId);
    if (index >= 0) {
      if (nuevaCantidad > 0) {
        _carrito[index].cantidad = nuevaCantidad;
      } else {
        _carrito.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Remover producto del carrito (alias de eliminar)
  void removerDelCarrito(String productId) => eliminar(productId);

  // 🔥 SUMA TOTAL DE TODAS LAS CANTIDADES DEL CARRITO
  int get totalCantidadProductos =>
      _carrito.fold(0, (sum, item) => sum + item.cantidad);

  // Subtotal (precio * cantidad) con precisión decimal
  double get subtotal => 
      _carrito.fold(0.0, (sum, i) => sum + (i.precio * i.cantidad));

  // Verificar si aplica envío gratis
  bool get aplicaEnvioGratis => subtotal >= _envioGratisMinimo;

  // Costo de envío
  double get envio => aplicaEnvioGratis ? 0.0 : _costoEnvio;

  // Calcular IGV (sobre subtotal + costo empaquetado)
  double calcularIgv([double costoEmpaquetado = 0.0]) =>
      (subtotal + costoEmpaquetado) * _igvPorcentaje;

  // Total final con todos los componentes
  double calcularTotal({double costoEmpaquetado = 0.0}) {
    final baseImponible = subtotal + costoEmpaquetado;
    final igv = baseImponible * _igvPorcentaje;
    return baseImponible + igv + envio;
  }

  // Getter para mantener compatibilidad
  double get total => calcularTotal();

  // Verificar si un producto está en el carrito
  bool contieneProducto(String productId) =>
      _carrito.any((item) => item.id == productId);

  // Obtener cantidad específica de un producto
  int cantidadDeProducto(String productId) {
    final item = _carrito.firstWhere(
      (item) => item.id == productId,
      orElse: () => CarritoItem(
        id: '',
        nombre: '',
        precio: 0,
        imagen: '',
        cantidad: 0,
      ),
    );
    return item.cantidad;
  }

  // Obtener item del carrito por ID
  CarritoItem? obtenerItem(String productId) {
    try {
      return _carrito.firstWhere((item) => item.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Método para obtener el resumen del pedido
  Map<String, double> obtenerResumenPedido({double costoEmpaquetado = 0.0}) {
    final igv = calcularIgv(costoEmpaquetado);
    final totalFinal = calcularTotal(costoEmpaquetado: costoEmpaquetado);

    return {
      'subtotal': subtotal,
      'costoEmpaquetado': costoEmpaquetado,
      'igv': igv,
      'envio': envio,
      'total': totalFinal,
    };
  }

  // Validar si el carrito puede proceder al checkout
  bool get puedeProcederCheckout => !estaVacio;

  // Método para clonar el carrito (útil para procesos de checkout)
  List<CarritoItem> clonarCarrito() {
    return _carrito.map((item) => CarritoItem(
      id: item.id,
      nombre: item.nombre,
      precio: item.precio,
      imagen: item.imagen,
      cantidad: item.cantidad,
    )).toList();
  }

  // Reiniciar el carrito después de una compra exitosa
  void reiniciarCarrito() {
    _carrito.clear();
    notifyListeners();
  }
}