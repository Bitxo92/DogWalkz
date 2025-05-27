import 'dart:async';
import 'package:dogwalkz/pages/password_reset_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final Uri? initialUri;
  const SplashScreen({Key? key, this.initialUri}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _taglineOpacityAnimation;
  String _displayText = '';
  int _currentIndex = 0;
  final String _appName = 'DogWalkz';
  final String _tagline = 'Where every walk \nis a wagging good time!';
  Timer? _typingTimer;
  bool _showTagline = false;

  /// Initilizes the splash screen with an animation controller and animations.
  /// The animation controller is used to control the duration and timing of the
  /// animation. The animations are used to animate the app name and tagline.
  @override
  void initState() {
    super.initState();
    if (widget.initialUri?.host == 'reset-password') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PasswordResetPage()),
        );
      });
    } else {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(
          milliseconds: 3500,
        ), // Total animation duration
      );

      // Animation for app name
      _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
        ),
      );

      // Animation for tagline
      _taglineOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
        ),
      );

      _startTypingAnimation();
      _navigateToLogin();
    }
  }

  /// Starts the typing animation for the app name.
  /// The animation types out the app name one letter at a time, with a delay between each letter.
  void _startTypingAnimation() {
    const letterDelay = Duration(milliseconds: 250); // Slower typing speed

    _typingTimer = Timer.periodic(letterDelay, (timer) {
      if (_currentIndex < _appName.length) {
        setState(() {
          _displayText = _appName.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        timer.cancel();
        // After typing completes, wait a moment then show tagline
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => _showTagline = true);
            _controller.forward(); // Starts the fade-in animation
          }
        });
      }
    });
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 7)); // Total screen duration
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  /// Disposes resources used by the splash screen.
  /// This method cancels the typing timer and disposes of the animation controller.
  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Builds the splash screen UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E9D9),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dog animation
              SizedBox(
                width: 300,
                height: 300,
                child: Lottie.network(
                  'https://lottie.host/2dc0f80f-298a-4dac-be21-504a26258d86/SjRWccUga2.json',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),

              // App name with typing effect
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Text(
                      _displayText,
                      style: GoogleFonts.chewy(
                        fontSize: 52,
                        height: 0.9,
                        color: Colors.brown[800],
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.brown.withOpacity(0.3),
                            offset: const Offset(3, 3),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Tagline with fade-in effect
              if (_showTagline)
                FadeTransition(
                  opacity: _taglineOpacityAnimation,
                  child: Text(
                    _tagline,
                    style: GoogleFonts.comicNeue(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown[700],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
