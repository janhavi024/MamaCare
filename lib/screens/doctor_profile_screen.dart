import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/doctor_provider.dart';
import 'login_screen.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF185FA5),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Provider.of<DoctorProvider>(context, listen: false).clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('doctors').doc(uid).get(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF185FA5)));
          }
          final data = snap.data?.data() as Map<String, dynamic>? ?? {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar & name
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: const Color(0xFFE6F1FB),
                        child: Text(
                          (data['name'] ?? 'D')[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF185FA5)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Dr. ${data['name'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D3D3A))),
                      const SizedBox(height: 4),
                      Text(data['specialization'] ?? '',
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF185FA5))),
                      if (data['hospital'] != null &&
                          data['hospital'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(data['hospital'],
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF888780))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _ProfileCard(
                  title: 'Professional Information',
                  icon: Icons.badge_outlined,
                  children: [
                    _ProfileRow('Qualification', data['qualification'] ?? '—'),
                    _ProfileRow('Experience',
                        '${data['yearsOfExperience'] ?? 0} years'),
                    _ProfileRow(
                        'Specialization', data['specialization'] ?? '—'),
                  ],
                ),
                const SizedBox(height: 14),

                _ProfileCard(
                  title: 'Contact',
                  icon: Icons.contact_mail_outlined,
                  children: [
                    _ProfileRow('Email', data['email'] ?? '—'),
                    _ProfileRow('Phone', data['phone'] ?? '—'),
                  ],
                ),

                if (data['bio'] != null &&
                    data['bio'].toString().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFECE8E3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Color(0xFF185FA5), size: 18),
                            SizedBox(width: 8),
                            Text('Bio',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3D3D3A))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(data['bio'],
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888780),
                                height: 1.5)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ProfileCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE8E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF185FA5), size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3D3D3A))),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label, value;
  const _ProfileRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF888780))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3D3D3A),
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
