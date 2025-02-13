import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' show max;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class PreferencesRadarChart extends StatelessWidget {
  final Map<String, int> preferences;
  final int maxPreferences;
  final String userId;
  final String userName;

  const PreferencesRadarChart({
    super.key,
    required this.preferences,
    required this.userId,
    required this.userName,
    this.maxPreferences = 6,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userService = UserService();
    final currentUserPreferences = currentUser != null
        ? userService.getUserPreferences(currentUser.uid)
        : Future.value(<String, int>{});

    // Get top preferences sorted by count
    final sortedPrefs = preferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topPrefs = sortedPrefs.take(maxPreferences).toList();

    // Find the maximum value for scaling
    final maxValue =
        topPrefs.isNotEmpty ? topPrefs.map((e) => e.value).reduce(max) : 1;

    return FutureBuilder<Map<String, int>>(
      future: currentUserPreferences,
      builder: (context, snapshot) {
        final currentPrefs = snapshot.data ?? {};
        final isCurrentUserProfile = currentUser?.uid == userId;
        final profileLabel = isCurrentUserProfile ? 'You' : userName;

        return Column(
          children: [
            if (!isCurrentUserProfile)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('You', Colors.red),
                    const SizedBox(width: 20),
                    _buildLegendItem(profileLabel, Colors.blue),
                  ],
                ),
              ),
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
                          tickCount: 6,
                          ticksTextStyle: const TextStyle(fontSize: 0),
                          dataSets: [
                            RadarDataSet(
                              fillColor:
                                  Colors.blue.withAlpha(51), // 0.2 * 255 ≈ 51
                              borderColor: Colors.blue,
                              entryRadius: 2,
                              dataEntries: [
                                for (var pref in topPrefs)
                                  RadarEntry(
                                    value: pref.value / maxValue * 100,
                                  ),
                              ],
                            ),
                            if (currentUser != null && !isCurrentUserProfile)
                              RadarDataSet(
                                fillColor:
                                    Colors.red.withAlpha(51), // 0.2 * 255 ≈ 51
                                borderColor: Colors.red,
                                entryRadius: 2,
                                dataEntries: [
                                  for (var pref in topPrefs)
                                    RadarEntry(
                                      value: (currentPrefs[pref.key] ?? 0) /
                                          (currentPrefs.values.isNotEmpty
                                              ? currentPrefs.values.reduce(max)
                                              : 1) *
                                          100,
                                    ),
                                ],
                              ),
                          ],
                          radarBorderData: const BorderSide(color: Colors.grey),
                          tickBorderData: const BorderSide(color: Colors.grey),
                          gridBorderData:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                          titleTextStyle: const TextStyle(fontSize: 10),
                          getTitle: (index, angle) => RadarChartTitle(
                            text: index >= topPrefs.length
                                ? ''
                                : topPrefs[index].key,
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
      },
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Color.fromRGBO(color.red, color.green, color.blue, 0.2),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
