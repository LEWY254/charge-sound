import 'package:flutter/material.dart';

Future<void> showRoyaltyFreeTermsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Royalty-Free Marketplace Terms',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'Marketplace sounds are provided as royalty-free assets for your '
              'personal and commercial projects unless a license entry says otherwise.',
            ),
            SizedBox(height: 10),
            Text(
              'You are responsible for following the listed attribution and usage rules '
              'for each sound before publishing your work.',
            ),
            SizedBox(height: 10),
            Text(
              'Do not re-upload, resell, or redistribute marketplace sounds as standalone files.',
            ),
            SizedBox(height: 10),
            Text(
              'Always check the License section on each sound to review creator credit, '
              'source terms, and permitted use.',
            ),
          ],
        ),
      ),
    ),
  );
}
