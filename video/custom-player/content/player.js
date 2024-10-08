
import { setSoundButtons, setReloadAction, setStopAction, setButtons } from './player-buttons.js';
import { restoreQuality } from './player-quality.js';
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
  playerInstance.on('ready', function (data) {
    console.log('player ready', data);
    playerInstance.setAutoQuality(false);
    const settings = getSettings();
    if (settings.sourceType != null && settings.sourceFile != null) {
      setSource(globalPlayer, settings.sourceType, settings.sourceFile);
    }
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
    console.log('volumeChanged', data);
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
  
  const containerId = 'player_id';
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
  console.log('setQualityButtons: appInfo', appInfo);
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

function setSource(playerInstance, type, file) {
  const sources = playerInstance.getSources();
  let ending = '/' + file;
  if (type == 'webrtc') {
    ending += '?transport=tcp';
  }
  for (let i = 0; i < sources.length; i++) {
    const s = sources[i];
    if (s.file.endsWith(ending)) {
      playerInstance.setCurrentSource(i);
      return;
    }
  }
  alert('womething went wrong when changing quality');
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

async function setupPage() {
  const args = parseHash();
  if (args.url === undefined || args.app === undefined || args.key === undefined || args.api == undefined) {
    console.log('args missing');
    return;
  }
  const appInfo = await getAppInfo(args.api, args.url, args.app, args.key);
  console.log('app info', appInfo)

  setDefaultSettingsName('settings@' + args.type + '@' + args.url);
  const settings = getSettings();
  console.log('using settings', settings);

  const sources = makePlaySources(appInfo, args.url, args.key);
  console.log('player sources', sources);
  updateQualityButtons(appInfo, settings.sourceFile);

  const playerOptions = {
    // title: 'My title',
    autoStart: true,
    autoFallback: false,
    controls: false,
    mute: settings.mute ?? false,
    volume: settings.volume ?? 100,
    sources: sources,
  }

  createPlayer(playerOptions)
  setupEvents(globalPlayer);

  setStopAction(destroyPlayer);
}

setupPage();

setReloadAction(setupPage);
