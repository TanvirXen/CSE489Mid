import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/landmark.dart';
import '../services/landmark_api.dart';
import '../services/landmark_cache.dart';

class LandmarkController extends ChangeNotifier {
  LandmarkController({LandmarkApi? api, LandmarkCache? cache})
      : _api = api ?? LandmarkApi(),
        _cache = cache ?? LandmarkCache();

  final LandmarkApi _api;
  final LandmarkCache _cache;

  List<Landmark> _landmarks = [];
  bool _isLoading = false;
  String? _errorMessage;
  LandmarkDraft _draft = LandmarkDraft();

  List<Landmark> get landmarks => _landmarks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LandmarkDraft get draft => _draft;
  bool get isEditing => _draft.id != null;

  Future<void> fetchLandmarks() async {
    _setLoading(true);
    final hadCache = await _hydrateFromCache();
    try {
      final remote = await _api.fetchLandmarks();
      _landmarks = remote;
      _errorMessage = null;
      await _syncCache(() => _cache.replaceAll(remote));
    } catch (error) {
      _errorMessage = hadCache
          ? 'Showing offline data. ${error.toString()}'
          : error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveDraft() async {
    if (!_draft.isComplete) {
      _errorMessage = 'Please complete all required fields.';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    try {
      if (isEditing) {
        await _api.updateLandmark(_draft);
      } else {
        final newId = await _api.createLandmark(_draft);
        _draft.id = newId;
      }
      await fetchLandmarks();
      _errorMessage = null;
      resetDraft();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeLandmark(int id) async {
    _setLoading(true);
    try {
      await _api.deleteLandmark(id);
      _landmarks = _landmarks.where((element) => element.id != id).toList();
      _errorMessage = null;
      await _syncCache(() => _cache.remove(id));
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void startEditing(Landmark landmark) {
    _draft = LandmarkDraft.fromLandmark(landmark);
    notifyListeners();
  }

  void updateDraft({String? title, double? lat, double? lon}) {
    _draft = _draft.copyWith(
      title: title ?? _draft.title,
      lat: lat ?? _draft.lat,
      lon: lon ?? _draft.lon,
    );
    notifyListeners();
  }

  void updateDraftImage(Uint8List? bytes, {String? fileName}) {
    _draft
      ..imageBytes = bytes
      ..imageName = bytes == null
          ? _draft.imageName
          : (fileName ?? _draft.imageName)
      ..existingImageUrl = bytes == null ? _draft.existingImageUrl : null;
    notifyListeners();
  }

  void resetDraft() {
    _draft = LandmarkDraft();
    notifyListeners();
  }

  Future<bool> _hydrateFromCache() async {
    try {
      final cached = await _cache.readAll();
      if (cached.isEmpty) return false;
      _landmarks = cached;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _syncCache(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Cache sync skipped: $error');
    }
  }
}
