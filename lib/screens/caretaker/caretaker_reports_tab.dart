import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CaretakerReportsTab extends StatelessWidget {
  final String patientId;
  const CaretakerReportsTab({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('patientId', isEqualTo: patientId)
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
                Icon(Icons.description_outlined,
                    size: 60, color: Color(0xFFB4B2A9)),
                SizedBox(height: 12),
                Text('No reports from the doctor yet.',
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
            final ts = data['createdAt'] as Timestamp?;
            final date = ts != null
                ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                : '';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFECE8E3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(data['type'] ?? 'Report',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Text(date,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF888780))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(data['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF3D3D3A))),
                  if ((data['notes'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(data['notes'],
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF888780))),
                  ],
                  const SizedBox(height: 6),
                  Text('By Dr. ${data['doctorName'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF888780))),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
