import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

// ── Bouton principal ─────────────────────────────────────────────────────────
class FBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final IconData? icon;

  const FBtn({super.key, required this.label, required this.onTap, this.filled = true, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: filled ? C.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: C.border, width: 0.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Icon(icon, size: 16, color: filled ? C.bg : C.ink), const SizedBox(width: 8)],
          Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: filled ? C.bg : C.ink)),
        ]),
      ),
    );
  }
}

// ── Row item avec divider ─────────────────────────────────────────────────────
class FRow extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;

  const FRow({super.key, required this.child, this.onTap, this.showDivider = true, this.padding});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () { HapticFeedback.selectionClick(); onTap!(); } : null,
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: padding ?? const EdgeInsets.symmetric(vertical: 14), child: child),
        if (showDivider) const Divider(height: 0, thickness: 0.5, color: C.line),
      ]),
    );
  }
}

// ── Label de section ──────────────────────────────────────────────────────────
class FSectionLabel extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;

  const FSectionLabel({super.key, required this.text, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Row(children: [
        Text(text, style: T.label(context)),
        const Spacer(),
        if (action != null)
          GestureDetector(onTap: onAction, child: Text(action!, style: T.small(context).copyWith(color: C.ink))),
      ]),
    );
  }
}

// ── Champ texte ───────────────────────────────────────────────────────────────
class FField extends StatelessWidget {
  final String hint;
  final TextEditingController ctrl;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? action;
  final bool autofocus;

  const FField({super.key, required this.hint, required this.ctrl, this.maxLines = 1, this.keyboardType, this.action, this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: action,
      autofocus: autofocus,
      style: GoogleFonts.inter(color: C.ink, fontSize: 15),
      decoration: InputDecoration(hintText: hint),
    );
  }
}

// ── Champ inline (sans background) ───────────────────────────────────────────
class FInlineField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final int maxLines;
  final TextStyle? style;
  final bool autofocus;

  const FInlineField({super.key, required this.label, required this.ctrl, this.maxLines = 1, this.style, this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      autofocus: autofocus,
      style: style ?? T.body(context),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: T.body(context).copyWith(color: C.muted),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

// ── Sélecteur de jours ────────────────────────────────────────────────────────
class FDayPicker extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const FDayPicker({super.key, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1;
        final on = selected.contains(day);
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onToggle(day); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: on ? C.ink : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: on ? C.ink : C.border, width: 0.5),
            ),
            child: Center(
              child: Text(labels[i], style: TextStyle(fontSize: 11, fontWeight: on ? FontWeight.w700 : FontWeight.w400, color: on ? C.bg : C.dim, fontFamily: 'Inter')),
            ),
          ),
        );
      }),
    );
  }
}

// ── Handle de sheet ───────────────────────────────────────────────────────────
class FHandle extends StatelessWidget {
  const FHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32, height: 3,
        margin: const EdgeInsets.only(top: 10, bottom: 18),
        decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

// ── Checkbox circulaire ───────────────────────────────────────────────────────
class FCheck extends StatelessWidget {
  final bool checked;
  final VoidCallback onToggle;
  final Color? color;

  const FCheck({super.key, required this.checked, required this.onToggle, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onToggle(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 20, height: 20,
        decoration: BoxDecoration(
          color: checked ? (color ?? C.ink) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: checked ? (color ?? C.ink) : C.muted, width: 1),
        ),
        child: checked ? const Icon(Icons.check_rounded, size: 12, color: C.bg) : null,
      ),
    );
  }
}

// ── Dot de priorité ───────────────────────────────────────────────────────────
class FPrioDot extends StatelessWidget {
  final int priority;
  const FPrioDot({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = C.priority(priority);
    if (priority == 0) return const SizedBox.shrink();
    return Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

// ── Time picker trigger ───────────────────────────────────────────────────────
class FTimeTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showDivider;

  const FTimeTile({super.key, required this.label, required this.value, required this.onTap, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return FRow(
      onTap: onTap,
      showDivider: showDivider,
      child: Row(children: [
        Text(label, style: T.body(context)),
        const Spacer(),
        Text(value, style: T.monoLg(context).copyWith(fontSize: 15)),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right, color: C.muted, size: 16),
      ]),
    );
  }
}
