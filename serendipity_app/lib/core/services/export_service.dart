import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

class _DebugPaintSnapshot {
  final bool baselinesEnabled;
  final bool sizeEnabled;
  final bool pointersEnabled;
  final bool repaintRainbowEnabled;

  const _DebugPaintSnapshot({
    required this.baselinesEnabled,
    required this.sizeEnabled,
    required this.pointersEnabled,
    required this.repaintRainbowEnabled,
  });

  static _DebugPaintSnapshot? disableForExport() {
    if (!kDebugMode) return null;

    final snapshot = _DebugPaintSnapshot(
      baselinesEnabled: debugPaintBaselinesEnabled,
      sizeEnabled: debugPaintSizeEnabled,
      pointersEnabled: debugPaintPointersEnabled,
      repaintRainbowEnabled: debugRepaintRainbowEnabled,
    );

    debugPaintBaselinesEnabled = false;
    debugPaintSizeEnabled = false;
    debugPaintPointersEnabled = false;
    debugRepaintRainbowEnabled = false;

    return snapshot;
  }

  void restore() {
    if (!kDebugMode) return;

    debugPaintBaselinesEnabled = baselinesEnabled;
    debugPaintSizeEnabled = sizeEnabled;
    debugPaintPointersEnabled = pointersEnabled;
    debugRepaintRainbowEnabled = repaintRainbowEnabled;
  }
}

/// 图片导出服务
///
/// 负责将渲染好的图片字节保存到系统相册。
/// 截图逻辑由各自的 ExportCard Widget 负责，本服务只负责 I/O。
///
/// 调用者：
/// - RecordExportCard.export()
/// - StoryLineExportCard.export()
///
/// 设计原则：
/// - 单一职责：只负责保存，不负责渲染
/// - Fail Fast：Web 平台立即返回失败，不走后续逻辑
/// - Android 导出统一写入公共图片目录，降低 OEM 相册收录差异
class ExportService {
  ExportService._();

  static const String _androidRelativePath = 'Pictures/Serendipity';
  static const String _tempExportFolderName = 'serendipity_exports';

  static Future<void> _flushDebugPaintState() async {
    final renderView = RendererBinding.instance.renderViews.firstOrNull;
    renderView?.markNeedsPaint();
    renderView?.markNeedsLayout();
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
  }

  /// 在导出期间临时关闭 Flutter 调试辅助绘制，避免污染导出图片。
  static Future<T> runWithDebugPaintDisabled<T>(
    Future<T> Function() action,
  ) async {
    final debugPaintSnapshot = _DebugPaintSnapshot.disableForExport();

    try {
      if (debugPaintSnapshot != null) {
        await _flushDebugPaintState();
      }

      return await action();
    } finally {
      debugPaintSnapshot?.restore();
      if (debugPaintSnapshot != null) {
        await _flushDebugPaintState();
      }
    }
  }

  /// 将 [key] 对应的 RepaintBoundary 渲染为 PNG 字节
  ///
  /// [pixelRatio] 控制导出分辨率，默认 3.0
  ///
  /// 调用者：RecordExportCard.export()、StoryLineExportCard.export()
  static Future<Uint8List?> capture(
    GlobalKey key, {
    double pixelRatio = 3.0,
  }) async {
    if (kIsWeb) return null;

    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// 将字节保存为图片到系统相册
  ///
  /// 返回 true 表示保存成功
  ///
  /// 调用者：RecordExportCard.export()、StoryLineExportCard.export()
  static Future<bool> saveToGallery(
    Uint8List bytes, {
    required String name,
  }) async {
    if (kIsWeb) return false;

    final permissionState = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        iosAccessLevel: IosAccessLevel.addOnly,
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      ),
    );
    if (!permissionState.isAuth) return false;

    final filename = '${name}_${DateTime.now().millisecondsSinceEpoch}.png';
    final asset = await _saveImageAsset(bytes, filename: filename);
    return await _verifySavedAsset(asset, expectedFilename: filename);
  }

  static Future<AssetEntity> _saveImageAsset(
    Uint8List bytes, {
    required String filename,
  }) async {
    final now = DateTime.now();

    if (Platform.isAndroid) {
      final tempFile = await _writeTempImageFile(bytes, filename: filename);
      return PhotoManager.editor.saveImageWithPath(
        tempFile.path,
        title: filename,
        relativePath: _androidRelativePath,
        creationDate: now,
      );
    }

    return PhotoManager.editor.saveImage(
      bytes,
      filename: filename,
      title: filename,
      creationDate: now,
    );
  }

  static Future<File> _writeTempImageFile(
    Uint8List bytes, {
    required String filename,
  }) async {
    final tempDirectory = await getTemporaryDirectory();
    final exportDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}$_tempExportFolderName',
    );

    if (!exportDirectory.existsSync()) {
      await exportDirectory.create(recursive: true);
    }

    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}$filename',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<bool> _verifySavedAsset(
    AssetEntity asset, {
    required String expectedFilename,
  }) async {
    if (asset.id.isEmpty) {
      return false;
    }

    final refreshedAsset = await asset.obtainForNewProperties() ?? asset;
    final resolvedTitle = refreshedAsset.title ?? await refreshedAsset.titleAsync;
    if (resolvedTitle != expectedFilename) {
      return false;
    }

    if (Platform.isAndroid) {
      final relativePath = refreshedAsset.relativePath;
      if (relativePath == null || !relativePath.startsWith(_androidRelativePath)) {
        return false;
      }
    }

    final resolvedFile = await refreshedAsset.file;
    return resolvedFile != null && await resolvedFile.exists();
  }
}
