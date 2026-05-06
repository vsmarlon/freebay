import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/features/wallet/data/models/wallet_model.dart';

class WalletService {
  Future<Either<Failure, WalletModel>> getWallet() async {
    try {
      final response = await HttpClient.instance.get('/wallet/');

      if (kDebugMode) {
        debugPrint('[WALLET] getWallet status: ${response.statusCode}');
        debugPrint('[WALLET] getWallet data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        return Right(WalletModel.fromJson(data));
      } else {
        return const Left(ServerFailure('Erro ao carregar dados da carteira.'));
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[WALLET] getWallet error: $e');
        debugPrint('[WALLET] getWallet stack: $stack');
      }
      return const Left(ServerFailure('Erro ao conectar com o servidor.'));
    }
  }

  Future<Either<Failure, List<dynamic>>> getTransactions() async {
    try {
      final response = await HttpClient.instance.get('/wallet/transactions');

      if (kDebugMode) {
        debugPrint('[WALLET] getTransactions status: ${response.statusCode}');
        debugPrint('[WALLET] getTransactions data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final transactions = (data?['transactions'] as List?) ?? [];
        return Right(transactions);
      } else {
        return const Left(ServerFailure('Erro ao carregar transações.'));
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[WALLET] getTransactions error: $e');
        debugPrint('[WALLET] getTransactions stack: $stack');
      }
      return const Left(ServerFailure('Erro ao conectar com o servidor.'));
    }
  }
}
