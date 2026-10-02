import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeData get lightTheme => ThemeData.light().copyWith(
      textTheme: ThemeData.light().textTheme.apply(
        fontFamily: 'Poppins',
      ),
      );

  ThemeData get darkTheme => ThemeData.dark().copyWith(
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Poppins',
      ),
        scaffoldBackgroundColor: const Color(0xFF121016),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF211D29),
          elevation: 0,
        ),
        cardColor: const Color(0xFF1D1A20),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF121016),
          selectedItemColor: Colors.white,
          unselectedItemColor: Color(0xFFAAA6B0),
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF55339B),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2A272E),
          hintStyle: TextStyle(color: Color(0xFFAAA6B0)),
          prefixIconColor: Color(0xFFAAA6B0),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF8D6BD1)),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );

  void toggleTheme(bool value) {
    _isDark = value;
    notifyListeners();
  }
}
