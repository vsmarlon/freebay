import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/dispute/data/entities/dispute_entity.dart';
import 'package:freebay/features/dispute/data/repositories/dispute_repository.dart';
import 'package:freebay/features/dispute/domain/repositories/dispute_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freebay/shared/services/http_client.dart';

part 'dispute_providers.g.dart';

final disputeRepositoryProvider = Provider<DisputeRepository>(
  (ref) => DisputeRepositoryImpl(client: HttpClient.instance),
);

class DisputeListState {
  final bool isLoading;
  final List<DisputeEntity> disputes;
  final String? error;

  const DisputeListState({
    this.isLoading = false,
    this.disputes = const [],
    this.error,
  });

  DisputeListState copyWith({
    bool? isLoading,
    List<DisputeEntity>? disputes,
    String? error,
  }) {
    return DisputeListState(
      isLoading: isLoading ?? this.isLoading,
      disputes: disputes ?? this.disputes,
      error: error,
    );
  }
}

@Riverpod(keepAlive: true)
class DisputeList extends _$DisputeList {
  @override
  DisputeListState build() {
    ref.watch(disputeRepositoryProvider);
    return const DisputeListState();
  }

  Future<void> loadDisputes() async {
    state = state.copyWith(isLoading: true);
    final result = await ref.read(disputeRepositoryProvider).getMyDisputes();
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (disputes) =>
          state = state.copyWith(isLoading: false, disputes: disputes),
    );
  }
}

class DisputeDetailState {
  final bool isLoading;
  final bool isSubmitting;
  final DisputeEntity? dispute;
  final String? error;

  const DisputeDetailState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.dispute,
    this.error,
  });

  DisputeDetailState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    DisputeEntity? dispute,
    String? error,
  }) {
    return DisputeDetailState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      dispute: dispute ?? this.dispute,
      error: error,
    );
  }
}

@Riverpod()
class DisputeDetail extends _$DisputeDetail {
  @override
  DisputeDetailState build(String disputeId) {
    ref.watch(disputeRepositoryProvider);
    return const DisputeDetailState();
  }

  Future<void> loadDispute() async {
    state = state.copyWith(isLoading: true);
    final result = await ref
        .read(disputeRepositoryProvider)
        .getDispute(disputeId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (dispute) => state = state.copyWith(isLoading: false, dispute: dispute),
    );
  }

  Future<bool> submitEvidence(String evidence) async {
    state = state.copyWith(isSubmitting: true);
    final result = await ref
        .read(disputeRepositoryProvider)
        .submitEvidence(disputeId, evidence);
    return result.fold(
      (failure) {
        state = state.copyWith(isSubmitting: false, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isSubmitting: false);
        loadDispute();
        return true;
      },
    );
  }
}
