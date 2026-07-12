/// Estado de operações assíncronas — substitui o padrão
/// manual `bool _loading / String? _error / T? _data`.
sealed class AsyncValue<T> {
  const AsyncValue();
}

/// Carregando dados
final class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

/// Dados disponíveis
final class AsyncData<T> extends AsyncValue<T> {
  final T value;
  const AsyncData(this.value);
}

/// Erro ao carregar
final class AsyncError<T> extends AsyncValue<T> {
  final String message;
  const AsyncError(this.message);
}
