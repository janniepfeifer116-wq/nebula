import SwiftUI

/// A grouped list of key-value rows in a glass card — used for addresses,
/// display info and device info. Values are monospaced; rows marked
/// copyable get a copy glyph and copy their value on tap.
struct KeyValueList: View {
    struct Row: Identifiable {
        let label: String
        let value: String
        var isCopyable = false
        var id: String { label }
    }

    var header: String? = nil
    let rows: [Row]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let header {
                MicroLabel(text: header)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
            }
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                KeyValueRowView(row: row)
                if index < rows.count - 1 {
                    Divider().overlay(Theme.divider).padding(.leading, 16)
                }
            }
        }
        .glassCard(padding: 0)
    }
}

private struct KeyValueRowView: View {
    let row: KeyValueList.Row
    @State private var justCopied = false

    var body: some View {
        HStack {
            Text(row.label)
                .font(.sans(12))
                .foregroundStyle(Theme.textBody)
            Spacer()
            Text(row.value)
                .font(.mono(12))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            if row.isCopyable {
                Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(justCopied ? Theme.aurora : Theme.textMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            guard row.isCopyable else { return }
            UIPasteboard.general.string = row.value
            withAnimation { justCopied = true }
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation { justCopied = false }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
