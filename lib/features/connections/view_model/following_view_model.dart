import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/connection_user.dart';
import 'connections_view_model.dart';

part 'following_view_model.g.dart';

/// Provider for managing following list (users you are following)
/// Derives data from shared connectionsViewModelProvider to avoid duplicate API calls
@riverpod
class FollowingViewModel extends _$FollowingViewModel {
  @override
  Future<List<ConnectionUser>> build() async {
    // Watch the shared connections provider and extract following
    final connectionsAsync = ref.watch(connectionsViewModelProvider);
    return connectionsAsync.when(
      data: (response) => response.following,
      loading: () => throw const AsyncLoading<List<ConnectionUser>>(),
      error: (error, stack) =>
          throw AsyncError<List<ConnectionUser>>(error, stack),
    );
  }

  /// Refresh following list by refreshing the shared connections provider
  Future<void> refresh() async {
    await ref.read(connectionsViewModelProvider.notifier).refresh();
  }
}
