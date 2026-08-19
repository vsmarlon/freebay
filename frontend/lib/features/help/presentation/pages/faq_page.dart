import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  static const List<Map<String, dynamic>> _sections = [
    {
      'title': 'CONTA E PERFIL',
      'items': [
        {
          'q': 'Como criar uma conta?',
          'a':
              'Baixe o FreeBay e clique em "Criar conta". Informe seu e-mail, nome de exibição e crie uma senha de no mínimo 8 caracteres. Após confirmar o e-mail, sua conta estará pronta para uso.',
        },
        {
          'q': 'Como editar meu perfil?',
          'a':
              'Acesse seu perfil pelo menu inferior e clique no botão "Editar perfil". Você pode alterar seu nome de exibição, bio, foto e banner. As alterações são salvas automaticamente.',
        },
        {
          'q': 'Esqueci minha senha. O que fazer?',
          'a':
              'Na tela de login, clique em "Esqueci minha senha". Insira o e-mail cadastrado e enviaremos um link para redefinição. O link expira em 15 minutos por segurança.',
        },
        {
          'q': 'Como excluir minha conta?',
          'a':
              'Vá em Configurações > Excluir conta. Sua conta será desativada por 30 dias antes da exclusão permanente. Durante esse período, você pode reativá-la fazendo login.',
        },
      ],
    },
    {
      'title': 'COMPRAS E PAGAMENTOS',
      'items': [
        {
          'q': 'Quais são os métodos de pagamento aceitos?',
          'a':
              'Aceitamos cartão de crédito (Visa, Mastercard, Elo, Hipercard) e PIX via Stripe. Pagamentos via PIX são aprovados instantaneamente.',
        },
        {
          'q': 'O que é o sistema de custódia (escrow)?',
          'a':
              'Quando você compra um produto, o valor fica retido com segurança pelo FreeBay. O vendedor só recebe o dinheiro após você confirmar que recebeu o produto em perfeitas condições.',
        },
        {
          'q': 'Como funciona o cancelamento de uma compra?',
          'a':
              'Você pode cancelar uma compra antes do vendedor confirmar o envio. Após o envio, é necessário abrir uma disputa para solicitar o reembolso.',
        },
        {
          'q': 'Em quanto tempo recebo meu reembolso?',
          'a':
              'Para pagamentos via PIX, o reembolso é instantâneo na sua carteira FreeBay. Para cartão de crédito, o estorno pode levar de 5 a 10 dias úteis dependendo da operadora.',
        },
      ],
    },
    {
      'title': 'VENDAS E CARTEIRA',
      'items': [
        {
          'q': 'Como anunciar um produto?',
          'a':
              'Toque no botão central "+" no menu inferior, tire ou selecione fotos do produto, preencha o título, descrição, categoria, condição e preço. Revise e publique!',
        },
        {
          'q': 'Existe alguma taxa para vender?',
          'a':
              'O FreeBay cobra uma taxa de 0% na fase de lançamento! Você recebe 100% do valor da sua venda diretamente na sua carteira após a confirmação de entrega pelo comprador.',
        },
        {
          'q': 'Como sacar meu dinheiro da carteira?',
          'a':
              'Acesse a aba Carteira, clique em "Solicitar saque via PIX", insira o valor desejado e sua chave PIX. O saque mínimo é de R\$ 10,00 e o processamento é rápido.',
        },
        {
          'q': 'O que acontece se o comprador não confirmar a entrega?',
          'a':
              'Se o comprador não confirmar em até 7 dias após o envio comprovado, a entrega é confirmada automaticamente pelo sistema e o saldo é liberado na sua carteira.',
        },
      ],
    },
    {
      'title': 'SEGURANÇA E DISPUTAS',
      'items': [
        {
          'q': 'O que fazer se o produto não chegar ou vier com defeito?',
          'a':
              'Abra uma disputa na página do pedido em até 7 dias após o prazo estimado de entrega. Nossa equipe de moderação avaliará as evidências e mediará uma solução justa.',
        },
        {
          'q': 'Como denunciar um usuário ou produto?',
          'a':
              'Toque nos três pontos no canto superior direito do perfil ou anúncio e selecione "Denunciar". Escolha o motivo e adicione detalhes para que nossa equipe investigue.',
        },
        {
          'q': 'Meus dados estão seguros no FreeBay?',
          'a':
              'Sim! Todos os dados de pagamento são processados com criptografia de ponta a ponta pela Stripe (certificação PCI-DSS Nível 1). Nunca armazenamos dados de cartão.',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'FAQ / AJUDA',
            leading: GestureDetector(
              onTap: () => context.pop(),
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
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: _sections.length,
              itemBuilder: (context, sIndex) {
                final sec = _sections[sIndex];
                final items = sec['items'] as List<Map<String, String>>;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        sec['title'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: context.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...items.map(
                      (item) =>
                          _FaqTile(question: item['q']!, answer: item['a']!),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.remove : Icons.add,
                    size: 18,
                    color: context.textPrimary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              color: context.surfaceColor,
              child: Text(
                widget.answer,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: context.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
