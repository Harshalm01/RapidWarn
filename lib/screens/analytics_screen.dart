import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
            _buildHeatmapSection(),
            const SizedBox(height: 24),
            _buildTrendAnalysis(),
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
            .where(
                (doc) => (doc['prediction'] ?? doc['classification']) == 'fire')
            .length;
        final accidents = docs
            .where((doc) =>
                (doc['prediction'] ?? doc['classification']) == 'accident')
            .length;
        final avgConfidence = docs.isEmpty
            ? 0.0
            : docs
                    .map((doc) => (doc['confidence'] ?? 0.0).toDouble())
                    .reduce((a, b) => a + b) /
                docs.length;

        return Row(
          children: [
            Expanded(
                child: _buildSummaryCard(
                    'Total Reports', totalReports.toString(), Colors.blue)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSummaryCard(
                    'Fire Incidents', fireReports.toString(), Colors.red)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSummaryCard(
                    'Accidents', accidents.toString(), Colors.orange)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSummaryCard(
                    'Avg Confidence',
                    '${(avgConfidence * 100).toStringAsFixed(1)}%',
                    Colors.green)),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold),
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
                  margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
                  padding: const EdgeInsets.all(16),
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
          StreamBuilder<QuerySnapshot>(
            stream: _getFilteredStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.orange));
              }

              final docs = snapshot.data!.docs;
              final typeData = <String, int>{};

              for (var doc in docs) {
                final type = (doc['prediction'] ?? doc['classification'] ?? 'normal').toString().toLowerCase();
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
                        title: '${entry.value}\n${percentage.toStringAsFixed(1)}%',
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
      {'type': 'accident', 'color': const Color(0xFFFFA726), 'label': 'Accident'},
      {'type': 'stampede', 'color': const Color(0xFF9C27B0), 'label': 'Stampede'},
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
          StreamBuilder<QuerySnapshot>(
            stream: _getFilteredStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.orange));
              }

              final docs = snapshot.data!.docs;
              final lineData = _processDisasterLineData(docs);

              if (lineData['fire']!.isEmpty && lineData['accident']!.isEmpty && lineData['stampede']!.isEmpty) {
                return const Center(
                  child: Text('No data available',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              return SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
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
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final labels = lineData['labels'] as List<String>;
                            final index = value.toInt();
                            if (index >= 0 && index < labels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  labels[index],
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
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
          StreamBuilder<QuerySnapshot>(
            stream: _getFilteredStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.orange));
              }

              final docs = snapshot.data!.docs;
              final barData = _processMonthlyBarData(docs);

              if (barData.isEmpty) {
                return const Center(
                  child: Text('No data available',
                      style: TextStyle(color: Colors.grey)),
                );
              }

              return SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: barData.map((e) => e['fire'] + e['accident'] + e['stampede'] + e['normal']).reduce((a, b) => a > b ? a : b) * 1.2,
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
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < barData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  barData[index]['label'],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
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
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            );
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
                      horizontalInterval: 1,
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

  Widget _buildHeatmapSection() {
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
            'Activity Heatmap',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hour of Day vs Day of Week',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildHourlyHeatmap(),
        ],
      ),
    );
  }

  Widget _buildHourlyHeatmap() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.orange));
        }

        final docs = snapshot.data!.docs;
        final heatmapData = _processHeatmapData(docs);

        return Column(
          children: List.generate(7, (dayIndex) {
            final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      dayNames[dayIndex],
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                  ...List.generate(24, (hourIndex) {
                    final intensity = heatmapData[dayIndex][hourIndex];
                    final color = _getHeatmapColor(intensity);

                    return Container(
                      width: 8,
                      height: 20,
                      margin: const EdgeInsets.only(right: 1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildTrendAnalysis() {
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
            'Trend Analysis',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _getFilteredStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.orange));
              }

              final docs = snapshot.data!.docs;
              final insights = _generateInsights(docs);

              return Column(
                children: insights
                    .map((insight) => _buildInsightCard(insight))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2028),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: insight['color'], width: 4)),
      ),
      child: Row(
        children: [
          Icon(insight['icon'], color: insight['color'], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight['text'],
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
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
      // First try to get data from incident_reports table (where ML results are stored)
      final incidentResponse = await supabase
          .from('incident_reports')
          .select('*')
          .gte('created_at', startDate.toIso8601String())
          .order('created_at', ascending: false);

      // Also try to get data from insights table
      final insightsResponse = await supabase
          .from('insights')
          .select('*')
          .gte('timestamp', startDate.toIso8601String())
          .order('timestamp', ascending: false);

      // Combine both data sources
      List<Map<String, dynamic>> allData = [];

      if (incidentResponse.isNotEmpty) {
        allData.addAll(List<Map<String, dynamic>>.from(incidentResponse));
      }

      if (insightsResponse.isNotEmpty) {
        allData.addAll(List<Map<String, dynamic>>.from(insightsResponse));
      }

      return allData;
    } catch (e) {
      print('Error fetching analytics data: $e');
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
  Map<String, dynamic> _processDisasterLineData(List<QueryDocumentSnapshot> docs) {
    final fireData = <String, int>{};
    final accidentData = <String, int>{};
    final stampedeData = <String, int>{};
    final format = _selectedTimeRange == '24 hours' ? 'HH:00' : 'MMM dd';

    for (var doc in docs) {
      final timestamp = doc['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final dateStr = DateFormat(format).format(timestamp.toDate());
        final type = (doc['prediction'] ?? doc['classification'] ?? '').toString().toLowerCase();
        
        if (type == 'fire') {
          fireData[dateStr] = (fireData[dateStr] ?? 0) + 1;
        } else if (type == 'accident') {
          accidentData[dateStr] = (accidentData[dateStr] ?? 0) + 1;
        } else if (type == 'stampede') {
          stampedeData[dateStr] = (stampedeData[dateStr] ?? 0) + 1;
        }
      }
    }

    // Get all unique dates sorted
    final allDates = <String>{};
    allDates.addAll(fireData.keys);
    allDates.addAll(accidentData.keys);
    allDates.addAll(stampedeData.keys);
    final sortedDates = allDates.toList()..sort();

    // Create FlSpot lists for each disaster type
    final fireSpots = <FlSpot>[];
    final accidentSpots = <FlSpot>[];
    final stampedeSpots = <FlSpot>[];

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      fireSpots.add(FlSpot(i.toDouble(), (fireData[date] ?? 0).toDouble()));
      accidentSpots.add(FlSpot(i.toDouble(), (accidentData[date] ?? 0).toDouble()));
      stampedeSpots.add(FlSpot(i.toDouble(), (stampedeData[date] ?? 0).toDouble()));
    }

    return {
      'fire': fireSpots,
      'accident': accidentSpots,
      'stampede': stampedeSpots,
      'labels': sortedDates,
    };
  }

  // Process data for monthly bar chart
  List<Map<String, dynamic>> _processMonthlyBarData(List<QueryDocumentSnapshot> docs) {
    final monthlyData = <String, Map<String, double>>{};

    for (var doc in docs) {
      final timestamp = doc['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        final monthKey = DateFormat('MMM yy').format(date);
        final type = (doc['prediction'] ?? doc['classification'] ?? 'normal').toString().toLowerCase();

        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {
            'fire': 0.0,
            'accident': 0.0,
            'stampede': 0.0,
            'normal': 0.0,
          };
        }

        if (type == 'fire') {
          monthlyData[monthKey]!['fire'] = (monthlyData[monthKey]!['fire'] ?? 0) + 1;
        } else if (type == 'accident') {
          monthlyData[monthKey]!['accident'] = (monthlyData[monthKey]!['accident'] ?? 0) + 1;
        } else if (type == 'stampede') {
          monthlyData[monthKey]!['stampede'] = (monthlyData[monthKey]!['stampede'] ?? 0) + 1;
        } else {
          monthlyData[monthKey]!['normal'] = (monthlyData[monthKey]!['normal'] ?? 0) + 1;
        }
      }
    }

    // Convert to list and sort by date
    final result = monthlyData.entries.map((entry) {
      return {
        'label': entry.key,
        'fire': entry.value['fire']!,
        'accident': entry.value['accident']!,
        'stampede': entry.value['stampede']!,
        'normal': entry.value['normal']!,
      };
    }).toList();

    // Sort by month (latest 6 months)
    result.sort((a, b) {
      try {
        final dateA = DateFormat('MMM yy').parse(a['label'] as String);
        final dateB = DateFormat('MMM yy').parse(b['label'] as String);
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });

    // Return only last 6 months
    return result.length > 6 ? result.sublist(result.length - 6) : result;
  }

  List<List<double>> _processHeatmapData(List<QueryDocumentSnapshot> docs) {
    // Initialize 7x24 matrix (7 days, 24 hours)
    final heatmap = List.generate(7, (_) => List.filled(24, 0.0));

    for (var doc in docs) {
      final timestamp = doc['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        final dayOfWeek = (date.weekday - 1) % 7; // Monday = 0
        final hour = date.hour;
        heatmap[dayOfWeek][hour] += 1.0;
      }
    }

    // Normalize to 0-1 range
    final maxValue =
        heatmap.expand((row) => row).reduce((a, b) => a > b ? a : b);
    if (maxValue > 0) {
      for (int i = 0; i < 7; i++) {
        for (int j = 0; j < 24; j++) {
          heatmap[i][j] = heatmap[i][j] / maxValue;
        }
      }
    }

    return heatmap;
  }

  Color _getHeatmapColor(double intensity) {
    if (intensity == 0) return Colors.grey[800]!;
    return Color.lerp(Colors.blue[900]!, Colors.red, intensity)!;
  }

  List<Map<String, dynamic>> _generateInsights(
      List<QueryDocumentSnapshot> docs) {
    final insights = <Map<String, dynamic>>[];

    if (docs.isEmpty) {
      insights.add({
        'icon': Icons.info,
        'color': Colors.blue,
        'text': 'No reports in the selected time period.',
      });
      return insights;
    }

    // Most common disaster type
    final typeCount = <String, int>{};
    for (var doc in docs) {
      final type = doc['prediction'] ?? 'unknown';
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }

    if (typeCount.isNotEmpty) {
      final mostCommon =
          typeCount.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add({
        'icon': Icons.trending_up,
        'color': Colors.orange,
        'text':
            'Most reported: ${mostCommon.key} (${mostCommon.value} reports)',
      });
    }

    // Peak hour analysis
    final hourCount = <int, int>{};
    for (var doc in docs) {
      final timestamp = doc['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final hour = timestamp.toDate().hour;
        hourCount[hour] = (hourCount[hour] ?? 0) + 1;
      }
    }

    if (hourCount.isNotEmpty) {
      final peakHour =
          hourCount.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add({
        'icon': Icons.schedule,
        'color': Colors.green,
        'text':
            'Peak reporting hour: ${peakHour.key}:00 (${peakHour.value} reports)',
      });
    }

    // Average confidence
    final confidences =
        docs.map((doc) => doc['confidence'] ?? 0.0).cast<double>();
    if (confidences.isNotEmpty) {
      final avgConfidence =
          confidences.reduce((a, b) => a + b) / confidences.length;
      insights.add({
        'icon': Icons.analytics,
        'color': Colors.purple,
        'text':
            'Average ML confidence: ${(avgConfidence * 100).toStringAsFixed(1)}%',
      });
    }

    return insights;
  }

  Stream<QuerySnapshot> _getFilteredStream() {
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

    // Return Firestore stream filtered by timestamp
    return FirebaseFirestore.instance
        .collection('incident_reports')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
