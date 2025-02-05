import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';

class UploadScreen extends StatefulWidget {
  final ImageSource source;
  const UploadScreen({super.key, required this.source});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  String? _selectedVideoPath;
  bool _isUploading = false;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _userService = UserService();
  final List<String> _foodTags = [];

  @override
  void initState() {
    super.initState();
    // Automatically open video picker/camera when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickVideo();
    });
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: widget.source);

    if (video != null) {
      setState(() {
        _selectedVideoPath = video.path;
      });
    } else {
      // If no video was selected/captured, go back
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<String?> _uploadToFirebase(File videoFile) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Upload to Firebase Storage
      final storageRef = _storage
          .ref()
          .child('videos/$userId/${DateTime.now().millisecondsSinceEpoch}.mp4');

      // Set proper metadata for video upload
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {'userId': userId},
      );

      // Upload with metadata
      await storageRef.putFile(videoFile, metadata);

      // Get download URL
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Firebase upload error details: $e'); // Add detailed logging
      throw Exception('Firebase upload failed: $e');
    }
  }

  Future<void> _uploadVideo() async {
    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upload videos')),
      );
      return;
    }

    if (_selectedVideoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video first')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final videoFile = File(_selectedVideoPath!);

      // 1. Upload to Firebase Storage
      final videoUrl = await _uploadToFirebase(videoFile);

      // 2. Save metadata to Firestore with food tags
      await _userService.addUserVideo(
        user.uid,
        videoUrl!,
        description: _descriptionController.text,
        foodTags: _foodTags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload successful!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Upload error details: $e'); // Add detailed logging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_foodTags.contains(tag)) {
      setState(() {
        _foodTags.add(tag);
        _tagController.clear();
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickVideo,
              icon: const Icon(Icons.video_library),
              label: const Text('Select Video'),
            ),
            if (_selectedVideoPath != null) ...[
              const SizedBox(height: 16),
              Text(
                'Selected video: ${_selectedVideoPath!.split('/').last}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Add Food Tags',
                      hintText: 'Enter a food tag',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Tag',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_foodTags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _foodTags
                    .map((tag) => Chip(
                          label: Text(tag),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _foodTags.remove(tag);
                            });
                          },
                        ))
                    .toList(),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadVideo,
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Upload Video'),
            ),
          ],
        ),
      ),
    );
  }
}
