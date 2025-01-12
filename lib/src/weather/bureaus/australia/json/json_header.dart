class JSONHeader {
  final String? refreshMessage;
  final String? id;
  final String? mainID;
  final String? name;
  final String? stateTimeZone;
  final String? timeZone;
  final String? productName;
  final String? state;

  JSONHeader({
    this.refreshMessage,
    this.id,
    this.mainID,
    this.name,
    this.stateTimeZone,
    this.timeZone,
    this.productName,
    this.state,
  });

  /// Factory constructor to create a `JSONHeader` from a map.
  factory JSONHeader.fromJson(Map<String, dynamic> json) {
    return JSONHeader(
      refreshMessage: json['refresh_message'] as String?,
      id: json['ID'] as String?,
      mainID: json['main_ID'] as String?,
      name: json['name'] as String?,
      stateTimeZone: json['state_time_zone'] as String?,
      timeZone: json['time_zone'] as String?,
      productName: json['product_name'] as String?,
      state: json['state'] as String?,
    );
  }

  /// Converts the `JSONHeader` instance to a map.
  Map<String, dynamic> toJson() {
    return {
      'refresh_message': refreshMessage,
      'ID': id,
      'main_ID': mainID,
      'name': name,
      'state_time_zone': stateTimeZone,
      'time_zone': timeZone,
      'product_name': productName,
      'state': state,
    };
  }

  @override
  String toString() {
    return '''
JSONHeader {
  refreshMessage: $refreshMessage,
  id: $id,
  mainID: $mainID,
  name: $name,
  stateTimeZone: $stateTimeZone,
  timeZone: $timeZone,
  productName: $productName,
  state: $state
}
''';
  }
}
