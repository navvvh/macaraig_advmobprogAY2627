import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _showFullDescription = false;
  bool _isAddingToCart = false;

  Future<void> _addToCart() async {
    if (_isAddingToCart || widget.product.stock <= 0) return;
    setState(() => _isAddingToCart = true);

    try {
      final user = await UserService().getUser();
      if (user.id <= 0) throw Exception('No signed-in user found');
      await CartService().addToCart(
        userId: user.id,
        products: [
          {'id': widget.product.id, 'quantity': 1},
        ],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.product.title} added to cart')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add product to cart: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final theme = Theme.of(context);
    final inStock = product.stock > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Product details'), centerTitle: true),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
        child: SizedBox(
          height: 52.h,
          child: FilledButton.icon(
            onPressed: inStock && !_isAddingToCart ? _addToCart : null,
            icon: _isAddingToCart
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.shopping_cart_outlined, size: 21.sp),
            label: Text(inStock ? 'Add to cart' : 'Out of stock'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3840A2),
              disabledBackgroundColor: theme.disabledColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: AspectRatio(
                // The fixed frame prevents portrait/landscape images stretching.
                aspectRatio: 1.15,
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Hero(
                    tag: 'product_${product.id}',
                    child: Image.network(
                      product.thumbnail,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.image_outlined, size: 72.sp),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _InfoChip(label: product.category),
                _InfoChip(
                  label: inStock
                      ? '${product.stock} available'
                      : 'Out of stock',
                  color: inStock ? Colors.green : theme.colorScheme.error,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            CustomText(
              text: product.title,
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
            ),
            if (product.brand.isNotEmpty) ...[
              SizedBox(height: 3.h),
              CustomText(
                text: product.brand,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                CustomText(
                  text: '\$${product.price.toStringAsFixed(2)}',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                ),
                const Spacer(),
                Icon(Icons.star_rounded, color: Colors.amber, size: 21.sp),
                SizedBox(width: 4.w),
                CustomText(
                  text: product.rating.toStringAsFixed(1),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
            SizedBox(height: 24.h),
            const _SectionTitle(text: 'Description'),
            SizedBox(height: 7.h),
            CustomText(
              text: product.description,
              fontSize: 14.sp,
              maxLines: _showFullDescription ? null : 3,
              overflow: _showFullDescription ? null : TextOverflow.ellipsis,
            ),
            if (product.description.length > 90)
              TextButton(
                onPressed: () => setState(
                  () => _showFullDescription = !_showFullDescription,
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(_showFullDescription ? 'Show less' : 'Read more'),
              ),
            SizedBox(height: 14.h),
            const _SectionTitle(text: 'Product information'),
            SizedBox(height: 8.h),
            _DetailsCard(product: product),
            if (product.reviews.isNotEmpty) ...[
              SizedBox(height: 22.h),
              _SectionTitle(text: 'Reviews (${product.reviews.length})'),
              SizedBox(height: 8.h),
              ...product.reviews.map((review) => _ReviewCard(review: review)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label),
    labelStyle: TextStyle(fontSize: 12.sp, color: color),
    visualDensity: VisualDensity.compact,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) =>
      CustomText(text: text, fontSize: 16.sp, fontWeight: FontWeight.w700);
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: EdgeInsets.all(14.w),
      child: Column(
        children: [
          _DetailRow(label: 'SKU', value: product.sku),
          _DetailRow(label: 'Warranty', value: product.warrantyInformation),
          _DetailRow(label: 'Shipping', value: product.shippingInformation),
          _DetailRow(label: 'Return policy', value: product.returnPolicy),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(label, style: TextStyle(fontSize: 12.sp)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ProductReview review;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.only(bottom: 8.h),
    child: Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              Text(' ${review.rating}', style: TextStyle(fontSize: 12.sp)),
            ],
          ),
          SizedBox(height: 5.h),
          Text(review.comment, style: TextStyle(fontSize: 12.sp)),
        ],
      ),
    ),
  );
}
