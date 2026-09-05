import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';

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
              'Acesse a aba Perfil no menu inferior e clique no botão "Editar Perfil". Você pode alterar seu avatar, bio, localização e chaves Pix.',
        },
        {
          'q': 'Esqueci minha senha, o que fazer?',
          'a':
              'Na tela de login, clique em "Esqueci minha senha". Digite seu e-mail cadastrado e você receberá um código de 6 dígitos para redefinir sua senha.',
        },
        {
          'q': 'Como funciona o login biométrico?',
          'a':
              'Após fazer login com e-mail e senha, você pode ativar a autenticação biométrica (Face ID ou impressão digital) para acessos rápidos e seguros nas próximas sessões.',
        },
      ],
    },
    {
      'title': 'COMPRAS E PAGAMENTOS',
      'items': [
        {
          'q': 'Como comprar um produto?',
          'a':
              'Navegue pelo Feed ou Explore, clique no produto desejado e depois em "Comprar". Você será direcionado para o checkout seguro onde poderá pagar com cartão de crédito via Stripe.',
        },
        {
          'q': 'O que é o sistema de Custódia (Escrow)?',
          'a':
              'Para garantir sua segurança, o pagamento fica retido em custódia até você receber o produto e confirmar a entrega. Somente após sua confirmação (ou prazo limite) o dinheiro é liberado ao vendedor.',
        },
        {
          'q': 'Como funciona o Carrinho?',
          'a':
              'Você pode adicionar produtos de diferentes vendedores ao carrinho e gerenciar quantidades. O checkout cria os pedidos com custódia individual para cada item.',
        },
        {
          'q': 'Quais formas de pagamento são aceitas?',
          'a':
              'Aceitamos cartões de crédito (Visa, Mastercard, Elo, Amex) processados com segurança pela Stripe.',
        },
        {
          'q': 'Como parcelar uma compra?',
          'a':
              'O parcelamento é disponibilizado na tela de pagamento da Stripe conforme as condições configuradas para o valor do pedido.',
        },
      ],
    },
    {
      'title': 'VENDAS E CARTEIRA',
      'items': [
        {
          'q': 'Como anunciar um produto?',
          'a':
              'Clique no botão "+" no menu inferior, adicione fotos, título, descrição detalhada, preço em reais e selecione a categoria. Seu anúncio ficará visível imediatamente.',
        },
        {
          'q': 'Qual é a taxa cobrada por venda?',
          'a':
              'Cobramos uma taxa fixa de 10% sobre o valor da venda. Essa taxa só é descontada quando a venda é concluída com sucesso e o comprador confirma a entrega.',
        },
        {
          'q': 'Quando recebo o dinheiro da venda?',
          'a':
              'O valor fica na sua Carteira como "Saldo em Custódia" até o comprador confirmar o recebimento. Após a confirmação, o saldo se torna "Disponível para Saque".',
        },
        {
          'q': 'Como solicitar um saque Pix?',
          'a':
              'Na sua Carteira, clique em "Solicitar Saque", insira o valor desejado (mínimo de R\$ 5,00) e confirme sua chave Pix cadastrada. O processamento é realizado em instantes.',
        },
      ],
    },
    {
      'title': 'DISPUTAS E SEGURANÇA',
      'items': [
        {
          'q': 'Não recebi o produto, o que fazer?',
          'a':
              'Acesse Meus Pedidos > selecione o pedido > clique em "Abrir Disputa". Como o dinheiro está em custódia, nossa equipe de mediação avaliará o caso e realizará o reembolso se procedente.',
        },
        {
          'q': 'O produto veio com defeito ou diferente do anunciado?',
          'a':
              'Abra uma disputa pelo app enviando fotos/vídeos que comprovem o problema. O vendedor terá um prazo para responder e podemos mediar a devolução.',
        },
        {
          'q': 'Como funciona o chat seguro?',
          'a':
              'Você pode conversar com compradores e vendedores em tempo real diretamente pelo app. Todo o histórico fica registrado para segurança de ambas as partes.',
        },
        {
          'q': 'Meus dados bancários estão seguros?',
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
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
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
