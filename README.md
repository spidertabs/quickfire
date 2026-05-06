<p align="center">
  <img src="assets/images/q_light.png" width="120" alt="Quickfire Logo" style="border-radius: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"/>
</p>

# Quickfire Exam Portal App
A powerful, hardened assessment extension of the **Quickfire Student App — UEMS-PHD-VV** system for **Kampala International University** students, meticulously designed for academic integrity and seamless submission management.

---

## 🌟 Key Features

- 🟢 **Premium Green Branding** — Optimized professional aesthetic matching the official KIU identity.
- 📋 **Unified Tasks Hub** — A consolidated workspace for active assessments, in-progress tasks, and historical submission previews.
- 🛡️ **Hardened Linux Anti-Cheat** — Multi-layer desktop lockdown including window focus tracking, minimize blocking, and persistent kiosk enforcement.
- 🔍 **Privacy-First Preview** — Review your submitted answers through a dedicated "Answer Preview" mode that hides all grading metrics (marks, percentages, "correct/wrong" labels) for initial feedback.
- 🔒 **Resume Lockdown** — Persistent security tracking that automatically locks any assessment being resumed from a previous session to ensure supervisor oversight.
- ✅ **Multi-Platform Security** — Consistent lockdown protocols across Web, Mobile, and Linux Desktop environments.
- 💾 **Robust Sync Logic** — Automatic background syncing with local caching ensures no progress is lost, even during university network outages.
- 📄 **Academic PDF Export** — Professional submission records with official KIU branding, formatted for official printing and storage.

---

## 🛡️ Security & Integrity Protocol

The platform implements the **UEMS "Ironclad" Security Standard**:
1. **Persistent Kiosk Mode**: Fullscreen and "Always-On-Top" enforcement prevent unauthorized window switching.
2. **Behavioral Lockdown**: 
    - **Focus Loss**: Locking occurs immediately if the application loses window focus.
    - **Minimization**: Any attempt to minimize the app triggers a security violation.
    - **Back-Button Interception**: Intelligent `PopScope` integration prevents accidental screen exits with formal confirmation dialogs.
3. **Supervisor Verification**: Re-entry into any locked or resumed session requires a lecturer to enter a secure 4-digit verification pin (Default: `8888`).
4. **Visual Accountability**: High-intensity "Security Lockdown" overlays ensure that unauthorized activity is immediately visible to invigilators.

---

## 🚦 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.x (Hardened build) |
| **OS Support** | Linux Desktop, Android, iOS, Web |
| **Backend** | Supabase (PostgreSQL with RLS + REST Logic) |
| **Desktop Security** | Window Manager 0.5.x + Custom Focus Listeners |
| **Reporting** | PDF Library with Custom Branding Engine |
| **Data Flow** | Debounced Background Sync Queue |

---

## 📁 Project Structure

```bash
lib/
├── main.dart                    # Entry point & Window Initialization
├── theme.dart                   # Premium Green Design System
├── services/
│   ├── supabase_service.dart    # Cloud API & Transactional Logic
│   └── offline_service.dart     # Background Task Sync & Caching
├── utils/
│   ├── fullscreen.dart          # Platform-specific Lockdown Bridge
│   └── report_exporter.dart     # PDF generation engine
└── screens/
    ├── assessment_screen.dart   # Secure Exam Engine (Lockdown + Confirmation)
    ├── home_screen.dart         # Unified Task Hub & Dashboard
    └── report_screen.dart       # Academic Submission Preview
```

---

## 📖 How to Use the Application

### 1. Dashboard & Course Directory
Upon logging into Quickfire, you enter your primary dashboard.
- The **Dashboard** showcases your key metrics like total pending work and recent activity.
- The **Courses** section allows you to view all enrolled classes.

`![Dashboard](assets/screenshots/dashboard.png)`
`![Course Directory](assets/screenshots/course_directory.png)`

### 2. Unified Tasks Hub
Select the **Tasks** tab to interact with your assessments.
- Available tasks can be started from here.
- Completed tasks are marked with a success badge and can be reviewed directly by clicking on them.

`![Tasks Screen](assets/screenshots/task_screen.png)`

### 3. The Exam Environment
Entering an assessment engages **Persistent Kiosk Mode**. Focus on your work in a distraction-free layout.
- Use the left sidebar to navigate quickly between questions.
- Answers are **auto-saved** via our robust sync logic. Keep an eye on the live timer!

`![Assignment Screen](assets/screenshots/assignment_screen.png)`

### 4. Back-Button Interception (Security Warnings)
The assessment environment is built to prevent accidental and unauthorized exits.
- If you attempt to use the system back-button or click to exit, you will receive a formal confirmation dialog warning you of the academic integrity consequences.

`![Exit Warning Dialog](assets/screenshots/warning_before_clicking_back.png)`

### 5. Security Interventions (Lockdown)
If you deliberately bypass the environment (e.g., changing windows, minimizing, or escaping fullscreen):
- A high-visibility **Security Lockdown** screen halts the assessment.
- Only an authorized lecturer can unlock the session by entering their 4-digit verification code.

`![Assessment Locked](assets/screenshots/assesment_locked.png)`

---

## 📝 Operating Notes

- **Unified Navigation**: The "Preview" module has been merged into the **Tasks** list. Finished assignments are marked with a "Completed" badge and can be viewed directly from there.
- **Privacy Mode**: "showResults" is set to `false` for student previews by default. This hides all marks and fractional counts (e.g., "4/22") to focus on the content of the work.
- **Lockdown Persistence**: Once a lockdown is triggered, the app stays locked even if restarted, until a supervisor provides the unlock code.

---

**Spider Tabs Ltd · UEMS-PHD-VV © 2026**  
*Kampala International University*
