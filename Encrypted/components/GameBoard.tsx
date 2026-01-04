import React from 'react';
import { Dimensions, StyleSheet, View } from 'react-native';
import WordCard from './WordCard';
import type { GameCard, PlayerRole, TeamColor } from '../lib/types/game';

type Props = {
  cards: GameCard[];
  onCardPress: (cardId: string) => void;
  playerRole: PlayerRole;
  playerTeam: TeamColor;
  votes?: Record<string, string[]>;
  currentGuesses?: string[];
};

const GRID_SIZE = 5;
const { width } = Dimensions.get('window');
const CARD_SIZE = (width - 40) / GRID_SIZE;

export default function GameBoard({ cards, onCardPress, playerRole, playerTeam, votes, currentGuesses = [] }: Props) {
  const getCardBorderColor = (card: GameCard) => {
    // Revealed cards show their true color to everyone
    if (card.revealed) {
      return card.type === 'assassin' ? 'black' : card.type;
    }

    // DECODERS: Only see neutral color for unrevealed cards (like real Codenames)
    if (playerRole === 'decoder') {
      return '#cdb79e';
    }

    // ENCODERS: See all card colors (the key card)
    if (card.type === playerTeam) return playerTeam;
    if (card.type === 'assassin') return 'black';
    if (card.type === 'neutral') return '#cdb79e';
    return '#777'; // opponent cards
  };

  const voteCountFor = (cardId: string) => {
    if (!votes) return 0;
    return Object.values(votes).filter((arr) => arr.includes(cardId)).length;
  };

  return (
    <View style={styles.container}>
      {cards.map((card) => (
        <WordCard
          key={card.id}
          word={card.word}
          size={CARD_SIZE}
          borderColor={getCardBorderColor(card)}
          revealed={card.revealed}
          onPress={() => onCardPress(card.id)}
          voteCount={voteCountFor(card.id)}
          isSelected={currentGuesses.includes(card.id)}
        />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    padding: 10,
    gap: 4,
  },
});


