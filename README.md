NeuralQR – Offline Neural Network QR Scanner

NeuralQR is a proof‑of‑concept mobile application created for the Liquid AI Hackathon. It demonstrates how tiny neural networks can be encoded directly into a QR code and executed on a smartphone without any internet connection. When the app scans a NeuralQR, it extracts the embedded JavaScript model, analyzes the physical context using Liquid AI’s vision‑language model, and then executes the neural network locally to produce a result.

Concept

QR codes can store several thousand characters of plain text, making them ideal carriers for code. The accompanying NeuralQR Guide notes that a NeuralQR contains complete, runnable JavaScript code for small neural networks. Because code is text, the QR itself becomes a portable vessel for intelligence—there is no need for URLs or cloud services. To maximize scan reliability, code should be kept under 800–1,000 characters and minified. Users can generate NeuralQRs using built‑in browser QR generators or other offline tools.

How Liquid AI Is Used

NeuralQR leverages the Liquid AI LEAP SDK via the flutter_leap_sdk package. This plugin provides on‑device AI inference capabilities for Liquid Foundation Models (LFMs) and ensures that all AI processing occurs locally on the device with no cloud dependencies. The SDK offers several key features:

On‑device inference – AI models run locally without requiring an internet connection, preserving user privacy.
Multimodal support – Models can process text, images and audio. NeuralQR uses this feature to analyze camera frames.
Automatic model management – The SDK can download and cache models on the device; vision models require manual download through downloadModel.
Edge‑ready models – The selected model, LFM2.5‑VL‑450M, is Liquid AI’s smallest vision‑language model and is designed to run on mobile and embedded devices. Its minimal memory footprint and low latency make it suitable for real‑time inference on smartphones.
Local privacy – Vision‑language models in Liquid AI examples emphasise complete privacy by performing inference entirely on the device.
Model Download and Loading

On first launch, NeuralQR checks whether the LFM2.5‑VL‑450M bundle is present on the device. If not, it prompts the user to download the ~350 MB model file. The download process uses FlutterLeapSdkService.downloadModel and displays a progress indicator. Once downloaded, the model is stored under the /leap/ directory and remains cached. The app then loads the model into memory and creates a persistent conversation using LiquidAiLeap to prepare for vision inference.

Vision Context Analysis

When a QR code is scanned, the app captures the current camera frame (as image bytes) alongside the QR’s decoded text. These image bytes are passed to LiquidAIContext.analyzeScan(), which calls the vision‑language model via generateResponseWithImage() to produce a natural‑language description of the scene. Vision‑language models can describe images, answer visual questions, detect objects and understand context; this context is crucial for neural networks that depend on physical surroundings.

Application Workflow
Camera & QR scanning – A live camera preview is displayed using the mobile_scanner package. QR scanning is configured with returnImage: true, so when a QR is detected, both the decoded text and the captured image are returned.
Model check & download – ModelService checks for the LFM2.5‑VL‑450M model. If absent, an alert asks the user to download the model and displays real‑time progress. After download, the model is loaded into memory.
Context analysis – The captured image bytes are passed to the vision‑language model via LiquidAIContext.analyzeScan() to obtain a textual description of the scene.
JavaScript execution – The QR’s text, which contains JavaScript code for a neural network, is evaluated in a sandbox using flutter_js. The NeuralQREngine injects the context description as input and calls a predict() or run() function from the code. The network’s output (e.g., classification or numeric result) is captured.
Result display – ScannerScreen shows the live camera feed, the extracted context description, and the neural network’s result, giving users immediate feedback.
Project Structure & Key Files
File	Description
pubspec.yaml	Declares Flutter dependencies and includes flutter_leap_sdk, mobile_scanner, flutter_js, and path_provider.
lib/services/ModelService.dart	Handles downloading and loading the LFM2.5‑VL‑450M model, prompting the user when necessary, and exposing isModelDownloaded(), downloadModel() and loadModel() methods.
lib/services/LiquidAIContext.dart	Creates a persistent conversation with the vision‑language model and provides analyzeScan(Uint8List imageBytes) to generate context from camera frames.
lib/services/NeuralQREngine.dart	Wraps flutter_js to safely evaluate JavaScript neural networks embedded in QR codes. Injects the vision context and executes predict() or run() functions to obtain results.
lib/screens/ScannerScreen.dart	Orchestrates the UI: handles model download prompts, camera preview, QR scanning, vision analysis and JS execution, then displays results.
Current Status and Future Work
What’s completed
Offline architecture: The entire pipeline—QR scanning, vision analysis, JavaScript execution and result display—runs fully on‑device. No network calls are made after the initial model download.
Model management: Users are prompted to download the LFM2.5‑VL‑450M model if it’s missing, and progress is displayed. The model is then loaded and reused across sessions.
Contextual inference: The app uses a vision‑language model to describe the scene and passes that information into the neural network. This enables context‑aware behavior beyond simply decoding the QR.
JavaScript sandbox: Neural networks embedded in QR codes execute in a sandboxed JS runtime, preventing them from escaping into the host environment.
Basic UI: The app provides a camera preview, download progress dialog, and results display. It is functional for demonstration and testing.
Areas for improvement

Although the core features work, several enhancements could make NeuralQR more robust and user‑friendly:

Improved UI and UX: Implement material design components, error messages and animations to create a polished user experience.
Security hardening: Further isolate the JavaScript sandbox to prevent malicious code from accessing device resources. Consider implementing a strict API surface for the JS model.
Broader QR support: Support scanning larger models split across multiple QR codes (as suggested in the NeuralQR guide) and decompressing gzipped models.
Custom prompts: Allow users to provide their own system prompts or questions to the vision‑language model for more targeted context generation.
Cross‑platform testing: The app currently targets Android. Additional work is needed to test and optimize for iOS, including ensuring the model download process works on Apple’s file system and code execution limitations.
Performance optimization: Cache and reuse the vision‑language model conversation across scans to reduce latency; consider asynchronous loading of the JS engine.
Expanded sample models: Create a library of example NeuralQR codes (beyond the XOR demo) to showcase more complex networks and user scenarios.
Getting Started
Clone the repository and open it in your favorite IDE (e.g., VS Code or Android Studio).
Install dependencies by running flutter pub get.
Run the app on a real Android device (API 31+ arm64‑v8a recommended). The app will prompt you to download the model on first launch.
Test with example NeuralQR codes such as the XOR network described in the guide. Point your camera at the QR, wait for context analysis and view the network output.
License

This project is provided for educational and hackathon purposes and is licensed under the MIT license.# NeuralQR-LiquidAI-Hackathon
NeuralQR Scanner – Offline AI neural networks encoded in QR codes using Liquid AI’s LFM2.5-VL-450M + flutter_js (Liquid AI Hackathon submission)
