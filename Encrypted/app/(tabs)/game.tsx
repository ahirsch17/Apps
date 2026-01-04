import React from 'react';
import { router } from 'expo-router';
import { ImageBackground, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { useFonts, Poppins_600SemiBold } from '@expo-google-fonts/poppins';
import ClueInput from '../../components/ClueInput';
import GameBoard from '../../components/GameBoard';
import { useGameStore } from '../../lib/hooks/useGameState';

export default function GameScreen() {
  const game = useGameStore((s) => s.game);
  const { revealCard, submitClue, endTurn, toggleGuess, submitGuesses } = useGameStore((s) => s.actions);

  const [poppinsLoaded] = useFonts({
    Poppins_600SemiBold,
  });

  if (!poppinsLoaded) {
    return null;
  }

  if (!game) {
    return (
      <ImageBackground
        source={require('../../assets/OtherScreensBackground.png')}
        style={styles.background}
        resizeMode="cover"
      >
        <View style={styles.overlay}>
          <View style={styles.centerContent}>
            <Text style={styles.title}>No active game</Text>
            <TouchableOpacity style={styles.button} onPress={() => router.push('/')}>
              <Text style={[styles.buttonText, { fontFamily: 'Poppins_600SemiBold' }]}>
                Back to Lobby
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </ImageBackground>
    );
  }

  const me = game.players.find((p) => p.isHost) ?? game.players[0];
  const myTurn = game.currentTurn === me.team;
  const isEncoder = me.role === 'encoder';
  const isDecoder = me.role === 'decoder';
  const hasClue = game.clues.length > 0 && game.clues[game.clues.length - 1].team === me.team;
  const canGuess = isDecoder && myTurn && hasClue && game.guessesRemaining > 0;

  const openHelp = () => {
    router.push('/help');
  };

  return (
    <ImageBackground
      source={require('../../assets/OtherScreensBackground.png')}
      style={styles.background}
      resizeMode="cover"
    >
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.overlay}>
          <TouchableOpacity style={styles.helpButton} onPress={openHelp}>
            <Text style={styles.helpButtonText}>❓</Text>
          </TouchableOpacity>

          <View style={styles.header}>
            <View style={styles.headerLeft}>
              <Text style={styles.turnText}>
                Current Turn: <Text style={[styles.turnTeam, game.currentTurn === 'red' ? styles.redTeam : styles.blueTeam]}>
                  {game.currentTurn.toUpperCase()}
                </Text>
              </Text>
              <Text style={styles.meta}>
                You: {me.name} • {me.team.toUpperCase()} • {me.role === 'encoder' ? 'Encoder' : 'Decoder'}
              </Text>
            </View>
            
            {game.isGameOver && (
              <TouchableOpacity style={styles.resultsButton} onPress={() => router.push('/results')}>
                <Text style={[styles.resultsButtonText, { fontFamily: 'Poppins_600SemiBold' }]}>
                  Results
                </Text>
              </TouchableOpacity>
            )}
          </View>

          <View style={styles.scoreRow}>
            <View style={[styles.scoreCard, styles.redCard]}>
              <Text style={styles.scoreLabel}>Red Team</Text>
              <Text style={styles.scoreValue}>{game.remaining.red}</Text>
            </View>
            <View style={[styles.scoreCard, styles.blueCard]}>
              <Text style={styles.scoreLabel}>Blue Team</Text>
              <Text style={styles.scoreValue}>{game.remaining.blue}</Text>
            </View>
          </View>

          <GameBoard
            cards={game.cards}
            onCardPress={canGuess ? toggleGuess : () => {}}
            playerRole={me.role}
            playerTeam={me.team}
            votes={game.votes}
            currentGuesses={game.currentGuesses}
          />

          {canGuess && game.currentGuesses.length > 0 && (
            <View style={styles.guessPanel}>
              <Text style={styles.guessPanelText}>
                Selected {game.currentGuesses.length} card(s) • {game.guessesRemaining} guess(es) remaining
              </Text>
              <TouchableOpacity style={styles.submitGuessButton} onPress={submitGuesses}>
                <Text style={[styles.submitGuessButtonText, { fontFamily: 'Poppins_600SemiBold' }]}>
                  Reveal Selected Cards
                </Text>
              </TouchableOpacity>
            </View>
          )}

          <View style={styles.panel}>
            <Text style={styles.panelTitle}>
              {isEncoder ? 'Give Clue' : 'Current Clue'}
            </Text>
            {isEncoder ? (
              <ClueInput 
                onSubmit={submitClue} 
                disabled={!myTurn || game.isGameOver}
                boardWords={game.cards.map(c => c.word)}
              />
            ) : (
              <View style={styles.clueDisplay}>
                {game.clues.length > 0 && game.clues[game.clues.length - 1].team === me.team ? (
                  <>
                    <Text style={styles.currentClue}>
                      {game.clues[game.clues.length - 1].word} {game.clues[game.clues.length - 1].number}
                    </Text>
                    {canGuess && (
                      <Text style={styles.clueHint}>
                        Tap cards to select, then submit your guesses
                      </Text>
                    )}
                  </>
                ) : (
                  <Text style={styles.noClue}>Waiting for Encoder's clue...</Text>
                )}
              </View>
            )}
            
            {game.isGameOver ? (
              <View style={styles.gameOverPanel}>
                <Text style={styles.gameOverText}>
                  🎉 Game Over! 🎉
                </Text>
                <Text style={styles.winnerText}>
                  Winner: <Text style={game.winner === 'red' ? styles.redTeam : styles.blueTeam}>
                    {game.winner?.toUpperCase()}
                  </Text> TEAM
                </Text>
                <TouchableOpacity style={styles.button} onPress={() => router.push('/')}>
                  <Text style={[styles.buttonText, { fontFamily: 'Poppins_600SemiBold' }]}>
                    Back to Lobby
                  </Text>
                </TouchableOpacity>
              </View>
            ) : (
              <View style={styles.panelFooter}>
                <TouchableOpacity 
                  style={[styles.endTurnButton, !myTurn && styles.buttonDisabled]} 
                  onPress={() => endTurn(game.currentTurn)}
                  disabled={!myTurn}
                >
                  <Text style={[styles.endTurnButtonText, { fontFamily: 'Poppins_600SemiBold' }]}>
                    {isEncoder && !hasClue ? 'Skip Turn' : 'End Turn'}
                  </Text>
                </TouchableOpacity>
              </View>
            )}
          </View>

          <View style={styles.panel}>
            <Text style={styles.panelTitle}>Clue History</Text>
            {game.clues.length === 0 ? (
              <Text style={styles.empty}>No clues yet. Encoders start giving clues!</Text>
            ) : (
              <View style={styles.clueList}>
                {game.clues
                  .slice()
                  .reverse()
                  .slice(0, 10)
                  .map((c, idx) => (
                    <View key={`${c.timestamp}_${idx}`} style={styles.clueItem}>
                      <Text style={[styles.clueTeam, c.team === 'red' ? styles.redTeam : styles.blueTeam]}>
                        {c.team.toUpperCase()}:
                      </Text>
                      <Text style={styles.clueText}>
                        {c.word} ({c.number})
                      </Text>
                    </View>
                  ))}
              </View>
            )}
          </View>
        </View>
      </ScrollView>
    </ImageBackground>
  );
}

const styles = StyleSheet.create({
  background: {
    flex: 1,
    width: '100%',
    height: '100%',
  },
  container: {
    flexGrow: 1,
  },
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    padding: 12,
    paddingTop: 60,
    gap: 12,
  },
  helpButton: {
    position: 'absolute',
    top: 10,
    right: 12,
    backgroundColor: 'rgba(74, 144, 226, 0.9)',
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.5,
    shadowRadius: 4,
    elevation: 5,
    zIndex: 100,
  },
  helpButtonText: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '700',
  },
  centerContent: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 20,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 6,
  },
  headerLeft: {
    flex: 1,
    gap: 4,
  },
  turnText: {
    color: '#fff',
    fontSize: 20,
    fontWeight: '700',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 3,
  },
  turnTeam: {
    fontSize: 22,
    fontWeight: '900',
  },
  redTeam: {
    color: '#FF6B6B',
  },
  blueTeam: {
    color: '#4DABF7',
  },
  meta: {
    color: '#E0E0E0',
    fontSize: 14,
    fontWeight: '600',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  resultsButton: {
    backgroundColor: '#7B68EE',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 8,
  },
  resultsButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  scoreRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
    paddingHorizontal: 6,
  },
  scoreCard: {
    flex: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 12,
    padding: 12,
    alignItems: 'center',
    borderWidth: 2,
  },
  redCard: {
    borderColor: 'rgba(255, 107, 107, 0.5)',
  },
  blueCard: {
    borderColor: 'rgba(77, 171, 247, 0.5)',
  },
  scoreLabel: {
    color: '#E0E0E0',
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 4,
  },
  scoreValue: {
    color: '#FFFFFF',
    fontSize: 28,
    fontWeight: '900',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 3,
  },
  title: {
    color: '#fff',
    fontSize: 24,
    fontWeight: '900',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  panel: {
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.25)',
    paddingVertical: 12,
  },
  panelTitle: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '700',
    paddingHorizontal: 14,
    paddingBottom: 8,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  panelFooter: {
    paddingHorizontal: 14,
    paddingTop: 8,
  },
  endTurnButton: {
    backgroundColor: '#28A745',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
    alignItems: 'center',
  },
  endTurnButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  buttonDisabled: {
    backgroundColor: 'rgba(150, 150, 150, 0.5)',
  },
  gameOverPanel: {
    paddingHorizontal: 14,
    paddingTop: 8,
    gap: 12,
    alignItems: 'center',
  },
  gameOverText: {
    color: '#FFD700',
    fontSize: 24,
    fontWeight: '900',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  winnerText: {
    color: '#FFFFFF',
    fontSize: 20,
    fontWeight: '700',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 3,
  },
  button: {
    backgroundColor: '#4A90E2',
    paddingVertical: 12,
    paddingHorizontal: 32,
    borderRadius: 8,
    marginTop: 8,
  },
  buttonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
  empty: {
    color: '#E0E0E0',
    paddingHorizontal: 14,
    paddingBottom: 8,
    fontSize: 14,
    fontStyle: 'italic',
  },
  clueList: {
    gap: 8,
    paddingHorizontal: 14,
    paddingBottom: 8,
  },
  clueItem: {
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
  },
  clueTeam: {
    fontSize: 14,
    fontWeight: '900',
  },
  clueText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  guessPanel: {
    backgroundColor: 'rgba(74, 144, 226, 0.3)',
    borderRadius: 12,
    padding: 14,
    borderWidth: 2,
    borderColor: 'rgba(74, 144, 226, 0.6)',
    alignItems: 'center',
    gap: 10,
  },
  guessPanelText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '700',
    textAlign: 'center',
  },
  submitGuessButton: {
    backgroundColor: '#28A745',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
  },
  submitGuessButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  clueDisplay: {
    paddingHorizontal: 14,
    paddingVertical: 12,
    alignItems: 'center',
    gap: 8,
  },
  currentClue: {
    color: '#FFD700',
    fontSize: 24,
    fontWeight: '900',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 3,
  },
  clueHint: {
    color: '#E0E0E0',
    fontSize: 13,
    fontStyle: 'italic',
    textAlign: 'center',
  },
  noClue: {
    color: '#C0C0C0',
    fontSize: 15,
    fontStyle: 'italic',
  },
});


