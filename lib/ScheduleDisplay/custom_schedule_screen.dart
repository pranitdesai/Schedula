import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:schedula/Utils/app_color.dart';

import '../HomeScreen/db_data_getter.dart';

class CustomScheduleScreen extends StatefulWidget {
  final bool isDailySchedule;

  const CustomScheduleScreen({super.key, this.isDailySchedule = false});

  @override
  State<CustomScheduleScreen> createState() => _CustomScheduleScreenState();
}

class _CustomScheduleScreenState extends State<CustomScheduleScreen> {
  static const _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final Map<String, List<_ScheduleEntry>> _entries = {
    for (final day in _days) day: [],
  };
  int _selectedDay = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final schedule = widget.isDailySchedule
          ? await DataGetter.getDailySchedule()
          : await DataGetter.getWeeklySchedule();

      for (final day in _days) {
        final rawDayEntries = schedule[day];
        if (rawDayEntries is! Map) continue;

        for (final rawEntry in rawDayEntries.entries) {
          final range = rawEntry.key.toString().split(' - ');
          if (range.length != 2) continue;

          try {
            final start = DateFormat('hh:mm a').parse(range[0].trim());
            final end = DateFormat('hh:mm a').parse(range[1].trim());
            _entries[day]!.add(
              _ScheduleEntry(
                subject: rawEntry.value.toString(),
                start: TimeOfDay.fromDateTime(start),
                end: TimeOfDay.fromDateTime(end),
              ),
            );
          } on FormatException {
            // Ignore malformed legacy entries instead of breaking the editor.
          }
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load schedule: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addEntry() async {
    final entry = await showDialog<_ScheduleEntry>(
      context: context,
      builder: (_) => _ScheduleEntryDialog(day: _days[_selectedDay]),
    );

    if (entry != null) {
      setState(() => _entries[_days[_selectedDay]]!.add(entry));
    }
  }

  Future<void> _saveSchedule() async {
    final schedule = <String, dynamic>{};
    for (final day in _days) {
      final dayEntries = <String, String>{};
      for (final entry in _entries[day]!) {
        dayEntries[_formatRange(entry.start, entry.end)] = entry.subject;
      }
      schedule[day] = dayEntries;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.isDailySchedule) {
        await DataGetter.setDailySchedule(schedule);
      } else {
        await DataGetter.setWeeklySchedule(schedule);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.isDailySchedule ? 'Daily' : 'Weekly'} schedule saved',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save schedule: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = _days[_selectedDay];
    final dayEntries = _entries[day]!;

    return Scaffold(
      backgroundColor: AppColor.green50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Create ${widget.isDailySchedule ? 'daily' : 'weekly'} schedule',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                'Add your study sessions, then save them to your account.',
                style: GoogleFonts.poppins(color: Colors.black54),
              ),
            ),
            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = index == _selectedDay;
                  return ChoiceChip(
                    label: Text(_capitalize(_days[index])),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedDay = index),
                    selectedColor: AppColor.green700,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColor.green800,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                  );
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : dayEntries.isEmpty
                  ? Center(
                      child: Text(
                        'No sessions for ${_capitalize(day)} yet.',
                        style: GoogleFonts.poppins(color: Colors.black45),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: dayEntries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = dayEntries[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          color: Colors.white,
                          elevation: 0,
                          child: ListTile(
                            leading: const HugeIcon(
                              icon: HugeIcons.strokeRoundedBook02,
                              color: AppColor.green700,
                            ),
                            title: Text(entry.subject),
                            subtitle: Text(
                              _formatRange(entry.start, entry.end),
                            ),
                            trailing: IconButton(
                              tooltip: 'Remove session',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  setState(() => dayEntries.removeAt(index)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _addEntry,
                      icon: const Icon(Icons.add),
                      label: const Text('Add session'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.green700,
                        side: const BorderSide(color: AppColor.green700),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLoading || _isSaving ? null : _saveSchedule,
                      icon: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Save schedule'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.green700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static String _formatRange(TimeOfDay start, TimeOfDay end) {
    final format = DateFormat('hh:mm a');
    final today = DateTime.now();
    return '${format.format(DateTime(today.year, today.month, today.day, start.hour, start.minute))} - '
        '${format.format(DateTime(today.year, today.month, today.day, end.hour, end.minute))}';
  }

  static String _capitalize(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';
}

class _ScheduleEntryDialog extends StatefulWidget {
  final String day;

  const _ScheduleEntryDialog({required this.day});

  @override
  State<_ScheduleEntryDialog> createState() => _ScheduleEntryDialogState();
}

class _ScheduleEntryDialogState extends State<_ScheduleEntryDialog> {
  final TextEditingController _subjectController = TextEditingController();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  String? _errorText;

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  void _submit() {
    final subject = _subjectController.text.trim();
    if (subject.isEmpty) {
      setState(() => _errorText = 'Enter a subject or activity.');
      return;
    }
    if (_CustomScheduleScreenState._minutes(_end) <=
        _CustomScheduleScreenState._minutes(_start)) {
      setState(() => _errorText = 'End time must be after start time.');
      return;
    }

    Navigator.pop(
      context,
      _ScheduleEntry(subject: subject, start: _start, end: _end),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text(
        'Add ${_CustomScheduleScreenState._capitalize(widget.day)} session',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _subjectController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Subject or activity',
                prefixIcon: const Icon(Icons.book_outlined),
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Starts',
                    time: _start,
                    onPressed: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeButton(
                    label: 'Ends',
                    time: _end,
                    onPressed: () => _pickTime(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColor.green700),
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _ScheduleEntry {
  final String subject;
  final TimeOfDay start;
  final TimeOfDay end;

  const _ScheduleEntry({
    required this.subject,
    required this.start,
    required this.end,
  });
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onPressed;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(10)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Text(time.format(context)),
        ],
      ),
    );
  }
}
