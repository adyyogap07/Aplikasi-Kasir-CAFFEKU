import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart'; // <-- PERBAIKAN: Impor ditambahkan

import '../domain/product_model.dart';
import '../domain/category_model.dart';
import 'product_controller.dart';
import 'category_controller.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormPage({super.key, this.product});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  bool _isLoading = false;
  File? _imageFile;
  final _picker = ImagePicker();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _selectedCategoryId = widget.product!.categoryId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final data = {
        'name': _nameController.text,
        'slug': _nameController.text.toLowerCase().replaceAll(' ', '-'),
        'category_id': _selectedCategoryId ?? 0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'price': int.tryParse(_priceController.text) ?? 0,
        'is_active': true,
        'barcode': '',
        'description': '',
      };

      try {
        final notifier = ref.read(productControllerProvider.notifier);
        if (widget.product == null) {
          await notifier.createProduct(data, image: _imageFile);
          _showSuccessSnackBar('Produk berhasil ditambahkan!');
        } else {
          await notifier.updateProduct(widget.product!.id, data, image: _imageFile);
          _showSuccessSnackBar('Produk berhasil diperbarui!');
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) _showErrorSnackBar('Error: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
  
  void _showSuccessSnackBar(String message) {
     if (!mounted) return;
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
     );
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoryControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 24),
            _buildSectionTitle('Informasi Utama'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Nama Produk',
              icon: Icons.inventory_2_outlined,
              validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Harga',
                    icon: Icons.price_change_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => value == null || value.isEmpty ? 'Harga harus diisi' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _stockController,
                    label: 'Stok',
                    icon: Icons.production_quantity_limits,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                     validator: (value) => value == null || value.isEmpty ? 'Stok harus diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
             _buildSectionTitle('Kategorisasi'),
            const SizedBox(height: 16),
            categoriesState.when(
              data: (categories) => _buildCategoryDropdown(categories),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Gagal memuat kategori: $e', style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: DottedBorder(
          color: Colors.grey.shade400,
          strokeWidth: 2,
          dashPattern: const [8, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                : (widget.product?.fullImageUrl != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(widget.product!.fullImageUrl!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey.shade500),
                          const SizedBox(height: 8),
                          const Text('Unggah Gambar Produk', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
  
  Widget _buildCategoryDropdown(List<Category> categories) {
    return DropdownButtonFormField<int?>(
      value: _selectedCategoryId,
      decoration: InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(Icons.category_outlined, color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      hint: const Text('Pilih Kategori'),
      items: categories.map((category) => DropdownMenuItem<int?>(
        value: category.id,
        child: Text(category.name),
      )).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
       validator: (value) => value == null ? 'Kategori harus dipilih' : null,
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save),
          label: _isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Text(widget.product == null ? 'Simpan Produk' : 'Perbarui Produk', style: const TextStyle(fontSize: 16)),
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
