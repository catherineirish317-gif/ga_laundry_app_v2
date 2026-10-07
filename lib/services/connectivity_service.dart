import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Emits true/false whenever connectivity changes, so the SyncService
  /// and the offline banner widget can both listen to one source of truth.
  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none);
}
