import React from 'react';
import { router } from 'expo-router';
import { ImageBackground, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { useFonts, Cinzel_700Bold } from '@expo-google-fonts/cinzel';
import { useFonts as usePoppinsFonts, Poppins_600SemiBold } from '@expo-google-fonts/poppins';
import { useGameStore } from '../../lib/hooks/useGameState';

export default function ResultsScreen() {
  const game = useGameStore((s) => s.game);

  const [cinzelLoaded] = useFonts({
    Cinzel_700Bold,
  });

  const [poppinsLoaded] = usePoppinsFonts({
    Poppins_600SemiBold,
  });

  if (!cinzelLoaded || !poppinsLoaded) {
    return null;
  }

  const redTeam = game?.players.filter((p) => p.team === 'red') || [];
  const blueTeam = game?.players.filter((p) => p.team === 'blue') || [];

  return (
    <ImageBackground
      source={require('../../assets/OtherScreensBackground.png')}
      style={styles.background}
      resizeMode="cover"
    >
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.overlay}>
          <View style={styles.content}>
            <Text style={[styles.title, { fontFamily: 'Cinzel_700Bold' }]}>Game Results</Text>

            {game ? (
              <>
                {game.isGameOver && (
                  <View style={styles.winnerCard}>
                    <Text style={styles.winnerLabel}>🎉 Winner 🎉</Text>
                    <Text
                      style={[
                        styles.winnerText,
                        game.winner === 'red' ? styles.redTeam : styles.blueTeam,
                      ]}
                    >
                      {game.winner?.toUpperCase()} TEAM
                    </Text>
                  </View>
                )}

                <View style={styles.scoreSection}>
                  <Text style={styles.sectionTitle}>Final Score</Text>
                  <View style={styles.scoreRow}>
                    <View style={[styles.scoreCard, styles.redCard]}>
                      <Text style={styles.scoreLabel}>Red Team</Text>
                      <Text style={styles.scoreValue}>{game.remaining.red}</Text>
                      <Text style={styles.scoreSubtext}>cards remaining</Text>
                    </View>
                    <View style={[styles.scoreCard, styles.blueCard]}>
                      <Text style={styles.scoreLabel}>Blue Team</Text>
                      <Text style={styles.scoreValue}>{game.remaining.blue}</Text>
                      <Text style={styles.scoreSubtext}>cards remaining</Text>
                    </View>
                  </View>
                </View>

                <View style={styles.teamSection}>
                  <Text style={styles.sectionTitle}>Teams</Text>
                  
                  <View style={styles.teamCard}>
                    <Text style={[styles.teamTitle, styles.redTeam]}>Red Team</Text>
                    {redTeam.map((player) => (
                      <View key={player.id} style={styles.playerRow}>
                        <Text style={styles.playerName}>{player.name}</Text>
                        <Text style={styles.playerRole}>
                          {player.role === 'encoder' ? '🔐 Encoder' : '🔍 Decoder'}
                        </Text>
                      </View>
                    ))}
                  </View>

                  <View style={styles.teamCard}>
                    <Text style={[styles.teamTitle, styles.blueTeam]}>Blue Team</Text>
                    {blueTeam.map((player) => (
                      <View key={player.id} style={styles.playerRow}>
                        <Text style={styles.playerName}>{player.name}</Text>
                        <Text style={styles.playerRole}>
                          {player.role === 'encoder' ? '🔐 Encoder' : '🔍 Decoder'}
                        </Text>
                      </View>
                    ))}
                  </View>
                </View>

                {game.clues.length > 0 && (
                  <View style={styles.clueSection}>
                    <Text style={styles.sectionTitle}>Clue History</Text>
                    <View style={styles.clueList}>
                      {game.clues
                        .slice()
                        .reverse()
                        .map((clue, idx) => (
                          <View key={`${clue.timestamp}_${idx}`} style={styles.clueItem}>
                            <Text style={[styles.clueTeam, clue.team === 'red' ? styles.redTeam : styles.blueTeam]}>
                              {clue.team.toUpperCase()}:
                            </Text>
                            <Text style={styles.clueText}>
                              {clue.word} ({clue.number})
                            </Text>
                          </View>
                        ))}
                    </View>
                  </View>
                )}
              </>
            ) : (
              <View style={styles.noGameCard}>
                <Text style={styles.noGameText}>No game data available</Text>
              </View>
            )}

            <View style={styles.buttonContainer}>
              {game && !game.isGameOver && (
                <TouchableOpacity style={styles.button} onPress={() => router.push('/game')}>
                  <Text style={[styles.buttonText, { fontFamily: 'Poppins_600SemiBold' }]}>
                    Back to Game
                  </Text>
                </TouchableOpacity>
              )}
              <TouchableOpacity style={[styles.button, styles.secondaryButton]} onPress={() => router.push('/')}>
                <Text style={[styles.buttonText, { fontFamily: 'Poppins_600SemiBold' }]}>
                  Back to Lobby
                </Text>
              </TouchableOpacity>
            </View>
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
  scrollContent: {
    flexGrow: 1,
  },
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
    padding: 20,
    paddingTop: 60,
  },
  content: {
    width: '100%',
    maxWidth: 600,
    alignSelf: 'center',
  },
  title: {
    fontSize: 42,
    fontWeight: 'bold',
    marginBottom: 30,
    color: '#FFFFFF',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 6,
  },
  winnerCard: {
    backgroundColor: 'rgba(255, 215, 0, 0.2)',
    borderRadius: 16,
    borderWidth: 3,
    borderColor: '#FFD700',
    padding: 20,
    alignItems: 'center',
    marginBottom: 25,
  },
  winnerLabel: {
    fontSize: 20,
    fontWeight: '700',
    color: '#FFD700',
    marginBottom: 10,
  },
  winnerText: {
    fontSize: 32,
    fontWeight: '900',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  redTeam: {
    color: '#FF6B6B',
  },
  blueTeam: {
    color: '#4DABF7',
  },
  scoreSection: {
    marginBottom: 25,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: '#E0E0E0',
    marginBottom: 15,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 3,
  },
  scoreRow: {
    flexDirection: 'row',
    gap: 12,
  },
  scoreCard: {
    flex: 1,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 12,
    padding: 16,
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
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 8,
  },
  scoreValue: {
    color: '#FFFFFF',
    fontSize: 36,
    fontWeight: '900',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 3,
  },
  scoreSubtext: {
    color: '#C0C0C0',
    fontSize: 12,
    marginTop: 4,
  },
  teamSection: {
    marginBottom: 25,
  },
  teamCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.25)',
  },
  teamTitle: {
    fontSize: 20,
    fontWeight: '800',
    marginBottom: 12,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  playerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 6,
    paddingHorizontal: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 8,
    marginBottom: 6,
  },
  playerName: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  playerRole: {
    color: '#E0E0E0',
    fontSize: 14,
    fontWeight: '500',
  },
  clueSection: {
    marginBottom: 25,
  },
  clueList: {
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.25)',
    gap: 8,
  },
  clueItem: {
    flexDirection: 'row',
    gap: 10,
    alignItems: 'center',
    paddingVertical: 4,
  },
  clueTeam: {
    fontSize: 14,
    fontWeight: '900',
    minWidth: 50,
  },
  clueText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
  },
  noGameCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 12,
    padding: 30,
    alignItems: 'center',
    marginBottom: 25,
  },
  noGameText: {
    color: '#E0E0E0',
    fontSize: 18,
    fontWeight: '600',
  },
  buttonContainer: {
    gap: 12,
    marginTop: 10,
    marginBottom: 40,
  },
  button: {
    backgroundColor: '#4A90E2',
    paddingVertical: 16,
    paddingHorizontal: 40,
    borderRadius: 12,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.6,
    shadowRadius: 8,
    elevation: 8,
  },
  secondaryButton: {
    backgroundColor: '#7B68EE',
  },
  buttonText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
});


