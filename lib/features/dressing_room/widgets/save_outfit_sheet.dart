import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/sketch_widgets.dart';

enum SaveAction { saveNew, update, share }

class SaveSheetResult {
  const SaveSheetResult(this.action, this.name, this.withBackground);

  final SaveAction action;
  final String name;
  final bool withBackground;
}

class SaveOutfitSheet extends StatefulWidget {
  const SaveOutfitSheet({
    super.key,
    required this.initialName,
    required this.canUpdate,
    required this.exportBackground,
  });

  final String initialName;
  final bool canUpdate;
  final bool exportBackground;

  @override
  State<SaveOutfitSheet> createState() => _SaveOutfitSheetState();
}

class _SaveOutfitSheetState extends State<SaveOutfitSheet> {
  late final _name = TextEditingController(text: widget.initialName);
  late bool _background = widget.exportBackground;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _finish(SaveAction action) {
    final typed = _name.text.trim();
    Navigator.of(context).pop(SaveSheetResult(
      action,
      typed.isEmpty ? 'My Look' : typed,
      _background,
    ));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            18,
            22,
            18 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Keep this look',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.title,
                  fontWeight: FontWeight.w700,
                  fontSize: 34,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('save_name'),
                controller: _name,
                maxLength: 30,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Outfit name',
                  hintText: 'My Look',
                  counterText: '',
                ),
              ),
              SwitchListTile(
                key: const Key('save_background'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Include sketchbook background in picture'),
                value: _background,
                onChanged: (value) => setState(() => _background = value),
              ),
              const SizedBox(height: 6),
              if (widget.canUpdate) ...[
                PillSketchButton(
                  key: const Key('save_update'),
                  label: 'Update this outfit',
                  pink: true,
                  expand: true,
                  onPressed: () => _finish(SaveAction.update),
                ),
                const SizedBox(height: 10),
              ],
              PillSketchButton(
                key: const Key('save_confirm'),
                label: widget.canUpdate ? 'Save as new outfit' : 'Save outfit',
                pink: !widget.canUpdate,
                expand: true,
                onPressed: () => _finish(SaveAction.saveNew),
              ),
              const SizedBox(height: 10),
              PillSketchButton(
                key: const Key('save_share'),
                label: 'Export and share picture',
                icon: SketchIcons.share,
                expand: true,
                onPressed: () => _finish(SaveAction.share),
              ),
            ],
          ),
        ),
      );
}
