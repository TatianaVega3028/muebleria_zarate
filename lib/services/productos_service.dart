import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto.dart';

class ProductosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Producto>> obtenerProductos() {
    return _db.collection('Productos').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => Producto.fromFirestore(doc.data(), doc.id))
            .toList());
  }

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


  Future<Producto?> obtenerProductoPorId(String id) async {
    final doc = await _db.collection('Productos').doc(id).get();
    if (doc.exists) {
      return Producto.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }


  Future<List<Producto>> searchByTitle(String query) async {
    final snapshot = await _db
        .collection('Productos')
        .where('titulo', isGreaterThanOrEqualTo: query)
        .where('titulo', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs
        .map((doc) => Producto.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}
