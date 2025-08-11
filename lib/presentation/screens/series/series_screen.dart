import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/presentation/screens/series/viewmodel/series_viewmodel.dart';
import '../../../data/models/series_model.dart';
import 'widgets/series_app_bar.dart';
import 'widgets/series_category_list.dart';

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, String>>> _categoriesFuture;
  final TextEditingController _searchController = TextEditingController();
  Future<List<SeriesModel>>? _searchResults;
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _categoriesFuture = ref.read(seriesViewModelProvider).getSeriesCategories();
  }

  void _onSearch(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = null;
          _isSearching = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _isSearching = true;
        _searchResults = ref
            .read(seriesViewModelProvider)
            .searchSeries(trimmedQuery);
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    if (mounted) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: SeriesAppBar(
        searchController: _searchController,
        isSearching: _isSearching,
        onClear: _clearSearch,
        onSearch: _onSearch,
      ),
      body: SafeArea(
        child: _isSearching && _searchResults != null
            ? FutureBuilder<List<SeriesModel>>(
                future: _searchResults,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'حدث خطأ أثناء البحث',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  final results = snapshot.data ?? const <SeriesModel>[];
                  if (results.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد نتائج',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: SizedBox.shrink(),
                  );
                },
              )
            : FutureBuilder<List<Map<String, String>>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'فشل تحميل التصنيفات',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  final categories =
                      snapshot.data ?? const <Map<String, String>>[];
                  return SeriesCategoryList(categories: categories);
                },
              ),
      ),
    );
  }
}
