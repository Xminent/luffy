import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:luffy/api/anilist.dart";
import "package:luffy/screens/details.dart";

class RelationCard extends StatelessWidget {
  const RelationCard({super.key, required this.relation});

  final Relation relation;

  Widget _buildTypeIcon(String mediaType) {
    switch (mediaType.toLowerCase()) {
      case "manga":
        return const Icon(
          Icons.menu_book,
          size: 16,
        );
      default:
        return const Icon(
          Icons.movie_filter,
          size: 16,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: SizedBox(
        width: 120,
        child: Column(
          children: [
            Flexible(
              flex: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: relation.coverImage,
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTypeIcon(relation.type),
                  const SizedBox(width: 8),
                  Text(
                    relation.relationType,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 2,
              child: Text(
                relation.titleUserPreferred,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DetailsScreen(
            animeId: relation.id,
            malId: relation.malId,
            title: relation.titleUserPreferred,
            imageUrl: relation.coverImage,
            bannerImageUrl: relation.bannerImage,
            titleRomaji: relation.titleRomaji,
            totalEpisodes: relation.episodes,
          ),
        ),
      ),
    );
  }
}
