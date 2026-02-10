import 'package:flutter/material.dart';
import '../models/form_component.dart';
import 'field_widgets/text_field_widget.dart';
import 'field_widgets/dropdown_field_widget.dart';
import 'field_widgets/radio_field_widget.dart';
import 'field_widgets/checkbox_field_widget.dart';
import 'field_widgets/slider_field_widget.dart';
import 'field_widgets/date_field_widget.dart';
import 'field_widgets/time_field_widget.dart';

class FormkitRenderer extends StatefulWidget {
  final List<dynamic> components;
  final void Function(Map<String, dynamic> data) onSubmit;

  const FormkitRenderer({
    super.key,
    required this.components,
    required this.onSubmit,
  });

  @override
  State<FormkitRenderer> createState() => _FormkitRendererState();
}

class _FormkitRendererState extends State<FormkitRenderer> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _data = {};

  List<FormComponent> get _parsed =>
      widget.components
          .map((c) => FormComponent.fromJson(c as Map<String, dynamic>))
          .toList();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(Map.from(_data));
    }
  }

  Widget _buildField(FormComponent comp) {
    switch (comp.type) {
      case 'textarea':
        return FieldTextInput(
          label: comp.label,
          placeholder: comp.placeholder,
          isRequired: comp.isRequired,
          maxLines: 4,
          onChanged: (v) => _data[comp.key] = v,
        );
      case 'email':
        return FieldTextInput(
          label: comp.label,
          placeholder: comp.placeholder,
          isRequired: comp.isRequired,
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => _data[comp.key] = v,
        );
      case 'url':
        return FieldTextInput(
          label: comp.label,
          placeholder: comp.placeholder,
          isRequired: comp.isRequired,
          keyboardType: TextInputType.url,
          onChanged: (v) => _data[comp.key] = v,
        );
      case 'tel':
        return FieldTextInput(
          label: comp.label,
          placeholder: comp.placeholder,
          isRequired: comp.isRequired,
          keyboardType: TextInputType.phone,
          onChanged: (v) => _data[comp.key] = v,
        );
      case 'number':
        return FieldTextInput(
          label: comp.label,
          placeholder: comp.placeholder,
          isRequired: comp.isRequired,
          keyboardType: TextInputType.number,
          onChanged: (v) => _data[comp.key] = num.tryParse(v) ?? v,
        );
      case 'range':
        return FieldSlider(
          label: comp.label,
          min: comp.min ?? 0,
          max: comp.max ?? 100,
          step: comp.step ?? 1,
          onChanged: (v) => _data[comp.key] = v,
        );
      case 'date':
        return FieldDatePicker(
          label: comp.label,
          isRequired: comp.isRequired,
          onChanged: (v) => _data[comp.key] = v,
        );
      case 'time':
        return FieldTimePicker(
          label: comp.label,
          isRequired: comp.isRequired,
          onChanged: (v) => _data[comp.key] = v,
        );
      case 'datetime':
        return FieldTimePicker(
          label: comp.label,
          isRequired: comp.isRequired,
          includeDate: true,
          onChanged: (v) => _data[comp.key] = v,
        );
      case 'select':
        return FieldDropdown(
          label: comp.label,
          isRequired: comp.isRequired,
          options:
              comp.options.map((o) => MapEntry(o.value, o.label)).toList(),
          onChanged: (v) => _data[comp.key] = v,
        );
      case 'radio':
        return FieldRadioGroup(
          label: comp.label,
          isRequired: comp.isRequired,
          options:
              comp.options.map((o) => MapEntry(o.value, o.label)).toList(),
          onChanged: (v) => _data[comp.key] = v,
        );
      case 'checkbox':
        return FieldCheckbox(
          label: comp.label,
          onChanged: (v) => _data[comp.key] = v,
        );
      case 'color':
      case 'file':
      case 'password':
        return const SizedBox.shrink();
      default:
        // textfield and any unknown types
        return FieldTextInput(
          label: comp.label,
          placeholder: comp.placeholder,
          isRequired: comp.isRequired,
          onChanged: (v) => _data[comp.key] = v,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final components = _parsed;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: components.map(_buildField).toList(),
            ),
          ),
          // Submit button bar
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
              child: SizedBox(
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
