let DEBUG = false;
loaded = false;
metadata = {};
subs = {};
audios = {};
settings = { disableNotifications: false, seekSeconds: 10 };

function setCookie(cookie) {
  document.cookie = cookie + '; expires = Thu, 23 May 2200 20:00:00 UTC";';
}

function loadCookies() {
  document.cookie.split("; ").forEach((cookie) => {
    if (cookie === "") {
      return;
    }
    let [key, value] = cookie.split("=");
    if (key === "disableNotifications") {
      value = value === "true";
    } else if (key === "seekSeconds") {
      value = parseInt(value);
    }
    settings[key] = value;
  });
}

window.onload = function () {
  loadCookies();
  document.getElementById("disableNotifications").checked =
    settings.disableNotifications;
  document.getElementById("seekSeconds").value = settings.seekSeconds;
};

function useNotifications() {
  return "mediaSession" in navigator && !settings.disableNotifications;
}

function send(command, ...args) {
  DEBUG && console.log(`Sending command: ${command} params: ${args}`);
  if (useNotifications()) {
    audioLoad();
  }
  const path = ["api", command, ...args].join("/");

  const request = new XMLHttpRequest();
  request.open("post", path);

  request.send(null);
  // Kick off a refresh quickly in response to user input.
  refreshStatus(100);
}

function toggleOverlay(id) {
  document.body.classList.toggle("noscroll");
  const el = document.getElementById(id);
  el.style.visibility =
    el.style.visibility === "visible" ? "hidden" : "visible";
}

function hideOverlay(id) {
  const el = document.getElementById(id);
  if (el.style.visibility === "visible") toggleOverlay(id);
}

function hideOverlays() {
  hideOverlay("playlist-overlay");
  hideOverlay("shortcuts-overlay");
  hideOverlay("settings-overlay");
  hideOverlay("uri-loader-overlay");
}

function createPlaylistTable(entry, position, pause, first) {
  function setActive(set) {
    if (set === true) {
      td_left.classList.add("active");
      td_2.classList.add("active");
    } else {
      td_left.classList.remove("active");
      td_2.classList.remove("active");
    }
  }

  function blink() {
    td_left.classList.add("click");
    td_2.classList.add("click");
    setTimeout(function () {
      td_left.classList.remove("click");
      td_2.classList.remove("click");
    }, 100);
  }

  let title;
  if (entry.title) {
    title = entry.title;
  } else {
    const filename_array = entry.filename.split("/");
    title = filename_array[filename_array.length - 1];
  }

  const table = document.createElement("table");
  const tr = document.createElement("tr");
  const td_left = document.createElement("td");
  const td_2 = document.createElement("td");
  const td_3 = document.createElement("td");
  const td_right = document.createElement("td");
  table.className = "playlist";
  tr.className = "playlist";
  td_2.className = "playlist";
  td_left.className = "playlist";
  td_right.className = "playlist";
  td_2.innerText = title;
  if (first === false) {
    td_3.innerHTML = '<i class="fas fa-arrow-up"></i>';
    td_3.className = "playlist";
  }
  td_right.innerHTML = '<i class="fas fa-trash"></i>';

  if (entry.hasOwnProperty("playing")) {
    if (pause) {
      td_left.innerHTML = '<i class="fas fa-pause"></i>';
    } else {
      td_left.innerHTML = '<i class="fas fa-play"></i>';
    }

    td_left.classList.add("playing");
    td_left.classList.add("violet");
    td_2.classList.add("playing");
    td_2.classList.add("violet");
    first || td_3.classList.add("violet");
    td_right.classList.add("violet");
  } else {
    td_left.classList.add("gray");
    td_2.classList.add("gray");
    first || td_3.classList.add("gray");
    td_right.classList.add("gray");

    td_left.onclick = td_2.onclick = (function (arg) {
      return function () {
        send("playlist_jump", arg);
        return false;
      };
    })(position);

    td_left.addEventListener("mouseover", function () {
      setActive(true);
    });
    td_left.addEventListener("mouseout", function () {
      setActive(false);
    });
    td_2.addEventListener("mouseover", function () {
      setActive(true);
    });
    td_2.addEventListener("mouseout", function () {
      setActive(false);
    });

    td_left.addEventListener("click", blink);
    td_2.addEventListener("click", blink);
  }

  if (first === false) {
    td_3.onclick = (function (arg) {
      return function () {
        send("playlist_move_up", arg);
        return false;
      };
    })(position);
  }

  td_right.onclick = (function (arg) {
    return function () {
      send("playlist_remove", arg);
      return false;
    };
  })(position);

  tr.appendChild(td_left);
  tr.appendChild(td_2);
  first || tr.appendChild(td_3);
  tr.appendChild(td_right);
  table.appendChild(tr);
  return table;
}

function populatePlaylist(json, pause) {
  const playlist = document.getElementById("playlist");
  playlist.innerHTML = "";

  let first = true;
  for (let i = 0; i < json.length; ++i) {
    playlist.appendChild(createPlaylistTable(json[i], i, pause, first));
    if (first === true) {
      first = false;
    }
  }
}

function uriLoader(mode) {
  uri = document.getElementById("uri-loader-input").value;
  if (uri) {
    send("loadfile", encodeURIComponent(uri), mode);
    document.getElementById("uri-loader-input").value = "";
  }
}

const keyboardBindings = [
  {
    help: "hide current overlay",
    key: "Escape",
    code: 27,
    command: hideOverlays,
  },
  {
    help: "toggle keyboard shortcuts overlay",
    key: "?",
    code: 191,
    command: () => toggleOverlay("shortcuts-overlay"),
  },
  {
    help: "Play/Pause",
    helpKey: "Space",
    key: " ",
    code: 32,
    command: () => send("toggle_pause"),
  },
  {
    help: "seek +10",
    key: "ArrowRight",
    code: 39,
    command: () => send("seek", "10"),
  },
  {
    help: "seek -10",
    key: "ArrowLeft",
    code: 37,
    command: () => send("seek", "-10"),
  },
  {
    help: "seek +1min",
    key: "ArrowUp",
    code: 38,
    command: () => send("seek", "60"),
  },
  {
    help: "seek -1min",
    key: "ArrowDown",
    code: 40,
    command: () => send("seek", "-60"),
  },
  {
    help: "seek +3",
    key: "PageDown",
    code: 34,
    command: () => send("seek", "3"),
  },
  {
    help: "seek -3",
    key: "PageUp",
    code: 33,
    command: () => send("seek", "-3"),
  },
  {
    help: "decrease volume",
    key: "9",
    code: 57,
    command: () => send("add_volume", "-2"),
  },
  {
    help: "increase volume",
    key: "0",
    code: 48,
    command: () => send("add_volume", "2"),
  },
  {
    help: "toggle fullscreen",
    key: "f",
    code: 70,
    command: () => send("fullscreen"),
  },
  {
    help: "cycle through subtitles",
    key: "j",
    code: 74,
    command: () => send("cycle_sub"),
  },
  {
    help: "toggle subtitle visibility",
    key: "v",
    code: 86,
    command: () => send("toggle", "sub-visibility"),
  },
  {
    help: "playlist next",
    key: "n",
    code: 78,
    command: () => send("playlist_next"),
  },
  {
    help: "playlist previous",
    key: "p",
    code: 80,
    command: () => send("playlist_prev"),
  },
  // These {} must come before [] as they have the same "code".
  {
    help: "decrease playback speed more",
    key: "{",
    command: () => send("speed_adjust", "0.5"),
  },
  {
    help: "increase playback speed more",
    key: "}",
    command: () => send("speed_adjust", "2.0"),
  },
  {
    help: "decrease playback speed",
    key: "[",
    code: 219,
    // This funky value matches mpv defaults.
    command: () => send("speed_adjust", "0.9091"),
  },
  {
    help: "increase playback speed",
    key: "]",
    code: 221,
    command: () => send("speed_adjust", "1.1"),
  },
  {
    help: "reset playback speed",
    key: "Backspace",
    code: 8,
    command: () => send("speed_set"),
  },
];

window.onkeydown = function (e) {
  // We have no shortcuts below that use these combos, so don't capture them.
  // We allow Shift key as some keyboards require that to trigger the keys.
  // For example, a US QWERTY uses Shift+/ to get ?.
  // Additionally, we want to ignore any keystrokes if an input element is focussed.
  if (
    e.altKey ||
    e.ctrlKey ||
    e.metaKey ||
    document.activeElement.tagName.toLowerCase() === "input"
  ) {
    return;
  }

  for (let i = 0; i < keyboardBindings.length; i++) {
    const binding = keyboardBindings[i];
    if (e.keyCode === binding.code || e.key === binding.key) {
      binding.command();
      return false;
    }
  }
};

function updateShortcutsHelp() {
  const table = document.getElementById("shortcuts-table");
  keyboardBindings.forEach((binding) => {
    const row = table.insertRow(-1);
    row.insertCell(-1).innerText = binding.helpKey || binding.key;
    row.insertCell(-1).innerText = binding.help;
  });
}
updateShortcutsHelp();

function format_time(seconds) {
  const date = new Date(null);
  date.setSeconds(seconds);
  return date.toISOString().substr(11, 8);
}

function setFullscreenButton(fullscreen) {
  let fullscreenText = "Fullscreen on";
  if (fullscreen) {
    fullscreenText = "Fullscreen off";
  }
  document.getElementById("fullscreenButton").innerText = fullscreenText;
}

function setTrackList(tracklist) {
  window.audios.selected = 0;
  window.audios.count = 0;
  window.subs.selected = 0;
  window.subs.count = 0;
  for (let i = 0; i < tracklist.length; i++) {
    if (tracklist[i].type === "audio") {
      window.audios.count++;
      if (tracklist[i].selected) {
        window.audios.selected = tracklist[i].id;
      }
    } else if (tracklist[i].type === "sub") {
      window.subs.count++;
      if (tracklist[i].selected) {
        window.subs.selected = tracklist[i].id;
      }
    }
  }
  document.getElementById("nextSub").innerText =
    "Next sub " + window.subs.selected + "/" + window.subs.count;
  document.getElementById("nextAudio").innerText =
    "Next audio " + window.audios.selected + "/" + window.audios.count;
}

function sanitize(string) {
  // https://stackoverflow.com/a/48226843
  const map = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#x27;",
    "/": "&#x2F;",
    "`": "&grave;",
  };
  const reg = /[&<>"'/`]/gi;
  return string.replace(reg, (match) => map[match]);
}

function setMetadata(metadata, playlist, filename) {
  // try to gather the track number
  let track = "";
  if (metadata["track"]) {
    track = metadata["track"] + " - ";
  }

  // try to gather the playing playlist element
  let pl_title;
  for (let i = 0; i < playlist.length; i++) {
    if (playlist[i].hasOwnProperty("playing")) {
      pl_title = playlist[i].title;
    }
  }
  // set the title. Try values in this order:
  // 1. title set in playlist
  // 2. metadata['title']
  // 3. metadata['TITLE']
  // 4. filename
  if (pl_title) {
    window.metadata.title = sanitize(track + pl_title);
  } else if (metadata["title"]) {
    window.metadata.title = track + sanitize(metadata["title"]);
  } else if (metadata["TITLE"]) {
    window.metadata.title = track + sanitize(metadata["TITLE"]);
  } else {
    window.metadata.title = track + sanitize(filename);
  }

  // set the artist
  if (metadata["artist"]) {
    window.metadata.artist = sanitize(metadata["artist"]);
  } else {
    window.metadata.artist = "";
  }

  // set the album
  if (metadata["album"]) {
    window.metadata.album = sanitize(metadata["album"]);
  } else {
    window.metadata.album = "";
  }

  document.getElementById("title").innerHTML = window.metadata.title;
  document.getElementById("artist").innerHTML = window.metadata.artist;
  document.getElementById("album").innerHTML = window.metadata.album;
}

function touchRangeOffset(e) {
  if (!e.layerX) {
    document
      .getElementById("mediaPosition")
      .removeEventListener("touchstart", handleMediaPositionStart, false);
    document
      .getElementById("mediaPosition")
      .removeEventListener("touchmove", handleMediaPositionMove, false);
    document
      .getElementById("mediaPosition")
      .removeEventListener("touchend", handleMediaPositionEnd, false);
    document
      .getElementById("mediaVolume")
      .removeEventListener("touchstart", handleVolumeStart, false);
    document
      .getElementById("mediaVolume")
      .removeEventListener("touchmove", handleVolumeMove, false);
    document
      .getElementById("mediaVolume")
      .removeEventListener("touchend", handleVolumeEnd, false);
    return false;
  }
  e.preventDefault();
  const slider = e.target;
  return slider.max * (e.layerX / slider.scrollWidth);
}

function setPosSlider(position, duration) {
  const slider = document.getElementById("mediaPosition");
  const pos = document.getElementById("position");
  slider.max = duration;
  slider.value = position;
  pos.innerHTML = format_time(slider.value);
}

function handleMediaPositionStart(e) {
  const offset = touchRangeOffset(e);
  setPosSlider(offset, document.getElementById("mediaPosition").max);
}

function handleMediaPositionMove(e) {
  const offset = touchRangeOffset(e);
  setPosSlider(offset, document.getElementById("mediaPosition").max);
}

function handleMediaPositionEnd(e) {
  const offset = touchRangeOffset(e);
  setPosSlider(offset, document.getElementById("mediaPosition").max);
  send("set_position", offset);
}

document
  .getElementById("mediaPosition")
  .addEventListener("touchstart", handleMediaPositionStart, false);
document
  .getElementById("mediaPosition")
  .addEventListener("touchmove", handleMediaPositionMove, false);
document
  .getElementById("mediaPosition")
  .addEventListener("touchend", handleMediaPositionEnd, false);

document.getElementById("mediaPosition").onchange = function () {
  const slider = document.getElementById("mediaPosition");
  send("set_position", slider.value);
};

document.getElementById("mediaPosition").onmousemove = function (e) {
  const slider = e.target;
  const offset = slider.max * (e.offsetX / slider.clientWidth);
  slider.title = format_time(offset);
};

document.getElementById("mediaPosition").oninput = function () {
  const slider = document.getElementById("mediaPosition");
  const pos = document.getElementById("position");
  pos.innerHTML = format_time(slider.value);
};

function setVolumeSlider(volume, volumeMax) {
  const slider = document.getElementById("mediaVolume");
  const vol = document.getElementById("volume");
  slider.value = volume;
  slider.max = volumeMax;
  vol.innerHTML = slider.value + "%";
}

function handleVolumeStart(e) {
  const offset = touchRangeOffset(e);
  setVolumeSlider(offset, document.getElementById("mediaVolume").max);
}

function handleVolumeMove(e) {
  const offset = touchRangeOffset(e);
  setVolumeSlider(offset, document.getElementById("mediaVolume").max);
}

function handleVolumeEnd(e) {
  const offset = touchRangeOffset(e);
  setVolumeSlider(offset, document.getElementById("mediaVolume").max);
  send("set_volume", offset);
}

document
  .getElementById("mediaVolume")
  .addEventListener("touchstart", handleVolumeStart, false);
document
  .getElementById("mediaVolume")
  .addEventListener("touchmove", handleVolumeMove, false);
document
  .getElementById("mediaVolume")
  .addEventListener("touchend", handleVolumeEnd, false);

document.getElementById("mediaVolume").onchange = function () {
  const slider = document.getElementById("mediaVolume");
  send("set_volume", slider.value);
};

document.getElementById("mediaVolume").onmousemove = function (e) {
  const slider = e.target;
  const offset = slider.max * (e.offsetX / slider.clientWidth);
  slider.title = `${offset.toFixed(1)}%`;
};

document.getElementById("mediaVolume").oninput = function () {
  const slider = document.getElementById("mediaVolume");
  const vol = document.getElementById("volume");
  vol.innerHTML = slider.value + "%";
};

function setPlayPause(value) {
  const playPause = document.getElementsByClassName("playPauseButton");

  if (useNotifications()) {
    navigator.mediaSession.playbackState = value ? "paused" : "playing";
  }

  // const playPause = document.getElementById("playPause");
  if (value) {
    [].slice.call(playPause).forEach(function (div) {
      div.innerHTML = '<i class="fas fa-play"></i>';
    });
    if (useNotifications()) {
      audioPause();
    }
  } else {
    [].slice.call(playPause).forEach(function (div) {
      div.innerHTML = '<i class="fas fa-pause"></i>';
    });
    if (useNotifications()) {
      audioPlay();
    }
  }
}

function setChapter(chapters, chapter, chapterList) {
  const chapterElements = document.getElementsByClassName("chapter");
  const chapterContent = document.getElementById("chapterContent");
  if (chapters === 0) {
    [].slice.call(chapterElements).forEach(function (div) {
      div.classList.add("hidden");
    });
    chapterContent.innerText = "0/0";
  } else {
    [].slice.call(chapterElements).forEach(function (div) {
      div.classList.remove("hidden");
    });
    chapterContent.innerText = chapter + 1 + "/" + chapters;
    if (chapterList && chapterList[chapter])
      chapterContent.innerText += ` (${chapterList[chapter].title})`;
  }

  const datalist = document.getElementById("chapters");
  while (datalist.lastElementChild) datalist.lastElementChild.remove();
  if (chapterList) {
    chapterList.forEach((info) => {
      datalist.appendChild(new Option(info.title, info.time));
    });
  }
}

function setOrHideStartEnd(elementsClass, contentId, value) {
  const elements = document.getElementsByClassName(elementsClass);
  const content = document.getElementById(contentId);
  if (value == null) {
    [].slice.call(elements).forEach(function (div) {
      div.classList.add("hidden");
    });
  } else {
    [].slice.call(elements).forEach(function (div) {
      div.classList.remove("hidden");
    });
    content.innerText = format_time(value);
  }
}

function setStartEnd(start, end) {
  setOrHideStartEnd("start", "startContent", start);
  setOrHideStartEnd("end", "endContent", end);
}

function playlist_loop_cycle() {
  const loopButton = document.getElementsByClassName("playlistLoopButton");
  if (loopButton.value === "no") {
    send("loop_file", "inf");
    send("loop_playlist", "no");
  } else if (loopButton.value === "1") {
    send("loop_file", "no");
    send("loop_playlist", "inf");
  } else if (loopButton.value === "a") {
    send("loop_file", "no");
    send("loop_playlist", "no");
  }
}

function setLoop(loopFile, loopPlaylist) {
  const loopButton = document.getElementsByClassName("playlistLoopButton");
  let html, value;
  if (loopFile === false) {
    if (loopPlaylist === false) {
      html = '!<i class="fas fa-redo-alt"></i>';
      value = "no";
    } else {
      html = '<i class="fas fa-redo-alt"></i>Σ';
      value = "a";
    }
  } else {
    html = '<i class="fas fa-redo-alt"></i>1';
    value = "1";
  }

  [].slice.call(loopButton).forEach(function (div) {
    div.innerHTML = html;
  });

  loopButton.value = value;
}

function seek(multiplier) {
  send("seek", settings.seekSeconds * multiplier);
}

function handleStatusResponse(json) {
  setMetadata(json["metadata"], json["playlist"], json["filename"]);
  setTrackList(json["track-list"]);
  document.getElementById("duration").innerHTML =
    "&nbsp;" + format_time(json["duration"]);
  document.getElementById("remaining").innerHTML =
    "-" + format_time(json["remaining"]);
  document.getElementById("speed").innerHTML = json["speed"].toFixed(2) + "x";
  document.getElementById("sub-delay").innerHTML = json["sub-delay"] + " ms";
  document.getElementById("audio-delay").innerHTML =
    json["audio-delay"] + " ms";
  setPlayPause(json["pause"]);
  setPosSlider(json["position"], json["duration"]);
  setVolumeSlider(json["volume"], json["volume-max"]);
  setLoop(json["loop-file"], json["loop-playlist"]);
  setFullscreenButton(json["fullscreen"]);
  setChapter(json["chapters"], json["chapter"], json["chapter-list"]);
  setStartEnd(json["start"], json["end"]);
  populatePlaylist(json["playlist"], json["pause"]);
  setupNotification(json);
}

let nextRefresh;
function refreshStatus(timeout) {
  if (nextRefresh) {
    return;
  }
  nextRefresh = setTimeout(() => {
    nextRefresh = undefined;
    status();
  }, timeout);
}

function status() {
  const request = new XMLHttpRequest();
  request.open("get", "/api/status");

  request.onreadystatechange = function () {
    if (request.readyState === 4 && request.status === 200) {
      const json = JSON.parse(request.responseText);
      handleStatusResponse(json);
    } else if (request.status === 0) {
      document.getElementById("title").innerHTML =
        "<h1><span class='error'>Couldn't connect to MPV!</span></h1>";
      document.getElementById("artist").innerHTML = "";
      document.getElementById("album").innerHTML = "";
      setPlayPause(true);
    }
  };
  request.send(null);
}

document.getElementById("disableNotifications").onchange = function () {
  settings.disableNotifications = document.getElementById(
    "disableNotifications"
  ).checked;
  setCookie("disableNotification=" + settings.disableNotifications);
  const audio = document.getElementById("audio");
  audio.src = "static/audio/silence.mp3";
  if (settings.disableNotifications) {
    audio.src = "";
  } else {
    audioLoad();
  }
};

document.getElementById("seekSeconds").onchange = function () {
  settings.seekSeconds = document.getElementById("seekSeconds").value;
  setCookie("seekSeconds=" + settings.seekSeconds);
};

function audioLoad() {
  if (!window.loaded) {
    DEBUG && console.log("Loading dummy audio");
    document.getElementById("audio").load();
    window.loaded = true;
  }
}

function audioPlay() {
  const audio = document.getElementById("audio");
  if (audio.paused) {
    audio.play().then(function () {
      DEBUG && console.log("Playing dummy audio");
    });
  }
}

function audioPause() {
  const audio = document.getElementById("audio");
  if (!audio.paused) {
    DEBUG && console.log("Pausing dummy audio");
    audio.pause();
  }
}

function setupNotification({ duration, speed, position }) {
  if (useNotifications()) {
    if (navigator.mediaSession.setPositionState) {
      navigator.mediaSession.setPositionState({
        duration: duration,
        playbackRate: speed,
        position: position,
      });
    }
    navigator.mediaSession.metadata = new MediaMetadata({
      title: window.metadata.title,
      artist: window.metadata.artist,
      album: window.metadata.album,
      artwork: [
        {
          src: "static/favicons/android-chrome-192x192.png",
          sizes: "192x192",
          type: "image/png",
        },
        {
          src: "static/favicons/android-chrome-512x512.png",
          sizes: "512x512",
          type: "image/png",
        },
      ],
    });

    navigator.mediaSession.setActionHandler("play", function () {
      send("play");
    });
    navigator.mediaSession.setActionHandler("pause", function () {
      send("pause");
    });
    navigator.mediaSession.setActionHandler("seekbackward", function () {
      seek(-1);
    });
    navigator.mediaSession.setActionHandler("seekforward", function () {
      seek(1);
    });
    navigator.mediaSession.setActionHandler("previoustrack", function () {
      send("playlist_prev");
    });
    navigator.mediaSession.setActionHandler("nexttrack", function () {
      send("playlist_next");
    });
  }
}

// Toggle between high-refresh when active, but low-refresh when backgrounded.
let refreshInterval;
let nextPeriodicRefresh;
function schedulePeriodicStatus() {
  if (nextPeriodicRefresh) {
    clearTimeout(nextPeriodicRefresh);
  }

  refreshInterval = document.hidden ? 10000 : 1000;
  nextPeriodicRefresh = setTimeout(refreshStatus, refreshInterval);
}
function refreshStatus() {
  status();
  schedulePeriodicStatus();
}

document.addEventListener("visibilitychange", refreshStatus, false);
refreshStatus();
