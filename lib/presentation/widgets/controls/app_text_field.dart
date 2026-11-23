import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/theme/controls_theme.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_section.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.maxLength,
    this.style,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final int? maxLength;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(final BuildContext context) {
    final label = this.label;
    final errorText = this.errorText;
    if (ScreenSpec.of(context).family != ChromeFamily.glass) {
      return TextField(
        controller: controller,
        maxLength: maxLength,
        style: style,
        textAlign: textAlign,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        autofocus: autofocus,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          errorMaxLines: 3,
          counterText: maxLength == null ? null : '',
        ),
      );
    }
    final colors = GameColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) InsetHeader(label),
        CupertinoTextField(
          controller: controller,
          placeholder: hint,
          maxLength: maxLength,
          style: style,
          textAlign: textAlign,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          autofocus: autofocus,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          onSubmitted: onSubmitted,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.board,
            borderRadius: BorderRadius.all(Radius.circular(ControlsTheme.cupertino.fieldRadius)),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              errorText,
              style: TextStyle(fontSize: 13, height: 18 / 13, color: colors.bad),
            ),
          ),
      ],
    );
  }
}
