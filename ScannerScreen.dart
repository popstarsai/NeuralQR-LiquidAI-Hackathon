import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:typed_data';

import '../services/ModelService.dart';
import '../services/LiquidAIContext.dart';
import '../services/NeuralQREngine.dart';

/// Stateful widget responsible for orchestrating the NeuralQR scanning flow.
///
/// When the widget is first created it ensures the vision model is
/// available. If the model has not been downloaded, it prompts the user
/// with an alert dialog to initiate the 350 MB download. During the
/// download a linear progress indicator shows the status. Once the
/// model is ready the camera feed is displayed and scanning begins. When
/// a QR code is detected, both the raw JavaScript and the current
/// camera frame are captured. The frame is analysed via Liquid AI to
/// produce context which is then passed into the NeuralQR code. The
/// result is shown at the bottom of the screen.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController =
      MobileScannerController(returnImage: true);
  final LiquidAIContext _liquidAIContext = LiquidAIContext();
  final NeuralQREngine _neuralQREngine = NeuralQREngine();

  bool _modelReady = false;
  double _downloadProgress = 0.0;
  bool _processing = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  /// Ensures that the vision model is downloaded and loaded. If the model
  /// doesn’t exist a dialog prompts the user to start the download. The
  /// progress callback updates [_downloadProgress] so the UI can show
  /// feedback. Once downloaded the model is loaded and a conversation
  /// initialised.
  Future<void> _initModel() async {
    final exists = await ModelService.isModelDownloaded();
    if (!exists) {
      final shouldDownload = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Download model'),
            content: const Text(
                'The LFM2.5‑VL‑450M model (~350 MB) is required to run NeuralQR scans entirely offline. Would you like to download it now?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Download'),
              ),
            ],
          );
        },
      );
      if (shouldDownload != true) {
        // User cancelled, you might close the screen or disable scanning.
        return;
      }
      // Download with progress callback
      await ModelService.downloadModel(onProgress: (progress) {
        setState(() {
          _downloadProgress = progress.percentage / 100.0;
        });
      });
    }
    // Load the model. The conversation is lazily created in
    // LiquidAIContext when analyseScan is first called.
    await ModelService.loadModel();
    setState(() {
      _modelReady = true;
    });
  }

  /// Handles barcode detection events from the scanner. This method
  /// extracts the JavaScript from the QR code, stops scanning, analyses
  /// the captured frame with LiquidAI and executes the NeuralQR network.
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || !_modelReady) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final String? jsCode = barcodes.first.rawValue;
    final Uint8List? imageBytes = capture.image;
    if (jsCode == null || imageBytes == null) return;
    setState(() {
      _processing = true;
    });
    // Stop the scanner while processing to avoid duplicate detections
    await _scannerController.stop();
    try {
      // Analyse the frame to get context about the scanned object
      final contextString = await _liquidAIContext.analyseScan(imageBytes);
      // Execute the neural net defined in the QR code
      final result = await _neuralQREngine.executeNeuralQR(jsCode, contextString);
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
    setState(() {
      _processing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NeuralQR Scanner'),
      ),
      body: _modelReady
          ? Stack(
              children: [
                // Live camera feed with QR scanning enabled
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),
                // Processing overlay
                if (_processing)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                // Result overlay
                if (_result != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _result!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_downloadProgress > 0 && _downloadProgress < 1)
                    Column(
                      children: [
                        const Text('Downloading model...'),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(value: _downloadProgress),
                        const SizedBox(height: 8),
                        Text('${(_downloadProgress * 100).toStringAsFixed(1)}%'),
                      ],
                    )
                  else
                    const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Preparing NeuralQR Scanner'),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }
}