{{flutter_js}}
{{flutter_build_config}}

const removeLoadingIndicator = () => {
  const loadingIndicator = document.getElementById('app-loading');
  if (loadingIndicator) {
    loadingIndicator.remove();
  }
};

const webAssetVersion = '20260616f';
const legacyCleanupKey = 'football-note:legacy-flutter-cleanup:v4';
const legacyCleanupReloadKey = 'football-note:legacy-flutter-cleanup-reload:v4';

if (window._flutter?.buildConfig?.builds) {
  window._flutter.buildConfig.builds = window._flutter.buildConfig.builds.map(
    (build) => ({
      ...build,
      mainJsPath: `${build.mainJsPath || 'main.dart.js'}?v=${webAssetVersion}`,
    }),
  );
}

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

const shouldReloadAfterLegacyCleanup = () => {
  try {
    return window.sessionStorage.getItem(legacyCleanupReloadKey) !== 'done';
  } catch (_) {
    return true;
  }
};

const markLegacyCleanupReloaded = () => {
  try {
    window.sessionStorage.setItem(legacyCleanupReloadKey, 'done');
  } catch (_) {
    // A reload loop guard is best effort only.
  }
};

const installSelfRemovingServiceWorker = async () => {
  if (!('serviceWorker' in navigator)) {
    return false;
  }

  try {
    const cleanupWorkerUrl = new URL(
      'flutter_service_worker.js?cleanup=v4',
      document.baseURI
    ).toString();
    const registration = await navigator.serviceWorker.register(
      cleanupWorkerUrl
    );
    await registration.update();
    return true;
  } catch (error) {
    console.warn('Unable to install Flutter service worker cleanup.', error);
    return false;
  }
};

const clearLegacyFlutterServiceWorker = async () => {
  let removedLegacyState = false;

  if (!('serviceWorker' in navigator)) {
    return removedLegacyState;
  }

  try {
    const registrations = await navigator.serviceWorker.getRegistrations();
    removedLegacyState =
      registrations.length > 0 || Boolean(navigator.serviceWorker.controller);
    if (removedLegacyState) {
      const installedCleanupWorker = await installSelfRemovingServiceWorker();
      if (!installedCleanupWorker) {
        await Promise.all(
          registrations.map((registration) => registration.unregister()),
        );
      }
    }
  } catch (error) {
    console.warn('Unable to unregister legacy Flutter service worker.', error);
  }

  if (!window.caches) {
    return removedLegacyState;
  }

  try {
    const cacheNames = await caches.keys();
    const flutterCacheNames = cacheNames.filter(
      (name) => name.includes('flutter') || name.includes('football-note'),
    );
    removedLegacyState = removedLegacyState || flutterCacheNames.length > 0;
    await Promise.all(flutterCacheNames.map((name) => caches.delete(name)));
  } catch (error) {
    console.warn('Unable to clear legacy Flutter caches.', error);
  }

  return removedLegacyState;
};

const loadFlutterApp = () => {
  return _flutter.loader.load({
    config: {
      useLocalCanvasKit: false,
    },
    onEntrypointLoaded: async (engineInitializer) => {
      const loadingOverlayWatchdog = window.setTimeout(
        removeLoadingIndicator,
        12000
      );
      const appRunner = await engineInitializer.initializeEngine();
      const runApp = appRunner.runApp();
      window.setTimeout(removeLoadingIndicator, 1500);
      await runApp;
      window.clearTimeout(loadingOverlayWatchdog);
      removeLoadingIndicator();
    },
  });
};

const startupCleanup = shouldRunLegacyCleanup()
  ? clearLegacyFlutterServiceWorker().then((removedLegacyState) => {
      markLegacyCleanupDone();
      if (removedLegacyState && shouldReloadAfterLegacyCleanup()) {
        markLegacyCleanupReloaded();
        window.location.reload();
        return new Promise(() => {});
      }
      return undefined;
    })
  : Promise.resolve();

startupCleanup
  .then(loadFlutterApp)
  .catch((error) => {
    console.warn('Flutter web startup cleanup failed.', error);
    return loadFlutterApp();
  });
