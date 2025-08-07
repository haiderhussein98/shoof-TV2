import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_iptv/presentation/screens/series/viewmodel/series_viewmodel.dart';
import '../../../data/models/series_model.dart';
import 'widgets/series_app_bar.dart';
import 'widgets/series_search_results_grid.dart';
import 'widgets/series_category_list.dart';

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  late Future<List<Map<String, String>>> _categoriesFuture;
  final TextEditingController _searchController = TextEditingController();
  Future<List<SeriesModel>>? _searchResults;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ref.read(seriesViewModelProvider).getSeriesCategories();
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
          .read(seriesViewModelProvider)
          .searchSeries(trimmedQuery);
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
      appBar: SeriesAppBar(
        searchController: _searchController,
        isSearching: _isSearching,
        onClear: _clearSearch,
        onSearch: _onSearch,
      ),
      body: _isSearching && _searchResults != null
          ? FutureBuilder<List<SeriesModel>>(
              future: _searchResults,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final results = snapshot.data!;
                if (results.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد نتائج',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return SeriesSearchResultsGrid(
                  results: results,
                  screenWidth: screenWidth,
                );
              },
            )
          : FutureBuilder<List<Map<String, String>>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data!;
                return SeriesCategoryList(
                  categories: categories,
                  screenWidth: screenWidth,
                );
              },
            ),
    );
  }
}
