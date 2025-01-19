import 'package:flutter/material.dart';

class ItemFader extends StatefulWidget {
  final Widget child;
  const ItemFader({super.key, required this.child});

  @override
  ItemFaderState createState() => ItemFaderState();
}

class ItemFaderState extends State<ItemFader>
    with SingleTickerProviderStateMixin {
  int position = 1;
  late AnimationController _animationController;
  late Animation _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animation,
        child: widget.child,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 64.0 * position * (1 - _animation.value)),
            child: Opacity(
              opacity: _animation.value,
              child: child,
            ),
          );
        });
  }

  void show() {
    setState(() => position = 1);
    _animationController.forward();
  }

  void hide() {
    setState(() => position = -1);
    _animationController.reverse();
  }
}

class MyPage extends StatefulWidget {
  final List<Widget> elements;
  final VoidCallback onNext;

  const MyPage({super.key, required this.elements, required this.onNext});
  @override
  PageState createState() => PageState();
}

class PageState extends State<MyPage> {
  late List<GlobalKey<ItemFaderState>> keys;

  @override
  void initState() {
    super.initState();
    keys = List.generate(
      20,
      (_) => GlobalKey<ItemFaderState>(),
    );
    onInit();
  }

  void onInit() async {
    for (GlobalKey<ItemFaderState> key in keys) {
      await Future.delayed(const Duration(milliseconds: 60));
      key.currentState!.show();
    }
  }

  void onTap() {
    for (GlobalKey<ItemFaderState> key in keys) {
      if (key.currentState != null) {
        Future.delayed(const Duration(milliseconds: 40));
        key.currentState!.hide();
      }
    }

    Future.delayed(const Duration(milliseconds: 100));
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(188, 104, 104, 1),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(
                height: 32,
              ),
              ...widget.elements.map(
                (Widget element) {
                  int index = widget.elements.indexOf(element);
                  return ItemFader(key: keys[index], child: element);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
