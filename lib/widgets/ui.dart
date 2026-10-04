import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import 'bottom_nav.dart';

/// Page with the design's bottom navigation bar.
class AppShell extends StatelessWidget {
  final Widget body;
  final bool showNav;

  const AppShell({Key? key, required this.body, this.showNav = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tw.gray50,
      body: body,
      bottomNavigationBar: showNav ? const BottomNav() : null,
    );
  }
}

void goBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/home');
  }
}

/// The white header with a back arrow used on inner pages.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? bottom;
  final List<Widget> actions;

  const PageHeader({Key? key, required this.title, this.subtitle, this.bottom, this.actions = const []})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF),
        border: Border(bottom: BorderSide(color: Tw.gray200)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => goBack(context),
                    child: const Icon(Icons.arrow_back, color: Tw.gray900, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Tw.gray900)),
                        if (subtitle != null)
                          Text(subtitle!, style: const TextStyle(fontSize: 14, color: Tw.muted)),
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
              if (bottom != null) ...[const SizedBox(height: 12), bottom!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded tinted square holding an icon (`bg-blue-100 p-3 rounded-xl`).
class IconBox extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color color;
  final double size;
  final double padding;

  const IconBox({
    Key? key,
    required this.icon,
    required this.background,
    required this.color,
    this.size = 20,
    this.padding = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: size),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color color;
  final IconData? icon;

  const Pill({Key? key, required this.text, required this.background, required this.color, this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

/// Plain white rounded card.
class WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool border;
  final VoidCallback? onTap;

  const WhiteCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 12,
    this.border = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: border ? const BorderSide(color: Tw.gray200) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Small uppercase group title used in the settings sheets.
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 12, color: Tw.muted, letterSpacing: 1.2),
      ),
    );
  }
}

/// Grey rounded group of rows separated by thin dividers.
class GroupBox extends StatelessWidget {
  final List<Widget> children;
  final Color color;

  const GroupBox({Key? key, required this.children, this.color = Tw.gray50}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: Tw.gray100),
            children[i],
          ],
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final bool small;

  const FieldLabel(this.text, {Key? key, this.trailing, this.small = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: small ? 4 : 8),
      child: Row(
        children: [
          Text(
            text,
            style: small
                ? const TextStyle(fontSize: 12, color: Tw.muted)
                : const TextStyle(fontSize: 16, color: Tw.gray900),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class OptionalTag extends StatelessWidget {
  const OptionalTag({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Tw.gray100, borderRadius: BorderRadius.circular(999)),
      child: const Text('Optional', style: TextStyle(fontSize: 12, color: Tw.muted)),
    );
  }
}

/// Full-width rounded action button (`py-4 rounded-2xl`).
class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final Gradient? gradient;
  final bool loading;

  const BigButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = Tw.blue600,
    this.textColor = Colors.white,
    this.gradient,
    this.loading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled || loading ? 1 : 0.5,
      child: Material(
        color: gradient == null ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: gradient == null
              ? null
              : BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
                    )
                  else if (icon != null)
                    Icon(icon, color: textColor, size: 20),
                  if (loading || icon != null) const SizedBox(width: 8),
                  Flexible(
                    child: Text(label, style: TextStyle(color: textColor, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The design's bottom sheet: drag handle, title, subtitle and close button.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  required String subtitle,
  required WidgetBuilder builder,
  Widget? header,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Tw.gray200, borderRadius: BorderRadius.circular(999)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Tw.gray900)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 14, color: Tw.muted)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(sheetContext).pop(),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: Tw.gray100, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: Tw.gray600),
                  ),
                ),
              ],
            ),
          ),
          if (header != null) header,
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: builder(sheetContext),
            ),
          ),
        ],
      ),
    ),
  );
}

/// One row inside a [GroupBox]: tinted icon, label, description, trailing widget.
class SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final Widget? trailing;
  final bool active;
  final Color? iconBackground;
  final Color? iconColor;
  final Color labelColor;
  final VoidCallback? onTap;

  const SettingRow({
    Key? key,
    required this.icon,
    required this.label,
    this.description,
    this.trailing,
    this.active = true,
    this.iconBackground,
    this.iconColor,
    this.labelColor = Tw.gray900,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBackground ?? (active ? Tw.blue100 : Tw.gray200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 16, color: iconColor ?? (active ? Tw.blue600 : Tw.gray400)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, color: labelColor)),
                  if (description != null)
                    Text(description!, style: const TextStyle(fontSize: 12, color: Tw.muted)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

String formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
