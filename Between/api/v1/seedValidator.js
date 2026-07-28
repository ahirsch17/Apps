/**
 * Validates seed_data.json referential integrity.
 * Every event participant must be a real student with at least one enrollment.
 */

function validateSeed(db) {
  const errors = [];
  const studentIds = new Set((db.students || []).map((s) => s.id));
  const eventIds = new Set((db.campusEvents || []).map((e) => e.id));
  const sectionIds = new Set((db.sections || []).map((s) => s.sectionId));
  const enrolledStudentIds = new Set((db.enrollments || []).map((e) => e.studentId));

  for (const enrollment of db.enrollments || []) {
    if (!studentIds.has(enrollment.studentId)) {
      errors.push(`enrollment references unknown student ${enrollment.studentId}`);
    }
    if (!sectionIds.has(enrollment.sectionId)) {
      errors.push(`enrollment references unknown section ${enrollment.sectionId}`);
    }
  }

  for (const p of db.eventParticipations || []) {
    if (!eventIds.has(p.eventId)) {
      errors.push(`participation references unknown event ${p.eventId}`);
    }
    if (!studentIds.has(p.studentId)) {
      errors.push(`participation references unknown student ${p.studentId}`);
    } else if (!enrolledStudentIds.has(p.studentId)) {
      errors.push(`participation student ${p.studentId} has no enrollment (must have classes)`);
    }
  }

  for (const pp of db.partnerProfiles || []) {
    if (!studentIds.has(pp.studentId)) {
      errors.push(`partner profile references unknown student ${pp.studentId}`);
    }
    if (!eventIds.has(pp.eventId)) {
      errors.push(`partner profile references unknown event ${pp.eventId}`);
    }
    const participation = (db.eventParticipations || []).find(
      (p) => p.eventId === pp.eventId && p.studentId === pp.studentId && p.kind === 'lookingForPartner'
    );
    if (!participation) {
      errors.push(
        `partner profile for ${pp.studentId} on ${pp.eventId} missing lookingForPartner participation`
      );
    }
    const student = (db.students || []).find((s) => s.id === pp.studentId);
    if (student && pp.displayName !== student.name.split(' ')[0]) {
      errors.push(`partner profile displayName for ${pp.studentId} should match student first name`);
    }
  }

  for (const ev of db.campusEvents || []) {
    const real = new Set(
      (db.eventParticipations || []).filter((p) => p.eventId === ev.id).map((p) => p.studentId)
    );
    if (real.size === 0) {
      errors.push(`event ${ev.id} has no enrolled student participations`);
    }
  }

  return errors;
}

function assertValidSeed(db) {
  const errors = validateSeed(db);
  if (errors.length) {
    throw new Error(`Invalid seed_data.json:\n${errors.map((e) => `  - ${e}`).join('\n')}`);
  }
}

module.exports = { validateSeed, assertValidSeed };
