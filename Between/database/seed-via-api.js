#!/usr/bin/env node
// Seed database via API endpoints (mimics real user flow)
// Run: node seed-via-api.js

const API_BASE = process.env.API_URL || 'http://localhost:3000/v1';

async function request(method, path, body = null, token = null) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  
  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : null
  });
  
  if (!res.ok) {
    throw new Error(`${method} ${path}: ${res.status} ${await res.text()}`);
  }
  return res.json();
}

async function seedDatabase() {
  console.log('🌱 Seeding database via API...\n');
  
  // 1. Create test students via activation (mimics SSO flow)
  console.log('1. Creating students...');
  const alex = await request('POST', '/auth/activate', {
    email: 'alex.hirsch@vt.edu',
    code: '482910'
  });
  
  const john = await request('POST', '/auth/activate', {
    email: 'john.martinez@vt.edu',
    code: '482910'
  });
  
  const rachel = await request('POST', '/auth/activate', {
    email: 'rachel.chen@vt.edu',
    code: '482910'
  });
  console.log('✅ Students created\n');
  
  // 2. Add course enrollments (mimics Canvas sync)
  // This would typically come from Canvas API webhook
  // For now, direct DB insert or admin API endpoint
  console.log('2. Enrolling in courses...');
  await request('POST', '/admin/enrollments', {
    student_id: alex.userId,
    section_ids: ['CS2114-001', 'CS3214-001', 'MATH2204-001']
  }, alex.token);
  console.log('✅ Enrollments added\n');
  
  // 3. Send friend requests (real user flow)
  console.log('3. Creating friendships...');
  await request('POST', '/me/friend-requests', {
    to_student_id: john.userId
  }, alex.token);
  
  await request('POST', '/me/friend-requests', {
    to_student_id: rachel.userId
  }, alex.token);
  
  // Accept requests
  const johnDash = await request('GET', '/me/dashboard', null, john.token);
  const alexRequest = johnDash.pendingIncoming.find(r => r.from.id === alex.userId);
  await request('POST', `/me/friend-requests/${alexRequest.id}/accept`, null, john.token);
  console.log('✅ Friendships established\n');
  
  // 4. Create interests onboarding (real user flow)
  console.log('4. Setting interests...');
  await request('POST', '/me/interests', {
    interest_ids: ['int-volleyball', 'int-study']
  }, alex.token);
  console.log('✅ Interests set\n');
  
  // 5. Mark event interested (real user flow)
  console.log('5. Joining events...');
  await request('POST', '/events/evt-vb-im/interested', null, alex.token);
  console.log('✅ Event participation added\n');
  
  // 6. Create partner profile (real user flow)
  console.log('6. Creating partner profile...');
  await request('POST', '/events/evt-vb-im/partner', {
    note: 'Need a setter for IM team',
    experience: 'Intermediate'
  }, john.token);
  console.log('✅ Partner profile created\n');
  
  // 7. Set activity mode (real user flow)
  console.log('7. Setting activity mode...');
  await request('POST', '/me/activity-mode', {
    mode: 'hungry'
  }, alex.token);
  console.log('✅ Activity mode set\n');
  
  console.log('✨ Seeding complete!\n');
  console.log('Test users:');
  console.log(`  Alex:   alex.hirsch@vt.edu / demo123`);
  console.log(`  John:   john.martinez@vt.edu / demo123`);
  console.log(`  Rachel: rachel.chen@vt.edu / demo123`);
}

// Admin functions (for courses and events)
async function seedAdminData() {
  const ADMIN_TOKEN = process.env.ADMIN_TOKEN;
  if (!ADMIN_TOKEN) {
    console.log('⚠️  Skipping admin data (ADMIN_TOKEN not set)');
    return;
  }
  
  console.log('\n🔐 Seeding admin data...\n');
  
  // Add course sections (mimics Canvas import)
  await request('POST', '/admin/sections', {
    sections: [
      {
        section_id: 'CS2114-001',
        canonical_course_id: 'CSE-1002',
        course_code: 'CS 2114',
        course_name: 'Software Design & Data Structures',
        section_label: '001',
        meeting_days: ['Mon', 'Wed', 'Fri'],
        start_time: '09:00',
        end_time: '09:50',
        location: 'McBryde Hall'
      }
    ]
  }, ADMIN_TOKEN);
  console.log('✅ Course sections added\n');
  
  // Add campus events
  await request('POST', '/admin/events', {
    title: 'IM Volleyball - Open Gym',
    description: 'Drop-in at War Memorial. All skill levels.',
    interest_id: 'int-volleyball',
    location: 'War Memorial Gym',
    start_time: '2026-07-29T18:00:00Z',
    matching_kind: 'partner',
    is_recurring: true,
    recurrence_label: 'Every Wednesday'
  }, ADMIN_TOKEN);
  console.log('✅ Campus events added\n');
}

// Run seeding
(async () => {
  try {
    await seedAdminData();
    await seedDatabase();
  } catch (error) {
    console.error('❌ Seeding failed:', error.message);
    process.exit(1);
  }
})();
