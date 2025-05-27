import 'dart:async';

import 'package:dogwalkz/models/walker.dart';
import 'package:dogwalkz/repositories/dogs_repository.dart';
import 'package:dogwalkz/repositories/walk_repository.dart';
import 'package:dogwalkz/repositories/wallet_repository.dart';
import 'package:dogwalkz/services/location_service.dart';
import 'package:dogwalkz/services/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import '../models/walk.dart';
import '../models/dog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class WalkDetailsPage extends StatelessWidget {
  final Walk walk;
  final _supabase = Supabase.instance.client;
  final DogsRepository _dogsRepository = DogsRepository();
  late final currentUser;
  late final currentUserId;
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _locationStreamSubscription;
  Position? _currentPosition;

  WalkDetailsPage({super.key, required this.walk}) {
    currentUser = _supabase.auth.currentUser;
    currentUserId = currentUser?.id;
  }

  /// Builds the main UI of the WalkDetailsPage.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF5E9D9),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.walkDetails,
          style: GoogleFonts.comicNeue(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.1,
                        ),
                      ),
                      // Contact Details Card
                      (walk.walker != null && walk.walkerId != currentUserId)
                          ? _buildWalkerCard(context)
                          : _buildCustomerCard(context),

                      const SizedBox(height: 16),
                      _buildStatusHeader(context),
                      const SizedBox(height: 2),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.5,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 4,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          _buildSectionBadge(
                            context,
                            icon: Ionicons.time_outline,
                            title: AppLocalizations.of(context)!.timePlace,
                            onTap: () => _showTimePlaceDialog(context),
                          ),
                          _buildSectionBadge(
                            context,
                            icon: Ionicons.paw_outline,
                            title: AppLocalizations.of(context)!.dogs,
                            onTap: () => _showDogsDialog(context),
                          ),
                          _buildSectionBadge(
                            context,
                            icon: Ionicons.wallet_outline,
                            title: AppLocalizations.of(context)!.billing,
                            onTap: () => _showBillingDialog(context),
                          ),
                          _buildSectionBadge(
                            context,
                            icon: Ionicons.help_circle_outline,
                            title: AppLocalizations.of(context)!.support,
                            onTap: () => _showSupportOptions(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (walk.walker != null) _buildActionButtons(context),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Builds a header with the current status of the walk.
  /// if the walk is in progress, it shows a Lottie animation.
  /// Tapping on the header will navigate to Google Maps using the coordinates sent from the walker.
  Widget _buildStatusHeader(BuildContext context) {
    final statusColor = _getStatusColor(walk.status);
    final isInProgress = walk.status == "in_progress";

    return GestureDetector(
      onTap: () {
        if (isInProgress) {
          _openWalkerLocationInMaps(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(_getStatusIcon(walk.status), color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.currentStatus,
                    style: GoogleFonts.comicNeue(color: Colors.grey.shade600),
                  ),
                  Text(
                    _getWalkStatusText(walk.status.toUpperCase(), context),
                    style: GoogleFonts.comicNeue(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            if (isInProgress)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Lottie.network(
                    'https://lottie.host/c0543e1b-dcd3-4f48-a530-612b51518b12/YNsMCAG9Iw.json',
                    fit: BoxFit.contain,
                    animate: true,
                    repeat: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a card with the scheduled date, time, and location of the walk.
  Widget _buildTimeLocationCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
              icon: Ionicons.calendar_outline,
              title: AppLocalizations.of(context)!.date,
              value: _formatDate(walk.scheduledStart),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Ionicons.time_outline,
              title: AppLocalizations.of(context)!.time,
              value:
                  '${_formatTime(walk.scheduledStart)} - ${_formatTime(walk.scheduledEnd)}',
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Ionicons.location_outline,
              title: AppLocalizations.of(context)!.location,
              value: walk.location.isNotEmpty ? walk.city : 'Not specified',
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a row with an icon, title, and value for the walk details.
  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.brown),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.comicNeue(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a card with walker details, including the walker's name,
  /// profile picture, and contact buttons (message and call).
  Widget _buildWalkerCard(BuildContext context) {
    final walker = walk.walker!;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundImage:
                    walker.profilePictureUrl != null
                        ? NetworkImage(walker.profilePictureUrl!)
                        : null,
                child:
                    walker.profilePictureUrl == null
                        ? const Icon(Ionicons.person_outline, size: 28)
                        : null,
              ),
              title: Text(
                walker.fullName,
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.walker,
                        style: GoogleFonts.comicNeue(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        final fullStar = index < walker.rating.floor();
                        final halfStar =
                            index == walker.rating.floor() &&
                            walker.rating % 1 >= 0.5;

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
                      const SizedBox(width: 6),
                      Text(
                        walker.rating.toStringAsFixed(1),
                        style: GoogleFonts.comicNeue(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildContactButtons(context),
          ],
        ),
      ),
    );
  }

  /// Builds a card with customer details, including the customer's name,
  /// profile picture, and contact buttons (message and call).
  Widget _buildCustomerCard(BuildContext context) {
    final customer = walk.customer!;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundImage:
                    customer.profilePictureUrl != null
                        ? NetworkImage(customer.profilePictureUrl!)
                        : null,
                child:
                    customer.profilePictureUrl == null
                        ? const Icon(Ionicons.person_outline, size: 28)
                        : null,
              ),
              title: Text(
                customer.fullName,
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(AppLocalizations.of(context)!.dogOwner),
            ),
            const SizedBox(height: 12),
            _buildCustomerContactButtons(context),
          ],
        ),
      ),
    );
  }

  /// Builds a row of two buttons for contacting the customer: a message button
  /// and a call button. The message button shows a dialog for sending a message
  /// to the customer, while the call button opens the dialer with the customer's
  /// phone number.
  Widget _buildCustomerContactButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Ionicons.chatbubble_outline, size: 20),
            label: Text(AppLocalizations.of(context)!.message),
            onPressed: () => _showCustomerContactDialog(context, true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: Colors.white,
              backgroundColor: Colors.brown,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Ionicons.call_outline, size: 20),
            label: Text(AppLocalizations.of(context)!.call),
            onPressed: () => _showCustomerContactDialog(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a row of two buttons for contacting the walker: a message button
  /// and a call button. The message button shows a dialog for sending a
  /// message to the walker, and the call button shows a dialog for making a
  /// phone call to the walker. The buttons are styled with a brown background
  /// and white foreground color, and have a padding of 12 vertical units.
  Widget _buildContactButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Ionicons.chatbubble_outline, size: 20),
            label: Text(AppLocalizations.of(context)!.message),
            onPressed: () => _showContactDialog(context, true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Ionicons.call_outline, size: 20),
            label: Text(AppLocalizations.of(context)!.call),
            onPressed: () => _showContactDialog(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a column of dog items in the walk details page.
  ///
  /// This method maps each dog in the [walk.dogs] list to a [_buildDogItem]
  /// widget and returns a [Column] widget with the mapped children.
  Widget _buildDogsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...walk.dogs.map((dog) => _buildDogItem(dog, context))],
    );
  }

  /// Builds a widget for a dog in the walk details page.
  Widget _buildDogItem(Dog dog, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            dog.photoUrl ?? 'https://placehold.co/100x100?text=Dog',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Ionicons.paw_outline),
          ),
        ),
        title: Text(
          dog.name,
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_dogsRepository.getLocalizedBreedName(dog.breed, context)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dog.isSociable)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Ionicons.people_outline, color: Colors.green),
              ),
            if (dog.isDangerousBreed)
              const Icon(Ionicons.warning_outline, color: Colors.orange),
          ],
        ),
      ),
    );
  }

  /// Makes a phone call to the given phone number using the
  /// [FlutterPhoneDirectCaller] package.
  ///
  /// The phone number should be in the format of a string, e.g. '1234567890'.
  //
  /// The function will return a [Future] that resolves when the call is finished.
  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    } catch (e) {
      throw 'Could not make phone call: $e';
    }
  }

  /// Launches the SMS app with the given phone number pre-filled.
  ///
  /// This allows the user to send an SMS to the given phone number.
  ///
  /// If the SMS app could not be launched, it throws an error.
  Future<void> _sendSMS(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch SMS app';
    }
  }

  /// Shows a dialog that allows the walker to contact the customer.
  ///
  /// If the walker's phone number is not available, it will show an
  /// [AlertDialog] saying that the contact information is unavailable.
  ///
  /// Otherwise, it will show an [AlertDialog] with a title asking if the
  /// user wants to contact the walker, and two buttons(Cancel and Confirm).
  /// Cancel Button will dismiss the dialog if pressed, while the Confirm
  /// button will launch the phone or SMS app to contact the walker.
  void _showContactDialog(BuildContext context, bool isChat) {
    final walkerPhone = walk.walker?.phone;

    if (walkerPhone == null || walkerPhone.isEmpty) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.contactUnavailable),
              content: Text(AppLocalizations.of(context)!.noWalkerContact),
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

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.contactPerson(
                walk.walker?.fullName ?? AppLocalizations.of(context)!.walker,
              ),
            ),

            content: Text(
              AppLocalizations.of(context)!.wouldYouLikeTo(
                isChat
                    ? AppLocalizations.of(context)!.message
                    : AppLocalizations.of(context)!.call,
                walk.walker?.fullName ?? AppLocalizations.of(context)!.walker,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    if (isChat) {
                      await _sendSMS(walkerPhone);
                    } else {
                      await _makePhoneCall(walkerPhone);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to launch: $e')),
                    );
                  }
                },
                child: Text(AppLocalizations.of(context)!.confirm),
              ),
            ],
          ),
    );
  }

  /// Builds a payment details card with the total payment, platform commission, and walker earnings.
  ///
  /// The card is displayed in the walk details page and contains the total payment, platform commission, and walker earnings.
  /// The total payment is the price of the walk.
  /// The platform commission is the commission the platform takes from the total payment.
  /// The walker earnings are the earnings the walker will receive after the platform commission is subtracted from the total payment.
  Widget _buildPaymentDetails(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPaymentRow(
              AppLocalizations.of(context)!.total,
              '\$${walk.price.toStringAsFixed(2)}',
            ),
            const Divider(),
            _buildPaymentRow(
              AppLocalizations.of(context)!.platformCommission,
              '-\$${walk.platformCommission.toStringAsFixed(2)}',
            ),
            const Divider(),
            _buildPaymentRow(
              AppLocalizations.of(context)!.walkerEarnings,
              '\$${walk.walkerEarnings.toStringAsFixed(2)}',
              isEarnings: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single row for the payment details card.
  Widget _buildPaymentRow(
    String label,
    String value, {
    bool isEarnings = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.comicNeue()),
          Text(
            value,
            style: GoogleFonts.comicNeue(
              color: isEarnings ? Colors.green : Colors.brown,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds action buttons for the walk details page based on the status of the walk
  /// and whether the current user is the walker or not.
  ///
  /// If the current user is not the walker, this function returns a [SizedBox.shrink]
  /// widget.
  ///
  /// If the walk status is 'requested', this function returns a row with two buttons:
  /// one for confirming the walk and one for declining the walk.
  ///
  /// If the walk status is 'accepted', this function returns a single button for
  /// cancelling the walk.
  ///
  /// The buttons are styled with a minimum size of 50px and a bold font style.
  Widget _buildActionButtons(BuildContext context) {
    final isWalker = currentUserId == walk.walkerId;
    final isRequested = walk.status.toLowerCase() == 'requested';
    final isAccepted = walk.status.toLowerCase() == 'accepted';
    final isInProgress = walk.status.toLowerCase() == 'in_progress';
    final isCompleted = walk.status.toLowerCase() == 'completed';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (isRequested && isWalker)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmWalk(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.confirm,
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _declineWalk(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.brown),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.decline,
                      style: GoogleFonts.comicNeue(
                        color: Colors.brown,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (isRequested && !(isWalker))
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _cancelWalk(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (isAccepted && isWalker)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startWalk(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.startWalk,
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _cancelWalk(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.brown),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: GoogleFonts.comicNeue(
                        color: Colors.brown,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (isAccepted && !(isWalker))
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _cancelWalk(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          if (isInProgress && !(isWalker))
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _finishWalk(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.finishWalk,
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (isCompleted)
            GestureDetector(
              onTap: () => _showReviewDetailsDialog(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.brown,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.rating,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < (walk.rating ?? 0)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.yellow[700],
                          size: 28,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Confirms a walk request and handles the associated payment operations
  /// asynchronously.
  //
  /// This method will update the walk record to 'accepted' status and
  /// send a notification to the customer that the walker has accepted the
  /// walk request.
  //
  /// This method is intended to be used when a walker accepts a walk request.

  Future<void> _confirmWalk(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CircularProgressIndicator(color: Colors.brown),
          ),
    );

    try {
      await _supabase
          .from('walks')
          .update({'status': 'accepted'})
          .eq('id', walk.id);

      await NotificationService.sendNotification(
        userId: walk.customerId,
        title: 'walkAccepted',
        message: 'walkAcceptedMessage',
        type: 'walk_accepted',
        relatedEntityType: 'walk',
        relatedEntityId: walk.id,
      );
    } catch (e) {
      debugPrint('Failed to confirm walk: $e');
    } finally {
      // Close loading dialog
      Navigator.pop(context, true);
      Navigator.popUntil(context, ModalRoute.withName('/home'));
    }
  }

  /// Declines a walk request and handles the associated payment operations
  /// asynchronously.
  //
  /// This method will refund the customer and delete the walk record.
  ///
  /// This method is intended to be used when a walker declines a walk request.
  ///
  Future<void> _declineWalk(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      bool wasCancelled = await _handleWalkCancellation(
        context: context,
        refundCustomer: true,
      );
      Navigator.pop(context, true);
      if (wasCancelled == true) {
        Navigator.pop(context, true);
        Navigator.popUntil(context, ModalRoute.withName('/home'));
      }
    } catch (e) {
      debugPrint('Failed to decline walk: $e');
    }
  }

  /// Cancels a walk and handles the associated payment operations
  /// asynchronously.
  Future<void> _cancelWalk(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CircularProgressIndicator(color: Colors.brown),
          ),
    );
    try {
      bool wasCancelled = await _handleWalkCancellation(
        context: context,
        refundCustomer: true,
        withdrawWalkerEarnings: true,
      );
      Navigator.pop(context, true);
      if (wasCancelled == true) {
        Navigator.pop(context, true);
        Navigator.popUntil(context, ModalRoute.withName('/home'));
      }
    } catch (e) {
      debugPrint('Failed to cancel walk: $e');
    }
  }

  /// Handles the cancellation of a walk.
  ///
  /// This method is responsible for processing the cancellation of a walk
  /// and performing the necessary financial transactions based on the
  /// parameters provided. It can refund the customer and/or withdraw
  /// the walker’s earnings.
  ///
  /// The method will also delete the walk record.
  ///
  Future<bool> _handleWalkCancellation({
    required BuildContext context,
    bool wasCancelled = false,
    bool refundCustomer = false,
    bool withdrawWalkerEarnings = false,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmCancel),
          content: Text(AppLocalizations.of(context)!.confirmCancelMessage),
          actions: <Widget>[
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.no,
                style: TextStyle(color: Colors.red.shade500),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.yesCancel),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    if (confirm == false) return wasCancelled = false;
    final walletRepo = WalletRepository();

    //Refund customer if needed
    if (refundCustomer) {
      final customerWallet = await walletRepo.getWallet(walk.customerId);
      if (customerWallet.isNotEmpty) {
        await walletRepo.addFunds(
          userId: walk.customerId,
          walletId: customerWallet['id'],
          isRefund: true,
          amount: walk.price,
          description: 'cancelationRefund',
        );
      }
    }

    NotificationService.sendNotification(
      userId: walk.customerId,
      title: 'walkCancelled',
      message: 'walkCancelledMessage',
      type: 'walk_cancelled',
      relatedEntityType: 'walk',
      relatedEntityId: walk.id,
    );

    //Delete the walk and related records
    await _supabase.from('walks').delete().eq('id', walk.id);
    await _supabase.from('walk_dogs').delete().eq('walk_id', walk.id);
    return (wasCancelled = true);
  }

  /// Formats the given DateTime object to a string in 'HH:mm' format.
  ///
  /// Pads the hour and minute with leading zeros if necessary.
  ///
  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  /// Returns an [IconData] based on the given walk status.
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Ionicons.checkmark_done_outline;
      case 'accepted':
        return Ionicons.checkmark_circle_outline;
      case 'in_progress':
        return Ionicons.walk_outline;
      case 'cancelled':
        return Ionicons.close_circle_outline;
      case 'requested':
        return Ionicons.time_outline;
      default:
        return Ionicons.help_circle_outline;
    }
  }

  /// Returns a [Color] based on the given walk status.
  /// The colors returned are as follows:
  /// - `completed`: [Colors.green]
  /// - `in_progress`: [Colors.blue]
  /// - `accepted`: [Colors.green]
  /// - `cancelled`: [Colors.red]
  /// - `requested`: [Colors.orange]
  /// - All other statuses: [Colors.grey]
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'requested':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Shows a dialog that allows the walker to contact the customer.
  ///
  /// If the customer's phone number is not available, it will show an
  /// [AlertDialog] saying that the contact information is unavailable.
  ///
  /// Otherwise, it will show an [AlertDialog] with a title asking if the
  /// user wants to contact the customer, and two buttons(Cancel and Confirm).
  /// Cancel Button will dismiss the dialog if pressed, while the Confirm
  /// button will launch the phone or SMS app to contact the customer.
  void _showCustomerContactDialog(BuildContext context, bool isChat) {
    final customerPhone = walk.customer?.phone;

    if (customerPhone == null || customerPhone.isEmpty) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.contactUnavailable),
              content: Text(AppLocalizations.of(context)!.noCustomerContact),
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

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.contactPerson(
                walk.customer?.fullName ??
                    AppLocalizations.of(context)!.customer,
              ),
            ),
            content: Text(
              AppLocalizations.of(context)!.wouldYouLikeTo(
                isChat
                    ? AppLocalizations.of(context)!.message
                    : AppLocalizations.of(context)!.call,
                AppLocalizations.of(context)!.customer,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    if (isChat) {
                      await _sendSMS(customerPhone);
                    } else {
                      await _makePhoneCall(customerPhone);
                    }
                  } catch (e) {
                    debugPrint('Failed to launch: $e');
                  }
                },
                child: Text(AppLocalizations.of(context)!.confirm),
              ),
            ],
          ),
    );
  }

  String _getWalkStatusText(String status, context) {
    switch (status) {
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

  Widget _buildSectionBadge(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        // Vibration feedback when the button is tapped
        //Vibration.vibrate(duration: 80, amplitude: 128);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        width: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.brown, size: 36),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.comicNeue(
                color: Colors.brown,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePlaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Ionicons.time_outline, color: Colors.brown),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.timePlace),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogDetailRow(
                  icon: Ionicons.calendar_outline,
                  title: AppLocalizations.of(context)!.date,
                  value: _formatDate(walk.scheduledStart),
                ),
                const SizedBox(height: 12),
                _buildDialogDetailRow(
                  icon: Ionicons.time_outline,
                  title: AppLocalizations.of(context)!.time,
                  value:
                      '${_formatTime(walk.scheduledStart)} - ${_formatTime(walk.scheduledEnd)}',
                ),
                const SizedBox(height: 12),
                _buildDialogDetailRow(
                  icon: Ionicons.location_outline,
                  title: AppLocalizations.of(context)!.location,
                  value: walk.city ?? 'not available',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
    );
  }

  Widget _buildDialogDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.brown, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.comicNeue(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.comicNeue(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Ionicons.paw_outline, color: Colors.brown),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.dogs),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    walk.dogs
                        .map((dog) => _buildDogDialogItem(dog, context))
                        .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
    );
  }

  Widget _buildDogDialogItem(Dog dog, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            dog.photoUrl ?? 'https://placehold.co/100x100?text=Dog',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Ionicons.paw_outline),
          ),
        ),
        title: Text(
          dog.name,
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_dogsRepository.getLocalizedBreedName(dog.breed, context)}',
            ),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dog.isSociable)
                  Row(
                    children: [
                      const Icon(
                        Ionicons.people_outline,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.sociable,
                        style: GoogleFonts.comicNeue(fontSize: 12),
                      ),
                    ],
                  ),
                if (dog.isDangerousBreed)
                  Row(
                    children: [
                      const Icon(
                        Ionicons.warning_outline,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.dangerous,
                        style: GoogleFonts.comicNeue(fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBillingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Ionicons.wallet_outline, color: Colors.brown),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.billing),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBillingRow(
                  AppLocalizations.of(context)!.total,
                  '\$${walk.price.toStringAsFixed(2)}',
                ),
                const Divider(),
                _buildBillingRow(
                  AppLocalizations.of(context)!.paymentStatus,
                  _getPaymentStatus(walk.paymentStatus, context),
                ),
                const Divider(),
                _buildBillingRow(
                  AppLocalizations.of(context)!.platformCommission,
                  '-\$${walk.platformCommission.toStringAsFixed(2)}',
                ),
                const Divider(),
                _buildBillingRow(
                  AppLocalizations.of(context)!.walkerEarnings,
                  '\$${walk.walkerEarnings.toStringAsFixed(2)}',
                  isEarnings: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
    );
  }

  Widget _buildBillingRow(
    String label,
    String value, {
    bool isEarnings = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.comicNeue()),
          Text(
            value,
            style: GoogleFonts.comicNeue(
              color: isEarnings ? Colors.green : Colors.brown,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Ionicons.help_circle_outline, color: Colors.brown),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.support),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.supportOptionsMessage),
                ListTile(
                  leading: Image.network(
                    'https://img.icons8.com/color/48/whatsapp--v1.png',
                    width: 24,
                    height: 24,
                  ),
                  title: const Text('WhatsApp'),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(Uri.parse('https://wa.me/+34603659696'));
                  },
                ),
                ListTile(
                  leading: Image.network(
                    'https://img.icons8.com/color/48/telegram-app--v1.png',
                    width: 24,
                    height: 24,
                  ),
                  title: const Text('Telegram'),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(Uri.parse('https://t.me/dogwalkzsupport'));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.email, color: Colors.redAccent),
                  title: const Text('Email'),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(Uri.parse('mailto:dogwalkzsupport@mail.com'));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.phone, color: Colors.green),
                  title: Text(AppLocalizations.of(context)!.callSupport),
                  onTap: () async {
                    Navigator.pop(context);
                    const number = '+34603659696';
                    await FlutterPhoneDirectCaller.callNumber(number);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
    );
  }

  String _getPaymentStatus(String? paymentStatus, context) {
    switch (paymentStatus) {
      case 'pending':
        return AppLocalizations.of(context)!.pending;
      case 'released':
        return AppLocalizations.of(context)!.released;
      case 'failed':
        return AppLocalizations.of(context)!.failed;
      default:
        return AppLocalizations.of(context)!.unknownStatus;
    }
  }

  Future<void> _startWalk(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CircularProgressIndicator(color: Colors.brown),
          ),
    );
    try {
      await _handleWalkStart();
      if (currentUserId == walk.walkerId) {
        _startLocationTracking();
      }
      Navigator.pop(context, true);
      NotificationService.sendNotification(
        userId: walk.customerId,
        title: 'walkStarted',
        message: 'walkStartedMessage',
        type: 'walk_started',
        relatedEntityType: 'walk',
        relatedEntityId: walk.id,
      );
    } catch (e) {
      debugPrint('Failed to start walk: $e');
    } finally {
      // Close loading dialog
      Navigator.pop(context, true);
      Navigator.popUntil(context, ModalRoute.withName('/home'));
    }
  }

  _handleWalkStart() async {
    await _supabase
        .from('walks')
        .update({
          'status': 'in_progress',
          'actual_start': DateTime.now().toIso8601String(),
        })
        .eq('id', walk.id);
  }

  Future<void> _finishWalk(BuildContext context) async {
    final reviewData = await _showReviewDialog(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CircularProgressIndicator(color: Colors.brown),
          ),
    );
    try {
      await _handleWalkFinish();

      // Insert review
      await _supabase.from('reviews').insert({
        'walk_id': walk.id,
        'reviewer_id': currentUser.id,
        'reviewed_id': walk.walker?.userId,
        'rating': reviewData?['rating'],
        'comment': reviewData?['comment'],
      });
      // Update walker's rating through a DB stored procedure
      await _supabase.rpc(
        'update_walker_after_review',
        params: {
          'p_walker_id': walk.walker?.userId,
          'p_new_rating': reviewData?['rating'],
        },
      );

      NotificationService.sendNotification(
        userId: walk.walker!.userId,
        title: 'walkCompleted',
        message: 'walkCompletedMessage',
        type: 'walk_completed',
        relatedEntityType: 'walk',
        relatedEntityId: walk.id,
      );
    } catch (e) {
      debugPrint('Failed to finish walk: $e');
    } finally {
      // Close loading dialog
      Navigator.pop(context, true);
      Navigator.popUntil(context, ModalRoute.withName('/home'));
    }
  }

  _handleWalkFinish() async {
    try {
      await _supabase
          .from('walks')
          .update({
            'status': 'completed',
            'actual_end': DateTime.now().toIso8601String(),
          })
          .eq('id', walk.id);
    } catch (e) {
      debugPrint('Failed to finish walk: $e');
    }

    try {
      await _supabase.rpc(
        'process_walker_payment',
        params: {
          'p_walker_id': walk.walker?.userId,
          'p_walk_id': walk.id,
          'p_amount': walk.walkerEarnings,
        },
      );
    } catch (e) {
      debugPrint('Failed to process walker payment: $e');
    }
  }

  Future<Map<String, dynamic>?> _showReviewDialog(BuildContext context) async {
    int rating = 0;
    final TextEditingController commentController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Rate Your Walk'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 20.0,
              ), // Custom padding to fix overflow issue
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.yellow[700],
                              size: 32,
                            ),
                            onPressed: () {
                              setState(() {
                                rating = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          labelText: 'Review',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (rating > 0) {
                      Navigator.pop(context, {
                        'rating': rating,
                        'comment': commentController.text.trim(),
                      });
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReviewDetailsDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      walk.customer?.profilePictureUrl != null
                          ? NetworkImage(walk.customer!.profilePictureUrl!)
                          : null,
                  child:
                      walk.customer?.profilePictureUrl == null
                          ? const Icon(Ionicons.person_outline)
                          : null,
                ),
                const SizedBox(width: 12),
                Text(
                  walk.customer?.fullName ??
                      AppLocalizations.of(context)!.customer,
                  style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < (walk.rating ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.yellow[700],
                      size: 24,
                    );
                  }),
                ),
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.reviewComment,
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      walk.reviewComment ??
                          AppLocalizations.of(context)!.noReviewTitle,
                      style: GoogleFonts.comicNeue(),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
    );
  }

  /// Start tracking the walker's location
  void _startLocationTracking() async {
    // Check if we're the walker
    if (currentUserId != walk.walkerId) return;

    // Check permissions
    final status = await Permission.location.request();
    if (!status.isGranted) {
      debugPrint('Location permission denied');
      return;
    }

    // Cancel any existing subscription
    _locationStreamSubscription?.cancel();

    // Start listening to location updates
    _locationStreamSubscription = LocationService.getLocationStream().listen(
      (position) async {
        _currentPosition = position;
        try {
          await WalkRepository().trackWalkerLocation(
            walkId: walk.id,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        } catch (e) {
          debugPrint('Failed to update location: $e');
        }
      },
      onError: (e) {
        debugPrint('Location stream error: $e');
      },
    );
  }

  /// Open Google Maps with walker's current location
  Future<void> _openWalkerLocationInMaps(BuildContext context) async {
    try {
      // First try to get the latest from our local cache
      if (_currentPosition != null) {
        final url =
            'https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
          return;
        }
      }

      // Fall back to database if local cache is empty
      final location = await WalkRepository().getWalkerLocation(walk.id);

      if (location == null ||
          location['latitude'] == null ||
          location['longitude'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Walker location not available yet')),
        );
        return;
      }

      final lat = location['latitude'];
      final lng = location['longitude'];
      final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open maps: $e')));
    }
  }
}
