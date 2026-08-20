import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';

import 'product_details_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Enhancement 3: Use a specific user ID to render
  // only that user's cart.
  final int _userId = 5;

  late Future<List<Cart>> _cartFuture;

  List<CartProduct> _items = [];
  final Map<int, int> _quantities = {};

  bool _loadingProduct = false;
  bool _addingToCart = false;

  @override
  void initState() {
    super.initState();

    // Enhancement 3: Get the cart of one specific user.
    _cartFuture = CartService().getCartByUserId(_userId);
  }

  double get _subtotal {
    double sum = 0;

    for (final item in _items) {
      final qty = _quantities[item.id] ?? item.quantity;

      final unitDiscounted =
          item.price -
          (item.price * item.discountPercentage / 100);

      sum += unitDiscounted * qty;
    }

    return sum;
  }

  void _incrementQty(int productId) {
    setState(() {
      _quantities[productId] =
          (_quantities[productId] ?? 1) + 1;
    });
  }

  void _decrementQty(int productId) {
    setState(() {
      final current = _quantities[productId] ?? 1;

      if (current > 1) {
        _quantities[productId] = current - 1;
      }
    });
  }

  // Enhancement 1: Get the complete Product information
  // from the Product API and open the existing
  // ProductDetailsScreen.
  Future<void> _openDetails(int productId) async {
    if (_loadingProduct) return;

    setState(() {
      _loadingProduct = true;
    });

    try {
      final product =
          await ProductService().getProductById(productId);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProductDetailsScreen(product: product),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to open product: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingProduct = false;
        });
      }
    }
  }

  // Enhancement 3: Send the current product values
  // and quantities to the DummyJSON Add to Cart endpoint.
  Future<void> _addCurrentProductsToCart() async {
    if (_items.isEmpty || _addingToCart) return;

    setState(() {
      _addingToCart = true;
    });

    try {
      final products = _items.map((item) {
        return {
          'id': item.id,
          'quantity':
              _quantities[item.id] ?? item.quantity,
        };
      }).toList();

      await CartService().addToCart(
        userId: _userId,
        products: products,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Products added to cart successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add products: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _addingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Cart>>(
      future: _cartFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: CustomText(
                text: 'Error: ${snapshot.error}',
                fontSize: 14.sp,
              ),
            ),
          );
        }

        final carts = snapshot.data ?? [];

        if (carts.isEmpty) {
          return Center(
            child: CustomText(
              text: 'No cart found for User $_userId.',
              fontSize: 14.sp,
            ),
          );
        }

        _items = carts.first.products;

        for (final item in _items) {
          _quantities.putIfAbsent(
            item.id,
            () => item.quantity,
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  16.h,
                  16.w,
                  8.h,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];

                  final qty =
                      _quantities[item.id] ??
                      item.quantity;

                  final unitDiscounted =
                      item.price -
                      (item.price *
                          item.discountPercentage /
                          100);

                  final lineTotal =
                      unitDiscounted * qty;

                  return Padding(
                    padding:
                        EdgeInsets.only(bottom: 12.h),
                    child: GestureDetector(
                      // Enhancement 1:
                      // Makes each cart item clickable
                      // and opens the product detail screen.
                      onTap: () =>
                          _openDetails(item.id),
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).cardColor,
                          borderRadius:
                              BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.05),
                              blurRadius: 4,
                              offset:
                                  const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                8.r,
                              ),
                              child: Image.network(
                                item.thumbnail,
                                width: 64.w,
                                height: 64.w,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) =>
                                        Icon(
                                  Icons.image,
                                  size: 32.sp,
                                ),
                              ),
                            ),

                            SizedBox(width: 12.w),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  CustomText(
                                    text: item.title,
                                    fontSize: 14.sp,
                                    fontWeight:
                                        FontWeight.w600,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                  ),

                                  SizedBox(height: 4.h),

                                  CustomText(
                                    text:
                                        '\$${item.price.toStringAsFixed(2)}',
                                    fontSize: 13.sp,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),

                                  SizedBox(height: 2.h),

                                  CustomText(
                                    text:
                                        '${item.discountPercentage.toStringAsFixed(0)}% off · \$${lineTotal.toStringAsFixed(2)} total',
                                    fontSize: 11.sp,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 8.w),

                            Column(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      _incrementQty(
                                    item.id,
                                  ),
                                  child: Container(
                                    padding:
                                        EdgeInsets.all(
                                      5.r,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        6.r,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 16.sp,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 4.h),

                                CustomText(
                                  text: '$qty',
                                  fontSize: 13.sp,
                                  fontWeight:
                                      FontWeight.w600,
                                ),

                                SizedBox(height: 4.h),

                                GestureDetector(
                                  onTap: () =>
                                      _decrementQty(
                                    item.id,
                                  ),
                                  child: Container(
                                    padding:
                                        EdgeInsets.all(
                                      5.r,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          Colors.grey.shade300,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        6.r,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 16.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Container(
              padding: EdgeInsets.fromLTRB(
                16.w,
                8.h,
                16.w,
                16.h,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: 'Subtotal:',
                        fontSize: 14.sp,
                      ),
                      CustomText(
                        text:
                            '\$${_subtotal.toStringAsFixed(2)}',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding:
                            EdgeInsets.symmetric(
                          vertical: 14.h,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12.r,
                          ),
                        ),
                      ),
                      onPressed: _addingToCart
                          ? null
                          : _addCurrentProductsToCart,
                      child: _addingToCart
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child:
                                  const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : CustomText(
                              text: 'Confirm Order',
                              fontSize: 15.sp,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}