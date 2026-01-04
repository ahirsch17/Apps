import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, ImageBackground } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useFonts, Cinzel_600SemiBold, Cinzel_700Bold } from '@expo-google-fonts/cinzel';
import { useFonts as usePoppinsFonts, Poppins_400Regular, Poppins_600SemiBold } from '@expo-google-fonts/poppins';

export default function RulesView() {
  const navigation = useNavigation();
  
  const [cinzelLoaded] = useFonts({
    Cinzel_600SemiBold,
    Cinzel_700Bold,
  });
  
  const [poppinsLoaded] = usePoppinsFonts({
    Poppins_400Regular,
    Poppins_600SemiBold,
  });
  
  return (
    <ImageBackground 
      source={require('../../assets/background.png')} 
      style={styles.container}
      resizeMode="cover"
    >
      {/* Dark vignette overlay */}
      <View style={styles.vignette} />
      
      {/* Main content overlay */}
      <View style={styles.contentOverlay}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity
            style={styles.backButton}
            onPress={() => navigation.goBack()}
            activeOpacity={0.7}
          >
            <Text style={styles.backButtonText}>←</Text>
          </TouchableOpacity>
          <Text style={[styles.title, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>
            Rules
          </Text>
          <View style={styles.backButtonPlaceholder} />
        </View>
        
        {/* Scrollable content */}
        <ScrollView 
          style={styles.scrollView}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.rulesCard}>
            <Text style={[styles.sectionTitle, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>
              The Bluff Protocol
            </Text>
            <Text style={[styles.bodyText, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>
              Intelligence agencies use "The Bluff Protocol" to test operatives. Agents are dropped into unfamiliar locations and must either <Text style={styles.highlightText}>identify their location</Text> or <Text style={styles.highlightText}>remain undetected</Text> until extraction time.{'\n\n'}
              Meanwhile, <Text style={styles.residentText}>Residents</Text> (locals) must expose the <Text style={styles.spyText}>Spy</Text> before they complete their mission.
            </Text>
            
            <Text style={[styles.sectionTitle, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>
              Setup
            </Text>
            <Text style={[styles.bodyText, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>
              <Text style={styles.boldText}>3-8 players.</Text> One player is secretly the <Text style={styles.spyText}>Spy</Text>, all others are <Text style={styles.residentText}>Residents</Text>. Residents see the same location (e.g., "Airport", "Hospital"). The <Text style={styles.spyText}>Spy</Text> sees only "You are the SPY!" and must figure out the location.
            </Text>
            
            <Text style={[styles.sectionTitle, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>
              Mission Objectives
            </Text>
            <Text style={[styles.subsectionTitle, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
              <Text style={styles.spyText}>Spy:</Text>
            </Text>
            <Text style={[styles.bodyText, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>
              Hold down a location to guess. If correct, <Text style={styles.spyText}>Spy wins!</Text> If wrong, <Text style={styles.residentText}>Residents win!</Text> Or survive until time runs out.
            </Text>
            <Text style={[styles.subsectionTitle, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
              <Text style={styles.residentText}>Residents:</Text>
            </Text>
            <Text style={[styles.bodyText, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>
              Enable the <Text style={styles.actionText}>Vote</Text> button. When all players enable it, voting begins. Majority vote determines the outcome. If tied, <Text style={styles.spyText}>Spy wins</Text> automatically.
            </Text>
            
            <Text style={[styles.sectionTitle, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>
              How to Play
            </Text>
            <Text style={[styles.bodyText, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>
              <Text style={styles.boldText}>1. Location Reveal</Text>{'\n'}
              All players check their devices. <Text style={styles.residentText}>Residents</Text> see the location, <Text style={styles.spyText}>Spy</Text> sees only their role.{'\n\n'}
              
              <Text style={styles.boldText}>2. Question Phase</Text>{'\n'}
              A player is randomly selected to be the first questioner. The next questioner will be the person to their left (clockwise) and so on. When it is your turn to question, you can ask <Text style={styles.highlightText}>ANY player</Text> a question about the location. Continue until voting begins or time expires.{'\n\n'}
              
              <Text style={styles.boldText}>3. Voting Phase</Text>{'\n'}
              Any player can enable the <Text style={styles.actionText}>Vote</Text> button. When <Text style={styles.highlightText}>all players</Text> enable it, voting mode begins. No more questions can be asked once you enter this mode. The spy can still try to guess the location before you vote for them in this mode. Timer continues. Majority vote wins. If tied, Spy wins automatically so last voter should avoid creating a tie.{'\n\n'}
              
              <Text style={styles.boldText}>4. Spy Location Guess</Text>{'\n'}
              The <Text style={styles.spyText}>Spy</Text> can <Text style={styles.actionText}>hold down</Text> any location card to guess. Confirm when prompted. <Text style={styles.warningText}>One guess per game. Use it wisely!</Text>
            </Text>
            
            <Text style={[styles.sectionTitle, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>
              Strategy Tips
            </Text>
            <Text style={[styles.subsectionTitle, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
              <Text style={styles.residentText}>Residents:</Text>
            </Text>
            <Text style={[styles.bodyText, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>
              Ask location-specific questions. Watch for vague answers. Don't reveal the location too early. Notice players who avoid specifics.
            </Text>
            <Text style={[styles.subsectionTitle, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
              <Text style={styles.spyText}>Spy:</Text>
            </Text>
            <Text style={[styles.bodyText, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>
              Ask broad questions. Give vague but plausible answers. Listen carefully for location clues. Blend in - don't be too quiet or too talkative.
            </Text>
            
            <View style={styles.footer}>
              <Text style={[styles.footerText, poppinsLoaded && { fontFamily: 'Poppins_400Regular' }]}>
                <Text style={styles.boldText}>Game Length:</Text> Typically 5-10 minutes per round
              </Text>
            </View>
          </View>
        </ScrollView>
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
  vignette: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  contentOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.3)',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingTop: 50,
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  backButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(20, 20, 30, 0.8)',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  backButtonText: {
    fontSize: 24,
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  backButtonPlaceholder: {
    width: 44,
  },
  title: {
    fontSize: 42,
    fontWeight: '700',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 1)',
    textShadowOffset: { width: 3, height: 3 },
    textShadowRadius: 8,
    letterSpacing: 1,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingBottom: 40,
  },
  rulesCard: {
    backgroundColor: 'rgba(20, 20, 30, 0.75)',
    borderRadius: 16,
    padding: 24,
    marginTop: 10,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.5,
    shadowRadius: 8,
    elevation: 8,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: '#FFFFFF',
    marginTop: 24,
    marginBottom: 12,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
    letterSpacing: 0.5,
  },
  subsectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#D4A574',
    marginTop: 16,
    marginBottom: 8,
    textShadowColor: 'rgba(0, 0, 0, 0.6)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  bodyText: {
    fontSize: 16,
    fontWeight: '400',
    color: '#F5F5F5',
    lineHeight: 24,
    marginBottom: 12,
    textShadowColor: 'rgba(0, 0, 0, 0.5)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  boldText: {
    fontWeight: '600',
    color: '#FFFFFF',
  },
  highlightText: {
    color: '#D4A574',
    fontWeight: '600',
  },
  spyText: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  residentText: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  actionText: {
    color: '#D4A574',
    fontWeight: '600',
  },
  warningText: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  footer: {
    marginTop: 32,
    paddingTop: 20,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.2)',
  },
  footerText: {
    fontSize: 14,
    fontWeight: '400',
    color: '#E0E0E0',
    fontStyle: 'italic',
    lineHeight: 20,
  },
});

