const { describe, it, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { createRouter, signSession } = require('./routes');
const { createFreshStore } = require('./dataStore');
const { withTestServer, request } = require('./testHttp');

describe('v1 routes (HTTP)', () => {
  /** @type {ReturnType<typeof createFreshStore>} */
  let store;

  beforeEach(() => {
    store = createFreshStore();
  });

  it('GET /health', async () => {
    await withTestServer(createRouter(store), async (base) => {
      const res = await request(base, '/health');
      assert.equal(res.status, 200);
      assert.equal(res.body.status, 'ok');
    });
  });

  it('POST /auth/login returns session and dashboard', async () => {
    await withTestServer(createRouter(store), async (base) => {
      const res = await request(base, '/auth/login', {
        method: 'POST',
        body: { email: 'alex.hirsch@vt.edu', password: 'demo123' },
      });
      assert.equal(res.status, 200);
      assert.equal(res.body.session.userId, 'stu-alex');
      assert.ok(res.body.dashboard.nearbyFriends.length >= 10);
    });
  });

  it('POST /auth/login rejects bad password', async () => {
    await withTestServer(createRouter(store), async (base) => {
      const res = await request(base, '/auth/login', {
        method: 'POST',
        body: { email: 'alex.hirsch@vt.edu', password: 'wrong' },
      });
      assert.equal(res.status, 401);
    });
  });

  it('POST /auth/sso requires vt.edu', async () => {
    await withTestServer(createRouter(store), async (base) => {
      const res = await request(base, '/auth/sso', {
        method: 'POST',
        body: { email: 'test@gmail.com' },
      });
      assert.equal(res.status, 400);
    });
  });

  it('POST /events/:id/interested requires auth and bumps count', async () => {
    const session = signSession('stu-alex', 'alex.hirsch@vt.edu');
    await withTestServer(createRouter(store), async (base) => {
      const before = await request(base, '/me/events', { token: session.token });
      const vbBefore = before.body.events.find((e) => e.id === 'evt-vb-im');
      assert.equal(vbBefore.interestedCount, 11);

      const post = await request(base, '/events/evt-vb-im/interested', {
        method: 'POST',
        token: session.token,
        body: {},
      });
      assert.equal(post.status, 200);
      const vbAfter = post.body.events.find((e) => e.id === 'evt-vb-im');
      assert.equal(vbAfter.interestedCount, 12);
      assert.equal(vbAfter.isInterested, true);
    });
  });

  it('GET /events/:id/partners returns 403 without opt-in', async () => {
    const session = signSession('stu-alex', 'alex.hirsch@vt.edu');
    await withTestServer(createRouter(store), async (base) => {
      const res = await request(base, '/events/evt-vb-im/partners', { token: session.token });
      assert.equal(res.status, 403);
    });
  });

  it('POST /me/course-hashes returns matches for enrolled peers', async () => {
    const crypto = require('crypto');
    const hash = (cid) =>
      crypto.createHash('sha256').update(`vt:${cid}`).digest('hex');
    const session = signSession('stu-alex', 'alex.hirsch@vt.edu');
    await withTestServer(createRouter(store), async (base) => {
      const res = await request(base, '/me/course-hashes', {
        method: 'POST',
        token: session.token,
        body: { hashedCourseIds: [hash('CSE-1002')] },
      });
      assert.equal(res.status, 200);
      assert.ok(Array.isArray(res.body.matches));
      assert.ok(res.body.matches.some((m) => m.classmateCount >= 1));
    });
  });
});
