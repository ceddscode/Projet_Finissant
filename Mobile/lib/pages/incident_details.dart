import 'package:flutter/material.dart';
import 'package:municipalgo/http/dtos/transfer.dart';
import 'package:municipalgo/http/lib_http.dart';
import 'package:municipalgo/models/intervention_type_enum.dart';
import 'package:municipalgo/pages/confirmation_incident_page.dart';
import 'package:municipalgo/services/intervention_type_translator.dart';
import 'package:municipalgo/services/date_formatter.dart';
import 'package:municipalgo/widgets/incident_post_card.dart';
import 'package:municipalgo/widgets/photo_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:municipalgo/widgets/comments_sheet.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import '../services/icon_change_intervention_type.dart';
import '../services/roleProvider.dart';

class IncidentDetailsPage extends StatefulWidget {
  final int incidentId;

  const IncidentDetailsPage({required this.incidentId, super.key});

  @override
  State<IncidentDetailsPage> createState() => _IncidentDetailsPageState();
}

class _IncidentDetailsPageState extends State<IncidentDetailsPage> {
  RoleProvider get roleProvider => context.watch<RoleProvider>();
  bool loading = true;
  IncidentDetailsDTO? incident;
  SubscriptionInfo? subInfo;
  List<IncidentHistoryDTO> incidentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadIncident();
  }

  bool get isCitizen => roleProvider.role == UserRole.citizen;
  bool get isCitizenOwner => incident?.citizenId == roleProvider.userId;
  bool get canStart => isCitizenOwner && incident?.status == 2;
  bool get canTerminate => isCitizenOwner && incident?.status == 3;

  bool get isBlueCollar => roleProvider.role == UserRole.blueCollar;
  bool get isBlueCollarOwner => incident?.citizenId == roleProvider.userId;
  bool get canBlueCollarStart => isBlueCollarOwner && incident?.status == 5;
  bool get canBlueCollarTerminate => isBlueCollarOwner && incident?.status == 3;

  Future<void> _loadIncident() async {
    setState(() => loading = true);
    try {
      final fetchedIncident = await getIncidentDetails(widget.incidentId);
      final subscription = await getSubscriptionInfos(widget.incidentId);
      final historiqueIncidents = await getIncidentHistory(widget.incidentId);

      if (!mounted) return;
      setState(() {
        incident = fetchedIncident;
        subInfo = subscription;
        incidentHistory = historiqueIncidents;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  /// Convert IncidentDetailsDTO → Incident for IncidentPostCard
  Incident _toIncident(IncidentDetailsDTO dto) {
    return Incident(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      isLiked: dto.isLiked,
      likeCount: dto.likeCount,
      imagesUrl: dto.imagesUrl,
      location: dto.location,
      createdAt: dto.createdDate,
      category: dto.category,
      status: dto.status,
      latitude: 0,
      longitude: 0,
    );
  }

  Future<void> _toggleLike() async {
    if (incident == null) return;
    final oldValue = incident!.isLiked;
    setState(() => incident!.isLiked = !oldValue);
    try {
      await putLike(incident!.id);
    } catch (e) {
      setState(() => incident!.isLiked = oldValue);
    }
  }

  Future<void> _toggleSubscription() async {
    if (subInfo?.isMandatory == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).cannotUnsubscribe)));
      return;
    }
    try {
      final result = await toggleSubscriptionInfos(widget.incidentId);
      setState(() => subInfo = result);
      final s = S.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.isSubscribed ? s.subscribedSuccess : s.unsubscribedSuccess)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _takeTask() async {
    if (loading || incident == null) return;
    setState(() => loading = true);
    try {
      await getTakeTask(id: incident!.id);
      await _loadIncident();
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _startTask() async {
    if (loading || incident == null) return;
    setState(() => loading = true);
    try {
      await changeStatusToUnderRepair(id: incident!.id);
      await _loadIncident();
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _terminateTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConfirmationIncidentPage(incidentId: widget.incidentId)),
    ).then((_) => _loadIncident());
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CommentsSheet(incidentId: widget.incidentId),
    );
  }

  Widget _buildActionButton(S s) {
    if (loading || incident == null) return const SizedBox.shrink();
    if (!isCitizen && !isBlueCollar) return const SizedBox.shrink();

    String label;
    Color color;
    VoidCallback action;

    if (incident!.status == 6 && isCitizen) {
      label = s.assign;
      color = Colors.lightBlueAccent;
      action = _takeTask;
    } else if ((canStart && isCitizen) || (canBlueCollarStart && isBlueCollar)) {
      label = s.startTask;
      color = Colors.orange;
      action = _startTask;
    } else if ((canTerminate && isCitizen) || (canBlueCollarTerminate && isBlueCollar)) {
      label = s.terminateTask;
      color = Colors.red;
      action = _terminateTask;
    } else {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
        onPressed: action,
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(s.details)),
      body: Stack(
        children: [
          if (incident != null)
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Incident post card (like accueil) ──
                        IncidentPostCard(
                          incident: _toIncident(incident!),
                          subInfo: subInfo,
                          subLoading: false,
                          subToggleInProgress: false,
                          onLike: _toggleLike,
                          onOpenDetails: () {},  // already on details
                          onOpenComments: _openComments,
                          onToggleSubscription: _toggleSubscription,
                          onRefresh: _loadIncident,
                        ),

                        // ── Confirmation proof (only when Done) ──
                        if (incident!.status == 4) _buildConfirmationSection(s),

                        // ── History section ──
                        _buildHistorySection(s),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _buildActionButton(s),
                ),
              ],
            ),
          if (loading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  Confirmation proof section (shown when status == Done)
  // ══════════════════════════════════════════════════════════
  Widget _buildConfirmationSection(S s) {
    final desc = (incident!.confirmationDescription ?? '').trim();
    final images = incident!.confirmationImagesUrl ?? [];
    final hasContent = desc.isNotEmpty || images.isNotEmpty;

    if (!hasContent) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Row(
            children: [
              Icon(Icons.verified, color: Colors.green.shade600, size: 22),
              const SizedBox(width: 8),
              Text(
                s.confirmationProof,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (desc.isNotEmpty) ...[
                  Text(
                    s.confirmationDescription,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (images.isNotEmpty) const SizedBox(height: 16),
                ],

                // Photos
                if (images.isNotEmpty) ...[
                  Text(
                    s.confirmationPhotos,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => PhotoViewer.show(context, images, initialIndex: index),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: images[index],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey.shade200,
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              ),
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
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  History section (kept from original)
  // ══════════════════════════════════════════════════════════
  Widget _buildHistorySection(S s) {
    if (incidentHistory.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(s.history, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  itemCount: incidentHistory.length,
                  shrinkWrap: false,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[300]),
                  itemBuilder: (context, index) => _buildHistoryItem(incidentHistory[index], s),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Empty history
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(s.history, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  s.noHistory,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(IncidentHistoryDTO history, S s) {
    final interventionType = history.interventionType != null
        ? InterventionTypeEnum.values[history.interventionType!]
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.blue[100], shape: BoxShape.circle),
                child: Center(
                  child: history.interventionType != null
                      ? InterventionTypeIcon(interventionTypeIndex: history.interventionType!)
                      : Icon(Icons.help, color: Colors.blue[700]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserRoleLabel(history),
                    if (history.interventionType != null)
                      Text(
                        InterventionTypeTranslator.translate(history.interventionType!, s),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    Text(
                      DateFormatter.formatDateTime(context, history.updatedAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Refusal message
          if (interventionType == InterventionTypeEnum.RefusedRepair &&
              history.refusDescription != null &&
              history.refusDescription!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                history.refusDescription!,
                style: TextStyle(color: Colors.red[700], fontSize: 13),
              ),
            ),
          ],
          // Confirmation images
          if (interventionType == InterventionTypeEnum.DoneRepairing &&
              history.confirmationImgUrls != null &&
              history.confirmationImgUrls!.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: history.confirmationImgUrls!.length,
                itemBuilder: (context, imgIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        history.confirmationImgUrls![imgIndex],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserRoleLabel(IncidentHistoryDTO history) {
    final s = S.of(context);
    final name = history.nomUtilisateur ?? '';
    final role = history.roleUtilisateur ?? '';
    final isAnon = history.isAnonymous ?? false;

    String roleLabel;
    switch (role) {
      case "1":
        roleLabel = s.whiteCollar;
        break;
      case "2":
        roleLabel = s.blueCollar;
        break;
      case "3":
        roleLabel = s.citizen;
        break;
      case "4":
        roleLabel = s.admin;
        break;
      default:
        roleLabel = s.unknown;
    }

    final displayName = (role == "3" && isAnon) ? s.anonymous : name;
    return Text('$displayName - $roleLabel');
  }
}
