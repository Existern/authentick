import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/screens/settings/listtile.dart';
import 'package:flutter_mvvm_riverpod/screens/settings/profile_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isEditing = false;
  String name = 'Alok Mishra';
  String handle = '@alokmishra';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController handleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = name;
    handleController.text = handle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeArea(
                child: Stack(
                  children: [
                    // Back button on the left
                    Positioned(
                      left: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.arrow_back,
                            size: 28,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    // Centered title
                    const Center(
                      child: Text(
                        'Settings',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isEditing = false;
                      });
                    },
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            !isEditing ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),

                  if (!isEditing)
                    GestureDetector(
                      onTap: () {
                        setState(() => isEditing = true);
                      },
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF3620B3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              nameController.text = name;
                              handleController.text = handle;
                              isEditing = false;
                            });
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              name = nameController.text;
                              handle = handleController.text;
                              isEditing = false;
                            });
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF3620B3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 8),


              ProfileSection(
                nameController: nameController,
                handleController: handleController,
                isEditable: isEditing,
                onSave: () {},
              ),

              const SizedBox(height: 24),
              const Text(
                'Trust & Privacy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              BorderedListTile(title: 'Privacy Policy', onTap: () {}),
              const SizedBox(height: 8),
              BorderedListTile(title: 'Terms of Use', onTap: () {}),
              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
