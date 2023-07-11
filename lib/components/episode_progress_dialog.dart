import "package:flutter/material.dart";
import "package:scrollable_positioned_list/scrollable_positioned_list.dart";

class EpisodeProgressDialog extends StatefulWidget {
  const EpisodeProgressDialog({
    super.key,
    required this.watchedEpisodes,
    required this.totalEpisodes,
    required this.onEpisodeSelected,
  });

  final int watchedEpisodes;
  final int totalEpisodes;
  final Function(int) onEpisodeSelected;

  @override
  State<EpisodeProgressDialog> createState() => _EpisodeProgressDialogState();
}

class _EpisodeProgressDialogState extends State<EpisodeProgressDialog> {
  List<Widget> _buildEpisodeButtons() {
    final columnCount = widget.totalEpisodes > 500 ? 5 : 3;
    final ret = <Widget>[];

    for (var i = 0; i < widget.totalEpisodes + 1; i += columnCount) {
      final rowChildren = <Widget>[];

      for (var j = 0; j < columnCount; j++) {
        final episodeNumber = i + j;
        final hasWatchedStyle = TextStyle(
          color: episodeNumber <= widget.watchedEpisodes
              ? Theme.of(context).colorScheme.primary
              : null,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        );

        if (episodeNumber > widget.totalEpisodes) {
          break;
        }

        final item = Expanded(
          child: InkWell(
            onTap: () {
              widget.onEpisodeSelected(episodeNumber);
              Navigator.of(context).pop();
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: FittedBox(
                  child: Text(
                    "$episodeNumber",
                    style: hasWatchedStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );

        if (j != 0) {
          rowChildren.addAll(
            [
              const SizedBox(width: 8),
              item,
            ],
          );

          continue;
        }

        rowChildren.add(item);
      }

      ret.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rowChildren,
        ),
      );
    }

    return ret;
  }

  @override
  Widget build(BuildContext context) {
    final columnCount = widget.totalEpisodes > 500 ? 5 : 3;
    final rowCount = (widget.totalEpisodes / columnCount).ceil();
    final rowsToDisplay = rowCount > 11 ? 11 : rowCount;

    final episodeButtons = _buildEpisodeButtons();
    final initialScrollIndex = (widget.watchedEpisodes - 1) ~/ columnCount;

    return AlertDialog(
      title: const Text("Set episode progress"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            // Calculated height of component considering 8px padding. We also use the episodeButtons.length to calculate the height of the component.
            final calculatedWidth = (constraints.maxWidth - 16) / columnCount;
            final calculatedHeight =
                ((height - 8 * (rowsToDisplay - 1)) / rowsToDisplay)
                    .clamp(40.0, 60.0);

            return ScrollablePositionedList.builder(
              initialScrollIndex: initialScrollIndex,
              itemCount: episodeButtons.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: calculatedWidth,
                  height: calculatedHeight,
                  child: index == 0
                      ? episodeButtons[index]
                      : Column(
                          children: [
                            const SizedBox(height: 8),
                            Expanded(child: episodeButtons[index]),
                          ],
                        ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
