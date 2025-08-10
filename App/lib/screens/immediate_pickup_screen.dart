import 'package:clearo/screens/chat_admin_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io'; // Add this import for File class
import 'package:image_picker/image_picker.dart'; // Add this import for image picking
import 'package:clearo/screens/truck_tracking_screen.dart'; // Import TruckTrackingScreen
import 'package:firebase_storage/firebase_storage.dart'; // Add this import for Firebase Storage
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import for Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Add this import for Firebase Auth
// Removed incorrect import statement

class ImmediatePickupScreen extends StatefulWidget {
  const ImmediatePickupScreen({Key? key}) : super(key: key);

  @override
  State<ImmediatePickupScreen> createState() => _ImmediatePickupScreenState();
}

class _ImmediatePickupScreenState extends State<ImmediatePickupScreen> {
  bool _isRequestView = true;
  int _currentStep = 0;
  String? selectedBin;
  String? paymentStatus;
  String? pickupTime;
  final TextEditingController _instructionsController = TextEditingController();

  // Modern color palette
  final Color _primaryColor = const Color(0xFF8FD3A9);
  final Color _secondaryColor = const Color(0xFFC5E8B7);
  final Color _accentColor = const Color(0xFF6AC47A);
  final Color _darkColor = const Color(0xFF4A7856);
  final Color _lightColor = const Color(0xFFF0F7F4);
  final Color _errorColor = const Color(0xFFFF6B6B);

  final List<Map<String, String>> _pickupHistory = [
    {'bin': 'BIN-1001', 'time': '9:00 AM', 'date': 'Today'},
    {'bin': 'BIN-1002', 'time': '12:00 PM', 'date': 'Yesterday'},
  ];

  List<Map<String, dynamic>> _userBins = []; // Store user bins

  Future<void> _fetchUserBins() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user's home number from Firestore
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final homeNumber = userDoc.data()?['homeNumber'];
      if (homeNumber == null) {
        throw Exception('Home number not found for the user.');
      }

      // Fetch bins associated with the user's home number
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('bins')
              .where('homeNumber', isEqualTo: homeNumber)
              .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No bins found for the user\'s home number.');
      }

      setState(() {
        _userBins =
            querySnapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'binId': data['binId'], // Use binId directly from the database
                'status': data['status'] ?? 'Available',
              };
            }).toList();
      });
    } catch (e) {
      _showErrorDialog('Error fetching bins: $e');
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && selectedBin == null) {
      _showErrorDialog('Please select a bin.');
      return;
    }
    if (_currentStep == 1 && paymentStatus != 'Paid') {
      _showErrorDialog('Please complete the payment.');
      return;
    }
    if (_currentStep == 2 && pickupTime == null) {
      _showErrorDialog('Please select a pickup time.');
      return;
    }
    setState(() {
      if (_currentStep < 3) {
        _currentStep++;
      } else {
        _savePickupDetails();
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: _errorColor),
                  const SizedBox(height: 16),
                  Text(
                    'Oops!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _errorColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _errorColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('UNDERSTOOD'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _savePickupDetails() async {
    if (selectedBin == null || pickupTime == null || paymentStatus != 'Paid') {
      _showErrorDialog('Please complete all steps before confirming.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('User not authenticated. Please log in again.');
      return;
    }

    setState(() => _isRequestView = false);

    try {
      // Get the current date
      final currentDate = DateTime.now().toLocal().toString().split(' ')[0];

      // Save pickup details to Firestore
      final pickupData = {
        'userId': user.uid, // Ensure the user ID is stored
        'bin': selectedBin,
        'pickupTime': pickupTime,
        'pickupDate': currentDate, // Add the current date
        'instructions': _instructionsController.text.trim(),
        'status': 'Pending', // Default status for new pickups
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Ensure the collection name is correct
      await FirebaseFirestore.instance
          .collection('immediate_pickups') // Check this collection name
          .add(pickupData);

      // Show success message and reset the form
      _showSnackBar('Pickup request saved successfully!');
      _resetPickupForm();

      // Refresh the history view
      setState(() {
        _isRequestView = false;
      });
    } catch (e) {
      _showErrorDialog('Error saving pickup details: $e');
    }
  }

  void _resetPickupForm() {
    setState(() {
      _currentStep = 0;
      selectedBin = null;
      paymentStatus = null;
      pickupTime = null;
      _instructionsController.clear();
      _isRequestView = true;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchPickupHistory() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('immediate_pickups')
              .orderBy('timestamp', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id, // Ensure the pickup has an 'id' field
          'bin': data['bin'] ?? '--',
          'pickupTime': data['pickupTime'] ?? '--',
          'pickupDate':
              data['timestamp']?.toDate().toLocal().toString().split(' ')[0] ??
              '--',
          'status': data['status'] ?? 'Pending',
          'instructions': data['instructions'] ?? '',
        };
      }).toList();
    } catch (e) {
      _showErrorDialog('Error fetching pickup history: $e');
      return [];
    }
  }

  Widget _buildRequestSteps() {
    return Column(
      children: [
        // Modern step indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              bool isActive = index <= _currentStep;
              bool isCompleted = index < _currentStep;
              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive ? _primaryColor : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child:
                          isCompleted
                              ? Icon(Icons.check, color: Colors.white, size: 20)
                              : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ['Select', 'Payment', 'Time', 'Confirm'][index],
                    style: TextStyle(
                      color: isActive ? _darkColor : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStepContent(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _previousStep,
                    child: Text('BACK', style: TextStyle(color: _primaryColor)),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _nextStep,
                  child: Text(
                    _currentStep == 3 ? 'CONFIRM PICKUP' : 'CONTINUE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _lightColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, size: 60, color: _accentColor),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Pickup Scheduled!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _darkColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            icon: Icons.delete,
            title: 'Bin ID',
            value: selectedBin ?? '--',
          ),
          _buildDetailCard(
            icon: Icons.access_time,
            title: 'Pickup Time',
            value: pickupTime ?? '--',
          ),
          if (_instructionsController.text.isNotEmpty)
            _buildDetailCard(
              icon: Icons.note,
              title: 'Instructions',
              value: _instructionsController.text,
            ),
          const SizedBox(height: 24),
          Text(
            'Recent Pickups',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _darkColor,
            ),
          ),
          const SizedBox(height: 8),
          ..._pickupHistory.map((pickup) => _buildHistoryItem(pickup)).toList(),
          const SizedBox(height: 24),
          Text(
            'Need Help?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _lightColor,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chat, color: _primaryColor),
                  ),
                  title: Text(
                    'Chat with Admin',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _darkColor,
                    ),
                  ),
                  subtitle: const Text('Get instant support'),
                  trailing: Icon(Icons.chevron_right, color: _primaryColor),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatAdminScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.history, color: _primaryColor),
                  ),
                  title: Text(
                    'Track Pickup',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _darkColor,
                    ),
                  ),
                  subtitle: const Text('View real-time status'),
                  trailing: Icon(Icons.chevron_right, color: _primaryColor),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TruckTrackingScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _currentStep = 0;
                  selectedBin = null;
                  paymentStatus = null;
                  pickupTime = null;
                  _instructionsController.clear();
                  _isRequestView = true;
                });
              },
              child: const Text(
                'REQUEST ANOTHER PICKUP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _darkColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> pickup) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Bin ID', pickup['bin']),
            _buildDetailRow('Pickup Time', pickup['pickupTime']),
            _buildDetailRow('Pickup Date', pickup['pickupDate']),
            _buildDetailRow('Status', pickup['status']),
            if (pickup['instructions'].isNotEmpty)
              _buildDetailRow('Instructions', pickup['instructions']),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editPickup(pickup),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  label: const Text(
                    'Edit',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deletePickup(pickup),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editPickup(Map<String, dynamic> pickup) {
    // Populate the form with the selected pickup details for editing
    setState(() {
      selectedBin = pickup['bin'];
      pickupTime = pickup['pickupTime'];
      _instructionsController.text = pickup['instructions'] ?? '';
      _currentStep = 0; // Navigate back to the first step
      _isRequestView = true; // Switch to the request view
    });
  }

  Future<void> _deletePickup(Map<String, dynamic> pickup) async {
    try {
      // Confirm deletion
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Delete Pickup'),
              content: const Text(
                'Are you sure you want to delete this pickup?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
      );

      if (confirm != true) return;

      // Delete the pickup from Firestore
      await FirebaseFirestore.instance
          .collection('immediate_pickups')
          .doc(pickup['id']) // Ensure the pickup has an 'id' field
          .delete();

      // Refresh the history view
      setState(() {});

      _showSnackBar('Pickup deleted successfully!');
    } catch (e) {
      _showErrorDialog('Error deleting pickup: $e');
    }
  }

  Widget _buildHistoryView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPickupHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: GestureDetector(
              onTap: () => setState(() {}), // Refresh the history
              child: Text(
                'No pickup history available. Tap to refresh.',
                style: TextStyle(
                  color: _darkColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: snapshot.data!.map(_buildHistoryItem).toList(),
        );
      },
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBinSelectionStep();
      case 1:
        return _buildPaymentStep();
      case 2:
        return _buildTimeSelectionStep();
      case 3:
        return _buildConfirmationStep();
      default:
        return Container();
    }
  }

  Widget _buildBinSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Bin',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _darkColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which bin needs pickup',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: _lightColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Available Bins',
                  labelStyle: TextStyle(color: _darkColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.search, color: _primaryColor),
                ),
                items:
                    _userBins.map((bin) {
                      return DropdownMenuItem<String>(
                        value: bin['binId'],
                        child: Text('${bin['binId']} (${bin['status']})'),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBin = value;
                  });
                },
                style: TextStyle(color: _darkColor),
              ),
              if (_userBins.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'No bins available. Please add bins to your account.',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Special Instructions (Optional)',
                  labelStyle: TextStyle(color: _darkColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _darkColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Secure payment for your pickup',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: _lightColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.credit_card, color: _primaryColor),
                ),
                title: Text(
                  'Credit/Debit Card',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _darkColor,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: _primaryColor),
                onTap: () {
                  setState(() {
                    paymentStatus = 'Paid';
                  });
                },
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.money, color: _primaryColor),
                ),
                title: Text(
                  'Cash on Pickup',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _darkColor,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: _primaryColor),
                onTap: () {
                  setState(() {
                    paymentStatus = 'Paid';
                  });
                },
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: _primaryColor,
                  ),
                ),
                title: Text(
                  'Wallet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _darkColor,
                  ),
                ),
                subtitle: const Text('Balance: \Rs.1500.00'),
                trailing: Icon(Icons.chevron_right, color: _primaryColor),
                onTap: () {
                  setState(() {
                    paymentStatus = 'Paid';
                  });
                },
              ),
              if (paymentStatus == 'Paid') ...[
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: _accentColor),
                      const SizedBox(width: 12),
                      Text(
                        'Payment Successful',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'A charge of \Rs.480.00 will be applied for immediate pickup.',
          style: TextStyle(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTimeSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pickup Time',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _darkColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a convenient time slot',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: _lightColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTimeSlotOption('9:00 AM - 11:00 AM'),
              const Divider(height: 24),
              _buildTimeSlotOption('1:00 PM - 3:00 PM'),
              const Divider(height: 24),
              _buildTimeSlotOption('4:00 PM - 6:00 PM'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotOption(String time) {
    bool isSelected = pickupTime == time;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : _primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.access_time,
          color: isSelected ? Colors.white : _primaryColor,
        ),
      ),
      title: Text(
        time,
        style: TextStyle(fontWeight: FontWeight.bold, color: _darkColor),
      ),
      trailing:
          isSelected ? Icon(Icons.check_circle, color: _accentColor) : null,
      onTap: () {
        setState(() {
          pickupTime = time;
        });
      },
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _darkColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your pickup information',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: _lightColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildConfirmationItem(
                icon: Icons.delete,
                title: 'Bin ID',
                value: selectedBin ?? '--',
              ),
              const Divider(height: 24),
              _buildConfirmationItem(
                icon: Icons.access_time,
                title: 'Pickup Time',
                value: pickupTime ?? '--',
              ),
              if (_instructionsController.text.isNotEmpty) ...[
                const Divider(height: 24),
                _buildConfirmationItem(
                  icon: Icons.note,
                  title: 'Instructions',
                  value: _instructionsController.text,
                ),
              ],
              const Divider(height: 24),
              _buildConfirmationItem(
                icon: Icons.payment,
                title: 'Payment',
                value: '\Rs.480.00 (Completed)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: _accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your pickup will arrive within the selected time window.',
                  style: TextStyle(color: _darkColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _darkColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPickupDetailsDialog(Map<String, dynamic> pickup) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Pickup Details: ${pickup['bin']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Bin ID', pickup['bin']!),
                _buildDetailRow('Pickup Time', pickup['pickupTime']!),
                _buildDetailRow('Pickup Date', pickup['timestamp']!),
                _buildDetailRow('Status', 'Completed'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$title:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _primaryColor),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUserBins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Immediate Pickup',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isRequestView ? Icons.history : Icons.add_circle_outline,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _isRequestView = !_isRequestView);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, _lightColor],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: _isRequestView ? _buildRequestSteps() : _buildHistoryView(),
      ),
    );
  }
}
