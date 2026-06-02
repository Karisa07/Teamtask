# TODO - TT-12 Estadísticas (Supabase + Riverpod + Gráfico)

## Plan
- [x] 1) TT-12-2: Agregar RPC en `supabase/schema.sql` para obtener stats agregadas por board.

- [x] 2) TT-12-2: Implementar `getBoardStats(boardId)` en `lib/board_repository.dart` usando `client.rpc`.
- [x] 3) TT-12-4: Crear `statsProvider` (FutureProvider.family) en `lib/board_provider.dart` que consuma la RPC.
- [x] 4) TT-12-1: Diseñar pantalla `lib/screens/statistics_page.dart` con UI de KPIs + breakdown.
- [x] 5) TT-12-3: Integrar `fl_chart` (BarChart) en la pantalla de estadísticas.
- [x] 6) TT-12-1: Actualizar navegación: ruta en `lib/app_router.dart` y botón desde `lib/screens/board_detail_page.dart`.
- [x] 7) Validación: `flutter pub get`, `flutter analyze`, y prueba manual en runtime.


