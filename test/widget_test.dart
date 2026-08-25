import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:quijano_advmobprog/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'HOST=https://dummyjson.com');
  });

  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const QuijanoAdvMobProg());
    await tester.pump();
    expect(find.text('E-Commerce App'), findsOneWidget);
  });
}
