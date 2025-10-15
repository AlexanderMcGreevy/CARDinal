//  QRScannerSheet.swift
//  CARDinal
//
//  Presents a camera-based QR code scanner and returns the raw string payload.
//
//  Created by AI Assistant on 9/30/25.

import SwiftUI
import AVFoundation

struct QRScannerSheet: View {
    enum ScanError: Error { case denied, failed }
    var completion: (Result<String, Error>) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var cameraAuthorized = false
    @State private var error: ScanError? = nil

    var body: some View {
        NavigationStack {
            Group {
                if cameraAuthorized {
                    ScannerViewRepresentable(onResult: handleResult)
                        .overlay(alignment: .top) { ScannerOverlay() }
                        .overlay(alignment: .bottom) { instruction }
                } else if error != nil {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle").font(.largeTitle)
                        Text("Camera access denied")
                        Text("Enable camera permission in Settings to scan QR codes.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Close") { dismiss() }
                    }.padding()
                } else {
                    ProgressView("Requesting Camera...")
                }
            }
            .navigationTitle("Scan QR")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .task { await requestPermission() }
            .background(Color.black.ignoresSafeArea())
        }
    }

    private var instruction: some View {
        Text("Align the QR code within the frame")
            .font(.footnote.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 40)
    }

    private func handleResult(_ result: Result<String, Error>) {
        completion(result)
        dismiss()
    }

    private func requestPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAuthorized = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run { cameraAuthorized = granted; if !granted { error = .denied } }
        default:
            error = .denied
        }
    }
}

private struct ScannerOverlay: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.85), lineWidth: 3)
                .frame(width: 260, height: 260)
                .shadow(color: .black.opacity(0.6), radius: 8)
        }
        .padding(.top, 40)
    }
}

// MARK: - UIViewRepresentable Scanner
private struct ScannerViewRepresentable: UIViewControllerRepresentable {
    var onResult: (Result<String, Error>) -> Void

    func makeUIViewController(context: Context) -> ScannerVC { ScannerVC(onResult: onResult) }
    func updateUIViewController(_ uiViewController: ScannerVC, context: Context) {}

    final class ScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        private let session = AVCaptureSession()
        private var previewLayer: AVCaptureVideoPreviewLayer!
        private var onResult: (Result<String, Error>) -> Void
        private var didFinish = false

        init(onResult: @escaping (Result<String, Error>) -> Void) {
            self.onResult = onResult
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            configureSession()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if session.isRunning {
                session.stopRunning()
            }
        }

        private func configureSession() {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { 
                onResult(.failure(QRScannerSheet.ScanError.failed))
                return 
            }
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { 
                onResult(.failure(QRScannerSheet.ScanError.failed))
                return 
            }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]

            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)

            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.session.startRunning()
            }
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !didFinish, 
                  let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject, 
                  obj.type == .qr, 
                  let value = obj.stringValue else { return }
            
            didFinish = true
            session.stopRunning()
            
            // Haptic feedback for successful scan
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            onResult(.success(value))
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            previewLayer?.frame = view.bounds
        }
    }
}

#Preview { QRScannerSheet { _ in } }
