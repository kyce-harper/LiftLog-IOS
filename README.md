# 🏋️ **LiftLog: The Strength Tracker Built for the Dedicated**

If you're like me, you're tired of workout apps that have subscriptions, AI garbage, and social features nobody asked for. **LiftLog** is the solution: it's a simple and robust strength tracker I built for myself—and for every other lifters who believes progress comes from the iron, not the algorithm.

This isn't a complex piece of software. It's a precise, private tool that respects your expertise and keeps your focus where it belongs: the next heavy set. I want it to be like a notebook and pencil that you cary around.

-----

## 🧠 The Philosophy: Master Your Own Program

The best training programs are written by you. You don't need generic AI suggestions; you need reliable data.

  * **100% Data Ownership:** Your logs stay on your device. Period. We use **Core Data** for rock-solid local persistence. No cloud, no account creation, no data collection. **Privacy isn't a feature; it's the foundation.**
  * **A Fair Transaction:** This is a professional tool. Buy it once, own it forever. No monthly fees, no hidden tiers.
  * **Progressive Overload, Simplified:** We make the hardest part of lifting—beating your last performance—the easiest part of logging.

-----

## ✨ Core Functionality & Technical Execution

LiftLog provides only the essentials, engineered to work flawlessly every time.

  * **Template Flow:** Define your workouts (**`WorkoutTemplate`**) and the exercises (**`TemplateExercise`**) within them. This blueprint structure is clean, fast, and repeatable.
  * **The Overload Cue:** When starting an exercise, the app instantly queries your local database to display your **most recent weight and reps**. This immediate feedback is the only "AI" you need to ensure you're adding weight or hitting extra reps.
  * **Rock-Solid History:** Your logs are structured beautifully. Every session is recorded as a dedicated **`WorkoutSession`**, allowing you to review entire workouts, not just scattered sets. You can drill down into any date to see the **set-by-set breakdown**.

-----

## 🛣️ Roadmap & Community Strategy

LiftLog is built to be stable and dependable first. While the core feature set is almost complete, future development will be dictated by community/family/personal feedback and a continued commitment to gym gains haha

### Pricing Model

The application will be released on the Apple App Store for a **one-time flat price**. This purchase grants lifetime access to the current feature set and all future updates. No subscriptions, ever.

### Open Source & Support

This project is **open source**. I encourage developers to inspect the architecture, submit fixes, and propose enhancements.

While the app will be open to contribution, I appreciate support for the time invested in its development and maintenance. The one-time App Store purchase serves as the primary way to support the project and myself. (Apple liscense is expensive lol)

### Future Development Plans

| Phase | Focus Area | Goal |
| :--- | :--- | :--- |
| **V1.0 - Stability** | Polish & UX Refinement | Add user settings (e.g., default weight unit), improve keyboard focus in the logging view, and ensure robust Core Data performance on ios devices. |


-----

## 📈 What I'm Learning: Software Engineering Mastery

Building LiftLog has been an exercise in disciplined software architecture, solidifying core Computer Science principles and production-ready techniques:

  * **System Architecture & Resource Management (SDA):** By implementing the **Singleton Pattern** with the `PersistenceController`, I mastered the control of critical shared resources. This design ensures that only one **Core Data stack** manages the database file, eliminating potential concurrency issues and data races—a key requirement for stable production systems.
  * **Relational Data Integrity:** I designed the **One-to-Many** data model spanning four distinct entities (`Template`, `Exercise`, `Session`, `Set`). This required deep knowledge of setting up foreign keys and inverse relationships within Core Data to guarantee **referential integrity** (e.g., ensuring a `LoggedSet` always points back to a valid `WorkoutSession` and `TemplateExercise`).
  * **Data Structures & Ordering Logic:** The application uses a custom solution for **ordered list persistence**. The `order` attribute on `TemplateExercise` is manually calculated (`currentMaxOrder + 1`), demonstrating a practical application of maintaining sequential data structures in a persistent environment without relying solely on creation timestamp.
  * **Performance Optimization:** For a read-heavy app like a log, performance is critical. I configured the Core Data **Managed Object Context** by disabling the `undoManager` and enabling `automaticallyMergesChangesFromParent`, which significantly reduces memory overhead and improves UI responsiveness, especially during heavy data manipulation.

-----

## 🚀 Get Started (Developer Setup)

Check out the code, verify the simplicity, and appreciate the execution.

1.  **Prerequisites:** Xcode 15+ (or compatible version).

2.  **Clone the Repository:**

    ```bash
    git clone https://github.com/your-username/liftlog.git
    cd liftlog
    ```

3.  **Preview Setup:** The project contains both a functional **`preview`** (with sample data) and an **`emptyPreview`** configuration. This separation allows for clean state-testing (empty views) and feature-testing (populating the `HistoryView`), demonstrating proper decoupling of testing environments.

This project proves you don't need complexity to solve a core user problem. You just need thoughtful engineering and respect for the user's intelligence.
