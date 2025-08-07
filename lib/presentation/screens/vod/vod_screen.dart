import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_iptv/data/models/movie_model.dart.dart';
import 'package:shoof_iptv/domain/providers/vod_providers.dart';
import 'package:shoof_iptv/presentation/screens/vod/viewmodel/vod_viewmodel.dart';
import 'package:shoof_iptv/presentation/screens/vod/widgets/vod_app_bar.dart';
import 'package:shoof_iptv/presentation/screens/vod/widgets/vod_search_results_grid.dart';
import 'package:shoof_iptv/presentation/screens/vod/widgets/vod_category_list.dart';

class VodScreen extends ConsumerStatefulWidget {
  const VodScreen({super.key});

  @override
  ConsumerState<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends ConsumerState<VodScreen> {
  late Future<List<Map<String, String>>> _categoriesFuture;
  final TextEditingController _searchController = TextEditingController();
  Future<List<MovieModel>>? _searchResults;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ref.read(vodViewModelProvider).getVodCategories();
  }

  void _onSearch(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = ref
          .read(vodServiceProvider)
          .getVOD(offset: 0, limit: 300, searchQuery: trimmedQuery);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = null;
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: VodAppBar(
        controller: _searchController,
        isSearching: _isSearching,
        onSearch: _onSearch,
        onClear: _clearSearch,
      ),
      body: _isSearching && _searchResults != null
          ? VodSearchResultsGrid(
              key: ValueKey(_searchController.text),
              searchResults: _searchResults!,
            )
          : VodCategoryList(
              categoriesFuture: _categoriesFuture,
              screenWidth: screenWidth,
            ),
    );
  }
}
