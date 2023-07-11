import "package:custom_refresh_indicator/custom_refresh_indicator.dart";
import "package:flutter/material.dart";
import "package:luffy/api/mal.dart";
import "package:luffy/components/anime_info.dart";
import "package:luffy/screens/details.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  late Future<AnimeList?> _animeListFuture;

  final List<String> _tabNames = [
    "Watching",
    "Plan to Watch",
    "On Hold",
    "Completed",
    "Dropped",
  ];

  Future<AnimeList> _getAnimeList() async {
    // return Future.value(AnimeList(
    //   completed: [],
    //   watching: List.generate(
    //       100,
    //       (index) => AnimeListEntry(
    //           id: 1,
    //           title: "title $index",
    //           imageUrl: "https://via.placeholder.com/150",
    //           status: AnimeListStatus.completed,
    //           score: 1,
    //           watchedEpisodes: 1,
    //           totalEpisodes: 2,
    //           isRewatching: false,
    //           startDate: null,
    //           endDate: null)),
    //   dropped: [],
    //   onHold: [],
    //   planToWatch: [],
    // ));

    return MalService.getAnimeList();
  }

  @override
  void initState() {
    super.initState();
    _animeListFuture = _getAnimeList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder(
      future: _animeListFuture,
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

        if (snapshot.data == null) {
          return const Center(
            child: Text("No data"),
          );
        }

        final animeList = snapshot.data!;

        return SafeArea(
          child: DefaultTabController(
            length: _tabNames.length,
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Home"),
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
                            builder: (context, controller) {
                              final offset = controller.value * 0.5 * 3.1415;

                              return Transform.rotate(
                                angle: offset,
                                child: Icon(
                                  Icons.ac_unit,
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
                                duration: Duration(seconds: 1),
                              ),
                            );

                            // Wait for 2 seconds to simulate refreshing.
                            return Future.delayed(const Duration(seconds: 2),
                                () {
                              setState(() {
                                _animeListFuture = _getAnimeList();
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Refreshed!"),
                                  duration: Duration(seconds: 1),
                                ),
                              );
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
                                    MaterialPageRoute(
                                      builder: (context) => DetailsScreen(
                                        animeId: anime.id,
                                        title: anime.title,
                                        imageUrl: anime.imageUrl,
                                        startDate: anime.startDate,
                                        endDate: anime.endDate,
                                        status: anime.status,
                                        score: anime.score,
                                        watchedEpisodes: anime.watchedEpisodes,
                                        totalEpisodes: anime.totalEpisodes ?? 0,
                                        coverImageUrl: anime.coverImageUrl,
                                        titleEnJp: anime.titleEnJp,
                                        titleJaJp: anime.titleJaJp,
                                        type: anime.type,
                                        onUpdate:
                                            (score, watchedEpisodes, status) {
                                          setState(() {
                                            anime.score = score;
                                            anime.watchedEpisodes =
                                                watchedEpisodes;

                                            if (anime.status == status) {
                                              return;
                                            }

                                            final toModify = (() {
                                              switch (anime.status) {
                                                case AnimeListStatus.watching:
                                                  return animeList.watching;
                                                case AnimeListStatus
                                                      .planToWatch:
                                                  return animeList.planToWatch;
                                                case AnimeListStatus.onHold:
                                                  return animeList.onHold;
                                                case AnimeListStatus.completed:
                                                  return animeList.completed;
                                                case AnimeListStatus.dropped:
                                                  return animeList.dropped;
                                              }
                                            })();

                                            final toAdd = (() {
                                              switch (status) {
                                                case AnimeListStatus.watching:
                                                  return animeList.watching;
                                                case AnimeListStatus
                                                      .planToWatch:
                                                  return animeList.planToWatch;
                                                case AnimeListStatus.onHold:
                                                  return animeList.onHold;
                                                case AnimeListStatus.completed:
                                                  return animeList.completed;
                                                case AnimeListStatus.dropped:
                                                  return animeList.dropped;
                                              }
                                            })();

                                            toModify.remove(anime);
                                            toAdd.insert(0, anime);
                                            anime.status = status;
                                          });
                                        },
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
  bool get wantKeepAlive => true;
}
