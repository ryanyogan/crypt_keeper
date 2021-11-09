import 'phoenix_html';
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import topbar from '../vendor/topbar';
import Alpine from 'alpinejs';

window.Alpine = Alpine;
Alpine.start();

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');

const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
const liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken, timezone: timezone },
  dom: {
    onBeforeElUpdated(from, to) {
      if (from.__x) {
        window.Alpine.clone(from.__x, to);
      }
    },
  },
});

topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' });
window.addEventListener('phx:page-loading-start', (info) => topbar.show());
window.addEventListener('phx:page-loading-stop', (info) => topbar.hide());

liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
