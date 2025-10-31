import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedTimeRange = '7 days';
  final List<String> _timeRanges = ['24 hours', '7 days', '30 days', '90 days'];
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2028),
      appBar: AppBar(
        title: const Text('Analytics & Heatmaps',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B2028),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
              });
            },
            itemBuilder: (context) => _timeRanges
                .map((range) => PopupMenuItem(
                      value: range,
                      child: Row(
                        children: [
                          if (_selectedTimeRange == range)
                            const Icon(Icons.check,
                                color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(range),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildDisasterTypeChart(),
            const SizedBox(height: 24),
            _buildTimeDistributionChart(),
            const SizedBox(height: 24),
            _buildMonthlyBarChart(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getFilteredData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingCards();
        }

        final docs = snapshot.data!;
        final totalReports = docs.length;
        final fireReports = docs
            .where((doc) =>
                (doc['disaster_type'] ?? '').toString().toLowerCase() == 'fire')
            .length;
        final accidents = docs
            .where((doc) =>
                (doc['disaster_type'] ?? '').toString().toLowerCase() ==
                'accident')
            .length;
        final stampedes = docs
            .where((doc) =>
                (doc['disaster_type'] ?? '').toString().toLowerCase() ==
                'stampede')
            .length;

        return Row(
          children: [
            Expanded(
                flex: 1,
                child: _buildSummaryCard(
                    'Total', totalReports.toString(), Colors.blue)),
            const SizedBox(width: 8), // Reduced spacing
            Expanded(
                flex: 1,
                child: _buildSummaryCard(
                    'Fire', fireReports.toString(), const Color(0xFFFF4444))),
            const SizedBox(width: 8), // Reduced spacing
            Expanded(
                flex: 1,
                child: _buildSummaryCard('Accidents', accidents.toString(),
                    const Color(0xFFFFA726))),
            const SizedBox(width: 8), // Reduced spacing
            Expanded(
                flex: 1,
                child: _buildSummaryCard(
                    'Stampede', stampedes.toString(), const Color(0xFF9C27B0))),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      height: 75, // Reduced from 90 to 75
      padding: const EdgeInsets.all(12), // Reduced from 16 to 12
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D36),
        borderRadius: BorderRadius.circular(8), // Reduced radius
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          Flexible(
            // Allow text to shrink if needed
            child: Text(
              title,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 9), // Reduced from 11 to 9
              maxLines: 1, // Single line only
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4), // Small spacing
          Flexible(
            // Allow value to shrink if needed
            child: Text(
              value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold), // Reduced from 24 to 20
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCards() {
    return Row(
      children: List.generate(
          4,
          (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                      right: index < 3 ? 8 : 0), // Reduced from 12 to 8
                  height: 75, // Match the summary card height
                  padding: const EdgeInsets.all(12), // Reduced from 16 to 12
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2D36),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 18,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
    );
  }

  Widget _buildDisasterTypeChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D36),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Disaster Types Distribution',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getFilteredData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.orange));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No data available',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              final docs = snapshot.data!;
              final typeData = <String, int>{};

              for (var doc in docs) {
                final type =
                    (doc['disaster_type'] ?? 'normal').toString().toLowerCase();
                typeData[type] = (typeData[type] ?? 0) + 1;
              }

              if (typeData.isEmpty) {
                return const Center(
                  child: Text('No data available',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              return SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: typeData.entries.map((entry) {
                      final color = _getColorForType(entry.key);
                      final percentage = (entry.value / docs.length * 100);
                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        title:
                            '${entry.value}\n${percentage.toStringAsFixed(1)}%',
                        color: color,
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    centerSpaceRadius: 50,
                    sectionsSpace: 3,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    final legendItems = [
      {'type': 'fire', 'color': const Color(0xFFFF4444), 'label': 'Fire'},
      {
        'type': 'accident',
        'color': const Color(0xFFFFA726),
        'label': 'Accident'
      },
      {
        'type': 'stampede',
        'color': const Color(0xFF9C27B0),
        'label': 'Stampede'
      },
      {'type': 'normal', 'color': const Color(0xFF4CAF50), 'label': 'Normal'},
    ];

    return Wrap(
      children: legendItems
          .map((item) => Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['label'] as String,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildTimeDistributionChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D36),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Disaster Trends - Line Chart',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track fire, accident, and stampede incidents over time',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getFilteredData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.orange));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No data available',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              final docs = snapshot.data!;
              final lineData = _processDisasterLineDataFromSupabase(docs);

              if (lineData['fire']!.isEmpty &&
                  lineData['accident']!.isEmpty &&
                  lineData['stampede']!.isEmpty) {
                return const Center(
                  child: Text('No data available',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              // Calculate max value for Y-axis
              final maxFireValue = lineData['fire'].isEmpty
                  ? 0.0
                  : (lineData['fire'] as List<FlSpot>)
                      .map((e) => e.y)
                      .reduce((a, b) => a > b ? a : b);
              final maxAccidentValue = lineData['accident'].isEmpty
                  ? 0.0
                  : (lineData['accident'] as List<FlSpot>)
                      .map((e) => e.y)
                      .reduce((a, b) => a > b ? a : b);
              final maxStampedeValue = lineData['stampede'].isEmpty
                  ? 0.0
                  : (lineData['stampede'] as List<FlSpot>)
                      .map((e) => e.y)
                      .reduce((a, b) => a > b ? a : b);
              final maxValue = [
                maxFireValue,
                maxAccidentValue,
                maxStampedeValue
              ].reduce((a, b) => a > b ? a : b);
              final yInterval =
                  maxValue <= 10 ? 5.0 : (maxValue <= 50 ? 10.0 : 20.0);

              return SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.black87,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            String label = '';
                            Color color = Colors.white;
                            if (spot.barIndex == 0) {
                              label = 'Fire';
                              color = const Color(0xFFFF4444);
                            } else if (spot.barIndex == 1) {
                              label = 'Accident';
                              color = const Color(0xFFFFA726);
                            } else if (spot.barIndex == 2) {
                              label = 'Stampede';
                              color = const Color(0xFF9C27B0);
                            }
                            return LineTooltipItem(
                              '$label\n${spot.y.toInt()}',
                              TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white12,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value % yInterval == 0) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40, // Increased to prevent overflow
                          getTitlesWidget: (value, meta) {
                            final labels = lineData['labels'] as List<String>;
                            final index = value.toInt();
                            if (index >= 0 && index < labels.length) {
                              final label = labels[index];
                              // Only show non-empty labels (we already set empty strings for skipped labels)
                              if (label.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: SizedBox(
                                    width:
                                        40, // Fixed width to prevent overflow
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 8),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.white24, width: 1),
                        left: BorderSide(color: Colors.white24, width: 1),
                      ),
                    ),
                    lineBarsData: [
                      // Fire line
                      LineChartBarData(
                        spots: lineData['fire'] as List<FlSpot>,
                        isCurved: true,
                        color: const Color(0xFFFF4444),
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFFFF4444),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFFFF4444).withOpacity(0.1),
                        ),
                      ),
                      // Accident line
                      LineChartBarData(
                        spots: lineData['accident'] as List<FlSpot>,
                        isCurved: true,
                        color: const Color(0xFFFFA726),
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFFFFA726),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFFFFA726).withOpacity(0.1),
                        ),
                      ),
                      // Stampede line
                      LineChartBarData(
                        spots: lineData['stampede'] as List<FlSpot>,
                        isCurved: true,
                        color: const Color(0xFF9C27B0),
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF9C27B0),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF9C27B0).withOpacity(0.1),
                        ),
                      ),
                    ],
                    minY: 0,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Legend for line chart
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLineLegendItem('Fire', const Color(0xFFFF4444)),
              const SizedBox(width: 20),
              _buildLineLegendItem('Accident', const Color(0xFFFFA726)),
              const SizedBox(width: 20),
              _buildLineLegendItem('Stampede', const Color(0xFF9C27B0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMonthlyBarChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D36),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Distribution - Bar Chart',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Incident reports by month',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getFilteredData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.orange));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No data available',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              final docs = snapshot.data!;
              final barData = _processMonthlyBarDataFromSupabase(docs);

              if (barData.isEmpty) {
                return const Center(
                  child: Text('No data available',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              // Calculate max value and appropriate interval
              final maxValue = barData
                  .map((e) =>
                      e['fire'] + e['accident'] + e['stampede'] + e['normal'])
                  .reduce((a, b) => a > b ? a : b);
              final maxY = maxValue * 1.2;
              final yInterval =
                  maxValue <= 10 ? 5.0 : (maxValue <= 50 ? 10.0 : 20.0);

              return SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.black87,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String type = '';
                          switch (rodIndex) {
                            case 0:
                              type = 'Fire';
                              break;
                            case 1:
                              type = 'Accident';
                              break;
                            case 2:
                              type = 'Stampede';
                              break;
                            case 3:
                              type = 'Normal';
                              break;
                          }
                          return BarTooltipItem(
                            '$type\n${rod.toY.toInt()}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45, // Increased to prevent overflow
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < barData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: SizedBox(
                                  width: 35, // Fixed width to prevent overflow
                                  child: Text(
                                    barData[index]['label'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 8,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value % yInterval == 0) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white12,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.white24, width: 1),
                        left: BorderSide(color: Colors.white24, width: 1),
                      ),
                    ),
                    barGroups: List.generate(barData.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: barData[index]['fire'],
                            color: const Color(0xFFFF4444),
                            width: 12,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                          BarChartRodData(
                            toY: barData[index]['accident'],
                            color: const Color(0xFFFFA726),
                            width: 12,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                          BarChartRodData(
                            toY: barData[index]['stampede'],
                            color: const Color(0xFF9C27B0),
                            width: 12,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                          BarChartRodData(
                            toY: barData[index]['normal'],
                            color: const Color(0xFF4CAF50),
                            width: 12,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Legend for bar chart
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBarLegendItem('Fire', const Color(0xFFFF4444)),
              const SizedBox(width: 16),
              _buildBarLegendItem('Accident', const Color(0xFFFFA726)),
              const SizedBox(width: 16),
              _buildBarLegendItem('Stampede', const Color(0xFF9C27B0)),
              const SizedBox(width: 16),
              _buildBarLegendItem('Normal', const Color(0xFF4CAF50)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _getFilteredData() async {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedTimeRange) {
      case '24 hours':
        startDate = now.subtract(const Duration(hours: 24));
        break;
      case '7 days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30 days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '90 days':
        startDate = now.subtract(const Duration(days: 90));
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    try {
      // Get data from Supabase 'insights' table (where disasters are stored)
      final response = await supabase
          .from('insights')
          .select('*')
          .gte('created_at', startDate.toIso8601String())
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> allData = [];

      if (response.isNotEmpty) {
        allData = List<Map<String, dynamic>>.from(response);
      }

      print(
          '✅ Fetched ${allData.length} disaster reports from Supabase insights table');
      return allData;
    } catch (e) {
      print('❌ Error fetching analytics data: $e');
      return [];
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return const Color(0xFFFF4444); // Bright red for fire
      case 'accident':
        return const Color(0xFFFFA726); // Orange for accident
      case 'stampede':
        return const Color(0xFF9C27B0); // Purple for stampede
      case 'normal':
        return const Color(0xFF4CAF50); // Green for normal
      default:
        return Colors.grey;
    }
  }

  // Process data for disaster line chart (3 separate lines)
  // Process Supabase data for line chart
  Map<String, dynamic> _processDisasterLineDataFromSupabase(
      List<Map<String, dynamic>> docs) {
    final fireData = <DateTime, int>{};
    final accidentData = <DateTime, int>{};
    final stampedeData = <DateTime, int>{};

    // Always group by day for consistent date display
    for (var doc in docs) {
      final createdAt = doc['created_at'] as String?;
      if (createdAt != null) {
        final dateTime = DateTime.parse(createdAt);
        // Group by day only
        final dayKey = DateTime(dateTime.year, dateTime.month, dateTime.day);
        final type = (doc['disaster_type'] ?? '').toString().toLowerCase();

        if (type == 'fire') {
          fireData[dayKey] = (fireData[dayKey] ?? 0) + 1;
        } else if (type == 'accident') {
          accidentData[dayKey] = (accidentData[dayKey] ?? 0) + 1;
        } else if (type == 'stampede') {
          stampedeData[dayKey] = (stampedeData[dayKey] ?? 0) + 1;
        }
      }
    }

    // Get all unique dates sorted
    final allDates = <DateTime>{};
    allDates.addAll(fireData.keys);
    allDates.addAll(accidentData.keys);
    allDates.addAll(stampedeData.keys);

    if (allDates.isEmpty) {
      return {
        'fire': <FlSpot>[],
        'accident': <FlSpot>[],
        'stampede': <FlSpot>[],
        'labels': <String>[],
      };
    }

    final sortedDates = allDates.toList()..sort();

    // Always create a date range spanning multiple days for better visualization
    final List<DateTime> dateRange;
    if (sortedDates.length <= 1) {
      // If 1 or 0 dates, create a 7-day range
      final referenceDate =
          sortedDates.isEmpty ? DateTime.now() : sortedDates[0];
      dateRange = [];
      for (int i = -6; i <= 0; i++) {
        dateRange.add(DateTime(
            referenceDate.year, referenceDate.month, referenceDate.day + i));
      }
    } else if (sortedDates.length < 5) {
      // If less than 5 dates, fill in the gaps
      final firstDate = sortedDates.first;
      final lastDate = sortedDates.last;
      final daysDiff = lastDate.difference(firstDate).inDays;

      if (daysDiff < 6) {
        // Extend to 7 days
        dateRange = [];
        for (int i = 0; i < 7; i++) {
          dateRange.add(
              DateTime(firstDate.year, firstDate.month, firstDate.day + i));
        }
      } else {
        dateRange = sortedDates;
      }
    } else {
      dateRange = sortedDates;
    }

    // Create labels - always show date format "dd MMM"
    final labels = <String>[];

    // Calculate interval to show maximum 4-5 labels to avoid overcrowding
    int labelInterval;
    if (dateRange.length <= 5) {
      labelInterval = 1; // Show all labels for small datasets
    } else if (dateRange.length <= 10) {
      labelInterval = 2; // Show every 2nd label
    } else if (dateRange.length <= 20) {
      labelInterval = 4; // Show every 4th label
    } else {
      labelInterval = (dateRange.length / 4).ceil(); // Show max 4 labels
    }

    for (int i = 0; i < dateRange.length; i++) {
      // Show first, last, and evenly spaced labels with better spacing
      if (i == 0 ||
          i == dateRange.length - 1 ||
          (i % labelInterval == 0 &&
              i > labelInterval &&
              i < dateRange.length - labelInterval)) {
        // Use shorter date format to prevent overlap
        labels.add(DateFormat('dd/MM').format(dateRange[i]));
      } else {
        labels.add(''); // Empty label
      }
    }

    // Create FlSpot lists for each disaster type
    final fireSpots = <FlSpot>[];
    final accidentSpots = <FlSpot>[];
    final stampedeSpots = <FlSpot>[];

    for (int i = 0; i < dateRange.length; i++) {
      final date = dateRange[i];
      fireSpots.add(FlSpot(i.toDouble(), (fireData[date] ?? 0).toDouble()));
      accidentSpots
          .add(FlSpot(i.toDouble(), (accidentData[date] ?? 0).toDouble()));
      stampedeSpots
          .add(FlSpot(i.toDouble(), (stampedeData[date] ?? 0).toDouble()));
    }

    return {
      'fire': fireSpots,
      'accident': accidentSpots,
      'stampede': stampedeSpots,
      'labels': labels,
    };
  }

  // Process Supabase data for monthly bar chart
  List<Map<String, dynamic>> _processMonthlyBarDataFromSupabase(
      List<Map<String, dynamic>> docs) {
    final monthlyData = <DateTime, Map<String, double>>{};

    for (var doc in docs) {
      final createdAt = doc['created_at'] as String?;
      if (createdAt != null) {
        final date = DateTime.parse(createdAt);
        // Use first day of month as key
        final monthKey = DateTime(date.year, date.month, 1);
        final type =
            (doc['disaster_type'] ?? 'normal').toString().toLowerCase();

        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {
            'fire': 0.0,
            'accident': 0.0,
            'stampede': 0.0,
            'normal': 0.0,
          };
        }

        if (type == 'fire') {
          monthlyData[monthKey]!['fire'] =
              (monthlyData[monthKey]!['fire'] ?? 0) + 1;
        } else if (type == 'accident') {
          monthlyData[monthKey]!['accident'] =
              (monthlyData[monthKey]!['accident'] ?? 0) + 1;
        } else if (type == 'stampede') {
          monthlyData[monthKey]!['stampede'] =
              (monthlyData[monthKey]!['stampede'] ?? 0) + 1;
        } else {
          monthlyData[monthKey]!['normal'] =
              (monthlyData[monthKey]!['normal'] ?? 0) + 1;
        }
      }
    }

    // Create last 6 months array (fill missing months with zeros)
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
    final allMonths = <DateTime>[];

    for (int i = 0; i < 6; i++) {
      final month = DateTime(sixMonthsAgo.year, sixMonthsAgo.month + i, 1);
      allMonths.add(month);
    }

    // Convert to list format with proper labels
    final result = allMonths.map((month) {
      final data = monthlyData[month] ??
          {
            'fire': 0.0,
            'accident': 0.0,
            'stampede': 0.0,
            'normal': 0.0,
          };

      return {
        'label': DateFormat('MMM')
            .format(month), // Shorter format to prevent overlap
        'fire': data['fire']!,
        'accident': data['accident']!,
        'stampede': data['stampede']!,
        'normal': data['normal']!,
      };
    }).toList();

    return result;
  }
}
