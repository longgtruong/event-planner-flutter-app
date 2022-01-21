class Party {
  final int? id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;

  const Party(
      {this.id,
      required this.title,
      this.description,
      required this.startDate,
      required this.endDate});

  static Party parseJson(Map<String, Object?> json) => Party(
      id: json['id'] as int,
      title: json['title'].toString(),
      description: json['description'].toString(),
      startDate: DateTime.parse(json['start_date'].toString()),
      endDate: DateTime.parse(json['end_date'].toString()));

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String()
      };
}
