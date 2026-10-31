import 'package:flutter/material.dart';

class VastuDirection {
  final String name;
  final double degree;
  final String element;
  final String deity;
  final String meaning;
  final Color color;

  const VastuDirection({
    required this.name,
    required this.degree,
    required this.element,
    required this.deity,
    required this.meaning,
    required this.color,
  });
}

class VastuData {
  static const List<String> dirNames = [
    'N',
    'NNE',
    'NE',
    'ENE',
    'E',
    'ESE',
    'SE',
    'SSE',
    'S',
    'SSW',
    'SW',
    'WSW',
    'W',
    'WNW',
    'NW',
    'NNW',
  ];

  static const Map<String, VastuDirection> directions = {
    'N': VastuDirection(
      name: 'N',
      degree: 0,
      element: 'Water',
      deity: 'Kubera',
      meaning: 'Wealth, prosperity, opportunities',
      color: Color(0xFF4A7BA7),
    ),
    'NNE': VastuDirection(
      name: 'NNE',
      degree: 22.5,
      element: 'Water',
      deity: 'Soma',
      meaning: 'Health, peace, mental clarity',
      color: Color(0xFF5E96C4),
    ),
    'NE': VastuDirection(
      name: 'NE',
      degree: 45,
      element: 'Water',
      deity: 'Ishana',
      meaning: 'Most sacred — spirituality, knowledge',
      color: Color(0xFF87CEEB),
    ),
    'ENE': VastuDirection(
      name: 'ENE',
      degree: 67.5,
      element: 'Air',
      deity: 'Parjanya',
      meaning: 'Nourishment, rain, abundance',
      color: Color(0xFF9FD8A4),
    ),
    'E': VastuDirection(
      name: 'E',
      degree: 90,
      element: 'Air',
      deity: 'Indra',
      meaning: 'Social status, power, vitality',
      color: Color(0xFF90C695),
    ),
    'ESE': VastuDirection(
      name: 'ESE',
      degree: 112.5,
      element: 'Fire',
      deity: 'Agni',
      meaning: 'Energy, transformation',
      color: Color(0xFFE8A87C),
    ),
    'SE': VastuDirection(
      name: 'SE',
      degree: 135,
      element: 'Fire',
      deity: 'Agni',
      meaning: 'Kitchen zone — fire, health',
      color: Color(0xFFE67E50),
    ),
    'SSE': VastuDirection(
      name: 'SSE',
      degree: 157.5,
      element: 'Fire',
      deity: 'Pusha',
      meaning: 'Strength, nourishment',
      color: Color(0xFFDB6B4A),
    ),
    'S': VastuDirection(
      name: 'S',
      degree: 180,
      element: 'Earth',
      deity: 'Yama',
      meaning: 'Dharma, discipline, avoid main entrance',
      color: Color(0xFFB85450),
    ),
    'SSW': VastuDirection(
      name: 'SSW',
      degree: 202.5,
      element: 'Earth',
      deity: 'Nirruti',
      meaning: 'Heavy storage, obstacles removed',
      color: Color(0xFFA67C52),
    ),
    'SW': VastuDirection(
      name: 'SW',
      degree: 225,
      element: 'Earth',
      deity: 'Nirruti',
      meaning: 'Master bedroom — stability',
      color: Color(0xFF9B8B7E),
    ),
    'WSW': VastuDirection(
      name: 'WSW',
      degree: 247.5,
      element: 'Earth',
      deity: 'Pitru',
      meaning: 'Ancestors, heritage',
      color: Color(0xFFB8A890),
    ),
    'W': VastuDirection(
      name: 'W',
      degree: 270,
      element: 'Space',
      deity: 'Varun',
      meaning: 'Gains, prosperity, dining',
      color: Color(0xFFBDBDB0),
    ),
    'WNW': VastuDirection(
      name: 'WNW',
      degree: 292.5,
      element: 'Air',
      deity: 'Vayu',
      meaning: 'Air circulation, movement',
      color: Color(0xFFA8B8C8),
    ),
    'NW': VastuDirection(
      name: 'NW',
      degree: 315,
      element: 'Air',
      deity: 'Vayu',
      meaning: 'Relationships, support',
      color: Color(0xFF8AA4BE),
    ),
    'NNW': VastuDirection(
      name: 'NNW',
      degree: 337.5,
      element: 'Air',
      deity: 'Vayu',
      meaning: 'Mental balance, relationships',
      color: Color(0xFF6A94B4),
    ),
  };

  static String nameFromDegree(double degree) {
    double d = degree % 360;
    if (d < 0) d += 360;
    int idx = ((d / 22.5).round()) % 16;
    return dirNames[idx];
  }

  static VastuDirection fromDegree(double degree) {
    return directions[nameFromDegree(degree)]!;
  }
}

/// Vastu Safety Tips - Do's and Don'ts
class VastuSafetyTips {
  static const List<VastuTip> dos = [
    VastuTip(icon: '✓', text: 'Keep North and East open and clutter-free'),
    VastuTip(
      icon: '✓',
      text: 'Place main entrance in North, East, or Northeast',
    ),
    VastuTip(icon: '✓', text: 'Kitchen in Southeast (Agni zone)'),
    VastuTip(icon: '✓', text: 'Master bedroom in Southwest for stability'),
    VastuTip(icon: '✓', text: 'Study room in Northeast or West'),
    VastuTip(icon: '✓', text: 'Keep toilets in Northwest or Southeast'),
    VastuTip(icon: '✓', text: 'Sleep with head towards South or East'),
    VastuTip(icon: '✓', text: 'Keep Northeast corner at lowest level'),
  ];

  static const List<VastuTip> donts = [
    VastuTip(icon: '✗', text: 'Avoid main entrance in South or Southwest'),
    VastuTip(icon: '✗', text: 'No kitchen in Northeast (sacred zone)'),
    VastuTip(icon: '✗', text: 'No toilet in Northeast or center'),
    VastuTip(icon: '✗', text: 'Avoid sleeping with head towards North'),
    VastuTip(icon: '✗', text: 'No heavy furniture in Northeast'),
    VastuTip(icon: '✗', text: 'No dark colors in Northeast'),
    VastuTip(icon: '✗', text: 'Avoid staircase in center of home'),
    VastuTip(icon: '✗', text: 'No mirrors facing main entrance'),
  ];
}

class VastuTip {
  final String icon;
  final String text;

  const VastuTip({required this.icon, required this.text});
}

/// Capture entry for saved compass/camera readings
class CaptureEntry {
  final DateTime time;
  final double heading;
  final String direction;
  final String chakraId;
  final String? imagePath;
  final String? notes;

  const CaptureEntry({
    required this.time,
    required this.heading,
    required this.direction,
    required this.chakraId,
    this.imagePath,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'heading': heading,
        'direction': direction,
        'chakraId': chakraId,
        'imagePath': imagePath,
        'notes': notes,
      };

  factory CaptureEntry.fromJson(Map<String, dynamic> json) {
    return CaptureEntry(
      time: DateTime.parse(json['time'] as String),
      heading: (json['heading'] as num).toDouble(),
      direction: json['direction'] as String? ?? 'N',
      chakraId: json['chakraId'] as String,
      imagePath: json['imagePath'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

/// Chakra definition (id + display name)
class ChakraDef {
  final String id;
  final String name;
  final String description;

  const ChakraDef({
    required this.id,
    required this.name,
    required this.description,
  });
}

/// Registry of all available chakra types
class ChakraRegistry {
  static const List<ChakraDef> all = [
    ChakraDef(
      id: '16-directions',
      name: '16 Zone',
      description: 'Code version of the provided 16-zone chakra',
    ),
    ChakraDef(
      id: '32-gates',
      name: '32 Gate',
      description: 'Code version of the provided 32-gate chakra',
    ),
    ChakraDef(
      id: 'vastu-purush',
      name: 'Vastu Purush',
      description: 'Code version of the provided Vastu Purush grid',
    ),
    ChakraDef(
      id: 'kubar-vastu',
      name: 'Kuber Vastu',
      description: 'Code version of the provided Kuber Vastu chakra',
    ),
    ChakraDef(
      id: 'compass-chakra',
      name: 'Compass Chakra',
      description: 'Code version of the provided compass chakra wheel',
    ),
  ];

  static ChakraDef byId(String id) {
    return all.firstWhere((c) => c.id == id, orElse: () => all.first);
  }
}
