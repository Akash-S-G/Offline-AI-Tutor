class ExperimentTemplates {
  static const Map<String, dynamic> freeFall = {
    "metadata": {
      "version": "1.0.0",
      "author": "PIHUB Starter",
      "category": "physics"
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
          "description": "Device Acceleration"
        },
        {
          "id": "var_timer_1",
          "name": "elapsedTime",
          "type": "elapsedTime",
          "value": 0.0,
          "description": "Time since drop"
        }
      ],
      "objects": [
        {
          "objectId": "obj_graph_1",
          "name": "Acceleration Graph",
          "objectType": "lineGraph",
          "properties": {"linked_variable": "var_accel_1"}
        }
      ],
      "rules": [
        {
          "ruleId": "rule_drop_1",
          "name": "DropDetection",
          "trigger": "variableChanged",
          "condition": {
            "variableId": "var_accel_1",
            "operator": "<",
            "value": 2.0 // Approaching 0g freefall
          },
          "action": {
            "type": "start_recording"
          },
          "description": "Starts recording when device is dropped"
        }
      ]
    }
  };

  static const Map<String, dynamic> heartRate = {
    "metadata": {
      "version": "1.0.0",
      "author": "PIHUB Starter",
      "category": "biology"
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
          "description": "Pulse input"
        }
      ],
      "objects": [
        {
          "objectId": "obj_gauge_1",
          "name": "BPM Gauge",
          "objectType": "gauge",
          "properties": {"linked_variable": "var_pulse"}
        }
      ],
      "rules": []
    }
  };

  static const List<Map<String, dynamic>> allTemplates = [
    freeFall,
    heartRate,
  ];
}
