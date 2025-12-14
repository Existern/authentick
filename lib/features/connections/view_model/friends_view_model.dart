import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/connection_user.dart';
import 'connections_view_model.dart';

part 'friends_view_model.g.dart';

/// Provider for managing friends list (accepted friend connections)
/// Derives data from shared connectionsViewModelProvider to avoid duplicate API calls
@riverpod
class FriendsViewModel extends _$FriendsViewModel {
  @override
  Future<List<ConnectionUser>> build() async {
    // Watch the shared connections provider and extract friends
    final connectionsAsync = ref.watch(connectionsViewModelProvider);
    return connectionsAsync.when(
      data: (response) => response.friends,
      loading: () => throw const AsyncLoading<List<ConnectionUser>>(),
      error: (error, stack) =>
          throw AsyncError<List<ConnectionUser>>(error, stack),
    );
  }

  /// Refresh friends list by refreshing the shared connections provider
  Future<void> refresh() async {
    await ref.read(connectionsViewModelProvider.notifier).refresh();
  }
}
