import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/bug_report/domain/usecases/create_bug_report_usecase.dart';

final createBugReportUsecaseProvider = Provider<CreateBugReportUsecase>((ref) {
  return CreateBugReportUsecase();
});
