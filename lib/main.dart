import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/fare_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(FareFinder());
}

class FareFinder extends StatelessWidget {
  const FareFinder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FareProvider()),
      ],
      child: MaterialApp(
        title: 'Find Fare',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}


