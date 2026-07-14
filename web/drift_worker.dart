// Web worker para drift (sqlite3.wasm). Compilado a JS con `dart compile js`.
// Source: https://drift.simonbinder.eu/platforms/web
// ignore_for_file: avoid_dynamic_calls

import 'package:drift/wasm.dart';

void main() => WasmDatabase.workerMainForOpen();
