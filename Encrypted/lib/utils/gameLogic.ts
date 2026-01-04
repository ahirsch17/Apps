import { WORD_LIST } from '../constants/words';
import type { GameCard, GameSettings, GameState, Player, TeamColor } from '../types/game';

type CardType = 'red' | 'blue' | 'neutral' | 'assassin';

function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export function initializeGame(players: Player[], settings: GameSettings, usedWords: Set<string> = new Set()): GameState {
  // Filter out already used words
  const availableWords = WORD_LIST.filter(word => !usedWords.has(word));
  
  if (availableWords.length < 25) {
    // If we don't have enough words, reset the pool
    usedWords.clear();
  }
  
  const selectedWords = shuffle(availableWords.length >= 25 ? availableWords : WORD_LIST).slice(0, 25);

  const cards: GameCard[] = selectedWords.map((word, i) => ({
    id: `card_${i}`,
    word,
    type: 'neutral',
    revealed: false,
    position: { row: Math.floor(i / 5), col: i % 5 },
  }));

  const cardTypes: CardType[] = shuffle([
    ...Array(9).fill('red'),
    ...Array(8).fill('blue'),
    'assassin',
    ...Array(7).fill('neutral'),
  ]) as CardType[];

  cards.forEach((c, i) => {
    c.type = cardTypes[i];
  });

  const firstTeam: TeamColor = Math.random() > 0.5 ? 'red' : 'blue';

  // Add selected words to used words
  selectedWords.forEach(word => usedWords.add(word));

  return {
    id: `game_${Date.now()}`,
    players,
    cards,
    currentTurn: firstTeam,
    clues: [],
    remaining: { red: 9, blue: 8 },
    isGameOver: false,
    settings,
    votes: {},
    currentGuesses: [],
    guessesRemaining: 0,
    usedWords,
    roundNumber: 1,
  };
}


