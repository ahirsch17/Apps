import React, { useState } from 'react';
import { Alert, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { validateClue } from '../lib/utils/wordValidation';

type Props = {
  onSubmit: (clue: { word: string; number: number }) => void;
  disabled?: boolean;
  boardWords?: string[];
};

export default function ClueInput({ onSubmit, disabled, boardWords = [] }: Props) {
  const [clueWord, setClueWord] = useState('');
  const [number, setNumber] = useState('');

  const handleSubmit = () => {
    const parsed = Number.parseInt(number, 10);
    const validation = validateClue(clueWord, parsed, boardWords);

    if (!validation.isValid) {
      Alert.alert('Invalid Clue', validation.message);
      return;
    }

    onSubmit({ word: clueWord.toUpperCase(), number: parsed });
    setClueWord('');
    setNumber('');
  };

  const canSubmit = !disabled && clueWord.trim() && number;

  return (
    <View style={styles.container}>
      <TextInput
        style={styles.input}
        value={clueWord}
        onChangeText={setClueWord}
        placeholder="Enter clue word"
        placeholderTextColor="rgba(255, 255, 255, 0.4)"
        autoCapitalize="characters"
        editable={!disabled}
      />
      <TextInput
        style={[styles.input, styles.numberInput]}
        value={number}
        onChangeText={setNumber}
        placeholder="#"
        placeholderTextColor="rgba(255, 255, 255, 0.4)"
        keyboardType="number-pad"
        maxLength={2}
        editable={!disabled}
      />
      <TouchableOpacity
        style={[styles.submitButton, !canSubmit && styles.submitButtonDisabled]}
        onPress={handleSubmit}
        disabled={!canSubmit}
      >
        <Text style={styles.submitButtonText}>Submit</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 14,
    paddingVertical: 8,
  },
  input: {
    flex: 1,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  numberInput: {
    maxWidth: 70,
    textAlign: 'center',
  },
  submitButton: {
    backgroundColor: '#28A745',
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
  },
  submitButtonDisabled: {
    backgroundColor: 'rgba(150, 150, 150, 0.5)',
  },
  submitButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
  },
});


