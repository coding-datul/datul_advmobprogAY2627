import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';

class DetailScreen extends StatefulWidget {
  final int productId;
  final String? initialTitle;
  final double? initialPrice;
  final String? initialThumbnail;
  final double? initialDiscountPercentage;

  const DetailScreen({
    super.key,
    required this.productId,
    this.initialTitle,
    this.initialPrice,
    this.initialThumbnail,
    this.initialDiscountPercentage,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();

  Future<Product>? _productFuture;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _productFuture = _productService.getProductById(widget.productId);
  }

  // Enhancement 3: Add product to user cart via DummyJSON API
  Future<void> _handleAddToCart() async {
    setState(() => _isAddingToCart = true);
    try {
      await _cartService.addToCart(
        userId: 1,
        products: [
          {'id': widget.productId, 'quantity': 1}
        ],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.initialTitle ?? "Item"} added to cart successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
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
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: widget.initialTitle ?? 'Product Detail',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && snapshot.data == null) {
            // Fallback UI using initial values if offline or error
            return _buildContent(
              title: widget.initialTitle ?? 'Product',
              thumbnail: widget.initialThumbnail ?? '',
              price: widget.initialPrice ?? 0.0,
              discountPercentage: widget.initialDiscountPercentage ?? 0.0,
              description: 'No detailed description available.',
              brand: 'Brand',
              category: 'General',
              rating: 4.5,
              stock: 10,
              isDark: isDark,
            );
          }

          final product = snapshot.data!;
          return _buildContent(
            title: product.title,
            thumbnail: product.thumbnail,
            price: product.price,
            discountPercentage: product.discountPercentage,
            description: product.description,
            brand: product.brand,
            category: product.category,
            rating: product.rating,
            stock: product.stock,
            isDark: isDark,
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: _isAddingToCart ? null : _handleAddToCart,
              icon: _isAddingToCart
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.shopping_cart_outlined),
              label: CustomText(
                text: _isAddingToCart ? 'Adding...' : 'Add to Cart',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required String title,
    required String thumbnail,
    required double price,
    required double discountPercentage,
    required String description,
    required String brand,
    required String category,
    required double rating,
    required int stock,
    required bool isDark,
  }) {
    final discountedPrice = price * (1 - discountPercentage / 100);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Container
          Center(
            child: Container(
              height: 240.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: thumbnail.isNotEmpty
                    ? Image.network(
                        thumbnail,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image, size: 48)),
                      )
                    : const Center(child: Icon(Icons.image, size: 48)),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Category & Brand Tag
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: CustomText(
                  text: category.toUpperCase(),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 8.w),
              CustomText(
                text: brand,
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  SizedBox(width: 4.w),
                  CustomText(
                    text: rating.toStringAsFixed(1),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Title
          CustomText(
            text: title,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 12.h),

          // Pricing Card
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: '\$${discountedPrice.toStringAsFixed(2)}',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    if (discountPercentage > 0)
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textMuted,
                          fontSize: 13.sp,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                if (discountPercentage > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: CustomText(
                      text: '${discountPercentage.toStringAsFixed(0)}% OFF',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Stock Info
          Row(
            children: [
              Icon(
                stock > 0 ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: stock > 0 ? Colors.green : Colors.red,
                size: 18,
              ),
              SizedBox(width: 6.w),
              CustomText(
                text: stock > 0 ? '$stock units in stock' : 'Out of stock',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: stock > 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Description Section
          const CustomText(
            text: 'Description',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 6.h),
          CustomText(
            text: description,
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ],
      ),
    );
  }
}
