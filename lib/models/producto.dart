class Producto {
  final String id;
  final String titulo;
  final String descripcion;
  final double precio;
  final String categoria;
  final String sku;
  final bool destacado;
  final int stock;
  final List<String> fotos;
  final Map<String, dynamic> medidas;

  Producto({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.precio,
    required this.categoria,
    required this.sku,
    required this.destacado,
    required this.stock,
    required this.fotos,
    required this.medidas,
  });

  factory Producto.fromFirestore(Map<String, dynamic> data, String id) {
    return Producto(
      id: id,
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      precio: (data['precio'] != null)
          ? (data['precio'] is int
              ? (data['precio'] as int).toDouble()
              : (data['precio'] as num).toDouble())
          : 0.0,
      categoria: data['categoria'] ?? '',
      sku: data['sku'] ?? '',
      destacado: data['destacado'] ?? false,
      stock: data['stock'] ?? 0,

      fotos: data['fotos'] != null
          ? List<String>.from(data['fotos'])
          : (data['foto'] != null
              ? List<String>.from(data['foto'])
              : []),

      medidas: data['medidas'] != null
          ? Map<String, dynamic>.from(data['medidas'])
          : {},
    );
  }
}
