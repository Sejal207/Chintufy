import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/firebase_storage_service.dart';
import '../../models/product.dart';

class AddProductDialog extends StatefulWidget {
  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  File? _imageFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    // Get the storage service from Provider
    final storageService = Provider.of<FirebaseStorageService>(context, listen: false);

    try {
      // Simplify by passing minimal required parameters
      final imageUrl = await storageService.uploadImage(
        imageFile: _imageFile!,
        folderName: 'products', // This will be ignored in our updated service
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
              _uploadStatus = '${(progress * 100).toStringAsFixed(1)}% uploaded';
            });
          }
        },
        onError: (errorMsg) {
          if (mounted) {
            setState(() {
              _uploadStatus = 'Error: $errorMsg';
              _isUploading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload error: $errorMsg')),
            );
          }
        },
      );
      
      if (imageUrl != null) {
        if (mounted) {
          setState(() {
            _uploadStatus = 'Upload complete!';
          });
        }
        return imageUrl;
      } else {
        throw Exception('Failed to get image URL');
      }
    } on PlatformException catch (e) {
      print('Platform Exception during upload: $e');
      if (mounted) {
        setState(() {
          _uploadStatus = 'Platform error: ${e.message}';
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device error: ${e.message}')),
        );
      }
      return null;
    } catch (e) {
      print('Error in _uploadImage: $e');
      if (mounted) {
        setState(() {
          _uploadStatus = 'Upload failed';
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image. Please try again.')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return AlertDialog(
      title: Text('Add New Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image preview and selection
              GestureDetector(
                onTap: () => _showImageSourceDialog(context),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                      Text('Tap to add image'),
                    ],
                  )
                      : Image.file(_imageFile!, fit: BoxFit.cover),
                ),
              ),
              if (_isUploading) ...[
                SizedBox(height: 8),
                LinearProgressIndicator(value: _uploadProgress),
                SizedBox(height: 4),
                Text(_uploadStatus, style: TextStyle(fontSize: 12)),
              ],
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _stockController,
                decoration: InputDecoration(labelText: 'Initial Stock'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : () async {
            if (_formKey.currentState!.validate()) {
              final imageUrl = await _uploadImage();

              final newProduct = Product(
                id: '', // Will be generated by Firestore
                name: _nameController.text,
                description: _descController.text,
                price: double.parse(_priceController.text),
                stock: int.parse(_stockController.text),
                imageUrl: imageUrl ?? 'https://via.placeholder.com/150',
              );

              await databaseService.addProduct(newProduct);
              Navigator.pop(context);
            }
          },
          child: _isUploading
              ? CircularProgressIndicator()
              : Text('Add Product'),
        ),
      ],
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: Text('Gallery'),
          ),
        ],
      ),
    );
  }
}