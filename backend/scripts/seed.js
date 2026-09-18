import "dotenv/config";
import bcrypt from "bcryptjs";
import pg from "pg";

const { Pool } = pg;

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error("Error: DATABASE_URL is not set or .env is not saved!");
  process.exit(1);
}

const pool = new Pool({
  connectionString,
  ssl: { rejectUnauthorized: false },
});

const query = (text, params) => pool.query(text, params);

async function main() {
  console.log(
    "Connecting to database:",
    connectionString.split("@")[1] || "Neon host"
  );

  const pass = await bcrypt.hash("Password123!", 12);

  // --------------------------------------------------
  // 1. CLEAR EXISTING LEARNSCI DATA
  // --------------------------------------------------

  const existingTables = (
    await query(`
      SELECT tablename
      FROM pg_tables
      WHERE schemaname = 'public'
        AND tablename IN (
          'certificates',
          'live_classes',
          'notifications',
          'announcements',
          'bookmarks',
          'progress',
          'enrollments',
          'exam_attempt_answers',
          'exam_attempts',
          'exam_questions',
          'exams',
          'quiz_attempt_answers',
          'quiz_attempts',
          'answers',
          'questions',
          'quizzes',
          'articles',
          'lesson_resources',
          'course_materials',
          'lessons',
          'topics',
          'courses',
          'subscriptions',
          'payments',
          'payment_webhook_events',
          'learner_profiles',
          'teacher_profiles',
          'users',
          'subjects'
        );
    `)
  ).rows.map((r) => `"${r.tablename}"`);

  if (existingTables.length > 0) {
    console.log("Clearing existing LearnSci seed data...");

    await query(
      `TRUNCATE ${existingTables.join(", ")} RESTART IDENTITY CASCADE`
    );
  }

  // --------------------------------------------------
  // 2. ROLES
  // --------------------------------------------------

  const roles = (
    await query("SELECT id, name FROM roles ORDER BY id")
  ).rows;

  const role = (name) => {
    const found = roles.find(
      (r) => String(r.name).toLowerCase() === name.toLowerCase()
    );

    if (!found) {
      throw new Error(
        `Role "${name}" was not found. Available roles: ${roles
          .map((r) => r.name)
          .join(", ")}`
      );
    }

    return found.id;
  };

  console.log("Roles loaded:", roles.map((r) => r.name).join(", "));

  // --------------------------------------------------
  // 3. TEACHERS
  // --------------------------------------------------

  const teachers = [];

  const teacherData = [
    ["Dr. Jane Mwangi", "teacher@learnsci.test"],
    ["Mr. Peter Otieno", "teacher2@learnsci.test"],
    ["Ms. Amina Noor", "teacher3@learnsci.test"],
  ];

  for (const [name, email] of teacherData) {
    const result = await query(
      `
      INSERT INTO users
        (name, email, password_hash, role_id)
      VALUES
        ($1, $2, $3, $4)
      RETURNING id
      `,
      [name, email, pass, role("teacher")]
    );

    const userId = result.rows[0].id;
    teachers.push(userId);

    await query(
      `
      INSERT INTO teacher_profiles
        (user_id, bio, qualification)
      VALUES
        ($1, $2, $3)
      `,
      [
        userId,
        "Experienced science educator and curriculum specialist.",
        "Bachelor of Education",
      ]
    );
  }

  // --------------------------------------------------
  // 4. LEARNER
  // --------------------------------------------------

  const learner = await query(
    `
    INSERT INTO users
      (name, email, password_hash, role_id)
    VALUES
      ($1, $2, $3, $4)
    RETURNING id
    `,
    ["John Kamau", "learner@learnsci.test", pass, role("learner")]
  );

  await query(
    `
    INSERT INTO learner_profiles
      (user_id, education_level)
    VALUES
      ($1, $2)
    `,
    [learner.rows[0].id, "Secondary"]
  );

  // --------------------------------------------------
  // 5. ADMIN
  // --------------------------------------------------

  await query(
    `
    INSERT INTO users
      (name, email, password_hash, role_id)
    VALUES
      ($1, $2, $3, $4)
    `,
    ["LearnSci Admin", "admin@learnsci.test", pass, role("admin")]
  );

  // --------------------------------------------------
  // 6. SUBJECTS
  // --------------------------------------------------

  const subjects = [
    [
      "Mathematics",
      "mathematics",
      "Algebra, geometry, statistics and mathematical reasoning.",
      "blue",
    ],
    [
      "Chemistry",
      "chemistry",
      "Matter, reactions, organic chemistry and laboratory reasoning.",
      "purple",
    ],
    [
      "Physics",
      "physics",
      "Mechanics, energy, waves, electricity and modern physics.",
      "orange",
    ],
    [
      "Biology",
      "biology",
      "Cells, genetics, ecology, physiology and evolution.",
      "green",
    ],
  ];

  const sub = {};

  for (const s of subjects) {
    const result = await query(
      `
      INSERT INTO subjects
        (name, slug, description, color)
      VALUES
        ($1, $2, $3, $4)
      RETURNING id
      `,
      s
    );

    sub[s[1]] = result.rows[0].id;
  }

  // --------------------------------------------------
  // 7. TOPICS
  // --------------------------------------------------

  const topicNames = {
    mathematics: [
      "Algebra",
      "Functions",
      "Linear Equations",
      "Quadratic Equations",
      "Geometry",
      "Trigonometry",
      "Statistics",
      "Probability",
      "Sequences",
      "Calculus",
    ],

    chemistry: [
      "Atomic Structure",
      "Periodic Table",
      "Chemical Bonding",
      "Mole Concept",
      "Stoichiometry",
      "Acids & Bases",
      "Organic Chemistry",
      "Energetics",
      "Rates of Reaction",
      "Electrochemistry",
    ],

    physics: [
      "Measurement",
      "Motion",
      "Forces",
      "Energy",
      "Momentum",
      "Waves",
      "Thermal Physics",
      "Electricity",
      "Magnetism",
      "Modern Physics",
    ],

    biology: [
      "Cell Structure",
      "Biological Molecules",
      "Enzymes",
      "Genetics",
      "Evolution",
      "Ecology",
      "Human Nutrition",
      "Respiration",
      "Reproduction",
      "Homeostasis",
    ],
  };

  // Store created lessons so quizzes can reference real lesson IDs.
  const lessons = [];

  // --------------------------------------------------
  // 8. TOPICS + LESSONS
  // --------------------------------------------------

  for (const [subjectSlug, names] of Object.entries(topicNames)) {
    for (let i = 0; i < names.length; i++) {
      const topicResult = await query(
        `
        INSERT INTO topics
          (subject_id, name, slug, description)
        VALUES
          ($1, $2, $3, $4)
        RETURNING id
        `,
        [
          sub[subjectSlug],
          names[i],
          `${subjectSlug}-${i + 1}`,
          `Core ${names[i]} concepts with guided examples and practice.`,
        ]
      );

      const topicId = topicResult.rows[0].id;

      // Create 5 lessons per subject = 20 total lessons.
      if (i < 5) {
        const lessonResult = await query(
          `
          INSERT INTO lessons
            (
              topic_id,
              title,
              slug,
              content_html,
              duration_minutes,
              level,
              is_premium,
              published,
              created_by
            )
          VALUES
            ($1, $2, $3, $4, $5, $6, $7, $8, $9)
          RETURNING id
          `,
          [
            topicId,
            `${names[i]}: Core Concepts`,
            `${subjectSlug}-${i + 1}-core-concepts`,
            `
              <h2>${names[i]}</h2>
              <p>
                This lesson introduces the essential ideas,
                vocabulary and worked reasoning for ${names[i]}.
              </p>
              <p>
                <strong>Study approach:</strong>
                read the concept, work through the example,
                then complete the practice questions.
              </p>
            `,
            18 + i * 2,
            "Secondary",
            true,
            true,
            teachers[i % teachers.length],
          ]
        );

        const lessonId = lessonResult.rows[0].id;

        lessons.push({
          id: lessonId,
          subject: subjectSlug,
          topic: names[i],
        });

        await query(
          `
          INSERT INTO lesson_resources
            (lesson_id, title, type, url)
          VALUES
            ($1, $2, $3, $4)
          `,
          [
            lessonId,
            `${names[i]} revision notes`,
            "PDF",
            `https://example.com/learnsci/${subjectSlug}/${i + 1}.pdf`,
          ]
        );
      }
    }
  }

  // --------------------------------------------------
  // 9. COURSES
  // --------------------------------------------------

  const courses = [];

  for (let i = 1; i <= 10; i++) {
    const subjectSlug = subjects[(i - 1) % 4][1];

    const courseResult = await query(
      `
      INSERT INTO courses
        (
          subject_id,
          title,
          slug,
          description,
          is_premium,
          is_published,
          created_by
        )
      VALUES
        ($1, $2, $3, $4, $5, $6, $7)
      RETURNING id
      `,
      [
        sub[subjectSlug],
        `LearnSci Course ${i}`,
        `course-${i}`,
        `Structured course ${i} for progressive mastery.`,
        true,
        true,
        teachers[i % teachers.length],
      ]
    );

    courses.push({
      id: courseResult.rows[0].id,
      subject: subjectSlug,
    });
  }

  // --------------------------------------------------
  // 10. QUIZZES + QUESTIONS
  // --------------------------------------------------

  for (let i = 1; i <= 10; i++) {
    const lesson = lessons[(i - 1) % lessons.length];
    const course = courses[(i - 1) % courses.length];

    const quizResult = await query(
      `
      INSERT INTO quizzes
        (
          lesson_id,
          title,
          slug,
          description,
          course_id
        )
      VALUES
        ($1, $2, $3, $4, $5)
      RETURNING id
      `,
      [
        lesson.id,
        `Revision Quiz ${i}`,
        `quiz-${i}`,
        `A comprehensive revision quiz covering ${lesson.topic}.`,
        course.id,
      ]
    );

    const quizId = quizResult.rows[0].id;

    for (let j = 0; j < 10; j++) {
      await query(
  `
  INSERT INTO questions
    (
      quiz_id,
      question,
      prompt,
      options,
      correct_option,
      position
    )
  VALUES
    ($1, $2, $2, $3, $4, $5)
  `,
  [
    quizId,
    `Question ${j + 1}: Which statement best represents the concept being tested?`,
    JSON.stringify([
      "Option A",
      "Option B",
      "Option C",
      "Option D",
    ]),
    j % 4,
    j + 1,
  ]
);
    }
  }

  // --------------------------------------------------
  // 11. ARTICLES
  // --------------------------------------------------

  for (let i = 1; i <= 10; i++) {
    const subjectSlug = subjects[(i - 1) % 4][1];

    await query(
      `
      INSERT INTO articles
        (
          title,
          slug,
          excerpt,
          content_html,
          subject_id,
          author_id,
          status,
          published_at
        )
      VALUES
        ($1, $2, $3, $4, $5, $6, $7, NOW() - ($8 || ' days')::interval)
      `,
      [
        `Study Strategy ${i}: Building Better Science Habits`,
        `study-strategy-${i}`,
        "Practical guidance for learning science consistently.",
        `
          <h2>Build a repeatable study system</h2>
          <p>
            Use retrieval practice, worked examples,
            spaced review and deliberate practice.
          </p>
        `,
        sub[subjectSlug],
        teachers[i % teachers.length],
        "published",
        i,
      ]
    );
  }

  // --------------------------------------------------
  // 12. FINAL SUMMARY
  // --------------------------------------------------

  console.log("");
  console.log("========================================");
  console.log("✅ LearnSci database seed completed!");
  console.log("========================================");
  console.log("Subjects: 4");
  console.log("Topics: 40");
  console.log("Lessons: 20");
  console.log("Courses: 10");
  console.log("Quizzes: 10");
  console.log("Questions: 100");
  console.log("Articles: 10");
  console.log("Teachers: 3");
  console.log("Learners: 1");
  console.log("Admins: 1");
  console.log("");
  console.log("Test accounts:");
  console.log("Teacher: teacher@learnsci.test");
  console.log("Learner: learner@learnsci.test");
  console.log("Admin: admin@learnsci.test");
  console.log("Password: Password123!");
  console.log("========================================");
}

main()
  .catch((error) => {
    console.error("");
    console.error("❌ Seed execution failed:");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });