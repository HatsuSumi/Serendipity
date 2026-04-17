import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class AvatarPickerGrid extends StatelessWidget {
  final ScrollController controller;
  final List<AssetEntity> assets;
  final bool isLoadingMore;
  final ValueChanged<AssetEntity> onAssetTap;

  const AvatarPickerGrid({
    super.key,
    required this.controller,
    required this.assets,
    required this.isLoadingMore,
    required this.onAssetTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: assets.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= assets.length) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final asset = assets[index];
        return AvatarAssetTile(
          asset: asset,
          onTap: () => onAssetTap(asset),
        );
      },
    );
  }
}

class AvatarAssetTile extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onTap;

  const AvatarAssetTile({
    super.key,
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
                    return const AssetPlaceholder(
                      icon: Icons.broken_image_outlined,
                    );
                  }
                  return const AssetPlaceholder(icon: Icons.image_outlined);
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

class AssetPlaceholder extends StatelessWidget {
  final IconData icon;

  const AssetPlaceholder({
    super.key,
    required this.icon,
  });

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

