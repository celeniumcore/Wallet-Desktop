import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/biometric_service.dart';
import '../services/wallet_storage.dart';
import '../strings.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({
    super.key,
    required this.onVerified,
    this.allowBiometric = true,
    this.title,
    this.subtitle,
  });
  final VoidCallback onVerified;
  final bool allowBiometric;
  final String? title;
  final String? subtitle;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _biometricReady = false;
  bool _biometricTried = false;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    if (!widget.allowBiometric) return;
    final enabled = await WalletStorage.loadBiometric();
    if (!enabled) return;
    final available = await BiometricService.instance.isAvailable();
    if (!mounted) return;
    setState(() => _biometricReady = available);
    if (available && !_biometricTried) {
      _biometricTried = true;
      // Auto-prompt once for convenience
      await _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (!_biometricReady || _loading) return;
    final ok = await BiometricService.instance.authenticate(
      reason: S.biometrikBukaReason,
    );
    if (!mounted) return;
    if (ok) {
      widget.onVerified();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _ctrl.text.trim();
    if (pin.length < 4) {
      setState(() => _error = S.pinMin);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await WalletStorage.verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      widget.onVerified();
    } else {
      setState(() {
        _loading = false;
        _error = S.pinSalah;
        _ctrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CenTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: CenTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: CenTheme.line),
                    ),
                    child: Icon(
                      _biometricReady ? Icons.fingerprint : Icons.lock_rounded,
                      color: CenTheme.acid,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.title ?? S.bukaDompet,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: CenTheme.txt,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle ??
                        (_biometricReady
                            ? S.pinSubBiometrik
                            : S.pinSub),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13.5, color: CenTheme.sub, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _ctrl,
                    obscureText: true,
                    obscuringCharacter: '•',
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: CenTheme.txt,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                      hintStyle: const TextStyle(
                          color: CenTheme.muted, letterSpacing: 8),
                      filled: true,
                      fillColor: CenTheme.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: CenTheme.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: CenTheme.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: CenTheme.acid),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style:
                            const TextStyle(color: CenTheme.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: CenTheme.primaryBtn,
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: CenTheme.bg),
                            )
                          : Text(S.buka),
                    ),
                  ),
                  if (_biometricReady) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _tryBiometric,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CenTheme.txt,
                          side: const BorderSide(color: CenTheme.line),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon:
                            const Icon(Icons.fingerprint, color: CenTheme.acid),
                        label: Text(S.gunakanSidikJari),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
