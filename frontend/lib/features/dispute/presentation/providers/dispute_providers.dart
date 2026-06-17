import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/dispute/data/entities/dispute_entity.dart';
import 'package:freebay/features/dispute/data/services/dispute_service.dart';

final disputeServiceProvider = Provider((ref) => DisputeService());

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

class DisputeListNotifier extends StateNotifier<DisputeListState> {
  final DisputeService _service;

  DisputeListNotifier(this._service) : super(const DisputeListState());

  Future<void> loadDisputes() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _service.getMyDisputes();
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (disputes) => state = state.copyWith(isLoading: false, disputes: disputes),
    );
  }
}

final disputeListProvider = StateNotifierProvider<DisputeListNotifier, DisputeListState>((ref) {
  return DisputeListNotifier(ref.watch(disputeServiceProvider));
});

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

class DisputeDetailNotifier extends StateNotifier<DisputeDetailState> {
  final DisputeService _service;
  final String disputeId;

  DisputeDetailNotifier(this._service, this.disputeId) : super(const DisputeDetailState());

  Future<void> loadDispute() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _service.getDispute(disputeId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (dispute) => state = state.copyWith(isLoading: false, dispute: dispute),
    );
  }

  Future<bool> submitEvidence(String evidence) async {
    state = state.copyWith(isSubmitting: true, error: null);
    final result = await _service.submitEvidence(disputeId, evidence);
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

final disputeDetailProvider = StateNotifierProvider.autoDispose
    .family<DisputeDetailNotifier, DisputeDetailState, String>((ref, disputeId) {
  return DisputeDetailNotifier(ref.watch(disputeServiceProvider), disputeId);
});
