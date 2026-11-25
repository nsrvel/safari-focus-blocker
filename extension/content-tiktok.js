(() => {
  "use strict";

  try {
    window.stop();
  } catch (_) {
    // Ignore if stop is unavailable
  }

  const renderBlockedNotice = () => {
    const html = `
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Focus Blocker</title>
        <style>
          html, body {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            background: #0f1115;
            color: #f3f4f6;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .box {
            text-align: center;
            padding: 32px 24px;
            max-width: 420px;
          }
          h1 {
            margin: 0 0 10px;
            font-size: 20px;
            font-weight: 600;
            color: #ffffff;
          }
          p {
            margin: 0;
            font-size: 14px;
            color: #9ca3af;
          }
        </style>
      </head>
      <body>
        <main class="box">
          <h1>diblokir oleh Focus Blocker</h1>
          <p>TikTok is always blocked by Focus Blocker.</p>
        </main>
      </body>
    `;

    if (document.documentElement) {
      document.documentElement.innerHTML = html;
    } else {
      document.open();
      document.write(`<!doctype html><html>${html}</html>`);
      document.close();
    }
  };

  renderBlockedNotice();
})();
