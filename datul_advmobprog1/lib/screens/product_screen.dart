import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();

  static final List<Product> sampleProducts = [
    Product(
      id: 162,
      title: 'Blue Frock',
      description: 'Elegant blue frock dress crafted from breathable cotton blend fabric.',
      price: 28.00,
      discountPercentage: 12.0,
      rating: 4.8,
      stock: 15,
      brand: 'Fashion Club',
      category: 'tops',
      thumbnail: 'https://cdn.dummyjson.com/product-images/tops/blue-frock/thumbnail.webp',
      images: ['https://cdn.dummyjson.com/product-images/tops/blue-frock/thumbnail.webp'],
    ),
    Product(
      id: 113,
      title: 'Generic Motorcycle',
      description: 'High-performance standard commuter motorcycle with 150cc engine.',
      price: 2300.00,
      discountPercentage: 12.0,
      rating: 4.7,
      stock: 8,
      brand: 'Generic Moto',
      category: 'motorcycle',
      thumbnail: 'https://cdn.dummyjson.com/product-images/motorcycle/generic-motorcycle/thumbnail.webp',
      images: ['https://cdn.dummyjson.com/product-images/motorcycle/generic-motorcycle/thumbnail.webp'],
    ),
    Product(
      id: 122,
      title: 'iPhone 6',
      description: 'Apple iPhone 6 with 4.7-inch Retina HD display and 16GB storage.',
      price: 449.99,
      discountPercentage: 7.0,
      rating: 4.6,
      stock: 20,
      brand: 'Apple',
      category: 'smartphones',
      thumbnail: 'https://cdn.dummyjson.com/product-images/smartphones/iphone-6/thumbnail.webp',
      images: ['https://cdn.dummyjson.com/product-images/smartphones/iphone-6/thumbnail.webp'],
    ),
    Product(
      id: 138,
      title: 'Baseball Ball',
      description: 'Official competition leather baseball ball with raised red seams.',
      price: 5.00,
      discountPercentage: 2.0,
      rating: 4.5,
      stock: 50,
      brand: 'Rawlings',
      category: 'sports-accessories',
      thumbnail: 'https://cdn.dummyjson.com/product-images/sports-accessories/baseball-ball/thumbnail.webp',
      images: ['https://cdn.dummyjson.com/product-images/sports-accessories/baseball-ball/thumbnail.webp'],
    ),
  ];

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _allProducts = List.from(sampleProducts);
    _filteredProducts = List.from(sampleProducts);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getAllProducts();
      if (products.isNotEmpty) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        if (_allProducts.isEmpty) {
          _allProducts = List.from(sampleProducts);
          _filteredProducts = List.from(sampleProducts);
        }
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        final q = query.toLowerCase();
        _filteredProducts = _allProducts.where((p) {
          return p.title.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<void> _quickAddToCart(Product product) async {
    try {
      await _cartService.addToCart(
        userId: 1,
        products: [
          {'id': product.id, 'quantity': 1}
        ],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.title} added to cart!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
          text: 'Products',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products by name, brand, category...',
                hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.cardDark : Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 12.h),
              CustomText(text: _errorMessage!, fontSize: 14),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadProducts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 54, color: AppColors.textMuted),
            SizedBox(height: 12),
            CustomText(text: 'No products found', fontSize: 15),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14.h,
          crossAxisSpacing: 14.w,
          childAspectRatio: 0.70,
        ),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return _buildProductCard(product, isDark);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              productId: product.id,
              initialTitle: product.title,
              initialPrice: product.price,
              initialThumbnail: product.thumbnail,
              initialDiscountPercentage: product.discountPercentage,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262626) : Colors.grey.shade100,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                  child: product.thumbnail.isNotEmpty
                      ? Image.network(
                          product.thumbnail,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 32),
                        )
                      : const Icon(Icons.image, size: 32),
                ),
              ),
            ),

            // Info
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: product.title,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  CustomText(
                    text: product.brand,
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: '\$${product.price.toStringAsFixed(2)}',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      InkWell(
                        onTap: () => _quickAddToCart(product),
                        borderRadius: BorderRadius.circular(6.r),
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
