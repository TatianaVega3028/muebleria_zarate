import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
 
class HistorialPedidosScreen extends StatelessWidget { 
  const HistorialPedidosScreen({super.key}); 
 
  @override 
  Widget build(BuildContext context) { 
    final user = FirebaseAuth.instance.currentUser; 
 
    if (user == null) { 
      return const Scaffold( 
        body: Center(child: Text('Debes iniciar sesión para ver tus pedidos.')), 
      ); 
    } 
 
    final pedidosRef = FirebaseFirestore.instance 
        .collection('usuarios') 
        .doc(user.uid) 
        .collection('Pedidos') 
        .orderBy('fecha', descending: true); 
 
    return Scaffold( 
      appBar: AppBar( 
        title: const Text('Historial de pedidos'), 
        backgroundColor: Colors.brown.shade400, 
        centerTitle: true, 
      ), 
      body: StreamBuilder<QuerySnapshot>( 
        stream: pedidosRef.snapshots(), 
        builder: (context, snapshot) { 
          if (snapshot.connectionState == ConnectionState.waiting) { 
            return const Center(child: CircularProgressIndicator()); 
          } 

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { 
            return const Center(child: Text('No tienes pedidos aún.')); 
          } 
 
          final pedidos = snapshot.data!.docs; 
 
          return ListView.builder( 
            itemCount: pedidos.length, 
            itemBuilder: (context, index) { 
              final pedido = pedidos[index]; 
              final productos = List<Map<String, 
dynamic>>.from(pedido['productos']); 
              final total = pedido['total']; 
 
              return ExpansionTile( 
                title: Text('Pedido ${index + 1} - S/. ${total.toStringAsFixed(2)}'), 
                subtitle: Text('Estado: ${pedido['estado']}'), 
                children: productos 
                    .map((p) => ListTile( 
                          title: Text(p['nombre']), 
                          subtitle: Text('S/. ${p['precio']}'), 
                        )) 
                    .toList(), 
              ); 
            }, 
          ); 
        }, 
      ), 
    ); 
  } 
}