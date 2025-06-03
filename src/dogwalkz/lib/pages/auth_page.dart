import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:dogwalkz/constants/supabase.dart';
import 'package:dogwalkz/pages/password_reset_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  bool _handledResetPasswordLink = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _acceptTerms = false;
  bool _isLogin = true;
  late final StreamSubscription<Uri> _sub;

  /// Initializes the state of the widget.
  @override
  void initState() {
    super.initState();
    final appLinks = AppLinks();
    // Listen for new deep links while the app is running
    _sub = appLinks.uriLinkStream.listen((uri) {
      if (!_handledResetPasswordLink && uri.host == 'reset-password') {
        _handledResetPasswordLink = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PasswordResetPage()),
        );
      }
    });
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
    _sub.cancel();
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
        emailRedirectTo: 'https://symphonious-macaron-f46ddc.netlify.app/',
        data: {'name': _nameController.text.trim()},
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

  Future<void> _resetPassword(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'dogwalkz://reset-password',
      );
      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Password Reset Email Sent'),
              content: Text(
                'A password reset link has been sent to $email. '
                'Please check your inbox and follow the instructions.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final emailController = TextEditingController(
          text: _emailController.text,
        );
        return AlertDialog(
          title: const Text('Reset Password'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email address',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetPassword(emailController.text.trim());
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  /// Builds the UI for the authentication page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Image.asset('assets/Background.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  SizedBox(
                    height: 140,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 24, right: 24),
                            child: Text(
                              _isLogin
                                  ? 'Welcome Back to the Pack! 🐾'
                                  : 'Where Pets & Walkers Connect! 🐾',
                              style: GoogleFonts.comicNeue(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[800],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          height: 140,
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

                  const SizedBox(height: 20),

                  // Auth Forms
                  _isLogin ? _buildLoginForm() : _buildRegisterForm(),

                  const SizedBox(height: 20),

                  // Toggle Login/Register
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(
                        _isLogin
                            ? "Don't have an account? Sign up"
                            : "Already have an account? Log in",
                        style: TextStyle(
                          color: Colors.brown[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // OAuth Icons Row
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildOAuthIconButton(
                          Ionicons.logo_google,
                          _signInWithGoogle,
                        ),
                        const SizedBox(width: 20),
                        _buildOAuthIconButton(
                          Ionicons.logo_facebook,
                          _signInWithFacebook,
                        ),
                        const SizedBox(width: 20),
                        _buildOAuthIconButton(
                          Ionicons.logo_instagram,
                          _signInWithFacebook,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOAuthButton(IconData icon, String label) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.brown.shade100,
        foregroundColor: Colors.brown[800],
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {},
      icon: Icon(icon, size: 24),
      label: Text(label, style: const TextStyle(fontSize: 16)),
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
                    onPressed: () => _showResetPasswordDialog(),
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
                ? const CircularProgressIndicator(color: Colors.brown)
                : Text(
                  text,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
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
  Widget _buildOAuthIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.brown.shade100,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 28, color: Colors.brown[800]),
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

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: SupabaseCredentials.googleClientId,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user == null) {
        throw Exception('Authentication failed');
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign in failed: ${e.message}')),
      );
    } on PlatformException catch (e) {
      String errorMessage = 'Google sign in failed';
      if (e.code == 'sign_in_failed') {
        errorMessage = 'Sign in failed. Please try again.';
      } else if (e.code == 'sign_in_canceled') {
        errorMessage = 'Sign in was canceled';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);

    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.facebook);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facebook sign-in failed: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
