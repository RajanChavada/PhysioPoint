## Feature: PhysioGuard Chat Engine
Overview

An on-device RAG-style chatbot powered by SystemLanguageModel that floats over every main screen. The user describes their pain in natural language; the engine matches it against the app's static knowledge base and generates guardrailed, structured exercise recommendations — all offline.

1. Architecture: Three-Layer Engine
text
┌─────────────────────────────────────────────────────────┐
│                   PhysioGuardEngine                     │
│                                                         │
│  Layer 1: KnowledgeStore (your static data)             │
│    └── Conditions[], Exercises[], RecoveryPhases[]      │
│                                                         │
│  Layer 2: PromptTemplateBuilder (guardrail layer)       │
│    └── Injects context → builds Instructions struct     │
│                                                         │
│  Layer 3: LanguageModelSession (Apple on-device LLM)    │
│    └── SystemLanguageModel.default + Guardrails.default │
└─────────────────────────────────────────────────────────┘
The model never receives a raw user string. Every input is injected into a typed template by PromptTemplateBuilder before it hits LanguageModelSession.
​

2. Model Availability Gate
Per Apple docs, SystemLanguageModel requires Apple Intelligence to be enabled — must be checked before showing the chat FAB.
​

```swift
// PhysioGuardEngine.swift

import FoundationModels

@Observable
final class PhysioGuardEngine {
    enum EngineState {
        case available
        case unavailable(SystemLanguageModel.Availability)
    }

    private(set) var state: EngineState = .available
    private let model = SystemLanguageModel.default

    init() {
        switch model.availability {
        case .available:
            state = .available
        case .unavailable(let reason):
            state = .unavailable(.unavailable(reason))
        }
    }
}
```
## UI Rule: 
- The floating chat FAB only renders when state == .available. Otherwise show a subtle .unavailable message inside the sheet: "AI features require Apple Intelligence to be enabled in Settings."

## 3. KnowledgeStore — Your "RAG" Layer
This is the in-memory knowledge base the model draws from. It is not sent as one giant blob to the model — it is programmatically filtered first, keeping token usage low.
​

```swift
// KnowledgeStore.swift

struct KnowledgeCondition {
    let name: String              // "Knee Dislocation"
    let bodyArea: BodyArea
    let keywords: [String]        // ["knee", "dislocated", "popped out", "cap"]
    let summary: String           // Max ~60 words — keep token budget tight
    let exerciseNames: [String]   // Must match Exercise.name exactly
    let redFlags: [String]        // "Seek immediate care if..."
}

struct KnowledgeStore {
    static let conditions: [KnowledgeCondition] = [
        KnowledgeCondition(
            name: "Knee Dislocation",
            bodyArea: .knee,
            keywords: ["knee", "dislocated", "kneecap", "popped", "cap", "unstable"],
            summary: "Knee dislocation involves the kneecap slipping out of the femoral groove. Recovery focuses on quad strengthening, ROM restoration, and gradual weight-bearing.",
            exerciseNames: ["Quad Sets", "Short Arc Quads", "Straight Leg Raise", "Terminal Knee Extension"],
            redFlags: ["Immediate severe swelling", "Inability to bear any weight"]
        ),
        KnowledgeCondition(
            name: "ACL Tear",
            bodyArea: .knee,
            keywords: ["acl", "ligament", "tear", "popping sound", "unstable knee"],
            summary: "ACL tears affect knee stability. Non-surgical rehab focuses on quad/hamstring balance, proprioception, and gradual return to activity.",
            exerciseNames: ["Hamstring Curls", "Wall Squats", "Balance Board", "Step-Ups"],
            redFlags: ["Significant joint instability", "Inability to straighten knee"]
        ),
        // Add all conditions from LearnBodyArea enum here...
    ]

    /// Filters conditions to top-3 matches using keyword overlap scoring
    static func match(userInput: String, bodyArea: BodyArea?) -> [KnowledgeCondition] {
        let tokens = userInput.lowercased().split(separator: " ").map(String.init)
        var scored = conditions.map { condition -> (KnowledgeCondition, Int) in
            let score = condition.keywords.filter { tokens.contains($0) }.count
            return (condition, score)
        }
        if let area = bodyArea {
            scored = scored.filter { $0.0.bodyArea == area }
        }
        return scored
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0.0 }
    }
}
```
Why this works as RAG: You do the retrieval step in Swift (fast, no tokens wasted), then inject only the matched condition summaries into the model prompt.
​

4. PromptTemplateBuilder — The Guardrail Layer
Apple's docs are clear: on-device models are small, so prompts must be short, direct, and single-goal. Conditionals should be handled in Swift code, not inside the prompt string.
​

```swift
// PromptTemplateBuilder.swift

import FoundationModels

struct PhysioPromptContext {
    let userConcern: String
    let selectedBodyArea: BodyArea?
    let matchedConditions: [KnowledgeCondition]  // max 3 from KnowledgeStore
}

struct PromptTemplateBuilder {

    /// Builds the Instructions (system prompt) — persona + constraints + knowledge context
    static func buildInstructions(context: PhysioPromptContext) -> Instructions {
        let conditionBlock = context.matchedConditions
            .map { c in
                """
                Condition: \(c.name)
                Summary: \(c.summary)
                Suggested exercises: \(c.exerciseNames.joined(separator: ", "))
                """
            }
            .joined(separator: "\n\n")

        // Swift handles the conditional — not the model
        let areaContext = context.selectedBodyArea.map {
            "The user is focused on: \($0.displayName)."
        } ?? ""

        return Instructions(
            """
            You are PhysioPoint's recovery assistant. \
            You only answer questions about physical therapy and musculoskeletal recovery.
            \(areaContext)
            
            Use ONLY the following conditions from the knowledge base. \
            Do not invent conditions or exercises not listed below.
            
            \(conditionBlock.isEmpty ? "No matching conditions found." : conditionBlock)
            
            If the user's concern does not match any condition, say: \
            "I couldn't find a close match. Try selecting a body area or describe the location of your discomfort."
            
            Always end with: "This is educational guidance only, not medical advice."
            """
        )
    }

    /// The actual user turn prompt — kept to a single focused ask
    static func buildPrompt(userConcern: String) -> String {
        // Per Apple docs: imperative, single goal, no jargon
        "Based on the conditions above, identify the most likely condition, \
        explain why in one sentence, and list the 3 most appropriate exercises."
    }
}
```
Key doc-aligned decisions here:
​

Role + persona injected via Instructions struct (not the prompt itself)

Swift if/else handles the body area context, not inline conditionals in the prompt string

Prompt is imperative, single-goal, under 3 sentences

## 5. Guided Generation — Structured Output with @Generable
Instead of parsing free text, use @Generable to force the model into a typed struct. This eliminates hallucinated exercise names.
​

```swift
// PhysioChatResponse.swift

import FoundationModels

@Generable
struct PhysioChatResponse {
    // Reasoning field FIRST — per Apple docs, lets model reason before answering
    @Guide(description: "One sentence explaining why this condition matches the user's concern.")
    var reasoning: String

    @Guide(description: "The single most likely condition name from the knowledge base only.")
    var conditionName: String

    @Guide(description: "Exactly 3 exercise names from the knowledge base, comma separated.")
    var suggestedExercises: [String]

    @Guide(description: "One encouraging sentence motivating the user to start recovery.")
    var encouragement: String
}
```
The reasoning field being first is directly from Apple's on-device reasoning guidance — it gives the model a scratch pad before committing to the answer.
​

## 6. PhysioGuardEngine — Full Session Manager
```swift
// PhysioGuardEngine.swift (full implementation)

import FoundationModels
import SwiftUI

@MainActor
@Observable
final class PhysioGuardEngine {

    var messages: [ChatMessage] = []
    var isLoading = false
    var modelUnavailableReason: String? = nil

    private let model = SystemLanguageModel.default
    // Session is recreated per conversation — keeps context window clean
    private var session: LanguageModelSession?

    init() {
        guard model.isAvailable else {
            switch model.availability {
            case .unavailable(.appleIntelligenceNotEnabled):
                modelUnavailableReason = "Enable Apple Intelligence in Settings to use the AI assistant."
            case .unavailable(.deviceNotEligible):
                modelUnavailableReason = "AI assistant requires an Apple Intelligence-compatible device."
            default:
                modelUnavailableReason = "AI assistant is temporarily unavailable."
            }
            return
        }
    }

    func send(concern: String, bodyArea: BodyArea?) async {
        guard model.isAvailable else { return }

        let userMessage = ChatMessage(text: concern, role: .user)
        messages.append(userMessage)
        isLoading = true

        // Step 1: Retrieve matching conditions (RAG layer)
        let matched = KnowledgeStore.match(userInput: concern, bodyArea: bodyArea)

        // Step 2: Build guardrailed instructions + prompt
        let context = PhysioPromptContext(
            userConcern: concern,
            selectedBodyArea: bodyArea,
            matchedConditions: matched
        )
        let instructions = PromptTemplateBuilder.buildInstructions(context: context)
        let promptText   = PromptTemplateBuilder.buildPrompt(userConcern: concern)

        // Step 3: New session per turn (context window stays small per Apple guidance)
        session = LanguageModelSession(instructions: instructions)

        do {
            let response = try await session!.respond(
                to: promptText,
                generating: PhysioChatResponse.self
            )
            let result = response.content

            // Map exercise names back to real Exercise objects
            let resolvedExercises = result.suggestedExercises
                .compactMap { name in ExerciseStore.shared.exercise(named: name) }

            let botMessage = ChatMessage(
                text: result.reasoning,
                role: .assistant,
                conditionName: result.conditionName,
                suggestedExercises: resolvedExercises,
                encouragement: result.encouragement
            )
            messages.append(botMessage)

        } catch let error as LanguageModelSession.GenerationError {
            handleGenerationError(error)
        }

        isLoading = false
    }

    private func handleGenerationError(_ error: LanguageModelSession.GenerationError) {
        switch error {
        case .unsupportedLanguageOrLocale:
            messages.append(ChatMessage(
                text: "Please write your concern in English.",
                role: .system
            ))
        default:
            messages.append(ChatMessage(
                text: "Something went wrong. Please try rephrasing your concern.",
                role: .system
            ))
        }
    }
}
```
## 7. Data Model: ChatMessage
```swift
// ChatMessage.swift

import Foundation

enum ChatRole { case user, assistant, system }

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let role: ChatRole
    var conditionName: String? = nil
    var suggestedExercises: [Exercise] = []
    var encouragement: String? = nil
}
```
## 8. UI Layer
## 8a. Floating Action Button (FAB)
Sits in a ZStack overlay on HomeView and LearnHomeView. Only shown when model.isAvailable.
​

```swift
// ChatFAB.swift

struct ChatFABOverlay: View {
    @State private var showChat = false
    @Environment(PhysioGuardEngine.self) var engine

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear  // pass-through

            if engine.modelUnavailableReason == nil {
                Button { showChat.toggle() } label: {
                    Image(systemName: "brain.head.profile")
                        .font(.title2).foregroundColor(.white)
                        .frame(width: 58, height: 58)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#007AFF"), Color(hex: "#00C7BE")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .blue.opacity(0.35), radius: 12, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 90)  // sits above tab bar
            }
        }
        .sheet(isPresented: $showChat) {
            PhysioChatSheet()
                .presentationDetents([.medium, .large])
                .presentationBackground(.ultraThinMaterial)
                .presentationDragIndicator(.visible)
        }
    }
}   
```
## 8b. Chat Sheet
```swift
// PhysioChatSheet.swift

struct PhysioChatSheet: View {
    @Environment(PhysioGuardEngine.self) var engine
    @State private var input = ""
    @State private var selectedArea: BodyArea? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Body area quick filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        AreaPill(label: "Any", area: nil, selected: $selectedArea)
                        ForEach(BodyArea.allCases) { area in
                            AreaPill(label: area.displayName, area: area, selected: $selectedArea)
                        }
                    }.padding(.horizontal).padding(.vertical, 8)
                }
                Divider()

                // Message list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(engine.messages) { msg in
                                ChatBubble(message: msg)
                                    .id(msg.id)
                            }
                            if engine.isLoading {
                                TypingIndicator()
                            }
                        }.padding()
                    }
                    .onChange(of: engine.messages.count) {
                        if let last = engine.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                // Input bar
                HStack(spacing: 10) {
                    TextField("Describe your concern...", text: $input, axis: .vertical)
                        .lineLimit(1...3)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    Button {
                        let text = input.trimmingCharacters(in: .whitespaces)
                        guard !text.isEmpty else { return }
                        input = ""
                        Task { await engine.send(concern: text, bodyArea: selectedArea) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2).foregroundColor(.blue)
                    }
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || engine.isLoading)
                }
                .padding()
            }
            .navigationTitle("PhysioPoint AI")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}   
```
## 8c. ChatBubble — with Exercise CTA
```swift
struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer()
                Text(message.text)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .frame(maxWidth: 260, alignment: .trailing)
            }

        case .assistant:
            VStack(alignment: .leading, spacing: 10) {
                // Condition badge
                if let condition = message.conditionName {
                    Label(condition, systemImage: "stethoscope")
                        .font(.caption.bold())
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }

                Text(message.text).font(.subheadline)

                // Exercise cards — tappable CTAs into AR session
                if !message.suggestedExercises.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(message.suggestedExercises) { exercise in
                            NavigationLink(destination: ARSessionView(exercise: exercise)) {
                                HStack {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .foregroundColor(.blue)
                                    Text(exercise.name).font(.subheadline.bold())
                                    Spacer()
                                    Text("Start →").font(.caption).foregroundColor(.blue)
                                }
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
                }

                if let enc = message.encouragement {
                    Text(enc).font(.caption).foregroundColor(.secondary).italic()
                }

                // Disclaimer — always shown
                Text("Educational guidance only. Not a medical diagnosis.")
                    .font(.caption2).foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4)

        case .system:
            Text(message.text)
                .font(.caption).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
```
## 9. Integration into Existing Views
Add ChatFABOverlay to HomeView and LearnHomeView via ZStack, and inject PhysioGuardEngine as an environment object at the app root:

```swift
// PhysioPointApp.swift

@main
struct PhysioPointApp: App {
    @State private var engine = PhysioGuardEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(engine)
        }
    }
}

// HomeView.swift
struct HomeView: View {
    var body: some View {
        ZStack {
            HomeContentView()
            ChatFABOverlay()      // ← one line addition
        }
    }
}
```
## 10. Token Budget Strategy
Per Apple's docs, the on-device model has a small context window — keep each prompt under ~500 tokens total.
​

Component	Max Tokens
Instructions (persona + constraints)	~120
Injected condition summaries (3 × ~60 words)	~180
User prompt template	~30
User's input	~50
Total budget used	~380 / contextSize
This leaves headroom for the @Generable output fields and keeps inference fast.

## 11. File Structure
```text
PhysioPoint/
├── AI/
│   ├── PhysioGuardEngine.swift        ← Observable session manager
│   ├── KnowledgeStore.swift           ← Static RAG data + keyword matcher
│   ├── PromptTemplateBuilder.swift    ← Template injection + guardrails
│   ├── PhysioChatResponse.swift       ← @Generable output struct
│   └── ChatMessage.swift              ← Message model
├── UI/
│   ├── Chat/
│   │   ├── ChatFABOverlay.swift
│   │   ├── PhysioChatSheet.swift
│   │   ├── ChatBubble.swift
│   │   ├── TypingIndicator.swift
│   │   └── AreaPill.swift
```

## IMPORTANT
- Ensure its <25mb guideline and fully offline 

Required Architecture Changes
## 1. Strip all network calls
Audit every file for these patterns and remove them entirely:

```swift
// ❌ REMOVE — any of these will fail offline judging
URLSession.shared.dataTask(...)
URLSession.shared.data(from: URL(...))
WKWebView(...)  // loads remote content

// ✅ KEEP — all local
Bundle.main.url(forResource: ...)
KnowledgeStore.conditions  // pure Swift structs
SystemLanguageModel.default  // on-device
```
## 2. Make KnowledgeStore purely static
No JSON files fetched at runtime — your entire knowledge base must be hardcoded Swift structs compiled into the binary. This is fine for 20–30 conditions and is essentially zero file size cost:

```swift
// ✅ Compliant — lives in .swift source file, compiles into binary
struct KnowledgeStore {
    static let conditions: [KnowledgeCondition] = [
        KnowledgeCondition(
            name: "Knee Dislocation",
            bodyArea: .knee,
            keywords: ["knee", "dislocated", "kneecap", "popped"],
            summary: "...",
            exerciseNames: ["Quad Sets", "Short Arc Quads"],
            redFlags: ["Severe swelling", "Cannot bear weight"]
        ),
        // etc.
    ]
}
```
## 3. Add an availability fallback for judges without Apple Intelligence
Judges may be on devices without Apple Intelligence enabled. Your app must still be fully usable without it:
​

```swift
// PhysioGuardEngine.swift

init() {
    switch model.availability {
    case .available:
        state = .available
    case .unavailable(let reason):
        // App still works — AI feature gracefully disabled
        state = .unavailable(reason)
    }
}

// ChatFABOverlay.swift — show fallback instead of crashing
if engine.modelUnavailableReason != nil {
    // Replace FAB with a static "Browse Recovery Guides" button
    // that goes directly to LearnHomeView
    NavigationLink("Browse Recovery Guides") {
        LearnHomeView()
    }
    .buttonStyle(.borderedProminent)
}
```
## 4. Image assets — use 2x PNG only, no 3x - resize all images to to be smaller
```text
// ❌ Wasteful — adds ~40% extra size
icon-knee@3x.png   (192x192)

// ✅ Use this only
icon-knee@2x.png   (128x128)
// SF Symbols cover everything else at zero cost
```
## 5. USDZ / AR assets are your biggest size risk
Audit with:

```bash
# Run in your project root
find . -name "*.usdz" -exec du -sh {} \;
find . -name "*.png" -exec du -sh {} \;
find . -name "*.mp4" -exec du -sh {} \;
```
If any single USDZ is over 3 MB, use Reality Composer Pro to decimate the mesh. Target under 1.5 MB per model.

6. Declare AI tool usage
Per 2026 rules, if you used Copilot, Cursor, Claude, or Perplexity during development, include a brief disclosure in your submission form answer:
​

"AI coding assistants (GitHub Copilot, Claude) were used to accelerate boilerplate generation. All architectural decisions, prompt design, and feature logic were written and understood by me individually."

3-Minute Experience Rule
Judges must be able to experience your app in ≤ 3 minutes. That means:
​

Onboarding must be skippable or max 20 seconds

AR session default should start on a short exercise (≤ 60 second rep set)

Chat should have 2–3 pre-filled example prompts so judges can tap rather than type:

```swift
// PhysioChatSheet.swift — add starter prompts
let starterPrompts = [
    "My knee hurts when I go down stairs",
    "I have lower back pain from sitting",
    "My shoulder clicks when I raise my arm"
]

// Show as tap chips when messages is empty
if engine.messages.isEmpty {
    FlowLayout(starterPrompts) { prompt in
        Button(prompt) {
            Task { await engine.send(concern: prompt, bodyArea: nil) }
        }
        .buttonStyle(.bordered)
        .font(.caption)
    }
}
```
This is also a judge UX win — they immediately see your AI feature in action without needing to type anything.
## AI Rep Consistency Beta Toggle
- Restored the  within the  as an optional beta feature.
- Powered by the  toggle.
- The toggle is exposed to the user within the  (reachable via Profile Settings).


## AI Rep Consistency Beta Toggle
- Restored the `repConsistencyCard` within the `SummaryView` as an optional beta feature.
- Powered by the `@AppStorage("enableRepConsistency")` toggle.
- The toggle is exposed to the user within the `AccessibilitySettingsView` (reachable via Profile Settings).
