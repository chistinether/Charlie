import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  bool showLetter = false;
  bool showName = false;
  bool showSlogan = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Controls the logo pop animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Makes the square grow from small to normal size
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _startAnimation();
  }


  void _startAnimation() async {

    // Show golden square with pop effect
    await Future.delayed(const Duration(milliseconds: 300));

    _controller.forward();


    // Show C
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      showLetter = true;
    });


    // Show Charlie
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      showName = true;
    });


    // Show slogan
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      showSlogan = true;
    });


    // Move to login screen
    await Future.delayed(const Duration(seconds: 2));


    if (!mounted) return;


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            // Golden square logo
            ScaleTransition(
              scale: _scaleAnimation,

              child: Container(
                width: 90,
                height: 90,

                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),

                  borderRadius:
                  BorderRadius.circular(22),

                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),


                child: Center(

                  // Letter C
                  child: AnimatedOpacity(
                    opacity: showLetter ? 1 : 0,

                    duration:
                    const Duration(milliseconds: 500),

                    child: const Text(
                      "C",

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 55,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),


            const SizedBox(height: 25),


            // Charlie
            AnimatedOpacity(
              opacity: showName ? 1 : 0,

              duration:
              const Duration(milliseconds: 500),

              child: const Text(
                "Charlie",

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),


            const SizedBox(height: 10),


            // Slogan
            AnimatedOpacity(
              opacity: showSlogan ? 1 : 0,

              duration:
              const Duration(milliseconds: 500),

              child: const Text(
                "be in charge of your finances",

                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}