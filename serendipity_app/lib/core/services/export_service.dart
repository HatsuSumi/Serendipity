import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

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
class ExportService {
  ExportService._();

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

    final result = await ImageGallerySaver.saveImage(
      bytes,
      name: '${name}_${DateTime.now().millisecondsSinceEpoch}',
    );
    return result['isSuccess'] == true;
  }
}

