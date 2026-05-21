import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';
import '../models/event.dart';
import '../models/tribute.dart';
import 'event_tile.dart';

enum StatsFilter { all, kills, byTribute, byPeriod }

class StatisticsPanel extends StatefulWidget {
  final List<EventModel> events;
  final Map<String, TributeModel> allTributesById;
  final Map<String, String> tributeImages;

  const StatisticsPanel({
    super.key,
    required this.events,
    required this.allTributesById,
    required this.tributeImages,
  });

  @override
  State<StatisticsPanel> createState() => _StatisticsPanelState();
}

class _StatisticsPanelState extends State<StatisticsPanel> {
  StatsFilter _filter = StatsFilter.all;

  // By tribute filter
  String? _selectedTributeId;

  // By period filter
  final _periodController = TextEditingController();
  String _periodEventType = 'all';

  @override
  void dispose() {
    _periodController.dispose();
    super.dispose();
  }

  List<EventModel> get _filteredEvents {
    switch (_filter) {
      case StatsFilter.all:
        return widget.events;

      case StatsFilter.kills:
        return widget.events.where((e) => e.isDeath).toList();

      case StatsFilter.byTribute:
        if (_selectedTributeId == null) return [];
        return widget.events
            .where((e) =>
                e.relatedTributes.contains(_selectedTributeId))
            .toList();

      case StatsFilter.byPeriod:
        var filtered = widget.events;
        final periodText = _periodController.text.trim();
        if (periodText.isNotEmpty) {
          final num = int.tryParse(periodText);
          if (num != null) {
            filtered = filtered
                .where((e) => e.periodNumber == num)
                .toList();
          }
        }
        if (_periodEventType != 'all') {
          filtered = filtered
              .where((e) => e.eventType == _periodEventType)
              .toList();
        }
        return filtered;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.goldBorder)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'STATISTICS',
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filtered.length} event${filtered.length != 1 ? "s" : ""}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.border, height: 1),

              // Filter tabs
              _buildFilterTabs(),

              // Extra filter controls
              if (_filter == StatsFilter.byTribute)
                _buildTributeSelector(),
              if (_filter == StatsFilter.byPeriod)
                _buildPeriodSelector(),

              const Divider(color: AppColors.border, height: 1),

              // Event list
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => EventTile(
                          event: filtered[i],
                          allTributesById: widget.allTributesById,
                          tributeImages: widget.tributeImages,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _FilterChip(
            label: 'ALL EVENTS',
            selected: _filter == StatsFilter.all,
            onTap: () => setState(() => _filter = StatsFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '☠ KILLS ONLY',
            selected: _filter == StatsFilter.kills,
            onTap: () => setState(() => _filter = StatsFilter.kills),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'BY TRIBUTE',
            selected: _filter == StatsFilter.byTribute,
            onTap: () =>
                setState(() => _filter = StatsFilter.byTribute),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'BY PERIOD',
            selected: _filter == StatsFilter.byPeriod,
            onTap: () =>
                setState(() => _filter = StatsFilter.byPeriod),
          ),
        ],
      ),
    );
  }

  Widget _buildTributeSelector() {
    final tributes = widget.allTributesById.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Select tribute',
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        child: DropdownButton<String>(
          value: _selectedTributeId,
          dropdownColor: AppColors.surfaceVariant,
          isExpanded: true,
          underline: const SizedBox(),
          style: const TextStyle(color: AppColors.offWhite, fontSize: 14),
          hint: const Text('— choose —',
              style: TextStyle(color: AppColors.muted, fontSize: 14)),
          items: tributes.map((t) {
            return DropdownMenuItem(
              value: t.idString,
              child: Row(
                children: [
                  Text(t.name),
                  const SizedBox(width: 8),
                  if (!t.isAlive)
                    const Text(
                      '☠',
                      style:
                          TextStyle(color: AppColors.deathRed, fontSize: 12),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedTributeId = v),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _periodController,
              style:
                  const TextStyle(color: AppColors.offWhite, fontSize: 14),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Period number (0 = Bloodbath)',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Type',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: DropdownButton<String>(
                value: _periodEventType,
                dropdownColor: AppColors.surfaceVariant,
                isExpanded: true,
                underline: const SizedBox(),
                style: const TextStyle(
                    color: AppColors.offWhite, fontSize: 13),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All types')),
                  DropdownMenuItem(
                      value: 'bloodbath', child: Text('Bloodbath')),
                  DropdownMenuItem(value: 'day', child: Text('Day')),
                  DropdownMenuItem(value: 'night', child: Text('Night')),
                ],
                onChanged: (v) =>
                    setState(() => _periodEventType = v ?? 'all'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty,
              color: AppColors.muted, size: 32),
          const SizedBox(height: 12),
          Text(
            'No events match this filter',
            style: GoogleFonts.cinzel(
              fontSize: 12,
              color: AppColors.muted,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.gold : AppColors.surfaceVariant,
          border: Border.all(
            color:
                selected ? AppColors.gold : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.background
                : AppColors.muted,
            fontSize: 11,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
