import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CaretakerMedicationsTab extends StatelessWidget {
  final String patientId;
  const CaretakerMedicationsTab({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctor_medications')
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
                Icon(Icons.medication_outlined,
                    size: 60, color: Color(0xFFB4B2A9)),
                SizedBox(height: 12),
                Text('No medications prescribed yet.',
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
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFECE8E3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication_rounded,
                        color: Color(0xFF2E7D32), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15,
                                color: Color(0xFF3D3D3A))),
                        if ((data['dosage'] ?? '').toString().isNotEmpty)
                          Text(data['dosage'],
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF888780))),
                        const SizedBox(height: 4),
                        if ((data['frequency'] ?? '').toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(data['frequency'],
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w600)),
                          ),
                        if ((data['instructions'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(data['instructions'],
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888780),
                                  fontStyle: FontStyle.italic)),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Prescribed by Dr. ${data['doctorName'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF888780)),
                        ),
                      ],
                    ),
                  ),
                  // Read-only badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('View only',
                        style: TextStyle(
                            fontSize: 9, color: Color(0xFF888780))),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
