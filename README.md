<p align="center">
  <img src="assets/images/q_light.png" width="120" alt="Quickfire Logo" style="border-radius: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.1);"/>
</p>

# Quickfire Exam Portal

A powerful, hardened assessment extension of the **UEMS-PHD-VV** platform — built exclusively for **Kampala International University** students and designed to uphold academic integrity while ensuring a seamless examination experience.

---

## 🌟 Key Features

- 🟢 **Premium Green Branding** — A polished, professional aesthetic aligned with the official KIU visual identity.
- 📋 **Unified Tasks Hub** — A consolidated workspace for active assessments, in-progress tasks, and completed submission reviews — all in one place.
- 🛡️ **Hardened Anti-Cheat (Linux)** — Multi-layer desktop lockdown including window focus tracking, minimize blocking, and persistent kiosk enforcement.
- 🔍 **Privacy-First Preview** — Review submitted answers through a dedicated preview mode that hides all grading metrics (marks, percentages, and correct/wrong labels) to keep focus on content.
- 🔒 **Resume Lockdown** — Any assessment resumed from a previous session is automatically locked, ensuring mandatory supervisor oversight before continuing.
- ✅ **Multi-Platform Security** — Consistent lockdown protocols across Web, Android, iOS, and Linux Desktop.
- 💾 **Robust Sync Engine** — Automatic background syncing with local caching ensures no progress is lost, even during network outages.
- 📄 **Academic PDF Export** — Professional submission records with official KIU branding, formatted for printing and archival.

---

## 🛡️ Security & Integrity Protocol

Quickfire implements the **UEMS "Ironclad" Security Standard**:

1. **Persistent Kiosk Mode** — Fullscreen and "Always-On-Top" enforcement prevent unauthorized window switching.
2. **Behavioral Lockdown**
   - **Focus Loss** — The session locks immediately if the application loses window focus.
   - **Minimization** — Any attempt to minimize the app triggers a security violation.
   - **Back-Button Interception** — Intelligent `PopScope` integration intercepts accidental exits with a formal confirmation dialog.
3. **Supervisor Verification** — Re-entry into any locked or resumed session requires a lecturer to enter a secure 4-digit PIN *(Default: `8888`)*.
4. **Visual Accountability** — High-visibility "Security Lockdown" overlays make unauthorized activity immediately apparent to invigilators.

---

## 🚦 Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x (Hardened Build) |
| **OS Support** | Linux Desktop, Android, iOS, Web |
| **Backend** | Supabase (PostgreSQL with RLS + REST Logic) |
| **Desktop Security** | Window Manager 0.5.x + Custom Focus Listeners |
| **Reporting** | PDF Library with Custom Branding Engine |
| **Data Flow** | Debounced Background Sync Queue |

---

## 📁 Project Structure

```
lib/
├── main.dart                    # Entry point & window initialization
├── theme.dart                   # Premium Green design system
├── services/
│   ├── supabase_service.dart    # Cloud API & transactional logic
│   └── offline_service.dart     # Background task sync & caching
├── utils/
│   ├── fullscreen.dart          # Platform-specific lockdown bridge
│   └── report_exporter.dart     # PDF generation engine
└── screens/
    ├── assessment_screen.dart   # Secure exam engine (lockdown + confirmation)
    ├── home_screen.dart         # Unified Task Hub & dashboard
    └── report_screen.dart       # Academic submission preview
```

---

## 📖 How to Use the Application

### 1. Dashboard & Course Directory

Upon logging in, you land on your primary dashboard.

- The **Dashboard** displays key metrics such as pending tasks and recent activity.
- The **Courses** tab lets you browse all enrolled classes.

![Dashboard](assets/screenshots/dashboard.png)
![Course Directory](assets/screenshots/course_directory.png)

---

### 2. Unified Tasks Hub

Navigate to the **Tasks** tab to manage your assessments.

- Available tasks can be launched directly from this view.
- Completed tasks display a success badge and can be reviewed by tapping them.

![Tasks Screen](assets/screenshots/task_screen.png)

---

### 3. The Exam Environment

Starting an assessment activates **Persistent Kiosk Mode** for a distraction-free experience.

- Use the left sidebar to jump between questions quickly.
- Answers are **auto-saved** continuously via the background sync engine.
- A live countdown timer is always visible.

![Assignment Screen](assets/screenshots/assignment_screen.png)

---

### 4. Back-Button Interception

The exam environment prevents accidental and unauthorized exits.

- Pressing the system back button or attempting to close the screen triggers a formal confirmation dialog outlining the academic integrity consequences of exiting.

![Exit Warning Dialog](assets/screenshots/warning_before_clicking_back.png)

---

### 5. Security Lockdown

If the environment is bypassed (e.g., switching windows, minimizing, or exiting fullscreen):

- A high-visibility **Security Lockdown** overlay immediately halts the assessment.
- Only an authorized lecturer can resume the session by entering their 4-digit verification PIN.

![Assessment Locked](assets/screenshots/assesment_locked.png)

---

## 📝 Operating Notes

- **Unified Navigation** — The "Preview" module is integrated into the Tasks list. Completed assignments are marked with a "Completed" badge and reviewable directly from there.
- **Privacy Mode** — `showResults` is set to `false` by default for student previews, hiding all marks, scores, and fractional counts to keep focus on the submitted content.
- **Lockdown Persistence** — Once triggered, a lockdown persists across app restarts until a supervisor provides the unlock code.

---

<p align="center">
  <strong>Spider Tabs Ltd · UEMS-PHD-VV © 2026</strong><br/>
  <em>Kampala International University</em>
</p>