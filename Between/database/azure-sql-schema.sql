-- Between Azure SQL Database Schema
-- Compatible with Azure SQL Database and SQL Server 2019+
-- Use this schema for production deployment

-- Schools/Universities table
CREATE TABLE schools (
    id VARCHAR(50) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    email_domain VARCHAR(100) NOT NULL,
    timezone VARCHAR(50) NOT NULL,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    INDEX idx_email_domain (email_domain)
);

-- Students table
CREATE TABLE students (
    id VARCHAR(50) PRIMARY KEY,
    school_id VARCHAR(50) NOT NULL,
    name NVARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    year VARCHAR(50),
    major VARCHAR(100),
    phone_number VARCHAR(20),
    suggested_via VARCHAR(50),
    privacy_share_schedule VARCHAR(20) DEFAULT 'full',
    privacy_share_class_details BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (school_id) REFERENCES schools(id),
    INDEX idx_school_email (school_id, email),
    INDEX idx_school (school_id)
);

-- Course sections table
CREATE TABLE sections (
    section_id VARCHAR(50) PRIMARY KEY,
    school_id VARCHAR(50) NOT NULL,
    canonical_course_id VARCHAR(100) NOT NULL,
    course_code VARCHAR(50) NOT NULL,
    course_name NVARCHAR(255) NOT NULL,
    section_label VARCHAR(20) NOT NULL,
    meeting_days NVARCHAR(100) NOT NULL, -- JSON array stored as string
    start_time VARCHAR(10) NOT NULL,
    end_time VARCHAR(10) NOT NULL,
    location NVARCHAR(255),
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (school_id) REFERENCES schools(id),
    INDEX idx_school_canonical (school_id, canonical_course_id),
    INDEX idx_school_code (school_id, course_code)
);

-- Student enrollments
CREATE TABLE enrollments (
    id INT IDENTITY(1,1) PRIMARY KEY,
    student_id VARCHAR(50) NOT NULL,
    section_id VARCHAR(50) NOT NULL,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(section_id),
    UNIQUE (student_id, section_id),
    INDEX idx_student (student_id),
    INDEX idx_section (section_id)
);

-- Friendships table
CREATE TABLE friendships (
    id INT IDENTITY(1,1) PRIMARY KEY,
    student_a VARCHAR(50) NOT NULL,
    student_b VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    updated_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (student_a) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (student_b) REFERENCES students(id),
    CHECK (student_a < student_b), -- Ensure consistent ordering
    UNIQUE (student_a, student_b),
    INDEX idx_student_a_status (student_a, status),
    INDEX idx_student_b_status (student_b, status)
);

-- Friend requests table
CREATE TABLE friend_requests (
    id VARCHAR(50) PRIMARY KEY,
    from_student_id VARCHAR(50) NOT NULL,
    to_student_id VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (from_student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (to_student_id) REFERENCES students(id),
    INDEX idx_to_status (to_student_id, status),
    INDEX idx_from_status (from_student_id, status)
);

-- Presence/activity status table
CREATE TABLE presence (
    student_id VARCHAR(50) PRIMARY KEY,
    status VARCHAR(20) NOT NULL DEFAULT 'busy',
    activity NVARCHAR(255),
    location NVARCHAR(255),
    last_updated DATETIME2 DEFAULT GETUTCDATE(),
    expires_at DATETIME2,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    INDEX idx_expires (expires_at)
);

-- Plans table
CREATE TABLE plans (
    id VARCHAR(50) PRIMARY KEY,
    creator_id VARCHAR(50) NOT NULL,
    type VARCHAR(50) NOT NULL,
    title NVARCHAR(255) NOT NULL,
    location NVARCHAR(255),
    start_time DATETIME2 NOT NULL,
    visibility VARCHAR(20) NOT NULL DEFAULT 'friends',
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (creator_id) REFERENCES students(id) ON DELETE CASCADE,
    INDEX idx_creator_start (creator_id, start_time),
    INDEX idx_start_time (start_time)
);

-- Interests table
CREATE TABLE interests (
    id VARCHAR(50) PRIMARY KEY,
    school_id VARCHAR(50) NOT NULL,
    name NVARCHAR(100) NOT NULL,
    icon VARCHAR(100),
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (school_id) REFERENCES schools(id),
    INDEX idx_school (school_id)
);

-- Student profiles/preferences table
CREATE TABLE student_profiles (
    student_id VARCHAR(50) PRIMARY KEY,
    interest_ids NVARCHAR(MAX), -- JSON array as string
    onboarding_complete BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    updated_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- Campus events table
CREATE TABLE campus_events (
    id VARCHAR(50) PRIMARY KEY,
    school_id VARCHAR(50) NOT NULL,
    interest_id VARCHAR(50) NOT NULL,
    title NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    location NVARCHAR(255),
    start_time DATETIME2 NOT NULL,
    end_time DATETIME2,
    matching_kind VARCHAR(20) DEFAULT 'partner',
    is_recurring BIT DEFAULT 0,
    recurrence_label NVARCHAR(100),
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (school_id) REFERENCES schools(id),
    FOREIGN KEY (interest_id) REFERENCES interests(id),
    INDEX idx_school_start (school_id, start_time),
    INDEX idx_interest (interest_id)
);

-- Event participations table
CREATE TABLE event_participations (
    id INT IDENTITY(1,1) PRIMARY KEY,
    event_id VARCHAR(50) NOT NULL,
    student_id VARCHAR(50) NOT NULL,
    kind VARCHAR(30) NOT NULL, -- 'interested' or 'lookingForPartner'
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (event_id) REFERENCES campus_events(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    UNIQUE (event_id, student_id),
    INDEX idx_event (event_id),
    INDEX idx_student (student_id)
);

-- Partner seeking profiles table
CREATE TABLE partner_profiles (
    id INT IDENTITY(1,1) PRIMARY KEY,
    event_id VARCHAR(50) NOT NULL,
    student_id VARCHAR(50) NOT NULL,
    display_name NVARCHAR(100) NOT NULL,
    year VARCHAR(50),
    experience_note NVARCHAR(500),
    looking_note NVARCHAR(500),
    social_handle VARCHAR(100),
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (event_id) REFERENCES campus_events(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    UNIQUE (event_id, student_id),
    INDEX idx_event (event_id)
);

-- Course hashes table for privacy (FERPA compliance)
CREATE TABLE course_hashes (
    id INT IDENTITY(1,1) PRIMARY KEY,
    school_id VARCHAR(50) NOT NULL,
    canonical_course_id VARCHAR(100) NOT NULL,
    hash_value VARCHAR(64) NOT NULL UNIQUE, -- SHA-256 hex
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (school_id) REFERENCES schools(id),
    INDEX idx_hash (hash_value),
    INDEX idx_school_canonical (school_id, canonical_course_id)
);

-- Row-level security helper view for friend data
-- Students can only see friends they're connected to
GO
CREATE VIEW friend_connections AS
SELECT 
    CASE 
        WHEN student_a < student_b THEN student_a
        ELSE student_b
    END as student_id,
    CASE 
        WHEN student_a < student_b THEN student_b
        ELSE student_a
    END as friend_id,
    status
FROM friendships
WHERE status = 'accepted';
GO

-- Helper stored procedure for overlap calculation
CREATE PROCEDURE sp_get_friend_overlaps
    @student_id VARCHAR(50),
    @day_index INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Return friends with their sections for the given day
    SELECT DISTINCT
        s.id as friend_id,
        s.name as friend_name,
        sec.section_id,
        sec.start_time,
        sec.end_time,
        sec.meeting_days
    FROM students s
    INNER JOIN friend_connections fc ON (fc.student_id = @student_id AND fc.friend_id = s.id)
        OR (fc.friend_id = @student_id AND fc.student_id = s.id)
    INNER JOIN enrollments e ON e.student_id = s.id
    INNER JOIN sections sec ON sec.section_id = e.section_id
    WHERE sec.meeting_days LIKE '%' + CAST(@day_index AS VARCHAR) + '%';
END;
GO
