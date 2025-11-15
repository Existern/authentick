import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:exif/exif.dart';
import 'package:intl/intl.dart';

import '../repository/post_repository.dart';
import 'widgets/location_picker_dialog.dart';
import 'widgets/privacy_selector.dart';
import '../../onboarding/view_model/onboarding_view_model.dart';

/// Screen for creating a new post
/// This screen will be used both during onboarding and in the main app
/// Opens the camera by default when the screen is loaded
class CreatePostScreen extends ConsumerStatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onComplete;

  const CreatePostScreen({
    super.key,
    this.isOnboarding = false,
    this.onComplete,
  });

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  XFile? _selectedImage;
  bool _isLoading = false;
  String? _location;
  double? _latitude;
  double? _longitude;
  PostPrivacy _privacy = PostPrivacy.friends;

  @override
  void initState() {
    super.initState();
    // Open camera automatically when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  /// Get current device location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _location = null;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _location = null;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final locationName = [
          placemark.locality,
          placemark.administrativeArea,
          placemark.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _location = locationName;
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }
    } catch (e) {
      setState(() {
        _location = null;
        _latitude = null;
        _longitude = null;
      });
    }
  }

  /// Extract location from image EXIF data
  Future<void> _extractLocationFromImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isEmpty) {
        await _getCurrentLocation();
        return;
      }

      // Try to get GPS coordinates from EXIF
      final latValue = data['GPS GPSLatitude'];
      final lonValue = data['GPS GPSLongitude'];

      if (latValue != null && lonValue != null) {
        // Parse GPS coordinates and get location name
        await _getCurrentLocation(); // Fallback for now
      } else {
        await _getCurrentLocation();
      }
    } catch (e) {
      // Fallback to current location if EXIF reading fails
      await _getCurrentLocation();
    }
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = photo;
        });
        // Extract location from image
        await _extractLocationFromImage(photo.path);
      } else {
        // User cancelled camera
        if (widget.isOnboarding && mounted) {
          // Go back to previous screen if in onboarding
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open camera: $e')),
        );
      }
    }
  }

  Future<void> _retakePhoto() async {
    setState(() {
      _selectedImage = null;
      _location = null;
    });
    await _openCamera();
  }

  Future<void> _selectFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = photo;
        });
        // Extract location from image
        await _extractLocationFromImage(photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select photo: $e')),
        );
      }
    }
  }

  Future<void> _changeLocation() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => LocationPickerDialog(currentLocation: _location),
    );

    if (result != null) {
      setState(() {
        _location = result;
      });
    }
  }

  Future<void> _submitPost() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(postRepositoryProvider);

      // Determine content type from file extension
      final filePath = _selectedImage!.path;
      final extension = filePath.split('.').last.toLowerCase();
      String contentType = 'image/jpeg';
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      }

      final postResponse = await repository.createPost(
        imagePath: filePath,
        contentType: contentType,
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        privacy: _privacy,
        location: _location,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (!mounted) return;

      // If this is onboarding, store the post data for the share screen
      if (widget.isOnboarding) {
        final mediaUrl = postResponse.data.media.isNotEmpty
            ? postResponse.data.media.first.mediaUrl
            : null;

        // Format the time - convert from UTC to local timezone
        String? formattedTime;
        try {
          // Parse the UTC time from server
          final createdAtUtc = DateTime.parse(postResponse.data.createdAt);
          // Convert to local timezone
          final createdAtLocal = createdAtUtc.toLocal();
          // Format to "3:45 PM" format
          formattedTime = DateFormat('h:mm a').format(createdAtLocal);
        } catch (e) {
          // If time parsing fails, don't show time
          formattedTime = null;
        }

        ref.read(onboardingViewModelProvider.notifier).updateFirstPostData(
          mediaUrl: mediaUrl,
          location: _location,
          time: formattedTime,
        );
      }

      setState(() {
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Complete the flow
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _selectedImage == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Header
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        const Text(
                          'New moment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                  ),
                ),

                // Image - Fixed height container
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRect(
                        child: Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Location overlay on image (centered at bottom)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _changeLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _location ?? 'Add location...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Caption - Scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Caption input
                          TextField(
                            controller: _captionController,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Add a caption...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                            maxLines: 2,
                            minLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Privacy selector - Fixed above button
                Container(
                  color: Colors.white,
                  child: PrivacySelector(
                    currentPrivacy: _privacy,
                    onPrivacyChanged: (privacy) {
                      setState(() {
                        _privacy = privacy;
                      });
                    },
                  ),
                ),

                // Share button at the bottom
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3620B3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Share this moment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
