import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/repositories/base_http_repository.dart';
import 'package:freebay/features/dispute/data/entities/dispute_entity.dart';

class DisputeService extends BaseHttpRepository {
  DisputeService({super.client});

  Future<Either<Failure, DisputeEntity>> getDispute(String disputeId) =>
      safeGet<DisputeEntity>(
        '/disputes/$disputeId',
        extractKey: 'data.dispute',
        fromJson: DisputeEntity.fromJson,
      );

  Future<Either<Failure, List<DisputeEntity>>> getMyDisputes() =>
      safeGetList<DisputeEntity>(
        '/disputes',
        listKey: 'data.disputes',
        fromJson: DisputeEntity.fromJson,
      );

  Future<Either<Failure, DisputeEntity>> createDispute(
    String orderId,
    String reason,
  ) => safePost<DisputeEntity>(
    '/disputes',
    data: {'orderId': orderId, 'reason': reason},
    extractKey: 'data',
    fromJson: DisputeEntity.fromJson,
  );

  Future<Either<Failure, bool>> submitEvidence(
    String disputeId,
    String evidence,
  ) => safePost<bool>(
    '/disputes/$disputeId/evidence',
    data: {'evidence': evidence},
    customMapper: (_) => true,
  );
}
