part of 'create_record_page.dart';

class _CreateRecordPageBody extends ConsumerWidget {
  const _CreateRecordPageBody(this.state);

  final _CreateRecordPageState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    state._colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        if (state._hasUnsavedChanges()) {
          final shouldPop = await state._showUnsavedChangesDialog();

          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.widget.isEditMode ? '编辑记录' : '创建记录'),
          actions: [
            if (state._isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              TextButton(
                onPressed: state._saveRecord,
                child: const Text(
                  '保存',
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
        body: Form(
          key: state._formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              state._buildTimeSection(),
              const SizedBox(height: 24),
              state._buildLocationSection(),
              const SizedBox(height: 24),
              state._buildStatusSection(),
              const SizedBox(height: 24),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: state._selectedStatus == EncounterStatus.met
                      ? Column(
                          key: const ValueKey('conversation_starter'),
                          children: [
                            state._buildConversationStarterSection(),
                            const SizedBox(height: 24),
                          ],
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('empty'),
                        ),
                ),
              ),
              state._buildDescriptionSection(),
              const SizedBox(height: 24),
              state._buildTagsSection(),
              const SizedBox(height: 24),
              state._buildEmotionSection(),
              const SizedBox(height: 24),
              state._buildBackgroundMusicSection(),
              const SizedBox(height: 24),
              state._buildWeatherSection(),
              const SizedBox(height: 24),
              state._buildIfReencounterSection(),
              const SizedBox(height: 24),
              state._buildOtherSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

