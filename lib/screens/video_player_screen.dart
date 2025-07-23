// lib/screens/video_player_screen.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // Core video player package
import 'package:chewie/chewie.dart'; // Provides UI controls for video player

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl; // The URL of the video to play

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController
      _videoPlayerController; // Controller for the video player
  ChewieController? _chewieController; // Controller for Chewie UI

  @override
  void initState() {
    super.initState();
    _initializePlayer(); // Initialize the video player when the screen loads
  }

  // Asynchronous function to initialize the video player
  Future<void> _initializePlayer() async {
    // Create a VideoPlayerController from the network URL
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    // Initialize the controller and wait for it to be ready
    await _videoPlayerController.initialize();

    // Create the ChewieController with the initialized video controller
    _createChewieController();

    // Rebuild the UI to display the video player
    setState(() {});
  }

  // Function to create the ChewieController
  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true, // Start playing automatically
      looping: false, // Do not loop the video
      // Custom error builder for Chewie
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Dispose of both controllers when the widget is removed from the tree
    _videoPlayerController.dispose();
    _chewieController
        ?.dispose(); // Use ?. to safely call dispose if controller is null
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
        centerTitle: true,
      ),
      body: Center(
        child: _chewieController != null &&
                _chewieController!.videoPlayerController.value.isInitialized
            ? AspectRatio(
                aspectRatio: _videoPlayerController
                    .value.aspectRatio, // Maintain video aspect ratio
                child: Chewie(
                    controller:
                        _chewieController!), // Display the Chewie player
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(), // Show loading indicator
                  SizedBox(height: 20),
                  Text('Loading video...'), // Loading text
                ],
              ),
      ),
    );
  }
}
