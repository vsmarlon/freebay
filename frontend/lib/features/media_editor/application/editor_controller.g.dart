// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EditorController)
final editorControllerProvider = EditorControllerFamily._();

final class EditorControllerProvider
    extends $NotifierProvider<EditorController, EditorHistory> {
  EditorControllerProvider._({
    required EditorControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'editorControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$editorControllerHash();

  @override
  String toString() {
    return r'editorControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EditorController create() => EditorController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditorHistory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditorHistory>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EditorControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$editorControllerHash() => r'50b22b127287b07e7ef8fd5f547a7450118b8162';

final class EditorControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          EditorController,
          EditorHistory,
          EditorHistory,
          EditorHistory,
          String
        > {
  EditorControllerFamily._()
    : super(
        retry: null,
        name: r'editorControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EditorControllerProvider call(String sessionId) =>
      EditorControllerProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'editorControllerProvider';
}

abstract class _$EditorController extends $Notifier<EditorHistory> {
  late final _$args = ref.$arg as String;
  String get sessionId => _$args;

  EditorHistory build(String sessionId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EditorHistory, EditorHistory>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EditorHistory, EditorHistory>,
              EditorHistory,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
