-- 1. Roles (already present)
CREATE TABLE IF NOT EXISTS roles (
  id   SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL
);
INSERT INTO roles(name) VALUES ('learner'), ('teacher'), ('admin')
ON CONFLICT DO NOTHING;

-- 2. Subjects (MISSING – add this)
CREATE TABLE IF NOT EXISTS subjects (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(120) NOT NULL,
  slug        VARCHAR(140) UNIQUE NOT NULL,
  description TEXT,
  color       VARCHAR(30), 
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE subjects
ADD COLUMN IF NOT EXISTS color VARCHAR(30);

-- 3. Users (already present)
CREATE TABLE IF NOT EXISTS users (
  id            BIGSERIAL PRIMARY KEY,
  name          VARCHAR(120) NOT NULL,
  email         VARCHAR(180) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role_id       INT REFERENCES roles(id),
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Teacher Profiles

CREATE TABLE IF NOT EXISTS teacher_profiles (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bio TEXT,
  specialization VARCHAR(220),
  qualification VARCHAR(220),
  experience_years INT DEFAULT 0,
  profile_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Learner Profiles

CREATE TABLE IF NOT EXISTS learner_profiles (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bio TEXT,
  school VARCHAR(220),
  education_level VARCHAR(120),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Courses (MISSING – add this)
CREATE TABLE IF NOT EXISTS courses (
  id          BIGSERIAL PRIMARY KEY,
  subject_id  INT REFERENCES subjects(id) ON DELETE CASCADE,
  title       VARCHAR(220) NOT NULL,
  slug        VARCHAR(240) UNIQUE NOT NULL,
  description TEXT,
  is_premium  BOOLEAN DEFAULT TRUE,
  is_published BOOLEAN DEFAULT TRUE,
  published   BOOLEAN DEFAULT TRUE,
  created_by  BIGINT REFERENCES users(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE courses
ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT TRUE;

ALTER TABLE courses
ADD COLUMN IF NOT EXISTS published BOOLEAN DEFAULT TRUE;

-- 7. Then the rest of your tables (topics, lessons, quizzes, etc.)
CREATE TABLE IF NOT EXISTS topics (
  id          BIGSERIAL PRIMARY KEY,
  subject_id  INT REFERENCES subjects(id) ON DELETE CASCADE,
  name        VARCHAR(180) NOT NULL,
  slug        VARCHAR(180) NOT NULL,
  description TEXT,
  UNIQUE (subject_id, slug)
);

CREATE TABLE IF NOT EXISTS lessons (
  id               BIGSERIAL PRIMARY KEY,
  topic_id         BIGINT REFERENCES topics(id) ON DELETE CASCADE,
  title            VARCHAR(220) NOT NULL,
  slug             VARCHAR(240) UNIQUE NOT NULL,
  content          TEXT,
  content_html     TEXT,
  duration_minutes INT DEFAULT 0,
  level            VARCHAR(50),
  is_premium       BOOLEAN DEFAULT TRUE,
  published        BOOLEAN DEFAULT TRUE,
  created_by       BIGINT REFERENCES users(id),
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS content_html TEXT;

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS duration_minutes INT DEFAULT 0;

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS level VARCHAR(50);

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT TRUE;

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS published BOOLEAN DEFAULT TRUE;

ALTER TABLE lessons
ADD COLUMN IF NOT EXISTS created_by BIGINT REFERENCES users(id);

CREATE TABLE IF NOT EXISTS quizzes (
  id          BIGSERIAL PRIMARY KEY,
  lesson_id   BIGINT REFERENCES lessons(id) ON DELETE CASCADE,
  title       VARCHAR(220) NOT NULL,
  slug        VARCHAR(240) UNIQUE NOT NULL,
  description TEXT,
  course_id   BIGINT REFERENCES courses(id) ON DELETE CASCADE,
  is_published BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE quizzes
ADD COLUMN IF NOT EXISTS description TEXT;

ALTER TABLE quizzes
ADD COLUMN IF NOT EXISTS course_id BIGINT REFERENCES courses(id) ON DELETE CASCADE;

ALTER TABLE quizzes
ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT TRUE;

CREATE TABLE IF NOT EXISTS questions (
  id          BIGSERIAL PRIMARY KEY,
  quiz_id     BIGINT REFERENCES quizzes(id) ON DELETE CASCADE,
  question    TEXT,
  prompt      TEXT,
  options     JSONB,
  correct_option INT,
  position    INT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE questions
ADD COLUMN IF NOT EXISTS prompt TEXT;

ALTER TABLE questions
ADD COLUMN IF NOT EXISTS options JSONB;

ALTER TABLE questions
ADD COLUMN IF NOT EXISTS correct_option INT;

ALTER TABLE questions
ADD COLUMN IF NOT EXISTS position INT;

ALTER TABLE questions
ALTER COLUMN question DROP NOT NULL;

CREATE TABLE IF NOT EXISTS lesson_resources (
  id          BIGSERIAL PRIMARY KEY,
  lesson_id   BIGINT REFERENCES lessons(id) ON DELETE CASCADE,
  title       VARCHAR(220) NOT NULL,
  type        VARCHAR(50),
  url         TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE lesson_resources
ADD COLUMN IF NOT EXISTS type VARCHAR(50);

ALTER TABLE lesson_resources
ADD COLUMN IF NOT EXISTS url TEXT;

CREATE TABLE IF NOT EXISTS articles (
  id            BIGSERIAL PRIMARY KEY,
  title         VARCHAR(220) NOT NULL,
  slug          VARCHAR(240) UNIQUE NOT NULL,
  excerpt       TEXT,
  content_html  TEXT,
  subject_id    INT REFERENCES subjects(id) ON DELETE SET NULL,
  author_id     BIGINT REFERENCES users(id) ON DELETE SET NULL,
  status        VARCHAR(50) NOT NULL DEFAULT 'draft',
  published_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS answers (
  id          BIGSERIAL PRIMARY KEY,
  question_id BIGINT REFERENCES questions(id) ON DELETE CASCADE,
  answer      TEXT NOT NULL,
  is_correct  BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS enrollments (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT REFERENCES users(id) ON DELETE CASCADE,
  course_id   BIGINT REFERENCES courses(id) ON DELETE CASCADE,
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, course_id)
);

CREATE TABLE IF NOT EXISTS progress (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT REFERENCES users(id) ON DELETE CASCADE,
  lesson_id   BIGINT REFERENCES lessons(id) ON DELETE CASCADE,
  completed   BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS quiz_attempts (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT REFERENCES users(id) ON DELETE CASCADE,
  quiz_id     BIGINT REFERENCES quizzes(id) ON DELETE CASCADE,
  score       INT,
  attempted_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, quiz_id)
);

CREATE TABLE IF NOT EXISTS quiz_attempt_answers (
  id          BIGSERIAL PRIMARY KEY,
  quiz_attempt_id BIGINT REFERENCES quiz_attempts(id) ON DELETE CASCADE,
  question_id BIGINT REFERENCES questions(id) ON DELETE CASCADE,
  answer_id   BIGINT REFERENCES answers(id) ON DELETE CASCADE,
  UNIQUE (quiz_attempt_id, question_id)
);

CREATE TABLE IF NOT EXISTS course_reviews (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT REFERENCES users(id) ON DELETE CASCADE,
  course_id   BIGINT REFERENCES courses(id) ON DELETE CASCADE,
  rating      INT CHECK (rating >= 1 AND rating <= 5),
  comment     TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, course_id)
);

CREATE TABLE IF NOT EXISTS course_materials (
  id          BIGSERIAL PRIMARY KEY,
  course_id   BIGINT REFERENCES courses(id) ON DELETE CASCADE,
  title       VARCHAR(220) NOT NULL,
  file_url    TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS announcements (
  id          BIGSERIAL PRIMARY KEY,
  course_id   BIGINT REFERENCES courses(id) ON DELETE CASCADE,
  title       VARCHAR(220) NOT NULL,
  content     TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ... continue with the rest of your schema