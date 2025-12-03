import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerDialog extends StatefulWidget {
  final String? currentLocation;

  const LocationPickerDialog({super.key, this.currentLocation});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Location> _searchResults = [];
  List<String> _locationSuggestions = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _locationSuggestions = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final locations = await locationFromAddress(query);
      final List<String> suggestions = [];

      for (var location in locations) {
        final placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final locationName = [
            placemark.locality,
            placemark.administrativeArea,
            placemark.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          suggestions.add(locationName);
        }
      }

      setState(() {
        _searchResults = locations;
        _locationSuggestions = suggestions;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _locationSuggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              children: [
                const Text(
                  'Change location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Enter a location...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchLocation(value);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Results
            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_locationSuggestions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _locationSuggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                      ),
                      title: Text(
                        _locationSuggestions[index],
                        style: const TextStyle(color: Colors.black87),
                      ),
                      onTap: () {
                        Navigator.of(context).pop(_locationSuggestions[index]);
                      },
                    );
                  },
                ),
              )
            else if (_searchController.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No locations found',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Search for a location',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
