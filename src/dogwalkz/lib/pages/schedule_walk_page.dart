import 'package:dogwalkz/repositories/dogs_repository.dart';
import 'package:dogwalkz/services/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/dog.dart';
import '../models/walker.dart';
import '../repositories/walk_repository.dart';
import 'walker_selection_page.dart';

class ScheduleWalkPage extends StatefulWidget {
  const ScheduleWalkPage({super.key});

  @override
  State<ScheduleWalkPage> createState() => _ScheduleWalkPageState();
}

class _ScheduleWalkPageState extends State<ScheduleWalkPage> {
  final WalkRepository _walkRepository = WalkRepository();
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _dogsRepository = DogsRepository();
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  Walker? _selectedWalker;
  List<Dog> _userDogs = [];
  List<bool> _selectedDogs = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  double _walletBalance = 0.0;
  double _totalPrice = 0.0;
  bool _isCityEmpty = true;
  double _pricePerDog = 0.0;
  double _platformCommission = 0.0;
  double _walkerEarnings = 0.0;
  List<Walker> _availableWalkers = [];
  bool _isLoadingWalkers = false;

  int _currentStep = 0;
  final List<StepItem> _steps = [
    StepItem(Ionicons.location_outline, ""),
    StepItem(Ionicons.time_outline, ""),
    StepItem(Ionicons.paw_outline, ""),
    StepItem(Ionicons.person_outline, ""),
    StepItem(Ionicons.checkmark_done_outline, ""),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    final now = DateTime.now();
    _startDateTime ??= DateTime(now.year, now.month, now.day);
  }

  Future<void> _loadInitialData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final dogs = await _walkRepository.getUserDogs(userId);
      final balance = await _walkRepository.getWalletBalance(userId);
      setState(() {
        _userDogs = dogs;
        _selectedDogs = List<bool>.filled(dogs.length, false);
        _walletBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load data: $e');
    }
  }

  Future<void> _selectStartDateTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.brown,
              onPrimary: Colors.white,
              onSurface: Colors.brown,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.brown),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.brown,
                onPrimary: Colors.white,
                onSurface: Colors.brown,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: Colors.brown),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (time == null) return;

    setState(() {
      _startDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
      _calculatePrice();
    });
  }

  Future<void> _selectEndDateTime() async {
    if (_startDateTime == null) {
      _showError(AppLocalizations.of(context)!.selectStartTimeMessage);
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDateTime!,
      firstDate: _startDateTime!,
      lastDate: _startDateTime!.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.brown,
              onPrimary: Colors.white,
              onSurface: Colors.brown,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.brown),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDateTime!),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.brown,
                onPrimary: Colors.white,
                onSurface: Colors.brown,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: Colors.brown),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (time == null) return;

    final endDateTime = DateTime(
      picked.year,
      picked.month,
      picked.day,
      time.hour,
      time.minute,
    );

    if (endDateTime.isBefore(_startDateTime!)) {
      _showError(AppLocalizations.of(context)!.endTimeBeforeStartTime);
      return;
    }

    setState(() {
      _endDateTime = endDateTime;
      _calculatePrice();
    });
  }

  void _calculatePrice() {
    if (_startDateTime == null || _endDateTime == null) return;
    if (_selectedDogs.every((selected) => !selected)) return;

    final durationInHours =
        _endDateTime!.difference(_startDateTime!).inMinutes / 60;
    final selectedDogsCount =
        _selectedDogs.where((selected) => selected).length;
    double baseRate = _selectedWalker?.baseRatePerHour ?? 15.0;
    double total = baseRate * durationInHours * selectedDogsCount;

    //if (_hasLargeDogs()) total *= 1.2;
    //if (_hasDangerousBreeds()) total *= 1.3;

    final platformCommission = total * WalkRepository.platformCommissionRate;
    final walkerEarnings = total - platformCommission;

    setState(() {
      _totalPrice = total;
      _platformCommission = platformCommission;
      _walkerEarnings = walkerEarnings;
      _pricePerDog = baseRate * durationInHours;
    });
  }

  bool _hasLargeDogs() => _userDogs.asMap().entries.any(
    (entry) => _selectedDogs[entry.key] && entry.value.size == 'large',
  );

  bool _hasDangerousBreeds() => _userDogs.asMap().entries.any(
    (entry) => _selectedDogs[entry.key] && entry.value.isDangerousBreed,
  );

  Future<void> _loadAvailableWalkers() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (_cityController.text.isEmpty) {
      _showError(AppLocalizations.of(context)!.enterLocation);
      return;
    }
    if (_selectedDogs.every((selected) => !selected)) {
      _showError(AppLocalizations.of(context)!.selectDogsMessage);
      return;
    }
    if (_startDateTime == null || _endDateTime == null) {
      _showError(AppLocalizations.of(context)!.selectTimeMessage);
      return;
    }

    setState(() => _isLoadingWalkers = true);
    try {
      final walkers = await _walkRepository.getAvailableWalkers(
        city: _cityController.text,
        startTime: _startDateTime!,
        endTime: _endDateTime!,
        needsLargeDogWalker: _hasLargeDogs(),
        needsDangerousBreedCertification: _hasDangerousBreeds(),
        excludeUserId: currentUser?.id,
      );

      setState(() {
        _availableWalkers = walkers;
        _isLoadingWalkers = false;
      });
    } catch (e) {
      setState(() => _isLoadingWalkers = false);
      _showError('Failed to load walkers: $e');
    }
  }

  Future<void> _submitWalkRequest() async {
    if (!_formKey.currentState!.validate())
      return;
    else if (_cityController.text.isEmpty) {
      _showError(AppLocalizations.of(context)!.enterLocation);
      return;
    } else if (_selectedDogs.every((selected) => !selected)) {
      _showError(AppLocalizations.of(context)!.selectDogsMessage);
      return;
    } else if (_startDateTime == null || _endDateTime == null) {
      _showError(AppLocalizations.of(context)!.selectTimeMessage);
      return;
    } else if (_walletBalance < _totalPrice) {
      _showError(AppLocalizations.of(context)!.insufficientFunds);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final dogIds =
          _userDogs
              .asMap()
              .entries
              .where((entry) => _selectedDogs[entry.key])
              .map((entry) => entry.value.id)
              .toList();

      final walkID = await _walkRepository.scheduleWalk(
        customerId: userId,
        walkerId: _selectedWalker?.userId,
        scheduledStart: _startDateTime!,
        scheduledEnd: _endDateTime!,
        totalPrice: _totalPrice,
        dogIds: dogIds,
        location: _locationController.text,
        city: _cityController.text,
      );

      if (_selectedWalker != null) {
        await NotificationService.sendWalkScheduledNotification(
          walkerId: _selectedWalker!.userId,
          walkId: walkID,
        );
      }

      _showSuccess(AppLocalizations.of(context)!.walkscheduled);
    } catch (e) {
      _showError('Failed to schedule walk: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.error),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
    );
  }

  void _showSuccess(String message) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.success),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst),
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.scheduleWalk,
          style: TextStyle(
            fontFamily: GoogleFonts.comicNeue().fontFamily,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.brown),
              )
              : Column(
                children: [
                  _buildStepperHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: NeverScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Form(key: _formKey, child: _buildStepContent()),
                    ),
                  ),
                  _buildNavigationControls(),
                ],
              ),
    );
  }

  Widget _buildStepperHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 20,
                  right: 20,
                  top: 30,
                  child: Container(height: 2, color: Colors.grey.shade300),
                ),

                Positioned(
                  left: 20,
                  right: 20,
                  top: 15,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final progress = (_currentStep / (_steps.length - 1))
                          .clamp(0.0, 1.0);
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: constraints.maxWidth * progress,
                          height: 2,
                          color: Colors.brown,
                        ),
                      );
                    },
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      _steps.asMap().entries.map((entry) {
                        final index = entry.key;
                        final step = entry.value;
                        final isActive = index == _currentStep;
                        final isCompleted = index < _currentStep;

                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                isActive
                                    ? Colors.brown
                                    : isCompleted
                                    ? Colors.brown.shade300
                                    : Colors.grey.shade300,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Icon(
                            step.icon,
                            color:
                                isActive || isCompleted
                                    ? Colors.white
                                    : Colors.brown.shade300,
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                _steps.map((step) {
                  return SizedBox(
                    width: 40,
                    child: Text(
                      step.title,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildLocationStep();
      case 1:
        return _buildTimeStep();
      case 2:
        return _buildDogsStep();
      case 3:
        return _buildWalkerStep();
      case 4:
      default:
        return _buildConfirmationStep();
    }
  }

  Widget _buildLocationStep() {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.meet,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _cityController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.city,
            prefixIcon: const Icon(
              Ionicons.location_outline,
              color: Colors.brown,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.brown),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.brown, width: 2),
            ),
          ),
          validator:
              (value) =>
                  value?.isEmpty ?? true
                      ? AppLocalizations.of(context)!.required
                      : null,
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.helpUs,
          style: TextStyle(
            color: Colors.brown.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
        Container(
          padding: EdgeInsets.all(10),
          child: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              //Attribution:https://www.vecteezy.com/free-png/pet-ownerPet Owner PNGs by Vecteezy
              child: Image.asset('assets/dogwalker.png', fit: BoxFit.contain),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppLocalizations.of(context)!.walkTime,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Swipeable-animated calendar
        SizedBox(
          height: 300,
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              setState(() {
                if (details.primaryVelocity != null) {
                  final currentDate = _startDateTime ?? DateTime.now();

                  if (details.primaryVelocity! < 0) {
                    var nextMonth = currentDate.month + 1;
                    var nextYear = currentDate.year;
                    if (nextMonth > 12) {
                      nextMonth = 1;
                      nextYear++;
                    }
                    final lastDayOfNextMonth =
                        DateTime(nextYear, nextMonth + 1, 0).day;
                    final newDay =
                        currentDate.day <= lastDayOfNextMonth
                            ? currentDate.day
                            : lastDayOfNextMonth;
                    _startDateTime = DateTime(
                      nextYear,
                      nextMonth,
                      newDay,
                      currentDate.hour,
                      currentDate.minute,
                    );
                  } else if (details.primaryVelocity! > 0) {
                    var prevMonth = currentDate.month - 1;
                    var prevYear = currentDate.year;
                    if (prevMonth < 1) {
                      prevMonth = 12;
                      prevYear--;
                    }
                    final lastDayOfPrevMonth =
                        DateTime(prevYear, prevMonth + 1, 0).day;
                    final newDay =
                        currentDate.day <= lastDayOfPrevMonth
                            ? currentDate.day
                            : lastDayOfPrevMonth;
                    _startDateTime = DateTime(
                      prevYear,
                      prevMonth,
                      newDay,
                      currentDate.hour,
                      currentDate.minute,
                    );
                  }

                  _endDateTime = null;
                  _calculatePrice();
                }
              });
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              child: Column(
                key: ValueKey<String>(
                  DateFormat(
                    'yyyy-MM',
                  ).format(_startDateTime ?? DateTime.now()),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.brown,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat(
                          'MMMM',
                          AppLocalizations.of(context)!.localeName,
                        ).format(_startDateTime ?? DateTime.now()),

                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Weekday-headers
                  Row(
                    children:
                        ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                            .map(
                              (day) => Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: const TextStyle(
                                      color: Colors.brown,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Days-grid
                  Flexible(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1.2,
                          ),
                      itemCount:
                          _getDaysInMonthDisplay(
                            _startDateTime ?? DateTime.now(),
                          ).length,
                      itemBuilder: (context, index) {
                        final day =
                            _getDaysInMonthDisplay(
                              _startDateTime ?? DateTime.now(),
                            )[index];
                        final isSelected = isSameDay(
                          day,
                          _startDateTime ?? DateTime.now(),
                        );
                        final isToday = isSameDay(day, DateTime.now());

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _startDateTime = DateTime(
                                day.year,
                                day.month,
                                day.day,
                                _startDateTime?.hour ?? 0,
                                _startDateTime?.minute ?? 0,
                              );
                              _endDateTime = null;
                              _calculatePrice();
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Colors.brown
                                      : isToday
                                      ? Colors.brown.shade100
                                      : null,
                              shape: BoxShape.circle,
                              border:
                                  isToday && !isSelected
                                      ? Border.all(color: Colors.brown)
                                      : null,
                            ),
                            child: Center(
                              child: Text(
                                day.day.toString(),
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.brown,
                                  fontWeight:
                                      isSelected || isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Time period selection
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: List.generate(17, (index) {
              final startHour = 6 + index;
              final endHour = startHour + 1;
              final start = TimeOfDay(hour: startHour, minute: 0);
              final end = TimeOfDay(hour: endHour, minute: 0);
              final period =
                  '${start.format(context)} - ${end.format(context)}';

              final isSelected =
                  _startDateTime != null &&
                  _endDateTime != null &&
                  _startDateTime!.hour == startHour &&
                  _endDateTime!.hour == endHour;

              return GestureDetector(
                onTap: () {
                  if (_startDateTime == null) return;

                  setState(() {
                    _startDateTime = DateTime(
                      _startDateTime!.year,
                      _startDateTime!.month,
                      _startDateTime!.day,
                      startHour,
                      0,
                    );
                    _endDateTime = DateTime(
                      _startDateTime!.year,
                      _startDateTime!.month,
                      _startDateTime!.day,
                      endHour,
                      0,
                    );
                    _calculatePrice();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.brown : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.brown,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      period,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.brown,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  List<DateTime> _getDaysInMonthDisplay(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    final firstWeekday = firstDayOfMonth.weekday % 7;

    final lastWeekday = lastDayOfMonth.weekday % 7;

    final days = <DateTime>[];

    for (var i = 0; i < firstWeekday; i++) {
      days.add(firstDayOfMonth.subtract(Duration(days: firstWeekday - i)));
    }

    for (var i = 0; i < daysInMonth; i++) {
      days.add(DateTime(date.year, date.month, i + 1));
    }

    for (var i = lastWeekday; i < 6; i++) {
      days.add(lastDayOfMonth.add(Duration(days: i - lastWeekday + 1)));
    }

    return days;
  }

  Widget _buildDateTimePicker({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            const Icon(Ionicons.calendar_outline, color: Colors.brown),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            const Icon(Ionicons.chevron_forward, color: Colors.brown),
          ],
        ),
      ),
    );
  }

  Widget _buildDogsStep() {
    if (_userDogs.isEmpty) {
      return Center(
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.join,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.brown,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.noDogsAccount,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/dogs');

                      final userId =
                          Supabase.instance.client.auth.currentUser?.id;
                      if (userId != null) {
                        final dogs = await _walkRepository.getUserDogs(userId);
                        setState(() {
                          _userDogs = dogs;
                          _selectedDogs = List.generate(
                            dogs.length,
                            (_) => false,
                          );
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.brown,
                      padding: EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.addFurryFriend,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.join,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _userDogs.length,
          itemBuilder: (context, index) {
            final dog = _userDogs[index];
            final isSelected = _selectedDogs[index];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDogs[index] = !isSelected;
                  _calculatePrice();
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.brown,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          dog.photoUrl != null
                              ? Image.network(
                                dog.photoUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.brown.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Ionicons.paw_outline,
                                  size: 40,
                                  color: Colors.brown,
                                ),
                              ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dog.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _dogsRepository.getLocalizedBreedName(
                              dog.breed,
                              context,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWalkerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            AppLocalizations.of(context)!.match,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.brown,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 33),

        if (_isLoadingWalkers)
          const Center(child: CircularProgressIndicator(color: Colors.brown)),

        if (!_isLoadingWalkers && _availableWalkers.isEmpty)
          Center(
            child: Text(
              AppLocalizations.of(context)!.noWalkersAvailable,
              style: TextStyle(color: Colors.brown),
            ),
          ),

        if (!_isLoadingWalkers && _availableWalkers.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availableWalkers.length,
            itemBuilder: (context, index) {
              final walker = _availableWalkers[index];
              final isSelected = _selectedWalker?.userId == walker.userId;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedWalker = isSelected ? null : walker;
                    _calculatePrice();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.brown,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            walker.profilePictureUrl != null
                                ? NetworkImage(walker.profilePictureUrl!)
                                : null,
                        child:
                            walker.profilePictureUrl == null
                                ? const Icon(Ionicons.person_outline, size: 30)
                                : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              walker.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: List.generate(5, (starIndex) {
                                return Icon(
                                  starIndex < walker.rating.floor()
                                      ? Ionicons.star
                                      : starIndex == walker.rating.floor() &&
                                          walker.rating % 1 >= 0.5
                                      ? Ionicons.star_half
                                      : Ionicons.star_outline,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                            if (walker.experienceYears != null)
                              Text('${walker.experienceYears} years'),
                            Text(
                              '\$${walker.baseRatePerHour.toStringAsFixed(2)}/hr',
                              style: TextStyle(
                                color: Colors.brown.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.almost,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.brown,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        if (_totalPrice > 0)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      AppLocalizations.of(context)!.paymentDetails,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.totalPrice),
                      Text(
                        '\$${_totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.pricePerDog),
                      Text(
                        '\$${_pricePerDog.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.platformCommission),
                      Text(
                        '\$${_platformCommission.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.walkerEarnings),
                      Text(
                        '\$${_walkerEarnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          "${AppLocalizations.of(context)!.balance} \$${_walletBalance.toStringAsFixed(2)}",
          style: TextStyle(
            color: _walletBalance >= _totalPrice ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep--);
                  _handleStepChange();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.brown),
                  foregroundColor: Colors.brown,
                ),
                child: Text(
                  AppLocalizations.of(context)!.back,
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        _currentStep == _steps.length - 1
                            ? AppLocalizations.of(context)!.submit
                            : AppLocalizations.of(context)!.next,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStepChange() {
    if (_currentStep == 3) {
      _loadAvailableWalkers();
    }
  }

  Future<void> _handleNextStep() async {
    if (_currentStep == _steps.length - 1) {
      _submitWalkRequest();
    } else {
      if (await _validateCurrentStep()) {
        setState(() => _currentStep++);
        _handleStepChange();
      }
    }
  }

  Future<bool> _validateCurrentStep() async {
    final localizations = AppLocalizations.of(context)!;
    switch (_currentStep) {
      case 0:
        if (_cityController.text.isEmpty) {
          _showError(localizations.enterCity);
          return false;
        }
        final exists = await _walkRepository.checkWalkersExistInCity(
          _cityController.text.trim(),
        );
        if (!exists) {
          _showError(localizations.noWalkersInCity);
          return false;
        }
        return true;
      case 1:
        if (_startDateTime == null || _endDateTime == null) {
          _showError(localizations.selectStartEnd);
          return false;
        }
        return true;
      case 2:
        if (_selectedDogs.every((selected) => !selected)) {
          _showError(localizations.selectOneDog);
          return false;
        }
        return true;
      case 3:
        if (_selectedWalker == null) {
          _showError(localizations.selectWalker);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}

class StepItem {
  final IconData icon;
  final String title;

  StepItem(this.icon, this.title);
}
