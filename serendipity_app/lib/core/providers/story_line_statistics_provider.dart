import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../services/statistics_service.dart';
import '../../models/statistics.dart';
import 'membership_provider.dart';
import 'story_lines_provider.dart';

class StoryLineTagCloudResult {
  final bool isVisible;
  final List<TagCloudItem> items;

  const StoryLineTagCloudResult._({
    required this.isVisible,
    required this.items,
  });

  const StoryLineTagCloudResult.hidden()
      : this._(isVisible: false, items: const []);

  const StoryLineTagCloudResult.visible(List<TagCloudItem> items)
      : this._(isVisible: true, items: items);
}

final storyLineTagCloudProvider =
    Provider.family<StoryLineTagCloudResult, String>((ref, storyLineId) {
  final records = ref.watch(storyLineRecordsProvider(storyLineId));
  final membership = ref.watch(membershipProvider).valueOrNull;

  final hasAdvancedStatisticsAccess = AppConfig.isDeveloperMode ||
      (membership != null && membership.isPremium);

  if (!hasAdvancedStatisticsAccess) {
    return const StoryLineTagCloudResult.hidden();
  }

  return StoryLineTagCloudResult.visible(
    StatisticsService.calculateTagCloud(records),
  );
});

