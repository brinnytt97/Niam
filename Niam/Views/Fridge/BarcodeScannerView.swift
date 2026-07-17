import SwiftUI
import AVFoundation

/// Camera barcode scanner using AVFoundation.
struct BarcodeScannerView: UIViewControllerRepresentable {
    var onBarcodeScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onBarcodeScanned = { barcode in
            onBarcodeScanned(barcode)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var onBarcodeScanned: ((String) -> Void)?
        private var captureSession: AVCaptureSession?
        private var hasScanned = false

        override func viewDidLoad() {
            super.viewDidLoad()
            setupCamera()
        }

        private func setupCamera() {
            let session = AVCaptureSession()

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                showError()
                return
            }

            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: .main)
                output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39, .code93]
            }

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            // Add scan frame overlay
            let overlay = UIView()
            overlay.layer.borderColor = UIColor.white.cgColor
            overlay.layer.borderWidth = 2
            overlay.layer.cornerRadius = 12
            overlay.frame = CGRect(x: 50, y: 200, width: view.bounds.width - 100, height: 200)
            overlay.backgroundColor = .clear
            view.addSubview(overlay)

            // Add instruction label
            let label = UILabel()
            label.text = "Point camera at barcode"
            label.textColor = .white
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 16, weight: .medium)
            label.frame = CGRect(x: 0, y: 420, width: view.bounds.width, height: 40)
            view.addSubview(label)

            captureSession = session

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }

        private func showError() {
            let label = UILabel()
            label.text = "Camera not available"
            label.textColor = .white
            label.textAlignment = .center
            label.frame = view.bounds
            view.addSubview(label)
            view.backgroundColor = .black
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !hasScanned,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let barcode = object.stringValue else { return }

            hasScanned = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            captureSession?.stopRunning()
            onBarcodeScanned?(barcode)
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            captureSession?.stopRunning()
        }
    }
}
