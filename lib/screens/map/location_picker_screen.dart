import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  
  LatLng _pickedLocation = const LatLng(-12.0724559, -75.2113603);
  String _direccionTexto = "Desliza el mapa para seleccionar ubicación";
  bool _isLoading = false;
  bool _isSearching = false;

  // Función para obtener la dirección a partir de coordenadas
  Future<void> _obtenerDireccionDesdeCoordenadas(LatLng coordenadas) async {
    setState(() => _isLoading = true);
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordenadas.latitude,
        coordenadas.longitude,
        localeIdentifier: 'es_PE',
      );

      if (placemarks.isNotEmpty) {
        Placemark lugar = placemarks.first;
        
        // Construye la dirección en formato peruano común
        String calle = lugar.street ?? '';
        String numero = lugar.subThoroughfare ?? '';
        String distrito = lugar.locality ?? lugar.subAdministrativeArea ?? '';
        String ciudad = lugar.administrativeArea ?? '';
        
        // Formato: "Jr. Amazonas 123, Distrito, Ciudad"
        String direccionCompleta = '';
        
        if (calle.isNotEmpty) {
          direccionCompleta = calle;
          if (numero.isNotEmpty) {
            direccionCompleta += ' $numero';
          }
        } else {
          direccionCompleta = 'Ubicación seleccionada';
        }
        
        if (distrito.isNotEmpty && distrito != ciudad) {
          direccionCompleta += ', $distrito';
        }
        
        if (ciudad.isNotEmpty) {
          direccionCompleta += ', $ciudad';
        }

        setState(() => _direccionTexto = direccionCompleta);
      } else {
        setState(() => _direccionTexto = "Ubicación seleccionada");
      }
    } catch (e) {
      debugPrint("Error en geocodificación: $e");
      setState(() => _direccionTexto = "Ubicación seleccionada");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Función para buscar una dirección
  Future<void> _buscarDireccion(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);
    
    try {
      List<Location> locations = await locationFromAddress(
        query,
        localeIdentifier: 'es_PE',
      );

      if (locations.isNotEmpty) {
        final location = locations.first;
        final newLatLng = LatLng(location.latitude, location.longitude);
        
        final GoogleMapController controller = await _mapController.future;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(newLatLng, 16),
        );
        
        setState(() => _pickedLocation = newLatLng);
        await _obtenerDireccionDesdeCoordenadas(newLatLng);
        
        // Limpiar el campo de búsqueda
        _searchController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("No se encontró la dirección"),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error en búsqueda: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Error al buscar la dirección"),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // Función cuando se mueve la cámara (al arrastrar el mapa)
  Future<void> _onCameraMove(CameraPosition position) async {
    _pickedLocation = position.target;
    await _obtenerDireccionDesdeCoordenadas(_pickedLocation);
  }

  @override
  void initState() {
    super.initState();
    // Obtener dirección inicial
    _obtenerDireccionDesdeCoordenadas(_pickedLocation);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar Ubicación"),
        backgroundColor: const Color(0xFF6D4C41),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // BUSCADOR EN LA PARTE SUPERIOR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Buscar dirección...",
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade600,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (value) => _buscarDireccion(value),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 60,
                  child: _isSearching
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6D4C41),
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            if (_searchController.text.trim().isNotEmpty) {
                              _buscarDireccion(_searchController.text);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6D4C41),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Icon(Icons.search, size: 20),
                        ),
                ),
              ],
            ),
          ),
          
          // DIRECCIÓN SELECCIONADA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  color: const Color(0xFF6D4C41),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dirección seleccionada:",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _isLoading
                          ? Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF6D4C41),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Obteniendo dirección...",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _direccionTexto,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // MAPA DE GOOGLE MAPS
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _pickedLocation,
                    zoom: 16,
                  ),
                  onMapCreated: (controller) {
                    _mapController.complete(controller);
                  },
                  onCameraMove: _onCameraMove,
                  onCameraIdle: () async {
                    await _obtenerDireccionDesdeCoordenadas(_pickedLocation);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _pickedLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                      anchor: const Offset(0.5, 1.0), // Ajustado para mejor visualización
                    ),
                  },
                ),
                
                // Ícono de referencia en el centro (solo visual, no interactivo)
                const Center(
                  child: Icon(
                    Icons.location_searching,
                    color: Color(0xFF6D4C41),
                    size: 40,
                  ),
                ),
                
                // Botón de centrar en ubicación seleccionada
                Positioned(
                  bottom: 100,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: () async {
                      try {
                        final controller = await _mapController.future;
                        await controller.animateCamera(
                          CameraUpdate.newLatLng(_pickedLocation),
                        );
                      } catch (e) {
                        debugPrint("Error al centrar mapa: $e");
                      }
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6D4C41),
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          
          // BOTÓN DE CONFIRMAR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'latLng': _pickedLocation,
                  'direccion': _direccionTexto,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D4C41),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Confirmar ubicación",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}