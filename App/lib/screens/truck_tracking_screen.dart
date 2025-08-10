import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TruckTrackingScreen extends StatefulWidget {
  const TruckTrackingScreen({Key? key}) : super(key: key);

  @override
  State<TruckTrackingScreen> createState() => _TruckTrackingScreenState();
}

class _TruckTrackingScreenState extends State<TruckTrackingScreen> {
  late GoogleMapController _mapController;
  final LatLng _truckLocation = const LatLng(37.7749, -122.4194);
  final LatLng _userLocation = const LatLng(37.7849, -122.4094);
  bool _showRoute = true;
  bool _isRefreshing = false;
  int _estimatedTime = 15; // in minutes

  // Custom truck icon
  BitmapDescriptor? _truckIcon;
  BitmapDescriptor? _userIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
  }

  Future<void> _loadCustomIcons() async {
    final truckIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/truck_icon.png', // Replace with your asset
    );
    final userIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/user_location.png', // Replace with your asset
    );
    setState(() {
      _truckIcon = truckIcon;
      _userIcon = userIcon;
    });
  }

  Future<void> _refreshLocation() async {
    setState(() => _isRefreshing = true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _estimatedTime = _estimatedTime > 5 ? _estimatedTime - 1 : 5;
      _isRefreshing = false;
    });
  }

  Set<Polyline> _getRoutePolyline() {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_truckLocation, _userLocation],
        color: const Color.fromARGB(255, 108, 207, 111),
        width: 4,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Truck Tracking'),
        backgroundColor: const Color.fromARGB(255, 158, 225, 160),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _truckLocation,
              zoom: 14,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('truck'),
                position: _truckLocation,
                icon:
                    _truckIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                infoWindow: const InfoWindow(title: 'Waste Collection Truck'),
                rotation: 45.0, // Example rotation
              ),
              Marker(
                markerId: const MarkerId('user'),
                position: _userLocation,
                icon:
                    _userIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue,
                    ),
                infoWindow: const InfoWindow(title: 'Your Location'),
              ),
            },
            polylines: _showRoute ? _getRoutePolyline() : {},
            onMapCreated: (controller) {
              _mapController = controller;
              // Center the map to show both locations
              _mapController.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: LatLng(
                      _truckLocation.latitude < _userLocation.latitude
                          ? _truckLocation.latitude
                          : _userLocation.latitude,
                      _truckLocation.longitude < _userLocation.longitude
                          ? _truckLocation.longitude
                          : _userLocation.longitude,
                    ),
                    northeast: LatLng(
                      _truckLocation.latitude > _userLocation.latitude
                          ? _truckLocation.latitude
                          : _userLocation.latitude,
                      _truckLocation.longitude > _userLocation.longitude
                          ? _truckLocation.longitude
                          : _userLocation.longitude,
                    ),
                  ),
                  100, // padding
                ),
              );
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'location',
                  onPressed: () {
                    _mapController.animateCamera(
                      CameraUpdate.newLatLng(_userLocation),
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'route',
                  onPressed: () {
                    setState(() {
                      _showRoute = !_showRoute;
                    });
                  },
                  backgroundColor: Colors.white,
                  child: Icon(
                    _showRoute ? Icons.route : Icons.route_outlined,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Positioned(bottom: 20, left: 20, right: 20, child: _buildInfoCard()),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Arrival',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Chip(
                  backgroundColor: const Color(0xFFE8F5E9),
                  label: Text(
                    '$_estimatedTime min',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Waste Collection Truck #245',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.speed, color: Colors.orange.shade400),
                const SizedBox(width: 8),
                const Text(
                  'Current Speed: 32 km/h',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red.shade400),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '123 Main St, San Francisco',
                    style: TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: 0.7, // Example progress
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
