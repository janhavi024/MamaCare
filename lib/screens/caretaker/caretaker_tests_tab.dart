import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CaretakerTestsTab extends StatelessWidget {
  final String patientId;
  const CaretakerTestsTab({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('tests')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
        }
        if (snap.hasError) {
          return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Color(0xFF888780))));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_outlined,
                    size: 60, color: Color(0xFFB4B2A9)),
                SizedBox(height: 12),
                Text('No tests scheduled yet.',
                    style: TextStyle(color: Color(0xFF888780))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final ts = data['date'] as Timestamp?;
            final date = ts != null
                ? DateFormat('EEE, d MMM yyyy').format(ts.toDate())
                : 'Date unknown';
            final done = data['done'] == true;
            final isPast = ts != null && ts.toDate().isBefore(DateTime.now());

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: done
                      ? const Color(0xFFA5D6A7)
                      : const Color(0xFFECE8E3),
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: done
                        ? const Color(0xFFE8F5E9)
                        : isPast
                            ? const Color(0xFFFCEBEB)
                            : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    done
                        ? Icons.check_circle_rounded
                        : isPast
                            ? Icons.warning_amber_rounded
                            : Icons.calendar_today_outlined,
                    color: done
                        ? const Color(0xFF2E7D32)
                        : isPast
                            ? const Color(0xFFA32D2D)
                            : const Color(0xFF2E7D32),
                    size: 20,
                  ),
                ),
                title: Text(
                  data['name'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D3D3A),
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPast && !done
                        ? const Color(0xFFA32D2D)
                        : const Color(0xFF888780),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: done
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F3F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    done ? 'Done' : 'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: done
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF888780),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
