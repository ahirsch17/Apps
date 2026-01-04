// Articles and conjunctions that can be lowercase in proper names/titles
const ALLOWED_LOWERCASE = new Set(['a', 'an', 'the', 'and', 'or', 'but', 'of', 'in', 'on', 'at', 'to', 'for', 'with']);

export function validateClue(word: string, number: number, boardWords: string[] = []) {
  const trimmed = word.trim();
  if (trimmed.length === 0) {
    return { isValid: false as const, message: 'Clue word is required' };
  }

  if (trimmed.length === 1) {
    return { isValid: false as const, message: 'Clue cannot be a single letter' };
  }

  const parts = trimmed.split(/\s+/);
  
  // For multi-word clues, check if it's a proper name (most words capitalized)
  if (parts.length > 1) {
    const capitalizedWords = parts.filter(p => /^[A-Z]/.test(p)).length;
    const lowercaseAllowed = parts.filter(p => ALLOWED_LOWERCASE.has(p.toLowerCase())).length;
    const totalWords = parts.length;
    
    // Most words should be capitalized (proper name), or be allowed lowercase words
    if (capitalizedWords + lowercaseAllowed < totalWords) {
      return {
        isValid: false as const,
        message: 'Multi-word clues should be proper names (capitalize first letters)',
      };
    }
  }

  // Check if clue contains any words from the board
  const clueUpper = trimmed.toUpperCase();
  const containsBoardWord = boardWords.some(boardWord => {
    const boardUpper = boardWord.toUpperCase();
    return clueUpper.includes(boardUpper) || boardUpper.includes(clueUpper);
  });

  if (containsBoardWord) {
    return {
      isValid: false as const,
      message: 'Clue cannot contain or be part of any word on the board',
    };
  }

  if (!Number.isFinite(number)) {
    return { isValid: false as const, message: 'Number must be a valid integer' };
  }

  if (number < 1 || number > 9) {
    return { isValid: false as const, message: 'Number must be between 1 and 9' };
  }

  return { isValid: true as const, message: '' };
}


