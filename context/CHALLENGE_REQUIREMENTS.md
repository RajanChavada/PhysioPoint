# Swift Student Challenge 2026 – Requirements

Source: Official Apple pages and related summaries.[web:3][web:14][web:9][web:159][web:178][web:179][web:180]

_Last updated: 2026‑02‑20_

This file defines the **hard constraints** and **judging signals** for the 2026 Swift Student Challenge. All code, assets, and design decisions for PhysioPoint **must obey this file**.

---

## 1. Format & Technical Requirements

- **Deliverable type**
  - Submission must be an **app playground** (`.swiftpm`) compressed into a **ZIP file**.[web:3][web:179]
  - **No `.xcodeproj`** – only `.swiftpm` projects are accepted.[web:5]

- **Size limit**
  - The ZIP file must be **≤ 25 MB** total.[web:3][web:178][web:179]
  - All code, assets, and resources must fit within this limit.

- **Runtime environment**
  - App playground must be built with and run on **Swift Playgrounds 4.6** (Mac or iPad) **or Xcode 26 or later**.[web:3][web:14][web:179]
  - For this project we are using **Swift Playgrounds on Mac** only.
  - If built for iPad, UI must be properly laid out for iPad; however, PhysioPoint is being developed and judged primarily on Mac Playgrounds.

- **Offline execution**
  - Submissions are **judged offline**.[web:3][web:178][web:179]
  - The app **must not require a network connection** for any core functionality.
  - **No network calls** (no APIs, no remote data, no external model downloads).
  - All resources (data files, images, models, etc.) must be **bundled locally** inside the `.swiftpm` and ZIP.[web:3][web:178]

- **Language**
  - All UI strings, content, and essays must be in **English**.[web:3]

- **AI usage**
  - AI tools may assist with specific tasks (code gen, copy, design), but:
    - Usage must be **fully disclosed** in the submission form.
    - The app must still demonstrate the student’s **own understanding and significant individual contribution**.[web:3]
  - This repo’s `context/` folder and commit history help prove authorship.

---

## 2. Eligibility Snapshot (for reference)

Not enforced by code, but important context.[web:3][web:9][web:179][web:180]

- Must meet minimum age requirements (13–16+ depending on country).
- Must be:
  - Currently enrolled (school, university, homeschool, Apple Developer Academy, or STEM program), or
  - Recently graduated (within 90 days for university; 6 months for high school).[web:3][web:9]
- Cannot be a **full‑time professional software developer**.[web:9][web:179]
- Must have a **free Apple Developer account** or be in the Developer Program.[web:3][web:163]
- Only **one submission per person**; cannot reuse last year’s project with minimal changes.[web:3][web:181]

Agents do **not** need to enforce this; it’s for submission awareness.

---

## 3. Submission Content Requirements

- **Single app playground**
  - Only **one** `.swiftpm` project can be submitted per participant.[web:3]
  - It must be **individually created** – no group work, no shared codebases.[web:3][web:5]
  - It can be:
    - Built from a Swift Playgrounds template and then **fully modified by the student**, or
    - Created from scratch.

- **3‑minute experience**
  - Judges should be able to **understand and experience** the core of the app in **3 minutes or less**.[web:14][web:159][web:179][web:180]
  - That means:
    - Minimal onboarding.
    - A single, clear “happy path” through the main feature.
    - No deep configuration required to see the main idea.

- **No sign‑in or analytics**
  - App **must not require sign‑in** of any kind (no Apple ID, email, OAuth, etc.).[web:3]
  - **No analytics or tracking code** aimed at identifying or tracking judge behavior.[web:3][web:181]
  - No external telemetry.

- **Assets and IP**
  - All code and assets must either be:
    - Created by the student, or
    - Properly licensed and not infringing.
  - No plagiarized code, music, images, or third‑party IP that violates licenses.[web:3]
  - Open‑source code must comply with its license and be used minimally.

- **Supplemental documents**
  - Must provide **proof of enrollment** (PDF/PNG/JPEG schedule or equivalent) showing:
    - Student’s name.
    - School/organization name.
    - Valid dates.[web:3][web:178]
  - Must answer all **essay questions in the submission form** with text written by the student.[web:3]

---

## 4. Judging Criteria

Apple judges submissions on three main axes:[web:3][web:9][web:5]

1. **Technical accomplishment**
   - Clean, working implementation.
   - Appropriate use of Swift, SwiftUI, and any Apple frameworks.
   - Robustness (no obvious crashes or broken flows).
   - For PhysioPoint: good use of **state management**, **math/geometry**, and optionally **ARKit** if supported.

2. **Creativity / innovation**
   - Originality of the idea.
   - Interesting interaction design.
   - Fresh approach to solving a real problem (e.g., accessible rehab).

3. **Content of written responses**
   - Clarity and authenticity of the story (e.g., family rehab struggles).
   - Explanation of the problem, constraints, and decisions.
   - Reflection on what was learned.

Some external summaries also highlight:
- **Social impact**
- **Inclusivity**
as implicit judging factors, especially for Distinguished Winners.[web:9][web:180]

---

## 5. Disqualification Triggers (must avoid)

Per Apple’s 2026 Terms and related guidance:[web:3][web:181]

The submission can be disqualified if:

- The app **does not function** during judging (e.g., crashes on launch or critical paths don’t work).
- The app **was not built by the student alone** (or shows clear signs of plagiarism).
- The app:
  - Requires sign‑in.
  - Uses analytics code to track judges.
  - Requires a network connection to reach core functionality.
  - Exceeds the **25 MB ZIP size**.
- The app is **substantially the same** as a previous year’s submission with minimal changes.
- There is misappropriation of:
  - Copyrighted content (music, photos, artworks, etc.).
  - Open‑source code beyond what licenses allow.

Agents should treat these as **hard “DO NOT DO” rules.**

---

## 6. Design & UX Hints from Apple

From Apple’s “Get ready” guidance and past winners:[web:14][web:5][web:20]

- Apps should:
  - Focus on a **clear user problem**.
  - Have a **simple, discoverable flow**.
  - Look and feel like a real app (not just a random code playground).
- Adding polish:
  - Use **SwiftUI** for modern UI.
  - Support **basic accessibility** (large text, contrast, VoiceOver where feasible).
  - Include small, meaningful **animations** or visual feedback.

For PhysioPoint, that means:

- A single, well‑defined rehab flow (e.g., one knee exercise path) that is easy to run in 3 minutes.
- Clear copy about what the app does **and what it does NOT do** (medical disclaimer).
- Reliance on visuals instead of depth of content (few screens, high clarity).

---

## 7. How Agents Should Use This File

Whenever generating or modifying code or documentation for PhysioPoint:

1. **Check against this file** before proposing features:
   - No networking.
   - Mind the 25 MB limit.
   - Ensure the feature fits in a 3‑minute path.

2. **Preserve submission‑safe behavior**:
   - Do not introduce sign‑in, analytics, remote APIs, or huge assets.
   - Keep all content English‑only.

3. **Align with judging criteria**:
   - Show off at least one technically interesting thing (e.g., angle math, AR overlay).
   - Keep the core interaction creative and impactful.
   - Keep the story tied to the real‑world problem (affordable at‑home rehab for family members).

This file + `CONTEXT.md` together form the **constraint box** for all agentic development on this repo.
