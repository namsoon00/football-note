# App Context

Last updated: 2026-03-15

## Purpose
- Product: Football Note / 태오의 노트
- Core value: help youth football players and parents record training, review growth, and continue data across devices
- Primary business lens: improve retention around training logs and convert recorded data into paid value

## Current Product Shape
- Platform: Flutter app for iOS, Android, Web, desktop targets present
- App entry: [`lib/main.dart`](../lib/main.dart)
- Main navigation: 4-tab structure in [`lib/presentation/screens/home_screen.dart`](../lib/presentation/screens/home_screen.dart)
- Tabs:
  - Home
  - Logs
  - Calendar
  - Stats
- Secondary destinations:
  - News via top app bar shortcut
  - Game via top app bar shortcut
  - Coach via top app bar shortcut

## Implemented Core Areas

### 1. Training Logs
- Screen: [`lib/presentation/screens/logs_screen.dart`](../lib/presentation/screens/logs_screen.dart)
- Create/edit flow: [`lib/presentation/screens/entry_form_screen.dart`](../lib/presentation/screens/entry_form_screen.dart)
- Backed by Hive via [`lib/application/training_service.dart`](../lib/application/training_service.dart)
- Current capabilities:
  - training note creation and edit
  - autosave behavior
  - card/list browsing
  - search and filters
  - status, condition, location, program tracking
  - injury/rehab fields
  - daily goals
  - jump rope and lifting inputs
  - linked training sketch boards
  - optional fortune-style comment fields already in model
  - image attachment support in model

### 2. Calendar and Planing
- Screen: [`lib/presentation/screens/calendar_screen.dart`](../lib/presentation/screens/calendar_screen.dart)
- Current capabilities:
  - monthly calendar
  - view entries by date
  - local training plans
  - match entry creation flow
  - reminder sync via `TrainingPlanReminderService`
  - quick-create actions from drawer

### 3. Growth and Statistics
- Screen: [`lib/presentation/screens/stats_screen.dart`](../lib/presentation/screens/stats_screen.dart)
- Supporting service: [`lib/application/benchmark_service.dart`](../lib/application/benchmark_service.dart)
- Current capabilities:
  - selected date-range stats
  - training vs match split
  - graphs and summary metrics
  - profile-based average comparison
  - external benchmark refresh with cache
- This is one of the strongest monetization foundations because it turns raw logs into interpreted value

### 4. News
- Screen: [`lib/presentation/screens/news_screen.dart`](../lib/presentation/screens/news_screen.dart)
- Repository: [`lib/infrastructure/rss_news_repository.dart`](../lib/infrastructure/rss_news_repository.dart)
- Current capabilities:
  - channel-based football RSS aggregation
  - title translation option in Korean context
  - search
  - scrap/bookmark behavior
  - blocked domain filtering
- Role in business: retention/support feature, not the core monetization driver

### 5. Game and Quiz
- Game: [`lib/presentation/screens/space_speed_game_screen.dart`](../lib/presentation/screens/space_speed_game_screen.dart)
- Quiz: [`lib/presentation/screens/skill_quiz_screen.dart`](../lib/presentation/screens/skill_quiz_screen.dart)
- Ranking: [`lib/presentation/screens/game_ranking_screen.dart`](../lib/presentation/screens/game_ranking_screen.dart)
- Guide: [`lib/presentation/screens/game_guide_screen.dart`](../lib/presentation/screens/game_guide_screen.dart)
- Current capabilities:
  - playable pass/decision game
  - difficulty and ranking history
  - daily mixed quiz and wrong-answer review
- Role in business: short-loop engagement and habit support

### 6. Coach / Learning Content
- Manual screen: [`lib/presentation/screens/coach_lesson_screen.dart`](../lib/presentation/screens/coach_lesson_screen.dart)
- Current capabilities:
  - diagnosis
  - lesson selection
  - practice guidance
  - self-check
- This is a strong base for paid curriculum or premium lesson packs

### 7. Training Sketch Boards
- List screen: [`lib/presentation/screens/training_board_list_screen.dart`](../lib/presentation/screens/training_board_list_screen.dart)
- Current capabilities:
  - create/edit board templates
  - link boards to entries
  - manage reusable drill sketches
- Monetization potential: paid template packs and coach-authored programs

### 8. Profile / Parent-Relevant Data
- Screen: [`lib/presentation/screens/profile_screen.dart`](../lib/presentation/screens/profile_screen.dart)
- Current capabilities:
  - player info
  - birth date
  - soccer start date
  - height/weight
  - photo
  - profile tests
- Important for personalized reporting and parent-facing value

### 9. Backup / Data Continuity
- Settings: [`lib/presentation/screens/settings_screen.dart`](../lib/presentation/screens/settings_screen.dart)
- Service wrapper: [`lib/application/backup_service.dart`](../lib/application/backup_service.dart)
- Current capabilities:
  - Google sign-in state
  - manual backup/restore
  - auto daily backup
  - auto backup on save
  - local pre-restore safety backup
- Important trust feature; should support premium but not be the only paid reason

## Data Model Notes
- Main entity: [`lib/domain/entities/training_entry.dart`](../lib/domain/entities/training_entry.dart)
- The model already holds enough data to power premium summaries:
  - duration
  - intensity
  - mood/status
  - goals and improvements
  - body and injury data
  - lifting and jump rope metrics
  - match statistics
  - timestamps for recent activity sorting

## Current Product Strengths
- Broader than a simple diary app
- Real habit loop exists through logs, calendar, stats, quiz, and game
- Strong local-first behavior
- Growth interpretation already exists, not just raw storage
- Parent/coach expansion path is visible in the current structure

## Current Product Risks
- Scope is already wide, so adding more free features can dilute value
- News and game may consume effort without directly increasing payment intent
- No visible monetization layer yet around reports, premium insights, or paid programs
- The strongest assets are fragmented across tabs instead of being packaged into a clear premium outcome

## Revenue-First Interpretation
- Core monetization anchor should be `growth insight`, not `content volume`
- Most valuable user segments:
  - parents of youth players
  - serious self-training players
  - private coaches
- Best near-term paid surfaces:
  - weekly growth report
  - parent share report
  - premium drill/sketch packs
  - guided challenge programs
  - coach multi-player view

## Suggested Priority Order
1. Increase logging frequency
2. Turn logged data into shareable insight
3. Package repeatable premium programs/templates
4. Add coach/parent collaboration surfaces
5. Use news/game only to support retention

## Home Hub Strategy
- Goal: make the first screen a daily action hub instead of a passive log list
- Best implementation path: evolve the current Logs screen into the home dashboard while keeping the existing tab architecture
- Reason:
  - the Logs tab is already the practical entry surface
  - it has direct access to entries, board count, search/filter, and create flows
  - this minimizes navigation churn and avoids a large IA rewrite

### Recommended Home Information Architecture
1. Today card
   - today's plan summary
   - latest training date
   - this week session count
   - streak / consistency signal
2. Quick actions
   - add training log
   - add match
   - add training plan
   - open training sketch
   - start quiz
3. Weekly growth summary
   - training count
   - total minutes
   - strongest metric
   - weakest metric
   - one recommended next action
4. Continue section
   - recent sketch board
   - last edited log
   - next unfinished plan
   - latest quiz/game re-entry point
5. Recent logs
   - preserve the current log list below the dashboard blocks

### Home Screen Rules
- show actions and summaries, not full-detail screens
- every card should lead to a clear next action
- reduce dead-end browsing from the first screen
- home should answer:
  - what should I do today?
  - how am I doing this week?
  - what should I open next?

### Functional Connection Model
- Home -> create or continue action
- Action complete -> immediate feedback
- Feedback -> weekly progress update
- Progress update -> recommended next action
- Recommended action -> logs, calendar, stats, board, or quiz

### Product Success Impact
- better daily return behavior
- lower friction to first action
- clearer perceived value from existing features

## Gamification Layer
- Level system service: [`lib/application/player_level_service.dart`](../lib/application/player_level_service.dart)
- Current MVP:
  - player XP and level persisted locally in options storage
  - home hero card shows level, progress bar, and visual growth tier
  - training log save grants XP
  - quiz completion grants daily XP
  - training plan creation grants XP
- Current level philosophy:
  - fast early progression for onboarding and habit formation
  - football-themed level titles
  - built-in visual tier illustration on home as a placeholder for future art assets
- stronger foundation for premium weekly report and guided programs

## Working Rule For Future Updates
- Keep this file updated whenever implemented functionality materially changes
- Prefer updating sections above instead of appending random notes
- When proposing ideas, tie them back to current implemented surfaces in this document
