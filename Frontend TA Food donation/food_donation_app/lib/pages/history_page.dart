import 'package:flutter/material.dart';
import '../services/food_service.dart';

class HistoryPage extends StatefulWidget {
  final String token;

  const HistoryPage({super.key, required this.token});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool showDonation = true;
  bool loading = true;

  List donations = [];
  List claims = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
  try {
    final data = await FoodService.getHistory(widget.token);

    setState(() {
      donations = data['myDonation'] ?? [];
      claims = data['myClaim'] ?? [];
      loading = false;
    });
  } catch (e) {
    setState(() {
      loading = false;
    });

    debugPrint('LOAD HISTORY ERROR: $e');
  }
}

  Color getStatusColor(String status, bool isDonation) {
    if (isDonation) {
      switch (status) {
        case 'CANCELED':
          return Colors.red;
        case 'PICKED_UP':
          return Colors.green;
        default:
          return Colors.orange;
      }
    } else {
      switch (status) {
        case 'CANCELED':
          return Colors.red;
        case 'PICKED_UP':
        case 'POSTED': // Completed partial claims return to POSTED but are finished for the claimer
          return Colors.green;
        case 'ON_THE_WAY':
        default:
          return Colors.orange;
      }
    }
  }

  String getStatusText(String status, bool isDonation) {
    if (isDonation) {
      switch (status) {
        case 'CANCELED':
          return 'Canceled';
        case 'PICKED_UP':
          return 'Claimed';
        default:
          return 'Posted';
      }
    } else {
      switch (status) {
        case 'CANCELED':
          return 'Canceled';
        case 'PICKED_UP':
        case 'POSTED':
          return 'Claimed';
        case 'ON_THE_WAY':
        default:
          return 'On The Way';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentData = showDonation ? donations : claims;

    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'History',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA8DDBB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                showDonation = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: showDonation
                                    ? const Color(0xFF0B6B3A)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'My Donation',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: showDonation
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                showDonation = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !showDonation
                                    ? const Color(0xFF0B6B3A)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'My Claim',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !showDonation
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: currentData.isEmpty
                        ? Center(
                            child: Text(
                              showDonation
                                  ? 'Belum ada history donation'
                                  : 'Belum ada history claim',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: currentData.length,
                            itemBuilder: (context, index) {
                              final item = currentData[index];

                              final status = (item['status'] ?? 'POSTED')
                                  .toString();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFA8DDBB),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item['photo_url'] ?? '',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.fastfood),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['food_name'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            showDonation
                                                ? 'Jumlah: ${item['quantity']}'
                                                : 'Jumlah: ${item['claimed_quantity']}',
                                          ),
                                          const SizedBox(height: 4),
                                          RichText(
                                            text: TextSpan(
                                              style: const TextStyle(
                                                color: Colors.black,
                                              ),
                                              children: [
                                                const TextSpan(
                                                  text: 'Status: ',
                                                ),
                                                TextSpan(
                                                  text: getStatusText(status, showDonation),
                                                  style: TextStyle(
                                                    color: getStatusColor(
                                                      status,
                                                      showDonation,
                                                    ),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
