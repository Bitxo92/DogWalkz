import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSuccess = false;
  String? _errorMessage;

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      setState(() {
        _isSuccess = true;
      });

      // Optionally auto-navigate after success
      // Future.delayed(const Duration(seconds: 2), () {
      //   Navigator.pushReplacementNamed(context, '/auth');
      // });
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E9D9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Form(
            key: _formKey,
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
                            _isSuccess
                                ? 'Password Updated! ✅'
                                : 'Create New Password 🔒',
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
                          _isSuccess
                              ? 'https://lottie.host/5b6d0a8a-9e7a-4f3a-8b8f-9f9f9f9f9f9f/5b6d0a8a-9e7a-4f3a-8b8f-9f9f9f9f9f9f.json'
                              : 'https://lottie.host/4410b37a-0f15-4bbc-be66-ab2a92a6fb2e/D5q35grkIb.json',
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

                if (_isSuccess) ...[
                  // Success State
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Your password has been updated successfully! You can now login with your new password.',
                      style: TextStyle(fontSize: 16, color: Colors.brown[700]),
                    ),
                  ),
                  const SizedBox(height: 30),
                ] else ...[
                  // Form State
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Please enter your new password and confirm it to complete the reset process.',
                      style: TextStyle(fontSize: 16, color: Colors.brown[700]),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // New Password Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_isPasswordVisible,
                      decoration: _inputDecoration(
                        'New Password',
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
                        if (value!.isEmpty) return 'Please enter new password';
                        if (value.length < 6)
                          return 'At least 6 characters required';
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Confirm Password Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: _inputDecoration(
                        'Confirm Password',
                        Ionicons.lock_closed_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Ionicons.eye_outline
                                : Ionicons.eye_off_outline,
                            color: Colors.brown,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) return 'Please confirm password';
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Ionicons.warning_outline,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                _isLoading
                    ? null
                    : _isSuccess
                    ? () => Navigator.pushReplacementNamed(context, '/auth')
                    : _updatePassword,
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
                      _isSuccess ? 'Back to Login' : 'Update Password',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
          ),
        ),
      ),
    );
  }

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
}
