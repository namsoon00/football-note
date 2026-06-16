{{flutter_js}}
{{flutter_build_config}}

const removeLoadingIndicator = () => {
  document.getElementById('app-loading')?.remove();
};

const legacyCleanupKey = 'football-note:legacy-flutter-cleanup:v1';

const shouldRunLegacyCleanup = () => {
  try {
    return window.localStorage.getItem(legacyCleanupKey) !== 'done';
  } catch (_) {
    return true;
  }
};

const markLegacyCleanupDone = () => {
  try {
    window.localStorage.setItem(legacyCleanupKey, 'done');
  } catch (_) {
    // Ignore storage failures; startup should never depend on persistence.
  }
};

const clearLegacyFlutterServiceWorker = async () => {
  if (!('serviceWorker' in navigator)) {
    return;
  }

  try {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(
      registrations.map((registration) => registration.unregister()),
    );
  } catch (error) {
    console.warn('Unable to unregister legacy Flutter service worker.', error);
  }

  if (!window.caches) {
    return;
  }

  try {
    const cacheNames = await caches.keys();
    await Promise.all(
      cacheNames
        .filter(
          (name) => name.includes('flutter') || name.includes('football-note'),
        )
        .map((name) => caches.delete(name)),
    );
  } catch (error) {
    console.warn('Unable to clear legacy Flutter caches.', error);
  }
};

const loadFlutterApp = () => {
  return _flutter.loader.load({
    config: {
      useLocalCanvasKit: false,
    },
    onEntrypointLoaded: async (engineInitializer) => {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
      removeLoadingIndicator();
    },
  });
};

const startupCleanup = shouldRunLegacyCleanup()
  ? clearLegacyFlutterServiceWorker().finally(markLegacyCleanupDone)
  : Promise.resolve();

startupCleanup
  .then(loadFlutterApp)
  .catch((error) => {
    console.warn('Flutter web startup cleanup failed.', error);
    return loadFlutterApp();
  });
