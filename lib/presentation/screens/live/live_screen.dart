﻿import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shoof_tv/domain/providers/live_providers.dart';
import 'package:shoof_tv/presentation/screens/live/live_player_screen.dart';
import 'package:shoof_tv/presentation/screens/live/viewmodel/live_viewmodel.dart';
import 'package:shoof_tv/data/models/channel_model.dart';
import 'widgets/live_app_bar.dart';
import 'widgets/live_search_bar.dart';
import 'widgets/live_categories_bar.dart';
import 'widgets/live_channels_grid.dart';
import 'package:shoof_tv/core/responsive.dart';

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _scrollController = ScrollController();

  List<GlobalKey> _categoryKeys = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveViewModelProvider.notifier).initialize();
    });
  }

  void _onScroll() {
    final vm = ref.read(liveViewModelProvider.notifier);
    final state = ref.read(liveViewModelProvider);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !state.isLoadingMore &&
        state.hasMore &&
        !state.isLoading) {
      vm.loadMoreChannels();
    }
  }

  Future<void> _fetchChannels(String categoryId) async {
    await ref
        .read(liveViewModelProvider.notifier)
        .fetchChannelsByCategory(categoryId);

    final index = ref
        .read(liveViewModelProvider)
        .categories
        .indexWhere((cat) => cat['id'] == categoryId);

    if (index != -1 && _categoryKeys.length > index) {
      final key = _categoryKeys[index];
      final ctx = key.currentContext;
      if (ctx != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final itemCtx = key.currentContext;
          if (mounted && itemCtx != null && itemCtx.mounted) {
            Scrollable.ensureVisible(
              itemCtx,
              duration: const Duration(milliseconds: 400),
              alignment: 0.5,
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
  }

  void _navigateToPlayer(ChannelModel channel) {
    final api = ref.read(liveServiceProvider);
    if (!mounted) return;
    Navigator.of(context).push(
      platformPageRoute(
        context: context,
        builder: (_) => LivePlayerScreen(
          serverUrl: api.serverUrl,
          username: api.username,
          password: api.password,
          streamId: channel.streamId,
          title: channel.name,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    _categoryScrollController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveViewModelProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (_categoryKeys.length != state.categories.length) {
      _categoryKeys = List.generate(
        state.categories.length,
        (_) => GlobalKey(),
      );
    }

    return PlatformScaffold(
      appBar: LiveAppBar(),
      backgroundColor: Colors.black,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Padding(
                padding: context.pagePadding,
                child: Column(
                  children: [
                    LiveSearchBar(
                      controller: _searchController,
                      searchQuery: _searchQuery,
                    ),
                    if (state.categories.isNotEmpty)
                      LiveCategoriesBar(
                        categories: state.categories,
                        controller: _categoryScrollController,
                        selectedCategoryId: state.selectedCategoryId,
                        keys: _categoryKeys,
                        countMap: state.channelCountByCategory,
                        onSelect: _fetchChannels,
                      ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: LiveChannelsGrid(
                        channels: state.allChannels,
                        scrollController: _scrollController,
                        bottomInset: bottomInset,
                        searchQuery: _searchQuery,
                        onTap: _navigateToPlayer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
