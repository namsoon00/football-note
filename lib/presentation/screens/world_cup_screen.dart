import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/world_cup_schedule.dart';
import '../../domain/repositories/option_repository.dart';
import '../../gen/app_localizations.dart';
import '../widgets/app_background.dart';
import '../widgets/watch_cart/watch_cart_card.dart';

class WorldCupScreen extends StatefulWidget {
  final OptionRepository? optionRepository;

  const WorldCupScreen({super.key, this.optionRepository});

  @override
  State<WorldCupScreen> createState() => _WorldCupScreenState();
}

class _WorldCupScreenState extends State<WorldCupScreen> {
  static const String _supportCountryKey = 'world_cup_support_country_v1';
  static const String _interestCountriesKey = 'world_cup_interest_countries_v1';
  static final Uri _sourceUri = Uri.parse(
    'https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/match-schedule-fixtures-results-teams-stadiums',
  );
  static final DateTime _openingDate = DateTime(2026, 6, 11);
  static final DateTime _finalDate = DateTime(2026, 7, 19);

  late final List<String> _countries;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  String _supportCountry = 'Korea Republic';
  Set<String> _interestCountries = <String>{};
  bool _showSelectedCountriesOnly = false;

  @override
  void initState() {
    super.initState();
    _countries = worldCupCountries();
    _focusedDay = _initialCalendarDay();
    _selectedDay = _focusedDay;
    _loadCountryPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.worldCupTitle)),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildHero(context),
              const SizedBox(height: 12),
              _buildOverview(context),
              const SizedBox(height: 12),
              _buildCountrySettings(context),
              const SizedBox(height: 12),
              _buildHighlightedMatches(context),
              const SizedBox(height: 12),
              _buildCalendar(context),
              const SizedBox(height: 12),
              _buildSelectedDayMatches(context),
              const SizedBox(height: 12),
              _buildMilestones(context),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    launchUrl(_sourceUri, mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(l10n.worldCupSourceAction),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return WatchCartCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF143D2B), Color(0xFF0A6B58), Color(0xFFE4F4EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.worldCupHeroTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.worldCupHeroSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withAlpha(225),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _WorldCupBadge(label: _countdownLabel(context)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(45),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withAlpha(130)),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.public_rounded,
            title: l10n.worldCupOverviewTitle,
          ),
          const SizedBox(height: 12),
          _InfoGrid(
            items: [
              _InfoItem(l10n.worldCupHostsLabel, l10n.worldCupHostsValue),
              _InfoItem(l10n.worldCupDatesLabel, _dateRange(context)),
              _InfoItem(l10n.worldCupFormatLabel, l10n.worldCupFormatValue),
              _InfoItem(
                l10n.worldCupMatchesLabel,
                l10n.worldCupMatchesCountValue(worldCupFixtures.length),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountrySettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final interestCountries = _interestCountries.toList()..sort();
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.flag_rounded,
            title: l10n.worldCupTeamSettingsTitle,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _countries.contains(_supportCountry)
                ? _supportCountry
                : _countries.first,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.worldCupSupportCountryLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final country in _countries)
                DropdownMenuItem<String>(
                  value: country,
                  child: Text(country, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              unawaited(_setSupportCountry(value));
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.worldCupInterestCountriesLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _editInterestCountries,
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.worldCupEditInterestCountriesAction),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (interestCountries.isEmpty)
            Text(
              l10n.worldCupInterestCountriesEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final country in interestCountries)
                  InputChip(
                    label: Text(country),
                    onDeleted: () => _removeInterestCountry(country),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          FilterChip(
            avatar: const Icon(Icons.filter_alt_outlined, size: 18),
            label: Text(l10n.worldCupSelectedCountriesOnly),
            selected: _showSelectedCountriesOnly,
            onSelected: _selectedCountrySet.isEmpty
                ? null
                : (selected) {
                    setState(() => _showSelectedCountriesOnly = selected);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedMatches(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final selectedCountries = _selectedCountrySet;
    final now = DateTime.now();
    final matches = worldCupFixturesForCountries(selectedCountries)
        .where((fixture) => fixture.kickoffLocal.isAfter(now))
        .take(6)
        .toList(growable: false);
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.star_rounded,
            title: l10n.worldCupHighlightedMatchesTitle,
          ),
          const SizedBox(height: 10),
          if (matches.isEmpty)
            Text(
              l10n.worldCupNoHighlightedMatches,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final fixture in matches) ...[
              _FixtureRow(
                fixture: fixture,
                supportCountry: _supportCountry,
                interestCountries: _interestCountries,
                onTap: () => _selectFixtureDay(fixture),
              ),
              if (fixture != matches.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final firstDay = worldCupFixtures.first.localDay;
    final lastDay = worldCupFixtures.last.localDay;
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.calendar_month_rounded,
            title: l10n.worldCupCalendarTitle,
          ),
          const SizedBox(height: 10),
          TableCalendar<WorldCupFixture>(
            firstDay: firstDay,
            lastDay: lastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                normalizeWorldCupDay(day) == normalizeWorldCupDay(_selectedDay),
            eventLoader: _fixturesForDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: {
              CalendarFormat.month: l10n.calendarFormatMonth,
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ) ??
                  const TextStyle(fontWeight: FontWeight.w900),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              markerDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
            calendarBuilders: CalendarBuilders<WorldCupFixture>(
              markerBuilder: (context, day, fixtures) {
                if (fixtures.isEmpty) return const SizedBox.shrink();
                final selectedCount = fixtures
                    .where(
                      (fixture) => _fixtureMatchesSelectedCountries(fixture),
                    )
                    .length;
                return PositionedDirectional(
                  bottom: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CalendarMarker(
                        color: theme.colorScheme.primary,
                        label: fixtures.length.toString(),
                      ),
                      if (selectedCount > 0) ...[
                        const SizedBox(width: 2),
                        _CalendarMarker(
                          color: theme.colorScheme.tertiary,
                          label: selectedCount.toString(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = normalizeWorldCupDay(selectedDay);
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayMatches(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final formattedDay = DateFormat.yMMMd(localeName).format(_selectedDay);
    final matches = _visibleFixturesForDay(_selectedDay);
    final theme = Theme.of(context);
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.event_note_rounded,
            title: l10n.worldCupDayMatchesTitle(formattedDay, matches.length),
          ),
          const SizedBox(height: 10),
          if (matches.isEmpty)
            Text(
              l10n.worldCupNoMatchesOnDay,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final fixture in matches) ...[
              _FixtureRow(
                fixture: fixture,
                supportCountry: _supportCountry,
                interestCountries: _interestCountries,
              ),
              if (fixture != matches.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildMilestones(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final milestones = <_InfoItem>[
      _InfoItem(l10n.worldCupMilestoneOpeningLabel, l10n.worldCupOpeningMatch),
      _InfoItem(l10n.worldCupMilestoneGroupLabel, l10n.worldCupGroupStage),
      _InfoItem(l10n.worldCupMilestoneKnockoutLabel, l10n.worldCupKnockouts),
      _InfoItem(l10n.worldCupMilestoneFinalLabel, l10n.worldCupFinalMatch),
    ];
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.route_rounded,
            title: l10n.worldCupMilestonesTitle,
          ),
          const SizedBox(height: 12),
          for (final item in milestones) ...[
            _MilestoneRow(item: item),
            if (item != milestones.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Future<void> _editInterestCountries() async {
    final l10n = AppLocalizations.of(context)!;
    final working = Set<String>.from(_interestCountries);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.82,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Text(
                        l10n.worldCupInterestCountriesLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _countries.length,
                        itemBuilder: (context, index) {
                          final country = _countries[index];
                          return CheckboxListTile(
                            value: working.contains(country),
                            title: Text(country),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (checked) {
                              sheetSetState(() {
                                if (checked ?? false) {
                                  working.add(country);
                                } else {
                                  working.remove(country);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              sheetSetState(working.clear);
                            },
                            child: Text(
                              l10n.worldCupClearInterestCountriesAction,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(l10n.cancel),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(l10n.save),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (saved != true || !mounted) return;
    setState(() {
      _interestCountries = working;
      if (_selectedCountrySet.isEmpty) {
        _showSelectedCountriesOnly = false;
      }
    });
    await widget.optionRepository?.saveOptions(
      _interestCountriesKey,
      _interestCountries.toList()..sort(),
    );
  }

  Future<void> _setSupportCountry(String country) async {
    setState(() => _supportCountry = country);
    await widget.optionRepository?.setValue(_supportCountryKey, country);
  }

  Future<void> _removeInterestCountry(String country) async {
    setState(() {
      _interestCountries.remove(country);
      if (_selectedCountrySet.isEmpty) {
        _showSelectedCountriesOnly = false;
      }
    });
    await widget.optionRepository?.saveOptions(
      _interestCountriesKey,
      _interestCountries.toList()..sort(),
    );
  }

  void _loadCountryPreferences() {
    final repository = widget.optionRepository;
    if (repository == null) return;
    final storedSupport = repository.getValue<String>(_supportCountryKey);
    final storedInterest = repository.getOptions(
      _interestCountriesKey,
      const <String>[],
    );
    if (storedSupport != null && _countries.contains(storedSupport)) {
      _supportCountry = storedSupport;
    }
    _interestCountries =
        storedInterest.where((country) => _countries.contains(country)).toSet();
  }

  void _selectFixtureDay(WorldCupFixture fixture) {
    setState(() {
      _selectedDay = fixture.localDay;
      _focusedDay = fixture.localDay;
    });
  }

  List<WorldCupFixture> _fixturesForDay(DateTime day) {
    return worldCupFixturesForDay(day);
  }

  List<WorldCupFixture> _visibleFixturesForDay(DateTime day) {
    final fixtures = _fixturesForDay(day);
    if (!_showSelectedCountriesOnly) return fixtures;
    return fixtures
        .where(_fixtureMatchesSelectedCountries)
        .toList(growable: false);
  }

  bool _fixtureMatchesSelectedCountries(WorldCupFixture fixture) {
    final selected = _selectedCountrySet;
    if (selected.isEmpty) return false;
    return selected.any(fixture.involvesCountry);
  }

  Set<String> get _selectedCountrySet {
    return <String>{_supportCountry, ..._interestCountries}
      ..removeWhere((country) => country.trim().isEmpty);
  }

  DateTime _initialCalendarDay() {
    final today = normalizeWorldCupDay(DateTime.now());
    final firstDay = worldCupFixtures.first.localDay;
    final lastDay = worldCupFixtures.last.localDay;
    if (today.isBefore(firstDay)) return firstDay;
    if (today.isAfter(lastDay)) return lastDay;
    return today;
  }

  String _countdownLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = normalizeWorldCupDay(DateTime.now());
    if (today.isAfter(_finalDate)) {
      return l10n.worldCupCountdownComplete;
    }
    if (today.isAtSameMomentAs(_openingDate)) {
      return l10n.worldCupCountdownToday;
    }
    if (today.isAfter(_openingDate)) {
      return l10n.worldCupCountdownStarted;
    }
    return l10n.worldCupCountdownDays(_openingDate.difference(today).inDays);
  }

  String _dateRange(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formatter = DateFormat.yMMMd(locale);
    return AppLocalizations.of(context)!.worldCupDateRange(
      formatter.format(_openingDate),
      formatter.format(_finalDate),
    );
  }
}

class _FixtureRow extends StatelessWidget {
  final WorldCupFixture fixture;
  final String supportCountry;
  final Set<String> interestCountries;
  final VoidCallback? onTap;

  const _FixtureRow({
    required this.fixture,
    required this.supportCountry,
    required this.interestCountries,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final supportMatch = fixture.involvesCountry(supportCountry);
    final interestMatch = interestCountries.any(fixture.involvesCountry);
    final selected = supportMatch || interestMatch;
    final borderColor = supportMatch
        ? theme.colorScheme.primary
        : interestMatch
            ? theme.colorScheme.tertiary
            : theme.colorScheme.outlineVariant;
    final backgroundColor = selected
        ? borderColor.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.MMMd(
      localeName,
    ).add_Hm().format(fixture.kickoffLocal);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor.withValues(alpha: 0.58)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SmallPill(
                    label: l10n.worldCupMatchNumber(fixture.matchNumber),
                  ),
                  const SizedBox(width: 6),
                  _SmallPill(label: _stageLabel(l10n, fixture)),
                  if (supportMatch || interestMatch) ...[
                    const SizedBox(width: 6),
                    _SmallPill(
                      label: supportMatch
                          ? l10n.worldCupSupportBadge
                          : l10n.worldCupInterestBadge,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${fixture.homeTeam} ${l10n.worldCupVersusShort} ${fixture.awayTeam}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.worldCupKickoffLocal(time),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fixture.venue,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stageLabel(AppLocalizations l10n, WorldCupFixture fixture) {
    return switch (fixture.stage) {
      WorldCupStage.group => l10n.worldCupGroupStageLabel(fixture.group ?? ''),
      WorldCupStage.roundOf32 => l10n.worldCupRoundOf32Label,
      WorldCupStage.roundOf16 => l10n.worldCupRoundOf16Label,
      WorldCupStage.quarterFinal => l10n.worldCupQuarterFinalLabel,
      WorldCupStage.semiFinal => l10n.worldCupSemiFinalLabel,
      WorldCupStage.thirdPlace => l10n.worldCupThirdPlaceLabel,
      WorldCupStage.finalMatch => l10n.worldCupFinalLabel,
    };
  }
}

class _CalendarMarker extends StatelessWidget {
  final Color color;
  final String label;

  const _CalendarMarker({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
      ),
    );
  }
}

class _WorldCupBadge extends StatelessWidget {
  final String label;

  const _WorldCupBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(120)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 2 : 1;
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _InfoTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final _InfoItem item;

  const _InfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final _InfoItem item;

  const _MilestoneRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String label;

  const _SmallPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;

  const _InfoItem(this.label, this.value);
}
