import 'package:flutter/material.dart';

class StatCards extends StatelessWidget {
  final int totalBooks;
  final int readBooks;
  final int readingBooks;
  final int unreadBooks;

  const StatCards({
    super.key,
    required this.totalBooks,
    required this.readBooks,
    required this.readingBooks,
    required this.unreadBooks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem('📚 藏书', '$totalBooks', Colors.brown.shade700),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          _buildItem('📗 已读完', '$readBooks', Colors.green.shade600),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          _buildItem('📖 在读', '$readingBooks', Colors.orange.shade600),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          _buildItem('📘 未开始', '$unreadBooks', Colors.grey.shade500),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}