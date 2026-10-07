import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_colors.dart';
import 'state.dart';
import 'screens.dart' show ResponsiveCenter, BouncingWidget;

// --- SAVED ADDRESSES SCREEN ---
class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  void _showAddDialog(BuildContext context, AppState state) {
    final labelC = TextEditingController();
    final addressC = TextEditingController();
    bool makeDefault = state.savedAddresses.isEmpty;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add New Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelC,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: "Label (e.g. Home, Work)", prefixIcon: Icon(Icons.label_outline_rounded, color: AppColors.primary)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressC,
                  keyboardType: TextInputType.streetAddress,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Full address",
                    hintText: "Street, Barangay, Town",
                    errorText: error,
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  ),
                ),
                if (state.savedAddresses.isNotEmpty)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primary,
                    title: const Text("Set as primary address", style: TextStyle(fontSize: 13)),
                    value: makeDefault,
                    onChanged: (v) => setDialog(() => makeDefault = v ?? false),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                if (addressC.text.trim().length < 5) {
                  setDialog(() => error = "Please enter your full address");
                  return;
                }
                final label = labelC.text.trim().isEmpty ? "Address ${state.savedAddresses.length + 1}" : labelC.text.trim();
                state.addAddress(label, addressC.text, makeDefault: makeDefault);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address saved.")));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text("SAVE"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final state = AppStateProvider.of(context);
    final addresses = state.savedAddresses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Saved Addresses", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            if (addresses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 14),
                    const Text("No saved addresses yet.", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
                  ],
                ),
              ),
            ...List.generate(addresses.length, (i) => _buildAddressCard(context, state, addresses[i], isDefault: i == 0)),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () => _showAddDialog(context, state),
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text("ADD NEW ADDRESS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: brandColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, AppState state, SavedAddress a, {required bool isDefault}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDefault ? AppColors.primary : Colors.grey.shade200, width: isDefault ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: isDefault ? AppColors.primary.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(a.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink))),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Text("PRIMARY", style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(a.address, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              if (!isDefault)
                TextButton.icon(
                  onPressed: () => state.makeDefaultAddress(a.id),
                  icon: const Icon(Icons.star_outline_rounded, size: 16),
                  label: const Text("Set as primary", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              TextButton.icon(
                onPressed: () {
                  state.removeAddress(a.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address removed.")));
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text("Remove", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- PAYMENT METHODS SCREEN ---
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  Color _colorFor(String type) => type == 'GCash' ? const Color(0xFF0077FF) : const Color(0xFF00B14F);

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final state = AppStateProvider.of(context);
    final methods = state.savedPaymentMethods;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Payment Methods", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (methods.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 14),
                    const Text("No payment methods yet.", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Text("Add your GCash or PayMaya account.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              )
            else ...[
              const Text("Saved E-Wallets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 15),
              ...methods.map((m) => _buildPaymentTile(context, state, m)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPaymentMethodScreen())),
                icon: const Icon(Icons.add_rounded),
                label: const Text("ADD PAYMENT METHOD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTile(BuildContext context, AppState state, SavedPaymentMethod m) {
    final color = _colorFor(m.type);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: AppColors.border)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(m.type == 'GCash' ? Icons.account_balance_wallet_rounded : Icons.wallet_rounded, color: color),
        ),
        title: Text(m.type, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${m.accountName}\n${m.phone}"),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
          tooltip: "Remove",
          onPressed: () {
            state.removePaymentMethod(m.id);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${m.type} account removed.")));
          },
        ),
      ),
    );
  }
}

// --- ADD PAYMENT METHOD SCREEN ---
class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  String _type = 'GCash';
  final TextEditingController _nameC = TextEditingController();
  final TextEditingController _phoneC = TextEditingController();
  String? _nameError;
  String? _phoneError;

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameC.text.trim();
    final digits = _phoneC.text.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      _nameError = name.length < 2 ? "Please enter the account name" : null;
      _phoneError = digits.length < 10 || digits.length > 13 ? "Please enter a valid phone number" : null;
    });
    if (_nameError != null || _phoneError != null) return;

    AppStateProvider.of(context).addPaymentMethod(type: _type, accountName: name, phone: _phoneC.text);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$_type account saved.")));
  }

  Widget _typeTile(String type, IconData icon, Color color) {
    final bool selected = _type == type;
    return Expanded(
      child: BouncingWidget(
        onTap: () => setState(() => _type = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(type, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? color : AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Add Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        maxWidth: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Choose e-wallet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _typeTile('GCash', Icons.account_balance_wallet_rounded, const Color(0xFF0077FF)),
                  const SizedBox(width: 12),
                  _typeTile('PayMaya', Icons.wallet_rounded, const Color(0xFF00B14F)),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameC,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: "Account name",
                  errorText: _nameError,
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneC,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "$_type phone number",
                  hintText: "09XX XXX XXXX",
                  errorText: _phoneError,
                  prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ADMIN: GCASH / PAYMAYA QR CODE UPLOAD ---
class AdminPaymentQrScreen extends StatelessWidget {
  const AdminPaymentQrScreen({super.key});

  Future<void> _pick(BuildContext context, AppState state, String method) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      state.setQr(method, bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$method QR code saved. Customers will see it when paying.")));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open the photo gallery. Please allow photo access and try again.")));
      }
    }
  }

  Widget _qrCard(BuildContext context, AppState state, String method, Color color) {
    final qr = state.qrFor(method);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(method == 'GCash' ? Icons.account_balance_wallet_rounded : Icons.wallet_rounded, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text("$method QR Code", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: (qr == null ? AppColors.warning : AppColors.success).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  qr == null ? "NOT SET" : "ACTIVE",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: qr == null ? AppColors.warning : AppColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: qr == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text("No QR uploaded yet", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              )
                  : ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(qr, fit: BoxFit.contain)),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pick(context, state, method),
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: Text(qr == null ? "Upload QR" : "Replace QR", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (qr != null)
                OutlinedButton.icon(
                  onPressed: () => state.setQr(method, null),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text("Remove", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Payment QR Codes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "Upload your shop's GCash and PayMaya QR codes. Customers see them when they choose that payment method while placing an order.",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _qrCard(context, state, 'GCash', const Color(0xFF0077FF)),
            const SizedBox(height: 16),
            _qrCard(context, state, 'PayMaya', const Color(0xFF00B14F)),
          ],
        ),
      ),
    );
  }
}