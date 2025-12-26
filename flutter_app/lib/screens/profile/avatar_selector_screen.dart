import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/models.dart';
import '../../widgets/avatar_widget.dart';

class AvatarSelectorScreen extends StatefulWidget {
  final AvatarData currentAvatar;
  final Function(AvatarData) onSave;

  const AvatarSelectorScreen({
    Key? key,
    required this.currentAvatar,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AvatarSelectorScreen> createState() => _AvatarSelectorScreenState();
}

class _AvatarSelectorScreenState extends State<AvatarSelectorScreen> {
  late String _selectedColor;
  late String _selectedIcon;
  late String _selectedStyle;

  final List<String> _colors = ['blue', 'green', 'orange', 'red', 'purple', 'black'];
  final List<String> _icons = ['person', 'plane', 'mountain', 'beach', 'city', 'food', 'music', 'camera'];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentAvatar.color;
    _selectedIcon = widget.currentAvatar.icon;
    _selectedStyle = widget.currentAvatar.style;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Avatar'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Preview
          Center(
            child: AvatarWidget(
              avatar: AvatarData(
                color: _selectedColor,
                icon: _selectedIcon,
                style: _selectedStyle,
              ),
              size: 120,
            ).animate(key: ValueKey('$_selectedColor$_selectedIcon')).scale(duration: 300.ms, curve: Curves.elasticOut),
          ),
          const SizedBox(height: 40),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                   BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
                ],
              ),
              child: ListView(
                children: [
                  _buildSectionTitle('Choose Color'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final color = _colors[index];
                        final isSelected = color == _selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AvatarWidget(avatar: AvatarData(color: color)).getGradient(color), // Helper needed or just duplicate logic?
                              border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                              boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)] : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Choose Icon'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _icons.map((icon) {
                      final isSelected = icon == _selectedIcon;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : Border.all(color: Colors.transparent),
                          ),
                          child: Icon(
                            AvatarWidget(avatar: AvatarData(icon: icon)).getIcon(icon),
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                            size: 28,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                   widget.onSave(AvatarData(
                     color: _selectedColor,
                     icon: _selectedIcon,
                     style: _selectedStyle,
                   ));
                   Navigator.pop(context);
                },
                child: const Text('Save Avatar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }
}
