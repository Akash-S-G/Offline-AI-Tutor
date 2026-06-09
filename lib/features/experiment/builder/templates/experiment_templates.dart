class ExperimentTemplates {
  static const Map<String, dynamic> freeFall = {
    "metadata": {
      "version": "1.0.0",
      "author": "PIHUB Starter",
      "category": "physics",
      "difficulty": "Medium",
      "grade": "Grade 9",
      "subject": "Physics",
      "estimatedTime": "15 mins",
    },
    "scene": {
      "sceneId": "free_fall_1",
      "name": "Free Fall Experiment",
      "description": "Measure gravity using the accelerometer.",
      "tags": ["physics", "gravity", "acceleration"],
      "variables": [
        {
          "id": "var_accel_1",
          "name": "accelerometer",
          "type": "accelerometer",
          "value": {"x": 0.0, "y": 0.0, "z": 0.0},
          "description": "Device Acceleration",
        },
        {
          "id": "var_timer_1",
          "name": "elapsedTime",
          "type": "elapsedTime",
          "value": 0.0,
          "description": "Time since drop",
        },
      ],
      "objects": [
        {
          "objectId": "obj_graph_1",
          "name": "Acceleration Graph",
          "objectType": "lineGraph",
          "properties": {"linked_variable": "var_accel_1"},
        },
      ],
      "rules": [
        {
          "ruleId": "rule_drop_1",
          "name": "DropDetection",
          "trigger": "variableChanged",
          "condition": {
            "variableId": "var_accel_1",
            "operator": "<",
            "value": 2.0,
          },
          "action": {"type": "start_recording"},
          "description": "Starts recording when device is dropped",
        },
      ],
    },
  };

  static const Map<String, dynamic> heartRate = {
    "metadata": {
      "version": "1.0.0",
      "author": "PIHUB Starter",
      "category": "biology",
      "difficulty": "Easy",
      "grade": "Grade 8",
      "subject": "Biology",
      "estimatedTime": "10 mins",
    },
    "scene": {
      "sceneId": "heart_rate_1",
      "name": "Heart Rate Monitor",
      "description": "Measure heart rate using device sensors if available.",
      "tags": ["biology", "health"],
      "variables": [
        {
          "id": "var_pulse",
          "name": "pulse",
          "type": "numberInput",
          "value": 0.0,
          "description": "Pulse input",
        },
      ],
      "objects": [
        {
          "objectId": "obj_gauge_1",
          "name": "BPM Gauge",
          "objectType": "gauge",
          "properties": {"linked_variable": "var_pulse"},
        },
      ],
      "rules": [
        {
          "ruleId": "rule_pulse_warning",
          "name": "PulseWarning",
          "trigger": "any",
          "condition": {
            "variableId": "var_pulse",
            "operator": ">",
            "value": 120,
          },
          "action": {"type": "show_warning"},
          "description": "Shows a warning for a high pulse value",
        },
      ],
    },
  };

  static const Map<String, dynamic> pendulum = {
    "metadata": {
      "version": "1.0.0",
      "author": "PIHUB Starter",
      "category": "physics",
      "difficulty": "Hard",
      "grade": "Grade 11",
      "subject": "Physics",
      "estimatedTime": "30 mins",
    },
    "scene": {
      "sceneId": "pendulum_1",
      "name": "Pendulum Motion",
      "description": "Observe simple harmonic motion parameters.",
      "tags": ["physics", "motion", "harmonic"],
      "variables": [
        {
          "id": "var_angle",
          "name": "angle",
          "type": "numberInput",
          "value": 45.0,
          "description": "Initial Angle",
        },
      ],
      "objects": [
        {
          "objectId": "obj_pendulum",
          "name": "Pendulum Bob",
          "objectType": "pendulumSimulation",
          "properties": {"linked_variable": "var_angle"},
        },
      ],
      "rules": [
        {
          "ruleId": "rule_angle_warning",
          "name": "LargeAngleWarning",
          "trigger": "any",
          "condition": {
            "variableId": "var_angle",
            "operator": ">",
            "value": 60,
          },
          "action": {"type": "show_warning"},
          "description": "Shows a warning when the pendulum angle is large",
        },
      ],
    },
  };

  static const Map<String, dynamic> plantGrowth = {
    "metadata": {
      "version": "1.0.0",
      "author": "PIHUB Starter",
      "category": "biology",
      "difficulty": "Medium",
      "grade": "Grade 7",
      "subject": "Science",
      "estimatedTime": "20 mins",
    },
    "scene": {
      "sceneId": "plant_growth_1",
      "name": "Plant Growth",
      "description":
          "Simulate plant growth based on sunlight and water variables.",
      "tags": ["biology", "plants", "simulation"],
      "variables": [
        {
          "id": "var_water",
          "name": "waterLevel",
          "type": "numberInput",
          "value": 50.0,
          "description": "Water amount",
        },
        {
          "id": "var_sunlight",
          "name": "sunlight",
          "type": "numberInput",
          "value": 50.0,
          "description": "Sunlight exposure",
        },
      ],
      "objects": [
        {
          "objectId": "obj_plant",
          "name": "Plant Model",
          "objectType": "plantSimulation",
          "properties": {"water_var": "var_water", "sun_var": "var_sunlight"},
        },
      ],
      "rules": [
        {
          "ruleId": "rule_water_warning",
          "name": "LowWaterWarning",
          "trigger": "any",
          "condition": {
            "variableId": "var_water",
            "operator": "<",
            "value": 20,
          },
          "action": {"type": "show_warning"},
          "description": "Shows a warning when water is low",
        },
      ],
    },
  };

  static const Map<String, dynamic> waterCycle = {
    "metadata": {
      "version": "1.0.0",
      "author": "PIHUB Starter",
      "category": "earth_science",
      "difficulty": "Easy",
      "grade": "Grade 6",
      "subject": "Geography",
      "estimatedTime": "15 mins",
    },
    "scene": {
      "sceneId": "water_cycle_1",
      "name": "Water Cycle",
      "description": "Interactive water cycle simulation.",
      "tags": ["geography", "environment"],
      "variables": [
        {
          "id": "var_temp",
          "name": "temperature",
          "type": "numberInput",
          "value": 25.0,
          "description": "Atmospheric Temperature",
        },
      ],
      "objects": [
        {
          "objectId": "obj_cycle",
          "name": "Cycle Diagram",
          "objectType": "interactiveDiagram",
          "properties": {"temp_var": "var_temp"},
        },
      ],
      "rules": [
        {
          "ruleId": "rule_temp_warning",
          "name": "EvaporationWarning",
          "trigger": "any",
          "condition": {"variableId": "var_temp", "operator": ">", "value": 35},
          "action": {"type": "show_warning"},
          "description": "Shows a warning when temperature is high",
        },
      ],
    },
  };

  static const List<Map<String, dynamic>> allTemplates = [
    freeFall,
    heartRate,
    pendulum,
    plantGrowth,
    waterCycle,
  ];
}
