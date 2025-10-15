//  EditCardView.swift
//  CARDinal
//
//  Form to edit the user's business card details.
//
//  Created by AI Assistant on 9/30/25.

import SwiftUI
import UniformTypeIdentifiers

struct EditCardView: View {
    @EnvironmentObject var store: CardStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: BusinessCard = BusinessCard()
    @State private var color: Color = .cyan
    @State private var showingDocumentPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Full Name", text: stringBinding(\.fullName))
                    TextField("Company", text: stringBinding(\.company))
                    TextField("Role / Title", text: stringBinding(\.role))
                }
                Section("Contact") {
                    TextField("Phone", text: optionalStringBinding(\.phone))
                        .keyboardType(.phonePad)
                    TextField("Email", text: stringBinding(\.email))
                        .keyboardType(.emailAddress)
                    TextField("Website (https://...)", text: websiteBinding())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section("Social") {
                    TextField("Instagram (handle only)", text: stringBinding(\.instagram))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("LinkedIn (profile slug)", text: stringBinding(\.linkedIn))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section("Card Material") {
                    Picker("Material", selection: $draft.material) {
                        ForEach(CardMaterial.allCases, id: \.rawValue) { material in
                            HStack {
                                Image(systemName: material.icon)
                                Text(material.displayName)
                            }
                            .tag(material)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Resume") {
                    if draft.hasResume {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(color)
                            VStack(alignment: .leading) {
                                Text(draft.resumeFileName ?? "Resume")
                                    .font(.subheadline)
                                Text("Attached")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Remove") {
                                draft.resumeData = nil
                                draft.resumeFileName = nil
                            }
                            .foregroundStyle(.red)
                        }
                    } else {
                        Button(action: { showingDocumentPicker = true }) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Attach Resume (PDF)")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Section("Accent Color") {
                    ColorPicker("Accent", selection: $color, supportsOpacity: false)
                    Rectangle().fill(color.gradient).frame(height: 44).clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(Text("Preview").font(.caption).foregroundStyle(.white.opacity(0.7)))
                }
                Section("Preview") {
                    GlassCardView(card: previewCard, compact: true)
                        .listRowInsets(EdgeInsets())
                        .frame(maxWidth: .infinity, minHeight: 160)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        var updated = draft
                        updated.accentColorHex = color.toHex()
                        store.myCard = updated
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                draft = store.myCard
                color = draft.accentColor
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleDocumentSelection(result)
            }
        }
    }
    
    private var previewCard: BusinessCard {
        var c = draft
        c.accentColorHex = color.toHex()
        return c
    }

    private func handleDocumentSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                draft.resumeData = data
                draft.resumeFileName = url.lastPathComponent
            } catch {
                print("Error reading PDF: \(error)")
            }
            
        case .failure(let error):
            print("Document picker error: \(error)")
        }
    }

    private func load() {
        draft = store.myCard
        color = store.myCard.accentColor
    }

    private func save() {
        store.updateMyCard { current in
            current.fullName = draft.fullName
            current.company = draft.company
            current.role = draft.role
            current.phone = draft.phone
            current.email = draft.email
            current.instagram = draft.instagram
            current.linkedIn = draft.linkedIn
            current.website = draft.website
            current.accentColorHex = color.toHex()
        }
        dismiss()
    }

    // MARK: - Bindings helpers
    private func binding<T>(_ keyPath: WritableKeyPath<BusinessCard, T>) -> Binding<T> {
        Binding(get: { draft[keyPath: keyPath] }, set: { draft[keyPath: keyPath] = $0 })
    }

    private func stringBinding(_ keyPath: WritableKeyPath<BusinessCard, String>) -> Binding<String> {
        Binding<String>(get: { draft[keyPath: keyPath] }, set: { draft[keyPath: keyPath] = $0 })
    }

    private func optionalStringBinding(_ keyPath: WritableKeyPath<BusinessCard, String?>, default def: String = "") -> Binding<String> {
        Binding<String>(get: { draft[keyPath: keyPath] ?? def }, set: { draft[keyPath: keyPath] = $0.isEmpty ? nil : $0 })
    }

    private func websiteBinding() -> Binding<String> {
        Binding<String>(get: { draft.website?.absoluteString ?? "" }, set: { newVal in
            draft.website = URL(string: newVal.trimmingCharacters(in: .whitespacesAndNewlines))
        })
    }
}

#Preview {
    EditCardView().environmentObject(CardStore())
}
