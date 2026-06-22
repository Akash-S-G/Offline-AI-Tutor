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
          "action": {"type": "show_warning", "message": "Drop detected"},
          "description": "Starts recording when device is dropped",
        },
      ],
    },
  };

  static const Map<String, dynamic> heartRate = {
    "metadata": {
      "version": "2.0.0",
      "author": "PIHUB Starter",
      "category": "biology",
      "difficulty": "Easy",
      "grade": "Grade 8",
      "subject": "Biology",
      "estimatedTime": "10 mins",
    },
    "scene": {
      "sceneId": "heart_rate",
      "name": "Heart Rate Monitor",
      "description": "Measure heart rate using device sensors if available.",
      "tags": ["biology", "health"],
      "variables": [
        {
          "id": "activity",
          "type": "number",
          "default": 0
        },
        {
          "id": "heart_rate",
          "type": "number",
          "default": 60
        }
      ],
      "computedVariables": [
        {
          "id": "target_heart_rate",
          "type": "computed",
          "formula": "60 + (activity * 1.2)"
        },
        {
          "id": "blood_flow",
          "type": "computed",
          "formula": "heart_rate / 60.0"
        }
      ],
      "states": [
        {
          "id": "resting",
          "rules": [
            {
              "type": "trigger",
              "condition": "activity >= 20",
              "actions": [
                { "type": "transition", "payload": { "target": "active" } }
              ]
            },
            {
              "type": "continuous",
              "condition": "heart_rate > target_heart_rate",
              "actions": [
                { "type": "add_to_variable", "payload": { "variableId": "heart_rate", "value": -0.5 } }
              ]
            },
            {
              "type": "continuous",
              "condition": "heart_rate < target_heart_rate",
              "actions": [
                { "type": "add_to_variable", "payload": { "variableId": "heart_rate", "value": 0.5 } }
              ]
            }
          ]
        },
        {
          "id": "active",
          "rules": [
            {
              "type": "trigger",
              "condition": "activity >= 80",
              "actions": [
                { "type": "transition", "payload": { "target": "intense" } }
              ]
            },
            {
              "type": "trigger",
              "condition": "activity < 20",
              "actions": [
                { "type": "transition", "payload": { "target": "recovery" } }
              ]
            },
            {
              "type": "continuous",
              "condition": "heart_rate > target_heart_rate",
              "actions": [
                { "type": "add_to_variable", "payload": { "variableId": "heart_rate", "value": -0.5 } }
              ]
            },
            {
              "type": "continuous",
              "condition": "heart_rate < target_heart_rate",
              "actions": [
                { "type": "add_to_variable", "payload": { "variableId": "heart_rate", "value": 0.5 } }
              ]
            }
          ]
        },
        {
          "id": "intense",
          "rules": [
            {
              "type": "trigger",
              "condition": "activity < 50",
              "actions": [
                { "type": "transition", "payload": { "target": "recovery" } }
              ]
            },
            {
              "type": "continuous",
              "condition": "heart_rate > target_heart_rate",
              "actions": [
                { "type": "add_to_variable", "payload": { "variableId": "heart_rate", "value": -0.5 } }
              ]
            },
            {
              "type": "continuous",
              "condition": "heart_rate < target_heart_rate",
              "actions": [
                { "type": "add_to_variable", "payload": { "variableId": "heart_rate", "value": 0.5 } }
              ]
            }
          ]
        },
        {
          "id": "recovery",
          "rules": [
            {
              "type": "trigger",
              "condition": "activity == 0 && heart_rate <= 65",
              "actions": [
                { "type": "transition", "payload": { "target": "resting" } }
              ]
            },
            {
              "type": "trigger",
              "condition": "activity >= 50",
              "actions": [
                { "type": "transition", "payload": { "target": "active" } }
              ]
            },
            {
              "type": "continuous",
              "condition": "heart_rate > target_heart_rate",
              "actions": [
                { "type": "add_to_variable", "payload": { "variableId": "heart_rate", "value": -0.5 } }
              ]
            },
            {
              "type": "continuous",
              "condition": "heart_rate < target_heart_rate",
              "actions": [
                { "type": "add_to_variable", "payload": { "variableId": "heart_rate", "value": 0.5 } }
              ]
            }
          ]
        }
      ],
      "behaviors": [
        {
          "type": "pulse",
          "params": {
            "rate_var": "heart_rate",
            "base_scale": 1.0,
            "pulse_scale": 1.3
          }
        },
        {
          "type": "flow",
          "params": {
            "speed_var": "blood_flow"
          }
        }
      ],
      "effects": [
        {
          "type": "heart_glow",
          "params": {}
        },
        {
          "type": "blood_flow",
          "params": {}
        }
      ],
      "visualMappings": [
        {
          "variableId": "pulse_intensity",
          "targetType": "effect",
          "targetId": "heart_glow",
          "property": "pulse_intensity",
          "range": { "min": 0, "max": 1 },
          "mapTo": { "min": 0.0, "max": 1.0 }
        },
        {
          "variableId": "blood_flow",
          "targetType": "effect",
          "targetId": "blood_flow",
          "property": "flow_speed",
          "range": { "min": 0, "max": 4 },
          "mapTo": { "min": 0.0, "max": 4.0 }
        }
      ],
      "tools": [
        { "id": "stopwatch", "enabled": true }
      ],
      "missions": [
        {
          "id": "mission_1",
          "title": "Increase Heart Rate",
          "description": "Tap the treadmill to increase your activity until your heart rate reaches the intense zone.",
          "successCondition": "heart_rate >= 140"
        },
        {
          "id": "mission_2",
          "title": "Recover",
          "description": "Double tap the treadmill to stop and let your heart rate recover back to resting.",
          "successCondition": "heart_rate <= 65"
        }
      ]
    },
  };

  static const Map<String, dynamic> pendulum = {
  "metadata": {
    "version": "1.0.0",
    "author": "Antigravity",
    "category": "physics",
    "difficulty": "Medium",
    "grade": "Grade 11",
    "subject": "Physics",
    "estimatedTime": "20 mins"
  },
  "scene": {
    "sceneId": "pendulum_motion_lab",
    "name": "Pendulum Motion Laboratory",
    "description": "Interactive laboratory for exploring pendulum motion, period, and mass dependence.",
    "tags": ["physics", "pendulum", "oscillation", "gravity", "kinematics"],
    "visualPreset": "pendulum",
    "variables": [
      {
        "id": "var_length",
        "name": "Length",
        "type": "number",
        "value": 1.0,
        "description": "Length of the pendulum string (meters)"
      },
      {
        "id": "var_mass",
        "name": "Mass",
        "type": "number",
        "value": 1.0,
        "description": "Mass of the bob (kg)"
      },
      {
        "id": "var_angle",
        "name": "Release Angle",
        "type": "number",
        "value": 30.0,
        "description": "Initial release angle (degrees)"
      },
      {
        "id": "var_period",
        "name": "Period",
        "type": "computed",
        "value": 0.0,
        "description": "Time taken for one full oscillation (seconds)",
        "metadata": {
          "formula": "2 * 3.14159265359 * sqrt(var_length / 9.81)",
          "dependencies": ["var_length"]
        }
      },
      {
        "id": "var_velocity",
        "name": "Maximum Velocity",
        "type": "computed",
        "value": 0.0,
        "description": "Maximum swing velocity at the lowest point (m/s)",
        "metadata": {
          "formula": "(2 * 3.14159265359 * var_length * (var_angle / 360.0)) / var_period",
          "dependencies": ["var_length", "var_angle", "var_period"]
        }
      },
      {
        "id": "var_is_swinging",
        "name": "Is Swinging",
        "type": "boolean",
        "value": false,
        "description": "Indicates if the pendulum has been released and is swinging"
      }
    ],

    "behaviors": [
      {
        "type": "oscillation",
        "params": {
          "frequency": "sqrt(9.81 / var_length)",
          "length_var": "var_length",
          "angle_var": "var_angle",
          "is_active_var": "var_is_swinging"
        }
      }
    ],

    "effects": [
      { "type": "motion_trail" },
      { "type": "glow" }
    ],

    "states": [
      { "id": "idle",     "label": "Idle" },
      { "id": "swinging", "label": "Swinging" },
      { "id": "stopped",  "label": "Stopped" }
    ],

    "stateTransitions": [
      { "from": "idle",     "to": "swinging", "condition": { "variable": "var_is_swinging", "operator": ">=", "value": 1 } },
      { "from": "swinging", "to": "stopped",  "condition": { "variable": "var_is_swinging", "operator": "<",  "value": 1 } }
    ],

    "visualMappings": [
      { "variable": "var_velocity",     "property": "trail_length",   "min": 0, "max": 5 },
      { "variable": "var_velocity",     "property": "glow_intensity",  "min": 0, "max": 5 },
      { "variable": "behavior_velocity_norm", "property": "glow_intensity", "min": 0, "max": 1 }
    ],

    "tools": ["stopwatch", "ruler"],

    "objects": [
      {
        "objectId": "ctrl_length",
        "name": "Length",
        "objectType": "slider",
        "properties": { "linked_variable": "var_length" },
        "state": { "label": "Length (m)", "value": 1.0, "min": 0.1, "max": 5.0 }
      },
      {
        "objectId": "ctrl_mass",
        "name": "Mass",
        "objectType": "slider",
        "properties": { "linked_variable": "var_mass" },
        "state": { "label": "Mass (kg)", "value": 1.0, "min": 0.1, "max": 10.0 }
      },
      {
        "objectId": "ctrl_angle",
        "name": "Angle",
        "objectType": "slider",
        "properties": { "linked_variable": "var_angle" },
        "state": { "label": "Angle (deg)", "value": 30.0, "min": 0.0, "max": 90.0 }
      },
      {
        "objectId": "btn_release",
        "name": "Release",
        "objectType": "button",
        "properties": { "action": "trigger_rule", "rule": "rule_release" },
        "state": { "label": "Release" }
      },
      {
        "objectId": "btn_reset",
        "name": "Reset",
        "objectType": "button",
        "properties": { "action": "trigger_rule", "rule": "rule_reset" },
        "state": { "label": "Reset" }
      }
    ],
    "rules": [
      {
        "ruleId": "rule_release",
        "name": "Release Pendulum",
        "trigger": "buttonClicked",
        "condition": {
          "variableId": "btn_release",
          "operator": "==",
          "value": true
        },
        "action": {
          "type": "set_variable",
          "payload": {
            "variableId": "var_is_swinging",
            "value": true
          }
        }
      },
      {
        "ruleId": "rule_reset",
        "name": "Reset Pendulum",
        "trigger": "buttonClicked",
        "condition": {
          "variableId": "btn_reset",
          "operator": "==",
          "value": true
        },
        "action": {
          "type": "set_variable",
          "payload": {
            "variableId": "var_is_swinging",
            "value": false
          }
        }
      }
    ],
    "mission": {
      "id": "mission_pendulum_motion",
      "title": "Pendulum Motion Mission",
      "description": "Investigate the factors that affect the period of a simple pendulum.",
      "tasks": [
        { "id": "task_1", "title": "Mission 1 — Change length to 2.0 m",          "condition": "var_length >= 1.9" },
        { "id": "task_2", "title": "Mission 2 — Release the pendulum",            "condition": "var_is_swinging == true" },
        { "id": "task_3", "title": "Mission 3 — Measure period with stopwatch",   "condition": "var_period > 0.0" },
        { "id": "task_4", "title": "Mission 4 — Compare two lengths",             "condition": "trials_saved >= 2" }
      ]
    },
    "assessment": {
      "id": "assess_pendulum_motion",
      "title": "Pendulum Motion Assessment",
      "questions": [
        { "id": "q1", "type": "multiple_choice", "question": "What happens to the period of a pendulum when its length is quadrupled?", "options": ["It halves", "It stays the same", "It doubles", "It quadruples"], "correctAnswer": "It doubles" },
        { "id": "q2", "type": "multiple_choice", "question": "How does the mass of the bob affect the period of a simple pendulum?", "options": ["Increasing mass increases the period", "Increasing mass decreases the period", "Mass has no effect on the period", "It depends on the initial angle"], "correctAnswer": "Mass has no effect on the period" },
        { "id": "q3", "type": "multiple_choice", "question": "Where is the pendulum's velocity at its maximum?", "options": ["At the highest points of its swing", "At the lowest point (equilibrium position)", "Halfway between the highest and lowest points", "Velocity is constant throughout the swing"], "correctAnswer": "At the lowest point (equilibrium position)" },
        { "id": "q4", "type": "multiple_choice", "question": "What provides the restoring force for a simple pendulum?", "options": ["Tension in the string", "Air resistance", "Gravity", "The mass of the bob"], "correctAnswer": "Gravity" },
        { "id": "q5", "type": "multiple_choice", "question": "If you take a pendulum from Earth to the Moon, its period will:", "options": ["Increase", "Decrease", "Stay the same", "Become zero"], "correctAnswer": "Increase" },
        { "id": "q6", "type": "true_false", "question": "For small angles, the period of a pendulum is independent of the release angle.", "correctAnswer": "True" },
        { "id": "q7", "type": "true_false", "question": "The time taken for a pendulum to swing from one extreme to the other and back again is called its amplitude.", "correctAnswer": "False" },
        { "id": "q8", "type": "reflection", "question": "Explain why a grandfather clock might run slow in the summer and fast in the winter, based on the physics of a pendulum.", "correctAnswer": "" }
      ]
    },
    "investigation": {
      "title": "Compare period",
      "trials": [
        {
          "id": "trial_1",
          "title": "Trial 1",
          "parameters": {
            "var_length": 1.0
          }
        },
        {
          "id": "trial_2",
          "title": "Trial 2",
          "parameters": {
            "var_length": 2.0
          }
        }
      ]
    }
  }
  };

  static const Map<String, dynamic> plantGrowth = {
    "metadata": {
      "version": "2.0.0",
      "author": "Antigravity",
      "category": "biology",
      "difficulty": "Medium",
      "grade": "Grade 7",
      "subject": "Biology",
      "estimatedTime": "20 mins",
    },
    "scene": {
  "sceneId": "plant_growth",
  "variables": [
    {
      "id": "water",
      "type": "number",
      "default": 30
    },
    {
      "id": "sunlight",
      "type": "number",
      "default": 30
    },
    {
      "id": "growth",
      "type": "number",
      "default": 0
    },
    {
      "id": "health",
      "type": "number",
      "default": 100
    }
  ],
  "computedVariables": [
    {
      "id": "photosynthesis_rate",
      "type": "computed",
      "formula": "(water * 0.4) + (sunlight * 0.6)"
    },
    {
      "id": "growth_rate",
      "type": "computed",
      "formula": "photosynthesis_rate > 50 ? 5 : (photosynthesis_rate > 20 ? 1 : 0)"
    },
    {
      "id": "decay_rate",
      "type": "computed",
      "formula": "water < 10 || sunlight < 10 ? 10 : 0"
    }
  ],
  "states": [
    {
      "id": "seed",
      "rules": [
        {
          "type": "trigger",
          "condition": "growth > 10",
          "actions": [
            { "type": "transition", "payload": { "target": "sprout" } }
          ]
        },
        {
          "type": "continuous",
          "condition": "true",
          "actions": [
            { "type": "add_to_variable", "payload": { "variableId": "growth", "value": 0.5 } }
          ]
        }
      ]
    },
    {
      "id": "sprout",
      "rules": [
        {
          "type": "trigger",
          "condition": "growth > 40 && health > 50",
          "actions": [
            { "type": "transition", "payload": { "target": "vegetative" } }
          ]
        },
        {
          "type": "trigger",
          "condition": "health <= 0",
          "actions": [
            { "type": "transition", "payload": { "target": "wilted" } }
          ]
        },
        {
          "type": "continuous",
          "condition": "true",
          "actions": [
            { "type": "add_to_variable", "payload": { "variableId": "growth", "value": 0.5 } },
            { "type": "add_to_variable", "payload": { "variableId": "water", "value": -0.1 } }
          ]
        }
      ]
    },
    {
      "id": "vegetative",
      "rules": [
        {
          "type": "trigger",
          "condition": "growth > 80 && health > 80",
          "actions": [
            { "type": "transition", "payload": { "target": "flowering" } }
          ]
        },
        {
          "type": "trigger",
          "condition": "health <= 0",
          "actions": [
            { "type": "transition", "payload": { "target": "wilted" } }
          ]
        },
        {
          "type": "continuous",
          "condition": "true",
          "actions": [
            { "type": "add_to_variable", "payload": { "variableId": "growth", "value": 0.5 } },
            { "type": "add_to_variable", "payload": { "variableId": "water", "value": -0.2 } },
            { "type": "add_to_variable", "payload": { "variableId": "health", "value": -0.1 } }
          ]
        }
      ]
    },
    {
      "id": "flowering",
      "rules": [
        {
          "type": "trigger",
          "condition": "health <= 0",
          "actions": [
            { "type": "transition", "payload": { "target": "wilted" } }
          ]
        },
        {
          "type": "continuous",
          "condition": "true",
          "actions": [
            { "type": "add_to_variable", "payload": { "variableId": "water", "value": -0.3 } },
            { "type": "add_to_variable", "payload": { "variableId": "health", "value": -0.2 } }
          ]
        }
      ]
    },
    {
      "id": "wilted",
      "rules": [
        {
          "type": "trigger",
          "condition": "water > 50 && sunlight > 30",
          "actions": [
            { "type": "transition", "payload": { "target": "recovering" } },
            { "type": "set_variable", "payload": { "variableId": "health", "value": 10 } }
          ]
        },
        {
          "type": "trigger",
          "condition": "health < -50",
          "actions": [
            { "type": "transition", "payload": { "target": "dead" } }
          ]
        },
        {
          "type": "continuous",
          "condition": "true",
          "actions": [
            { "type": "add_to_variable", "payload": { "variableId": "health", "value": -1 } }
          ]
        }
      ]
    },
    {
      "id": "recovering",
      "rules": [
        {
          "type": "trigger",
          "condition": "health > 50 && growth > 80",
          "actions": [
            { "type": "transition", "payload": { "target": "flowering" } }
          ]
        },
        {
          "type": "trigger",
          "condition": "health > 50 && growth <= 80",
          "actions": [
            { "type": "transition", "payload": { "target": "vegetative" } }
          ]
        },
        {
          "type": "trigger",
          "condition": "health <= 0",
          "actions": [
            { "type": "transition", "payload": { "target": "wilted" } }
          ]
        },
        {
          "type": "continuous",
          "condition": "true",
          "actions": [
            { "type": "add_to_variable", "payload": { "variableId": "health", "value": 0.5 } }
          ]
        }
      ]
    },
    {
      "id": "dead",
      "rules": []
    }
  ],
  "behaviors": [
    {
      "type": "growth",
      "params": {
        "growth_var": "growth",
        "outputs": {
          "plant_height": { "min": 0.1, "max": 2.0 },
          "leaf_count": { "min": 0.0, "max": 20.0 }
        }
      }
    }
  ],
  "effects": [
    {
      "type": "water_droplets",
      "params": {}
    },
    {
      "type": "organic_growth",
      "params": {}
    }
  ],
  "visualMappings": [
    {
      "variableId": "water",
      "targetType": "effect",
      "targetId": "water_droplets",
      "property": "droplet_frequency",
      "range": { "min": 0, "max": 100 },
      "mapTo": { "min": 0.0, "max": 40.0 }
    },
    {
      "variableId": "leaf_count",
      "targetType": "effect",
      "targetId": "organic_growth",
      "property": "node_count",
      "range": { "min": 0, "max": 20 },
      "mapTo": { "min": 0, "max": 20 }
    },
    {
      "variableId": "health",
      "targetType": "effect",
      "targetId": "organic_growth",
      "property": "node_color",
      "range": { "min": 0, "max": 100 },
      "mapTo": { "min": 0.0, "max": 100.0 }
    },
    {
      "variableId": "growth",
      "targetType": "effect",
      "targetId": "organic_growth",
      "property": "flower_visibility",
      "range": { "min": 0, "max": 100 },
      "mapTo": { "min": 0.0, "max": 100.0 }
    }
  ],
  "tools": [
    { "id": "ruler", "enabled": true },
    { "id": "stopwatch", "enabled": true }
  ],
  "missions": [
    {
      "id": "mission_1",
      "title": "Grow a Plant",
      "description": "Provide enough water and sunlight to grow the plant into the flowering stage.",
      "successCondition": "growth > 80 && health > 80"
    }
  ]
}
  };

  static const Map<String, dynamic> waterCycle = {
  "metadata": {
    "version": "2.0.0",
    "author": "Antigravity",
    "category": "environmental",
    "difficulty": "Easy",
    "grade": "Grade 10",
    "subject": "Geography",
    "estimatedTime": "15 mins"
  },
  "scene": {
    "sceneId": "water_cycle_v2",
    "name": "Water Cycle Explorer",
    "description": "Interactive laboratory for exploring the water cycle.",
    "tags": ["environmental", "water cycle", "evaporation", "condensation", "precipitation"],
    "visualPreset": "nature",
    "backgroundAssets": ["assets/images/experiments/sky_bg.svg", "assets/images/experiments/mountains.svg"],
    "actorAssets": ["assets/images/experiments/sun.svg", "assets/images/experiments/clouds.svg"],
    "effectAssets": ["assets/images/experiments/lake.svg"],
    "theme": "nature_lab",
    "variables": [
      {
        "id": "temperature",
        "name": "Temperature",
        "type": "number",
        "value": 20.0,
        "description": "Ambient temperature in °C"
      },
      {
        "id": "humidity",
        "name": "Humidity",
        "type": "number",
        "value": 20.0,
        "description": "Ambient humidity in %"
      },
      {
        "id": "evaporation_rate",
        "name": "Evaporation Rate",
        "type": "computed",
        "value": 0.0,
        "description": "Rate of evaporation",
        "metadata": {
          "formula": "(temperature * 0.6) + (humidity * 0.2)",
          "dependencies": ["temperature", "humidity"]
        }
      },
      {
        "id": "cloud_density",
        "name": "Cloud Density",
        "type": "computed",
        "value": 0.0,
        "description": "Density of clouds in the sky",
        "metadata": {
          "formula": "evaporation_rate * 0.5",
          "dependencies": ["evaporation_rate"]
        }
      },
      {
        "id": "rainfall",
        "name": "Rainfall",
        "type": "computed",
        "value": 0.0,
        "description": "Amount of rainfall",
        "metadata": {
          "formula": "cloud_density > 80 ? 100 : 0",
          "dependencies": ["cloud_density"]
        }
      }
    ],
    "behaviors": [
      {
        "type": "oscillation",
        "params": {
          "frequency": 0.1,
          "amplitude": 50,
          "axis": "horizontal"
        }
      },
      {
        "type": "pulse",
        "params": {
          "speed": 0.5,
          "scale_min": 0.95,
          "scale_max": 1.05
        }
      }
    ],
    "effects": [
      { "type": "rain" },
      { "type": "cloud" },
      { "type": "glow" },
      { "type": "wave_motion", "params": { "amplitude": 4, "speed": 0.3 } },
      { "type": "ripple" }
    ],
    "states": [
      { "id": "clear", "label": "Clear Sky" },
      { "id": "evaporating",  "label": "Evaporation" },
      { "id": "cloud_forming",  "label": "Condensation" },
      { "id": "heavy_cloud",  "label": "Heavy Clouds" },
      { "id": "raining",  "label": "Precipitation" },
      { "id": "collection",  "label": "Collection" }
    ],
    "stateTransitions": [
      { "from": "clear", "to": "evaporating", "condition": { "variable": "temperature", "operator": ">", "value": 30 } },
      { "from": "evaporating", "to": "cloud_forming", "condition": { "variable": "cloud_density", "operator": ">", "value": 30 } },
      { "from": "cloud_forming", "to": "heavy_cloud", "condition": { "variable": "cloud_density", "operator": ">", "value": 60 } },
      { "from": "heavy_cloud", "to": "raining", "condition": { "variable": "cloud_density", "operator": ">", "value": 80 } },
      { "from": "raining", "to": "collection", "condition": { "variable": "rainfall", "operator": ">", "value": 0 } }
    ],
    "visualMappings": [
      { "variable": "temperature", "property": "glow_intensity", "min": 0, "max": 100 },
      { "variable": "cloud_density", "property": "opacity", "min": 0, "max": 100 },
      { "variable": "cloud_density", "property": "scale", "min": 0, "max": 100 },
      { "variable": "rainfall", "property": "dropCount", "min": 0, "max": 100 },
      { "variable": "rainfall", "property": "dropSpeed", "min": 0, "max": 100 },
      { "variable": "rainfall", "property": "ripple_count", "min": 0, "max": 100 }
    ],
    "tools": [
      {
        "type": "numeric",
        "variable": "temperature",
        "unit": "°C",
        "label": "Temperature"
      },
      {
        "type": "numeric",
        "variable": "humidity",
        "unit": "%",
        "label": "Humidity"
      },
      {
        "type": "numeric",
        "variable": "cloud_density",
        "unit": "%",
        "label": "Cloud Density"
      }
    ],
    "mission": {
      "id": "mission_water_cycle",
      "title": "Water Cycle Mission",
      "description": "Explore the different stages of the water cycle.",
      "tasks": [
        { "id": "task_1", "title": "Mission 1 — Increase temperature", "condition": "temperature > 30" },
        { "id": "task_2", "title": "Mission 2 — Observe evaporation", "condition": "evaporation_rate > 20" },
        { "id": "task_3", "title": "Mission 3 — Increase cloud density", "condition": "cloud_density > 60" },
        { "id": "task_4", "title": "Mission 4 — Trigger rainfall", "condition": "rainfall > 0" },
        { "id": "task_5", "title": "Mission 5 — Complete the water cycle", "condition": "rainfall > 0" }
      ]
    }
  }
  };

  static const Map<String, dynamic> circuit = {
  "metadata": {
    "version": "1.0.0",
    "author": "Antigravity",
    "category": "physics",
    "difficulty": "Easy",
    "grade": "Grade 10",
    "subject": "Physics",
    "estimatedTime": "15 mins"
  },
  "scene": {
    "sceneId": "circuit",
    "name": "Simple Circuit Laboratory",
    "description": "Interactive laboratory for exploring Ohm's Law and simple circuits.",
    "tags": ["physics", "circuit", "electricity", "voltage", "current", "resistance"],
    "visualPreset": "circuit",
    "backgroundAssets": ["assets/images/experiments/circuit_bg.svg"],
    "actorAssets": ["assets/images/experiments/circuit_components.svg"],
    "effectAssets": [],
    "theme": "dark_lab",
    "variables": [
      {
        "id": "var_voltage",
        "name": "Voltage",
        "type": "number",
        "value": 1.0,
        "description": "Battery voltage in Volts (V)"
      },
      {
        "id": "var_resistance",
        "name": "Resistance",
        "type": "number",
        "value": 10.0,
        "description": "Resistor value in Ohms (Ω)"
      },
      {
        "id": "var_switch_state",
        "name": "Switch State",
        "type": "boolean",
        "value": false,
        "description": "Switch state (true = ON, false = OFF)"
      },
      {
        "id": "var_current",
        "name": "Current",
        "type": "computed",
        "value": 0.0,
        "description": "Current in Amperes (A)",
        "metadata": {
          "formula": "var_switch_state >= 0.5 ? (var_voltage / var_resistance) : 0.0",
          "dependencies": ["var_voltage", "var_resistance", "var_switch_state"]
        }
      },
      {
        "id": "var_brightness",
        "name": "Brightness",
        "type": "computed",
        "value": 0.0,
        "description": "Bulb brightness factor",
        "metadata": {
          "formula": "var_current * 10.0",
          "dependencies": ["var_current"]
        }
      }
    ],
    "behaviors": [
      {
        "type": "flow",
        "params": {
          "speed_var": "var_current",
          "is_active_var": "var_switch_state"
        }
      }
    ],
    "effects": [
      { "type": "current_flow" },
      { "type": "glow" }
    ],
    "states": [
      { "id": "off", "label": "Circuit Open" },
      { "id": "on",  "label": "Circuit Closed" }
    ],
    "stateTransitions": [
      { "from": "off", "to": "on",  "condition": { "variable": "var_switch_state", "operator": "==", "value": true } },
      { "from": "on",  "to": "off", "condition": { "variable": "var_switch_state", "operator": "==", "value": false } }
    ],
    "visualMappings": [
      { "variable": "var_current", "property": "particle_speed", "min": 0, "max": 1 },
      { "variable": "var_current", "property": "particle_density", "min": 0, "max": 100 },
      { "variable": "var_brightness", "property": "glow_radius", "min": 0, "max": 100 },
      { "variable": "var_brightness", "property": "glow_intensity", "min": 0, "max": 5 }
    ],
    "tools": [
      {
        "type": "numeric",
        "variable": "var_current",
        "unit": "A",
        "label": "Ammeter"
      }
    ],
    "objects": [
      {
        "objectId": "btn_switch",
        "name": "Switch",
        "objectType": "button",
        "properties": { "action": "trigger_rule", "rule": "rule_toggle_switch" },
        "state": { "label": "Toggle Switch" }
      },
      {
        "objectId": "btn_battery",
        "name": "Battery",
        "objectType": "button",
        "properties": { "action": "trigger_rule", "rule": "rule_cycle_voltage" },
        "state": { "label": "Cycle Voltage" }
      },
      {
        "objectId": "btn_resistor",
        "name": "Resistor",
        "objectType": "button",
        "properties": { "action": "trigger_rule", "rule": "rule_cycle_resistance" },
        "state": { "label": "Cycle Resistance" }
      }
    ],
    "rules": [
      {
        "ruleId": "rule_toggle_switch",
        "name": "Toggle Switch",
        "trigger": "buttonClicked",
        "condition": {
          "variableId": "btn_switch",
          "operator": "==",
          "value": true
        },
        "action": {
          "type": "toggle_variable",
          "payload": {
            "variableId": "var_switch_state"
          }
        }
      },
      {
        "ruleId": "rule_cycle_voltage",
        "name": "Cycle Voltage",
        "trigger": "buttonClicked",
        "condition": {
          "variableId": "btn_battery",
          "operator": "==",
          "value": true
        },
        "action": {
          "type": "cycle_variable",
          "payload": {
            "variableId": "var_voltage",
            "values": [1.0, 3.0, 5.0, 9.0]
          }
        }
      },
      {
        "ruleId": "rule_cycle_resistance",
        "name": "Cycle Resistance",
        "trigger": "buttonClicked",
        "condition": {
          "variableId": "btn_resistor",
          "operator": "==",
          "value": true
        },
        "action": {
          "type": "cycle_variable",
          "payload": {
            "variableId": "var_resistance",
            "values": [10.0, 20.0, 50.0]
          }
        }
      }
    ],
    "mission": {
      "id": "mission_circuit_basics",
      "title": "Ohm's Law Mission",
      "description": "Investigate the relationship between Voltage, Resistance, and Current.",
      "tasks": [
        { "id": "task_1", "title": "Mission 1 — Close the switch", "condition": "var_switch_state == true" },
        { "id": "task_2", "title": "Mission 2 — Increase voltage to 9V", "condition": "var_voltage == 9.0" },
        { "id": "task_3", "title": "Mission 3 — Increase resistance to 50Ω", "condition": "var_resistance == 50.0" }
      ]
    },
    "assessment": {
      "id": "assess_circuit",
      "title": "Circuit Assessment",
      "questions": [
        { "id": "q1", "type": "multiple_choice", "question": "What happens to the current when voltage increases and resistance stays the same?", "options": ["Current increases", "Current decreases", "Current stays the same", "Current goes to zero"], "correctAnswer": "Current increases" },
        { "id": "q2", "type": "multiple_choice", "question": "What happens to the current when resistance increases and voltage stays the same?", "options": ["Current increases", "Current decreases", "Current stays the same", "Current goes to zero"], "correctAnswer": "Current decreases" }
      ]
    },
    "investigation": {
      "title": "Compare current with different voltages",
      "trials": [
        {
          "id": "trial_1",
          "title": "Trial 1",
          "parameters": {
            "var_voltage": 1.0,
            "var_resistance": 10.0
          }
        },
        {
          "id": "trial_2",
          "title": "Trial 2",
          "parameters": {
            "var_voltage": 9.0,
            "var_resistance": 10.0
          }
        }
      ]
    }
  }
  };

  static const List<Map<String, dynamic>> allTemplates = [
    freeFall,
    heartRate,
    pendulum,
    plantGrowth,
    waterCycle,
    circuit,
  ];
}
