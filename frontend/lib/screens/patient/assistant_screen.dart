import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

class _Msg {
  final String text;
  final bool user, urgent;
  _Msg(this.text, {this.user = false, this.urgent = false});
}

/// Rule-based pregnancy information assistant (backend). No external AI service, no diagnosis, no medication advice.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [
    _Msg('Hi! I can share general pregnancy information, such as common symptoms, tests, food and exercise, or tell you which week you are in. I can\'t diagnose anything or recommend medicines.'),
  ];
  bool _busy = false;

  Future<void> _send([String? preset]) async {
    final q = (preset ?? _input.text).trim();
    if (q.isEmpty || _busy) return;
    _input.clear();
    setState(() {
      _msgs.add(_Msg(q, user: true));
      _busy = true;
    });
    try {
      final r = await context.read<Services>().assistant.ask(q);
      setState(() => _msgs.add(_Msg('${r['answer']}', urgent: r['urgent'] == true)));
    } on ApiException catch (e) {
      setState(() => _msgs.add(_Msg('Sorry, I could not answer: ${e.message}')));
    } finally {
      if (mounted) setState(() => _busy = false);
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Column(children: [
          const Padding(padding: EdgeInsets.fromLTRB(20, 12, 20, 4), child: Align(alignment: Alignment.centerLeft, child: Text('Health information assistant', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)))),
          const Padding(padding: EdgeInsets.fromLTRB(20, 4, 20, 0), child: Disclaimer('General information only, not medical advice. For anything urgent, contact your doctor or emergency services.')),
          Expanded(
            child: ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), children: [
              for (final m in _msgs)
                Align(
                  alignment: m.user ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: m.user ? AppColors.lavenderDark : (m.urgent ? AppColors.danger.withValues(alpha: 0.12) : Colors.white),
                      border: m.urgent ? Border.all(color: AppColors.danger) : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(m.text, style: TextStyle(color: m.user ? Colors.white : AppColors.ink, height: 1.35)),
                  ),
                ),
              if (_busy) const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)))),
              if (_msgs.length == 1)
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final q in ['What week am I in?', 'Tips for nausea', 'Back pain', 'When is the glucose test?'])
                    ActionChip(label: Text(q), onPressed: () => _send(q)),
                ]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            child: Row(children: [
              Expanded(child: TextField(controller: _input, maxLength: 500, buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Ask a pregnancy question…'))),
              const SizedBox(width: 8),
              IconButton.filled(style: IconButton.styleFrom(backgroundColor: AppColors.lavenderDark, minimumSize: const Size(52, 52)), tooltip: 'Send', onPressed: _busy ? null : () => _send(), icon: const Icon(Icons.send_rounded)),
            ]),
          ),
        ]),
      );
}
