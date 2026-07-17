import SwiftUI
import SwiftData

struct FridgeView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: FridgeViewModel?
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    FridgeListContent(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("My Fridge")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddFridgeItemView { item in
                    viewModel?.addItem(item)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = FridgeViewModel(context: context)
                }
            }
        }
    }
}

private struct FridgeListContent: View {
    @Bindable var viewModel: FridgeViewModel

    var body: some View {
        List {
            if !viewModel.expiringSoonItems.isEmpty {
                Section("Expiring Soon") {
                    ForEach(viewModel.expiringSoonItems) { item in
                        FridgeItemRow(item: item)
                    }
                }
            }

            Section("All Items (\(viewModel.filteredItems.count))") {
                ForEach(viewModel.filteredItems) { item in
                    FridgeItemRow(item: item)
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.deleteItem(viewModel.filteredItems[index])
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search ingredients...")
        .overlay {
            if viewModel.items.isEmpty {
                ContentUnavailableView(
                    "Fridge is empty",
                    systemImage: "refrigerator",
                    description: Text("Tap + to add ingredients")
                )
            }
        }
    }
}
