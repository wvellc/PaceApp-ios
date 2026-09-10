//
//  MetricsPopupView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/22/26.
//

import SwiftUI

// MARK: - MetricsPopupView

struct MetricsPopupView: View {
	@Binding var isPresented: Bool
	let metrics: [HomeMetric]
	var startingIndex: Int = 0
	
	@State private var currentIndex: Int = 0
	@State private var slideDirection: SlideDirection = .forward
	@State private var popupScale: CGFloat = 0.85
	@State private var popupOpacity: Double = 0
	@State private var dragOffset: CGFloat = 0
	
	enum SlideDirection { case forward, backward }
	
	private var currentMetric: HomeMetric { metrics[currentIndex] }
	private var isLastStep: Bool { currentIndex == metrics.count - 1 }
	private var isFirstStep: Bool { currentIndex == 0 }
	
	var body: some View {
		ZStack(alignment: .center) {
			// Dimmed background
			Color.black.opacity(0.8)
				.ignoresSafeArea()
				.onTapGesture { dismissPopup() }
				.opacity(popupOpacity)
			
			VStack(spacing: 0) {
				// Close button — outside card
				HStack {
					Spacer()
					Button(action: dismissPopup) {
						Image(.icClose)
							.frame(width: 28, height: 28)
					}
				}
				.padding(.bottom, 8)
				
				// Card
				VStack(spacing: 0) {
					// Step progress bars
					HStack(spacing: 4) {
						ForEach(0..<metrics.count, id: \.self) { i in
							Capsule()
								.fill(i <= currentIndex ? .neonAquaBlue : .neonAquaBlue.opacity(0.2))
								.frame(height: 6)
								.animation(.easeInOut(duration: 0.28), value: currentIndex)
						}
					}
					.padding(.bottom, 24)
					
					// Sliding step content
					ZStack {
						ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
							if index == currentIndex {
								StepContentView(metric: metric)
									.offset(x: dragOffset)
									.transition(
										slideDirection == .forward
										? .asymmetric(
											insertion: .move(edge: .trailing).combined(with: .opacity),
											removal:   .move(edge: .leading).combined(with: .opacity)
										)
										: .asymmetric(
											insertion: .move(edge: .leading).combined(with: .opacity),
											removal:   .move(edge: .trailing).combined(with: .opacity)
										)
									)
							}
						}
					}
					.clipped()
					.gesture(
						DragGesture()
							.onChanged { value in
								// Rubber-band resistance at boundaries
								let isAtStart = isFirstStep && value.translation.width > 0
								let isAtEnd   = isLastStep  && value.translation.width < 0
								dragOffset = (isAtStart || isAtEnd)
								? value.translation.width * 0.2
								: value.translation.width * 0.6
							}
							.onEnded { value in
								let threshold: CGFloat = 60
								if value.translation.width < -threshold, !isLastStep {
									slideDirection = .forward
									withAnimation(.easeInOut(duration: 0.32)) {
										dragOffset = 0
										currentIndex += 1
									}
								} else if value.translation.width > threshold, !isFirstStep {
									slideDirection = .backward
									withAnimation(.easeInOut(duration: 0.32)) {
										dragOffset = 0
										currentIndex -= 1
									}
								} else {
									// Snap back
									withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
										dragOffset = 0
									}
								}
							}
					)
					
					// Action buttons
					HStack(spacing: Constant.UI.spacing16) {
						if !isFirstStep {
							AppButton(.previous, style: .secondary, action: handlePrevious)
								.transition(.opacity.combined(with: .scale))
						}
						AppButton(isLastStep ? .done : .next, action: handleNext)
					}
					.animation(.easeInOut(duration: 0.22), value: isFirstStep)
					.padding(.top, Constant.UI.spacing16)
				}
				.padding(Constant.UI.spacing16)
				.cardBackground()
			}
			.padding(Constant.UI.spacing16)
			.scaleEffect(popupScale)
			.opacity(popupOpacity)
		}
		.onAppear {
			currentIndex = max(0, min(startingIndex, metrics.count - 1))
			withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
				popupScale   = 1.0
				popupOpacity = 1.0
			}
		}
	}
	
	// MARK: - Actions
	
	private func handleNext() {
		if isLastStep {
			dismissPopup()
		} else {
			slideDirection = .forward
			withAnimation(.easeInOut(duration: 0.32)) {
				dragOffset = 0
				currentIndex += 1
			}
		}
	}
	
	private func handlePrevious() {
		guard !isFirstStep else { return }
		slideDirection = .backward
		withAnimation(.easeInOut(duration: 0.32)) {
			dragOffset = 0
			currentIndex -= 1
		}
	}
	
	private func dismissPopup() {
		// Remove the popup once the fade-out actually finishes — no guessed delay.
		withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
			popupScale   = 0.85
			popupOpacity = 0
		} completion: {
			isPresented = false
		}
	}
}

// MARK: - Step Content View

private struct StepContentView: View {
	let metric: HomeMetric
	
	var body: some View {
		VStack {
			Image(metric.symbol)
				.resizable()
				.scaledToFit()
				.foregroundStyle(.fluorescentMint)
				.frame(width: 128, height: 128)
				.padding(.bottom, 24)
			
			Text(metric.title)
				.font(.medium24)
				.foregroundColor(.darkCharcoal)
				.multilineTextAlignment(.center)
				.padding(.bottom, 8)

			
			Text(metric.description)
				.font(.medium16)
				.foregroundColor(.fashionGray)
				.multilineTextAlignment(.center)
				.lineSpacing(4)
				.fixedSize(horizontal: false, vertical: true)
				.padding(.bottom, 24)

		}
		.frame(maxWidth: .infinity)
	}
}

#Preview {
	
	let vm = HomeViewModel()
	
	MetricsPopupView(
		isPresented: .constant(true),
		metrics: vm.metrics,
		startingIndex: 0
	)
	.appBackground()
}
