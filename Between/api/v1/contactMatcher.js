function normalizePhone(raw) {
  const digits = String(raw || '').replace(/\D/g, '');
  if (!digits) return null;
  if (digits.length === 10) return `1${digits}`;
  return digits;
}

function matchedStudentIds(students, deviceContacts) {
  const contactPhones = new Set(
    deviceContacts.map((c) => normalizePhone(c.phoneNumber)).filter(Boolean),
  );
  if (!contactPhones.size) return new Set();

  const matched = new Set();
  for (const student of students) {
    const normalized = normalizePhone(student.phoneNumber);
    if (normalized && contactPhones.has(normalized)) {
      matched.add(student.id);
    }
  }
  return matched;
}

function applyContactSuggestions(students, contactMatchedIds) {
  const ids = contactMatchedIds instanceof Set ? contactMatchedIds : new Set(contactMatchedIds);
  return students.map((s) => ({
    ...s,
    suggestedVia: ids.has(s.id) ? 'contacts' : null,
  }));
}

module.exports = { normalizePhone, matchedStudentIds, applyContactSuggestions };
