import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/domain/providers/live_providers.dart';
import '../../../../data/models/channel_model.dart';
import '../state/live_state.dart';

class LiveViewModel extends StateNotifier<LiveState> {
  final Ref ref;
  LiveViewModel(this.ref) : super(LiveState.initial());

  Future<void> initialize() async {
    try {
      final api = ref.read(liveServiceProvider);
      final cats = await api.getLiveCategories();
      final allChannels = await api.getLiveChannels(offset: 0, limit: 5000);

      final countMap = <String, int>{};
      for (final channel in allChannels) {
        final id = channel.categoryId;
        countMap[id] = (countMap[id] ?? 0) + 1;
      }

      final allOption = {
        'id': 'all',
        'name': 'عرض الكل (${allChannels.length})',
      };

      state = state.copyWith(
        categories: [allOption, ...cats],
        channelCountByCategory: countMap,
        selectedCategoryId: 'all',
        offset: allChannels.length,
        allChannels: allChannels,
        hasMore: false,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMoreChannels() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final api = ref.read(liveServiceProvider);
      final categoryId = state.selectedCategoryId;
      List<ChannelModel> channels;

      if (categoryId == 'all') {
        channels = await api.getLiveChannels(offset: state.offset, limit: 100);
      } else {
        channels = await api.getLiveChannelsByCategory(
          categoryId,
          offset: state.offset,
          limit: 100,
        );
      }

      final updatedChannels = [...state.allChannels, ...channels];
      final hasMore = channels.length == 100;

      state = state.copyWith(
        allChannels: updatedChannels,
        offset: state.offset + channels.length,
        isLoadingMore: false,
        hasMore: hasMore,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false, hasMore: false);
    }
  }

  Future<void> fetchChannelsByCategory(String categoryId) async {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      offset: 0,
      allChannels: [],
      hasMore: true,
      isLoading: true,
    );

    await loadMoreChannels();
    state = state.copyWith(isLoading: false);
  }

  Future<void> fetchAllChannelsForSearch() async {
    if (state.allChannels.length >= 5000) return;
    try {
      final api = ref.read(liveServiceProvider);
      final allChannels = await api.getLiveChannels(offset: 0, limit: 5000);

      state = state.copyWith(
        allChannels: allChannels,
        offset: allChannels.length,
        hasMore: false,
      );
    } catch (_) {}
  }
}

final liveViewModelProvider = StateNotifierProvider<LiveViewModel, LiveState>((
  ref,
) {
  return LiveViewModel(ref);
});
