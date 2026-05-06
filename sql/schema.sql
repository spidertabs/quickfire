-- ============================================================
--  UEMS-PHD-VV — University Examination Management System
--              & PhD Viva Voce Administration
--
--  PostgreSQL v3.2 (FIXED ORDER)
--  Kampala International University | © 2026 Spider Tabs Ltd
-- ============================================================

SET client_encoding = 'UTF8';

-- ============================================================
--  CUSTOM ENUM TYPES
-- ============================================================

CREATE TYPE programme_level      AS ENUM ('certificate','diploma','bachelors','masters','phd');
CREATE TYPE user_role            AS ENUM ('lecturer','professor','external_examiner','hod','dean','exam_master','viva_coordinator','admin');
CREATE TYPE question_type        AS ENUM ('multiple_choice','true_false','short_answer','essay','practical','case_study');
CREATE TYPE difficulty_level     AS ENUM ('easy','medium','hard');
CREATE TYPE bloom_taxonomy       AS ENUM ('remember','understand','apply','analyze','evaluate','create');
CREATE TYPE exam_type            AS ENUM ('TEST','CAT','FINAL');
CREATE TYPE paper_status         AS ENUM (
    'draft','submitted','hod_review','hod_approved','hod_rejected',
    'dean_review','dean_approved','dean_rejected',
    'ready_for_print','printing','printed','published'
);
CREATE TYPE workflow_action      AS ENUM (
    'created','submitted','hod_approved','hod_rejected',
    'dean_approved','dean_rejected','ready_for_print',
    'printing_started','printed','published','returned','updated'
);
CREATE TYPE comment_type         AS ENUM (
    'feedback','revision_request','hod_approval_note',
    'dean_note','print_instruction','general'
);
CREATE TYPE notification_type    AS ENUM (
    'paper_submitted','paper_approved','paper_rejected',
    'paper_returned','permission_granted','approval_required',
    'ready_for_print','print_completed','comment_added',
    'viva_scheduled','viva_reminder','viva_result',
    'thesis_uploaded','examiner_assigned','general'
);
CREATE TYPE notification_priority AS ENUM ('low','medium','high','urgent');
CREATE TYPE candidate_status     AS ENUM (
    'enrolled','thesis_submitted','viva_scheduled',
    'viva_completed','corrections_pending',
    'corrections_submitted','awarded','withdrawn'
);
CREATE TYPE viva_status          AS ENUM ('scheduled','postponed','cancelled','in_progress','completed');
CREATE TYPE examiner_role        AS ENUM ('chairperson','internal_examiner','external_examiner');
CREATE TYPE viva_outcome         AS ENUM ('pass','pass_with_minor_corrections','pass_with_major_corrections','fail');
CREATE TYPE supervisor_role      AS ENUM ('main', 'co_supervisor', 'advisor');


-- ============================================================
--  ⚠️  UTILITY FUNCTIONS — MUST exist BEFORE any trigger uses them
-- ============================================================

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$ BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
 $$;


-- ============================================================
--  SECTION 1 — ORGANISATIONAL STRUCTURE
-- ============================================================

CREATE TABLE colleges (
    id          SERIAL       PRIMARY KEY,
    code        VARCHAR(50)  NOT NULL UNIQUE,
    name        VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    deleted_at  TIMESTAMPTZ,
    deleted_by  INT,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_colleges_code    ON colleges (code);
CREATE INDEX idx_colleges_deleted ON colleges (deleted_at);


CREATE TABLE departments (
    id          SERIAL       PRIMARY KEY,
    college_id  INT          NOT NULL REFERENCES colleges(id) ON DELETE RESTRICT,
    code        VARCHAR(50)  NOT NULL UNIQUE,
    name        VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    deleted_at  TIMESTAMPTZ,
    deleted_by  INT,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_departments_code    ON departments (code);
CREATE INDEX idx_departments_college ON departments (college_id);
CREATE INDEX idx_departments_deleted ON departments (deleted_at);


CREATE TABLE programmes (
    id             SERIAL           PRIMARY KEY,
    code           VARCHAR(50)      NOT NULL UNIQUE,
    name           VARCHAR(255)     NOT NULL UNIQUE,
    level          programme_level  NOT NULL,
    duration_years INT,
    department_id  INT REFERENCES departments(id) ON DELETE SET NULL,
    college_id     INT REFERENCES colleges(id)    ON DELETE SET NULL,
    description    TEXT,
    is_active      BOOLEAN          NOT NULL DEFAULT TRUE,
    deleted_at     TIMESTAMPTZ,
    deleted_by     INT,
    created_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_programmes_code       ON programmes (code);
CREATE INDEX idx_programmes_department ON programmes (department_id);
CREATE INDEX idx_programmes_college    ON programmes (college_id);
CREATE INDEX idx_programmes_level      ON programmes (level);
CREATE INDEX idx_programmes_active     ON programmes (is_active);
CREATE INDEX idx_programmes_deleted    ON programmes (deleted_at);


-- ============================================================
--  SECTION 2 — USER MANAGEMENT & AUTHENTICATION (staff)
-- ============================================================

CREATE TABLE staff (
    id            SERIAL      PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name    VARCHAR(100) NOT NULL,
    last_name     VARCHAR(100) NOT NULL,
    role          user_role    NOT NULL DEFAULT 'lecturer',
    department_id INT REFERENCES departments(id) ON DELETE SET NULL,
    college_id    INT REFERENCES colleges(id)    ON DELETE SET NULL,
    phone         VARCHAR(20),
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    last_login    TIMESTAMPTZ,
    deleted_at    TIMESTAMPTZ,
    deleted_by    INT,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_staff_email      ON staff (email);
CREATE INDEX idx_staff_role       ON staff (role);
CREATE INDEX idx_staff_department ON staff (department_id);
CREATE INDEX idx_staff_deleted    ON staff (deleted_at);


CREATE TABLE sessions (
    id         SERIAL       PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL UNIQUE,
    user_id    INT          REFERENCES staff(id) ON DELETE CASCADE,
    student_id INT,
    expires_at TIMESTAMPTZ  NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_session_owner
        CHECK (user_id IS NOT NULL OR student_id IS NOT NULL)
);
CREATE INDEX idx_sessions_session_id   ON sessions (session_id);
CREATE INDEX idx_sessions_expires_at   ON sessions (expires_at);
CREATE INDEX idx_sessions_user_expire  ON sessions (user_id, expires_at);


-- ============================================================
--  SECTION 3 — STUDENTS
-- ============================================================

CREATE TABLE students (
    id                  SERIAL       PRIMARY KEY,
    registration_number VARCHAR(50)  NOT NULL UNIQUE,
    email               VARCHAR(255) NOT NULL UNIQUE,
    password_hash       VARCHAR(255) NOT NULL,
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    phone               VARCHAR(20),
    programme_id        INT          REFERENCES programmes(id)  ON DELETE SET NULL,
    college_id          INT          REFERENCES colleges(id)    ON DELETE SET NULL,
    department_id       INT          REFERENCES departments(id) ON DELETE SET NULL,
    enrolment_year      SMALLINT,
    study_year          SMALLINT,
    semester            SMALLINT,
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    last_login          TIMESTAMPTZ,
    deleted_at          TIMESTAMPTZ,
    deleted_by          INT,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_students_registration_number ON students (registration_number);
CREATE INDEX idx_students_email          ON students (email);
CREATE INDEX idx_students_programme      ON students (programme_id);
CREATE INDEX idx_students_college        ON students (college_id);
CREATE INDEX idx_students_department     ON students (department_id);
CREATE INDEX idx_students_deleted        ON students (deleted_at);

-- Add FK for student_id
ALTER TABLE sessions
    ADD CONSTRAINT fk_sessions_student
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE;

-- Trigger
CREATE TRIGGER trg_students_updated_at
    BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


-- ============================================================
--  SECTION 4 — ACADEMIC CONTENT
-- ============================================================

CREATE TABLE courses (
    id            SERIAL       PRIMARY KEY,
    code          VARCHAR(50)  NOT NULL UNIQUE,
    title         VARCHAR(255) NOT NULL,
    level         INT,
    semester      INT,
    credit_units  INT,
    college_id    INT REFERENCES colleges(id)    ON DELETE RESTRICT,
    department_id INT REFERENCES departments(id) ON DELETE RESTRICT,
    hod_id        INT REFERENCES staff(id)       ON DELETE SET NULL,
    description   TEXT,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    deleted_at    TIMESTAMPTZ,
    deleted_by    INT,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_courses_code       ON courses (code);
CREATE INDEX idx_courses_department ON courses (department_id);
CREATE INDEX idx_courses_hod        ON courses (hod_id);
CREATE INDEX idx_courses_deleted    ON courses (deleted_at);


CREATE TABLE study_units (
    id                SERIAL       PRIMARY KEY,
    course_id         INT          NOT NULL REFERENCES courses(id) ON DELETE RESTRICT,
    code              VARCHAR(50)  NOT NULL,
    name              VARCHAR(255) NOT NULL,
    description       TEXT,
    sequence_order    INT          NOT NULL DEFAULT 0,
    learning_outcomes TEXT,
    created_by        INT REFERENCES staff(id) ON DELETE RESTRICT,
    is_active         BOOLEAN      NOT NULL DEFAULT TRUE,
    deleted_at        TIMESTAMPTZ,
    deleted_by        INT,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (course_id, code)
);
CREATE INDEX idx_study_units_course      ON study_units (course_id);
CREATE INDEX idx_study_units_created_by  ON study_units (created_by);
CREATE INDEX idx_study_units_deleted     ON study_units (deleted_at);


-- ============================================================
--  SECTION 5 — QUESTION BANK
-- ============================================================

CREATE TABLE questions (
    id               SERIAL           PRIMARY KEY,
    course_id        INT              NOT NULL REFERENCES courses(id)     ON DELETE RESTRICT,
    study_unit_id    INT              REFERENCES study_units(id)          ON DELETE SET NULL,
    created_by       INT              NOT NULL REFERENCES staff(id)       ON DELETE RESTRICT,
    question_type    question_type    NOT NULL,
    difficulty_level difficulty_level NOT NULL DEFAULT 'medium',
    question_text    TEXT             NOT NULL,
    options          JSONB,
    correct_answer   TEXT,
    marks            INT              NOT NULL DEFAULT 1,
    time_allocation  INT,
    learning_outcome TEXT,
    keywords         JSONB,
    bloom_taxonomy   bloom_taxonomy,
    tags             JSONB,
    usage_count      INT              NOT NULL DEFAULT 0,
    is_active        BOOLEAN          NOT NULL DEFAULT TRUE,
    approved_by      INT              REFERENCES staff(id)                ON DELETE SET NULL,
    approved_at      TIMESTAMPTZ,
    deleted_at       TIMESTAMPTZ,
    deleted_by       INT,
    created_at       TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_options_json CHECK (options  IS NULL OR jsonb_typeof(options)  IS NOT NULL),
    CONSTRAINT chk_tags_json    CHECK (tags     IS NULL OR jsonb_typeof(tags)     IS NOT NULL),
    CONSTRAINT chk_keywords_json CHECK (keywords IS NULL OR jsonb_typeof(keywords) IS NOT NULL)
);
CREATE INDEX idx_questions_course      ON questions (course_id);
CREATE INDEX idx_questions_study_unit  ON questions (study_unit_id);
CREATE INDEX idx_questions_created_by  ON questions (created_by);
CREATE INDEX idx_questions_type        ON questions (question_type);
CREATE INDEX idx_questions_difficulty  ON questions (difficulty_level);
CREATE INDEX idx_questions_approved_by ON questions (approved_by);
CREATE INDEX idx_questions_deleted     ON questions (deleted_at);
CREATE INDEX idx_questions_fts ON questions USING GIN (to_tsvector('english', question_text));


-- ============================================================
--  SECTION 6 — EXAM PAPERS
-- ============================================================

CREATE TABLE exam_papers (
    id               SERIAL        PRIMARY KEY,
    paper_code       VARCHAR(50)   NOT NULL UNIQUE,
    course_id        INT           NOT NULL REFERENCES courses(id) ON DELETE RESTRICT,
    created_by       INT           NOT NULL REFERENCES staff(id)   ON DELETE RESTRICT,
    exam_type        exam_type     NOT NULL,
    academic_year    INT           NOT NULL,
    semester         INT           NOT NULL,
    exam_date        DATE,
    duration         INT,
    total_marks      INT           NOT NULL DEFAULT 0,
    instructions     TEXT,
    footer_text      VARCHAR(255),
    status           paper_status  NOT NULL DEFAULT 'draft',
    hod_id           INT REFERENCES staff(id) ON DELETE SET NULL,
    hod_approved_at  TIMESTAMPTZ,
    dean_id          INT REFERENCES staff(id) ON DELETE SET NULL,
    dean_approved_at TIMESTAMPTZ,
    exam_master_id   INT REFERENCES staff(id) ON DELETE SET NULL,
    printed_at       TIMESTAMPTZ,
    print_quantity   INT           NOT NULL DEFAULT 0,
    submitted_at     TIMESTAMPTZ,
    published_at     TIMESTAMPTZ,
    version          INT           NOT NULL DEFAULT 1,
    is_locked        BOOLEAN       NOT NULL DEFAULT FALSE,
    deleted_at       TIMESTAMPTZ,
    deleted_by       INT,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_exam_papers_paper_code          ON exam_papers (paper_code);
CREATE INDEX idx_exam_papers_course              ON exam_papers (course_id);
CREATE INDEX idx_exam_papers_created_by          ON exam_papers (created_by);
CREATE INDEX idx_exam_papers_status              ON exam_papers (status);
CREATE INDEX idx_exam_papers_exam_type           ON exam_papers (exam_type);
CREATE INDEX idx_exam_papers_hod                 ON exam_papers (hod_id);
CREATE INDEX idx_exam_papers_academic_year       ON exam_papers (academic_year, semester);
CREATE INDEX idx_exam_papers_status_type         ON exam_papers (status, exam_type);
CREATE INDEX idx_exam_papers_creator_stat        ON exam_papers (created_by, status);
CREATE INDEX idx_exam_papers_deleted             ON exam_papers (deleted_at);


CREATE TABLE exam_paper_versions (
    id             SERIAL      PRIMARY KEY,
    exam_paper_id  INT         NOT NULL REFERENCES exam_papers(id) ON DELETE CASCADE,
    version_number INT         NOT NULL,
    snapshot       JSONB       NOT NULL,
    changes_summary TEXT,
    created_by     INT         NOT NULL REFERENCES staff(id) ON DELETE RESTRICT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (exam_paper_id, version_number)
);
CREATE INDEX idx_epv_exam_paper ON exam_paper_versions (exam_paper_id);


CREATE TABLE exam_paper_programmes (
    id            SERIAL      PRIMARY KEY,
    exam_paper_id INT         NOT NULL REFERENCES exam_papers(id)  ON DELETE CASCADE,
    programme_id  INT         NOT NULL REFERENCES programmes(id)   ON DELETE CASCADE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (exam_paper_id, programme_id)
);
CREATE INDEX idx_epp_exam_paper ON exam_paper_programmes (exam_paper_id);
CREATE INDEX idx_epp_programme  ON exam_paper_programmes (programme_id);


-- ============================================================
--  SECTION 7 — EXAM PAPER QUESTIONS (with Sub-Question support)
-- ============================================================

CREATE TABLE exam_paper_questions (
    id                     SERIAL       PRIMARY KEY,
    exam_paper_id          INT          NOT NULL REFERENCES exam_papers(id)          ON DELETE CASCADE,
    question_id            INT          NOT NULL REFERENCES questions(id)            ON DELETE RESTRICT,
    section                VARCHAR(10)  NOT NULL DEFAULT 'A',
    question_number        VARCHAR(20)  NOT NULL,
    sub_question_label     VARCHAR(20),
    display_number         VARCHAR(50),
    marks                  INT          NOT NULL,
    sub_marks              VARCHAR(50),
    is_required            BOOLEAN      NOT NULL DEFAULT TRUE,
    is_choice              BOOLEAN      NOT NULL DEFAULT FALSE,
    choice_group           VARCHAR(20),
    choice_instructions    VARCHAR(255),
    sequence_order         INT          NOT NULL,
    parent_question_id     INT          REFERENCES exam_paper_questions(id) ON DELETE CASCADE,
    indentation_level      INT          NOT NULL DEFAULT 0,
    can_have_sub_questions BOOLEAN      NOT NULL DEFAULT TRUE,
    custom_instructions    TEXT,
    notes                  TEXT,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_epq_exam_paper  ON exam_paper_questions (exam_paper_id);
CREATE INDEX idx_epq_question    ON exam_paper_questions (question_id);
CREATE INDEX idx_epq_parent      ON exam_paper_questions (parent_question_id);
CREATE INDEX idx_epq_section     ON exam_paper_questions (section);
CREATE INDEX idx_epq_indentation ON exam_paper_questions (indentation_level);

CREATE UNIQUE INDEX idx_epq_uniq_section_seq
    ON exam_paper_questions (exam_paper_id, section, sequence_order, COALESCE(parent_question_id, 0));
CREATE UNIQUE INDEX idx_epq_uniq_question_parent
    ON exam_paper_questions (exam_paper_id, question_id, COALESCE(parent_question_id, 0));


-- ============================================================
--  SECTION 8 — PERMISSIONS SYSTEM
-- ============================================================

CREATE TABLE lecturer_permissions (
    id                 SERIAL      PRIMARY KEY,
    lecturer_id        INT         NOT NULL REFERENCES staff(id)   ON DELETE CASCADE,
    course_id          INT         NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    granted_by         INT         NOT NULL REFERENCES staff(id)   ON DELETE RESTRICT,
    can_add_questions  BOOLEAN     NOT NULL DEFAULT TRUE,
    can_create_papers  BOOLEAN     NOT NULL DEFAULT TRUE,
    can_edit_questions BOOLEAN     NOT NULL DEFAULT FALSE,
    granted_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at         TIMESTAMPTZ,
    is_active          BOOLEAN     NOT NULL DEFAULT TRUE,
    notes              TEXT,
    UNIQUE (lecturer_id, course_id)
);
CREATE INDEX idx_lp_lecturer   ON lecturer_permissions (lecturer_id);
CREATE INDEX idx_lp_course     ON lecturer_permissions (course_id);
CREATE INDEX idx_lp_granted_by ON lecturer_permissions (granted_by);
CREATE INDEX idx_lp_active     ON lecturer_permissions (is_active);


-- ============================================================
--  SECTION 9 — WORKFLOW & APPROVALS
-- ============================================================

CREATE TABLE workflow_history (
    id            SERIAL           PRIMARY KEY,
    exam_paper_id INT              NOT NULL REFERENCES exam_papers(id) ON DELETE CASCADE,
    action        workflow_action  NOT NULL,
    from_status   VARCHAR(50),
    to_status     VARCHAR(50)      NOT NULL,
    actor_id      INT              NOT NULL REFERENCES staff(id) ON DELETE RESTRICT,
    actor_role    VARCHAR(50)      NOT NULL,
    comments      TEXT,
    metadata      JSONB,
    created_at    TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_wf_metadata CHECK (metadata IS NULL OR jsonb_typeof(metadata) IS NOT NULL)
);
CREATE INDEX idx_wh_exam_paper       ON workflow_history (exam_paper_id);
CREATE INDEX idx_wh_actor            ON workflow_history (actor_id);
CREATE INDEX idx_wh_action           ON workflow_history (action);
CREATE INDEX idx_wh_paper_date       ON workflow_history (exam_paper_id, created_at);


CREATE TABLE paper_comments (
    id                SERIAL        PRIMARY KEY,
    exam_paper_id     INT           NOT NULL REFERENCES exam_papers(id)    ON DELETE CASCADE,
    user_id           INT           NOT NULL REFERENCES staff(id)          ON DELETE RESTRICT,
    comment_type      comment_type  NOT NULL DEFAULT 'general',
    comment           TEXT          NOT NULL,
    is_resolved       BOOLEAN       NOT NULL DEFAULT FALSE,
    parent_comment_id INT           REFERENCES paper_comments(id)          ON DELETE CASCADE,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_pc_exam_paper ON paper_comments (exam_paper_id);
CREATE INDEX idx_pc_user       ON paper_comments (user_id);
CREATE INDEX idx_pc_resolved   ON paper_comments (is_resolved);


-- ============================================================
--  SECTION 10 — NOTIFICATIONS
-- ============================================================

CREATE TABLE notifications (
    id                  SERIAL                 PRIMARY KEY,
    user_id             INT                    REFERENCES staff(id)                ON DELETE CASCADE,
    student_id          INT                    REFERENCES students(id)             ON DELETE CASCADE,
    type                notification_type      NOT NULL,
    title               VARCHAR(255)           NOT NULL,
    message             TEXT                   NOT NULL,
    related_paper_id    INT                    REFERENCES exam_papers(id)          ON DELETE CASCADE,
    related_entity_type VARCHAR(50),
    related_entity_id   INT,
    is_read             BOOLEAN                NOT NULL DEFAULT FALSE,
    read_at             TIMESTAMPTZ,
    priority            notification_priority  NOT NULL DEFAULT 'medium',
    action_url          VARCHAR(500),
    archived_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ            NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_recipient CHECK (
        (user_id IS NOT NULL AND student_id IS NULL) OR
        (user_id IS NULL AND student_id IS NOT NULL)
    )
);
CREATE INDEX idx_notif_user_unread    ON notifications (user_id, is_read, created_at) WHERE user_id IS NOT NULL;
CREATE INDEX idx_notif_student_unread ON notifications (student_id, is_read, created_at) WHERE student_id IS NOT NULL;
CREATE INDEX idx_notif_archived       ON notifications (archived_at);


-- ============================================================
--  SECTION 11 — AUDIT LOGS
-- ============================================================

CREATE TABLE audit_logs (
    id          SERIAL       PRIMARY KEY,
    user_id     INT          REFERENCES staff(id) ON DELETE SET NULL,
    action      VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50)  NOT NULL,
    entity_id   INT,
    old_values  JSONB,
    new_values  JSONB,
    ip_address  VARCHAR(45),
    user_agent  TEXT,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_old_vals CHECK (old_values IS NULL OR jsonb_typeof(old_values) IS NOT NULL),
    CONSTRAINT chk_new_vals CHECK (new_values IS NULL OR jsonb_typeof(new_values) IS NOT NULL)
);
CREATE INDEX idx_al_user       ON audit_logs (user_id);
CREATE INDEX idx_al_entity     ON audit_logs (entity_type, entity_id);
CREATE INDEX idx_al_action     ON audit_logs (action);
CREATE INDEX idx_al_created_at ON audit_logs (created_at);


-- ============================================================
--  SECTION 12 — PhD VIVA VOCE ADMINISTRATION
-- ============================================================

CREATE TABLE phd_candidates (
    id                  SERIAL           PRIMARY KEY,
    registration_number VARCHAR(50)      NOT NULL UNIQUE REFERENCES students(registration_number) ON DELETE RESTRICT,
    thesis_title        VARCHAR(500)     NOT NULL,
    programme_id        INT              NOT NULL REFERENCES programmes(id) ON DELETE RESTRICT,
    supervisor_id       INT              REFERENCES staff(id)               ON DELETE SET NULL,
    co_supervisor_id    INT              REFERENCES staff(id)               ON DELETE SET NULL,
    enrolment_year      SMALLINT,
    status              candidate_status NOT NULL DEFAULT 'enrolled',
    deleted_at          TIMESTAMPTZ,
    deleted_by          INT,
    created_at          TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_phd_registration_number ON phd_candidates (registration_number);
CREATE INDEX idx_phd_programme           ON phd_candidates (programme_id);
CREATE INDEX idx_phd_supervisor          ON phd_candidates (supervisor_id);
CREATE INDEX idx_phd_status              ON phd_candidates (status);
CREATE INDEX idx_phd_deleted             ON phd_candidates (deleted_at);


CREATE TABLE thesis_submissions (
    id               SERIAL      PRIMARY KEY,
    candidate_id     INT         NOT NULL REFERENCES phd_candidates(id) ON DELETE CASCADE,
    file_name        VARCHAR(255) NOT NULL,
    file_path        VARCHAR(500) NOT NULL,
    file_size_kb     INT,
    version          INT         NOT NULL DEFAULT 1,
    submission_notes TEXT,
    submitted_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_ts_candidate ON thesis_submissions (candidate_id);
CREATE INDEX idx_ts_version   ON thesis_submissions (version);


CREATE TABLE viva_schedules (
    id                 SERIAL      PRIMARY KEY,
    candidate_id       INT         NOT NULL REFERENCES phd_candidates(id)   ON DELETE RESTRICT,
    thesis_id          INT         NOT NULL REFERENCES thesis_submissions(id) ON DELETE RESTRICT,
    scheduled_date     DATE        NOT NULL,
    scheduled_time     TIME        NOT NULL,
    venue              VARCHAR(255) NOT NULL,
    duration_minutes   INT         NOT NULL DEFAULT 90,
    status             viva_status NOT NULL DEFAULT 'scheduled',
    postponement_reason TEXT,
    created_by         INT         NOT NULL REFERENCES staff(id)             ON DELETE RESTRICT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_vs_candidate  ON viva_schedules (candidate_id);
CREATE INDEX idx_vs_date       ON viva_schedules (scheduled_date);
CREATE INDEX idx_vs_status     ON viva_schedules (status);
CREATE INDEX idx_vs_created_by ON viva_schedules (created_by);


CREATE TABLE viva_examiners (
    id           SERIAL        PRIMARY KEY,
    viva_id      INT           NOT NULL REFERENCES viva_schedules(id) ON DELETE CASCADE,
    examiner_id  INT           NOT NULL REFERENCES staff(id)          ON DELETE RESTRICT,
    role         examiner_role NOT NULL,
    panel_slot   INT,           -- 1: Professor, 2: Lecturer, 3: External
    confirmed    BOOLEAN       NOT NULL DEFAULT FALSE,
    confirmed_at TIMESTAMPTZ,
    notified_at  TIMESTAMPTZ,
    UNIQUE (viva_id, examiner_id),
    UNIQUE (viva_id, panel_slot) -- Each slot can only be filled once per viva
);
CREATE INDEX idx_ve_viva     ON viva_examiners (viva_id);
CREATE INDEX idx_ve_examiner ON viva_examiners (examiner_id);
CREATE INDEX idx_ve_role     ON viva_examiners (role);


CREATE TABLE viva_evaluations (
    id                      SERIAL      PRIMARY KEY,
    viva_id                 INT         NOT NULL REFERENCES viva_schedules(id) ON DELETE CASCADE,
    examiner_id             INT         NOT NULL REFERENCES staff(id)          ON DELETE RESTRICT,
    originality_score       SMALLINT    CHECK (originality_score   BETWEEN 0 AND 25),
    methodology_score       SMALLINT    CHECK (methodology_score   BETWEEN 0 AND 25),
    presentation_score      SMALLINT    CHECK (presentation_score  BETWEEN 0 AND 25),
    literature_score        SMALLINT    CHECK (literature_score    BETWEEN 0 AND 25),
    overall_score           SMALLINT    GENERATED ALWAYS AS (
                                COALESCE(originality_score,0)  +
                                COALESCE(methodology_score,0)  +
                                COALESCE(presentation_score,0) +
                                COALESCE(literature_score,0)
                            ) STORED,
    strengths               TEXT,
    weaknesses              TEXT,
    recommended_corrections TEXT,
    general_comments        TEXT,
    submitted_at            TIMESTAMPTZ,
    is_submitted            BOOLEAN     NOT NULL DEFAULT FALSE,
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (viva_id, examiner_id)
);
CREATE INDEX idx_veval_viva      ON viva_evaluations (viva_id);
CREATE INDEX idx_veval_examiner  ON viva_evaluations (examiner_id);
CREATE INDEX idx_veval_submitted ON viva_evaluations (is_submitted);
CREATE INDEX idx_veval_overall   ON viva_evaluations (overall_score);


CREATE TABLE viva_recommendations (
    id                  SERIAL       PRIMARY KEY,
    viva_id             INT          NOT NULL UNIQUE REFERENCES viva_schedules(id) ON DELETE CASCADE,
    outcome             viva_outcome NOT NULL,
    correction_deadline DATE,
    final_comments      TEXT,
    issued_by           INT          NOT NULL REFERENCES staff(id) ON DELETE RESTRICT, -- Usually HOD
    issued_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_vrec_viva    ON viva_recommendations (viva_id);
CREATE INDEX idx_vrec_outcome ON viva_recommendations (outcome);


-- ============================================================
--  SECTION 12B — PhD CANDIDATE SUPERVISORS
--  Junction table replacing flat supervisor_id / co_supervisor_id
--  Supports multiple supervisors, role tracking & history
-- ============================================================

CREATE TABLE phd_candidate_supervisors (
    id             SERIAL           PRIMARY KEY,
    candidate_id   INT              NOT NULL REFERENCES phd_candidates(id) ON DELETE CASCADE,
    supervisor_id  INT              NOT NULL REFERENCES staff(id)          ON DELETE RESTRICT,
    role           supervisor_role  NOT NULL DEFAULT 'main',
    is_active      BOOLEAN          NOT NULL DEFAULT TRUE,
    assigned_at    TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    ended_at       TIMESTAMPTZ,
    notes          TEXT,
    created_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    UNIQUE (candidate_id, supervisor_id)
);

CREATE INDEX idx_pcs_candidate   ON phd_candidate_supervisors (candidate_id);
CREATE INDEX idx_pcs_supervisor  ON phd_candidate_supervisors (supervisor_id);
CREATE INDEX idx_pcs_role        ON phd_candidate_supervisors (role);
CREATE INDEX idx_pcs_active      ON phd_candidate_supervisors (is_active);


-- ============================================================
--  SECTION 13 — VIEWS
-- ============================================================

-- Supervisor overview per candidate
CREATE VIEW vw_candidate_supervisors AS
SELECT
    pc.id                                           AS candidate_id,
    pc.registration_number,
    pc.thesis_title,
    pc.status                                       AS candidate_status,
    s.first_name  || ' ' || s.last_name             AS candidate_name,
    p.name                                          AS programme_name,
    u.id                                            AS supervisor_id,
    u.first_name  || ' ' || u.last_name             AS supervisor_name,
    u.email                                         AS supervisor_email,
    pcs.role                                        AS supervisor_role,
    pcs.is_active,
    pcs.assigned_at,
    pcs.ended_at,
    pcs.notes
FROM phd_candidate_supervisors pcs
JOIN phd_candidates pc ON pcs.candidate_id   = pc.id
JOIN staff          u  ON pcs.supervisor_id  = u.id
JOIN students       s  ON pc.registration_number = s.registration_number
JOIN programmes     p  ON pc.programme_id    = p.id
WHERE pc.deleted_at IS NULL
ORDER BY pc.registration_number, pcs.role;


-- Examiner evaluations view - links examiners to their evaluations for candidates
CREATE VIEW vw_examiner_evaluations AS
SELECT
    ve.id                                           AS evaluation_id,
    vs.id                                           AS viva_id,
    vs.scheduled_date,
    vs.scheduled_time,
    vs.venue,
    vs.status                                       AS viva_status,
    pc.id                                           AS candidate_id,
    pc.registration_number,
    pc.thesis_title,
    pc.status                                       AS candidate_status,
    s.first_name || ' ' || s.last_name              AS candidate_name,
    s.email                                         AS candidate_email,
    p.name                                          AS programme_name,
    u.id                                            AS examiner_id,
    u.first_name || ' ' || u.last_name              AS examiner_name,
    u.email                                         AS examiner_email,
    vxe.role                                        AS examiner_role,
    vxe.confirmed                                   AS examiner_confirmed,
    ve.originality_score,
    ve.methodology_score,
    ve.presentation_score,
    ve.literature_score,
    ve.overall_score,
    ve.strengths,
    ve.weaknesses,
    ve.recommended_corrections,
    ve.general_comments,
    ve.submitted_at,
    ve.is_submitted,
    vr.outcome,
    vr.correction_deadline,
    vr.final_comments
FROM viva_evaluations ve
JOIN viva_schedules    vs  ON ve.viva_id      = vs.id
JOIN viva_examiners    vxe ON ve.viva_id = vxe.viva_id AND ve.examiner_id = vxe.examiner_id
JOIN phd_candidates    pc  ON vs.candidate_id = pc.id
JOIN students          s   ON pc.registration_number = s.registration_number
JOIN programmes        p   ON pc.programme_id = p.id
JOIN staff             u   ON ve.examiner_id  = u.id
LEFT JOIN viva_recommendations vr ON vs.id = vr.viva_id
ORDER BY vs.scheduled_date, pc.registration_number, vxe.role;


-- Examiners and their assigned candidates (for examiner dashboard)
CREATE VIEW vw_examiner_candidates AS
SELECT
    vxe.id                                         AS assignment_id,
    vs.id                                          AS viva_id,
    vs.scheduled_date,
    vs.scheduled_time,
    vs.venue,
    vs.status                                      AS viva_status,
    vs.duration_minutes,
    pc.id                                          AS candidate_id,
    pc.registration_number,
    pc.thesis_title,
    pc.status                                      AS candidate_status,
    s.first_name || ' ' || s.last_name             AS candidate_name,
    s.email                                        AS candidate_email,
    s.phone                                        AS candidate_phone,
    p.name                                         AS programme_name,
    col.name                                       AS college_name,
    d.name                                         AS department_name,
    u.id                                           AS examiner_id,
    u.first_name || ' ' || u.last_name             AS examiner_name,
    u.email                                        AS examiner_email,
    vxe.role                                       AS examiner_role,
    vxe.confirmed                                  AS examiner_confirmed,
    vxe.confirmed_at,
    vxe.notified_at,
    ve.id                                          AS evaluation_id,
    ve.is_submitted                                AS evaluation_submitted,
    ve.overall_score,
    vr.outcome                                     AS viva_outcome,
    ts.file_path                                   AS thesis_file_path,
    ts.version                                     AS thesis_version
FROM viva_examiners vxe
JOIN viva_schedules     vs  ON vxe.viva_id      = vs.id
JOIN phd_candidates     pc  ON vs.candidate_id   = pc.id
JOIN students           s   ON pc.registration_number = s.registration_number
JOIN programmes         p   ON pc.programme_id   = p.id
LEFT JOIN departments   d   ON p.department_id   = d.id
LEFT JOIN colleges      col ON d.college_id      = col.id
JOIN staff              u   ON vxe.examiner_id   = u.id
LEFT JOIN viva_evaluations      ve ON vxe.viva_id = ve.viva_id AND vxe.examiner_id = ve.examiner_id
LEFT JOIN viva_recommendations  vr ON vs.id = vr.viva_id
LEFT JOIN thesis_submissions    ts ON vs.thesis_id = ts.id
ORDER BY vs.scheduled_date, vxe.role;


CREATE VIEW hod_pending_approvals AS
SELECT
    ep.id,
    ep.paper_code,
    ep.status,
    ep.exam_type,
    c.code                                    AS course_code,
    c.title                                   AS course_name,
    u.first_name || ' ' || u.last_name        AS lecturer_name,
    ep.submitted_at,
    ep.hod_id,
    d.name                                    AS department_name,
    STRING_AGG(DISTINCT p.code, ', ' ORDER BY p.code) AS programmes
FROM exam_papers ep
JOIN  courses     c   ON ep.course_id    = c.id
JOIN  staff       u   ON ep.created_by   = u.id
LEFT JOIN departments d ON c.department_id = d.id
LEFT JOIN exam_paper_programmes epp ON ep.id = epp.exam_paper_id
LEFT JOIN programmes  p ON epp.programme_id = p.id
WHERE ep.status IN ('submitted','hod_review')
  AND ep.deleted_at IS NULL
GROUP BY ep.id, ep.paper_code, ep.status, ep.exam_type,
         c.code, c.title, u.first_name, u.last_name,
         ep.submitted_at, ep.hod_id, d.name;


CREATE VIEW papers_ready_for_print AS
SELECT
    ep.id,
    ep.paper_code,
    ep.status,
    ep.exam_type,
    ep.exam_date,
    c.code                                    AS course_code,
    c.title                                   AS course_name,
    ep.total_marks,
    ep.duration,
    ep.hod_approved_at,
    ep.print_quantity,
    d.name                                    AS department_name,
    col.name                                  AS college_name,
    STRING_AGG(DISTINCT p.code, ', ' ORDER BY p.code) AS programmes
FROM exam_papers ep
JOIN  courses     c   ON ep.course_id     = c.id
LEFT JOIN departments d   ON c.department_id  = d.id
LEFT JOIN colleges    col ON c.college_id     = col.id
LEFT JOIN exam_paper_programmes epp ON ep.id = epp.exam_paper_id
LEFT JOIN programmes  p   ON epp.programme_id = p.id
WHERE ep.status IN ('ready_for_print','printing')
  AND ep.deleted_at IS NULL
GROUP BY ep.id, ep.paper_code, ep.status, ep.exam_type, ep.exam_date,
         c.code, c.title, ep.total_marks, ep.duration,
         ep.hod_approved_at, ep.print_quantity, d.name, col.name;


CREATE VIEW vw_paper_questions_hierarchy AS
SELECT
    epq.*,
    q.question_text,
    q.question_type,
    q.difficulty_level,
    q.bloom_taxonomy,
    q.options,
    c.code                                    AS course_code,
    c.title                                   AS course_title,
    su.name                                   AS study_unit_title,
    u.first_name || ' ' || u.last_name        AS question_author,
    'Q' || epq.question_number ||
        CASE WHEN epq.sub_question_label IS NOT NULL
             THEN '(' || epq.sub_question_label || ')'
             ELSE ''
        END                                   AS full_question_label
FROM exam_paper_questions epq
JOIN  questions   q   ON epq.question_id    = q.id
JOIN  exam_papers ep  ON epq.exam_paper_id  = ep.id
JOIN  courses     c   ON ep.course_id       = c.id
LEFT JOIN study_units su ON q.study_unit_id  = su.id
LEFT JOIN staff       u  ON q.created_by     = u.id
WHERE ep.deleted_at IS NULL
  AND q.deleted_at  IS NULL
ORDER BY epq.exam_paper_id, epq.section, epq.sequence_order, epq.indentation_level;


CREATE VIEW vw_viva_schedule_overview AS
SELECT
    vs.id                                           AS viva_id,
    vs.scheduled_date,
    vs.scheduled_time,
    vs.venue,
    vs.status                                       AS viva_status,
    pc.registration_number,
    pc.thesis_title,
    pc.status                                       AS candidate_status,
    s.first_name || ' ' || s.last_name              AS candidate_name,
    s.email                                         AS candidate_email,
    su.first_name || ' ' || su.last_name            AS supervisor_name,
    p.name                                          AS programme_name,
    vr.outcome,
    COUNT(DISTINCT ve.id)                           AS evaluations_submitted,
    COUNT(DISTINCT vi.id)                           AS total_examiners
FROM viva_schedules vs
JOIN  phd_candidates pc ON vs.candidate_id          = pc.id
JOIN  students       s  ON pc.registration_number   = s.registration_number
LEFT JOIN staff      su ON pc.supervisor_id         = su.id
JOIN  programmes     p  ON pc.programme_id          = p.id
LEFT JOIN viva_examiners vi ON vs.id = vi.viva_id
LEFT JOIN viva_evaluations ve ON vs.id = ve.viva_id AND ve.is_submitted = TRUE
LEFT JOIN viva_recommendations vr ON vs.id = vr.viva_id
GROUP BY vs.id, vs.scheduled_date, vs.scheduled_time, vs.venue,
         vs.status, pc.registration_number, pc.thesis_title,
         pc.status, s.first_name, s.last_name, s.email,
         su.first_name, su.last_name, p.name, vr.outcome;


CREATE VIEW lecturer_permissions_summary AS
SELECT
    u.id                                       AS lecturer_id,
    u.first_name   || ' ' || u.last_name       AS lecturer_name,
    c.code                                     AS course_code,
    c.title                                    AS course_name,
    lp.can_add_questions,
    lp.can_create_papers,
    lp.granted_at,
    lp.expires_at,
    hod.first_name || ' ' || hod.last_name     AS granted_by_name
FROM lecturer_permissions lp
JOIN staff   u   ON lp.lecturer_id = u.id
JOIN courses c   ON lp.course_id   = c.id
JOIN staff   hod ON lp.granted_by  = hod.id
WHERE lp.is_active  = TRUE
  AND u.deleted_at  IS NULL
  AND c.deleted_at  IS NULL;


-- ============================================================
--  SECTION 14 — TRIGGERS
-- ============================================================

-- Batch-create updated_at triggers for remaining tables
DO $$ DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'colleges','departments','programmes','staff','courses',
        'study_units','exam_papers','exam_paper_questions',
        'paper_comments','phd_candidates','viva_schedules',
        'phd_candidate_supervisors','viva_evaluations',
        'quickfire_assessments','quickfire_attempts'
    ] LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%I_updated_at
             BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at()',
            tbl, tbl
        );
    END LOOP;
END;
 $$;


CREATE OR REPLACE FUNCTION fn_prevent_subquestions_when_disabled()
RETURNS TRIGGER LANGUAGE plpgsql AS $$ DECLARE
    v_allowed BOOLEAN;
BEGIN
    IF NEW.parent_question_id IS NOT NULL THEN
        v_allowed := (
            SELECT can_have_sub_questions
            FROM exam_paper_questions
            WHERE id = NEW.parent_question_id
        );
        IF v_allowed = FALSE THEN
            RAISE EXCEPTION 'Parent question does not allow sub-questions';
        END IF;
    END IF;
    RETURN NEW;
END;
 $$;

CREATE TRIGGER trg_prevent_subquestions_when_disabled
BEFORE INSERT ON exam_paper_questions
FOR EACH ROW EXECUTE FUNCTION fn_prevent_subquestions_when_disabled();


CREATE OR REPLACE FUNCTION fn_recalculate_total_marks()
RETURNS TRIGGER LANGUAGE plpgsql AS $$ DECLARE
    v_paper_id INT;
BEGIN
    v_paper_id := COALESCE(NEW.exam_paper_id, OLD.exam_paper_id);
    UPDATE exam_papers
    SET total_marks = (
        SELECT COALESCE(SUM(marks), 0)
        FROM exam_paper_questions
        WHERE exam_paper_id = v_paper_id
    )
    WHERE id = v_paper_id;
    RETURN NULL;
END;
 $$;

CREATE TRIGGER trg_marks_after_insert
AFTER INSERT ON exam_paper_questions
FOR EACH ROW EXECUTE FUNCTION fn_recalculate_total_marks();

CREATE TRIGGER trg_marks_after_update
AFTER UPDATE ON exam_paper_questions
FOR EACH ROW EXECUTE FUNCTION fn_recalculate_total_marks();

CREATE TRIGGER trg_marks_after_delete
AFTER DELETE ON exam_paper_questions
FOR EACH ROW EXECUTE FUNCTION fn_recalculate_total_marks();


CREATE OR REPLACE FUNCTION fn_increment_question_usage()
RETURNS TRIGGER LANGUAGE plpgsql AS $$ BEGIN
    UPDATE questions SET usage_count = usage_count + 1 WHERE id = NEW.question_id;
    RETURN NULL;
END;
 $$;

CREATE TRIGGER trg_increment_question_usage
AFTER INSERT ON exam_paper_questions
FOR EACH ROW EXECUTE FUNCTION fn_increment_question_usage();


CREATE OR REPLACE FUNCTION fn_decrement_question_usage()
RETURNS TRIGGER LANGUAGE plpgsql AS $$ BEGIN
    UPDATE questions
    SET usage_count = GREATEST(usage_count - 1, 0)
    WHERE id = OLD.question_id;
    RETURN NULL;
END;
 $$;

CREATE TRIGGER trg_decrement_question_usage
AFTER DELETE ON exam_paper_questions
FOR EACH ROW EXECUTE FUNCTION fn_decrement_question_usage();


CREATE OR REPLACE FUNCTION fn_candidate_status_on_viva_schedule()
RETURNS TRIGGER LANGUAGE plpgsql AS $$ BEGIN
    UPDATE phd_candidates SET status = 'viva_scheduled' WHERE id = NEW.candidate_id;
    RETURN NULL;
END;
 $$;

CREATE TRIGGER trg_candidate_status_on_viva_schedule
AFTER INSERT ON viva_schedules
FOR EACH ROW EXECUTE FUNCTION fn_candidate_status_on_viva_schedule();


CREATE OR REPLACE FUNCTION fn_candidate_status_on_viva_complete()
RETURNS TRIGGER LANGUAGE plpgsql AS $$ BEGIN
    IF NEW.status = 'completed' AND OLD.status <> 'completed' THEN
        UPDATE phd_candidates SET status = 'viva_completed' WHERE id = NEW.candidate_id;
    END IF;
    RETURN NULL;
END;
 $$;

CREATE TRIGGER trg_candidate_status_on_viva_complete
AFTER UPDATE ON viva_schedules
FOR EACH ROW EXECUTE FUNCTION fn_candidate_status_on_viva_complete();


CREATE OR REPLACE FUNCTION fn_thesis_version_increment()
RETURNS TRIGGER LANGUAGE plpgsql AS $$ DECLARE
    v_latest_version INT;
BEGIN
    v_latest_version := (
        SELECT COALESCE(MAX(version), 0)
        FROM thesis_submissions
        WHERE candidate_id = NEW.candidate_id
    );
    NEW.version := v_latest_version + 1;
    RETURN NEW;
END;
 $$;

CREATE TRIGGER trg_thesis_version_increment
BEFORE INSERT ON thesis_submissions
FOR EACH ROW EXECUTE FUNCTION fn_thesis_version_increment();


-- ============================================================
--  SECTION 15 — STORED PROCEDURES
-- ============================================================

CREATE OR REPLACE PROCEDURE cleanup_expired_sessions()
LANGUAGE plpgsql AS $$ BEGIN
    DELETE FROM sessions WHERE expires_at < NOW();
END;
 $$;


CREATE OR REPLACE PROCEDURE archive_old_notifications()
LANGUAGE plpgsql AS $$ BEGIN
    UPDATE notifications
    SET archived_at = NOW()
    WHERE is_read     = TRUE
      AND archived_at IS NULL
      AND created_at  < NOW() - INTERVAL '90 days';
END;
 $$;


CREATE OR REPLACE FUNCTION sp_get_paper_full_details(p_paper_id INT)
RETURNS TABLE (
    paper_id        INT,
    paper_code      VARCHAR,
    course_code     VARCHAR,
    course_title    VARCHAR,
    created_by_name TEXT,
    hod_name        TEXT,
    programmes      TEXT,
    exam_type       exam_type,
    academic_year   INT,
    semester        INT,
    exam_date       DATE,
    duration        INT,
    total_marks     INT,
    instructions    TEXT,
    status          paper_status,
    version         INT,
    submitted_at    TIMESTAMPTZ,
    published_at    TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY
    SELECT
        ep.id,
        ep.paper_code,
        c.code,
        c.title,
        creator.first_name || ' ' || creator.last_name,
        hod.first_name    || ' ' || hod.last_name,
        STRING_AGG(DISTINCT p.code, ', ' ORDER BY p.code),
        ep.exam_type,
        ep.academic_year,
        ep.semester,
        ep.exam_date,
        ep.duration,
        ep.total_marks,
        ep.instructions,
        ep.status,
        ep.version,
        ep.submitted_at,
        ep.published_at
    FROM exam_papers ep
    JOIN  courses c       ON ep.course_id  = c.id
    JOIN  staff   creator ON ep.created_by = creator.id
    LEFT JOIN staff hod   ON ep.hod_id     = hod.id
    LEFT JOIN exam_paper_programmes epp ON ep.id = epp.exam_paper_id
    LEFT JOIN programmes p ON epp.programme_id = p.id
    WHERE ep.id         = p_paper_id
      AND ep.deleted_at IS NULL
    GROUP BY ep.id, ep.paper_code, c.code, c.title,
             creator.first_name, creator.last_name,
             hod.first_name, hod.last_name,
             ep.exam_type, ep.academic_year, ep.semester,
             ep.exam_date, ep.duration, ep.total_marks,
             ep.instructions, ep.status, ep.version,
             ep.submitted_at, ep.published_at;
END;
 $$;


CREATE OR REPLACE FUNCTION sp_get_viva_report_schedule(p_viva_id INT)
RETURNS TABLE (
    viva_id             INT,
    scheduled_date      DATE,
    scheduled_time      TIME,
    venue               VARCHAR,
    viva_status         viva_status,
    registration_number VARCHAR,
    thesis_title        VARCHAR,
    candidate_name      TEXT,
    candidate_email     VARCHAR,
    supervisor_name     TEXT,
    programme_name      VARCHAR,
    outcome             viva_outcome,
    correction_deadline DATE,
    final_comments      TEXT
)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY
    SELECT
        vs.id,
        vs.scheduled_date,
        vs.scheduled_time,
        vs.venue,
        vs.status,
        pc.registration_number,
        pc.thesis_title,
        s.first_name || ' ' || s.last_name,
        s.email,
        su.first_name || ' ' || su.last_name,
        pr.name,
        vr.outcome,
        vr.correction_deadline,
        vr.final_comments
    FROM viva_schedules vs
    JOIN  phd_candidates pc ON vs.candidate_id        = pc.id
    JOIN  students       s  ON pc.registration_number = s.registration_number
    LEFT JOIN staff      su ON pc.supervisor_id       = su.id
    JOIN  programmes     pr ON pc.programme_id        = pr.id
    LEFT JOIN viva_recommendations vr ON vs.id        = vr.viva_id
    WHERE vs.id = p_viva_id;
END;
 $$;


CREATE OR REPLACE FUNCTION sp_get_viva_report_evaluations(p_viva_id INT)
RETURNS TABLE (
    examiner_name           TEXT,
    examiner_role           examiner_role,
    originality_score       SMALLINT,
    methodology_score       SMALLINT,
    presentation_score      SMALLINT,
    literature_score        SMALLINT,
    overall_score           SMALLINT,
    strengths               TEXT,
    weaknesses              TEXT,
    recommended_corrections TEXT,
    general_comments        TEXT,
    submitted_at            TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY
    SELECT
        u.first_name || ' ' || u.last_name,
        vi.role,
        ve.originality_score,
        ve.methodology_score,
        ve.presentation_score,
        ve.literature_score,
        ve.overall_score,
        ve.strengths,
        ve.weaknesses,
        ve.recommended_corrections,
        ve.general_comments,
        ve.submitted_at
    FROM viva_evaluations ve
    JOIN viva_examiners vi ON ve.viva_id = vi.viva_id AND ve.examiner_id = vi.examiner_id
    JOIN staff u           ON ve.examiner_id = u.id
    WHERE ve.viva_id = p_viva_id
    ORDER BY vi.role;
END;
 $$;


-- Get examiner's assigned candidates with evaluation status
CREATE OR REPLACE FUNCTION sp_get_examiner_candidates(p_examiner_id INT)
RETURNS TABLE (
    viva_id             INT,
    scheduled_date      DATE,
    scheduled_time      TIME,
    venue               VARCHAR,
    viva_status         viva_status,
    candidate_id        INT,
    registration_number VARCHAR,
    thesis_title        VARCHAR,
    candidate_status    candidate_status,
    candidate_name      TEXT,
    candidate_email     VARCHAR,
    programme_name      VARCHAR,
    examiner_role       examiner_role,
    examiner_confirmed  BOOLEAN,
    evaluation_id       INT,
    evaluation_submitted BOOLEAN,
    overall_score       SMALLINT,
    thesis_file_path    VARCHAR,
    thesis_version      INT
)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY
    SELECT
        vs.id,
        vs.scheduled_date,
        vs.scheduled_time,
        vs.venue,
        vs.status,
        pc.id,
        pc.registration_number,
        pc.thesis_title,
        pc.status,
        s.first_name || ' ' || s.last_name,
        s.email,
        p.name,
        vxe.role,
        vxe.confirmed,
        ve.id,
        ve.is_submitted,
        ve.overall_score,
        ts.file_path,
        ts.version
    FROM viva_examiners vxe
    JOIN viva_schedules      vs ON vxe.viva_id      = vs.id
    JOIN phd_candidates      pc ON vs.candidate_id   = pc.id
    JOIN students            s  ON pc.registration_number = s.registration_number
    JOIN programmes          p  ON pc.programme_id   = p.id
    LEFT JOIN viva_evaluations ve ON vxe.viva_id = ve.viva_id AND vxe.examiner_id = ve.examiner_id
    LEFT JOIN thesis_submissions ts ON vs.thesis_id = ts.id
    WHERE vxe.examiner_id = p_examiner_id
    ORDER BY vs.scheduled_date DESC;
END;
 $$;


-- Submit or update an evaluation for a viva
CREATE OR REPLACE FUNCTION sp_submit_evaluation(
    p_viva_id             INT,
    p_examiner_id         INT,
    p_originality_score   SMALLINT,
    p_methodology_score   SMALLINT,
    p_presentation_score  SMALLINT,
    p_literature_score    SMALLINT,
    p_strengths           TEXT,
    p_weaknesses          TEXT,
    p_recommended_corrections TEXT,
    p_general_comments    TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$ 
DECLARE
    v_evaluation_id INT;
    v_result JSONB;
BEGIN
    -- Verify examiner is assigned to this viva
    IF NOT EXISTS (
        SELECT 1 FROM viva_examiners 
        WHERE viva_id = p_viva_id AND examiner_id = p_examiner_id
    ) THEN
        RAISE EXCEPTION 'Examiner is not assigned to this viva session';
    END IF;
    
    -- Upsert the evaluation
    INSERT INTO viva_evaluations (
        viva_id, examiner_id,
        originality_score, methodology_score, presentation_score, literature_score,
        strengths, weaknesses, recommended_corrections, general_comments,
        submitted_at, is_submitted
    ) VALUES (
        p_viva_id, p_examiner_id,
        p_originality_score, p_methodology_score, p_presentation_score, p_literature_score,
        p_strengths, p_weaknesses, p_recommended_corrections, p_general_comments,
        NOW(), TRUE
    )
    ON CONFLICT (viva_id, examiner_id) DO UPDATE SET
        originality_score = EXCLUDED.originality_score,
        methodology_score = EXCLUDED.methodology_score,
        presentation_score = EXCLUDED.presentation_score,
        literature_score = EXCLUDED.literature_score,
        strengths = EXCLUDED.strengths,
        weaknesses = EXCLUDED.weaknesses,
        recommended_corrections = EXCLUDED.recommended_corrections,
        general_comments = EXCLUDED.general_comments,
        submitted_at = NOW(),
        is_submitted = TRUE
    RETURNING id INTO v_evaluation_id;
    
    SELECT jsonb_build_object(
        'success', TRUE,
        'evaluation_id', v_evaluation_id,
        'message', 'Evaluation submitted successfully'
    ) INTO v_result;
    
    RETURN v_result;
END;
 $$;


-- ============================================================
--  RPC HELPERS — Next.js query layer
-- ============================================================

CREATE OR REPLACE FUNCTION public.execute_query(p_sql text, p_params jsonb DEFAULT '[]'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$ DECLARE
  v_result JSONB;
  n INTEGER;
BEGIN
  n := COALESCE(jsonb_array_length(p_params), 0);
  IF n = 0 THEN
    EXECUTE 'SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (' || p_sql || ') t' INTO v_result;
  ELSIF n = 1 THEN
    EXECUTE 'SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (' || p_sql || ') t' INTO v_result USING (p_params->>0);
  ELSIF n = 2 THEN
    EXECUTE 'SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (' || p_sql || ') t' INTO v_result USING (p_params->>0),(p_params->>1);
  ELSIF n = 3 THEN
    EXECUTE 'SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (' || p_sql || ') t' INTO v_result USING (p_params->>0),(p_params->>1),(p_params->>2);
  ELSIF n = 4 THEN
    EXECUTE 'SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (' || p_sql || ') t' INTO v_result USING (p_params->>0),(p_params->>1),(p_params->>2),(p_params->>3);
  ELSIF n = 5 THEN
    EXECUTE 'SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (' || p_sql || ') t' INTO v_result USING (p_params->>0),(p_params->>1),(p_params->>2),(p_params->>3),(p_params->>4);
  ELSIF n = 6 THEN
    EXECUTE 'SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (' || p_sql || ') t' INTO v_result USING (p_params->>0),(p_params->>1),(p_params->>2),(p_params->>3),(p_params->>4),(p_params->>5);
  ELSIF n = 7 THEN
    EXECUTE 'SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (' || p_sql || ') t' INTO v_result USING (p_params->>0),(p_params->>1),(p_params->>2),(p_params->>3),(p_params->>4),(p_params->>5),(p_params->>6);
  ELSIF n = 8 THEN
    EXECUTE 'SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (' || p_sql || ') t' INTO v_result USING (p_params->>0),(p_params->>1),(p_params->>2),(p_params->>3),(p_params->>4),(p_params->>5),(p_params->>6),(p_params->>7);
  ELSIF n = 9 THEN
    EXECUTE 'SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (' || p_sql || ') t' INTO v_result USING (p_params->>0),(p_params->>1),(p_params->>2),(p_params->>3),(p_params->>4),(p_params->>5),(p_params->>6),(p_params->>7),(p_params->>8);
  ELSIF n = 10 THEN
    EXECUTE 'SELECT COALESCE(jsonb_agg(t), ''[]''::jsonb) FROM (' || p_sql || ') t' INTO v_result USING (p_params->>0),(p_params->>1),(p_params->>2),(p_params->>3),(p_params->>4),(p_params->>5),(p_params->>6),(p_params->>7),(p_params->>8),(p_params->>9);
  ELSE
    RAISE EXCEPTION 'execute_query supports up to 10 parameters, got %', n;
  END IF;
  RETURN COALESCE(v_result, '[]'::jsonb);
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'execute_query [%]: %', SQLSTATE, SQLERRM;
END;
 $function$;


CREATE OR REPLACE FUNCTION public.execute_write(p_sql text, p_params jsonb DEFAULT '[]'::jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$ DECLARE
  n INTEGER;
  v_result JSONB;
  has_returning BOOLEAN;
BEGIN
  n := COALESCE(jsonb_array_length(p_params), 0);
  has_returning := p_sql ~* '\bRETURNING\b';
  IF has_returning THEN
    IF n = 0 THEN EXECUTE p_sql INTO v_result;
    ELSIF n = 1 THEN EXECUTE p_sql INTO v_result USING (p_params->>0)::text;
    ELSIF n = 2 THEN EXECUTE p_sql INTO v_result USING (p_params->>0)::text,(p_params->>1)::text;
    ELSIF n = 3 THEN EXECUTE p_sql INTO v_result USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text;
    ELSIF n = 4 THEN EXECUTE p_sql INTO v_result USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text;
    ELSIF n = 5 THEN EXECUTE p_sql INTO v_result USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text,(p_params->>4)::text;
    ELSIF n = 6 THEN EXECUTE p_sql INTO v_result USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text,(p_params->>4)::text,(p_params->>5)::text;
    ELSIF n = 7 THEN EXECUTE p_sql INTO v_result USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text,(p_params->>4)::text,(p_params->>5)::text,(p_params->>6)::text;
    ELSIF n = 8 THEN EXECUTE p_sql INTO v_result USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text,(p_params->>4)::text,(p_params->>5)::text,(p_params->>6)::text,(p_params->>7)::text;
    ELSIF n = 9 THEN EXECUTE p_sql INTO v_result USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text,(p_params->>4)::text,(p_params->>5)::text,(p_params->>6)::text,(p_params->>7)::text,(p_params->>8)::text;
    ELSIF n = 10 THEN EXECUTE p_sql INTO v_result USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text,(p_params->>4)::text,(p_params->>5)::text,(p_params->>6)::text,(p_params->>7)::text,(p_params->>8)::text,(p_params->>9)::text;
    END IF;
  ELSE
    IF n = 0 THEN EXECUTE p_sql;
    ELSIF n = 1 THEN EXECUTE p_sql USING (p_params->>0)::text;
    ELSIF n = 2 THEN EXECUTE p_sql USING (p_params->>0)::text,(p_params->>1)::text;
    ELSIF n = 3 THEN EXECUTE p_sql USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text;
    ELSIF n = 4 THEN EXECUTE p_sql USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text;
    ELSIF n = 5 THEN EXECUTE p_sql USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text,(p_params->>4)::text;
    ELSIF n = 6 THEN EXECUTE p_sql USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text,(p_params->>4)::text,(p_params->>5)::text;
    ELSIF n = 7 THEN EXECUTE p_sql USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text,(p_params->>4)::text,(p_params->>5)::text,(p_params->>6)::text;
    ELSIF n = 8 THEN EXECUTE p_sql USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text,(p_params->>4)::text,(p_params->>5)::text,(p_params->>6)::text,(p_params->>7)::text;
    ELSIF n = 9 THEN EXECUTE p_sql USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text,(p_params->>4)::text,(p_params->>5)::text,(p_params->>6)::text,(p_params->>7)::text,(p_params->>8)::text;
    ELSIF n = 10 THEN EXECUTE p_sql USING (p_params->>0)::text,(p_params->>1)::text,(p_params->>2)::text,(p_params->>3)::text,(p_params->>4)::text,(p_params->>5)::text,(p_params->>6)::text,(p_params->>7)::text,(p_params->>8)::text,(p_params->>9)::text;
    ELSE RAISE EXCEPTION 'execute_write supports up to 10 parameters, got %', n;
    END IF;
  END IF;
  RETURN COALESCE(v_result, '[]'::jsonb);
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'execute_write [%]: %', SQLSTATE, SQLERRM;
END;
 $function$;



-- ============================================================
--  SECTION 15 — EXAM TIMETABLE & ENROLLMENT
-- ============================================================

CREATE TABLE exam_timetables (
    id               SERIAL      PRIMARY KEY,
    exam_paper_id    INT         REFERENCES exam_papers(id) ON DELETE CASCADE,
    course_id        INT         REFERENCES courses(id) ON DELETE CASCADE,
    exam_date        DATE        NOT NULL,
    start_time       TIME        NOT NULL,
    end_time         TIME        NOT NULL,
    venue            VARCHAR(255) NOT NULL,
    capacity         INT,
    created_by       INT         REFERENCES staff(id) ON DELETE SET NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_et_paper ON exam_timetables (exam_paper_id) WHERE exam_paper_id IS NOT NULL;
CREATE INDEX idx_et_course ON exam_timetables (course_id);
CREATE INDEX idx_et_date  ON exam_timetables (exam_date);

CREATE TABLE course_enrollments (
    id               SERIAL      PRIMARY KEY,
    student_id       INT         NOT NULL REFERENCES students(id)    ON DELETE CASCADE,
    course_id        INT         NOT NULL REFERENCES courses(id)     ON DELETE CASCADE,
    academic_year    INT         NOT NULL,
    semester         INT         NOT NULL,
    enrolled_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (student_id, course_id, academic_year, semester)
);
CREATE INDEX idx_ce_student ON course_enrollments (student_id);
CREATE INDEX idx_ce_course  ON course_enrollments (course_id);

CREATE TABLE exam_supervisors (
    id               SERIAL      PRIMARY KEY,
    timetable_id     INT         NOT NULL REFERENCES exam_timetables(id) ON DELETE CASCADE,
    lecturer_id      INT         NOT NULL REFERENCES staff(id)          ON DELETE CASCADE,
    assigned_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (timetable_id, lecturer_id)
);
CREATE INDEX idx_es_timetable ON exam_supervisors (timetable_id);
CREATE INDEX idx_es_lecturer  ON exam_supervisors (lecturer_id);

-- Trigger for timetable updated_at
CREATE TRIGGER trg_timetable_updated_at
    BEFORE UPDATE ON exam_timetables
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


--  SECTION 16 — QUICKFIRE MODULE (ASSESSMENTS)
-- ============================================================

CREATE TABLE quickfire_assessments (
    id                SERIAL       PRIMARY KEY,
    course_id         INT          NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    lecturer_id       INT          NOT NULL REFERENCES staff(id)   ON DELETE CASCADE,
    title             VARCHAR(255) NOT NULL,
    description       TEXT,
    duration_minutes  INT,          -- Optional: null means unlimited
    is_active         BOOLEAN      NOT NULL DEFAULT TRUE,
    show_results      BOOLEAN      NOT NULL DEFAULT TRUE, -- Show score to student after submission
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_qa_course   ON quickfire_assessments (course_id);
CREATE INDEX idx_qa_lecturer ON quickfire_assessments (lecturer_id);
CREATE INDEX idx_qa_active   ON quickfire_assessments (is_active);

CREATE TABLE quickfire_questions (
    id                SERIAL       PRIMARY KEY,
    assessment_id     INT          NOT NULL REFERENCES quickfire_assessments(id) ON DELETE CASCADE,
    question_text     TEXT         NOT NULL,
    question_type     question_type NOT NULL DEFAULT 'multiple_choice',
    options           JSONB,       -- For multiple choice: ["A", "B", "C", "D"]
    correct_answer    TEXT,        -- The correct choice or answer text
    marks             INT          NOT NULL DEFAULT 1,
    min_words         INT,         -- For essay type questions
    max_words         INT,         -- For essay type questions
    sequence_order    INT          NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_qq_assessment ON quickfire_questions (assessment_id);

CREATE TABLE quickfire_attempts (
    id                SERIAL       PRIMARY KEY,
    assessment_id     INT          NOT NULL REFERENCES quickfire_assessments(id) ON DELETE CASCADE,
    student_id        INT          NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    started_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    submitted_at      TIMESTAMPTZ,
    total_score       INT          NOT NULL DEFAULT 0,
    status            VARCHAR(20)  NOT NULL DEFAULT 'in_progress', -- 'in_progress', 'submitted'
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (assessment_id, student_id)
);
CREATE INDEX idx_qatt_assessment ON quickfire_attempts (assessment_id);
CREATE INDEX idx_qatt_student    ON quickfire_attempts (student_id);
CREATE INDEX idx_qatt_status     ON quickfire_attempts (status);

CREATE TABLE quickfire_answers (
    id                SERIAL       PRIMARY KEY,
    attempt_id        INT          NOT NULL REFERENCES quickfire_attempts(id) ON DELETE CASCADE,
    question_id       INT          NOT NULL REFERENCES quickfire_questions(id) ON DELETE CASCADE,
    answer_text       TEXT,
    is_correct        BOOLEAN,
    marks_obtained    INT          NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (attempt_id, question_id)
);
CREATE INDEX idx_qans_attempt  ON quickfire_answers (attempt_id);
CREATE INDEX idx_qans_question ON quickfire_answers (question_id);

-- Reporting Views
CREATE VIEW vw_quickfire_results AS
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
    (SELECT SUM(marks) FROM quickfire_questions WHERE assessment_id = qa.id) as max_marks
FROM quickfire_attempts qt
JOIN quickfire_assessments qa ON qt.assessment_id = qa.id
JOIN students s ON qt.student_id = s.id
JOIN courses c ON qa.course_id = c.id;

CREATE VIEW vw_quickfire_detailed_answers AS
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
FROM quickfire_answers an
JOIN quickfire_attempts qt ON an.attempt_id = qt.id
JOIN quickfire_assessments qa ON qt.assessment_id = qa.id
JOIN quickfire_questions qq ON an.question_id = qq.id
JOIN students s ON qt.student_id = s.id;


-- ============================================================
--  END OF SCHEMA — UEMS-PHD-VV v3.3 (PostgreSQL)
--  Kampala International University | © 2026 Spider Tabs Ltd
-- ============================================================
