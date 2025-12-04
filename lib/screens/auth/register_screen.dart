import 'package:flutter/material.dart';
import 'package:muebleria_zarate/services/auth_service.dart';
import 'login_screen.dart';
import 'package:muebleria_zarate/screens/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../map/location_picker_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _etiquetaController = TextEditingController();
  final _referenciaController = TextEditingController();

  // Variables para ubicación
  Map<String, dynamic>? _ubicacionSeleccionada;
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Color primaryColor = const Color(0xFF795548);

  // 🔹 Función para abrir el selector de ubicación
  Future<void> _seleccionarUbicacion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _ubicacionSeleccionada = result;
        _direccionController.text = result['direccion'];
      });
    }
  }

  // 🔹 Validar formulario
  bool _validarFormulario() {
    if (!_formKey.currentState!.validate()) return false;
    if (_ubicacionSeleccionada == null) {
      _showErrorDialog('Por favor selecciona una ubicación en el mapa');
      return false;
    }
    if (_etiquetaController.text.trim().isEmpty) {
      _showErrorDialog('Por favor ingresa una etiqueta para la dirección');
      return false;
    }
    return true;
  }

  // 🔹 Registrar usuario
  Future<void> _register() async {
    if (!_validarFormulario()) return;

    setState(() => _isLoading = true);

    try {
      // Registrar usuario con Firebase Auth
      final User? user = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        // Crear objeto con la información de ubicación completa
        Map<String, dynamic> direccionData = {
          'direccion': _direccionController.text.trim(),
          'etiqueta': _etiquetaController.text.trim(),
          'referencia': _referenciaController.text.trim().isNotEmpty 
              ? _referenciaController.text.trim() 
              : '',
          'lat': _ubicacionSeleccionada!['latLng'].latitude,
          'lng': _ubicacionSeleccionada!['latLng'].longitude,
          'seleccionado': true,
          'fecha': FieldValue.serverTimestamp(),
        };

        // Guardar datos del usuario en Firestore
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'rol': 'cliente',
          'nombre': _nombreController.text.trim(),
          'apellidos': _apellidosController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'creadoEn': FieldValue.serverTimestamp(),
          'direccionPrincipal': _direccionController.text.trim(),
        });

        // Guardar la dirección seleccionada en la subcolección 'direcciones'
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('direcciones')
            .add(direccionData);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message.replaceFirst('Exception: ', '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Aceptar', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Limpiar todos los controladores
    _nombreController.dispose();
    _apellidosController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _etiquetaController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Logo y título
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(0.4),
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.person_add_alt_1,
                        size: 60,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Mueblería Zárate",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Crea tu cuenta",
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Nombre
                    _buildTextField(
                      controller: _nombreController,
                      label: "Nombre",
                      icon: Icons.person,
                      obscure: false,
                      validator: (v) => v!.isEmpty ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 16),

                    // Apellidos
                    _buildTextField(
                      controller: _apellidosController,
                      label: "Apellidos",
                      icon: Icons.person_outline,
                      obscure: false,
                      validator: (v) => v!.isEmpty ? 'Ingresa tus apellidos' : null,
                    ),
                    const SizedBox(height: 16),

                    // Dirección con selector de mapa
                    _buildDireccionField(),
                    const SizedBox(height: 16),

                    // Etiqueta (Casa 2, Oficina, etc.)
                    _buildTextField(
                      controller: _etiquetaController,
                      label: "Etiqueta (ej: Casa, Oficina, Trabajo)",
                      icon: Icons.label,
                      obscure: false,
                      validator: (v) => v!.isEmpty ? 'Ingresa una etiqueta para la dirección' : null,
                    ),
                    const SizedBox(height: 16),

                    // Referencia (opcional)
                    _buildTextField(
                      controller: _referenciaController,
                      label: "Referencia (opcional)",
                      icon: Icons.description,
                      obscure: false,
                      validator: null,
                    ),
                    const SizedBox(height: 16),

                    // Teléfono
                    _buildTextField(
                      controller: _telefonoController,
                      label: "Teléfono",
                      icon: Icons.phone,
                      obscure: false,
                      validator: (v) => v!.isEmpty ? 'Ingresa tu número de teléfono' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      label: "Correo electrónico",
                      icon: Icons.email,
                      obscure: false,
                      validator: (v) => v!.isEmpty ? 'Ingresa un correo válido' : null,
                    ),
                    const SizedBox(height: 16),

                    // Contraseña
                    _buildTextField(
                      controller: _passwordController,
                      label: "Contraseña",
                      icon: Icons.lock,
                      obscure: _obscurePassword,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                        if (v.length < 6) return 'Debe tener al menos 6 caracteres';
                        return null;
                      },
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: primaryColor,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirmar contraseña
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: "Confirmar contraseña",
                      icon: Icons.lock_outline,
                      obscure: _obscureConfirmPassword,
                      validator: (v) {
                        if (v != _passwordController.text) return 'Las contraseñas no coinciden';
                        return null;
                      },
                      suffix: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: primaryColor,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Botón de registro
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: primaryColor.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Registrarse',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Enlace a login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes cuenta? ',
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                          child: Text(
                            'Inicia sesión',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔸 Campo de dirección con selector de mapa
  Widget _buildDireccionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _direccionController,
            readOnly: true,
            onTap: _seleccionarUbicacion,
            style: TextStyle(color: primaryColor),
            decoration: InputDecoration(
              labelText: "Dirección",
              labelStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
              prefixIcon: Icon(Icons.location_on, color: primaryColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _ubicacionSeleccionada != null 
                      ? Icons.check_circle 
                      : Icons.map_outlined,
                  color: _ubicacionSeleccionada != null 
                      ? Colors.green 
                      : primaryColor,
                ),
                onPressed: _seleccionarUbicacion,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              hintText: "Selecciona tu ubicación en el mapa",
              hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Selecciona tu dirección';
              return null;
            },
          ),
        ),
        
        // Indicador de ubicación seleccionada
        if (_ubicacionSeleccionada != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Ubicación seleccionada ✓",
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 🔸 Widget de campo de texto reutilizable
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: TextStyle(color: primaryColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: primaryColor),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}