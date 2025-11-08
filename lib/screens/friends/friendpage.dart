import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Friendpage extends StatefulWidget {
  const Friendpage({super.key});

  @override
  State<Friendpage> createState() => _FriendpageState();
}

class _FriendpageState extends State<Friendpage> {
  String selectedTab = 'Friend requests';

  // Static data for different tabs
  final Map<String, List<Map<String, dynamic>>> userData = {
    'Friend requests': [
      {
        'name': 'Andrew',
        'username': '@theandrew',
        'image': 'https://randomuser.me/api/portraits/men/1.jpg',
        'status': 'pending'
      },
      {
        'name': 'Peter',
        'username': '@thepeter',
        'image': 'https://randomuser.me/api/portraits/men/2.jpg',
        'status': 'pending'
      },
    ],
    'Friends': [
      {
        'name': 'Andrew',
        'username': '@theandrew',
        'image': 'https://randomuser.me/api/portraits/men/1.jpg',
      },
      {
        'name': 'Peter',
        'username': '@thepeter',
        'image': 'https://randomuser.me/api/portraits/men/2.jpg',
      },
    ],
    'Following': [
      {
        'name': 'Andrew',
        'username': '@theandrew',
        'image': 'https://randomuser.me/api/portraits/men/1.jpg',
      },
      {
        'name': 'Peter',
        'username': '@thepeter',
        'image': 'https://randomuser.me/api/portraits/men/2.jpg',
      },
    ],
    'Followers': [
      {
        'name': 'Peter',
        'username': '@thepeter',
        'image': 'https://randomuser.me/api/portraits/men/2.jpg',
      },
    ],
    'Friends of friends': [
      {
        'name': 'Andrew',
        'username': '@theandrew',
        'image': 'https://randomuser.me/api/portraits/men/1.jpg',
      },
      {
        'name': 'Peter',
        'username': '@thepeter',
        'image': 'https://randomuser.me/api/portraits/men/2.jpg',
      },
    ],
  };

  Map<String, dynamic> userStates = {};

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
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
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
                    color: Colors.black.withOpacity(0.1),
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

  int getTabCount(String tab) {
    return userData[tab]?.length ?? 0;
  }

  @override
  Widget build(BuildContext context) {
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
                      showCustomNotification('Invite feature coming soon!');
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

            // Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildTab(
                    label: 'Friend requests',
                    icon: Icons.person_add,
                    count: getTabCount('Friend requests'),
                  ),
                  _buildTab(
                    label: 'Friends',
                    icon: Icons.people,
                    count: getTabCount('Friends'),
                  ),
                  _buildTab(
                    label: 'Following',
                    icon: Icons.visibility,
                    count: getTabCount('Following'),
                  ),
                  _buildTab(
                    label: 'Followers',
                    icon: Icons.group,
                    count: getTabCount('Followers'),
                  ),
                  _buildTab(
                    label: 'Friends of friends',
                    icon: Icons.people_outline,
                    count: getTabCount('Friends of friends'),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // User List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: userData[selectedTab]?.length ?? 0,
                itemBuilder: (context, index) {
                  final user = userData[selectedTab]![index];
                  return _buildUserCard(user);
                },
              ),
            ),
          ],
        ),
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
              '$label($count)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF3620B3) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    String userKey = '${user['username']}_$selectedTab';
    String? state = userStates[userKey];

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
              image: DecorationImage(
                image: NetworkImage(user['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user['username'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
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
              _showOptionsMenu(context, user);
            },
          ),

          const SizedBox(width: 8),

          // Action Buttons
          _buildActionButtons(user, userKey, state),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      Map<String, dynamic> user, String userKey, String? state) {
    if (selectedTab == 'Friend requests') {
      if (state == 'accepted') {
        return const SizedBox.shrink();
      }
      return Row(
        children: [
          OutlinedButton(
            onPressed: () {
              showCustomNotification('Friend request denied', isError: true);
              setState(() {
                userData[selectedTab]?.remove(user);
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF3620B3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Deny',
              style: TextStyle(color: Color(0xFF3620B3)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              showCustomNotification('Friend request accepted');
              setState(() {
                userStates[userKey] = 'accepted';
                userData[selectedTab]?.remove(user);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3620B3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Accept',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    } else if (selectedTab == 'Friends') {
      if (state == 'unfriended') {
        return ElevatedButton(
          onPressed: () {
            showCustomNotification('Friend request sent');
            setState(() {
              userStates[userKey] = 'pending';
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3620B3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          child: const Text(
            'Make friend',
            style: TextStyle(color: Colors.white),
          ),
        );
      }
      if (state == 'pending') {
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule, size: 16),
          label: const Text('Pending'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
      return ElevatedButton(
        onPressed: () {
          showCustomNotification('You unfriended ${user['name']}', isError: true);
          setState(() {
            userStates[userKey] = 'unfriended';
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3620B3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
        child: const Text(
          'Unfriend',
          style: TextStyle(color: Colors.white),
        ),
      );
    } else if (selectedTab == 'Following') {
      if (state == 'unfollowed') {
        return ElevatedButton(
          onPressed: () {
            showCustomNotification('You are now following ${user['name']}');
            setState(() {
              userStates[userKey] = null;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3620B3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            'Follow',
            style: TextStyle(color: Colors.white),
          ),
        );
      }
      return ElevatedButton(
        onPressed: () {
          showCustomNotification('Friend request sent');
          setState(() {
            userStates[userKey] = 'friend_requested';
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3620B3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text(
          'Make friend',
          style: TextStyle(color: Colors.white),
        ),
      );
    } else if (selectedTab == 'Followers') {
      if (state == 'following') {
        return ElevatedButton(
          onPressed: () {
            showCustomNotification('You unfollowed ${user['name']}', isError: true);
            setState(() {
              userStates[userKey] = null;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3620B3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            'Unfollow',
            style: TextStyle(color: Colors.white),
          ),
        );
      }
      return ElevatedButton(
        onPressed: () {
          showCustomNotification('You are now following ${user['name']}');
          setState(() {
            userStates[userKey] = 'following';
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3620B3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
        child: const Text(
          'Follow',
          style: TextStyle(color: Colors.white),
        ),
      );
    } else if (selectedTab == 'Friends of friends') {
      if (state == 'pending') {
        return ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule, size: 16),
          label: const Text('Pending'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
      return ElevatedButton(
        onPressed: () {
          showCustomNotification('Friend request sent');
          setState(() {
            userStates[userKey] = 'pending';
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3620B3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
        child: const Text(
          'Follow',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showOptionsMenu(BuildContext context, Map<String, dynamic> user) {
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3620B3).withOpacity(0.1),
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
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showCustomNotification('Opening ${user['name']}\'s profile');
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.block,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Block User',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showCustomNotification('${user['name']} has been blocked', isError: true);
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
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
}
