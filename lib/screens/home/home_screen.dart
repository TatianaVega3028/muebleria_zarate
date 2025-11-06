import 'package:flutter/material.dart';
import 'package:muebleria_zarate/screens/historial/historial_pedidos_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        backgroundColor: Colors.brown[700],
        title: const Text(
          'Bienvenido a Mueblería Zárate',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.brown[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildCard(context, Icons.chair_outlined, "Catálogo", '/catalog'),
            _buildCard(context, Icons.shopping_cart_outlined, "Pedidos", '/orders'),
            _buildCard(context, Icons.history_outlined, "Historial", '/historial'),
            _buildCard(context, Icons.person_outlined, "Perfil", '/profile'),
            _buildCard(context, Icons.logout_outlined, "Cerrar Sesión", '/login'),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String title, String route) {
    return Card(
      elevation: 8,
      shadowColor: Colors.brown[300],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.brown[100]!,
              Colors.brown[50]!,
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (route == '/login') {
                Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
              } else {
                Navigator.pushNamed(context, route);
              }
            },
            splashColor: Colors.brown[200],
            highlightColor: Colors.brown[100]!.withOpacity(0.5),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.brown[50],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.brown[300]!,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: Colors.brown[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.brown[900],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}