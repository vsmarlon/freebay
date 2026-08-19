import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/dispute/data/entities/dispute_entity.dart';
import 'package:freebay/features/dispute/data/repositories/dispute_repository.dart';
import 'package:freebay/features/dispute/data/services/dispute_service.dart';
import 'package:freebay/features/dispute/domain/repositories/i_dispute_repository.dart';
import 'package:freebay/features/dispute/domain/usecases/create_dispute_usecase.dart';
import 'package:freebay/features/dispute/domain/usecases/get_dispute_usecase.dart';
import 'package:freebay/features/dispute/domain/usecases/get_my_disputes_usecase.dart';
import 'package:freebay/features/dispute/domain/usecases/submit_evidence_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dispute_providers.g.dart';

final disputeServiceProvider = Provider((ref) => DisputeService());

final disputeRepositoryProvider = Provider<IDisputeRepository>((ref) {
  return DisputeRepository(ref.watch(disputeServiceProvider));
});

final getDisputeUsecaseProvider = Provider(
  (ref) => GetDisputeUsecase(ref.watch(disputeRepositoryProvider)),
);
final getMyDisputesUsecaseProvider = Provider(
  (ref) => GetMyDisputesUsecase(ref.watch(disputeRepositoryProvider)),
);
final createDisputeUsecaseProvider = Provider(
  (ref) => CreateDisputeUsecase(ref.watch(disputeRepositoryProvider)),
);
final submitEvidenceUsecaseProvider = Provider(
  (ref) => SubmitEvidenceUsecase(ref.watch(disputeRepositoryProvider)),
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
    ref.watch(getMyDisputesUsecaseProvider);
    return const DisputeListState();
  }

  Future<void> loadDisputes() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(getMyDisputesUsecaseProvider)();
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

@Riverpod(keepAlive: false)
class DisputeDetail extends _$DisputeDetail {
  @override
  DisputeDetailState build(String disputeId) {
    ref.watch(getDisputeUsecaseProvider);
    ref.watch(submitEvidenceUsecaseProvider);
    return const DisputeDetailState();
  }

  Future<void> loadDispute() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(getDisputeUsecaseProvider)(disputeId);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (dispute) => state = state.copyWith(isLoading: false, dispute: dispute),
    );
  }

  Future<bool> submitEvidence(String evidence) async {
    state = state.copyWith(isSubmitting: true, error: null);
    final result = await ref.read(submitEvidenceUsecaseProvider)(
      SubmitEvidenceParams(disputeId: disputeId, evidence: evidence),
    );
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
