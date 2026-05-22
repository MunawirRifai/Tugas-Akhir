import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/food_mapper.dart';

enum InAppCallType {
  audio,
  video,
}

class CallPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> food;
  final String counterpartName;
  final InAppCallType callType;

  const CallPage({
    super.key,
    required this.token,
    required this.food,
    required this.counterpartName,
    required this.callType,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late final FoodRecord _food;

  Timer? _timer;

  int _elapsedSeconds = 0;
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isSpeakerEnabled = true;
  bool _isCameraEnabled = true;

  bool get _isVideoCall => widget.callType == InAppCallType.video;

  @override
  void initState() {
    super.initState();

    _food = FoodRecord(widget.food);
    _connectMockCall();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _connectMockCall() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    setState(() {
      _isConnected = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _endCall() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
    });
  }

  void _toggleCamera() {
    setState(() {
      _isCameraEnabled = !_isCameraEnabled;
    });
  }

  String get _durationLabel {
    final int minutes = _elapsedSeconds ~/ 60;
    final int seconds = _elapsedSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get _callTitle {
    return _isVideoCall ? 'Video Call' : 'Audio Call';
  }

  String get _connectionLabel {
    return _isConnected ? _durationLabel : 'Menghubungkan...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: Column(
            children: [
              _CallTopBar(
                callTitle: _callTitle,
                connectionLabel: _connectionLabel,
                onClose: _endCall,
              ),
              const SizedBox(height: AppSpacing.x4),
              Expanded(
                child: _isVideoCall
                    ? _VideoCallPreview(
                        counterpartName: widget.counterpartName,
                        foodName: _food.name,
                        isCameraEnabled: _isCameraEnabled,
                      )
                    : _AudioCallPreview(
                        counterpartName: widget.counterpartName,
                        foodName: _food.name,
                      ),
              ),
              const SizedBox(height: AppSpacing.x3),
              _NetworkSimulationCard(
                isConnected: _isConnected,
                callType: widget.callType,
              ),
              const SizedBox(height: AppSpacing.x3),
              _CallControls(
                isVideoCall: _isVideoCall,
                isMuted: _isMuted,
                isSpeakerEnabled: _isSpeakerEnabled,
                isCameraEnabled: _isCameraEnabled,
                onMute: _toggleMute,
                onSpeaker: _toggleSpeaker,
                onCamera: _toggleCamera,
                onEndCall: _endCall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallTopBar extends StatelessWidget {
  final String callTitle;
  final String connectionLabel;
  final VoidCallback onClose;

  const _CallTopBar({
    required this.callTitle,
    required this.connectionLabel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onClose,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: AppSpacing.x1),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                callTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              Text(
                connectionLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x1,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.42),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'In-App',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AudioCallPreview extends StatelessWidget {
  final String counterpartName;
  final String foodName;

  const _AudioCallPreview({
    required this.counterpartName,
    required this.foodName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(48),
            boxShadow: AppShadows.brand,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 72,
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
        Text(
          counterpartName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: AppSpacing.x1),
        Text(
          foodName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
              ),
        ),
      ],
    );
  }
}

class _VideoCallPreview extends StatelessWidget {
  final String counterpartName;
  final String foodName;
  final bool isCameraEnabled;

  const _VideoCallPreview({
    required this.counterpartName,
    required this.foodName,
    required this.isCameraEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: isCameraEnabled
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: AppShadows.brand,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          counterpartName,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          foodName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.72),
                                  ),
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.videocam_off_rounded,
                      color: Colors.white,
                      size: 70,
                    ),
            ),
          ),
          Positioned(
            right: AppSpacing.x2,
            bottom: AppSpacing.x2,
            child: Container(
              width: 104,
              height: 144,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.20),
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkSimulationCard extends StatelessWidget {
  final bool isConnected;
  final InAppCallType callType;

  const _NetworkSimulationCard({
    required this.isConnected,
    required this.callType,
  });

  @override
  Widget build(BuildContext context) {
    final String bitrate = callType == InAppCallType.video
        ? '± 900 kbps'
        : '± 64 kbps';

    final String latency = isConnected ? '± 42 ms' : 'estimasi...';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Row(
          children: [
            Expanded(
              child: _NetworkMetric(
                label: 'Bitrate',
                value: bitrate,
              ),
            ),
            const SizedBox(width: AppSpacing.x1),
            Expanded(
              child: _NetworkMetric(
                label: 'Latency',
                value: latency,
              ),
            ),
            const SizedBox(width: AppSpacing.x1),
            Expanded(
              child: _NetworkMetric(
                label: 'Mode',
                value: 'VoIP',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkMetric extends StatelessWidget {
  final String label;
  final String value;

  const _NetworkMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.70),
                ),
          ),
        ],
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  final bool isVideoCall;
  final bool isMuted;
  final bool isSpeakerEnabled;
  final bool isCameraEnabled;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onCamera;
  final VoidCallback onEndCall;

  const _CallControls({
    required this.isVideoCall,
    required this.isMuted,
    required this.isSpeakerEnabled,
    required this.isCameraEnabled,
    required this.onMute,
    required this.onSpeaker,
    required this.onCamera,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ControlButton(
          icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: isMuted ? 'Muted' : 'Mute',
          onTap: onMute,
        ),
        _ControlButton(
          icon: isSpeakerEnabled
              ? Icons.volume_up_rounded
              : Icons.volume_off_rounded,
          label: 'Speaker',
          onTap: onSpeaker,
        ),
        if (isVideoCall)
          _ControlButton(
            icon: isCameraEnabled
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            label: 'Camera',
            onTap: onCamera,
          ),
        _ControlButton(
          icon: Icons.call_end_rounded,
          label: 'End',
          isDanger: true,
          onTap: onEndCall,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDanger;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color background =
        isDanger ? AppColors.danger : Colors.white.withValues(alpha: 0.12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
          ),
        ],
      ),
    );
  }
}