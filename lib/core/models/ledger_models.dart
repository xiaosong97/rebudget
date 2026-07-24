enum TransactionKind { income, expense }
enum ExpenseNature { regular, special }
enum AnalyticsPeriod { week, month, year, all }

class Category {
  const Category({required this.id, required this.name, required this.kind, this.parentId});
  final int id;
  final String name;
  final TransactionKind kind;
  final int? parentId;
}

class Tag {
  const Tag({required this.id, required this.name});
  final int id;
  final String name;
}

class LedgerTransaction {
  const LedgerTransaction({
    required this.id, required this.amountFen, required this.kind, required this.paymentDate,
    required this.categoryId, required this.categoryName, required this.tags,
    required this.expenseNature, this.note,
  });
  final int id;
  final int amountFen;
  final TransactionKind kind;
  final DateTime paymentDate;
  final int categoryId;
  final String categoryName;
  final List<Tag> tags;
  final ExpenseNature? expenseNature;
  final String? note;
}

String formatFen(int fen) => '¥${(fen / 100).toStringAsFixed(2)}';
int? parseFen(String input) {
  final value = input.trim();
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) return null;
  final pieces = value.split('.');
  return int.parse(pieces.first) * 100 + (pieces.length == 2 ? int.parse(pieces[1].padRight(2, '0')) : 0);
}
String dateKey(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';


class DateRange {
  const DateRange(this.start, this.end);
  final DateTime start;
  final DateTime? end;
}

DateRange analyticsRange(AnalyticsPeriod period, DateTime now) {
  final date = DateTime(now.year, now.month, now.day);
  return switch (period) {
    AnalyticsPeriod.week => DateRange(date.subtract(Duration(days: date.weekday - 1)), date.subtract(Duration(days: date.weekday - 1)).add(const Duration(days: 7))),
    AnalyticsPeriod.month => DateRange(DateTime(date.year, date.month), DateTime(date.year, date.month + 1)),
    AnalyticsPeriod.year => DateRange(DateTime(date.year), DateTime(date.year + 1)),
    AnalyticsPeriod.all => const DateRange(DateTime(1970), null),
  };
}

String analyticsPeriodLabel(AnalyticsPeriod period) => switch (period) {
  AnalyticsPeriod.week => '本周',
  AnalyticsPeriod.month => '本月',
  AnalyticsPeriod.year => '今年',
  AnalyticsPeriod.all => '全部',
};
