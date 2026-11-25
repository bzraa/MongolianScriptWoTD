//
//  ContentView.swift
//  MongolianScriptWoTD
//
//  Created by Bazarsad Uurdmandakh on 2026.11.24.
//

import Combine
import SwiftUI

// Rotated text whose layout frame matches its rotated size, so HStack spacing works
struct VerticalWord: View {
    let text: String
    let fontSize: CGFloat
    var maxLength: CGFloat = .infinity   // longest the word may be on screen
    
    @State private var textSize: CGSize = .zero
    
    private var scale: CGFloat {
        guard textSize.width > maxLength, textSize.width > 0 else { return 1 }
        return maxLength / textSize.width
    }
    
    var body: some View {
        Text(text )
            .font(.custom(mongolianFontName, size: fontSize))
            .lineLimit(1)
            .fixedSize()
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { textSize = proxy.size }
                        .onChange(of: proxy.size) { _, new in textSize = new }
                }
            )
            .rotationEffect(.degrees(90))
            .scaleEffect(scale)
            .frame(width: textSize.height * scale, height: textSize.width * scale)
    }
}

enum AnimationPhase {
    case flowing
    case entering
    case featured
    case exiting
}

// easing curves for the featured animation
extension Animation {
    /// fast start, long soft landing (ease-out cubic)
    static func featuredArrive(_ duration: Double) -> Animation {
        .timingCurve(0.33, 1, 0.68, 1, duration: duration)
    }
    /// slow start, accelerates away (ease-in cubic)
    static func featuredDepart(_ duration: Double) -> Animation {
        .timingCurve(0.32, 0, 0.67, 0, duration: duration)
    }
}

struct ContentView: View {
    var theme: BackgroundTheme = .blue
    
    @State private var movingWords: [MovingWord] = []
    @State private var phase: AnimationPhase = .flowing
    
    @State private var overlayOpacity: Double = 0
    @State private var panelOpacity: Double = 0
    @State private var dimOpacity: Double = 0
    @State private var panelOffset: CGFloat = 16
    
    @State private var showFeaturedBg = false
    @State private var featuredBgPhase = 0
    @State private var featuredBgOpacity: Double = 1
    
    @State private var featuredEntry = wordEntries[0]
    
    @State private var screenWidth: CGFloat = 0
    @State private var featuredBgLength: CGFloat = 0
    
    private let laneCount = 8
    private let reservedLanes: Set<Int> = [3, 4]
    
    private let spawnTimer = Timer.publish(every: 1.6, on: .main, in: .common)
        .autoconnect()
    
    private let sampleWords = wordEntries.map { $0.mongolian }
    
    private func wordSize(_ geometry: GeometryProxy) -> CGFloat {
        fittedSize(
            featuredEntry.mongolian,
            maxSize: 130,
            maxLength: geometry.size.height * 0.7
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            let half = geometry.size.width / 2
            
            ZStack {
                // 1. Background gradient
                LinearGradient(
                    colors: theme.colors,
                    startPoint: .bottom,
                    endPoint: .top
                )
                .ignoresSafeArea()
                
                
                // 2. Flowing words
                ForEach(movingWords) { word in
                    FallingWord(
                        word: word,
                        color: theme.wordColor,
                        screenHeight: geometry.size.height
                    ) {
                        movingWords.removeAll { $0.id == word.id }
                    }
                }
                
                // 3. Featured word in the background
                if showFeaturedBg {
                    HStack(alignment: .center, spacing: 0) {
                        VerticalWord(
                            text: featuredEntry.mongolian,
                            fontSize: wordSize(geometry)
                        )
                        .opacity(0)
                        .overlay {
                            let scale = featuredBgLength > 0
                            ? min(1, geometry.size.height * 0.8 / featuredBgLength)
                            : 1
                            let travel = geometry.size.height / 2 + featuredBgLength * scale / 2 + 20
                            let targetY: CGFloat = featuredBgPhase == 0 ? -travel
                            : featuredBgPhase == 1 ? 0
                            : travel
                            
                            Text(featuredEntry.mongolian)
                                .font(.custom(mongolianFontName, size: 280))
                                .foregroundStyle(theme.wordColor)
                                .lineLimit(1)
                                .fixedSize()
                                .background(
                                    GeometryReader { proxy in
                                        Color.clear
                                            .onAppear { featuredBgLength = proxy.size.width }
                                            .onChange(of: proxy.size.width) { _, new in featuredBgLength = new }
                                    }
                                )
                                .rotationEffect(.degrees(90))
                                .scaleEffect(scale)
                                .opacity(featuredBgLength > 0 ? featuredBgOpacity : 0)
                                .offset(y: targetY)
                        }
                        .padding(.trailing, 12)
                        .frame(width: half, alignment: .trailing)
                        
                        Color.clear
                            .frame(width: half)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // 4. Dark layer
                Color.black
                    .opacity(dimOpacity * 0.6)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                // 5. Featured overlay
                if phase != .flowing {
                    HStack(alignment: .center, spacing: 0) {
                        VerticalWord(
                            text: featuredEntry.mongolian,
                            fontSize: wordSize(geometry),
                            maxLength: geometry.size.height * 0.8
                        )
                        .foregroundStyle(.white)
                        .padding(.trailing, 12)
                        .frame(width: half, alignment: .trailing)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(featuredEntry.meaning)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.white)
                            
                            Text(featuredEntry.pronunciation)
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        .padding(.leading, 12)
                        .padding(.trailing, 24)
                        .frame(width: half, alignment: .leading)
                        .opacity(panelOpacity)
                        .offset(y: panelOffset)
                    }
                    .opacity(overlayOpacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(2)
                }
                
            }
            .onReceive(spawnTimer) { _ in spawnRandomWord() }
            .onAppear {
                screenWidth = geometry.size.width
                startCycle(screenHeight: geometry.size.height)
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) {
            Text("words: \(wordEntries.count)\n\(wordStatus)")
                .font(.system(size: 14, weight: .bold))
                .padding(8)
                .background(.black.opacity(0.7))
                .foregroundStyle(.white)
                .padding(.top, 40)
                .padding(.leading, 12)
        }
    }
    
    // MARK: - Helpers
    
    private func fittedSize(
        _ text: String,
        maxSize: CGFloat,
        maxLength: CGFloat
    ) -> CGFloat {
        let estimatedLength = CGFloat(max(text.count, 1)) * 0.75
        return min(maxSize, maxLength / estimatedLength)
    }
    
    // MARK: - Random spawning
    
    private func spawnRandomWord() {
        guard screenWidth > 0 else { return }
        
        let usedLanes = Set(movingWords.map { $0.lane })
        let freeLanes = (0..<laneCount).filter {
            !reservedLanes.contains($0) && !usedLanes.contains($0)
        }
        guard let lane = freeLanes.randomElement() else { return }
        
        let laneWidth = screenWidth / CGFloat(laneCount)
        let maxSize = min(220, laneWidth * 1.0)
        let minSize = maxSize * 0.55
        let size = CGFloat.random(in: minSize...maxSize)
        let t = Double((size - minSize) / (maxSize - minSize))
        
        movingWords.append(
            MovingWord(
                text: sampleWords.randomElement()!,
                lane: lane,
                xPosition: (CGFloat(lane) + 0.5) / CGFloat(laneCount),
                fontSize: size,
                duration: 6 + t * 5 + Double.random(in: 0...1.5),
                opacity: 0.75 - t * 0.5
            )
        )
    }
    
    // MARK: - Featured cycle
    
    private func startCycle(screenHeight: CGFloat) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            runFeaturedCycle(screenHeight: screenHeight)
        }
    }
    
    private func runFeaturedCycle(screenHeight: CGFloat) {
        let start: Double = 0.15
        let toCenter: Double = 4.5
        let overlayLead: Double = 0.8
        let panelDelay: Double = 1.2
        let hold: Double = 3.5
        let toBottom: Double = 4.0
        
        featuredEntry = wordEntries.randomElement()!
        
        featuredBgPhase = 0
        featuredBgLength = 0
        featuredBgOpacity = 0.95
        panelOffset = 16
        showFeaturedBg = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + start) {
            withAnimation(.featuredArrive(toCenter)) {
                featuredBgPhase = 1
            }
        }
        
        let overlayStart = start + toCenter - overlayLead
        DispatchQueue.main.asyncAfter(deadline: .now() + overlayStart) {
            phase = .entering
            withAnimation(.easeInOut(duration: 1.2)) {
                dimOpacity = 1
                featuredBgOpacity = 0.3
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                overlayOpacity = 1
            }
        }
        
        let panelStart = overlayStart + panelDelay
        DispatchQueue.main.asyncAfter(deadline: .now() + panelStart) {
            phase = .featured
            withAnimation(.easeOut(duration: 0.7)) {
                panelOpacity = 1
                panelOffset = 0
            }
        }
        
        let exitStart = panelStart + hold
        DispatchQueue.main.asyncAfter(deadline: .now() + exitStart) {
            phase = .exiting
            withAnimation(.easeIn(duration: 0.4)) {
                panelOpacity = 0
                panelOffset = -8
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.15)) {
                overlayOpacity = 0
            }
            withAnimation(.easeInOut(duration: 0.9).delay(0.3)) {
                dimOpacity = 0
                featuredBgOpacity = 0.95
            }
        }
        
        let departStart = exitStart + 0.9
        DispatchQueue.main.asyncAfter(deadline: .now() + departStart) {
            withAnimation(.featuredDepart(toBottom)) {
                featuredBgPhase = 2
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + exitStart + 1.3) {
            phase = .flowing
        }
        
        let total = departStart + toBottom
        DispatchQueue.main.asyncAfter(deadline: .now() + total) {
            showFeaturedBg = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + total + 5) {
            runFeaturedCycle(screenHeight: screenHeight)
        }
    }
}

struct MovingWord: Identifiable {
    let id = UUID()
    let text: String
    let lane: Int
    let xPosition: CGFloat
    let fontSize: CGFloat
    let duration: Double
    let opacity: Double
}

struct FallingWord: View {
    let word: MovingWord
    let color: Color
    let screenHeight: CGFloat
    let onRemove: () -> Void
    
    @State private var offsetY: CGFloat = -5000
    @State private var hasStarted = false
    
    var body: some View {
        GeometryReader { geometry in
            Text(word.text)
                .font(.custom(mongolianFontName, size: word.fontSize))
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize()
                .background(
                    GeometryReader { proxy in
                        Color.clear.onAppear { start(length: proxy.size.width) }
                    }
                )
                .rotationEffect(.degrees(90))
                .opacity(word.opacity)
                .position(
                    x: geometry.size.width * word.xPosition,
                    y: offsetY
                )
        }
    }
    
    private func start(length: CGFloat) {
        guard !hasStarted else { return }
        hasStarted = true
        
        let startY = -length / 2
        let endY = screenHeight + length / 2
        
        let distance = endY - startY
        let duration = word.duration * Double(distance / (screenHeight + 600))
        
        offsetY = startY
        
        DispatchQueue.main.async {
            withAnimation(.linear(duration: duration)) {
                offsetY = endY
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            onRemove()
        }
    }
}

#Preview("Pink") {
    let _ = FontLoader.registerFonts()
    ContentView(theme: .pink)
}

