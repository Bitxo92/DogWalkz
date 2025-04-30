import 'package:dogwalkz/repositories/wallet_repository.dart';
import 'package:dogwalkz/services/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/walk.dart';
import '../models/dog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WalkDetailsPage extends StatelessWidget {
  final Walk walk;
  final _supabase = Supabase.instance.client;
  late final currentUser;
  late final currentUserId;

  WalkDetailsPage({super.key, required this.walk}) {
    currentUser = _supabase.auth.currentUser;
    currentUserId = currentUser?.id;
  }

  /// Builds the main UI of the WalkDetailsPage.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.contactDetails,
                        style: GoogleFonts.comicNeue(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    (walk.walker != null && walk.walkerId != currentUserId)
                        ? _buildWalkerCard(context)
                        : // Show walker card if current user is the customer
                        _buildCustomerCard(
                          context,
                        ), // Show customer card if current user is the walker

                    const SizedBox(height: 16),
                    _buildStatusHeader(context),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.timePlace,
                        style: GoogleFonts.comicNeue(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTimeLocationCard(context),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.dogs,
                        style: GoogleFonts.comicNeue(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDogsSection(),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.billing,
                        style: GoogleFonts.comicNeue(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentDetails(context),
                  ],
                ),
              ),
            ),
            if (walk.walker != null) _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Builds a header with the current status of the walk.
  Widget _buildStatusHeader(BuildContext context) {
    final statusColor = _getStatusColor(walk.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(walk.status), color: statusColor, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.currentStatus,
                style: GoogleFonts.comicNeue(color: Colors.grey.shade600),
              ),
              Text(
                walk.status.toUpperCase(),
                style: GoogleFonts.comicNeue(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
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
              value: walk.location.isNotEmpty ? walk.location : 'Not specified',
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
      elevation: 2,
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
      elevation: 2,
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
  Widget _buildDogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...walk.dogs.map((dog) => _buildDogItem(dog))],
    );
  }

  /// Builds a widget for a dog in the walk details page.
  Widget _buildDogItem(Dog dog) {
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
        subtitle: Text('${dog.breed} • ${dog.size}'),
        trailing:
            dog.isDangerousBreed
                ? const Icon(Ionicons.warning_outline, color: Colors.orange)
                : null,
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

    if (!isWalker) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (isRequested)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmWalk(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.confirm,
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
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
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.decline,
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (isAccepted)
            ElevatedButton(
              onPressed: () => _cancelWalk(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                AppLocalizations.of(context)!.cancelWalk,
                style: GoogleFonts.comicNeue(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
    try {
      await _supabase
          .from('walks')
          .update({'status': 'accepted'})
          .eq('id', walk.id);

      await NotificationService.sendNotification(
        userId: walk.customerId,
        title: AppLocalizations.of(context)!.walkAcceptedTitle,
        message: AppLocalizations.of(context)!.walkAcceptedMessage(walk.id),
        type: 'walk_accepted',
        relatedEntityType: 'walk',
        relatedEntityId: walk.id,
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Failed to confirm walk: $e');
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
    try {
      await _handleWalkCancellation(refundCustomer: true);
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Failed to decline walk: $e');
    }
  }

  /// Cancels a walk and handles the associated payment operations
  /// asynchronously.
  Future<void> _cancelWalk(BuildContext context) async {
    try {
      await _handleWalkCancellation(
        refundCustomer: true,
        withdrawWalkerEarnings: true,
      );
      Navigator.pop(context, true);
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
  Future<void> _handleWalkCancellation({
    bool refundCustomer = false,
    bool withdrawWalkerEarnings = false,
  }) async {
    final walletRepo = WalletRepository();

    //Refund customer if needed
    if (refundCustomer && walk.customerId != null) {
      final customerWallet = await walletRepo.getWallet(walk.customerId!);
      if (customerWallet.isNotEmpty) {
        await walletRepo.addFunds(
          userId: walk.customerId!,
          walletId: customerWallet['id'],
          amount: walk.price,
          description: 'Refund for cancelation ${walk.id}',
        );
      }
    }

    //Withdraw walker earnings if needed
    if (withdrawWalkerEarnings && walk.walkerId != null) {
      final walkerWallet = await walletRepo.getWallet(walk.walkerId!);
      if (walkerWallet.isNotEmpty) {
        await walletRepo.withdrawFunds(
          userId: walk.walkerId!,
          walletId: walkerWallet['id'],
          amount: walk.walkerEarnings,
          description: 'Customer Refund due to cancelation ${walk.id}',
        );
      }
    }

    //Delete the walk and related records
    await _supabase.from('walks').delete().eq('id', walk.id);
    await _supabase.from('walk_dogs').delete().eq('walk_id', walk.id);
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
}
