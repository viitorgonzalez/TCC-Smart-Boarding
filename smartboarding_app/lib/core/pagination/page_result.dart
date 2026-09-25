/// Uma fatia de uma lista que o servidor entrega por partes.
///
/// Existe pra os serviços não repetirem a leitura de `content`/`totalPages` a
/// cada endpoint paginado, e pra `hasMore` ser decidido num lugar só — a conta
/// errada aqui trava o carregamento ou faz o app pedir páginas que não existem.
class PageResult<T> {
  final List<T> items;
  final bool hasMore;

  const PageResult({required this.items, required this.hasMore});

  /// [json] é o corpo de `data`, no formato de página do Spring.
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
