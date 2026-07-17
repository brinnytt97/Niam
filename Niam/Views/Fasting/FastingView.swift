import SwiftUI
import SwiftData

struct FastingView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: FastingViewModel?
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    FastingContent(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Intermittent Fasting")
            .onAppear {
                if viewModel == nil {
                    viewModel = FastingViewModel(context: context)
                }
                startTimer()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            // Force SwiftUI to re-evaluate the view
            viewModel?.fetchData()
        }
    }
}

private struct FastingContent: View {
    @Bindable var viewModel: FastingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Timer Circle
                ZStack {
                    Circle()
                        .stroke(.gray.opacity(0.2), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(
                            viewModel.progress >= 1 ? Color.green : Color.orange,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: viewModel.progress)

                    VStack(spacing: 8) {
                        Text(viewModel.isActive ? "Fasting" : "Not Fasting")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(viewModel.elapsedFormatted)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))

                        if viewModel.isActive {
                            Text("Remaining: \(viewModel.remainingFormatted)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: 260, height: 260)
                .padding(.top, 20)

                // Plan Picker
                if !viewModel.isActive {
                    Picker("Plan", selection: $viewModel.selectedPlan) {
                        ForEach(FastingPlan.allCases, id: \.self) { plan in
                            Text(plan.rawValue).tag(plan)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                // Start / Stop Button
                Button {
                    if viewModel.isActive {
                        viewModel.stopFasting()
                    } else {
                        viewModel.startFasting()
                    }
                } label: {
                    Text(viewModel.isActive ? "End Fast" : "Start Fasting")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isActive ? Color.red : Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // History
                if !viewModel.history.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("History")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.history.prefix(10)) { session in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(session.plan.rawValue)
                                        .font(.subheadline.bold())
                                    Text(session.startTime, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                let hours = Int(session.elapsedSeconds) / 3600
                                let minutes = (Int(session.elapsedSeconds) % 3600) / 60
                                Text("\(hours)h \(minutes)m")
                                    .font(.subheadline)
                                    .foregroundStyle(session.progress >= 1 ? .green : .orange)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                }

                Spacer()
            }
        }
    }
}
