import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StoryPilotAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StoryPilotAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  final Widget title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: context.canPop() ? const BackButton() : null,
      title: title,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
