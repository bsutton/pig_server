import 'json_header.dart';
import 'json_notice.dart';
import 'json_observation.dart';

class JSONObservations {
  JSONObservations({
    required this.notice,
    required this.header,
    required this.observations,
  });

  factory JSONObservations.fromJson(Map<String, dynamic> json) =>
      JSONObservations(
        notice: (json['notice'] as List<dynamic>?)
                ?.map(
                    (item) => JSONNotice.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        header: (json['header'] as List<dynamic>?)
                ?.map(
                    (item) => JSONHeader.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        observations: (json['data'] as List<dynamic>?)
                ?.map((item) =>
                    JSONObservation.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
      );
  final List<JSONNotice> notice;
  final List<JSONHeader> header;
  final List<JSONObservation> observations;

  Map<String, dynamic> toJson() => {
        'notice': notice.map((item) => item.toJson()).toList(),
        'header': header.map((item) => item.toJson()).toList(),
        'data': observations.map((item) => item.toJson()).toList(),
      };

  @override
  String toString() => '''
JSONObservations {
  notice: $notice,
  header: $header,
  observations: $observations,
}
''';
}
