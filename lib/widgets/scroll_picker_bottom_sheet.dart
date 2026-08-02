import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class ScrollPickerBottomSheet {
  const ScrollPickerBottomSheet._();

  static Future<int?> showNumber({
    required BuildContext context,
    required String title,
    required String unit,
    required int min,
    required int max,
    required int step,
    required int currentValue,
    String Function(int value)? labelBuilder,
  }) {
    final values = <int>[
      for (var value = min; value <= max; value += step) value,
    ];
    final initialIndex = ((currentValue.clamp(min, max) - min) / step)
        .round()
        .clamp(0, values.length - 1)
        .toInt();

    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PickerSheet<int>(
        title: title,
        unit: unit,
        columns: [
          _PickerColumn<int>(
            values: values,
            initialIndex: initialIndex,
            labelBuilder: labelBuilder ?? (value) => value.toString(),
          ),
        ],
        valueBuilder: (values) => values.first,
      ),
    );
  }

  static Future<int?> showDigits({
    required BuildContext context,
    required String title,
    required String unit,
    required int currentValue,
    int digitCount = 6,
    bool dimLeadingZeros = false,
    int? digitGroupSize,
  }) {
    final maximum = int.parse(List.filled(digitCount, '9').join());
    final digits = currentValue
        .clamp(0, maximum)
        .toString()
        .padLeft(digitCount, '0')
        .split('')
        .map(int.parse)
        .toList();
    final digitValues = List<int>.generate(10, (index) => index);

    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PickerSheet<int>(
        title: title,
        unit: unit,
        columns: [
          for (final digit in digits)
            _PickerColumn<int>(
              values: digitValues,
              initialIndex: digit,
              labelBuilder: (value) => value.toString(),
            ),
        ],
        dimLeadingZeros: dimLeadingZeros,
        digitGroupSize: digitGroupSize,
        valueBuilder: (values) => int.parse(values.join()),
      ),
    );
  }

  static Future<({int hours, int minutes})?> showDuration({
    required BuildContext context,
    required int currentHours,
    required int currentMinutes,
  }) {
    final hours = List<int>.generate(24, (index) => index);
    final minutes = List<int>.generate(12, (index) => index * 5);
    final hourIndex = currentHours.clamp(0, 23).toInt();
    final minuteIndex = (currentMinutes.clamp(0, 55) / 5).round();

    return showModalBottomSheet<({int hours, int minutes})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PickerSheet<({int hours, int minutes})>(
        title: 'オンライン時間',
        unit: '時間 / 分',
        columns: [
          _PickerColumn<int>(
            values: hours,
            initialIndex: hourIndex,
            labelBuilder: (value) => '$value時間',
          ),
          _PickerColumn<int>(
            values: minutes,
            initialIndex: minuteIndex,
            labelBuilder: (value) => '${value.toString().padLeft(2, '0')}分',
          ),
        ],
        valueBuilder: (values) => (hours: values[0], minutes: values[1]),
      ),
    );
  }
}

class _PickerColumn<T> {
  const _PickerColumn({
    required this.values,
    required this.initialIndex,
    required this.labelBuilder,
  });

  final List<T> values;
  final int initialIndex;
  final String Function(T value) labelBuilder;
}

class _PickerSheet<R> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.unit,
    required this.columns,
    required this.valueBuilder,
    this.dimLeadingZeros = false,
    this.digitGroupSize,
  });

  final String title;
  final String unit;
  final List<_PickerColumn<int>> columns;
  final R Function(List<int> values) valueBuilder;
  final bool dimLeadingZeros;
  final int? digitGroupSize;

  @override
  State<_PickerSheet<R>> createState() => _PickerSheetState<R>();
}

class _PickerSheetState<R> extends State<_PickerSheet<R>> {
  late final List<int> _selectedIndexes;
  late final List<FixedExtentScrollController> _controllers;
  bool _isClosing = false;

  void _cancel() {
    if (_isClosing) return;
    _isClosing = true;
    Navigator.of(context).pop();
  }

  void _confirm() {
    if (_isClosing) return;
    _isClosing = true;
    final values = <int>[
      for (var i = 0; i < widget.columns.length; i++)
        widget.columns[i].values[_controllers[i].selectedItem],
    ];
    Navigator.of(context).pop(widget.valueBuilder(values));
  }

  @override
  void initState() {
    super.initState();
    _selectedIndexes = [
      for (final column in widget.columns) column.initialIndex,
    ];
    _controllers = [
      for (final column in widget.columns)
        FixedExtentScrollController(initialItem: column.initialIndex),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    var firstSignificantIndex = widget.columns.length - 1;
    for (var i = 0; i < widget.columns.length; i++) {
      if (widget.columns[i].values[_selectedIndexes[i]] != 0) {
        firstSignificantIndex = i;
        break;
      }
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                TextButton(onPressed: _cancel, child: const Text('キャンセル')),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.unit,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: _confirm, child: const Text('決定')),
              ],
            ),
            SizedBox(
              height: 216,
              child: Row(
                children: [
                  for (var i = 0; i < widget.columns.length; i++) ...[
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _controllers[i],
                        itemExtent: 44,
                        useMagnifier: true,
                        magnification: 1.08,
                        selectionOverlay:
                            CupertinoPickerDefaultSelectionOverlay(
                              background: AppColors.primary.withValues(
                                alpha: 0.12,
                              ),
                            ),
                        onSelectedItemChanged: (index) {
                          if (widget.dimLeadingZeros) {
                            setState(() => _selectedIndexes[i] = index);
                          }
                        },
                        children: [
                          for (final value in widget.columns[i].values)
                            Center(
                              child: Text(
                                widget.columns[i].labelBuilder(value),
                                style: TextStyle(
                                  fontSize: 22,
                                  color:
                                      widget.dimLeadingZeros &&
                                          i < firstSignificantIndex &&
                                          value == 0
                                      ? Colors.grey.shade400
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.digitGroupSize != null &&
                        i < widget.columns.length - 1 &&
                        (i + 1) % widget.digitGroupSize! == 0)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
