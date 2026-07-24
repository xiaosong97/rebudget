import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rebudget/core/database/ledger_repository.dart';
import 'package:rebudget/core/models/ledger_models.dart';

final repositoryProvider = Provider<LedgerRepository>((_) => throw UnimplementedError());
final reloadProvider = StateProvider<int>((_) => 0);
final transactionsProvider = FutureProvider<List<LedgerTransaction>>((ref) { ref.watch(reloadProvider); return ref.read(repositoryProvider).transactions(); });
final categoriesProvider = FutureProvider.family<List<Category>, TransactionKind>((ref, kind) { ref.watch(reloadProvider); return ref.read(repositoryProvider).categories(kind); });
final tagsProvider = FutureProvider<List<Tag>>((ref) { ref.watch(reloadProvider); return ref.read(repositoryProvider).tags(); });

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await LedgerRepository.open();
  runApp(ProviderScope(overrides: [repositoryProvider.overrideWithValue(repository)], child: const RebudgetApp()));
}

class RebudgetApp extends StatelessWidget {
  const RebudgetApp({super.key});
  @override Widget build(BuildContext context) => const CupertinoApp(debugShowCheckedModeBanner: false, title: '复账', home: AppShell());
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});
  @override Widget build(BuildContext context) => CupertinoTabScaffold(
    tabBar: const CupertinoTabBar(items: [
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), label: '首页'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.list_bullet), label: '账单'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.chart_bar), label: '分析'),
    ]),
    tabBuilder: (_, index) => CupertinoTabView(builder: (_) => switch(index) { 0 => const HomePage(), 1 => const TransactionsPage(), _ => const InsightsPage() }),
  );
}

class PageScaffold extends StatelessWidget {
  const PageScaffold({super.key, required this.title, required this.child, this.trailing});
  final String title; final Widget child; final Widget? trailing;
  @override Widget build(BuildContext context) => CupertinoPageScaffold(navigationBar: CupertinoNavigationBar(middle: Text(title), trailing: trailing), child: SafeArea(child: child));
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(transactionsProvider);
    return PageScaffold(title: '复账', trailing: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => _openEntry(context), child: const Icon(CupertinoIcons.add_circled_solid)), child: entries.when(
      loading: () => const Center(child: CupertinoActivityIndicator()), error: (_, __) => const Center(child: Text('暂时无法读取本地账本')),
      data: (items) { final regular = items.where((e) => e.kind == TransactionKind.expense && e.expenseNature == ExpenseNature.regular).fold(0, (int sum, e) => sum + e.amountFen); final income = items.where((e) => e.kind == TransactionKind.income).fold(0, (int sum, e) => sum + e.amountFen);
        return ListView(padding: const EdgeInsets.all(20), children: [
          const Text('今天，记下一笔', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Text('所有数据仅保存在这台设备上。', style: TextStyle(color: CupertinoColors.secondaryLabel)), const SizedBox(height: 22),
          Row(children: [Expanded(child: _Metric(label: '常规支出', value: formatFen(regular))), const SizedBox(width: 12), Expanded(child: _Metric(label: '收入', value: formatFen(income)))]), const SizedBox(height: 24),
          CupertinoButton.filled(onPressed: () => _openEntry(context), child: const Text('记一笔')),
          const SizedBox(height: 26), const Text('最近账单', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)), const SizedBox(height: 8), ...items.take(5).map(_TransactionRow.new),
        ]);
      },
    ));
  }
}
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});
  final String label; final bool selected; final VoidCallback onTap;
  @override Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), onPressed: onTap,
    color: selected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5.resolveFrom(context),
    borderRadius: BorderRadius.circular(99),
    child: Text(label, style: TextStyle(fontSize: 14, color: selected ? CupertinoColors.white : CupertinoColors.label.resolveFrom(context))),
  );
}

class _Metric extends StatelessWidget { const _Metric({required this.label, required this.value}); final String label, value; @override Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(color: CupertinoColors.systemGrey6.resolveFrom(context), borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: CupertinoColors.secondaryLabel)), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))]))); }

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => PageScaffold(title: '账单', trailing: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => _openEntry(context), child: const Icon(CupertinoIcons.add)), child: ref.watch(transactionsProvider).when(loading: () => const Center(child: CupertinoActivityIndicator()), error: (_, __) => const Center(child: Text('无法读取账单')), data: (items) => items.isEmpty ? const Center(child: Text('还没有账单\n点击右上角开始记账', textAlign: TextAlign.center)) : ListView.separated(padding: const EdgeInsets.all(16), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) => _TransactionRow(items[i]))));
}
class _TransactionRow extends StatelessWidget { const _TransactionRow(this.entry); final LedgerTransaction entry; @override Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(color: CupertinoColors.systemBackground.resolveFrom(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: CupertinoColors.separator.resolveFrom(context))), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry.categoryName, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 3), Text('${dateKey(entry.paymentDate)}${entry.tags.isEmpty ? '' : ' · ${entry.tags.map((e) => e.name).join('、')}' }', style: const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel))])), Text('${entry.kind == TransactionKind.expense ? '-' : '+'}${formatFen(entry.amountFen)}', style: TextStyle(fontWeight: FontWeight.w700, color: entry.kind == TransactionKind.expense ? CupertinoColors.label : CupertinoColors.systemGreen))]))); }

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});
  @override ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  AnalyticsPeriod period = AnalyticsPeriod.month;

  @override Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider(TransactionKind.expense));
    final tags = ref.watch(tagsProvider);
    final reload = ref.watch(reloadProvider);
    return PageScaffold(
      title: '分析',
      child: categories.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (_, __) => const Center(child: Text('无法读取分析')),
        data: (cats) => tags.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (_, __) => const Center(child: Text('无法读取标签')),
          data: (tagList) => FutureBuilder<List<Map<int, int>>>(
            key: ValueKey('$period-$reload'),
            future: Future.wait([
              ref.read(repositoryProvider).categoryTotals(period),
              ref.read(repositoryProvider).tagTotals(period),
            ]),
            builder: (_, snapshot) {
              if (!snapshot.hasData) return const Center(child: CupertinoActivityIndicator());
              final categoryTotals = snapshot.data![0];
              final tagTotals = snapshot.data![1];
              return ListView(padding: const EdgeInsets.all(20), children: [
                const Text('支出分析', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('仅统计常规支出；同一账单可归入多个标签。', style: TextStyle(color: CupertinoColors.secondaryLabel)),
                const SizedBox(height: 18),
                CupertinoSlidingSegmentedControl<AnalyticsPeriod>(
                  groupValue: period,
                  children: {for (final value in AnalyticsPeriod.values) value: Text(analyticsPeriodLabel(value))},
                  onValueChanged: (value) => setState(() => period = value!),
                ),
                const SizedBox(height: 24),
                Text('${analyticsPeriodLabel(period)}分类排行', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (categoryTotals.isEmpty) const Text('这个周期还没有常规支出。', style: TextStyle(color: CupertinoColors.secondaryLabel)),
                ...cats.where((c) => categoryTotals.containsKey(c.id)).map((c) => _AnalysisRow(
                  name: c.name, amount: categoryTotals[c.id]!,
                  onTap: () => _openFilteredTransactions(context, title: '${c.name}账单', categoryId: c.id, period: period),
                )),
                const SizedBox(height: 24),
                Text('${analyticsPeriodLabel(period)}热点标签', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('按带该标签的常规支出累计排序。', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
                const SizedBox(height: 8),
                if (tagTotals.isEmpty) const Text('为账单添加标签后，即可在这里查看消费场景。', style: TextStyle(color: CupertinoColors.secondaryLabel)),
                ...tagList.where((t) => tagTotals.containsKey(t.id)).map((t) => _AnalysisRow(
                  name: t.name, amount: tagTotals[t.id]!,
                  onTap: () => _openFilteredTransactions(context, title: '#${t.name}', tagId: t.id, period: period),
                )),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  const _AnalysisRow({required this.name, required this.amount, required this.onTap});
  final String name; final int amount; final VoidCallback onTap;
  @override Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.symmetric(vertical: 10), onPressed: onTap,
    child: Row(children: [Expanded(child: Text(name, style: const TextStyle(color: CupertinoColors.label))), Text(formatFen(amount), style: const TextStyle(fontWeight: FontWeight.w600, color: CupertinoColors.label)), const SizedBox(width: 6), const Icon(CupertinoIcons.chevron_right, size: 15)]),
  );
}

void _openFilteredTransactions(BuildContext context, {required String title, int? categoryId, int? tagId, AnalyticsPeriod? period}) {
  Navigator.of(context).push(CupertinoPageRoute(builder: (_) => FilteredTransactionsPage(title: title, categoryId: categoryId, tagId: tagId, period: period)));
}

class FilteredTransactionsPage extends ConsumerWidget {
  const FilteredTransactionsPage({super.key, required this.title, this.categoryId, this.tagId, this.period});
  final String title; final int? categoryId; final int? tagId; final AnalyticsPeriod? period;
  @override Widget build(BuildContext context, WidgetRef ref) {
    final reload = ref.watch(reloadProvider);
    return PageScaffold(title: title, child: FutureBuilder<List<LedgerTransaction>>(
      key: ValueKey(reload), future: ref.read(repositoryProvider).transactions(categoryId: categoryId, tagId: tagId, period: period),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Center(child: CupertinoActivityIndicator());
        final entries = snapshot.data!;
        return entries.isEmpty ? const Center(child: Text('这个筛选下还没有账单')) : ListView.separated(padding: const EdgeInsets.all(16), itemCount: entries.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, index) => _TransactionRow(entries[index]));
      },
    ));
  }
}

Future<void> _openEntry(BuildContext context) => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const EntryPage()));

class EntryPage extends ConsumerStatefulWidget { const EntryPage({super.key}); @override ConsumerState<EntryPage> createState() => _EntryPageState(); }
class _EntryPageState extends ConsumerState<EntryPage> {
  final amount = TextEditingController(); final note = TextEditingController(); TransactionKind kind = TransactionKind.expense; ExpenseNature nature = ExpenseNature.regular; DateTime date = DateTime.now(); int? categoryId; final selectedTags = <int>{};
  @override void dispose() { amount.dispose(); note.dispose(); super.dispose(); }
  Future<void> save() async { final parsed = parseFen(amount.text); if (parsed == null || parsed == 0 || categoryId == null) { await showCupertinoDialog<void>(context: context, builder: (_) => CupertinoAlertDialog(title: const Text('请完善账单'), content: const Text('请输入正确金额并选择分类。'), actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('好'))])); return; } await ref.read(repositoryProvider).addTransaction(amountFen: parsed, kind: kind, date: date, categoryId: categoryId!, tagIds: selectedTags.toList(), nature: kind == TransactionKind.expense ? nature : null, note: note.text); ref.read(reloadProvider.notifier).state++; if (mounted) Navigator.pop(context); }
  @override Widget build(BuildContext context) { final cats = ref.watch(categoriesProvider(kind)); final tags = ref.watch(tagsProvider); return PageScaffold(title: '记一笔', trailing: CupertinoButton(padding: EdgeInsets.zero, onPressed: save, child: const Text('保存')), child: ListView(padding: const EdgeInsets.all(20), children: [CupertinoSlidingSegmentedControl<TransactionKind>(groupValue: kind, children: const {TransactionKind.expense: Text('支出'), TransactionKind.income: Text('收入')}, onValueChanged: (v) => setState(() { kind = v!; categoryId = null; })), const SizedBox(height: 20), CupertinoTextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), placeholder: '金额，例如 28.50', prefix: const Padding(padding: EdgeInsets.only(left: 12), child: Text('¥ ')), padding: const EdgeInsets.all(14)), const SizedBox(height: 10), CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), alignment: Alignment.centerLeft, onPressed: _selectDate, child: Text('记账日期  ${dateKey(date)}')), const SizedBox(height: 10), const Text('分类', style: TextStyle(fontWeight: FontWeight.w600)), cats.when(loading: () => const CupertinoActivityIndicator(), error: (_, __) => const Text('分类加载失败'), data: (items) => Wrap(spacing: 8, runSpacing: 8, children: items.map((c) => _Pill(label: c.name, selected: categoryId == c.id, onTap: () => setState(() => categoryId = c.id))).toList())), if (kind == TransactionKind.expense) ...[const SizedBox(height: 18), const Text('支出属性', style: TextStyle(fontWeight: FontWeight.w600)), CupertinoSlidingSegmentedControl<ExpenseNature>(groupValue: nature, children: const {ExpenseNature.regular: Text('常规'), ExpenseNature.special: Text('特殊')}, onValueChanged: (v) => setState(() => nature = v!))], const SizedBox(height: 18), const Text('标签', style: TextStyle(fontWeight: FontWeight.w600)), tags.when(loading: () => const CupertinoActivityIndicator(), error: (_, __) => const Text('标签加载失败'), data: (items) => Wrap(spacing: 8, runSpacing: 8, children: [...items.map((t) => _Pill(label: t.name, selected: selectedTags.contains(t.id), onTap: () => setState(() => selectedTags.contains(t.id) ? selectedTags.remove(t.id) : selectedTags.add(t.id))), _Pill(label: '+ 新标签', selected: false, onTap: _newTag)])), const SizedBox(height: 18), CupertinoTextField(controller: note, placeholder: '备注（可选）', maxLines: 3, padding: const EdgeInsets.all(14))])); }
  Future<void> _selectDate() async {
    var selected = date;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(children: [
          Align(alignment: Alignment.centerRight, child: CupertinoButton(onPressed: () { setState(() => date = selected); Navigator.pop(context); }, child: const Text('完成'))),
          Expanded(child: CupertinoDatePicker(initialDateTime: date, maximumDate: DateTime.now(), mode: CupertinoDatePickerMode.date, onDateTimeChanged: (value) => selected = value)),
        ]),
      ),
    );
  }

  Future<void> _newTag() async { final controller = TextEditingController(); final result = await showCupertinoDialog<String>(context: context, builder: (_) => CupertinoAlertDialog(title: const Text('新标签'), content: Padding(padding: const EdgeInsets.only(top: 12), child: CupertinoTextField(controller: controller, placeholder: '例如：工作日')), actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('取消')), CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(context, controller.text), child: const Text('添加'))])); if (result == null || result.trim().isEmpty) return; try { final tag = await ref.read(repositoryProvider).createTag(result); setState(() => selectedTags.add(tag.id)); ref.read(reloadProvider.notifier).state++; } catch (_) { if (mounted) await showCupertinoDialog<void>(context: context, builder: (_) => CupertinoAlertDialog(title: const Text('标签已存在'), actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('好'))])); } }
}
