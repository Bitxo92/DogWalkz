import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import '../models/walker.dart';

class WalkerSelectionPage extends StatefulWidget {
  final List<Walker> walkers;
  final Function(Walker) onWalkerSelected;

  const WalkerSelectionPage({
    super.key,
    required this.walkers,
    required this.onWalkerSelected,
  });

  @override
  State<WalkerSelectionPage> createState() => _WalkerSelectionPageState();
}

class _WalkerSelectionPageState extends State<WalkerSelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Select Walker',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: GoogleFonts.comicNeue().fontFamily,
          ),
        ),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.walkers.length,
              itemBuilder: (context, index) {
                final walker = widget.walkers[index];
                return _buildWalkerCard(walker);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// This method builds a card for each walker in the list.
  Widget _buildWalkerCard(Walker walker) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        title: Text(walker.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rating: ${walker.rating.toStringAsFixed(1)} ⭐ (${walker.totalWalks} walks)',
            ),
            if (walker.experienceYears != null)
              Text('Experience: ${walker.experienceYears} years'),
            if (walker.bio != null && walker.bio!.isNotEmpty)
              Text(walker.bio!, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '\$${walker.baseRatePerHour.toStringAsFixed(2)}/hr',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        onTap: () {
          widget.onWalkerSelected(walker);
          Navigator.pop(context);
        },
      ),
    );
  }
}
