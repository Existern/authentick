import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../features/connections/model/connection_request.dart';
import '../../features/connections/model/connection_user.dart';
import '../../features/connections/model/discover_user.dart';
import '../../features/connections/view_model/pending_connections_view_model.dart';
import '../../features/connections/view_model/friends_view_model.dart';
import '../../features/connections/view_model/followers_view_model.dart';
import '../../features/connections/view_model/following_view_model.dart';
import '../../features/connections/view_model/discover_users_view_model.dart';
import '../../features/connections/view_model/search_users_view_model.dart';
import '../../features/user/repository/user_profile_repository.dart';
import '../profile/user_profile_screen.dart';
import 'widgets/invite_modal.dart';

class Friendpage extends ConsumerStatefulWidget {
  const Friendpage({super.key});

  @override
  ConsumerState<Friendpage> createState() => _FriendpageState();
}

class _FriendpageState extends ConsumerState<Friendpage> {
  String selectedTab = 'Friend requests';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasTriedRefresh = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  String _lastSearchedQuery = '';
  bool _isLoadingMoreDiscover = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _searchQuery = query;
      });

      // Cancel previous timer
      _debounceTimer?.cancel();

      // Handle search for Discover People tab
      if (selectedTab == 'Discover People') {
        if (query.isEmpty) {
          // Clear immediately when search is empty
          ref.read(searchUsersViewModelProvider.notifier).clear();
          setState(() {
            _lastSearchedQuery = '';
          });
        } else if (query.length >= 3) {
          // Debounce the search with 300ms delay
          _debounceTimer = Timer(const Duration(milliseconds: 300), () {
            if (mounted) {
              ref.read(searchUsersViewModelProvider.notifier).search(query);
              setState(() {
                _lastSearchedQuery = query;
              });
            }
          });
        }
      }
    });

    _scrollController.addListener(_onScroll);

    // Trigger profile fetch on first load if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProfileLoaded();
    });
  }

  void _onScroll() {
    // Scroll listener removed - pagination now uses Load More button
  }

  Future<void> _ensureProfileLoaded() async {
    final profileState = ref.read(userProfileRepositoryProvider);

    // If profile data is null and not currently loading, trigger refresh
    if (profileState.value == null &&
        !profileState.isLoading &&
        !_hasTriedRefresh) {
      _hasTriedRefresh = true;
      // Fetch from API
      await ref.read(userProfileRepositoryProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void showCustomNotification(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 140,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isError
                    ? const Color(0xFFFFE5E5)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isError
                          ? const Color(0xFFFF5252)
                          : const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isError ? Icons.close : Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isError
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF2E7D32),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  int getTabCount(
    String label,
    AsyncValue<List<ConnectionRequest>> pendingConnectionsAsync,
    AsyncValue<List<ConnectionUser>> friendsAsync,
    AsyncValue<List<ConnectionUser>> followersAsync,
    AsyncValue<List<ConnectionUser>> followingAsync,
  ) {
    switch (label) {
      case 'Friend requests':
        return pendingConnectionsAsync.maybeWhen(
          data: (connections) => connections.length,
          orElse: () => 0,
        );
      case 'Friends':
        return friendsAsync.maybeWhen(
          data: (connections) => connections.length,
          orElse: () => 0,
        );
      case 'Following':
        return followingAsync.maybeWhen(
          data: (connections) => connections.length,
          orElse: () => 0,
        );
      case 'Followers':
        return followersAsync.maybeWhen(
          data: (connections) => connections.length,
          orElse: () => 0,
        );
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingConnectionsAsync = ref.watch(
      pendingConnectionsViewModelProvider,
    );
    final friendsAsync = ref.watch(friendsViewModelProvider);
    final followersAsync = ref.watch(followersViewModelProvider);
    final followingAsync = ref.watch(followingViewModelProvider);
    final userProfileAsync = ref.watch(userProfileRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/images/authentick_logo.svg',
                    width: 30,
                    height: 30,
                  ),
                  GestureDetector(
                    onTap: () {
                      userProfileAsync.whenData((profile) {
                        if (profile != null) {
                          final inviteCode = profile.inviteCode ?? '';
                          final maxUses = profile.inviteCodeMaxUses ?? 3;
                          final currentUses =
                              profile.inviteCodeCurrentUses ?? 0;
                          final invitesLeft = maxUses - currentUses;

                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => InviteModal(
                              inviteCode: inviteCode,
                              invitesLeft: invitesLeft,
                              maxInvites: maxUses,
                              currentUses: currentUses,
                            ),
                          );
                        } else {
                          showCustomNotification(
                            'Unable to load invite data',
                            isError: true,
                          );
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          color: Color(0xFF3620B3),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Invite',
                          style: TextStyle(
                            color: Color(0xFF3620B3),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            _buildSearchBar(),

            // Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildTab(
                    label: 'Friend requests',
                    icon: Icons.person_add,
                    count: getTabCount(
                      'Friend requests',
                      pendingConnectionsAsync,
                      friendsAsync,
                      followersAsync,
                      followingAsync,
                    ),
                  ),
                  _buildTab(
                    label: 'Friends of friends',
                    icon: Icons.people_outline,
                    count: 0,
                  ),
                  _buildTab(
                    label: 'Discover People',
                    icon: Icons.explore,
                    count: 0,
                  ),
                  _buildTab(
                    label: 'Friends',
                    icon: Icons.people,
                    count: getTabCount(
                      'Friends',
                      pendingConnectionsAsync,
                      friendsAsync,
                      followersAsync,
                      followingAsync,
                    ),
                  ),
                  _buildTab(
                    label: 'Following',
                    icon: Icons.visibility,
                    count: getTabCount(
                      'Following',
                      pendingConnectionsAsync,
                      friendsAsync,
                      followersAsync,
                      followingAsync,
                    ),
                  ),
                  _buildTab(
                    label: 'Followers',
                    icon: Icons.group,
                    count: getTabCount(
                      'Followers',
                      pendingConnectionsAsync,
                      friendsAsync,
                      followersAsync,
                      followingAsync,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // User List
            Expanded(
              child: _buildContent(
                pendingConnectionsAsync,
                friendsAsync,
                followersAsync,
                followingAsync,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search for people',
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF757575),
            size: 24,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Color(0xFF757575),
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3620B3), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    AsyncValue<List<ConnectionRequest>> pendingConnectionsAsync,
    AsyncValue<List<ConnectionUser>> friendsAsync,
    AsyncValue<List<ConnectionUser>> followersAsync,
    AsyncValue<List<ConnectionUser>> followingAsync,
  ) {
    if (selectedTab == 'Friend requests') {
      return pendingConnectionsAsync.when(
        data: (connections) {
          // Filter based on search query
          final filteredConnections = _searchQuery.isEmpty
              ? connections
              : connections.where((connection) {
                  final user = connection.requesterUser;
                  if (user == null) return false;

                  final fullName = user.fullName.toLowerCase();
                  final username = (user.username ?? '').toLowerCase();

                  return fullName.contains(_searchQuery) ||
                      username.contains(_searchQuery);
                }).toList();

          if (filteredConnections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isEmpty
                        ? Icons.person_add_disabled
                        : Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No pending friend requests'
                        : 'No results found for "$_searchQuery"',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(pendingConnectionsViewModelProvider.notifier)
                  .refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredConnections.length,
              itemBuilder: (context, index) {
                final connection = filteredConnections[index];
                return _buildConnectionCard(connection);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF3620B3)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Failed to load friend requests',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref
                      .read(pendingConnectionsViewModelProvider.notifier)
                      .refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Friends tab
    if (selectedTab == 'Friends') {
      return friendsAsync.when(
        data: (connections) {
          // Filter based on search query
          final filteredConnections = _searchQuery.isEmpty
              ? connections
              : connections.where((user) {
                  final fullName = user.fullName.toLowerCase();
                  final username = (user.username ?? '').toLowerCase();

                  return fullName.contains(_searchQuery) ||
                      username.contains(_searchQuery);
                }).toList();

          if (filteredConnections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isEmpty
                        ? Icons.people_outline
                        : Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No friends yet'
                        : 'No results found for "$_searchQuery"',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(friendsViewModelProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredConnections.length,
              itemBuilder: (context, index) {
                final user = filteredConnections[index];
                return _buildFriendCard(user);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF3620B3)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Failed to load friends',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(friendsViewModelProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Following tab
    if (selectedTab == 'Following') {
      return followingAsync.when(
        data: (connections) {
          // Filter based on search query
          final filteredConnections = _searchQuery.isEmpty
              ? connections
              : connections.where((user) {
                  final fullName = user.fullName.toLowerCase();
                  final username = (user.username ?? '').toLowerCase();

                  return fullName.contains(_searchQuery) ||
                      username.contains(_searchQuery);
                }).toList();

          if (filteredConnections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isEmpty
                        ? Icons.visibility_outlined
                        : Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Not following anyone yet'
                        : 'No results found for "$_searchQuery"',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(followingViewModelProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredConnections.length,
              itemBuilder: (context, index) {
                final user = filteredConnections[index];
                return _buildFollowingCard(user);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF3620B3)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Failed to load following',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(followingViewModelProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Followers tab
    if (selectedTab == 'Followers') {
      return followersAsync.when(
        data: (connections) {
          // Filter based on search query
          final filteredConnections = _searchQuery.isEmpty
              ? connections
              : connections.where((user) {
                  final fullName = user.fullName.toLowerCase();
                  final username = (user.username ?? '').toLowerCase();

                  return fullName.contains(_searchQuery) ||
                      username.contains(_searchQuery);
                }).toList();

          if (filteredConnections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isEmpty
                        ? Icons.group_outlined
                        : Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No followers yet'
                        : 'No results found for "$_searchQuery"',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(followersViewModelProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredConnections.length,
              itemBuilder: (context, index) {
                final user = filteredConnections[index];
                return _buildFollowerCard(user);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF3620B3)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Failed to load followers',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(followersViewModelProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Discover People tab
    if (selectedTab == 'Discover People') {
      // If search query is >= 3 characters, show search results
      if (_searchQuery.length >= 3) {
        final searchUsersAsync = ref.watch(searchUsersViewModelProvider);
        final searchViewModel = ref.read(searchUsersViewModelProvider.notifier);

        // Show loading while waiting for debounce timer or if query hasn't been searched yet
        if (_lastSearchedQuery != _searchQuery) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3620B3)),
          );
        }

        return searchUsersAsync.when(
          data: (users) {
            // Only show "no results" if we have actually searched and got empty results
            if (searchViewModel.lastQuery.isNotEmpty && users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No results found for "$_lastSearchedQuery"',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // Show loading indicator initially if we haven't searched yet
            if (searchViewModel.lastQuery.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF3620B3)),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _buildDiscoverUserCard(user);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF3620B3)),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Failed to search users',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref
                        .read(searchUsersViewModelProvider.notifier)
                        .search(_searchQuery);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      } else if (_searchQuery.isNotEmpty && _searchQuery.length < 3) {
        // Show message about minimum query length
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter at least 3 characters to search',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      } else {
        // Show default discover users
        final discoverUsersAsync = ref.watch(discoverUsersViewModelProvider);
        return discoverUsersAsync.when(
          data: (discoverUsers) {
            if (discoverUsers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.explore_off,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No users to discover',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final discoverViewModel = ref.read(
              discoverUsersViewModelProvider.notifier,
            );

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _isLoadingMoreDiscover = false;
                });
                await discoverViewModel.refresh();
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: 100, // Add bottom padding to avoid collision with FAB
                  left: 0,
                  right: 0,
                ),
                itemCount:
                    discoverUsers.length + (discoverViewModel.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == discoverUsers.length) {
                    // Show Load More button or loading indicator
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      child: Center(
                        child: _isLoadingMoreDiscover
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF3620B3),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    _isLoadingMoreDiscover = true;
                                  });
                                  try {
                                    await discoverViewModel.loadMore();
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isLoadingMoreDiscover = false;
                                      });
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3620B3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Load More',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    );
                  }
                  final discoverUser = discoverUsers[index];
                  return _buildDiscoverUserCardWithMutual(discoverUser);
                },
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF3620B3)),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load discover users',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.read(discoverUsersViewModelProvider.notifier).refresh();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Other tabs - not implemented yet
    return Center(
      child: Text(
        '$selectedTab - Coming soon!',
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required IconData icon,
    required int count,
  }) {
    final bool isSelected = selectedTab == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3620B3) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label == 'Discover People' ? label : '$label($count)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF3620B3)
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(ConnectionRequest connectionRequest) {
    // The user who sent the request (requester_user is the one who sent it to the current user)
    final requestUser = connectionRequest.requesterUser;

    if (requestUser == null) {
      return const SizedBox.shrink();
    }

    final displayName = requestUser.fullName;
    final username = '@${requestUser.username ?? 'user'}';
    final profileImage = requestUser.profileImage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
              image: profileImage != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(profileImage),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profileImage == null
                ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                : null,
          ),
          const SizedBox(width: 12),

          // Name and Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  username,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Three dot menu
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/3dot.svg',
              width: 20,
              height: 20,
            ),
            onPressed: () {
              _showOptionsMenu(context, username);
            },
          ),

          const SizedBox(width: 8),

          // Action Buttons
          _buildActionButtons(connectionRequest),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ConnectionRequest connectionRequest) {
    return Row(
      children: [
        OutlinedButton(
          onPressed: () async {
            try {
              await ref
                  .read(pendingConnectionsViewModelProvider.notifier)
                  .rejectConnection(connectionRequest.id);
              if (mounted) {
                showCustomNotification('Friend request denied', isError: true);
              }
            } catch (e) {
              if (mounted) {
                showCustomNotification('Failed to deny request', isError: true);
              }
            }
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF3620B3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Deny', style: TextStyle(color: Color(0xFF3620B3))),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            try {
              await ref
                  .read(pendingConnectionsViewModelProvider.notifier)
                  .acceptConnection(connectionRequest.id);
              if (mounted) {
                showCustomNotification('Friend request accepted');
              }
            } catch (e) {
              if (mounted) {
                showCustomNotification(
                  'Failed to accept request',
                  isError: true,
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3620B3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Accept', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildFriendCard(ConnectionUser user) {
    // Get the connected friend user
    final displayName = user.fullName;
    final username = '@${user.username ?? 'user'}';
    final profileImage = user.profileImage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
              image: profileImage != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(profileImage),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profileImage == null
                ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                : null,
          ),
          const SizedBox(width: 12),

          // Name and Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  username,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Three dot menu
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/3dot.svg',
              width: 20,
              height: 20,
            ),
            onPressed: () {
              _showOptionsMenu(context, user.username ?? 'User');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerCard(ConnectionUser user) {
    // Get the follower user
    final displayName = user.fullName;
    final username = '@${user.username ?? 'user'}';
    final profileImage = user.profileImage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
              image: profileImage != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(profileImage),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profileImage == null
                ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                : null,
          ),
          const SizedBox(width: 12),

          // Name and Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  username,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Three dot menu
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/3dot.svg',
              width: 20,
              height: 20,
            ),
            onPressed: () {
              _showOptionsMenu(context, user.username ?? 'User');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingCard(ConnectionUser user) {
    // Get the user being followed
    final displayName = user.fullName;
    final username = '@${user.username ?? 'user'}';
    final profileImage = user.profileImage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
              image: profileImage != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(profileImage),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profileImage == null
                ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                : null,
          ),
          const SizedBox(width: 12),

          // Name and Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  username,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Three dot menu
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/3dot.svg',
              width: 20,
              height: 20,
            ),
            onPressed: () {
              _showOptionsMenu(context, user.username ?? 'User');
            },
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, String username) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // View Profile
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3620B3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF3620B3),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'View Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showCustomNotification('Opening $username\'s profile');
                },
              ),
            ),

            // Block User
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.block, color: Colors.red, size: 24),
                ),
                title: const Text(
                  'Block User',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showCustomNotification(
                    '$username has been blocked',
                    isError: true,
                  );
                },
              ),
            ),

            // Report User
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.report,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Report User',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showCustomNotification('Report submitted');
                },
              ),
            ),

            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverUserCard(ConnectionUser user) {
    final displayName = user.fullName;
    final username = '@${user.username ?? 'user'}';
    final profileImage = user.profileImage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Profile Image - Clickable
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    userId: user.id,
                    initialUsername: user.username,
                  ),
                ),
              );
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
                image: profileImage != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(profileImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: profileImage == null
                  ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Name and Username - Clickable
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(
                      userId: user.id,
                      initialUsername: user.username,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    username,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Add Friend Button
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(searchUsersViewModelProvider.notifier)
                    .sendFriendRequest(user.id);
                if (mounted) {
                  showCustomNotification('Friend request sent');
                }
              } catch (e) {
                if (mounted) {
                  showCustomNotification(
                    'Failed to send request',
                    isError: true,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3620B3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Add Friend',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverUserCardWithMutual(DiscoverUser discoverUser) {
    final user = discoverUser.user;
    final mutualCount = discoverUser.mutualCount;
    final displayName = user.fullName;
    final username = '@${user.username ?? 'user'}';
    final profileImage = user.profileImage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Profile Image - Clickable
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    userId: user.id,
                    initialUsername: user.username,
                  ),
                ),
              );
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
                image: profileImage != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(profileImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: profileImage == null
                  ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Name, Username, and Mutual Friends - Clickable
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(
                      userId: user.id,
                      initialUsername: user.username,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    username,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (mutualCount > 0)
                    Text(
                      '$mutualCount mutual ${mutualCount == 1 ? 'friend' : 'friends'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF3620B3),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Add Friend Button
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(discoverUsersViewModelProvider.notifier)
                    .sendFriendRequest(user.id);
                if (mounted) {
                  showCustomNotification('Friend request sent');
                }
              } catch (e) {
                if (mounted) {
                  showCustomNotification(
                    'Failed to send request',
                    isError: true,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3620B3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Add Friend',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
