import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthButton extends StatelessWidget {
  const AppleAuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }
    return SignInWithAppleButton(
      text: text,
      iconAlignment: SignInWithAppleIconAlignment.left,
      onPressed: loading ? null : onPressed,
    );
  }
}
