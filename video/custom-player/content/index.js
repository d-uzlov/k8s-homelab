
import { getJSON, saveLocal } from './utils.js';
import { addStreamCard, setLoadingCard, addErrorCard } from './stream-cards.js';
import { getDataSources } from './data-sources.js';

let totalStreams = 0;
let urlsChecked = 0;

const dataSources = Object.entries(getDataSources());

function addStream(server, sourceName) {
  const apps = server.apps;
  if (apps == null || apps.length == 0) {
    return;
  }
  for (let i = 0; i < apps.length; i++) {
    const keys = apps[i].keys;
    const app = apps[i].app;
    if (keys.length == 0) {
      continue;
    }
    const url = server.url;
    const name = app.name;

    let description = url + '/' + name;
    if (app.readName != null && app.readName != "") {
      description = app.readName;
    }

    for (let j = 0; j < keys.length; j++) {
      const key = keys[j];
      const playerArgs = 'url=' + url + '&app=' + name + '&key=' + key + '&api=' + sourceName;

      let thumbLink = '/no-thumbnail.png';
      if (app.image) {
        thumbLink = 'https://' + url + '/tc/' + key + '/thumb.jpg';
      }

      const link = './player.html#' + playerArgs;
      const header = key + ' streaming';
      addStreamCard(thumbLink, link, header, description, 'active-stream');
    }
  }

  totalStreams++;
}

function checkEmpty() {
  if (urlsChecked >= dataSources.length && totalStreams == 0) {
    setLoadingCard('no streams found');
  } else if (urlsChecked < dataSources.length) {
    setLoadingCard('still fetching more streams from ' + (dataSources.length - urlsChecked) + ' source(s)...');
  } else {
    setLoadingCard('');
  }
}

for (let i = 0; i < dataSources.length; i++) {
  const source = dataSources[i];
  const sName = source[0];
  const sUrl = source[1];
  getJSON(sUrl + '/list').then(function (data) {
    for (let i = 0; i < data.length; i++) {
      addStream(data[i], sName);
    }
    urlsChecked++;
  }).catch(function (err) {
    urlsChecked++;
    addErrorCard("error " + JSON.stringify(err) + " from " + sUrl);
  }).finally(function () {
    checkEmpty();
  });
}
setTimeout(checkEmpty, 100);
