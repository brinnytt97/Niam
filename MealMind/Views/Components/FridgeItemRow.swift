import SwiftUI

struct FridgeItemRow: View {
    let item: FridgeItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text("\(item.quantity, specifier: "%.1f") \(item.unit.rawValue) · \(item.category.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if item.isExpired {
                Label("Expired", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if item.isExpiringSoon {
                Label("Expiring", systemImage: "clock.badge.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if let date = item.expirationDate {
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
