import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/survey_element.dart';
import '../theme/app_colors.dart';
import 'field_widgets/text_field_widget.dart';
import 'field_widgets/dropdown_field_widget.dart';
import 'field_widgets/radio_field_widget.dart';
import 'field_widgets/checkbox_field_widget.dart';
import 'field_widgets/switch_field_widget.dart';
import 'field_widgets/rating_field_widget.dart';

class SurveyjsRenderer extends StatefulWidget {
  final Map<String, dynamic> schema;
  final void Function(Map<String, dynamic> data) onSubmit;

  const SurveyjsRenderer({
    super.key,
    required this.schema,
    required this.onSubmit,
  });

  @override
  State<SurveyjsRenderer> createState() => _SurveyjsRendererState();
}

class _SurveyjsRendererState extends State<SurveyjsRenderer> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _data = {};
  int _currentPage = 0;

  List<SurveyPage> get _pages {
    final pagesJson = widget.schema['pages'] as List<dynamic>? ?? [];
    return pagesJson
        .map((p) => SurveyPage.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  bool get _isMultiPage => _pages.length > 1;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(Map.from(_data));
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  Widget _buildElement(SurveyElement element) {
    switch (element.type) {
      case 'text':
        return FieldTextInput(
          label: element.title,
          isRequired: element.isRequired,
          onChanged: (v) => _data[element.name] = v,
        );
      case 'comment':
        return FieldTextInput(
          label: element.title,
          isRequired: element.isRequired,
          maxLines: 4,
          onChanged: (v) => _data[element.name] = v,
        );
      case 'dropdown':
        return FieldDropdown(
          label: element.title,
          isRequired: element.isRequired,
          options: element.choices
              .map((c) => MapEntry(c.value, c.text))
              .toList(),
          onChanged: (v) => _data[element.name] = v,
        );
      case 'radiogroup':
        return FieldRadioGroup(
          label: element.title,
          isRequired: element.isRequired,
          options: element.choices
              .map((c) => MapEntry(c.value, c.text))
              .toList(),
          onChanged: (v) => _data[element.name] = v,
        );
      case 'checkbox':
        return FieldMultiCheckbox(
          label: element.title,
          isRequired: element.isRequired,
          options: element.choices
              .map((c) => MapEntry(c.value, c.text))
              .toList(),
          onChanged: (v) => _data[element.name] = v,
        );
      case 'boolean':
        return FieldSwitch(
          label: element.title,
          onChanged: (v) => _data[element.name] = v,
        );
      case 'rating':
        return FieldRating(
          label: element.title,
          isRequired: element.isRequired,
          maxRating: element.rateMax ?? 5,
          onChanged: (v) => _data[element.name] = v,
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Text(
              'Unsupported field type: ${element.type}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    if (pages.isEmpty) {
      return const Center(child: Text('No form elements found'));
    }

    final currentElements =
        _isMultiPage ? pages[_currentPage].elements : pages[0].elements;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Page indicator
          if (_isMultiPage)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Page ${_currentPage + 1} of ${pages.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          // Form fields
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: currentElements.map(_buildElement).toList(),
            ),
          ),
          // Bottom bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: SafeArea(
              top: false,
              child: _isMultiPage
                  ? Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _prevPage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.accent,
                                side: const BorderSide(
                                    color: AppColors.accent),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text('Previous'),
                            ),
                          ),
                        if (_currentPage > 0) const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentPage < pages.length - 1
                                ? _nextPage
                                : _submit,
                            child: Text(_currentPage < pages.length - 1
                                ? 'Next'
                                : 'Submit'),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Submit'),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
