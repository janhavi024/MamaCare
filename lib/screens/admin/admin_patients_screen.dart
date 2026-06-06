import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPatientsScreen extends StatefulWidget {
  const AdminPatientsScreen({super.key});

  @override
  State<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends State<AdminPatientsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        title: const Text('All Patients'),
        backgroundColor: const Color(0xFF6C3483),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Approved'),
            Tab(text: 'Pending'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PatientList(status: 'approved'),
          _PatientList(status: 'pending'),
          _PatientList(status: 'rejected'),
        ],
      ),
    );
  }
}

class _PatientList extends StatelessWidget {
  final String status;

  const _PatientList({required this.status});

  Future<void> _updateStatus(
      BuildContext context, String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update({'approvalStatus': newStatus});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('approvalStatus', isEqualTo: status)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF6C3483)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_outlined,
                    size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No $status patients',
                    style: const TextStyle(color: Color(0xFF888780))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _PatientListCard(
              docId: doc.id,
              data: data,
              currentStatus: status,
              onStatusChange: (newStatus) =>
                  _updateStatus(context, doc.id, newStatus),
            );
          },
        );
      },
    );
  }
}

class _PatientListCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String currentStatus;
  final ValueChanged<String> onStatusChange;

  const _PatientListCard({
    required this.docId,
    required this.data,
    required this.currentStatus,
    required this.onStatusChange,
  });

  Color get _statusColor {
    switch (currentStatus) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return const Color(0xFF856404);
    }
  }

  Color get _statusBg {
    switch (currentStatus) {
      case 'approved':
        return const Color(0xFFEAF3DE);
      case 'rejected':
        return const Color(0xFFFCEBEB);
      default:
        return const Color(0xFFFFF3CD);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? '';
    final dueDate = data['dueDate'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE8E3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFBEAF0),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'P',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8785A),
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF3D3D3A))),
                Text(email,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888780))),
                if (dueDate != null)
                  Text(
                    'Due: ${_formatDate(dueDate.toDate())}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFE8785A)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(currentStatus,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _statusColor)),
              ),
              const SizedBox(height: 6),
              if (currentStatus != 'approved')
                GestureDetector(
                  onTap: () => onStatusChange('approved'),
                  child: const Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 22),
                ),
              if (currentStatus != 'rejected')
                GestureDetector(
                  onTap: () => onStatusChange('rejected'),
                  child: const Icon(Icons.cancel_outlined,
                      color: Colors.red, size: 22),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
