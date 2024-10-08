
const streamList = document.getElementById("stream-list");

export function addStreamCard(thumbnailLink, link, streamHeader, streamDescription, cardType) {
  const thumbImage = document.createElement('img');
  thumbImage.src = thumbnailLink;
  const thumbContainer = document.createElement('a');
  thumbContainer.classList = 'thumbnail-container';
  thumbContainer.appendChild(thumbImage);
  thumbContainer.href = link;

  const headerContainer = document.createElement('div');
  headerContainer.setAttribute('class', 'list-description');
  const header = document.createElement('div');
  headerContainer.appendChild(header);
  const headerLink = document.createElement('a');
  header.appendChild(headerLink);
  headerLink.href = link;
  headerLink.textContent = streamHeader;

  const descriptionContainer = document.createElement('div');
  descriptionContainer.classList = 'list-description';
  descriptionContainer.textContent = streamDescription;

  const rightContainer = document.createElement('div');
  rightContainer.classList = 'list-right';
  rightContainer.appendChild(headerContainer);
  rightContainer.appendChild(descriptionContainer);

  const element = document.createElement('li');
  element.classList = cardType;
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
    loadingInner.classList = 'list-description';
  }

  if (loadingOuter == null) {
    loadingOuter = document.createElement('li');
    loadingOuter.classList = 'empty-stream';
    loadingOuter.appendChild(loadingInner);
    streamList.appendChild(loadingOuter);
  }

  loadingInner.textContent = content;
  if (content != null && content.length > 0) {
    loadingOuter.style.display = null;
  } else {
    loadingOuter.style.display = 'none';
  }

  return loadingOuter;
}

export function addErrorCard(content, errorText) {
  const descriptionContainer = document.createElement('div');
  descriptionContainer.classList = 'list-description';
  descriptionContainer.textContent = content;

  const textContainer = document.createElement('div');
  textContainer.classList = 'list-description';
  textContainer.textContent = errorText;

  const element = document.createElement('li');
  element.classList = 'error-stream';
  element.appendChild(descriptionContainer);
  element.appendChild(textContainer);
  streamList.appendChild(element);
  return element;
}
