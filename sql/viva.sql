-- ============================================================
--  PhD SEED DATA — regenerated to match actual programmes
-- ============================================================

DO $$ DECLARE
    missing TEXT := '';
BEGIN
    IF NOT EXISTS (SELECT 1 FROM programmes WHERE code IN ('PHD-COMPSCI','PHDCOMPSCI')) THEN missing := missing || ' PHD-COMPSCI'; END IF;
    IF NOT EXISTS (SELECT 1 FROM programmes WHERE code IN ('PHD-PH','PHDPH'))           THEN missing := missing || ' PHD-PH';       END IF;
    IF NOT EXISTS (SELECT 1 FROM programmes WHERE code IN ('PHD-LAW','PHDLAW'))         THEN missing := missing || ' PHD-LAW';      END IF;
    IF NOT EXISTS (SELECT 1 FROM programmes WHERE code = 'PHD-BA')                      THEN missing := missing || ' PHD-BA';       END IF;
    IF NOT EXISTS (SELECT 1 FROM programmes WHERE code IN ('PHD-MSEA','PHDMSEA'))       THEN missing := missing || ' PHD-MSEA';     END IF;
    IF NOT EXISTS (SELECT 1 FROM programmes WHERE code IN ('PHD-ENG','PHDENG'))         THEN missing := missing || ' PHD-ENG';      END IF;
    IF missing <> '' THEN
        RAISE EXCEPTION 'Missing programme codes: %', missing;
    END IF;
END $$;


-- ============================================================
--  SECTION 1: PHD CANDIDATES
-- ============================================================

INSERT INTO phd_candidates (
    registration_number, thesis_title, programme_id,
    supervisor_id, co_supervisor_id, enrolment_year, status
)
VALUES

    -- PHD-COMPSCI
    ('KIU/2020/1001',
     'Machine Learning Approaches for Predicting Crop Yields in Sub-Saharan Africa',
     (SELECT id FROM programmes WHERE code IN ('PHD-COMPSCI','PHDCOMPSCI') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.cs1@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.cs2@uems.ac.ug'),
     2020, 'viva_scheduled'),

    ('KIU/2020/1002',
     'Enhancing Cybersecurity Frameworks for Ugandan Financial Institutions',
     (SELECT id FROM programmes WHERE code IN ('PHD-COMPSCI','PHDCOMPSCI') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.cs3@uems.ac.ug'),
     NULL,
     2020, 'viva_scheduled'),

    ('KIU/2019/P001',
     'Deep Learning Models for Low-Resource Language Processing in East Africa',
     (SELECT id FROM programmes WHERE code IN ('PHD-COMPSCI','PHDCOMPSCI') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.cs1@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.cs2@uems.ac.ug'),
     2019, 'corrections_submitted'),

    ('KIU/2019/P002',
     'Blockchain-Based Land Registry Systems for Developing Nations',
     (SELECT id FROM programmes WHERE code IN ('PHD-COMPSCI','PHDCOMPSCI') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.cs2@uems.ac.ug'),
     NULL,
     2019, 'thesis_submitted'),

    ('KIU/2019/P003',
     'Edge Computing Architectures for IoT in Resource-Constrained Environments',
     (SELECT id FROM programmes WHERE code IN ('PHD-COMPSCI','PHDCOMPSCI') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.cs3@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.cs1@uems.ac.ug'),
     2019, 'awarded'),

    -- PHD-PH
    ('KIU/2019/2001',
     'Epidemiology of Malaria Resistance in Northern Uganda',
     (SELECT id FROM programmes WHERE code IN ('PHD-PH','PHDPH') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.ph1@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.epid1@uems.ac.ug'),
     2019, 'viva_scheduled'),

    ('KIU/2019/2002',
     'Impact of Maternal Nutrition Interventions on Infant Mortality Rates',
     (SELECT id FROM programmes WHERE code IN ('PHD-PH','PHDPH') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.ph2@uems.ac.ug'),
     NULL,
     2019, 'viva_scheduled'),

    ('KIU/2019/P004',
     'Community Health Worker Effectiveness in Rural Uganda: A Mixed-Methods Study',
     (SELECT id FROM programmes WHERE code IN ('PHD-PH','PHDPH') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.ph1@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.ph2@uems.ac.ug'),
     2019, 'corrections_submitted'),

    ('KIU/2020/P005',
     'HIV/AIDS Treatment Adherence Patterns Among Adolescents in Western Uganda',
     (SELECT id FROM programmes WHERE code IN ('PHD-PH','PHDPH') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.epid1@uems.ac.ug'),
     NULL,
     2020, 'thesis_submitted'),

    ('KIU/2020/P006',
     'Tobacco Smoking Prevalence and Cessation Strategies in Urban Ugandan Communities',
     (SELECT id FROM programmes WHERE code IN ('PHD-PH','PHDPH') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.ph2@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.ph1@uems.ac.ug'),
     2020, 'enrolled'),

    -- PHD-LAW
    ('KIU/2021/3001',
     'Jurisprudential Analysis of Land Rights and Evictions in Urban Uganda',
     (SELECT id FROM programmes WHERE code IN ('PHD-LAW','PHDLAW') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.law1@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.law2@uems.ac.ug'),
     2021, 'viva_scheduled'),

    ('KIU/2021/P007',
     'International Human Rights Law and Refugee Protection in the Great Lakes Region',
     (SELECT id FROM programmes WHERE code IN ('PHD-LAW','PHDLAW') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.law2@uems.ac.ug'),
     NULL,
     2021, 'thesis_submitted'),

    ('KIU/2021/P008',
     'Corporate Governance and Accountability Under Ugandan Company Law',
     (SELECT id FROM programmes WHERE code IN ('PHD-LAW','PHDLAW') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.law1@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.law2@uems.ac.ug'),
     2021, 'corrections_submitted'),

    ('KIU/2022/P009',
     'Environmental Law and Climate Change Liability in East Africa',
     (SELECT id FROM programmes WHERE code IN ('PHD-LAW','PHDLAW') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.law2@uems.ac.ug'),
     NULL,
     2022, 'enrolled'),

    ('KIU/2022/P010',
     'Constitutional Mechanisms for Protecting Electoral Rights in Uganda',
     (SELECT id FROM programmes WHERE code IN ('PHD-LAW','PHDLAW') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.law1@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.law2@uems.ac.ug'),
     2022, 'enrolled'),

    -- PHD-BA
    ('KIU/2020/4001',
     'Strategic Leadership and Organisational Performance in Ugandan SMEs',
     (SELECT id FROM programmes WHERE code = 'PHD-BA'),
     (SELECT id FROM staff WHERE email = 'lect.bus1@uems.ac.ug'),
     NULL,
     2020, 'viva_scheduled'),

    ('KIU/2020/P011',
     'Supply Chain Resilience and Digital Transformation in Ugandan Manufacturing',
     (SELECT id FROM programmes WHERE code = 'PHD-BA'),
     (SELECT id FROM staff WHERE email = 'lect.bus1@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.bus2@uems.ac.ug'),
     2020, 'corrections_submitted'),

    ('KIU/2021/P012',
     'Financial Inclusion Through Mobile Banking: Evidence from Rural Uganda',
     (SELECT id FROM programmes WHERE code = 'PHD-BA'),
     (SELECT id FROM staff WHERE email = 'lect.bus2@uems.ac.ug'),
     NULL,
     2021, 'thesis_submitted'),

    ('KIU/2021/P013',
     'Entrepreneurial Ecosystems and Start-Up Survival Rates in Kampala',
     (SELECT id FROM programmes WHERE code = 'PHD-BA'),
     (SELECT id FROM staff WHERE email = 'lect.bus1@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.bus2@uems.ac.ug'),
     2021, 'enrolled'),

    ('KIU/2022/P014',
     'Corporate Social Responsibility and Brand Equity in the Ugandan Telecom Sector',
     (SELECT id FROM programmes WHERE code = 'PHD-BA'),
     (SELECT id FROM staff WHERE email = 'lect.bus2@uems.ac.ug'),
     NULL,
     2022, 'enrolled'),

    -- PHD-MSEA
    ('KIU/2021/5001',
     'Teacher Professional Development and Learner Outcomes in Ugandan Secondary Schools',
     (SELECT id FROM programmes WHERE code IN ('PHD-MSEA','PHDMSEA') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.edu1@uems.ac.ug'),
     NULL,
     2021, 'viva_scheduled'),

    ('KIU/2021/P015',
     'Inclusive Education Policies and Implementation Gaps for Learners with Disabilities',
     (SELECT id FROM programmes WHERE code IN ('PHD-MSEA','PHDMSEA') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.edu2@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.edu1@uems.ac.ug'),
     2021, 'thesis_submitted'),

    ('KIU/2021/P016',
     'Technology Integration in Primary Education in Post-COVID Uganda',
     (SELECT id FROM programmes WHERE code IN ('PHD-MSEA','PHDMSEA') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.edu1@uems.ac.ug'),
     NULL,
     2021, 'corrections_submitted'),

    ('KIU/2022/P017',
     'Early Childhood Education Quality Indicators in Northern Uganda',
     (SELECT id FROM programmes WHERE code IN ('PHD-MSEA','PHDMSEA') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.edu2@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.edu1@uems.ac.ug'),
     2022, 'enrolled'),

    ('KIU/2022/P018',
     'Parental Involvement and Student Academic Achievement in Rural Schools',
     (SELECT id FROM programmes WHERE code IN ('PHD-MSEA','PHDMSEA') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.edu1@uems.ac.ug'),
     NULL,
     2022, 'enrolled'),

    -- PHD-ENG (Civil)
    ('KIU/2020/P019',
     'Structural Performance of Bamboo-Reinforced Concrete Beams in Tropical Climates',
     (SELECT id FROM programmes WHERE code IN ('PHD-ENG','PHDENG') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.civ1@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.civ2@uems.ac.ug'),
     2020, 'viva_scheduled'),

    ('KIU/2020/P020',
     'Road Pavement Deterioration Models for Low-Traffic Rural Roads in Uganda',
     (SELECT id FROM programmes WHERE code IN ('PHD-ENG','PHDENG') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.civ2@uems.ac.ug'),
     NULL,
     2020, 'thesis_submitted'),

    ('KIU/2021/P021',
     'Sustainable Urban Drainage Systems for Flooding Mitigation in Kampala',
     (SELECT id FROM programmes WHERE code IN ('PHD-ENG','PHDENG') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.civ1@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.civ2@uems.ac.ug'),
     2021, 'corrections_submitted'),

    -- PHD-ENG (Electrical)
    ('KIU/2021/P022',
     'Renewable Energy Integration and Grid Stability in Rural Electrification Projects',
     (SELECT id FROM programmes WHERE code IN ('PHD-ENG','PHDENG') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.ele1@uems.ac.ug'),
     (SELECT id FROM staff WHERE email = 'lect.ele2@uems.ac.ug'),
     2021, 'enrolled'),

    ('KIU/2022/P023',
     'Smart Metering and Demand-Side Management for Sub-Saharan Africa Power Utilities',
     (SELECT id FROM programmes WHERE code IN ('PHD-ENG','PHDENG') LIMIT 1),
     (SELECT id FROM staff WHERE email = 'lect.ele1@uems.ac.ug'),
     NULL,
     2022, 'enrolled');


-- ============================================================
--  SECTION 2: PHD CANDIDATE SUPERVISORS
--  Mirrors supervisor_id / co_supervisor_id from phd_candidates.
-- ============================================================

INSERT INTO phd_candidate_supervisors
    (candidate_id, supervisor_id, role, is_active, assigned_at)

-- Main supervisors
SELECT
    id,
    supervisor_id,
    'main'::supervisor_role,
    TRUE,
    created_at
FROM phd_candidates
WHERE supervisor_id IS NOT NULL

UNION ALL

-- Co-supervisors
SELECT
    id,
    co_supervisor_id,
    'co_supervisor'::supervisor_role,
    TRUE,
    created_at
FROM phd_candidates
WHERE co_supervisor_id IS NOT NULL;


-- ============================================================
--  SECTION 3: THESIS SUBMISSIONS
-- ============================================================

INSERT INTO thesis_submissions (
    candidate_id, file_name, file_path,
    file_size_kb, version, submission_notes, submitted_at
)
VALUES
    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/1001'),
     'Mukasa_John_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2020-1001/v1/Mukasa_John_PhD_Thesis_Final.pdf',
     4520, 1, 'Final draft approved by supervisors for Viva.', NOW() - INTERVAL '15 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/1002'),
     'Nabunya_Sarah_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2020-1002/v1/Nabunya_Sarah_PhD_Thesis_Final.pdf',
     3890, 1, 'Submitted after minor corrections.', NOW() - INTERVAL '10 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/P001'),
     'Sekitto_Adam_PhD_Thesis_v2.pdf',
     '/uploads/theses/KIU-2019-P001/v2/Sekitto_Adam_PhD_Thesis_v2.pdf',
     5120, 2, 'Resubmission after corrections from first viva.', NOW() - INTERVAL '30 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/P002'),
     'Atim_Beatrice_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2019-P002/v1/Atim_Beatrice_PhD_Thesis_Final.pdf',
     4780, 1, 'First submission for review.', NOW() - INTERVAL '8 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/P003'),
     'Lubega_Charles_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2019-P003/v1/Lubega_Charles_PhD_Thesis_Final.pdf',
     5930, 1, 'Defended and passed. Final copy submitted.', NOW() - INTERVAL '60 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/2001'),
     'Okello_Peter_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2019-2001/v1/Okello_Peter_PhD_Thesis_Final.pdf',
     6100, 1, 'Comprehensive 5-year study final document.', NOW() - INTERVAL '20 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/2002'),
     'Ainomugisha_Grace_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2019-2002/v1/Ainomugisha_Grace_PhD_Thesis_Final.pdf',
     5240, 1, 'Final submission.', NOW() - INTERVAL '12 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/P004'),
     'Oryem_Nicholas_PhD_Thesis_v2.pdf',
     '/uploads/theses/KIU-2019-P004/v2/Oryem_Nicholas_PhD_Thesis_v2.pdf',
     4400, 2, 'Resubmission incorporating examiner corrections.', NOW() - INTERVAL '25 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/P005'),
     'Namugosa_Diana_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2020-P005/v1/Namugosa_Diana_PhD_Thesis_Final.pdf',
     3760, 1, 'First submission.', NOW() - INTERVAL '5 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/3001'),
     'Tumwesigye_David_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2021-3001/v1/Tumwesigye_David_PhD_Thesis_Final.pdf',
     4100, 1, 'Legal thesis ready for defense.', NOW() - INTERVAL '18 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/P007'),
     'Nankya_Ruth_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2021-P007/v1/Nankya_Ruth_PhD_Thesis_Final.pdf',
     4850, 1, 'First and final submission.', NOW() - INTERVAL '9 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/P008'),
     'Mugabi_Richard_PhD_Thesis_v2.pdf',
     '/uploads/theses/KIU-2021-P008/v2/Mugabi_Richard_PhD_Thesis_v2.pdf',
     3920, 2, 'Revised after panel review.', NOW() - INTERVAL '22 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/4001'),
     'Nakamya_Jane_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2020-4001/v1/Nakamya_Jane_PhD_Thesis_Final.pdf',
     5010, 1, 'Ready for viva.', NOW() - INTERVAL '14 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/P011'),
     'Barigye_Felix_PhD_Thesis_v2.pdf',
     '/uploads/theses/KIU-2020-P011/v2/Barigye_Felix_PhD_Thesis_v2.pdf',
     4690, 2, 'Corrections incorporated.', NOW() - INTERVAL '28 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/P012'),
     'Nantume_Lydia_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2021-P012/v1/Nantume_Lydia_PhD_Thesis_Final.pdf',
     3540, 1, 'First submission pending review.', NOW() - INTERVAL '6 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/5001'),
     'Olupot_Samuel_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2021-5001/v1/Olupot_Samuel_PhD_Thesis_Final.pdf',
     4250, 1, 'Supervisor-approved.', NOW() - INTERVAL '16 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/P015'),
     'Nassali_Irene_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2021-P015/v1/Nassali_Irene_PhD_Thesis_Final.pdf',
     3870, 1, 'Submitted to graduate school.', NOW() - INTERVAL '7 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/P016'),
     'Kirunda_Andrew_PhD_Thesis_v2.pdf',
     '/uploads/theses/KIU-2021-P016/v2/Kirunda_Andrew_PhD_Thesis_v2.pdf',
     4020, 2, 'Post-corrections resubmission.', NOW() - INTERVAL '33 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/P019'),
     'Namutebi_Oliver_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2020-P019/v1/Namutebi_Oliver_PhD_Thesis_Final.pdf',
     5640, 1, 'Ready for viva.', NOW() - INTERVAL '11 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/P020'),
     'Okidi_Lawrence_PhD_Thesis_Final.pdf',
     '/uploads/theses/KIU-2020-P020/v1/Okidi_Lawrence_PhD_Thesis_Final.pdf',
     4930, 1, 'First submission.', NOW() - INTERVAL '4 days'),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/P021'),
     'Tumusiime_Caroline_PhD_Thesis_v2.pdf',
     '/uploads/theses/KIU-2021-P021/v2/Tumusiime_Caroline_PhD_Thesis_v2.pdf',
     5100, 2, 'Revised thesis — corrections applied.', NOW() - INTERVAL '40 days');


-- ============================================================
--  SECTION 4: VIVA SCHEDULES
-- ============================================================

INSERT INTO viva_schedules (
    candidate_id, thesis_id, scheduled_date, scheduled_time,
    venue, duration_minutes, status, postponement_reason, created_by
)
VALUES
    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/1001'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/1001') LIMIT 1),
     CURRENT_DATE + INTERVAL '7 days', '09:00',
     'ICT Building, Room 101', 120, 'scheduled', NULL,
     (SELECT id FROM staff WHERE email = 'admin@uems.ac.ug')),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/1002'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/1002') LIMIT 1),
     CURRENT_DATE + INTERVAL '7 days', '14:00',
     'ICT Building, Room 101', 90, 'scheduled', NULL,
     (SELECT id FROM staff WHERE email = 'admin@uems.ac.ug')),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/P001'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/P001') LIMIT 1),
     CURRENT_DATE - INTERVAL '45 days', '10:00',
     'ICT Building, Room 102', 120, 'completed', NULL,
     (SELECT id FROM staff WHERE email = 'admin@uems.ac.ug')),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/2001'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/2001') LIMIT 1),
     CURRENT_DATE + INTERVAL '14 days', '10:00',
     'School of Health Sciences, Boardroom', 120, 'scheduled', NULL,
     (SELECT id FROM staff WHERE email = 'dean.sph@uems.ac.ug')),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/2002'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/2002') LIMIT 1),
     CURRENT_DATE - INTERVAL '5 days', '10:00',
     'School of Health Sciences, Boardroom', 90, 'postponed',
     'Lead external examiner fell ill; pending reschedule.',
     (SELECT id FROM staff WHERE email = 'dean.sph@uems.ac.ug')),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/P004'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2019/P004') LIMIT 1),
     CURRENT_DATE - INTERVAL '40 days', '09:00',
     'School of Health Sciences, Seminar Room', 90, 'completed', NULL,
     (SELECT id FROM staff WHERE email = 'dean.sph@uems.ac.ug')),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/3001'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/3001') LIMIT 1),
     CURRENT_DATE + INTERVAL '21 days', '09:30',
     'Faculty of Law, Moot Court Room', 120, 'scheduled', NULL,
     (SELECT id FROM staff WHERE email = 'dean.sol@uems.ac.ug')),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/P008'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/P008') LIMIT 1),
     CURRENT_DATE - INTERVAL '35 days', '14:00',
     'Faculty of Law, Conference Room', 90, 'completed', NULL,
     (SELECT id FROM staff WHERE email = 'dean.sol@uems.ac.ug')),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/4001'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/4001') LIMIT 1),
     CURRENT_DATE + INTERVAL '10 days', '11:00',
     'College of Business, Boardroom A', 120, 'scheduled', NULL,
     (SELECT id FROM staff WHERE email = 'admin@uems.ac.ug')),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/P011'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/P011') LIMIT 1),
     CURRENT_DATE - INTERVAL '50 days', '10:00',
     'College of Business, Boardroom B', 90, 'completed', NULL,
     (SELECT id FROM staff WHERE email = 'admin@uems.ac.ug')),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/5001'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/5001') LIMIT 1),
     CURRENT_DATE + INTERVAL '18 days', '09:00',
     'College of Education, Seminar Hall', 120, 'scheduled', NULL,
     (SELECT id FROM staff WHERE email = 'admin@uems.ac.ug')),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/P016'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/P016') LIMIT 1),
     CURRENT_DATE - INTERVAL '55 days', '14:30',
     'College of Education, Room 201', 90, 'completed', NULL,
     (SELECT id FROM staff WHERE email = 'admin@uems.ac.ug')),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/P019'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2020/P019') LIMIT 1),
     CURRENT_DATE + INTERVAL '12 days', '10:00',
     'College of Engineering, Workshop Hall', 120, 'scheduled', NULL,
     (SELECT id FROM staff WHERE email = 'admin@uems.ac.ug')),

    ((SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/P021'),
     (SELECT id FROM thesis_submissions WHERE candidate_id = (SELECT id FROM phd_candidates WHERE registration_number = 'KIU/2021/P021') LIMIT 1),
     CURRENT_DATE - INTERVAL '60 days', '09:30',
     'College of Engineering, Conference Room', 90, 'completed', NULL,
     (SELECT id FROM staff WHERE email = 'admin@uems.ac.ug'));


-- ============================================================
--  SECTION 5: VIVA EXAMINERS
--  Assigns examiners to viva sessions via the viva_examiners table.
--  This is the CORRECT table for examiner assignments (not supervisors table).
--  Note: lect.math1 and lect.epid1 are used as stand-ins for
--  external examiners (no dedicated external accounts in seed).
-- ============================================================

INSERT INTO viva_examiners (viva_id, examiner_id, role, panel_slot, confirmed, confirmed_at, notified_at)

-- CS candidates: KIU/2020/1001, KIU/2020/1002, KIU/2019/P001
SELECT vs.id, u.id, ex.role, ex.panel_slot, ex.confirmed,
       CASE WHEN ex.confirmed THEN NOW() - INTERVAL '3 days' ELSE NULL END,
       NOW() - INTERVAL '5 days'
FROM viva_schedules vs
JOIN phd_candidates pc ON vs.candidate_id = pc.id
CROSS JOIN LATERAL (VALUES
    ((SELECT id FROM staff WHERE email = 'viva.coord@uems.ac.ug'), 'chairperson'::examiner_role,       NULL, TRUE),
    ((SELECT id FROM staff WHERE email = 'prof.kato@uems.ac.ug'),  'internal_examiner'::examiner_role, 1,    TRUE),
    ((SELECT id FROM staff WHERE email = 'lect.cs1@uems.ac.ug'),   'internal_examiner'::examiner_role, 2,    TRUE),
    ((SELECT id FROM staff WHERE email = 'ext.smith@external.ac.uk'), 'external_examiner'::examiner_role, 3,    TRUE)
) AS ex(id, role, panel_slot, confirmed)
JOIN staff u ON u.id = ex.id
WHERE pc.registration_number IN ('KIU/2020/1001','KIU/2020/1002','KIU/2019/P001')

UNION ALL

-- PH candidates: KIU/2019/2001, KIU/2019/2002, KIU/2019/P004
SELECT vs.id, u.id, ex.role, ex.panel_slot, ex.confirmed,
       CASE WHEN ex.confirmed THEN NOW() - INTERVAL '3 days' ELSE NULL END,
       NOW() - INTERVAL '5 days'
FROM viva_schedules vs
JOIN phd_candidates pc ON vs.candidate_id = pc.id
CROSS JOIN LATERAL (VALUES
    ((SELECT id FROM staff WHERE email = 'dean.sph@uems.ac.ug'),   'chairperson'::examiner_role,       NULL, TRUE),
    ((SELECT id FROM staff WHERE email = 'prof.musoke@uems.ac.ug'),'internal_examiner'::examiner_role, 1,    TRUE),
    ((SELECT id FROM staff WHERE email = 'lect.ph1@uems.ac.ug'),   'internal_examiner'::examiner_role, 2,    TRUE),
    ((SELECT id FROM staff WHERE email = 'ext.njeri@external.ac.ke'), 'external_examiner'::examiner_role, 3,    FALSE)
) AS ex(id, role, panel_slot, confirmed)
JOIN staff u ON u.id = ex.id
WHERE pc.registration_number IN ('KIU/2019/2001','KIU/2019/2002','KIU/2019/P004')

UNION ALL

-- LAW candidates: KIU/2021/3001, KIU/2021/P008
SELECT vs.id, u.id, ex.role, ex.panel_slot, ex.confirmed,
       CASE WHEN ex.confirmed THEN NOW() - INTERVAL '3 days' ELSE NULL END,
       NOW() - INTERVAL '5 days'
FROM viva_schedules vs
JOIN phd_candidates pc ON vs.candidate_id = pc.id
CROSS JOIN LATERAL (VALUES
    ((SELECT id FROM staff WHERE email = 'dean.sol@uems.ac.ug'),   'chairperson'::examiner_role,       NULL, TRUE),
    ((SELECT id FROM staff WHERE email = 'prof.kato@uems.ac.ug'),  'internal_examiner'::examiner_role, 1,    TRUE),
    ((SELECT id FROM staff WHERE email = 'lect.law1@uems.ac.ug'),  'internal_examiner'::examiner_role, 2,    TRUE),
    ((SELECT id FROM staff WHERE email = 'ext.smith@external.ac.uk'), 'external_examiner'::examiner_role, 3,    TRUE)
) AS ex(id, role, panel_slot, confirmed)
JOIN staff u ON u.id = ex.id
WHERE pc.registration_number IN ('KIU/2021/3001','KIU/2021/P008')

UNION ALL

-- BA candidates: KIU/2020/4001, KIU/2020/P011
SELECT vs.id, u.id, ex.role, ex.panel_slot, ex.confirmed,
       CASE WHEN ex.confirmed THEN NOW() - INTERVAL '3 days' ELSE NULL END,
       NOW() - INTERVAL '5 days'
FROM viva_schedules vs
JOIN phd_candidates pc ON vs.candidate_id = pc.id
CROSS JOIN LATERAL (VALUES
    ((SELECT id FROM staff WHERE email = 'dean.som@uems.ac.ug'),   'chairperson'::examiner_role,       NULL, TRUE),
    ((SELECT id FROM staff WHERE email = 'prof.musoke@uems.ac.ug'),'internal_examiner'::examiner_role, 1,    TRUE),
    ((SELECT id FROM staff WHERE email = 'lect.bus1@uems.ac.ug'),  'internal_examiner'::examiner_role, 2,    TRUE),
    ((SELECT id FROM staff WHERE email = 'ext.njeri@external.ac.ke'), 'external_examiner'::examiner_role, 3,    TRUE)
) AS ex(id, role, panel_slot, confirmed)
JOIN staff u ON u.id = ex.id
WHERE pc.registration_number IN ('KIU/2020/4001','KIU/2020/P011')

UNION ALL

-- MSEA candidates: KIU/2021/5001, KIU/2021/P016
SELECT vs.id, u.id, ex.role, ex.panel_slot, ex.confirmed,
       CASE WHEN ex.confirmed THEN NOW() - INTERVAL '3 days' ELSE NULL END,
       NOW() - INTERVAL '5 days'
FROM viva_schedules vs
JOIN phd_candidates pc ON vs.candidate_id = pc.id
CROSS JOIN LATERAL (VALUES
    ((SELECT id FROM staff WHERE email = 'dean.soe@uems.ac.ug'),   'chairperson'::examiner_role,       NULL, TRUE),
    ((SELECT id FROM staff WHERE email = 'prof.kato@uems.ac.ug'),  'internal_examiner'::examiner_role, 1,    TRUE),
    ((SELECT id FROM staff WHERE email = 'lect.edu1@uems.ac.ug'),  'internal_examiner'::examiner_role, 2,    TRUE),
    ((SELECT id FROM staff WHERE email = 'ext.smith@external.ac.uk'), 'external_examiner'::examiner_role, 3,    TRUE)
) AS ex(id, role, panel_slot, confirmed)
JOIN staff u ON u.id = ex.id
WHERE pc.registration_number IN ('KIU/2021/5001','KIU/2021/P016')

UNION ALL

-- ENG candidates: KIU/2020/P019, KIU/2021/P021
SELECT vs.id, u.id, ex.role, ex.panel_slot, ex.confirmed,
       CASE WHEN ex.confirmed THEN NOW() - INTERVAL '3 days' ELSE NULL END,
       NOW() - INTERVAL '5 days'
FROM viva_schedules vs
JOIN phd_candidates pc ON vs.candidate_id = pc.id
CROSS JOIN LATERAL (VALUES
    ((SELECT id FROM staff WHERE email = 'dean.eng@uems.ac.ug'),   'chairperson'::examiner_role,       NULL, TRUE),
    ((SELECT id FROM staff WHERE email = 'prof.musoke@uems.ac.ug'),'internal_examiner'::examiner_role, 1,    TRUE),
    ((SELECT id FROM staff WHERE email = 'lect.civ1@uems.ac.ug'),  'internal_examiner'::examiner_role, 2,    TRUE),
    ((SELECT id FROM staff WHERE email = 'ext.njeri@external.ac.ke'), 'external_examiner'::examiner_role, 3,    TRUE)
) AS ex(id, role, panel_slot, confirmed)
JOIN staff u ON u.id = ex.id
WHERE pc.registration_number IN ('KIU/2020/P019','KIU/2021/P021');


-- ============================================================
--  SECTION 6: VIVA EVALUATIONS (for all completed vivas)
--  Each examiner provides their individual evaluation via viva_evaluations
-- ============================================================

INSERT INTO viva_evaluations (
    viva_id, examiner_id,
    originality_score, methodology_score, presentation_score, literature_score,
    strengths, weaknesses, recommended_corrections, general_comments,
    submitted_at, is_submitted
)

-- PHD-COMPSCI: Sekitto Adam (KIU/2019/P001)
SELECT vs.id,
       unnest(ARRAY[
           (SELECT id FROM staff WHERE email = 'prof.kato@uems.ac.ug'),
           (SELECT id FROM staff WHERE email = 'lect.cs1@uems.ac.ug'),
           (SELECT id FROM staff WHERE email = 'ext.smith@external.ac.uk')
       ]),
       unnest(ARRAY[20, 18, 19]),
       unnest(ARRAY[21, 19, 20]),
       unnest(ARRAY[18, 20, 17]),
       unnest(ARRAY[22, 20, 21]),
       unnest(ARRAY[
           'Highly original approach to NLP for Luganda.',
           'Well-structured experimental design.',
           'Impressive command of recent literature.'
       ]),
       unnest(ARRAY[
           'Chapter 4 needs tighter argumentation.',
           'Some datasets are under-described.',
           'Conclusion chapter too brief.'
       ]),
       unnest(ARRAY[
           'Expand chapter 4 discussion section.',
           'Add appendix with dataset metadata.',
           'Rewrite conclusion with future research directions.'
       ]),
       unnest(ARRAY[
           'Overall a commendable thesis ready for minor corrections.',
           'Good research with some gaps to address.',
           'Recommend pass with minor corrections.'
       ]),
       NOW() - INTERVAL '44 days', TRUE
FROM viva_schedules vs
JOIN phd_candidates pc ON vs.candidate_id = pc.id
WHERE pc.registration_number = 'KIU/2019/P001'

UNION ALL

-- PHD-PH: Oryem Nicholas (KIU/2019/P004)
SELECT vs.id,
       unnest(ARRAY[
           (SELECT id FROM staff WHERE email = 'prof.musoke@uems.ac.ug'),
           (SELECT id FROM staff WHERE email = 'lect.ph1@uems.ac.ug'),
           (SELECT id FROM staff WHERE email = 'ext.njeri@external.ac.ke')
       ]),
       unnest(ARRAY[19, 17, 18]),
       unnest(ARRAY[20, 19, 21]),
       unnest(ARRAY[17, 18, 19]),
       unnest(ARRAY[21, 20, 20]),
       unnest(ARRAY[
           'Community engagement component is excellent.',
           'Strong epidemiological framework.',
           'Good use of WHO frameworks.'
       ]),
       unnest(ARRAY[
           'Data collection period was limited.',
           'Some statistical tests not justified.',
           'Discussion of policy implications thin.'
       ]),
       unnest(ARRAY[
           'Extend data collection description.',
           'Justify choice of regression models.',
           'Expand policy recommendations section.'
       ]),
       unnest(ARRAY[
           'Minor corrections recommended.',
           'Pass with corrections.',
           'Solid thesis overall.'
       ]),
       NOW() - INTERVAL '39 days', TRUE
FROM viva_schedules vs
JOIN phd_candidates pc ON vs.candidate_id = pc.id
WHERE pc.registration_number = 'KIU/2019/P004'

UNION ALL

-- PHD-LAW: Mugabi Richard (KIU/2021/P008)
SELECT vs.id,
       unnest(ARRAY[
           (SELECT id FROM staff WHERE email = 'prof.kato@uems.ac.ug'),
           (SELECT id FROM staff WHERE email = 'lect.law1@uems.ac.ug'),
           (SELECT id FROM staff WHERE email = 'ext.smith@external.ac.uk')
       ]),
       unnest(ARRAY[22, 20, 21]),
       unnest(ARRAY[20, 21, 20]),
       unnest(ARRAY[19, 18, 20]),
       unnest(ARRAY[23, 22, 21]),
       unnest(ARRAY[
           'Thorough comparative analysis of corporate law regimes.',
           'Excellent use of case law.',
           'Original contribution to Ugandan corporate governance literature.'
       ]),
       unnest(ARRAY[
           'Introduction is overly long.',
           'Some jurisdictional comparisons need updating.',
           'Footnote style inconsistent.'
       ]),
       unnest(ARRAY[
           'Trim introduction to 15 pages.',
           'Update comparative sections with 2024 amendments.',
           'Standardise footnote referencing to OSCOLA.'
       ]),
       unnest(ARRAY[
           'Recommend pass with minor corrections.',
           'Excellent work deserving commendation.',
           'Strong PhD-level contribution.'
       ]),
       NOW() - INTERVAL '34 days', TRUE
FROM viva_schedules vs
JOIN phd_candidates pc ON vs.candidate_id = pc.id
WHERE pc.registration_number = 'KIU/2021/P008'

UNION ALL

-- PHD-BA: Barigye Felix (KIU/2020/P011)
SELECT vs.id,
       unnest(ARRAY[
           (SELECT id FROM staff WHERE email = 'prof.musoke@uems.ac.ug'),
           (SELECT id FROM staff WHERE email = 'lect.bus1@uems.ac.ug'),
           (SELECT id FROM staff WHERE email = 'ext.njeri@external.ac.ke')
       ]),
       unnest(ARRAY[18, 19, 17]),
       unnest(ARRAY[19, 20, 18]),
       unnest(ARRAY[20, 19, 21]),
       unnest(ARRAY[19, 18, 20]),
       unnest(ARRAY[
           'Novel application of resilience theory to Ugandan SMEs.',
           'Good mixed-methods design.',
           'Practically relevant findings.'
       ]),
       unnest(ARRAY[
           'Literature review lacks recent African supply chain studies.',
           'Survey sample size could be larger.',
           'Theoretical framework section is weak.'
       ]),
       unnest(ARRAY[
           'Add 10 recent sub-Saharan supply chain studies to literature.',
           'Discuss sampling limitations more explicitly.',
           'Strengthen chapter 2 theoretical framework.'
       ]),
       unnest(ARRAY[
           'Pass with minor corrections.',
           'Good research contribution.',
           'Recommend minor revision and resubmission.'
       ]),
       NOW() - INTERVAL '49 days', TRUE
FROM viva_schedules vs
JOIN phd_candidates pc ON vs.candidate_id = pc.id
WHERE pc.registration_number = 'KIU/2020/P011'

UNION ALL

-- PHD-MSEA: Kirunda Andrew (KIU/2021/P016)
SELECT vs.id,
       unnest(ARRAY[
           (SELECT id FROM staff WHERE email = 'prof.kato@uems.ac.ug'),
           (SELECT id FROM staff WHERE email = 'lect.edu1@uems.ac.ug'),
           (SELECT id FROM staff WHERE email = 'ext.smith@external.ac.uk')
       ]),
       unnest(ARRAY[21, 20, 19]),
       unnest(ARRAY[20, 22, 20]),
       unnest(ARRAY[19, 18, 20]),
       unnest(ARRAY[20, 21, 19]),
       unnest(ARRAY[
           'Timely and important topic for post-COVID education.',
           'Strong qualitative component.',
           'Clear research questions and methodology.'
       ]),
       unnest(ARRAY[
           'Technology access disparities not fully explored.',
           'Teacher perspectives underrepresented.',
           'Recommendations section underdeveloped.'
       ]),
       unnest(ARRAY[
           'Add a section on technology infrastructure gaps.',
           'Include more teacher interview data.',
           'Expand policy recommendations to 5 pages.'
       ]),
       unnest(ARRAY[
           'Minor corrections; overall pass recommended.',
           'Very good work with small gaps.',
           'Pass with corrections.'
       ]),
       NOW() - INTERVAL '54 days', TRUE
FROM viva_schedules vs
JOIN phd_candidates pc ON vs.candidate_id = pc.id
WHERE pc.registration_number = 'KIU/2021/P016'

UNION ALL

-- PHD-ENG: Tumusiime Caroline (KIU/2021/P021)
SELECT vs.id,
       unnest(ARRAY[
           (SELECT id FROM staff WHERE email = 'prof.musoke@uems.ac.ug'),
           (SELECT id FROM staff WHERE email = 'lect.civ1@uems.ac.ug'),
           (SELECT id FROM staff WHERE email = 'ext.njeri@external.ac.ke')
       ]),
       unnest(ARRAY[22, 21, 20]),
       unnest(ARRAY[23, 22, 21]),
       unnest(ARRAY[20, 19, 22]),
       unnest(ARRAY[21, 22, 20]),
       unnest(ARRAY[
           'Outstanding hydraulic modelling work.',
           'Comprehensive fieldwork in multiple catchments.',
           'Practical design solutions well-presented.'
       ]),
       unnest(ARRAY[
           'Cost-benefit analysis is superficial.',
           'Chapter 5 results need more discussion.',
           'Some figures lack proper scale bars.'
       ]),
       unnest(ARRAY[
           'Develop full cost-benefit analysis in appendix.',
           'Expand discussion of results in chapter 5.',
           'Add scale bars to all site maps and figures.'
       ]),
       unnest(ARRAY[
           'Recommend pass with minor corrections.',
           'Excellent engineering PhD thesis.',
           'Strong technical contribution — pass.'
       ]),
       NOW() - INTERVAL '59 days', TRUE
FROM viva_schedules vs
JOIN phd_candidates pc ON vs.candidate_id = pc.id
WHERE pc.registration_number = 'KIU/2021/P021';


-- ============================================================
--  SECTION 7: VIVA RECOMMENDATIONS
-- ============================================================

INSERT INTO viva_recommendations (
    viva_id, outcome, correction_deadline,
    final_comments, issued_by, issued_at
)
SELECT vs.id,
       rec.outcome::viva_outcome,
       rec.correction_deadline,
       rec.final_comments,
       (SELECT id FROM staff WHERE email = rec.issued_by_email),
       rec.issued_at
FROM viva_schedules vs
JOIN phd_candidates pc ON vs.candidate_id = pc.id
JOIN (VALUES
    ('KIU/2019/P001', 'pass_with_minor_corrections', CURRENT_DATE + INTERVAL '30 days',
     'Panel unanimously recommends pass with minor corrections. Candidate to address NLP chapter argumentation and dataset appendix.',
     'admin@uems.ac.ug', NOW() - INTERVAL '43 days'),

    ('KIU/2019/P003', 'pass', NULL,
     'Candidate has passed unconditionally. PhD degree to be conferred at next graduation.',
     'admin@uems.ac.ug', NOW() - INTERVAL '58 days'),

    ('KIU/2019/P004', 'pass_with_minor_corrections', CURRENT_DATE + INTERVAL '21 days',
     'Corrections to statistical methodology and policy discussion section required within 21 days.',
     'dean.sph@uems.ac.ug', NOW() - INTERVAL '38 days'),

    ('KIU/2021/P008', 'pass_with_minor_corrections', CURRENT_DATE + INTERVAL '30 days',
     'Outstanding legal scholarship. Minor corrections to introduction length and footnote style.',
     'dean.sol@uems.ac.ug', NOW() - INTERVAL '33 days'),

    ('KIU/2020/P011', 'pass_with_minor_corrections', CURRENT_DATE + INTERVAL '21 days',
     'Candidate to address literature gaps and strengthen theoretical framework.',
     'admin@uems.ac.ug', NOW() - INTERVAL '48 days'),

    ('KIU/2021/P016', 'pass_with_minor_corrections', CURRENT_DATE + INTERVAL '30 days',
     'Minor corrections required. Teacher perspectives and policy recommendations to be expanded.',
     'admin@uems.ac.ug', NOW() - INTERVAL '53 days'),

    ('KIU/2021/P021', 'pass_with_minor_corrections', CURRENT_DATE + INTERVAL '21 days',
     'Excellent engineering contribution. Cost-benefit analysis and figure annotations to be completed.',
     'admin@uems.ac.ug', NOW() - INTERVAL '58 days')

) AS rec(reg_no, outcome, correction_deadline, final_comments, issued_by_email, issued_at)
ON pc.registration_number = rec.reg_no
WHERE vs.status = 'completed';