import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:municipalgo/generated/l10n.dart';
import 'package:municipalgo/pages/authentification.dart';
import 'package:municipalgo/pages/login.dart';
import 'package:municipalgo/pages/register.dart';
import 'package:municipalgo/http/lib_http.dart';
import 'package:municipalgo/main.dart';
import '../http/dtos/transfer.dart';
import '../services/roleProvider.dart';
import 'account.dart';

class _BadgeLevel {
  final int id;
  final String imageUrl;
  final int minPoints;
  final IconData fallbackIcon;
  final Color color;

  const _BadgeLevel({
    required this.id,
    required this.imageUrl,
    required this.minPoints,
    required this.fallbackIcon,
    required this.color,
  });
}

const _allLevels = [
  _BadgeLevel(
    id: 1,
    imageUrl:
    'https://cafigpmqhacybpynazsu.supabase.co/storage/v1/object/public/imageBucket/one.png',
    minPoints: 0,
    fallbackIcon: Icons.verified_user,
    color: Color(0xFF78909C),
  ),
  _BadgeLevel(
    id: 2,
    imageUrl:
    'https://cafigpmqhacybpynazsu.supabase.co/storage/v1/object/public/imageBucket/two.png',
    minPoints: 50,
    fallbackIcon: Icons.trending_up,
    color: Color(0xFF66BB6A),
  ),
  _BadgeLevel(
    id: 3,
    imageUrl:
    'https://cafigpmqhacybpynazsu.supabase.co/storage/v1/object/public/imageBucket/three.png',
    minPoints: 150,
    fallbackIcon: Icons.star,
    color: Color(0xFF42A5F5),
  ),
  _BadgeLevel(
    id: 4,
    imageUrl:
    'https://cafigpmqhacybpynazsu.supabase.co/storage/v1/object/public/imageBucket/four.png',
    minPoints: 300,
    fallbackIcon: Icons.shield,
    color: Color(0xFFAB47BC),
  ),
  _BadgeLevel(
    id: 5,
    imageUrl:
    'https://cafigpmqhacybpynazsu.supabase.co/storage/v1/object/public/imageBucket/five.png',
    minPoints: 600,
    fallbackIcon: Icons.emoji_events,
    color: Color(0xFFFFB300),
  ),
];

String _levelName(S s, int id) {
  switch (id) {
    case 1:
      return s.badgeLevelOfficialCitizen;
    case 2:
      return s.badgeLevelActiveCitizen;
    case 3:
      return s.badgeLevelEngagedCitizen;
    case 4:
      return s.badgeLevelLocalHero;
    case 5:
      return s.badgeLevelMunicipalLegend;
    default:
      return s.unknown;
  }
}

String _levelDesc(S s, int id) {
  switch (id) {
    case 1:
      return s.badgeLevelOfficialCitizenDesc;
    case 2:
      return s.badgeLevelActiveCitizenDesc;
    case 3:
      return s.badgeLevelEngagedCitizenDesc;
    case 4:
      return s.badgeLevelLocalHeroDesc;
    case 5:
      return s.badgeLevelMunicipalLegendDesc;
    default:
      return s.unknown;
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int nbClicks = 0;
  bool showSix = false;

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>();
    restoreAuthFromProvider(roleProvider);
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () {
            setState(() {
              nbClicks++;
              if (nbClicks == 6) showSix = true;
              if (nbClicks == 7) {
                showSix = false;
                nbClicks = 0;
              }
            });
          },
          child: Text(s.profile,
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      ),
      body: SafeArea(
        child: roleProvider.isLoggedIn
            ? _LoggedInView(s: s, roleProvider: roleProvider)
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          child: _LoggedOutView(s: s),
        ),
      ),
    );
  }
}

class _LoggedOutView extends StatelessWidget {
  final S s;
  const _LoggedOutView({required this.s});

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.profileWelcome,
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            s.loginToContinue,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const Connexion())),
                  child: Text(s.login),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const Inscription())),
                  child: Text(s.register),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoggedInView extends StatefulWidget {
  final S s;
  final RoleProvider roleProvider;
  const _LoggedInView({required this.s, required this.roleProvider});

  @override
  State<_LoggedInView> createState() => _LoggedInViewState();
}

class _LoggedInViewState extends State<_LoggedInView> {
  CitizenBadgeProfileDTO? _data;
  bool _loading = true;
  Object? _error;

  S get s => widget.s;
  RoleProvider get roleProvider => widget.roleProvider;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  bool get _isBlueCollar => roleProvider.role == UserRole.blueCollar;

  Future<void> _loadBadges() async {
    if (_isBlueCollar) {
      setState(() {
        _loading = false;
        _data = null;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await getMyBadges();
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _forceLogout(BuildContext context) {
    AuthStore.isLoggingOut = true;
    AuthStore.token = null;
    SingletonDio.getDio().options.headers.remove('Authorization');
    roleProvider.logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthentificationPage()),
          (route) => false,
    );
    AuthStore.isLoggingOut = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null && !_isBlueCollar) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _data == null) {
      if (_error is ApiException &&
          (_error as ApiException).code == 'UNAUTHORIZED') {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _forceLogout(context));
        return _LoggedOutView(s: s);
      }

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.errorGeneric(_error.toString())),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadBadges, child: Text(s.retry)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBadges,
      child: _ProfileContent(
        data: _data,
        s: s,
        roleProvider: roleProvider,
        onLogout: () => _forceLogout(context),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final CitizenBadgeProfileDTO? data;
  final S s;
  final RoleProvider roleProvider;
  final VoidCallback onLogout;

  const _ProfileContent({
    required this.data,
    required this.s,
    required this.roleProvider,
    required this.onLogout,
  });

  bool get _isCitizen => data != null;

  Set<int> get _earnedIds => data?.badges.map((b) => b.id).toSet() ?? {};

  int? get _nextLevelPoints {
    if (data == null) return null;
    for (final lvl in _allLevels) {
      if (lvl.minPoints > data!.points) return lvl.minPoints;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final earnedIds = _earnedIds;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      children: [
        _Section(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AccountPage())),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.black.withValues(alpha: 0.06),
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.account,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                        roleProvider.email ?? '—',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: baseColor.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: baseColor.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isCitizen) ...[
          _Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.badgeYourProgress,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                _StatsRow(items: [
                  _StatItem(label: s.pointsLabel, value: data!.points.toString()),
                  _StatItem(
                      label: s.badgesLabel,
                      value: data!.badges.length.toString()),
                  _StatItem(label: s.levelLabel, value: data!.currentLevelName),
                ]),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (data!.progressPercentage.clamp(0, 100)) / 100,
                    minHeight: 10,
                    backgroundColor: Colors.black.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF42A5F5)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _nextLevelPoints != null
                      ? s.nextLevelIn(
                      (_nextLevelPoints! - data!.points).toString())
                      : s.maxLevelReached,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: baseColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(s.badgeAllTitle,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900)),
          ),
          ...List.generate(_allLevels.length, (i) {
            final lvl = _allLevels[i];
            final isEarned = earnedIds.contains(lvl.id);
            return _BadgeTile(
              level: lvl,
              isEarned: isEarned,
              userPoints: data!.points,
              s: s,
            );
          }),
          const SizedBox(height: 16),
        ],
        _Section(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: Colors.red.shade400),
            title: Text(
              s.logout,
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: Colors.red.shade400),
            ),
            subtitle: Text(
              s.logoutSubtitle,
              style: TextStyle(
                color: baseColor.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: onLogout,
          ),
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final _BadgeLevel level;
  final bool isEarned;
  final int userPoints;
  final S s;

  const _BadgeTile({
    required this.level,
    required this.isEarned,
    required this.userPoints,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = isEarned ? 1.0 : 0.4;
    final name = _levelName(s, level.id);
    final desc = _levelDesc(s, level.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showBadgeDetail(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEarned
                    ? level.color.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.08),
                width: isEarned ? 1.5 : 1,
              ),
              color: isEarned ? level.color.withValues(alpha: 0.06) : null,
            ),
            child: Row(
              children: [
                Opacity(opacity: opacity, child: _BadgeAvatar(level: level, radius: 24)),
                const SizedBox(width: 14),
                Expanded(
                  child: Opacity(
                    opacity: opacity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(isEarned: isEarned, level: level, s: s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BadgeDetailSheet(
        level: level,
        isEarned: isEarned,
        userPoints: userPoints,
        s: s,
      ),
    );
  }
}

class _BadgeDetailSheet extends StatelessWidget {
  final _BadgeLevel level;
  final bool isEarned;
  final int userPoints;
  final S s;

  const _BadgeDetailSheet({
    required this.level,
    required this.isEarned,
    required this.userPoints,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (level.minPoints - userPoints).clamp(0, 999999);
    final name = _levelName(s, level.id);
    final desc = _levelDesc(s, level.id);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _BadgeAvatar(level: level, radius: 44),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.04),
              ),
              child: Text(
                s.badgeRequired(level.minPoints.toString()),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            if (isEarned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.green.withValues(alpha: 0.1),
                ),
                child: Text(
                  s.badgeEarned,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.green.shade700,
                  ),
                ),
              )
            else ...[
              if (remaining > 0)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: level.minPoints > 0
                            ? (userPoints / level.minPoints).clamp(0.0, 1.0)
                            : 0,
                        minHeight: 8,
                        backgroundColor: Colors.black.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation(level.color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.nextLevelIn(remaining.toString()),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.orange.withValues(alpha: 0.1),
                ),
                child: Text(
                  s.badgeLocked,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _BadgeAvatar extends StatelessWidget {
  final _BadgeLevel level;
  final double radius;
  const _BadgeAvatar({required this.level, required this.radius});

  @override
  Widget build(BuildContext context) {
    if (level.imageUrl.isNotEmpty && level.imageUrl.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: level.color.withValues(alpha: 0.12),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: level.imageUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Icon(level.fallbackIcon, size: radius, color: level.color),
            errorWidget: (_, __, ___) =>
                Icon(level.fallbackIcon, size: radius, color: level.color),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: level.color.withValues(alpha: 0.12),
      child: Icon(level.fallbackIcon, size: radius, color: level.color),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isEarned;
  final _BadgeLevel level;
  final S s;
  const _StatusChip({required this.isEarned, required this.level, required this.s});

  @override
  Widget build(BuildContext context) {
    if (isEarned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.green.withValues(alpha: 0.12),
        ),
        child: Text(
          '✓',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Colors.green.shade700,
          ),
        ),
      );
    }
    return Icon(Icons.lock_outline, size: 18, color: Colors.black.withValues(alpha: 0.25));
  }
}

class _Section extends StatelessWidget {
  final Widget child;
  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<_StatItem> items;
  const _StatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.03),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: items
            .map(
              (x) => Expanded(
            child: Column(
              children: [
                Text(x.value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  x.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        )
            .toList(),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
}