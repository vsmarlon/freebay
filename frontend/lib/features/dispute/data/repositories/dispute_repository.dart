import 'package:dio/dio.dart';
import 'package:freebay/features/dispute/data/entities/dispute_entity.dart';
import 'package:freebay/features/dispute/domain/repositories/dispute_repository.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/http/request_either.dart';
import 'package:freebay/shared/services/http_client.dart';

class DisputeRepositoryImpl implements DisputeRepository {
  final Dio client;

  DisputeRepositoryImpl({Dio? client}) : client = client ?? HttpClient.instance;

  @override
  Future<Either<Failure, DisputeEntity>> getDispute(String disputeId) =>
      requestEither(
        () => client.get('/disputes/$disputeId'),
        decoder: (response) =>
            Right(DisputeEntity.fromJson(response.data['data']['dispute'])),
      );

  @override
  Future<Either<Failure, List<DisputeEntity>>> getMyDisputes() => requestEither(
    () => client.get('/disputes'),
    decoder: (response) {
      final raw = response.data['data']['disputes'];
      final disputes = raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) =>
                      DisputeEntity.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <DisputeEntity>[];
      return Right(disputes);
    },
  );

  @override
  Future<Either<Failure, DisputeEntity>> createDispute(
    String orderId,
    String reason,
  ) => requestEither(
    () =>
        client.post('/disputes', data: {'orderId': orderId, 'reason': reason}),
    decoder: (response) => Right(DisputeEntity.fromJson(response.data['data'])),
  );

  @override
  Future<Either<Failure, bool>> submitEvidence(
    String disputeId,
    String evidence,
  ) => requestEither(
    () => client.post(
      '/disputes/$disputeId/evidence',
      data: {'evidence': evidence},
    ),
    decoder: (_) => const Right(true),
  );
}
