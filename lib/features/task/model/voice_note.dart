class VoiceNote {
  final String? url;
  final int? durationSeconds;

  const VoiceNote({this.url, this.durationSeconds});

  factory VoiceNote.fromJson(Map<String, dynamic> json) => VoiceNote(
    url: json['url'] as String?,
    durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'url': url,
    'durationSeconds': durationSeconds,
  };
}