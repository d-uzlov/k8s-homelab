
function createButton(text, onclick, redBorder) {
  const button = document.createElement('button');
  let style = 'button-27';
  if (redBorder) {
    style += ' red-border';
  }
  button.setAttribute('class', style);
  button.setAttribute('role', 'button');
  button.textContent = text;
  button.onclick = onclick;
  return button;
}

// values is { name, action }
// checkSelected is called with full value
export function setButtons(containerId, values, checkSelected) {
  const container = document.getElementById(containerId);
  container.textContent = '';

  for (const v of values) {
    const mute = createButton(v.name, v.action, checkSelected(v));
    container.appendChild(mute);
  }
}

const soundButtonsContainer = document.getElementById("volume-select-buttons");
export function setSoundButtons(playerInstance, currentVolume, currentMute, saveSettings) {
  soundButtonsContainer.textContent = '';
  console.log('current volume', currentVolume)

  const mute = createButton('Mute', function () {
    playerInstance.setMute(true);
    saveSettings();
  }, currentMute);
  console.log('currentMute', currentMute);
  soundButtonsContainer.appendChild(mute);

  const options = [1, 5, 15, 50, 100];
  for (let i = 0; i < options.length; i++) {
    const element = options[i];
    const button = createButton(element, function () {
      playerInstance.setMute(false);
      playerInstance.setVolume(element);
      saveSettings();
    }, element == currentVolume);
    soundButtonsContainer.appendChild(button);
  }
}

const reloadButton = document.getElementById("reload-button");
const stopButton = document.getElementById("stop-button");
export function setReloadAction(action) {
  reloadButton.onclick = action;
}
export function setStopAction(action) {
  stopButton.onclick = action;
}
