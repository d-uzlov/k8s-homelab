
const streamList = document.getElementById("stream-list");

export function addStreamCard(thumbnailLink, streamName, links, cardType) {
  const thumbImage = document.createElement('img');
  thumbImage.setAttribute('src', thumbnailLink);
  const thumbContainer = document.createElement('div');
  thumbContainer.setAttribute('class', 'thumbnail-container');
  thumbContainer.appendChild(thumbImage);

  const header = document.createElement('h3');

  for (let i = 0; i < links.length; i++) {
    const link = links[i];

    const linkContainer = document.createElement('h3');
    linkContainer.setAttribute('class', 'list-link button-27');

    const linkElement = document.createElement('a');
    linkElement.setAttribute('href', link.ref);
    linkElement.text = link.name;
    linkContainer.appendChild(linkElement);

    header.appendChild(linkContainer);
  }

  const descriptionContainer = document.createElement('div');
  descriptionContainer.setAttribute('class', 'list-description');
  descriptionContainer.textContent = streamName;

  const rightContainer = document.createElement('div');
  rightContainer.setAttribute('class', 'list-right');
  rightContainer.appendChild(descriptionContainer);
  rightContainer.appendChild(header);

  const element = document.createElement('li');
  element.setAttribute('class', cardType);
  element.appendChild(thumbContainer);
  element.appendChild(rightContainer);
  streamList.appendChild(element);
  return element;
}

let loadingInner = null;
let loadingOuter = null;
export function setLoadingCard(content) {
  if (loadingInner == null) {
    loadingInner = document.createElement('div');
    loadingInner.setAttribute('class', 'list-description');
  }

  if (loadingOuter == null) {
    loadingOuter = document.createElement('li');
    loadingOuter.setAttribute('class', 'empty-stream');
    loadingOuter.appendChild(loadingInner);
    streamList.appendChild(loadingOuter);
  }

  loadingInner.textContent = content;
  if (content.length > 0) {
    loadingOuter.style.display = null;
  } else {
    loadingOuter.style.display = 'none';
  }

  return loadingOuter;
}

export function addErrorCard(content, errorText) {
  const descriptionContainer = document.createElement('div');
  descriptionContainer.setAttribute('class', 'list-description');
  descriptionContainer.textContent = content;

  const textContainer = document.createElement('div');
  textContainer.setAttribute('class', 'list-description');
  textContainer.textContent = errorText;

  const element = document.createElement('li');
  element.setAttribute('class', 'error-stream');
  element.appendChild(descriptionContainer);
  element.appendChild(textContainer);
  streamList.appendChild(element);
  return element;
}
