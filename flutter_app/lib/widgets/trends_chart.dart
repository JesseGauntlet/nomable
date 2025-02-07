import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Data model representing a single snapshot of user preferences at a given time.
class HistorySnapshot {
  final DateTime date;
  final Map<String, int> preferences;

  HistorySnapshot({required this.date, required this.preferences});
}

/// A widget that displays a line chart tracking the ranking of top foods over time.
///
/// [snapshots] should be sorted by date in ascending order. Each snapshot contains a map
/// of food preferences (food -> count). This widget computes a ranking for each food at each
/// snapshot and then plots the rank trajectory using a line chart.
///
/// The ranking is computed as follows:
///   - For each snapshot, the foods are sorted in descending order by count.
///   - The rank for a food is its position in the sorted list (1-indexed). If a food is not present
///     in a snapshot, it is assigned a rank of (number of foods + 1).
///   - To display the chart with rank 1 at the top, we invert the rank values by computing:
///         adjustedY = (maxRank + 1) - rank
///     where maxRank is the maximum rank encountered across all snapshots (for the tracked foods).
class TrendsChart extends StatelessWidget {
  /// List of historical snapshots of food preferences.
  final List<HistorySnapshot> snapshots;

  /// The number of top foods (by global count) to track. Default is 5.
  final int topFoodsCount;

  const TrendsChart({Key? key, required this.snapshots, this.topFoodsCount = 5})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure snapshots are sorted by date in ascending order.
    List<HistorySnapshot> sortedSnapshots = List.from(snapshots);
    sortedSnapshots.sort((a, b) => a.date.compareTo(b.date));

    // Compute global summed counts for all food items from all snapshots.
    Map<String, int> globalFoodCounts = {};
    for (var snapshot in sortedSnapshots) {
      snapshot.preferences.forEach((food, count) {
        globalFoodCounts[food] = (globalFoodCounts[food] ?? 0) + count;
      });
    }

    // Determine the global top foods based on summed counts.
    List<String> trackedFoods =
        globalFoodCounts.entries.map((e) => e.key).toList();
    trackedFoods.sort((a, b) =>
        (globalFoodCounts[b] ?? 0).compareTo(globalFoodCounts[a] ?? 0));
    trackedFoods = trackedFoods.take(topFoodsCount).toList();

    // Prepare raw series data: for each tracked food, a list of (snapshot index, raw rank).
    // We'll also compute the maximum rank encountered for scaling purposes.
    Map<String, List<FlSpot>> rawSeries = {};
    double globalMaxRank = 0;

    // Initialize series list for each tracked food.
    for (var food in trackedFoods) {
      rawSeries[food] = [];
    }

    // Iterate snapshots and compute rank for each tracked food
    for (int i = 0; i < sortedSnapshots.length; i++) {
      final snapshot = sortedSnapshots[i];
      // Sort the snapshot's foods by count in descending order.
      List<MapEntry<String, int>> sortedPrefs =
          snapshot.preferences.entries.toList();
      sortedPrefs.sort((a, b) => b.value.compareTo(a.value));
      int totalFoods = sortedPrefs.length;

      for (var food in trackedFoods) {
        int rank;
        // Find the rank if the food exists in this snapshot
        int index = sortedPrefs.indexWhere((entry) => entry.key == food);
        if (index != -1) {
          rank = index + 1;
        } else {
          // If the food is not present, assign a rank of totalFoods + 1
          rank = totalFoods + 1;
        }
        // Update globalMaxRank if needed.
        if (rank > globalMaxRank) globalMaxRank = rank.toDouble();
        rawSeries[food]!.add(FlSpot(i.toDouble(), rank.toDouble()));
      }
    }

    // Transform raw series into adjusted series so that rank 1 becomes the top of the chart.
    // adjustedY = (globalMaxRank + 1) - rawRank
    Map<String, List<FlSpot>> adjustedSeries = {};
    rawSeries.forEach((food, spots) {
      adjustedSeries[food] = spots
          .map((spot) => FlSpot(spot.x, (globalMaxRank + 1) - spot.y))
          .toList();
    });

    // Define some colors for the tracked foods. Extend or modify as needed.
    List<Color> seriesColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    // Build the LineChartBarData for each food series.
    List<LineChartBarData> lines = [];
    int colorIndex = 0;
    adjustedSeries.forEach((food, spots) {
      lines.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        barWidth: 3,
        dotData: FlDotData(show: true),
        color: seriesColors[colorIndex % seriesColors.length],
      ));
      colorIndex++;
    });

    // Determine the x-axis range
    double minX = 0;
    double maxX = sortedSnapshots.isNotEmpty
        ? (sortedSnapshots.length - 1).toDouble()
        : 0;

    // Set the y-axis range: after adjustment, best rank (1) becomes y = globalMaxRank, worst becomes y = 1.
    double minY = 1;
    double maxY = globalMaxRank + 1;

    // Build the LineChartData for fl_chart.
    LineChartData chartData = LineChartData(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              // For simplicity, we label the x-axis with the snapshot index or date
              int index = value.toInt();
              if (index < 0 || index >= sortedSnapshots.length)
                return Container();
              DateTime date = sortedSnapshots[index].date;
              // Format date as month/day for brevity
              return Text('${date.month}/${date.day}',
                  style: const TextStyle(fontSize: 10));
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              // Invert the adjusted value to show original rank.
              // displayedRank = (globalMaxRank + 1) - value
              int displayedRank = ((globalMaxRank + 1) - value).round();
              return Text('$displayedRank',
                  style: const TextStyle(fontSize: 10));
            },
          ),
        ),
      ),
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: true),
      lineBarsData: lines,
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Legend
          Wrap(
            spacing: 16,
            children: [
              for (int i = 0; i < trackedFoods.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: seriesColors[i % seriesColors.length],
                    ),
                    const SizedBox(width: 4),
                    Text(trackedFoods[i], style: const TextStyle(fontSize: 12)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          AspectRatio(
            aspectRatio: 1.5,
            child: LineChart(chartData),
          ),
        ],
      ),
    );
  }
}
