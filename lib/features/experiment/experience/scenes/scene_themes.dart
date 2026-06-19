import 'package:flutter/material.dart';

class SceneTheme {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;
  final Color gridColor;
  final LinearGradient? backgroundGradient;

  const SceneTheme({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    required this.gridColor,
    this.backgroundGradient,
  });

  static const SceneTheme waterCycle = SceneTheme(
    id: 'water_cycle',
    name: 'Water Cycle',
    backgroundColor: Color(0xFFE0F7FA), // Light Cyan
    primaryColor: Color(0xFF0288D1), // Light Blue
    secondaryColor: Color(0xFF00ACC1), // Cyan
    textColor: Color(0xFF004D40), // Dark Teal
    gridColor: Color(0x330288D1),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF81D4FA), Color(0xFFE0F7FA)],
    ),
  );

  static const SceneTheme pendulum = SceneTheme(
    id: 'pendulum',
    name: 'Physics Lab',
    backgroundColor: Color(0xFFFAFAFA),
    primaryColor: Color(0xFF455A64), // Blue Grey
    secondaryColor: Color(0xFF607D8B),
    textColor: Color(0xFF263238),
    gridColor: Color(0x22455A64),
  );

  static const SceneTheme circuit = SceneTheme(
    id: 'circuit',
    name: 'Electronics Bench',
    backgroundColor: Color(0xFFF5F5F5), // Light Grey
    primaryColor: Color(0xFFF57C00), // Orange
    secondaryColor: Color(0xFFFFB300), // Amber
    textColor: Color(0xFF212121),
    gridColor: Color(0x22000000),
  );

  static const SceneTheme solarSystem = SceneTheme(
    id: 'solar_system',
    name: 'Deep Space',
    backgroundColor: Color(0xFF0B0C10),
    primaryColor: Color(0xFF45A29E),
    secondaryColor: Color(0xFFC5C6C7),
    textColor: Color(0xFFE0E0E0),
    gridColor: Color(0x22FFFFFF),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF020205), Color(0xFF141526)],
    ),
  );

  static const SceneTheme heartRate = SceneTheme(
    id: 'heart_rate',
    name: 'Medical Monitor',
    backgroundColor: Color(0xFF0A0A0A),
    primaryColor: Color(0xFF00E676), // Bright Green
    secondaryColor: Color(0xFF1DE9B6), // Teal
    textColor: Color(0xFF00E676),
    gridColor: Color(0x3300E676),
  );

  static const SceneTheme plantGrowth = SceneTheme(
    id: 'plant_growth',
    name: 'Greenhouse',
    backgroundColor: Color(0xFFF1F8E9), // Light Green
    primaryColor: Color(0xFF33691E), // Dark Green
    secondaryColor: Color(0xFF689F38), // Light Green
    textColor: Color(0xFF1B5E20),
    gridColor: Color(0x3333691E),
  );

  static const SceneTheme motion = SceneTheme(
    id: 'motion',
    name: 'Testing Track',
    backgroundColor: Color(0xFFECEFF1), // Blue Grey Light
    primaryColor: Color(0xFFD32F2F), // Red
    secondaryColor: Color(0xFF1976D2), // Blue
    textColor: Color(0xFF263238),
    gridColor: Color(0x33B0BEC5),
  );
  
  static const SceneTheme simpleMachines = SceneTheme(
    id: 'simple_machines',
    name: 'Workshop',
    backgroundColor: Color(0xFFEFEBE9), // Brown Light
    primaryColor: Color(0xFF5D4037), // Brown Dark
    secondaryColor: Color(0xFF8D6E63), // Brown
    textColor: Color(0xFF3E2723),
    gridColor: Color(0x335D4037),
  );

  static const SceneTheme defaultTheme = SceneTheme(
    id: 'default',
    name: 'Default Environment',
    backgroundColor: Colors.white,
    primaryColor: Colors.blue,
    secondaryColor: Colors.lightBlue,
    textColor: Colors.black87,
    gridColor: Color(0x11000000),
  );

  static SceneTheme getById(String id) {
    switch (id) {
      case 'water_cycle': return waterCycle;
      case 'pendulum': return pendulum;
      case 'circuit': return circuit;
      case 'solar_system': return solarSystem;
      case 'heart_rate': return heartRate;
      case 'plant_growth': return plantGrowth;
      case 'motion': return motion;
      case 'simple_machines': return simpleMachines;
      default: return defaultTheme;
    }
  }
}
