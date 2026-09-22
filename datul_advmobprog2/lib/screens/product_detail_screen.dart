import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/product.dart';
import '../widgets/custom_text.dart';

// Enhancement 2: Add details page when clicked the card.
class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: product.title,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhancement 2: Product Image Card
              Center(
                child: Container(
                  width: double.infinity,
                  height: 260.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Image.network(
                      product.thumbnail,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.broken_image, size: 60.sp, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Category & Brand Badges
              Row(
                children: [
                  if (product.brand.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      margin: EdgeInsets.only(right: 8.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: CustomText(
                        text: product.brand,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: CustomText(
                      text: product.category.toUpperCase(),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Rating
                  Icon(Icons.star, color: Colors.amber, size: 18.sp),
                  SizedBox(width: 4.w),
                  CustomText(
                    text: product.rating.toStringAsFixed(1),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Title
              CustomText(
                text: product.title,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 8.h),

              // Price & Discount
              Row(
                children: [
                  CustomText(
                    text: '\$${product.price.toStringAsFixed(2)}',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                  if (product.discountPercentage > 0) ...[
                    SizedBox(width: 10.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: CustomText(
                        text: '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const Spacer(),
                  CustomText(
                    text: product.availabilityStatus.isNotEmpty
                        ? product.availabilityStatus
                        : 'In Stock (${product.stock})',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              const Divider(),
              SizedBox(height: 12.h),

              // Description
              CustomText(
                text: 'Description',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 6.h),
              CustomText(
                text: product.description,
                fontSize: 14.sp,
                fontFamily: 'Poppins',
              ),
              SizedBox(height: 16.h),

              // Additional Details (Warranty, Shipping, Return Policy)
              if (product.warrantyInformation.isNotEmpty ||
                  product.shippingInformation.isNotEmpty ||
                  product.returnPolicy.isNotEmpty) ...[
                const Divider(),
                SizedBox(height: 12.h),
                CustomText(
                  text: 'Product Information',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 8.h),
                if (product.warrantyInformation.isNotEmpty)
                  _buildInfoRow('Warranty:', product.warrantyInformation),
                if (product.shippingInformation.isNotEmpty)
                  _buildInfoRow('Shipping:', product.shippingInformation),
                if (product.returnPolicy.isNotEmpty)
                  _buildInfoRow('Return Policy:', product.returnPolicy),
                SizedBox(height: 16.h),
              ],

              // Reviews Section
              if (product.reviews.isNotEmpty) ...[
                const Divider(),
                SizedBox(height: 12.h),
                CustomText(
                  text: 'Customer Reviews (${product.reviews.length})',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 10.h),
                ...product.reviews.map(
                  (review) => Card(
                    margin: EdgeInsets.only(bottom: 8.h),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(10.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomText(
                                text: review.reviewerName,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              const Spacer(),
                              Row(
                                children: List.generate(
                                  review.rating,
                                  (index) => Icon(Icons.star,
                                      size: 14.sp, color: Colors.amber),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          CustomText(
                            text: review.comment,
                            fontSize: 12.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: CustomText(
              text: label,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: CustomText(
              text: value,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}
