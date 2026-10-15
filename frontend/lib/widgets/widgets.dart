import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? AppColors.danger : AppColors.ink));
}

/// Runs an action, shows a success message or the API error. Returns true on success.
Future<bool> guarded(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (success != null && context.mounted) showSnack(context, success);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) showSnack(context, e.detailed, error: true);
    return false;
  } catch (e) {
    if (context.mounted) showSnack(context, 'Something went wrong. Please try again.', error: true);
    return false;
  }
}

Future<bool> confirm(BuildContext context, String title, String body, {String ok = 'Confirm'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: Text(ok)),
      ],
    ),
  );
  return r == true;
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.onTap, this.radius = 24});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color ?? AppColors.card,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [BoxShadow(color: AppColors.lavenderDark.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          if (trailing != null) trailing!,
        ]),
      );
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final good = {'CONFIRMED', 'ACTIVE', 'ACCEPTED', 'GRANTED', 'APPROVED', 'COMPLETED'}.contains(status);
    final bad = {'DECLINED', 'CANCELLED', 'REJECTED', 'REVOKED', 'SUSPENDED'}.contains(status);
    final c = good ? AppColors.success : bad ? AppColors.danger : AppColors.lavenderDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(status[0] + status.substring(1).toLowerCase(), style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const EmptyView({super.key, required this.icon, required this.text, this.action});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(radius: 34, backgroundColor: AppColors.lavenderSoft, child: Icon(icon, size: 32, color: AppColors.lavenderDark)),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ]),
        ),
      );
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
            ],
          ]),
        ),
      );
}

/// Loads data once, shows spinner / error-with-retry, then builds. `reload` re-runs the loader.
class AsyncBody<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;
  const AsyncBody({super.key, required this.load, required this.builder});
  @override
  State<AsyncBody<T>> createState() => _AsyncBodyState<T>();
}

class _AsyncBodyState<T> extends State<AsyncBody<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  Future<void> _reload() async {
    final f = widget.load();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: _reload);
          return widget.builder(context, snap.data as T, _reload);
        },
      );
}

/// Button with an in-button spinner for async submits.
class BusyButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  const BusyButton({super.key, required this.label, required this.busy, required this.onPressed});
  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(label),
      );
}

class Disclaimer extends StatelessWidget {
  final String text;
  const Disclaimer(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.lavenderSoft, borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.lavenderDark),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.ink))),
        ]),
      );
}

class AvatarCircle extends StatelessWidget {
  final String text;
  final double radius;
  const AvatarCircle(this.text, {super.key, this.radius = 24});
  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.lavender,
        child: Text(text, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: radius * 0.7)),
      );
}

/// Dark floating pill navigation, as in the design reference.
class PillNavBar extends StatelessWidget {
  final int index;
  final List<IconData> icons;
  final List<String> labels;
  final ValueChanged<int> onTap;
  const PillNavBar({super.key, required this.index, required this.icons, required this.labels, required this.onTap});
  @override
  Widget build(BuildContext context) => SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(40), boxShadow: [
            BoxShadow(color: AppColors.ink.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8)),
          ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < icons.length; i++)
                Semantics(
                  label: labels[i],
                  button: true,
                  selected: i == index,
                  child: InkResponse(
                    onTap: () => onTap(i),
                    radius: 34,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: i == index ? AppColors.lavender : const Color(0xFF3A3445)),
                      child: Icon(icons[i], color: Colors.white, size: 24),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

/// Pregnancy progress bar (0-40 weeks): filled part, hatched remainder, knob showing the current week.
class WeekTrack extends StatelessWidget {
  final int week;
  const WeekTrack({super.key, required this.week});

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (final w in [0, 10, 20, 30, 40]) Text('${w}W', style: const TextStyle(fontSize: 12, color: AppColors.muted))],
        ),
        const SizedBox(height: 8),
        SizedBox(height: 28, width: double.infinity, child: CustomPaint(painter: _TrackPainter(week.clamp(0, 40) / 40.0, week))),
      ]);
}

class _TrackPainter extends CustomPainter {
  final double fraction;
  final int week;
  _TrackPainter(this.fraction, this.week);

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(0, 4, size.width, 20), const Radius.circular(10));
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRect(r.outerRect, Paint()..color = const Color(0xFFE9E2F3));
    final stripe = Paint()..color = const Color(0xFF5B5568)..strokeWidth = 1.4;
    for (double x = -20; x < size.width + 20; x += 6) {
      canvas.drawLine(Offset(x, 24), Offset(x + 12, 4), stripe);
    }
    final fillW = size.width * fraction;
    canvas.drawRect(Rect.fromLTWH(0, 4, fillW, 20),
        Paint()..shader = const LinearGradient(colors: [AppColors.lavender, AppColors.lavenderDark]).createShader(Rect.fromLTWH(0, 0, size.width, 20)));
    canvas.restore();
    final knobX = (size.width * fraction).clamp(12.0, size.width - 12.0);
    canvas.drawCircle(Offset(knobX, 14), 12, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(knobX, 14), 12, Paint()..color = AppColors.lavenderDark..style = PaintingStyle.stroke..strokeWidth = 2);
    final tp = TextPainter(text: TextSpan(text: '$week', style: const TextStyle(color: AppColors.ink, fontSize: 10, fontWeight: FontWeight.w700)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(knobX - tp.width / 2, 14 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TrackPainter old) => old.fraction != fraction || old.week != week;
}

/// Standard modal bottom sheet container used by all forms.
Future<T?> showFormSheet<T>(BuildContext context, {required String title, required Widget Function(BuildContext) builder}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(c).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            builder(c),
          ]),
        ),
      ),
    );

Future<DateTime?> pickDate(BuildContext context, {DateTime? initial, DateTime? first, DateTime? last}) => showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: first ?? DateTime(2000),
      lastDate: last ?? DateTime(2100),
    );
