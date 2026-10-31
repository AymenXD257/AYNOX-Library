class BookCollection {
  final String id;
  final String name;
  final List<String> bookIds;
  final DateTime createdAt;

  BookCollection({
    required this.id,
    required this.name,
    this.bookIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bookIds': bookIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookCollection.fromJson(Map<String, dynamic> json) {
    return BookCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      bookIds: (json['bookIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  BookCollection copyWith({
    String? id,
    String? name,
    List<String>? bookIds,
    DateTime? createdAt,
  }) {
    return BookCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      bookIds: bookIds ?? this.bookIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
