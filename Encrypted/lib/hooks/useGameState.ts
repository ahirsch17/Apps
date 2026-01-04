import { create } from 'zustand';
import type { Clue, GameSettings, GameState, Player, TeamColor } from '../types/game';
import { initializeGame } from '../utils/gameLogic';

interface GameStore {
  game: GameState | null;
  localPlayers: Player[];
  settings: Partial<GameSettings>;
  usedWords: Set<string>; // Track words across all games in session
  actions: {
    initializeNewGame: (players: Player[], settings: GameSettings) => void;
    submitClue: (clue: { word: string; number: number }) => void;
    toggleGuess: (cardId: string) => void; // Add/remove from current guesses
    submitGuesses: () => void; // Reveal the guessed cards
    voteCard: (playerId: string, cardId: string) => void;
    revealCard: (cardId: string) => void;
    endTurn: (team: TeamColor) => void;
    resetGame: () => void; // Clear everything for new game
    connectWebSocket: (url: string) => void;
    sendWebSocketEvent: (event: unknown) => void;
  };
}

export const useGameStore = create<GameStore>((set, get) => ({
  game: null,
  localPlayers: [],
  settings: {},
  usedWords: new Set<string>(),

  actions: {
    initializeNewGame: (players, settings) => {
      const usedWords = get().usedWords;
      const game = initializeGame(players, settings, usedWords);
      set({ game, localPlayers: players, settings, usedWords: game.usedWords });
    },

    submitClue: ({ word, number }) => {
      const game = get().game;
      if (!game || game.isGameOver) return;

      const clue: Clue = {
        word: word.toUpperCase(),
        number,
        team: game.currentTurn,
        timestamp: new Date().toISOString(),
      };

      set({
        game: {
          ...game,
          clues: [...game.clues, clue],
          guessesRemaining: number + 1, // Can guess number + 1 (bonus guess)
          currentGuesses: [], // Reset guesses for new clue
        },
      });
    },

    toggleGuess: (cardId) => {
      const game = get().game;
      if (!game || game.isGameOver) return;

      const currentGuesses = game.currentGuesses;
      const isSelected = currentGuesses.includes(cardId);

      set({
        game: {
          ...game,
          currentGuesses: isSelected
            ? currentGuesses.filter(id => id !== cardId)
            : [...currentGuesses, cardId],
        },
      });
    },

    submitGuesses: () => {
      const game = get().game;
      if (!game || game.isGameOver || game.currentGuesses.length === 0) return;

      // Reveal all guessed cards one by one
      let updatedGame = { ...game };
      let continueGuessing = true;

      for (const cardId of game.currentGuesses) {
        const card = updatedGame.cards.find(c => c.id === cardId);
        if (!card || card.revealed) continue;

        const cards = updatedGame.cards.map(c =>
          c.id === cardId ? { ...c, revealed: true } : c
        );

        // Update remaining counts
        const remaining = { ...updatedGame.remaining };
        if (card.type === 'red') remaining.red = Math.max(0, remaining.red - 1);
        if (card.type === 'blue') remaining.blue = Math.max(0, remaining.blue - 1);

        let isGameOver = false;
        let winner: TeamColor | undefined;

        // Check win/loss conditions
        if (card.type === 'assassin') {
          isGameOver = true;
          winner = updatedGame.currentTurn === 'red' ? 'blue' : 'red';
          continueGuessing = false;
        } else if (remaining.red === 0) {
          isGameOver = true;
          winner = 'red';
          continueGuessing = false;
        } else if (remaining.blue === 0) {
          isGameOver = true;
          winner = 'blue';
          continueGuessing = false;
        } else if (card.type !== updatedGame.currentTurn) {
          // Hit neutral or opponent's card - turn ends
          continueGuessing = false;
        }

        updatedGame = {
          ...updatedGame,
          cards,
          remaining,
          isGameOver,
          winner,
          guessesRemaining: Math.max(0, updatedGame.guessesRemaining - 1),
        };

        if (!continueGuessing || isGameOver) break;
      }

      // End turn if hit wrong card or out of guesses
      if (!continueGuessing || updatedGame.guessesRemaining === 0) {
        updatedGame = {
          ...updatedGame,
          currentTurn: updatedGame.currentTurn === 'red' ? 'blue' : 'red',
          currentGuesses: [],
          guessesRemaining: 0,
        };
      } else {
        // Clear guesses but keep turn
        updatedGame = {
          ...updatedGame,
          currentGuesses: [],
        };
      }

      set({ game: updatedGame });
    },

    voteCard: (playerId, cardId) => {
      const game = get().game;
      if (!game || game.isGameOver) return;

      const existing = game.votes[playerId] ?? [];
      const next = existing.includes(cardId)
        ? existing.filter((id) => id !== cardId)
        : [...existing, cardId];

      set({
        game: {
          ...game,
          votes: { ...game.votes, [playerId]: next },
        },
      });
    },

    revealCard: (cardId) => {
      const game = get().game;
      if (!game || game.isGameOver) return;

      const card = game.cards.find((c) => c.id === cardId);
      if (!card || card.revealed) return;

      const cards = game.cards.map((c) => (c.id === cardId ? { ...c, revealed: true } : c));

      // Update remaining counts & detect game over (minimal ruleset for now)
      const remaining = { ...game.remaining };
      if (card.type === 'red') remaining.red = Math.max(0, remaining.red - 1);
      if (card.type === 'blue') remaining.blue = Math.max(0, remaining.blue - 1);

      let isGameOver: boolean = game.isGameOver;
      let winner: TeamColor | undefined = game.winner;

      if (card.type === 'assassin') {
        isGameOver = true;
        winner = game.currentTurn === 'red' ? 'blue' : 'red';
      } else if (remaining.red === 0) {
        isGameOver = true;
        winner = 'red';
      } else if (remaining.blue === 0) {
        isGameOver = true;
        winner = 'blue';
      }

      set({
        game: {
          ...game,
          cards,
          remaining,
          isGameOver,
          winner,
        },
      });
    },

    endTurn: (_team) => {
      const game = get().game;
      if (!game || game.isGameOver) return;

      set({
        game: {
          ...game,
          currentTurn: game.currentTurn === 'red' ? 'blue' : 'red',
          votes: {},
          currentGuesses: [],
          guessesRemaining: 0,
        },
      });
    },

    resetGame: () => {
      set({
        game: null,
        localPlayers: [],
        settings: {},
        usedWords: new Set<string>(),
      });
    },

    connectWebSocket: (url: string) => {
      // placeholder for future WebSocket implementation
      // eslint-disable-next-line no-console
      console.log('WebSocket would connect to:', url);
    },

    sendWebSocketEvent: (event: unknown) => {
      // placeholder for future WebSocket implementation
      // eslint-disable-next-line no-console
      console.log('WebSocket event:', event);
    },
  },
}));


