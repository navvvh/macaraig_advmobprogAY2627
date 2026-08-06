import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/product.dart';
import '../widgets/custom_text.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _showFullDescription = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero image with a back button floating on top, matching the
          // mock's illustration + circular back button layout.
          SliverAppBar(
            pinned: false,
            expandedHeight: 320.h,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            leading: Padding(
              padding: EdgeInsets.only(left: 12.w, top: 4.h),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_${product.id}',
                child: Image.network(
                  product.thumbnail,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image,
                    size: 80.sp,
                  ),
                ),
              ),
            ),
          ),

        
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: product.title,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 6.h),
                  CustomText(
                    text: product.brand,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: 14.h),

                  Row(
                    children: [
                      CustomText(
                        text: '\$${product.price.toStringAsFixed(2)}',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      SizedBox(width: 10.w),
                      Icon(Icons.star, color: Colors.amber, size: 18.sp),
                      SizedBox(width: 2.w),
                      CustomText(
                        text: product.rating.toStringAsFixed(1),
                        fontSize: 13.sp,
                      ),
                      SizedBox(width: 10.w),
                      CustomText(
                        text: product.stock > 0
                            ? '${product.stock} in stock'
                            : 'Out of stock',
                        fontSize: 12.sp,
                      ),
                    ],
                  ),

                  SizedBox(height: 18.h),
                  CustomText(
                    text: 'Description',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 6.h),

                
                  CustomText(
                    text: product.description,
                    fontSize: 13.sp,
                    maxLines: _showFullDescription ? null : 3,
                    overflow: _showFullDescription
                        ? null
                        : TextOverflow.ellipsis,
                  ),
                  if (product.description.length > 90)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showFullDescription = !_showFullDescription;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: CustomText(
                          text: _showFullDescription ? 'Show less' : 'Read All',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  SizedBox(height: 18.h),
                  CustomText(
                    text: 'Category',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(text: product.category, fontSize: 13.sp),

                  SizedBox(height: 18.h),
                  CustomText(
                    text: 'Reviews (${product.reviews.length})',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 8.h),
                  ...product.reviews.map(
                    (review) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomText(
                                text: review.reviewerName,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              SizedBox(width: 6.w),
                              Icon(Icons.star,
                                  color: Colors.amber, size: 14.sp),
                              CustomText(
                                text: '${review.rating}',
                                fontSize: 12.sp,
                              ),
                            ],
                          ),
                          CustomText(
                            text: review.comment,
                            fontSize: 12.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}