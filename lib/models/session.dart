class Session {
  final int id;
  final String name;
  final String description;
  final Map<String, dynamic> formConfig;
  final bool isActive;
  final bool isPublic;
  final String createdAt;

  Session({
    required this.id,
    required this.name,
    required this.description,
    required this.formConfig,
    required this.isActive,
    required this.isPublic,
    required this.createdAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      formConfig: json['form_config'] ?? {},
      isActive: json['is_active'] ?? true,
      isPublic: json['is_public'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  String get formMode => formConfig['form_mode'] ?? 'formkit';
  bool get trackLocation => formConfig['track_location'] == true;
  List<dynamic> get components => formConfig['components'] ?? [];
  Map<String, dynamic>? get schema => formConfig['schema'];
}
