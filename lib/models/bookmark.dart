class Bookmark {
  final String id;
  final String bookId;
  final String title;
  final int location; // page or chapter index
  final String snippet;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.bookId,
    required this.title,
    required this.location,
    required this.snippet,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'title': title,
      'location': location,
      'snippet': snippet,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      title: json['title'] as String? ?? 'Bookmark',
      location: (json['location'] as num?)?.toInt() ?? 0,
      snippet: json['snippet'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
