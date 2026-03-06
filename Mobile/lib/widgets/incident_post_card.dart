import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../generated/l10n.dart';
import '../http/dtos/transfer.dart';
import '../http/lib_http.dart';
import '../services/time_ago.dart';
import '../services/category_translator.dart';
import '../services/icon_change_category.dart';
import '../services/roleProvider.dart';
import '../pages/confirmation_incident_page.dart';
import 'common_widgets.dart';
import 'photo_viewer.dart';

class IncidentPostCard extends StatefulWidget {
  final Incident incident;
  final SubscriptionInfo? subInfo;
  final bool subLoading;
  final bool subToggleInProgress;
  final VoidCallback onLike;
  final VoidCallback onOpenDetails;
  final VoidCallback onOpenComments;
  final VoidCallback onToggleSubscription;
  final VoidCallback? onRequestSubInfo;
  final VoidCallback? onFocusIncident;
  final double? distance;
  final VoidCallback? onRefresh;

  const IncidentPostCard({
    super.key,
    required this.incident,
    required this.subInfo,
    required this.subLoading,
    required this.onLike,
    required this.onOpenDetails,
    required this.onOpenComments,
    required this.onToggleSubscription,
    this.onRequestSubInfo,
    this.onFocusIncident,
    this.distance,
    this.subToggleInProgress = false,
    this.onRefresh,
  });

  @override
  State<IncidentPostCard> createState() => _IncidentPostCardState();
}

class _IncidentPostCardState extends State<IncidentPostCard> with AutomaticKeepAliveClientMixin {
   int _page = 0;

  bool _descExpanded = false;
  String? _remoteDescription;
  bool _loadingDescription = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.subInfo == null && widget.onRequestSubInfo != null) {
        widget.onRequestSubInfo!();
      }
      if ((widget.incident.description ?? '').trim().isEmpty) {
        _ensureDescriptionLoaded();
      }
    });
  }

  @override
  void didUpdateWidget(covariant IncidentPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.incident.id != widget.incident.id) {
      _page = 0;
      _descExpanded = false;
      _remoteDescription = null;
      _loadingDescription = false;

      if ((widget.incident.description ?? '').trim().isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _ensureDescriptionLoaded();
        });
      }
    }
  }

  Future<void> _ensureDescriptionLoaded() async {
    if (_loadingDescription) return;

    final local = (widget.incident.description ?? '').trim();
    if (local.isNotEmpty) return;

    if (_remoteDescription != null && _remoteDescription!.trim().isNotEmpty) return;

    final requestId = widget.incident.id;

    setState(() => _loadingDescription = true);
    try {
      final details = await getIncidentDetails(requestId);

      if (!mounted) return;
      if (widget.incident.id != requestId) return;

      setState(() => _remoteDescription = (details.description ?? '').trim());
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (!mounted) return;
      if (widget.incident.id == requestId) {
        setState(() => _loadingDescription = false);
      }
    }
  }

  String _effectiveDescription() {
    final local = (widget.incident.description ?? '').trim();
    if (local.isNotEmpty) return local;

    final remote = (_remoteDescription ?? '').trim();
    if (remote.isNotEmpty) return remote;

    return '';
  }

  _AssignmentInfo _getAssignmentInfo(int status, S s) {
    switch (status) {
      case 0:
        return _AssignmentInfo(
          icon: Icons.pending_outlined,
          color: Colors.amber,
          label: s.waitingForValidation,
        );
      case 1:
        return _AssignmentInfo(
          icon: Icons.hourglass_empty,
          color: Colors.grey,
          label: s.waitingAssignment,
        );
      case 2:
        return _AssignmentInfo(
          icon: Icons.person,
          color: Colors.green,
          label: s.assignedToCitizen,
        );
      case 3:
        return _AssignmentInfo(
          icon: Icons.build,
          color: Colors.orange,
          label: s.underRepair,
        );
      case 4:
        return _AssignmentInfo(
          icon: Icons.check_circle,
          color: Colors.green,
          label: s.done,
        );
      case 5:
        return _AssignmentInfo(
          icon: Icons.engineering,
          color: Colors.blue,
          label: s.assignedBlueCollar,
        );
      case 6:
        return _AssignmentInfo(
          icon: Icons.people_outline,
          color: Colors.teal,
          label: s.availableForCitizens,
        );
      case 7:
        return _AssignmentInfo(
          icon: Icons.hourglass_top,
          color: Colors.purple,
          label: s.waitingForConfirmation,
        );
      default:
        return _AssignmentInfo(
          icon: Icons.help_outline,
          color: Colors.grey,
          label: s.unknownStatus,
        );
    }
  }

  String _formatDistance(double? distance) {
    if (distance == null) return '';
    if (distance < 1000) return '${distance.toInt()} m';
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  void _showCategoryHelper(BuildContext context, Incident i, S s) {
    final label = CategoryTranslator.translate(i.category, s);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        contentPadding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        title: Row(
          children: [
            CategoryIcon(categoryIndex: i.category, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.category,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required when using AutomaticKeepAliveClientMixin
    final s = S.of(context);
    final i = widget.incident;
    final images = (i.imagesUrl ?? <String>[]);
    final hasImages = images.isNotEmpty;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(i, s),
              _buildImageGallery(images, hasImages),
              _buildActionBar(i, s),
              _buildMetaAndDescription(i, s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Incident i, S s) {
    final assignmentInfo = _getAssignmentInfo(i.status, s);
    final distanceStr = _formatDistance(widget.distance);
    final location = (i.location ?? '').trim();
    final quartier = (i.quartier ?? '').isEmpty ? 'Longueuil' : i.quartier!;

    // Affichage du bouton 3 points :
    // - visible pour les citoyens sauf si status == 5 (assigné à col bleu)
    // - visible pour col bleu si status dans [6, 2, 3, 5]
    final roleProv = context.read<RoleProvider>();
    final isCitizen = roleProv.role == UserRole.citizen;
    final isBlueCollar = roleProv.role == UserRole.blueCollar;
    final showMoreButton = (
      (isCitizen && [6, 2, 3].contains(i.status)) ||
      (isBlueCollar && [6, 2, 3, 5].contains(i.status))
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: assignmentInfo.color.withValues(alpha: 0.15),
            child: Icon(assignmentInfo.icon, size: 20, color: assignmentInfo.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignmentInfo.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: assignmentInfo.color,
                  ),
                ),
                Row(
                  children: [
                    // tappable location -> open in Google Maps
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        await _openInMaps(location);
                      },
                      child: Text(
                        location + ", " +quartier,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    if (distanceStr.isNotEmpty) ...[
                      Text(
                        '  ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                      Icon(Icons.near_me, size: 12, color: Colors.black.withValues(alpha: 0.5)),
                      const SizedBox(width: 2),
                      Text(
                        distanceStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (showMoreButton)
            IconButton(
              onPressed: () => _onMorePressed(i, s),
              icon: const Icon(Icons.more_horiz),
            ),
        ],
      ),
    );
  }

  Future<void> _onMorePressed(Incident i, S s) async {
    // load full details to know assigned user
    showModalBottomSheet(
      context: context,
      builder: (_) => const Center(child: SizedBox(height: 200)),
    );
    IncidentDetailsDTO? details;
    try {
      details = await getIncidentDetails(i.id);
    } catch (e) {
      Navigator.pop(context); // close placeholder sheet
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }
    Navigator.pop(context); // close placeholder

    final roleProv = context.read<RoleProvider>();
    final userId = roleProv.userId;
    final role = roleProv.role;

    final status = details.status; // int mapping as in backend
    final assignedToMe = details.citizenId != null && details.citizenId == userId;

    // Build list of actions
    final List<Widget> actions = [];

    // If waiting for assignation to citizen (6), citizens can take it
    if (status == 6 && role == UserRole.citizen) {
      actions.add(ListTile(
        leading: const Icon(Icons.how_to_reg),
        title: Text(s.assign),
        onTap: () async {
          Navigator.pop(context);
          final res = await getTakeTask(id: i.id);
          if (res == 'OK') {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.issueSubmitted)));
            if (widget.onRequestSubInfo != null) widget.onRequestSubInfo!();
            if (widget.onRefresh != null) widget.onRefresh!();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
          }
        },
      ));
    }

    // If assigned to me (citizen or blue collar) allow start -> under repair
    if ((status == 2 && role == UserRole.citizen && assignedToMe) || (status == 5 && role == UserRole.blueCollar && assignedToMe)) {
      actions.add(ListTile(
        leading: const Icon(Icons.build),
        title: Text(s.startTask),
        onTap: () async {
          Navigator.pop(context);
          final res = await changeStatusToUnderRepair(id: i.id);
          if (res == 'OK') {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.startTask)));
            if (widget.onRequestSubInfo != null) widget.onRequestSubInfo!();
            if (widget.onRefresh != null) widget.onRefresh!();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
          }
        },
      ));
    }

    // If under repair show confirm action
    if (status == 3) {
      actions.add(ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(s.terminateTask),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => ConfirmationIncidentPage(incidentId: i.id))).then((_) {
            if (widget.onRequestSubInfo != null) widget.onRequestSubInfo!();
            if (widget.onRefresh != null) widget.onRefresh!();
          });
        },
      ));
    }

    if (actions.isEmpty) {
      // nothing to do
      showModalBottomSheet(
        context: context,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(s.unknownStatus),
        ),
      );
      return;
    }

    // show actions
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Expanded(child: Text(s.more, style: const TextStyle(fontWeight: FontWeight.w700))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            ...actions,
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).then((_) {
      // Rafraîchit la page après action
      if (widget.onRequestSubInfo != null) widget.onRequestSubInfo!();
      if (widget.onRefresh != null) widget.onRefresh!();
    });
  }

  Widget _buildImageGallery(List<String> images, bool hasImages) {
    return GestureDetector(
      onTap: widget.onFocusIncident ?? (hasImages
          ? () => PhotoViewer.show(context, images, initialIndex: _page)
          : null),
      onDoubleTap: widget.onLike,
      child: AspectRatio(
        aspectRatio: 1,
        child: hasImages
            ? Stack(
           children: [
            PageView.builder(
              key: PageStorageKey('incident-gallery-${widget.incident.id}'),
              itemCount: images.length,
              onPageChanged: (p) => setState(() => _page = p),
              itemBuilder: (context, idx) {
                return RepaintBoundary(
                  child: CachedNetworkImage(
                    imageUrl: images[idx],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    useOldImageOnUrlChange: true,
                    placeholder: (ctx, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (ctx, url, e) => const Center(child: Icon(Icons.broken_image)),
                  ),
                );
              },
            ),
            Positioned(
              top: 10,
              right: 10,
              child: ImagePageBadge(
                currentPage: _page + 1,
                totalPages: images.length,
              ),
            ),
          ],
        )
            : Container(
          color: Colors.black.withValues(alpha: 0.05),
          alignment: Alignment.center,
          child: const Icon(Icons.image, size: 46),
        ),
      ),
    );
  }

  Widget _buildActionBar(Incident i, S s) {
    final info = widget.subInfo;
    final icon = info?.isSubscribed == true ? Icons.notifications : Icons.notifications_none_outlined;
    final color = info?.isMandatory == true
        ? Colors.red
        : (info?.isSubscribed == true ? Colors.blue : Colors.grey);

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 10, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onLike,
            icon: Icon(
              i.isLiked ? Icons.favorite : Icons.favorite_border,
              color: i.isLiked ? Colors.red : null,
            ),
          ),
          IconButton(
            onPressed: widget.onOpenComments,
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            onPressed: widget.onOpenDetails,
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(
            onPressed: () => _showCategoryHelper(context, i, s),
            icon: CategoryIcon(categoryIndex: i.category, size: 28),
            tooltip: s.category,
          ),


          const Spacer(),
          IconButton(
            onPressed: widget.subLoading || widget.subToggleInProgress || info?.isMandatory == true ? null : widget.onToggleSubscription,
            icon: widget.subLoading || widget.subToggleInProgress
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Icon(icon, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaAndDescription(Incident i, S s) {
    final created = TimeAgo.format(context, i.createdAt);
    final desc = _effectiveDescription();
    final baseColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),

          // Description (if any)
          if (desc.isNotEmpty) ...[
            Text(
              desc,
              maxLines: _descExpanded ? null : 2,
              overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.25,
                fontWeight: FontWeight.w500,
                color: baseColor.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 8),
            _buildMoreLessIfNeeded(desc, baseColor, s),
            const SizedBox(height: 8),
          ],

          // Time row (now placed under the description; if no description, it will be under the title)
          Row(
            children: [
              Expanded(
                child: Text(
                  created,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: baseColor.withValues(alpha: 0.55),
                  ),
                ),
              ),
              if (_loadingDescription)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoreLessIfNeeded(String desc, Color baseColor, S s) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: const TextSpan(
            text: '',
          ),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        );

        tp.text = TextSpan(
          text: desc,
          style: const TextStyle(
            fontSize: 14,
            height: 1.25,
            fontWeight: FontWeight.w500,
          ),
        );

        tp.layout(maxWidth: constraints.maxWidth);
        final hasOverflow = tp.didExceedMaxLines;

        if (!hasOverflow && !_descExpanded) return const SizedBox.shrink();

        return TextButton(
          onPressed: () => setState(() => _descExpanded = !_descExpanded),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _descExpanded ? s.less : s.more,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: baseColor.withValues(alpha: 0.55),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openInMaps(String address) async {
    if (address.trim().isEmpty) return;
    final encoded = Uri.encodeComponent(address);

    // We want to show the directions preview (with Start button), not start navigation directly.
    // Preferred app schemes (if installed) then fall back to web URL which also shows directions preview.

    final googleAppScheme = 'comgooglemaps://?daddr=$encoded&directionsmode=driving';
    final appleMapsScheme = 'maps://?daddr=$encoded&dirflg=d';
    final googleWeb = 'https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving';

    try {
      if (Platform.isIOS) {
        if (await canLaunchUrlString(appleMapsScheme)) {
          await launchUrlString(appleMapsScheme, mode: LaunchMode.externalApplication);
          return;
        }
        // Try Google Maps app on iOS if available
        if (await canLaunchUrlString(googleAppScheme)) {
          await launchUrlString(googleAppScheme, mode: LaunchMode.externalApplication);
          return;
        }
      } else {
        // Android or others: try Google Maps app scheme first
        if (await canLaunchUrlString(googleAppScheme)) {
          await launchUrlString(googleAppScheme, mode: LaunchMode.externalApplication);
          return;
        }
      }
    } catch (_) {
      // ignore and fall back to web
    }

    // Fallback to web URL (opens in browser or may be handled by Google Maps app as preview)
    if (await canLaunchUrlString(googleWeb)) {
      await launchUrlString(googleWeb, mode: LaunchMode.externalApplication);
    }
  }

  @override
  bool get wantKeepAlive => true;
}

class _AssignmentInfo {
  final IconData icon;
  final Color color;
  final String label;

  _AssignmentInfo({
    required this.icon,
    required this.color,
    required this.label,
  });
}