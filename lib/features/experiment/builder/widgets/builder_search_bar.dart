import 'package:flutter/material.dart';

class BuilderSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const BuilderSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  static List<T> filter<T>(
    List<T> items,
    String query,
    Iterable<String> Function(T item) terms,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return items;
    return items
        .where((item) {
          return terms(
            item,
          ).any((term) => term.toLowerCase().contains(normalized));
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: hintText,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
