import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:dogwalkz/models/dog.dart';
import 'package:dogwalkz/repositories/dogs_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddEditDogPage extends StatefulWidget {
  final Dog? dog;

  const AddEditDogPage({super.key, this.dog});

  @override
  State<AddEditDogPage> createState() => _AddEditDogPageState();
}

class _AddEditDogPageState extends State<AddEditDogPage> {
  final _formKey = GlobalKey<FormState>();
  final _dogsRepository = DogsRepository();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  String _size = 'medium';
  bool _isDangerousBreed = false;
  bool _isSociable = true;
  File? _selectedImage;
  bool _isUploading = false;
  final List<String> _dogBreeds = [
    'germanShepherd',
    'labradorRetriever',
    'bulldog',
    'goldenRetriever',
    'beagle',
    'poodle',
    'rottweiler',
    'yorkshireTerrier',
    'boxer',
    'dachshund',
  ];

  /// Initializes the state of the widget.
  @override
  void initState() {
    super.initState();
    if (widget.dog != null) {
      _nameController.text = widget.dog!.name;
      _breedController.text = widget.dog!.breed;
      if (widget.dog!.age != null) {
        _ageController.text = widget.dog!.age.toString();
      }
      _specialInstructionsController.text =
          widget.dog!.specialInstructions ?? '';
      _size = widget.dog!.size;
      _isDangerousBreed = widget.dog!.isDangerousBreed;
      _isSociable = widget.dog!.isSociable;
    }
  }

  /// Disposes of the controllers to free up resources.
  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  /// Allows the user to select an image from their device's gallery.
  /// When the user selects an image, it is saved to the [_selectedImage]
  /// variable, and the widget is rebuilt to display the selected image.
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /// Builds the UI for the AddEditDogPage.
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: false,

      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Image.asset('assets/Background.png', fit: BoxFit.cover),
          ),
          Container(
            height: screenHeight * 0.16,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
              child: AppBar(
                elevation: 0,
                backgroundColor: Colors.brown,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Ionicons.arrow_back_outline),
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  widget.dog == null
                      ? AppLocalizations.of(context)!.addDog
                      : AppLocalizations.of(context)!.editDog,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: GoogleFonts.comicNeue().fontFamily,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.only(top: screenHeight * 0.16, bottom: 100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.07),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.dogName,
                        labelStyle: TextStyle(
                          fontFamily: GoogleFonts.comicNeue().fontFamily,
                          color: Colors.brown,
                        ),
                        prefixIcon: Icon(
                          Ionicons.paw_outline,
                          color: Colors.brown,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.required;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.dogBreed,
                        labelStyle: TextStyle(
                          fontFamily: GoogleFonts.comicNeue().fontFamily,
                          color: Colors.brown,
                        ),
                        prefixIcon: Icon(
                          Ionicons.earth_outline,
                          color: Colors.brown,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      controller: TextEditingController(
                        text:
                            _breedController.text.isNotEmpty
                                ? DogsRepository().getLocalizedBreedName(
                                  _breedController.text,
                                  context,
                                )
                                : '',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.required;
                        }
                        return null;
                      },
                      onTap: () async {
                        await _showBreedSelectionDialog();
                        setState(
                          () {},
                        ); //!Important --> Force rebuild so that the updated breed is translated
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.dogAge,
                        labelStyle: TextStyle(
                          fontFamily: GoogleFonts.comicNeue().fontFamily,
                          color: Colors.brown,
                        ),
                        prefixIcon: Icon(
                          Ionicons.calendar_outline,
                          color: Colors.brown,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _size,
                      items:
                          ['small', 'medium', 'large']
                              .map(
                                (size) => DropdownMenuItem(
                                  value: size,
                                  child: Text(
                                    _localizedSize(size, context),
                                    style: TextStyle(
                                      fontFamily:
                                          GoogleFonts.comicNeue().fontFamily,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) => setState(() => _size = value!),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.size,
                        labelStyle: TextStyle(
                          fontFamily: GoogleFonts.comicNeue().fontFamily,
                          color: Colors.brown,
                        ),
                        prefixIcon: Icon(
                          Ionicons.scale_outline,
                          color: Colors.brown,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context)!.dangerous,
                        style: TextStyle(
                          fontFamily: GoogleFonts.comicNeue().fontFamily,
                        ),
                      ),
                      secondary: Icon(
                        Ionicons.warning_outline,
                        color: _isDangerousBreed ? Colors.brown : Colors.grey,
                      ),
                      value: _isDangerousBreed,
                      onChanged:
                          (value) => setState(() => _isDangerousBreed = value),
                      activeColor: Colors.brown,
                    ),
                    SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context)!.sociable,
                        style: TextStyle(
                          fontFamily: GoogleFonts.comicNeue().fontFamily,
                        ),
                      ),
                      secondary: Icon(
                        Ionicons.people_outline,
                        color: _isSociable ? Colors.brown : Colors.grey,
                      ),
                      value: _isSociable,
                      onChanged: (value) => setState(() => _isSociable = value),
                      activeColor: Colors.brown,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _specialInstructionsController,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.specialInstructions,
                        labelStyle: TextStyle(
                          fontFamily: GoogleFonts.comicNeue().fontFamily,
                          color: Colors.brown,
                        ),
                        prefixIcon: Icon(
                          Ionicons.document_text_outline,
                          color: Colors.brown,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 200),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: (screenHeight * 0.16) - 40,
            left: screenWidth / 2 - 60,
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Hero(
                      tag: 'dog-image-${widget.dog?.id ?? 'new'}',
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.brown.shade100,
                        backgroundImage:
                            _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : widget.dog?.photoUrl != null
                                ? NetworkImage(widget.dog!.photoUrl!)
                                : null,
                        child:
                            _selectedImage == null &&
                                    widget.dog?.photoUrl == null
                                ? const Icon(
                                  Ionicons.camera_outline,
                                  size: 40,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                    ),
                  ),
                  if (_selectedImage == null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.brown,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Ionicons.camera_outline,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        height: 100,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _saveDog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _isUploading
                        ? const CircularProgressIndicator(color: Colors.brown)
                        : Text(
                          widget.dog == null
                              ? AppLocalizations.of(context)!.save
                              : AppLocalizations.of(context)!.updateDog,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: GoogleFonts.comicNeue().fontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Validates the form and saves the dog information to the database.
  Future<void> _saveDog() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);

      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await _dogsRepository.uploadDogPhoto(
          widget.dog?.id ?? const Uuid().v4(),
          File(_selectedImage!.path),
        );
      } else if (widget.dog != null) {
        photoUrl = widget.dog!.photoUrl;
      }

      final dog = Dog(
        id: widget.dog?.id ?? const Uuid().v4(),
        ownerId: Supabase.instance.client.auth.currentUser!.id,
        name: _nameController.text,
        breed: _breedController.text,
        age:
            _ageController.text.isNotEmpty
                ? int.tryParse(_ageController.text) ?? 0
                : null,
        size: _size,
        isDangerousBreed: _isDangerousBreed,
        isSociable: _isSociable,
        specialInstructions:
            _specialInstructionsController.text.isNotEmpty
                ? _specialInstructionsController.text
                : null,
        photoUrl: photoUrl,
        createdAt: widget.dog?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        if (widget.dog == null) {
          await _dogsRepository.addDog(dog);
        } else {
          await _dogsRepository.updateDog(dog);
        }
        setState(() => _isUploading = false);
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.dogProfileSaved),
                content: Text(
                  AppLocalizations.of(context)!.dogProfileSavedMessage,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/dogs'));
                    },
                    child: Text(AppLocalizations.of(context)!.ok),
                  ),
                ],
              ),
        );
      } catch (e) {
        print(e);
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Shows a confirmation dialog before deleting the dog.
  /// If the user confirms, it deletes the dog from the database.
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.deleteDog,
              style: TextStyle(fontFamily: GoogleFonts.comicNeue().fontFamily),
            ),
            content: Text(
              AppLocalizations.of(context)!.deleteDogMessage,
              style: TextStyle(fontFamily: GoogleFonts.comicNeue().fontFamily),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: TextStyle(
                    fontFamily: GoogleFonts.comicNeue().fontFamily,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  AppLocalizations.of(context)!.delete,
                  style: TextStyle(
                    fontFamily: GoogleFonts.comicNeue().fontFamily,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _dogsRepository.deleteDog(widget.dog!.id);
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error deleting dog: $e');
      }
    }
  }

  /// This method localizes the size string based on the current locale.
  /// It returns the localized string for the given size.
  String _localizedSize(String size, BuildContext context) {
    switch (size) {
      case 'small':
        return AppLocalizations.of(context)!.small;
      case 'medium':
        return AppLocalizations.of(context)!.medium;
      case 'large':
        return AppLocalizations.of(context)!.large;
      default:
        return size;
    }
  }

  Future<void> _showBreedSelectionDialog() async {
    String? searchTerm;
    String? selectedBreed = _breedController.text;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final bottomInsets = MediaQuery.of(context).viewInsets.bottom;

            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.dogBreed),
              contentPadding: const EdgeInsets.all(16),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchBreeds,
                        prefixIcon: const Icon(Ionicons.search_outline),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.brown),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.brown),
                        ),
                      ),
                      cursorColor: Colors.brown,
                      onChanged: (value) {
                        setState(() {
                          searchTerm = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children:
                              _dogBreeds
                                  .where(
                                    (breedKey) =>
                                        searchTerm == null ||
                                        DogsRepository()
                                            .getLocalizedBreedName(
                                              breedKey,
                                              context,
                                            )
                                            .toLowerCase()
                                            .contains(searchTerm!),
                                  )
                                  .map((breedKey) {
                                    final breedName = DogsRepository()
                                        .getLocalizedBreedName(
                                          breedKey,
                                          context,
                                        );
                                    return RadioListTile<String>(
                                      title: Text(breedName),
                                      activeColor: Colors.brown,
                                      value: breedKey,
                                      groupValue: selectedBreed,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedBreed = value;
                                        });
                                        Navigator.pop(context);
                                        setState(() {
                                          _breedController.text = breedKey;
                                        });
                                      },
                                    );
                                  })
                                  .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: EdgeInsets.zero,
            );
          },
        );
      },
    );
  }
}
