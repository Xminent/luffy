import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:luffy/api/anilist.dart";

class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.character,
  });

  final Character character;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Flexible(
            flex: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: character.image ?? "https://via.placeholder.com/150",
                errorWidget: (context, url, error) => const Icon(
                  Icons.error,
                  color: Colors.red,
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SizedBox(
              width: 150,
              child: Text(
                character.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Flexible(
            child: Text(
              character.role,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }
}
