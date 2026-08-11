// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_locale.dart';

enum LegalDocumentType { privacy, terms }

class LegalDocumentPage extends ConsumerWidget {
  const LegalDocumentPage({required this.type, super.key});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(localeStringsProvider);
    final isPrivacy = type == LegalDocumentType.privacy;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isPrivacy
              ? strings.paywallPrivacyPolicy
              : strings.paywallTermsOfService,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SelectableText(
                isPrivacy
                    ? strings.legalPrivacyDocument
                    : strings.legalTermsDocument,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
