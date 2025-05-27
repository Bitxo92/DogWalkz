import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dogwalkz/models/dog.dart';
import 'package:dogwalkz/repositories/dogs_repository.dart';
import 'package:dogwalkz/pages/add_edit_dog_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DogsPage extends StatefulWidget {
  const DogsPage({super.key});

  @override
  State<DogsPage> createState() => _DogsPageState();
}

class _DogsPageState extends State<DogsPage> {
  final DogsRepository _dogsRepository = DogsRepository();
  late Future<List<Dog>> _dogsFuture;
  final addEditDogPage = AddEditDogPage();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initializes the state of the widget.
  @override
  void initState() {
    super.initState();
    _loadDogs();
  }

  /// Loads the list of dogs from the DogsRepository.
  void _loadDogs() {
    setState(() {
      _dogsFuture = _dogsRepository.getDogsByOwner(
        _supabase.auth.currentUser!.id,
      );
    });
  }

  /// Deletes a dog from the list and the database.
  Future<void> _deleteDog(String dogId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.deleteDog),
            content: Text(AppLocalizations.of(context)!.deleteDogMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  AppLocalizations.of(context)!.delete,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _dogsRepository.deleteDog(dogId);
      _loadDogs();
    }
  }

  /// Builds the UI for the DogsPage.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E9D9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back_outline),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.furryFriends,
          style: TextStyle(
            fontFamily: GoogleFonts.comicNeue().fontFamily,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown,
      ),
      body: FutureBuilder<List<Dog>>(
        future: _dogsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Lottie.network(
                'https://lottie.host/4410b37a-0f15-4bbc-be66-ab2a92a6fb2e/D5q35grkIb.json',
                width: 200,
                height: 200,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final dogs = snapshot.data ?? [];

          if (dogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.network(
                    'https://lottie.host/4410b37a-0f15-4bbc-be66-ab2a92a6fb2e/D5q35grkIb.json',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.noDogs,
                    style: TextStyle(
                      fontFamily: GoogleFonts.comicNeue().fontFamily,
                      color: Colors.brown,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dogs.length,
            itemBuilder: (context, index) {
              final dog = dogs[index];
              return Dismissible(
                key: Key(dog.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Ionicons.trash_outline,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  await _deleteDog(dog.id);
                  return false;
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => _navigateToEditDog(dog),
                    onLongPress: () => _navigateToEditDog(dog),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (dog.photoUrl != null)
                            Hero(
                              tag: 'dog-image-${dog.id}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  dog.photoUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Hero(
                              tag: 'dog-image-${dog.id}',
                              child: Container(
                                width: 80,
                                height: 80,
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily:
                                        GoogleFonts.comicNeue().fontFamily,
                                    color: Colors.brown.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DogsRepository().getLocalizedBreedName(
                                    dog.breed,
                                    context,
                                  ),
                                  style: TextStyle(
                                    fontFamily:
                                        GoogleFonts.comicNeue().fontFamily,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (dog.age != null)
                                  Text(
                                    '${dog.age} ${AppLocalizations.of(context)!.years}',
                                    style: TextStyle(
                                      fontFamily:
                                          GoogleFonts.comicNeue().fontFamily,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Ionicons.chevron_forward_outline,
                            color: Colors.brown,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddDog,
        backgroundColor: Colors.brown,
        child: const Icon(Ionicons.paw_outline, color: Colors.white),
      ),
    );
  }

  /// Navigates to the Add/Edit Dog page to add a new dog.
  void _navigateToAddDog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditDogPage()),
    ).then((_) => _loadDogs());
  }

  /// Navigates to the Add/Edit Dog page to edit an existing dog.
  void _navigateToEditDog(Dog dog) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                AddEditDogPage(dog: dog),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    ).then((_) => _loadDogs());
  }
}
