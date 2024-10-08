
export function parseHash() {
  const hash = window.location.hash.substring(1);
  const result = hash.split('&').reduce(function (res, item) {
    const parts = item.split('=');
    res[parts[0]] = parts[1];
    return res;
  }, {});
  return result;
}

let defaultSettingsName = '';
export function setDefaultSettingsName(name) {
  defaultSettingsName = name;
}

export function getSettings(name) {
  const settingsName = name ?? defaultSettingsName;
  return JSON.parse(localStorage.getItem(settingsName)) || {};
}

export function saveSettings(source, fun, name) {
  const settingsName = name ?? defaultSettingsName;
  const settings = getSettings(settingsName);
  fun(settings);
  console.log('saving settings', source, settings);
  localStorage.setItem(settingsName, JSON.stringify(settings));
}

export function saveLocal(name, value) {
  localStorage.setItem(name, JSON.stringify(value));
}
export function readLocal(name) {
  return JSON.parse(localStorage.getItem(name));
}

export async function getJSON(url) {
  return new Promise(function (resolve, reject) {
    let xhr = new XMLHttpRequest();
    xhr.responseType = 'json';
    xhr.timeout = 1000;
    xhr.open('GET', url);
    xhr.onload = function () {
      if (this.status >= 200 && this.status < 300) {
        resolve(xhr.response);
      } else {
        console.log('xhr error 2', xhr.response)
        reject({
          status: this.status,
          statusText: xhr.statusText
        });
      }
    };
    xhr.onerror = function () {
      console.log('xhr error', xhr.response)
      reject({
        status: this.status,
        statusText: xhr.statusText
      });
    };
    xhr.send();
  });
}
// export async function getJSON(url, callback) {
//   var xhr = new XMLHttpRequest();
//   xhr.open('GET', url, true);
//   xhr.responseType = 'json';
//   xhr.timeout = 1000;
//   xhr.onload = function () {
//     var status = xhr.status;
//     if (status === 200) {
//       callback(null, xhr.response);
//     } else {
//       callback(status, xhr.response);
//     }
//   };
//   xhr.onerror = function (event) {
//     console.log(event);
//     callback(event, null);
//   }
//   try {
//     xhr.send();
//   } catch (error) {
//     console.log(error);
//     callback('xhr exception: ' + error, null);
//   }
// };
