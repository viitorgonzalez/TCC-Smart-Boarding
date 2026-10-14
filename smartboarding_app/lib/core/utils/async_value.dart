sealed class AsyncValue<T> {
  const AsyncValue();
}

final class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

final class AsyncData<T> extends AsyncValue<T> {
  final T value;
  const AsyncData(this.value);
}

final class AsyncError<T> extends AsyncValue<T> {
  final String message;
  const AsyncError(this.message);
}
