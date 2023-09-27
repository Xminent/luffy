import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:luffy/api/anilist.dart";
import "package:luffy/screens/details.dart";

class SearchResultComponent extends StatelessWidget {
  const SearchResultComponent({
    super.key,
    required this.anime,
    this.score,
  });

  final SearchResult anime;
  final double? score;

  @override
  Widget build(BuildContext context) {
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
                // TODO: DetailsScreen should be notified when the ID is not from MAL.
                animeId: anime.id,
                malId: anime.malId,
                imageUrl: anime.coverImage,
                bannerImageUrl: anime.bannerImage,
                title: anime.titleUserPreferred,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              CachedNetworkImage(
                imageUrl: anime.coverImage,
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.surface,
                ),
                height: 100,
                width: 100,
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.titleUserPreferred,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    // const SizedBox(
                    //   height: 8,
                    // ),
                    // Text(
                    //   anime.synopsis,
                    //   maxLines: 3,
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
