import SwiftUI
import PhotosUI
import Vision
import PDFKit
import UniformTypeIdentifiers
import ImageIO

private enum ReceiptReadError: LocalizedError {
    case unreadable, empty, tooLarge
    var errorDescription: String? {
        switch self {
        case .unreadable: return "이미지를 읽을 수 없어요. JPG·PNG 사진 또는 PDF 영수증을 선택해 주세요."
        case .empty: return "읽을 수 있는 글자를 찾지 못했어요. 글자가 선명하고 잘리지 않은 사진으로 다시 선택해 주세요."
        case .tooLarge: return "25MB 이하 파일을 선택해 주세요."
        }
    }
}
enum ReceiptTextReader {
    static func read(_ data: Data, pdf: Bool) throws -> String {
        guard data.count <= 25 * 1024 * 1024 else { throw ReceiptReadError.tooLarge }
        var texts: [String] = []
        if pdf {
            guard let document = PDFDocument(data: data), !document.isLocked, document.pageCount > 0 else { throw ReceiptReadError.unreadable }
            for i in 0..<min(document.pageCount, 5) {
                guard let page = document.page(at: i) else { continue }
                // OCR each page even if the PDF also has a text layer; use one representation.
                let image = page.thumbnail(of: CGSize(width: 1800, height: 2400), for: .mediaBox)
                if let cg = image.cgImage { texts.append(try recognize(cg)) }
            }
        } else {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil), let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 2400, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { throw ReceiptReadError.unreadable }
            texts.append(try recognize(image))
        }
        let result = texts.joined(separator: "\n")
        guard !result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ReceiptReadError.empty }
        return result
    }
    private static func recognize(_ image: CGImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ko-KR", "en-US"]
        request.usesLanguageCorrection = true
        try VNImageRequestHandler(cgImage: image).perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }
}

struct ReceiptImportView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Subscription) -> Bool
    @State private var photo: PhotosPickerItem?
    @State private var showingFiles = false
    @State private var reading = false
    @State private var error: String?
    @State private var recognizedText = ""
    @State private var recognition = ReceiptRecognition()
    @State private var name = ""
    @State private var amount = ""
    @State private var currency = "KRW"
    @State private var yearly = false
    @State private var billingDate = Date()
    @State private var confirmed = false
    @State private var loaded = false
    @State private var saveFailed = false
    private var valid: Bool { loaded && !reading && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Subscription.validAmount(amount, allowZero: true) != nil && confirmed }
    var body: some View {
        Form {
            sourceSection
            if let error { Section { Text(error).foregroundStyle(.red).font(.subheadline) } }
            if loaded {
                reviewSection
                Section {
                    DisclosureGroup("인식한 원문 보기") { Text(recognizedText).font(.caption).textSelection(.enabled) }
                    if saveFailed { Text("저장하지 못했어요. 입력 내용은 유지돼 있어요. 다시 저장해 주세요.").foregroundStyle(.red) }
                    Button("확인하고 구독 저장", action: save).disabled(!valid).accessibilityIdentifier("receipt.save")
                }
            }
        }
        .scrollContentBackground(.hidden).background(Color.membershipBackground)
        .navigationTitle("사진·영수증 자동 입력").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
        .onChange(of: photo) { _, item in
            guard let item else { return }
            Task {
                reading = true; loaded = false; error = nil; confirmed = false
                do { guard let data = try await item.loadTransferable(type: Data.self) else { throw ReceiptReadError.unreadable }; await process(data, pdf: false) }
                catch { self.error = error.localizedDescription; reading = false }
            }
        }
        .fileImporter(isPresented: $showingFiles, allowedContentTypes: [.image, .pdf]) { result in
            switch result {
            case .success(let url):
                Task {
                    reading = true; loaded = false; error = nil; confirmed = false
                    let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
                    do {
                        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                        guard size <= 25 * 1024 * 1024 else { throw ReceiptReadError.tooLarge }
                        let data = try Data(contentsOf: url)
                        await process(data, pdf: url.pathExtension.lowercased() == "pdf")
                    } catch { self.error = error.localizedDescription; reading = false }
                }
            case .failure(let failure): error = failure.localizedDescription
            }
        }
        .onChange(of: name) { _, _ in confirmed = false }
        .onChange(of: amount) { _, _ in confirmed = false }
        .onChange(of: currency) { _, _ in confirmed = false }
        .onChange(of: yearly) { _, _ in confirmed = false }
        .onChange(of: billingDate) { _, _ in confirmed = false }
    }
    private var sourceSection: some View {
            Section {
                PhotosPicker(selection: $photo, matching: .images, photoLibrary: .shared()) { Label("결제 화면·영수증 사진 선택", systemImage: "photo") }.disabled(reading)
                Button { showingFiles = true } label: { Label("파일에서 가져오기", systemImage: "doc") }.disabled(reading)
                if reading { ProgressView("글자를 읽고 있어요…") }
            } footer: { Text("사진·PDF(앞 5페이지, 최대 25MB)를 기기 안에서 읽어요. 원본 사진과 인식한 전체 문장은 저장하거나 서버로 보내지 않아요.") }
    }
    private var reviewSection: some View {
                Section {
                    TextField("서비스 이름", text: $name).accessibilityIdentifier("receipt.name")
                    if recognition.amounts.count > 1 {
                        Menu("다른 인식 금액 선택") {
                            ForEach(recognition.amounts.indices, id: \.self) { index in
                                let candidate = recognition.amounts[index]
                                Button("\(candidate.value.formatted(.currency(code: candidate.currency))) · \(candidate.evidence)") {
                                    amount = String(candidate.value); currency = candidate.currency; confirmed = false
                                }
                            }
                        }
                    }
                    HStack { Text("결제 금액"); TextField("직접 입력", text: $amount).multilineTextAlignment(.trailing).keyboardType(.decimalPad).accessibilityIdentifier("receipt.amount") }
                    Picker("통화", selection: $currency) { Text("원 KRW").tag("KRW"); Text("달러 USD").tag("USD") }
                    Picker("결제 주기", selection: $yearly) { Text("매월").tag(false); Text("매년").tag(true) }
                    DatePicker("다음 결제일", selection: $billingDate, displayedComponents: .date)
                    if recognition.nextPayment == nil {
                        Text("다음 결제일은 확인하지 못했어요. 아래 날짜는 오늘로 표시되어 있으니 직접 지정해 주세요. 영수증 결제일을 다음 결제일로 간주하지 않아요.").font(.caption).foregroundStyle(.secondary)
                    }
                    if recognition.yearly == nil { Text("결제 주기는 확인하지 못했어요. 매월·매년 중 실제 주기를 선택해 주세요.").font(.caption).foregroundStyle(.secondary) }
                    if recognition.amounts.isEmpty { Text("금액은 확인하지 못했어요. 직접 입력해 주세요.").font(.caption).foregroundStyle(.secondary) }
                    Toggle("금액·주기·다음 결제일을 확인했어요", isOn: $confirmed).font(.subheadline)
                } header: { Text("인식한 정보 확인") } footer: { Text("할인 금액·일회성 결제가 포함될 수 있어요. 실제 정기 구독의 금액과 일정을 확인한 뒤 저장하세요.") }
    }
    @MainActor private func process(_ data: Data, pdf: Bool) async {
        do {
            let text = try await Task.detached(priority: .userInitiated) { try ReceiptTextReader.read(data, pdf: pdf) }.value
            let parsed = ReceiptParser.parse(text)
            recognition = parsed; recognizedText = text; name = parsed.name
            amount = parsed.amounts.first.map { String($0.value) } ?? ""; currency = parsed.amounts.first?.currency ?? "KRW"
            yearly = parsed.yearly ?? false; billingDate = parsed.nextPayment ?? Date(); confirmed = false; loaded = true
        } catch { self.error = error.localizedDescription }
        reading = false
    }
    private func save() {
        guard valid, let value = Subscription.validAmount(amount, allowZero: true) else { return }
        let matched = CatalogService.all.first { service in ([service.name, service.displayName] + service.aliases).contains { $0.localizedCaseInsensitiveCompare(name) == .orderedSame } }
        var item = Subscription(name: name.trimmingCharacters(in: .whitespacesAndNewlines), amount: value, yearly: yearly, billingDate: billingDate, serviceID: matched?.id, category: matched?.category)
        item.currency = currency; if onSave(item) { dismiss() } else { saveFailed = true }
    }
}
