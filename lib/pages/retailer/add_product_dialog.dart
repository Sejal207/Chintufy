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
  const AddProductDialog({Key? key}) : super(key: key);

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();
  final FocusNode _stockFocus = FocusNode();
  final FocusNode _categoryFocus = FocusNode();
  
  File? _imageFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  bool _hasChanges = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final ImagePicker _picker = ImagePicker();
  final List<String> _categoryOptions = ['Food', 'Drinks', 'Snacks', 'Stationery', 'Other'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    
    // Start the animation
    _animationController.forward();
    
    // Add focus listeners to provide subtle visual feedback
    _nameFocus.addListener(_onFocusChange);
    _descFocus.addListener(_onFocusChange);
    _priceFocus.addListener(_onFocusChange);
    _stockFocus.addListener(_onFocusChange);
    _categoryFocus.addListener(_onFocusChange);
    
    // Add listeners to track changes
    _nameController.addListener(_onFieldChange);
    _descController.addListener(_onFieldChange);
    _priceController.addListener(_onFieldChange);
    _stockController.addListener(_onFieldChange);
    _categoryController.addListener(_onFieldChange);
  }

  void _onFocusChange() {
    setState(() {
      // This will trigger a rebuild when focus changes
    });
  }
  
  void _onFieldChange() {
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    _priceFocus.dispose();
    _stockFocus.dispose();
    _categoryFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      // Get the storage service from Provider
      final storageService = Provider.of<FirebaseStorageService>(context, listen: false);

      // Simplify by passing minimal required parameters
      final imageUrl = await storageService.uploadImage(
        imageFile: _imageFile!,
        folderName: 'products',
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
            _showErrorSnackBar('Upload error: $errorMsg');
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
        
        _showErrorSnackBar('Device error: ${e.message}');
      }
      return null;
    } catch (e) {
      print('Error in _uploadImage: $e');
      if (mounted) {
        setState(() {
          _uploadStatus = 'Upload failed';
          _isUploading = false;
        });
        
        _showErrorSnackBar('Failed to upload image. Please try again.');
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // Confirm exit if there are unsaved changes
  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DISCARD'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header - Fixed position
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline, color: Colors.black87, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Add New Product',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black54),
                            onPressed: () => _onWillPop().then((canExit) {
                              if (canExit) Navigator.pop(context);
                            }),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    
                    // Form - Scrollable content
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image preview and selection
                              _buildImageSelector(),
                              
                              const SizedBox(height: 24),
                              
                              // Form fields
                              _buildTextField(
                                controller: _nameController,
                                focusNode: _nameFocus,
                                label: 'Product Name',
                                hint: 'Enter product name',
                                prefixIcon: Icons.shopping_bag_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a product name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              _buildTextField(
                                controller: _descController,
                                focusNode: _descFocus,
                                label: 'Description',
                                hint: 'Enter product description',
                                prefixIcon: Icons.description_outlined,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              
                              // Price and Stock in a row
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  // Use column for narrow screens
                                  if (constraints.maxWidth < 400) {
                                    return Column(
                                      children: [
                                        _buildTextField(
                                          controller: _priceController,
                                          focusNode: _priceFocus,
                                          label: 'Price',
                                          hint: '0.00',
                                          prefixIcon: Icons.attach_money,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Required';
                                            }
                                            if (double.tryParse(value) == null) {
                                              return 'Invalid price';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        _buildTextField(
                                          controller: _stockController,
                                          focusNode: _stockFocus,
                                          label: 'Stock',
                                          hint: '0',
                                          prefixIcon: Icons.inventory_2_outlined,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Required';
                                            }
                                            if (int.tryParse(value) == null) {
                                              return 'Invalid number';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    );
                                  }
                                  
                                  // Use row for wider screens
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _priceController,
                                          focusNode: _priceFocus,
                                          label: 'Price',
                                          hint: '0.00',
                                          prefixIcon: Icons.attach_money,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Required';
                                            }
                                            if (double.tryParse(value) == null) {
                                              return 'Invalid price';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _stockController,
                                          focusNode: _stockFocus,
                                          label: 'Stock',
                                          hint: '0',
                                          prefixIcon: Icons.inventory_2_outlined,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Required';
                                            }
                                            if (int.tryParse(value) == null) {
                                              return 'Invalid number';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Category dropdown
                              _buildCategoryDropdown(),
                              
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Action buttons - Fixed position at bottom
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isUploading 
                                  ? null 
                                  : () => _onWillPop().then((canExit) {
                                      if (canExit) Navigator.pop(context);
                                    }),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _isUploading 
                                  ? null 
                                  : () => _saveProduct(databaseService),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: _isUploading
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Processing...'),
                                      ],
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.save_outlined, size: 18),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Save Product',
                                          style: TextStyle(
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showImageSourceDialog(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 200,
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _imageFile == null ? Colors.grey[300]! : Colors.black,
                  width: 1.5,
                ),
                boxShadow: _imageFile != null ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: _imageFile == null
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 48,
                            color: Color(0xFF757575), // grey[600]
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tap to add product image',
                            style: TextStyle(
                              color: Color(0xFF757575), // grey[600]
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Recommended: 1000x1000 px',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E), // grey[500]
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.passthrough,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.7),
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                              onPressed: () => _showImageSourceDialog(context),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (_isUploading) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 4),
          Text(
            _uploadStatus,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final bool hasFocus = focusNode.hasFocus;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasFocus ? Colors.black : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: hasFocus ? Colors.black87 : Colors.grey[400],
              ),
              border: InputBorder.none,
              errorStyle: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
              // Ensure error text doesn't cause overflow
              errorMaxLines: 2,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final bool hasFocus = _categoryFocus.hasFocus;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasFocus ? Colors.black : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: DropdownButtonFormField<String>(
            value: _categoryController.text.isNotEmpty ? _categoryController.text : null,
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            isExpanded: true, // Prevent dropdown overflow
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(
                Icons.category_outlined,
                color: hasFocus ? Colors.black87 : Colors.grey[400],
              ),
              border: InputBorder.none,
              errorStyle: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
            hint: Text(
              'Select category',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _categoryController.text = newValue;
                  _hasChanges = true;
                });
              }
            },
            items: _categoryOptions.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            focusNode: _categoryFocus,
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Select Image Source',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.camera_alt, color: Colors.black87),
              ),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.photo_library, color: Colors.black87),
              ),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from your photos'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imageFile != null) ...[
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red[50],
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: const Text('Remove Image'),
                subtitle: const Text('Clear the current image'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                    _hasChanges = true;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      contentPadding: const EdgeInsets.all(24),
    ),
  );
}
  Future<void> _saveProduct(DatabaseService databaseService) async {
    if (!_formKey.currentState!.validate()) {
      // Show error message
      _showErrorSnackBar('Please fix the errors in the form');
      return;
    }

    // Start loading state
    setState(() {
      _isUploading = true;
    });

    try {
      // Upload image if available
      final String? imageUrl = await _uploadImage();
      
      // Create product object
      final newProduct = Product(
        id: '', // Will be generated by Firestore
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        imageUrl: imageUrl ?? 'https://via.placeholder.com/400',
        category: _categoryController.text, // Add this line
      );

      // Add to database
      await databaseService.addProduct(newProduct);
      
      // Show success message
      _showSuccessSnackBar('Product added successfully!');
      
      // Close dialog
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      print('Error saving product: $e');
      _showErrorSnackBar('Failed to save product: ${e.toString()}');
    } finally {
      // End loading state
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}