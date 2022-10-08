import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:immersion_reader/providers/local_asset_server_provider.dart';
import 'package:immersion_reader/providers/vocabulary_list_provider.dart';
import './reader.dart';
import 'pages/settings/settings_page.dart';
import 'pages/search.dart';
import 'pages/vocabulary_list/vocabulary_list_page.dart';

void main() {
  runApp(const CupertinoApp(home: App()));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final ValueNotifier<bool> _notifier = ValueNotifier(false);
  LocalAssetsServerProvider? localAssetsServerProvider;
  VocabularyListProvider? vocabularyListProvider;

  Future<void> setupProviders() async {
    localAssetsServerProvider = await LocalAssetsServerProvider.create();
    vocabularyListProvider = await VocabularyListProvider.create();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    setupProviders();
  }

  void handleSwitchNavigation(int index) async {
    if (index == 0 && vocabularyListProvider != null) {
      await vocabularyListProvider!.getVocabularyList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        onTap: handleSwitchNavigation,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.star_fill),
            label: 'My Words',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book),
            label: 'Reader',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            return buildBody(index);
          },
        );
      },
    ));
  }

  Widget buildBody(int index) {
    switch (index) {
      case 0:
        return (vocabularyListProvider != null)
            ? ValueListenableBuilder(
                valueListenable: _notifier,
                builder: (context, val, child) => VocabularyListPage(
                    vocabularyListProvider: vocabularyListProvider!,
                    notifier: _notifier))
            : const CupertinoActivityIndicator(
                animating: true,
                radius: 24,
              );
      case 1:
        if (localAssetsServerProvider != null) {
          return Reader(localAssetsServer: localAssetsServerProvider!.server);
        } else {
          return const CupertinoActivityIndicator(
            animating: true,
            radius: 24,
          );
        }
      case 2:
        return const Search();
      case 3:
        return const SettingsPage();
    }
    return const Text('no page');
  }
}
