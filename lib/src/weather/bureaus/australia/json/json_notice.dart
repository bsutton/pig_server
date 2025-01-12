class JSONNotice {
  final String? copyright;
  final String? copyrightUrl;
  final String? disclaimerUrl;
  final String? feedbackUrl;

  JSONNotice({
    this.copyright,
    this.copyrightUrl,
    this.disclaimerUrl,
    this.feedbackUrl,
  });

  /// Factory constructor to create a `JSONNotice` from a JSON map.
  factory JSONNotice.fromJson(Map<String, dynamic> json) {
    return JSONNotice(
      copyright: json['copyright'] as String?,
      copyrightUrl: json['copyright_url'] as String?,
      disclaimerUrl: json['disclaimer_url'] as String?,
      feedbackUrl: json['feedback_url'] as String?,
    );
  }

  /// Converts the `JSONNotice` instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'copyright': copyright,
      'copyright_url': copyrightUrl,
      'disclaimer_url': disclaimerUrl,
      'feedback_url': feedbackUrl,
    };
  }

  @override
  String toString() {
    return '''
JSONNotice {
  copyright: $copyright,
  copyrightUrl: $copyrightUrl,
  disclaimerUrl: $disclaimerUrl,
  feedbackUrl: $feedbackUrl
}
''';
  }
}
