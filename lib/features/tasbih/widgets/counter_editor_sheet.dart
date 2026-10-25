import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/dhikr/dhikr_catalog.dart';
import '../../../models/tasbih.dart';
import '../../../widgets/common/pressable.dart';
import '../bloc/tasbih_bloc.dart';
import '../../../widgets/common/app_backdrop_filter.dart';
import '../../../core/constants/radii.dart';

/// Frosted bottom-sheet frame shared by the dhikr sheets.
class DhikrSheetFrame extends StatelessWidget {
  final Widget child;

  const DhikrSheetFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      child: AppBackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        fallbackTint: AppBackdropFilter.sheetTint,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the sheet to add a counter, or to edit [existing]. Built-in counters
/// keep their name; only the target can change.
Future<void> showCounterEditor(BuildContext context, {Tasbih? existing}) {
  final bloc = context.read<TasbihBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => BlocProvider.value(value: bloc, child: _CounterEditor(existing: existing)),
  );
}

Future<bool> confirmDeleteCounter(BuildContext context, Tasbih t) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E2233),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('Delete ${t.name}?', style: AppTextStyles.h3(color: Colors.white)),
      content: Text(
        t.totalCount > 0
            ? 'Its ${t.totalCount} counted dhikr go with it. This can\'t be undone.'
            : 'This can\'t be undone.',
        style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.7)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Keep it', style: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.8))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Delete', style: AppTextStyles.body(color: const Color(0xFFFF8A80), weight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _CounterEditor extends StatefulWidget {
  final Tasbih? existing;

  const _CounterEditor({this.existing});

  @override
  State<_CounterEditor> createState() => _CounterEditorState();
}

class _CounterEditorState extends State<_CounterEditor> {
  static const _presets = [33, 99, 100, 1000];
  static const _maxTarget = 9999;
  static const _maxName = 40;

  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _other = TextEditingController();
  final FocusNode _otherFocus = FocusNode();
  late int? _target = widget.existing?.targetCount ?? 33;
  bool _otherSelected = false;
  String? _nameError;
  String? _targetError;

  bool get _builtIn => widget.existing != null && DhikrCatalog.isBuiltIn(widget.existing!.id);

  @override
  void initState() {
    super.initState();
    final t = widget.existing?.targetCount;
    if (t != null && !_presets.contains(t)) {
      _otherSelected = true;
      _other.text = '$t';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _other.dispose();
    _otherFocus.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final target = _otherSelected ? int.tryParse(_other.text.trim()) : _target;
    setState(() {
      _nameError = name.isEmpty ? 'Give it a name' : null;
      _targetError = (target == null || target < 1 || target > _maxTarget)
          ? 'Choose a target from 1 to $_maxTarget'
          : null;
    });
    if (_nameError != null || _targetError != null) return;

    final bloc = context.read<TasbihBloc>();
    final existing = widget.existing;
    if (existing == null) {
      bloc.add(AddTasbih(name, target!));
    } else {
      bloc.add(EditTasbih(existing.id, _builtIn ? existing.name : name, target!));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final adding = widget.existing == null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DhikrSheetFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              adding ? 'Add your own' : (_builtIn ? widget.existing!.name : 'Edit counter'),
              style: AppTextStyles.h3(color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (!_builtIn) ...[
              _label('Name'),
              TextField(
                controller: _name,
                autofocus: adding,
                maxLength: _maxName,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.body(color: Colors.white),
                cursorColor: AppColors.spiritualGold,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
                decoration: _fieldDecoration(hint: 'SubhanAllahi wa bihamdihi', error: _nameError),
              ),
              const SizedBox(height: 8),
            ],
            _label('Target'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _presets)
                  _Chip(
                    label: '$p',
                    selected: !_otherSelected && _target == p,
                    onTap: () => setState(() {
                      _otherSelected = false;
                      _target = p;
                      _targetError = null;
                    }),
                  ),
                _Chip(
                  label: 'Other',
                  selected: _otherSelected,
                  onTap: () {
                    setState(() {
                      _otherSelected = true;
                      _targetError = null;
                    });
                    // The field appears on this frame; focus it on the next.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _otherFocus.requestFocus();
                    });
                  },
                ),
              ],
            ),
            if (_otherSelected) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _other,
                focusNode: _otherFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                style: AppTextStyles.body(color: Colors.white),
                cursorColor: AppColors.spiritualGold,
                onChanged: (_) {
                  if (_targetError != null) setState(() => _targetError = null);
                },
                decoration: _fieldDecoration(hint: '313', error: null),
              ),
            ],
            if (_targetError != null) ...[
              const SizedBox(height: 6),
              Text(_targetError!, style: AppTextStyles.tiny(color: const Color(0xFFFF8A80))),
            ],
            const SizedBox(height: 20),
            Pressable(
              onTap: _save,
              pressedScale: 0.97,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.spiritualGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.spiritualGold.withValues(alpha: 0.45), width: 0.5),
                ),
                child: Text(
                  adding ? 'Add counter' : 'Save',
                  style: AppTextStyles.body(color: AppColors.spiritualGold, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTextStyles.tiny(color: Colors.white.withValues(alpha: 0.55))),
      );

  InputDecoration _fieldDecoration({required String hint, required String? error}) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: BorderSide(color: c, width: 0.8),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body(color: Colors.white.withValues(alpha: 0.3)),
      errorText: error,
      counterText: '',
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: border(Colors.white.withValues(alpha: 0.1)),
      focusedBorder: border(AppColors.spiritualGold.withValues(alpha: 0.6)),
      errorBorder: border(const Color(0xFFFF8A80)),
      focusedErrorBorder: border(const Color(0xFFFF8A80)),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.spiritualGold : Colors.white.withValues(alpha: 0.7);
    return Pressable(
      onTap: onTap,
      haptic: PressableHaptic.selection,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.spiritualGold.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? AppColors.spiritualGold.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Text(label, style: AppTextStyles.small(color: color, weight: selected ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }
}
