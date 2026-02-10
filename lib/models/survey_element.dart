class SurveyElement {
  final String type;
  final String name;
  final String title;
  final bool isRequired;
  final List<SurveyChoice> choices;
  final int? rateMax;

  SurveyElement({
    required this.type,
    required this.name,
    required this.title,
    this.isRequired = false,
    this.choices = const [],
    this.rateMax,
  });

  factory SurveyElement.fromJson(Map<String, dynamic> json) {
    final choicesJson = json['choices'] as List<dynamic>?;
    return SurveyElement(
      type: json['type'] ?? 'text',
      name: json['name'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      isRequired: json['isRequired'] == true,
      rateMax: json['rateMax'],
      choices: choicesJson?.map((c) {
            if (c is Map<String, dynamic>) {
              return SurveyChoice.fromJson(c);
            }
            return SurveyChoice(value: c.toString(), text: c.toString());
          }).toList() ??
          [],
    );
  }
}

class SurveyChoice {
  final String value;
  final String text;

  SurveyChoice({required this.value, required this.text});

  factory SurveyChoice.fromJson(Map<String, dynamic> json) {
    return SurveyChoice(
      value: json['value']?.toString() ?? '',
      text: json['text']?.toString() ?? json['value']?.toString() ?? '',
    );
  }
}

class SurveyPage {
  final String name;
  final List<SurveyElement> elements;

  SurveyPage({required this.name, required this.elements});

  factory SurveyPage.fromJson(Map<String, dynamic> json) {
    final elementsJson = json['elements'] as List<dynamic>? ?? [];
    return SurveyPage(
      name: json['name'] ?? '',
      elements: elementsJson
          .map((e) => SurveyElement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
