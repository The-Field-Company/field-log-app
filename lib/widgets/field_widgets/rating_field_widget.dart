import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class FieldRating extends StatefulWidget {
  final String label;
  final bool isRequired;
  final int maxRating;
  final ValueChanged<int> onChanged;

  const FieldRating({
    super.key,
    required this.label,
    required this.onChanged,
    this.isRequired = false,
    this.maxRating = 5,
  });

  @override
  State<FieldRating> createState() => _FieldRatingState();
}

class _FieldRatingState extends State<FieldRating> {
  int _value = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FormField<int>(
        validator: widget.isRequired
            ? (value) =>
                _value == 0 ? '${widget.label} is required' : null
            : null,
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label + (widget.isRequired ? ' *' : ''),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(widget.maxRating, (index) {
                  final starIndex = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _value = starIndex);
                      state.didChange(starIndex);
                      widget.onChanged(starIndex);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        starIndex <= _value
                            ? Icons.star
                            : Icons.star_border,
                        color: starIndex <= _value
                            ? AppColors.accent
                            : AppColors.borderColor,
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    state.errorText!,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.error),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
