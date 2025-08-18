class ChannelModel {
  final int streamId;
  final String name;
  final String streamIcon;
  final String streamType;
  final String containerExtension;
  final String serverUrl;
  final String username;
  final String password;

  final String categoryId;

  ChannelModel({
    required this.streamId,
    required this.name,
    required this.streamIcon,
    required this.streamType,
    required this.containerExtension,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.categoryId,
  });

  factory ChannelModel.fromJson(
    Map<String, dynamic> json,
    String serverUrl,
    String username,
    String password,
  ) {
    return ChannelModel(
      streamId: json['stream_id'],
      name: json['name'] ?? '',
      streamIcon: json['stream_icon'] ?? '',
      streamType: json['stream_type'] ?? '',
      containerExtension: json['container_extension'] ?? 'ts',
      serverUrl: serverUrl,
      username: username,
      password: password,
      categoryId: json['category_id']?.toString() ?? '',
    );
  }

  String get streamUrl =>
      '$serverUrl/live/$username/$password/$streamId.$containerExtension';
}
