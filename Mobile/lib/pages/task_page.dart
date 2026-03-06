import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:municipalgo/generated/l10n.dart';

import 'package:municipalgo/http/dtos/transfer.dart';

import 'package:municipalgo/http/lib_http.dart';

import 'package:municipalgo/services/location_services.dart';

import 'package:municipalgo/pages/incident_details.dart';

import 'package:municipalgo/services/roleProvider.dart';

import 'package:municipalgo/widgets/incident_post_card.dart';

import '../services/intervention_type_translator.dart';

import '../services/icon_change_intervention_type.dart';

import '../services/date_formatter.dart';

import '../models/intervention_type_enum.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final Map<int, double> _distanceMap = {};

  final Map<int, SubscriptionInfo> _subInfoByIncident = {};

  final Set<int> _subLoading = {};

  final Set<int> _toggleSubInProgress = {};

  List<Incident> _incidents = [];

  List<IncidentHistoryDTO> _interventions = [];

  bool _loading = true;

  int selectedTab = 0;

  RoleProvider get roleProvider => context.read<RoleProvider>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isBlue = roleProvider.role == UserRole.blueCollar;

      if (isBlue) {
        await _loadMesTaches();
      } else {
        await _loadMesTaches();
      }
    });
  }

  Future<void> _openDetailsById(int id) async {
    if (!mounted) return;

    await Navigator.push(
      context,

      MaterialPageRoute(builder: (_) => IncidentDetailsPage(incidentId: id)),
    );
  }

  Future<void> _openDetails(Incident i) async {
    await _openDetailsById(i.id);
  }

  Future<void> _loadMesTaches({bool refresh = false}) async {
    if (!refresh) setState(() => _loading = true);

    setState(() => selectedTab = 0);

    try {
      final result = await getBlueCollarApi();

      if (!mounted) return;

      setState(() {
        _incidents = result;

        _interventions = [];

        _loading = false;
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

      setState(() {
        _incidents = [];

        _interventions = [];

        _loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _loadAbonnes({bool refresh = false}) async {
    if (!refresh) setState(() => _loading = true);

    setState(() => selectedTab = 1);

    try {
      final result = await getSubbedIncidents();

      if (!mounted) return;

      setState(() {
        _incidents = result;

        _interventions = [];

        _loading = false;
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

      setState(() {
        _incidents = [];

        _interventions = [];

        _loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _loadMesInterventions({bool refresh = false}) async {
    if (!refresh) setState(() => _loading = true);

    setState(() => selectedTab = 2);

    try {
      final result = await getMyIncidentHistory();

      if (!mounted) return;

      setState(() {
        _interventions = result;

        _incidents = [];

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _interventions = [];

        _incidents = [];

        _loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _refresh() async {
    if (selectedTab == 0) {
      await _loadMesTaches(refresh: true);

      return;
    }

    if (selectedTab == 1) {
      await _loadAbonnes(refresh: true);

      return;
    }

    await _loadMesInterventions(refresh: true);
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
      if (!mounted) return;

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
        SnackBar(
          content: Text(
            result.isSubscribed ? s.subscribedSuccess : s.unsubscribedSuccess,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _toggleSubInProgress.remove(incidentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final isBlue = roleProvider.role == UserRole.blueCollar;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,

                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  slivers: [
                    SliverToBoxAdapter(child: _header(s, isBlue)),

                    if (selectedTab == 2) ...[
                      if (_interventions.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,

                          child: Center(child: Text(s.noIncidentsAvailable)),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),

                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildInterventionCard(_interventions[index]),

                              childCount: _interventions.length,
                            ),
                          ),
                        ),
                    ] else ...[
                      if (_incidents.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,

                          child: Center(child: Text(s.noIncidentsAvailable)),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),

                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final incident = _incidents[index];

                              final subInfo = _subInfoByIncident[incident.id];

                              final isSubLoading = _subLoading.contains(
                                incident.id,
                              );

                              final isToggleLoading = _toggleSubInProgress
                                  .contains(incident.id);

                              return IncidentPostCard(
                                incident: incident,

                                subInfo: subInfo,

                                subLoading: isSubLoading,

                                subToggleInProgress: isToggleLoading,

                                distance: _distanceMap[incident.id],

                                onLike: () => _toggleLike(incident),

                                onOpenDetails: () => _openDetails(incident),

                                onOpenComments: () {},

                                onToggleSubscription: () =>
                                    _toggleSubscriptionFor(incident.id),

                                onRequestSubInfo: () =>
                                    _ensureSubInfo(incident.id),

                                onFocusIncident: null,
                              );
                            }, childCount: _incidents.length),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _header(S s, bool isBlue) {
    if (isBlue) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),

        child: Row(
          children: [
            Text(
              s.myIncidents,

              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const Spacer(),

            IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _loadMesTaches(),

                  icon: Icon(
                    Icons.work,
                    size: 18,
                    color: selectedTab == 0 ? Colors.white : null,
                  ),

                  label: Text(
                    s.myIncidents,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 12,

                      fontWeight: FontWeight.w700,

                      color: selectedTab == 0 ? Colors.white : null,
                    ),
                  ),

                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),

                    backgroundColor: selectedTab == 0
                        ? Theme.of(context).primaryColor
                        : null,

                    side: BorderSide(
                      color: Colors.black.withValues(alpha: 0.12),
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _loadAbonnes(),

                  icon: Icon(
                    Icons.notifications,
                    size: 18,
                    color: selectedTab == 1 ? Colors.white : null,
                  ),

                  label: Text(
                    s.subbed,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 12,

                      fontWeight: FontWeight.w700,

                      color: selectedTab == 1 ? Colors.white : null,
                    ),
                  ),

                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),

                    backgroundColor: selectedTab == 1
                        ? Theme.of(context).primaryColor
                        : null,

                    side: BorderSide(
                      color: Colors.black.withValues(alpha: 0.12),
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _loadMesInterventions(),

                  icon: Icon(
                    Icons.build,
                    size: 18,
                    color: selectedTab == 2 ? Colors.white : null,
                  ),

                  label: Text(
                    s.myInterventions,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 12,

                      fontWeight: FontWeight.w700,

                      color: selectedTab == 2 ? Colors.white : null,
                    ),
                  ),

                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),

                    backgroundColor: selectedTab == 2
                        ? Theme.of(context).primaryColor
                        : null,

                    side: BorderSide(
                      color: Colors.black.withValues(alpha: 0.12),
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                s.incidentsCount(
                  selectedTab == 2 ? _interventions.length : _incidents.length,
                ),

                style: TextStyle(
                  fontSize: 13,

                  fontWeight: FontWeight.w700,

                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),

              const Spacer(),

              IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionCard(IncidentHistoryDTO intervention) {
    final s = S.of(context);

    return GestureDetector(
      onTap: () => _openDetailsById(intervention.incidentId!),

      child: Card(
        margin: const EdgeInsets.only(bottom: 12),

        elevation: 1,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

        child: Padding(
          padding: const EdgeInsets.all(12),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Container(
                    width: 48,

                    height: 48,

                    decoration: BoxDecoration(
                      color: Colors.blue[100],

                      shape: BoxShape.circle,
                    ),

                    child: Center(
                      child: InterventionTypeIcon(
                        interventionTypeIndex: intervention.interventionType,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          InterventionTypeTranslator.translate(
                            intervention.interventionType!,

                            s,
                          ),

                          style: const TextStyle(
                            fontWeight: FontWeight.bold,

                            fontSize: 14,
                          ),
                        ),

                        Text(
                          intervention.titreIncident ?? 'Incident inconnu',

                          style: TextStyle(
                            color: Colors.grey[600],

                            fontSize: 12,
                          ),
                        ),

                        Text(
                          DateFormatter.formatDateTime(
                            context,
                            intervention.updatedAt,
                          ),

                          style: TextStyle(
                            color: Colors.grey[500],

                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (InterventionTypeEnum.values[intervention.interventionType!] ==
                      InterventionTypeEnum.RefusedRepair &&
                  intervention.refusDescription != null &&
                  intervention.refusDescription!.isNotEmpty) ...[
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(10),

                  decoration: BoxDecoration(
                    color: Colors.red[50],

                    border: Border.all(color: Colors.red[300]!),

                    borderRadius: BorderRadius.circular(6),
                  ),

                  child: Text(
                    intervention.refusDescription!,

                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              ],

              if (InterventionTypeEnum.values[intervention.interventionType!] ==
                      InterventionTypeEnum.DoneRepairing &&
                  intervention.confirmationImgUrls != null &&
                  intervention.confirmationImgUrls!.isNotEmpty) ...[
                const SizedBox(height: 12),

                SizedBox(
                  height: 80,

                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,

                    itemCount: intervention.confirmationImgUrls!.length,

                    itemBuilder: (context, imgIndex) {
                      final imageUrl =
                          intervention.confirmationImgUrls![imgIndex];

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),

                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),

                          child: Image.network(
                            imageUrl,

                            width: 80,

                            height: 80,

                            fit: BoxFit.cover,

                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,

                                height: 80,

                                decoration: BoxDecoration(
                                  color: Colors.grey[300],

                                  borderRadius: BorderRadius.circular(6),
                                ),

                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
