import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

/// This is the main class for the authentication page.
/// It handles both login and registration functionalities using Supabase.
/// It also includes animations and form validation.
/// The page is divided into two tabs: Login and Register.
class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _animationController;
  final _supabase = Supabase.instance.client;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _acceptTerms = false;

  /// Initializes the state of the widget.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange); // Add this line
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _loadSavedCredentials();
  }

  /// Handles the tab change event.
  /// This method is called when the user switches between the login and register tabs.
  void _handleTabChange() {
    setState(() {});
  }

  /// Saves the user's credentials in shared preferences.
  /// This method is called when the user checks the "Remember Me" checkbox.
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('rememberMe', true);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
    } else {
      await prefs.remove('rememberMe');
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  /// Loads the saved credentials from shared preferences.
  /// This method is called when the user opens the app.
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      final email = prefs.getString('email') ?? '';
      final password = prefs.getString('password') ?? '';

      setState(() {
        _rememberMe = rememberMe;
        _emailController.text = email;
        _passwordController.text = password;
      });
    }
  }

  /// Disposes the animation controller and text controllers.
  /// This method is called when the widget is removed from the widget tree.
  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Handles the login functionality using Supabase.
  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user == null) {
        throw Exception('User not found');
      }
      // Save credentials if "Remember Me" is checked
      await _saveCredentials();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Handles the registration functionality using Supabase.
  /// This method validates the form fields and checks if the user has accepted the terms and conditions.
  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the terms and conditions'),
        ),
      );
      return;
    }
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
      );

      if (response.user == null) {
        throw Exception('Registration failed');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration successful! Please check your email for verification.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        // Clear form and switch to login tab
        _nameController.clear();
        _phoneController.clear();
        _emailController.clear();
        _passwordController.clear();
        _tabController.animateTo(0);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Builds the UI for the authentication page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E9D9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          _tabController.index == 0
                              ? 'Welcome Back to the Pack! 🐾' // Login message
                              : 'Where Pets & Walkers Connect! 🐾', // Register message
                          style: GoogleFonts.comicNeue(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[800],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Lottie.network(
                        'https://lottie.host/22aeebc6-fcf5-460e-ac08-91cdedf3dc55/hdaZK2C6hn.json',
                        controller: _animationController,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Ionicons.paw_outline,
                              size: 100,
                              color: Colors.brown,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              // Auth Container
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.brown,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.brown,
                      tabs: const [Tab(text: 'Login'), Tab(text: 'Register')],
                    ),

                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          SingleChildScrollView(child: _buildLoginForm()),
                          SingleChildScrollView(child: _buildRegisterForm()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the login form widget.
  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: _inputDecoration('Email', Ionicons.mail_outline),
              validator:
                  (value) => value!.isEmpty ? 'Please enter email' : null,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: _inputDecoration(
                'Password',
                Ionicons.lock_closed_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Ionicons.eye_outline
                        : Ionicons.eye_off_outline,
                    color: Colors.brown,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              validator:
                  (value) => value!.isEmpty ? 'Please enter password' : null,
            ),
            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                        activeColor: Colors.brown,
                      ),
                      const Text('Remember me'),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password reset functionality coming soon!',
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildAuthButton('Login', _login),
          ],
        ),
      ),
    );
  }

  /// Builds the register form widget.
  Widget _buildRegisterForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _registerFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Username', Ionicons.person_outline),
              validator:
                  (value) => value!.isEmpty ? 'Please enter username' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: _inputDecoration('Email', Ionicons.mail_outline),
              validator: (value) {
                if (value!.isEmpty) return 'Please enter email';
                if (!value.contains('@')) return 'Please enter a valid email';
                return null;
              },
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _phoneController,
              decoration: _inputDecoration('Phone', Ionicons.call_outline),
              validator:
                  (value) => value!.isEmpty ? 'Please enter phone' : null,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: _inputDecoration(
                'Password',
                Ionicons.lock_closed_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Ionicons.eye_outline
                        : Ionicons.eye_off_outline,
                    color: Colors.brown,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) return 'Please enter password';
                if (value.length < 6) return 'At least 6 characters required';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptTerms = value!;
                    });
                  },
                  activeColor: Colors.brown,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _showTermsDialog,
                    child: RichText(
                      text: const TextSpan(
                        text: 'I agree to the ',
                        style: TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: TextStyle(
                              color: Colors.brown,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAuthButton('Register', _register),
          ],
        ),
      ),
    );
  }

  /// Builds the input decoration for the text fields.
  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.brown),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
    );
  }

  /// Builds an auth button widget.
  /// This button is used for both login and register actions.
  /// It shows a loading indicator when the action is in progress.
  Widget _buildAuthButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child:
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                  text,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
      ),
    );
  }

  /// Shows the terms and conditions dialog.
  Future<void> _showTermsDialog() async {
    // Load the terms from the text file in assets folder
    final termsText = await rootBundle.loadString(
      'assets/terms_and_conditions.txt',
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Terms and Conditions'),
            content: SingleChildScrollView(child: Text(termsText)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
