// Ensure WebSocket exists in Node environment for libraries expecting a browser global
import WebSocket from 'ws';

// Only assign if not already defined
if (typeof (globalThis as any).WebSocket === 'undefined') {
  (globalThis as any).WebSocket = WebSocket as unknown as typeof WebSocket;
}


