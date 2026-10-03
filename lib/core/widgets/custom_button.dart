import 'package:flutter/material.dart';

enum CustomButtonType { filled, outlined }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.type = CustomButtonType.filled,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Si es true, muestra un spinner y deshabilita el botón.
  final bool isLoading;

  /// Widget opcional a la izquierda del texto (por ejemplo, un icono).
  final Widget? icon;

  final CustomButtonType type;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    final Widget child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: type == CustomButtonType.filled
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 10)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    switch (type) {
      case CustomButtonType.filled:
        return FilledButton(onPressed: effectiveOnPressed, child: child);
      case CustomButtonType.outlined:
        return OutlinedButton(onPressed: effectiveOnPressed, child: child);
    }
  }
}
