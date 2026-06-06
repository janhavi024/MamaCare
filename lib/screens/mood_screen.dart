import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  int? _todayMood;
  bool _saving = false;

  final moods = [
    {'emoji': '😢', 'label': 'Sad', 'score': 1},
    {'emoji': '😞', 'label': 'Low', 'score': 2},
    {'emoji': '😐', 'label': 'Okay', 'score': 3},
    {'emoji': '😊', 'label': 'Good', 'score': 4},
    {'emoji': '😄', 'label': 'Great', 'score': 5},
  ];

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _moodRef =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('moods');

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _saveMood() async {
    if (_todayMood == null) return;
    setState(() => _saving = true);
    await _moodRef.doc(_todayKey).set({
      'score': moods[_todayMood!]['score'],
      'emoji': moods[_todayMood!]['emoji'],
      'label': moods[_todayMood!]['label'],
      'date': _todayKey,
      'savedAt': FieldValue.serverTimestamp(),
    });
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mood saved!'), backgroundColor: Color(0xFFE8785A)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(title: const Text('Mood Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TodayMoodCard(
              moods: moods,
              selectedIndex: _todayMood,
              onSelect: (i) => setState(() => _todayMood = i),
              onSave: _saveMood,
              saving: _saving,
            ),
            const SizedBox(height: 20),
            const Text('Last 7 days',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF3D3D3A))),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _moodRef.limit(7).snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFE8785A)));
                }
                if (snap.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFECE8E3)),
                    ),
                    child: Center(
                      child: Text('Error loading history: ${snap.error}',
                          style: const TextStyle(color: Color(0xFF888780))),
                    ),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFECE8E3)),
                    ),
                    child: const Center(
                      child: Text('No mood history yet.\nStart tracking today!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF888780))),
                    ),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _MoodHistoryItem(data: data);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayMoodCard extends StatelessWidget {
  final List<Map<String, dynamic>> moods;
  final int? selectedIndex;
  final Function(int) onSelect;
  final VoidCallback onSave;
  final bool saving;

  const _TodayMoodCard({
    required this.moods,
    required this.selectedIndex,
    required this.onSelect,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE8E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How are you feeling today?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF3D3D3A))),
          const SizedBox(height: 4),
          const Text('Tap to log your mood',
              style: TextStyle(fontSize: 13, color: Color(0xFF888780))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(moods.length, (i) {
              final selected = selectedIndex == i;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFFEF3EE) : const Color(0xFFF5F3F0),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: selected ? const Color(0xFFE8785A) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(moods[i]['emoji'] as String,
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(moods[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected ? const Color(0xFFE8785A) : const Color(0xFF888780),
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        )),
                  ],
                ),
              );
            }),
          ),
          if (selectedIndex != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8785A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save today\'s mood'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoodHistoryItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MoodHistoryItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final score = data['score'] as int? ?? 3;
    final colors = {
      1: const Color(0xFFFCEBEB),
      2: const Color(0xFFFAEEDA),
      3: const Color(0xFFF1EFE8),
      4: const Color(0xFFEAF3DE),
      5: const Color(0xFFE1F5EE),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECE8E3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors[score] ?? const Color(0xFFF1EFE8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(data['emoji'] ?? '😐', style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['label'] ?? 'Okay',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3D3D3A))),
                Text(data['date'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF888780))),
              ],
            ),
          ),
          Row(
            children: List.generate(5, (i) => Icon(
              Icons.circle,
              size: 8,
              color: i < score ? const Color(0xFFE8785A) : const Color(0xFFECE8E3),
            )),
          ),
        ],
      ),
    );
  }
}
