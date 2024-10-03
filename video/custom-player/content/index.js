
import { getJSON } from './utils.js';
import { addStreamCard, setLoadingCard, addErrorCard } from './stream-cards.js';
import { getDataSources } from './data-sources.js';

let totalStreams = 0;
let urlsChecked = 0;

const urls = getDataSources();

function addStream(stream) {
  const thumbLink = '/empty-symbol.png';
  const urlArg = 'url=' + stream.url + '/' + stream.app + '/' + stream.key;

  const links = [];
  links.push({ name: 'Low latency', ref: './player.html#type=ome-webrtc&' + urlArg });
  links.push({ name: 'HLS', ref: './player.html#type=ome-llhls&' + urlArg });
  const fullName = stream.key + '@' + stream.url;
  addStreamCard(thumbLink, fullName, links, 'active-stream');
  totalStreams++;
}

function checkEmpty() {
  if (urlsChecked >= urls.length && totalStreams == 0) {
    setLoadingCard('no streams found');
  } else if (urlsChecked < urls.length) {
    setLoadingCard('still fetching more streams...');
  } else {
    setLoadingCard('');
  }
}

function handleResponse(err, data, url) {
  urlsChecked++;
  if (err !== null) {
    if (data === null) {
      addErrorCard("can't connect to " + url, 'see console for details');
    } else {
      addErrorCard("error from " + url, data);
    }
    return;
  }
  for (let i = 0; i < data.length; i++) {
    addStream(data[i]);
  }
}

for (let i = 0; i < urls.length; i++) {
  const url = urls[i];
  getJSON(url, function (err, data) {
    handleResponse(err, data, url);
    checkEmpty();
  });
}
setTimeout(checkEmpty, 100);
