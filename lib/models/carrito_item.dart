class CarritoItem {
  final String id;
  final String nombre;
  final double precio;
  final String imagen;
  int cantidad;

  CarritoItem({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.imagen,
    this.cantidad = 1,
  });
}