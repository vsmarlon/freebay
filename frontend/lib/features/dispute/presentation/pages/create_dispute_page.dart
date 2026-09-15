import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/shared/services/http_client.dart';

class CreateDisputePage extends ConsumerStatefulWidget {
  final String orderId;

  const CreateDisputePage({super.key, required this.orderId});

  @override
  ConsumerState<CreateDisputePage> createState() => _CreateDisputePageState();
}

class _CreateDisputePageState extends ConsumerState<CreateDisputePage> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: 'ABRIR DISPUTA',
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BrutalistBreadcrumb(items: context.breadcrumbs),
                    Spacing.vMd,
                    const Text('Descreva o problema', style: AppTypography.h3),
                    Spacing.vSm,
                    const Text(
                      'Explique detalhadamente o que houve de errado com o pedido',
                      style: AppTypography.bodySmall,
                    ),
                    Spacing.vMd,
                    BrutalistBox(
                      child: TextField(
                        controller: _reasonController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText:
                              'Ex: Produto diferente do anunciado, não recebi o produto...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Spacing.vLg,
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        color: AppColors.error,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSubmitting ? null : _createDispute,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: _isSubmitting
                                    ? const ShimmerBlock(width: 20, height: 20)
                                    : const Text(
                                        'Abrir Disputa',
                                        style: AppTypography.button,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createDispute() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descreva o motivo da disputa')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await HttpClient.instance.post(
        '/disputes',
        data: {'orderId': widget.orderId, 'reason': reason},
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disputa aberta com sucesso')),
        );
        context.pop();
      } else {
        AppSnackbar.error(context, 'Não foi possível abrir a disputa.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao conectar com o servidor')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
