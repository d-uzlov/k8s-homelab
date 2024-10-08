
import { getJSON, saveLocal } from './utils.js';
import { addStreamCard, setLoadingCard, addErrorCard } from './stream-cards.js';
import { getDataSources } from './data-sources.js';

let totalStreams = 0;
let urlsChecked = 0;

const dataSources = Object.entries(getDataSources());

function addStream(server, sourceName) {
  const thumbLink = '/empty-symbol.png';
  const apps = server.apps;
  if (apps == null || apps.length == 0) {
    return;
  }
  for (let i = 0; i < apps.length; i++) {
    const app = apps[i];
    if (app.keys.length == 0) {
      continue;
    }
    const url = server.url;
    const name = app.app.name;
    for (let j = 0; j < app.keys.length; j++) {
      const key = app.keys[j];
      const playerArgs = 'url=' + url + '&app=' + name + '&key=' + key + '&api=' + sourceName;

      const fullName = key + '@' + url + '/' + name;
      addStreamCard(thumbLink, fullName, [{
        name: 'Play',
        ref: './player.html#' + playerArgs,
      }], 'active-stream');
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

function handleResponse(err, data, url, sourceName) {
  urlsChecked++;
  if (err !== null) {
    if (data === null) {
      addErrorCard("can't connect to " + url, 'see console for details');
    } else {
      addErrorCard("error from " + url, data);
    }
    return;
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
    addErrorCard("error " + err + "from " + sUrl);
  }).finally(function(){
    checkEmpty();
  });
}
setTimeout(checkEmpty, 100);
