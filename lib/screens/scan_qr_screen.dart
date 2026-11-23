import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zxing2/qrcode.dart';

import '../strings.dart';
import '../theme.dart';

/// Scans a CEN address QR and pops the screen with the decoded text.
///
/// Phones use the live camera (front camera by default, switchable). Desktop
/// has no camera plugin, so the desktop branch decodes a QR image file with
/// zxing2 and still accepts a pasted address.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.front,
  );
  bool _done = false;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final code = capture.barcodes
        .map((b) => b.rawValue ?? '')
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    if (code.isEmpty) return;
    _done = true;
    Navigator.of(context).pop(code.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CenTheme.bg,
      appBar: AppBar(
        backgroundColor: CenTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CenTheme.txt),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          S.pindaiQRAlamat,
          style: const TextStyle(
              color: CenTheme.txt, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: _isMobile
            ? [
                IconButton(
                  tooltip: S.gantiKamera,
                  icon: const Icon(Icons.cameraswitch, color: CenTheme.muted),
                  onPressed: () => _ctrl.switchCamera(),
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CenTheme.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: CenTheme.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: _isMobile
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(controller: _ctrl, onDetect: _onDetect),
                          IgnorePointer(
                            child: Center(
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: CenTheme.acid.withValues(alpha: 0.8),
                                      width: 2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Platform.isWindows
                        ? _WindowsCameraPanel(
                            onSubmit: (v) => Navigator.of(context).pop(v.trim()),
                          )
                        : _DesktopQrPanel(
                            onSubmit: (v) => Navigator.of(context).pop(v.trim()),
                          ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isMobile
                  ? S.scanHint
                  : Platform.isWindows
                      ? S.kameraHintDesktop
                      : S.kameraDesktopTidakAda,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: CenTheme.muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// zxing2 needs ARGB ints; the `image` package gives raw RGBA bytes.

/// Windows has no ML Kit. The `camera` plugin gives a live preview and a still
/// frame; zxing2 decodes that frame. Frame streaming is unsupported on Windows,
/// so scanning is a button press instead of continuous detection.
class _WindowsCameraPanel extends StatefulWidget {
  const _WindowsCameraPanel({required this.onSubmit});
  final ValueChanged<String> onSubmit;

  @override
  State<_WindowsCameraPanel> createState() => _WindowsCameraPanelState();
}

class _WindowsCameraPanelState extends State<_WindowsCameraPanel> {
  List<CameraDescription> _cams = const [];
  CameraController? _cam;
  int _idx = 0;
  bool _opening = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    List<CameraDescription> cams;
    try {
      cams = await availableCameras();
    } catch (_) {
      cams = const [];
    }
    if (!mounted) return;
    if (cams.isEmpty) {
      setState(() => _opening = false);
      return;
    }
    _cams = cams;
    final front =
        cams.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
    _idx = front == -1 ? 0 : front;
    await _open();
  }

  Future<void> _open() async {
    final previous = _cam;
    _cam = null;
    await previous?.dispose();
    if (_cams.isEmpty) return;
    final c = CameraController(
      _cams[_idx],
      ResolutionPreset.high,
      enableAudio: false,
    );
    _cam = c;
    try {
      await c.initialize();
    } catch (_) {
      // Lens busy or driver refused; build() falls back to the file picker.
    }
    if (mounted) setState(() => _opening = false);
  }

  Future<void> _scan() async {
    final cam = _cam;
    if (cam == null || !cam.value.isInitialized || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final shot = await cam.takePicture();
      final code = decodeQrBytes(await shot.readAsBytes());
      if (!mounted) return;
      if (code == null || code.isEmpty) {
        setState(() {
          _busy = false;
          _error = S.gagalBacaQr;
        });
        return;
      }
      widget.onSubmit(code);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = S.gagalBacaQr;
        });
      }
    }
  }

  Future<void> _next() async {
    if (_cams.length < 2 || _busy) return;
    _idx = (_idx + 1) % _cams.length;
    setState(() {
      _opening = true;
      _error = null;
    });
    await _open();
  }

  @override
  void dispose() {
    _cam?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam = _cam;
    if (_opening) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (cam == null || !cam.value.isInitialized) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Text(
              S.kameraTidakAda,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5, color: CenTheme.muted, height: 1.45),
            ),
          ),
          Expanded(child: _DesktopQrPanel(onSubmit: widget.onSubmit)),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(cam),
              IgnorePointer(
                child: Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: CenTheme.acid.withValues(alpha: 0.8), width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, color: CenTheme.red),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: CenTheme.primaryBtn,
                      onPressed: _busy ? null : _scan,
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: Text(S.ambilPindai),
                    ),
                  ),
                  if (_cams.length > 1) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: S.gantiKamera,
                      onPressed: _busy ? null : _next,
                      icon: const Icon(Icons.cameraswitch, color: CenTheme.muted),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String? decodeQrBytes(Uint8List bytes) {
    try {
      final frame = img.decodeImage(bytes);
      if (frame == null) return null;
      final rgba = frame.convert(numChannels: 4).getBytes(order: img.ChannelOrder.rgba);
      final pixels = Int32List(frame.width * frame.height);
      for (var i = 0; i < pixels.length; i++) {
        final o = i * 4;
        pixels[i] = (rgba[o] << 16) | (rgba[o + 1] << 8) | rgba[o + 2];
      }
      final reader = QRCodeReader();
      final source = RGBLuminanceSource(frame.width, frame.height, pixels);
      try {
        return reader.decode(BinaryBitmap(HybridBinarizer(source))).text;
      } catch (_) {
        // Screenshots of dark-mode QRs decode only after inversion.
        return reader
            .decode(BinaryBitmap(HybridBinarizer(source.invert())))
            .text;
      }
    } catch (_) {
      return null;
    }
  }

class _DesktopQrPanel extends StatefulWidget {
  const _DesktopQrPanel({required this.onSubmit});
  final ValueChanged<String> onSubmit;

  @override
  State<_DesktopQrPanel> createState() => _DesktopQrPanelState();
}

class _DesktopQrPanelState extends State<_DesktopQrPanel> {
  final _ctrl = TextEditingController();
  String? _error;
  Uint8List? _preview;
  bool _decoding = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    const typeGroup = XTypeGroup(
      label: 'QR image',
      extensions: <String>['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif'],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _decoding = true;
      _error = null;
      _preview = bytes;
    });
    final decoded = decodeQrBytes(bytes);
    if (!mounted) return;
    if (decoded == null || decoded.isEmpty) {
      setState(() {
        _decoding = false;
        _error = S.gagalBacaQr;
      });
      return;
    }
    widget.onSubmit(decoded);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) setState(() => _ctrl.text = text);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_preview != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _preview!,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                )
              else
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: CenTheme.acid.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.qr_code_2, color: CenTheme.acid, size: 36),
                ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: CenTheme.primaryBtn,
                onPressed: _decoding ? null : _pickImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(S.pilihGambarQr),
              ),
              const SizedBox(height: 6),
              Text(
                S.pilihGambarDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: CenTheme.muted, height: 1.45),
              ),
              if (_decoding) ...[
                const SizedBox(height: 12),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: CenTheme.red),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider(color: CenTheme.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(S.atauTempel,
                        style: const TextStyle(fontSize: 12, color: CenTheme.muted)),
                  ),
                  const Expanded(child: Divider(color: CenTheme.line)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _ctrl,
                style: const TextStyle(
                    color: CenTheme.txt, fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'cen69…',
                  hintStyle: const TextStyle(color: CenTheme.muted),
                  filled: true,
                  fillColor: CenTheme.elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CenTheme.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CenTheme.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CenTheme.acid),
                  ),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) widget.onSubmit(v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _paste,
                      icon: const Icon(Icons.content_paste, size: 18),
                      label: Text(S.tempel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: CenTheme.primaryBtn,
                      onPressed: () {
                        final v = _ctrl.text.trim();
                        if (v.isNotEmpty) widget.onSubmit(v);
                      },
                      child: Text(S.gunakan),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
