import "package:flutter/material.dart";
import "package:luffy/screens/discover.dart";
import "package:luffy/screens/home.dart";
import "package:luffy/screens/search.dart";
import "package:luffy/screens/search_sources.dart";

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;

  final List<Widget> _tabs = [
    const HomeScreen(),
    const DiscoverScreen(),
    const SearchScreen(),
    const SearchScreenSources()
  ];

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length, // number of tabs
      vsync: this,
    );
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        physics:
            const NeverScrollableScrollPhysics(), // disable swiping between tabs
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        currentIndex: _currentIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          _tabController.animateTo(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: "Discover",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Search",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tv),
            label: "Search All",
          ),
        ],
      ),
    );
  }
}

      // body: Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: [
      //       const Text(
      //         'I have a huge penis!',
      //         style: TextStyle(fontSize: 24),
      //       ),
      //       const SizedBox(height: 20),
      //       ElevatedButton(
      //         onPressed: () => Navigator.pushNamed(context, '/details'),
      //         child: const Text('About'),
      //       ),
      //       const SizedBox(height: 20),
      //       ElevatedButton(
      //         onPressed: () => Navigator.pushNamed(context, '/login'),
      //         child: const Text('Login'),
      //       ),
      //     ],
      //   ),
      // ),
