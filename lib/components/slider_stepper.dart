import "package:flutter/material.dart";
import "package:luffy/components/video_player/control_icon.dart";

class SliderStepper extends StatefulWidget {
  const SliderStepper({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.original,
    this.min = 0.0,
    this.max = 5.0,
    this.minStep = 0.1,
    this.maxStep = 0.5,
    required this.labelBuilder,
    required this.tooltipBuilder,
    required this.onValueChanged,
  });

  final IconData icon;
  final String title;
  final double value;

  /// A value that the slider should start at (e.g 1.0 for speed).
  final double? original;
  final double min;
  final double max;
  final double minStep;
  final double maxStep;
  final String Function(double value) labelBuilder;
  final String Function(double value) tooltipBuilder;
  final ValueChanged<double> onValueChanged;

  @override
  State<SliderStepper> createState() => _SliderStepperState();
}

class _SliderStepperState extends State<SliderStepper> {
  late double _selectedSpeed = widget.value;
  bool _isConfirmButtonVisible = false;

  Future<void> _showSpeedDialog() async {
    final selectedSpeed = await showDialog<double>(
      context: context,
      builder: (context) {
        final original = widget.original;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(widget.title),
              content: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Button with minus symbol to decrease speed by widget.maxStep.
                  VideoPlayerIcon(
                    icon: Icons.remove_rounded,
                    onPressed: () {
                      setState(() {
                        _selectedSpeed = (_selectedSpeed - widget.maxStep)
                            .clamp(widget.min, widget.max);
                        _isConfirmButtonVisible = true;
                      });
                    },
                  ),
                  // Button with minus symbol to decrease speed by widget.minStep.
                  VideoPlayerIcon(
                    icon: Icons.remove,
                    onPressed: () {
                      setState(() {
                        _selectedSpeed = (_selectedSpeed - widget.minStep)
                            .clamp(widget.min, widget.max);
                        _isConfirmButtonVisible = true;
                      });
                    },
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Slider(
                        value: _selectedSpeed,
                        min: widget.min,
                        max: widget.max,
                        divisions: 45,
                        onChanged: (value) {
                          setState(() {
                            _selectedSpeed = value;
                            _isConfirmButtonVisible = true;
                          });
                        },
                        onChangeEnd: (value) {
                          setState(() {
                            _isConfirmButtonVisible = true;
                          });
                        },
                      ),
                      Text(widget.tooltipBuilder(_selectedSpeed)),
                    ],
                  ),
                  // Button with minus symbol to increase speed by widget.minStep.
                  VideoPlayerIcon(
                    icon: Icons.add,
                    onPressed: () {
                      setState(() {
                        _selectedSpeed = (_selectedSpeed + widget.minStep)
                            .clamp(widget.min, widget.max);
                        _isConfirmButtonVisible = true;
                      });
                    },
                  ),
                  // Button with minus symbol to increase speed by widget.maxStep.
                  VideoPlayerIcon(
                    icon: Icons.add_rounded,
                    onPressed: () {
                      setState(() {
                        _selectedSpeed = (_selectedSpeed + widget.maxStep)
                            .clamp(widget.min, widget.max);
                        _isConfirmButtonVisible = true;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                // Reset button to original speed if different.
                if (original != null && _selectedSpeed != original)
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedSpeed = original;
                    }),
                    child: const Text("Reset"),
                  ),
                if (_isConfirmButtonVisible)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_selectedSpeed),
                    child: const Text("Confirm"),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedSpeed != null) {
      setState(() {
        _selectedSpeed = selectedSpeed;
      });

      widget.onValueChanged(_selectedSpeed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayerIcon(
      icon: widget.icon,
      onPressed: _showSpeedDialog,
      label: widget.labelBuilder(widget.value),
    );
  }
}
