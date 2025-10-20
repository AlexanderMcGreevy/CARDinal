//  MyCardView.swift
//  CARDinal
//
//  Shows the user's own card, with actions to edit and share via QR.
//
//  Created by AI Assistant on 9/30/25.

import SwiftUI

struct MyCardView: View {
    @EnvironmentObject var store: CardStore
    @State private var showEdit = false
    @State private var showQR = false
    @State private var showDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                GlassCardView(card: store.myCard)
                    .tiltable()
                    .padding(.top, 40)
                    .onTapGesture {
                        showDetail = true
                    }
                    .overlay(alignment: .topTrailing) {
                        HStack(spacing: 12) {
                            Button { showQR = true } label: { Image(systemName: "qrcode") }
                                .buttonStyle(.borderless)
                                .tint(store.myCard.accentColor)
                            Button { showEdit = true } label: { Image(systemName: "pencil") }
                                .buttonStyle(.borderless)
                                .tint(store.myCard.accentColor)
                        }
                        .font(.title3)
                        .padding(14)
                    }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Share")
                        .font(.headline)
                        .foregroundStyle(.gray)
                    Text("Show your QR code so someone can scan it and instantly add your card.")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    Button {
                        showQR = true
                    } label: {
                        Label("Show My QR Code", systemImage: "qrcode")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.myCard.accentColor)
                }
                .padding(.horizontal)
                Spacer(minLength: 20)
            }
        }
        .sheet(isPresented: $showEdit) {
            EditCardView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showQR) {
            QRCodeShareView(card: store.myCard)
                .preferredColorScheme(.dark)
        }
        .navigationDestination(isPresented: $showDetail) {
            CardDetailView(card: store.myCard, isMyCard: true)
        }
        .background(BackgroundGradient())
        .navigationTitle("My Card")
    }
}

private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(colors: [Color.black, Color(white: 0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}

#Preview {
    MyCardView().environmentObject(CardStore())
}
