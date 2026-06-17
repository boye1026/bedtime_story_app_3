import 'package:flutter/material.dart';

class StarAnimation extends StatefulWidget {
  const StarAnimation({super.key});

  @override
  State<StarAnimation> createState() => _StarAnimationState();
}

class _StarAnimationState extends State<StarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _starAnimations;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _starAnimations = List.generate(5, (index) {
      return Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(index * 0.15, 1.0, curve: Curves.easeInOut),
        ),
      );
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _starAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _starAnimations[index].value,
              child: Opacity(
                opacity: _starAnimations[index].value,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.star, color: Colors.amber, size: 24),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
