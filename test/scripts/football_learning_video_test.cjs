const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const adapterPath = path.resolve(
  __dirname,
  '../../web/football_learning_video.js',
);

const node = (tag = 'div') => ({
  tag,
  style: {},
  children: [],
  parentNode: null,
  appendChild(child) {
    child.parentNode = this;
    this.children.push(child);
  },
  replaceChildren(...children) {
    for (const child of this.children) child.parentNode = null;
    this.children = children;
    for (const child of children) child.parentNode = this;
  },
  remove() {
    if (!this.parentNode) return;
    this.parentNode.replaceChildren(
      ...this.parentNode.children.filter((child) => child !== this),
    );
  },
});

const createContext = () => {
  const context = {
    console,
    JSON,
    Math,
    Number,
    Promise,
    Error,
    Set,
    String,
    setImmediate,
    queueMicrotask,
    setInterval,
    clearInterval,
    setTimeout,
    clearTimeout,
  };
  context.window = context;
  context.globalThis = context;
  context.document = {
    querySelector: () => null,
    createElement: (tag) => node(tag),
    head: node('head'),
  };
  vm.createContext(context);
  vm.runInContext(fs.readFileSync(adapterPath, 'utf8'), context);
  return context;
};

const configuration = (overrides = {}) =>
  JSON.stringify({
    videoId: 'abcdefghijk',
    start: 100,
    end: 120,
    initialTime: 104,
    autoplay: false,
    origin: 'https://example.test',
    ...overrides,
  });

(async () => {
  const context = createContext();
  const calls = [];
  let options;
  let playerHost;
  let destroyed = 0;
  const target = {
    cueVideoById: (value) => calls.push(['cue', value]),
    getAvailablePlaybackRates: () => [0.5, 0.75, 1],
    getCurrentTime: () => 105,
    playVideo: () => calls.push(['play']),
    pauseVideo: () => calls.push(['pause']),
    seekTo: (time) => calls.push(['seek', time]),
    setPlaybackRate: (rate) => calls.push(['rate', rate]),
    destroy: () => {
      destroyed += 1;
    },
  };
  context.YT = {
    PlayerState: { PLAYING: 1, PAUSED: 2, ENDED: 0, BUFFERING: 3, CUED: 5 },
    Player: function (host, value) {
      playerHost = host;
      options = value;
      const iframe = node('iframe');
      host.parentNode.replaceChildren(iframe);
      queueMicrotask(() => value.events.onReady({ target }));
      return target;
    },
  };

  const events = [];
  const stableHost = node('platform-view');
  const first = context.footballLearningVideo.create(
    stableHost,
    configuration(),
    (event) => events.push(event),
  );
  await new Promise((resolve) => setImmediate(resolve));

  assert.equal(options.videoId, 'abcdefghijk');
  assert.equal(options.playerVars.origin, 'https://example.test');
  assert.equal(playerHost.tag, 'div');
  assert.equal(stableHost.children[0].tag, 'div');
  assert.equal(stableHost.children[0].children[0].tag, 'iframe');
  assert.equal(options.playerVars.controls, 0);
  assert.equal(options.playerVars.disablekb, 1);
  assert.equal(events.some((event) => event.type === 'ready'), false);
  options.events.onStateChange({ data: context.YT.PlayerState.CUED });
  assert.equal(events.at(-1).type, 'ready');
  assert.deepEqual([...events.at(-1).rates], [0.5, 0.75, 1]);

  options.events.onStateChange({ data: context.YT.PlayerState.PLAYING });
  assert.equal(events.at(-1).type, 'playing');
  options.events.onStateChange({ data: context.YT.PlayerState.BUFFERING });
  assert.equal(events.at(-1).type, 'loading');

  context.footballLearningVideo.command(first, 'seek', 999);
  context.footballLearningVideo.command(first, 'rate', 0.75);
  assert.deepEqual(calls.find((call) => call[0] === 'seek'), ['seek', 120]);
  assert.deepEqual(calls.find((call) => call[0] === 'rate'), ['rate', 0.75]);

  const count = events.length;
  context.footballLearningVideo.destroy(first);
  options.events.onError({ data: 101 });
  assert.equal(destroyed, 1);
  assert.equal(events.length, count);
  assert.equal(stableHost.children.length, 0);

  const second = context.footballLearningVideo.create(
    stableHost,
    configuration({ initialTime: 110 }),
    () => {},
  );
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(stableHost.children[0].children[0].tag, 'iframe');
  assert.equal(playerHost.parentNode, null);
  context.footballLearningVideo.destroy(second);

  assert.throws(
    () =>
      context.footballLearningVideo.create(
        stableHost,
        JSON.stringify({ videoId: 'bad', start: 0, end: 1 }),
        () => {},
      ),
    /invalid_configuration/,
  );

  const retryContext = createContext();
  let attempts = 0;
  const rejectedEvents = [];
  retryContext.document.head.appendChild = (script) => {
    attempts += 1;
    if (attempts === 1) {
      script.onerror();
      return;
    }
    retryContext.YT = {
      PlayerState: { PLAYING: 1, PAUSED: 2, ENDED: 0, BUFFERING: 3, CUED: 5 },
      Player: function (_host, value) {
        const retryTarget = {
          cueVideoById: () => queueMicrotask(() =>
            value.events.onStateChange({ data: 5, target: retryTarget })),
          getAvailablePlaybackRates: () => [1],
          getCurrentTime: () => 104,
          destroy: () => {},
        };
        queueMicrotask(() =>
          value.events.onReady({
            target: retryTarget,
          }),
        );
        return retryTarget;
      },
    };
    retryContext.onYouTubeIframeAPIReady();
  };
  retryContext.footballLearningVideo.create(
    node('platform-view'),
    configuration(),
    (event) => rejectedEvents.push(event),
  );
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(rejectedEvents.at(-1).type, 'error');

  const retryEvents = [];
  retryContext.footballLearningVideo.create(
    node('platform-view'),
    configuration(),
    (event) => retryEvents.push(event),
  );
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(attempts, 2);
  assert.equal(retryEvents.some((event) => event.type === 'ready'), true);
})();
