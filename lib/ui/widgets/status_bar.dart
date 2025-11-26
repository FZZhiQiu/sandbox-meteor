import 'package:flutter/material.dart';

import '../../models/meteorology_state.dart';

class StatusBar extends StatelessWidget {
  final MeteorologyState state;
  final bool isSimulating;
  
  const StatusBar({
    super.key,
    required this.state,
    required this.isSimulating,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade600),
        ),
      ),
      child: Row(
        children: [
          // 模拟状态指示器
          _buildStatusIndicator(),
          
          const SizedBox(width: 16),
          
          // 时间戳
          Expanded(
            child: _buildTimestamp(),
          ),
          
          const SizedBox(width: 16),
          
          // 网格信息
          _buildGridInfo(),
          
          const SizedBox(width: 16),
          
          // 模拟速度
          _buildSimulationSpeed(),
        ],
      ),
    );
  }
  
  Widget _buildStatusIndicator() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isSimulating ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isSimulating ? '模拟中' : '已停止',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimestamp() {
    return Text(
      '更新时间: ${_formatTimestamp(state.timestamp)}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
    );
  }
  
  Widget _buildGridInfo() {
    return Text(
      '网格: ${state.grid.nx}×${state.grid.ny}×${state.grid.nz}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
    );
  }
  
  Widget _buildSimulationSpeed() {
    return Text(
      '速度: ${state.simulationSpeed.toStringAsFixed(1)}x',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }
}