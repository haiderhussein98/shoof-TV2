class SeriesModel {
  final int seriesId;
  final String name;
  final String cover;
  final String? categoryId;
  final String? plot;
  final String? cast;
  final String? director;
  final String? rating;
  final String? youtubeTrailer;
  final String? releaseDate;
  final String? genre;
  SeriesModel({
    required this.seriesId,
    required this.name,
    required this.cover,
    this.categoryId,
    this.plot,
    this.cast,
    this.director,
    this.rating,
    this.youtubeTrailer,
    this.releaseDate,
    this.genre,
  });

  factory SeriesModel.fromJson(
    Map<String, dynamic> json,
    String serverUrl,
    String username,
    String password,
  ) {
    return SeriesModel(
      seriesId: json['series_id'],
      name: json['name'] ?? '',
      cover: json['cover'] ?? '',
      categoryId: json['category_id']?.toString(),
      plot: json['plot'],
      cast: json['cast'],
      director: json['director'],
      rating: json['rating'],
      youtubeTrailer: json['youtube_trailer'],
      releaseDate: json['release_date'],
      genre: json['genre'],
    );
  }

  String getEpisodeUrl(
    String serverUrl,
    String username,
    String password,
    int episodeId,
  ) {
    return "$serverUrl/series/$username/$password/$episodeId.mkv";
  }
}

