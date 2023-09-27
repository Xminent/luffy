import "package:cached_network_image/cached_network_image.dart";
import "package:custom_refresh_indicator/custom_refresh_indicator.dart";
import "package:flutter/material.dart";
import "package:luffy/api/anime.dart";
import "package:luffy/api/history.dart";
import "package:luffy/api/mal.dart";
import "package:luffy/components/anime_info.dart";
import "package:luffy/screens/details.dart";
import "package:luffy/screens/details_sources.dart";

class _Data {
  _Data({
    required this.animeList,
    required this.userInfo,
  });

  final AnimeList animeList;
  final UserInfo? userInfo;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  late Future<_Data?> _dataFuture;

  void _onHistoryUpdate(List<HistoryEntry> e) {
    setState(() {
      _dataFuture = _getData();
    });
  }

  final List<String> _tabNames = [
    "Watching",
    "Plan to Watch",
    "On Hold",
    "Completed",
    "Dropped",
  ];

  final Map<String, AnimeExtractor> _extractorsMap = sources.fold(
    {},
    (Map<String, AnimeExtractor> map, AnimeExtractor extractor) {
      map[extractor.name] = extractor;
      return map;
    },
  );

  Future<_Data?> _getData() async {
    final animeList = await MalService.getAnimeList();
    final history = await HistoryService.getHistory();
    final animeListWatchingIdIdxMap = <int, int>{};

    // Create a map of the anime list's watching list's IDs to their index in the list.
    for (var i = 0; i < animeList.watching.length; i++) {
      final anime = animeList.watching[i];
      animeListWatchingIdIdxMap[anime.id] = i;
    }

    for (final historyEntry in history) {
      final latestEpisode = historyEntry.progress.keys.fold(
        0,
        (prev, curr) => curr > prev ? curr : prev,
      );

      animeList.watching.insert(
        0,
        AnimeListEntry(
          id: historyEntry.animeId ?? -1,
          title: historyEntry.title,
          imageUrl: historyEntry.imageUrl,
          status: AnimeListStatus.watching,
          score: 0,
          watchedEpisodes: latestEpisode,
          totalEpisodes: historyEntry.totalEpisodes <= 0
              ? null
              : historyEntry.totalEpisodes,
          isRewatching: false,
          startDate: null,
          endDate: null,
          // NOTE: CoverImageUrl will be used for the determining of the source.
          coverImageUrl: historyEntry.id,
          kitsuId: null,
          titleEnJp: "",
          titleJaJp: "",
          type: AnimeType.tv,
          extraData: historyEntry.showUrl,
        ),
      );
    }

    return _Data(
      animeList: animeList,
      userInfo: await MalService.getUserInfo(),
    );
  }

  @override
  void initState() {
    super.initState();

    _dataFuture = () async {
      await HistoryService.registerListener(_onHistoryUpdate);
      return _getData();
    }();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder(
      future: _dataFuture,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
            {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          case ConnectionState.done:
            break;
        }

        final data = snapshot.data;

        if (data == null) {
          return const Center(
            child: Text("No data"),
          );
        }

        final animeList = data.animeList;
        final userInfo = data.userInfo;

        return SafeArea(
          child: DefaultTabController(
            length: _tabNames.length,
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: userInfo?.picture ??
                          "https://via.placeholder.com/150",
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    if (userInfo != null)
                      Text(
                        " (${userInfo.name})",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    const Spacer(),
                    const Icon(Icons.more_vert),
                    const SizedBox(
                      width: 8,
                    )
                  ],
                ),
                bottom: TabBar(
                  isScrollable: true,
                  tabs: _tabNames.map((name) {
                    final toDisplay = (() {
                      switch (name) {
                        case "Watching":
                          return animeList.watching;
                        case "Plan to Watch":
                          return animeList.planToWatch;
                        case "On Hold":
                          return animeList.onHold;
                        case "Dropped":
                          return animeList.dropped;
                        case "Completed":
                          return animeList.completed;
                        default:
                          throw Exception("Invalid tab name");
                      }
                    })();

                    return Tab(text: "$name (${toDisplay.length})");
                  }).toList(),
                ),
              ),
              drawer: Drawer(
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text("Drawer Header"),
                    )
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  animeList.watching,
                  animeList.planToWatch,
                  animeList.onHold,
                  animeList.completed,
                  animeList.dropped
                ]
                    .map(
                      (e) => Container(
                        color: Theme.of(context).colorScheme.background,
                        child: CustomRefreshIndicator(
                          builder: MaterialIndicatorDelegate(
                            displacement: 20,
                            builder: (context, controller) {
                              final offset = controller.value * 0.5 * 3.1415;

                              return Transform.rotate(
                                angle: offset,
                                child: Icon(
                                  Icons.refresh,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 30,
                                ),
                              );
                            },
                          ),
                          onRefresh: () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Refreshing..."),
                                duration: Duration(milliseconds: 250),
                              ),
                            );

                            setState(() {
                              _dataFuture = () async {
                                final ret = await _getData();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Refreshed!"),
                                      duration: Duration(milliseconds: 250),
                                    ),
                                  );
                                }

                                return ret;
                              }();
                            });
                          },
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: e.length,
                            itemBuilder: (context, index) {
                              final anime = e[index];

                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    anime.id != -1 && anime.extraData.isEmpty
                                        ? MaterialPageRoute(
                                            builder: (context) => DetailsScreen(
                                              animeId: anime.id,
                                              malId: anime.id,
                                              isMalId: true,
                                              title: anime.title,
                                              imageUrl: anime.imageUrl,
                                              startDate: anime.startDate,
                                              endDate: anime.endDate,
                                              status: anime.status,
                                              score: anime.score,
                                              watchedEpisodes:
                                                  anime.watchedEpisodes,
                                              totalEpisodes:
                                                  anime.totalEpisodes ?? 0,
                                              bannerImageUrl:
                                                  anime.coverImageUrl,
                                              titleEnJp: anime.titleEnJp,
                                              titleJaJp: anime.titleJaJp,
                                              type: anime.type,
                                              onUpdate: (
                                                score,
                                                watchedEpisodes,
                                                status,
                                              ) {
                                                setState(() {
                                                  anime.score = score;
                                                  anime.watchedEpisodes =
                                                      watchedEpisodes;

                                                  if (anime.status == status) {
                                                    return;
                                                  }

                                                  final toModify = (() {
                                                    switch (anime.status) {
                                                      case AnimeListStatus
                                                            .watching:
                                                        return animeList
                                                            .watching;
                                                      case AnimeListStatus
                                                            .planToWatch:
                                                        return animeList
                                                            .planToWatch;
                                                      case AnimeListStatus
                                                            .onHold:
                                                        return animeList.onHold;
                                                      case AnimeListStatus
                                                            .completed:
                                                        return animeList
                                                            .completed;
                                                      case AnimeListStatus
                                                            .dropped:
                                                        return animeList
                                                            .dropped;
                                                    }
                                                  })();

                                                  final toAdd = (() {
                                                    switch (status) {
                                                      case AnimeListStatus
                                                            .watching:
                                                        return animeList
                                                            .watching;
                                                      case AnimeListStatus
                                                            .planToWatch:
                                                        return animeList
                                                            .planToWatch;
                                                      case AnimeListStatus
                                                            .onHold:
                                                        return animeList.onHold;
                                                      case AnimeListStatus
                                                            .completed:
                                                        return animeList
                                                            .completed;
                                                      case AnimeListStatus
                                                            .dropped:
                                                        return animeList
                                                            .dropped;
                                                    }
                                                  })();

                                                  toModify.remove(anime);
                                                  toAdd.insert(0, anime);
                                                  anime.status = status;
                                                });
                                              },
                                            ),
                                          )
                                        : MaterialPageRoute(
                                            builder: (context) =>
                                                DetailsScreenSources(
                                              anime: Anime(
                                                title: anime.title,
                                                imageUrl: anime.imageUrl,
                                                url: anime.extraData,
                                              ),
                                              animeId: anime.id,
                                              showId: anime.coverImageUrl!,
                                              title: anime.title,
                                              imageUrl: anime.imageUrl,
                                              extractor: _extractorsMap[anime
                                                  .coverImageUrl!
                                                  .substring(
                                                0,
                                                anime.coverImageUrl!
                                                    .indexOf("-"),
                                              )]!,
                                              watchedEpisodes:
                                                  anime.watchedEpisodes,
                                              totalEpisodes:
                                                  anime.totalEpisodes ?? 0,
                                            ),
                                          ),
                                  ),
                                  child: AnimeInfo(anime: anime),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    HistoryService.unregisterListener(_onHistoryUpdate);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
