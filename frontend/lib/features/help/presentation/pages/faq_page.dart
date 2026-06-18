import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/components/spacing.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: const [
                _FaqSection(
                  title: 'CONTA E PERFIL',
                  items: [
                    _FaqItem(
                      question: 'Como criar uma conta?',
                      answer:
                          'Baixe o FreeBay e clique em "Criar conta". '
                          'Informe seu e-mail, nome de exibição e crie uma senha '
                          'de no mínimo 8 caracteres. Após confirmar o e-mail, '
                          'sua conta estará pronta para uso.',
                    ),
                    _FaqItem(
                      question: 'Como editar meu perfil?',
                      answer:
                          'Acesse seu perfil pelo menu inferior e clique no '
                          'botão "Editar perfil". Você pode alterar seu nome de '
                          'exibição, bio, foto e banner. As alterações são '
                          'salvas automaticamente.',
                    ),
                    _FaqItem(
                      question: 'Esqueci minha senha. O que fazer?',
                      answer:
                          'Na tela de login, clique em "Esqueci minha senha". '
                          'Insira o e-mail cadastrado e enviaremos um link para '
                          'redefinição. O link expira em 15 minutos por segurança.',
                    ),
                    _FaqItem(
                      question: 'Como excluir minha conta?',
                      answer:
                          'Vá em Configurações > Excluir conta. Sua conta será '
                          'desativada por 30 dias antes da exclusão permanente. '
                          'Durante este período, você pode reativá-la fazendo login.',
                    ),
                  ],
                ),
                _FaqSection(
                  title: 'FEED E POSTS',
                  items: [
                    _FaqItem(
                      question: 'Como criar um post?',
                      answer:
                          'No feed, clique no campo "Criar post social ou '
                          'anúncio de venda". Escolha entre post social '
                          '(fotos, textos) ou anúncio de produto. Adicione '
                          'suas imagens e escreva uma descrição.',
                    ),
                    _FaqItem(
                      question:
                          'Qual a diferença entre post social e anúncio?',
                      answer:
                          'Posts sociais são para compartilhar momentos, '
                          'fotos e interagir com a comunidade. Anúncios de '
                          'venda são listagens de produtos com preço, '
                          'categoria e opção de compra via escrow.',
                    ),
                    _FaqItem(
                      question: 'O que são stories?',
                      answer:
                          'Stories são posts temporários que desaparecem '
                          'após 24 horas. Para criar, clique no seu avatar '
                          'no feed ou no perfil. Você pode adicionar fotos '
                          'e textos criativos.',
                    ),
                    _FaqItem(
                      question: 'Como interagir com posts?',
                      answer:
                          'Você pode curtir, comentar e compartilhar posts. '
                          'Toque no coração para curtir, no balão para '
                          'comentar, ou no ícone de compartilhar para '
                          'enviar o post para outro usuário.',
                    ),
                  ],
                ),
                _FaqSection(
                  title: 'COMPRAS E VENDAS',
                  items: [
                    _FaqItem(
                      question: 'Como comprar um produto?',
                      answer:
                          'Navegue pelos anúncios no feed ou na aba '
                          '"Explorar". Ao encontrar um produto, toque nele '
                          'para ver detalhes e clique em "Comprar". O '
                          'pagamento é processado via escrow, garantindo '
                          'segurança para ambas as partes.',
                    ),
                    _FaqItem(
                      question: 'Como anunciar um produto para venda?',
                      answer:
                          'No feed, clique em "Criar anúncio de venda" ou '
                          'vá em seu perfil e clique no botão de criar. '
                          'Adicione fotos do produto, defina o preço (em '
                          'reais), escolha a categoria e descreva o item.',
                    ),
                    _FaqItem(
                      question: 'O que é pagamento por escrow?',
                      answer:
                          'Escrow é um sistema de pagamento seguro: quando '
                          'você compra, o valor fica retido conosco até '
                          'confirmar que recebeu o produto. Após a '
                          'confirmação, liberamos o pagamento ao vendedor.',
                    ),
                    _FaqItem(
                      question: 'Como funcionam as ofertas?',
                      answer:
                          'Você pode enviar uma oferta para o vendedor com '
                          'um valor diferente do anunciado. O vendedor pode '
                          'aceitar, recusar ou contra-propor. A negociação '
                          'é feita diretamente no chat do anúncio.',
                    ),
                  ],
                ),
                _FaqSection(
                  title: 'PAGAMENTOS E CARTEIRA',
                  items: [
                    _FaqItem(
                      question: 'Como adicionar saldo na carteira?',
                      answer:
                          'Acesse sua Carteira pelo menu inferior e clique '
                          'em "Adicionar fundos". Escolha o valor e o '
                          'método de pagamento (PIX, cartão). O saldo cai '
                          'na hora e fica disponível para compras.',
                    ),
                    _FaqItem(
                      question: 'Como solicitar um saque?',
                      answer:
                          'Na Carteira, clique em "Sacar". Escolha o valor '
                          'desejado (mínimo de R\$ 10,00) e a conta de '
                          'destino. O prazo de processamento é de até 2 '
                          'dias úteis para conta bancária.',
                    ),
                    _FaqItem(
                      question:
                          'Diferença entre saldo pendente e disponível?',
                      answer:
                          'Saldo disponível é o valor que você pode usar '
                          'ou sacar imediatamente. Saldo pendente são '
                          'valores de vendas em escrow que ainda não foram '
                          'liberados — ficam disponíveis após a confirmação '
                          'do comprador.',
                    ),
                    _FaqItem(
                      question: 'Quais as taxas do FreeBay?',
                      answer:
                          'O FreeBay cobra uma taxa de 5% sobre o valor '
                          'de cada venda concluída. Depósitos e saques são '
                          'gratuitos. Não há taxa de anúncio ou '
                          'mensalidade.',
                    ),
                  ],
                ),
                _FaqSection(
                  title: 'SEGURANÇA E PRIVACIDADE',
                  items: [
                    _FaqItem(
                      question: 'Como bloquear um usuário?',
                      answer:
                          'No perfil do usuário, clique no menu de opções '
                          '(três pontos) e selecione "Bloquear". Usuários '
                          'bloqueados não podem ver seu perfil, enviar '
                          'mensagens ou interagir com seus posts.',
                    ),
                    _FaqItem(
                      question: 'Como denunciar um conteúdo?',
                      answer:
                          'Em qualquer post, perfil ou mensagem, clique '
                          'no menu de opções e selecione "Denunciar". '
                          'Escolha o motivo e nossa equipe analisará o '
                          'caso em até 24 horas.',
                    ),
                    _FaqItem(
                      question: 'Quem pode ver meus stories?',
                      answer:
                          'Por padrão, todos os seguidores podem ver seus '
                          'stories. Você pode alterar a privacidade em '
                          'Configurações > Privacidade, escolhendo entre '
                          '"Todos", "Apenas seguidores" ou "Personalizado".',
                    ),
                    _FaqItem(
                      question: 'Como proteger meus dados?',
                      answer:
                          'Recomendamos ativar a autenticação em duas '
                          'etapas em Configurações > Segurança. Nunca '
                          'compartilhe sua senha e desconfie de mensagens '
                          'solicitando dados pessoais.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  final String title;
  final List<_FaqItem> items;

  const _FaqSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Spacing.vLg,
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: context.textPrimary,
          ),
        ),
        Spacing.vSm,
        ...items,
      ],
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _isExpanded = false;

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      children: [
        InkWell(
          onTap: _toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              border: Border.all(color: AppColors.onSurface, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.onSurface,
                    ),
                  ),
                ),
                Spacing.hSm,
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    _isExpanded ? Icons.remove : Icons.add,
                    key: ValueKey(_isExpanded),
                    size: 20,
                    color: _isExpanded
                        ? AppColors.primaryContainer
                        : (isDark
                            ? AppColors.white
                            : AppColors.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          curve: Curves.linear,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.surfaceContainerLow,
                    border: Border(
                      left: BorderSide(color: AppColors.onSurface, width: 2),
                      right: BorderSide(color: AppColors.onSurface, width: 2),
                      bottom: BorderSide(color: AppColors.onSurface, width: 2),
                    ),
                  ),
                  child: Text(
                    widget.answer,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? AppColors.mediumGray : AppColors.onSurface,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Spacing.vSm,
      ],
    );
  }
}
