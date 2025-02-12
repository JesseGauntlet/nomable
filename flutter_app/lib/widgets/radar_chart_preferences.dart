import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' show max;

class PreferencesRadarChart extends StatelessWidget {
  final Map<String, int> preferences;
  final int maxPreferences;

  const PreferencesRadarChart({
    super.key,
    required this.preferences,
    this.maxPreferences = 5,
  });

  @override
  Widget build(BuildContext context) {
    // Get top preferences sorted by count
    final sortedPrefs = preferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topPrefs = sortedPrefs.take(maxPreferences).toList();

    // Find the maximum value for scaling
    final maxValue =
        topPrefs.isNotEmpty ? topPrefs.map((e) => e.value).reduce(max) : 1;

    return Column(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              // Radar Chart with top padding for labels
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: SizedBox(
                  height: 300,
                  child: RadarChart(
                    RadarChartData(
                      radarShape: RadarShape.polygon,
                      tickCount: 5,
                      ticksTextStyle: const TextStyle(fontSize: 0),
                      dataSets: [
                        RadarDataSet(
                          fillColor: Colors.blue.withOpacity(0.2),
                          borderColor: Colors.blue,
                          entryRadius: 2,
                          dataEntries: [
                            for (var pref in topPrefs)
                              RadarEntry(value: pref.value / maxValue * 100),
                          ],
                        ),
                      ],
                      radarBorderData: const BorderSide(color: Colors.grey),
                      tickBorderData: const BorderSide(color: Colors.grey),
                      gridBorderData:
                          BorderSide(color: Colors.grey.withOpacity(0.3)),
                      titleTextStyle: const TextStyle(fontSize: 10),
                      getTitle: (index, angle) => RadarChartTitle(
                        text:
                            index >= topPrefs.length ? '' : topPrefs[index].key,
                        angle: angle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
