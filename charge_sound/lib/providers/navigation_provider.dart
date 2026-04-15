import 'package:flutter_riverpod/legacy.dart';

/// Bottom navigation index: 0 Home, 1 Sounds, 2 Record, 3 Settings.
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// Sound Library inner [TabBar] index: 0 My Files, 1 Meme Sounds, 2 Recordings.
final soundLibraryTabProvider = StateProvider<int>((ref) => 1);

final homeEventSearchProvider = StateProvider<String>((ref) => '');
