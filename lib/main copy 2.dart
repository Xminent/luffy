// import "package:flutter/material.dart";
// import "package:media_kit/media_kit.dart";

// /// Provides [Player], [Media], [Playlist] etc.
// import "package:media_kit_video/media_kit_video.dart";

// /// Provides [VideoController] & [Video] etc.

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   MediaKit.ensureInitialized();
//   runApp(
//     const MaterialApp(home: MyScreen()),
//   );
// }

// class MyScreen extends StatefulWidget {
//   const MyScreen({Key? key}) : super(key: key);
//   @override
//   State<MyScreen> createState() => MyScreenState();
// }

// class MyScreenState extends State<MyScreen> {
//   /// Create a [Player].
//   final Player player = Player();

//   /// Store reference to the [VideoController].
//   VideoController? controller;

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() async {
//       /// Create a [VideoController] to show video output of the [Player].
//       controller = await VideoController.create(player);

//       /// Play any media source.
//       await player.open(
//         Media(
//           "https://crunchy.animeflix.live/https://ta-005.agetcdn.com/1ab5d45273a9183bebb58eb74d5722d8ea6384f350caf008f08cf018f1f0566d0cb82a2a799830d1af97cd3f4b6a9a81ef3aed2fb783292b1abcf1b8560a1d1aa308008b88420298522a9f761e5aa1024fbe74e5aa853cfc933cd1219327d1232e91847a185021b184c027f97ae732b3708ee6beb80ba5db6628ced43f1196fe/027e9529af2b06fe7b4f47e507a787eb/ep.1.1677593055.m3u8",
//         ),
//       );
//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     Future.microtask(() async {
//       /// Release allocated resources back to the system.
//       await controller?.dispose();
//       await player.dispose();
//     });
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     /// Use [Video] widget to display the output.
//     return Video(
//       /// Pass the [controller].
//       controller: controller,
//     );
//   }
// }
