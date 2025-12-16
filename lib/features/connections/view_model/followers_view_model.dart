import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/connection_user.dart';
import 'connections_view_model.dart';

part 'followers_view_model.g.dart';

/// Provider for managing followers list (accepted follower connections)
/// Derives data from shared connectionsViewModelProvider to avoid duplicate API calls
@riverpod
class FollowersViewModel extends _$FollowersViewModel {
  @override
  Future<List<ConnectionUser>> build() async {
    // Watch the shared connections provider and extract followers
    final connectionsResponse = await ref.watch(
      connectionsViewModelProvider.future,
    );
    return connectionsResponse.followers;
  }

  /// Refresh followers list by refreshing the shared connections provider
  Future<void> refresh() async {
    await ref.read(connectionsViewModelProvider.notifier).refresh();
  }
}
