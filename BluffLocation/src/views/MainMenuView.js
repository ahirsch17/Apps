import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ImageBackground, TextInput, Modal, Alert } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useFonts, Cinzel_600SemiBold, Cinzel_700Bold } from '@expo-google-fonts/cinzel';
import { useFonts as usePoppinsFonts, Poppins_600SemiBold } from '@expo-google-fonts/poppins';
import { getPlayerName, savePlayerName } from '../utils/PlayerStorage';

export default function MainMenuView() {
  const navigation = useNavigation();
  const [showNameModal, setShowNameModal] = useState(false);
  const [playerName, setPlayerName] = useState('');
  const [savedName, setSavedName] = useState('');
  
  const [cinzelLoaded] = useFonts({
    Cinzel_600SemiBold,
    Cinzel_700Bold,
  });
  
  const [poppinsLoaded] = usePoppinsFonts({
    Poppins_600SemiBold,
  });
  
  const fontsLoaded = cinzelLoaded && poppinsLoaded;
  
  useEffect(() => {
    loadSavedName();
  }, []);
  
  const loadSavedName = async () => {
    const name = await getPlayerName();
    setSavedName(name);
    setPlayerName(name);
  };
  
  const handleSaveName = async () => {
    const trimmedName = playerName.trim();
    if (trimmedName.length === 0) {
      Alert.alert('Error', 'Please enter your name');
      return;
    }
    await savePlayerName(trimmedName);
    setSavedName(trimmedName);
    setShowNameModal(false);
  };
  
  return (
    <ImageBackground 
      source={require('../../assets/menuScreen.png')} 
      style={styles.container}
      resizeMode="cover"
    >
      {/* Dark vignette overlay */}
      <View style={styles.vignette} />
      
      {/* Main content overlay */}
      <View style={styles.contentOverlay}>
        {/* Title */}
        <View style={styles.titleContainer}>
          <Text 
            style={[styles.title, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}
            numberOfLines={1}
            adjustsFontSizeToFit={true}
            minimumFontScale={0.7}
          >
            BluffLocation
          </Text>
        </View>
        
        {/* Buttons container */}
        <View style={styles.buttonsContainer}>
          <TouchableOpacity
            style={[styles.button, styles.createButton]}
            onPress={() => navigation.navigate('CreateGame')}
            activeOpacity={0.8}
          >
            <Text style={[styles.buttonText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
              CREATE GAME
            </Text>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[styles.button, styles.joinButton]}
            onPress={() => navigation.navigate('JoinGame')}
            activeOpacity={0.8}
          >
            <Text style={[styles.buttonText, poppinsLoaded && { fontFamily: 'Poppins_600SemiBold' }]}>
              JOIN GAME
            </Text>
          </TouchableOpacity>
        </View>
        
        {/* Rules/Info button - bottom center */}
        <TouchableOpacity
          style={styles.rulesButton}
          onPress={() => navigation.navigate('Rules')}
          activeOpacity={0.7}
        >
          <Text style={styles.rulesButtonText}>ⓘ</Text>
        </TouchableOpacity>
        
        {/* Name/Profile button - bottom left */}
        <TouchableOpacity
          style={styles.nameButton}
          onPress={() => setShowNameModal(true)}
          activeOpacity={0.7}
        >
          <Text style={styles.nameButtonText}>👤</Text>
        </TouchableOpacity>
      </View>
      
      {/* Name Edit Modal */}
      <Modal
        visible={showNameModal}
        transparent={true}
        animationType="fade"
        onRequestClose={() => setShowNameModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={[styles.modalTitle, cinzelLoaded && { fontFamily: 'Cinzel_700Bold' }]}>
              Edit Name
            </Text>
            <TextInput
              style={styles.modalInput}
              value={playerName}
              onChangeText={setPlayerName}
              placeholder="Your Name"
              placeholderTextColor="#999"
              autoCapitalize="words"
              autoCorrect={false}
              autoFocus={true}
            />
            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalButton, styles.modalButtonCancel]}
                onPress={() => {
                  setPlayerName(savedName);
                  setShowNameModal(false);
                }}
              >
                <Text style={styles.modalButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalButton, styles.modalButtonSave]}
                onPress={handleSaveName}
              >
                <Text style={[styles.modalButtonText, { color: '#fff' }]}>Save</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
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
    padding: 40,
    justifyContent: 'space-between',
    backgroundColor: 'rgba(0, 0, 0, 0.3)',
  },
  titleContainer: {
    marginTop: '15%',
    alignItems: 'center',
    width: '100%',
    paddingHorizontal: 20,
  },
  title: {
    fontSize: 56,
    fontWeight: '700',
    color: '#FFFFFF',
    textShadowColor: 'rgba(0, 0, 0, 1)',
    textShadowOffset: { width: 4, height: 4 },
    textShadowRadius: 12,
    letterSpacing: 1.2,
    textAlign: 'center',
    textTransform: 'none',
  },
  buttonsContainer: {
    alignItems: 'center',
    marginBottom: '20%',
  },
  button: {
    width: '85%',
    maxWidth: 320,
    paddingVertical: 16,
    paddingHorizontal: 48,
    borderRadius: 12,
    marginVertical: 12,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(30, 30, 30, 0.85)',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.5,
    shadowRadius: 8,
    elevation: 8,
  },
  createButton: {
    borderWidth: 2,
    borderColor: '#D4A574', // Warm gold accent
  },
  joinButton: {
    borderWidth: 2,
    borderColor: '#4A9EBF', // Ocean blue accent
  },
  buttonText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#FEFEFE',
    letterSpacing: 1.5,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  rulesButton: {
    position: 'absolute',
    bottom: 30,
    alignSelf: 'center',
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(20, 20, 30, 0.8)',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.4,
    shadowRadius: 4,
    elevation: 5,
  },
  rulesButtonText: {
    fontSize: 20,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  nameButton: {
    position: 'absolute',
    bottom: 30,
    left: 20,
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(20, 20, 30, 0.8)',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.4,
    shadowRadius: 4,
    elevation: 5,
  },
  nameButtonText: {
    fontSize: 20,
    color: '#FFFFFF',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: '#1A1A1A',
    borderRadius: 16,
    padding: 24,
    width: '80%',
    maxWidth: 400,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  modalTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: '#FFFFFF',
    marginBottom: 20,
    textAlign: 'center',
  },
  modalInput: {
    fontSize: 18,
    color: '#FFFFFF',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 8,
    padding: 12,
    marginBottom: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  modalButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
  },
  modalButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  modalButtonCancel: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  modalButtonSave: {
    backgroundColor: '#4A9EBF',
  },
  modalButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
});
