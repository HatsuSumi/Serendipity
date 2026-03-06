import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/region_data.dart';
import '../../../core/providers/region_provider.dart';

/// 地区选择器 Widget
/// 
/// 职责：
/// - 提供省市区三级联动选择
/// - 支持搜索功能
/// - 只负责UI展示和用户交互
/// 
/// 遵循原则：
/// - 单一职责：只负责地区选择UI
/// - 不包含业务逻辑
/// - 不直接访问数据源
/// - build() 方法纯函数
class RegionPickerDialog extends ConsumerStatefulWidget {
  final SelectedRegion? initialSelection;

  const RegionPickerDialog({
    super.key,
    this.initialSelection,
  });

  @override
  ConsumerState<RegionPickerDialog> createState() => _RegionPickerDialogState();

  /// 显示地区选择器
  /// 
  /// 返回：用户选择的地区，如果取消则返回 null
  static Future<SelectedRegion?> show(
    BuildContext context, {
    SelectedRegion? initialSelection,
  }) async {
    return showDialog<SelectedRegion>(
      context: context,
      builder: (context) => RegionPickerDialog(
        initialSelection: initialSelection,
      ),
    );
  }
}

class _RegionPickerDialogState extends ConsumerState<RegionPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  SelectedRegion _selectedRegion = const SelectedRegion();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialSelection ?? const SelectedRegion();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadState = ref.watch(regionDataProvider);

    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // 标题栏
            _buildHeader(theme),
            
            // 搜索框
            _buildSearchBar(theme),
            
            // 内容区域
            Expanded(
              child: loadState.when(
                data: (_) => _buildContent(theme),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _buildError(theme, error),
              ),
            ),
            
            // 底部按钮
            _buildActions(theme),
          ],
        ),
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '选择地区',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (!_selectedRegion.isEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedRegion = const SelectedRegion();
                  _searchController.clear();
                  _searchKeyword = '';
                });
              },
              child: const Text('清除'),
            ),
        ],
      ),
    );
  }

  /// 构建搜索框
  /// 
  /// 优化说明：
  /// - 添加防抖优化，避免频繁重建
  /// - 提升输入体验
  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索省/市/区',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchKeyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _debounceTimer?.cancel();
                    setState(() {
                      _searchController.clear();
                      _searchKeyword = '';
                    });
                  },
                )
              : null,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (value) {
          // 取消之前的定时器
          _debounceTimer?.cancel();
          
          // 设置新的定时器（300ms 防抖）
          _debounceTimer = Timer(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _searchKeyword = value;
              });
            }
          });
        },
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(ThemeData theme) {
    // 如果有搜索关键词，显示搜索结果
    if (_searchKeyword.isNotEmpty) {
      return _buildSearchResults(theme);
    }

    // 否则显示三级联动选择器
    return _buildCascadePicker(theme);
  }

  /// 构建搜索结果
  Widget _buildSearchResults(ThemeData theme) {
    final searchResults = ref.watch(regionSearchProvider(_searchKeyword));

    if (searchResults.isEmpty) {
      return Center(
        child: Text(
          '未找到匹配的地区',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final region = searchResults[index];
        return ListTile(
          title: Text(region.fullAddress),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _selectedRegion = region;
              _searchController.clear();
              _searchKeyword = '';
            });
          },
        );
      },
    );
  }

  /// 构建三级联动选择器
  Widget _buildCascadePicker(ThemeData theme) {
    return Row(
      children: [
        // 省份列表
        Expanded(
          child: _buildProvinceList(theme),
        ),
        
        // 城市列表
        if (_selectedRegion.province != null)
          Expanded(
            child: _buildCityList(theme),
          ),
        
        // 区县列表
        if (_selectedRegion.city != null)
          Expanded(
            child: _buildAreaList(theme),
          ),
      ],
    );
  }

  /// 构建省份列表
  Widget _buildProvinceList(ThemeData theme) {
    final provinces = ref.watch(provincesProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: ListView.builder(
        itemCount: provinces.length,
        itemBuilder: (context, index) {
          final province = provinces[index];
          final isSelected = _selectedRegion.province == province.name;

          return ListTile(
            title: Text(
              province.name,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onTap: () {
              setState(() {
                _selectedRegion = SelectedRegion(province: province.name);
              });
            },
          );
        },
      ),
    );
  }

  /// 构建城市列表
  Widget _buildCityList(ThemeData theme) {
    final cities = ref.watch(citiesProvider(_selectedRegion.province));

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: ListView.builder(
        itemCount: cities.length,
        itemBuilder: (context, index) {
          final city = cities[index];
          final isSelected = _selectedRegion.city == city.name;

          return ListTile(
            title: Text(
              city.name,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onTap: () {
              setState(() {
                _selectedRegion = _selectedRegion.copyWith(
                  city: city.name,
                  area: null, // 清除之前选择的区县
                );
              });
            },
          );
        },
      ),
    );
  }

  /// 构建区县列表
  Widget _buildAreaList(ThemeData theme) {
    final areas = ref.watch(areasProvider((
      province: _selectedRegion.province!,
      city: _selectedRegion.city!,
    )));

    return ListView.builder(
      itemCount: areas.length,
      itemBuilder: (context, index) {
        final area = areas[index];
        final isSelected = _selectedRegion.area == area;

        return ListTile(
          title: Text(
            area,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onTap: () {
            setState(() {
              _selectedRegion = _selectedRegion.copyWith(area: area);
            });
          },
        );
      },
    );
  }

  /// 构建错误提示
  Widget _buildError(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '加载地区数据失败',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref.read(regionDataProvider.notifier).reload();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建底部按钮
  Widget _buildActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          // 当前选择显示
          Expanded(
            child: Text(
              _selectedRegion.displayText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _selectedRegion.isEmpty
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // 取消按钮
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          const SizedBox(width: 8),
          
          // 确定按钮
          FilledButton(
            onPressed: _selectedRegion.isEmpty
                ? null
                : () => Navigator.of(context).pop(_selectedRegion),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

