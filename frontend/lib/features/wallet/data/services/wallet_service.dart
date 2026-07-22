import 'package:dio/dio.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_transaction_entity.dart';
import 'package:freebay/features/wallet/data/entities/withdrawal_entity.dart';

class WalletService {
  Future<Either<Failure, WalletEntity>> getWallet() async {
    try {
      final response = await HttpClient.instance.get('/wallet/');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        return Right(WalletEntity.fromJson(data));
      }
      return const Left(ServerFailure('Erro ao carregar dados da carteira.'));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(ServerFailure('Erro ao conectar com o servidor.'));
    }
  }

  Future<Either<Failure, List<WalletTransactionEntity>>>
  getTransactions() async {
    try {
      final response = await HttpClient.instance.get('/wallet/transactions');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final raw = (data?['transactions'] as List?) ?? [];
        return Right(
          raw
              .map(
                (e) =>
                    WalletTransactionEntity.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        );
      }
      return const Left(ServerFailure('Erro ao carregar transações.'));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(ServerFailure('Erro ao conectar com o servidor.'));
    }
  }

  Future<Either<Failure, List<WithdrawalEntity>>> getWithdrawals() async {
    try {
      final response = await HttpClient.instance.get('/wallet/withdrawals');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final raw = (data?['withdrawals'] as List?) ?? [];
        return Right(
          raw
              .map((e) => WithdrawalEntity.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
      return const Left(ServerFailure('Erro ao carregar saques.'));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(ServerFailure('Erro ao conectar com o servidor.'));
    }
  }

  Future<Either<Failure, void>> withdraw({
    required int amountCents,
    required String pixKey,
    required String pixKeyType,
    required String idempotencyKey,
  }) async {
    try {
      final response = await HttpClient.instance.post(
        '/wallet/withdraw',
        data: {
          'amount': amountCents,
          'pixKey': pixKey,
          'pixKeyType': pixKeyType,
          'idempotencyKey': idempotencyKey,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return const Right(null);
      }
      return const Left(ServerFailure('Erro ao solicitar saque.'));
    } on DioException catch (e) {
      return Left(mapDioExceptionToFailure(e));
    } catch (_) {
      return const Left(ServerFailure('Erro ao conectar com o servidor.'));
    }
  }
}
