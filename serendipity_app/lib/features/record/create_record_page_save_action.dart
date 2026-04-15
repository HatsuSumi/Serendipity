part of 'create_record_page.dart';

extension _CreateRecordPageSaveAction on _CreateRecordPageState {
  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStatus == null) {
      MessageHelper.showWarning(context, '请选择状态');
      return;
    }

    if (_publishToCommunity) {
      final authState = ref.read(authProvider);
      final currentUser = authState.value;

      if (currentUser == null) {
        MessageHelper.showError(context, '请先登录后再发布到树洞');
        return;
      }

      final shouldPublish = await PublishWarningDialog.show(context, ref);

      if (!shouldPublish) {
        _updateState(() {
          _publishToCommunity = false;
        });
        return;
      }
    }

    _updateState(() {
      _isSaving = true;
    });

    try {
      final description = _descriptionController.text.trim();
      final conversationStarter = _selectedStatus == EncounterStatus.met
          ? _conversationStarterController.text.trim()
          : null;
      final backgroundMusic = _backgroundMusicController.text.trim();
      final ifReencounter = _ifReencounterController.text.trim();
      final now = DateTime.now();

      final authState = ref.read(authProvider);
      final currentUser = authState.value;
      final ownerId = currentUser?.id;

      final record = EncounterRecord(
        id: widget.recordToEdit?.id ?? const Uuid().v4(),
        timestamp: _selectedTime,
        location: widget.isEditMode
            ? widget.recordToEdit!.location.copyWith(
                latitude: () => _ignoreGPS
                    ? null
                    : (ref.read(locationProvider).result?.latitude ?? widget.recordToEdit!.location.latitude),
                longitude: () => _ignoreGPS
                    ? null
                    : (ref.read(locationProvider).result?.longitude ?? widget.recordToEdit!.location.longitude),
                address: () => _ignoreGPS
                    ? null
                    : (ref.read(locationProvider).result?.address ?? widget.recordToEdit!.location.address),
                placeName: () => _placeNameController.text.trim().isEmpty
                    ? null
                    : _placeNameController.text.trim(),
                placeType: () => _selectedPlaceType,
              )
            : Location(
                latitude: _ignoreGPS ? null : ref.read(locationProvider).result?.latitude,
                longitude: _ignoreGPS ? null : ref.read(locationProvider).result?.longitude,
                address: _ignoreGPS ? null : ref.read(locationProvider).result?.address,
                placeName: _placeNameController.text.trim().isEmpty
                    ? null
                    : _placeNameController.text.trim(),
                placeType: _selectedPlaceType,
              ),
        description: description.isEmpty ? null : description,
        tags: _tags,
        emotion: _selectedEmotion,
        status: _selectedStatus!,
        storyLineId: _selectedStoryLineId,
        conversationStarter: conversationStarter?.isEmpty ?? true ? null : conversationStarter,
        backgroundMusic: backgroundMusic.isEmpty ? null : backgroundMusic,
        weather: _selectedWeather,
        ifReencounter: ifReencounter.isEmpty ? null : ifReencounter,
        createdAt: widget.recordToEdit?.createdAt ?? now,
        updatedAt: now,
        ownerId: widget.recordToEdit?.ownerId ?? ownerId,
      );

      if (widget.isEditMode) {
        await ref.read(recordsProvider.notifier).updateRecord(record);
      } else {
        await ref.read(recordsProvider.notifier).saveRecord(record);
      }

      if (_publishToCommunity && mounted) {
        final forceReplace = widget.isEditMode && _publishStatus != 'can_publish';
        await ref.read(communityPublishProvider.notifier).publishPost(record, forceReplace: forceReplace);
      }

      if (mounted) {
        MessageHelper.showSuccess(
          context,
          widget.isEditMode ? '记录已更新' : '记录已保存',
        );

        if (!widget.isEditMode &&
            _selectedStatus == EncounterStatus.reencounter &&
            _selectedStoryLineId != null) {
          await _showIfReencounterReminderIfNeeded();
        }

        if (!mounted) return;

        if (widget.isEditMode) {
          Navigator.of(context).pop(record);
        } else {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(
          context,
          '${widget.isEditMode ? "更新" : "保存"}失败：${AuthErrorHelper.extractErrorMessage(e)}',
        );
      }
    } finally {
      if (mounted) {
        _updateState(() {
          _isSaving = false;
        });
      }
    }
  }
}

