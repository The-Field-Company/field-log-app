import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class FieldSwitch extends StatefulWidget {
  final String label;
  final ValueChanged<bool> onChanged;

  const FieldSwitch({
    super.key,
    required this.label,
    required this.onChanged,
  });

  @override
  State<FieldSwitch> createState() => _FieldSwitchState();
}

class _FieldSwitchState extends State<FieldSwitch> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SwitchListTile(
        title: Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        value: _value,
        activeThumbColor: AppColors.accent,
        contentPadding: EdgeInsets.zero,
        onChanged: (value) {
          setState(() => _value = value);
          widget.onChanged(value);
        },
      ),
    );
  }
}
