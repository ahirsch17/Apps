import { WEBSOCKET_URL } from '../config/websocket';
import { bluffLocation } from '../../../client';

class GameManager {
  static instance = null;
  
  static getInstance() {
    if (!GameManager.instance) {
      GameManager.instance = new GameManager();
    }
    return GameManager.instance;
  }
  
  constructor() {
    this.currentGame = null;
    this.currentPlayer = null;
    this.connectionStatus = 'disconnected';
    this.eventListeners = {}; // Store event callbacks
    this.roomTimers = {}; // in-memory cache: { [roomCode]: minutes }
    this._forwardersBound = false;
  }
  
  // Connect to WebSocket server
  connect(serverUrl = WEBSOCKET_URL) {
    // Ensure shared client is connected & forwarders are attached in `Apps/client.js`
    bluffLocation.connect(serverUrl);
    this.connectionStatus = bluffLocation.isConnected() ? 'connected' : 'connecting';

    // Bind forwarders once per app session; these are NOT raw socket listeners.
    if (!this._forwardersBound) {
      this._setupServerEventListeners();
      this._forwardersBound = true;
    }
  }
  
  // Setup listeners for server events
  _setupServerEventListeners() {
    // Connection lifecycle
    bluffLocation.on('connected', () => {
      this.connectionStatus = 'connected';
      this._emitEvent('connected');

      // If we had a room + user before disconnect, try to rejoin and resync.
      // (Server may have removed us on disconnect.)
      if (this.currentGame && this.currentPlayer?.name) {
        bluffLocation.joinGame({
          room: this.currentGame,
          user: this.currentPlayer.name,
        });

        setTimeout(() => {
          this.syncState(this.currentGame);
        }, 300);
      }
    });

    bluffLocation.on('disconnected', () => {
      this.connectionStatus = 'disconnected';
      this._emitEvent('disconnected');
    });

    bluffLocation.on('already_in_room', (data) => {
      this._emitEvent('already_in_room', data);
    });

    bluffLocation.on('error', (data) => {
      this.connectionStatus = 'error';
      this._emitEvent('error', data);
    });

    // Room events
    bluffLocation.on('room_created', (data) => this._emitEvent('room_created', data));
    bluffLocation.on('joined_room', (data) => this._emitEvent('joined_room', data));
    bluffLocation.on('player_joined', (data) => this._emitEvent('player_joined', data));
    bluffLocation.on('player_left', (data) => this._emitEvent('player_left', data));

    // Game events
    bluffLocation.on('game_started', (data) => this._emitEvent('game_started', data));
    bluffLocation.on('role_assignment', (data) => this._emitEvent('role_assignment', data));
    bluffLocation.on('game_ended', (data) => this._emitEvent('game_ended', data));

    // Voting events
    bluffLocation.on('vote_recorded', (data) => this._emitEvent('vote_recorded', data));
    bluffLocation.on('vote_results', (data) => this._emitEvent('vote_results', data));

    // Spy guess events
    bluffLocation.on('spy_guess_result', (data) => this._emitEvent('spy_guess_result', data));

    // State sync events
    bluffLocation.on('state_sync', (data) => this._emitEvent('state_sync', data));
    bluffLocation.on('room_state', (data) => this._emitEvent('room_state', data));

    // Timer updates
    bluffLocation.on('time_limit_updated', (data) => {
      if (data?.room && data?.minutes) {
        this.roomTimers[data.room] = data.minutes;
      }
      this._emitEvent('time_limit_updated', data);
    });

    // Optional server messages
    bluffLocation.on('server_message', (data) => this._emitEvent('server_message', data));
  }
  
  // Register event listener
  on(event, callback) {
    if (!this.eventListeners[event]) {
      this.eventListeners[event] = [];
    }
    this.eventListeners[event].push(callback);
  }
  
  // Remove event listener
  off(event, callback) {
    if (this.eventListeners[event]) {
      // If no callback provided, remove all listeners for this event
      if (!callback) {
        this.eventListeners[event] = [];
        return;
      }
      this.eventListeners[event] = this.eventListeners[event].filter(cb => cb !== callback);
    }
  }
  
  // Emit event to registered listeners
  _emitEvent(event, data) {
    if (this.eventListeners[event]) {
      this.eventListeners[event].forEach(callback => callback(data));
    }
  }
  
  // Connect to game (create or join)
  connectToGame(gameCode, playerName, isHost, timerDuration = null) {
    this.connect();

    return bluffLocation
      .ensureConnected(WEBSOCKET_URL)
      .then(() => {
        this._connectToGame(gameCode, playerName, isHost, timerDuration);
      })
      .catch((err) => {
        this._emitEvent('error', err);
        throw err;
      });
  }

  // Convenience APIs used by views
  createGame(playerName, timerDuration = 5) {
    return this.connectToGame(null, playerName, true, timerDuration);
  }

  joinGame(gameCode, playerName) {
    return this.connectToGame(gameCode, playerName, false);
  }

  updateLocalTimer(roomCode, minutes) {
    if (!roomCode) return false;
    this.roomTimers[roomCode] = minutes;
    return true;
  }

  getLocalTimer(roomCode) {
    if (!roomCode) return null;
    return this.roomTimers[roomCode] ?? null;
  }

  clearLocalTimer(roomCode) {
    if (!roomCode) return false;
    delete this.roomTimers[roomCode];
    return true;
  }
  
  _connectToGame(gameCode, playerName, isHost, timerDuration) {
    this.currentPlayer = { name: playerName, isHost };
    this.currentGame = gameCode;
    
    if (isHost) {
      // Host creates game
      bluffLocation.createGame({
        user: playerName,
        time_limit_minutes: timerDuration || 5,
      });
    } else {
      // Player joins game
      bluffLocation.joinGame({
        room: gameCode,
        user: playerName,
      });
    }
  }
  
  // Game actions
  startGame(gameCode, timerDuration = null) {
    if (!bluffLocation.isConnected()) return;

    // If caller provided a timer, update it first so the next round uses it.
    if (timerDuration !== null && timerDuration !== undefined) {
      bluffLocation.updateTimeLimit({
        room: gameCode,
        minutes: timerDuration,
        user: this.currentPlayer?.name,
      });
    }
    
    bluffLocation.startGame({
      room: gameCode,
      user: this.currentPlayer?.name,
      time_limit_minutes: timerDuration ?? undefined,
    });
  }
  
  endGame(gameCode, reason = 'ended_by_host') {
    if (!bluffLocation.isConnected()) return;
    
    bluffLocation.endGame({
      room: gameCode,
      user: this.currentPlayer?.name,
      reason: reason,
    });
    // Don't disconnect here - let the cleanup handle it
  }
  
  voteForSpy(gameCode, spyName, tentative = false) {
    if (!bluffLocation.isConnected()) return;
    
    bluffLocation.voteSpy({
      room: gameCode,
      user: this.currentPlayer?.name,
      vote_for: spyName,
      tentative,
    });
  }
  
  guessLocation(gameCode, locationGuess) {
    if (!bluffLocation.isConnected()) return;
    
    bluffLocation.guessLocation({
      room: gameCode,
      user: this.currentPlayer?.name,
      location: locationGuess,
    });
  }
  
  leaveGame(gameCode) {
    if (!bluffLocation.isConnected()) return;
    
    bluffLocation.leaveGame({
      room: gameCode,
      user: this.currentPlayer?.name,
    });
    // Don't disconnect here - let the cleanup handle it
  }

  updateTimeLimit(gameCode, minutes) {
    if (!bluffLocation.isConnected()) return;

    if (gameCode && minutes) {
      this.roomTimers[gameCode] = minutes;
    }

    bluffLocation.updateTimeLimit({
      room: gameCode,
      minutes,
      user: this.currentPlayer?.name,
    });
  }
  
  removeAllListeners() {
    // Remove BluffLocation socket-level event forwarders
    bluffLocation.removeAllListeners();
    // Also remove any custom event listeners
    this.eventListeners = {};
  }
  
  syncState(gameCode) {
    if (!bluffLocation.isConnected()) return;
    
    bluffLocation.syncState({
      room: gameCode,
      user: this.currentPlayer?.name,
    });
  }
  
  disconnect() {
    bluffLocation.disconnect();
    this.connectionStatus = 'disconnected';
    this.currentGame = null;
    this.currentPlayer = null;
  }
  
}

export default GameManager.getInstance();
