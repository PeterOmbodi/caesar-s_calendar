import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/material.dart';

class InsetSection extends StatelessWidget {
  const InsetSection({super.key, required this.children, this.header, this.footer});

  static const double radius = 16;

  final List<Widget> children;
  final String? header;
  final String? footer;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final header = this.header;
    final footer = this.footer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Semantics(
              header: true,
              child: Text(
                header,
                style: TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600, color: colors.text),
              ),
            ),
          ),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(radius)),
          child: ColoredBox(
            color: colors.board,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, child) in children.indexed) ...[
                  if (index > 0) Divider(height: 1, thickness: 1, indent: InsetRow.textIndent, color: colors.gridLine),
                  child,
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(footer, style: TextStyle(fontSize: 13, height: 18 / 13, color: colors.textSecondary)),
          ),
      ],
    );
  }
}

class InsetRow extends StatelessWidget {
  const InsetRow({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.illustration,
  });

  /// Separators are indented to the text.
  static const double textIndent = 56;

  final String title;
  final IconData? icon;

  /// Shown instead of [icon], e.g. an avatar.
  final Widget? leading;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Widget? illustration;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final subtitle = this.subtitle;
    final trailing = this.trailing;
    final illustration = this.illustration;
    final row = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 11, 16, 11),
      child: Row(
        crossAxisAlignment: subtitle == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: textIndent - 16,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: leading ?? Icon(icon, size: 24, color: titleColor ?? colors.icon),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 17, height: 22 / 17, color: titleColor ?? colors.text),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 15, height: 20 / 15, color: colors.textSecondary)),
                ],
                if (illustration != null) ...[const SizedBox(height: 10), illustration],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing],
        ],
      ),
    );
    final onTap = this.onTap;
    return Semantics(
      button: onTap != null,
      child: onTap == null
          ? row
          : Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap, child: row),
            ),
    );
  }
}
