class PageResult<T> {
  final List<T> items;
  final bool hasMore;

  const PageResult({required this.items, required this.hasMore});

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final content = (json['content'] as List? ?? const []);
    final pagina = (json['number'] as num?)?.toInt() ?? 0;
    final total = (json['totalPages'] as num?)?.toInt() ?? 1;
    return PageResult(
      items: content
          .map((e) => parse(e as Map<String, dynamic>))
          .toList(growable: false),
      hasMore: pagina < total - 1,
    );
  }
}
