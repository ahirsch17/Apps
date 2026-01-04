import React from 'react';
import { router } from 'expo-router';
import { ImageBackground, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { useFonts, Cinzel_700Bold } from '@expo-google-fonts/cinzel';
import { useFonts as usePoppinsFonts, Poppins_600SemiBold } from '@expo-google-fonts/poppins';

export default function HelpScreen() {
  const [cinzelLoaded] = useFonts({
    Cinzel_700Bold,
  });

  const [poppinsLoaded] = usePoppinsFonts({
    Poppins_600SemiBold,
  });

  if (!cinzelLoaded || !poppinsLoaded) {
    return null;
  }

  return (
    <ImageBackground
      source={require('../assets/OtherScreensBackground.png')}
      style={styles.background}
      resizeMode="cover"
    >
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.overlay}>
          <View style={styles.content}>
            <Text style={[styles.title, { fontFamily: 'Cinzel_700Bold' }]}>How to Play</Text>

            <View style={styles.section}>
              <Text style={styles.sectionTitle}>🎯 Objective</Text>
              <Text style={styles.text}>
                Be the first team to find all your secret words on the 5×5 grid. But beware of the
                assassin card - it means instant defeat!
              </Text>
            </View>

            <View style={styles.section}>
              <Text style={styles.sectionTitle}>👥 Teams & Roles</Text>
              <Text style={styles.text}>
                <Text style={styles.bold}>Red Team vs Blue Team</Text>
              </Text>
              <Text style={styles.text}>
                Each team has:
              </Text>
              <Text style={styles.bulletText}>• <Text style={styles.bold}>Encoders</Text> 🔐 - Give clues (can see the secret cards)</Text>
              <Text style={styles.bulletText}>• <Text style={styles.bold}>Decoders</Text> 🔍 - Guess words (cannot see secrets)</Text>
            </View>

            <View style={styles.section}>
              <Text style={styles.sectionTitle}>🎮 How to Play</Text>
              <Text style={styles.subheading}>Encoders:</Text>
              <Text style={styles.bulletText}>1. Look at the board - you can see your team's cards</Text>
              <Text style={styles.bulletText}>2. Give a ONE-WORD clue + a number</Text>
              <Text style={styles.bulletText}>3. Example: "SPACE 3" (3 cards relate to space)</Text>
              <Text style={styles.bulletText}>4. The number tells how many cards match</Text>

              <Text style={styles.subheading}>Decoders:</Text>
              <Text style={styles.bulletText}>1. Discuss which cards might match the clue</Text>
              <Text style={styles.bulletText}>2. Tap cards to reveal them</Text>
              <Text style={styles.bulletText}>3. Keep guessing if you find your team's cards</Text>
              <Text style={styles.bulletText}>4. Your turn ends if you hit neutral or enemy cards</Text>
            </View>

            <View style={styles.section}>
              <Text style={styles.sectionTitle}>🃏 Card Types</Text>
              <Text style={styles.cardType}>
                <Text style={[styles.bold, styles.redText]}>Red Cards (9)</Text> - Red team's words
              </Text>
              <Text style={styles.cardType}>
                <Text style={[styles.bold, styles.blueText]}>Blue Cards (8)</Text> - Blue team's words
              </Text>
              <Text style={styles.cardType}>
                <Text style={styles.bold}>Neutral Cards (7)</Text> - End your turn
              </Text>
              <Text style={styles.cardType}>
                <Text style={[styles.bold, styles.assassinText]}>Assassin Card (1)</Text> - INSTANT LOSS! 💀
              </Text>
            </View>

            <View style={styles.section}>
              <Text style={styles.sectionTitle}>🏆 Winning</Text>
              <Text style={styles.bulletText}>✓ Find all your team's cards before the other team</Text>
              <Text style={styles.bulletText}>✗ Hit the assassin = you lose immediately</Text>
            </View>

            <View style={styles.tipBox}>
              <Text style={styles.tipTitle}>💡 Pro Tips</Text>
              <Text style={styles.tipText}>• Encoders: Connect multiple safe cards</Text>
              <Text style={styles.tipText}>• Decoders: Discuss before tapping!</Text>
              <Text style={styles.tipText}>• Sometimes fewer guesses is safer</Text>
              <Text style={styles.tipText}>• Watch out for words that could be assassin!</Text>
            </View>

            <TouchableOpacity style={styles.button} onPress={() => router.back()}>
              <Text style={[styles.buttonText, { fontFamily: 'Poppins_600SemiBold' }]}>
                Got It!
              </Text>
            </TouchableOpacity>
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
    backgroundColor: 'rgba(0, 0, 0, 0.65)',
    padding: 20,
    paddingTop: 60,
    paddingBottom: 40,
  },
  content: {
    width: '100%',
    maxWidth: 600,
    alignSelf: 'center',
  },
  title: {
    fontSize: 42,
    fontWeight: 'bold',
    marginBottom: 25,
    color: '#FFFFFF',
    textAlign: 'center',
    textShadowColor: 'rgba(0, 0, 0, 0.9)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 6,
  },
  section: {
    backgroundColor: 'rgba(255, 255, 255, 0.12)',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  sectionTitle: {
    fontSize: 22,
    fontWeight: '800',
    color: '#FFD700',
    marginBottom: 12,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 3,
  },
  text: {
    fontSize: 16,
    color: '#E8E8E8',
    lineHeight: 24,
    marginBottom: 8,
  },
  bold: {
    fontWeight: '700',
  },
  subheading: {
    fontSize: 18,
    fontWeight: '700',
    color: '#FFFFFF',
    marginTop: 12,
    marginBottom: 8,
  },
  bulletText: {
    fontSize: 15,
    color: '#E0E0E0',
    lineHeight: 22,
    marginBottom: 6,
    paddingLeft: 8,
  },
  cardType: {
    fontSize: 16,
    color: '#E8E8E8',
    lineHeight: 26,
    marginBottom: 6,
  },
  redText: {
    color: '#FF6B6B',
  },
  blueText: {
    color: '#4DABF7',
  },
  assassinText: {
    color: '#FF4444',
  },
  tipBox: {
    backgroundColor: 'rgba(74, 144, 226, 0.2)',
    borderRadius: 12,
    padding: 16,
    marginTop: 8,
    marginBottom: 20,
    borderWidth: 2,
    borderColor: 'rgba(74, 144, 226, 0.4)',
  },
  tipTitle: {
    fontSize: 20,
    fontWeight: '800',
    color: '#FFD700',
    marginBottom: 10,
    textAlign: 'center',
  },
  tipText: {
    fontSize: 15,
    color: '#E8E8E8',
    lineHeight: 22,
    marginBottom: 4,
  },
  button: {
    backgroundColor: '#4A90E2',
    paddingVertical: 16,
    paddingHorizontal: 40,
    borderRadius: 12,
    alignItems: 'center',
    marginTop: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.6,
    shadowRadius: 8,
    elevation: 8,
  },
  buttonText: {
    fontSize: 20,
    fontWeight: '600',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
});

