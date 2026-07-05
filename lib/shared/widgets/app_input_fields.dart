import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    required this.hint,
    this.icon,
    this.maxLines = 1,
    super.key,
  });

  final String label;
  final String hint;
  final IconData? icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
    );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({required this.hint, super.key});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      leading: const Icon(Icons.search_rounded),
      hintText: hint,
      elevation: const WidgetStatePropertyAll<double>(0),
      backgroundColor: WidgetStatePropertyAll<Color>(
        Theme.of(context).colorScheme.surface,
      ),
      side: WidgetStatePropertyAll<BorderSide>(
        BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}

class OtpPreviewFields extends StatelessWidget {
  const OtpPreviewFields({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: List<Widget>.generate(
        4,
        (int index) => Expanded(
          child: Container(
            margin: EdgeInsetsDirectional.only(end: index == 3 ? 0 : 12),
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant),
              color: scheme.surface,
            ),
            child: Center(
              child: Text(
                index.isEven ? '•' : '0',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
