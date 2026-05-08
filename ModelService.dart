import 'package:flutter_leap_sdk/flutter_leap_sdk.dart';

/// Service responsible for managing Liquid AI model lifecycle.
///
/// This class wraps the core functions exposed by the `flutter_leap_sdk`
/// package to check if a model exists on the device, download it with a
/// progress callback, and load it into memory. By centralising these
/// operations behind a simple API we keep the rest of the application free
/// from SDK‑specific code.
class ModelService {
  /// The display name of the vision model used throughout the app.
  ///
  /// LFM2.5‑VL‑450M is a compact vision‑language model that can analyse
  /// images on device. According to the Liquid AI documentation it
  /// supports object grounding, instruction following and bounding box
  /// prediction【980876961375991†L72-L83】. We rely on this model for
  /// analysing the physical context of scanned items.
  static const String modelName = 'LFM2.5-VL-450M';

  /// Returns true if the vision model bundle already exists in the local
  /// documents directory. Models downloaded via the LEAP SDK are stored
  /// under the `/leap/` folder of the app’s documents directory【980876961375991†L146-L147】.
  static Future<bool> isModelDownloaded() async {
    return await FlutterLeapSdkService.checkModelExists(modelName);
  }

  /// Checks whether a model is currently loaded into memory.
  static Future<bool> isModelLoaded() async {
    return await FlutterLeapSdkService.checkModelLoaded();
  }

  /// Downloads the vision model from the default LEAP repository. The
  /// [onProgress] callback receives periodic updates with the number of
  /// bytes downloaded, total bytes and percentage complete【980876961375991†L108-L113】.
  static Future<void> downloadModel({Function(DownloadProgress)? onProgress}) async {
    await FlutterLeapSdkService.downloadModel(
      modelName: modelName,
      onProgress: onProgress,
    );
  }

  /// Loads the vision model into memory so it can be used for inference.
  static Future<void> loadModel() async {
    await FlutterLeapSdkService.loadModel(
      modelPath: modelName,
    );
  }
}