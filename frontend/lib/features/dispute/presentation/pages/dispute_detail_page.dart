import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/dispute/presentation/providers/dispute_providers.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/navigation_tracker.dart';

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
    Future.microtask(
      () => ref
          .read(disputeDetailProvider(widget.disputeId).notifier)
          .loadDispute(),
    );
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
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? _buildSkeleton(context)
                : state.dispute == null
                ? Center(child: Text(state.error ?? 'Disputa não encontrada'))
                : _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return SkeletonPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const ShimmerBlock(height: 40, width: 120),
          const SizedBox(height: 16),
          const ShimmerBlock(height: 60),
          const SizedBox(height: 16),
          const ShimmerBlock(height: 14, width: 100),
          const SizedBox(height: 8),
          _buildTimelineStep(),
          const SizedBox(height: 12),
          _buildTimelineStep(),
          const SizedBox(height: 12),
          _buildTimelineStep(),
        ],
      ),
    );
  }

  Widget _buildTimelineStep() {
    return const Row(
      children: [
        ShimmerBlock(width: 24, height: 24),
        SizedBox(width: 12),
        ShimmerBlock(height: 14, width: 160),
      ],
    );
  }

  Widget _buildContent(DisputeDetailState state) {
    final dispute = state.dispute!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrutalistBreadcrumb(items: context.breadcrumbs),
          Spacing.vMd,
          BrutalistBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Status', dispute.status.label),
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
            const Text('Enviar Evidência', style: AppTypography.h3),
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
                    onTap: state.isSubmitting ? null : _submitEvidence,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Enviar Evidência',
                          style: AppTypography.button,
                        ),
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

    final success = await ref
        .read(disputeDetailProvider(widget.disputeId).notifier)
        .submitEvidence(evidence);
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
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: AppTypography.bodyMedium)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
