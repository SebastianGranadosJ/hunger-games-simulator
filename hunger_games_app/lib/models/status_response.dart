import 'tribute.dart';

class StatusResponseModel {
  final int periodNumber;
  final String eventType;
  final List<TributeModel> aliveTributes;

  StatusResponseModel({
    required this.periodNumber,
    required this.eventType,
    required this.aliveTributes,
  });

  String get periodLabel {
    final type = eventType.toLowerCase();
    switch (type) {
      case 'bloodbath':
        return 'BLOODBATH';
      case 'day':
        return 'DAY $periodNumber';
      case 'night':
        return 'NIGHT $periodNumber';
      default:
        return eventType.toUpperCase();
    }
  }

  factory StatusResponseModel.fromJson(Map<String, dynamic> json) {
    return StatusResponseModel(
      periodNumber: json['period_number'] as int,
      eventType: json['event_type'] as String,
      aliveTributes: (json['alive_tributes'] as List<dynamic>)
          .map((e) => TributeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
