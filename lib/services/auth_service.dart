import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Registrar un nuevo usuario
  Future<User?> signUp(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Devuelve el mensaje de error legible
      throw Exception(_handleFirebaseAuthError(e));
    }
  }

  /// 🔹 Iniciar sesión
  Future<User?> signIn(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseAuthError(e));
    }
  }

  /// 🔹 Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 🔹 Obtener usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// 🔹 Manejo de errores comunes
  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuario no encontrado. Verifica tu correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'El correo ya está registrado.';
      case 'invalid-email':
        return 'Correo electrónico inválido.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
