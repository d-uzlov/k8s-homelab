
import { setQualityButtons, setSoundButtons, setReloadAction, setStopAction } from './player-buttons.js';
import { restoreQuality } from './player-quality.js';
import { parseHash, setDefaultSettingsName, getSettings, saveSettings } from './utils.js';

function updateVolumeButtons(playerInstance) {
  setSoundButtons(playerInstance, playerInstance.getVolume(), playerInstance.getMute(), function () {
    saveSettings('volume', function (settings) {
      settings.volume = playerInstance.getVolume();
      settings.mute = playerInstance.getMute();
    });
  });
}

function setupEvents(playerInstance, settings) {
  playerInstance.on('ready', function (data) {
    console.log('player ready');
    playerInstance.setAutoQuality(false);
    updateVolumeButtons(playerInstance);
  });

  playerInstance.on('stateChanged', function (data) {
    console.log('stateChanged', data);
    console.log('quality levels', playerInstance.getQualityLevels());
    if (data.newstate == 'loading' || data.newstate == 'playing') {
      restoreQuality(playerInstance, settings.qualityLabel, settings.qualityHeight);
    }
  });

  playerInstance.on('volumeChanged', function (data) {
    console.log('volumeChanged', data);
    updateVolumeButtons(playerInstance);
  });
  playerInstance.on('qualityLevelChanged', function (data) {
    console.log('qualityLevelChanged', data);
    setQualityButtons(playerInstance, function () {
      const ql = playerInstance.getQualityLevels();
      const quality = ql[playerInstance.getCurrentQuality()];
      saveSettings('quality', function (settings) {
        settings.qualityHeight = String(quality.height);
        settings.qualityLabel = quality.label;
      });
    });
  });
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
  globalPlayer = OvenPlayer.create('player_id', playerOptions);
}

function setupPage() {
  const args = parseHash();
  if (args.type === undefined || args.url === undefined) {
    console.log('args missing');
    return;
  }
  console.log('type', args.type);
  console.log('url', args.url);

  let url = '';
  let urlType = '';
  switch (args.type) {
    case 'ome-webrtc':
      url = 'wss://' + args.url + '?transport=tcp';
      urlType = 'webrtc';
      break;
    case 'ome-llhls':
      url = 'https://' + args.url;
      urlType = 'll-hls';
      break;
    default:
      console.log('unknow stream type');
      return;
  }

  setDefaultSettingsName('settings@' + args.type + '@' + args.url);
  const settings = getSettings();
  console.log('using settings', settings);

  const playerOptions = {
    // title: 'My title',
    autoStart: true,
    autoFallback: false,
    controls: false,
    mute: settings.mute ?? false,
    volume: settings.volume ?? 100,
    sources: [{
      file: url,
      type: urlType,
    }],
  }

  createPlayer(playerOptions)
  setupEvents(globalPlayer, settings);

  setReloadAction(function () {
    createPlayer(playerOptions);
  });

  setStopAction(destroyPlayer);
}

setupPage();

