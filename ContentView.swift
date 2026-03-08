//
//  ContentView.swift
//  Project 4
//
//  Created by Abel Plascencia on 3/7/26.
//

import SwiftUI

struct Card: Identifiable, Equatable {
    let id: UUID = UUID()
    let content: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

struct ContentView: View {
    // Configuration (stretch)
    private let pairOptions = [2, 4, 8, 12]
    @State private var numberOfPairs: Int = 4
    @State private var cards: [Card] = []

    // Tracks picks
    @State private var firstSelectedIndex: Int? = nil
    @State private var secondSelectedIndex: Int? = nil

    @State private var isBusy: Bool = false

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.orange, .red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                header

                ScrollView { //Scroll if out of view: (stretch)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(cards.indices, id: \.self) { index in
                            CardView(card: cards[index])
                                .opacity(cards[index].isMatched ? 0 : 1)
                                .animation(.easeInOut(duration: 0.2), value: cards[index].isMatched)
                                .onTapGesture {
                                    handleTap(at: index)
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .padding(.top)
        }
        .onAppear {
            newGame()
        }
        .onChange(of: numberOfPairs) {
            newGame()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Match Game")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                Picker("Pairs", selection: $numberOfPairs) {
                    ForEach(pairOptions, id: \.self) { count in
                        Text("\(count) pairs").tag(count)
                    }
                }
                .pickerStyle(.menu)
                .tint(.white)

                Spacer()

                Button {
                    newGame()
                } label: {
                    Label("Reset", systemImage: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .foregroundStyle(.white)
                .disabled(isBusy)
                .opacity(isBusy ? 0.6 : 1)
            }
            .padding(.horizontal)
        }
    }

    private func newGame() {
        isBusy = false
        firstSelectedIndex = nil
        secondSelectedIndex = nil
        cards = makeCards(pairs: numberOfPairs).shuffled()
    }

    private func makeCards(pairs: Int) -> [Card] {
        let symbols = ["🐶","🐱","🐸","🐼","🦊","🐵","🐷","🦁","🐰","🐯","🦄","🐙","🦋","🐝","🐢","🦖"]
        let chosen = Array(symbols.prefix(pairs))

        var newCards: [Card] = []
        for symbol in chosen {
            newCards.append(Card(content: symbol))
            newCards.append(Card(content: symbol))
        }
        return newCards
    }

    private func handleTap(at index: Int) {
        guard !isBusy else { return }
        guard cards.indices.contains(index) else { return }
        guard !cards[index].isMatched else { return }
        guard !cards[index].isFaceUp else { return }

        // Flip up
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            cards[index].isFaceUp = true
        }

        if firstSelectedIndex == nil {
            firstSelectedIndex = index
            return
        }

        secondSelectedIndex = index
        checkMatch()
    }

    private func checkMatch() {
        guard let first = firstSelectedIndex,
              let second = secondSelectedIndex,
              first != second else { return }

        isBusy = true

        let isMatch = cards[first].content == cards[second].content

        if isMatch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    cards[first].isMatched = true
                    cards[second].isMatched = true
                }
                clearSelection()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    cards[first].isFaceUp = false
                    cards[second].isFaceUp = false
                }
                clearSelection()
            }
        }
    }

    private func clearSelection() {
        firstSelectedIndex = nil
        secondSelectedIndex = nil
        isBusy = false
    }
}

struct CardView: View {
    let card: Card

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(card.isFaceUp ? .white.opacity(0.95) : .white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)

            if card.isFaceUp {
                Text(card.content)
                    .font(.system(size: 36))
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "questionmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .aspectRatio(2/3, contentMode: .fit)
        .frame(height: 150)
        .rotation3DEffect(
            .degrees(card.isFaceUp ? 0 : 180),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.easeInOut(duration: 0.25), value: card.isFaceUp)
        .accessibilityLabel(card.isFaceUp ? Text("Card \(card.content)") : Text("Face down card"))
    }
}

#Preview {
    ContentView()
}
