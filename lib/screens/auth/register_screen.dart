import 'package:flutter/material.dart';
import 'package:muebleria_zarate/services/auth_service.dart';
import 'login_screen.dart';
import 'package:muebleria_zarate/screens/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 🔹 Registrar usuario
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Registrar usuario con Firebase Auth
      final User? user = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        // Guardar datos adicionales en Firestore
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'rol': 'cliente',
          'nombre': _nombreController.text.trim(),
          'apellidos': _apellidosController.text.trim(),
          'direccion': _direccionController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'creadoEn': FieldValue.serverTimestamp(),
        });
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
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF795548);
    const Color backgroundColor = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // 🔸 Logo
              Icon(Icons.person_add_alt_1, size: 80, color: primaryColor),
              const SizedBox(height: 10),
              const Text(
                "Crea tu cuenta",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 30),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nombreController,
                      label: "Nombre",
                      icon: Icons.person,
                      obscure: false,
                      primaryColor: primaryColor,
                      validator: (v) => v!.isEmpty ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _apellidosController,
                      label: "Apellidos",
                      icon: Icons.person_outline,
                      obscure: false,
                      primaryColor: primaryColor,
                      validator: (v) => v!.isEmpty ? 'Ingresa tus apellidos' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _direccionController,
                      label: "Dirección",
                      icon: Icons.home,
                      obscure: false,
                      primaryColor: primaryColor,
                      validator: (v) => v!.isEmpty ? 'Ingresa tu dirección' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _telefonoController,
                      label: "Teléfono",
                      icon: Icons.phone,
                      obscure: false,
                      primaryColor: primaryColor,
                      validator: (v) =>
                          v!.isEmpty ? 'Ingresa tu número de teléfono' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _emailController,
                      label: "Correo electrónico",
                      icon: Icons.email,
                      obscure: false,
                      primaryColor: primaryColor,
                      validator: (v) =>
                          v!.isEmpty ? 'Ingresa un correo válido' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _passwordController,
                      label: "Contraseña",
                      icon: Icons.lock,
                      obscure: _obscurePassword,
                      primaryColor: primaryColor,
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
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: "Confirmar contraseña",
                      icon: Icons.lock_outline,
                      obscure: _obscureConfirmPassword,
                      primaryColor: primaryColor,
                      validator: (v) {
                        if (v != _passwordController.text) return 'Las contraseñas no coinciden';
                        return null;
                      },
                      suffix: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: primaryColor,
                        ),
                        onPressed: () => setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text(
                                'Registrarse',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("¿Ya tienes cuenta? "),
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
                          child: const Text(
                            'Inicia sesión',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // 🔸 Widget de campo de texto reutilizable
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required Color primaryColor,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: primaryColor),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
