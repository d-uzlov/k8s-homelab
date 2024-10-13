
import { setSoundButtons, setButtons, reloadButton, stopButton, controlsTopButton, controlsBottomButton, redBorder } from './player-buttons.js';
import { getJSON, parseHash, setDefaultSettingsName, getSettings, saveSettings } from './utils.js';
import { getDataSources } from './data-sources.js';

function updateVolumeButtons(playerInstance) {
  setSoundButtons(playerInstance, playerInstance.getVolume(), playerInstance.getMute(), function () {
    saveSettings('volume', function (settings) {
      settings.volume = playerInstance.getVolume();
      settings.mute = playerInstance.getMute();
    });
  });
}

function setupEvents(playerInstance) {
  playerInstance.on('ready', function () {
    playerInstance.setAutoQuality(false);
    const settings = getSettings();
    setSource(playerInstance, settings.sourceType, settings.sourceFile);
    updateVolumeButtons(playerInstance);
  });

  playerInstance.on('stateChanged', function (data) {
    console.log('stateChanged', data);
    // console.log('quality levels', playerInstance.getQualityLevels());
    // restoreQuality(playerInstance, settings.qualityLabel, settings.qualityHeight);
    if (data.newstate == 'error') {
      setTimeout(function () {
        playerInstance.load();
      }, 1000);
    }
  });

  playerInstance.on('volumeChanged', function (data) {
    updateVolumeButtons(playerInstance);
  });
  // playerInstance.on('qualityLevelChanged', function (data) {
  //   console.log('qualityLevelChanged', data);
  // });
}

var globalPlayer = null;
function destroyPlayer() {
  if (globalPlayer === null || globalPlayer === undefined) {
    return
  }
  globalPlayer.remove();
  globalPlayer = null;
}

function createPlayer(playerOptions) {
  destroyPlayer();

  const containerId = 'main-player';
  globalPlayer = OvenPlayer.create(containerId, playerOptions);
}

async function getAppInfo(apiName, url, app, key) {
  const sources = getDataSources();
  const apiUrl = sources[apiName];
  if (apiUrl === undefined) {
    console.log('unknown api', apiName, sources);
    return;
  }
  let query = apiUrl;
  query += '/app?'
  query += 'url=' + url;
  query += '&app=' + app;
  query += '&key=' + key;
  return getJSON(query);
}

function setQualityButtons(appInfo, setSourceFile, selected) {
  if (appInfo.webrtc != null) {
    const qualityButtons = [];
    const links = appInfo.webrtc.links;
    for (const link of links) {
      if (link.resolution == 'multi' && links.length > 1) {
        continue
      }
      qualityButtons.push({
        name: link.resolution,
        file: link.file,
        action: () => setSourceFile('webrtc', link.file),
      });
    }
    setButtons('webrtc-quality-buttons', qualityButtons, function (val) {
      return val.file == selected;
    })
  } else {
    console.log('hiding webrtc quality');
    document.getElementById('webrtc-quality').style.display = 'none';
  }
  if (appInfo.llhls != null) {
    const qualityButtons = [];
    const links = appInfo.llhls.links;
    for (const link of links) {
      if (link.resolution == 'multi' && links.length > 1) {
        continue
      }
      qualityButtons.push({
        name: link.resolution,
        file: link.file,
        action: () => setSourceFile('llhls', link.file),
      });
    }
    setButtons('hls-quality-buttons', qualityButtons, function (val) {
      return val.file == selected;
    })
  } else {
    console.log('hiding hls quality');
    document.getElementById('hls-quality').style.display = 'none';
  }
  if (appInfo.webrtc == null && appInfo.llhls == null) {
    document.getElementById('no-quality').style.display = 'block';
  }
}

function makePlaySources(appInfo, url, key) {
  const res = [];
  if (appInfo.webrtc != null) {
    const links = appInfo.webrtc.links;
    for (const link of links) {
      if (link.resolution == 'multi' && links.length > 1) {
        continue
      }
      res.push({
        file: 'wss://' + url + '/' + appInfo.name + '/' + key + '/' + link.file + '?transport=tcp',
        type: 'webrtc',
      });
    }
  }
  if (appInfo.llhls != null) {
    const links = appInfo.llhls.links;
    for (const link of links) {
      if (link.resolution == 'multi' && links.length > 1) {
        continue
      }
      res.push({
        file: 'https://' + url + '/' + appInfo.name + '/' + key + '/' + link.file,
        type: 'll-hls',
      });
    }
  }
  return res;
}

function findSource(sources, type, file) {
  if (type == null) {
    return null;
  }
  let ending = '/' + file;
  if (type == 'webrtc') {
    ending += '?transport=tcp';
  }
  for (let i = 0; i < sources.length; i++) {
    const s = sources[i];
    if (s.file.endsWith(ending)) {
      return i;
    }
  }
  return null;
}

function setSource(playerInstance, type, file) {
  const sources = playerInstance.getSources();
  if (sources == null || !(sources.length > 0)) {
    return;
  }
  const foundIndex = findSource(sources, type, file);
  if (foundIndex != null) {
    playerInstance.setCurrentSource(foundIndex);
  } else {
    playerInstance.setCurrentSource(0);
  }
}

function updateQualityButtons(appInfo, selectedSource) {
  setQualityButtons(appInfo, (type, file) => {
    setSource(globalPlayer, type, file);
    saveSettings('source', function (settings) {
      settings.sourceType = type;
      settings.sourceFile = file;
    });
    updateQualityButtons(appInfo, file);
  }, selectedSource);
}

function updateSourceSettings(sources, appInfo) {
  if (sources == null || sources.length == 0) {
    return;
  }
  let settings = getSettings();

  let type = settings.sourceType;
  let file = settings.sourceFile;
  let sourceIndex = findSource(sources, type, file);
  if (sourceIndex != null) {
    return;
  }
  if (appInfo.props == null) {
    return;
  }
  type = appInfo.props.preferType;
  file = appInfo.props.prefer
  sourceIndex = findSource(sources, type, file);
  if (sourceIndex != null) {
    saveSettings('prefer', (settings) => {
      settings.sourceType = type;
      settings.sourceFile = file;
    });
    return;
  }
  let anySource = null;
  if (appInfo.webrtc != null) {
    const links = appInfo.webrtc.links;
    for (const link of links) {
      if (link.resolution == 'multi' && links.length > 1) {
        continue
      }
      anySource = {
        type: 'webrtc',
        file: link.file,
      };
      break;
    }
  } else if (appInfo.llhls != null) {
    const links = appInfo.llhls.links;
    for (const link of links) {
      if (link.resolution == 'multi' && links.length > 1) {
        continue
      }
      anySource = {
        type: 'llhls',
        file: link.file,
      };
      break;
    }
  }
  if (anySource != null) {
    saveSettings('prefer', (settings) => {
      settings.sourceType = anySource.type;
      settings.sourceFile = anySource.file;
    });
  }
}

async function setupPage() {
  const args = parseHash();
  if (args.url === undefined || args.app === undefined || args.key === undefined || args.api == undefined) {
    alert('required args missing');
    return;
  }
  setDefaultSettingsName('settings@' + args.key + '@' + args.url + '/' + args.app);

  const appInfo = await getAppInfo(args.api, args.url, args.app, args.key);
  const sources = makePlaySources(appInfo, args.url, args.key);

  updateSourceSettings(sources, appInfo);

  let settings = getSettings();
  console.log('using settings', settings);

  updateQualityButtons(appInfo, settings.sourceFile);

  const playerOptions = {
    // title: 'My title',
    autoStart: true,
    autoFallback: false,
    controls: false,
    // controls: true,
    mute: settings.mute ?? false,
    volume: settings.volume ?? 100,
    sources: sources,
  };

  createPlayer(playerOptions)
  setupEvents(globalPlayer);
}

reloadButton.onclick = setupPage;
stopButton.onclick = destroyPlayer;

const globalSettings = getSettings('global');
function moveControls(isTop) {
  const controls = document.getElementById('main-controls');
  const player = document.getElementById('main-player');
  const lastNode = isTop ? player : controls;
  controls.parentNode.appendChild(lastNode);
}
const topControls = globalSettings.topControls ?? true
moveControls(topControls);
const selectedControls = topControls ? controlsTopButton : controlsBottomButton;
selectedControls.classList.add(redBorder);
controlsTopButton.onclick = () => {
  const isTop = true;
  moveControls(isTop);
  saveSettings('controls-position', (settings) => settings.topControls = isTop, 'global');
  controlsTopButton.classList.add(redBorder);
  controlsBottomButton.classList.remove(redBorder);
}
controlsBottomButton.onclick = () => {
  const isTop = false;
  moveControls(isTop);
  saveSettings('controls-position', (settings) => settings.topControls = isTop, 'global');
  controlsTopButton.classList.remove(redBorder);
  controlsBottomButton.classList.add(redBorder);
}

OvenPlayer.debug(false);
setupPage();
