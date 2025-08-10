import 'package:clearo/screens/user_account_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong.')),
          );
        } else if (snapshot.hasData) {
          final User user = snapshot.data!;
          return DashboardPage(userName: user.displayName ?? 'User');
        } else {
          return const SignupPage();
        }
      },
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _homeNumberController = TextEditingController(); // Home number field
  final _addressController = TextEditingController(); // Address field
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final User user = userCredential.user!;
      await user.updateDisplayName(_nameController.text.trim());

      // Store user details in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'homeNumber': _homeNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'uid': user.uid, // Store user ID for reference
      });

      // Automatically create 3 bins for the user
      final homeNumber = _homeNumberController.text.trim();
      for (int i = 1; i <= 3; i++) {
        final binName = "BIN-$homeNumber-${i.toString().padLeft(3, '0')}";
        await FirebaseFirestore.instance.collection('bins').add({
          'binId': binName,
          'userId': user.uid,
          'homeNumber': homeNumber,
          'status': 'Available',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    DashboardPage(userName: _nameController.text.trim()),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      String message = 'An error occurred.';
      if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for this email.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _homeNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 216, 232, 219), Color(0xFFD4F1D8)],
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
                      'Create Your Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: const Icon(
                          Icons.person,
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
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
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        prefixIcon: const Icon(Icons.lock, color: Colors.green),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
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
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Home Number Field
                    TextFormField(
                      controller: _homeNumberController,
                      decoration: InputDecoration(
                        labelText: 'Home Number',
                        hintText: 'Enter your home number',
                        prefixIcon: const Icon(Icons.home, color: Colors.green),
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
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your home number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        hintText: 'Enter your address',
                        prefixIcon: const Icon(
                          Icons.location_on,
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Button
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : ElevatedButton(
                          onPressed: _registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    const SizedBox(height: 16),

                    // Terms of Service and Privacy Policy
                    GestureDetector(
                      onTap: () {
                        bool _isAgreed = false; // Track checkbox state
                        showDialog(
                          context: context,
                          builder:
                              (context) => StatefulBuilder(
                                builder:
                                    (context, setState) => AlertDialog(
                                      title: const Text(
                                        'Terms of Service & Privacy Policy',
                                      ),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '🌟 Terms of Service\n',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const Text(
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
                                            const SizedBox(height: 18),
                                            const Text(
                                              '🔒 Privacy Policy\n',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const Text(
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
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Checkbox(
                                                  value: _isAgreed,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _isAgreed =
                                                          value ?? false;
                                                    });
                                                  },
                                                ),
                                                const Expanded(
                                                  child: Text(
                                                    'I agree to the Terms of Service and Privacy Policy.',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              _isAgreed
                                                  ? () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop()
                                                  : null,
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                              ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.teal,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Terms of Service & Privacy Policy',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color.fromARGB(255, 143, 160, 174),
                              fontStyle: FontStyle.italic,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Login Redirect
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Already have an account? Login',
                        style: TextStyle(
                          color: Color.fromARGB(255, 165, 166, 164),
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
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserAccountScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: const Center(child: Text('Welcome!')),
    );
  }
}
