part of 'timeline_page.dart';

extension _TimelinePageAppBarSection on _TimelinePageState {
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    RecordsFilterCriteria filterCriteria,
    AsyncValue<int> countAsync,
  ) {
    return AppBar(
      title: countAsync.when(
        data: (count) => Text(
          filterCriteria.isActive ? 'TA (筛选后共$count条)' : 'TA (共$count条)',
        ),
        loading: () => const Text('TA'),
        error: (e, _) => const Text('TA'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: '筛选',
          onPressed: () => RecordFilterDialog.show(context),
        ),
        PopupMenuButton<RecordSortType>(
          icon: const Icon(Icons.sort),
          tooltip: '排序方式',
          onSelected: _selectSortType,
          itemBuilder: _buildSortMenuItems,
        ),
        IconButton(
          icon: Icon(_isMasked ? Icons.visibility : Icons.visibility_off),
          tooltip: _isMasked ? '显示原始信息' : '打码记录',
          onPressed: () => _toggleMask(context),
        ),
      ],
    );
  }

  List<PopupMenuEntry<RecordSortType>> _buildSortMenuItems(BuildContext context) {
    return RecordSortType.values.map((type) {
      return PopupMenuItem<RecordSortType>(
        value: type,
        child: Row(
          children: [
            if (_currentSort == type)
              const Icon(Icons.check, size: 20)
            else
              const SizedBox(width: 20),
            const SizedBox(width: 8),
            Text(type.label),
          ],
        ),
      );
    }).toList();
  }
}

