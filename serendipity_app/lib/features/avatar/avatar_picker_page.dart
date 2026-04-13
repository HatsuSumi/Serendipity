import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/utils/message_helper.dart';

class AvatarPickerPage extends StatefulWidget {
  const AvatarPickerPage({super.key});

  @override
  State<AvatarPickerPage> createState() => _AvatarPickerPageState();
}

class _AvatarPickerPageState extends State<AvatarPickerPage> {
  static const int _pageSize = 80;
  static const PermissionRequestOption _permissionRequest =
      PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      );

  final ScrollController _scrollController = ScrollController();

  PermissionState? _permissionState;
  List<AssetPathEntity> _albums = const [];
  AssetPathEntity? _selectedAlbum;
  final List<AssetEntity> _assets = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;

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
    setState(() => _isLoading = true);

    try {
      final permissionState = await PhotoManager.requestPermissionExtend(
        requestOption: _permissionRequest,
      );
      if (!mounted) return;

      if (!permissionState.hasAccess) {
        setState(() {
          _permissionState = permissionState;
          _albums = const [];
          _selectedAlbum = null;
          _assets.clear();
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(),
      );
      if (!mounted) return;

      final selectedAlbum = albums.isNotEmpty ? albums.first : null;
      setState(() {
        _permissionState = permissionState;
        _albums = albums;
        _selectedAlbum = selectedAlbum;
        _assets.clear();
        _currentPage = 0;
        _hasMore = selectedAlbum != null;
      });

      if (selectedAlbum != null) {
        await _loadNextPage(reset: true);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('AvatarPickerPage load failed: $error');
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      MessageHelper.showError(context, '加载相册失败');
    }
  }

  Future<void> _loadNextPage({bool reset = false}) async {
    final album = _selectedAlbum;
    if (album == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    if (!reset && (_isLoadingMore || !_hasMore)) {
      return;
    }

    setState(() {
      if (reset) {
        _isLoading = true;
        _assets.clear();
        _currentPage = 0;
        _hasMore = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final page = _currentPage;
      final nextAssets = await album.getAssetListPaged(
        page: page,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _assets.addAll(nextAssets);
        _currentPage = page + 1;
        _hasMore = nextAssets.length == _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('AvatarPickerPage load page failed: $error');
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = false;
      });
      MessageHelper.showError(context, '加载图片失败');
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadNextPage();
    }
  }

  Future<void> _handleAlbumChanged(AssetPathEntity? album) async {
    if (album == null || album == _selectedAlbum) {
      return;
    }
    setState(() {
      _selectedAlbum = album;
      _assets.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    await _loadNextPage(reset: true);
  }

  Future<void> _handleAssetTap(AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (!mounted) return;
      if (file == null || !file.existsSync()) {
        MessageHelper.showError(context, '读取图片失败');
        return;
      }
      Navigator.of(context).pop(file);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('AvatarPickerPage read asset failed: $error');
      }
      if (!mounted) return;
      MessageHelper.showError(context, '读取图片失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionState = _permissionState;

    return Scaffold(
      appBar: AppBar(title: const Text('选择头像图片')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : permissionState != null && !permissionState.hasAccess
          ? _PermissionDeniedView(
              permissionState: permissionState,
              onOpenSettings: () async {
                await PhotoManager.openSetting();
              },
              onRetry: _loadInitialData,
            )
          : Column(
              children: [
                if (_albums.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: DropdownButtonFormField<AssetPathEntity>(
                      initialValue: _selectedAlbum,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '相册',
                        border: OutlineInputBorder(),
                      ),
                      items: _albums
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
                  child: _assets.isEmpty
                      ? const _EmptyAssetsView()
                      : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _assets.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _assets.length) {
                              return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            }
                            return _AvatarAssetTile(
                              asset: _assets[index],
                              onTap: () => _handleAssetTap(_assets[index]),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _AvatarAssetTile extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onTap;

  const _AvatarAssetTile({
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(
                const ThumbnailSize.square(400),
              ),
              builder: (context, snapshot) {
                final bytes = snapshot.data;
                if (bytes == null) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return const _AssetPlaceholder(icon: Icons.broken_image_outlined);
                  }
                  return const _AssetPlaceholder(icon: Icons.image_outlined);
                }
                return Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AssetPlaceholder extends StatelessWidget {
  final IconData icon;

  const _AssetPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EmptyAssetsView extends StatelessWidget {
  const _EmptyAssetsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            const Text(
              '当前相册没有可用图片',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final PermissionState permissionState;
  final Future<void> Function() onOpenSettings;
  final Future<void> Function() onRetry;

  const _PermissionDeniedView({
    required this.permissionState,
    required this.onOpenSettings,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final message = permissionState == PermissionState.limited
        ? '当前只授予了部分图片访问权限，请在系统设置里补充选择头像图片。'
        : '需要相册权限才能在应用内选择头像图片。';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text(
              '无法访问相册',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: onOpenSettings,
                  child: const Text('打开系统设置'),
                ),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('重新授权'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

