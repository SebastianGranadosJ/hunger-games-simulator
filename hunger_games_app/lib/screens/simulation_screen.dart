import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_theme.dart';
import '../models/event.dart';
import '../models/tribute.dart';
import '../models/status_response.dart';
import '../services/api_service.dart';
import '../widgets/event_tile.dart';
import '../widgets/period_recap_overlay.dart';
import '../widgets/tribute_card.dart';
import '../widgets/statistics_panel.dart';
import 'winner_screen.dart';

class SimulationScreen extends StatefulWidget {
  final Map<String, String> tributeImages;
  final StatusResponseModel initialStatus;

  const SimulationScreen({
    super.key,
    required this.tributeImages,
    required this.initialStatus,
  });

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final _api = ApiService.instance;
  final _scrollController = ScrollController();

  late StatusResponseModel _status;

  // All tributes ever seen, keyed by id string — used for name/image lookups
  final Map<String, TributeModel> _allTributesById = {};

  // All events from every advance (for statistics)
  final List<EventModel> _allEvents = [];

  // Events currently shown in the feed (revealed one-by-one)
  final List<EventModel> _displayedEvents = [];

  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    // Seed the tribute map from the initial status (all alive at start)
    for (final t in _status.aliveTributes) {
      _allTributesById[t.idString] = t;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _advance() async {
    if (_isAdvancing) return;
    setState(() => _isAdvancing = true);

    try {
      final response = await _api.advanceSimulation();
      final newEvents = response.batch.events;

      // Accumulate all events for statistics
      _allEvents.addAll(newEvents);

      // Reveal events one by one with dramatic delay
      for (final event in newEvents) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        setState(() => _displayedEvents.add(event));
        _scrollToBottom();
      }

      if (!mounted) return;

      // Determine the phase label from the batch (BLOODBATH / DAY N / NIGHT N)
      final phaseLabel =
          newEvents.isNotEmpty ? newEvents.first.periodLabel : '';

      // Collect all tributes that fell this phase
      final fallenIds = <String>{};
      for (final event in newEvents) {
        if (event.isDeath && event.killedTributeId != null) {
          fallenIds.addAll(event.killedTributeId!);
        }
      }
      final fallen = fallenIds
          .map((id) => _allTributesById[id])
          .whereType<TributeModel>()
          .toList();

      // Show the death recap for this phase (bloodbath / day / night)
      // — shown before the winner screen so every phase gets a recap
      if (fallen.isNotEmpty) {
        await _showPeriodRecap(fallen, phaseLabel);
        if (!mounted) return;
      }

      // Game over — navigate to winner screen after the recap is dismissed
      if (response.isOver && response.winner != null) {
        setState(() => _isAdvancing = false);
        Navigator.pushReplacement(
          context,
          _fadeRoute(WinnerScreen(
            winner: response.winner!,
            tributeImages: widget.tributeImages,
            events: List.unmodifiable(_allEvents),
            allTributesById: Map.unmodifiable(_allTributesById),
          )),
        );
        return;
      }

      // Update alive tributes from status
      final status = await _api.getStatus();
      if (!mounted) return;

      // Merge status tributes into the lookup map (keeps dead tributes too)
      for (final t in status.aliveTributes) {
        _allTributesById[t.idString] = t;
      }

      setState(() {
        _status = status;
        _isAdvancing = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
      setState(() => _isAdvancing = false);
    } catch (e) {
      if (!mounted) return;
      _showError('Connection lost. Is the backend running?');
      setState(() => _isAdvancing = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showPeriodRecap(
      List<TributeModel> fallen, String phaseLabel) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      pageBuilder: (_, _, _) => PeriodRecapOverlay(
        fallenTributes: fallen,
        tributeImages: widget.tributeImages,
        phaseLabel: phaseLabel,
      ),
      transitionDuration: const Duration(milliseconds: 600),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      ),
    );
  }

  void _openStatistics() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatisticsPanel(
        events: List.unmodifiable(_allEvents),
        allTributesById: Map.unmodifiable(_allTributesById),
        tributeImages: widget.tributeImages,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(color: AppColors.offWhite)),
        backgroundColor: AppColors.deathRedDark,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _buildPeriodLabel() => _status.periodLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Divider(color: AppColors.goldBorder, height: 1),
            Expanded(child: _buildEventFeed()),
            _buildAdvanceBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final aliveCount = _status.aliveTributes.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Period label + alive count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _buildPeriodLabel(),
                  style: GoogleFonts.cinzel(
                    fontSize: 20,
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$aliveCount tribute${aliveCount != 1 ? "s" : ""} remaining',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistics button
          IconButton(
            onPressed: _allEvents.isEmpty ? null : _openStatistics,
            icon: const Icon(Icons.bar_chart_rounded),
            color: _allEvents.isEmpty ? AppColors.border : AppColors.gold,
            tooltip: 'Statistics',
          ),

          // Alive tributes peek button
          IconButton(
            onPressed: () => _showAliveTributes(),
            icon: const Icon(Icons.people_outline),
            color: AppColors.gold,
            tooltip: 'View survivors',
          ),
        ],
      ),
    );
  }

  Widget _buildEventFeed() {
    if (_displayedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_kabaddi,
              color: AppColors.goldDark,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              'THE ARENA AWAITS',
              style: GoogleFonts.cinzel(
                fontSize: 14,
                color: AppColors.muted,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap ADVANCE to begin the bloodshed.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _displayedEvents.length,
      itemBuilder: (_, i) => EventTile(
        event: _displayedEvents[i],
        allTributesById: _allTributesById,
        tributeImages: widget.tributeImages,
      ),
    );
  }

  Widget _buildAdvanceBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.goldBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isAdvancing ? null : _advance,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isAdvancing ? AppColors.goldDark : AppColors.gold,
            foregroundColor: AppColors.background,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2)),
          ),
          child: _isAdvancing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'THE GAMES UNFOLD...',
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        color: AppColors.background,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                )
              : Text(
                  'ADVANCE — ${_buildPeriodLabel()}',
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    color: AppColors.background,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
        ),
      ),
    );
  }

  void _showAliveTributes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SurvivorsSheet(
        aliveTributes: _status.aliveTributes,
        tributeImages: widget.tributeImages,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Survivors bottom sheet
// ─────────────────────────────────────────────

class _SurvivorsSheet extends StatelessWidget {
  final List<TributeModel> aliveTributes;
  final Map<String, String> tributeImages;

  const _SurvivorsSheet({
    required this.aliveTributes,
    required this.tributeImages,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.goldBorder)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'SURVIVORS',
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.goldDark.withValues(alpha: 0.3),
                        border: Border.all(color: AppColors.goldDark),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '${aliveTributes.length} alive',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: aliveTributes.length,
                  itemBuilder: (_, i) {
                    final t = aliveTributes[i];
                    return TributeCard(
                      tribute: t,
                      imageUrl: tributeImages[t.name],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

PageRouteBuilder _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, _, _) => page,
    transitionDuration: const Duration(milliseconds: 800),
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      );
    },
  );
}
