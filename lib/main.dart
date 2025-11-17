import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/catalog/catalog_screen.dart';
import 'screens/historial/historial_pedidos_screen.dart';
import 'screens/perfil/perfil_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MuebleriaApp());
}

class MuebleriaApp extends StatelessWidget {
  const MuebleriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mueblería Zárate',
      theme: ThemeData(primarySwatch: Colors.brown),

      /// 👉 Aquí forzamos que siempre vaya a HomeScreen
      home: const HomeScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/catalog': (context) => CatalogScreen(),
        '/historial': (context) => const HistorialPedidosScreen(),
        '/perfil':(context) => const PerfilScreen(),
      },
    );
  }
}
