import 'package:flutter/material.dart';
import '../models/family_member.dart';
import 'dart:math';

/// Древо с абсолютным позиционированием и анимацией
class FamilyTreeView extends StatefulWidget {
  const FamilyTreeView({
    super.key,
    required this.members,
    required this.onMemberSelected,
    required this.onLoadChildren,
  });

  final List<FamilyMember> members;
  final ValueChanged<FamilyMember> onMemberSelected;
  final Future<List<FamilyMember>> Function(String parentId) onLoadChildren;

  @override
  State<FamilyTreeView> createState() => _FamilyTreeViewState();
}

class _FamilyTreeViewState extends State<FamilyTreeView> with SingleTickerProviderStateMixin {
  static const Color _primaryYellow = Color(0xFFFBC02D); // Deep yellow/gold
  static const Color _bgYellow = Colors.white; // Changed from light yellow to white

  static const double _nodeWidth = 140;
  static const double _nodeHeight = 50;
  static const double _levelGap = 60;
  static const double _nodeGap = 20;

  late AnimationController _controller;
  late TransformationController _transformationController;
  
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
  Set<String> _loadingIds = {}; // Состояния загрузки для узлов
  List<FamilyMember> _localMembers = []; // Локальная копия загруженных элементов
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _localMembers = List.from(widget.members);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(_onTick);
    _transformationController = TransformationController();
  }

  @override
  void didUpdateWidget(FamilyTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.members != oldWidget.members) {
      // Инициализируем локальный список, если поменялся внешний
      // (Например, при полном обновлении корней)
      // Если мы уже загрузили локально, лучше объединить, но для простоты
      // пока просто берем внешние + всё что было локально
      final existingIds = widget.members.map((m) => m.id).toSet();
      final newLocal = List<FamilyMember>.from(widget.members);
      for (final m in _localMembers) {
        if (!existingIds.contains(m.id)) {
           newLocal.add(m);
        }
      }
      _localMembers = newLocal;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformationController.dispose();
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
        newPositions[id] = source; 
      } else if (target != null) {
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
    for (final m in _localMembers) map[m.id] = m;
    return map;
  }

  List<FamilyMember> _getRoots(Map<String, FamilyMember> byId) {
    final allChildIds = <String>{};
    for (final m in _localMembers) {
      for (final childId in m.childrenIds) {
        if (byId.containsKey(childId)) allChildIds.add(childId);
      }
    }
    return _localMembers.where((m) => !allChildIds.contains(m.id)).toList();
  }

  void _initExpandedIds() {
    if (_initialized) return;
    _initialized = true;
    _expandedIds = {};
    _currentPositions = {};
    
    final byId = _getMemberMap();
    final roots = _getRoots(byId);
    _expandToDepth(roots, byId, 0);
    
    _calculateTargetLayout();
    _currentPositions = Map.of(_targetPositions);
    _renderPositions = Map.of(_targetPositions);
    _updateRenderData(); 
  }

  void _updateRenderData() {
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
    _calculateTargetLayout(); 
    _sourcePositions = Map.of(_currentPositions);
    
    final byId = _getMemberMap();

    // 1. New nodes
    for (final id in _targetPositions.keys) {
      if (!_sourcePositions.containsKey(id)) {
        String? parentId;
        for (final m in _localMembers) {
          if (m.childrenIds.contains(id)) {
            parentId = m.id;
            break;
          }
        }
        if (parentId != null && _sourcePositions.containsKey(parentId)) {
           _sourcePositions[id] = _sourcePositions[parentId]!;
        } else {
           _sourcePositions[id] = _targetPositions[id]!; 
        }
      }
    }

    // 2. Deleted nodes (Collapsed)
    final disappearing = _sourcePositions.keys.where((k) => !_targetPositions.containsKey(k)).toList();
    
    for (final id in disappearing) {
        String? parentId;
        for (final m in _localMembers) {
          if (m.childrenIds.contains(id)) {
            parentId = m.id;
            break;
          }
        }
        
        if (parentId != null && _targetPositions.containsKey(parentId)) {
           _targetPositions[id] = _targetPositions[parentId]!;
        } else {
           _targetPositions[id] = _sourcePositions[id]!; 
        }
    }

    _controller.forward(from: 0).then((_) {
       setState(() {
         _calculateTargetLayout(); 
         _currentPositions = Map.of(_targetPositions);
         _renderPositions = Map.of(_targetPositions);
         _sourcePositions = {};
         _updateRenderData();
       });
    });
  }

  void _toggleExpand(String id) async {
    if (_controller.isAnimating) return; 
    
    // Check if we need to load children
    final byId = _getMemberMap();
    final member = byId[id];
    
    if (member != null && !_expandedIds.contains(id)) {
      // We are expanding. Do we have the children loaded?
      final missingChildren = member.childrenIds.any((childId) => !byId.containsKey(childId) && childId != 'has_children_marker');
      final onlyHasMarker = member.childrenIds.length == 1 && member.childrenIds.first == 'has_children_marker';
      
      if (missingChildren || onlyHasMarker) {
        setState(() {
           _loadingIds.add(id);
        });
        
        try {
          final newChildren = await widget.onLoadChildren(id);
          if (mounted) {
            setState(() {
              _loadingIds.remove(id);
              // Replace the 'has_children_marker' with actual loaded child IDs
              final updatedMember = member.copyWith(childrenIds: newChildren.map((c) => c.id).toList());
              
              // Update local members list
              final index = _localMembers.indexWhere((m) => m.id == id);
              if (index != -1) {
                 _localMembers[index] = updatedMember;
              }
              
              // Add new children that we don't already have
              final existingIds = _localMembers.map((m) => m.id).toSet();
              for (final child in newChildren) {
                 if (!existingIds.contains(child.id)) {
                    _localMembers.add(child);
                 }
              }
              
              _expandedIds.add(id);
            });
            _animateLayout();
          }
        } catch (e) {
          if (mounted) {
            setState(() { _loadingIds.remove(id); });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Қате: $e')));
          }
        }
        return; // Return early, animation will happen after fetch
      }
    }
    
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
    _animateLayout();
  }



  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _fitToScreen() {
    if (_renderWidth == 0 || _renderHeight == 0) return;
    
    final size = MediaQuery.of(context).size;
    final headerHeight = MediaQuery.of(context).padding.top + 120; // Approx header + controls
    final availableHeight = size.height - headerHeight - 100; // Buffer
    final availableWidth = size.width - 40;

    final scaleX = availableWidth / _renderWidth;
    final scaleY = availableHeight / _renderHeight;
    final scale = min(scaleX, min(scaleY, 1.0));

    // Центрируем
    final dx = (availableWidth - _renderWidth * scale) / 2;
    final dy = (availableHeight - _renderHeight * scale) / 2;

    _transformationController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  @override
  Widget build(BuildContext context) {
    if (_localMembers.isEmpty) return const Center(child: Text('Пусто'));
    
    if (!_initialized) {
      _initExpandedIds();
    }
    
    final byId = _getMemberMap();

    return Container(
      color: _bgYellow,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                 Text('${_localMembers.length} адам (жүктелген)', style: const TextStyle(fontWeight: FontWeight.bold, color: _primaryYellow)),
                 const Spacer(),
                  IconButton(
                    onPressed: _resetZoom,
                    icon: const Icon(Icons.center_focus_strong_outlined, color: _primaryYellow),
                    tooltip: 'Reset',
                  ),
                  IconButton(
                    onPressed: _fitToScreen,
                    icon: const Icon(Icons.fullscreen_exit_rounded, color: _primaryYellow),
                    tooltip: 'Fit',
                  ),
              ],
            ),
          ),
          
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformationController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(500),
              minScale: 0.1,
              maxScale: 4.0,
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
                        color: _primaryYellow.withAlpha(100),
                      ),
                    ),
                    
                    ..._renderPositions.entries.map((entry) {
                       final member = byId[entry.key];
                       if (member == null) return const SizedBox.shrink();
                       final hasChildren = member.childrenIds.isNotEmpty;
                       final isExpanded = _expandedIds.contains(member.id);
                       final isLoading = _loadingIds.contains(member.id);

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
                             isLoading: isLoading,
                             width: _nodeWidth,
                             height: _nodeHeight,
                             primaryColor: _primaryYellow,
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
    required this.isLoading,
    required this.width,
    required this.height,
    required this.primaryColor,
  });

  final FamilyMember member;
  final bool hasChildren;
  final bool isExpanded;
  final bool isLoading;
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
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => CircleAvatar(
                  backgroundColor: primaryColor,
                  radius: 18,
                  child: Text(
                    member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              member.fullName,
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
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    )
                  : Icon(
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
