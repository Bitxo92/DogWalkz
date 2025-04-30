import 'package:dogwalkz/pages/notifications_page.dart';
import 'package:dogwalkz/pages/schedule_walk_page.dart';
import 'package:dogwalkz/repositories/dogs_repository.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../repositories/wallet_repository.dart';
import '../models/walk.dart';
import '../repositories/walk_repository.dart';
import 'walk_details_page.dart';
import '../services/notifications_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  final WalletRepository _walletRepository = WalletRepository();
  double _walletBalance = 0.0;
  bool _isLoadingBalance = true;
  final WalkRepository _walkRepository = WalkRepository();
  List<Walk> _upcomingWalks = [];
  bool _isLoadingWalks = true;
  int _unreadNotifications = 0;
  bool _isLoadingNotifications = true;

  /// Initializes the state of the widget.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWalletBalance();
    _loadUpcomingWalks();
    _loadUnreadNotifications();
  }

  /// Loads the user's wallet balance from the WalletRepository.
  /// Sets the loading state to false once the balance is loaded.
  Future<void> _loadWalletBalance() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final wallet = await _walletRepository.getWallet(user.id);
    setState(() {
      _walletBalance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
      _isLoadingBalance = false;
    });
  }

  /// Handles the Floating Action Button press event.
  /// Checks if the user has funds in their wallet and at least one dog listed.
  Future<void> _handleFabPressed() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoadingBalance = true);

    final wallet = await _walletRepository.getWallet(user.id);
    final balance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;

    final dogsRepo = DogsRepository();
    final dogs = await dogsRepo.getDogsByOwner(user.id);

    setState(() => _isLoadingBalance = false);

    String? message;
    if (balance <= 0 && dogs.isEmpty) {
      message = 'You need funds in your wallet and at least one dog listed.';
    } else if (balance <= 0) {
      message = 'You don\'t have any funds in your wallet.';
    } else if (dogs.isEmpty) {
      message = 'You haven\'t added any dogs yet.';
    }

    if (message != null) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text(
                'Hold on 🐶!!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 33),
              ),
              content: Text(message ?? ''),
              actions: [
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
      );
      return;
    }

    Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScheduleWalkPage()),
        )
        .then((_) {
          _loadWalletBalance();
        })
        .then((_) {
          _loadUpcomingWalks();
        });
  }

  /// Builds the UI of the HomePage.
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'Pet Lover';

    return Scaffold(
      backgroundColor: const Color(0xFFF5E9D9),
      appBar: AppBar(
        leading: Stack(
          children: [
            IconButton(
              icon: const Icon(Ionicons.notifications_outline),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );
                _loadUnreadNotifications();
              },
            ),
            if (_unreadNotifications > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$_unreadNotifications',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        centerTitle: true,
        title: Text(
          'DogWalkz 🐾',
          style: TextStyle(
            fontFamily: GoogleFonts.comicNeue().fontFamily,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Ionicons.log_out_outline),
            color: Colors.white,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.welcomeBack,
                            style: TextStyle(
                              fontSize: 24,
                              fontFamily: GoogleFonts.comicNeue().fontFamily,
                              color: Colors.brown.shade700,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                              fontFamily: GoogleFonts.comicNeue().fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Lottie.network(
                        'https://lottie.host/4410b37a-0f15-4bbc-be66-ab2a92a6fb2e/D5q35grkIb.json',
                        fit: BoxFit.contain,
                        animate: true,
                        repeat: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Ionicons.wallet_outline,
                        size: 40,
                        color: Colors.brown,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.walletBalance,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            '\$${_walletBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade700,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/wallet').then((_) {
                            _loadWalletBalance();
                          });
                        },
                        child: Text(
                          AppLocalizations.of(context)!.manageWallet,
                          style: TextStyle(color: Colors.brown),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                Text(
                  AppLocalizations.of(context)!.upcomingWalks,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child:
                      _isLoadingWalks
                          ? const Center(child: CircularProgressIndicator())
                          : _upcomingWalks.isEmpty
                          ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "No upcoming walks scheduled",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                          : Column(
                            children: [
                              for (
                                var i = 0;
                                i < _upcomingWalks.length && i < 2;
                                i++
                              )
                                Column(
                                  children: [
                                    if (i > 0) const Divider(),
                                    ListTile(
                                      leading: const Icon(
                                        Ionicons.paw_outline,
                                        color: Colors.brown,
                                      ),
                                      title: Text(
                                        '${_getWalkPeriod(_upcomingWalks[i].scheduledStart)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.brown.shade700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        _formatWalkDate(_upcomingWalks[i]),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Ionicons.chevron_forward_outline,
                                        color: Colors.brown.shade700,
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => WalkDetailsPage(
                                                  walk: _upcomingWalks[i],
                                                ),
                                          ),
                                        ).then((_) {
                                          _loadUpcomingWalks();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleFabPressed,
        backgroundColor: Colors.brown,
        child: const Icon(Ionicons.add_outline, color: Colors.white),
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Colors.brown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Ionicons.wallet_outline, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/wallet').then((_) {
                  _loadWalletBalance();
                });
              },
            ),
            IconButton(
              icon: const Icon(Ionicons.calendar_outline, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/walks'),
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: const Icon(Ionicons.paw_outline, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/dogs'),
            ),
            IconButton(
              icon: const Icon(Ionicons.person_outline, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles the app lifecycle state changes.
  /// If the app is resumed, it reloads the wallet balance.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWalletBalance();
    }
  }

  /// Disposes the widget and removes the observer.
  /// This is important to prevent memory leaks and ensure that the widget is cleaned up properly.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Loads the upcoming walks from the WalkRepository.
  /// Filters the walks to only include those that are upcoming or ongoing.
  Future<void> _loadUpcomingWalks() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final allWalks = await _walkRepository.getUserWalks(user.id);
      final now = DateTime.now();

      // Filter upcoming walks and sort by date
      final upcoming =
          allWalks
              .where(
                (walk) =>
                    walk.scheduledStart.isAfter(now) ||
                    (walk.scheduledStart.isBefore(now) &&
                        walk.scheduledEnd.isAfter(now)),
              )
              .toList()
            ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));

      setState(() {
        _upcomingWalks = upcoming;
        _isLoadingWalks = false;
      });
    } catch (e) {
      setState(() => _isLoadingWalks = false);
      debugPrintStack(
        label: 'Error loading upcoming walks',
        stackTrace: StackTrace.current,
      );
    }
  }

  /// Formats the date of a walk to a user-friendly string.
  /// If the walk is today or tomorrow, it shows "Today" or "Tomorrow" respectively.
  String _formatWalkDate(Walk walk) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final walkDate = DateTime(
      walk.scheduledStart.year,
      walk.scheduledStart.month,
      walk.scheduledStart.day,
    );

    if (walkDate == today) {
      return '${AppLocalizations.of(context)!.today}, ${_formatTime(walk.scheduledStart)}';
    } else if (walkDate == today.add(const Duration(days: 1))) {
      return '${AppLocalizations.of(context)!.tomorrow}, ${_formatTime(walk.scheduledStart)}';
    } else {
      return '${walk.scheduledStart.day}/${walk.scheduledStart.month}, ${_formatTime(walk.scheduledStart)}';
    }
  }

  /// Formats the time to a user-friendly string in 12-hour format.
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour =
        hour > 12
            ? hour - 12
            : hour == 0
            ? 12
            : hour;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Returns the appropriate walk period based on the time of day.
  /// It categorizes the time into morning, afternoon, or evening.
  String _getWalkPeriod(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) {
      return AppLocalizations.of(context)!.morningWalk;
    } else if (hour >= 12 && hour < 20) {
      return AppLocalizations.of(context)!.afternoonWalk;
    } else {
      return AppLocalizations.of(context)!.eveningWalk;
    }
  }

  /// Loads the unread notifications count from the NotificationService.
  Future<void> _loadUnreadNotifications() async {
    setState(() => _isLoadingNotifications = true);
    try {
      final count = await NotificationService().getUnreadCount();
      setState(() {
        _unreadNotifications = count;
        _isLoadingNotifications = false;
      });
    } catch (e) {
      setState(() => _isLoadingNotifications = false);
      debugPrint('Error loading notifications: $e');
    }
  }
}
