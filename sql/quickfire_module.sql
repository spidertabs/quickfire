-- ============================================================
--  QUICKFIRE MODULE (ASSESSMENTS)
--  Standalone script for Supabase Cloud
-- ============================================================

-- Assessments Metadata
CREATE TABLE IF NOT EXISTS public.quickfire_assessments (
    id                SERIAL       PRIMARY KEY,
    course_id         INT          NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    lecturer_id       INT          NOT NULL REFERENCES public.staff(id)   ON DELETE CASCADE,
    title             VARCHAR(255) NOT NULL,
    description       TEXT,
    duration_minutes  INT,          -- Optional: null means unlimited
    is_active         BOOLEAN      NOT NULL DEFAULT TRUE,
    show_results      BOOLEAN      NOT NULL DEFAULT TRUE, -- Show score to student after submission
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Questions for each Assessment
CREATE TABLE IF NOT EXISTS public.quickfire_questions (
    id                SERIAL       PRIMARY KEY,
    assessment_id     INT          NOT NULL REFERENCES public.quickfire_assessments(id) ON DELETE CASCADE,
    question_text     TEXT         NOT NULL,
    question_type     public.question_type NOT NULL DEFAULT 'multiple_choice',
    options           JSONB,       -- For multiple choice: ["A", "B", "C", "D"]
    correct_answer    TEXT,        -- The correct choice or answer text
    marks             INT          NOT NULL DEFAULT 1,
    min_words         INT,         -- For essay type questions
    max_words         INT,         -- For essay type questions
    sequence_order    INT          NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Student Attempts
CREATE TABLE IF NOT EXISTS public.quickfire_attempts (
    id                SERIAL       PRIMARY KEY,
    assessment_id     INT          NOT NULL REFERENCES public.quickfire_assessments(id) ON DELETE CASCADE,
    student_id        INT          NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    started_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    submitted_at      TIMESTAMPTZ,
    total_score       INT          NOT NULL DEFAULT 0,
    status            VARCHAR(20)  NOT NULL DEFAULT 'in_progress', -- 'in_progress', 'submitted'
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (assessment_id, student_id)
);

-- Individual Question Answers
CREATE TABLE IF NOT EXISTS public.quickfire_answers (
    id                SERIAL       PRIMARY KEY,
    attempt_id        INT          NOT NULL REFERENCES public.quickfire_attempts(id) ON DELETE CASCADE,
    question_id       INT          NOT NULL REFERENCES public.quickfire_questions(id) ON DELETE CASCADE,
    answer_text       TEXT,
    is_correct        BOOLEAN,
    marks_obtained    INT          NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (attempt_id, question_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_qa_course   ON public.quickfire_assessments (course_id);
CREATE INDEX IF NOT EXISTS idx_qa_lecturer ON public.quickfire_assessments (lecturer_id);
CREATE INDEX IF NOT EXISTS idx_qq_assessment ON public.quickfire_questions (assessment_id);
CREATE INDEX IF NOT EXISTS idx_qatt_assessment ON public.quickfire_attempts (assessment_id);
CREATE INDEX IF NOT EXISTS idx_qatt_student    ON public.quickfire_attempts (student_id);

-- Reporting Views for Lecturers
CREATE OR REPLACE VIEW public.vw_quickfire_results AS
SELECT 
    qa.id AS assessment_id,
    qa.title AS assessment_title,
    c.code AS course_code,
    c.title AS course_title,
    s.registration_number,
    s.first_name || ' ' || s.last_name AS student_name,
    qt.id AS attempt_id,
    qt.started_at,
    qt.submitted_at,
    qt.total_score,
    qt.status,
    (SELECT SUM(marks) FROM public.quickfire_questions WHERE assessment_id = qa.id) as max_marks
FROM public.quickfire_attempts qt
JOIN public.quickfire_assessments qa ON qt.assessment_id = qa.id
JOIN public.students s ON qt.student_id = s.id
JOIN public.courses c ON qa.course_id = c.id;

CREATE OR REPLACE VIEW public.vw_quickfire_detailed_answers AS
SELECT 
    qt.id AS attempt_id,
    qa.id AS assessment_id,
    qa.title AS assessment_title,
    s.registration_number,
    s.first_name || ' ' || s.last_name AS student_name,
    qq.question_text,
    qq.correct_answer,
    an.answer_text AS student_answer,
    an.is_correct,
    an.marks_obtained,
    qq.marks AS max_question_marks
FROM public.quickfire_answers an
JOIN public.quickfire_attempts qt ON an.attempt_id = qt.id
JOIN public.quickfire_assessments qa ON qt.assessment_id = qa.id
JOIN public.quickfire_questions qq ON an.question_id = qq.id
JOIN public.students s ON qt.student_id = s.id;

-- Automated Updated At Triggers
DO $$ 
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY['quickfire_assessments', 'quickfire_attempts'] LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = tbl AND table_schema = 'public') THEN
            EXECUTE format('DROP TRIGGER IF EXISTS trg_%I_updated_at ON public.%I', tbl, tbl);
            EXECUTE format('CREATE TRIGGER trg_%I_updated_at BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at()', tbl, tbl);
        END IF;
    END LOOP;
END;
$$;
