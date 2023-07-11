import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:luffy/api/mal.dart";

class AnimeInfo extends StatelessWidget {
  const AnimeInfo({Key? key, required this.anime}) : super(key: key);

  final AnimeListEntry anime;

  @override
  Widget build(BuildContext context) {
    final episodesWatched = anime.watchedEpisodes;
    final episodeCount = anime.totalEpisodes;
    final score = anime.score;
    final progress =
        episodeCount == null ? 1.0 : episodesWatched / episodeCount;

    final startDate = anime.startDate != null
        ? DateFormat.yMd().format(anime.startDate!)
        : "???";
    final endDate =
        anime.endDate != null ? DateFormat.yMd().format(anime.endDate!) : "???";

    final badgeColor = (() {
      if (score! >= 8) {
        return Colors.lightGreen;
      }

      if (score >= 6) {
        return Colors.amber;
      }

      return Colors.red;
    })();

    return SizedBox(
      height: 100,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: CachedNetworkImage(
                imageUrl: anime.imageUrl,
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.surface,
                ),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            anime.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text("$startDate - $endDate"),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("$episodesWatched/$episodeCount"),
                              if (score != 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    "$score",
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(),
                            ],
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.1),
                              value: progress,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
