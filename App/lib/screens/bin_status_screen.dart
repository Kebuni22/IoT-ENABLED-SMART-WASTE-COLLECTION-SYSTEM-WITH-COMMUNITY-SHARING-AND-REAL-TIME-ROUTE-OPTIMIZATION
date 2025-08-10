import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BinStatusScreen extends StatefulWidget {
  const BinStatusScreen({Key? key}) : super(key: key);

  @override
  State<BinStatusScreen> createState() => _BinStatusScreenState();
}

class _BinStatusScreenState extends State<BinStatusScreen> {
  final List<Map<String, dynamic>> _bins = [];
  final List<Map<String, dynamic>> _pendingBins = [];
  String? _homeNumber;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData().then((_) {
      _initializeExampleBins(); // Initialize bins after fetching home number
      _loadBins();
    });
  }

  void _initializeExampleBins() {
    // Ensure the home number is set before initializing bins
    final homeNumber = _homeNumber ?? 'UNKNOWN';
    _bins.addAll([
      {
        'id': 'BIN-$homeNumber-001',
        'location': 'Food Waste',
        'type': 'Food Waste',
        'capacity': 120,
        'fillLevel': 0.75,
        'lastEmptied': '2 days ago',
        'status': 'Normal',
      },
      {
        'id': 'BIN-$homeNumber-002',
        'location': 'Polythene & Plastic Waste',
        'type': 'Polythene & Plastic Waste',
        'capacity': 90,
        'fillLevel': 0.45,
        'lastEmptied': '3 days ago',
        'status': 'Normal',
      },
      {
        'id': 'BIN-$homeNumber-003',
        'location': 'Other Waste',
        'type': 'Other Waste',
        'capacity': 60,
        'fillLevel': 0.92,
        'lastEmptied': '5 days ago',
        'status': 'Almost Full',
      },
    ]);
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          setState(() {
            _homeNumber = userDoc.data()?['homeNumber']?.toString();
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _loadBins() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('binRequests')
              .where('userId', isEqualTo: user.uid)
              .get();

      setState(() {
        _pendingBins.clear();

        int pendingIndex = 1; // Start sequential numbering for pending bins
        for (var doc in querySnapshot.docs) {
          final binData = doc.data();
          if (binData['status'] == 'Pending') {
            binData['id'] =
                'BIN-${_homeNumber ?? 'UNKNOWN'}-${pendingIndex.toString().padLeft(3, '0')}';
            _pendingBins.add(binData);
            pendingIndex++;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bins: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bin Status'),
        backgroundColor: const Color.fromARGB(255, 187, 221, 188),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildOverviewTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddBinDialog();
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        tooltip: 'Add New Bin',
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      children: [
        _buildStatusSummary(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadBins,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Original 3 bin cards
                ..._bins.take(3).map((bin) => _buildBinCard(bin)).toList(),

                // Pending bins section (if any)
                if (_pendingBins.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      'Pending Bin Requests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  ..._pendingBins
                      .map((bin) => _buildPendingBinCard(bin))
                      .toList(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSummary() {
    int totalBins = _bins.length;
    int normalBins = _bins.where((bin) => bin['status'] == 'Normal').length;
    int warningBins =
        _bins.where((bin) => bin['status'] == 'Almost Full').length;
    int alertBins = _bins.where((bin) => bin['status'] == 'Full').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bin Status Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusIndicator('Total', totalBins, Colors.blue),
              _buildStatusIndicator('Normal', normalBins, Colors.green),
              _buildStatusIndicator('Warning', warningBins, Colors.orange),
              _buildStatusIndicator('Full', alertBins, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBinCard(Map<String, dynamic> bin) {
    Color statusColor;
    if (bin['status'] == 'Normal') {
      statusColor = Colors.green;
    } else if (bin['status'] == 'Almost Full') {
      statusColor = Colors.orange;
    } else if (bin['status'] == 'Inactive') {
      statusColor = Colors.grey;
    } else {
      statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bin['location'] ?? 'No Location',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${bin['id']} • ${bin['type']}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    bin['status'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: _buildFillLevelIndicator(bin['fillLevel'] ?? 0.0),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Capacity',
                        '${bin['capacity'] ?? 'N/A'} liters',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Fill Level',
                        '${((bin['fillLevel'] ?? 0.0) * 100).toInt()}%',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Last Emptied',
                        bin['lastEmptied'] ?? 'Never',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showBinDetailsDialog(bin),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Details'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showRequestEmptyingDialog(bin),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Request Emptying'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBinCard(Map<String, dynamic> bin) {
    return Opacity(
      opacity: 0.6,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bin['location'] ?? 'No Location',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${bin['id']} • ${bin['type']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: _buildFillLevelIndicator(0.0),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          'Capacity',
                          '${bin['capacity'] ?? 'N/A'} liters',
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow('Status', 'Waiting for approval'),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          'Requested On',
                          bin['createdAt'] != null
                              ? '${(bin['createdAt'] as Timestamp).toDate().toString().substring(0, 10)}'
                              : 'Unknown',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showPendingBinDetailsDialog(bin),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFillLevelIndicator(double fillLevel) {
    return CustomPaint(
      painter: _FillLevelPainter(
        fillLevel: fillLevel,
        fillColor: _getFillLevelColor(fillLevel),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(fillLevel * 100).toInt()}%',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _getFillLevelColor(fillLevel),
              ),
            ),
            const Text(
              'Full',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFillLevelColor(double fillLevel) {
    if (fillLevel < 0.5) {
      return Colors.green;
    } else if (fillLevel < 0.8) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  void _showBinDetailsDialog(Map<String, dynamic> bin) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Bin Details: ${bin['id']}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailItem('ID', bin['id'] ?? 'N/A'),
                  _buildDetailItem('Location', bin['location'] ?? 'N/A'),
                  _buildDetailItem('Type', bin['type'] ?? 'N/A'),
                  _buildDetailItem(
                    'Capacity',
                    '${bin['capacity'] ?? 'N/A'} liters',
                  ),
                  _buildDetailItem(
                    'Fill Level',
                    '${((bin['fillLevel'] ?? 0.0) * 100).toInt()}%',
                  ),
                  _buildDetailItem('Status', bin['status'] ?? 'Unknown'),
                  _buildDetailItem(
                    'Last Emptied',
                    bin['lastEmptied'] ?? 'Never',
                  ),
                  _buildDetailItem('Installation Date', '10 Jan 2023'),
                  _buildDetailItem('Waste Type', bin['type'] ?? 'N/A'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showRequestEmptyingDialog(bin);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Request Emptying'),
              ),
            ],
          ),
    );
  }

  void _showPendingBinDetailsDialog(Map<String, dynamic> bin) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Pending Bin: ${bin['id']}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailItem('ID', bin['id'] ?? 'N/A'),
                  _buildDetailItem('Location', bin['location'] ?? 'N/A'),
                  _buildDetailItem('Type', bin['type'] ?? 'N/A'),
                  _buildDetailItem(
                    'Capacity',
                    '${bin['capacity'] ?? 'N/A'} liters',
                  ),
                  _buildDetailItem('Status', 'Pending Approval'),
                  _buildDetailItem(
                    'Requested On',
                    bin['createdAt'] != null
                        ? '${(bin['createdAt'] as Timestamp).toDate().toString().substring(0, 10)}'
                        : 'Unknown',
                  ),
                  _buildDetailItem('Reason', bin['reason'] ?? 'Not specified'),
                ],
              ),
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

  void _showRequestEmptyingDialog(Map<String, dynamic> bin) {
    final TextEditingController noteController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Request Bin Emptying'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bin ID: ${bin['id']}'),
                      Text('Location: ${bin['location']}'),
                      Text('Type: ${bin['type']}'),
                      const SizedBox(height: 16),
                      const Text('Select preferred date:'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 14),
                            ),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Preferred Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            selectedDate != null
                                ? '${selectedDate!.toLocal()}'.split(' ')[0]
                                : 'Select Date',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Any special instructions?'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          hintText: 'E.g., Please empty before 9 AM',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a date'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            throw Exception('User not logged in');
                          }

                          // Prepare request data
                          final requestData = {
                            'binId': bin['id'],
                            'type': bin['type'],
                            'date': selectedDate,
                            'note': noteController.text.trim(),
                            'userId': user.uid,
                            'createdAt': FieldValue.serverTimestamp(),
                          };

                          // Save request to Firestore
                          await FirebaseFirestore.instance
                              .collection('emptyingRequests')
                              .add(requestData);

                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Emptying request submitted successfully',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error submitting request: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Submit Request'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showAddBinDialog() {
    final TextEditingController locationController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    String selectedType = 'Food Waste';
    String selectedCapacity = '120 liters';
    String selectedLocation = 'Front Yard';
    bool wantBinImmediately = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Request New Bin'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedLocation,
                        items: const [
                          DropdownMenuItem(
                            value: 'Front Yard',
                            child: Text('Front Yard'),
                          ),
                          DropdownMenuItem(
                            value: 'Back Yard',
                            child: Text('Back Yard'),
                          ),
                          DropdownMenuItem(
                            value: 'Garage',
                            child: Text('Garage'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other (Type Below)'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedLocation = value!;
                            if (value != 'Other') {
                              locationController.clear();
                            }
                          });
                        },
                      ),
                      if (selectedLocation == 'Other')
                        const SizedBox(height: 8),
                      if (selectedLocation == 'Other')
                        TextField(
                          controller: locationController,
                          decoration: const InputDecoration(
                            labelText: 'Specify Location',
                            hintText: 'e.g., Rooftop',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Bin Type',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedType,
                        items: const [
                          DropdownMenuItem(
                            value: 'Food Waste',
                            child: Text('Food Waste'),
                          ),
                          DropdownMenuItem(
                            value: 'Polythene & Plastic Waste',
                            child: Text('Polythene & Plastic Waste'),
                          ),
                          DropdownMenuItem(
                            value: 'E-Waste',
                            child: Text('E-Waste'),
                          ),
                          DropdownMenuItem(
                            value: 'Glass',
                            child: Text('Glass'),
                          ),
                          DropdownMenuItem(
                            value: 'Other Waste',
                            child: Text('Other Waste'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Capacity',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedCapacity,
                        items: const [
                          DropdownMenuItem(
                            value: '30 liters',
                            child: Text('30 liters'),
                          ),
                          DropdownMenuItem(
                            value: '60 liters',
                            child: Text('60 liters'),
                          ),
                          DropdownMenuItem(
                            value: '90 liters',
                            child: Text('90 liters'),
                          ),
                          DropdownMenuItem(
                            value: '120 liters',
                            child: Text('120 liters'),
                          ),
                          DropdownMenuItem(
                            value: '240 liters',
                            child: Text('240 liters'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCapacity = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Request',
                          hintText: 'Why do you need this bin?',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: wantBinImmediately,
                            onChanged: (value) {
                              setState(() {
                                wantBinImmediately = value!;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'Want Bin Immediately',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedLocation == 'Other' &&
                          locationController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please specify a location'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          throw Exception('User not logged in');
                        }

                        // Generate unique bin ID without slashes
                        final binCount = _bins.length + _pendingBins.length + 1;
                        final binId =
                            'BIN-${_homeNumber?.replaceAll('/', '-')}-${binCount.toString().padLeft(3, '0')}';

                        // Prepare bin data
                        final binData = {
                          'id': binId,
                          'userId': user.uid,
                          'location':
                              selectedLocation == 'Other'
                                  ? locationController.text.trim()
                                  : selectedLocation,
                          'type': selectedType,
                          'capacity': int.parse(selectedCapacity.split(' ')[0]),
                          'reason': noteController.text.trim(),
                          'wantImmediately': wantBinImmediately,
                          'fillLevel': 0.0,
                          'lastEmptied': 'Never',
                          'status': 'Pending',
                          'createdAt': FieldValue.serverTimestamp(),
                        };

                        // Save bin data to Firestore
                        await FirebaseFirestore.instance
                            .collection('binRequests')
                            .doc(binId)
                            .set(binData);

                        // Refresh the pending bins list
                        await _loadBins();

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'New bin request submitted successfully',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error submitting request: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Submit Request'),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _FillLevelPainter extends CustomPainter {
  final double fillLevel;
  final Color fillColor;

  _FillLevelPainter({required this.fillLevel, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintOutline =
        Paint()
          ..color = Colors.grey.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10.0;

    final paintFill =
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    canvas.drawCircle(center, radius, paintOutline);

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fillLevel,
      false,
      paintFill,
    );
  }

  @override
  bool shouldRepaint(_FillLevelPainter oldDelegate) =>
      oldDelegate.fillLevel != fillLevel || oldDelegate.fillColor != fillColor;
}
