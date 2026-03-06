import 'package:flutter/material.dart';
import 'package:municipalgo/http/dtos/transfer.dart';
import 'package:municipalgo/pages/incident_details.dart';
import 'package:provider/provider.dart';
import '../services/roleProvider.dart';
import '../widgets/incident_card.dart';
import '../http/lib_http.dart';
import 'package:municipalgo/generated/l10n.dart';
import 'package:municipalgo/services/location_services.dart';

String getCategoryLabel(int categoryId, S s) {
  switch (categoryId) {
    case 0:
      return s.cleanliness;
    case 1:
      return s.furniture;
    case 2:
      return s.roadSigns;
    case 3:
      return s.greenSpaces;
    case 4:
      return s.seasonal;
    case 5:
      return s.social;
    default:
      return 'Unknown';
  }
}


class Accueil extends StatefulWidget {
  const Accueil({super.key});

  @override
  State<Accueil> createState() => _AccueilState();
}

class _AccueilState extends State<Accueil> {
  List<Incident>? incidents;
  RoleProvider get roleProvider => context.read<RoleProvider>();
  final Map<int, double> _distanceMap = {};
  bool isInitialLoad = true;

  // Backwards compatibility: some code may reference `isLoading` as a field.
  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String? selectedDistance = 'Closest';
  String? selectedStatus = '';
  int? selectedCategory;
  String? selectedNeighborhood;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
    _searchController.addListener(() {
      final v = _searchController.text;
      if (v != _search) setState(() => _search = v);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }



  Future<void> loadIncidentDetails(Incident incident) async {
    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentDetailsPage(
          incidentId: incident.id,
        ),
      ),
    );

    // 👇 Si le détail retourne une nouvelle valeur de like
    if (result != null) {
      setState(() {
        incident.isLiked = result;
      });
    }
  }

  Future<void> _loadIncidents() async {
    try {
      final result = roleProvider.role == UserRole.blueCollar
          ? await getBlueCollarApi()
          : await getAllIncidentsApi();
      if (!mounted) return;
      setState(() {
        incidents = result;
        isInitialLoad = false;
        isLoading = false;
      });

      final map = await locationServices.distancesForIncidents(context, result);
      if (!mounted) return;

      setState(() {
        _distanceMap
          ..clear()
          ..addAll(map);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

      setState(() {
        incidents = [];
        isInitialLoad = false;
        isLoading = false;
      });
    }
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
    } catch (e) {
      setState(() {
        incident.isLiked = oldLiked;
        incident.likeCount = oldCount;
      });
    }
  }
  Future<void> _refresh() async {
    await _loadIncidents();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final roleProvider = context.watch<RoleProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          roleProvider.role == UserRole.blueCollar ? s.homeAssigned : s.homeAll,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),

          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: isInitialLoad
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _refresh,
          child: _buildBody(s),
        ),
      ),
    );
  }

  Widget _buildBody(S s) {
    final list = incidents;

    if (list == null || list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 200),
          Center(child: Text(s.noIncidents)),
        ],
      );
    }

    final q = _search.trim().toLowerCase();
    final visible = list.where((i) {
      final matchesTitle = i.title.toLowerCase().contains(q);

      bool matchesStatus = true;
      if (selectedStatus != '') {
        matchesStatus = i.status.toString() == selectedStatus;
      }

      bool matchesCategory = true;
      if (selectedCategory != null) {
        matchesCategory = i.category == selectedCategory;
      }

      bool matchesNeighborhood = true;
      if (selectedNeighborhood != null) {
        matchesNeighborhood = (i.quartier ?? '').toLowerCase() == selectedNeighborhood!.toLowerCase();
      }

      return matchesTitle && matchesStatus && matchesCategory && matchesNeighborhood;
    }).toList();

    if (selectedDistance == 'Closest') {
      visible.sort((a, b) => (_distanceMap[a.id] ?? double.infinity).compareTo(_distanceMap[b.id] ?? double.infinity));
    } else if (selectedDistance == 'Farthest') {
      visible.sort((a, b) => (_distanceMap[b.id] ?? double.infinity).compareTo(_distanceMap[a.id] ?? double.infinity));
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: visible.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: s.search,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await showDialog<String>(
                            context: context,
                            builder: (ctx) => SimpleDialog(
                              title: Text(s.status),
                              children: [
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, ''), child: const Text('All')),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, '6'), child: Text(s.waitingAssignment)),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, '2'), child: Text(s.assignedToCitizen)),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, '3'), child: Text(s.underRepair)),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, '4'), child: Text(s.done)),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, '5'), child: Text(s.assignedBlueCollar)),
                              ],
                            ),
                          );

                          if (result != null) {
                            setState(() => selectedStatus = result);
                          }
                        },
                        icon: const Icon(Icons.filter_list, size: 18),
                        label: Text(s.status, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          backgroundColor: selectedStatus != '' ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Debug: show all incident categories
                          final allCategories = list.map((i) => i.category).toSet().toList();
                          print('DEBUG - All category IDs in incidents: $allCategories');

                          final result = await showDialog<int?>(
                            context: context,
                            builder: (ctx) => SimpleDialog(
                              title: Text(s.category),
                              children: [
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, null), child: const Text('All')),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 0), child: Text('${getCategoryLabel(0, s)} ')),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 1), child: Text('${getCategoryLabel(1, s)} ')),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 2), child: Text('${getCategoryLabel(2, s)}')),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 3), child: Text('${getCategoryLabel(3, s)}')),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 4), child: Text('${getCategoryLabel(4, s)}')),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 5), child: Text('${getCategoryLabel(5, s)}')),
                              ],
                            ),
                          );
                          if (result != null || result == null) {
                            print('DEBUG - Selected category ID: $result');
                            setState(() => selectedCategory = result);
                          }
                        },
                        icon: const Icon(Icons.category, size: 18),
                        label: Text(
                          selectedCategory == null ? s.category : getCategoryLabel(selectedCategory!, s),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          backgroundColor: selectedCategory != null ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await showDialog<String>(
                            context: context,
                            builder: (ctx) => SimpleDialog(
                              title: Text(s.distance),
                              children: [
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'Closest'), child: Text(s.closest)),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'Farthest'), child: Text(s.farthest)),
                              ],
                            ),
                          );
                          if (result != null) {
                            setState(() => selectedDistance = result);
                          }
                        },
                        icon: const Icon(Icons.near_me, size: 18),
                        label: Text(
                          selectedDistance == 'Closest' ? s.closest : s.farthest,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await showDialog<String?>(
                            context: context,
                            builder: (ctx) => SimpleDialog(
                              title: Text('Quartier'),
                              children: [
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, null), child: const Text('All')),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'Vieux-Longueuil'), child: Text('Vieux-Longueuil')),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'Saint-Hubert'), child: Text('Saint-Hubert')),
                                SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'Greenfield Park'), child: Text('Greenfield Park')),
                              ],
                            ),
                          );

                            setState(() => selectedNeighborhood = result);

                        },
                        icon: const Icon(Icons.location_pin, size: 18),
                        label: Text(
                          'Quartier',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final incident = visible[index - 1];
        final d = _distanceMap[incident.id];

        return InkWell(
          onTap: () => loadIncidentDetails(incident),
          child: IncidentCard(
            incident: incident,
            distanceMeters: d,
            onLike: () => _toggleLike(incident),
          ),
        );
      },
    );
  }
}