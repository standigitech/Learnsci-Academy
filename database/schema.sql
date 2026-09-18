-- ============================================================
-- LearnSci EdTech Platform
-- PostgreSQL / Neon Database Schema
-- ============================================================
--
-- Core architecture:
-- Users → Roles
-- Learners → Courses → Topics → Lessons → Resources
-- Lessons → Quizzes → Questions → Answers
-- Learners → Progress / Attempts / Enrollments
-- Users → Subscriptions → Payments
-- Courses → Live Classes / Reviews / Materials / Announcements
-- Learners → Exams / Certificates / Bookmarks / Notifications
--
-- Payment gate:
-- REGISTER → SUBSCRIBE → PAYMENT VERIFIED → ACTIVE SUBSCRIPTION
--         → PREMIUM ACCESS
--
-- ============================================================


-- ============================================================
-- 1. ROLES
-- ============================================================

CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO roles (name)
VALUES
    ('learner'),
    ('teacher'),
    ('admin')
ON CONFLICT (name) DO NOTHING;


-- ============================================================
-- 2. USERS
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,

    name VARCHAR(120) NOT NULL,

    email VARCHAR(180) UNIQUE NOT NULL,

    password_hash TEXT NOT NULL,

    role_id INT REFERENCES roles(id)
        ON DELETE SET NULL,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    email_verified BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 3. SUBJECTS
-- ============================================================

CREATE TABLE IF NOT EXISTS subjects (
    id SERIAL PRIMARY KEY,

    name VARCHAR(120) NOT NULL,

    slug VARCHAR(140) UNIQUE NOT NULL,

    description TEXT,

    color VARCHAR(30),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 4. TEACHER PROFILES
-- ============================================================

CREATE TABLE IF NOT EXISTS teacher_profiles (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT UNIQUE NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    bio TEXT,

    specialization VARCHAR(220),

    qualification VARCHAR(220),

    experience_years INT DEFAULT 0,

    profile_image_url TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 5. LEARNER PROFILES
-- ============================================================

CREATE TABLE IF NOT EXISTS learner_profiles (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT UNIQUE NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    bio TEXT,

    school VARCHAR(220),

    education_level VARCHAR(120),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 6. TOPICS
-- ============================================================

CREATE TABLE IF NOT EXISTS topics (
    id BIGSERIAL PRIMARY KEY,

    subject_id INT NOT NULL
        REFERENCES subjects(id)
        ON DELETE CASCADE,

    name VARCHAR(180) NOT NULL,

    slug VARCHAR(180) NOT NULL,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (subject_id, slug)
);


-- ============================================================
-- 7. COURSES
-- ============================================================

CREATE TABLE IF NOT EXISTS courses (
    id BIGSERIAL PRIMARY KEY,

    subject_id INT
        REFERENCES subjects(id)
        ON DELETE CASCADE,

    title VARCHAR(220) NOT NULL,

    slug VARCHAR(240) UNIQUE NOT NULL,

    description TEXT,

    is_premium BOOLEAN NOT NULL DEFAULT TRUE,

    is_published BOOLEAN NOT NULL DEFAULT TRUE,

    created_by BIGINT
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 8. LESSONS
-- ============================================================

CREATE TABLE IF NOT EXISTS lessons (
    id BIGSERIAL PRIMARY KEY,

    topic_id BIGINT
        REFERENCES topics(id)
        ON DELETE CASCADE,

    title VARCHAR(220) NOT NULL,

    slug VARCHAR(240) UNIQUE NOT NULL,

    content TEXT,

    content_html TEXT,

    duration_minutes INT NOT NULL DEFAULT 0,

    level VARCHAR(50),

    is_premium BOOLEAN NOT NULL DEFAULT TRUE,

    published BOOLEAN NOT NULL DEFAULT TRUE,

    created_by BIGINT
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 9. LESSON RESOURCES
-- ============================================================

CREATE TABLE IF NOT EXISTS lesson_resources (
    id BIGSERIAL PRIMARY KEY,

    lesson_id BIGINT NOT NULL
        REFERENCES lessons(id)
        ON DELETE CASCADE,

    title VARCHAR(220) NOT NULL,

    type VARCHAR(50),

    url TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 10. COURSE MATERIALS
-- ============================================================

CREATE TABLE IF NOT EXISTS course_materials (
    id BIGSERIAL PRIMARY KEY,

    course_id BIGINT NOT NULL
        REFERENCES courses(id)
        ON DELETE CASCADE,

    title VARCHAR(220) NOT NULL,

    file_url TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 11. ARTICLES
-- ============================================================

CREATE TABLE IF NOT EXISTS articles (
    id BIGSERIAL PRIMARY KEY,

    title VARCHAR(220) NOT NULL,

    slug VARCHAR(240) UNIQUE NOT NULL,

    excerpt TEXT,

    content_html TEXT,

    subject_id INT
        REFERENCES subjects(id)
        ON DELETE SET NULL,

    author_id BIGINT
        REFERENCES users(id)
        ON DELETE SET NULL,

    status VARCHAR(50) NOT NULL DEFAULT 'draft',

    published_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 12. QUIZZES
-- ============================================================

CREATE TABLE IF NOT EXISTS quizzes (
    id BIGSERIAL PRIMARY KEY,

    lesson_id BIGINT
        REFERENCES lessons(id)
        ON DELETE CASCADE,

    course_id BIGINT
        REFERENCES courses(id)
        ON DELETE CASCADE,

    title VARCHAR(220) NOT NULL,

    slug VARCHAR(240) UNIQUE NOT NULL,

    description TEXT,

    is_published BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 13. QUESTIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS questions (
    id BIGSERIAL PRIMARY KEY,

    quiz_id BIGINT
        REFERENCES quizzes(id)
        ON DELETE CASCADE,

    prompt TEXT NOT NULL,

    options JSONB,

    correct_option INT,

    position INT NOT NULL DEFAULT 1,

    marks INT NOT NULL DEFAULT 1,

    explanation TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 14. ANSWERS
-- ============================================================

CREATE TABLE IF NOT EXISTS answers (
    id BIGSERIAL PRIMARY KEY,

    question_id BIGINT NOT NULL
        REFERENCES questions(id)
        ON DELETE CASCADE,

    answer TEXT NOT NULL,

    is_correct BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 15. ENROLLMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS enrollments (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    course_id BIGINT NOT NULL
        REFERENCES courses(id)
        ON DELETE CASCADE,

    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (user_id, course_id)
);


-- ============================================================
-- 16. PROGRESS
-- ============================================================

CREATE TABLE IF NOT EXISTS progress (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    lesson_id BIGINT NOT NULL
        REFERENCES lessons(id)
        ON DELETE CASCADE,

    completed BOOLEAN NOT NULL DEFAULT FALSE,

    progress_percent INT NOT NULL DEFAULT 0,

    last_position INT DEFAULT 0,

    completed_at TIMESTAMPTZ,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (user_id, lesson_id),

    CHECK (progress_percent >= 0 AND progress_percent <= 100)
);


-- ============================================================
-- 17. QUIZ ATTEMPTS
-- ============================================================

CREATE TABLE IF NOT EXISTS quiz_attempts (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    quiz_id BIGINT NOT NULL
        REFERENCES quizzes(id)
        ON DELETE CASCADE,

    score INT,

    total_marks INT,

    percentage NUMERIC(5,2),

    started_at TIMESTAMPTZ DEFAULT NOW(),

    completed_at TIMESTAMPTZ,

    attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 18. QUIZ ATTEMPT ANSWERS
-- ============================================================

CREATE TABLE IF NOT EXISTS quiz_attempt_answers (
    id BIGSERIAL PRIMARY KEY,

    quiz_attempt_id BIGINT NOT NULL
        REFERENCES quiz_attempts(id)
        ON DELETE CASCADE,

    question_id BIGINT NOT NULL
        REFERENCES questions(id)
        ON DELETE CASCADE,

    answer_id BIGINT
        REFERENCES answers(id)
        ON DELETE SET NULL,

    selected_option INT,

    is_correct BOOLEAN,

    answered_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (quiz_attempt_id, question_id)
);


-- ============================================================
-- 19. EXAMS
-- ============================================================

CREATE TABLE IF NOT EXISTS exams (
    id BIGSERIAL PRIMARY KEY,

    course_id BIGINT
        REFERENCES courses(id)
        ON DELETE CASCADE,

    subject_id INT
        REFERENCES subjects(id)
        ON DELETE SET NULL,

    title VARCHAR(220) NOT NULL,

    slug VARCHAR(240) UNIQUE NOT NULL,

    description TEXT,

    duration_minutes INT NOT NULL DEFAULT 60,

    total_marks INT NOT NULL DEFAULT 0,

    pass_mark INT DEFAULT 50,

    is_premium BOOLEAN NOT NULL DEFAULT TRUE,

    is_published BOOLEAN NOT NULL DEFAULT FALSE,

    starts_at TIMESTAMPTZ,

    ends_at TIMESTAMPTZ,

    created_by BIGINT
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 20. EXAM QUESTIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS exam_questions (
    id BIGSERIAL PRIMARY KEY,

    exam_id BIGINT NOT NULL
        REFERENCES exams(id)
        ON DELETE CASCADE,

    prompt TEXT NOT NULL,

    options JSONB,

    correct_option INT,

    marks INT NOT NULL DEFAULT 1,

    position INT NOT NULL DEFAULT 1,

    explanation TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (exam_id, position)
);


-- ============================================================
-- 21. EXAM ATTEMPTS
-- ============================================================

CREATE TABLE IF NOT EXISTS exam_attempts (
    id BIGSERIAL PRIMARY KEY,

    exam_id BIGINT NOT NULL
        REFERENCES exams(id)
        ON DELETE CASCADE,

    user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    score INT DEFAULT 0,

    total_marks INT DEFAULT 0,

    percentage NUMERIC(5,2),

    status VARCHAR(30) NOT NULL DEFAULT 'in_progress',

    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    submitted_at TIMESTAMPTZ,

    time_remaining_seconds INT,

    UNIQUE (exam_id, user_id)
);


-- ============================================================
-- 22. EXAM ATTEMPT ANSWERS
-- ============================================================

CREATE TABLE IF NOT EXISTS exam_attempt_answers (
    id BIGSERIAL PRIMARY KEY,

    exam_attempt_id BIGINT NOT NULL
        REFERENCES exam_attempts(id)
        ON DELETE CASCADE,

    exam_question_id BIGINT NOT NULL
        REFERENCES exam_questions(id)
        ON DELETE CASCADE,

    selected_option INT,

    answer_text TEXT,

    is_correct BOOLEAN,

    marks_awarded INT DEFAULT 0,

    answered_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (exam_attempt_id, exam_question_id)
);


-- ============================================================
-- 23. COURSE REVIEWS
-- ============================================================

CREATE TABLE IF NOT EXISTS course_reviews (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    course_id BIGINT NOT NULL
        REFERENCES courses(id)
        ON DELETE CASCADE,

    rating INT NOT NULL,

    comment TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (user_id, course_id),

    CHECK (rating >= 1 AND rating <= 5)
);


-- ============================================================
-- 24. BOOKMARKS
-- ============================================================

CREATE TABLE IF NOT EXISTS bookmarks (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    lesson_id BIGINT
        REFERENCES lessons(id)
        ON DELETE CASCADE,

    article_id BIGINT
        REFERENCES articles(id)
        ON DELETE CASCADE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (
        lesson_id IS NOT NULL
        OR article_id IS NOT NULL
    ),

    UNIQUE (user_id, lesson_id, article_id)
);


-- ============================================================
-- 25. SUBSCRIPTIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS subscriptions (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    plan VARCHAR(30) NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'pending',

    amount NUMERIC(12,2) NOT NULL,

    currency VARCHAR(10) NOT NULL DEFAULT 'KES',

    start_date TIMESTAMPTZ,

    end_date TIMESTAMPTZ,

    auto_renew BOOLEAN NOT NULL DEFAULT FALSE,

    provider VARCHAR(30),

    provider_subscription_id TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (plan IN ('monthly', 'annual')),

    CHECK (
        status IN (
            'pending',
            'active',
            'expired',
            'cancelled',
            'failed'
        )
    )
);


-- ============================================================
-- 26. PAYMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS payments (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    subscription_id BIGINT
        REFERENCES subscriptions(id)
        ON DELETE SET NULL,

    provider VARCHAR(30) NOT NULL,

    transaction_reference TEXT,

    provider_transaction_id TEXT,

    amount NUMERIC(12,2) NOT NULL,

    currency VARCHAR(10) NOT NULL DEFAULT 'KES',

    status VARCHAR(30) NOT NULL DEFAULT 'pending',

    phone_number VARCHAR(30),

    metadata JSONB,

    paid_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (
        status IN (
            'pending',
            'processing',
            'successful',
            'failed',
            'cancelled',
            'refunded'
        )
    )
);


-- ============================================================
-- 27. LIVE CLASSES
-- ============================================================

CREATE TABLE IF NOT EXISTS live_classes (
    id BIGSERIAL PRIMARY KEY,

    course_id BIGINT
        REFERENCES courses(id)
        ON DELETE SET NULL,

    subject_id INT
        REFERENCES subjects(id)
        ON DELETE SET NULL,

    teacher_id BIGINT
        REFERENCES users(id)
        ON DELETE SET NULL,

    title VARCHAR(220) NOT NULL,

    description TEXT,

    meeting_url TEXT,

    recording_url TEXT,

    scheduled_at TIMESTAMPTZ NOT NULL,

    duration_minutes INT DEFAULT 60,

    status VARCHAR(30) NOT NULL DEFAULT 'scheduled',

    is_premium BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (
        status IN (
            'scheduled',
            'live',
            'completed',
            'cancelled'
        )
    )
);


-- ============================================================
-- 28. LIVE CLASS ENROLLMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS live_class_enrollments (
    id BIGSERIAL PRIMARY KEY,

    live_class_id BIGINT NOT NULL
        REFERENCES live_classes(id)
        ON DELETE CASCADE,

    user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    joined_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (live_class_id, user_id)
);


-- ============================================================
-- 29. CERTIFICATES
-- ============================================================

CREATE TABLE IF NOT EXISTS certificates (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    course_id BIGINT
        REFERENCES courses(id)
        ON DELETE SET NULL,

    exam_id BIGINT
        REFERENCES exams(id)
        ON DELETE SET NULL,

    certificate_number VARCHAR(120) UNIQUE NOT NULL,

    title VARCHAR(220) NOT NULL,

    issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    certificate_url TEXT,

    verification_code VARCHAR(120) UNIQUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 30. NOTIFICATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS notifications (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    title VARCHAR(220) NOT NULL,

    message TEXT NOT NULL,

    type VARCHAR(50),

    link TEXT,

    is_read BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    read_at TIMESTAMPTZ
);


-- ============================================================
-- 31. ANNOUNCEMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS announcements (
    id BIGSERIAL PRIMARY KEY,

    course_id BIGINT
        REFERENCES courses(id)
        ON DELETE CASCADE,

    title VARCHAR(220) NOT NULL,

    content TEXT NOT NULL,

    created_by BIGINT
        REFERENCES users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 32. PASSWORD RESET TOKENS
-- ============================================================

CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    token_hash TEXT NOT NULL,

    expires_at TIMESTAMPTZ NOT NULL,

    used_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 33. EMAIL VERIFICATION TOKENS
-- ============================================================

CREATE TABLE IF NOT EXISTS email_verification_tokens (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    token_hash TEXT NOT NULL,

    expires_at TIMESTAMPTZ NOT NULL,

    verified_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 34. PAYMENT WEBHOOK EVENTS
-- ============================================================
-- Prevents duplicate processing of Stripe/M-Pesa webhook events.

CREATE TABLE IF NOT EXISTS payment_webhook_events (
    id BIGSERIAL PRIMARY KEY,

    provider VARCHAR(30) NOT NULL,

    event_id VARCHAR(255) NOT NULL,

    event_type VARCHAR(120),

    payload JSONB,

    processed BOOLEAN NOT NULL DEFAULT FALSE,

    processed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (provider, event_id)
);

-- ============================================================
-- EXISTING DATABASE COMPATIBILITY
-- ============================================================
-- These ALTER statements ensure that an existing LearnSci
-- database is upgraded instead of relying only on CREATE TABLE.
-- ============================================================

-- USERS

ALTER TABLE users
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN
DEFAULT FALSE;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ
DEFAULT NOW();


-- TEACHER PROFILES

ALTER TABLE teacher_profiles
ADD COLUMN IF NOT EXISTS bio TEXT;

ALTER TABLE teacher_profiles
ADD COLUMN IF NOT EXISTS specialization VARCHAR(220);

ALTER TABLE teacher_profiles
ADD COLUMN IF NOT EXISTS qualification VARCHAR(220);

ALTER TABLE teacher_profiles
ADD COLUMN IF NOT EXISTS experience_years INT
DEFAULT 0;

ALTER TABLE teacher_profiles
ADD COLUMN IF NOT EXISTS profile_image_url TEXT;

ALTER TABLE teacher_profiles
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ
DEFAULT NOW();


-- LEARNER PROFILES

ALTER TABLE learner_profiles
ADD COLUMN IF NOT EXISTS bio TEXT;

ALTER TABLE learner_profiles
ADD COLUMN IF NOT EXISTS school VARCHAR(220);

ALTER TABLE learner_profiles
ADD COLUMN IF NOT EXISTS education_level VARCHAR(120);

ALTER TABLE learner_profiles
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ
DEFAULT NOW();


-- SUBJECTS

ALTER TABLE subjects
ADD COLUMN IF NOT EXISTS color VARCHAR(30);


-- COURSES

ALTER TABLE courses
ADD COLUMN IF NOT EXISTS created_by BIGINT
REFERENCES users(id)
ON DELETE SET NULL;

ALTER TABLE courses
ADD COLUMN IF NOT EXISTS is_premium BOOLEAN
DEFAULT TRUE;

ALTER TABLE courses
ADD COLUMN IF NOT EXISTS is_published BOOLEAN
DEFAULT TRUE;

ALTER TABLE courses
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ
DEFAULT NOW();


-- LESSONS

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS content_html TEXT;

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS duration_minutes INT
DEFAULT 0;

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS level VARCHAR(50);

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS is_premium BOOLEAN
DEFAULT TRUE;

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS published BOOLEAN
DEFAULT TRUE;

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS created_by BIGINT
REFERENCES users(id)
ON DELETE SET NULL;

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ
DEFAULT NOW();


-- ARTICLES

ALTER TABLE articles
ADD COLUMN IF NOT EXISTS excerpt TEXT;

ALTER TABLE articles
ADD COLUMN IF NOT EXISTS content_html TEXT;

ALTER TABLE articles
ADD COLUMN IF NOT EXISTS subject_id INT
REFERENCES subjects(id)
ON DELETE SET NULL;

ALTER TABLE articles
ADD COLUMN IF NOT EXISTS author_id BIGINT
REFERENCES users(id)
ON DELETE SET NULL;

ALTER TABLE articles
ADD COLUMN IF NOT EXISTS status VARCHAR(50)
DEFAULT 'draft';

ALTER TABLE articles
ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ;

ALTER TABLE articles
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ
DEFAULT NOW();


-- QUIZZES

ALTER TABLE quizzes
ADD COLUMN IF NOT EXISTS lesson_id BIGINT
REFERENCES lessons(id)
ON DELETE CASCADE;

ALTER TABLE quizzes
ADD COLUMN IF NOT EXISTS course_id BIGINT
REFERENCES courses(id)
ON DELETE CASCADE;

ALTER TABLE quizzes
ADD COLUMN IF NOT EXISTS description TEXT;

ALTER TABLE quizzes
ADD COLUMN IF NOT EXISTS is_published BOOLEAN
DEFAULT TRUE;


-- QUESTIONS

ALTER TABLE questions
ADD COLUMN IF NOT EXISTS prompt TEXT;

ALTER TABLE questions
ADD COLUMN IF NOT EXISTS options JSONB;

ALTER TABLE questions
ADD COLUMN IF NOT EXISTS correct_option INT;

ALTER TABLE questions
ADD COLUMN IF NOT EXISTS position INT
DEFAULT 1;

ALTER TABLE questions
ADD COLUMN IF NOT EXISTS marks INT
DEFAULT 1;

ALTER TABLE questions
ADD COLUMN IF NOT EXISTS explanation TEXT;


-- LESSON RESOURCES

ALTER TABLE lesson_resources
ADD COLUMN IF NOT EXISTS type VARCHAR(50);

ALTER TABLE lesson_resources
ADD COLUMN IF NOT EXISTS url TEXT;


-- PROGRESS

ALTER TABLE progress
ADD COLUMN IF NOT EXISTS progress_percent INT
DEFAULT 0;

ALTER TABLE progress
ADD COLUMN IF NOT EXISTS last_position INT
DEFAULT 0;

ALTER TABLE progress
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ
DEFAULT NOW();


-- QUIZ ATTEMPTS

ALTER TABLE quiz_attempts
ADD COLUMN IF NOT EXISTS total_marks INT;

ALTER TABLE quiz_attempts
ADD COLUMN IF NOT EXISTS percentage NUMERIC(5,2);

ALTER TABLE quiz_attempts
ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ;

ALTER TABLE quiz_attempts
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;


-- QUIZ ATTEMPT ANSWERS

ALTER TABLE quiz_attempt_answers
ADD COLUMN IF NOT EXISTS selected_option INT;

ALTER TABLE quiz_attempt_answers
ADD COLUMN IF NOT EXISTS is_correct BOOLEAN;

ALTER TABLE quiz_attempt_answers
ADD COLUMN IF NOT EXISTS answered_at TIMESTAMPTZ;


-- ANNOUNCEMENTS

ALTER TABLE announcements
ADD COLUMN IF NOT EXISTS created_by BIGINT
REFERENCES users(id)
ON DELETE SET NULL;

-- ============================================================
-- 35. INDEXES
-- ============================================================

-- Users

CREATE INDEX IF NOT EXISTS idx_users_role_id
ON users(role_id);

CREATE INDEX IF NOT EXISTS idx_users_email
ON users(email);


-- Subjects / Topics

CREATE INDEX IF NOT EXISTS idx_topics_subject_id
ON topics(subject_id);


-- Courses

CREATE INDEX IF NOT EXISTS idx_courses_subject_id
ON courses(subject_id);

CREATE INDEX IF NOT EXISTS idx_courses_created_by
ON courses(created_by);

CREATE INDEX IF NOT EXISTS idx_courses_published
ON courses(is_published);


-- Lessons

CREATE INDEX IF NOT EXISTS idx_lessons_topic_id
ON lessons(topic_id);

CREATE INDEX IF NOT EXISTS idx_lessons_created_by
ON lessons(created_by);

CREATE INDEX IF NOT EXISTS idx_lessons_published
ON lessons(published);


-- Resources

CREATE INDEX IF NOT EXISTS idx_lesson_resources_lesson_id
ON lesson_resources(lesson_id);


-- Quizzes

CREATE INDEX IF NOT EXISTS idx_quizzes_lesson_id
ON quizzes(lesson_id);

CREATE INDEX IF NOT EXISTS idx_quizzes_course_id
ON quizzes(course_id);


-- Questions

CREATE INDEX IF NOT EXISTS idx_questions_quiz_id
ON questions(quiz_id);


-- Enrollments

CREATE INDEX IF NOT EXISTS idx_enrollments_user_id
ON enrollments(user_id);

CREATE INDEX IF NOT EXISTS idx_enrollments_course_id
ON enrollments(course_id);


-- Progress

CREATE INDEX IF NOT EXISTS idx_progress_user_id
ON progress(user_id);

CREATE INDEX IF NOT EXISTS idx_progress_lesson_id
ON progress(lesson_id);


-- Quiz attempts

CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user_id
ON quiz_attempts(user_id);

CREATE INDEX IF NOT EXISTS idx_quiz_attempts_quiz_id
ON quiz_attempts(quiz_id);


-- Exams

CREATE INDEX IF NOT EXISTS idx_exams_course_id
ON exams(course_id);

CREATE INDEX IF NOT EXISTS idx_exams_subject_id
ON exams(subject_id);

CREATE INDEX IF NOT EXISTS idx_exam_questions_exam_id
ON exam_questions(exam_id);


-- Exam attempts

CREATE INDEX IF NOT EXISTS idx_exam_attempts_user_id
ON exam_attempts(user_id);

CREATE INDEX IF NOT EXISTS idx_exam_attempts_exam_id
ON exam_attempts(exam_id);


-- Articles

CREATE INDEX IF NOT EXISTS idx_articles_subject_id
ON articles(subject_id);

CREATE INDEX IF NOT EXISTS idx_articles_author_id
ON articles(author_id);

CREATE INDEX IF NOT EXISTS idx_articles_status
ON articles(status);


-- Reviews

CREATE INDEX IF NOT EXISTS idx_course_reviews_course_id
ON course_reviews(course_id);


-- Bookmarks

CREATE INDEX IF NOT EXISTS idx_bookmarks_user_id
ON bookmarks(user_id);


-- Subscriptions

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id
ON subscriptions(user_id);

CREATE INDEX IF NOT EXISTS idx_subscriptions_status
ON subscriptions(status);

CREATE INDEX IF NOT EXISTS idx_subscriptions_end_date
ON subscriptions(end_date);


-- Payments

CREATE INDEX IF NOT EXISTS idx_payments_user_id
ON payments(user_id);

CREATE INDEX IF NOT EXISTS idx_payments_subscription_id
ON payments(subscription_id);

CREATE INDEX IF NOT EXISTS idx_payments_status
ON payments(status);

CREATE INDEX IF NOT EXISTS idx_payments_provider
ON payments(provider);

CREATE INDEX IF NOT EXISTS idx_payments_transaction_reference
ON payments(transaction_reference);


-- Live classes

CREATE INDEX IF NOT EXISTS idx_live_classes_teacher_id
ON live_classes(teacher_id);

CREATE INDEX IF NOT EXISTS idx_live_classes_course_id
ON live_classes(course_id);

CREATE INDEX IF NOT EXISTS idx_live_classes_scheduled_at
ON live_classes(scheduled_at);


-- Certificates

CREATE INDEX IF NOT EXISTS idx_certificates_user_id
ON certificates(user_id);

CREATE INDEX IF NOT EXISTS idx_certificates_course_id
ON certificates(course_id);


-- Notifications

CREATE INDEX IF NOT EXISTS idx_notifications_user_id
ON notifications(user_id);

CREATE INDEX IF NOT EXISTS idx_notifications_is_read
ON notifications(is_read);


-- Password reset

CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_user_id
ON password_reset_tokens(user_id);

CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_expires_at
ON password_reset_tokens(expires_at);


-- Email verification

CREATE INDEX IF NOT EXISTS idx_email_verification_tokens_user_id
ON email_verification_tokens(user_id);


-- Webhooks

CREATE INDEX IF NOT EXISTS idx_payment_webhook_events_provider
ON payment_webhook_events(provider);


-- ============================================================
-- 36. UPDATED_AT TRIGGER FUNCTION
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- 37. UPDATED_AT TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS update_users_updated_at
ON users;

CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


DROP TRIGGER IF EXISTS update_teacher_profiles_updated_at
ON teacher_profiles;

CREATE TRIGGER update_teacher_profiles_updated_at
BEFORE UPDATE ON teacher_profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


DROP TRIGGER IF EXISTS update_learner_profiles_updated_at
ON learner_profiles;

CREATE TRIGGER update_learner_profiles_updated_at
BEFORE UPDATE ON learner_profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


DROP TRIGGER IF EXISTS update_courses_updated_at
ON courses;

CREATE TRIGGER update_courses_updated_at
BEFORE UPDATE ON courses
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


DROP TRIGGER IF EXISTS update_lessons_updated_at
ON lessons;

CREATE TRIGGER update_lessons_updated_at
BEFORE UPDATE ON lessons
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


DROP TRIGGER IF EXISTS update_articles_updated_at
ON articles;

CREATE TRIGGER update_articles_updated_at
BEFORE UPDATE ON articles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


DROP TRIGGER IF EXISTS update_subscriptions_updated_at
ON subscriptions;

CREATE TRIGGER update_subscriptions_updated_at
BEFORE UPDATE ON subscriptions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


DROP TRIGGER IF EXISTS update_payments_updated_at
ON payments;

CREATE TRIGGER update_payments_updated_at
BEFORE UPDATE ON payments
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();


-- ============================================================
-- END OF LEARNSCI DATABASE SCHEMA
-- ============================================================