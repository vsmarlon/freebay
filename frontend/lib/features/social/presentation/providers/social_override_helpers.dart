Map<String, T> withOverride<T>(Map<String, T> current, String key, T value) =>
    Map<String, T>.of(current)..[key] = value;
