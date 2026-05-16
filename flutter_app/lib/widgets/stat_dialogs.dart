import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_state.dart';
import '../models/habit_categories.dart';
import '../services/api_client.dart';

/// Dialog for customizing a stat (rename, change icon, change color, remap categories).
class StatCustomizeDialog extends StatefulWidget {
  final PlayerStat stat;

  const StatCustomizeDialog({super.key, required this.stat});

  @override
  State<StatCustomizeDialog> createState() => _StatCustomizeDialogState();
}

class _StatCustomizeDialogState extends State<StatCustomizeDialog> {
  late TextEditingController _nameCtrl;
  late String _icon;
  late String _color;
  late List<String> _mappedCategories;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.stat.name);
    _icon = widget.stat.icon;
    _color = widget.stat.color;
    _mappedCategories = _parseCategories(widget.stat.categoryMappings);
  }

  List<String> _parseCategories(String json) {
    try {
      final list = json as List<dynamic>?;
      if (list != null) return list.cast<String>();
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: widget.stat.displayColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Text(
                    'Customize Stat',
                    style: GoogleFonts.rajdhani(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Name
              Text('Name', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Stat name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Icon picker
              Text('Icon', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: StatIconGallery.allIcons.length,
                  itemBuilder: (ctx, i) {
                    final emoji = StatIconGallery.allIcons[i];
                    final selected = _icon == emoji;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = emoji),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? widget.stat.displayColor.withValues(alpha: 0.3)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          border: selected
                              ? Border.all(color: widget.stat.displayColor, width: 2)
                              : null,
                        ),
                        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Color picker
              Text('Color', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  '#FF5500', '#FF2D95', '#B026FF', '#00E5FF',
                  '#00FF88', '#FFD700', '#FF9B71', '#FF007F',
                  '#00BFFF', '#FF4444', '#44FF44', '#FF8800',
                ].map((hex) {
                  final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                  final selected = _color == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: selected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: selected
                            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Category mappings
              Text('Feeds From Categories',
                  style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: HabitCategories.names.map((cat) {
                  final selected = _mappedCategories.contains(cat);
                  return FilterChip(
                    label: Text(cat, style: GoogleFonts.rajdhani(fontSize: 12)),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _mappedCategories.add(cat);
                        } else {
                          _mappedCategories.remove(cat);
                        }
                      });
                    },
                    selectedColor: widget.stat.displayColor.withValues(alpha: 0.3),
                    checkmarkColor: widget.stat.displayColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.stat.displayColor,
                    ),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Save', style: GoogleFonts.rajdhani(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final api = ApiClient();
      await api.updateStat(widget.stat.id, {
        'name': _nameCtrl.text.trim(),
        'icon': _icon,
        'color': _color,
        'category_mappings': _mappedCategories.toString(),
      });
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Dialog for creating a new custom stat.
class StatCreateDialog extends StatefulWidget {
  const StatCreateDialog({super.key});

  @override
  State<StatCreateDialog> createState() => _StatCreateDialogState();
}

class _StatCreateDialogState extends State<StatCreateDialog> {
  late TextEditingController _nameCtrl;
  String _icon = '💪';
  String _color = '#FF5500';
  List<String> _mappedCategories = ['General'];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = Color(int.parse(_color.replaceFirst('#', '0xFF')));

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accentColor.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Text(
                    'New Stat',
                    style: GoogleFonts.rajdhani(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Stat Name',
                  hintText: 'e.g., Endurance, Magic, Stealth',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              Text('Icon', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8, mainAxisSpacing: 4, crossAxisSpacing: 4,
                  ),
                  itemCount: StatIconGallery.allIcons.length,
                  itemBuilder: (ctx, i) {
                    final emoji = StatIconGallery.allIcons[i];
                    final selected = _icon == emoji;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = emoji),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? accentColor.withValues(alpha: 0.3) : null,
                          borderRadius: BorderRadius.circular(8),
                          border: selected ? Border.all(color: accentColor, width: 2) : null,
                        ),
                        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              Text('Color', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  '#FF5500', '#FF2D95', '#B026FF', '#00E5FF',
                  '#00FF88', '#FFD700', '#FF9B71', '#FF007F',
                  '#00BFFF', '#FF4444', '#44FF44', '#FF8800',
                ].map((hex) {
                  final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                  final selected = _color == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: selected ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Text('Feeds From Categories', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: HabitCategories.names.map((cat) {
                  final selected = _mappedCategories.contains(cat);
                  return FilterChip(
                    label: Text(cat, style: GoogleFonts.rajdhani(fontSize: 12)),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) { _mappedCategories.add(cat); }
                        else { _mappedCategories.remove(cat); }
                      });
                    },
                    selectedColor: accentColor.withValues(alpha: 0.3),
                    checkmarkColor: accentColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _create,
                    style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Create', style: GoogleFonts.rajdhani(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final api = ApiClient();
      final now = DateTime.now();
      final stat = PlayerStat(
        id: '', // server assigns
        name: _nameCtrl.text.trim(),
        value: 1.0,
        level: 1,
        xpInStat: 0,
        xpToNext: 120,
        icon: _icon,
        color: _color,
        categoryMappings: _mappedCategories.toString(),
      );
      await api.createStat(stat);
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}