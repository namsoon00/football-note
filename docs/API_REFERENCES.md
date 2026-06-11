# API References

External APIs and feed sources used by the app should keep their public URL or
documentation link here so future changes can verify request paths and terms.

| Area | Service | Code | URL or docs |
| --- | --- | --- | --- |
| Weather forecast | Open-Meteo Forecast API | `lib/application/weather_forecast_service.dart`, `lib/application/weather_current_service.dart` | https://open-meteo.com/en/docs |
| Weather geocoding | Open-Meteo Geocoding API | `lib/application/weather_location_service.dart` | https://open-meteo.com/en/docs/geocoding-api |
| Weather history and air quality fallback | Open-Meteo Archive and Air Quality APIs | `lib/application/weather_shared_resource.dart` | https://open-meteo.com/en/docs/historical-weather-api, https://open-meteo.com/en/docs/air-quality-api |
| Korea weather | KMA short/mid forecast APIs through data.go.kr | `lib/application/weather_current_service.dart` | https://www.data.go.kr/data/15084084/openapi.do, https://www.data.go.kr/data/15059468/openapi.do |
| Korea air quality | AirKorea station and measurement APIs through data.go.kr | `lib/application/korean_air_quality_service.dart` | https://www.data.go.kr/data/15073861/openapi.do, https://www.data.go.kr/data/15073877/openapi.do |
| Korea local search/geocoding | Kakao Local API | `lib/application/weather_location_service.dart`, `lib/application/korean_air_quality_service.dart` | https://developers.kakao.com/docs/latest/en/local/dev-guide |
| League standings and fixtures | ESPN site soccer endpoints | `lib/application/league_standings_service.dart` | https://site.api.espn.com/apis/site/v2/sports/soccer |
| K League standings and fixtures | K League public pages/endpoints | `lib/application/league_standings_service.dart` | https://www.kleague.com/record/team.do, https://www.kleague.com/schedule.do?leagueId=1 |
| FIFA rankings and matches | FIFA API and ranking pages | `lib/application/fifa_world_overview_service.dart`, `lib/application/korea_football_snapshot_service.dart` | https://api.fifa.com/api/v3, https://inside.fifa.com/fifa-world-ranking |
| Korea national team snapshot | KFA public site | `lib/application/fifa_world_overview_service.dart`, `lib/application/korea_football_snapshot_service.dart` | https://www.kfa.or.kr/ |
| Backup | Google Drive API | `lib/application/drive_backup_service.dart`, `lib/application/auth_service.dart` | https://developers.google.com/drive/api/guides/about-sdk |
| News | Publisher RSS feeds | `lib/infrastructure/rss_news_repository.dart` | Feed URLs are listed in `_feeds`; proxy fallbacks use https://allorigins.win/ and https://rss2json.com/docs |
| Benchmarks | CDC, WHO, and soccer juggling public sources | `lib/application/benchmark_service.dart` | https://www.cdc.gov/growthcharts/, https://www.who.int/news-room/fact-sheets/detail/physical-activity, https://www.progressivesoccertraining.com/soccer-juggling-by-age/ |
