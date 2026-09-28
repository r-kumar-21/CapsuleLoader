import CapsuleLoader
import SwiftUI

struct ContentView: View {
    @State private var isLoading = false
    @State private var progress: Double?

    var body: some View {
        NavigationStack {
            List {
                Section("Global loader") {
                    Button("Bar for 2 seconds") {
                        Task { await fakeRequest(style: .bar) }
                    }
                    Button("Spinner for 2 seconds") {
                        Task { await fakeRequest(style: .spinner) }
                    }
                    Button("Download with progress") {
                        Task { await fakeDownload() }
                    }
                    Button("Two overlapping requests") {
                        Task { await overlappingRequests() }
                    }
                }

                Section("SwiftUI modifier") {
                    Button("Show with .capsuleLoader") {
                        Task {
                            isLoading = true
                            try? await Task.sleep(for: .seconds(2))
                            isLoading = false
                        }
                    }
                }

                Section("Inline indicators") {
                    LabeledContent("Sliding bar") {
                        CapsuleProgressBar()
                            .frame(width: 140)
                    }
                    LabeledContent("Bar at 40%") {
                        CapsuleProgressBar(progress: 0.4)
                            .frame(width: 140)
                    }
                    LabeledContent("Spinner") {
                        CapsuleSpinner(size: 24)
                    }
                    LabeledContent("Tinted spinner") {
                        CapsuleSpinner(size: 24, indicatorColor: .indigo)
                    }
                }
            }
            .navigationTitle("CapsuleLoader")
        }
        .capsuleLoader(isPresented: isLoading, message: "Loading")
    }

    private func fakeRequest(style: CapsuleLoader.Style) async {
        try? await CapsuleLoader.run("Loading", style: style) {
            try await Task.sleep(for: .seconds(2))
        }
    }

    private func fakeDownload() async {
        CapsuleLoader.show("Downloading", style: .bar)
        defer { CapsuleLoader.hide() }
        try? await Task.sleep(for: .milliseconds(600))
        for step in 1...10 {
            CapsuleLoader.setProgress(Double(step) / 10)
            try? await Task.sleep(for: .milliseconds(250))
        }
    }

    private func overlappingRequests() async {
        async let first: Void = fakeRequest(style: .spinner)
        async let second: Void = {
            try? await Task.sleep(for: .seconds(1))
            await fakeRequest(style: .spinner)
        }()
        _ = await (first, second)
    }
}

#Preview {
    ContentView()
}
