// lib/screens/sign_up_screen.dart

import 'package:flutter/material.dart';
import '../widgets/auth/sign_up_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              Icon(
                Icons.apartment,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 14),
              Text(
                'Join Us Today',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create an account to book your perfect stay',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const SignUpForm(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () {
                      // Navigate to SignIn screen
                      Navigator.pushReplacementNamed(context, '/signin');
                    },
                    child: const Text(
                      'Sign In',
                      style: TextStyle(color: Colors.blue), // Set text color to blue
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}