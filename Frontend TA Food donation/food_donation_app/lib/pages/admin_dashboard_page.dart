import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminDashboardPage extends StatefulWidget {
  final String token;

  const AdminDashboardPage({super.key, required this.token});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await AdminService.getAllUsers(widget.token);
      if (response['success'] == true) {
        setState(() {
          users = response['data'];
          isLoading = false;
        });
      } else {
        _showError(response['message'] ?? 'Failed to load users');
      }
    } catch (e) {
      _showError('Error connecting to server');
    }
  }

  void _showError(String message) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _banUser(int userId, bool isCurrentlyBanned) async {
    try {
      final response = await AdminService.banUser(widget.token, userId);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isCurrentlyBanned
                  ? 'User unbanned successfully'
                  : 'User banned successfully'),
              backgroundColor: Colors.green),
        );
        _fetchUsers(); // Refresh data
      } else {
        _showError(response['message'] ?? 'Failed to update ban status');
      }
    } catch (e) {
      _showError('Error connecting to server');
    }
  }

  Future<void> _timeoutUser(int userId) async {
    TextEditingController hoursController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Timeout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter timeout duration in hours (0 to remove):'),
              const SizedBox(height: 10),
              TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Hours',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                int hours = int.tryParse(hoursController.text) ?? 0;
                try {
                  final response = await AdminService.timeoutUser(
                      widget.token, userId, hours);
                  if (response['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Timeout updated successfully'),
                          backgroundColor: Colors.green),
                    );
                    _fetchUsers();
                  } else {
                    _showError(response['message'] ?? 'Failed to update timeout');
                  }
                } catch (e) {
                  _showError('Error connecting to server');
                }
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0B6B3A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.resolveWith(
                          (states) => Colors.grey[200]),
                      columns: const [
                        DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Donations', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Claims', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: users.map((user) {
                        bool isBanned = user['isBanned'] == true;
                        bool isTimeout = user['timeoutUntil'] != null &&
                            DateTime.parse(user['timeoutUntil'])
                                .isAfter(DateTime.now());

                        String statusText = 'Active';
                        Color statusColor = Colors.green;

                        if (isBanned) {
                          statusText = 'Banned';
                          statusColor = Colors.red;
                        } else if (isTimeout) {
                          statusText = 'Timeout';
                          statusColor = Colors.orange;
                        }

                        return DataRow(cells: [
                          DataCell(Text(user['fullName'] ?? '-')),
                          DataCell(Text(user['email'] ?? '-')),
                          DataCell(Text(user['totalDonations']?.toString() ?? '0')),
                          DataCell(Text(user['totalClaims']?.toString() ?? '0')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                      isBanned ? Icons.restore : Icons.block,
                                      color: isBanned ? Colors.green : Colors.red),
                                  tooltip: isBanned ? 'Unban User' : 'Ban User',
                                  onPressed: () => _banUser(user['id'], isBanned),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.timer, color: Colors.orange),
                                  tooltip: 'Set Timeout',
                                  onPressed: () => _timeoutUser(user['id']),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
