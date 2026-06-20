import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../app_state.dart';
import 'home_page.dart';
import 'edit_profile_screen.dart';

class StoryListScreen extends StatefulWidget {
  final String categoryTitle; // e.g. "Age 8-12 pdf"
  final String categoryKey; // e.g. "ages_8_12_pdf"
  final String fileType; // "pdf" or "word"

  const StoryListScreen({
    super.key,
    required this.categoryTitle,
    required this.categoryKey,
    required this.fileType,
  });

  @override
  State<StoryListScreen> createState() => _StoryListScreenState();
}

class _StoryListScreenState extends State<StoryListScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadingFileName;

  @override
  void initState() {
    super.initState();
    _migrateExistingStories();
  }

  void _showLoginPromptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Login Required', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('You need to log in to upload new stories.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCompleteProfilePromptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Profile Incomplete', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Please update your profile with your Name and Phone Number to upload stories.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
            child: const Text('GO TO PROFILE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _startUploadFlow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginPromptDialog();
      return;
    }

    final isComplete = await AppState().isCurrentProfileComplete();
    if (!isComplete) {
      _showCompleteProfilePromptDialog();
      return;
    }

    _selectFileAndConfirm();
  }

  Future<void> _migrateExistingStories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await _firestore.collection('stories').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('visibility')) {
          await doc.reference.update({
            'visibility': 'everyone',
            'authorId': user.uid,
            'allowedUsers': <String>[],
          });
        }
      }
    } catch (e) {
      debugPrint('Migration info: $e');
    }
  }

  Future<void> _selectFileAndConfirm() async {
    try {
      final allowedExt = widget.fileType == 'pdf' ? ['pdf'] : ['docx', 'doc'];

      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExt,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileExtension = file.extension?.toLowerCase();

      // Final double-check validation on extension
      if (widget.fileType == 'pdf') {
        if (fileExtension != 'pdf') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Only PDF files are allowed.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      } else {
        if (fileExtension != 'docx' && fileExtension != 'doc') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Only DOC files (.doc, .docx) are allowed.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }

      // Auto-extract title from file name without extension
      String originalName = file.name;
      int lastDotIndex = originalName.lastIndexOf('.');
      String defaultTitle = lastDotIndex != -1 
          ? originalName.substring(0, lastDotIndex) 
          : originalName;
      
      // Clean up symbols to make a clean default title
      defaultTitle = defaultTitle.replaceAll('_', ' ').replaceAll('-', ' ').trim();

      if (!mounted) return;

      final titleController = TextEditingController(text: defaultTitle);
      final formKey = GlobalKey<FormState>();
      String selectedVisibility = 'everyone';
      final selectedUserIds = <String>{};

      // Show confirmation dialog with editable title and visibility controls before publishing
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Publish Story', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F3D56))),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected File: ${file.name}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Story Title',
                            hintText: 'e.g. Pinocchio',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a story title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Who can view this story?',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F3D56), fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedVisibility,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'everyone', child: Text('Everyone (Public)')),
                            DropdownMenuItem(value: 'parents', child: Text('Logged-in Parents Only')),
                            DropdownMenuItem(value: 'specific', child: Text('Specific Parents...')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedVisibility = val;
                              });
                            }
                          },
                        ),
                        if (selectedVisibility == 'specific') ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Select allowed parents:',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FutureBuilder<QuerySnapshot>(
                              future: _firestore.collection('users').get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(child: Text('Error loading parents', style: TextStyle(color: Colors.red[300], fontSize: 12)));
                                }
                                final docs = snapshot.data?.docs ?? [];
                                final otherUsers = docs.where((doc) => doc.id != FirebaseAuth.instance.currentUser?.uid).toList();

                                if (otherUsers.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'No other registered parents found.',
                                        style: TextStyle(color: Colors.grey, fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: otherUsers.length,
                                  itemBuilder: (context, index) {
                                    final uDoc = otherUsers[index];
                                    final uData = uDoc.data() as Map<String, dynamic>;
                                    final uId = uDoc.id;
                                    final uName = uData['displayName'] ?? 'Unnamed Parent';
                                    final uEmail = uData['email'] ?? '';
                                    final uPhone = uData['phoneNumber'] ?? '';

                                    final isChecked = selectedUserIds.contains(uId);

                                    return CheckboxListTile(
                                      title: Text(uName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                      subtitle: uPhone.isNotEmpty 
                                          ? Text(uPhone, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
                                          : (uEmail.isNotEmpty ? Text(uEmail, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null),
                                      value: isChecked,
                                      dense: true,
                                      onChanged: (checked) {
                                        setState(() {
                                          if (checked == true) {
                                            selectedUserIds.add(uId);
                                          } else {
                                            selectedUserIds.remove(uId);
                                          }
                                        });
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      if (selectedVisibility == 'specific' && selectedUserIds.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select at least one parent, or choose another visibility option.'),
                            backgroundColor: Colors.orangeAccent,
                          ),
                        );
                        return;
                      }
                      final finalTitle = titleController.text.trim();
                      Navigator.pop(context);
                      _checkDuplicateAndUpload(
                        file: file,
                        storyName: finalTitle,
                        visibility: selectedVisibility,
                        allowedUsers: selectedUserIds.toList(),
                      );
                    }
                  },
                  child: const Text('PUBLISH', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ),
      );

    } catch (e) {
      debugPrint('Error selecting file: $e');
    }
  }

  String _getFriendlyCategoryName(String key) {
    switch (key) {
      case 'ages_0_4_word':
        return 'Ages 0-4 DOC';
      case 'ages_0_4_pdf':
        return 'Ages 0-4 PDF';
      case 'ages_4_8_word':
        return 'Ages 4-8 DOC';
      case 'ages_4_8_pdf':
        return 'Ages 4-8 PDF';
      case 'ages_8_12_word':
        return 'Ages 8-12 DOC';
      case 'ages_8_12_pdf':
        return 'Ages 8-12 PDF';
      default:
        return key;
    }
  }

  String _getAgeGroup(String categoryKey) {
    if (categoryKey.endsWith('_pdf')) {
      return categoryKey.substring(0, categoryKey.length - 4);
    } else if (categoryKey.endsWith('_word')) {
      return categoryKey.substring(0, categoryKey.length - 5);
    }
    return categoryKey;
  }

  String _getFileType(String categoryKey) {
    if (categoryKey.endsWith('_pdf')) return 'pdf';
    if (categoryKey.endsWith('_word')) return 'word';
    return '';
  }

  Future<void> _checkDuplicateAndUpload({
    required PlatformFile file,
    required String storyName,
    required String visibility,
    required List<String> allowedUsers,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('stories')
          .where('name', isEqualTo: storyName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final currentAge = _getAgeGroup(widget.categoryKey);
        final currentType = widget.fileType;

        // Block if story exists in same age group AND same type
        bool existsInSameAgeAndType = false;
        for (var doc in querySnapshot.docs) {
          final cat = doc['category'] as String;
          if (_getAgeGroup(cat) == currentAge && _getFileType(cat) == currentType) {
            existsInSameAgeAndType = true;
            break;
          }
        }

        if (existsInSameAgeAndType) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Story Already Exists', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text('A story with the name "$storyName" (${currentType == 'word' ? 'DOC' : 'PDF'}) already exists in this age group. Please use a different name.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          return;
        }

        // Show warning prompt if exists in a different age group
        final otherAgeCategories = <String>[];
        for (var doc in querySnapshot.docs) {
          final cat = doc['category'] as String;
          if (_getAgeGroup(cat) != currentAge) {
            otherAgeCategories.add(_getFriendlyCategoryName(cat));
          }
        }

        if (otherAgeCategories.isNotEmpty) {
          if (!mounted) return;
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Story Exists Elsewhere', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text('A story named "$storyName" already exists in: ${otherAgeCategories.toSet().join(', ')}.\n\nSince stories can fit multiple ages, you are allowed to upload a copy here. Do you want to proceed?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('PROCEED', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          if (proceed != true) return;
        }
      }

      _uploadStoryFile(
        file: file,
        storyName: storyName,
        visibility: visibility,
        allowedUsers: allowedUsers,
      );

    } catch (e) {
      debugPrint('Error checking duplicate: $e');
      _uploadStoryFile(
        file: file,
        storyName: storyName,
        visibility: visibility,
        allowedUsers: allowedUsers,
      );
    }
  }

  Future<void> _uploadStoryFile({
    required PlatformFile file,
    required String storyName,
    required String visibility,
    required List<String> allowedUsers,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadingFileName = file.name;
      });

      // Get bytes
      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && !kIsWeb && file.path != null) {
        fileBytes = await io.File(file.path!).readAsBytes();
      }

      if (fileBytes == null) {
        throw Exception('Could not read file data.');
      }

      // Configure Storage bucket
      final storage = FirebaseStorage.instanceFor(bucket: 'gs://toddlersstoriesfinalapp-et445s.firebasestorage.app');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final storagePath = 'stories/${widget.categoryKey}/${timestamp}_${file.name}';
      final ref = storage.ref().child(storagePath);

      // Start Upload
      final contentType = widget.fileType == 'pdf'
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      final uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: contentType),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      await uploadTask;

      // Get Download URL
      final downloadUrl = await ref.getDownloadURL();

      // Retrieve display name from profile
      String uploaderName = 'Parent';
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          uploaderName = doc.data()!['displayName'] ?? user.displayName ?? 'Parent';
        } else {
          uploaderName = user.displayName ?? 'Parent';
        }
      } catch (_) {}

      // Save Metadata to Firestore
      await _firestore.collection('stories').add({
        'name': storyName,
        'fileName': file.name,
        'url': downloadUrl,
        'storagePath': storagePath,
        'category': widget.categoryKey,
        'uploadedBy': uploaderName,
        'uploadedAt': FieldValue.serverTimestamp(),
        'authorId': user.uid,
        'visibility': visibility,
        'allowedUsers': allowedUsers,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Story "$storyName" uploaded successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading story: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadingFileName = null;
        });
      }
    }
  }

  Future<void> _openStory(String url, String storyName) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Downloading story...'),
              ],
            ),
            duration: const Duration(days: 1), // Keep open until manually dismissed
          ),
        );
      }

      final Uri uri = Uri.parse(url);
      
      // Determine file extension from URL
      String extension = 'pdf'; // Default fallback
      if (url.toLowerCase().contains('.docx')) {
        extension = 'docx';
      } else if (url.toLowerCase().contains('.doc')) {
        extension = 'doc';
      } else if (url.toLowerCase().contains('.pdf')) {
        extension = 'pdf';
      }

      // Download file to temporary directory
      final io.Directory tempDir = await getTemporaryDirectory();
      
      // Sanitize the story name for a valid file name
      final String safeName = storyName.replaceAll(RegExp(r'[^\w\s\-]'), '');
      final String filePath = '${tempDir.path}/${safeName}_downloaded.$extension';
      final io.File file = io.File(filePath);

      // Download the file from url using HttpClient
      final io.HttpClient client = io.HttpClient();
      final io.HttpClientRequest request = await client.getUrl(uri);
      final io.HttpClientResponse response = await request.close();
      
      if (response.statusCode == 200) {
        final List<int> bytes = await response.fold<List<int>>([], (previous, element) => previous..addAll(element));
        await file.writeAsBytes(bytes);
      } else {
        throw 'Failed to download file (status code: ${response.statusCode})';
      }

      // Dismiss the "Downloading..." snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      // Function to trigger opening the file
      Future<void> triggerOpen() async {
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          throw result.message;
        }
      }

      // Automatically try to open it first
      await triggerOpen();

      // Also show a Snackbar saying it was downloaded successfully with an "OPEN" button
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Download complete!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () {
                triggerOpen().catchError((e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open document: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                });
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open document: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteStory(String docId, String storagePath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Story?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this story? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 1. Delete from Firebase Storage
      final storage = FirebaseStorage.instanceFor(bucket: 'gs://toddlersstoriesfinalapp-et445s.firebasestorage.app');
      await storage.ref().child(storagePath).delete();

      // 2. Delete from Firestore
      await _firestore.collection('stories').doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story deleted.')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting story: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _editStorySettings(String docId, String currentName, String currentVisibility, List<String> currentAllowedUsers) async {
    final titleController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    String selectedVisibility = currentVisibility;
    final selectedUserIds = Set<String>.from(currentAllowedUsers);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Edit Story Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F3D56))),
            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Story Title',
                          hintText: 'e.g. Pinocchio',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a story title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Who can view this story?',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3F3D56), fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedVisibility,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'everyone', child: Text('Everyone (Public)')),
                          DropdownMenuItem(value: 'parents', child: Text('Logged-in Parents Only')),
                          DropdownMenuItem(value: 'specific', child: Text('Specific Parents...')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedVisibility = val;
                            });
                          }
                        },
                      ),
                      if (selectedVisibility == 'specific') ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Select allowed parents:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FutureBuilder<QuerySnapshot>(
                            future: _firestore.collection('users').get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(child: Text('Error loading parents', style: TextStyle(color: Colors.red[300], fontSize: 12)));
                              }
                              final docs = snapshot.data?.docs ?? [];
                              final otherUsers = docs.where((doc) => doc.id != FirebaseAuth.instance.currentUser?.uid).toList();

                              if (otherUsers.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'No other registered parents found.',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                itemCount: otherUsers.length,
                                itemBuilder: (context, index) {
                                  final uDoc = otherUsers[index];
                                  final uData = uDoc.data() as Map<String, dynamic>;
                                  final uId = uDoc.id;
                                  final uName = uData['displayName'] ?? 'Unnamed Parent';
                                  final uEmail = uData['email'] ?? '';
                                  final uPhone = uData['phoneNumber'] ?? '';

                                  final isChecked = selectedUserIds.contains(uId);

                                  return CheckboxListTile(
                                    title: Text(uName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                    subtitle: uPhone.isNotEmpty 
                                        ? Text(uPhone, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
                                        : (uEmail.isNotEmpty ? Text(uEmail, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null),
                                    value: isChecked,
                                    dense: true,
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          selectedUserIds.add(uId);
                                        } else {
                                          selectedUserIds.remove(uId);
                                        }
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (selectedVisibility == 'specific' && selectedUserIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least one parent, or choose another visibility option.'),
                          backgroundColor: Colors.orangeAccent,
                        ),
                      );
                      return;
                    }
                    final finalTitle = titleController.text.trim();
                    Navigator.pop(context);
                    
                    try {
                      await _firestore.collection('stories').doc(docId).update({
                        'name': finalTitle,
                        'visibility': selectedVisibility,
                        'allowedUsers': selectedUserIds.toList(),
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Story settings updated successfully! 🎉'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Update failed: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.fileType == 'pdf' ? const Color(0xFFE91E63) : const Color(0xFF2196F3);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(
          widget.categoryTitle.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFB74D), // Soft warm pastel orange
                Color(0xFFE1BEE7), // Soft pastel purple
                Color(0xFF81C784), // Soft pastel green
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_isUploading)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Uploading Story...',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _uploadingFileName ?? 'file',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: () {
                final user = FirebaseAuth.instance.currentUser;
                Query query = _firestore.collection('stories').where('category', isEqualTo: widget.categoryKey);
                if (user == null) {
                  // For unauthenticated guests, only show public stories
                  return query.where('visibility', isEqualTo: 'everyone').snapshots();
                } else {
                  // For logged-in users, show public, parent-only, or stories they are allowed to see
                  return query.where(
                    Filter.or(
                      Filter('visibility', isEqualTo: 'everyone'),
                      Filter('visibility', isEqualTo: 'parents'),
                      Filter('authorId', isEqualTo: user.uid),
                      Filter('allowedUsers', arrayContains: user.uid),
                    ),
                  ).snapshots();
                }
              }(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 60),
                          const SizedBox(height: 16),
                          const Text(
                            'Error loading stories',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.fileType == 'pdf' ? Icons.picture_as_pdf_outlined : Icons.description_outlined,
                            size: 80,
                            color: Colors.grey[350],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No stories uploaded yet.',
                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Be the first to upload a reading adventure!',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Copy docs and sort in memory by uploadedAt descending
                final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['uploadedAt'] as Timestamp?;
                  final bTime = bData['uploadedAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return -1;
                  if (bTime == null) return 1;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final name = data['name'] ?? 'Untitled Story';
                    final url = data['url'] ?? '';
                    final storagePath = data['storagePath'] ?? '';
                    final uploadedBy = data['uploadedBy'] ?? 'Parent';
                    final timestamp = data['uploadedAt'] as Timestamp?;

                    String formattedDate = '';
                    if (timestamp != null) {
                      formattedDate = DateFormat('MMM d, yyyy').format(timestamp.toDate());
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              widget.fileType == 'pdf'
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.description_rounded,
                              color: themeColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3F3D56),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'By $uploadedBy ${formattedDate.isNotEmpty ? "• $formattedDate" : ""}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.menu_book_rounded, color: themeColor),
                                tooltip: 'Read',
                                onPressed: () => _openStory(url, name),
                              ),
                              if (FirebaseAuth.instance.currentUser != null &&
                                  (data['authorId'] == null ||
                                   data['authorId'] == FirebaseAuth.instance.currentUser?.uid)) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.orangeAccent),
                                  tooltip: 'Edit Settings',
                                  onPressed: () => _editStorySettings(
                                    docId,
                                    name,
                                    data['visibility'] ?? 'everyone',
                                    List<String>.from(data['allowedUsers'] ?? []),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                  tooltip: 'Delete',
                                  onPressed: () => _deleteStory(docId, storagePath),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startUploadFlow,
        backgroundColor: themeColor,
        icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
        label: const Text(
          'UPLOAD STORY',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
