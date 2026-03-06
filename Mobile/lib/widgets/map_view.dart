import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:municipalgo/services/map_constants.dart';
import 'package:municipalgo/services/quartiersService.dart';

import '../services/quartiersService.dart';

class MapView extends StatefulWidget {
  final Completer<GoogleMapController> mapControllerCompleter;
  final Set<Marker> markers;
  final Set<Polygon> polygons;

  final String? selectedQuartier;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onReset;

  const MapView({
    required this.mapControllerCompleter,
    required this.markers,
    required this.polygons,
    required this.selectedQuartier,
    this.onRefresh,
    this.onReset,
    super.key,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  String? _lastQuartier;

  Future<GoogleMapController> get _map async => widget.mapControllerCompleter.future;

  @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final q = widget.selectedQuartier;
    if (q != _lastQuartier) {
      _lastQuartier = q;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyQuartierCamera(q);
      });
    }
  }

  Future<void> _applyQuartierCamera(String? quartier) async {
    final c = await _map;

    if (quartier == null || quartier.isEmpty) {
      await c.animateCamera(
        CameraUpdate.newCameraPosition(MapConstants.initialPosition),
      );
      return;
    }

    final b = QuartiersService.boundsFor(quartier);
    if (b == null) return;

    await c.animateCamera(CameraUpdate.newLatLngBounds(b, 60));
  }

  Future<void> _resetCamera() async {
    final c = await _map;
    await c.animateCamera(CameraUpdate.newCameraPosition(MapConstants.initialPosition));
    widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (widget.onRefresh != null) await widget.onRefresh!();
      },
      notificationPredicate: (n) => n.depth == 0,
      child: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: MapConstants.initialPosition,
            markers: widget.markers,
            polygons: widget.polygons,
            onMapCreated: (c) async {
              if (!widget.mapControllerCompleter.isCompleted) {
                widget.mapControllerCompleter.complete(c);
              }
              try {
                await c.setMapStyle(MapConstants.mapStyle);
              } catch (_) {
                if (kDebugMode) debugPrint('setMapStyle not available');
              }

              _lastQuartier = widget.selectedQuartier;
              await _applyQuartierCamera(widget.selectedQuartier);
            },
            cameraTargetBounds: MapConstants.cameraBounds,
            minMaxZoomPreference: MapConstants.zoomPreference,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: false,
          ),


        ],
      ),
    );
  }
}