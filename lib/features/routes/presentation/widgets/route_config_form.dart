import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/pricing_type.dart';
import '../providers/driver_route_providers.dart';

class RouteConfigForm extends ConsumerStatefulWidget {
  const RouteConfigForm({super.key});

  @override
  ConsumerState<RouteConfigForm> createState() => _RouteConfigFormState();
}

class _RouteConfigFormState extends ConsumerState<RouteConfigForm> {
  late TextEditingController _amountController;
  late TextEditingController _departureTimeController;
  late TextEditingController _returnTimeController;
  bool _showReturnTime = false;

  static const _dayLabels = {
    'mon': 'L',
    'tue': 'M',
    'wed': 'Mi',
    'thu': 'J',
    'fri': 'V',
    'sat': 'S',
    'sun': 'D',
  };

  static const _dayOrder = [
    'mon',
    'tue',
    'wed',
    'thu',
    'fri',
    'sat',
    'sun',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(createRouteNotifierProvider);
    _amountController =
        TextEditingController(text: state.pricing.amount > 0 ? state.pricing.amount.toStringAsFixed(2) : '');
    _departureTimeController =
        TextEditingController(text: state.schedule.departureTime);
    _returnTimeController =
        TextEditingController(text: state.schedule.returnTime ?? '');
    _showReturnTime = state.schedule.returnTime != null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _departureTimeController.dispose();
    _returnTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRouteNotifierProvider);
    final notifier = ref.read(createRouteNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Days selector
        const Text('Dias de viaje',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: _dayOrder.map((day) {
            final isSelected = state.schedule.days.contains(day);
            return FilterChip(
              label: Text(_dayLabels[day]!),
              selected: isSelected,
              onSelected: (selected) {
                final days = List<String>.from(state.schedule.days);
                if (selected) {
                  days.add(day);
                } else {
                  days.remove(day);
                }
                notifier.updateSchedule(
                    state.schedule.copyWith(days: days));
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Departure time
        TextFormField(
          controller: _departureTimeController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Hora de salida',
            prefixIcon: Icon(Icons.access_time),
            border: OutlineInputBorder(),
          ),
          onTap: () => _pickTime(
            context: context,
            controller: _departureTimeController,
            onPicked: (time) {
              notifier.updateSchedule(
                  state.schedule.copyWith(departureTime: time));
            },
          ),
        ),
        const SizedBox(height: 12),

        // Return time toggle
        Row(
          children: [
            Switch(
              value: _showReturnTime,
              onChanged: (value) {
                setState(() => _showReturnTime = value);
                if (!value) {
                  _returnTimeController.clear();
                  notifier.updateSchedule(
                      state.schedule.copyWith(returnTime: () => null));
                }
              },
            ),
            const Text('Agregar horario de retorno',
                style: TextStyle(fontSize: 14)),
          ],
        ),
        if (_showReturnTime) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _returnTimeController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Hora de retorno',
              prefixIcon: Icon(Icons.access_time),
              border: OutlineInputBorder(),
            ),
            onTap: () => _pickTime(
              context: context,
              controller: _returnTimeController,
              onPicked: (time) {
                notifier.updateSchedule(
                    state.schedule.copyWith(returnTime: () => time));
              },
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Available seats
        const Text('Asientos disponibles',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: state.availableSeats > 1
                  ? () =>
                      notifier.updateAvailableSeats(state.availableSeats - 1)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                '${state.availableSeats}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: state.availableSeats < 8
                  ? () =>
                      notifier.updateAvailableSeats(state.availableSeats + 1)
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Pricing type
        DropdownButtonFormField<PricingType>(
          initialValue: state.pricing.type,
          decoration: const InputDecoration(
            labelText: 'Tipo de tarifa',
            prefixIcon: Icon(Icons.monetization_on_outlined),
            border: OutlineInputBorder(),
          ),
          items: PricingType.values
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  ))
              .toList(),
          onChanged: (type) {
            if (type != null) {
              notifier.updatePricing(state.pricing.copyWith(type: type));
            }
          },
        ),
        const SizedBox(height: 12),

        // Amount
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0;
            notifier.updatePricing(
                state.pricing.copyWith(amount: amount));
          },
        ),
      ],
    );
  }

  Future<void> _pickTime({
    required BuildContext context,
    required TextEditingController controller,
    required ValueChanged<String> onPicked,
  }) async {
    final parts = controller.text.split(':');
    final initialHour = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 7;
    final initialMinute = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (time != null) {
      final formatted =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      controller.text = formatted;
      onPicked(formatted);
    }
  }
}
