import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:luffy/api/mal.dart";
import "package:luffy/screens/details.dart";

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  late Future<List<TopAnimeResult>?> _topAnimesFuture;

  @override
  void initState() {
    super.initState();
    _topAnimesFuture = MalService.getTopAnimes();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Discover"),
        ),
        body: FutureBuilder(
          future: _topAnimesFuture,
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

            return Container(
              color: Theme.of(context).colorScheme.background,
              child: ListView.builder(
                itemCount: topAnimes.length,
                itemBuilder: (context, index) {
                  final anime = topAnimes[index];

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      splashColor: Colors.grey,
                      splashFactory: InkRipple.splashFactory,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsScreen(
                              animeId: anime.id.toString(),
                              title: anime.title,
                              imageUrl: anime.imageUrl,
                              type: anime.type,
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: CachedNetworkImage(
                          imageUrl: anime.imageUrl,
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          height: 100,
                          width: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(anime.title),
                        subtitle: Text(animeTypeToStr(anime.type)),
                        trailing: Text(
                          "${anime.score}",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
