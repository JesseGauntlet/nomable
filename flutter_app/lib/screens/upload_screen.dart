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
  bool _uploadSuccess = false;
  bool _useAI = false;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _userService = UserService();
  final List<String> _foodTags = [];
  // Maximum file size in bytes (100MB)
  static const int _maxFileSize = 100 * 1024 * 1024;
  String? _selectedVideoError;

  @override
  void initState() {
    super.initState();
    // Automatically open video picker/camera when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickVideo();
    });
  }

  Future<bool> _checkVideoSize(String path) async {
    try {
      final file = File(path);
      final size = await file.length();
      if (size > _maxFileSize) {
        if (mounted) {
          setState(() {
            _selectedVideoError =
                'Video size (${(size / 1024 / 1024).toStringAsFixed(1)}MB) exceeds maximum allowed size (${(_maxFileSize / 1024 / 1024).toStringAsFixed(0)}MB)';
          });
        }
        return false;
      }
      setState(() {
        _selectedVideoError = null;
      });
      return true;
    } catch (e) {
      debugPrint('Error checking video size: $e');
      if (mounted) {
        setState(() {
          _selectedVideoError = 'Error checking video size';
        });
      }
      return false;
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: widget.source,
      maxDuration:
          const Duration(minutes: 5), // Limit video duration to 5 minutes
    );

    if (video != null) {
      // Check video size before setting it
      if (await _checkVideoSize(video.path)) {
        setState(() {
          _selectedVideoPath = video.path;
          _uploadSuccess = false;
        });
      } else {
        // If video is too large, clear the selection
        setState(() {
          _selectedVideoPath = null;
          _uploadSuccess = false;
        });
      }
    } else {
      // If no video was selected/captured, go back
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _resetState() {
    setState(() {
      _selectedVideoPath = null;
      _descriptionController.clear();
      _tagController.clear();
      _foodTags.clear();
      _uploadSuccess = false;
      _selectedVideoError = null;
    });
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

    // Double-check file size before upload
    if (!await _checkVideoSize(_selectedVideoPath!)) {
      return;
    }

    setState(() => _isUploading = true);

    try {
      final videoFile = File(_selectedVideoPath!);

      // 1. Create a Firestore document first to get the ID
      final postRef = FirebaseFirestore.instance.collection('posts').doc();

      // 2. Upload to Firebase Storage with postId in metadata
      final storageRef = _storage.ref().child(
          'videos/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.mp4');

      // Set proper metadata for video upload
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'userId': user.uid,
          'postId': postRef.id, // Include the post ID in metadata
          'useAI': _useAI.toString(),
        },
      );

      // Upload with metadata
      await storageRef.putFile(videoFile, metadata);
      final videoUrl = await storageRef.getDownloadURL();

      // 3. Save metadata to Firestore with food tags
      await postRef.set({
        'userId': user.uid,
        'mediaUrl': videoUrl,
        'mediaType': 'video',
        'foodTags': _foodTags,
        'description': _descriptionController.text,
        'swipeCounts': 0,
        'heartCount': 0,
        'bookmarkCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'previewGenerated': false, // Initialize preview status
        'thumbnailUrl':
            '', // Initialize empty thumbnail URL, will be updated by cloud function
      });

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadSuccess = true;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload successful! Processing video...'),
            duration: Duration(seconds: 3),
          ),
        );

        // Wait a moment to show the success state, then close
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      print('Upload error details: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
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
            if (_uploadSuccess) ...[
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Upload Successful!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Processing video...'),
                  ],
                ),
              ),
            ] else ...[
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
                if (_selectedVideoError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _selectedVideoError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Tag with AI'),
                subtitle: const Text('Let AI generate tags and description'),
                value: _useAI,
                onChanged: (bool value) {
                  setState(() {
                    _useAI = value;
                    // Clear manual inputs if AI is enabled
                    if (value) {
                      _descriptionController.clear();
                      _tagController.clear();
                      _foodTags.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                enabled: !_useAI,
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'AI will generate description if enabled',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      enabled: !_useAI,
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Add Food Tags',
                        hintText: 'AI will generate tags if enabled',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _useAI ? null : _addTag,
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
                onPressed: _isUploading || _selectedVideoError != null
                    ? null
                    : _uploadVideo,
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Upload Video'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
