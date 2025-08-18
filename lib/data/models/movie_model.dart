class MovieModel {
  final int streamId;
  final String name;
  final String streamType;
  final String streamIcon;
  final String? categoryId;
  final String? added;
  final String? releaseDate;
  final String? duration;
  final String? cast;
  final String? director;
  final String? description;
  final String? youtubeTrailer;
  final String? rating;
  final String containerExtension;

  final String? streamUrl;

  String getMovieUrl(String serverUrl, String username, String password) {
    if (streamUrl == null || streamUrl!.isEmpty) return '';

    if (streamUrl != null && streamUrl!.startsWith("http")) {
      return streamUrl!;
    }
    return 'http://$serverUrl/movie/$username/$password/$streamId.$containerExtension';
  }

  MovieModel({
    required this.streamId,
    required this.name,
    required this.streamType,
    required this.streamIcon,
    required this.containerExtension,
    this.categoryId,
    this.added,
    this.releaseDate,
    this.duration,
    this.cast,
    this.director,
    this.description,
    this.youtubeTrailer,
    this.rating,
    this.streamUrl,
  });

  factory MovieModel.fromJson(
    Map<String, dynamic> json,
    String serverUrl,
    String username,
    String password,
  ) {
    return MovieModel(
      streamId: json['stream_id'] ?? '',
      name: json['name'] ?? '',
      streamType: json['stream_type'] ?? '',
      streamIcon: json['stream_icon'] ?? '',
      containerExtension: json['container_extension'] ?? 'mkv',
      categoryId: json['category_id']?.toString(),
      added: json['added'],
      releaseDate: json['info']?['Release Date'],
      duration: json['info']?['duration'],
      cast: json['info']?['cast'],
      director: json['info']?['director'],
      description: json['info']?['plot'],
      youtubeTrailer: json['info']?['youtube_trailer'],
      rating: json['info']?['rating'],
      streamUrl:
          json['info']?['movie_data']?['stream_url'] ?? json['stream_url'],
    );
  }
}
