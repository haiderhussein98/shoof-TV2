import 'package:flutter/material.dart';
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

  Future<void> _refresh() async {
    final vm = ref.read(liveViewModelProvider.notifier);
    final s = ref.read(liveViewModelProvider);
    if ((s.selectedCategoryId).isNotEmpty) {
      await vm.fetchChannelsByCategory(s.selectedCategoryId);
    } else {
      await vm.initialize();
    }
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AnimatedGradientBackground(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GestureDetector(
                      key: const ValueKey('content'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: Padding(
                        padding: context.pagePadding,
                        child: Column(
                          children: [
                            // صندوق البحث + التصنيفات بشكل بطاقة عادية
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.fromLTRB(12, 10, 12, 12),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .08),
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  LiveSearchBar(
                                    controller: _searchController,
                                    searchQuery: _searchQuery,
                                  ),
                                  if (state.categories.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    LiveCategoriesBar(
                                      categories: state.categories,
                                      controller: _categoryScrollController,
                                      selectedCategoryId:
                                          state.selectedCategoryId,
                                      keys: _categoryKeys,
                                      countMap: state.channelCountByCategory,
                                      onSelect: _fetchChannels,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _refresh,
                                color: Colors.redAccent,
                                backgroundColor: Colors.black87,
                                child: Scrollbar(
                                  controller: _scrollController,
                                  thumbVisibility: true,
                                  radius: const Radius.circular(12),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: state.isLoadingMore ? 0.85 : 1.0,
                                    child: LiveChannelsGrid(
                                      channels: state.allChannels,
                                      scrollController: _scrollController,
                                      bottomInset: bottomInset,
                                      searchQuery: _searchQuery,
                                      onTap: _navigateToPlayer,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (state.isLoadingMore)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'جاري تحميل المزيد...',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// خلفية متدرجة متحركة هادئة
class _AnimatedGradientBackground extends StatefulWidget {
  const _AnimatedGradientBackground();

  @override
  State<_AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<_AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))
        ..repeat(reverse: true);
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: Curves.easeInOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (_, __) {
        final stops = [0.0, 0.5 + 0.2 * _t.value, 1.0];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: stops,
              colors: const [
                Color(0xFF0D0D0F), // أسود مزرق
                Color(0xFF16161A), // رمادي داكن
                Color(0xFF1F1B24), // بنفسجي داكن خفيف
              ],
            ),
          ),
        );
      },
    );
  }
}
