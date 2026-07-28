const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { buildDashboard } = require('./dashboardBuilder');

const SEED_PATH = path.join(__dirname, '../../Between/Resources/seed_data.json');

describe('dashboardBuilder', () => {
  it('builds Alex dashboard with friends and today plan', () => {
    const db = JSON.parse(fs.readFileSync(SEED_PATH, 'utf8'));
    const me = db.students.find((s) => s.id === 'stu-alex');
    const presenceByStudentId = Object.fromEntries(db.presence.map((p) => [p.studentId, p]));
    const dashboard = buildDashboard({
      me,
      students: db.students,
      sections: db.sections,
      enrollments: db.enrollments,
      friendships: db.friendships,
      friendRequests: db.friendRequests,
      presenceByStudentId,
      plans: db.plans,
      syncTime: new Date().toISOString(),
    });

    assert.equal(dashboard.me.id, 'stu-alex');
    assert.ok(dashboard.nearbyFriends.length >= 10);
    assert.ok(dashboard.todayPlan.length > 0);
    assert.ok(dashboard.pendingIncoming.length >= 1);
  });

  it('does not expose raw minute totals in today plan items', () => {
    const db = JSON.parse(fs.readFileSync(SEED_PATH, 'utf8'));
    const me = db.students.find((s) => s.id === 'stu-alex');
    const presenceByStudentId = Object.fromEntries(db.presence.map((p) => [p.studentId, p]));
    const dashboard = buildDashboard({
      me,
      students: db.students,
      sections: db.sections,
      enrollments: db.enrollments,
      friendships: db.friendships,
      friendRequests: db.friendRequests,
      presenceByStudentId,
      plans: db.plans,
      syncTime: new Date().toISOString(),
    });

    for (const item of dashboard.todayPlan) {
      for (const overlap of item.friendOverlaps || []) {
        assert.ok(overlap.totalMinutes < 500, 'overlap minutes should be human-scaled');
      }
    }
  });
});
