const express = require('express');
const jwt = require('jsonwebtoken');
const defaultStore = require('./dataStore');
const { encryptPayload, decryptPayload } = require('./crypto');

const JWT_SECRET = process.env.JWT_SECRET || 'between-demo-jwt-secret-vt-pilot';

function signSession(userId, email) {
  const token = jwt.sign({ sub: userId, email }, JWT_SECRET, { expiresIn: '7d' });
  return { userId, email, token: `bearer-${token}` };
}

function createRouter(store) {
  const router = express.Router();

  function authMiddleware(req, res, next) {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const raw = token.startsWith('bearer-') ? token.slice(7) : token;
      req.user = jwt.verify(raw, JWT_SECRET);
      next();
    } catch {
      res.status(401).json({ error: 'Invalid token' });
    }
  }

  router.get('/health', (_req, res) => {
    res.json({ status: 'ok', mode: 'seed-v1', school: 'vt' });
  });

  router.get('/auth/demo-candidates', (_req, res) => {
    res.json(store.loginCandidates());
  });

  router.post('/auth/login', (req, res) => {
    const { email, password } = req.body || {};
    const result = store.login(email, password);
    if (result.error === 'userNotFound') return res.status(404).json({ error: 'User not found' });
    if (result.error === 'badPassword') return res.status(401).json({ error: 'Incorrect password' });
    const session = signSession(result.userId, result.email);
    res.json({ session, dashboard: store.dashboard(result.userId) });
  });

  router.post('/auth/activate', (req, res) => {
    const { email, code } = req.body || {};
    const result = store.activate(email, code);
    if (result.error) return res.status(401).json({ error: 'Invalid activation' });
    const session = signSession(result.userId, result.email);
    res.json({ session, dashboard: store.dashboard(result.userId) });
  });

  router.post('/auth/sso', (req, res) => {
    const { email } = req.body || {};
    if (!email?.endsWith('@vt.edu')) {
      return res.status(400).json({ error: 'SSO requires @vt.edu email' });
    }
    const result = store.ssoLogin(email);
    if (result.error) return res.status(404).json({ error: 'User not found in pilot roster' });
    const session = signSession(result.userId, result.email);
    res.json({
      session,
      dashboard: store.dashboard(result.userId),
      ssoProvider: 'Virginia Tech (demo)',
      encryptedClaims: encryptPayload({ email, schoolId: 'vt', verified: true }, result.userId),
    });
  });

  router.post('/me/consent', authMiddleware, (req, res) => {
    const { accepted, ferpaAcknowledged, privacyVersion } = req.body || {};
    if (!accepted) return res.status(400).json({ error: 'Consent required' });
    store.recordConsent(req.user.sub, true);
    res.json({
      ok: true,
      ferpaAcknowledged: !!ferpaAcknowledged,
      privacyVersion: privacyVersion || '2026-07',
      message: 'Consent recorded. Schedule sharing follows your privacy settings.',
    });
  });

  router.get('/me/dashboard', authMiddleware, (req, res) => {
    const dashboard = store.dashboard(req.user.sub);
    if (!dashboard) return res.status(404).json({ error: 'User not found' });
    res.json(dashboard);
  });

  router.get('/me/events', authMiddleware, (req, res) => {
    res.json(store.events(req.user.sub));
  });

  router.get('/sections/search', (req, res) => {
    res.json(store.searchSections(req.query.q || ''));
  });

  router.patch('/me/presence', authMiddleware, (req, res) => {
    const { status, activity } = req.body || {};
    const record = store.setPresence(req.user.sub, status, activity);
    if (!record) return res.status(404).json({ error: 'User not found' });
    res.json(record);
  });

  router.patch('/me/mode', authMiddleware, (req, res) => {
    const { mode } = req.body || {};
    const record = store.setActivityMode(req.user.sub, mode);
    if (!record) return res.status(400).json({ error: 'Invalid mode' });
    res.json({ presence: record, mode, events: store.events(req.user.sub) });
  });

  router.patch('/me/interests', authMiddleware, (req, res) => {
    const { interestIds } = req.body || {};
    if (!Array.isArray(interestIds) || interestIds.length < 2) {
      return res.status(400).json({ error: 'Pick at least 2 interests' });
    }
    store.updateInterests(req.user.sub, interestIds);
    res.json(store.events(req.user.sub));
  });

  router.post('/events/:eventId/interested', authMiddleware, (req, res) => {
    if (!store.markEventInterested(req.user.sub, req.params.eventId)) {
      return res.status(400).json({ error: 'Invalid event' });
    }
    res.json(store.events(req.user.sub));
  });

  router.post('/events/:eventId/partner', authMiddleware, (req, res) => {
    const { note, experience } = req.body || {};
    if (!store.markLookingForPartner(req.user.sub, req.params.eventId, note || '', experience || '')) {
      return res.status(400).json({ error: 'Invalid event' });
    }
    const events = store.events(req.user.sub);
    const event = events.events.find((e) => e.id === req.params.eventId);
    const encrypted = encryptPayload(event?.partnerProfiles || [], req.params.eventId);
    res.json({ events, encryptedPartners: encrypted });
  });

  router.get('/events/:eventId/partners', authMiddleware, (req, res) => {
    const events = store.events(req.user.sub);
    const event = events.events.find((e) => e.id === req.params.eventId);
    if (!event?.canViewPartners) {
      return res.status(403).json({
        error: 'Mutual opt-in required',
        message: 'Mark yourself as looking for a partner to see others.',
        partnerSeekingCount: event?.partnerSeekingCount ?? 0,
      });
    }
    const encrypted = encryptPayload(event.partnerProfiles, req.params.eventId);
    res.json({ encrypted, count: event.partnerProfiles.length });
  });

  router.post('/security/demo-decrypt', authMiddleware, (req, res) => {
    const { encrypted, context } = req.body || {};
    try {
      const decrypted = decryptPayload(encrypted, context || '');
      res.json({ decrypted, note: 'In production, decryption happens only on the student device.' });
    } catch {
      res.status(400).json({ error: 'Decryption failed' });
    }
  });

  router.post('/friends/requests', authMiddleware, (req, res) => {
    store.sendFriendRequest(req.user.sub, req.body?.toStudentId);
    res.json({ ok: true });
  });

  router.post('/friends/requests/:id/accept', authMiddleware, (req, res) => {
    if (!store.acceptFriendRequest(req.user.sub, req.params.id)) {
      return res.status(400).json({ error: 'Invalid request' });
    }
    res.json({ ok: true, dashboard: store.dashboard(req.user.sub) });
  });

  router.post('/plans', authMiddleware, (req, res) => {
    const { type, title, location } = req.body || {};
    const plan = store.createPlan(req.user.sub, type, title, location);
    res.json(plan);
  });

  router.post('/me/course-hashes', authMiddleware, (req, res) => {
    const { hashedCourseIds } = req.body || {};
    if (!Array.isArray(hashedCourseIds)) {
      return res.status(400).json({ error: 'hashedCourseIds array required' });
    }
    const matches = store.courseHashMatches(req.user.sub, hashedCourseIds);
    res.json({
      matches,
      note: 'Server stores hashes only. Raw course titles never leave the device.',
    });
  });

  router.post('/nudges', authMiddleware, (req, res) => {
    res.json({ ok: true });
  });

  return router;
}

const router = createRouter(defaultStore);
module.exports = router;
module.exports.createRouter = createRouter;
module.exports.signSession = signSession;
