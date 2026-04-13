import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../providers/profile_providers.dart';

class VehicleSetupScreen extends ConsumerStatefulWidget {
  const VehicleSetupScreen({super.key});

  @override
  ConsumerState<VehicleSetupScreen> createState() => _VehicleSetupScreenState();
}

class _VehicleSetupScreenState extends ConsumerState<VehicleSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  final _seatsController = TextEditingController(text: '4');
  bool _isLoading = false;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? v, String label) {
    if (v == null || v.trim().isEmpty) return 'Ingresa $label';
    return null;
  }

  String? _validateYear(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa el año';
    final year = int.tryParse(v.trim());
    final current = DateTime.now().year;
    if (year == null || year < 1950 || year > current + 1) {
      return 'Año inválido';
    }
    return null;
  }

  String? _validateSeats(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa los asientos';
    final seats = int.tryParse(v.trim());
    if (seats == null || seats < 1 || seats > 9) return '1 a 9 asientos';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(authServiceProvider).currentUserId;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay sesión activa')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final vehicle = VehicleEntity(
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      plate: _plateController.text.trim().toUpperCase(),
      color: _colorController.text.trim(),
      seats: int.parse(_seatsController.text.trim()),
    );

    final result =
        await ref.read(profileRepositoryProvider).saveVehicle(uid, vehicle);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) {
        context.goNamed('home');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos de tu vehículo'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Necesitamos los datos del auto para que los pasajeros puedan reconocerte.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _brandController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _validateRequired(v, 'la marca'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _validateRequired(v, 'el modelo'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Año',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateYear,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Placa',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _validateRequired(v, 'la placa'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _colorController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _validateRequired(v, 'el color'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _seatsController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Asientos disponibles',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateSeats,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
