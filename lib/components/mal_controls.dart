import "package:flutter/material.dart";
import "package:luffy/api/mal.dart";
import "package:luffy/components/episode_progress_dialog.dart";

class MalControls extends StatelessWidget {
  const MalControls({
    super.key,
    required this.watchedEpisodes,
    required this.totalEpisodes,
    required this.score,
    required this.status,
    required this.onScoreChanged,
    required this.onStatusChanged,
    required this.onWatchedEpisodesChanged,
  });

  final int watchedEpisodes;
  final int totalEpisodes;
  final int? score;
  final AnimeListStatus status;
  final Function(int) onScoreChanged;
  final Function(AnimeListStatus) onStatusChanged;
  final Function(int) onWatchedEpisodesChanged;

  String _animeListStatusToString(AnimeListStatus status) {
    switch (status) {
      case AnimeListStatus.watching:
        return "Watching";
      case AnimeListStatus.completed:
        return "Completed";
      case AnimeListStatus.onHold:
        return "On Hold";
      case AnimeListStatus.dropped:
        return "Dropped";
      case AnimeListStatus.planToWatch:
        return "Plan to Watch";
    }
  }

  Widget _buildStatusOption(BuildContext context, AnimeListStatus opt) {
    return RadioListTile(
      title: Text(_animeListStatusToString(opt)),
      value: opt,
      groupValue: status,
      onChanged: (value) {
        if (value != null) {
          onStatusChanged(value);
        }

        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoreDescriptions = [
      "Unrated",
      "Amagami SS",
      "Horrible",
      "Very Bad",
      "Bad",
      "Average",
      "Fine",
      "Good",
      "Very Good",
      "Great",
      "Masterpiece",
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.grey,
              splashFactory: InkRipple.splashFactory,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Set Your Status"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusOption(context, AnimeListStatus.watching),
                        _buildStatusOption(
                          context,
                          AnimeListStatus.planToWatch,
                        ),
                        _buildStatusOption(context, AnimeListStatus.onHold),
                        _buildStatusOption(context, AnimeListStatus.completed),
                        _buildStatusOption(context, AnimeListStatus.dropped),
                      ],
                    ),
                  ),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  children: [
                    const Icon(Icons.tv),
                    const SizedBox(height: 8),
                    Text(_animeListStatusToString(status)),
                  ],
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.grey,
              splashFactory: InkRipple.splashFactory,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => EpisodeProgressDialog(
                    watchedEpisodes: watchedEpisodes,
                    totalEpisodes: totalEpisodes,
                    onEpisodeSelected: (episode) {
                      onWatchedEpisodesChanged(episode);
                    },
                  ),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  children: [
                    const Icon(Icons.playlist_play),
                    const SizedBox(height: 8),
                    Text("$watchedEpisodes/$totalEpisodes"),
                  ],
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.grey,
              splashFactory: InkRipple.splashFactory,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Set Your Score"),
                    content: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: GridView.builder(
                        itemCount: 11,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 6 / 2,
                        ),
                        itemBuilder: (context, index) {
                          final selectedStyle = score == index
                              ? TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null;

                          return InkWell(
                            onTap: () {
                              onScoreChanged(index);
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "$index",
                                    style: selectedStyle,
                                  ),
                                  Text(
                                    scoreDescriptions[index],
                                    style: selectedStyle,
                                  ),
                                ],
                              ),
                            ),
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
                  ),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  children: [
                    const Icon(Icons.star),
                    const SizedBox(height: 8),
                    Text("$score"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
