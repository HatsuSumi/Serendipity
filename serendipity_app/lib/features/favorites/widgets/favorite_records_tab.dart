import 'package:flutter/material.dart';

import '../../../core/providers/favorites_provider.dart';
import '../../../models/encounter_record.dart';
import 'favorite_record_card.dart';
import 'favorites_list_states.dart';

class FavoriteRecordsTab extends StatelessWidget {
  final FavoritesState favoritesState;
  final Future<void> Function() onRefresh;
  final Future<void> Function({required String recordId, required bool isDeleted})
      onUnfavoriteRecord;

  const FavoriteRecordsTab({
    super.key,
    required this.favoritesState,
    required this.onRefresh,
    required this.onUnfavoriteRecord,
  });

  @override
  Widget build(BuildContext context) {
    final records = favoritesState.favoritedRecords;
    final deletedRecords = favoritesState.deletedFavoritedRecords;
    final totalCount = records.length + deletedRecords.length;

    if (totalCount == 0) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            FavoriteRecordsEmptyState(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index < records.length) {
            return _buildRecordCard(
              records[index],
              isDeleted: false,
            );
          }

          return _buildRecordCard(
            deletedRecords[index - records.length],
            isDeleted: true,
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(EncounterRecord record, {required bool isDeleted}) {
    return FavoriteRecordCard(
      record: record,
      isDeleted: isDeleted,
      onUnfavorite: () => onUnfavoriteRecord(
        recordId: record.id,
        isDeleted: isDeleted,
      ),
    );
  }
}

