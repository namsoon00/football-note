(function (global) {
  'use strict';

  const handles = new Set();
  let apiPromise = null;

  const loadApi = () => {
    if (global.YT && typeof global.YT.Player === 'function') {
      return Promise.resolve(global.YT);
    }
    if (apiPromise) return apiPromise;
    apiPromise = new Promise((resolve, reject) => {
      const previousReady = global.onYouTubeIframeAPIReady;
      global.onYouTubeIframeAPIReady = () => {
        if (typeof previousReady === 'function') previousReady();
        resolve(global.YT);
      };
      const existing = document.querySelector(
        'script[src="https://www.youtube.com/iframe_api"]',
      );
      if (existing) return;
      const script = document.createElement('script');
      script.src = 'https://www.youtube.com/iframe_api';
      script.async = true;
      script.onerror = () => {
        if (typeof script.remove === 'function') script.remove();
        reject(new Error('youtube_api_load_failed'));
      };
      document.head.appendChild(script);
    }).catch((error) => {
      apiPromise = null;
      throw error;
    });
    return apiPromise;
  };

  const safeEmit = (handle, event) => {
    if (handle.disposed || !handles.has(handle)) return;
    try {
      handle.callback(event);
    } catch (_) {
      // Dart may have disposed between the membership check and callback.
    }
  };

  const currentTime = (handle) => {
    if (!handle.player || typeof handle.player.getCurrentTime !== 'function') {
      return handle.config.initialTime;
    }
    const value = Number(handle.player.getCurrentTime());
    return Number.isFinite(value) ? value : handle.config.initialTime;
  };

  const stopTelemetry = (handle) => {
    if (handle.telemetryTimer !== null) {
      global.clearInterval(handle.telemetryTimer);
      handle.telemetryTimer = null;
    }
  };

  const clearAutoplayTimer = (handle) => {
    if (handle.autoplayTimer !== null) {
      global.clearTimeout(handle.autoplayTimer);
      handle.autoplayTimer = null;
    }
  };

  const pauseAtBoundary = (handle, time) => {
    if (time < handle.config.end - 0.03) return false;
    if (handle.player && typeof handle.player.pauseVideo === 'function') {
      handle.player.pauseVideo();
    }
    if (handle.player && typeof handle.player.seekTo === 'function') {
      handle.player.seekTo(handle.config.end, true);
    }
    stopTelemetry(handle);
    safeEmit(handle, { type: 'ended', time: handle.config.end });
    return true;
  };

  const startTelemetry = (handle) => {
    stopTelemetry(handle);
    handle.telemetryTimer = global.setInterval(() => {
      const time = currentTime(handle);
      if (!pauseAtBoundary(handle, time)) {
        safeEmit(handle, { type: 'time', time });
      }
    }, 250);
  };

  const normalizedConfig = (json) => {
    const value = JSON.parse(json);
    const start = Number(value.start);
    const end = Number(value.end);
    const initial = Number(value.initialTime);
    if (
      !/^[A-Za-z0-9_-]{11}$/.test(String(value.videoId || '')) ||
      !Number.isFinite(start) ||
      !Number.isFinite(end) ||
      end <= start
    ) {
      throw new Error('invalid_configuration');
    }
    return {
      videoId: String(value.videoId),
      start,
      end,
      initialTime: Number.isFinite(initial)
        ? Math.min(end, Math.max(start, initial))
        : start,
      autoplay: value.autoplay === true,
      origin:
        typeof value.origin === 'string' && /^https?:\/\//.test(value.origin)
          ? value.origin
          : undefined,
    };
  };

  const create = (host, configurationJson, callback) => {
    const slot = document.createElement('div');
    const playerHost = document.createElement('div');
    slot.style.width = '100%';
    slot.style.height = '100%';
    playerHost.style.width = '100%';
    playerHost.style.height = '100%';
    slot.appendChild(playerHost);
    const handle = {
      host,
      slot,
      playerHost,
      callback,
      config: normalizedConfig(configurationJson),
      player: null,
      telemetryTimer: null,
      autoplayTimer: null,
      disposed: false,
    };
    host.replaceChildren(slot);
    host.__footballLearningVideoHandle = handle;
    handles.add(handle);
    safeEmit(handle, { type: 'loading', time: handle.config.initialTime });
    loadApi()
      .then((YT) => {
        if (handle.disposed) return;
        const playerVars = {
          // App controls keep seeking inside the selected learning passage.
          controls: 0,
          disablekb: 1,
          playsinline: 1,
          rel: 0,
          start: Math.floor(handle.config.start),
          end: Math.ceil(handle.config.end),
        };
        if (handle.config.origin) playerVars.origin = handle.config.origin;
        handle.player = new YT.Player(playerHost, {
          width: '100%',
          height: '100%',
          videoId: handle.config.videoId,
          playerVars,
          events: {
            onReady: (event) => {
              if (handle.disposed) return;
              event.target.cueVideoById({
                videoId: handle.config.videoId,
                startSeconds: handle.config.initialTime,
                endSeconds: handle.config.end,
              });
              // An initialized iframe may still reject the video. Media is
              // ready only when YouTube confirms that the video was cued.
              if (handle.config.autoplay) {
                event.target.playVideo();
                handle.autoplayTimer = global.setTimeout(() => {
                  handle.autoplayTimer = null;
                  safeEmit(handle, {
                    type: 'error',
                    time: currentTime(handle),
                    code: 'autoplay_blocked',
                  });
                }, 3000);
              }
            },
            onStateChange: (event) => {
              if (handle.disposed) return;
              const time = currentTime(handle);
              if (event.data === YT.PlayerState.PLAYING) {
                clearAutoplayTimer(handle);
                safeEmit(handle, {
                  type: 'playing',
                  time,
                  rates: handle.player.getAvailablePlaybackRates(),
                });
                startTelemetry(handle);
                return;
              }
              stopTelemetry(handle);
              if (event.data === YT.PlayerState.CUED) {
                safeEmit(handle, {
                  type: 'ready',
                  time: handle.config.initialTime,
                  rates: handle.player.getAvailablePlaybackRates(),
                });
              } else if (event.data === YT.PlayerState.PAUSED) {
                safeEmit(handle, { type: 'paused', time });
              } else if (event.data === YT.PlayerState.ENDED) {
                safeEmit(handle, { type: 'ended', time: handle.config.end });
              } else if (event.data === YT.PlayerState.BUFFERING) {
                safeEmit(handle, { type: 'loading', time });
              }
            },
            onPlaybackRateChange: (event) => {
              safeEmit(handle, {
                type: 'rate',
                time: currentTime(handle),
                rate: Number(event.data),
              });
            },
            onError: (event) => {
              stopTelemetry(handle);
              clearAutoplayTimer(handle);
              safeEmit(handle, {
                type: 'error',
                time: currentTime(handle),
                code: String(event.data),
              });
            },
          },
        });
      })
      .catch((error) => {
        safeEmit(handle, {
          type: 'error',
          time: handle.config.initialTime,
          code: error && error.message ? error.message : 'youtube_api_failed',
        });
      });
    return handle;
  };

  const command = (handle, name, value) => {
    if (!handle || handle.disposed || !handle.player) return;
    if (name === 'play') handle.player.playVideo();
    if (name === 'pause') handle.player.pauseVideo();
    if (name === 'seek') {
      const time = Math.min(
        handle.config.end,
        Math.max(handle.config.start, Number(value)),
      );
      handle.player.seekTo(time, true);
    }
    if (name === 'rate') handle.player.setPlaybackRate(Number(value));
  };

  const destroy = (handle) => {
    if (!handle || handle.disposed) return;
    handle.disposed = true;
    stopTelemetry(handle);
    clearAutoplayTimer(handle);
    handles.delete(handle);
    if (handle.player && typeof handle.player.destroy === 'function') {
      handle.player.destroy();
    }
    handle.player = null;
    if (
      handle.host &&
      handle.host.__footballLearningVideoHandle === handle
    ) {
      delete handle.host.__footballLearningVideoHandle;
      handle.host.replaceChildren();
    }
  };

  global.footballLearningVideo = { create, command, destroy };
})(typeof window !== 'undefined' ? window : globalThis);
