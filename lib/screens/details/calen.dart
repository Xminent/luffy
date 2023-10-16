import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:luffy/api/anilist.dart";
import "package:luffy/components/anime_card.dart";
import "package:luffy/screens/details.dart";

class _Data {
  _Data({
    required this.weekly,
  });

  final List<List<WeeklySearchResult>> weekly;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Future<_Data?> _animesFuture;

  Future<_Data?> _getData() async {
    final weekly = await AnilistService.weekly();
    final groupedWeekly = <List<WeeklySearchResult>>{};
    bool isSameDay(a, b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    for (final item in weekly) {
      if (groupedWeekly.isEmpty ||
          !isSameDay(item.airingAt, groupedWeekly.last.first.airingAt)) {
        groupedWeekly.add([item]);
        continue;
      }

      groupedWeekly.last.add(item);
    }

    return _Data(weekly: groupedWeekly.toList());
  }

  @override
  void initState() {
    super.initState();
    _animesFuture = _getData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _animesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final topAnimes = snapshot.data;

        if (topAnimes == null) {
          return const Center(
            child: Text("No data"),
          );
        }

        return SafeArea(
          child: DefaultTabController(
            length: topAnimes.weekly.length,
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Discover"),
                bottom: TabBar(
                  isScrollable: true,
                  tabs: topAnimes.weekly.map((list) {
                    return Tab(
                      text:
                          "${DateFormat("EEEE, MMMM d, y").format(list.first.airingAt)} (${list.length})",
                    );
                  }).toList(),
                ),
              ),
              body: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: TabBarView(
                  children: topAnimes.weekly.map((list) {
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 120 / 150,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final anime = list[index].media;

                        return Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailsScreen(
                                    animeId: anime.id,
                                    malId: anime.malId,
                                    title: anime.titleUserPreferred,
                                    imageUrl: anime.coverImage,
                                    bannerImageUrl: anime.bannerImage,
                                    titleRomaji: anime.titleRomaji,
                                    totalEpisodes: anime.episodes,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Expanded(
                                  child: AnimeCard(
                                    anime: anime,
                                    width: 120,
                                    height: 150,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Text(
                                    anime.titleUserPreferred,
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
