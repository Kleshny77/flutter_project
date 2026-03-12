import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/app_design.dart';
import '../../profile/data/user_profile_repository.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../data/home_preferences.dart';
import '../data/pharmacy_repository.dart';
import '../data/reminder_completion_repository.dart';
import '../data/reminder_notification_service.dart';
import '../models/home_tab.dart';
import '../models/pharmacy_vitamin.dart';
import 'pharmacy_flow_screens.dart';
import 'schedule_tab.dart';
import 'stats_tab.dart';
import '../widgets/home_onboarding_overlay.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({
    super.key,
    required this.userId,
    required this.onSignOut,
    this.userEmail,
    PharmacyRepository? pharmacyRepository,
  }) : pharmacyRepository =
           pharmacyRepository ?? FirestorePharmacyRepository(userId: userId);

  final String userId;
  final String? userEmail;
  final Future<void> Function() onSignOut;
  final PharmacyRepository pharmacyRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScheduleTabState> _scheduleTabKey =
      GlobalKey<ScheduleTabState>();
  final GlobalKey<_PharmacyTabState> _pharmacyTabKey =
      GlobalKey<_PharmacyTabState>();
  final GlobalKey<StatsTabState> _statsTabKey = GlobalKey<StatsTabState>();
  final UserProfileRepository _profileRepository = UserProfileRepository();
  final ReminderNotificationService _notificationService =
      ReminderNotificationService.instance;
  final PostRegistrationOnboardingStorage _onboardingStorage =
      PostRegistrationOnboardingStorage();
  StreamSubscription<String>? _notificationOpenSubscription;
  HomeTab _selectedTab = HomeTab.pharmacy;
  UserProfile _profile = const UserProfile.empty();
  HomeOnboardingStep? _onboardingStep;
  late final ReminderCompletionRepository _completionRepository =
      ReminderCompletionRepository(userId: widget.userId);

  @override
  void initState() {
    super.initState();
    _notificationOpenSubscription = _notificationService.reminderOpenRequests
        .listen(_handleReminderOpenRequest);
    _bootstrap();
  }

  @override
  void dispose() {
    _notificationOpenSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomInset = 56.0 + math.max(12.0, safeBottom);

    return Scaffold(
      backgroundColor: Colors.white,
      body: ColoredBox(
        color: Colors.white,
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  _HomeTopHeader(
                    safeTop: safeTop,
                    onPlusTap: _showFamilyAccountDialog,
                    onProfileTap: _showProfileSheet,
                    avatarBytes: _profile.avatarBytes,
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTab.index,
                      children: [
                        ScheduleTab(
                          key: _scheduleTabKey,
                          repository: widget.pharmacyRepository,
                          completionRepository: _completionRepository,
                          onAdd: _openAddVitaminFlow,
                          bottomInset: bottomInset,
                          onRemindersChanged: _handleScheduleDataChanged,
                        ),
                        _PharmacyTab(
                          key: _pharmacyTabKey,
                          repository: widget.pharmacyRepository,
                          onAdd: () {
                            _openAddVitaminFlow();
                          },
                          onOpenVitamin: (vitamin) {
                            _openVitaminDetailsFlow(vitamin);
                          },
                          bottomInset: bottomInset,
                        ),
                        StatsTab(
                          key: _statsTabKey,
                          repository: widget.pharmacyRepository,
                          completionRepository: _completionRepository,
                          bottomInset: bottomInset,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomNavigationHost(
                selectedTab: _selectedTab,
                onSelect: (tab) {
                  if (_onboardingStep != null && tab != HomeTab.pharmacy) {
                    return;
                  }
                  if (tab == _selectedTab) {
                    return;
                  }
                  setState(() {
                    _selectedTab = tab;
                  });
                  if (tab == HomeTab.stats) {
                    _statsTabKey.currentState?.reload();
                  }
                },
              ),
            ),
            if (_onboardingStep != null)
              HomeOnboardingOverlay(
                step: _onboardingStep!,
                onClose: _dismissOnboarding,
                onNext: _goToNextOnboardingStep,
                onPrevious: _goToPreviousOnboardingStep,
              ),
          ],
        ),
      ),
    );
  }

  void _showFamilyAccountDialog() {
    _showInfoDialog(
      title: 'Упс...',
      message: 'Функция семейного аккаунта появится позже',
    );
  }

  Future<void> _openAddVitaminFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddVitaminScreen(
          repository: widget.pharmacyRepository,
          onFlowCompleted: _reloadHomeData,
          onTabRequested: _handleTabRequestedFromFlow,
        ),
      ),
    );
  }

  Future<void> _openVitaminDetailsFlow(PharmacyVitamin vitamin) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => VitaminDetailsScreen(
          repository: widget.pharmacyRepository,
          reminderId: vitamin.id,
          onFlowCompleted: _reloadHomeData,
          onTabRequested: _handleTabRequestedFromFlow,
        ),
      ),
    );
  }

  void _reloadHomeData() {
    _scheduleTabKey.currentState?.reload();
    _pharmacyTabKey.currentState?.reload();
    _statsTabKey.currentState?.reload();
    unawaited(_refreshReminderNotifications());
  }

  Future<void> _handleScheduleDataChanged() async {
    _statsTabKey.currentState?.reload();
    await _refreshReminderNotifications();
  }

  void _handleTabRequestedFromFlow(HomeTab tab) {
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedTab = tab;
    });
  }

  Future<void> _showProfileSheet() async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (context) => EditProfileScreen(
          userId: widget.userId,
          fallbackEmail: widget.userEmail,
          onSignOut: widget.onSignOut,
          repository: _profileRepository,
        ),
      ),
    );
    await _loadProfile();
  }

  void _showInfoDialog({required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.w700,
            color: Color(0xFF3B3B3B),
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Commissioner',
            fontSize: 15,
            color: Color(0xFF656565),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Ок',
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontWeight: FontWeight.w600,
                color: AppPalette.blueMain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bootstrap() async {
    await _profileRepository.upsertEmail(
      userId: widget.userId,
      email: widget.userEmail ?? '',
    );
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
    await _loadProfile();
    await _refreshReminderNotifications();
    await _loadOnboardingState();
    final pendingReminderId = _notificationService.consumePendingReminderId();
    if (pendingReminderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _handleReminderOpenRequest(pendingReminderId);
      });
    }
  }

  Future<void> _refreshReminderNotifications() async {
    try {
      final reminders = await widget.pharmacyRepository.fetchReminders();
      await _notificationService.rescheduleReminders(reminders);
    } catch (_) {
      // Не ломаем home-screen, если локальные уведомления не удалось перепланировать.
    }
  }

  void _handleReminderOpenRequest(String reminderId) {
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedTab = HomeTab.pharmacy;
    });
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => VitaminDetailsScreen(
          repository: widget.pharmacyRepository,
          reminderId: reminderId,
          onFlowCompleted: _reloadHomeData,
          onTabRequested: _handleTabRequestedFromFlow,
        ),
      ),
    );
  }

  Future<void> _loadProfile() async {
    final profile = await _profileRepository.loadProfile(
      userId: widget.userId,
      fallbackEmail: widget.userEmail,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _profile = profile;
    });
  }

  Future<void> _loadOnboardingState() async {
    final shouldPresent = await _onboardingStorage.shouldPresentOnboarding();
    if (!mounted || !shouldPresent) {
      return;
    }
    setState(() {
      _selectedTab = HomeTab.pharmacy;
      _onboardingStep = HomeOnboardingStep.schedule;
    });
  }

  Future<void> _dismissOnboarding() async {
    await _onboardingStorage.markCompleted();
    if (!mounted) {
      return;
    }
    setState(() {
      _onboardingStep = null;
    });
  }

  void _goToNextOnboardingStep() {
    final next = _onboardingStep?.next;
    if (next == null) {
      _dismissOnboarding();
      return;
    }
    setState(() {
      _selectedTab = HomeTab.pharmacy;
      _onboardingStep = next;
    });
  }

  void _goToPreviousOnboardingStep() {
    final previous = _onboardingStep?.previous;
    if (previous == null) {
      return;
    }
    setState(() {
      _selectedTab = HomeTab.pharmacy;
      _onboardingStep = previous;
    });
  }
}

class _BottomNavigationHost extends StatelessWidget {
  const _BottomNavigationHost({
    required this.selectedTab,
    required this.onSelect,
  });

  final HomeTab selectedTab;
  final ValueChanged<HomeTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: math.max(12, safeBottom)),
      child: Center(
        heightFactor: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            return _HomeTabBar(
              selectedTab: selectedTab,
              maxWidth: maxWidth,
              onSelect: onSelect,
            );
          },
        ),
      ),
    );
  }
}

class _HomeTopHeader extends StatelessWidget {
  const _HomeTopHeader({
    required this.safeTop,
    required this.onPlusTap,
    required this.onProfileTap,
    this.avatarBytes,
  });

  final double safeTop;
  final VoidCallback onPlusTap;
  final VoidCallback onProfileTap;
  final Uint8List? avatarBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: safeTop + 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7087FF).withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(top: safeTop + 10, right: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProfileCircleButton(
                onTap: onProfileTap,
                avatarBytes: avatarBytes,
              ),
              const SizedBox(width: 12),
              _SmallPlusCircleButton(onTap: onPlusTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCircleButton extends StatelessWidget {
  const _ProfileCircleButton({this.onTap, this.avatarBytes});

  final VoidCallback? onTap;
  final Uint8List? avatarBytes;

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    final borderRadius = BorderRadius.circular(size / 2);
    final imageSize = math.max(0.0, size - 2);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              const Color.fromRGBO(231, 240, 255, 0.52),
              const Color(0xFF88A4FF),
              const Color.fromRGBO(180, 210, 255, 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7087FF).withValues(alpha: 0.25),
              blurRadius: 30.1,
              offset: const Offset(0, -14),
            ),
          ],
        ),
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: avatarBytes == null
              ? Image.asset(
                  'assets/images/home/profile.png',
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                )
              : Image.memory(
                  avatarBytes!,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }
}

class _SmallPlusCircleButton extends StatelessWidget {
  const _SmallPlusCircleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/images/home/plus.svg',
          width: 18,
          height: 18,
        ),
      ),
    );
  }
}

class _HomeTabBar extends StatelessWidget {
  const _HomeTabBar({
    required this.selectedTab,
    required this.maxWidth,
    required this.onSelect,
  });

  final HomeTab selectedTab;
  final double maxWidth;
  final ValueChanged<HomeTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final barWidth = math.min(363.0, math.max(280.0, maxWidth - 30));
    final highlightWidth = barWidth >= 363
        ? 118.0
        : math.min(118.0, (barWidth / 3) - 4);

    return Container(
      width: barWidth,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              alignment: _alignmentFor(selectedTab),
              child: Container(
                width: highlightWidth,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(7, 115, 241, 0.33),
                      Color.fromRGBO(31, 182, 237, 0.14),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: HomeTab.values.map((tab) {
              final isSelected = tab == selectedTab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(tab),
                  behavior: HitTestBehavior.opaque,
                  child: _TabBarItem(tab: tab, isSelected: isSelected),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Alignment _alignmentFor(HomeTab tab) {
    switch (tab) {
      case HomeTab.schedule:
        return Alignment.centerLeft;
      case HomeTab.pharmacy:
        return Alignment.center;
      case HomeTab.stats:
        return Alignment.centerRight;
    }
  }
}

class _TabBarItem extends StatelessWidget {
  const _TabBarItem({required this.tab, required this.isSelected});

  final HomeTab tab;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 29,
          child: Center(
            child: Transform.translate(
              offset: Offset(0, tab == HomeTab.pharmacy ? -3 : 0),
              child: Opacity(
                opacity: isSelected ? 1 : 0.65,
                child: Image.asset(
                  tab.assetPath,
                  height: tab == HomeTab.pharmacy ? 29 : 27,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 15,
          child: Center(
            child: Text(
              tab.title,
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppPalette.blueMain.withValues(
                  alpha: isSelected ? 1 : 0.65,
                ),
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _PharmacyStatus { loading, loaded, failed }

class _PharmacyTab extends StatefulWidget {
  const _PharmacyTab({
    super.key,
    required this.repository,
    required this.onAdd,
    required this.onOpenVitamin,
    required this.bottomInset,
  });

  final PharmacyRepository repository;
  final VoidCallback onAdd;
  final ValueChanged<PharmacyVitamin> onOpenVitamin;
  final double bottomInset;

  @override
  State<_PharmacyTab> createState() => _PharmacyTabState();
}

class _PharmacyTabState extends State<_PharmacyTab> {
  _PharmacyStatus _status = _PharmacyStatus.loading;
  List<PharmacyVitamin> _vitamins = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void reload() {
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = _PharmacyStatus.loading;
    });

    try {
      final vitamins = await widget.repository.fetchVitamins();
      if (!mounted) {
        return;
      }
      setState(() {
        _vitamins = vitamins;
        _status = _PharmacyStatus.loaded;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = _PharmacyStatus.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = math.max(0.0, constraints.maxWidth - 48);
        final floatingButtonBottom = MediaQuery.paddingOf(context).bottom + 72;

        return Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 32, 24, widget.bottomInset + 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Аптечка',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B3B3B),
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildContent(availableWidth),
                ],
              ),
            ),
            Positioned(
              right: 30,
              bottom: floatingButtonBottom,
              child: _FloatingPlusButton(onTap: widget.onAdd),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(double availableWidth) {
    switch (_status) {
      case _PharmacyStatus.loading:
        return const SizedBox(
          height: 280,
          child: Center(
            child: CircularProgressIndicator(color: AppPalette.blueMain),
          ),
        );
      case _PharmacyStatus.failed:
        return SizedBox(
          height: 280,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Не удалось загрузить витамины',
                  style: TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF656565),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _load,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    backgroundColor: AppPalette.blueMain.withValues(
                      alpha: 0.12,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Повторить',
                    style: TextStyle(
                      fontFamily: 'Commissioner',
                      fontWeight: FontWeight.w600,
                      color: AppPalette.blueMain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case _PharmacyStatus.loaded:
        if (_vitamins.isEmpty) {
          return _EmptyPharmacyView(onAdd: widget.onAdd);
        }
        return _VitaminsGridView(
          vitamins: _vitamins,
          availableWidth: availableWidth,
          onSelect: widget.onOpenVitamin,
        );
    }
  }
}

class _EmptyPharmacyView extends StatelessWidget {
  const _EmptyPharmacyView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/home/aptechka.png',
          height: 220,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        _LargeAddVitaminButton(onTap: onAdd),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Добавьте свои витамины, чтобы  получать напоминания, отслеживать запасы, просматривать свой прогресс и многое другое',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 16,
              color: Color(0xFF656565),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _LargeAddVitaminButton extends StatelessWidget {
  const _LargeAddVitaminButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _GradientBorderContainer(
        width: 188,
        height: 58,
        radius: 26,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.4806, 0.8770),
            end: Alignment(-0.4806, -0.8770),
            colors: [Color(0xFFD6FEC2), Color(0xFF6F95FC), Color(0xFF0773F1)],
            stops: [0.0, 0.4319, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        borders: const [
          _GradientBorderLayer(
            width: 2,
            gradient: LinearGradient(
              begin: Alignment(-0.8632, -0.5034),
              end: Alignment(0.8632, 0.5034),
              colors: [
                Color.fromRGBO(231, 240, 255, 0.523483),
                Color(0xFF88A4FF),
                Color.fromRGBO(180, 210, 255, 0.1),
              ],
              stops: [0.2276, 0.4951, 0.8712],
            ),
          ),
          _GradientBorderLayer(
            width: 2,
            gradient: RadialGradient(
              center: Alignment(-0.7012, 0.9346),
              radius: 0.62,
              colors: [Colors.white, Color.fromRGBO(255, 255, 255, 0)],
            ),
          ),
        ],
        child: const Center(
          child: Text(
            'Добавить витамин',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _VitaminsGridView extends StatelessWidget {
  const _VitaminsGridView({
    required this.vitamins,
    required this.availableWidth,
    required this.onSelect,
  });

  final List<PharmacyVitamin> vitamins;
  final double availableWidth;
  final ValueChanged<PharmacyVitamin> onSelect;

  @override
  Widget build(BuildContext context) {
    const itemSize = 137.0;
    final spacing = math.max(0.0, (availableWidth - (itemSize * 2)) / 3);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: vitamins.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final vitamin = vitamins[index];
        return Center(
          child: GestureDetector(
            onTap: () => onSelect(vitamin),
            child: _VitaminCard(title: vitamin.title),
          ),
        );
      },
    );
  }
}

class _VitaminCard extends StatelessWidget {
  const _VitaminCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return _GradientBorderContainer(
      width: 137,
      height: 137,
      radius: 15,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      borders: const [
        _GradientBorderLayer(
          width: 4,
          gradient: LinearGradient(
            begin: Alignment(-0.8632, -0.5034),
            end: Alignment(0.8632, 0.5034),
            colors: [
              Color.fromRGBO(231, 240, 255, 0.523483),
              Color(0xFF88A4FF),
              Color.fromRGBO(180, 210, 255, 0.1),
            ],
            stops: [0.2276, 0.4951, 0.8712],
          ),
        ),
        _GradientBorderLayer(
          width: 4,
          gradient: RadialGradient(
            center: Alignment(-0.7012, 0.9346),
            radius: 1.32,
            colors: [Colors.white, Color.fromRGBO(255, 255, 255, 0)],
          ),
        ),
      ],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 18.69,
              fontWeight: FontWeight.w700,
              color: Color(0xFF737373),
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingPlusButton extends StatelessWidget {
  const _FloatingPlusButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.16),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/images/home/plus.svg',
          width: 22,
          height: 22,
        ),
      ),
    );
  }
}

class _GradientBorderContainer extends StatelessWidget {
  const _GradientBorderContainer({
    required this.width,
    required this.height,
    required this.radius,
    required this.decoration,
    required this.borders,
    required this.child,
  });

  final double width;
  final double height;
  final double radius;
  final BoxDecoration decoration;
  final List<_GradientBorderLayer> borders;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _GradientBorderPainter(radius: radius, borders: borders),
        child: DecoratedBox(
          decoration: decoration.copyWith(
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GradientBorderLayer {
  const _GradientBorderLayer({required this.width, required this.gradient});

  final double width;
  final Gradient gradient;
}

class _GradientBorderPainter extends CustomPainter {
  const _GradientBorderPainter({required this.radius, required this.borders});

  final double radius;
  final List<_GradientBorderLayer> borders;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    for (final border in borders) {
      final rRect = RRect.fromRectAndRadius(
        rect.deflate(border.width / 2),
        Radius.circular(math.max(0, radius - (border.width / 2))),
      );

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = border.width
        ..shader = border.gradient.createShader(rect);

      canvas.drawRRect(rRect, paint);
    }
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.borders != borders;
  }
}
