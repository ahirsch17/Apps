const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { formatRange, formatTime12Hour, buildTodayPlan } = require('./scheduleEngine');

describe('scheduleEngine', () => {
  it('formatTime12Hour handles morning and afternoon', () => {
    assert.equal(formatTime12Hour(9 * 60), '9 AM');
    assert.equal(formatTime12Hour(14 * 60 + 30), '2:30 PM');
  });

  it('formatRange joins start and end', () => {
    assert.equal(formatRange(9 * 60, 10 * 60 + 50), '9 AM – 10:50 AM');
  });

  it('buildTodayPlan hides empty blocks longer than 90 minutes', () => {
    const sections = [
      {
        sectionId: 'early',
        courseCode: 'PHYS',
        courseName: 'Physics',
        sectionLabel: '001',
        meetingDays: ['Wed'],
        startTime: '08:00',
        endTime: '08:50',
        location: 'Hall',
        canonicalCourseId: 'PHYS-1',
      },
      {
        sectionId: 'late',
        courseCode: 'COMM',
        courseName: 'Comm',
        sectionLabel: '001',
        meetingDays: ['Wed'],
        startTime: '16:00',
        endTime: '16:50',
        location: 'Lib',
        canonicalCourseId: 'COMM-1',
      },
    ];
    const plan = buildTodayPlan(sections, {}, {});
    const hugeFree = plan.filter((p) => p.kind === 'freeBlock' && p.endMinutes - p.startMinutes > 90);
    assert.equal(hugeFree.length, 0);
  });

  it('buildTodayPlan includes class blocks on demo Wednesday', () => {
    const sections = [
      {
        sectionId: 'CS2114-001',
        courseCode: 'CS 2114',
        courseName: 'Soft Design',
        sectionLabel: '001',
        meetingDays: ['Mon', 'Wed', 'Fri'],
        startTime: '11:00',
        endTime: '11:50',
        location: 'McBryde',
        canonicalCourseId: 'CSE-1002',
      },
    ];
    const plan = buildTodayPlan(sections, {}, {});
    assert.ok(plan.some((p) => p.kind === 'classBlock'));
  });
});
