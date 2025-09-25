
function createButton(text, onclick, styleModify) {
  const button = document.createElement('button');
  let style = 'button-27';
  if (styleModify && styleModify.length > 0) {
    style += ' ' + styleModify;
  }
  button.classList = style;
  button.role = 'button';
  button.textContent = text;
  button.onclick = onclick;
  return button;
}

export let redBorder = 'red-border';
export let semiRedBorder = 'semi-red-border';

// values is { name, action }
// checkSelected is called with full value
export function setButtons(containerId, values, checkSelected) {
  const container = document.getElementById(containerId);
  container.textContent = '';

  for (const v of values) {
    const selected = checkSelected(v)
    const style = selected ? redBorder : '';
    const mute = createButton(v.name, v.action, style);
    container.appendChild(mute);
  }
}

const soundButtonsContainer = document.getElementById("volume-select-buttons");
export function setSoundButtons(playerInstance, currentVolume, currentMute, saveVolumeMute) {
  soundButtonsContainer.textContent = '';

  const muteStyle = currentMute ? redBorder : '';
  const mute = createButton('Mute', function () {
    playerInstance.setMute(true);
    saveVolumeMute(null, true);
  }, muteStyle);
  soundButtonsContainer.appendChild(mute);

  // in decibels
  const options = [-20, -15, -10, -5, 0];
  for (let i = 0; i < options.length; i++) {
    const element = options[i];
    let style = '';
    if (element == currentVolume) {
      style = currentMute ? semiRedBorder : redBorder;
    }
    const button = createButton(element, function () {
      playerInstance.setMute(false);
      console.log('element', element);
      const realVolume = Math.pow(10, element * 0.1);
      console.log('realVolume', realVolume);
      // player expected volume in 1-100 range
      playerInstance.setVolume(realVolume * 100);
      saveVolumeMute(element, false);
    }, style);
    soundButtonsContainer.appendChild(button);
  }
}

export const reloadButton = document.getElementById("reload-button");
export const stopButton = document.getElementById("stop-button");

export const controlsTopButton = document.getElementById("controls-top-button");
export const controlsBottomButton = document.getElementById("controls-bottom-button");
