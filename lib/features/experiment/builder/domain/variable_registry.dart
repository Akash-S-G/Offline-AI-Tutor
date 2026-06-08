import 'package:flutter/material.dart';

enum VariableCategory {
  sensor,
  userInput,
  computed,
  timer,
  constant,
}

enum VariableType {
  accelerometer,
  gyroscope,
  magnetometer,
  gps,
  microphone,
  lightSensor,
  proximity,

  slider,
  textInput,
  numberInput,
  dropdown,
  toggle,

  average,
  minimum,
  maximum,
  velocity,
  acceleration,
  distance,
  force,
  power,
  energy,

  elapsedTime,
  countdown,
  interval,

  customConstant,
}

class VariableDefinition {
  final VariableType type;
  final VariableCategory category;
  final String title;
  final String description;
  final IconData icon;
  final dynamic defaultValue;

  const VariableDefinition({
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    this.defaultValue = 0.0,
  });
}

class VariableRegistry {
  static const List<VariableDefinition> definitions = [
    // Sensors
    VariableDefinition(
      type: VariableType.accelerometer,
      category: VariableCategory.sensor,
      title: 'Accelerometer',
      description: 'Measure device motion and acceleration',
      icon: Icons.vibration,
      defaultValue: {'x': 0.0, 'y': 0.0, 'z': 0.0},
    ),
    VariableDefinition(
      type: VariableType.gyroscope,
      category: VariableCategory.sensor,
      title: 'Gyroscope',
      description: 'Measure device rotation',
      icon: Icons.screen_rotation,
      defaultValue: {'x': 0.0, 'y': 0.0, 'z': 0.0},
    ),
    VariableDefinition(
      type: VariableType.magnetometer,
      category: VariableCategory.sensor,
      title: 'Magnetometer',
      description: 'Measure magnetic fields',
      icon: Icons.explore,
      defaultValue: {'x': 0.0, 'y': 0.0, 'z': 0.0},
    ),
    VariableDefinition(
      type: VariableType.gps,
      category: VariableCategory.sensor,
      title: 'GPS',
      description: 'Device location and altitude',
      icon: Icons.gps_fixed,
      defaultValue: {'lat': 0.0, 'lng': 0.0, 'alt': 0.0},
    ),
    VariableDefinition(
      type: VariableType.microphone,
      category: VariableCategory.sensor,
      title: 'Microphone',
      description: 'Audio amplitude and frequency',
      icon: Icons.mic,
      defaultValue: 0.0,
    ),
    VariableDefinition(
      type: VariableType.lightSensor,
      category: VariableCategory.sensor,
      title: 'Light Sensor',
      description: 'Ambient light intensity (lux)',
      icon: Icons.light_mode,
      defaultValue: 0.0,
    ),
    VariableDefinition(
      type: VariableType.proximity,
      category: VariableCategory.sensor,
      title: 'Proximity',
      description: 'Distance to nearby objects',
      icon: Icons.sensors,
      defaultValue: 0.0,
    ),

    // User Input
    VariableDefinition(
      type: VariableType.slider,
      category: VariableCategory.userInput,
      title: 'Slider',
      description: 'User controlled numeric value',
      icon: Icons.tune,
      defaultValue: 0.0,
    ),
    VariableDefinition(
      type: VariableType.textInput,
      category: VariableCategory.userInput,
      title: 'Text Input',
      description: 'User provided text',
      icon: Icons.text_fields,
      defaultValue: '',
    ),
    VariableDefinition(
      type: VariableType.numberInput,
      category: VariableCategory.userInput,
      title: 'Number Input',
      description: 'User provided number',
      icon: Icons.numbers,
      defaultValue: 0.0,
    ),
    VariableDefinition(
      type: VariableType.dropdown,
      category: VariableCategory.userInput,
      title: 'Dropdown',
      description: 'Select from options',
      icon: Icons.arrow_drop_down_circle,
      defaultValue: '',
    ),
    VariableDefinition(
      type: VariableType.toggle,
      category: VariableCategory.userInput,
      title: 'Toggle',
      description: 'Boolean switch (On/Off)',
      icon: Icons.toggle_on,
      defaultValue: false,
    ),

    // Computed
    VariableDefinition(
      type: VariableType.average,
      category: VariableCategory.computed,
      title: 'Average',
      description: 'Mean of selected variables',
      icon: Icons.functions,
      defaultValue: 0.0,
    ),
    VariableDefinition(
      type: VariableType.minimum,
      category: VariableCategory.computed,
      title: 'Minimum',
      description: 'Lowest value over time',
      icon: Icons.minimize,
      defaultValue: 0.0,
    ),
    VariableDefinition(
      type: VariableType.maximum,
      category: VariableCategory.computed,
      title: 'Maximum',
      description: 'Highest value over time',
      icon: Icons.maximize,
      defaultValue: 0.0,
    ),
    VariableDefinition(
      type: VariableType.velocity,
      category: VariableCategory.computed,
      title: 'Velocity',
      description: 'Distance divided by time',
      icon: Icons.speed,
      defaultValue: 0.0,
    ),
    VariableDefinition(
      type: VariableType.acceleration,
      category: VariableCategory.computed,
      title: 'Acceleration',
      description: 'Change in velocity over time',
      icon: Icons.fast_forward,
      defaultValue: 0.0,
    ),
    VariableDefinition(
      type: VariableType.distance,
      category: VariableCategory.computed,
      title: 'Distance',
      description: 'Calculated distance',
      icon: Icons.route,
      defaultValue: 0.0,
    ),
    VariableDefinition(
      type: VariableType.force,
      category: VariableCategory.computed,
      title: 'Force',
      description: 'Mass times acceleration',
      icon: Icons.sports_mma,
      defaultValue: 0.0,
    ),
    VariableDefinition(
      type: VariableType.power,
      category: VariableCategory.computed,
      title: 'Power',
      description: 'Work done over time',
      icon: Icons.bolt,
      defaultValue: 0.0,
    ),
    VariableDefinition(
      type: VariableType.energy,
      category: VariableCategory.computed,
      title: 'Energy',
      description: 'Calculated kinetic/potential energy',
      icon: Icons.battery_charging_full,
      defaultValue: 0.0,
    ),

    // Timer
    VariableDefinition(
      type: VariableType.elapsedTime,
      category: VariableCategory.timer,
      title: 'Elapsed Time',
      description: 'Time since start (seconds)',
      icon: Icons.timer,
      defaultValue: 0.0,
    ),
    VariableDefinition(
      type: VariableType.countdown,
      category: VariableCategory.timer,
      title: 'Countdown',
      description: 'Time remaining (seconds)',
      icon: Icons.hourglass_bottom,
      defaultValue: 60.0,
    ),
    VariableDefinition(
      type: VariableType.interval,
      category: VariableCategory.timer,
      title: 'Interval',
      description: 'Triggers on a regular interval',
      icon: Icons.schedule,
      defaultValue: 1.0,
    ),

    // Constant
    VariableDefinition(
      type: VariableType.customConstant,
      category: VariableCategory.constant,
      title: 'Custom Constant',
      description: 'Fixed mathematical or physics constant',
      icon: Icons.pin,
      defaultValue: 0.0,
    ),
  ];

  static List<VariableDefinition> getByCategory(VariableCategory category) {
    return definitions.where((def) => def.category == category).toList();
  }
}
