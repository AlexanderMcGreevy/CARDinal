//
//  PDFViewer.swift
//  CARDinal
//
//  PDF viewer component for displaying resumes within the app.
//
//  Created by AI Assistant on 10/20/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct PDFViewer: View {
    let pdfData: Data
    let fileName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFKitView(data: pdfData)
                .navigationTitle(fileName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .topBarLeading) {
                        ShareLink(item: transferableData, preview: SharePreview(fileName)) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
        }
    }

    private var transferableData: Data {
        pdfData
    }
}

// UIViewRepresentable wrapper for PDFKit's PDFView
struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground

        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update if needed
    }
}

#Preview {
    // Create a simple test PDF
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
    let data = renderer.pdfData { context in
        context.beginPage()
        let text = "Sample Resume"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24)
        ]
        text.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
    }

    return PDFViewer(pdfData: data, fileName: "Sample Resume.pdf")
}
