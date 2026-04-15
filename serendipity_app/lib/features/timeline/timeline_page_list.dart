part of 'timeline_page.dart';

extension _TimelinePageListSection on _TimelinePageState {
  /// 构建记录列表（recordsProvider 已在 build() 中自动应用筛选条件）
  Widget _buildFilteredRecordList(
    BuildContext context,
    WidgetRef ref,
    RecordsFilterCriteria filterCriteria,
  ) {
    final recordsAsync = ref.watch(recordsProvider);
    return recordsAsync.when(
      data: (records) {
        final sortedRecords = _sortRecords(records);
        return _buildRecordList(context, sortedRecords, ref, filterCriteria);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(context, ref, error),
    );
  }

  /// 记录列表（签到卡片始终显示在顶部，记录为空时显示空状态占位）
  Widget _buildRecordList(
    BuildContext context,
    List<EncounterRecord> records,
    WidgetRef ref,
    RecordsFilterCriteria filterCriteria,
  ) {
    final notifier = ref.read(recordsProvider.notifier);
    // 无筛选时才显示底部加载指示器
    final showLoadMore = !filterCriteria.isActive && notifier.hasMore;
    // index 0 = 签到卡片，末尾可能有加载指示器
    final itemCount = records.isEmpty ? 2 : records.length + 1 + (showLoadMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(recordsProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // 第一项：签到卡片
          if (index == 0) {
            return CheckInCard(
              confettiController: _confettiController,
            );
          }

          // 无记录时显示空状态占位
          if (records.isEmpty) {
            final isFiltering = filterCriteria.isActive;
            // 刀子美学：单独筛选「失联」或「别离」时显示专属文案
            final onlyStatuses = filterCriteria.statuses;
            final isOnlyLost = isFiltering &&
                onlyStatuses != null &&
                onlyStatuses.length == 1 &&
                onlyStatuses.first == EncounterStatus.lost;
            final isOnlyFarewell = isFiltering &&
                onlyStatuses != null &&
                onlyStatuses.length == 1 &&
                onlyStatuses.first == EncounterStatus.farewell;

            String emptyTitle;
            String emptyDescription;
            if (isOnlyLost) {
              emptyTitle = '还没有人\n就这样从你的生活里消失。';
              emptyDescription = '这是运气，\n也是遗憾的另一种形式。';
            } else if (isOnlyFarewell) {
              emptyTitle = '还没有主动结束过什么。';
              emptyDescription = '不知道这是因为你\n足够勇敢，还是足够逃避。';
            } else if (isFiltering) {
              emptyTitle = '没有符合条件的记录';
              emptyDescription = '试试调整筛选条件';
            } else {
              emptyTitle = '还没有记录';
              emptyDescription = '点击下方按钮开始记录';
            }

            return Padding(
              padding: const EdgeInsets.only(top: 32),
              child: EmptyStateWidget(
                icon: isOnlyLost
                    ? Icons.cloud_off_outlined
                    : isOnlyFarewell
                        ? Icons.waving_hand_outlined
                        : isFiltering
                            ? Icons.search_off
                            : Icons.auto_awesome,
                title: emptyTitle,
                description: emptyDescription,
              ),
            );
          }

          // 末尾加载指示器
          if (showLoadMore && index == records.length + 1) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          // 记录卡片
          final record = records[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildRecordCard(context, record, ref, filterCriteria),
          );
        },
      ),
    );
  }
}

