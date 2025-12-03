import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  
  // 📍 COORDENADAS DE LA MUEBLERÍA ZÁRATE (PUNTO DE INICIO)
  LatLng _pickedLocation = const LatLng(-12.0724559, -75.2113603); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Elige punto de entrega"),
        backgroundColor: const Color(0xFF6D4C41),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation, // Inicia en la mueblería
              zoom: 16,
            ),
            onMapCreated: (controller) => _controller.complete(controller),
            onCameraMove: (position) {
              // Actualiza la posición mientras mueves el mapa
              _pickedLocation = position.target;
            },
            myLocationEnabled: true, // Muestra el punto azul si hay permiso
            myLocationButtonEnabled: true,
          ),
          // Marcador fijo en el centro de la pantalla
          const Center(
            child: Icon(Icons.table_bar_outlined, color: Color.fromARGB(255, 122, 80, 2), size: 30),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                // Devuelve la coordenada seleccionada
                Navigator.pop(context, _pickedLocation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D4C41),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Confirmar esta ubicación", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}