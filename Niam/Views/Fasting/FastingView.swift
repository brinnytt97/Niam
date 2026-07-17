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
                    viewModel?.requestNotificationPermission()
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
            viewModel?.fetchData()
        }
    }
}

private struct FastingContent: View {
    @Bindable var viewModel: FastingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Timer Circle
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
                            Text("Target: \(viewModel.targetHours)h")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Remaining: \(viewModel.remainingFormatted)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: 260, height: 260)
                .padding(.top, 20)

                // MARK: - Custom Duration Picker
                if !viewModel.isActive {
                    VStack(spacing: 8) {
                        Text("Fasting Duration")
                            .font(.headline)

                        HStack(spacing: 0) {
                            Stepper(
                                "\(viewModel.targetHours) hours",
                                value: $viewModel.targetHours,
                                in: 1...48
                            )
                        }
                        .padding(.horizontal)

                        // Quick presets
                        HStack(spacing: 10) {
                            ForEach([13, 14, 16, 18, 20], id: \.self) { hours in
                                Button("\(hours)h") {
                                    viewModel.targetHours = hours
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.targetHours == hours
                                        ? Color.accentColor
                                        : Color(.systemGray5)
                                )
                                .foregroundStyle(
                                    viewModel.targetHours == hours ? .white : .primary
                                )
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // MARK: - Start / Stop Button
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

                // MARK: - History
                if !viewModel.history.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("History")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.history.prefix(10)) { session in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(session.targetHours)h target")
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
