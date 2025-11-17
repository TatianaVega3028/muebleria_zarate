import 'package:flutter/material.dart';
import '../models/carrito_item.dart';

class CarritoService with ChangeNotifier {
  // Singleton (una sola instancia para toda la app)
  static final CarritoService _instance = CarritoService._internal();
  factory CarritoService() => _instance;
  CarritoService._internal();

  final List<CarritoItem> _carrito = [];

  List<CarritoItem> get items => List.unmodifiable(_carrito);

  void agregar(CarritoItem item) {
    final index = _carrito.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _carrito[index].cantidad++;
    } else {
      _carrito.add(item);
    }
    notifyListeners();
  }

  void eliminar(CarritoItem item) {
    _carrito.remove(item);
    notifyListeners();
  }

  void limpiar() {
    _carrito.clear();
    notifyListeners();
  }

  void incrementar(CarritoItem item) {
    final index = _carrito.indexOf(item);
    if (index >= 0) {
      _carrito[index].cantidad++;
      notifyListeners();
    }
  }

  void decrementar(CarritoItem item) {
    final index = _carrito.indexOf(item);
    if (index >= 0) {
      if (_carrito[index].cantidad > 1) {
        _carrito[index].cantidad--;
      } else {
        _carrito.removeAt(index);
      }
      notifyListeners();
    }
  }

  void actualizarCantidad(String productId, int nuevaCantidad) {
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

  void removerDelCarrito(String productId) {
    _carrito.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  // 🔥 SUMA TOTAL DE TODAS LAS CANTIDADES DEL CARRITO
  int get totalCantidadProductos =>
      _carrito.fold(0, (sum, item) => sum + item.cantidad);

  // Subtotal (precio * cantidad)
  double get subtotal => 
      _carrito.fold(0.0, (sum, i) => sum + (i.precio * i.cantidad));

  // IGV 18% (incluye el costo de empaquetado)
  double calcularIgv(double costoEmpaquetado) =>
      (subtotal + costoEmpaquetado) * 0.18;

  // Envío gratis si supera 150
  double get envio => subtotal >= 150 ? 0.0 : 10.0;

  // Total final
  double calcularTotal({double costoEmpaquetado = 0}) =>
      subtotal + calcularIgv(costoEmpaquetado) + costoEmpaquetado + envio;

  // Getter para mantener compatibilidad
  double get total => calcularTotal();

  bool contieneProducto(String productId) =>
      _carrito.any((item) => item.id == productId);

  int cantidadDeProducto(String productId) {
    final index = _carrito.indexWhere((item) => item.id == productId);
    return index >= 0 ? _carrito[index].cantidad : 0;
  }
}
