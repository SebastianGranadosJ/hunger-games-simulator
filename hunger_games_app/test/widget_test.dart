import 'package:flutter_test/flutter_test.dart';
import 'package:hunger_games_app/main.dart';

void main() {
  testWidgets('App renders home screen smoke test', (tester) async {
    await tester.pumpWidget(const HungerGamesApp());
    expect(find.text('BEGIN THE GAMES'), findsOneWidget);
  });
}
