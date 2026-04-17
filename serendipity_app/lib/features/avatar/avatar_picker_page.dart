import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/utils/message_helper.dart';
import 'avatar_picker_controller.dart';
import 'widgets/avatar_picker_grid.dart';
import 'widgets/avatar_picker_states.dart';

class AvatarPickerPage extends StatefulWidget {
  const AvatarPickerPage({super.key});

  @override
  State<AvatarPickerPage> createState() => _AvatarPickerPageState();
}

class _AvatarPickerPageState extends State<AvatarPickerPage> {
  final ScrollController _scrollController = ScrollController();
  final AvatarPickerController _controller = AvatarPickerController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _controller.isLoading = true;
    });

    try {
      await _controller.loadInitialData();
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      _controller.debugLog('AvatarPickerPage load failed: ', error);
      if (!mounted) return;
      setState(() {
        _controller.isLoading = false;
        _controller.hasMore = false;
      });
      MessageHelper.showError(context, '加载相册失败');
    }
  }

  Future<void> _loadNextPage({bool reset = false}) async {
    if (!reset && (_controller.isLoadingMore || !_controller.hasMore)) {
      return;
    }

    setState(() {
      if (reset) {
        _controller.isLoading = true;
      } else {
        _controller.isLoadingMore = true;
      }
    });

    try {
      await _controller.loadNextPage(reset: reset);
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      _controller.debugLog('AvatarPickerPage load page failed: ', error);
      if (!mounted) return;
      setState(() {
        _controller.isLoading = false;
        _controller.isLoadingMore = false;
        _controller.hasMore = false;
      });
      MessageHelper.showError(context, '加载图片失败');
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (_controller.shouldLoadMore(position.pixels, position.maxScrollExtent)) {
      _loadNextPage();
    }
  }

  Future<void> _handleAlbumChanged(AssetPathEntity? album) async {
    if (album == null || album == _controller.selectedAlbum) {
      return;
    }

    setState(() {
      _controller.assets.clear();
      _controller.currentPage = 0;
      _controller.hasMore = true;
      _controller.isLoading = true;
    });

    try {
      await _controller.selectAlbum(album);
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      _controller.debugLog('AvatarPickerPage change album failed: ', error);
      if (!mounted) return;
      setState(() {
        _controller.isLoading = false;
        _controller.isLoadingMore = false;
        _controller.hasMore = false;
      });
      MessageHelper.showError(context, '加载图片失败');
    }
  }

  Future<void> _handleAssetTap(AssetEntity asset) async {
    try {
      final file = await _controller.readAssetFile(asset);
      if (!mounted) return;
      if (file == null) {
        MessageHelper.showError(context, '读取图片失败');
        return;
      }
      Navigator.of(context).pop(file);
    } catch (error) {
      _controller.debugLog('AvatarPickerPage read asset failed: ', error);
      if (!mounted) return;
      MessageHelper.showError(context, '读取图片失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionState = _controller.permissionState;

    return Scaffold(
      appBar: AppBar(title: const Text('选择头像图片')),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : permissionState != null && !permissionState.hasAccess
          ? PermissionDeniedView(
              permissionState: permissionState,
              onOpenSettings: () async {
                await PhotoManager.openSetting();
              },
              onRetry: _loadInitialData,
            )
          : Column(
              children: [
                if (_controller.albums.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: DropdownButtonFormField<AssetPathEntity>(
                      initialValue: _controller.selectedAlbum,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '相册',
                        border: OutlineInputBorder(),
                      ),
                      items: _controller.albums
                          .map(
                            (album) => DropdownMenuItem<AssetPathEntity>(
                              value: album,
                              child: Text(album.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _handleAlbumChanged,
                    ),
                  ),
                Expanded(
                  child: _controller.assets.isEmpty
                      ? const EmptyAssetsView()
                      : AvatarPickerGrid(
                          controller: _scrollController,
                          assets: _controller.assets,
                          isLoadingMore: _controller.isLoadingMore,
                          onAssetTap: _handleAssetTap,
                        ),
                ),
              ],
            ),
    );
  }
}

