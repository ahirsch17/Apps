import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

type Props = {
  word: string;
  size: number;
  borderColor: string;
  revealed: boolean;
  onPress: () => void;
  voteCount?: number;
  isSelected?: boolean;
};

const colorMap: Record<string, string> = {
  red: '#FF6B6B',
  blue: '#4DABF7',
  black: '#2C2C2C',
  '#cdb79e': '#D4B896',
  '#777': '#888888',
};

export default function WordCard({ word, size, borderColor, revealed, onPress, voteCount = 0, isSelected = false }: Props) {
  const backgroundColor = revealed 
    ? (colorMap[borderColor] || borderColor) 
    : isSelected 
    ? '#FFD700' 
    : '#F5F1E8';
  const textColor = revealed && borderColor !== '#cdb79e' && borderColor !== '#777' ? '#FFFFFF' : '#1a1a1a';

  return (
    <Pressable
      onPress={onPress}
      style={[
        styles.card,
        {
          width: size,
          height: size,
          borderColor: isSelected ? '#FFD700' : (colorMap[borderColor] || borderColor),
          backgroundColor,
          borderWidth: isSelected ? 4 : 3,
        },
      ]}
    >
      <View style={styles.inner}>
        <Text numberOfLines={3} style={[styles.word, { color: textColor }, revealed && styles.revealedWord]}>
          {word}
        </Text>
        {voteCount > 0 && !revealed ? (
          <View style={styles.votePill}>
            <Text style={styles.voteText}>👍 {voteCount}</Text>
          </View>
        ) : null}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 3,
    borderRadius: 8,
    padding: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 3,
    elevation: 3,
  },
  inner: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  word: {
    fontSize: 11,
    fontWeight: '800',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.1)',
    textShadowOffset: { width: 0.5, height: 0.5 },
    textShadowRadius: 1,
  },
  revealedWord: {
    opacity: 0.9,
  },
  votePill: {
    position: 'absolute',
    right: 2,
    bottom: 2,
    backgroundColor: 'rgba(0, 0, 0, 0.85)',
    paddingHorizontal: 5,
    paddingVertical: 2,
    borderRadius: 10,
  },
  voteText: {
    color: '#fff',
    fontSize: 9,
    fontWeight: '800',
  },
});


