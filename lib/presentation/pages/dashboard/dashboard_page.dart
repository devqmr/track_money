import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/expense/expense_bloc.dart';
import '../profile/profile_page.dart';
import '../../widgets/expense/month_selector.dart';
import '../../../core/utils/currency_utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  // Get currency color from central utility
  Color getCurrencyColor(String currencyCode) {
    return CurrencyUtils.getCurrencyColor(currencyCode);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    
    final userId = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
        : '';
    
    if (userId.isNotEmpty) {
      // Check if we already have an ExpenseLoaded state with a selected month
      final expenseState = context.read<ExpenseBloc>().state;
      final DateTime month = expenseState is ExpenseLoaded
          ? expenseState.selectedMonth
          : DateTime.now();
      
      // Only load if not already loaded or if month is different
      if (expenseState is! ExpenseLoaded || 
          expenseState.selectedMonth.month != month.month || 
          expenseState.selectedMonth.year != month.year) {
        context.read<ExpenseBloc>().add(
          LoadExpensesByMonth(
            month: month,
            userId: userId,
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final userId = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
        : '';
    
    if (userId.isNotEmpty) {
      final DateTime selectedMonth = context.read<ExpenseBloc>().state is ExpenseLoaded 
          ? (context.read<ExpenseBloc>().state as ExpenseLoaded).selectedMonth
          : DateTime.now();
      
      context.read<ExpenseBloc>().add(
        LoadExpensesByMonth(
          month: selectedMonth,
          userId: userId,
        ),
      );
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state is ExpenseInitial || state is ExpenseLoading) {
          return _buildLoadingIndicator();
        } else if (state is ExpenseError) {
          return _buildErrorState(state.message);
        } else if (state is ExpenseLoaded) {
          return _buildDashboard(context, state);
        }
        
        return const Center(
          child: Text(
            'No data available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
      ),
    );
  }
  
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $message',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDashboard(BuildContext context, ExpenseLoaded state) {
    final totalExpenseAmount = state.totalByCurrency.values.fold<double>(0, (sum, amount) => sum + amount);
    final currencyFormatter = NumberFormat.currency(symbol: '');
    final dateFormat = DateFormat('MMMM yyyy');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = Theme.of(context).textTheme.bodySmall?.color;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    
    // Prepare data for category breakdown
    final categoryData = _prepareCategoryData(state);
    
    // Prepare data for payment methods
    final paymentMethodData = _preparePaymentMethodData(state);
    
    return RefreshIndicator(
      key: _refreshKey,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: surfaceColor,
      strokeWidth: 2.5,
      onRefresh: _refreshData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Month selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeInOut,
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
                child: MonthSelector(
                  selectedMonth: state.selectedMonth,
                  onPreviousMonth: () => _changeMonth(state.selectedMonth, -1),
                  onNextMonth: () => _changeMonth(state.selectedMonth, 1),
                ),
              ),
            ),
          ),
          
          // Monthly report card - with unified UI
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 20.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeInOut,
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Theme.of(context).cardTheme.color
                      : const Color(0xFFEFF8F1),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.assessment_outlined,
                              size: 20,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Report this month',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          height: 24, 
                          thickness: 0.5, 
                          color: Theme.of(context).dividerTheme.color,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Outflow',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: state.totalByCurrency.entries.map((entry) {
                                final currencyCode = entry.key;
                                final currencyColor = getCurrencyColor(currencyCode);
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: currencyColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          currencyCode,
                                          style: TextStyle(
                                            color: currencyColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        entry.value.toStringAsFixed(2),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Expenses by day
          SliverToBoxAdapter(
            child: _buildExpensesList(context, state),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Weekly spending',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Weekly bar chart
          SliverToBoxAdapter(
            child: _buildWeeklyBarChart(context, state),
          ),
          
          SliverToBoxAdapter(
            child: _buildCategoryBreakdown(context, categoryData),
          ),
          
          SliverToBoxAdapter(
            child: _buildPaymentMethodBreakdown(context, paymentMethodData),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedSection({
    required Widget child,
    double delay = 0.0,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, childWidget) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              delay, 
              1.0,
              curve: Curves.easeInOut,
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                delay, 
                1.0, 
                curve: Curves.easeOut,
              ),
            )),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
  
  Widget _buildExpenseOverview(
    BuildContext context,
    ExpenseLoaded state,
    double totalExpenseAmount,
    NumberFormat currencyFormatter,
  ) {
    // Prepare weekly spending data
    final weeklyData = _prepareWeeklyData(state);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Expense Overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: state.totalByCurrency.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${currencyFormatter.format(entry.value)} ${entry.key}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Expenses',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Weekly Spending',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Material(
              color: Colors.transparent,
              elevation: 0,
              child: Stack(
                children: [
                  BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: weeklyData.isEmpty ? 10 : null,
                      barTouchData: BarTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchExtraThreshold: const EdgeInsets.all(10),
                        touchCallback: (event, response) {
                          if (event is FlTapUpEvent || event is FlLongPressEnd) {
                            HapticFeedback.lightImpact();
                          }
                        },
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: isDarkMode 
                              ? Theme.of(context).colorScheme.surface 
                              : Colors.blueGrey.shade800,
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          tooltipMargin: 8,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          tooltipRoundedRadius: 8,
                          tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                          tooltipHorizontalOffset: 0,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final dayIndex = group.x.toInt();
                            
                            final dayData = state.expensesByDate.entries
                              .where((entry) => (entry.key.weekday + 1) % 7 == dayIndex)
                              .toList();
                            
                            if (dayData.isEmpty) {
                              return BarTooltipItem(
                                'No expenses',
                                TextStyle(
                                  color: isDarkMode 
                                    ? Theme.of(context).colorScheme.onSurface 
                                    : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                            
                            final Map<String, double> currencyTotals = {};
                            for (final entry in dayData) {
                              for (final expense in entry.value) {
                                if (!currencyTotals.containsKey(expense.currency)) {
                                  currencyTotals[expense.currency] = 0;
                                }
                                currencyTotals[expense.currency] = 
                                    currencyTotals[expense.currency]! + expense.amount;
                              }
                            }
                            
                            final buffer = StringBuffer();
                            buffer.writeln('Daily Total');
                            
                            currencyTotals.forEach((currency, total) {
                              buffer.writeln('${currencyFormatter.format(total)} $currency');
                            });
                            
                            return BarTooltipItem(
                              buffer.toString(),
                              TextStyle(
                                color: isDarkMode 
                                    ? Theme.of(context).colorScheme.onSurface 
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: isDarkMode 
                                      ? Theme.of(context).colorScheme.onSurface 
                                      : Colors.white70,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  days[value.toInt() % 7],
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      gridData: const FlGridData(
                        show: false,
                      ),
                      barGroups: weeklyData.isEmpty
                          ? [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: 0,
                                    color: _barChartColor,
                                    width: 22,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ]
                          : weeklyData,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryBreakdown(
    BuildContext context,
    Map<String, double> categoryData,
  ) {
    final categories = categoryData.keys.toList();
    final totalAmount = categoryData.values.fold<double>(0, (sum, amount) => sum + amount);
    final categoryPercentages = Map.fromEntries(
      categoryData.entries.map(
        (entry) => MapEntry(entry.key, (entry.value / totalAmount * 100).toStringAsFixed(1)),
      ),
    );
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).brightness == Brightness.dark 
          ? Theme.of(context).cardTheme.color
          : const Color(0xFFEFF8F1),
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Category Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            categories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No category data for the selected period',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: categories.map((category) {
                              final colorIndex = categories.indexOf(category) % _categoryColors.length;
                              return PieChartSectionData(
                                color: _categoryColors[colorIndex],
                                value: categoryData[category],
                                title: '${categoryPercentages[category]}%',
                                radius: 80,
                                titleStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              );
                            }).toList(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: categories.map((category) {
                          final colorIndex = categories.indexOf(category) % _categoryColors.length;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _categoryColors[colorIndex],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentMethodAnalysis(
    BuildContext context,
    Map<String, double> paymentMethodData,
  ) {
    final paymentMethods = paymentMethodData.keys.toList();
    final totalAmount = paymentMethodData.values.fold<double>(0, (sum, amount) => sum + amount);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payment,
                color: Colors.purple,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Method Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          paymentMethods.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No payment method data for the selected period',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: paymentMethods.map((method) {
                    final percentage = (paymentMethodData[method]! / totalAmount) * 100;
                    final colorIndex = paymentMethods.indexOf(method) % _paymentMethodColors.length;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                method,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _paymentMethodColors[colorIndex],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _paymentMethodColors[colorIndex],
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
  
  List<BarChartGroupData> _prepareWeeklyData(ExpenseLoaded state) {
    // Get the start of the week (Saturday) for the selected month
    final month = state.selectedMonth;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    DateTime startOfWeek = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday - 6),
    );
    
    if (startOfWeek.isAfter(firstDayOfMonth)) {
      startOfWeek = startOfWeek.subtract(const Duration(days: 7));
    }
    
    // Create a nested map for each day of the week and currency
    final Map<int, Map<String, double>> dailyByCurrency = {};
    
    // Keep track of all currencies
    final Set<String> allCurrencies = <String>{};
    
    // Group expenses by weekday (0 for Saturday, 6 for Friday) and currency
    for (final entry in state.expensesByDate.entries) {
      // Convert weekday to our custom index (0 = Saturday, 1 = Sunday, ..., 6 = Friday)
      final weekday = (entry.key.weekday + 1) % 7;
      
      // Initialize the day if needed
      if (!dailyByCurrency.containsKey(weekday)) {
        dailyByCurrency[weekday] = {};
      }
      
      // Group by currency
      for (final expense in entry.value) {
        final currency = expense.currency;
        allCurrencies.add(currency);
        
        if (!dailyByCurrency[weekday]!.containsKey(currency)) {
          dailyByCurrency[weekday]![currency] = 0;
        }
        
        dailyByCurrency[weekday]![currency] = 
            dailyByCurrency[weekday]![currency]! + expense.amount;
      }
    }
    
    // Convert currencies to a sorted list (for consistent coloring)
    final currencies = allCurrencies.toList()..sort();
    
    // Create stacked bar chart groups
    return List.generate(7, (dayIndex) {
      // Get totals for this day by currency
      final currencyValues = dailyByCurrency[dayIndex] ?? {};
      
      if (currencyValues.isEmpty) {
        // If no data for this day, return an empty bar
        return BarChartGroupData(
          x: dayIndex,
          barRods: [
            BarChartRodData(
              toY: 0,
              color: Colors.green.withOpacity(0.3),
              width: 24,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            )
          ],
        );
      }
      
      // Stack bars for each currency
      double fromY = 0;
      final List<BarChartRodStackItem> stackItems = [];
      
      for (int i = 0; i < currencies.length; i++) {
        final currency = currencies[i];
        final value = currencyValues[currency] ?? 0;
        
        if (value > 0) {
          final toY = fromY + value;
          stackItems.add(
            BarChartRodStackItem(
              fromY, 
              toY, 
              getCurrencyColor(currency),
            ),
          );
          fromY = toY;
        }
      }
      
      return BarChartGroupData(
        x: dayIndex,
        barRods: [
          BarChartRodData(
            toY: fromY,
            width: 24,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            rodStackItems: stackItems,
          ),
        ],
      );
    });
  }
  
  Map<String, double> _prepareCategoryData(ExpenseLoaded state) {
    final Map<String, double> categoryTotals = {};
    
    // Calculate total amount for each category
    for (final expenseList in state.expensesByDate.values) {
      for (final expense in expenseList) {
        if (!categoryTotals.containsKey(expense.category)) {
          categoryTotals[expense.category] = 0;
        }
        
        categoryTotals[expense.category] = categoryTotals[expense.category]! + expense.amount;
      }
    }
    
    // Sort categories by amount (descending)
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Return top 5 categories, combining the rest as "Others"
    if (sortedEntries.length <= 5) {
      return Map.fromEntries(sortedEntries);
    } else {
      final top5 = sortedEntries.take(5).toList();
      final otherTotal = sortedEntries.skip(5).fold<double>(
        0,
        (sum, entry) => sum + entry.value,
      );
      
      final result = Map.fromEntries(top5);
      result['Others'] = otherTotal;
      
      return result;
    }
  }
  
  Map<String, double> _preparePaymentMethodData(ExpenseLoaded state) {
    final Map<String, double> paymentMethodTotals = {};
    
    // Calculate total amount for each payment method
    for (final expenseList in state.expensesByDate.values) {
      for (final expense in expenseList) {
        if (!paymentMethodTotals.containsKey(expense.paymentMethod)) {
          paymentMethodTotals[expense.paymentMethod] = 0;
        }
        
        paymentMethodTotals[expense.paymentMethod] = 
            paymentMethodTotals[expense.paymentMethod]! + expense.amount;
      }
    }
    
    // Sort payment methods by amount (descending)
    final sortedEntries = paymentMethodTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries);
  }
  
  // Colors for category chart
  List<Color> get _categoryColors => [
    Theme.of(context).colorScheme.primary,
    Theme.of(context).colorScheme.error,
    Theme.of(context).colorScheme.tertiary,
    const Color(0xFFFFB74D), // Orange
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF009688), // Teal
    const Color(0xFFFFD54F), // Amber
    const Color(0xFFE91E63), // Pink
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF795548), // Brown
  ];
  
  // Get chart colors from app theme
  List<Color> get _chartColors => 
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme.chartColors 
          : AppTheme.chartColors;
          
  // Get bar chart color
  Color get _barChartColor => Theme.of(context).colorScheme.primary.withOpacity(0.7);

  // Colors for payment method bars
  final List<Color> _paymentMethodColors = [
    Colors.purple,
    Colors.blue,
    Colors.teal,
    Colors.amber,
    Colors.red,
    Colors.green,
    Colors.indigo,
    Colors.pink,
  ];

  // Add method to handle month changes
  void _changeMonth(DateTime currentMonth, int monthDelta) {
    HapticFeedback.lightImpact();
    final userId = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
        : '';
    
    if (userId.isNotEmpty) {
      _animationController.reset();
      _animationController.forward();
      context.read<ExpenseBloc>().add(
        ChangeMonth(
          direction: monthDelta > 0 ? MonthChangeDirection.next : MonthChangeDirection.previous,
          userId: userId,
        ),
      );
    }
  }

  Widget _buildExpensesList(BuildContext context, ExpenseLoaded state) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dateKeys = state.expensesByDate.keys.toList()..sort((a, b) => b.compareTo(a));
    
    if (dateKeys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No expenses for this period',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
      );
    }
    
    // Just show the most recent day's expenses in the dashboard
    final latestDate = dateKeys.first;
    final latestExpenses = state.expensesByDate[latestDate]!;
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).brightness == Brightness.dark 
          ? Theme.of(context).cardTheme.color
          : const Color(0xFFEFF8F1),
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Expenses',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...latestExpenses.take(3).map((expense) {
              final currencyColor = getCurrencyColor(expense.currency);
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: isDarkMode 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(expense.category),
                subtitle: Text(
                  DateFormat('MMM d, yyyy').format(expense.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: currencyColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expense.currency,
                        style: TextStyle(
                          color: currencyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      expense.amount.toStringAsFixed(2),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyBarChart(BuildContext context, ExpenseLoaded state) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: '');
    final weeklyData = _prepareWeeklyData(state);
    
    // Get all currencies for the legend
    final Set<String> allCurrencies = <String>{};
    for (final entry in state.totalByCurrency.entries) {
      allCurrencies.add(entry.key);
    }
    final currencies = allCurrencies.toList()..sort();
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).brightness == Brightness.dark 
          ? Theme.of(context).cardTheme.color
          : const Color(0xFFEFF8F1),
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add currency legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: currencies.map((currency) {
                final currencyColor = getCurrencyColor(currency);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: currencyColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currency,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Material(
                color: Colors.transparent,
                elevation: 0,
                child: Stack(
                  children: [
                    BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: weeklyData.isEmpty ? 10 : null,
                        barTouchData: BarTouchData(
                          enabled: true,
                          handleBuiltInTouches: true,
                          touchExtraThreshold: const EdgeInsets.all(10),
                          touchCallback: (event, response) {
                            if (event is FlTapUpEvent || event is FlLongPressEnd) {
                              HapticFeedback.lightImpact();
                            }
                          },
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: isDarkMode 
                                ? Theme.of(context).colorScheme.surface 
                                : Colors.blueGrey.shade800,
                            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            tooltipMargin: 8,
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipRoundedRadius: 8,
                            tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                            tooltipHorizontalOffset: 0,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final dayIndex = group.x.toInt();
                              
                              final dayData = state.expensesByDate.entries
                                .where((entry) => (entry.key.weekday + 1) % 7 == dayIndex)
                                .toList();
                              
                              if (dayData.isEmpty) {
                                return BarTooltipItem(
                                  'No expenses',
                                  TextStyle(
                                    color: isDarkMode 
                                      ? Theme.of(context).colorScheme.onSurface 
                                      : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }
                              
                              final Map<String, double> currencyTotals = {};
                              for (final entry in dayData) {
                                for (final expense in entry.value) {
                                  if (!currencyTotals.containsKey(expense.currency)) {
                                    currencyTotals[expense.currency] = 0;
                                  }
                                  currencyTotals[expense.currency] = 
                                      currencyTotals[expense.currency]! + expense.amount;
                                }
                              }
                              
                              final buffer = StringBuffer();
                              buffer.writeln('Daily Total');
                              
                              currencyTotals.forEach((currency, total) {
                                buffer.writeln('${currencyFormatter.format(total)} $currency');
                              });
                              
                              return BarTooltipItem(
                                buffer.toString(),
                                TextStyle(
                                  color: isDarkMode 
                                      ? Theme.of(context).colorScheme.onSurface 
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: isDarkMode 
                                        ? Theme.of(context).colorScheme.onSurface 
                                        : Colors.white70,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    days[value.toInt() % 7],
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                              reservedSize: 28,
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        gridData: const FlGridData(
                          show: false,
                        ),
                        barGroups: weeklyData.isEmpty
                            ? [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: 0,
                                      color: _barChartColor,
                                      width: 22,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ]
                            : weeklyData,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodBreakdown(
    BuildContext context,
    Map<String, double> paymentMethodData,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final paymentMethods = paymentMethodData.keys.toList();
    final totalAmount = paymentMethodData.values.fold<double>(0, (sum, amount) => sum + amount);
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).brightness == Brightness.dark 
          ? Theme.of(context).cardTheme.color
          : const Color(0xFFEFF8F1),
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Methods',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            paymentMethods.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No payment method data for the selected period',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: paymentMethods.take(4).map((method) {
                      final percentage = (paymentMethodData[method]! / totalAmount) * 100;
                      final colorIndex = paymentMethods.indexOf(method) % _paymentMethodColors.length;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  method,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode 
                                        ? _paymentMethodColors[colorIndex].withOpacity(0.8)
                                        : _paymentMethodColors[colorIndex],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: isDarkMode 
                                  ? Theme.of(context).cardTheme.color?.withOpacity(0.3)
                                  : Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDarkMode 
                                    ? _paymentMethodColors[colorIndex].withOpacity(0.8)
                                    : _paymentMethodColors[colorIndex],
                              ),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
} 