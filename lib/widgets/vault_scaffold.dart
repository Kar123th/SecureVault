import 'package:flutter/material.dart';
import '../utils/app_styles.dart';

class VaultScaffold extends StatelessWidget {
  final Widget body;
  final Widget? appBar; // Optional if we want to use slivers or custom appbars
  final PreferredSizeWidget? appBarPreferred;
  final Widget? floatingActionButton;
  final String? title;
  final List<Widget>? actions;

  const VaultScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.appBarPreferred,
    this.floatingActionButton,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarPreferred ?? (title != null ? AppBar(
        title: Text(title!),
        actions: actions,
        surfaceTintColor: Colors.transparent,
      ) : null),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: AppStyles.mainGradientDecoration,
        child: SafeArea(
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
