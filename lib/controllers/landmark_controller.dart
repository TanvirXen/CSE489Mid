import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/landmark.dart';
import '../services/landmark_api.dart';

class LandmarkController extends ChangeNotifier {
  LandmarkController({LandmarkApi? api}) : _api = api ?? LandmarkApi();

  final LandmarkApi _api;

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
    try {
      _landmarks = await _api.fetchLandmarks();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
