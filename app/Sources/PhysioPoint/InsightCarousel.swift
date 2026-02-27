import SwiftUI
import Foundation

// MARK: - Insight Carousel

struct InsightCarousel: View {
    @EnvironmentObject var storage: StorageService
    
    // Evaluate cards on view creation based on current storage state
    private var cards: [InsightCard] {
        InsightLibrary.selectCards(storage: storage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recovery Insights", systemImage: "brain.head.profile")
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(cards) { card in
                        InsightCardView(card: card)
                            .frame(width: 280)
                    }
                }
                .padding(.bottom, 8)
                // In iOS 17+ we can use scrollTargetLayout() but this has to compile for older iPads too 
                // in the Swift Student Challenge, so we'll rely on simple ScrollView.
            }
        }
    }
}

// MARK: - Insight Card View

struct InsightCardView: View {
    let card: InsightCard
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: card.icon)
                    .foregroundStyle(card.category.tint)
                    .font(.title3)
                Spacer()
                Text(card.category == .progress ? "Your Data" : "Did you know?")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(card.category.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(card.category.tint.opacity(0.12), in: Capsule())
            }

            Text(card.headline)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(card.body)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
                .lineSpacing(2)

            Spacer(minLength: 0)

            if let source = card.source {
                HStack {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 9))
                    Text(source)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
            }
        }
        .padding(18)
        .frame(height: 180, alignment: .topLeading)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.headline). \(card.body)")
    }
}
