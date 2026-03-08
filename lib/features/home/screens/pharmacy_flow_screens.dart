import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/app_design.dart';
import '../data/pharmacy_repository.dart';
import '../models/home_tab.dart';
import '../models/pharmacy_reminder.dart';
import '../models/pharmacy_reminder_input.dart';
import '../models/vitamin_catalog_item.dart';
import '../models/vitamin_draft.dart';
import '../models/weekday.dart';
import '../widgets/home_tab_bar.dart';

class AddVitaminScreen extends StatefulWidget {
  const AddVitaminScreen({
    super.key,
    required this.repository,
    required this.onFlowCompleted,
    required this.onTabRequested,
    this.initialDraft,
    this.editingReminderId,
  });

  final PharmacyRepository repository;
  final VoidCallback onFlowCompleted;
  final ValueChanged<HomeTab> onTabRequested;
  final VitaminDraft? initialDraft;
  final String? editingReminderId;

  @override
  State<AddVitaminScreen> createState() => _AddVitaminScreenState();
}

class _AddVitaminScreenState extends State<AddVitaminScreen> {
  static const List<String> _vitaminTypes = [
    'Таблетки',
    'Капсулы',
    'Капли',
    'Порошок',
    'Жидкость',
    'Жевательные таблетки',
    'Ампулы',
    'Спрей',
    'Уколы',
  ];

  late VitaminDraft _draft;
  late final TextEditingController _doseController;
  late final TextEditingController _notesController;
  List<VitaminCatalogItem> _catalog = const [];
  bool _loadingCatalog = true;
  String? _catalogError;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft ?? VitaminDraft.empty();
    _doseController = TextEditingController(
      text: PharmacyFlowLogic.extractDoseAmount(_draft.dose),
    );
    _notesController = TextEditingController(text: _draft.notes);
    _loadCatalog();
  }

  @override
  void dispose() {
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loadingCatalog = true;
      _catalogError = null;
    });
    try {
      final items = await widget.repository.fetchCatalog();
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = items;
        _loadingCatalog = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingCatalog = false;
        _catalogError = 'Не удалось загрузить каталог витаминов';
      });
    }
  }

  void _goNext() {
    final name = _draft.name.trim();
    final type = _draft.type.trim();
    final dose = _doseController.text.trim();
    if (name.isEmpty || type.isEmpty || dose.isEmpty || _draft.intake == null) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Заполните обязательные поля'),
          content: const Text(
            'Пожалуйста, заполните всю информацию, кроме поля «Примечание».',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ОК'),
            ),
          ],
        ),
      );
      return;
    }

    final updatedDraft = _draft.copyWith(
      dose: PharmacyFlowLogic.composeDose(
        type: _draft.type,
        amountText: dose,
        defaultUnit: _draft.catalogDefaultUnit,
      ),
      notes: _notesController.text.trim(),
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddVitaminScheduleScreen(
          repository: widget.repository,
          draft: updatedDraft,
          editingReminderId: widget.editingReminderId,
          onFlowCompleted: widget.onFlowCompleted,
          onTabRequested: widget.onTabRequested,
        ),
      ),
    );
  }

  Future<void> _openCatalogSearch() async {
    final item = await showModalBottomSheet<_CatalogSelectionResult>(
      context: context,
      isScrollControlled: true,
      requestFocus: false,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 360),
        reverseDuration: Duration(milliseconds: 240),
      ),
      builder: (context) => _CatalogSearchSheet(
        catalog: _catalog,
        loading: _loadingCatalog,
        errorMessage: _catalogError,
        initialQuery: _draft.name,
        selectedCatalogId: _draft.catalogId,
        selectedName: _draft.name,
      ),
    );
    if (!mounted || item == null) {
      return;
    }

    if (item.catalogItem != null) {
      final catalogItem = item.catalogItem!;
      setState(() {
        _draft = _draft.copyWith(
          name: catalogItem.resolvedName,
          catalogId: catalogItem.id,
          catalogDefaultUnit: catalogItem.defaultUnit,
          catalogInteractionText: catalogItem.interactionText,
          catalogCompatibilityText: catalogItem.compatibilityText,
          catalogContraindicationsText: catalogItem.contraindicationsText,
          catalogDefaultCondition: catalogItem.defaultCondition,
        );
      });
      return;
    }

    setState(() {
      _draft = _draft.copyWith(
        name: item.customName?.trim() ?? '',
        catalogId: null,
        catalogDefaultUnit: null,
        catalogInteractionText: null,
        catalogCompatibilityText: null,
        catalogContraindicationsText: null,
        catalogDefaultCondition: null,
      );
    });
  }

  Future<void> _openVitaminTypePicker() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _vitaminTypes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final type = _vitaminTypes[index];
              return ListTile(
                title: Text(
                  type,
                  style: const TextStyle(
                    fontFamily: 'Commissioner',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: _draft.type == type
                    ? const Icon(Icons.check, color: AppPalette.blueMain)
                    : null,
                onTap: () => Navigator.of(context).pop(type),
              );
            },
          ),
        );
      },
    );

    if (value == null) {
      return;
    }
    setState(() {
      _draft = _draft.copyWith(type: value);
    });
  }

  void _handleTabTap(HomeTab tab) {
    if (tab == HomeTab.pharmacy) {
      return;
    }
    widget.onTabRequested(tab);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final doseUnit = PharmacyFlowLogic.doseUnitFor(
      type: _draft.type,
      amountText: _doseController.text,
      defaultUnit: _draft.catalogDefaultUnit,
    );

    return _PharmacyFlowScaffold(
      selectedTab: HomeTab.pharmacy,
      onTabRequested: _handleTabTap,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30, 18, 30, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepProgressBar(filledSegments: 1),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _openCatalogSearch,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/pharmacy/pen.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _draft.name.isEmpty ? 'Название' : _draft.name,
                      style: TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: _draft.name.isEmpty
                            ? Colors.black
                            : const Color(0xFF3B3B3B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _BlueFieldButton(
              label: _draft.type.isEmpty ? 'Вид витамина' : _draft.type,
              onTap: _openVitaminTypePicker,
            ),
            const SizedBox(height: 18),
            const Text(
              'Разовая доза',
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF656565),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: TextField(
                controller: _doseController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Введите количество',
                  hintStyle: const TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE3EEFF),
                  ),
                  filled: true,
                  fillColor: AppPalette.blueMain,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  suffixText: doseUnit.isEmpty ? null : doseUnit,
                  suffixStyle: const TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE3EEFF),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < IntakeMoment.values.length; index++) ...[
                  Expanded(
                    child: _IntakeMomentCard(
                      moment: IntakeMoment.values[index],
                      selected: _draft.intake == IntakeMoment.values[index],
                      onTap: () => setState(() {
                        _draft = _draft.copyWith(
                          intake: IntakeMoment.values[index],
                        );
                      }),
                    ),
                  ),
                  if (index != IntakeMoment.values.length - 1)
                    const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B3B3B),
              ),
              decoration: InputDecoration(
                hintText: 'Примечание',
                hintStyle: const TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB5B5B5),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFB),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                ),
              ),
            ),
            const SizedBox(height: 42),
            Row(
              children: [
                Expanded(
                  child: _OutlineActionButton(
                    label: 'Назад',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _PrimaryGradientButton(
                    label: 'Далее',
                    onPressed: _goNext,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddVitaminScheduleScreen extends StatefulWidget {
  const AddVitaminScheduleScreen({
    super.key,
    required this.repository,
    required this.draft,
    required this.onFlowCompleted,
    required this.onTabRequested,
    this.editingReminderId,
  });

  final PharmacyRepository repository;
  final VitaminDraft draft;
  final String? editingReminderId;
  final VoidCallback onFlowCompleted;
  final ValueChanged<HomeTab> onTabRequested;

  @override
  State<AddVitaminScheduleScreen> createState() =>
      _AddVitaminScheduleScreenState();
}

class _AddVitaminScheduleScreenState extends State<AddVitaminScheduleScreen> {
  late List<String> _times;
  late Set<Weekday> _selectedDays;
  late DateTime _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _times = widget.draft.intakeTimes.isEmpty
        ? [PharmacyFlowLogic.currentTimeString()]
        : [...widget.draft.intakeTimes];
    _selectedDays = widget.draft.weekdays.isEmpty
        ? Weekday.values.toSet()
        : widget.draft.weekdays.toSet();
    _startDate = widget.draft.courseStartDate;
    _endDate = widget.draft.courseEndDate;
  }

  void _handleTabTap(HomeTab tab) {
    if (tab == HomeTab.pharmacy) {
      return;
    }
    widget.onTabRequested(tab);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _pickTime(int index) async {
    final initial = PharmacyFlowLogic.timeToDate(_times[index]);
    DateTime selected = initial;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 280,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Готово'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initial,
                  onDateTimeChanged: (value) => selected = value,
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _times[index] = PharmacyFlowLogic.dateToTime(selected);
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      locale: const Locale('ru'),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  void _goNext() {
    final updatedDraft = widget.draft.copyWith(
      intakeTimes: _times,
      weekdays: Weekday.values
          .where((day) => _selectedDays.contains(day))
          .toList(growable: false),
      courseStartDate: _startDate,
      courseEndDate: _endDate,
      clearCourseEndDate: _endDate == null,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddVitaminNotificationScreen(
          repository: widget.repository,
          draft: updatedDraft,
          editingReminderId: widget.editingReminderId,
          onFlowCompleted: widget.onFlowCompleted,
          onTabRequested: widget.onTabRequested,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PharmacyFlowScaffold(
      selectedTab: HomeTab.pharmacy,
      onTabRequested: _handleTabTap,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30, 18, 30, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepProgressBar(filledSegments: 2),
            const SizedBox(height: 28),
            Row(
              children: [
                Image.asset(
                  'assets/images/pharmacy/pen.png',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.draft.name,
                    style: const TextStyle(
                      fontFamily: 'Commissioner',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B3B3B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              children: List.generate(_times.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _IntakeTimeCard(
                    order: index + 1,
                    time: _times[index],
                    onTap: () => _pickTime(index),
                    onDelete: _times.length > 1
                        ? () => setState(() {
                              _times.removeAt(index);
                            })
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => setState(() {
                  _times.add(PharmacyFlowLogic.currentTimeString());
                }),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppPalette.blueMain,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.25),
                        blurRadius: 3.3,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Text(
                  'Дни приема',
                  style: TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  PharmacyFlowLogic.weekdaysSummary(_selectedDays),
                  style: const TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC3C3C3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Weekday.values.map((day) {
                final selected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  }),
                  child: Container(
                    width: 42,
                    height: 39,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppPalette.blueMain : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.25),
                          blurRadius: 3.3,
                          offset: Offset(1, 1),
                        ),
                      ],
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      day.label.toLowerCase(),
                      style: TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppPalette.blueMain,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            const Text(
              'Продолжительность курса',
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppPalette.blueMain,
              ),
            ),
            const SizedBox(height: 12),
            _DateRow(
              title: 'Начало',
              value: PharmacyFlowLogic.formatDateRu(_startDate),
              onTap: () => _pickDate(isStart: true),
            ),
            _DateRow(
              title: 'Конец',
              value: _endDate == null
                  ? 'дата'
                  : PharmacyFlowLogic.formatDateRu(_endDate!),
              onTap: () => _pickDate(isStart: false),
            ),
            const SizedBox(height: 42),
            Row(
              children: [
                Expanded(
                  child: _OutlineActionButton(
                    label: 'Назад',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _PrimaryGradientButton(
                    label: 'Далее',
                    onPressed: _goNext,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddVitaminNotificationScreen extends StatefulWidget {
  const AddVitaminNotificationScreen({
    super.key,
    required this.repository,
    required this.draft,
    required this.onFlowCompleted,
    required this.onTabRequested,
    this.editingReminderId,
  });

  final PharmacyRepository repository;
  final VitaminDraft draft;
  final String? editingReminderId;
  final VoidCallback onFlowCompleted;
  final ValueChanged<HomeTab> onTabRequested;

  @override
  State<AddVitaminNotificationScreen> createState() =>
      _AddVitaminNotificationScreenState();
}

class _AddVitaminNotificationScreenState
    extends State<AddVitaminNotificationScreen> {
  static const List<_NotificationOption> _options = [
    _NotificationOption(
      id: 'dose',
      title: 'Доза за прием',
      placeholder: 'Например, 1 таблетка',
      editable: false,
    ),
    _NotificationOption(
      id: 'frequency',
      title: 'Частота',
      placeholder: 'Например, 2 раза в день',
      editable: false,
    ),
    _NotificationOption(
      id: 'note',
      title: 'Примечание',
      placeholder: 'Добавьте примечание',
    ),
    _NotificationOption(
      id: 'condition',
      title: 'Условия приема',
      placeholder: 'Например, после еды',
    ),
    _NotificationOption(
      id: 'interaction',
      title: 'Взаимодействие',
      placeholder: 'Принимайте с...',
    ),
    _NotificationOption(
      id: 'compatibility',
      title: 'Совместимость',
      placeholder: 'Уточните совместимость',
    ),
    _NotificationOption(
      id: 'contraindications',
      title: 'Противопоказания',
      placeholder: 'Укажите противопоказания',
    ),
  ];

  String? _expandedOptionId;
  late Set<String> _selectedOptionIds;
  late Map<String, String> _details;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedOptionIds = {
      if (widget.draft.includeDose) 'dose',
      if (widget.draft.includeFrequency) 'frequency',
      'note',
      if (widget.draft.includeCondition) 'condition',
      if (widget.draft.includeInteraction) 'interaction',
      if (widget.draft.includeCompatibility) 'compatibility',
      if (widget.draft.includeContraindications) 'contraindications',
    };
    _details = PharmacyFlowLogic.prefilledNotificationDetails(widget.draft);
  }

  void _handleTabTap(HomeTab tab) {
    if (tab == HomeTab.pharmacy) {
      return;
    }
    widget.onTabRequested(tab);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final payload = PharmacyFlowLogic.buildReminderInput(
        draft: widget.draft,
        selectedOptionIds: _selectedOptionIds,
        details: _details,
      );
      if (widget.editingReminderId == null) {
        await widget.repository.createReminder(payload);
      } else {
        await widget.repository.updateReminder(widget.editingReminderId!, payload);
      }
      if (!mounted) {
        return;
      }
      widget.onFlowCompleted();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ошибка'),
          content: Text(
            widget.editingReminderId == null
                ? 'Не удалось добавить витамин'
                : 'Не удалось сохранить изменения',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ок'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel =
        widget.editingReminderId == null ? 'Добавить' : 'Сохранить';

    return _PharmacyFlowScaffold(
      selectedTab: HomeTab.pharmacy,
      onTabRequested: _handleTabTap,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(
          children: [
            const _StepProgressBar(filledSegments: 3),
            const SizedBox(height: 36),
            const Text(
              'Выберите пункты, которые\nбудут в уведомлении',
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ..._options.map((option) {
              final expanded = _expandedOptionId == option.id;
              final selected = _selectedOptionIds.contains(option.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _NotificationCard(
                  option: option,
                  expanded: expanded,
                  selected: selected,
                  value: _details[option.id] ?? '',
                  onToggleSelected: () => setState(() {
                    if (selected) {
                      _selectedOptionIds.remove(option.id);
                    } else {
                      _selectedOptionIds.add(option.id);
                    }
                  }),
                  onToggleExpanded: () => setState(() {
                    _expandedOptionId = expanded ? null : option.id;
                  }),
                  onChanged: option.editable
                      ? (value) => _details[option.id] = value
                      : null,
                ),
              );
            }),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _OutlineActionButton(
                    label: 'Назад',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _PrimaryGradientButton(
                    label: actionLabel,
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VitaminDetailsScreen extends StatefulWidget {
  const VitaminDetailsScreen({
    super.key,
    required this.repository,
    required this.reminderId,
    required this.onFlowCompleted,
    required this.onTabRequested,
  });

  final PharmacyRepository repository;
  final String reminderId;
  final VoidCallback onFlowCompleted;
  final ValueChanged<HomeTab> onTabRequested;

  @override
  State<VitaminDetailsScreen> createState() => _VitaminDetailsScreenState();
}

class _VitaminDetailsScreenState extends State<VitaminDetailsScreen> {
  PharmacyReminder? _reminder;
  bool _loading = true;
  bool _deleting = false;
  final Set<String> _expandedIds = <String>{};
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = <String>{};
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    setState(() => _loading = true);
    final reminder = await widget.repository.fetchReminder(widget.reminderId);
    if (!mounted) {
      return;
    }
    setState(() {
      _reminder = reminder;
      _loading = false;
      _selectedIds = reminder == null
          ? <String>{}
          : PharmacyFlowLogic.infoOptionIds(reminder);
    });
  }

  void _handleTabTap(HomeTab tab) {
    if (tab == HomeTab.pharmacy) {
      return;
    }
    widget.onTabRequested(tab);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _deleteReminder() async {
    if (_deleting || _reminder == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить?'),
          content: const Text(
            'Вы точно хотите удалить напоминание о приеме витамина?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Да'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _deleting = true);
    await widget.repository.deleteReminder(_reminder!.id);
    if (!mounted) {
      return;
    }
    widget.onFlowCompleted();
    Navigator.of(context).pop();
  }

  void _openEditFlow() {
    final reminder = _reminder;
    if (reminder == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddVitaminScreen(
          repository: widget.repository,
          initialDraft: PharmacyFlowLogic.makeDraftFromReminder(
            reminder,
            _selectedIds,
          ),
          editingReminderId: reminder.id,
          onFlowCompleted: widget.onFlowCompleted,
          onTabRequested: widget.onTabRequested,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PharmacyFlowScaffold(
      selectedTab: HomeTab.pharmacy,
      onTabRequested: _handleTabTap,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppPalette.blueMain),
            )
          : _reminder == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Не удалось загрузить данные витамина',
                          style: TextStyle(
                            fontFamily: 'Commissioner',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loadReminder,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 160),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.12),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Image.asset(
                                'assets/images/home/back_button.png',
                                width: 24,
                                height: 21,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _reminder!.title,
                              style: const TextStyle(
                                fontFamily: 'Commissioner',
                                fontSize: 32.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3B3B3B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 60),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Image.asset(
                        'assets/images/pharmacy/capsule2d.png',
                        width: 160,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatCard(
                            subtitle: PharmacyFlowLogic.formLabel(_reminder!.form),
                            child: Text(
                              PharmacyFlowLogic.doseAmount(_reminder!.dose),
                              style: const TextStyle(
                                fontFamily: 'Commissioner',
                                fontSize: 43,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.blueMain,
                              ),
                            ),
                          ),
                          _StatCard(
                            subtitle: PharmacyFlowLogic.frequencyLabel(_reminder!),
                            child: Image.asset(
                              'assets/images/pharmacy/calendar.png',
                              width: 32,
                              height: 35,
                            ),
                          ),
                          _StatCard(
                            subtitle: PharmacyFlowLogic.conditionLabel(
                              _reminder!.condition,
                            ),
                            child: Image.asset(
                              PharmacyFlowLogic.conditionIcon(_reminder!.condition),
                              width: PharmacyFlowLogic.conditionIconSize(
                                _reminder!.condition,
                              ).width,
                              height: PharmacyFlowLogic.conditionIconSize(
                                _reminder!.condition,
                              ).height,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ...PharmacyFlowLogic.infoOptions(_reminder!).map((option) {
                        final expanded = _expandedIds.contains(option.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _DetailsInfoCard(
                            option: option,
                            expanded: expanded,
                            selected: _selectedIds.contains(option.id),
                            onToggle: () => setState(() {
                              if (expanded) {
                                _expandedIds.remove(option.id);
                              } else {
                                _expandedIds.add(option.id);
                              }
                            }),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 174,
                        child: _OutlineActionButton(
                          label: 'Настроить',
                          onPressed: _openEditFlow,
                          textColor: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 174,
                        child: _OutlineActionButton(
                          label: 'Удалить',
                          onPressed: _deleteReminder,
                          textColor: const Color(0xFFEA3E3E),
                          loading: _deleting,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _PharmacyFlowScaffold extends StatelessWidget {
  const _PharmacyFlowScaffold({
    required this.selectedTab,
    required this.onTabRequested,
    required this.child,
  });

  final HomeTab selectedTab;
  final ValueChanged<HomeTab> onTabRequested;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFF6FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: child,
        ),
      ),
      bottomNavigationBar: HomeTabBarHost(
        selectedTab: selectedTab,
        onSelect: onTabRequested,
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.filledSegments});

  final int filledSegments;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final filled = index < filledSegments;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: filled
                  ? const LinearGradient(
                      colors: [Color(0xFF0773F1), Color(0xFFD6FEC2)],
                    )
                  : null,
              color: filled ? null : const Color(0xFFD2D2D2),
            ),
          ),
        );
      }),
    );
  }
}

class _BlueFieldButton extends StatelessWidget {
  const _BlueFieldButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppPalette.blueMain,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            Image.asset(
              'assets/images/pharmacy/chevron_white.png',
              width: 20,
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _IntakeMomentCard extends StatelessWidget {
  const _IntakeMomentCard({
    required this.moment,
    required this.selected,
    required this.onTap,
  });

  final IntakeMoment moment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: selected ? AppPalette.blueMain : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.16),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : Colors.black.withValues(alpha: 0.12),
                ),
              ),
              padding: const EdgeInsets.all(18),
              child: Center(
                child: Image.asset(
                  selected ? moment.selectedIconAsset : moment.iconAsset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            moment.title,
            style: const TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _IntakeTimeCard extends StatelessWidget {
  const _IntakeTimeCard({
    required this.order,
    required this.time,
    required this.onTap,
    this.onDelete,
  });

  final int order;
  final String time;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6F95FC), Color(0xFF0773F1), Color(0xFFD6FEC2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Прием $order',
                style: const TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 65,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                time,
                style: const TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC3C3C3),
              ),
            ),
            const SizedBox(width: 10),
            Image.asset(
              'assets/images/pharmacy/chevron_white.png',
              width: 20,
              height: 20,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationOption {
  const _NotificationOption({
    required this.id,
    required this.title,
    required this.placeholder,
    this.editable = true,
  });

  final String id;
  final String title;
  final String placeholder;
  final bool editable;
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.option,
    required this.expanded,
    required this.selected,
    required this.value,
    required this.onToggleSelected,
    required this.onToggleExpanded,
    this.onChanged,
  });

  final _NotificationOption option;
  final bool expanded;
  final bool selected;
  final String value;
  final VoidCallback onToggleSelected;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFADC4FF), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12),
            blurRadius: 2.2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onToggleSelected,
                    child: Container(
                      width: 33,
                      height: 33,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFADC4FF)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.25),
                            blurRadius: 3.3,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      child: selected
                          ? Padding(
                              padding: const EdgeInsets.all(5),
                              child: Image.asset(
                                'assets/images/pharmacy/characteristic_mark.png',
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: onToggleExpanded,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Commissioner',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B3B3B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Transform.rotate(
                              angle: expanded ? math.pi / 2 : 0,
                              child: Image.asset(
                                'assets/images/pharmacy/chevron_white.png',
                                width: 20,
                                height: 20,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 14, 30, 20),
              child: option.editable
                  ? TextField(
                      controller: TextEditingController(text: value)
                        ..selection = TextSelection.collapsed(offset: value.length),
                      maxLines: null,
                      onChanged: onChanged,
                      style: const TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B3B3B),
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        hintText: option.placeholder,
                        hintStyle: const TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA8A8A8),
                        ),
                        border: InputBorder.none,
                      ),
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value.trim().isEmpty ? option.placeholder : value,
                        style: const TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B3B3B),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _CatalogSelectionResult {
  const _CatalogSelectionResult({this.catalogItem, this.customName});

  final VitaminCatalogItem? catalogItem;
  final String? customName;
}

class _CatalogSearchSheet extends StatefulWidget {
  const _CatalogSearchSheet({
    required this.catalog,
    required this.loading,
    required this.errorMessage,
    required this.initialQuery,
    required this.selectedCatalogId,
    required this.selectedName,
  });

  final List<VitaminCatalogItem> catalog;
  final bool loading;
  final String? errorMessage;
  final String initialQuery;
  final String? selectedCatalogId;
  final String selectedName;

  @override
  State<_CatalogSearchSheet> createState() => _CatalogSearchSheetState();
}

class _CatalogSearchSheetState extends State<_CatalogSearchSheet> {
  late final TextEditingController _controller;

  String get _normalizedSelectedName => widget.selectedName.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.catalog
        : widget.catalog.where((item) {
            return item.resolvedName.toLowerCase().contains(query);
          }).toList();
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final sheetHeight = math.min(MediaQuery.of(context).size.height * 0.64, 470.0);

    return Container(
      width: double.infinity,
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD5D5D5),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE7EBF0),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppPalette.blueMain,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 1,
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C2C2C),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Введите витамин',
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _controller.clear();
                    }),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFBDBFC4),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Builder(
              builder: (context) {
                if (widget.loading && widget.catalog.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppPalette.blueMain,
                    ),
                  );
                }
                if (widget.errorMessage != null && widget.catalog.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        widget.errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF656565),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (filtered.isEmpty) {
                  final customName = _controller.text.trim();
                  if (customName.isEmpty) {
                    return const Center(
                      child: Text(
                        'Ничего не найдено',
                        style: TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF656565),
                        ),
                      ),
                    );
                  }
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, safeBottom + 12),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            _CatalogSelectionResult(customName: customName),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          backgroundColor: AppPalette.blueMain.withValues(
                            alpha: 0.08,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          'Использовать "$customName"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Commissioner',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.blueMain,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(22, 0, 22, safeBottom + 18),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE1E5EA),
                  ),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isSelected =
                        item.id == widget.selectedCatalogId ||
                            (widget.selectedCatalogId == null &&
                                item.resolvedName.trim().toLowerCase() ==
                                    _normalizedSelectedName);
                    final subtitle = item.code?.trim().isNotEmpty == true
                        ? item.code!.trim()
                        : 'Витамин';
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(
                        _CatalogSelectionResult(catalogItem: item),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.resolvedName,
                                    style: const TextStyle(
                                      fontFamily: 'Commissioner',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF222222),
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontFamily: 'Commissioner',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFB1B4BA),
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 30,
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: AppPalette.blueSecondary,
                                      size: 30,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.onPressed,
    this.textColor = AppPalette.blueMain,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final Color textColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFADC4FF), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          shadowColor: Colors.black.withValues(alpha: 0.25),
          elevation: 3,
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(100);

    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E7BF3), Color(0xFFA6C4DD)],
            ),
            borderRadius: borderRadius,
          ),
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: borderRadius,
            splashColor: Colors.white.withValues(alpha: 0.10),
            highlightColor: Colors.white.withValues(alpha: 0.06),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        height: 1,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.child, required this.subtitle});

  final Widget child;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          Container(
            width: 74.7,
            height: 69,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.2), width: 0.6),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.25),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: child,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3B3B3B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DetailsInfoCard extends StatelessWidget {
  const _DetailsInfoCard({
    required this.option,
    required this.expanded,
    required this.selected,
    required this.onToggle,
  });

  final PharmacyInfoOption option;
  final bool expanded;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFADC4FF), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.14),
            blurRadius: 2.4,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
              child: Row(
                children: [
                  Container(
                    width: 33,
                    height: 33,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFADC4FF)),
                    ),
                    child: selected
                        ? Padding(
                            padding: const EdgeInsets.all(5),
                            child: Image.asset(
                              'assets/images/pharmacy/characteristic_mark.png',
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: onToggle,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Commissioner',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B3B3B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Transform.rotate(
                              angle: expanded ? math.pi / 2 : 0,
                              child: Image.asset(
                                'assets/images/pharmacy/chevron_white.png',
                                width: 20,
                                height: 20,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 14, 30, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  option.text,
                  style: const TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3B3B3B),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PharmacyInfoOption {
  const PharmacyInfoOption({
    required this.id,
    required this.title,
    required this.text,
  });

  final String id;
  final String title;
  final String text;
}

class PharmacyFlowLogic {
  static String currentTimeString() {
    final now = DateTime.now();
    return dateToTime(now);
  }

  static String dateToTime(DateTime value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  static DateTime timeToDate(String raw) {
    final parts = raw.split(':');
    final now = DateTime.now();
    final hours = parts.isNotEmpty ? int.tryParse(parts[0]) ?? now.hour : now.hour;
    final minutes = parts.length > 1 ? int.tryParse(parts[1]) ?? now.minute : now.minute;
    return DateTime(now.year, now.month, now.day, hours, minutes);
  }

  static String extractDoseAmount(String dose) {
    return dose.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String doseUnitFor({
    required String type,
    required String amountText,
    String? defaultUnit,
  }) {
    final amount = int.tryParse(amountText);
    final normalizedType = type.trim().toLowerCase();
    if (normalizedType.isEmpty) {
      return '';
    }
    switch (normalizedType) {
      case 'таблетки':
      case 'капсулы':
      case 'жевательные таблетки':
      case 'ампулы':
      case 'уколы':
        return 'шт';
      case 'порошок':
        return 'г';
      case 'жидкость':
        return 'мл';
      case 'капли':
        return _pluralizeRussian(
          amount,
          one: 'капля',
          few: 'капли',
          many: 'капель',
          fallback: 'капли',
        );
      case 'спрей':
        return _pluralizeRussian(
          amount,
          one: 'нажатие',
          few: 'нажатия',
          many: 'нажатий',
          fallback: 'нажатия',
        );
      default:
        if (defaultUnit != null && defaultUnit.trim().isNotEmpty) {
          return defaultUnit.trim();
        }
        return '';
    }
  }

  static String composeDose({
    required String type,
    required String amountText,
    String? defaultUnit,
  }) {
    final normalizedAmount = amountText.trim();
    final unit = doseUnitFor(
      type: type,
      amountText: normalizedAmount,
      defaultUnit: defaultUnit,
    );
    if (normalizedAmount.isEmpty) {
      return '';
    }
    if (unit.isEmpty) {
      return normalizedAmount;
    }
    return '$normalizedAmount $unit';
  }

  static String _pluralizeRussian(
    int? amount, {
    required String one,
    required String few,
    required String many,
    required String fallback,
  }) {
    if (amount == null) {
      return fallback;
    }
    final mod100 = amount % 100;
    if (mod100 >= 11 && mod100 <= 14) {
      return many;
    }
    switch (amount % 10) {
      case 1:
        return one;
      case 2:
      case 3:
      case 4:
        return few;
      default:
        return many;
    }
  }

  static String formatDateRu(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = (value.year % 100).toString().padLeft(2, '0');
    return '$day.$month.$year';
  }

  static String weekdaysSummary(Set<Weekday> value) {
    if (value.isEmpty) {
      return 'выберите дни';
    }
    if (value.length == Weekday.values.length) {
      return 'каждый день';
    }
    return Weekday.values
        .where(value.contains)
        .map((day) => day.label.toLowerCase())
        .join(', ');
  }

  static Map<String, String> prefilledNotificationDetails(VitaminDraft draft) {
    return {
      'dose': draft.dose,
      'frequency': frequencyText(draft),
      'note': draft.notes,
      'condition': draft.intake?.title.replaceAll('\n', ' ') ??
          localizedCondition(draft.catalogDefaultCondition),
      'interaction': draft.interactionTextOverride?.trim().isNotEmpty == true
          ? draft.interactionTextOverride!.trim()
          : (draft.catalogInteractionText ?? ''),
      'compatibility':
          draft.compatibilityTextOverride?.trim().isNotEmpty == true
              ? draft.compatibilityTextOverride!.trim()
              : (draft.catalogCompatibilityText ?? ''),
      'contraindications':
          draft.contraindicationsTextOverride?.trim().isNotEmpty == true
              ? draft.contraindicationsTextOverride!.trim()
              : (draft.catalogContraindicationsText ?? ''),
    };
  }

  static String frequencyText(VitaminDraft draft) {
    final ordered = Weekday.values.where(draft.weekdays.contains).toList();
    final daysText = ordered.isEmpty || ordered.length == Weekday.values.length
        ? 'каждый день'
        : ordered.map((day) => day.label.toLowerCase()).join(', ');
    if (draft.intakeTimes.isEmpty) {
      return daysText;
    }
    return '$daysText, ${draft.intakeTimes.join(', ')}';
  }

  static String localizedCondition(String? apiCondition) {
    switch (apiCondition?.toLowerCase()) {
      case 'before_meal':
        return 'До еды';
      case 'after_meal':
        return 'После еды';
      case 'during_meal':
        return 'Во время еды';
      default:
        return 'Неважно';
    }
  }

  static String formApiValue(String type) {
    switch (type.toLowerCase()) {
      case 'таблетки':
        return 'tablet';
      case 'капсулы':
        return 'capsule';
      case 'капли':
        return 'drops';
      case 'порошок':
        return 'powder';
      case 'жевательные таблетки':
        return 'chewable_tablet';
      case 'жидкость':
        return 'liquid';
      case 'ампулы':
        return 'ampoule';
      case 'спрей':
        return 'spray';
      case 'уколы':
        return 'injection';
      default:
        return 'capsule';
    }
  }

  static String draftTypeFromForm(String form) {
    switch (form.toLowerCase()) {
      case 'tablet':
        return 'Таблетки';
      case 'capsule':
        return 'Капсулы';
      case 'drops':
        return 'Капли';
      case 'powder':
        return 'Порошок';
      case 'chewable_tablet':
        return 'Жевательные таблетки';
      case 'liquid':
        return 'Жидкость';
      case 'ampoule':
        return 'Ампулы';
      case 'spray':
        return 'Спрей';
      case 'injection':
        return 'Уколы';
      default:
        return 'Капсулы';
    }
  }

  static PharmacyReminderInput buildReminderInput({
    required VitaminDraft draft,
    required Set<String> selectedOptionIds,
    required Map<String, String> details,
  }) {
    return PharmacyReminderInput(
      title: draft.name.trim(),
      form: formApiValue(draft.type),
      dose: draft.dose.trim().isEmpty ? '1' : draft.dose.trim(),
      condition:
          draft.intake?.apiCondition ?? (draft.catalogDefaultCondition ?? 'any'),
      note: selectedOptionIds.contains('note')
          ? (details['note'] ?? '').trim()
          : '',
      courseStartDate: draft.courseStartDate,
      courseEndDate: draft.courseEndDate,
      timezone: DateTime.now().timeZoneName,
      days: draft.weekdays.isEmpty ? Weekday.values : draft.weekdays,
      times: draft.intakeTimes.isEmpty ? [currentTimeString()] : draft.intakeTimes,
      includeDose: selectedOptionIds.contains('dose'),
      includeFrequency: selectedOptionIds.contains('frequency'),
      includeInteraction: selectedOptionIds.contains('interaction'),
      includeCompatibility: selectedOptionIds.contains('compatibility'),
      includeCondition: selectedOptionIds.contains('condition'),
      includeContraindications: selectedOptionIds.contains('contraindications'),
      catalogId: draft.catalogId,
      catalog: draft.catalogId == null
          ? null
          : VitaminCatalogItem(
              id: draft.catalogId!,
              displayName: draft.name,
              defaultUnit: draft.catalogDefaultUnit,
              interactionText: draft.catalogInteractionText,
              compatibilityText: draft.catalogCompatibilityText,
              contraindicationsText: draft.catalogContraindicationsText,
              defaultCondition: draft.catalogDefaultCondition,
            ),
      interactionTextOverride: overrideText(
        selectedOptionIds.contains('interaction'),
        details['interaction'],
        draft.catalogInteractionText,
      ),
      compatibilityTextOverride: overrideText(
        selectedOptionIds.contains('compatibility'),
        details['compatibility'],
        draft.catalogCompatibilityText,
      ),
      contraindicationsTextOverride: overrideText(
        selectedOptionIds.contains('contraindications'),
        details['contraindications'],
        draft.catalogContraindicationsText,
      ),
    );
  }

  static String? overrideText(bool enabled, String? value, String? catalogDefault) {
    if (!enabled) {
      return null;
    }
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final defaultValue = catalogDefault?.trim();
    if (defaultValue != null && defaultValue.isNotEmpty && defaultValue == normalized) {
      return null;
    }
    return normalized;
  }

  static List<PharmacyInfoOption> infoOptions(PharmacyReminder reminder) {
    return [
      PharmacyInfoOption(
        id: 'interaction',
        title: 'Взаимодействие',
        text: resolvedInteractionText(reminder),
      ),
      PharmacyInfoOption(
        id: 'compatibility',
        title: 'Совместимость',
        text: resolvedCompatibilityText(reminder),
      ),
      PharmacyInfoOption(
        id: 'condition',
        title: 'Условие',
        text: resolvedConditionText(reminder),
      ),
      PharmacyInfoOption(
        id: 'contraindications',
        title: 'Противопоказания',
        text: resolvedContraindicationsText(reminder),
      ),
    ];
  }

  static Set<String> infoOptionIds(PharmacyReminder reminder) {
    final ids = <String>{};
    if (reminder.notificationPreferences.includeInteraction) {
      ids.add('interaction');
    }
    if (reminder.notificationPreferences.includeCompatibility) {
      ids.add('compatibility');
    }
    if (reminder.notificationPreferences.includeCondition) {
      ids.add('condition');
    }
    if (reminder.notificationPreferences.includeContraindications) {
      ids.add('contraindications');
    }
    return ids;
  }

  static VitaminDraft makeDraftFromReminder(
    PharmacyReminder reminder,
    Set<String> selectedOptionIds,
  ) {
    return VitaminDraft(
      name: reminder.title,
      type: draftTypeFromForm(reminder.form),
      dose: reminder.dose ?? '',
      intake: IntakeMoment.fromApiCondition(reminder.condition),
      notes: reminder.note ?? '',
      catalogId: reminder.catalogId,
      catalogDefaultUnit: reminder.catalog?.defaultUnit,
      catalogInteractionText: reminder.catalog?.interactionText,
      catalogCompatibilityText: reminder.catalog?.compatibilityText,
      catalogContraindicationsText: reminder.catalog?.contraindicationsText,
      catalogDefaultCondition: reminder.catalog?.defaultCondition,
      interactionTextOverride:
          reminder.contentOverrides.interactionTextOverride,
      compatibilityTextOverride:
          reminder.contentOverrides.compatibilityTextOverride,
      contraindicationsTextOverride:
          reminder.contentOverrides.contraindicationsTextOverride,
      includeDose: reminder.notificationPreferences.includeDose,
      includeFrequency: reminder.notificationPreferences.includeFrequency,
      includeInteraction: selectedOptionIds.contains('interaction'),
      includeCompatibility: selectedOptionIds.contains('compatibility'),
      includeCondition: selectedOptionIds.contains('condition'),
      includeContraindications: selectedOptionIds.contains('contraindications'),
      intakeTimes: reminder.schedule.times,
      weekdays: reminder.schedule.days,
      courseStartDate: reminder.course.startDate,
      courseEndDate: reminder.course.endDate,
    );
  }

  static String doseAmount(String? dose) {
    final value = dose?.replaceAll(RegExp(r'[^0-9]'), '');
    if (value == null || value.isEmpty) {
      return '1';
    }
    return value;
  }

  static String formLabel(String form) {
    switch (form.toLowerCase()) {
      case 'tablet':
        return 'Таблетка';
      case 'capsule':
        return 'Капсула';
      case 'drops':
        return 'Капли';
      case 'powder':
        return 'Порошок';
      case 'chewable_tablet':
        return 'Жевательная\nтаблетка';
      case 'liquid':
        return 'Жидкость';
      case 'ampoule':
        return 'Ампула';
      case 'spray':
        return 'Спрей';
      case 'injection':
        return 'Укол';
      default:
        return 'Вид';
    }
  }

  static String frequencyLabel(PharmacyReminder reminder) {
    final days = reminder.schedule.days;
    if (days.isEmpty || days.length == Weekday.values.length) {
      return 'Каждый\nдень';
    }
    return days.map((day) => day.label).join(', ');
  }

  static String conditionLabel(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'before_meal':
        return 'До еды';
      case 'after_meal':
        return 'После еды';
      case 'during_meal':
        return 'Во время\nеды';
      default:
        return 'Неважно';
    }
  }

  static String conditionIcon(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'before_meal':
        return 'assets/images/pharmacy/plate_unselected.png';
      case 'after_meal':
        return 'assets/images/pharmacy/fork_unselected.png';
      case 'during_meal':
        return 'assets/images/pharmacy/knee_unselected.png';
      default:
        return 'assets/images/pharmacy/mark_magnifier_unselected.png';
    }
  }

  static Size conditionIconSize(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'before_meal':
        return const Size(32, 32);
      case 'after_meal':
        return const Size(16, 39);
      case 'during_meal':
        return const Size(26, 26);
      default:
        return const Size(30, 30);
    }
  }

  static String resolvedInteractionText(PharmacyReminder reminder) {
    final override = reminder.contentOverrides.interactionTextOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    final value = reminder.catalog?.interactionText?.trim();
    return value == null || value.isEmpty ? 'Нет данных' : value;
  }

  static String resolvedCompatibilityText(PharmacyReminder reminder) {
    final override = reminder.contentOverrides.compatibilityTextOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    final value = reminder.catalog?.compatibilityText?.trim();
    return value == null || value.isEmpty ? 'Нет данных' : value;
  }

  static String resolvedContraindicationsText(PharmacyReminder reminder) {
    final override =
        reminder.contentOverrides.contraindicationsTextOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    final value = reminder.catalog?.contraindicationsText?.trim();
    return value == null || value.isEmpty ? 'Нет данных' : value;
  }

  static String resolvedConditionText(PharmacyReminder reminder) {
    final label = conditionLabel(reminder.condition).replaceAll('\n', ' ');
    final note = reminder.note?.trim() ?? '';
    final merged = [label, note].where((value) => value.isNotEmpty).join('. ');
    return merged.isEmpty ? 'Нет данных' : merged;
  }
}
