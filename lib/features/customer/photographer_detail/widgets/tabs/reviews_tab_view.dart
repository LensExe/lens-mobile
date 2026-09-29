import 'package:flutter/material.dart';

import '../../models/photographer_detail_model.dart';

class ReviewsTabView extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final List<ClientReview> reviews;

  const ReviewsTabView({
    super.key,
    required this.rating,
    required this.reviewCount,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with overall rating score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Đánh giá từ khách hàng',
                        style: TextStyle(
                          color: Color(0xFF1A1C1D),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '$rating ★',
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Xem tất cả ($reviewCount)',
                style: const TextStyle(
                  color: Color(0xFFA83900),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Reviews List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final rev = reviews[index];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client Identity Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8E8E9),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  rev.clientInitials,
                                  style: const TextStyle(
                                    color: Color(0xFF1A1C1D),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rev.clientName,
                                      style: const TextStyle(
                                        color: Color(0xFF1A1C1D),
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      rev.clientRole,
                                      style: const TextStyle(
                                        color: Color(0xFF5F5E60),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          rev.timeAgo,
                          style: const TextStyle(
                            color: Color(0xFF5F5E60),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Stars & Tag
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (starIdx) {
                            return const Padding(
                              padding: EdgeInsets.only(right: 2),
                              child: Icon(
                                Icons.star,
                                color: Color(0xFFFF5A00),
                                size: 14,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEF),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            rev.packageTag,
                            style: const TextStyle(
                              color: Color(0xFF5F5E60),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Content
                    Text(
                      rev.content,
                      style: const TextStyle(
                        color: Color(0xFF2F3132),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
