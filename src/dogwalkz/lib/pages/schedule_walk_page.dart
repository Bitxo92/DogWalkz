import 'package:dogwalkz/models/walk.dart';
import 'package:dogwalkz/services/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Loads initial data such as user dogs and wallet balance.
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

  /// Selects the start date and time for the walk.
  /// Displays a date picker and a time picker to the user.
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

  /// Selects the end date and time for the walk.
  /// Displays a date picker and a time picker to the user.
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

  /// Calculates the total price of the walk.
  /// Takes into account the number of dogs, their sizes, and the selected walker.
  /// Updates the state with the calculated values.
  void _calculatePrice() {
    if (_startDateTime == null || _endDateTime == null) return;
    if (_selectedDogs.every((selected) => !selected)) return;

    final durationInHours =
        _endDateTime!.difference(_startDateTime!).inMinutes / 60;
    final selectedDogsCount =
        _selectedDogs.where((selected) => selected).length;
    double baseRate = _selectedWalker?.baseRatePerHour ?? 15.0;
    double total = baseRate * durationInHours * selectedDogsCount;

    if (_hasLargeDogs()) total *= 1.2;
    if (_hasDangerousBreeds()) total *= 1.3;

    final platformCommission = total * WalkRepository.platformCommissionRate;

    final walkerEarnings = total - platformCommission;

    setState(() {
      _totalPrice = total;
      _platformCommission = platformCommission;
      _walkerEarnings = walkerEarnings;
      _pricePerDog = baseRate * durationInHours;
    });
  }

  /// Checks if any of the selected dogs are large.
  bool _hasLargeDogs() => _userDogs.asMap().entries.any(
    (entry) => _selectedDogs[entry.key] && entry.value.size == 'large',
  );

  /// Checks if any of the selected dogs are of a dangerous breed.
  bool _hasDangerousBreeds() => _userDogs.asMap().entries.any(
    (entry) => _selectedDogs[entry.key] && entry.value.isDangerousBreed,
  );

  /// Selects a walker for the scheduled walk.
  /// Displays a list of available walkers based on the selected criteria.
  Future<void> _selectWalker() async {
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

    try {
      final walkers = await _walkRepository.getAvailableWalkers(
        city: _cityController.text,
        startTime: _startDateTime!,
        endTime: _endDateTime!,
        needsLargeDogWalker: _hasLargeDogs(),
        needsDangerousBreedCertification: _hasDangerousBreeds(),
      );

      if (walkers.isEmpty) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.noWalkersAvailable),
                content: Text(
                  AppLocalizations.of(context)!.noWalkersAvailableMessage,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => WalkerSelectionPage(
                walkers: walkers,

                onWalkerSelected: (walker) {
                  setState(() {
                    _selectedWalker = walker;
                    _calculatePrice();
                  });
                },
              ),
        ),
      );
    } catch (e) {
      _showError('Failed to load walkers: $e');
    }
  }

  /// Submits the walk request to the server.
  /// Validates the input fields and checks if the user has sufficient funds.
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

      await _walkRepository.scheduleWalk(
        customerId: userId,
        walkerId: _selectedWalker?.userId,
        scheduledStart: _startDateTime!,
        scheduledEnd: _endDateTime!,
        totalPrice: _totalPrice,
        dogIds: dogIds,
        location: _locationController.text,
        city: _cityController.text,
      );

      final walkId = await _walkRepository.scheduleWalk(
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
          walkId: walkId,
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
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  /// Builds a card widget for displaying walker information.
  /// Displays the walker's name, rating, and profile picture.
  Widget _buildWalkerCard(Walker walker) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              walker.profilePictureUrl != null
                  ? NetworkImage(walker.profilePictureUrl!)
                  : null,
          child:
              walker.profilePictureUrl == null
                  ? const Icon(Ionicons.person_outline)
                  : null,
        ),
        title: Text(
          walker.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(5, (index) {
              final fullStar = index < walker.rating.floor();
              final halfStar =
                  index == walker.rating.floor() && walker.rating % 1 >= 0.5;

              return Icon(
                fullStar
                    ? Ionicons.star
                    : halfStar
                    ? Ionicons.star_half
                    : Ionicons.star_outline,
                size: 16,
                color: Colors.amber,
              );
            }),
          ],
        ),
        trailing: const Icon(Ionicons.checkmark_circle, color: Colors.green),
        onTap: () {},
      ),
    );
  }

  /// Displays a success message after scheduling a walk.
  /// Shows a dialog with the success message and an OK button to return to the main screen.
  void _showSuccess(String message) {
    if (mounted) {
      showDialog(
        context: context,
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
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  /// Builds the main UI of the Schedule Walk page.
  @override
  Widget build(BuildContext context) {
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
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.selectTimeAndLocation,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.enterCity,
                          //hintText: 'Location',
                          labelStyle: TextStyle(
                            color: Colors.brown,
                            fontWeight: FontWeight.w600,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: Colors.brown,
                            fontWeight: FontWeight.w600,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.brown,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.brown,
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Ionicons.location_outline,
                            color: Colors.brown,
                          ),
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? AppLocalizations.of(context)!.required
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: _selectStartDateTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.brown, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Ionicons.time_outline,
                                color: Colors.brown,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _startDateTime == null
                                      ? AppLocalizations.of(context)!.startTime
                                      : '${AppLocalizations.of(context)!.start} ${_startDateTime!.toLocal().toString().substring(0, 16)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                                ),
                              ),
                              const Icon(
                                Ionicons.chevron_forward,
                                color: Colors.brown,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      GestureDetector(
                        onTap: _selectEndDateTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.brown, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Ionicons.time_outline,
                                color: Colors.brown,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _endDateTime == null
                                      ? AppLocalizations.of(context)!.endTime
                                      : '${AppLocalizations.of(context)!.end} ${_endDateTime!.toLocal().toString().substring(0, 16)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.brown,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(
                                Ionicons.chevron_forward,
                                color: Colors.brown,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Dogs
                      Text(
                        AppLocalizations.of(context)!.selectDogs,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                                  color:
                                      isSelected ? Colors.green : Colors.brown,
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
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dog.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text('${dog.breed}'),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      Text(
                        AppLocalizations.of(context)!.selectWalker,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _selectedWalker == null
                          ? Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.brown, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Ionicons.person_outline,
                                color: Colors.brown,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.selectWalker,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                              trailing: const Icon(
                                Ionicons.chevron_forward,
                                color: Colors.brown,
                              ),
                              onTap: _selectWalker,
                            ),
                          )
                          : Column(
                            children: [_buildWalkerCard(_selectedWalker!)],
                          ),
                      const SizedBox(height: 16),

                      // Price
                      if (_totalPrice > 0)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.paymentDetails,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Total Price
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.totalPrice,
                                    ),
                                    Text(
                                      '\$${_totalPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.pricePerDog,
                                    ),
                                    Text(
                                      '\$${_pricePerDog.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.platformCommission,
                                    ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.walkerEarnings,
                                    ),
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

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitWalkRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:
                              _isSubmitting
                                  ? const CircularProgressIndicator()
                                  : Text(
                                    AppLocalizations.of(context)!.scheduleWalk,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily:
                                          GoogleFonts.comicNeue().fontFamily,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  /// Disposes of the controllers used in the form.
  /// Cleans up resources and prevents memory leaks.
  @override
  void dispose() {
    _locationController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}
