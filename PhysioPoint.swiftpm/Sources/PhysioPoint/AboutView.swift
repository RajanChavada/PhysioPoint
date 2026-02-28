import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            PPGradient.pageBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 36) {
                    
                    // Header Logo
                    VStack(spacing: 16) {
                        BundledImage("PPGrad", maxHeight: 100)
                            .frame(width: 100, height: 100)
                            .shadow(color: PPColor.actionBlue.opacity(0.3), radius: 16, y: 8)
                        
                        VStack(spacing: 4) {
                            Text("PhysioPoint")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            Text("Swift Student Challenge 2026")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Essay 1: The Problem
                    essayBlock(
                        title: "The Problem & Inspiration",
                        text: "In Canada, physiotherapy can cost upwards of $200 per session—an unaffordable barrier for my parents and relatives suffering from chronic pain. Watching family members struggle, I realized the problem wasn’t just cost, but a lack of consistent, high-quality guidance at home.\n\nWhether it was a senior recovering from surgery or a young athlete paying $100 out-of-pocket for a knee dislocation, they were performing exercises incorrectly or inconsistently, relying on confusing, static YouTube videos.\n\nPhysioPoint bridges this gap by democratizing clinical-grade rehab. I designed it for a broad spectrum: from seniors managing age-related mobility to young people recovering from acute injuries."
                    )
                    
                    // Essay 2: Beneficiaries
                    essayBlock(
                        title: "Who Benefits?",
                        text: "The Working Caregiver: Individuals like my brother-in-law’s mother benefit most from the \"functional rehab\" focus. After standing for seven-hour shifts, she returns home to the physical labor of cooking and cleaning. For her, PhysioPoint isn't just an app; it’s a tool for daily survival. The scheduled, at-home sessions allow her to alleviate chronic leg pain on her own terms, without sacrificing precious rest time or income for clinical visits.\n\nThe Under-Insured Athlete: Young athletes often fall through the \"benefit gap\" where insurance doesn't cover the high frequency of sessions required for acute injury recovery. PhysioPoint provides them with the high-fidelity data—like joint-angle tracking—they need to ensure their form is clinical-grade during solo training.\n\nThe Skeptical Senior: For elderly users who view healthcare costs with suspicion, this free, intuitive alternative removes the financial friction. By guiding correct form through AR, it transforms recovery from an expensive \"purchase\" into an accessible daily habit."
                    )
                    
                    // Essay 3: Accessibility
                    essayBlock(
                        title: "Inclusive Design Process",
                        text: "Accessibility formed the absolute foundation of PhysioPoint and shaped every design choice. My target users included elderly individuals, people recovering from serious injuries, and those experiencing cognitive fatigue during rehabilitation. This demanded a fundamentally different approach than simply building a technically complex system.\n\nAssistive Access: The most significant investment was a dedicated Assistive Access Mode. This completely parallels the UI/UX using custom SwiftUI environment keys to transform the entire interface into a simplified navigation model. It curates primary menus and scales touch targets to a minimum of 44x44pt per Apple's Human Interface Guidelines, offering a separate, calming interaction design specifically for users who find standard apps overwhelming.\n\nHands-Free AR & VoiceOver: I integrated accessibility directly into the active AR sessions. On-screen form cues and feedback messages fully support Apple VoiceOver, meaning visually impaired users—or those who cannot physically look at the screen while exercising—receive spoken, real-time auditory guidance.\n\nMulti-Sensory Feedback: The app never relies on one sense alone. Haptic feedback physically taps the user when they hit the correct joint angle, and color changes (like warnings) are always paired with distinct SF Symbols to ensure state changes are fully perceivable for color-blind users."
                    )
                    
                    // Essay 4: Community Impact
                    essayBlock(
                        title: "Open-Source Impact",
                        text: "My commitment to technology lies in its power to empower others. Beyond my local community, I developed and open-sourced \"Plyce,\" a React-based application designed to bridge the gap between traditional \"mom-and-pop\" restaurants and modern discovery methods based on TikTok reviews.\n\nThe impact went beyond the 1,300+ users. By making the project completely open-source, I turned my development process into a learning resource for others. For me, sharing knowledge isn't just about posting a link; it’s about providing the scaffolding for others to build their own community-focused solutions."
                    )
                    
                    // Disclaimer
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Educational Demo Only")
                                .font(.headline)
                        }
                        Text("This application is a software development demonstration. It is strictly not a medical device. The information and simulated AR feedback provided are for educational purposes and should never replace professional medical advice, diagnosis, or treatment.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(24)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Footer
                    VStack(spacing: 4) {
                        BundledImage("PP", maxHeight: 32)
                            .frame(width: 32, height: 32)
                            .opacity(0.4)
                            .padding(.bottom, 4)
                        
                        Text("Designed & Built in Toronto")
                            .font(.caption.bold())
                        Text("by Rajan Chavada")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.vertical, 30)
                    .padding(.bottom, 45)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Extracted standard block view for consistent styling across the essay chunks
    private func essayBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(PPColor.actionBlue)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(5)
                .multilineTextAlignment(.leading)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .physioGlass(.card)
    }
}
