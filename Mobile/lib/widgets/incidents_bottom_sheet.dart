import 'package:flutter/material.dart';
import '../generated/l10n.dart';
import '../http/dtos/transfer.dart';
import 'common_widgets.dart';
import 'incident_post_card.dart';

/// Bottom sheet draggable pour afficher la liste des incidents
class IncidentsBottomSheet extends StatefulWidget {
  final List<Incident> incidents;
  final Map<int, SubscriptionInfo> subInfoByIncident;
  final Set<int> subLoading;
  final Set<int> toggleInProgress;
  final Map<int, double> distanceMap;
  final double sheetExtent;
  final ValueChanged<double> onExtentChanged;
  final VoidCallback onRefresh;
  final void Function(Incident) onLike;
  final void Function(Incident) onOpenComments;
  final void Function(Incident) onOpenDetails;
  final void Function(int) onToggleSubscription;
  final void Function(int) onRequestSubInfo;
  final void Function(Incident) onFocusIncident;
  final DraggableScrollableController? sheetController;

  const IncidentsBottomSheet({
    super.key,
    required this.incidents,
    required this.subInfoByIncident,
    required this.subLoading,
    required this.toggleInProgress,
    required this.distanceMap,
    required this.sheetExtent,
    required this.onExtentChanged,
    required this.onRefresh,
    required this.onLike,
    required this.onOpenComments,
    required this.onOpenDetails,
    required this.onToggleSubscription,
    required this.onRequestSubInfo,
    required this.onFocusIncident,
    this.sheetController,
  });

  @override
  State<IncidentsBottomSheet> createState() => IncidentsBottomSheetState();
}

class IncidentsBottomSheetState extends State<IncidentsBottomSheet> {
  ScrollController? _activeScrollController;

  void scrollToTop() {
    final c = _activeScrollController;
    if (c != null && c.hasClients) {
      c.jumpTo(0);
    }
  }

  @override
  void dispose() {
    // don't dispose controller provided by DraggableScrollableSheet
    _activeScrollController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: widget.sheetController,
      initialChildSize: 0.28,
      minChildSize: 0.16,
      maxChildSize: 0.82,
      snap: true,
      snapSizes: const [0.16, 0.28, 0.82],
      builder: (ctx, sheetScrollCtrl) {
        // keep a reference to the active scroll controller for programmatic scrolling
        _activeScrollController = sheetScrollCtrl;
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (n) {
            if (widget.sheetExtent != n.extent) {
              widget.onExtentChanged(n.extent);
            }
            return false;
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 6,
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, -3),
                )
              ],
            ),
            child: Column(
              children: [
                // Fixed header - draggable area
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (details) {
                    // Forward drag to sheet controller
                    if (widget.sheetController != null && widget.sheetController!.isAttached) {
                      final currentSize = widget.sheetController!.size;
                      final delta = -details.primaryDelta! / MediaQuery.of(context).size.height;
                      final newSize = (currentSize + delta).clamp(0.16, 0.82);
                      widget.sheetController!.jumpTo(newSize);
                    }
                  },
                  child: _buildHeader(context),
                ),
                // Scrollable list - use ListView.builder (lazy build) with the sheet controller
                Expanded(
                  child: widget.incidents.isEmpty
                      ? Center(child: Text(S.of(context).noIncidentsAvailable))
                      : ListView.builder(
                          controller: sheetScrollCtrl,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                          physics: const ClampingScrollPhysics(),
                          itemCount: widget.incidents.length,
                          cacheExtent: 600,
                          itemBuilder: (ctx, index) {
                            final incident = widget.incidents[index];
                            final subInfo = widget.subInfoByIncident[incident.id];
                            final isSubLoading = widget.subLoading.contains(incident.id);
                            final isToggleInProgress = widget.toggleInProgress.contains(incident.id);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              key: ValueKey('incident-${incident.id}'),
                              child: IncidentPostCard(
                                incident: incident,
                                subInfo: subInfo,
                                subLoading: isSubLoading,
                                subToggleInProgress: isToggleInProgress,
                                distance: widget.distanceMap[incident.id],
                                onLike: () => widget.onLike(incident),
                                onOpenComments: () => widget.onOpenComments(incident),
                                onOpenDetails: () => widget.onOpenDetails(incident),
                                onToggleSubscription: () => widget.onToggleSubscription(incident.id),
                                onRequestSubInfo: () => widget.onRequestSubInfo(incident.id),
                                onFocusIncident: () => widget.onFocusIncident(incident),
                              onRefresh: widget.onRefresh,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final s = S.of(context);
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          const SheetHandle(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Text(
                  s.incidentsCount(widget.incidents.length),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
