export type TeamColor = 'red' | 'blue';
export type CardType = TeamColor | 'neutral' | 'assassin';

export type PlayerRole = 'encoder' | 'decoder';

export interface Player {
  id: string;
  name: string;
  team: TeamColor;
  role: PlayerRole;
  isHost: boolean;
}

export interface GameCard {
  id: string;
  word: string;
  type: CardType;
  revealed: boolean;
  position: { row: number; col: number };
}

export interface GameSettings {
  useTimer: boolean;
  encoderTimer: number; // seconds
  decoderTimer: number; // seconds
  teamAssignment: 'random' | 'choose' | 'rotate';
  roleAssignment: 'random' | 'choose' | 'rotate';
}

export interface Clue {
  word: string;
  number: number;
  team: TeamColor;
  timestamp: string; // ISO for easy serialization later (WebSocket)
}

export interface GameState {
  id: string;
  players: Player[];
  cards: GameCard[];
  currentTurn: TeamColor;
  clues: Clue[];
  remaining: {
    red: number;
    blue: number;
  };
  isGameOver: boolean;
  winner?: TeamColor;
  settings: GameSettings;
  votes: Record<string, string[]>; // playerId -> array of cardIds
  currentGuesses: string[]; // cardIds selected by team (not yet revealed)
  guessesRemaining: number; // how many guesses left this turn
  usedWords: Set<string>; // track words used to avoid reuse
  roundNumber: number;
}

export type GameEvent =
  | { type: 'JOIN_GAME'; payload: { player: Player } }
  | { type: 'START_GAME'; payload: { settings: GameSettings } }
  | { type: 'SUBMIT_CLUE'; payload: { clue: Clue } }
  | { type: 'VOTE_CARD'; payload: { playerId: string; cardId: string } }
  | { type: 'SUBMIT_GUESSES'; payload: { team: TeamColor } }
  | { type: 'END_TURN'; payload: { team: TeamColor } };


