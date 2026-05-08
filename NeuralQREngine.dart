import 'dart:convert';

import 'package:flutter_js/flutter_js.dart';

/// Wraps a JavaScript runtime to execute code extracted from NeuralQR codes.
///
/// NeuralQR codes embed JavaScript that defines a small neural network. This
/// class evaluates the untrusted code in a sandboxed runtime and then
/// invokes either a `predict` or `run` function with the provided
/// [context] as input. The context is a descriptive string returned by
/// the Liquid AI model about the scanned object. Results are returned as
/// strings.
class NeuralQREngine {
  final JavascriptRuntime _runtime;

  NeuralQREngine() : _runtime = getJavascriptRuntime();

  /// Executes [jsCode] and passes [context] to the exported predict/run
  /// function. The context is JSON‑encoded to safely embed into the JS
  /// environment. If neither `predict` nor `run` is defined, a default
  /// message is returned.
  Future<String> executeNeuralQR(String jsCode, String context) async {
    // Encode the context to a JSON string so that special characters are
    // properly escaped when injected into the JavaScript snippet.
    final encodedContext = jsonEncode(context);
    final script = '''
      (function() {
        ${jsCode}
        if (typeof predict === 'function') {
          return predict(${encodedContext});
        } else if (typeof run === 'function') {
          return run(${encodedContext});
        } else {
          return 'No predict or run function found in NeuralQR code.';
        }
      })();
    ''';
    final result = _runtime.evaluate(script);
    return result.stringResult;
  }
}