import 'package:flutter/material.dart';
import '../models/producto.dart';

class FavoritosService {
  // 🟤 Instancia única (singleton)
  static final FavoritosService _instancia = FavoritosService._interno();
  factory FavoritosService() => _instancia;
  FavoritosService._interno();

  // 🟤 Lista interna de favoritos
  final List<Producto> _favoritos = [];

  // 🟤 Notificador para saber si cambia la lista
  final ValueNotifier<List<Producto>> favoritosNotifier = ValueNotifier([]);

  // Getter: lista pública
  List<Producto> get favoritos => _favoritos;

  // 🔥 Agregar / quitar favorito
  void toggleFavorito(Producto p) {
    if (esFavorito(p.id)) {
      _favoritos.removeWhere((item) => item.id == p.id);
    } else {
      _favoritos.add(p);
    }
    favoritosNotifier.value = List.from(_favoritos);
  }

  // 🔥 Eliminar por ID
  void eliminar(String id) {
    _favoritos.removeWhere((p) => p.id == id);
    favoritosNotifier.value = List.from(_favoritos);
  }

  // 🔥 Saber si un producto YA es favorito
  bool esFavorito(String id) {
    return _favoritos.any((p) => p.id == id);
  }
}



