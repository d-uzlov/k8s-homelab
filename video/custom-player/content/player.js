
import { setSoundButtons, setButtons, reloadButton, stopButton, controlsTopButton, controlsBottomButton, redBorder } from './player-buttons.js';
import { getJSON, parseHash, setDefaultSettingsName, getSettings, saveSettings } from './utils.js';
import { getDataSources } from './data-sources.js';

const metaType = {
  llhls: 'llhls',
  webRtcTcp: 'webrtc-tcp',
  webRtcUdp: 'webrtc-udp',
};

const omePlayerType = {
  llhls: 'll-hls',
  webrtc: 'webrtc',
};

const settingsPreferKey = 'prefer';

function updateVolumeButtons(playerInstance) {
  setSoundButtons(playerInstance, playerInstance.getVolume(), playerInstance.getMute(), function () {
    saveSettings('', 'volume', function (settings) {
      settings.volume = playerInstance.getVolume();
      settings.mute = playerInstance.getMute();
    });
  });
}

function setupEvents(playerInstance) {
  playerInstance.on('ready', function () {
    playerInstance.setAutoQuality(false);
    const settings = getSettings();
    // setSource(playerInstance, settings.sourceType, settings.sourceFile);
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

var globalSourcesMeta = null;

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

function setQualityButtons(appInfo, setSourceFile, selectedType, selectedFile) {
  if (appInfo.webrtc != null) {
    const qualityButtonsTcp = [];
    const qualityButtonsUdp = [];
    const links = appInfo.webrtc.links;
    for (const link of links) {
      if (link.resolution == 'multi' && links.length > 1) {
        continue
      }
      qualityButtonsTcp.push({
        name: link.resolution,
        file: link.file,
        type: metaType.webRtcTcp,
        action: () => setSourceFile(metaType.webRtcTcp, link.file),
      });
      qualityButtonsUdp.push({
        name: link.resolution,
        file: link.file,
        type: metaType.webRtcUdp,
        action: () => setSourceFile(metaType.webRtcUdp, link.file),
      });
    }
    setButtons('webrtc-tcp-quality-buttons', qualityButtonsTcp, (val) => val.file == selectedFile && val.type == selectedType);
    setButtons('webrtc-udp-quality-buttons', qualityButtonsUdp, (val) => val.file == selectedFile && val.type == selectedType);
  } else {
    console.log('hiding webrtc quality');
    document.getElementById('webrtc-udp-quality').style.display = 'none';
    document.getElementById('webrtc-tcp-quality').style.display = 'none';
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
        action: () => setSourceFile(metaType.llhls, link.file),
      });
    }
    setButtons('hls-quality-buttons', qualityButtons, (val) => val.file == selectedFile && val.type == selectedType);
  } else {
    console.log('hiding hls quality');
    document.getElementById('hls-quality').style.display = 'none';
  }
  if (appInfo.webrtc == null && appInfo.llhls == null) {
    document.getElementById('no-quality').style.display = 'block';
  }
}

function sourceMetaIndex(type, file) {
  return type + ":" + file;
}

function makePlaySources(appInfo, url, key) {
  const list = [];
  const meta = {};
  if (appInfo.webrtc != null) {
    const links = appInfo.webrtc.links;
    for (const link of links) {
      if (link.resolution == 'multi' && links.length > 1) {
        continue
      }
      const fileTcp = 'wss://' + url + '/' + appInfo.name + '/' + key + '/' + link.file + '?transport=tcp';
      const fileUdp = 'wss://' + url + '/' + appInfo.name + '/' + key + '/' + link.file + '?transport=udp';
      list.push({ file: fileTcp, type: omePlayerType.webrtc });
      list.push({ file: fileUdp, type: omePlayerType.webrtc });
      meta[sourceMetaIndex(metaType.webRtcTcp, link.file)] = fileTcp;
      meta[sourceMetaIndex(metaType.webRtcUdp, link.file)] = fileUdp;
    }
  }
  if (appInfo.llhls != null) {
    const links = appInfo.llhls.links;
    for (const link of links) {
      if (link.resolution == 'multi' && links.length > 1) {
        continue
      }
      const file = 'https://' + url + '/' + appInfo.name + '/' + key + '/' + link.file;
      list.push({ file: file, type: omePlayerType.llhls });
      meta[sourceMetaIndex(metaType.llhls, link.file)] = file;
    }
  }
  return { list, meta };
}

function findSource(sources, type, file) {
  if (type == null) {
    return null;
  }
  const link = globalSourcesMeta[sourceMetaIndex(type, file)];
  for (let i = 0; i < sources.length; i++) {
    const s = sources[i];
    if (s.file == link) {
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

function updateQualityButtons(appInfo, selectedType, selectedFile) {
  setQualityButtons(appInfo, (type, file) => {
    setSource(globalPlayer, type, file);
    saveSettings('', 'set quality', function (settings) {
      settings.sourceType = type;
      settings.sourceFile = file;
    });
    updateQualityButtons(appInfo, type, file);
  }, selectedType, selectedFile);
}

function updateSourceSettings(sources, appInfo) {
  if (sources == null || sources.length == 0) {
    return;
  }
  let settings = getSettings(settingsPreferKey);

  let type = settings.sourceType;
  let file = settings.sourceFile;
  let sourceIndex = findSource(sources, type, file);
  if (sourceIndex != null) {
    return;
  }
  if (appInfo.props == null) {
    return;
  }
  console.log('no matching saved source, use default');
  type = appInfo.props.preferType;
  if (type == 'webrtc') {
    type = metaType.webRtcTcp;
  }
  file = appInfo.props.prefer;
  sourceIndex = findSource(sources, type, file);
  if (sourceIndex != null) {
    saveSettings(settingsPreferKey, 'updateSourceSettings', (settings) => {
      settings.sourceType = type;
      settings.sourceFile = file;
    });
    return;
  }
  console.log('no default source, use any');
}

async function setupPage() {
  const args = parseHash();
  if (args.url === undefined || args.app === undefined || args.key === undefined || args.api == undefined) {
    alert('required args missing');
    return;
  }
  setDefaultSettingsName('settings@' + args.key + '@' + args.url + '/' + args.app);

  const streamNameLabel = document.getElementById('stream-name');
  streamNameLabel.textContent = args.key + ' streaming';

  const appInfo = await getAppInfo(args.api, args.url, args.app, args.key);
  const playSources = makePlaySources(appInfo, args.url, args.key);
  globalSourcesMeta = playSources.meta;

  updateSourceSettings(playSources.list, appInfo);

  let settings = getSettings();
  console.log('using settings', settings);
  // let preferSettings = getSettings(settingsPreferKey);

  const foundIndex = findSource(playSources.list, settings.sourceType, settings.sourceFile);
  if (foundIndex != null) {
    // at start player selects the first source
    const selectedSource = playSources.list[foundIndex];
    playSources.list[foundIndex] = playSources.list[0];
    playSources.list[0] = selectedSource;
  }

  updateQualityButtons(appInfo, settings.sourceType, settings.sourceFile);

  const playerOptions = {
    // title: 'My title',
    autoStart: true,
    autoFallback: false,
    controls: false,
    // controls: true,
    mute: settings.mute ?? false,
    volume: settings.volume ?? 100,
    sources: playSources.list,
  };

  createPlayer(playerOptions)
  setupEvents(globalPlayer);
}

reloadButton.onclick = setupPage;
stopButton.onclick = destroyPlayer;

const globalSettingsKey = 'global';
function moveControls(isTop) {
  const controls = document.getElementById('main-controls');
  const player = document.getElementById('main-player');
  const lastNode = isTop ? player : controls;
  controls.parentNode.appendChild(lastNode);
  saveSettings(globalSettingsKey, 'controls-position', (settings) => settings.topControls = isTop);
  const selectedControls = isTop ? controlsTopButton : controlsBottomButton;
  const deselectedControls = isTop ? controlsBottomButton : controlsTopButton;
  selectedControls.classList.add(redBorder);
  deselectedControls.classList.remove(redBorder);
}

const globalSettings = getSettings(globalSettingsKey);
const topControls = globalSettings.topControls ?? true;
moveControls(topControls);
controlsTopButton.onclick = () => moveControls(true);
controlsBottomButton.onclick = () => moveControls(false);

// .debug enables verbose logs
OvenPlayer.debug(false);
setupPage();
