(() => {
  "use strict";

  const STYLE_ID = "focus-blocker-youtube-style";

  const HIDE_CSS = `
    ytd-reel-shelf-renderer,
    ytd-rich-shelf-renderer[is-shorts],
    ytd-rich-shelf-renderer:has(a[href^="/shorts/"]),
    ytd-guide-entry-renderer:has(a[title="Shorts"]),
    ytd-guide-entry-renderer:has(a[href^="/shorts"]),
    ytd-mini-guide-entry-renderer:has(a[title="Shorts"]),
    ytd-mini-guide-entry-renderer:has(a[href^="/shorts"]),
    ytm-pivot-bar-item-renderer:has(.pivot-shorts),
    ytd-reel-item-renderer,
    ytm-reel-shelf-renderer {
      display: none !important;
    }
  `;

  function redirectIfShorts() {
    const match = window.location.pathname.match(/^\/shorts\/([A-Za-z0-9_-]+)/);
    if (!match) {
      return false;
    }
    const videoId = match[1];
    window.location.replace("/watch?v=" + encodeURIComponent(videoId));
    return true;
  }

  function injectStyle() {
    if (document.getElementById(STYLE_ID)) {
      return;
    }
    const target = document.head || document.documentElement;
    if (!target) {
      return;
    }
    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.textContent = HIDE_CSS;
    target.appendChild(style);
  }

  function hideShortsElements(root) {
    if (!root || root.nodeType !== Node.ELEMENT_NODE) {
      return;
    }

    const selectors = [
      "ytd-reel-shelf-renderer",
      "ytd-rich-shelf-renderer[is-shorts]",
      "ytm-reel-shelf-renderer"
    ];

    for (const selector of selectors) {
      if (root.matches && root.matches(selector)) {
        root.style.setProperty("display", "none", "important");
      }
      const matches = root.querySelectorAll ? root.querySelectorAll(selector) : [];
      for (const el of matches) {
        el.style.setProperty("display", "none", "important");
      }
    }

    // Hide ytd-rich-shelf-renderer if it contains Shorts links or title
    const richShelves = root.matches && root.matches("ytd-rich-shelf-renderer")
      ? [root]
      : (root.querySelectorAll ? root.querySelectorAll("ytd-rich-shelf-renderer") : []);
    for (const shelf of richShelves) {
      if (shelf.hasAttribute("is-shorts") || shelf.querySelector('a[href^="/shorts/"]')) {
        shelf.style.setProperty("display", "none", "important");
      }
    }

    // Hide Shorts sidebar / guide entries
    const guideLinks = root.querySelectorAll
      ? root.querySelectorAll('a[title="Shorts"], a[href="/shorts"], a[href^="/shorts/"]')
      : [];
    for (const link of guideLinks) {
      const entry = link.closest(
        "ytd-guide-entry-renderer, ytd-mini-guide-entry-renderer, ytm-pivot-bar-item-renderer"
      );
      if (entry) {
        entry.style.setProperty("display", "none", "important");
      }
    }
  }

  if (redirectIfShorts()) {
    return;
  }

  injectStyle();

  const observer = new MutationObserver((mutations) => {
    redirectIfShorts();
    injectStyle();
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        if (node.nodeType === Node.ELEMENT_NODE) {
          hideShortsElements(node);
        }
      }
    }
  });

  if (document.documentElement) {
    observer.observe(document.documentElement, { childList: true, subtree: true });
    hideShortsElements(document.documentElement);
  } else {
    document.addEventListener("DOMContentLoaded", () => {
      injectStyle();
      hideShortsElements(document.documentElement);
      observer.observe(document.documentElement, { childList: true, subtree: true });
    }, { once: true });
  }

  window.addEventListener("yt-navigate-start", redirectIfShorts, true);
  window.addEventListener("yt-navigate-finish", () => {
    redirectIfShorts();
    injectStyle();
    hideShortsElements(document.documentElement);
  }, true);
  window.addEventListener("popstate", redirectIfShorts, true);
})();
