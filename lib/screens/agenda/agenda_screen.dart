import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../widgets/futura_tile.dart';
import 'add_event_sheet.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  void _add() => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => AddEventSheet(initialDate: _selected),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Consumer<EventProvider>(builder: (ctx, p, _) {
        final events = p.eventsForDay(_selected);
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Agenda', style: T.h1(context)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _add,
                      child: Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
                        child: const Icon(Icons.add_rounded, color: C.bg, size: 18),
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            // ── Calendrier ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              sliver: SliverToBoxAdapter(
                child: TableCalendar(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  focusedDay: _focused,
                  selectedDayPredicate: (d) => isSameDay(d, _selected),
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  locale: 'fr_FR',
                  eventLoader: p.eventsForDay,
                  onDaySelected: (sel, foc) => setState(() { _selected = sel; _focused = foc; }),
                  onPageChanged: (foc) => setState(() => _focused = foc),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: T.body(context).copyWith(fontSize: 14),
                    weekendTextStyle: T.body(context).copyWith(fontSize: 14, color: C.dim),
                    outsideTextStyle: T.body(context).copyWith(fontSize: 14, color: C.muted),
                    todayDecoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.ink, width: 1)),
                    todayTextStyle: T.body(context).copyWith(fontSize: 14),
                    selectedDecoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
                    selectedTextStyle: T.body(context).copyWith(fontSize: 14, color: C.bg, fontWeight: FontWeight.w600),
                    markerDecoration: const BoxDecoration(color: C.dim, shape: BoxShape.circle),
                    markerSize: 4,
                    markersMaxCount: 3,
                    cellMargin: const EdgeInsets.all(4),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: false,
                    titleTextStyle: T.h3(context),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: C.dim, size: 20),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: C.dim, size: 20),
                    headerPadding: const EdgeInsets.only(bottom: 12),
                    titleTextFormatter: (date, _) => DateFormat('MMMM yyyy', 'fr_FR').format(date),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: T.label(context).copyWith(fontSize: 11),
                    weekendStyle: T.label(context).copyWith(fontSize: 11, color: C.muted),
                  ),
                ),
              ),
            ),

            // ── Ligne date sélectionnée ───────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
              sliver: SliverToBoxAdapter(
                child: Row(children: [
                  Text(
                    DateFormat('EEEE d MMMM', 'fr_FR').format(_selected),
                    style: T.h3(context),
                  ),
                  if (isSameDay(_selected, DateTime.now())) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(4)),
                      child: Text("Aujourd'hui", style: T.small(context).copyWith(color: C.bg, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
              ),
            ),

            // ── Événements ────────────────────────────────────────────
            if (events.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: GestureDetector(
                      onTap: _add,
                      child: Text('+ Ajouter un événement', style: T.small(context).copyWith(color: C.dim)),
                    ),
                  ).animate().fadeIn(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 120),
                sliver: SliverList.builder(
                  itemCount: events.length,
                  itemBuilder: (_, i) => _EventRow(
                    event: events[i],
                    index: i,
                    onDelete: () => p.remove(events[i].id),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

const _eColors = [C.ink, C.blue, C.ok, C.warn, C.err];

class _EventRow extends StatelessWidget {
  final EventModel event;
  final int index;
  final VoidCallback onDelete;
  const _EventRow({required this.event, required this.index, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = _eColors[event.colorIndex.clamp(0, 4)];
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [SlidableAction(onPressed: (_) => onDelete(), backgroundColor: Colors.transparent, foregroundColor: C.err, icon: Icons.delete_outline, padding: EdgeInsets.zero)],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 2, height: 40, color: color, margin: const EdgeInsets.only(right: 16, top: 2)),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(event.title, style: T.h3(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  event.isAllDay ? 'Journée entière' : '${DateFormat('HH:mm').format(event.startDate)} → ${DateFormat('HH:mm').format(event.endDate)}',
                  style: T.mono(context).copyWith(fontSize: 12),
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(event.description, style: T.small(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ]),
            ),
          ]),
        ),
        const Divider(height: 0, thickness: 0.5, color: C.line),
      ]),
    ).animate(delay: Duration(milliseconds: index * 30)).fadeIn();
  }
}
