
const qualityButtonsContainer = document.getElementById("quality-select-buttons");

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

export function setQualityButtons(playerInstance, saveSettings) {
  qualityButtonsContainer.textContent = '';

  const qualityList = playerInstance.getQualityLevels();
  const currentQuality = playerInstance.getCurrentQuality();
  for (let i = 0; i < qualityList.length; i++) {
    const element = qualityList[i];
    const button = createButton(element.label, function () {
      playerInstance.setCurrentQuality(i);
      saveSettings();
    }, i == currentQuality);
    qualityButtonsContainer.appendChild(button);
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
