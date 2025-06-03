import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/walk.dart';
import '../repositories/walk_repository.dart';
import 'walk_details_page.dart';

class WalksPage extends StatefulWidget {
  const WalksPage({super.key});

  @override
  State<WalksPage> createState() => _WalksPageState();
}

enum WalkType { morning, afternoon, evening }

class _WalksPageState extends State<WalksPage> {
  final WalkRepository _walkRepository = WalkRepository();
  final SupabaseClient _supabase = Supabase.instance.client;

  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<Walk> _walks = [];
  bool _isLoading = true;

  /// Initializes the state of the [WalksPage] widget.
  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadWalks();
  }

  /// Loads the walks for the current user from the repository.
  Future<void> _loadWalks() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final walks = await _walkRepository.getUserWalks(userId);
      setState(() {
        _walks = walks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(AppLocalizations.of(context)!.failedToLoadWalks(e.toString()));
    }
  }

  /// Filters the walks for a specific day.
  /// Returns a list of walks that match the given day.
  List<Walk> _getWalksForDay(DateTime day) {
    return _walks.where((walk) {
      final walkDate = DateTime(
        walk.scheduledStart.year,
        walk.scheduledStart.month,
        walk.scheduledStart.day,
      );
      return isSameDay(walkDate, day);
    }).toList();
  }

  /// Displays an error message in a dialog.
  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context)!.ok,
                  style: TextStyle(color: Colors.brown.shade700),
                ),
              ),
            ],
          ),
    );
  }

  /// Builds the widget tree for the [WalksPage].
  /// Returns a [Scaffold] widget with an app bar, a calendar, and a list of walks.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E9D9),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/Background.png', fit: BoxFit.cover),
          ),

          Container(
            height:
                Size.fromHeight(
                  MediaQuery.of(context).size.height * 0.25,
                ).height,
            child: AppBar(
              title: Text(
                AppLocalizations.of(context)!.myWalks,
                style: TextStyle(
                  fontFamily: GoogleFonts.comicNeue().fontFamily,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              foregroundColor: Colors.white,
              centerTitle: true,
              backgroundColor: Colors.brown,
            ),
          ),
          Card(
            color: Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.11,
            ),

            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(color: Colors.brown),
                    )
                    : Column(
                      children: [
                        _buildCalendar(),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.scheduledWalks,

                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.brown.shade500.withOpacity(0.8),
                            fontSize: 24,
                          ),
                        ),
                        Divider(
                          color: Colors.brown.shade500.withOpacity(0.8),
                          thickness: 2,
                        ),
                        const SizedBox(height: 2),
                        Expanded(child: _buildWalksList()),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  /// Builds the calendar widget using the [TableCalendar] package.
  /// Returns a [Card] widget containing the calendar.
  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          locale: Localizations.localeOf(context).toString(),
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getWalksForDay,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Colors.brown,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.brown.shade300,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Colors.brown.shade200,
              shape: BoxShape.circle,
            ),
            markersAutoAligned: false,
            markersAlignment: Alignment.bottomCenter,
            outsideDaysVisible: false,
            defaultTextStyle: TextStyle(
              fontFamily: GoogleFonts.comicNeue().fontFamily,
            ),
            weekendTextStyle: TextStyle(
              color: const Color.fromARGB(255, 235, 5, 5),
              fontFamily: GoogleFonts.comicNeue().fontFamily,
            ),
          ),

          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleTextStyle: TextStyle(
              fontFamily: GoogleFonts.comicNeue().fontFamily,
              color: Colors.brown,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            formatButtonTextStyle: TextStyle(
              fontFamily: GoogleFonts.comicNeue().fontFamily,
              color: Colors.brown,
            ),
            formatButtonDecoration: BoxDecoration(
              border: Border.all(color: Colors.brown),
              borderRadius: BorderRadius.circular(8),
            ),
            leftChevronIcon: Icon(Ionicons.chevron_back, color: Colors.brown),
            rightChevronIcon: Icon(
              Ionicons.chevron_forward,
              color: Colors.brown,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: Colors.brown,
              fontFamily: GoogleFonts.comicNeue().fontFamily,
            ),
            weekendStyle: TextStyle(
              color: Colors.brown.shade700,
              fontFamily: GoogleFonts.comicNeue().fontFamily,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                final isPast = date.isBefore(
                  DateTime.now().subtract(const Duration(hours: 24)),
                );

                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color:
                          isPast ? Colors.grey.shade400 : Colors.red.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        events.length.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: GoogleFonts.comicNeue().fontFamily,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  /// Returns a widget that displays the walk period information based on the start time.
  Widget getWalkPeriodInfo(DateTime startTime) {
    final hour = startTime.hour;

    if (hour >= 5 && hour < 12) {
      return Row(
        children: [
          Text(
            AppLocalizations.of(context)!.morningWalk,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
          ),
          SizedBox(width: 6),
          Icon(Ionicons.sunny_outline, color: Colors.orange, size: 20),
        ],
      );
    } else if (hour >= 12 && hour < 17) {
      return Row(
        children: [
          Text(
            AppLocalizations.of(context)!.afternoonWalk,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
          ),
          SizedBox(width: 6),
          Icon(Ionicons.partly_sunny_outline, color: Colors.amber, size: 20),
        ],
      );
    } else {
      return Row(
        children: [
          Text(
            AppLocalizations.of(context)!.eveningWalk,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
          ),
          SizedBox(width: 6),
          Icon(Ionicons.moon_outline, color: Colors.indigo, size: 20),
        ],
      );
    }
  }

  /// Builds the list of walks for the selected day.
  /// Returns a [ListView] widget containing the walks for the selected day.
  Widget _buildWalksList() {
    final dayWalks = _selectedDay != null ? _getWalksForDay(_selectedDay!) : [];

    if (dayWalks.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noWalksForDay,
          style: TextStyle(
            fontFamily: GoogleFonts.comicNeue().fontFamily,
            color: Colors.brown,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: dayWalks.length,
      itemBuilder: (context, index) {
        final walk = dayWalks[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Icon(Ionicons.paw, color: Colors.brown),
            title: getWalkPeriodInfo(walk.scheduledStart),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  _getWalkStatusText(walk.status, context),
                  style: TextStyle(
                    color: _getStatusColor(walk.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${walk.scheduledStart.hour.toString().padLeft(2, '0')}:${walk.scheduledStart.minute.toString().padLeft(2, '0')} - '
                  '${walk.scheduledEnd.hour.toString().padLeft(2, '0')}:${walk.scheduledEnd.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              Ionicons.chevron_forward_outline,
              color: Colors.brown,
            ),
            onTap: () => _navigateToWalkDetails(walk),
          ),
        );
      },
    );
  }

  String _getWalkStatusText(String status, context) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return AppLocalizations.of(context)!.completed;
      case 'IN_PROGRESS':
        return AppLocalizations.of(context)!.inProgress;
      case 'ACCEPTED':
        return AppLocalizations.of(context)!.accepted;
      case 'CANCELLED':
        return AppLocalizations.of(context)!.cancelled;
      case 'REQUESTED':
        return AppLocalizations.of(context)!.requested;
      default:
        return AppLocalizations.of(context)!.unknownStatus;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'accepted':
        return Colors.green;
      case 'scheduled':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  /// Navigates to the [WalkDetailsPage] for the selected walk.
  /// Takes a [Walk] object as a parameter.
  void _navigateToWalkDetails(Walk walk) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WalkDetailsPage(walk: walk)),
    );
  }
}
