import React from 'react';
import { router } from 'expo-router';
import { ImageBackground, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { useFonts, Cinzel_700Bold } from '@expo-google-fonts/cinzel';
import { useFonts as usePoppinsFonts, Poppins_600SemiBold } from '@expo-google-fonts/poppins';
import { useGameStore } from '../../lib/hooks/useGameState';

export default function LobbyScreen() {
  const game = useGameStore((s) => s.game);
  const resetGame = useGameStore((s) => s.actions.resetGame);

  const [cinzelLoaded] = useFonts({
    Cinzel_700Bold,
  });

  const [poppinsLoaded] = usePoppinsFonts({
    Poppins_600SemiBold,
  });

  if (!cinzelLoaded || !poppinsLoaded) {
    return null;
  }

  const startNewGame = () => {
    if (game && !game.isGameOver) {
      // Ask for confirmation if there's an active game
      if (global.confirm && !global.confirm('Start a new game? Current game will be lost.')) {
        return;
      }
    }
    resetGame();
    router.push('/game-setup');
  };

  const continueGame = () => {
    router.push('/game');
  };

  const openHelp = () => {
    router.push('/help');
  };

  return (
    <ImageBackground
      source={require('../../assets/MainScreensBackground.png')}
      style={styles.container}
      resizeMode="cover"
    >
      <View style={styles.overlay}>
        <TouchableOpacity style={styles.helpButton} onPress={openHelp}>
          <Text style={styles.helpButtonText}>❓ How to Play</Text>
        </TouchableOpacity>

        <View style={styles.content}>
          <Text style={[styles.title, { fontFamily: 'Cinzel_700Bold' }]}>
            ENCRYPTED
          </Text>
          
          <Text style={styles.subtitle}>
            A game of words, clues, and deduction
          </Text>

          <View style={styles.buttonContainer}>
            <TouchableOpacity style={styles.button} onPress={startNewGame}>
              <Text style={[styles.buttonText, { fontFamily: 'Poppins_600SemiBold' }]}>
                {game ? 'New Game' : 'Start Game'}
              </Text>
            </TouchableOpacity>

            {game && !game.isGameOver && (
              <TouchableOpacity style={[styles.button, styles.secondaryButton]} onPress={continueGame}>
                <Text style={[styles.buttonText, { fontFamily: 'Poppins_600SemiBold' }]}>
                  Continue Game
                </Text>
              </TouchableOpacity>
            )}
          </View>
        </View>
      </View>
    </ImageBackground>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    width: '100%',
    height: '100%',
  },
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  helpButton: {
    position: 'absolute',
    top: 50,
    right: 20,
    backgroundColor: 'rgba(74, 144, 226, 0.9)',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.5,
    shadowRadius: 4,
    elevation: 5,
  },
  helpButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
  },
  content: {
    justifyContent: 'center',
    alignItems: 'center',
    width: '100%',
    maxWidth: 400,
  },
  title: {
    fontSize: 56,
    fontWeight: 'bold',
    marginBottom: 20,
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 3, height: 3 },
    textShadowRadius: 8,
    letterSpacing: 4,
  },
  subtitle: {
    fontSize: 18,
    marginBottom: 60,
    color: '#E0E0E0',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 3,
  },
  buttonContainer: {
    width: '100%',
    gap: 16,
  },
  button: {
    backgroundColor: '#4A90E2',
    paddingVertical: 18,
    paddingHorizontal: 40,
    borderRadius: 12,
    width: '100%',
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
    fontSize: 22,
    fontWeight: '600',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
});


