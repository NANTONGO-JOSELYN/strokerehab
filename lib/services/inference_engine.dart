// ── Platform dispatcher ─────────────────────────────────────────────────────
//
//  This barrel file selects the correct implementation at compile time:
//
//    dart.library.io  → inference_engine_io.dart   (Android/iOS/Desktop)
//    dart.library.js  → inference_engine_web.dart   (Web)
//
//  Every import of 'inference_engine.dart' resolves to the right version.

export 'inference_engine_io.dart'
    if (dart.library.js) 'inference_engine_web.dart';