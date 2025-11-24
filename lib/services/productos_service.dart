import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto.dart';

class ProductosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🟫 OBTENER TODOS LOS PRODUCTOS
  Stream<List<Producto>> obtenerProductos() {
    return _db.collection('Productos').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => Producto.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // 🟫 STREAM FILTRADO (CATEGORIAS / DESTACADOS)
  Stream<List<Producto>> streamProductos({
    String? categoria,
    bool soloDestacados = false,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('Productos');

    if (categoria != null && categoria.isNotEmpty) {
      query = query.where('categoria', isEqualTo: categoria);
    }

    if (soloDestacados) {
      query = query.where('destacado', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Producto.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // 🟫 OBTENER PRODUCTO POR ID
  Future<Producto?> obtenerProductoPorId(String id) async {
    final doc = await _db.collection('Productos').doc(id).get();
    if (doc.exists) {
      return Producto.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  // 🟫 MÉTODO NUEVO — PARA PRODUCTOS SIMILARES
  Future<List<Producto>> obtenerProductosPorCategoria(String categoria) async {
    final query = await _db
        .collection('Productos')
        .where('categoria', isEqualTo: categoria)
        .get();

    return query.docs
        .map((doc) => Producto.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // 🟫 BÚSQUEDA INTELIGENTE
  Future<List<Producto>> searchAdvanced(String query) async {
    final q = query.toLowerCase().trim();
    final palabras = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    final snapshot = await _db.collection('Productos').get();
    final todos = snapshot.docs
        .map((doc) => Producto.fromFirestore(doc.data(), doc.id))
        .toList();

    return todos.where((p) {
      final texto = ('${p.titulo} ${p.descripcion}')
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ');
      return palabras.every((w) => texto.contains(w));
    }).toList();
  }
}
