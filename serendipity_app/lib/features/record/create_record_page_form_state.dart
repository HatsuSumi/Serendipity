part of 'create_record_page.dart';

extension _CreateRecordPageFormState on _CreateRecordPageState {
  void _initializeFormData() {
    if (widget.recordToEdit != null) {
      final record = widget.recordToEdit!;

      _selectedTime = record.timestamp;
      _selectedStatus = record.status;

      if (record.location.placeName != null) {
        _placeNameController.text = record.location.placeName!;
      }
      _selectedPlaceType = record.location.placeType;

      if (record.location.latitude == null || record.location.longitude == null) {
        _ignoreGPS = true;
      }

      if (record.description != null) {
        _descriptionController.text = record.description!;
      }

      if (record.conversationStarter != null) {
        _conversationStarterController.text = record.conversationStarter!;
      }

      if (record.backgroundMusic != null) {
        _backgroundMusicController.text = record.backgroundMusic!;
      }

      if (record.ifReencounter != null) {
        _ifReencounterController.text = record.ifReencounter!;
      }

      _tags = List.from(record.tags);
      _selectedEmotion = record.emotion;
      _selectedWeather = List.from(record.weather);
      _selectedStoryLineId = record.storyLineId;
    } else {
      if (widget.initialStoryLineId != null) {
        _selectedStoryLineId = widget.initialStoryLineId;
      }
      if (widget.initialPublishToCommunity) {
        _publishToCommunity = true;
      }
    }
  }

  bool _hasUnsavedChanges() {
    if (widget.isEditMode) {
      final original = widget.recordToEdit!;

      if (_selectedTime != original.timestamp) return true;
      if (_selectedStatus != original.status) return true;

      final currentPlaceName = _placeNameController.text.trim();
      final originalPlaceName = original.location.placeName ?? '';
      if (currentPlaceName != originalPlaceName) return true;

      if (_selectedPlaceType != original.location.placeType) return true;

      final currentDescription = _descriptionController.text.trim();
      final originalDescription = original.description ?? '';
      if (currentDescription != originalDescription) return true;

      final currentConversationStarter = _conversationStarterController.text.trim();
      final originalConversationStarter = original.conversationStarter ?? '';
      if (currentConversationStarter != originalConversationStarter) return true;

      final currentBackgroundMusic = _backgroundMusicController.text.trim();
      final originalBackgroundMusic = original.backgroundMusic ?? '';
      if (currentBackgroundMusic != originalBackgroundMusic) return true;

      final currentIfReencounter = _ifReencounterController.text.trim();
      final originalIfReencounter = original.ifReencounter ?? '';
      if (currentIfReencounter != originalIfReencounter) return true;

      if (_tags.length != original.tags.length) return true;
      for (int i = 0; i < _tags.length; i++) {
        if (_tags[i].tag != original.tags[i].tag || _tags[i].note != original.tags[i].note) {
          return true;
        }
      }

      if (_selectedEmotion != original.emotion) return true;

      if (_selectedWeather.length != original.weather.length) return true;
      final originalWeatherSet = original.weather.toSet();
      final currentWeatherSet = _selectedWeather.toSet();
      if (!currentWeatherSet.containsAll(originalWeatherSet) ||
          !originalWeatherSet.containsAll(currentWeatherSet)) {
        return true;
      }

      if (_selectedStoryLineId != original.storyLineId) return true;

      return false;
    }

    return _selectedStatus != null ||
        _placeNameController.text.trim().isNotEmpty ||
        _selectedPlaceType != null ||
        _descriptionController.text.trim().isNotEmpty ||
        _tags.isNotEmpty ||
        _selectedEmotion != null ||
        _conversationStarterController.text.trim().isNotEmpty ||
        _backgroundMusicController.text.trim().isNotEmpty ||
        _selectedWeather.isNotEmpty ||
        _ifReencounterController.text.trim().isNotEmpty ||
        _publishToCommunity ||
        _selectedStoryLineId != null;
  }

  bool _hasContentChanges() {
    if (!widget.isEditMode) return false;

    final original = widget.recordToEdit!;

    if (_selectedTime != original.timestamp) return true;
    if (_selectedStatus != original.status) return true;

    final currentPlaceName = _placeNameController.text.trim();
    final originalPlaceName = original.location.placeName ?? '';
    if (currentPlaceName != originalPlaceName) return true;

    if (_selectedPlaceType != original.location.placeType) return true;

    final currentDescription = _descriptionController.text.trim();
    final originalDescription = original.description ?? '';
    if (currentDescription != originalDescription) return true;

    if (_tags.length != original.tags.length) return true;
    for (int i = 0; i < _tags.length; i++) {
      if (_tags[i].tag != original.tags[i].tag || _tags[i].note != original.tags[i].note) {
        return true;
      }
    }

    return false;
  }
}

