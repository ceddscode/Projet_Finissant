import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../http/lib_http.dart';
import '../services/roleProvider.dart';
import 'incident_details.dart';

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();
  RoleProvider get roleProvider => context.read<RoleProvider>();

  Set<Marker> _markers = {};
  BitmapDescriptor? _incidentIcon;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(45.5312, -73.5181),
    zoom: 13,



  );
  static final CameraTargetBounds _cityBounds = CameraTargetBounds(
    LatLngBounds(
      southwest: const LatLng(45.45, -73.65),
      northeast: const LatLng(45.62, -73.40),
    ),
  );


  static const String _mapStyle = '''
[
  {
    "featureType": "poi",
    "stylers": [
      { "visibility": "off" }
    ]
  }
]
''';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _incidentIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(25, 25)),
      'assets/warning-hazard-sign-on-transparent-background-free-png.png',
    );
    await loadIncidents();
  }

  Future<void> _refresh() async {
    await loadIncidents();
  }
  void refreshNow(){
    _refresh();
  }

  void setMarkersFromIncidents(List incidents) {
    final icon = _incidentIcon ?? BitmapDescriptor.defaultMarker;

    final newMarkers = incidents.map<Marker>((i) {
      return Marker(
        markerId: MarkerId(i.id.toString()),
        position: LatLng(i.latitude, i.longitude),
        infoWindow: InfoWindow(title: i.title),
        icon: icon,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IncidentDetailsPage(incidentId: i.id),
            ),
          );
        },
      );
    }).toSet();

    setState(() => _markers = newMarkers);
  }

  Future<void> loadIncidents() async {
    final incidents = roleProvider.role == UserRole.blueCollar
          ? await getBlueCollarApi()
          : await getAllIncidentsApi();
      if (!mounted) return;
    setMarkersFromIncidents(incidents);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              controller.setMapStyle(_mapStyle);
            },
            cameraTargetBounds: _cityBounds,
            minMaxZoomPreference: const MinMaxZoomPreference(10, 16),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: false,
          ),
        ],
      ),
    );
  }
}
