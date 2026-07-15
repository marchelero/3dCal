// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

/// Spinner centrado con texto opcional debajo.
///
/// Reemplaza el patron `Center(child: CircularProgressIndicator())`
/// esparcido por las paginas.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}
