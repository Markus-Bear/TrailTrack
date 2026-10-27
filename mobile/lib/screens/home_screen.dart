import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../services/trail_api.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// The app's main screen: the Map, Search and Profile tabs with a bottom
/// navigation bar. Every tab stays alive while another is shown, so switching
/// back finds it as it was.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.api, this.location});

  final TrailApi? api;
  final LocationService? location;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _mapTab = 0;
  static const _searchTab = 1;

  late final TrailApi _api = widget.api ?? TrailApi();
  int _tab = _mapTab;

  void _show(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          MapScreen(
            api: _api,
            location: widget.location,
            onSearch: () => _show(_searchTab),
          ),
          SearchScreen(api: _api, location: widget.location, autofocus: false),
          ProfileScreen(onLoggedOut: () => _show(_mapTab)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _show,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
