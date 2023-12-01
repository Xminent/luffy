import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";

class ParallaxContainer extends StatefulWidget {
  const ParallaxContainer({
    super.key,
    required this.child,
    required this.backgroundImageUrl,
  });

  final Widget child;
  final String? backgroundImageUrl;

  @override
  State<ParallaxContainer> createState() => _ParallaxContainerState();
}

class _ParallaxContainerState extends State<ParallaxContainer>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late Animation<double>? _animation;

  @override
  void initState() {
    super.initState();

    // _imageExists = ((){
    //   try {
    //     final res = await http.
    //   }
    // }async)();

    if (widget.backgroundImageUrl != null) {
      _controller = AnimationController(
        duration: const Duration(seconds: 30),
        vsync: this,
      )..repeat(reverse: true);

      _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller!,
          curve: Curves.linear,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.backgroundImageUrl != null)
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2,
            child: AnimatedBuilder(
              animation: _animation!,
              builder: (context, child) {
                return Transform.scale(
                  scale: 3,
                  child: Transform.translate(
                    offset: Offset(_animation!.value * 100, 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            widget.backgroundImageUrl!,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 2,
                          sigmaY: 2,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(
                              0.2,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        widget.child,
      ],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
