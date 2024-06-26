
function parseHash() {
    const hash = window.location.hash.substr(1);
    const result = hash.split('&').reduce(function (res, item) {
        const parts = item.split('=');
        res[parts[0]] = parts[1];
        return res;
    }, {});
    return result;
}
const args = parseHash();
const signalDomain = getDomain();
let sourceList = [];
if (args.sources == null) {
    sourceList = getDefaultStreamKeys();
} else {
    sourceList = args.sources.split(',');
}
console.log('sourceList', sourceList)
let playlist = [];
for (const i in sourceList) {
    const source = sourceList[i];
    console.log('creating playlist for', source);
    playlist.push(
        {
            title: source + ' (latency <1s)',
            image: 'https://' + signalDomain + '/tc/' + source + '/thumb.jpg',
            sources: [
                {
                    label: 'low-latency',
                    type: 'webrtc',
                    // udp doesn't seem to work, there are very hard stutters
                    file: 'wss://' + signalDomain + '/tc/' + source + '/webrtc?transport=tcp',
                },
                // {
                //   label: 'low-latency bypass',
                //   type: 'webrtc',
                //   file: 'wss://' + signalDomain + '/tc/' + source + '/webrtc_bypass?transport=tcp',
                // },
            ],
        },
        {
            title: source + ' (latency ~3s)',
            image: 'https://' + signalDomain + '/tc/' + source + '/thumb.jpg',
            sources: [
                {
                    label: 'high-latency',
                    type: 'll-hls',
                    file: 'https://' + signalDomain + '/tc/' + source + '/llhls.m3u8',
                },
            ],
        },
    );
}

playlist.push({
    title: 'empty',
    image: '/empty-symbol.png',
    sources: [
        {
            label: 'empty',
            type: 'webrtc',
            file: 'wss://does-not-exist/',
        },
    ],
});

const settingsContainer = {};
function getSettings() {
    if (settingsContainer.settings == null) {
        settingsContainer.settings = JSON.parse(localStorage.getItem('settings')) || {};
    }
    return settingsContainer.settings;
}
function saveSettings(source, fun) {
    const settings = getSettings();
    fun(settings);
    console.log('saving settings', source, settings);
    localStorage.setItem('settings', JSON.stringify(settings));
}
const settings = getSettings();
console.log('using settings', settings);

const player = OvenPlayer.create('player_id', {
    // title: 'My title',
    autoStart: true,
    autoFallback: false,
    mute: settings.mute ?? true,
    volume: settings.volume ?? 100,
    playlist: playlist,
});

function restorePlaylist(playerInstance, title) {
    // console.log('restorePlaylist');
    if (title == null) {
        return;
    }
    const list = playerInstance.getPlaylist();
    for (const i in list) {
        const item = list[i];
        if (item.title === title) {
            if (playerInstance.getCurrentPlaylist() == i) {
                return
            }
            console.log('restorePlaylist: found item', item);
            playerInstance.setCurrentPlaylist(i);
            return;
        }
    }
}
function restoreSource(playerInstance, label) {
    // console.log('restoreSource', label);
    if (label == null) {
        return;
    }
    const list = playerInstance.getSources();
    console.log('restoreSource: list', list);
    for (const i in list) {
        const item = list[i];
        if (item.label === label) {
            console.log('restoreSource: found item', item);
            playerInstance.setCurrentSource(i);
            return;
        }
    }
}
function waitStateRestoreSource(playerInstance) {
    console.log('waitStateRestoreSource');
    const restoreOrWait = function (data) {
        if (playerInstance.getState() != 'playing') {
            playerInstance.once('stateChanged', restoreOrWait);
            return;
        }
        console.log('waitStateRestoreSource: got good state');
        const settings = getSettings();
        restoreSource(playerInstance, settings.sourceLabel);
    }
    restoreOrWait();
}
function restoreQualityHLS(playerInstance, height) {
    console.log('restoreQualityHLS', height);
    if (height == null) {
        return;
    }
    const list = playerInstance.getQualityLevels();
    console.log('restoreQualityHLS: list', list);
    for (const i in list) {
        const item = list[i];
        console.log('restoreQualityHLS: checking item', item.height, height, item);
        if (item.height === height) {
            console.log('restoreQualityHLS: found item', item);
            playerInstance.setCurrentQuality(i);
            return;
        }
    }
}
function restoreQualityWebRTC(playerInstance, label) {
    console.log('restoreQualityWebRTC', label);
    if (label == null) {
        return;
    }
    const list = playerInstance.getQualityLevels();
    console.log('restoreQualityWebRTC: list', list);
    for (const i in list) {
        const item = list[i];
        console.log('restoreQualityWebRTC: checking item', item.label, label, item);
        if (item.label === label) {
            console.log('restoreQuality: found item', item);
            playerInstance.setCurrentQuality(i);
            return;
        }
    }
}
function restoreQuality(playerInstance, quality) {
    // quality restore is buggy, and usually doesn't work
    // I'll leave this code here, maybe I will have motivation to improve it in the future
    if (playerInstance.isAutoQuality()) {
        console.log('restoreQuality: skip auto');
        return;
    }
    const currentSourceItem = player.getSources()[player.getCurrentSource()];
    if (currentSourceItem == null) {
        return;
    }
    console.log('currentSourceItem', currentSourceItem);
    switch (currentSourceItem.type) {
        case 'hls':
        case 'll-hls':
        case 'dash':
            restoreQualityHLS(playerInstance, quality);
            break;
        case 'webrtc':
            restoreQualityWebRTC(playerInstance, quality);
            break;
    }
}
player.on('ready', function (data) {
    console.log('player ready');
    const settings = getSettings();
    restorePlaylist(player, settings.playlistTitle);
    waitStateRestoreSource(player);
    // restoreQuality(player, settings.qualityLabel, settings.qualityHeight);
});
player.on('stateChanged', function (data) {
    console.log('stateChanged', data);
});

player.on('volumeChanged', function (data) {
    saveSettings('volumeChanged', function (settings) {
        settings.volume = player.getVolume();
        settings.mute = player.getMute();
    });
});
player.on('playlistChanged', function (data) {
    console.log('playlistChanged');
    waitStateRestoreSource(player);
    saveSettings('playlistChanged', function (settings) {
        const currentPlaylistItem = player.getPlaylist()[player.getCurrentPlaylist()];
        if (currentPlaylistItem == null) {
            return;
        }
        // console.log('currentPlaylistItem', currentPlaylistItem);
        settings.playlistTitle = currentPlaylistItem.title;
    });
});
player.on('sourceChanged', function (data) {
    console.log('sourceChanged');
    // const handleSourceStartup = function (data) {
    //   if (player.getState() != 'playing') {
    //     console.log('handleSourceStartup: schedule next');
    //     player.once('stateChanged', handleSourceStartup);
    //     return
    //   }
    //   const settings = getSettings();
    //   console.log('handleSourceStartup: got good state');
    //   restoreQuality(player, settings.quality);
    // }
    // handleSourceStartup();
    saveSettings('sourceChanged', function (settings) {
        const currentSourceItem = player.getSources()[player.getCurrentSource()];
        if (currentSourceItem == null) {
            return;
        }
        // console.log('currentSourceItem', currentSourceItem);
        settings.sourceLabel = currentSourceItem.label;
    });
});
// player.on('qualityLevelChanged', function (data) {
//   // player.play()
//   saveSettings('qualityLevelChanged', function (settings) {
//     if (player.isAutoQuality()) {
//       return;
//     }
//     const currentQualityItem = player.getQualityLevels()[player.getCurrentQuality()];
//     if (currentQualityItem == null) {
//       return;
//     }
//     console.log('quality', currentQualityItem);
//     if (currentQualityItem.height != null) {
//       settings.quality = String(currentQualityItem.height);
//     } else {
//       settings.quality = currentQualityItem.label;
//     }
//   });
// });
