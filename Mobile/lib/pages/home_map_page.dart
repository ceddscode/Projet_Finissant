import 'dart:async';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:municipalgo/generated/l10n.dart';
import 'package:municipalgo/services/location_services.dart';
import 'package:municipalgo/services/map_constants.dart';
import 'package:municipalgo/services/quartiersService.dart';
import 'package:municipalgo/services/quartier_utils.dart';
import 'package:municipalgo/widgets/map_view.dart';
import 'package:municipalgo/widgets/overlay_widget.dart';
import 'package:municipalgo/widgets/search_filters_widget.dart';
import '../http/dtos/transfer.dart';
import '../http/lib_http.dart';
import '../services/icon_change_category.dart';
import '../services/roleProvider.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/incidents_bottom_sheet.dart';
import 'incident_details.dart';
String normalizeKey(String s) {
  final x = removeDiacritics(s).toLowerCase().trim();
  return x.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class MapFilters {
  String search = '';
  String? status = '';
  int? category;
  String? quartier;
  String distance = 'Closest';
  bool get resetActive =>
      (status != '' && status != null) || category != null ||quartier != null ||search.trim().isNotEmpty ||distance != 'Closest';
  void clear() {
    search = '';
    status = '';
    category = null;
    quartier = null;
    distance = 'Closest';
  }
}

class HomeMapPage extends StatefulWidget {
  const HomeMapPage({super.key});

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

class _HomeMapPageState extends State<HomeMapPage> {
  final _mapController = Completer<GoogleMapController>();
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  final _sheetController = DraggableScrollableController();
  final _bottomSheetKey = GlobalKey<IncidentsBottomSheetState>();
  final _filters = MapFilters();
  List<Incident> _incidents = [];
  List<Incident> _visible = [];
  Set<Marker> _markers = {};
  int? _lastSyncedSelectedId;
  final Map<int, double> _distanceMap = {};
  int? _selectedIncidentId;

  final Map<int, SubscriptionInfo> _subInfoByIncident = {};
  final Set<int> _subLoading = {};
  final Set<int> _toggleSubInProgress = {};

  BitmapDescriptor? _incidentIcon;
  double _sheetExtent = 0.28;
  bool _loadingIncidents = true;

  RoleProvider get roleProvider => context.read<RoleProvider>();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _setFilters(void Function(MapFilters f) update) {
    setState(() => update(_filters));
    _applyFilters();
  }

  void _onSearchChanged() {
    // Debounce search to avoid filtering on every keystroke.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final v = _searchCtrl.text;
      if (v != _filters.search) _setFilters((f) => f.search = v);
    });
  }

  Future<void> _init() async {
    _incidentIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(26, 26)),
      'assets/warning-hazard-sign-on-transparent-background-free-png.png',
    );
    setState(() => _loadingIncidents = true);
    await _loadIncidents();
    if (mounted) setState(() => _loadingIncidents = false);
  }

  Future<void> _loadIncidents() async {
    setState(() => _loadingIncidents = true);
    final result = roleProvider.role == UserRole.blueCollar
        ? await getBlueCollarApi()
        : await getAllIncidentsApi();

    if (!mounted) return;
    setState(() => _incidents = result);

    final map = await locationServices.distancesForIncidents(context, result);
    if (!mounted) return;

    setState(() {
      _distanceMap
        ..clear()
        ..addAll(map);
    });

    _applyFilters();
    _syncMarkers();
    if (mounted) setState(() => _loadingIncidents = false);
  }

  void _applyFilters() {
    final q = _filters.search.trim().toLowerCase();
    final selQuartier = _filters.quartier == null ? null : normalizeKey(_filters.quartier!);

    final visible = _incidents.where((i) {
      final matchesTitle = i.title.toLowerCase().contains(q);
      final matchesStatus = (_filters.status == '' || _filters.status == null) || i.status.toString() == _filters.status;
      final matchesCategory = _filters.category == null || i.category == _filters.category;
      final matchesNeighborhood = selQuartier == null || normalizeKey(i.quartier ?? '') == selQuartier;
      return matchesTitle && matchesStatus && matchesCategory && matchesNeighborhood;
    }).toList();

    visible.sort((a, b) {
      final da = _distanceMap[a.id] ?? double.infinity;
      final db = _distanceMap[b.id] ?? double.infinity;
      return _filters.distance == 'Closest' ? da.compareTo(db) : db.compareTo(da);
    });

    setState(() => _visible = visible);
    _syncMarkers();
  }

  Future<void> _resetAllFilters() async {
    _searchCtrl.clear();
    setState(() {
      _filters.clear();
      _selectedIncidentId = null;
    });

    _applyFilters();

    final c = await _mapController.future;
    await c.animateCamera(CameraUpdate.newCameraPosition(MapConstants.initialPosition));
  }

  Future<void> _syncMarkers() async {
    // Pour chaque incident visible, récupère l'icône Twemoji
    final List<Future<Marker>> markerFutures = _visible.map((i) async {
      final isSelected = i.id == _selectedIncidentId;
      final icon = await getCategoryMarkerIcon(i.category);
      return Marker(
        markerId: MarkerId(i.id.toString()),
        position: LatLng(i.latitude, i.longitude),
        icon: isSelected
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
            : icon,
        infoWindow: InfoWindow(title: i.title),
        onTap: () => _openIncident(i, focusOnly: false),
      );
    }).toList();

    final newMarkers = Set<Marker>.from(await Future.wait(markerFutures));

    setState(() {
      _markers = newMarkers;
      _lastSyncedSelectedId = _selectedIncidentId;
    });
  }

  Future<void> _focusIncident(Incident i) async {
    _bottomSheetKey.currentState?.scrollToTop();
    await Future.delayed(const Duration(milliseconds: 50));

    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.16,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    setState(() => _selectedIncidentId = i.id);
    _syncMarkers();

    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(i.latitude, i.longitude), zoom: 16),
      ),
    );
  }

  Future<void> _openIncident(Incident i, {required bool focusOnly}) async {
    setState(() => _selectedIncidentId = i.id);
    _syncMarkers();

    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(i.latitude, i.longitude), zoom: 15),
      ),
    );
    if (focusOnly) return;
    final result = await Navigator.push<bool>(context,MaterialPageRoute(builder: (_) => IncidentDetailsPage(incidentId: i.id)),);
    if (!mounted) return;

    if (result != null) {
      final idx = _incidents.indexWhere((x) => x.id == i.id);
      if (idx != -1) {
        setState(() => _incidents[idx].isLiked = result);
        _applyFilters();
      }
    }
  }

  LatLngBounds _boundsFromPoints(List<LatLng> pts) {
    var minLat = pts.first.latitude;
    var maxLat = pts.first.latitude;
    var minLng = pts.first.longitude;
    var maxLng = pts.first.longitude;

    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _zoomToQuartier(String? q) async {
    final controller = await _mapController.future;

    if (q == null) {
      await controller.animateCamera(CameraUpdate.newCameraPosition(MapConstants.initialPosition));
      return;
    }

    final pts = QuartiersService.polygons[q];
    if (pts == null || pts.isEmpty) return;

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsFromPoints(pts), 60),
    );
  }

  Future<void> _toggleLike(Incident incident) async {
    final oldLiked = incident.isLiked;
    final oldCount = incident.likeCount;

    setState(() {
      incident.isLiked = !oldLiked;
      incident.likeCount += oldLiked ? -1 : 1;
    });

    try {
      await putLike(incident.id);
    } catch (_) {
      setState(() {
        incident.isLiked = oldLiked;
        incident.likeCount = oldCount;
      });
    }
  }

  Future<void> _ensureSubInfo(int incidentId) async {
    if (_subInfoByIncident.containsKey(incidentId)) return;
    if (_subLoading.contains(incidentId)) return;

    setState(() => _subLoading.add(incidentId));

    try {
      final info = await getSubscriptionInfos(incidentId);
      if (!mounted) return;
      setState(() {
        _subInfoByIncident[incidentId] = info;
        _subLoading.remove(incidentId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _subLoading.remove(incidentId));
    }
  }

  Future<void> _toggleSubscriptionFor(int incidentId) async {
    await _ensureSubInfo(incidentId);
    if (_toggleSubInProgress.contains(incidentId)) return;

    setState(() => _toggleSubInProgress.add(incidentId));

    try {
      final current = _subInfoByIncident[incidentId];
      if (current == null) return;

      if (current.isMandatory == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).cannotUnsubscribe)),
        );
        return;
      }

      final result = await toggleSubscriptionInfos(incidentId);
      if (!mounted) return;
      setState(() => _subInfoByIncident[incidentId] = result);

      final s = S.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.isSubscribed ? s.subscribedSuccess : s.unsubscribedSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _toggleSubInProgress.remove(incidentId));
    }
  }

  Future<void> _openCommentsSheet(Incident incident) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(incidentId: incident.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      body: Stack(
        children: [
          MapView(
            mapControllerCompleter: _mapController,
            markers: _markers,
            polygons: buildQuartierPolygons(_filters.quartier),
            onRefresh: _loadIncidents, selectedQuartier: '',
          ),
          OverlayWidget(extent: _sheetExtent),
          SearchFiltersWidget(controller: _searchCtrl,
            s: s,
            resetActive: _filters.resetActive,
            selectedStatus: _filters.status,
            selectedCategory: _filters.category,
            selectedNeighborhood: _filters.quartier,
            selectedDistance: _filters.distance,
            onReset: _resetAllFilters,
            onClear: () => _setFilters((f) {
              f.clear();
              _selectedIncidentId = null;
            }),
            onStatusChanged: (v) => _setFilters((f) => f.status = v),
            onCategoryChanged: (v) => _setFilters((f) => f.category = v),
            onNeighborhoodChanged: (v) async {
              _setFilters((f) => f.quartier = v);
              await _zoomToQuartier(v);
            },
            onDistanceChanged: (v) => _setFilters((f) => f.distance = v),
          ),
          IncidentsBottomSheet(
            key: _bottomSheetKey,
            incidents: _visible,
            subInfoByIncident: _subInfoByIncident,
            subLoading: _subLoading,
            toggleInProgress: _toggleSubInProgress,
            distanceMap: _distanceMap,
            sheetExtent: _sheetExtent,
            sheetController: _sheetController,
            onExtentChanged: (extent) => setState(() => _sheetExtent = extent),
            onRefresh: _loadIncidents,
            onLike: _toggleLike,
            onOpenComments: _openCommentsSheet,
            onOpenDetails: (i) => _openIncident(i, focusOnly: false),
            onToggleSubscription: _toggleSubscriptionFor,
            onRequestSubInfo: _ensureSubInfo,
            onFocusIncident: _focusIncident,
          ),
          if (_loadingIncidents)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}