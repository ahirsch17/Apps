import io from "socket.io-client";

// Shared websocket client for all apps.
// Goal: no app should call socket APIs directly; they should call this module instead.

let socket = null;
let lastUrl = null;
let lastOptions = null;

function ensureSocket(url, options) {
  // If an app connects to a different server URL, we treat it as a new session.
  if (socket && lastUrl && lastUrl !== url) {
    try {
      socket.disconnect();
    } catch (_) {
      // ignore
    } finally {
      socket = null;
    }
  }

  if (socket) return socket;

  lastUrl = url;
  lastOptions = options;

  socket = io(url, options);
  return socket;
}

export const client = {
  connect(url, options = {}) {
    const resolvedOptions = {
      transports: ["websocket"],
      reconnection: true,
      reconnectionAttempts: 5,
      reconnectionDelay: 1000,
      ...options,
    };

    const s = ensureSocket(url, resolvedOptions);

    // socket.io connects automatically, but calling connect() again is safe.
    if (!s.connected) {
      try {
        s.connect();
      } catch (_) {
        // ignore
      }
    }

    return s;
  },

  disconnect() {
    if (!socket) return;
    try {
      socket.disconnect();
    } finally {
      socket = null;
    }
  },

  isConnected() {
    return Boolean(socket && socket.connected);
  },

  emit(event, payload) {
    if (!socket) return false;
    socket.emit(event, payload);
    return true;
  },

  on(event, handler) {
    if (!socket) return false;
    socket.on(event, handler);
    return true;
  },

  once(event, handler) {
    if (!socket) return false;
    socket.once(event, handler);
    return true;
  },

  off(event, handler) {
    if (!socket) return false;
    socket.off(event, handler);
    return true;
  },

  onAny(handler) {
    if (!socket) return false;
    socket.onAny(handler);
    return true;
  },

  offAny(handler) {
    if (!socket) return false;
    // If handler is omitted, Socket.IO removes all "any" listeners.
    socket.offAny(handler);
    return true;
  },

  onAnyOutgoing(handler) {
    if (!socket) return false;
    socket.onAnyOutgoing(handler);
    return true;
  },

  offAnyOutgoing(handler) {
    if (!socket) return false;
    socket.offAnyOutgoing(handler);
    return true;
  },

  removeAllListeners() {
    if (!socket) return false;
    socket.removeAllListeners();
    return true;
  },

  // Optional: allow apps to re-init with last config after a full disconnect.
  reconnect() {
    if (!lastUrl) return false;
    this.disconnect();
    this.connect(lastUrl, lastOptions || undefined);
    return true;
  },
};


function createEmitter() {
  /** @type {{ [event: string]: Set<Function> }} */
  const listeners = {};

  return {
    on(event, handler) {
      if (!listeners[event]) listeners[event] = new Set();
      listeners[event].add(handler);
      return () => this.off(event, handler);
    },
    off(event, handler) {
      if (!listeners[event]) return;
      if (!handler) {
        listeners[event].clear();
        return;
      }
      listeners[event].delete(handler);
    },
    emit(event, payload) {
      if (!listeners[event] || listeners[event].size === 0) return;
      for (const handler of listeners[event]) {
        try {
          handler(payload);
        } catch (err) {
          // Don't let one bad handler break others
          // eslint-disable-next-line no-console
          console.error(`[client.js] handler error for event "${event}"`, err);
        }
      }
    },
    removeAllListeners() {
      for (const key of Object.keys(listeners)) listeners[key].clear();
    },
  };
}

/**
 * BluffLocation websocket API (Socket.IO)
 *
 * Owns:
 * - connect / disconnect
 * - mapping Socket.IO events -> app events
 * - all emits for BluffLocation gameplay actions
 *
 * Consumers should NOT use `socket.io-client` or raw socket APIs.
 */
const bluffLocationEmitter = createEmitter();
let bluffLocationForwardersAttached = false;

function attachBluffLocationForwarders() {
  if (bluffLocationForwardersAttached) return true;
  if (!socket) return false;

  // Connection lifecycle
  socket.on("connect", () => {
    bluffLocationEmitter.emit("connected");
  });

  socket.on("disconnect", () => {
    bluffLocationEmitter.emit("disconnected");
  });

  socket.on("connect_error", (error) => {
    bluffLocationEmitter.emit("error", { message: error?.message || "Connection failed" });
  });

  // Server emits 'error' for app-level errors.
  socket.on("error", (data) => {
    const msg = (data?.message || "").toLowerCase();
    if (msg.includes("already in room") || msg.includes("already joined")) {
      bluffLocationEmitter.emit("already_in_room", data);
      return;
    }
    bluffLocationEmitter.emit("error", data);
  });

  // Room events
  socket.on("room_created", (data) => bluffLocationEmitter.emit("room_created", data));
  socket.on("joined_room", (data) => bluffLocationEmitter.emit("joined_room", data));
  socket.on("player_joined", (data) => bluffLocationEmitter.emit("player_joined", data));
  socket.on("player_left", (data) => bluffLocationEmitter.emit("player_left", data));

  // Game events
  socket.on("game_started", (data) => bluffLocationEmitter.emit("game_started", data));
  socket.on("role_assignment", (data) => bluffLocationEmitter.emit("role_assignment", data));
  socket.on("game_ended", (data) => bluffLocationEmitter.emit("game_ended", data));

  // Voting events
  socket.on("vote_recorded", (data) => bluffLocationEmitter.emit("vote_recorded", data));
  socket.on("vote_results", (data) => bluffLocationEmitter.emit("vote_results", data));

  // Spy guess events
  socket.on("spy_guess_result", (data) => bluffLocationEmitter.emit("spy_guess_result", data));

  // State sync events
  socket.on("state_sync", (data) => bluffLocationEmitter.emit("state_sync", data));
  socket.on("room_state", (data) => bluffLocationEmitter.emit("room_state", data));

  // Timer updates
  socket.on("time_limit_updated", (data) => bluffLocationEmitter.emit("time_limit_updated", data));

  // Optional server messages
  socket.on("server_message", (data) => bluffLocationEmitter.emit("server_message", data));

  bluffLocationForwardersAttached = true;
  return true;
}

export const bluffLocation = {
  connect(serverUrl, options = {}) {
    // Ensure socket exists and is connected, then attach one-time forwarders.
    client.connect(serverUrl, options);
    attachBluffLocationForwarders();
    return true;
  },

  disconnect() {
    client.disconnect();
    bluffLocationForwardersAttached = false;
  },

  isConnected() {
    return client.isConnected();
  },

  /**
   * Resolves when connected (or immediately if already connected).
   * Rejects on timeout.
   */
  ensureConnected(serverUrl, options = {}, timeoutMs = 8000) {
    this.connect(serverUrl, options);
    if (this.isConnected()) return Promise.resolve(true);

    return new Promise((resolve, reject) => {
      let settled = false;
      const offConnected = bluffLocationEmitter.on("connected", () => {
        if (settled) return;
        settled = true;
        offConnected();
        offError();
        clearTimeout(timeoutId);
        resolve(true);
      });
      const offError = bluffLocationEmitter.on("error", (err) => {
        if (settled) return;
        settled = true;
        offConnected();
        offError();
        clearTimeout(timeoutId);
        reject(err || new Error("Connection failed"));
      });
      const timeoutId = setTimeout(() => {
        if (settled) return;
        settled = true;
        offConnected();
        offError();
        reject(new Error("Connection timed out"));
      }, timeoutMs);
    });
  },

  // App-level events (NOT socket events)
  on(event, handler) {
    return bluffLocationEmitter.on(event, handler);
  },
  off(event, handler) {
    return bluffLocationEmitter.off(event, handler);
  },
  removeAllListeners() {
    bluffLocationEmitter.removeAllListeners();
  },

  // BluffLocation actions (all emits live here)
  createGame({ user, time_limit_minutes }) {
    return client.emit("create_game", { user, time_limit_minutes });
  },
  joinGame({ room, user }) {
    return client.emit("join_game", { room, user });
  },
  leaveGame({ room, user }) {
    return client.emit("leave_game", { room, user });
  },
  startGame({ room, user, time_limit_minutes }) {
    return client.emit("start_game", { room, user, time_limit_minutes });
  },
  endGame({ room, user, reason }) {
    return client.emit("end_game", { room, user, reason });
  },
  voteSpy({ room, user, vote_for, tentative }) {
    return client.emit("vote_spy", { room, user, vote_for, tentative });
  },
  guessLocation({ room, user, location }) {
    return client.emit("guess_location", { room, user, location });
  },
  syncState({ room, user }) {
    return client.emit("sync_state", { room, user });
  },
  updateTimeLimit({ room, minutes, user }) {
    return client.emit("update_time_limit", { room, minutes, user });
  },
};


