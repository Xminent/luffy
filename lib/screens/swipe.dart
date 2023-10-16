import "package:flutter/material.dart";

class TwoProgressBarsScreen extends StatefulWidget {
  const TwoProgressBarsScreen({super.key});

  @override
  State<TwoProgressBarsScreen> createState() => _TwoProgressBarsScreenState();
}

class _TwoProgressBarsScreenState extends State<TwoProgressBarsScreen> {
  double _leftProgress = 0.0;
  double _rightProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) {
            setState(() {
              if (details.localPosition.dx <
                  MediaQuery.of(context).size.width / 2) {
                _leftProgress +=
                    details.delta.dy / MediaQuery.of(context).size.height;
                _leftProgress = _leftProgress.clamp(0.0, 1.0);
              } else {
                _rightProgress +=
                    details.delta.dy / MediaQuery.of(context).size.height;
                _rightProgress = _rightProgress.clamp(0.0, 1.0);
              }
            });
          },
          child: Stack(
            children: [
              Positioned.fill(
                left: 16,
                right: 16,
                top: 16,
                bottom: 48, // leave space for the button
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade300,
                        ),
                        child: FractionallySizedBox(
                          heightFactor: _leftProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade300,
                        ),
                        child: FractionallySizedBox(
                          heightFactor: _rightProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _leftProgress = 0;
                        _rightProgress = 0;
                      });
                    },
                    child: const Text("Reset"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
