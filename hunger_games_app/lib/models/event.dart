class ItemEventModel {
  final String tributeId;
  final String itemName;

  ItemEventModel({required this.tributeId, required this.itemName});

  factory ItemEventModel.fromJson(Map<String, dynamic> json) {
    return ItemEventModel(
      tributeId: json['tribute_id'] as String,
      itemName: json['item_name'] as String,
    );
  }
}

class StateNoteModel {
  final String tributeId;
  final String note;

  StateNoteModel({required this.tributeId, required this.note});

  factory StateNoteModel.fromJson(Map<String, dynamic> json) {
    return StateNoteModel(
      tributeId: json['tribute_id'] as String,
      note: json['note'] as String,
    );
  }
}

class EventModel {
  final List<String> relatedTributes;
  final String eventType;
  final int periodNumber;
  final String narrative;
  final List<String>? killedTributeId;
  final List<String>? killerTributeId;
  final List<ItemEventModel> itemsAdded;
  final List<ItemEventModel> itemsRemoved;
  final List<StateNoteModel> stateNotes;

  EventModel({
    required this.relatedTributes,
    required this.eventType,
    required this.periodNumber,
    required this.narrative,
    this.killedTributeId,
    this.killerTributeId,
    required this.itemsAdded,
    required this.itemsRemoved,
    required this.stateNotes,
  });

  bool get isDeath =>
      killedTributeId != null && killedTributeId!.isNotEmpty;

  String get periodLabel {
    switch (eventType) {
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

  factory EventModel.fromJson(Map<String, dynamic> json) {
    List<String>? parseStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        final list = value.map((e) => e.toString()).toList();
        return list.isEmpty ? null : list;
      }
      return null;
    }

    // Handle event_type that might come as enum value or string
    final rawType = json['event_type'] as String;
    final eventType = rawType.toLowerCase().replaceAll('eventtype.', '');

    return EventModel(
      relatedTributes: (json['related_tributes'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      eventType: eventType,
      periodNumber: json['period_number'] as int,
      narrative: json['narrative'] as String,
      killedTributeId: parseStringList(json['killed_tribute_id']),
      killerTributeId: parseStringList(json['killer_tribute_id']),
      itemsAdded: (json['items_added'] as List<dynamic>)
          .map((e) => ItemEventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemsRemoved: (json['items_removed'] as List<dynamic>)
          .map((e) => ItemEventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      stateNotes: (json['state_notes'] as List<dynamic>)
          .map((e) => StateNoteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EventBatchModel {
  final List<EventModel> events;

  EventBatchModel({required this.events});

  factory EventBatchModel.fromJson(Map<String, dynamic> json) {
    return EventBatchModel(
      events: (json['events'] as List<dynamic>)
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
