import 'package:path/path.dart';
import 'package:rebudget/core/models/ledger_models.dart';
import 'package:sqflite/sqflite.dart';

class LedgerRepository {
  LedgerRepository._(this._db);
  final Database _db;

  static Future<LedgerRepository> open() async {
    final db = await openDatabase(join(await getDatabasesPath(), 'rebudget_v01.db'), version: 1,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY, name TEXT NOT NULL, kind TEXT NOT NULL, parent_id INTEGER, sort_order INTEGER NOT NULL DEFAULT 0, is_archived INTEGER NOT NULL DEFAULT 0)');
        await db.execute('CREATE TABLE tags(id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, is_archived INTEGER NOT NULL DEFAULT 0)');
        await db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY, amount_fen INTEGER NOT NULL CHECK(amount_fen > 0), kind TEXT NOT NULL, payment_date TEXT NOT NULL, category_id INTEGER NOT NULL, expense_nature TEXT, note TEXT, created_at_utc TEXT NOT NULL, FOREIGN KEY(category_id) REFERENCES categories(id))');
        await db.execute('CREATE TABLE transaction_tags(transaction_id INTEGER NOT NULL, tag_id INTEGER NOT NULL, PRIMARY KEY(transaction_id, tag_id), FOREIGN KEY(transaction_id) REFERENCES transactions(id) ON DELETE CASCADE, FOREIGN KEY(tag_id) REFERENCES tags(id))');
        const seeds = [('餐饮', 'expense'), ('交通', 'expense'), ('住房', 'expense'), ('购物', 'expense'), ('娱乐', 'expense'), ('医疗', 'expense'), ('其他', 'expense'), ('工资', 'income'), ('其它收入', 'income')];
        for (var i = 0; i < seeds.length; i++) { await db.insert('categories', {'name': seeds[i].$1, 'kind': seeds[i].$2, 'sort_order': i}); }
      },
      onOpen: (db) async => db.execute('PRAGMA foreign_keys = ON'));
    return LedgerRepository._(db);
  }

  Future<List<Category>> categories(TransactionKind kind) async => (await _db.query('categories', where: 'kind = ? AND is_archived = 0', whereArgs: [kind.name], orderBy: 'sort_order, id')).map((r) => Category(id: r['id'] as int, name: r['name'] as String, kind: kind, parentId: r['parent_id'] as int?)).toList();
  Future<List<Tag>> tags() async => (await _db.query('tags', where: 'is_archived = 0', orderBy: 'name COLLATE NOCASE')).map((r) => Tag(id: r['id'] as int, name: r['name'] as String)).toList();
  Future<Tag> createTag(String name) async { final id = await _db.insert('tags', {'name': name.trim()}); return Tag(id: id, name: name.trim()); }

  Future<void> addTransaction({required int amountFen, required TransactionKind kind, required DateTime date, required int categoryId, required List<int> tagIds, required ExpenseNature? nature, String? note}) async {
    await _db.transaction((txn) async {
      final id = await txn.insert('transactions', {'amount_fen': amountFen, 'kind': kind.name, 'payment_date': dateKey(date), 'category_id': categoryId, 'expense_nature': nature?.name, 'note': note == null || note.trim().isEmpty ? null : note.trim(), 'created_at_utc': DateTime.now().toUtc().toIso8601String()});
      for (final tagId in tagIds) { await txn.insert('transaction_tags', {'transaction_id': id, 'tag_id': tagId}); }
    });
  }

  Future<List<LedgerTransaction>> transactions({int? categoryId, int? tagId, AnalyticsPeriod? period}) async {
    final clauses = <String>[]; final args = <Object?>[];
    if (categoryId != null) { clauses.add('t.category_id = ?'); args.add(categoryId); }
    if (tagId != null) { clauses.add('EXISTS (SELECT 1 FROM transaction_tags ft WHERE ft.transaction_id=t.id AND ft.tag_id=?)'); args.add(tagId); }
    if (period != null) {
      final range = analyticsRange(period, DateTime.now());
      if (range.end != null) { clauses.add('t.payment_date >= ? AND t.payment_date < ?'); args.addAll([dateKey(range.start), dateKey(range.end!)]); }
    }
    final rows = await _db.rawQuery('SELECT t.*, c.name category_name FROM transactions t JOIN categories c ON c.id=t.category_id ${clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}'} ORDER BY payment_date DESC, id DESC', args);
    final result = <LedgerTransaction>[];
    for (final r in rows) {
      final tagRows = await _db.rawQuery('SELECT g.id, g.name FROM tags g JOIN transaction_tags tt ON tt.tag_id=g.id WHERE tt.transaction_id=? ORDER BY g.name', [r['id']]);
      result.add(LedgerTransaction(id: r['id'] as int, amountFen: r['amount_fen'] as int, kind: TransactionKind.values.byName(r['kind'] as String), paymentDate: DateTime.parse(r['payment_date'] as String), categoryId: r['category_id'] as int, categoryName: r['category_name'] as String, tags: tagRows.map((t) => Tag(id: t['id'] as int, name: t['name'] as String)).toList(), expenseNature: r['expense_nature'] == null ? null : ExpenseNature.values.byName(r['expense_nature'] as String), note: r['note'] as String?));
    }
    return result;
  }

  Future<Map<int, int>> categoryTotals(AnalyticsPeriod period) async {
    final range = analyticsRange(period, DateTime.now());
    final where = range.end == null ? '' : ' AND payment_date >= ? AND payment_date < ?';
    final args = range.end == null ? <Object?>[] : [dateKey(range.start), dateKey(range.end!)];
    return {for (final r in await _db.rawQuery("SELECT category_id, SUM(amount_fen) total FROM transactions WHERE kind='expense' AND expense_nature='regular'$where GROUP BY category_id ORDER BY total DESC", args)) r['category_id'] as int: r['total'] as int};
  }

  Future<Map<int, int>> tagTotals(AnalyticsPeriod period) async {
    final range = analyticsRange(period, DateTime.now());
    final where = range.end == null ? '' : ' AND t.payment_date >= ? AND t.payment_date < ?';
    final args = range.end == null ? <Object?>[] : [dateKey(range.start), dateKey(range.end!)];
    return {for (final r in await _db.rawQuery("SELECT tt.tag_id, SUM(t.amount_fen) total FROM transaction_tags tt JOIN transactions t ON t.id=tt.transaction_id WHERE t.kind='expense' AND t.expense_nature='regular'$where GROUP BY tt.tag_id ORDER BY total DESC", args)) r['tag_id'] as int: r['total'] as int};
  }
}
