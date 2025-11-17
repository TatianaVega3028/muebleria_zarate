import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final LatLng _muebleriaLocation = const LatLng(-12.0724559, -75.2113603);

  LocationData? _currentLocation;
  bool _isLoading = true;
  bool _permissionDenied = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Location _locationService = Location();

  @override
  void initState() {
    super.initState();
    _initMapAndLocation();
  }

  Future<void> _initMapAndLocation() async {
    try {
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
      }

      PermissionStatus permissionGranted = await _locationService.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _locationService.requestPermission();
      }

      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
          _markers.add(Marker(
            markerId: const MarkerId('muebleria'),
            position: _muebleriaLocation,
            infoWindow: const InfoWindow(title: 'Mueblería Zárate'),
          ));
        });
        return;
      }

      final loc = await _locationService.getLocation();
      _currentLocation = loc;

      _markers.addAll([
        Marker(
          markerId: const MarkerId('muebleria'),
          position: _muebleriaLocation,
          infoWindow: const InfoWindow(title: 'Mueblería Zárate'),
        ),
        Marker(
          markerId: const MarkerId('usuario'),
          position: LatLng(loc.latitude!, loc.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
        ),
      ]);

      _locationService.onLocationChanged.listen((updatedLoc) {
        setState(() {
          _currentLocation = updatedLoc;
          _markers.removeWhere((m) => m.markerId.value == 'usuario');
          _markers.add(Marker(
            markerId: const MarkerId('usuario'),
            position: LatLng(updatedLoc.latitude!, updatedLoc.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: 'Tu ubicación'),
          ));
        });
      });

      setState(() => _isLoading = false);
    } catch (e) {
      print("❌ Error de inicialización: $e");
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
        _markers.add(Marker(
          markerId: const MarkerId('muebleria'),
          position: _muebleriaLocation,
          infoWindow: const InfoWindow(title: 'Mueblería Zárate'),
        ));
      });
    }
  }

  /// 🔹 Obtiene la ruta real usando Google Directions API
  Future<void> _mostrarRutaReal() async {
    if (_currentLocation == null) {
      await _initMapAndLocation();
      if (_currentLocation == null) return;
    }

    final startLat = _currentLocation!.latitude!;
    final startLng = _currentLocation!.longitude!;
    final endLat = _muebleriaLocation.latitude;
    final endLng = _muebleriaLocation.longitude;

    const apiKey = "AIzaSyBIZrptkE0IGakPhzMzMpq4PaW_gw_D1vk"; // ⚠️ Reemplaza con tu clave válida
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$endLat,$endLng&mode=driving&key=$apiKey";

    print("🌍 Solicitando ruta: $url");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == "OK" && data['routes'].isNotEmpty) {
        final route = data['routes'][0]['overview_polyline']['points'];
        final points = _decodePolyline(route);

        final polyline = Polyline(
          polylineId: const PolylineId('ruta_real'),
          color: const Color(0xFF795548),
          width: 6,
          points: points,
        );

        setState(() {
          _polylines.clear();
          _polylines.add(polyline);
        });

        final controller = await _controller.future;
        final bounds = _boundsFromLatLngList(points);
        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
      } else {
        print("⚠️ Error en datos de ruta: ${data['status']}");
        _mostrarError("No se encontró una ruta disponible.");
      }
    } else {
      print("❌ Error al conectar con la API: ${response.statusCode}");
      _mostrarError("Error al obtener la ruta. Código: ${response.statusCode}");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      final p = LatLng(lat / 1E5, lng / 1E5);
      polyline.add(p);
    }
    return polyline;
  }

  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          )
        ],
      ),
    );
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (final latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(southwest: LatLng(x0!, y0!), northeast: LatLng(x1!, y1!));
  }

  @override
  Widget build(BuildContext context) {
    const marron = Color(0xFF795548);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: marron,
        title: const Text(
          'Ubicación de Mueblería Zárate',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: (controller) {
                    if (!_controller.isCompleted) _controller.complete(controller);
                  },
                  initialCameraPosition: CameraPosition(
                    target: _muebleriaLocation,
                    zoom: 16,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: _currentLocation != null,
                  myLocationButtonEnabled: true,
                ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: marron,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final controller = await _controller.future;
                        controller.animateCamera(CameraUpdate.newLatLngZoom(_muebleriaLocation, 17));
                      },
                      icon: const Icon(Icons.store, color: Colors.white),
                      label: const Text('Ir a Mueblería', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentLocation != null ? marron : Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _mostrarRutaReal,
                      icon: const Icon(Icons.alt_route, color: Colors.white),
                      label: const Text('Cómo llegar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
