import 'dart:typed_data';

import 'package:flutter_leap_sdk/flutter_leap_sdk.dart';

import 'ModelService.dart';

/// Abstraction around Liquid AI vision model usage.
///
/// This class encapsulates the initialization of a conversation with the
/// vision model and exposes a simple method to analyse camera frames. A
/// persistent conversation is used to keep context between requests which
/// improves performance and avoids repeatedly paying model loading costs.
class LiquidAIContext {
  Conversation? _visionConversation;

  /// Lazily initialises the conversation and ensures the model is loaded.
  Future<void> _initialize() async {
    // Load the model if it is not already loaded.
    if (!await ModelService.isModelLoaded()) {
      await ModelService.loadModel();
    }
    // Create the conversation only once.
    _visionConversation ??= await FlutterLeapSdkService.createConversation(
      systemPrompt:
          'You are an on‑device AI that can see and analyse images. '
          'Describe objects and their context concisely when asked.',
    );
  }

  /// Analyses a captured camera frame to produce a human readable summary of
  /// the objects and context visible. The image is passed directly to the
  /// model via `generateResponseWithImage` which is supported by LFM2‑VL
  /// models【980876961375991†L269-L292】. The returned string is fed into the
  /// JavaScript neural network as input data.
  Future<String> analyseScan(Uint8List imageBytes) async {
    await _initialize();
    final conversation = _visionConversation!;
    final prompt =
        'Describe the physical object and its surroundings in one sentence.';
    final response = await conversation.generateResponseWithImage(
      prompt,
      imageBytes,
    );
    return response;
  }
}