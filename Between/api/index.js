const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  }
});

// Initialize database tables
async function initializeDatabase() {
  try {
    const createUsersTable = `
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        vt_email VARCHAR(50) UNIQUE NOT NULL,
        name VARCHAR(100) NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        activated BOOLEAN DEFAULT false,
        crn1 VARCHAR(10),
        crn2 VARCHAR(10),
        crn3 VARCHAR(10),
        crn4 VARCHAR(10),
        crn5 VARCHAR(10),
        crn6 VARCHAR(10),
        crn7 VARCHAR(10),
        crn8 VARCHAR(10),
        match_list TEXT[] DEFAULT '{}',
        location VARCHAR(100),
        last_schedule_update TIMESTAMP DEFAULT NOW(),
        course_data_cache JSONB,
        friends_in_courses_cache JSONB,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `;

    const createCoursesTable = `
      CREATE TABLE IF NOT EXISTS courses (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        crn VARCHAR(10) UNIQUE NOT NULL,
        subject VARCHAR(10) NOT NULL,
        course_number VARCHAR(10) NOT NULL,
        course_name VARCHAR(200) NOT NULL,
        credits INTEGER NOT NULL,
        time VARCHAR(50),
        days VARCHAR(20),
        location VARCHAR(100),
        instructor VARCHAR(100),
        campus VARCHAR(50),
        term VARCHAR(20),
        schedule_type VARCHAR(10),
        modality VARCHAR(50),
        capacity INTEGER,
        begin_time VARCHAR(20),
        end_time VARCHAR(20),
        exam_code VARCHAR(10),
        last_updated TIMESTAMP DEFAULT NOW()
      );
    `;

    const createMatchesTable = `
      CREATE TABLE IF NOT EXISTS matches (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user1_email VARCHAR(50) NOT NULL,
        user2_email VARCHAR(50) NOT NULL,
        shared_courses TEXT[],
        match_strength INTEGER DEFAULT 1,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(user1_email, user2_email)
      );
    `;

    await pool.query(createUsersTable);
    await pool.query(createCoursesTable);
    await pool.query(createMatchesTable);
    
    // Create indexes
    await pool.query('CREATE INDEX IF NOT EXISTS idx_users_vt_email ON users(vt_email);');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_courses_crn ON courses(crn);');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_matches_users ON matches(user1_email, user2_email);');
    
    console.log('✅ Database tables created successfully');
  } catch (error) {
    console.error('❌ Error creating tables:', error);
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// User endpoints
app.post('/users', async (req, res) => {
  try {
    const { vtEmail, name, password, activated = false } = req.body;
    
    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);
    
    const result = await pool.query(
      'INSERT INTO users (vt_email, name, password_hash, activated) VALUES ($1, $2, $3, $4) RETURNING *',
      [vtEmail, name, passwordHash, activated]
    );
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

// Dedicated endpoint for updating match list
app.put('/users/:vtEmail/match-list', async (req, res) => {
  try {
    const { vtEmail } = req.params;
    const { matchList } = req.body;
    
    if (!Array.isArray(matchList)) {
      return res.status(400).json({ error: 'matchList must be an array' });
    }
    
    const result = await pool.query(
      'UPDATE users SET match_list = $1, updated_at = NOW() WHERE vt_email = $2 RETURNING *',
      [matchList, vtEmail]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Clear cache for this user and any users who had this user in their match list
    await clearUserCache(vtEmail);
    await clearCacheForUsersWithMatch(vtEmail);
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating match list:', error);
    res.status(500).json({ error: 'Failed to update match list' });
  }
});

// Helper function to clear cache for users who had this user in their match list
async function clearCacheForUsersWithMatch(vtEmail) {
  try {
    const result = await pool.query(
      'SELECT vt_email FROM users WHERE $1 = ANY(match_list)',
      [vtEmail]
    );
    
    for (const row of result.rows) {
      await clearUserCache(row.vt_email);
    }
  } catch (error) {
    console.error('Error clearing cache for users with match:', error);
  }
}

// Helper function to clear user cache (placeholder - implement based on your cache system)
async function clearUserCache(vtEmail) {
  // This would clear the user's course data cache
  // Implementation depends on your cache system
  console.log(`Cache cleared for user: ${vtEmail}`);
}

app.get('/users/:vtEmail', async (req, res) => {
  try {
    const { vtEmail } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM users WHERE vt_email = $1',
      [vtEmail]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error getting user:', error);
    res.status(500).json({ error: 'Failed to get user' });
  }
});

// Optimized endpoint for getting friend data (for schedule matching)
app.get('/users/:vtEmail/friends', async (req, res) => {
  try {
    const { vtEmail } = req.params;
    
    // Get user's match list
    const userResult = await pool.query(
      'SELECT match_list FROM users WHERE vt_email = $1',
      [vtEmail]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const matchList = userResult.rows[0].match_list || [];
    
    if (matchList.length === 0) {
      return res.json({ friends: [] });
    }
    
    // Get friend data efficiently with a single query
    const friendsResult = await pool.query(
      `SELECT vt_email, name, crn1, crn2, crn3, crn4, crn5, crn6, crn7, crn8 
       FROM users 
       WHERE vt_email = ANY($1)`,
      [matchList]
    );
    
    const friends = friendsResult.rows.map(row => ({
      vtEmail: row.vt_email,
      name: row.name,
      crns: [row.crn1, row.crn2, row.crn3, row.crn4, row.crn5, row.crn6, row.crn7, row.crn8]
        .filter(crn => crn !== null)
    }));
    
    res.json({ friends });
  } catch (error) {
    console.error('Error getting friends:', error);
    res.status(500).json({ error: 'Failed to get friends' });
  }
});

app.put('/users/:vtEmail', async (req, res) => {
  try {
    const { vtEmail } = req.params;
    const updateData = req.body;
    
    // Build dynamic update query
    const fields = Object.keys(updateData).filter(key => key !== 'vt_email');
    const values = fields.map((field, index) => `${field} = $${index + 2}`);
    
    const query = `
      UPDATE users 
      SET ${values.join(', ')}, updated_at = NOW()
      WHERE vt_email = $1 
      RETURNING *
    `;
    
    const result = await pool.query(query, [vtEmail, ...fields.map(field => updateData[field])]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Clear cache if schedule or match list was updated
    if (updateData.match_list || updateData.crn1 || updateData.crn2 || updateData.crn3 || 
        updateData.crn4 || updateData.crn5 || updateData.crn6 || updateData.crn7 || updateData.crn8) {
      await clearUserCache(vtEmail);
      if (updateData.match_list) {
        await clearCacheForUsersWithMatch(vtEmail);
      }
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

app.get('/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
    res.json({ users: result.rows });
  } catch (error) {
    console.error('Error getting users:', error);
    res.status(500).json({ error: 'Failed to get users' });
  }
});

// Delete user endpoint
app.delete('/users/:vtEmail', async (req, res) => {
  try {
    const { vtEmail } = req.params;
    
    const result = await pool.query(
      'DELETE FROM users WHERE vt_email = $1 RETURNING *',
      [vtEmail]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ 
      success: true, 
      message: 'User deleted successfully',
      user: result.rows[0]
    });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Failed to delete user' });
  }
});

// VT Integration endpoint - for VT website to send user data
app.post('/vt-import', async (req, res) => {
  try {
    const { vtEmail, name, crns, matchList = [] } = req.body;
    
    // Validate required fields
    if (!vtEmail || !name || !crns || !Array.isArray(crns)) {
      return res.status(400).json({ 
        error: 'Missing required fields: vtEmail, name, crns (array)' 
      });
    }
    
    // Ensure vtEmail is just the PID (before @vt.edu)
    const cleanVtEmail = vtEmail.replace('@vt.edu', '').toLowerCase();
    
    // Generate unique 6-digit activation code
    const activationCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Hash the activation code (temporary password)
    const passwordHash = await bcrypt.hash(activationCode, 10);
    
    // Check if user already exists
    const existingUser = await pool.query(
      'SELECT * FROM users WHERE vt_email = $1',
      [cleanVtEmail]
    );
    
    if (existingUser.rows.length > 0) {
      return res.status(409).json({ 
        error: 'User already exists',
        message: 'User with this VT email already exists in the system'
      });
    }
    
    // Ensure matchList is an array and log for debugging
    const finalMatchList = Array.isArray(matchList) ? matchList : [];
    console.log(`DEBUG: Inserting matchList for ${cleanVtEmail}:`, finalMatchList);
    console.log(`DEBUG: matchList type:`, typeof finalMatchList);
    console.log(`DEBUG: matchList length:`, finalMatchList.length);
    
    // Create user with VT data including match_list
    const result = await pool.query(
      `INSERT INTO users (
        vt_email, name, password_hash, activated, 
        crn1, crn2, crn3, crn4, crn5, crn6, crn7, crn8,
        match_list
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13) 
      RETURNING *`,
      [
        cleanVtEmail, name, passwordHash, false, // activated = false
        crns[0] || null, crns[1] || null, crns[2] || null, crns[3] || null,
        crns[4] || null, crns[5] || null, crns[6] || null, crns[7] || null,
        finalMatchList // Pass the array directly to pg
      ]
    );
    
    const newUser = result.rows[0];
    console.log(`DEBUG: User created with match_list:`, newUser.match_list);
    
    // TODO: Send activation email to user
    // For now, just log the email details
    console.log(`
    ===== VT USER IMPORTED =====
    PID: ${cleanVtEmail}
    Full Email: ${cleanVtEmail}@vt.edu
    Name: ${name}
    Activation Code: ${activationCode}
    CRNs: ${crns.join(', ')}
    Match List: ${finalMatchList.join(', ')}
    ============================
    `);
    
    res.json({
      success: true,
      message: 'User imported successfully',
      user: {
        vtEmail: newUser.vt_email,
        fullEmail: `${newUser.vt_email}@vt.edu`,
        name: newUser.name,
        activated: newUser.activated,
        activationCode: activationCode, // Only for development - remove in production
        matchList: newUser.match_list || []
      }
    });
    
  } catch (error) {
    console.error('Error importing VT user:', error);
    res.status(500).json({ error: 'Failed to import VT user' });
  }
});

// VT activation endpoint - for users to activate with code
app.post('/vt-activate', async (req, res) => {
  try {
    console.log('--- /vt-activate endpoint called ---');
    const { vtEmail, activationCode, newPassword } = req.body;
    
    // Validate required fields
    if (!vtEmail || !activationCode) {
      console.log('Missing required fields:', { vtEmail, activationCode });
      return res.status(400).json({ 
        error: 'Missing required fields: vtEmail, activationCode' 
      });
    }
    
    // Get user from database
    const userResult = await pool.query(
      'SELECT * FROM users WHERE vt_email = $1',
      [vtEmail]
    );
    
    if (userResult.rows.length === 0) {
      console.log('User not found for vtEmail:', vtEmail);
      return res.status(404).json({ error: 'User not found' });
    }
    
    const user = userResult.rows[0];
    
    // Debug logging
    console.log('--- VT-Activate Debug ---');
    console.log('VT PID:', vtEmail);
    console.log('Activation code (input):', activationCode);
    console.log('Password hash (from DB):', user.password_hash);
    
    // Check if user is already activated
    if (user.activated) {
      console.log('User is already activated.');
      return res.status(400).json({ error: 'User is already activated' });
    }
    
    // Verify activation code using bcrypt.compare
    const isValidCode = await bcrypt.compare(activationCode, user.password_hash);
    console.log('bcrypt.compare result:', isValidCode);
    if (!isValidCode) {
      console.log('Invalid activation code.');
      return res.status(401).json({ error: 'Invalid activation code' });
    }
    
    // Always activate user when valid code is provided
    // If newPassword is provided, update password too
    if (newPassword) {
      const newPasswordHash = await bcrypt.hash(newPassword, 10);
      
      await pool.query(
        'UPDATE users SET password_hash = $1, activated = $2, updated_at = NOW() WHERE vt_email = $3',
        [newPasswordHash, true, vtEmail]
      );
      
      console.log('User activated and password updated.');
      res.json({
        success: true,
        message: 'User activated successfully',
        user: {
          vtEmail: user.vt_email,
          name: user.name,
          activated: true
        }
      });
    } else {
      // Just activate the user with the existing activation code as password
      await pool.query(
        'UPDATE users SET activated = $1, updated_at = NOW() WHERE vt_email = $2',
        [true, vtEmail]
      );
      
      console.log('User activated (no password change).');
      res.json({
        success: true,
        message: 'User activated successfully',
        user: {
          vtEmail: user.vt_email,
          name: user.name,
          activated: true
        }
      });
    }
    
    console.log('--- End VT-Activate Debug ---');
  } catch (error) {
    console.error('Error activating VT user:', error);
    res.status(500).json({ error: 'Failed to activate user' });
  }
});

// Course endpoints
app.post('/courses', async (req, res) => {
  try {
    const courseData = req.body;
    
    const result = await pool.query(
      `INSERT INTO courses (
        crn, subject, course_number, course_name, credits, time, days, 
        location, instructor, campus, term, schedule_type, modality, 
        capacity, begin_time, end_time, exam_code
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17) 
      RETURNING *`,
      [
        courseData.crn, courseData.subject, courseData.courseNumber, courseData.courseName,
        courseData.credits, courseData.time, courseData.days, courseData.location,
        courseData.instructor, courseData.campus, courseData.term, courseData.scheduleType,
        courseData.modality, courseData.capacity, courseData.beginTime, courseData.endTime,
        courseData.examCode
      ]
    );
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error creating course:', error);
    res.status(500).json({ error: 'Failed to create course' });
  }
});

app.get('/courses/:crn', async (req, res) => {
  try {
    const { crn } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM courses WHERE crn = $1',
      [crn]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Course not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error getting course:', error);
    res.status(500).json({ error: 'Failed to get course' });
  }
});

app.put('/courses/:crn', async (req, res) => {
  try {
    const { crn } = req.params;
    const updateData = req.body;
    
    const fields = Object.keys(updateData);
    const values = fields.map((field, index) => `${field} = $${index + 2}`);
    
    const query = `
      UPDATE courses 
      SET ${values.join(', ')}, last_updated = NOW()
      WHERE crn = $1 
      RETURNING *
    `;
    
    const result = await pool.query(query, [crn, ...fields.map(field => updateData[field])]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Course not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating course:', error);
    res.status(500).json({ error: 'Failed to update course' });
  }
});

// Login endpoint
app.post('/login', async (req, res) => {
  try {
    const { vtEmail, password } = req.body;
    
    if (!vtEmail || !password) {
      return res.status(400).json({ error: 'Missing vtEmail or password' });
    }
    
    // Get user from database
    const userResult = await pool.query(
      'SELECT * FROM users WHERE vt_email = $1',
      [vtEmail.trim()]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const user = userResult.rows[0];
    
    // Check if user is activated
    if (!user.activated) {
      return res.status(401).json({ error: 'Account not activated. Please use the setup screen to activate your account.' });
    }
    
    // Verify password using bcrypt.compare
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    res.json({
      success: true,
      user: {
        vtEmail: user.vt_email,
        name: user.name,
        activated: user.activated,
        crn1: user.crn1,
        crn2: user.crn2,
        crn3: user.crn3,
        crn4: user.crn4,
        crn5: user.crn5,
        crn6: user.crn6,
        crn7: user.crn7,
        crn8: user.crn8,
        matchList: user.match_list || [],
        location: user.location
      }
    });
    
  } catch (error) {
    console.error('Error logging in:', error);
    res.status(500).json({ error: 'Failed to log in' });
  }
});

// Get user by activation code
app.post('/get-user-by-code', async (req, res) => {
  try {
    const { activationCode } = req.body;
    
    if (!activationCode) {
      return res.status(400).json({ error: 'Missing activation code' });
    }
    
    // Get all users and check which one has this activation code
    const usersResult = await pool.query('SELECT * FROM users WHERE activated = false');
    
    for (const user of usersResult.rows) {
      const isValidCode = await bcrypt.compare(activationCode, user.password_hash);
      if (isValidCode) {
        return res.json({
          success: true,
          user: {
            vtEmail: user.vt_email,
            name: user.name,
            activated: user.activated
          }
        });
      }
    }
    
    res.status(404).json({ error: 'Invalid activation code' });
    
  } catch (error) {
    console.error('Error getting user by code:', error);
    res.status(500).json({ error: 'Failed to get user by code' });
  }
});

// Generate new activation code for testing
app.post('/users/:vtEmail/new-activation-code', async (req, res) => {
  try {
    const { vtEmail } = req.params;
    
    // Check if user exists
    const userResult = await pool.query(
      'SELECT * FROM users WHERE vt_email = $1',
      [vtEmail]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Generate new activation code
    const newActivationCode = Math.floor(100000 + Math.random() * 900000).toString();
    const passwordHash = await bcrypt.hash(newActivationCode, 10);
    
    // Update user with new activation code
    await pool.query(
      'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE vt_email = $2',
      [passwordHash, vtEmail]
    );
    
    res.json({
      success: true,
      message: 'New activation code generated',
      user: {
        vtEmail: vtEmail,
        name: userResult.rows[0].name,
        activationCode: newActivationCode
      }
    });
    
  } catch (error) {
    console.error('Error generating activation code:', error);
    res.status(500).json({ error: 'Failed to generate activation code' });
  }
});

// Match endpoints
app.post('/matches', async (req, res) => {
  try {
    const { user1Email, user2Email, sharedCourses, matchStrength = 1 } = req.body;
    
    const result = await pool.query(
      'INSERT INTO matches (user1_email, user2_email, shared_courses, match_strength) VALUES ($1, $2, $3, $4) RETURNING *',
      [user1Email, user2Email, sharedCourses, matchStrength]
    );
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error creating match:', error);
    res.status(500).json({ error: 'Failed to create match' });
  }
});

app.get('/matches/user/:vtEmail', async (req, res) => {
  try {
    const { vtEmail } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM matches WHERE user1_email = $1 OR user2_email = $1',
      [vtEmail]
    );
    
    res.json({ matches: result.rows });
  } catch (error) {
    console.error('Error getting matches:', error);
    res.status(500).json({ error: 'Failed to get matches' });
  }
});

// Batch operations
app.put('/users/batch', async (req, res) => {
  try {
    const { users } = req.body;
    const results = [];
    
    for (const user of users) {
      const result = await pool.query(
        `UPDATE users 
         SET name = $1, crn1 = $2, crn2 = $3, crn3 = $4, crn4 = $5, 
             crn5 = $6, crn6 = $7, crn7 = $8, crn8 = $9, match_list = $10,
             location = $11, last_schedule_update = NOW(), updated_at = NOW()
         WHERE vt_email = $12 
         RETURNING *`,
        [
          user.name, user.crn1, user.crn2, user.crn3, user.crn4,
          user.crn5, user.crn6, user.crn7, user.crn8, user.matchList,
          user.location, user.vtEmail
        ]
      );
      
      if (result.rows.length > 0) {
        results.push(result.rows[0]);
      }
    }
    
    res.json({ updated: results.length, users: results });
  } catch (error) {
    console.error('Error batch updating users:', error);
    res.status(500).json({ error: 'Failed to batch update users' });
  }
});

app.put('/courses/batch', async (req, res) => {
  try {
    const { courses } = req.body;
    const results = [];
    
    for (const course of courses) {
      const result = await pool.query(
        `INSERT INTO courses (
          crn, subject, course_number, course_name, credits, time, days,
          location, instructor, campus, term, schedule_type, modality,
          capacity, begin_time, end_time, exam_code
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
        ON CONFLICT (crn) DO UPDATE SET
          subject = EXCLUDED.subject,
          course_number = EXCLUDED.course_number,
          course_name = EXCLUDED.course_name,
          credits = EXCLUDED.credits,
          time = EXCLUDED.time,
          days = EXCLUDED.days,
          location = EXCLUDED.location,
          instructor = EXCLUDED.instructor,
          campus = EXCLUDED.campus,
          term = EXCLUDED.term,
          schedule_type = EXCLUDED.schedule_type,
          modality = EXCLUDED.modality,
          capacity = EXCLUDED.capacity,
          begin_time = EXCLUDED.begin_time,
          end_time = EXCLUDED.end_time,
          exam_code = EXCLUDED.exam_code,
          last_updated = NOW()
        RETURNING *`,
        [
          course.crn, course.subject, course.courseNumber, course.courseName,
          course.credits, course.time, course.days, course.location,
          course.instructor, course.campus, course.term, course.scheduleType,
          course.modality, course.capacity, course.beginTime, course.endTime,
          course.examCode
        ]
      );
      
      results.push(result.rows[0]);
    }
    
    res.json({ updated: results.length, courses: results });
  } catch (error) {
    console.error('Error batch updating courses:', error);
    res.status(500).json({ error: 'Failed to batch update courses' });
  }
});

// Initialize database and start server
async function startServer() {
  try {
    await initializeDatabase();
    
    app.listen(port, () => {
      console.log(`🚀 Between API server running on port ${port}`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

startServer(); 