import SwiftUI
import TidyCore

struct HomeView: View {
    @State private var signature = SigningInfo.current()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You could free")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("—")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    ForEach(CleanupArea.allCases) { area in
                        Label {
                            VStack(alignment: .leading) {
                                Text(area.title)
                                Text("Coming in stage \(area.stage)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: area.systemImage)
                        }
                    }
                }

                Section {
                    Text(signature.message)
                        .font(.footnote)
                        .foregroundStyle(signature.needsAttention ? .red : .secondary)
                }
            }
            .navigationTitle("Tidy")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { signature = SigningInfo.current() }
        }
    }
}
