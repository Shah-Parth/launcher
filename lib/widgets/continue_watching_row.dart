import 'package:flauncher/models/watch_next_program.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ContinueWatchingRow extends StatelessWidget {
  const ContinueWatchingRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);
    if (!settingsService.showContinueWatching) {
      return const SizedBox.shrink();
    }

    return Consumer2<WatchNextService, AppsService>(
      builder: (context, watchNextService, appsService, _) {
        final List<WatchNextProgram> programs = watchNextService.programs;
        if (programs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  "Continue Watching",
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    shadows: [
                      const Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 1),
                        blurRadius: 8,
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 150, // Height of card + padding
                child: ListView.builder(
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.all(8),
                  scrollDirection: Axis.horizontal,
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: WatchNextCard(
                        program: program,
                        appsService: appsService,
                        watchNextService: watchNextService,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WatchNextCard extends StatefulWidget {
  final WatchNextProgram program;
  final AppsService appsService;
  final WatchNextService watchNextService;

  const WatchNextCard({
    Key? key,
    required this.program,
    required this.appsService,
    required this.watchNextService,
  }) : super(key: key);

  @override
  State<WatchNextCard> createState() => _WatchNextCardState();
}

class _WatchNextCardState extends State<WatchNextCard> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _focused = _focusNode.hasFocus;
      });
      if (_focusNode.hasFocus) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 100),
        );
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onPressed() {
    widget.watchNextService.launch(widget.program);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsService = Provider.of<SettingsService>(context, listen: false);

    // Accent color
    final accentColor = settingsService.accentColor;

    // Dimensions
    const double cardWidth = 220;
    const double cardHeight = 124; // 16:9 ratio approximately

    // Progress percentage
    double progress = 0;
    if (widget.program.duration > 0 && widget.program.playbackPosition >= 0) {
      progress = widget.program.playbackPosition / widget.program.duration;
      if (progress > 1.0) progress = 1.0;
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            _onPressed();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            Actions.invoke(context, const MoveFocusToSettingsIntent());
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _onPressed,
        child: AnimatedScale(
          scale: _focused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused ? accentColor : Colors.white24,
                width: _focused ? 3.0 : 1.0,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  // Poster background
                  Positioned.fill(
                    child: widget.program.posterBytes != null
                        ? Image.memory(
                            widget.program.posterBytes!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: Icon(
                                Icons.play_arrow,
                                size: 48,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                  ),
                  // App icon branding overlay (small icon top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FutureBuilder<dynamic>(
                      future: widget.appsService.getAppIcon(widget.program.packageName),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Image.memory(snapshot.data),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  // Title and progress info overlay (bottom)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.program.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                const Shadow(
                                  color: Colors.black87,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                )
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.program.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                widget.program.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (progress > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                  minHeight: 3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
