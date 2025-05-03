import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  // Get a direct reference to the root of the storage bucket
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Upload an image file to Firebase Storage
  Future<String?> uploadImage({
    required File imageFile,
    required String folderName, // e.g., 'product_images'
    Function(double)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      // Generate a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final extension = path.extension(imageFile.path).toLowerCase();
      final fileName = '${timestamp}${extension}';
      
      // Use a simpler path structure and reference the root directly
      final ref = _storage.ref().child(fileName);
      
      // Check if file exists and has content
      if (!imageFile.existsSync() || imageFile.lengthSync() == 0) {
        if (onError != null) {
          onError('File is empty or does not exist');
        }
        return null;
      }
      
      // Set minimal metadata
      final metadata = SettableMetadata(
        contentType: extension == '.png' ? 'image/png' : 'image/jpeg',
      );
      
      // Create and start upload task with simpler approach
      final uploadTask = ref.putFile(imageFile, metadata);
      
      // Monitor upload progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen(
          (TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          },
          onError: (e) {
            print('Upload error: $e');
            if (onError != null) {
              onError('Upload failed: ${e.toString()}');
            }
          },
          cancelOnError: false,
        );
      }
      
      // Wait for the upload to complete
      final snapshot = await uploadTask;
      
      // Only get URL if upload succeeded
      if (snapshot.state == TaskState.success) {
        try {
          final downloadUrl = await ref.getDownloadURL();
          return downloadUrl;
        } catch (e) {
          print('Error getting download URL: $e');
          if (onError != null) {
            onError('Failed to get download URL: $e');
          }
          return null;
        }
      } else {
        throw Exception('Upload did not complete successfully');
      }
    } on FirebaseException catch (e) {
      print('Firebase Storage error: ${e.code} - ${e.message}');
      if (onError != null) {
        onError('Firebase error: ${e.message}');
      }
      return null;
    } on PlatformException catch (e) {
      print('Platform error: ${e.code} - ${e.message}');
      if (onError != null) {
        onError('Platform error: ${e.message}');
      }
      return null;
    } catch (e) {
      print('Error in uploadImage: $e');
      if (onError != null) {
        onError(e.toString());
      }
      return null;
    }
  }
  
  // Delete an image from Firebase Storage by URL
  Future<bool> deleteImageByUrl(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
} 