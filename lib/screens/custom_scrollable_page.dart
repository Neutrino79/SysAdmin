import 'package:flutter/material.dart';

class CustomScrollablePage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget content;

  const CustomScrollablePage({
    Key? key,
    required this.title,
    required this.icon,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(title,
                  style: TextStyle(color: colorScheme.onPrimary)),
              background: Container(
                child: Center(
                  child: Icon(
                    icon,
                    size: 80,
                    color: colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
              ),
            ),
            backgroundColor: colorScheme.primary,
            automaticallyImplyLeading: false,
          ),
          SliverToBoxAdapter(
            child: Container(
              height: MediaQuery.of(context).size.height + 500,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }
}