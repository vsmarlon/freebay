import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/dispute/presentation/providers/dispute_providers.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/brutalist_box.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';
import 'package:freebay/core/components/spacing.dart';

class DisputeDetailPage extends ConsumerStatefulWidget {
  final String disputeId;

  const DisputeDetailPage({super.key, required this.disputeId});

  @override
  ConsumerState<DisputeDetailPage> createState() => _DisputeDetailPageState();
}

class _DisputeDetailPageState extends ConsumerState<DisputeDetailPage> {
  final _evidenceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(disputeDetailProvider(widget.disputeId).notifier).loadDispute());
  }

  @override
  void dispose() {
    _evidenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(disputeDetailProvider(widget.disputeId));

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            text: 'DETALHES DA DISPUTA',
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: context.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.dispute == null
                    ? Center(child: Text(state.error ?? 'Disputa não encontrada'))
                    : _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DisputeDetailState state) {
    final dispute = state.dispute!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrutalistBreadcrumb(items: [
            BreadcrumbItem(label: 'Disputas', onTap: () => Navigator.pop(context)),
            const BreadcrumbItem(label: 'Detalhes da Disputa'),
          ]),
          Spacing.vMd,
          BrutalistBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Status', _statusLabel(dispute.status)),
                Spacing.vSm,
                _row('Motivo', dispute.reason),
                Spacing.vSm,
                _row('Aberta em', _formatDate(dispute.createdAt)),
                if (dispute.resolvedAt != null) ...[
                  Spacing.vSm,
                  _row('Resolvida em', _formatDate(dispute.resolvedAt!)),
                ],
                if (dispute.resolution != null) ...[
                  Spacing.vSm,
                  _row('Resolução', dispute.resolution!),
                ],
              ],
            ),
          ),
          if (dispute.isOpen) ...[
            Spacing.vLg,
            Text('Enviar Evidência', style: AppTypography.h3),
            Spacing.vSm,
            BrutalistBox(
              child: TextField(
                controller: _evidenceController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Descreva sua evidência...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Container(
                color: AppColors.primaryContainer,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: state.isSubmitting ? null : () => _submitEvidence(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text('Enviar Evidência', style: AppTypography.button),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitEvidence() async {
    final evidence = _evidenceController.text.trim();
    if (evidence.isEmpty) return;

    final success = await ref.read(disputeDetailProvider(widget.disputeId).notifier).submitEvidence(evidence);
    if (success && mounted) {
      _evidenceController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evidência enviada com sucesso')),
      );
    }
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
        ),
        Expanded(child: Text(value, style: AppTypography.bodyMedium)),
      ],
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'OPEN': return 'Aberta';
      case 'AWAITING_SELLER': return 'Aguardando vendedor';
      case 'AWAITING_BUYER': return 'Aguardando comprador';
      case 'RESOLVED': return 'Resolvida';
      case 'CANCELLED': return 'Cancelada';
      default: return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
