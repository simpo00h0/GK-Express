import 'package:flutter/material.dart';
import '../models/parcel.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'parcel_detail_screen.dart';

class CreateParcelScreen extends StatefulWidget {
  final Function(Parcel) onParcelCreated;

  const CreateParcelScreen({super.key, required this.onParcelCreated});

  @override
  State<CreateParcelScreen> createState() => _CreateParcelScreenState();
}

class _CreateParcelScreenState extends State<CreateParcelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _destinationController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isPaid = false;
  bool _isLoading = false;

  List<Office> _offices = [];
  Office? _originOffice;
  Office? _destinationOffice;

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  Future<void> _loadOffices() async {
    final offices = await AuthService.fetchOffices();
    setState(() {
      _offices = offices;
      // Set origin office to user's office if agent
      if (AuthService.currentUser?.officeId != null) {
        _originOffice = offices.firstWhere(
          (o) => o.id == AuthService.currentUser!.officeId,
          orElse: () => offices.first,
        );
      }
    });
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _createParcel() async {
    if (_formKey.currentState!.validate()) {
      if (_originOffice == null || _destinationOffice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Veuillez sélectionner les bureaux d\'origine et de destination',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final newParcel = await ApiService.createParcel(
        senderName: _senderNameController.text,
        senderPhone: _senderPhoneController.text,
        receiverName: _receiverNameController.text,
        receiverPhone: _receiverPhoneController.text,
        destination: _destinationController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        isPaid: _isPaid,
        originOfficeId: _originOffice!.id,
        destinationOfficeId: _destinationOffice!.id,
      );

      setState(() => _isLoading = false);

      if (newParcel != null && mounted) {
        widget.onParcelCreated(newParcel);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ParcelDetailScreen(parcel: newParcel, onStatusUpdated: () {}),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création du colis')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Créer un Nouveau Colis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Office Selection Section
              _buildSectionCard(
                'Bureaux',
                Icons.business_rounded,
                const Color(0xFF9C27B0),
                [
                  DropdownButtonFormField<Office>(
                    initialValue: _originOffice,
                    decoration: const InputDecoration(
                      labelText: 'Bureau d\'Origine',
                      prefixIcon: Icon(Icons.location_city_rounded),
                    ),
                    items: _offices.map((office) {
                      return DropdownMenuItem(
                        value: office,
                        child: Text('${office.flag} ${office.name}'),
                      );
                    }).toList(),
                    onChanged: AuthService.currentUser?.role == 'agent'
                        ? null // Agents can't change origin office
                        : (value) => setState(() => _originOffice = value),
                    validator: (value) =>
                        value == null ? 'Bureau d\'origine requis' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Office>(
                    initialValue: _destinationOffice,
                    decoration: const InputDecoration(
                      labelText: 'Bureau de Destination',
                      prefixIcon: Icon(Icons.flight_takeoff_rounded),
                    ),
                    items: _offices.map((office) {
                      return DropdownMenuItem(
                        value: office,
                        child: Text('${office.flag} ${office.name}'),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _destinationOffice = value),
                    validator: (value) =>
                        value == null ? 'Bureau de destination requis' : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionCard(
                'Expéditeur',
                Icons.person_outline_rounded,
                const Color(0xFF667EEA),
                [
                  TextFormField(
                    controller: _senderNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom Complet',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senderPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Requis' : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionCard(
                'Destinataire',
                Icons.person_rounded,
                const Color(0xFFF093FB),
                [
                  TextFormField(
                    controller: _receiverNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom Complet',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _receiverPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Requis' : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionCard(
                'Détails de l\'Expédition',
                Icons.local_shipping_rounded,
                const Color(0xFF4FACFE),
                [
                  TextFormField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse de Destination',
                      prefixIcon: Icon(Icons.location_on_rounded),
                      hintText: 'Ville, Adresse complète',
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Prix (FCFA)',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      if (double.tryParse(value) == null) {
                        return 'Montant invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isPaid
                          ? Colors.green.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isPaid
                            ? Colors.green.shade200
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isPaid
                              ? Icons.check_circle_rounded
                              : Icons.pending_rounded,
                          color: _isPaid ? Colors.green : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Statut de Paiement',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _isPaid
                                  ? Colors.green.shade900
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isPaid,
                          onChanged: (value) => setState(() => _isPaid = value),
                          activeTrackColor: Colors.green.withValues(alpha: 0.5),
                          activeThumbColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createParcel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_rounded, size: 22),
                            SizedBox(width: 12),
                            Text(
                              'CRÉER LE COLIS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
