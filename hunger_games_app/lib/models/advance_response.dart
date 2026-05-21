import 'tribute.dart';
import 'event.dart';

class AdvanceResponseModel {
  final EventBatchModel batch;
  final bool isOver;
  final TributeModel? winner;

  AdvanceResponseModel({
    required this.batch,
    required this.isOver,
    this.winner,
  });

  factory AdvanceResponseModel.fromJson(Map<String, dynamic> json) {
    return AdvanceResponseModel(
      batch: EventBatchModel.fromJson(json['batch'] as Map<String, dynamic>),
      isOver: json['is_over'] as bool,
      winner: json['winner'] != null
          ? TributeModel.fromJson(json['winner'] as Map<String, dynamic>)
          : null,
    );
  }
}
