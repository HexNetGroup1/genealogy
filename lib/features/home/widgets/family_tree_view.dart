import 'package:flutter/material.dart';
import '../models/family_member.dart';

/// Древо с абсолютным позиционированием и анимацией
class FamilyTreeView extends StatefulWidget {
  const FamilyTreeView({
    super.key,
    required this.members,
    required this.onMemberSelected,
  });

  final List<FamilyMember> members;
  final ValueChanged<FamilyMember> onMemberSelected;

  @override
  State<FamilyTreeView> createState() => _FamilyTreeViewState();
}

class _FamilyTreeViewState extends State<FamilyTreeView> with SingleTickerProviderStateMixin {
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _bgGreen = Color(0xFFE8F5E9);

  static const double _nodeWidth = 140;
  static const double _nodeHeight = 50;
  static const double _levelGap = 60;
  static const double _nodeGap = 20;

  late AnimationController _controller;
  
  Map<String, Offset> _currentPositions = {};
  Map<String, Offset> _targetPositions = {};
  Map<String, Offset> _sourcePositions = {};
  
  // Для отрисовки (интерполированные)
  Map<String, Offset> _renderPositions = {};
  List<_Connection> _renderConnections = [];
  double _renderWidth = 0;
  double _renderHeight = 0;
  
  int _expandDepth = 1;
  Set<String> _expandedIds = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(_onTick);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTick() {
    final t = Curves.easeInOutCubic.transform(_controller.value);
    final allKeys = {..._sourcePositions.keys, ..._targetPositions.keys};
    final newPositions = <String, Offset>{};
    double maxX = 0;
    double maxY = 0;

    for (final id in allKeys) {
      final source = _sourcePositions[id];
      final target = _targetPositions[id];

      if (source != null && target != null) {
        newPositions[id] = Offset.lerp(source, target, t)!;
      } else if (source != null) {
        // Исчезает -> анимируем к родителю (если найдем) или просто исчезаем
        // Для простоты пока оставляем на месте, но можно улучшить
        newPositions[id] = source; 
      } else if (target != null) {
        // Появляется -> уже должен быть обработан в prepareLayout
        newPositions[id] = target;
      }
      
      if (newPositions[id] != null) {
        final p = newPositions[id]!;
        if (p.dx + _nodeWidth > maxX) maxX = p.dx + _nodeWidth;
        if (p.dy + _nodeHeight > maxY) maxY = p.dy + _nodeHeight;
      }
    }

    // Соединения
    final newConnections = <_Connection>[];
    final byId = _getMemberMap();
    for (final id in newPositions.keys) {
      final member = byId[id];
      if (member == null) continue;
      
      // Если у ребенка есть позиция, рисуем линию
      for (final childId in member.childrenIds) {
        if (newPositions.containsKey(childId)) {
          newConnections.add(_Connection(id, childId));
        }
      }
    }

    setState(() {
      _renderPositions = newPositions;
      _renderConnections = newConnections;
      _renderWidth = maxX + 50;
      _renderHeight = maxY + 50;
    });
  }

  Map<String, FamilyMember> _getMemberMap() {
    final map = <String, FamilyMember>{};
    for (final m in widget.members) map[m.id] = m;
    return map;
  }

  List<FamilyMember> _getRoots(Map<String, FamilyMember> byId) {
    final allChildIds = <String>{};
    for (final m in widget.members) {
      for (final childId in m.childrenIds) {
        if (byId.containsKey(childId)) allChildIds.add(childId);
      }
    }
    return widget.members.where((m) => !allChildIds.contains(m.id)).toList();
  }

  void _initExpandedIds() {
    if (_initialized) return;
    _initialized = true;
    _expandedIds = {};
    _currentPositions = {};
    
    final byId = _getMemberMap();
    final roots = _getRoots(byId);
    _expandToDepth(roots, byId, 0);
    
    // Начальный расчет без анимации
    _calculateTargetLayout();
    _currentPositions = Map.of(_targetPositions);
    _renderPositions = Map.of(_targetPositions);
    _updateRenderData(); // Force update connections size
  }

  void _updateRenderData() {
    // Вспомогательный метод для обновления соединений без анимации
    double maxX = 0;
    double maxY = 0;
    for (final p in _renderPositions.values) {
      if (p.dx + _nodeWidth > maxX) maxX = p.dx + _nodeWidth;
      if (p.dy + _nodeHeight > maxY) maxY = p.dy + _nodeHeight;
    }
    _renderWidth = maxX + 50;
    _renderHeight = maxY + 50;
    
    final newConnections = <_Connection>[];
    final byId = _getMemberMap();
    for (final id in _renderPositions.keys) {
      final member = byId[id];
      if (member == null) continue;
      for (final childId in member.childrenIds) {
        if (_renderPositions.containsKey(childId)) {
          newConnections.add(_Connection(id, childId));
        }
      }
    }
    _renderConnections = newConnections;
  }

  void _expandToDepth(List<FamilyMember> members, Map<String, FamilyMember> byId, int currentDepth) {
    if (currentDepth >= _expandDepth) return;
    for (final member in members) {
      _expandedIds.add(member.id);
      final children = member.childrenIds.map((id) => byId[id]).whereType<FamilyMember>().toList();
      if (children.isNotEmpty) _expandToDepth(children, byId, currentDepth + 1);
    }
  }

  void _calculateTargetLayout() {
    _targetPositions = {};
    
    final byId = _getMemberMap();
    final roots = _getRoots(byId);
    if (roots.isEmpty) return;

    double currentY = _nodeGap;

    double layoutNode(FamilyMember member, int depth) {
      final children = member.childrenIds
          .map((id) => byId[id])
          .whereType<FamilyMember>()
          .toList();
      
      final isExpanded = _expandedIds.contains(member.id);
      final x = _nodeGap + depth * (_nodeWidth + _levelGap);

      if (children.isEmpty || !isExpanded) {
        final y = currentY;
        _targetPositions[member.id] = Offset(x, y);
        currentY += _nodeHeight + _nodeGap;
        return y;
      } else {
        double firstChildY = 0;
        double lastChildY = 0;
        for (int i = 0; i < children.length; i++) {
          final childY = layoutNode(children[i], depth + 1);
          if (i == 0) firstChildY = childY;
          lastChildY = childY;
        }
        final y = (firstChildY + lastChildY) / 2;
        _targetPositions[member.id] = Offset(x, y);
        return y;
      }
    }

    for (final root in roots) {
      layoutNode(root, 0);
    }
  }

  void _animateLayout() {
    _calculateTargetLayout(); // Заполняет _targetPositions
    
    // Подготовка _sourcePositions
    _sourcePositions = Map.of(_currentPositions);

    // Обработка появляющихся узлов (Appearing)
    // Если узел есть в target, но нет в source -> ставим его в позицию родителя из source
    // Обработка исчезающих узлов (Disappearing)
    // Если узел есть в source, но нет в target -> ставим его в target позицию родителя (схлопываем)

    // Сложный момент: родитель тоже может двигаться.
    // Простой вариант: 
    // New nodes start at their PARENT's SOURCE position.
    // Deleted nodes end at their PARENT's TARGET position.
    
    final byId = _getMemberMap();

    // 1. New nodes
    for (final id in _targetPositions.keys) {
      if (!_sourcePositions.containsKey(id)) {
        // Найти родителя
        String? parentId;
        // Это неэффективно, но для 20-50 нод нормально. Можно оптимизировать map-ом child->parent
        for (final m in widget.members) {
          if (m.childrenIds.contains(id)) {
            parentId = m.id;
            break;
          }
        }
        
        if (parentId != null && _sourcePositions.containsKey(parentId)) {
           _sourcePositions[id] = _sourcePositions[parentId]!;
        } else {
           _sourcePositions[id] = _targetPositions[id]!; // Fallback
        }
      }
    }

    // 2. Deleted nodes (Collapsed)
    // Мы хотим, чтобы они анимировались. Значит они должны быть в _targetPositions тоже!
    // Мы добавим их в _targetPositions, но в позиции их РОДИТЕЛЯ.
    // А после анимации - удалим из _currentPositions списка отрисовки.
    // Но _onTick использует _targetPositions для интерполяции.
    // Так что добавим.
    
    // Нам нужен список ключей, которые исчезли
    final disappearing = _sourcePositions.keys.where((k) => !_targetPositions.containsKey(k)).toList();
    
    for (final id in disappearing) {
       // Найти родителя
        String? parentId;
        for (final m in widget.members) {
          if (m.childrenIds.contains(id)) {
            parentId = m.id;
            break;
          }
        }
        
        if (parentId != null && _targetPositions.containsKey(parentId)) {
           _targetPositions[id] = _targetPositions[parentId]!;
        } else {
           // Если родитель тоже исчез? Рекурсия сложная. 
           // Просто оставляем текущую позицию или скрываем.
           _targetPositions[id] = _sourcePositions[id]!; 
        }
    }

    _controller.forward(from: 0).then((_) {
      // Cleanup cleanup deleted nodes
       setState(() {
         // Сохраняем только те, что должны быть (реальные target)
         // Но мы модифицировали _targetPositions выше. Нужно пересчитать чистый target или отфильтровать.
         // Проще пересчитать.
         _calculateTargetLayout(); 
         _currentPositions = Map.of(_targetPositions);
         _renderPositions = Map.of(_targetPositions);
         _sourcePositions = {};
         _updateRenderData();
       });
    });
  }


  void _toggleExpand(String id) {
    if (_controller.isAnimating) return; // Ждем окончания
    
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
    _animateLayout();
  }

  void _changeDepth(int newDepth) {
     setState(() {
       _expandDepth = newDepth;
       _expandedIds = {};
       final byId = _getMemberMap();
       final roots = _getRoots(byId);
       _expandToDepth(roots, byId, 0);
     });
     _animateLayout();
  }

  void _showDepthDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempDepth = _expandDepth;
        return AlertDialog(
          title: const Text('Глубина раскрытия'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$tempDepth',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _primaryGreen),
                  ),
                  Slider(
                    value: tempDepth.toDouble(),
                    min: 0, max: 10, divisions: 10,
                    activeColor: _primaryGreen,
                    onChanged: (v) => setDialogState(() => tempDepth = v.round()),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _changeDepth(tempDepth);
              },
              style: FilledButton.styleFrom(backgroundColor: _primaryGreen),
              child: const Text('Применить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.members.isEmpty) return const Center(child: Text('Пусто'));
    
    if (!_initialized) {
      _initExpandedIds();
    }
    // Если вдруг ресайз или апдейт без анимации, можно форсировать
    // Но пока надеемся на initState/actions
    
    final byId = _getMemberMap();

    return Container(
      color: _bgGreen,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                 Text('${widget.members.length} чел.', style: const TextStyle(fontWeight: FontWeight.bold, color: _primaryGreen)),
                 const Spacer(),
                 FilledButton.icon(
                   onPressed: _showDepthDialog,
                   icon: const Icon(Icons.unfold_more, size: 18),
                   label: Text('Глубина: $_expandDepth'),
                   style: FilledButton.styleFrom(backgroundColor: _primaryGreen),
                 ),
              ],
            ),
          ),
          
          Expanded(
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.1,
              maxScale: 3.0,
              child: SizedBox(
                width: _renderWidth,
                height: _renderHeight,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(_renderWidth, _renderHeight),
                      painter: _TreePainter(
                        connections: _renderConnections,
                        positions: _renderPositions,
                        nodeWidth: _nodeWidth,
                        nodeHeight: _nodeHeight,
                        color: _primaryGreen.withAlpha(100),
                      ),
                    ),
                    
                    ..._renderPositions.entries.map((entry) {
                       final member = byId[entry.key];
                       if (member == null) return const SizedBox.shrink();
                       final hasChildren = member.childrenIds.any((id) => byId.containsKey(id));
                       final isExpanded = _expandedIds.contains(member.id);

                       return Positioned(
                         left: entry.value.dx,
                         top: entry.value.dy,
                         child: GestureDetector(
                           onTap: () {
                             if (hasChildren) {
                               _toggleExpand(member.id);
                             } else {
                               widget.onMemberSelected(member);
                             }
                           },
                           child: _NodeWidget(
                             member: member,
                             hasChildren: hasChildren,
                             isExpanded: isExpanded,
                             width: _nodeWidth,
                             height: _nodeHeight,
                             primaryColor: _primaryGreen,
                           ),
                         ),
                       );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeWidget extends StatelessWidget {
  const _NodeWidget({
    required this.member,
    required this.hasChildren,
    required this.isExpanded,
    required this.width,
    required this.height,
    required this.primaryColor,
  });

  final FamilyMember member;
  final bool hasChildren;
  final bool isExpanded;
  final double width;
  final double height;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isExpanded && hasChildren ? primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: CircleAvatar(
              backgroundColor: primaryColor,
              radius: 18,
              child: Text(
                member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          Expanded(
            child: Text(
              member.fullName.split(' ').first,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasChildren)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                isExpanded ? Icons.remove_circle : Icons.add_circle,
                size: 18,
                color: primaryColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _Connection {
  final String parentId;
  final String childId;
  _Connection(this.parentId, this.childId);
}

class _TreePainter extends CustomPainter {
  final List<_Connection> connections;
  final Map<String, Offset> positions;
  final double nodeWidth;
  final double nodeHeight;
  final Color color;

  _TreePainter({
    required this.connections,
    required this.positions,
    required this.nodeWidth,
    required this.nodeHeight,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (final conn in connections) {
      final pPos = positions[conn.parentId];
      final cPos = positions[conn.childId];
      if (pPos == null || cPos == null) continue;

      final startX = pPos.dx + nodeWidth;
      final startY = pPos.dy + nodeHeight / 2;
      final endX = cPos.dx;
      final endY = cPos.dy + nodeHeight / 2;

      path.moveTo(startX, startY);
      final cp1X = startX + (endX - startX) / 2;
      final cp2X = startX + (endX - startX) / 2;
      path.cubicTo(cp1X, startY, cp2X, endY, endX, endY);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
