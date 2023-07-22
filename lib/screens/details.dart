import "package:cached_network_image/cached_network_image.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:intl/intl.dart";
import "package:luffy/api/anime.dart";
import "package:luffy/api/extractors/animeflix.dart";
import "package:luffy/api/extractors/animepahe.dart";
import "package:luffy/api/extractors/gogoanime.dart";
import "package:luffy/api/extractors/superstream.dart";
import "package:luffy/api/mal.dart";
import "package:luffy/components/blinking_button.dart";
import "package:luffy/components/episode_list.dart";
import "package:luffy/components/mal_controls.dart";
import "package:luffy/dialogs.dart";
import "package:luffy/screens/video_player.dart";
import "package:luffy/util.dart";
import "package:skeletons/skeletons.dart";
import "package:string_similarity/string_similarity.dart";
import "package:tuple/tuple.dart";
import "package:url_launcher/url_launcher.dart";

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({
    super.key,
    required this.animeId,
    required this.title,
    this.imageUrl,
    this.startDate,
    this.endDate,
    this.status,
    this.score,
    this.watchedEpisodes,
    this.totalEpisodes,
    this.coverImageUrl,
    this.titleEnJp,
    this.titleJaJp,
    this.type,
    this.onUpdate,
  });

  final int animeId;
  final String title;
  final String? imageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final AnimeListStatus? status;
  final int? score;
  final int? watchedEpisodes;
  final int? totalEpisodes;
  final String? coverImageUrl;
  final String? titleEnJp;
  final String? titleJaJp;
  final AnimeType? type;
  final void Function(
    int score,
    int watchedEpisodes,
    AnimeListStatus status,
  )? onUpdate;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _AnimeAndEpisodes {
  _AnimeAndEpisodes({
    required this.isLoggedIn,
    required this.anime,
    required this.episodes,
    required this.episodeProgress,
    required this.totalEpisodes,
    required this.score,
    required this.watchedEpisodes,
    required this.status,
  });

  final bool isLoggedIn;
  final MalAnime anime;
  final List<Episode> episodes;
  List<double?> episodeProgress;
  final int? totalEpisodes;
  final int? score;
  final int? watchedEpisodes;
  final AnimeListStatus? status;
}

class _DetailsScreenState extends State<DetailsScreen>
    with AutomaticKeepAliveClientMixin {
  late Future<_AnimeAndEpisodes?> _animeInfoFuture;
  late int? _oldScore = widget.score;
  late int? _oldWatchedEpisodes = widget.watchedEpisodes;
  late AnimeListStatus? _oldStatus = widget.status;

  late int? _score = widget.score;
  late int? _watchedEpisodes = widget.watchedEpisodes;
  late AnimeListStatus? _status = widget.status;

  static final _extractors = [
    AnimeFlixExtractor(),
    AnimePaheExtractor(),
    GogoAnimeExtractor(),
    SuperStreamExtractor(),
  ];

  AnimeExtractor _extractor = _extractors.first;
  int _extractorIndex = 0;

  Future<void> _handleEpisodeSelected(
    Episode episode,
    int idx,
    _AnimeAndEpisodes? animeInfo,
  ) async {
    if (!context.mounted || animeInfo == null) {
      return;
    }

    final source = await _extractor.getVideoUrl(episode);

    if (source == null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to get video url"),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    const storage = FlutterSecureStorage();

    final savedProgressData =
        await storage.read(key: "anime_${widget.animeId}_episode_${idx + 1}");

    final savedProgress = double.tryParse(savedProgressData ?? "");

    // ignore: use_build_context_synchronously
    final progress = await Navigator.of(context).push<double>(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          showId: widget.animeId,
          showTitle: widget.title,
          episode: idx + 1,
          episodeTitle: episode.title ?? "Untitled",
          url: source.videoUrl,
          sourceName: _extractor.name,
          subtitle: source.subtitle,
          savedProgress: savedProgress,
        ),
      ),
    );

    if (progress != null && progress.isFinite) {
      setState(() {
        animeInfo.episodeProgress[idx] = progress;
      });
    }
  }

  Future<_AnimeAndEpisodes?> _getAnimeInfo({
    bool firstTime = false,
  }) async {
    final anime = await MalService.getAnimeInfo(widget.animeId);

    if (anime == null) {
      return null;
    }

    final episodes = await (() async {
      if (!firstTime) {
        final results = await _extractor.search(widget.title);

        if (results.isEmpty) {
          return <Episode>[];
        }

        final titles = results.map((e) => e.title.toLowerCase()).toList();
        final bestMatch =
            results[anime.title.toLowerCase().bestMatch(titles).bestMatchIndex];

        return _extractor.getEpisodes(bestMatch);
      }

      for (; _extractorIndex < _extractors.length; _extractorIndex++) {
        // Search all extractors for one with results.
        _extractor = _extractors[_extractorIndex];

        final results = await _extractor.search(widget.title);

        if (results.isEmpty) {
          continue;
        }

        final titles = results.map((e) => e.title).toList();
        final bestMatch = results[anime.title.bestMatch(titles).bestMatchIndex];

        if (_extractorIndex >= _extractors.length - 1) {
          _extractorIndex = 0;
        }

        return _extractor.getEpisodes(bestMatch);
      }

      if (_extractorIndex >= _extractors.length - 1) {
        _extractorIndex = 0;
      }

      return <Episode>[];
    })();

    final listStatus = await (() async {
      if (widget.score != null &&
          widget.status != null &&
          widget.totalEpisodes != null &&
          widget.watchedEpisodes != null) {
        return null;
      }

      return MalService.getListStatusFor(widget.animeId);
    })();

    final score = listStatus?.score ?? widget.score;
    final status = listStatus?.status ?? widget.status;
    final watchedEpisodes =
        listStatus?.watchedEpisodes ?? widget.watchedEpisodes;

    final isLoggedIn = await MalService.isLoggedIn();
    const storage = FlutterSecureStorage();

    final episodeProgress = await Future.wait(
      episodes.asMap().entries.map((e) async {
        final idx = e.key;

        // Attempt to read the progress from the storage.
        final key = "anime_${widget.animeId}_episode_${idx + 1}";
        final value = await storage.read(key: key);

        if (value == null) {
          return null;
        }

        return double.tryParse(value);
      }).toList(),
    );

    return _AnimeAndEpisodes(
      isLoggedIn: isLoggedIn,
      anime: anime,
      episodes: episodes,
      episodeProgress: episodeProgress,
      // Initially set the ones provided.
      score: score,
      status: status,
      watchedEpisodes: watchedEpisodes,
      totalEpisodes:
          listStatus?.totalEpisodes ?? widget.totalEpisodes ?? anime.episodes,
    );
  }

  List<Widget> _buildUpdateButton() {
    final oldScore = _oldScore;
    final oldStatus = _oldStatus;
    final oldWatchedEpisodes = _oldWatchedEpisodes;

    final score = _score;
    final status = _status;
    final watchedEpisodes = _watchedEpisodes;

    if (oldScore == score &&
        oldStatus == status &&
        oldWatchedEpisodes == watchedEpisodes) {
      return [];
    }

    return [
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: BlinkingWidget(
          blinkDuration: const Duration(milliseconds: 500),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.surface.withOpacity(0.1),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            onPressed: _saveChanges,
            child: const Text("Update"),
          ),
        ),
      ),
    ];
  }

  Tuple2<List<Widget>, double?> _buildLocalResumeButton(
    _AnimeAndEpisodes animeInfo,
  ) {
    final episodeProgress = animeInfo.episodeProgress;

    final recentProgress = episodeProgress
        .asMap()
        .entries
        .lastWhereOrNull((e) => e.value != null && e.value!.isFinite);

    if (recentProgress == null) {
      return const Tuple2([], null);
    }

    return Tuple2(
      [
        TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              Theme.of(context).colorScheme.surface,
            ),
          ),
          onPressed: () async {
            if (!context.mounted) {
              return;
            }

            final episode = animeInfo.episodes[recentProgress.key];
            final idx = recentProgress.key;

            _handleEpisodeSelected(episode, idx, animeInfo);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow),
              const SizedBox(width: 8),
              Text("Resume Episode ${recentProgress.key + 1}"),
            ],
          ),
        )
      ],
      recentProgress.value,
    );
  }

  List<Widget> _buildMalWatchButton(_AnimeAndEpisodes animeInfo) {
    final watchedEpisodes = _watchedEpisodes ?? 0;
    final proposedEpisode = watchedEpisodes + 1;
    final totalEpisodes = animeInfo.totalEpisodes;

    if (totalEpisodes == null || proposedEpisode > totalEpisodes) {
      return [];
    }

    return [
      TextButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.surface,
          ),
          foregroundColor: MaterialStateProperty.all(Colors.blue),
        ),
        onPressed: () async {
          if (!context.mounted) {
            return;
          }

          final episode = animeInfo.episodes[watchedEpisodes];
          final idx = watchedEpisodes;

          _handleEpisodeSelected(episode, idx, animeInfo);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow),
            const SizedBox(width: 8),
            Text("Watch Episode ${watchedEpisodes + 1}"),
          ],
        ),
      )
    ];
  }

  List<Widget> _buildResumeButton(_AnimeAndEpisodes? animeInfo) {
    if (animeInfo == null) {
      return [];
    }

    final localResume = _buildLocalResumeButton(animeInfo);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final recentProgress = localResume.item2;
    final progressBar = recentProgress != null && recentProgress.isFinite
        ? [
            LinearProgressIndicator(
              value: recentProgress,
              backgroundColor: primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(primaryColor),
            )
          ]
        : [];

    return [
      SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...localResume.item1,
                ..._buildMalWatchButton(animeInfo),
              ],
            ),
            const SizedBox(height: 8),
            ...progressBar,
          ],
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildAddToListButton(bool? isLoggedIn) {
    final oldScore = _oldScore;
    final oldStatus = _oldStatus;
    final oldWatchedEpisodes = _oldWatchedEpisodes;

    if (oldScore != null ||
        oldStatus != null ||
        oldWatchedEpisodes != null ||
        isLoggedIn == null ||
        !isLoggedIn) {
      return [];
    }

    return [
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: BlinkingWidget(
          blinkDuration: const Duration(milliseconds: 500),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.surface.withOpacity(0.1),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            onPressed: () async {
              final res = await MalService.updateAnimeListItem(
                widget.animeId,
                AnimeListStatus.planToWatch,
                score: 0,
                numWatchedEpisodes: 0,
              );

              if (res == null || res.statusCode != 200) {
                if (context.mounted) {
                  showErrorDialog(
                    context,
                    "Could not add anime to list. I'm guessing that MyAnimeList is down or you are not connected to the internet. Please try to add again later.",
                  );
                }

                return;
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Anime added to list!"),
                  ),
                );
              }
            },
            child: const Text("Add to list"),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildMalControls(_AnimeAndEpisodes? animeInfo) {
    if (animeInfo == null) {
      return [];
    }

    final watchedEpisodes = _watchedEpisodes;
    final totalEpisodes = animeInfo.totalEpisodes ?? widget.totalEpisodes;
    final score = _score;
    final status = _status;

    if (watchedEpisodes == null ||
        totalEpisodes == null ||
        score == null ||
        status == null) {
      return [];
    }

    return [
      const SizedBox(height: 16),
      MalControls(
        watchedEpisodes: watchedEpisodes,
        totalEpisodes: totalEpisodes,
        score: score,
        status: status,
        onScoreChanged: (value) {
          setState(() {
            _score = value;
          });
        },
        onStatusChanged: (value) {
          setState(() {
            _status = value;
          });
        },
        onWatchedEpisodesChanged: (value) {
          setState(() {
            _watchedEpisodes = value;

            if (value == 0) {
              _status = AnimeListStatus.planToWatch;
              return;
            }

            if (value == totalEpisodes) {
              _status = AnimeListStatus.completed;
              return;
            }

            if (value > 0) {
              _status = AnimeListStatus.watching;
            }
          });
        },
      ),
    ];
  }

  List<Widget> _buildCharactersScrollable(_AnimeAndEpisodes? animeInfo) {
    if (animeInfo == null) {
      return [];
    }

    final characters = animeInfo.anime.characters;

    if (characters == null || characters.isEmpty) {
      return [];
    }

    return [
      const SizedBox(height: 16),
      const Text(
        "Characters",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: characters.length,
          itemBuilder: (context, idx) {
            final character = characters[idx];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: character.imageUrl,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 150,
                    child: Text(
                      character.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildRelationsCards(_AnimeAndEpisodes? animeInfo) {
    final relations = animeInfo?.anime.relations;

    if (relations == null || relations.isEmpty) {
      return [];
    }

    final groupedRelations = relations.fold<Map<String, List<Relation>>>(
      {},
      (acc, relation) {
        final type = relation.relationType;

        if (acc.containsKey(type)) {
          acc[type]!.add(relation);
        } else {
          acc[type] = [relation];
        }

        return acc;
      },
    );

    return [
      const SizedBox(height: 16),
      Text(
        "Relations",
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      ...groupedRelations.entries.map(
        (entry) {
          final relationType = entry.key;
          final relations = entry.value;

          return Column(
            children: [
              Text(
                relationType,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: relations.length * 30.0,
                child: Column(
                  children: relations.map(
                    (relation) {
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DetailsScreen(
                              animeId: relation.id,
                              title: relation.title,
                            ),
                          ),
                        ),
                        child: SizedBox(
                          height: 30,
                          child: Text(
                            relation.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildBody({
    required _AnimeAndEpisodes? animeInfo,
    required String? coverImageUrl,
    required bool isLoading,
  }) {
    if (isLoading) {
      return _skeletonView();
    }

    final startDate = widget.startDate != null
        ? DateFormat.yMd().format(widget.startDate!)
        : "???";

    final animePoster = widget.imageUrl ?? animeInfo?.anime.imageUrl;

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            ...[
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: coverImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: coverImageUrl,
                              errorWidget: (context, url, error) => Container(
                                color: Theme.of(context).colorScheme.surface,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Theme.of(context).colorScheme.surface,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: animePoster != null
                            ? CachedNetworkImage(
                                imageUrl: animePoster,
                                errorWidget: (context, url, error) => Container(
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                                width: 100,
                                height: 140,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Theme.of(context).colorScheme.surface,
                                width: 100,
                                height: 140,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                startDate,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                animeInfo?.anime.status ?? "N/A",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                animeInfo?.anime.synopsis ?? "No synopsis available.",
                style: const TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              _buildGenres(animeInfo?.anime),
              ..._buildCharactersScrollable(animeInfo),
              ..._buildRelationsCards(animeInfo),
              ..._buildMalControls(animeInfo),
              ..._buildAddToListButton(animeInfo?.isLoggedIn),
              ..._buildUpdateButton(),
              DropdownButton(
                value: _extractorIndex,
                onChanged: (index) {
                  if (index == null) {
                    return;
                  }

                  setState(() {
                    _extractorIndex = index;
                    _extractor = _extractors[index];
                    _animeInfoFuture = _getAnimeInfo();
                  });
                },
                items: _extractors
                    .asMap()
                    .entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value.name),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              ..._buildResumeButton(animeInfo),
              EpisodeList(
                episodes: animeInfo?.episodes ?? [],
                episodeProgress: animeInfo?.episodeProgress ?? [],
                watchedEpisodes: animeInfo?.watchedEpisodes ?? 0,
                totalEpisodes:
                    animeInfo?.totalEpisodes ?? widget.totalEpisodes ?? 0,
                onEpisodeSelected: (episode, idx) {
                  _handleEpisodeSelected(episode, idx, animeInfo);
                },
              ),

              // ...List.generate(
              //   widget.totalEpisodes,
              //   (index) => Column(children: [
              //     const SizedBox(height: 5),
              //     Container(
              //       decoration: BoxDecoration(
              //         color: widget.totalEpisodes - index <=
              //                 widget.watchedEpisodes
              //             ? Theme.of(context)
              //                 .colorScheme
              //                 .primary
              //                 .withOpacity(0.5)
              //             : Theme.of(context).colorScheme.surface,
              //         borderRadius: BorderRadius.circular(10),
              //       ),
              //       child: Padding(
              //           padding: const EdgeInsets.all(8.0),
              //           child: Row(
              //             mainAxisAlignment:
              //                 MainAxisAlignment.spaceBetween,
              //             children: [
              //               Text(
              //                 "Episode ${widget.totalEpisodes - index}",
              //                 style: textColorStyle.copyWith(
              //                   fontSize: 16,
              //                 ),
              //               ),
              //               const Icon(Icons.check),
              //             ],
              //           )),
              //     ),
              //     const SizedBox(height: 5)
              //   ]),
              // ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenres(MalAnime? animeInfo) {
    final textColorStyle = TextStyle(
      color: Theme.of(context).colorScheme.onBackground,
    );

    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (animeInfo?.genres == null) {
      return const SizedBox.shrink();
    }

    if (isPortrait) {
      return Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          const Text(
            "Genres:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...animeInfo!.genres!
              .map(
                (genre) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      genre,
                      style: textColorStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ],
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      alignment: WrapAlignment.center,
      children: [
        const Text("Genres:", style: TextStyle(fontWeight: FontWeight.bold)),
        ...animeInfo!.genres!
            .map(
              (genre) => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    genre,
                    style: textColorStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _skeletonView() => Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).colorScheme.background,
        child: SkeletonItem(
          child: Column(
            children: [
              const Expanded(
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      // full-width cover image
                      Positioned.fill(
                        child: SkeletonAvatar(
                          style: SkeletonAvatarStyle(
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      // anime picture centered on top of the cover image
                      Positioned(
                        top: 50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SkeletonAvatar(
                            style: SkeletonAvatarStyle(
                              width: 100,
                              height: 140,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Flexible(
                child: SizedBox(
                  height: 8,
                ),
              ),
              Expanded(
                child: SkeletonLine(
                  style: SkeletonLineStyle(
                    alignment: AlignmentDirectional.center,
                    width: MediaQuery.of(context).size.width / 3,
                    height: 24,
                  ),
                ),
              ),
              const Flexible(
                child: SizedBox(
                  height: 8,
                ),
              ),
              Expanded(
                child: SkeletonLine(
                  style: SkeletonLineStyle(
                    alignment: AlignmentDirectional.center,
                    width: MediaQuery.of(context).size.width / 3,
                    height: 16,
                  ),
                ),
              ),
              const Flexible(
                child: SizedBox(
                  height: 8,
                ),
              ),
              Expanded(
                child: SkeletonLine(
                  style: SkeletonLineStyle(
                    alignment: AlignmentDirectional.center,
                    width: MediaQuery.of(context).size.width / 4,
                    height: 16,
                  ),
                ),
              ),
              const Flexible(
                child: SizedBox(
                  height: 8,
                ),
              ),
              SkeletonParagraph(
                style: SkeletonParagraphStyle(
                  spacing: 6,
                  lineStyle: SkeletonLineStyle(
                    randomLength: true,
                    height: 16,
                    minLength: MediaQuery.of(context).size.width / 2,
                    alignment: AlignmentDirectional.center,
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              const Expanded(
                child: SkeletonAvatar(
                  style: SkeletonAvatarStyle(
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              const Flexible(
                child: SizedBox(
                  height: 8,
                ),
              ),
              const Expanded(
                child: SkeletonAvatar(
                  style: SkeletonAvatarStyle(
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _goToMyAnimeList() async {
    final uri = Uri.parse("https://myanimelist.net/anime/${widget.animeId}");

    if (!await canLaunchUrl(uri)) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _saveChanges() async {
    final status = _status;
    final score = _score;
    final watchedEpisodes = _watchedEpisodes;

    if (status == null || score == null || watchedEpisodes == null) {
      return;
    }

    final res = await MalService.updateAnimeListItem(
      widget.animeId,
      status,
      score: score,
      numWatchedEpisodes: watchedEpisodes,
    );

    if (res == null || res.statusCode != 200) {
      if (context.mounted) {
        showErrorDialog(
          context,
          "Could not update this anime. I'm guessing that MyAnimeList is down or you are not connected to the internet. Please try to update again later.",
        );
      }

      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anime updated successfully!"),
        ),
      );
    }

    setState(() {
      _oldScore = score;
      _oldStatus = status;
      _oldWatchedEpisodes = watchedEpisodes;
    });

    widget.onUpdate?.call(score, watchedEpisodes, status);
  }

  Future<bool> _onWillPop() async {
    if (_oldScore == _score &&
        _oldStatus == _status &&
        _oldWatchedEpisodes == _watchedEpisodes) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Save changes?",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "You have unsaved changes. Do you want to sync them with MyAnimeList?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (result == null) {
      return false;
    }

    if (result) {
      await _saveChanges();
    }

    return true;
  }

  void _setInitialValues(_AnimeAndEpisodes? animeInfo) {
    if (animeInfo == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _oldScore = animeInfo.score ?? widget.score;
        _oldStatus = animeInfo.status ?? widget.status;
        _oldWatchedEpisodes =
            animeInfo.watchedEpisodes ?? widget.watchedEpisodes;

        _score = _oldScore;
        _status = _oldStatus;
        _watchedEpisodes = _oldWatchedEpisodes;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _animeInfoFuture = _getAnimeInfo(firstTime: true);

    // Post frame callback to set the initial values if the future is already done.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animeInfoFuture.then((animeInfo) {
        prints("Setting initial values");

        _setInitialValues(animeInfo);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: FutureBuilder(
          future: _animeInfoFuture,
          builder: (context, snapshot) {
            prints("Rebuilding anime info page");

            final animeInfo = snapshot.data;
            final coverImageUrl = widget.coverImageUrl;

            return Scaffold(
              appBar: AppBar(
                title: Text(widget.title),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: _goToMyAnimeList,
                  ),
                ],
              ),
              body: _buildBody(
                animeInfo: animeInfo,
                coverImageUrl: coverImageUrl,
                isLoading: snapshot.connectionState != ConnectionState.done,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
