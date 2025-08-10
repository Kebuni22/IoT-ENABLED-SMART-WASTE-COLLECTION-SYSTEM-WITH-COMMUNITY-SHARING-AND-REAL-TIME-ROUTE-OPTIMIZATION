import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final user = userCredential.user;
      if (user != null) {
        // Check the user's position in Firestore
        final DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final String? position = data['position'];

          // Restrict access if the user has any position field
          if (position != null && position.isNotEmpty) {
            await _auth.signOut(); // Sign the user out
            _showErrorSnackBar('Access denied. Your account is restricted.');
            return;
          }
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DashboardPage(
                    userName: user.email?.split('@')[0] ?? 'User',
                    showLoginMessage: true,
                  ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      _showErrorSnackBar(message);
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 220, 233, 223), Color(0xFFD4F1D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo or Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.teal, Colors.green],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Clea~Ro',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                            shadows: [
                              Shadow(
                                color: Colors.green,
                                blurRadius: 5,
                                offset: Offset(1, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Welcome!  Start Smart, Stay Clean...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.green,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.green,
                            width: 2,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock, color: Colors.green),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.green,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          if (_emailController.text.trim().isEmpty) {
                            _showErrorSnackBar(
                              'Please enter your email to reset your password',
                            );
                            return;
                          }
                          _auth.sendPasswordResetEmail(
                            email: _emailController.text.trim(),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Password reset email sent. Check your inbox.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.teal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.teal),
                        )
                        : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    const SizedBox(height: 24),

                    // Sign Up Redirect
                    OutlinedButton(
                      onPressed: _navigateToSignup,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create New Account',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Terms of Service and Privacy Policy
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text(
                                  'Terms of Service & Privacy Policy',
                                ),
                                content: const SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '🌟 Terms of Service\n',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Welcome to Clearo!\n\n'
                                        'Clearo is dedicated to turning waste into worth by offering smart, sustainable, and community-driven waste collection solutions. '
                                        'With a focus on technology and togetherness, we aim to build a cleaner and greener Sri Lanka.\n\n'
                                        '🚀 What Clearo Offers:\n'
                                        '• 🛻 Real-time waste truck and bin tracking\n'
                                        '• 📅 Immediate waste pickup scheduling\n'
                                        '• 📍 Optimized waste collection route planning\n'
                                        '• 🔁 Share reusable items with the community\n'
                                        '• 📷 Upload photos & descriptions of reusable goods\n'
                                        '• 📊 Track your environmental contributions\n'
                                        '• 🧠 Waste segregation guidance\n'
                                        '• 🧾 Smart mapping and reporting features\n'
                                        '• 🚨 Citizen reporting for illegal dumping or bin issues\n'
                                        '• 📢 Community cleanup event notifications\n'
                                        '• 🦟 Dengue awareness updates in your area\n'
                                        '• 🌐 Multilingual support for inclusive access\n'
                                        '• 💬 Community feedback and suggestion hub\n\n'
                                        '❤️ Why We Built Clearo:\n'
                                        'Sri Lanka faces rising challenges in managing urban and suburban waste effectively. Overflowing bins, unoptimized truck routes, lack of community awareness, and communication gaps between citizens and municipalities contribute to environmental and health issues.\n\n'
                                        'We chose to build Clearo because we believe:\n'
                                        '• Technology can simplify complex waste collection processes\n'
                                        '• Communities play a key role in responsible disposal\n'
                                        '• Everyone deserves access to clean surroundings\n'
                                        '• Reusability and sustainability should be encouraged\n'
                                        '• Real-time visibility leads to better decision-making\n\n'
                                        '🌱 Your Impact as a Clearo User:\n'
                                        'By using Clearo, you’re helping to:\n'
                                        '• Keep your neighborhood clean\n'
                                        '• Promote reuse over discard\n'
                                        '• Optimize collection efforts and reduce pollution\n'
                                        '• Raise awareness of proper waste segregation\n'
                                        '• Prevent mosquito-borne diseases like dengue\n'
                                        '• Build a smarter and greener Sri Lanka, together\n\n'
                                        '💡 Did you know?\n'
                                        'Your contributions and participation are recorded in the app so you can **track your positive impact on the environment** and receive **recognition** for your efforts!\n\n'
                                        '🔎 Need Help?\n'
                                        'Visit our website or reach out to our support team—we\'re here to help!\n\n'
                                        '🌟 Let’s revolutionize waste collection—one bin, one truck, one smart action at a time.\n\n'
                                        '💚 Thank you for being a part of Clearo.\n\n',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 18),
                                      Text(
                                        '🔒 Privacy Policy\n',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'At Clearo, we value your privacy and are committed to protecting your personal information. '
                                        'This Privacy Policy outlines how we collect, use, and safeguard your data:\n\n'
                                        '1. Data Collection:\n'
                                        '   - We collect your email, name, and location to provide personalized services.\n'
                                        '   - Usage data is collected to improve app performance and user experience.\n\n'
                                        '2. Data Usage:\n'
                                        '   - Your data is used for scheduling pickups, tracking contributions, and sending notifications.\n'
                                        '   - We do not sell or share your data with third parties without your consent.\n\n'
                                        '3. Data Security:\n'
                                        '   - We implement robust security measures to protect your data from unauthorized access.\n\n'
                                        '4. Your Rights:\n'
                                        '   - You can request access to your data or ask for its deletion at any time.\n\n'
                                        'For more details, please visit our website or contact our support team.\n\n'
                                        '💚 Thank you for trusting Clearo to manage your waste responsibly!',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                        );
                      },
                      child: const Text(
                        'By signing in, you agree to our Terms of Service and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color.fromARGB(255, 143, 160, 174),
                          fontStyle: FontStyle.italic,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
