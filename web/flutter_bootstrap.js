{{flutter_js}}
{{flutter_build_config}}

const removeLoadingIndicator = () => {
  const loadingIndicator = document.getElementById('app-loading');
  if (loadingIndicator) {
    loadingIndicator.remove();
  }
};

const webAssetVersion = '__WEB_ASSET_VERSION__';
const unstampedAssetVersionToken = ['__WEB', 'ASSET', 'VERSION__'].join('_');
const legacyCleanupReloadKey = 'football-note:legacy-flutter-cleanup-reload:v8';
const webBuildReloadKeyPrefix = 'football-note:web-build-reload:v1';
const webBuildVersionParam = 'fn_build';

if (window._flutter?.buildConfig?.builds) {
  window._flutter.buildConfig.builds = window._flutter.buildConfig.builds.map(
    (build) => ({
      ...build,
      mainJsPath: `${build.mainJsPath || 'main.dart.js'}?v=${webAssetVersion}`,
    }),
  );
}

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
      'flutter_service_worker.js?cleanup=v8',
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

const getLatestWebAssetVersion = async () => {
  if (!webAssetVersion || webAssetVersion === unstampedAssetVersionToken) {
    return null;
  }

  const versionUrl = new URL('version.json', document.baseURI);
  versionUrl.searchParams.set('t', String(Date.now()));
  const response = await fetch(versionUrl.toString(), {
    cache: 'no-store',
  });

  if (!response.ok) {
    return null;
  }

  const versionManifest = await response.json();
  const latestVersion =
    typeof versionManifest.assetVersion === 'string'
      ? versionManifest.assetVersion.trim()
      : '';
  return latestVersion || null;
};

const shouldReloadForWebBuild = (latestVersion) => {
  if (!latestVersion || latestVersion === webAssetVersion) {
    return false;
  }

  try {
    return (
      window.sessionStorage.getItem(
        `${webBuildReloadKeyPrefix}:${latestVersion}`,
      ) !== 'done'
    );
  } catch (_) {
    return true;
  }
};

const markWebBuildReloaded = (latestVersion) => {
  try {
    window.sessionStorage.setItem(
      `${webBuildReloadKeyPrefix}:${latestVersion}`,
      'done',
    );
  } catch (_) {
    // A reload loop guard is best effort only.
  }
};

const reloadForLatestWebBuild = (latestVersion) => {
  markWebBuildReloaded(latestVersion);
  const nextUrl = new URL(window.location.href);
  nextUrl.searchParams.set(webBuildVersionParam, latestVersion);
  window.location.replace(nextUrl.toString());
};

const reloadIfOutdatedWebBuild = async () => {
  try {
    const latestVersion = await getLatestWebAssetVersion();
    if (!shouldReloadForWebBuild(latestVersion)) {
      return false;
    }

    await clearLegacyFlutterServiceWorker();
    reloadForLatestWebBuild(latestVersion);
    return true;
  } catch (error) {
    console.warn('Unable to check latest web build version.', error);
    return false;
  }
};

const loadFlutterApp = () => {
  return _flutter.loader.load({
    config: {
      useLocalCanvasKit: true,
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

const runStartupMaintenance = async () => {
  const removedLegacyState = await clearLegacyFlutterServiceWorker();
  if (removedLegacyState && shouldReloadAfterLegacyCleanup()) {
    markLegacyCleanupReloaded();
    window.location.reload();
    return true;
  }

  return reloadIfOutdatedWebBuild();
};

runStartupMaintenance()
  .then((isReloading) => {
    if (isReloading) {
      return new Promise(() => {});
    }
    return loadFlutterApp();
  })
  .catch((error) => {
    console.warn('Flutter web startup cleanup failed.', error);
    return loadFlutterApp();
  });
