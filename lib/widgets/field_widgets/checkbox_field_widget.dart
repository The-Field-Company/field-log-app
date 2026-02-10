import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class FieldCheckbox extends StatefulWidget {
  final String label;
  final ValueChanged<bool> onChanged;

  const FieldCheckbox({
    super.key,
    required this.label,
    required this.onChanged,
  });

  @override
  State<FieldCheckbox> createState() => _FieldCheckboxState();
}

class _FieldCheckboxState extends State<FieldCheckbox> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: CheckboxListTile(
        title: Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        value: _value,
        activeColor: AppColors.accent,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (value) {
          setState(() => _value = value ?? false);
          widget.onChanged(_value);
        },
      ),
    );
  }
}

class FieldMultiCheckbox extends StatefulWidget {
  final String label;
  final bool isRequired;
  final List<MapEntry<String, String>> options;
  final ValueChanged<List<String>> onChanged;

  const FieldMultiCheckbox({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  State<FieldMultiCheckbox> createState() => _FieldMultiCheckboxState();
}

class _FieldMultiCheckboxState extends State<FieldMultiCheckbox> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label + (widget.isRequired ? ' *' : ''),
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          ...widget.options.map(
            (o) => CheckboxListTile(
              title: Text(o.value,
                  style: GoogleFonts.inter(
                      fontSize: 15, color: AppColors.textPrimary)),
              value: _selected.contains(o.key),
              activeColor: AppColors.accent,
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selected.add(o.key);
                  } else {
                    _selected.remove(o.key);
                  }
                });
                widget.onChanged(_selected.toList());
              },
            ),
          ),
        ],
      ),
    );
  }
}
