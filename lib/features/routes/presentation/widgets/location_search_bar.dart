import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/geocoding_result.dart';
import '../providers/driver_route_providers.dart';

class LocationSearchBar extends ConsumerStatefulWidget {
  final String label;
  final String? initialValue;
  final ValueChanged<GeocodingResult> onResultSelected;

  const LocationSearchBar({
    super.key,
    required this.label,
    required this.onResultSelected,
    this.initialValue,
  });

  @override
  ConsumerState<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends ConsumerState<LocationSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String _searchQuery = '';
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant LocationSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue ?? '';
      _showResults = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted && value.trim().length >= 3) {
        setState(() {
          _searchQuery = value.trim();
          _showResults = true;
        });
      } else if (mounted) {
        setState(() => _showResults = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          onTap: () {
            if (_searchQuery.length >= 3) {
              setState(() => _showResults = true);
            }
          },
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _searchQuery = '';
                        _showResults = false;
                      });
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        if (_showResults && _searchQuery.length >= 3)
          _buildResults(),
      ],
    );
  }

  Widget _buildResults() {
    final results = ref.watch(geocodingSearchProvider(_searchQuery));

    return results.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Error al buscar', style: TextStyle(color: AppColors.error)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Sin resultados',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.location_on,
                    size: 20, color: AppColors.primary),
                title: Text(item.name,
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  item.fullAddress,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  _controller.text = item.name;
                  setState(() => _showResults = false);
                  widget.onResultSelected(item);
                },
              );
            },
          ),
        );
      },
    );
  }
}
