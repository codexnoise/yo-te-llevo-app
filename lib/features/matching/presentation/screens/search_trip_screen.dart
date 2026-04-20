import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/lat_lng.dart';
import '../../../routes/domain/entities/geocoding_result.dart';
import '../../../routes/presentation/widgets/location_search_bar.dart';
import '../../domain/entities/match_search_input.dart';
import '../providers/matching_providers.dart';

const _weekDays = <_WeekDay>[
  _WeekDay('mon', 'Lun'),
  _WeekDay('tue', 'Mar'),
  _WeekDay('wed', 'Mié'),
  _WeekDay('thu', 'Jue'),
  _WeekDay('fri', 'Vie'),
  _WeekDay('sat', 'Sáb'),
  _WeekDay('sun', 'Dom'),
];

class SearchTripScreen extends ConsumerStatefulWidget {
  const SearchTripScreen({super.key});

  @override
  ConsumerState<SearchTripScreen> createState() => _SearchTripScreenState();
}

class _SearchTripScreenState extends ConsumerState<SearchTripScreen> {
  GeocodingResult? _origin;
  GeocodingResult? _destination;
  final Set<String> _selectedDays = {};
  TimeOfDay? _departureTime;

  bool get _canSubmit =>
      _origin != null && _destination != null && _selectedDays.isNotEmpty;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _departureTime = picked);
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final input = MatchSearchInput(
      origin: LatLng(
        _origin!.coordinates.latitude,
        _origin!.coordinates.longitude,
      ),
      destination: LatLng(
        _destination!.coordinates.latitude,
        _destination!.coordinates.longitude,
      ),
      days: _selectedDays.toList(),
      departureTime:
          _departureTime != null ? _formatTime(_departureTime!) : null,
    );

    // Arrancamos la búsqueda sin await — MatchResultsScreen muestra el
    // loading directamente desde el estado del notifier.
    unawaited(
      ref.read(matchingNotifierProvider.notifier).searchMatches(input),
    );
    context.push('/search/results');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar viaje')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LocationSearchBar(
                label: 'Origen',
                initialValue: _origin?.fullAddress,
                onResultSelected: (result) =>
                    setState(() => _origin = result),
              ),
              const SizedBox(height: 16),
              LocationSearchBar(
                label: 'Destino',
                initialValue: _destination?.fullAddress,
                onResultSelected: (result) =>
                    setState(() => _destination = result),
              ),
              const SizedBox(height: 24),
              Text(
                'Días',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _weekDays.map((d) {
                  final selected = _selectedDays.contains(d.code);
                  return FilterChip(
                    label: Text(d.label),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedDays.add(d.code);
                      } else {
                        _selectedDays.remove(d.code);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Hora de salida (opcional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _departureTime != null
                      ? _formatTime(_departureTime!)
                      : 'Seleccionar hora',
                ),
              ),
              if (_departureTime != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _departureTime = null),
                  child: const Text('Quitar hora'),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _canSubmit ? _submit : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Buscar conductores'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekDay {
  final String code;
  final String label;
  const _WeekDay(this.code, this.label);
}
