import 'dart:convert';

import 'package:dogwalkz/main.dart';
import 'package:dogwalkz/services/language_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _verificationDocumentController = TextEditingController();
  String? _verificationStatus;
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  File? _localImage;
  Map<String, dynamic> _profileData = {};
  Map<String, dynamic> _walkerProfileData = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEnglish = true;
  bool _notificationsEnabled = true;
  List<String> _allMunicipalities = [];
  List<String> _provinces = [];
  Map<String, String> _municipalityToProvince = {};
  Map<String, String> _variationToOfficialName = {};

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _docIdController = TextEditingController();
  final _ageController = TextEditingController();
  final _dobController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _certificationNumberController = TextEditingController();

  /// Initializes the state of the ProfilePage widget.
  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _loadProfile();
    _loadGalicianMunicipalities();
  }

  /// Loads the user's profile data from the Supabase database.
  Future<void> _loadProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();

      if (response != null) {
        setState(() {
          _profileData = response;
          _firstNameController.text = response['first_name'] ?? '';
          _lastNameController.text = response['last_name'] ?? '';
          _emailController.text = response['email'] ?? '';
          _phoneController.text = response['phone'] ?? '';
          _dobController.text = response['date_of_birth']?.toString() ?? '';

          final address = response['address'];
          if (address is Map) {
            _streetController.text = address['street'] ?? '';
            _cityController.text = address['city'] ?? '';
            _stateController.text = address['state'] ?? '';
            _postalCodeController.text = address['postal_code'] ?? '';
            _countryController.text = address['country'] ?? '';
          }

          _verificationStatus = response['verification_status'];
          _verificationDocumentController.text =
              response['verification_document_url'] ?? '';

          _notificationsEnabled =
              response['push_notifications_enabled'] ?? true;

          if (response['is_walker'] == true) {
            _loadWalkerProfile(userId);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Loads the user's language preference from the LanguageService.
  Future<void> _loadLanguagePreference() async {
    final savedLanguage = await LanguageService.getLanguage();
    if (savedLanguage != null) {
      setState(() {
        _isEnglish = savedLanguage == 'en';
      });
    }
  }

  /// Loads the walker's profile data from the Supabase database.
  Future<void> _loadWalkerProfile(String userId) async {
    try {
      final response =
          await _supabase
              .from('walker_profiles')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      if (response != null) {
        setState(() {
          _walkerProfileData = response;
          _bioController.text = response['bio'] ?? '';

          _experienceController.text =
              response['experience_years']?.toString() ?? '';
          _certificationNumberController.text =
              response['certification_number'] ?? '';
          _docIdController.text = response['doc_id'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading walker profile: $e');
    }
  }

  /// Allows the user to select an image from their device's gallery, and then
  /// uploads it to the Supabase storage bucket. The image is resized to a
  /// maximum width and height of 800px, and the image quality is set to 80%.
  ///
  /// If the user doesn't select an image, the function does nothing.
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _localImage = imageFile;
        });
        await _uploadImage(imageFile); // Upload after setting the local image
      }
    } catch (e) {
      _showError('Image selection failed: ${e.toString()}');
    }
  }

  /// Uploads a user's profile image to Supabase storage and updates the user's profile with the image URL.
  ///
  /// This method first retrieves the current user's ID from the Supabase authentication service.
  /// If the user ID is not found, the method returns early. The image file is then read into bytes,
  /// and a filename is generated using the user's ID and the image file's extension.
  ///
  /// The image bytes are uploaded to the 'profile-pictures' bucket in Supabase storage with the option
  /// to upsert (this means it will overwrite existing files with the same name). After a successful upload, the public URL
  /// of the uploaded image is obtained and the user's profile in the 'users' table is updated with this
  /// URL. The local profile data state is also updated with the new image URL.
  Future<void> _uploadImage(File image) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Validate image file
      if (!await image.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileExt = image.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'gif'].contains(fileExt)) {
        throw Exception('Unsupported image format');
      }
      // create unique file name to avoid cached images
      final fileName =
          '${userId}_profile_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Show loading state
      setState(() => _isSaving = true);

      // Upload the file
      await _supabase.storage
          .from('profile-pictures')
          .upload(
            fileName,
            image,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/${fileExt == 'jpg' ? 'jpeg' : fileExt}',
            ),
          );

      // Get the public URL
      final imageUrl = _supabase.storage
          .from('profile-pictures')
          .getPublicUrl(fileName);

      // Update user profile with the new URL
      await _supabase
          .from('users')
          .update({
            'profile_picture_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Update local state
      setState(() {
        _profileData['profile_picture_url'] = imageUrl;
        _localImage = null; // Clear local image since we now have a URL
      });
    } catch (e) {
      _showError('Upload failed: ${e.toString()}');
      debugPrint('Image upload error: $e');
      // Optionally show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Saves the user's profile information to the Supabase database.
  ///
  /// This method first validates the form data and ensures that it is correct.
  /// If the form is valid, it sets the [_isSaving] state to true, retrieves
  /// the current user's ID, and constructs an address map from the input fields.
  ///
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final address = {
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'country': _countryController.text.trim(),
      };

      await _supabase.from('users').upsert({
        'id': userId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': address,
        'date_of_birth': _dobController.text.trim(),
        'is_walker': _profileData['is_walker'] ?? false,
        'notifications_enabled': _notificationsEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (_profileData['is_walker'] == true) {
        await _supabase.from('walker_profiles').upsert({
          'user_id': userId,
          'bio': _bioController.text.trim(),
          'doc_id': _docIdController.text.trim(),
          'experience_years': int.tryParse(_experienceController.text),
          'certification_number': _certificationNumberController.text.trim(),
          'can_walk_small': _walkerProfileData['can_walk_small'] ?? true,
          'can_walk_medium': _walkerProfileData['can_walk_medium'] ?? true,
          'can_walk_large': _walkerProfileData['can_walk_large'] ?? false,
          'has_dangerous_breed_certification':
              _walkerProfileData['has_dangerous_breed_certification'] ?? false,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.profileSaved),
                content: Text(
                  AppLocalizations.of(context)!.profileSavedMessage,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/home'));
                    },
                    child: Text(AppLocalizations.of(context)!.ok),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      _showError('Save failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Displays an error message in the debug console.
  /// was neccessary while debugging the app.
  void _showError(String message) {
    debugPrint("Error: $message");
  }

  /// Displays a profile image or a placeholder icon.
  Widget _buildProfileImage() {
    return GestureDetector(
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
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.brown.shade100,
              backgroundImage: _getProfileImage(),
              child:
                  _shouldShowPlaceholder()
                      ? const Icon(
                        Ionicons.person_outline,
                        size: 60,
                        color: Colors.brown,
                      )
                      : null,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.brown,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Ionicons.camera_outline,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Returns the profile image based on the local image or the URL from the database.
  /// If no image is available, it returns null.
  ImageProvider? _getProfileImage() {
    if (_localImage != null) return FileImage(_localImage!);
    if (_profileData['profile_picture_url'] != null) {
      return NetworkImage(_profileData['profile_picture_url']);
    }
    return null;
  }

  /// Checks if a placeholder Image should be shown.
  bool _shouldShowPlaceholder() {
    return _localImage == null && _profileData['profile_picture_url'] == null;
  }

  /// Displays a date picker dialog to select the date of birth.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF6D4C41),
              onPrimary: Colors.white,
              onSurface: Colors.brown,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFF6D4C41)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  /// Builds the UI for the ProfilePage widget.
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5E9D9),
        body: Center(child: CircularProgressIndicator(color: Colors.brown)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
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
                title: Text(AppLocalizations.of(context)!.myProfile),
                titleTextStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: GoogleFonts.comicNeue().fontFamily,
                ),
                centerTitle: true,

                backgroundColor: Colors.brown,
                leading: IconButton(
                  icon: const Icon(Ionicons.arrow_back_outline),
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.only(top: screenHeight * 0.16, bottom: 100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.07),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                AppLocalizations.of(context)!.personalInfo,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: InputDecoration(
                                      labelText:
                                          AppLocalizations.of(
                                            context,
                                          )!.firstName,
                                      prefixIcon: const Icon(
                                        Ionicons.person_outline,
                                        color: Colors.brown,
                                      ),
                                    ),
                                    validator:
                                        (value) =>
                                            value?.isEmpty ?? true
                                                ? AppLocalizations.of(
                                                  context,
                                                )!.required
                                                : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: InputDecoration(
                                      labelText:
                                          AppLocalizations.of(
                                            context,
                                          )!.lastName,
                                    ),
                                    validator:
                                        (value) =>
                                            value?.isEmpty ?? true
                                                ? AppLocalizations.of(
                                                  context,
                                                )!.required
                                                : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              readOnly: true,
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.email,
                                prefixIcon: const Icon(
                                  Ionicons.mail_outline,
                                  color: Colors.brown,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.isEmpty ?? true)
                                  return AppLocalizations.of(context)!.required;
                                if (!value!.contains('@'))
                                  return AppLocalizations.of(
                                    context,
                                  )!.emailInvalid;
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.phone,
                                prefixIcon: Icon(
                                  Ionicons.call_outline,
                                  color: Colors.brown,
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              validator:
                                  (value) =>
                                      value?.isEmpty ?? true
                                          ? AppLocalizations.of(
                                            context,
                                          )!.required
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _dobController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.dob,
                                prefixIcon: const Icon(
                                  Ionicons.calendar_outline,
                                  color: Colors.brown,
                                ),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              validator:
                                  (value) =>
                                      value?.isEmpty ?? true
                                          ? AppLocalizations.of(
                                            context,
                                          )!.required
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                AppLocalizations.of(context)!.address,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _streetController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.street,
                                prefixIcon: Icon(
                                  Ionicons.home_outline,
                                  color: Colors.brown,
                                ),
                              ),
                              validator:
                                  (value) =>
                                      value?.isEmpty ?? true
                                          ? AppLocalizations.of(
                                            context,
                                          )!.required
                                          : null,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TypeAheadFormField<String>(
                                    textFieldConfiguration:
                                        TextFieldConfiguration(
                                          controller: _cityController,
                                          decoration: InputDecoration(
                                            labelText:
                                                AppLocalizations.of(
                                                  context,
                                                )!.city,
                                            prefixIcon: Icon(
                                              Ionicons.business_outline,
                                              color: Colors.brown,
                                            ),
                                          ),
                                        ),
                                    suggestionsCallback: (pattern) {
                                      return _allMunicipalities
                                          .where(
                                            (municipality) => municipality
                                                .toLowerCase()
                                                .contains(
                                                  pattern.toLowerCase(),
                                                ),
                                          )
                                          .toList();
                                    },
                                    itemBuilder: (context, String suggestion) {
                                      return Card(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.location_city,
                                            color: Colors.brown,
                                          ),
                                          title: Text(
                                            suggestion,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    onSuggestionSelected: (String suggestion) {
                                      final normalized =
                                          _variationToOfficialName[suggestion
                                              .toLowerCase()] ??
                                          suggestion;
                                      _cityController.text = normalized;

                                      final province =
                                          _municipalityToProvince[suggestion
                                              .toLowerCase()];
                                      if (province != null) {
                                        _stateController.text = province;
                                      }
                                    },
                                    suggestionsBoxDecoration:
                                        SuggestionsBoxDecoration(
                                          color: const Color(0xFFF5E9D9),
                                          elevation: 4.0,

                                          constraints: BoxConstraints(
                                            maxHeight: 200,
                                          ),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),

                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TypeAheadFormField<String>(
                                    textFieldConfiguration:
                                        TextFieldConfiguration(
                                          controller: _stateController,
                                          decoration: InputDecoration(
                                            labelText:
                                                AppLocalizations.of(
                                                  context,
                                                )!.state,
                                            prefixIcon: Icon(
                                              Ionicons.map_outline,
                                              color: Colors.brown,
                                            ),
                                          ),
                                        ),
                                    suggestionsCallback: (pattern) {
                                      return _provinces
                                          .where(
                                            (province) =>
                                                province.toLowerCase().contains(
                                                  pattern.toLowerCase(),
                                                ),
                                          )
                                          .toList();
                                    },
                                    itemBuilder: (context, String suggestion) {
                                      return Card(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.map,
                                            color: Colors.brown,
                                          ),
                                          title: Text(
                                            suggestion,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    onSuggestionSelected: (String suggestion) {
                                      _stateController.text = suggestion;
                                    },
                                    suggestionsBoxDecoration:
                                        SuggestionsBoxDecoration(
                                          color: const Color(0xFFF5E9D9),
                                          elevation: 4.0,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          constraints: BoxConstraints(
                                            maxHeight: 200,
                                          ),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _postalCodeController,
                                    decoration: InputDecoration(
                                      labelText:
                                          AppLocalizations.of(
                                            context,
                                          )!.postalCode,
                                      prefixIcon: Icon(
                                        Ionicons.code_outline,
                                        color: Colors.brown,
                                      ),
                                    ),
                                    validator:
                                        (value) =>
                                            value?.isEmpty ?? true
                                                ? AppLocalizations.of(
                                                  context,
                                                )!.required
                                                : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _countryController,
                                    decoration: InputDecoration(
                                      labelText:
                                          AppLocalizations.of(context)!.country,
                                      prefixIcon: Icon(
                                        Ionicons.earth_outline,
                                        color: Colors.brown,
                                      ),
                                    ),
                                    validator:
                                        (value) =>
                                            value?.isEmpty ?? true
                                                ? AppLocalizations.of(
                                                  context,
                                                )!.required
                                                : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: Text(
                                AppLocalizations.of(context)!.registerWalker,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              activeColor: Colors.brown,
                              secondary: const Icon(
                                Ionicons.paw_outline,
                                color: Colors.brown,
                              ),
                              value: _profileData['is_walker'] ?? false,
                              onChanged:
                                  (value) => setState(() {
                                    _profileData['is_walker'] = value;
                                    if (value) {
                                      _loadWalkerProfile(
                                        _supabase.auth.currentUser!.id,
                                      );
                                    }
                                  }),
                            ),
                            if (_profileData['is_walker'] == true) ...[
                              TextFormField(
                                controller: _bioController,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.bio,
                                  prefixIcon: Icon(
                                    Ionicons.document_text_outline,
                                    color: Colors.brown,
                                  ),
                                ),
                                maxLines: 3,
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? AppLocalizations.of(
                                              context,
                                            )!.required
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _experienceController,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.experience,
                                  prefixIcon: Icon(
                                    Ionicons.time_outline,
                                    color: Colors.brown,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty ?? true)
                                    return AppLocalizations.of(
                                      context,
                                    )!.required;
                                  final years = int.tryParse(value!);
                                  if (years == null || years < 0)
                                    return 'Invalid';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _docIdController,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.nie,
                                  prefixIcon: Icon(
                                    Ionicons.card_outline,
                                    color: Colors.brown,
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? AppLocalizations.of(
                                              context,
                                            )!.required
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: Text(
                                  AppLocalizations.of(context)!.walkSmall,
                                ),
                                secondary: const Icon(
                                  Ionicons.paw_outline,
                                  color: Colors.brown,
                                  size: 20,
                                ),
                                activeColor: Colors.brown,
                                value:
                                    _walkerProfileData['can_walk_small'] ??
                                    true,
                                onChanged:
                                    (value) => setState(() {
                                      _walkerProfileData['can_walk_small'] =
                                          value;
                                    }),
                              ),
                              SwitchListTile(
                                title: Text(
                                  AppLocalizations.of(context)!.walkMedium,
                                ),
                                secondary: const Icon(
                                  Ionicons.paw_outline,
                                  color: Colors.brown,
                                  size: 20,
                                ),
                                activeColor: Colors.brown,
                                value:
                                    _walkerProfileData['can_walk_medium'] ??
                                    true,
                                onChanged:
                                    (value) => setState(() {
                                      _walkerProfileData['can_walk_medium'] =
                                          value;
                                    }),
                              ),
                              SwitchListTile(
                                title: Text(
                                  AppLocalizations.of(context)!.walkLarge,
                                ),
                                secondary: const Icon(
                                  Ionicons.paw_outline,
                                  color: Colors.brown,
                                  size: 20,
                                ),
                                activeColor: Colors.brown,
                                value:
                                    _walkerProfileData['can_walk_large'] ??
                                    false,
                                onChanged:
                                    (value) => setState(() {
                                      _walkerProfileData['can_walk_large'] =
                                          value;
                                    }),
                              ),
                              SwitchListTile(
                                title: Text(
                                  AppLocalizations.of(context)!.dangerousBreed,
                                ),
                                secondary: const Icon(
                                  Ionicons.warning_outline,
                                  color: Colors.brown,
                                ),
                                activeColor: Colors.brown,
                                value:
                                    _walkerProfileData['has_dangerous_breed_certification'] ??
                                    false,
                                onChanged:
                                    (value) => setState(() {
                                      _walkerProfileData['has_dangerous_breed_certification'] =
                                          value;
                                    }),
                              ),
                              if (_walkerProfileData['has_dangerous_breed_certification'] ==
                                  true) ...[
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _certificationNumberController,
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(
                                          context,
                                        )!.certificationNumber,
                                    prefixIcon: Icon(
                                      Ionicons.ribbon_outline,
                                      color: Colors.brown,
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Required when certification is enabled'
                                              : null,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                AppLocalizations.of(context)!.settings,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              title: Text(
                                AppLocalizations.of(context)!.language,
                              ),
                              subtitle: Text(
                                _isEnglish
                                    ? AppLocalizations.of(context)!.english
                                    : AppLocalizations.of(context)!.spanish,
                              ),
                              leading: const Icon(
                                Ionicons.language_outline,
                                color: Colors.brown,
                              ),
                              trailing: const Icon(
                                Ionicons.chevron_forward_outline,
                                color: Colors.brown,
                              ),
                              onTap: () => _showLanguageDialog(context),
                            ),
                            SwitchListTile(
                              title: Text(
                                AppLocalizations.of(context)!.notifications,
                              ),
                              activeColor: Colors.brown,
                              subtitle: Text(
                                AppLocalizations.of(
                                  context,
                                )!.enableNotifications,
                              ),
                              secondary: const Icon(
                                Ionicons.notifications_outline,
                                color: Colors.brown,
                              ),
                              value: _notificationsEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _notificationsEnabled = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: (screenHeight * 0.16) - 40,
            left: screenWidth / 2 - 60,
            child: _buildProfileImage(),
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
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  elevation: 4,
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _isSaving
                        ? const CircularProgressIndicator(color: Colors.brown)
                        : Text(
                          AppLocalizations.of(context)!.save,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: GoogleFonts.comicNeue().fontFamily,
                          ),
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Displays a dialog to select the language.
  Future<void> _showLanguageDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<bool>(
                title: Text(AppLocalizations.of(context)!.english),
                activeColor: Colors.brown,
                value: true,
                groupValue: _isEnglish,
                onChanged: (value) {
                  Navigator.pop(context);
                  _changeLanguage(value!);
                },
              ),
              RadioListTile<bool>(
                title: Text(AppLocalizations.of(context)!.spanish),
                activeColor: Colors.brown,
                value: false,
                groupValue: _isEnglish,
                onChanged: (value) {
                  Navigator.pop(context);
                  _changeLanguage(value!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Changes the app's language based on the user's selection.
  /// It updates the app's locale and saves the selected language to local storage.
  void _changeLanguage(bool isEnglish) async {
    setState(() {
      _isEnglish = isEnglish;
    });
    final locale = isEnglish ? const Locale('en') : const Locale('es');
    MyApp.of(context)?.setLocale(locale);
    await LanguageService.saveLanguage(isEnglish ? 'en' : 'es');
  }

  Future<void> _loadGalicianMunicipalities() async {
    try {
      final data = await rootBundle.loadString(
        'assets/galician_municipalities.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(data);

      _provinces = jsonMap.keys.toList();
      _allMunicipalities = [];
      _municipalityToProvince = {};
      _variationToOfficialName = {};
      jsonMap.forEach((province, municipalities) {
        for (var mun in municipalities) {
          final officialName = mun['municipio'];
          final variations = List<String>.from(mun['variaciones'] ?? []);

          // Add official name
          _allMunicipalities.add(officialName);
          _municipalityToProvince[officialName.toLowerCase()] = province;
          _variationToOfficialName[officialName.toLowerCase()] = officialName;

          // Add variations
          for (var variation in variations) {
            _allMunicipalities.add(variation);
            _municipalityToProvince[variation.toLowerCase()] = province;
            _variationToOfficialName[variation.toLowerCase()] =
                officialName; // Map variation to official name
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading municipalities: $e');
    }
  }

  /// Disposes of the controllers to free up resources.
  /// This is important to prevent memory leaks and ensure that the app runs efficiently.
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _docIdController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _certificationNumberController.dispose();
    _verificationDocumentController.dispose();
    super.dispose();
  }
}
