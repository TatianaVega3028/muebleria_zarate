// lib/services/favoritos_service.dart
import 'package:flutter/foundation.dart';
import '../models/producto.dart';

class FavoritosService {
  // Singleton
  static final FavoritosService _instancia = FavoritosService._();
  FavoritosService._();
  factory FavoritosService() => _instancia;

  // Lista privada de favoritos
  final List<Producto> _favoritos = [];

  // Notificador para actualizar la UI (se incrementa cuando cambia la lista)
  final ValueNotifier<int> favoritosNotifier = ValueNotifier<int>(0);

  // Obtener lista inmutable
  List<Producto> get favoritos => List.unmodifiable(_favoritos);

  // Verificar si un producto está en favoritos por id
  bool esFavorito(String id) {
    return _favoritos.any((p) => p.id == id);
  }

  // Agregar
  void agregar(Producto p) {
    if (!esFavorito(p.id)) {
      _favoritos.add(p);
      favoritosNotifier.value++;
    }
  }

  // Eliminar
  void eliminar(String id) {
    final removed = _favoritos.removeWhere((p) => p.id == id);
    // removeWhere devuelve void; en todo caso notificamos siempre que llamen eliminar
    favoritosNotifier.value++;
  }

  // Alternar favorito
  void toggleFavorito(Producto p) {
    if (esFavorito(p.id)) {
      _favoritos.removeWhere((x) => x.id == p.id);
    } else {
      _favoritos.add(p);
    }
    favoritosNotifier.value++;
  }

  // Opcional: limpiar lista
  void limpiar() {
    _favoritos.clear();
    favoritosNotifier.value++;
  }
}

