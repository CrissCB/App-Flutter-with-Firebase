import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_button.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Continuar con Google',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      label: label,
      type: CustomButtonType.outlined,
      isLoading: isLoading,
      onPressed: onPressed,
      icon: const _GoogleLogo(),
    );
  }
}

/// Logo provisional dibujado con texto, para no depender de assets.
/// Para el logo oficial, agrega la imagen en assets/ y reemplaza este
/// widget por Image.asset('assets/google_logo.png', height: 22).
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w800,
          fontSize: 15,
          height: 1,
        ),
      ),
    );
  }
}
