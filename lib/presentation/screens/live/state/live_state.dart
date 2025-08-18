import '../../../../data/models/channel_model.dart';

class LiveState {
  final List<Map<String, String>> categories;
  final List<ChannelModel> allChannels;
  final Map<String, int> channelCountByCategory;
  final String selectedCategoryId;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;

  LiveState({
    required this.categories,
    required this.allChannels,
    required this.channelCountByCategory,
    required this.selectedCategoryId,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.offset,
  });

  LiveState.initial()
      : categories = [],
        allChannels = [],
        channelCountByCategory = {},
        selectedCategoryId = 'all',
        isLoading = true,
        isLoadingMore = false,
        hasMore = true,
        offset = 0;

  LiveState copyWith({
    List<Map<String, String>>? categories,
    List<ChannelModel>? allChannels,
    Map<String, int>? channelCountByCategory,
    String? selectedCategoryId,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
  }) {
    return LiveState(
      categories: categories ?? this.categories,
      allChannels: allChannels ?? this.allChannels,
      channelCountByCategory:
          channelCountByCategory ?? this.channelCountByCategory,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
    );
  }
}
