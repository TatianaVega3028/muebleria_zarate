import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../map/location_picker_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _direcciones = [];
  bool _isLoading = true;
  bool _isUploading = false;
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
      _getUserData(user!.uid);
      _getDirecciones(user.uid);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userData = doc.data();
        });
      }
    } catch (e) {
      print('Error al obtener datos: $e');
    }
  }

  Future<void> _getDirecciones(String uid) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('direcciones')
          .orderBy('fecha', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _direcciones = querySnapshot.docs
              .map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  ...data,
                };
              })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al obtener direcciones: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  //  GESTIÓN DE DIRECCIONES
  // ---------------------------------------------------------------------

  // 🔹 Agregar nueva dirección
  Future<void> _agregarDireccion(BuildContext context, String uid) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );

    if (result != null) {
      _mostrarDialogoDireccion(
        context: context,
        uid: uid,
        accion: 'agregar',
        datosIniciales: null,
        ubicacion: result,
      );
    }
  }

  // 🔹 Editar dirección existente
  Future<void> _editarDireccion(
      BuildContext context, String uid, Map<String, dynamic> direccion) async {
    _mostrarDialogoDireccion(
      context: context,
      uid: uid,
      accion: 'editar',
      datosIniciales: direccion,
      ubicacion: null,
    );
  }

  // 🔹 Eliminar dirección
  Future<void> _eliminarDireccion(BuildContext context, String uid, String direccionId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar dirección'),
        content: const Text('¿Estás seguro de que quieres eliminar esta dirección?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(uid)
                    .collection('direcciones')
                    .doc(direccionId)
                    .delete();

                setState(() {
                  _direcciones.removeWhere((dir) => dir['id'] == direccionId);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Dirección eliminada'),
                    backgroundColor: Colors.green.shade600,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Error al eliminar dirección'),
                    backgroundColor: Colors.red.shade600,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 🔹 Diálogo para agregar/editar dirección
  void _mostrarDialogoDireccion({
    required BuildContext context,
    required String uid,
    required String accion,
    required Map<String, dynamic>? datosIniciales,
    required dynamic ubicacion,
  }) {
    final _etiquetaController = TextEditingController(text: datosIniciales?['etiqueta'] ?? '');
    final _referenciaController = TextEditingController(text: datosIniciales?['referencia'] ?? '');
    String _direccionTexto = datosIniciales?['direccion'] ?? (ubicacion != null ? ubicacion['direccion'] : '');
    LatLng? _coordenadas = datosIniciales != null
        ? LatLng(datosIniciales['lat'], datosIniciales['lng'])
        : (ubicacion != null ? ubicacion['latLng'] : null);

    Future<void> _guardarDireccion() async {
      if (_etiquetaController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingresa una etiqueta para la dirección'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_coordenadas == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes seleccionar una ubicación'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Map<String, dynamic> direccionData = {
        'direccion': _direccionTexto,
        'etiqueta': _etiquetaController.text.trim(),
        'referencia': _referenciaController.text.trim(),
        'lat': _coordenadas?.latitude,
        'lng': _coordenadas?.longitude,
        'seleccionado': accion == 'agregar' ? true : datosIniciales?['seleccionado'] ?? false,
        'fecha': FieldValue.serverTimestamp(),
      };

      try {
        if (accion == 'agregar') {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .collection('direcciones')
              .add(direccionData);
        } else {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .collection('direcciones')
              .doc(datosIniciales!['id'])
              .update(direccionData);
        }

        await _getDirecciones(uid);
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dirección ${accion == 'agregar' ? 'agregada' : 'actualizada'}'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al guardar dirección'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }

    Future<void> _seleccionarUbicacion() async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LocationPickerScreen(),
        ),
      );

      if (result != null) {
        setState(() {
          _direccionTexto = result['direccion'];
          _coordenadas = result['latLng'];
        });
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6D4C41),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${accion == 'agregar' ? 'Agregar' : 'Editar'} Dirección',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Botón para seleccionar ubicación
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD7CCC8)),
                            ),
                            child: TextButton.icon(
                              onPressed: _seleccionarUbicacion,
                              icon: const Icon(Icons.map_outlined, color: Color(0xFF6D4C41)),
                              label: Text(
                                _direccionTexto.isNotEmpty ? _direccionTexto : 'Seleccionar ubicación en el mapa',
                                style: TextStyle(
                                  color: _direccionTexto.isNotEmpty ? Colors.black87 : const Color(0xFFA1887F),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Campo etiqueta
                          _buildTextFieldDireccion(
                            controller: _etiquetaController,
                            icon: Icons.label,
                            label: 'Etiqueta (ej: Casa, Oficina)',
                            hintText: 'Ingresa una etiqueta',
                          ),
                          const SizedBox(height: 16),

                          // Campo referencia
                          _buildTextFieldDireccion(
                            controller: _referenciaController,
                            icon: Icons.description,
                            label: 'Referencia (opcional)',
                            hintText: 'Referencias adicionales',
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF6D4C41),
                                    side: const BorderSide(color: Color(0xFF6D4C41)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _guardarDireccion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6D4C41),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Guardar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextFieldDireccion({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5D4037)),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD7CCC8)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: const Color(0xFF8D6E63), size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintStyle: const TextStyle(color: Color(0xFFA1887F)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔹 LÓGICA DE FOTO
  Future<void> _actualizarFoto(String uid, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    
    final XFile? image = await picker.pickImage(
      source: source, 
      maxWidth: 500,      
      imageQuality: 50,   
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await File(image.path).readAsBytes();
      String base64Image = base64Encode(bytes);

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .update({'fotoBase64': base64Image});

      if (mounted) {
        setState(() {
          if (_userData != null) {
            _userData!['fotoBase64'] = base64Image;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Foto de perfil actualizada"),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("Error Base64: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al subir la imagen."), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _mostrarOpcionesFoto(String uid) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Cambiar foto de perfil",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4E342E)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _botonOpcion(Icons.camera_alt_rounded, "Cámara", () {
                    Navigator.pop(ctx);
                    _actualizarFoto(uid, ImageSource.camera);
                  }),
                  _botonOpcion(Icons.photo_library_rounded, "Galería", () {
                    Navigator.pop(ctx);
                    _actualizarFoto(uid, ImageSource.gallery);
                  }),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _botonOpcion(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6D4C41).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: const Color(0xFF6D4C41)),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5D4037))),
          ],
        ),
      ),
    );
  }

  // Ayudante para mostrar la imagen correcta
  ImageProvider? _getImageProvider(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data.containsKey('fotoBase64') && data['fotoBase64'] != null) {
      try {
        return MemoryImage(base64Decode(data['fotoBase64']));
      } catch (e) { return null; }
    }
    if (data.containsKey('fotoUrl') && data['fotoUrl'] != null) {
      return NetworkImage(data['fotoUrl']);
    }
    return null;
  }

  // 🔹 EDICIÓN DE PERFIL
  void _editarPerfil(BuildContext context, String uid) {
    final nombreCtrl = TextEditingController(text: _userData?["nombre"] ?? "");
    final telefonoCtrl = TextEditingController(text: _userData?["telefono"] ?? "");

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6D4C41),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text("Editar Perfil", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildTextFieldWithIcon(controller: nombreCtrl, icon: Icons.person_outline_rounded, label: "Nombre", hintText: "Tu nombre"),
                      const SizedBox(height: 16),
                      _buildTextFieldWithIcon(controller: telefonoCtrl, icon: Icons.phone_iphone_rounded, label: "Teléfono", hintText: "Tu teléfono", keyboardType: TextInputType.phone),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6D4C41),
                                side: const BorderSide(color: Color(0xFF6D4C41)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Cancelar"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection("usuarios").doc(uid).update({
                                  "nombre": nombreCtrl.text.trim(),
                                  "telefono": telefonoCtrl.text.trim(),
                                });
                                await _getUserData(uid);
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6D4C41),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Guardar"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextFieldWithIcon({required TextEditingController controller, required IconData icon, required String label, required String hintText, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5D4037))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD7CCC8))),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), child: Icon(icon, color: const Color(0xFF8D6E63), size: 20)),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(hintText: hintText, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12), hintStyle: const TextStyle(color: Color(0xFFA1887F))),
                ),
              ),
            ],
          ),
        ),
      ],
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
                color: const Color(0xFFD7CCC8).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, size: 60, color: Color(0xFFA1887F)),
            ),
            const SizedBox(height: 24),
            const Text(
              "Inicia sesión para ver tu perfil",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4E342E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Accede a tu cuenta para gestionar tu perfil y ver tu información personal",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D4C41),
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
                Navigator.pushNamed(context, '/register');
              },
              child: const Text(
                "¿No tienes cuenta? Regístrate",
                style: TextStyle(
                  color: Color(0xFF6D4C41),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  //  WIDGET DE DIRECCIONES
  // ---------------------------------------------------------------------
  Widget _buildDireccionesCard(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFFD7CCC8).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: const Color(0xFFF5F5F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF6D4C41).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.location_on, color: Color(0xFF6D4C41), size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Mis Direcciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_direcciones.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                children: [
                  Icon(Icons.location_off, size: 40, color: const Color(0xFF9E9E9E).withOpacity(0.5)),
                  const SizedBox(height: 12),
                  const Text(
                    'No tienes direcciones guardadas',
                    style: TextStyle(color: Color(0xFF757575), fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Agrega una dirección para recibir tus pedidos',
                    style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: _direcciones.map((direccion) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: direccion['seleccionado'] == true 
                          ? const Color(0xFF4CAF50) 
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getIconForEtiqueta(direccion['etiqueta']),
                                color: const Color(0xFF6D4C41),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                direccion['etiqueta'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4E342E),
                                ),
                              ),
                              if (direccion['seleccionado'] == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PRINCIPAL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          PopupMenuButton(
                            icon: const Icon(Icons.more_vert, color: Color(0xFF757575)),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 18, color: Color(0xFF6D4C41)),
                                    const SizedBox(width: 8),
                                    const Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'eliminar',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, size: 18, color: Colors.red),
                                    const SizedBox(width: 8),
                                    const Text('Eliminar'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'editar') {
                                _editarDireccion(context, user.uid, direccion);
                              } else if (value == 'eliminar') {
                                _eliminarDireccion(context, user.uid, direccion['id']);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        direccion['direccion'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF616161),
                        ),
                      ),
                      if (direccion['referencia'] != null && direccion['referencia'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Referencia: ${direccion['referencia']}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF757575),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          
        ],
      ),
    );
  }

  IconData _getIconForEtiqueta(String etiqueta) {
    switch (etiqueta.toLowerCase()) {
      case 'casa':
      case 'hogar':
        return Icons.home;
      case 'trabajo':
      case 'oficina':
        return Icons.work;
      case 'familia':
        return Icons.family_restroom;
      default:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF795548),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_userLoggedIn && _userData != null)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                onPressed: () => _editarPerfil(context, FirebaseAuth.instance.currentUser!.uid),
              ),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF9F5F3),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF795548)))
          : _userLoggedIn 
              ? _buildContent(FirebaseAuth.instance.currentUser!)
              : _buildUsuarioNoLogueado(),
    );
  }

  Widget _buildContent(User user) {
    final nombre = _userData!['nombre'] ?? 'Usuario';
    final telefono = _userData!['telefono'] ?? 'No disponible';
    final imageProvider = _getImageProvider(_userData);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 1. Tarjeta de Perfil
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6D4C41), Color(0xFF4E342E)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4E342E).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Colors.white, Color(0xFFD7CCC8)]),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: imageProvider,
                        child: _isUploading
                            ? const CircularProgressIndicator(color: Color(0xFF6D4C41))
                            : imageProvider == null
                                ? const Icon(Icons.person_rounded, size: 60, color: Color(0xFF6D4C41))
                                : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _mostrarOpcionesFoto(user.uid),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8D6E63),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  nombre,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? '',
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // 2. Direcciones
          _buildDireccionesCard(user),
          
          const SizedBox(height: 24),

          // 3. Información Personal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFFD7CCC8).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
              border: Border.all(color: const Color(0xFFF5F5F5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF6D4C41).withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.info_outline_rounded, color: Color(0xFF6D4C41), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text('Información Personal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4E342E))),
                  ],
                ),
                const SizedBox(height: 20),
                _buildEnhancedInfoItem(
                  icon: Icons.phone_iphone_rounded,
                  title: 'Teléfono de contacto',
                  value: telefono,
                  isImportant: true,
                ),
                const SizedBox(height: 16),
                _buildEnhancedInfoItem(
                  icon: Icons.calendar_month_rounded,
                  title: 'Miembro desde',
                  value: user.metadata.creationTime != null ? _formatDate(user.metadata.creationTime!) : 'Desconocido',
                  isImportant: false,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // 4. Botón Cerrar Sesión
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Cerrar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoItem({required IconData icon, required String title, required String value, required bool isImportant}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isImportant ? const Color(0xFF6D4C41).withOpacity(0.1) : const Color(0xFF9E9E9E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isImportant ? const Color(0xFF6D4C41) : const Color(0xFF757575), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF616161),
                    fontWeight: isImportant ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isImportant ? const Color(0xFF4E342E) : const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          if (isImportant)
            const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 16),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}

// Clase LatLng para manejar coordenadas
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}