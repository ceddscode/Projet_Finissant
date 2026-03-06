import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../generated/l10n.dart';
import '../http/dtos/transfer.dart';

Map<String, double> _computeDistances(Map<String, dynamic> payload) {
  final user = payload['user'] as Map<String, dynamic>?;
  final incidents = payload['incidents'] as List<dynamic>?;
  if (user == null || incidents == null) return <String, double>{};
  final double uLat = (user['lat'] as num).toDouble();
  final double uLng = (user['lng'] as num).toDouble();
  final out = <String, double>{};
  for (final item in incidents) {
    final m = item as Map<String, dynamic>;
    final id = m['id'].toString();
    final lat = (m['lat'] as num).toDouble();
    final lng = (m['lng'] as num).toDouble();
    final d = _haversine(uLat, uLng, lat, lng);
    out[id] = d;
  }
  return out;
}

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  final phi1 = lat1 * math.pi / 180.0;
  final phi2 = lat2 * math.pi / 180.0;
  final dPhi = (lat2 - lat1) * math.pi / 180.0;
  final dLambda = (lon2 - lon1) * math.pi / 180.0;
  final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) * math.cos(phi2) *
          math.sin(dLambda / 2) * math.sin(dLambda / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

class locationServices {
  static Future<Position?> getCurrentLocation(BuildContext context) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).serviceUnavailable)),
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).serviceRefused)),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).serviceDenied),
          action: SnackBarAction(
            label: S.of(context).activateLocalization,
            onPressed: Geolocator.openLocationSettings,
          ),
        ),
      );
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 50,
      ),
    );
  }

  static double distanceMeters(Position userPos, Incident incident) {
    return Geolocator.distanceBetween(
      userPos.latitude,
      userPos.longitude,
      incident.latitude,
      incident.longitude,
    );
  }

  static Future<Map<int, double>> distancesForIncidents(
      BuildContext context,
      List<Incident> incidents,
      ) async {
    final pos = await getCurrentLocation(context);
    if (pos == null) return <int, double>{};
    final payload = {
      'user': {'lat': pos.latitude, 'lng': pos.longitude},
      'incidents': incidents.map((i) => {'id': i.id, 'lat': i.latitude, 'lng': i.longitude}).toList(),
    };
    final result = await compute(_computeDistances, payload);
    final out = <int, double>{};
    result.forEach((k, v) {
      out[int.parse(k)] = v;
    });
    return out;
  }

  static Future<Map<int, double>> IncidentInsideZone(
      BuildContext context,
      List<Incident> incidents,
      ) async {
    final pos = await getCurrentLocation(context);
    if (pos == null) return <int, double>{};
    final payload = {
      'user': {'lat': pos.latitude, 'lng': pos.longitude},
      'incidents': incidents.map((i) => {'id': i.id, 'lat': i.latitude, 'lng': i.longitude}).toList(),
    };
    final result = await compute(_computeDistances, payload);
    final out = <int, double>{};
    result.forEach((k, v) {
      final id = int.parse(k);
      if (v <= 15.0) out[id] = v;
    });
    return out;
  }
}