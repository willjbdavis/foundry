import 'dart:async';

import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_core/foundry_core.dart';

part 'rest_timer_service.g.dart';

const int _defaultRestTimerSeconds = 90;
const int maxRestTimerSeconds = 3599;

@foundry.FoundryServiceState()
class RestTimerState with _$RestTimerStateMixin {
  const RestTimerState({
    this.totalSeconds = _defaultRestTimerSeconds,
    this.remainingSeconds = _defaultRestTimerSeconds,
    this.isRunning = false,
    this.showRestFinishedBanner = false,
  });

  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool showRestFinishedBanner;
}

@foundry.FoundryService(stateful: true)
class RestTimerService extends StatefulService<RestTimerState> {
  RestTimerService() {
    emitNewState(const RestTimerState());
  }

  Timer? _timer;

  void setDuration(int totalSeconds) {
    final int normalizedSeconds = totalSeconds.clamp(1, maxRestTimerSeconds);
    _cancelTimer();
    emitNewState(
      state.copyWith(
        totalSeconds: normalizedSeconds,
        remainingSeconds: normalizedSeconds,
        isRunning: false,
        showRestFinishedBanner: false,
      ),
    );
  }

  void start() {
    if (state.isRunning) {
      return;
    }

    if (state.remainingSeconds <= 0) {
      emitNewState(
        state.copyWith(
          remainingSeconds: state.totalSeconds,
          isRunning: false,
          showRestFinishedBanner: false,
        ),
      );
    }

    _timer = Timer.periodic(const Duration(seconds: 1), _handleTick);
    emitNewState(
      state.copyWith(isRunning: true, showRestFinishedBanner: false),
    );
  }

  void pause() {
    if (!state.isRunning) {
      return;
    }

    _cancelTimer();
    emitNewState(
      state.copyWith(isRunning: false, showRestFinishedBanner: false),
    );
  }

  void toggleStartPause() {
    if (state.isRunning) {
      pause();
      return;
    }

    start();
  }

  void restart() {
    _cancelTimer();
    emitNewState(
      state.copyWith(
        remainingSeconds: state.totalSeconds,
        isRunning: false,
        showRestFinishedBanner: false,
      ),
    );
  }

  void dismissBanner() {
    if (!state.showRestFinishedBanner) {
      return;
    }

    emitNewState(state.copyWith(showRestFinishedBanner: false));
  }

  @override
  Future<void> onDispose() async {
    _cancelTimer();
  }

  void _handleTick(Timer timer) {
    final int nextRemainingSeconds = state.remainingSeconds - 1;
    if (nextRemainingSeconds <= 0) {
      _cancelTimer();
      emitNewState(
        state.copyWith(
          remainingSeconds: 0,
          isRunning: false,
          showRestFinishedBanner: true,
        ),
      );
      return;
    }

    emitNewState(
      state.copyWith(
        remainingSeconds: nextRemainingSeconds,
        showRestFinishedBanner: false,
      ),
    );
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
