import 'package:flutter/material.dart';

import '../../features/trips/domain/entities/cancel_scope.dart';
import '../theme/app_colors.dart';

/// Modal de cancelación con 3 opciones (spec viajes recurrentes §6.3):
/// - "Sólo esta fecha" → [CancelScope.occurrence]
/// - "Toda la serie" → [CancelScope.series]
/// - "Volver" → null
///
/// Para `tripType=oneTime` se debe pasar [showSeriesOption] = false: en ese
/// caso el modal se reduce a un confirm simple.
Future<CancelScope?> showCancelScopeDialog(
  BuildContext context, {
  bool showSeriesOption = true,
  String title = '¿Cancelar viaje?',
  String? body,
}) async {
  return showDialog<CancelScope>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(
        body ??
            (showSeriesOption
                ? '¿Quieres cancelar sólo esta fecha o toda la serie?'
                : 'Esta acción no se puede deshacer.'),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        if (showSeriesOption)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(CancelScope.occurrence),
            child: const Text('Sólo esta fecha'),
          ),
        if (showSeriesOption)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(CancelScope.series),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Toda la serie'),
          ),
        if (!showSeriesOption)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(CancelScope.occurrence),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Confirmar'),
          ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Volver'),
        ),
      ],
    ),
  );
}
