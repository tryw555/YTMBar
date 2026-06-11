import AppKit
import WebKit

final class YouTubeMusicViewController: NSViewController, WKNavigationDelegate, WKScriptMessageHandler {
    var onPlaybackStateChange: ((PlaybackState) -> Void)?

    private var webView: WKWebView!

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let userContentController = WKUserContentController()
        userContentController.add(self, name: "ytmbarState")
        userContentController.addUserScript(WKUserScript(source: Self.stateObserverScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        configuration.userContentController = userContentController

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15 YTMBar/0.1"

        view = webView

        if let url = URL(string: "https://music.youtube.com") {
            var request = URLRequest(url: url)
            request.setValue("https://com.ozwin.ytmbar", forHTTPHeaderField: "Referer")
            webView.load(request)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let urlString = webView.url?.absoluteString ?? "unknown URL"
        NSLog("YTMBar WebView finished loading: \(urlString)")
        DiagnosticsLogger.shared.log("WebView finished loading: \(urlString)")
        injectStateObserver()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "ytmbarState",
              let payload = message.body as? [String: Any]
        else {
            return
        }

        let title = (payload["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = (payload["artist"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let artworkString = payload["artwork"] as? String
        let isPlaying = payload["isPlaying"] as? Bool ?? false

        guard let title, !title.isEmpty else { return }

        let state = PlaybackState(
            title: title,
            artist: artist?.isEmpty == false ? artist! : "YouTube Music",
            artworkURL: artworkString.flatMap(URL.init(string:)),
            isPlaying: isPlaying
        )

        NSLog("YTMBar detected playback: title='\(state.title)' artist='\(state.artist)' playing=\(state.isPlaying) artwork=\(state.artworkURL?.absoluteString ?? "none")")
        DiagnosticsLogger.shared.log("Detected playback: title='\(state.title)' artist='\(state.artist)' playing=\(state.isPlaying) artwork=\(state.artworkURL?.absoluteString ?? "none")")
        onPlaybackStateChange?(state)
    }

    func playPrevious() {
        executeControlScript(commandName: "previous", preferredSelectors: [
            "ytmusic-player-bar .previous-button",
            "ytmusic-player-bar #left-controls .previous-button",
            "ytmusic-player-bar [aria-label*='Previous']",
            "ytmusic-player-bar [aria-label*='이전']"
        ], labels: ["previous", "이전"])
    }

    func togglePlayPause() {
        executeControlScript(commandName: "playpause", preferredSelectors: [
            "ytmusic-player-bar #play-pause-button",
            "ytmusic-player-bar .play-pause-button",
            "ytmusic-player-bar [aria-label*='Play']",
            "ytmusic-player-bar [aria-label*='Pause']",
            "ytmusic-player-bar [aria-label*='재생']",
            "ytmusic-player-bar [aria-label*='일시정지']",
            "ytmusic-player-bar [aria-label*='일시중지']"
        ], labels: ["play", "pause", "재생", "일시정지", "일시중지"])
    }

    func setPlayback(playing shouldPlay: Bool) {
        if shouldPlay {
            executePlaybackScript(shouldPlay: true)
        } else {
            webView.pauseAllMediaPlayback { [weak self] in
                DiagnosticsLogger.shared.log("Native pauseAllMediaPlayback completed")
                self?.executePlaybackScript(shouldPlay: false)
            }
        }
    }

    func playNext() {
        executeControlScript(commandName: "next", preferredSelectors: [
            "ytmusic-player-bar .next-button",
            "ytmusic-player-bar #left-controls .next-button",
            "ytmusic-player-bar [aria-label*='Next']",
            "ytmusic-player-bar [aria-label*='다음']"
        ], labels: ["next", "다음"])
    }

    private func executeControlScript(commandName: String, preferredSelectors: [String], labels: [String]) {
        let selectorsLiteral = preferredSelectors
            .map { "\"\($0)\"" }
            .joined(separator: ", ")
        let labelsLiteral = labels
            .map { "\"\($0)\"" }
            .joined(separator: ", ")

        let script = """
        (() => {
          const selectors = [\(selectorsLiteral)];
          const labels = [\(labelsLiteral)];
          const commandName = "\(commandName)";
          const wantsPlayPause = labels.some((label) => ['play', 'pause', '재생', '일시정지', '일시중지'].includes(label.toLowerCase()));
          const clean = (value) => (value || '').replace(/\\s+/g, ' ').trim();
          const deepQuerySelectorAll = (selector, root = document) => {
            const results = [];
            const visit = (node) => {
              if (!node) return;

              if (node.querySelectorAll) {
                results.push(...node.querySelectorAll(selector));
                for (const element of node.querySelectorAll('*')) {
                  if (element.shadowRoot) visit(element.shadowRoot);
                }
              }
            };

            visit(root);
            return results;
          };
          const deepQuerySelector = (selector, root = document) => deepQuerySelectorAll(selector, root)[0] || null;
          const postStateSoon = () => {
            if (window.__ytmbarPostState) {
              setTimeout(window.__ytmbarPostState, 60);
              setTimeout(window.__ytmbarPostState, 260);
              setTimeout(window.__ytmbarPostState, 650);
            }
          };

          const mediaElements = () => deepQuerySelectorAll('video, audio');
          const activeMedia = () => mediaElements().filter((element) => element.readyState > 0);
          const playerCandidates = () => [
            deepQuerySelector('#movie_player'),
            deepQuerySelector('ytmusic-player'),
            deepQuerySelector('ytmusic-player-page')
          ].filter(Boolean);

          const clickLikeUser = (element) => {
            if (!element) return false;
            const target = element.shadowRoot && element.shadowRoot.querySelector('button')
              ? element.shadowRoot.querySelector('button')
              : element;
            const eventInit = { bubbles: true, cancelable: true, composed: true, view: window };
            const pointerEvent = (name) => typeof PointerEvent === 'function'
              ? new PointerEvent(name, eventInit)
              : new MouseEvent(name.replace('pointer', 'mouse'), eventInit);

            target.dispatchEvent(pointerEvent('pointerdown'));
            target.dispatchEvent(new MouseEvent('mousedown', eventInit));
            target.dispatchEvent(pointerEvent('pointerup'));
            target.dispatchEvent(new MouseEvent('mouseup', eventInit));
            target.dispatchEvent(new MouseEvent('click', eventInit));
            postStateSoon();
            return true;
          };

          const findButton = () => {
            for (const selector of selectors) {
              const button = document.querySelector(selector) || deepQuerySelector(selector);
              if (button) return button;
            }

            const bar = document.querySelector('ytmusic-player-bar') || document;
            const candidates = deepQuerySelectorAll('button, tp-yt-paper-icon-button, yt-icon-button, .play-pause-button, #play-pause-button', bar);
            return candidates.find((candidate) => {
              const labelText = [
                candidate.getAttribute('aria-label'),
                candidate.getAttribute('title'),
                candidate.getAttribute('data-tooltip'),
                candidate.textContent
              ].map(clean).join(' ').toLowerCase();
              return labels.some((label) => labelText.includes(label.toLowerCase()));
            });
          };

          if (wantsPlayPause) {
            const media = activeMedia();
            const playingMedia = media.filter((element) => !element.paused && !element.ended);

            if (playingMedia.length) {
              playingMedia.forEach((element) => element.pause());
              postStateSoon();
              return { ok: true, commandName, method: 'media.pause', mediaCount: media.length };
            }

            for (const player of playerCandidates()) {
              if (typeof player.getPlayerState === 'function') {
                const state = Number(player.getPlayerState());
                if ((state === 1 || state === 3) && typeof player.pauseVideo === 'function') {
                  player.pauseVideo();
                  postStateSoon();
                  return { ok: true, commandName, method: 'player.pauseVideo' };
                }
                if ((state === 0 || state === 2 || state === 5 || Number.isNaN(state)) && typeof player.playVideo === 'function') {
                  player.playVideo();
                  postStateSoon();
                  return { ok: true, commandName, method: 'player.playVideo' };
                }
              }
            }

            const pausedMedia = media[0];
            if (pausedMedia && pausedMedia.paused) {
              const promise = pausedMedia.play();
              if (promise && typeof promise.catch === 'function') {
                promise.catch(() => {
                  const button = findButton();
                  clickLikeUser(button);
                });
              }
              postStateSoon();
              return { ok: true, commandName, method: 'media.play', mediaCount: media.length };
            }
          }

          const button = findButton();
          if (button) {
            clickLikeUser(button);
            return { ok: true, commandName, method: 'button.click', mediaCount: activeMedia().length };
          }

          return { ok: false, commandName, method: 'not-found', mediaCount: activeMedia().length };
        })();
        """

        webView.evaluateJavaScript(script) { result, error in
            if let error {
                DiagnosticsLogger.shared.log("Command \(commandName) failed: \(error.localizedDescription)")
            } else {
                DiagnosticsLogger.shared.log("Command \(commandName) result: \(String(describing: result))")
            }
        }
    }

    private func executePlaybackScript(shouldPlay: Bool) {
        let desiredState = shouldPlay ? "play" : "pause"
        let shouldPlayLiteral = shouldPlay ? "true" : "false"
        let script = """
        (() => {
          const shouldPlay = \(shouldPlayLiteral);
          const desiredState = "\(desiredState)";
          const clean = (value) => (value || '').replace(/\\s+/g, ' ').trim();
          const deepQuerySelectorAll = (selector, root = document) => {
            const results = [];
            const visit = (node) => {
              if (!node || !node.querySelectorAll) return;

              results.push(...node.querySelectorAll(selector));
              for (const element of node.querySelectorAll('*')) {
                if (element.shadowRoot) visit(element.shadowRoot);
              }
            };

            visit(root);
            return results;
          };
          const deepQuerySelector = (selector, root = document) => deepQuerySelectorAll(selector, root)[0] || null;
          const postStateSoon = () => {
            if (window.__ytmbarPostState) {
              setTimeout(window.__ytmbarPostState, 40);
              setTimeout(window.__ytmbarPostState, 140);
              setTimeout(window.__ytmbarPostState, 420);
              setTimeout(window.__ytmbarPostState, 900);
            }
          };
          const labelTextFor = (candidate) => [
            candidate && candidate.getAttribute && candidate.getAttribute('aria-label'),
            candidate && candidate.getAttribute && candidate.getAttribute('title'),
            candidate && candidate.getAttribute && candidate.getAttribute('data-tooltip'),
            candidate && candidate.textContent
          ].map(clean).join(' ').toLowerCase();
          const meansPause = (text) =>
            text.includes('pause') ||
            text.includes('일시정지') ||
            text.includes('일시 정지') ||
            text.includes('일시중지') ||
            text.includes('일시 중지');
          const meansPlay = (text) =>
            !meansPause(text) && (
              text.includes('play') ||
              text.includes('재생')
            );
          const clickLikeUser = (element) => {
            if (!element) return false;
            const target = element.shadowRoot && element.shadowRoot.querySelector('button')
              ? element.shadowRoot.querySelector('button')
              : element;
            const eventInit = { bubbles: true, cancelable: true, composed: true, view: window };
            const pointerEvent = (name) => typeof PointerEvent === 'function'
              ? new PointerEvent(name, eventInit)
              : new MouseEvent(name.replace('pointer', 'mouse'), eventInit);

            target.dispatchEvent(pointerEvent('pointerdown'));
            target.dispatchEvent(new MouseEvent('mousedown', eventInit));
            target.dispatchEvent(pointerEvent('pointerup'));
            target.dispatchEvent(new MouseEvent('mouseup', eventInit));
            if (typeof target.click === 'function') {
              target.click();
            } else {
              target.dispatchEvent(new MouseEvent('click', eventInit));
            }
            postStateSoon();
            return true;
          };
          const media = deepQuerySelectorAll('video, audio').filter((element) => element.readyState > 0);
          const players = [
            deepQuerySelector('#movie_player'),
            deepQuerySelector('ytmusic-player'),
            deepQuerySelector('ytmusic-player-page')
          ].filter(Boolean);

          if (!shouldPlay) {
            const playingMedia = media.filter((element) => !element.paused && !element.ended);
            if (playingMedia.length) {
              playingMedia.forEach((element) => element.pause());
              postStateSoon();
              return { ok: true, desiredState, method: 'media.pause', mediaCount: media.length };
            }

            for (const player of players) {
              if (typeof player.pauseVideo === 'function') {
                player.pauseVideo();
                postStateSoon();
                return { ok: true, desiredState, method: 'player.pauseVideo', mediaCount: media.length };
              }
            }
          } else {
            for (const player of players) {
              if (typeof player.playVideo === 'function') {
                player.playVideo();
                postStateSoon();
                return { ok: true, desiredState, method: 'player.playVideo', mediaCount: media.length };
              }
            }

            const pausedMedia = media.find((element) => element.paused || element.ended);
            if (pausedMedia) {
              const promise = pausedMedia.play();
              if (promise && typeof promise.catch === 'function') promise.catch(() => {});
              postStateSoon();
              return { ok: true, desiredState, method: 'media.play', mediaCount: media.length };
            }
          }

          const bar = document.querySelector('ytmusic-player-bar') || document;
          const candidates = [
            document.querySelector('ytmusic-player-bar #play-pause-button'),
            document.querySelector('ytmusic-player-bar .play-pause-button'),
            deepQuerySelector('ytmusic-player-bar #play-pause-button'),
            deepQuerySelector('ytmusic-player-bar .play-pause-button'),
            ...deepQuerySelectorAll('button, tp-yt-paper-icon-button, yt-icon-button, .play-pause-button, #play-pause-button', bar)
          ].filter(Boolean);
          const matchingButton = candidates.find((button) => {
            const text = labelTextFor(button);
            return shouldPlay ? meansPlay(text) : meansPause(text);
          }) || candidates[0];

          if (matchingButton) {
            clickLikeUser(matchingButton);
            return { ok: true, desiredState, method: 'button.click', mediaCount: media.length, label: labelTextFor(matchingButton) };
          }

          return { ok: false, desiredState, method: 'not-found', mediaCount: media.length };
        })();
        """

        webView.evaluateJavaScript(script) { result, error in
            if let error {
                DiagnosticsLogger.shared.log("Playback \(desiredState) failed: \(error.localizedDescription)")
            } else {
                DiagnosticsLogger.shared.log("Playback \(desiredState) result: \(String(describing: result))")
            }
        }
    }

    private func injectStateObserver() {
        webView.evaluateJavaScript(Self.stateObserverScript)
    }

    private static let stateObserverScript = """
    (() => {
      if (window.__ytmbarInstalled) {
        window.__ytmbarPostState && window.__ytmbarPostState();
        return;
      }

      window.__ytmbarInstalled = true;

      const clean = (value) => (value || '').replace(/\\s+/g, ' ').trim();
      const deepQuerySelectorAll = (selector, root = document) => {
        const results = [];
        const visit = (node) => {
          if (!node) return;

          if (node.querySelectorAll) {
            results.push(...node.querySelectorAll(selector));
            for (const element of node.querySelectorAll('*')) {
              if (element.shadowRoot) visit(element.shadowRoot);
            }
          }
        };

        visit(root);
        return results;
      };
      const deepQuerySelector = (selector, root = document) => deepQuerySelectorAll(selector, root)[0] || null;
      const mediaSession = () => navigator.mediaSession || null;
      const mediaMetadata = () => mediaSession() && mediaSession().metadata ? mediaSession().metadata : null;
      const mediaElements = () => deepQuerySelectorAll('video, audio');

      const findPlayerBar = () => {
        return document.querySelector('ytmusic-player-bar') || document.body;
      };

      const readTitle = (bar) => {
        const metadataTitle = clean(mediaMetadata() && mediaMetadata().title);
        if (metadataTitle) return metadataTitle;

        const selectors = [
          'ytmusic-player-bar .title',
          '.title.ytmusic-player-bar',
          'yt-formatted-string.title',
          '#layout ytmusic-player-bar .title',
          'ytmusic-player-bar .song-title',
          'a.yt-simple-endpoint.ytmusic-player-bar'
        ];

        for (const selector of selectors) {
          const node = bar.querySelector(selector);
          const text = clean(node && node.textContent);
          if (text) return text;
        }

        return clean(document.title.replace(/- YouTube Music$/i, ''));
      };

      const readArtist = (bar) => {
        const metadataArtist = clean(mediaMetadata() && mediaMetadata().artist);
        if (metadataArtist) return metadataArtist;

        const selectors = [
          'ytmusic-player-bar .byline',
          '.byline.ytmusic-player-bar',
          'yt-formatted-string.byline',
          '#layout ytmusic-player-bar .byline',
          'ytmusic-player-bar .subtitle'
        ];

        for (const selector of selectors) {
          const node = bar.querySelector(selector);
          const text = clean(node && node.textContent);
          if (text) return text;
        }

        return '';
      };

      const readArtwork = (bar) => {
        const artwork = mediaMetadata() && mediaMetadata().artwork;
        if (artwork && artwork.length) {
          const sortedArtwork = Array.from(artwork).sort((left, right) => {
            const leftSize = parseInt((left.sizes || '0').split('x')[0], 10) || 0;
            const rightSize = parseInt((right.sizes || '0').split('x')[0], 10) || 0;
            return rightSize - leftSize;
          });

          const src = clean(sortedArtwork[0] && sortedArtwork[0].src);
          if (src) return src;
        }

        const image = bar.querySelector('img[src*="ytimg"], img');
        return image ? image.src : '';
      };

      const readIsPlaying = (bar) => {
        const playbackState = clean(mediaSession() && mediaSession().playbackState).toLowerCase();
        if (playbackState === 'playing') return true;
        if (playbackState === 'paused') return false;

        const playerCandidates = [
          deepQuerySelector('#movie_player'),
          deepQuerySelector('ytmusic-player'),
          deepQuerySelector('ytmusic-player-page')
        ];

        for (const player of playerCandidates) {
          const getPlayerState = player && player.getPlayerState;
          if (typeof getPlayerState === 'function') {
            const state = Number(getPlayerState.call(player));
            if (state === 1 || state === 3) return true;
            if (state === 0 || state === 2) return false;
          }
        }

        const media = mediaElements().filter((element) => element.readyState > 0);
        if (media.some((element) => !element.paused && !element.ended)) return true;

        const buttons = deepQuerySelectorAll('button, tp-yt-paper-icon-button, yt-icon-button, .play-pause-button, #play-pause-button', bar);
        const button = buttons.find((candidate) => {
          const labelText = [
            candidate.getAttribute('aria-label'),
            candidate.getAttribute('title'),
            candidate.getAttribute('data-tooltip'),
            candidate.textContent
          ].map(clean).join(' ').toLowerCase();
          return labelText.includes('pause') ||
            labelText.includes('play') ||
            labelText.includes('paused') ||
            labelText.includes('playing') ||
            labelText.includes('일시정지') ||
            labelText.includes('일시 정지') ||
            labelText.includes('일시중지') ||
            labelText.includes('일시 중지') ||
            labelText.includes('재생');
        });

        const labelText = [
          button && button.getAttribute('aria-label'),
          button && button.getAttribute('title'),
          button && button.getAttribute('data-tooltip'),
          button && button.textContent
        ].map(clean).join(' ').toLowerCase();

        if (labelText.includes('paused')) {
          return false;
        }

        if (labelText.includes('playing') || labelText.includes('재생 중')) {
          return true;
        }

        if (
          labelText.includes('pause') ||
          labelText.includes('일시정지') ||
          labelText.includes('일시 정지') ||
          labelText.includes('일시중지') ||
          labelText.includes('일시 중지')
        ) {
          return true;
        }

        if (labelText.includes('play') || labelText.includes('재생')) {
          return false;
        }

        if (media.length) return media.some((element) => !element.paused && !element.ended);
        return false;
      };

      window.__ytmbarPostState = () => {
        const bar = findPlayerBar();
        const title = readTitle(bar);

        if (!title || title === 'YouTube Music') return;

        window.webkit.messageHandlers.ytmbarState.postMessage({
          title,
          artist: readArtist(bar),
          artwork: readArtwork(bar),
          isPlaying: readIsPlaying(bar)
        });
      };

      const queuePost = () => {
        clearTimeout(window.__ytmbarTimer);
        window.__ytmbarTimer = setTimeout(window.__ytmbarPostState, 250);
      };

      const observer = new MutationObserver(queuePost);
      observer.observe(document.documentElement, {
        subtree: true,
        childList: true,
        attributes: true,
        characterData: true
      });

      setInterval(window.__ytmbarPostState, 2500);
      window.__ytmbarPostState();
    })();
    """
}
