import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

class AvatarPickerController {
  static const int pageSize = 80;
  static const PermissionRequestOption permissionRequest =
      PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      );

  PermissionState? permissionState;
  List<AssetPathEntity> albums = const [];
  AssetPathEntity? selectedAlbum;
  final List<AssetEntity> assets = [];

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 0;

  Future<void> loadInitialData() async {
    isLoading = true;

    final nextPermissionState = await PhotoManager.requestPermissionExtend(
      requestOption: permissionRequest,
    );

    if (!nextPermissionState.hasAccess) {
      permissionState = nextPermissionState;
      albums = const [];
      selectedAlbum = null;
      assets.clear();
      hasMore = false;
      isLoading = false;
      isLoadingMore = false;
      currentPage = 0;
      return;
    }

    final nextAlbums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(),
    );
    final nextSelectedAlbum = nextAlbums.isNotEmpty ? nextAlbums.first : null;

    permissionState = nextPermissionState;
    albums = nextAlbums;
    selectedAlbum = nextSelectedAlbum;
    assets.clear();
    currentPage = 0;
    hasMore = nextSelectedAlbum != null;
    isLoadingMore = false;

    if (nextSelectedAlbum != null) {
      await loadNextPage(reset: true);
      return;
    }

    isLoading = false;
  }

  Future<void> loadNextPage({bool reset = false}) async {
    final album = selectedAlbum;
    if (album == null) {
      isLoading = false;
      return;
    }
    if (!reset && (isLoadingMore || !hasMore)) {
      return;
    }

    if (reset) {
      isLoading = true;
      assets.clear();
      currentPage = 0;
      hasMore = true;
      isLoadingMore = false;
    } else {
      isLoadingMore = true;
    }

    final page = currentPage;
    final nextAssets = await album.getAssetListPaged(
      page: page,
      size: pageSize,
    );

    assets.addAll(nextAssets);
    currentPage = page + 1;
    hasMore = nextAssets.length == pageSize;
    isLoading = false;
    isLoadingMore = false;
  }

  Future<void> selectAlbum(AssetPathEntity? album) async {
    if (album == null || album == selectedAlbum) {
      return;
    }

    selectedAlbum = album;
    assets.clear();
    currentPage = 0;
    hasMore = true;
    await loadNextPage(reset: true);
  }

  Future<File?> readAssetFile(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null || !file.existsSync()) {
      return null;
    }
    return file;
  }

  bool shouldLoadMore(double pixels, double maxScrollExtent) {
    return !isLoadingMore &&
        hasMore &&
        pixels >= maxScrollExtent - 320;
  }

  void debugLog(String message, Object error) {
    if (kDebugMode) {
      debugPrint('$message$error');
    }
  }
}

