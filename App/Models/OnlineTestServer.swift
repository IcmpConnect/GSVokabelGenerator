import Foundation
import Network
import Combine
import CoreImage
import AppKit

@MainActor
public class OnlineTestServer: ObservableObject {
    @Published public private(set) var isRunning: Bool = false
    @Published public var port: UInt16 = 8000
    @Published public var localIP: String = "127.0.0.1"
    @Published public private(set) var serverURL: String = ""
    @Published public private(set) var results: [StudentTestResult] = []
    @Published public private(set) var activeUnit: VocabularyUnit? = nil
    @Published public var direction: TestDirection = .germanToEnglish
    @Published public var shuffleQuestions: Bool = true
    @Published public var statusMessage: String = "Bereit zum Starten"

    private var listener: NWListener?
    private let listenerQueue = DispatchQueue(label: "de.gsvokabel.server.queue", qos: .userInitiated)

    nonisolated private let serverState = ServerState()

    public init(defaultPort: UInt16 = 8000) {
        self.port = defaultPort
        self.localIP = Self.detectPrimaryIPv4()
        self.serverURL = "http://\(self.localIP):\(self.port)"
    }

    public func setPort(_ newPort: UInt16) {
        guard self.port != newPort else { return }
        self.port = newPort
        self.serverURL = "http://\(self.localIP):\(self.port)"
        if isRunning, let unit = activeUnit {
            start(unit: unit, port: newPort, direction: direction, shuffle: shuffleQuestions)
        }
    }

    public func setLocalIP(_ newIP: String) {
        self.localIP = newIP
        self.serverURL = "http://\(self.localIP):\(self.port)"
        if isRunning, let unit = activeUnit {
            start(unit: unit, port: self.port, direction: direction, shuffle: shuffleQuestions)
        }
    }

    public func refreshNetwork() {
        self.localIP = Self.detectPrimaryIPv4()
        self.serverURL = "http://\(self.localIP):\(self.port)"
        if isRunning, let unit = activeUnit {
            start(unit: unit, port: port, direction: direction, shuffle: shuffleQuestions)
        }
    }

    public func start(unit: VocabularyUnit, port: UInt16? = nil, direction: TestDirection = .germanToEnglish, shuffle: Bool = true) {
        stop()

        self.activeUnit = unit
        if let p = port {
            self.port = p
        }
        self.direction = direction
        self.shuffleQuestions = shuffle
        if self.localIP == "127.0.0.1" || self.localIP.isEmpty {
            self.localIP = Self.detectPrimaryIPv4()
        }
        self.serverURL = "http://\(self.localIP):\(self.port)"

        serverState.set(unit: unit, direction: direction, shuffle: shuffle)

        do {
            let nwPort = NWEndpoint.Port(rawValue: self.port) ?? NWEndpoint.Port(integerLiteral: 8000)
            let newListener = try NWListener(using: .tcp, on: nwPort)

            newListener.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingConnection(connection)
            }

            newListener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    switch state {
                    case .ready:
                        self.isRunning = true
                        self.statusMessage = "Online-Test läuft auf Port \(self.port)"
                    case .failed(let error):
                        self.isRunning = false
                        self.statusMessage = "Serverfehler: \(error.localizedDescription)"
                    case .cancelled:
                        self.isRunning = false
                        self.statusMessage = "Server gestoppt"
                    default:
                        break
                    }
                }
            }

            self.listener = newListener
            newListener.start(queue: listenerQueue)
            self.isRunning = true
            self.statusMessage = "Server gestartet..."
        } catch {
            self.statusMessage = "Start fehlgeschlagen: \(error.localizedDescription)"
            self.isRunning = false
        }
    }

    public func stop() {
        if let l = listener {
            l.cancel()
            listener = nil
        }
        isRunning = false
        statusMessage = "Server angehalten"
    }

    public func clearResults() {
        serverState.clear()
        results.removeAll()
    }

    public func exportResultsCSV() -> String {
        guard activeUnit != nil else { return "" }
        var csv = "Schülername;Uhrzeit;Punkte;Max. Punkte;Prozent;Pflanzen-Stufe;Fehleranzahl;Falsche Wörter\n"
        for r in results {
            let incorrectWords = r.incorrectAnswers
                .map { "\($0.prompt) -> getippt: '\($0.studentAnswer)' (richtig: '\($0.expectedAnswer)')" }
                .joined(separator: " | ")
                .replacingOccurrences(of: ";", with: ",")
            let line = "\(r.studentName);\(r.formattedTime);\(r.score);\(r.maxScore);\(r.formattedPercentage);\(r.levelName);\(r.incorrectAnswers.count);\"\(incorrectWords)\"\n"
            csv += line
        }
        return csv
    }

    public func generateQRCode(size: CGFloat = 360) -> NSImage? {
        guard let data = serverURL.data(using: .utf8) else { return nil }
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let outputImage = filter.outputImage else { return nil }

        let scale = size / outputImage.extent.width
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let rep = NSCIImageRep(ciImage: scaledImage)
        let img = NSImage(size: rep.size)
        img.addRepresentation(rep)
        return img
    }

    // MARK: - Connection & HTTP Handling
    nonisolated private func handleIncomingConnection(_ connection: NWConnection) {
        connection.start(queue: listenerQueue)
        receiveHTTPData(connection: connection, accumulated: Data())
    }

    nonisolated private func receiveHTTPData(connection: NWConnection, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self, error == nil else {
                connection.cancel()
                return
            }

            var current = accumulated
            if let data = data {
                current.append(data)
            }

            if let headerEnd = current.range(of: Data("\r\n\r\n".utf8)) {
                let headerData = current.subdata(in: 0..<headerEnd.lowerBound)
                let headerString = String(data: headerData, encoding: .utf8) ?? ""
                var expectedContentLength = 0
                for line in headerString.components(separatedBy: "\r\n") {
                    let lower = line.lowercased()
                    if lower.hasPrefix("content-length:") {
                        let val = line.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)
                        expectedContentLength = Int(val) ?? 0
                    }
                }

                let bodyReceived = current.count - headerEnd.upperBound
                if bodyReceived >= expectedContentLength || isComplete {
                    Task {
                        let responseData = await self.processHTTPRequest(current)
                        connection.send(content: responseData, completion: .contentProcessed { _ in
                            connection.cancel()
                        })
                    }
                    return
                }
            } else if isComplete {
                Task {
                    let responseData = await self.processHTTPRequest(current)
                    connection.send(content: responseData, completion: .contentProcessed { _ in
                        connection.cancel()
                    })
                }
                return
            }

            // Continue receiving
            self.receiveHTTPData(connection: connection, accumulated: current)
        }
    }

    // MARK: - Thread-Safe Config & State Access
    nonisolated private func getCachedConfig() -> (unit: VocabularyUnit?, direction: TestDirection, shuffle: Bool, results: [StudentTestResult]) {
        return serverState.getSnapshot()
    }

    nonisolated private func appendCachedResult(_ result: StudentTestResult) {
        serverState.appendResult(result)
    }

    nonisolated private func processHTTPRequest(_ requestData: Data) async -> Data {
        guard let requestString = String(data: requestData, encoding: .utf8) else {
            return makeHTTPResponse(status: 400, contentType: "text/plain", body: "Bad Request")
        }

        let lines = requestString.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            return makeHTTPResponse(status: 400, contentType: "text/plain", body: "Bad Request")
        }

        let parts = firstLine.split(separator: " ")
        guard parts.count >= 2 else {
            return makeHTTPResponse(status: 400, contentType: "text/plain", body: "Bad Request")
        }

        let method = String(parts[0])
        let path = String(parts[1])

        if method == "GET" && (path == "/" || path == "/index.html") {
            let html = renderStudentHTML()
            return makeHTTPResponse(status: 200, contentType: "text/html; charset=utf-8", body: html)
        } else if method == "GET" && path.starts(with: "/api/test") {
            let json = makeTestQuestionsJSON()
            return makeHTTPResponse(status: 200, contentType: "application/json; charset=utf-8", body: json)
        } else if method == "GET" && path.starts(with: "/api/results") {
            let json = makeResultsJSON()
            return makeHTTPResponse(status: 200, contentType: "application/json; charset=utf-8", body: json)
        } else if method == "POST" && path.starts(with: "/api/submit") {
            // Find body after double CRLF
            if let range = requestString.range(of: "\r\n\r\n") {
                let body = String(requestString[range.upperBound...])
                let responseJSON = await handleSubmission(bodyJSON: body)
                return makeHTTPResponse(status: 200, contentType: "application/json; charset=utf-8", body: responseJSON)
            }
            return makeHTTPResponse(status: 400, contentType: "application/json", body: "{\"error\":\"No payload\"}")
        } else {
            return makeHTTPResponse(status: 404, contentType: "text/plain", body: "404 Not Found")
        }
    }

    nonisolated private func makeHTTPResponse(status: Int, contentType: String, body: String) -> Data {
        let statusText = status == 200 ? "OK" : (status == 404 ? "Not Found" : "Error")
        let utf8Body = body.data(using: .utf8) ?? Data()
        let headers = [
            "HTTP/1.1 \(status) \(statusText)",
            "Content-Type: \(contentType)",
            "Content-Length: \(utf8Body.count)",
            "Connection: close",
            "Access-Control-Allow-Origin: *",
            "\r\n"
        ].joined(separator: "\r\n")

        var fullData = headers.data(using: .utf8) ?? Data()
        fullData.append(utf8Body)
        return fullData
    }

    // MARK: - Test Questions & Evaluation
    nonisolated private func makeTestQuestionsJSON() -> String {
        let (unitOpt, direction, shuffle, _) = getCachedConfig()
        guard let unit = unitOpt else {
            return "{\"error\":\"No active unit\"}"
        }

        var pairs = unit.pairs
        if shuffle {
            pairs.shuffle()
        }

        var questionItems: [[String: Any]] = []
        for (index, pair) in pairs.enumerated() {
            let (prompt, expected, promptLang) = determinePromptAndExpected(pair: pair, index: index, direction: direction)
            let hasMultipleSolutions = expected.contains("/")
            let slashCount = expected.components(separatedBy: "/").count
            let promptHasSlash = prompt.contains("/")
            questionItems.append([
                "id": pair.id.uuidString,
                "prompt": prompt,
                "promptLang": promptLang,
                "hasMultipleSolutions": hasMultipleSolutions,
                "slashCount": slashCount,
                "promptHasSlash": promptHasSlash
            ])
        }

        let dict: [String: Any] = [
            "unitTitle": unit.title,
            "classNumber": unit.classNumber,
            "unitNumber": unit.cleanUnitNumber,
            "deadlineDay": unit.deadlineDay,
            "totalQuestions": questionItems.count,
            "questions": questionItems
        ]

        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{}"
    }

    nonisolated private func determinePromptAndExpected(pair: VocabularyPair, index: Int, direction: TestDirection) -> (prompt: String, expected: String, promptLang: String) {
        switch direction {
        case .germanToEnglish:
            return (pair.german, pair.english, "DE")
        case .englishToGerman:
            return (pair.english, pair.german, "EN")
        case .alternating:
            if index % 2 == 0 {
                return (pair.german, pair.english, "DE")
            } else {
                return (pair.english, pair.german, "EN")
            }
        }
    }

    nonisolated private func handleSubmission(bodyJSON: String) async -> String {
        let (unitOpt, direction, _, _) = getCachedConfig()
        guard let unit = unitOpt,
              let data = bodyJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let studentName = json["studentName"] as? String,
              let submittedAnswers = json["answers"] as? [[String: Any]] else {
            return "{\"error\":\"Invalid submission data\"}"
        }

        var studentAnswers: [StudentAnswer] = []
        var totalScore = 0

        for (index, pair) in unit.pairs.enumerated() {
            let (prompt, expected, promptLang) = determinePromptAndExpected(pair: pair, index: index, direction: direction)
            let submissionForPair = submittedAnswers.first { ($0["pairID"] as? String) == pair.id.uuidString }
            let studentInput = (submissionForPair?["answer"] as? String) ?? ""

            let isCorrect = evaluateAnswer(student: studentInput, expected: expected)
            if isCorrect {
                totalScore += 1
            }

            let ans = StudentAnswer(
                pairID: pair.id,
                prompt: prompt,
                promptLanguage: promptLang,
                expectedAnswer: expected,
                studentAnswer: studentInput,
                isCorrect: isCorrect
            )
            studentAnswers.append(ans)
        }

        let maxScore = max(1, unit.pairs.count)
        let percentage = (Double(totalScore) / Double(maxScore)) * 100.0

        // Calculate Pedagogical Grading Threshold
        let grading = GradingScale(totalPoints: maxScore)
        var feedbackLevel = 1
        var feedbackText = "Ich kann es noch nicht, gebe aber nicht auf und übe fleißig."

        for th in grading.thresholds {
            if Double(totalScore) >= th.minPoints && Double(totalScore) <= th.maxPoints {
                feedbackLevel = th.level
                feedbackText = th.textGerman
                break
            }
        }

        let cleanName = studentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Schüler" : studentName.trimmingCharacters(in: .whitespacesAndNewlines)

        let result = StudentTestResult(
            studentName: cleanName,
            submissionDate: Date(),
            score: totalScore,
            maxScore: maxScore,
            percentage: percentage,
            feedbackLevel: feedbackLevel,
            feedbackText: feedbackText,
            answers: studentAnswers
        )

        // Store result in thread-safe cache and update UI on MainActor
        appendCachedResult(result)
        Task { @MainActor [weak self] in
            self?.results.append(result)
        }

        // Build response JSON for student's iPad
        var evaluatedAnswersJSON: [[String: Any]] = []
        for a in studentAnswers {
            evaluatedAnswersJSON.append([
                "prompt": a.prompt,
                "promptLang": a.promptLanguage,
                "studentAnswer": a.studentAnswer,
                "expectedAnswer": a.expectedAnswer,
                "isCorrect": a.isCorrect
            ])
        }

        let responseDict: [String: Any] = [
            "studentName": result.studentName,
            "score": result.score,
            "maxScore": result.maxScore,
            "percentage": Int(round(result.percentage)),
            "feedbackLevel": result.feedbackLevel,
            "feedbackText": result.feedbackText,
            "levelIcon": result.levelIcon,
            "levelName": result.levelName,
            "answers": evaluatedAnswersJSON
        ]

        if let resData = try? JSONSerialization.data(withJSONObject: responseDict, options: [.prettyPrinted]),
           let resStr = String(data: resData, encoding: .utf8) {
            return resStr
        }
        return "{\"status\":\"ok\"}"
    }

    nonisolated private func evaluateAnswer(student: String, expected: String) -> Bool {
        let cleanStudent = normalizeString(student)
        let cleanExpected = normalizeString(expected)

        if cleanStudent.isEmpty {
            return false
        }

        if cleanStudent == cleanExpected {
            return true
        }

        // 1. Split expected answer into options if it contains slashes (e.g. "das Fest / die Party")
        let expectedOptions: [String]
        if expected.contains("/") {
            expectedOptions = expected.components(separatedBy: "/").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        } else {
            expectedOptions = [expected]
        }

        // Build a comprehensive set of valid candidate strings
        var validCandidates: Set<String> = []

        // Add normalized full expected and article-stripped full expected
        validCandidates.insert(cleanExpected)
        let cleanExpectedStripped = stripArticles(cleanExpected)
        if !cleanExpectedStripped.isEmpty {
            validCandidates.insert(cleanExpectedStripped)
        }

        // Add each single option (both with and without articles)
        for opt in expectedOptions {
            let normOpt = normalizeString(opt)
            validCandidates.insert(normOpt)
            let strippedOpt = stripArticles(normOpt)
            if !strippedOpt.isEmpty {
                validCandidates.insert(strippedOpt)
            }
        }

        // If multiple options exist, accept combined forms in various orders and separators
        if expectedOptions.count > 1 {
            let normOpts = expectedOptions.map { normalizeString($0) }
            let strippedOpts = normOpts.map { stripArticles($0) }

            // With "/" separator (normal and reversed)
            validCandidates.insert(normOpts.joined(separator: " / "))
            validCandidates.insert(normOpts.reversed().joined(separator: " / "))
            validCandidates.insert(strippedOpts.joined(separator: " / "))
            validCandidates.insert(strippedOpts.reversed().joined(separator: " / "))

            // Without spaces around slash "a/b"
            validCandidates.insert(normOpts.joined(separator: "/"))
            validCandidates.insert(normOpts.reversed().joined(separator: "/"))
            validCandidates.insert(strippedOpts.joined(separator: "/"))
            validCandidates.insert(strippedOpts.reversed().joined(separator: "/"))

            // With "oder" or "or"
            validCandidates.insert(normOpts.joined(separator: " oder "))
            validCandidates.insert(normOpts.joined(separator: " or "))
            validCandidates.insert(strippedOpts.joined(separator: " oder "))
            validCandidates.insert(strippedOpts.joined(separator: " or "))

            // With comma or space
            validCandidates.insert(normOpts.joined(separator: ", "))
            validCandidates.insert(strippedOpts.joined(separator: ", "))
            validCandidates.insert(normOpts.joined(separator: " "))
            validCandidates.insert(strippedOpts.joined(separator: " "))
        }

        // Direct check against candidates
        if validCandidates.contains(cleanStudent) {
            return true
        }

        // Check with student articles stripped (e.g. student typed "das Fest" when option was "Fest", or vice versa)
        let studentStripped = stripArticles(cleanStudent)
        if !studentStripped.isEmpty && validCandidates.contains(studentStripped) {
            return true
        }

        // If student separated their answer by slash or comma or "oder" / "or",
        // check whether each part given by the student matches a valid expected option
        let studentParts = cleanStudent
            .replacingOccurrences(of: " oder ", with: "/")
            .replacingOccurrences(of: " or ", with: "/")
            .replacingOccurrences(of: ", ", with: "/")
            .components(separatedBy: "/")
            .map { normalizeString($0) }
            .filter { !$0.isEmpty }

        if studentParts.count > 1 {
            let allValid = studentParts.allSatisfy { part in
                let partStripped = stripArticles(part)
                return expectedOptions.contains { opt in
                    let normOpt = normalizeString(opt)
                    return normOpt == part || stripArticles(normOpt) == part || normOpt == partStripped || stripArticles(normOpt) == partStripped
                }
            }
            if allValid {
                return true
            }
        }

        return false
    }

    nonisolated private func stripArticles(_ text: String) -> String {
        let articles = ["der ", "die ", "das ", "the ", "a ", "an "]
        var result = text
        for art in articles {
            if result.hasPrefix(art) {
                result = String(result.dropFirst(art.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        return result
    }

    nonisolated private func normalizeString(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,!?:;\"'()"))
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    nonisolated private func makeResultsJSON() -> String {
        let (_, _, _, results) = getCachedConfig()
        var list: [[String: Any]] = []
        for r in results {
            list.append([
                "id": r.id.uuidString,
                "studentName": r.studentName,
                "score": r.score,
                "maxScore": r.maxScore,
                "percentage": r.percentage,
                "levelIcon": r.levelIcon,
                "levelName": r.levelName,
                "time": r.formattedTime,
                "incorrectCount": r.incorrectAnswers.count
            ])
        }
        if let data = try? JSONSerialization.data(withJSONObject: list, options: [.prettyPrinted]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "[]"
    }

    // MARK: - Detect Local IP
    public static func detectPrimaryIPv4() -> String {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return "127.0.0.1" }
        defer { freeifaddrs(ifaddr) }

        var candidateIPs: [(name: String, ip: String)] = []

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee

            if (flags & (IFF_UP | IFF_RUNNING)) == (IFF_UP | IFF_RUNNING) &&
               (flags & IFF_LOOPBACK) == 0 &&
               addr.sa_family == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let ifName = String(cString: ptr.pointee.ifa_name)
                    let ip = String(cString: hostname)
                    candidateIPs.append((name: ifName, ip: ip))
                }
            }
        }

        // Prioritize Wi-Fi (en0)
        if let wifi = candidateIPs.first(where: { $0.name == "en0" }) {
            return wifi.ip
        }
        // Fallback to any 192.168.x or 10.x
        if let localSubnet = candidateIPs.first(where: { $0.ip.starts(with: "192.168.") || $0.ip.starts(with: "10.") }) {
            return localSubnet.ip
        }
        return candidateIPs.first?.ip ?? "127.0.0.1"
    }

    public static func allAvailableIPv4s() -> [(name: String, ip: String)] {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return [] }
        defer { freeifaddrs(ifaddr) }

        var candidateIPs: [(name: String, ip: String)] = []

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee

            if (flags & (IFF_UP | IFF_RUNNING)) == (IFF_UP | IFF_RUNNING) &&
               (flags & IFF_LOOPBACK) == 0 &&
               addr.sa_family == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let ifName = String(cString: ptr.pointee.ifa_name)
                    let ip = String(cString: hostname)
                    if !candidateIPs.contains(where: { $0.ip == ip }) {
                        candidateIPs.append((name: ifName, ip: ip))
                    }
                }
            }
        }
        return candidateIPs
    }

    // MARK: - Embedded Student iPad HTML/CSS/JS
    nonisolated private func renderStudentHTML() -> String {
        let (unitOpt, _, _, _) = getCachedConfig()
        let title = unitOpt?.title ?? "Vokabeltest"
        let classNum = unitOpt?.classNumber ?? 3
        let unitNum = unitOpt?.cleanUnitNumber ?? "1"

        return """
        <!DOCTYPE html>
        <html lang="de">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <title>Vokabeltest • Class \(classNum) Unit \(unitNum)</title>
          <style>
            :root {
              --primary: #2563eb;
              --primary-light: #eff6ff;
              --success: #16a34a;
              --success-light: #f0fdf4;
              --error: #dc2626;
              --error-light: #fef2f2;
              --text: #1e293b;
              --text-muted: #64748b;
              --border: #e2e8f0;
              --card-bg: #ffffff;
              --bg: #f8fafc;
            }
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
              font-family: -apple-system, BlinkMacSystemFont, "SF Pro Rounded", "Comic Neue", "Arial Rounded MT Bold", sans-serif;
              background-color: var(--bg);
              color: var(--text);
              padding: 16px;
              min-height: 100vh;
              display: flex;
              justify-content: center;
              align-items: center;
            }
            .container {
              width: 100%;
              max-width: 620px;
              background: var(--card-bg);
              border-radius: 24px;
              box-shadow: 0 10px 25px -5px rgba(0,0,0,0.06), 0 8px 10px -6px rgba(0,0,0,0.04);
              padding: 24px;
              overflow: hidden;
            }
            .header {
              text-align: center;
              margin-bottom: 24px;
            }
            .badge {
              display: inline-block;
              padding: 6px 14px;
              background: var(--primary-light);
              color: var(--primary);
              border-radius: 999px;
              font-weight: 700;
              font-size: 14px;
              margin-bottom: 8px;
            }
            h1 { font-size: 26px; font-weight: 800; color: #0f172a; margin-bottom: 4px; }
            .subtitle { font-size: 15px; color: var(--text-muted); }
            
            /* Inputs & Buttons */
            .input-group { margin: 20px 0; }
            label { display: block; font-weight: 700; font-size: 15px; margin-bottom: 8px; color: #334155; }
            input[type="text"] {
              width: 100%;
              padding: 14px 18px;
              font-size: 19px;
              border: 2px solid var(--border);
              border-radius: 14px;
              outline: none;
              font-family: inherit;
              transition: border-color 0.2s;
              background: #fff;
            }
            input[type="text"]:focus {
              border-color: var(--primary);
              box-shadow: 0 0 0 3px rgba(37,99,235,0.15);
            }
            button.btn {
              width: 100%;
              padding: 16px;
              font-size: 18px;
              font-weight: 700;
              border: none;
              border-radius: 14px;
              cursor: pointer;
              transition: transform 0.1s, background-color 0.2s;
              font-family: inherit;
            }
            button.btn-primary { background: var(--primary); color: #fff; }
            button.btn-primary:active { transform: scale(0.98); }
            button.btn-success { background: var(--success); color: #fff; }
            button.btn-success:active { transform: scale(0.98); }
            button.btn-secondary { background: #f1f5f9; color: #475569; }
            
            /* Screens */
            .screen { display: none; }
            .screen.active { display: block; }

            /* Question view */
            .progress-container {
              display: flex;
              align-items: center;
              justify-content: space-between;
              margin-bottom: 16px;
              font-size: 14px;
              font-weight: 700;
              color: var(--text-muted);
            }
            .progress-bar-bg {
              width: 100%;
              height: 10px;
              background: #e2e8f0;
              border-radius: 6px;
              overflow: hidden;
              margin-bottom: 20px;
            }
            .progress-bar-fill {
              height: 100%;
              background: var(--primary);
              width: 0%;
              transition: width 0.3s;
            }
            .question-box {
              background: #f8fafc;
              border: 2px solid #e2e8f0;
              border-radius: 18px;
              padding: 20px;
              text-align: center;
              margin-bottom: 20px;
            }
            .lang-badge {
              display: inline-block;
              font-size: 13px;
              font-weight: 700;
              padding: 4px 10px;
              border-radius: 8px;
              margin-bottom: 8px;
            }
            .lang-de { background: #fee2e2; color: #991b1b; }
            .lang-en { background: #e0e7ff; color: #3730a3; }
            .prompt-word {
              font-size: 26px;
              font-weight: 800;
              color: #0f172a;
            }
            .multi-solution-hint {
              margin-top: 12px;
              padding: 10px 14px;
              background: #fffbeb;
              border: 1px solid #fde68a;
              border-radius: 8px;
              font-size: 13px;
              color: #92400e;
              display: none;
              line-height: 1.4;
              text-align: left;
            }
            .nav-buttons {
              display: flex;
              gap: 12px;
              margin-top: 20px;
            }
            .nav-buttons button { flex: 1; }

            /* Question Grid / Dots */
            .dots-grid {
              display: flex;
              flex-wrap: wrap;
              gap: 8px;
              justify-content: center;
              margin-top: 20px;
              padding-top: 16px;
              border-top: 1px dashed var(--border);
            }
            .dot {
              width: 32px;
              height: 32px;
              border-radius: 8px;
              background: #f1f5f9;
              display: flex;
              align-items: center;
              justify-content: center;
              font-size: 13px;
              font-weight: 700;
              color: #64748b;
              cursor: pointer;
            }
            .dot.answered { background: #dbeafe; color: #1e40af; border: 1px solid #bfdbfe; }
            .dot.active { background: var(--primary); color: #fff; }

            /* Results view */
            .result-hero {
              text-align: center;
              padding: 20px 0;
            }
            .score-circle {
              width: 110px;
              height: 110px;
              border-radius: 55px;
              background: var(--success-light);
              color: var(--success);
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              margin: 0 auto 16px;
              border: 3px solid #bbf7d0;
            }
            .score-num { font-size: 30px; font-weight: 900; line-height: 1; }
            .score-pct { font-size: 13px; font-weight: 700; opacity: 0.85; }
            .plant-card {
              background: #f0fdf4;
              border: 2px solid #86efac;
              border-radius: 16px;
              padding: 16px;
              margin: 16px 0;
              text-align: center;
            }
            .plant-icon { font-size: 40px; margin-bottom: 6px; }
            .plant-title { font-size: 18px; font-weight: 800; color: #166534; margin-bottom: 4px; }
            .plant-text { font-size: 14px; color: #15803d; line-height: 1.4; }

            .answer-list {
              margin: 20px 0;
              text-align: left;
            }
            .answer-card {
              display: flex;
              align-items: flex-start;
              gap: 12px;
              padding: 12px 16px;
              border-radius: 12px;
              margin-bottom: 10px;
              background: #fff;
              border: 1px solid var(--border);
            }
            .answer-card.correct { border-color: #86efac; background: #f0fdf4; }
            .answer-card.incorrect { border-color: #fca5a5; background: #fef2f2; }
            .answer-icon { font-size: 20px; line-height: 1.2; }
            .answer-content { flex: 1; }
            .answer-prompt { font-weight: 700; font-size: 15px; color: #0f172a; margin-bottom: 2px; }
            .answer-typed { font-size: 14px; color: #475569; }
            .answer-expected { font-size: 14px; font-weight: 700; color: var(--success); margin-top: 3px; }
          </style>
        </head>
        <body>
          <div class="container">
            <!-- Screen 1: Begrüßung & Name -->
            <div id="screen-intro" class="screen active">
              <div class="header">
                <div class="badge">🇬🇧 Grundschule Englisch-Test 🇩🇪</div>
                <h1>Class \(classNum) Unit \(unitNum)</h1>
                <div class="subtitle">„\(title)“</div>
              </div>

              <div class="input-group">
                <label for="student-name">Wie heißt du? (Vorname & Klasse):</label>
                <input type="text" id="student-name" placeholder="z. B. Max, 3b" autocomplete="off" autocapitalize="words">
              </div>

              <button class="btn btn-primary" onclick="startTest()">Test jetzt starten 🚀</button>
            </div>

            <!-- Screen 2: Testfragen -->
            <div id="screen-test" class="screen">
              <div class="progress-container">
                <span id="student-name-display">Schüler</span>
                <span id="progress-text">Frage 1 von 10</span>
              </div>
              <div class="progress-bar-bg">
                <div id="progress-bar-fill" class="progress-bar-fill"></div>
              </div>

              <div class="question-box">
                <div id="lang-badge" class="lang-badge lang-de">🇩🇪 Deutsch vorgegeben:</div>
                <div id="prompt-word" class="prompt-word">Katze</div>
                <div id="multi-hint" class="multi-solution-hint"></div>
              </div>

              <div class="input-group">
                <label id="input-label" for="answer-input">Deine englische Übersetzung:</label>
                <input type="text" id="answer-input" placeholder="Wort eingeben..." autocomplete="off" autocapitalize="off" spellcheck="false">
              </div>

              <div class="nav-buttons">
                <button class="btn btn-secondary" id="btn-prev" onclick="navigate(-1)">← Zurück</button>
                <button class="btn btn-primary" id="btn-next" onclick="navigate(1)">Weiter →</button>
              </div>

              <div style="margin-top: 16px;">
                <button class="btn btn-success" id="btn-finish" onclick="finishTest()" style="display: none;">Fertig & Test abgeben ✨</button>
              </div>

              <div class="dots-grid" id="dots-grid"></div>
            </div>

            <!-- Screen 3: Auswertung & Ergebnis -->
            <div id="screen-result" class="screen">
              <div class="result-hero">
                <div class="score-circle">
                  <div class="score-num" id="res-score">10/10</div>
                  <div class="score-pct" id="res-pct">100 %</div>
                </div>
                <h1 id="res-congrats">Super gemacht!</h1>
                <div class="subtitle" id="res-subtitle">Hier ist deine Auswertung:</div>
              </div>

              <div class="plant-card" id="plant-card">
                <div class="plant-icon" id="plant-icon">🌻</div>
                <div class="plant-title" id="plant-title">Stufe 4: Blüte</div>
                <div class="plant-text" id="plant-text">Ich habe alles verstanden und kann es anderen zeigen.</div>
              </div>

              <h3 style="margin-bottom: 12px; font-size: 16px;">Deine Vokabeln im Detail:</h3>
              <div class="answer-list" id="answer-list"></div>

              <button class="btn btn-secondary" onclick="resetToStart()" style="margin-top: 10px;">Fertig / Zum Anfang</button>
            </div>
          </div>

          <script>
            let questions = [];
            let answers = {};
            let currentIndex = 0;
            let studentName = "";

            async function startTest() {
              const nameInput = document.getElementById("student-name");
              studentName = nameInput.value.trim();
              if (!studentName) {
                alert("Bitte gib zuerst deinen Namen ein!");
                nameInput.focus();
                return;
              }

              try {
                const res = await fetch("/api/test");
                const data = await res.json();
                questions = data.questions || [];
                if (questions.length === 0) {
                  alert("Der Server hat keine Vokabeln geladen!");
                  return;
                }
                answers = {};
                currentIndex = 0;
                document.getElementById("student-name-display").textContent = studentName;
                buildDots();
                showQuestion(0);
                showScreen("screen-test");
              } catch(e) {
                alert("Fehler beim Laden des Tests: " + e.message);
              }
            }

            function buildDots() {
              const grid = document.getElementById("dots-grid");
              grid.innerHTML = "";
              questions.forEach((q, idx) => {
                const dot = document.createElement("div");
                dot.className = "dot";
                dot.textContent = idx + 1;
                dot.onclick = () => showQuestion(idx);
                grid.appendChild(dot);
              });
            }

            function updateDots() {
              const dots = document.querySelectorAll(".dot");
              dots.forEach((dot, idx) => {
                dot.classList.remove("active");
                const qId = questions[idx].id;
                if (answers[qId] && answers[qId].trim().length > 0) {
                  dot.classList.add("answered");
                } else {
                  dot.classList.remove("answered");
                }
                if (idx === currentIndex) {
                  dot.classList.add("active");
                }
              });
            }

            function showQuestion(index) {
              if (index < 0 || index >= questions.length) return;
              
              // Save current input before switching
              saveCurrentInput();
              currentIndex = index;

              const q = questions[currentIndex];
              document.getElementById("progress-text").textContent = `Frage ${currentIndex + 1} von ${questions.length}`;
              const pct = ((currentIndex + 1) / questions.length) * 100;
              document.getElementById("progress-bar-fill").style.width = pct + "%";

              const badge = document.getElementById("lang-badge");
              const label = document.getElementById("input-label");
              if (q.promptLang === "DE") {
                badge.className = "lang-badge lang-de";
                badge.textContent = "🇩🇪 Deutsch vorgegeben:";
                label.textContent = "Deine englische Übersetzung (🇬🇧):";
              } else {
                badge.className = "lang-badge lang-en";
                badge.textContent = "🇬🇧 Englisch vorgegeben:";
                label.textContent = "Deine deutsche Übersetzung (🇩🇪):";
              }
              document.getElementById("prompt-word").textContent = q.prompt;

              const hintEl = document.getElementById("multi-hint");
              if (q.hasMultipleSolutions) {
                hintEl.style.display = "block";
                hintEl.innerHTML = "💡 <strong>Tipp:</strong> Für diesen Begriff gibt es mehrere richtige Lösungen (durch <code>/</code> getrennt). Du musst <strong>nur eine davon</strong> eingeben! (Beide mit / sind auch erlaubt.)";
              } else if (q.promptHasSlash) {
                hintEl.style.display = "block";
                hintEl.innerHTML = "ℹ️ <strong>Tipp:</strong> Das vorgegebene Wort hat zwei Formen (z. B. Einzahl / Mehrzahl). Gib die passende Übersetzung für eine Form oder beide ein.";
              } else {
                hintEl.style.display = "none";
                hintEl.innerHTML = "";
              }

              const input = document.getElementById("answer-input");
              input.placeholder = q.hasMultipleSolutions ? "Eine der Lösungen (oder beide) eingeben..." : "Wort eingeben...";
              input.value = answers[q.id] || "";
              input.focus();

              // Navigation buttons
              document.getElementById("btn-prev").style.visibility = currentIndex === 0 ? "hidden" : "visible";
              const isLast = currentIndex === questions.length - 1;
              document.getElementById("btn-next").style.display = isLast ? "none" : "block";
              document.getElementById("btn-finish").style.display = isLast ? "block" : "none";

              updateDots();
            }

            function saveCurrentInput() {
              if (questions.length > 0 && currentIndex < questions.length) {
                const q = questions[currentIndex];
                const input = document.getElementById("answer-input");
                answers[q.id] = input.value;
              }
            }

            function navigate(step) {
              saveCurrentInput();
              showQuestion(currentIndex + step);
            }

            // Enter key navigates to next or submits
            document.getElementById("answer-input").addEventListener("keydown", function(e) {
              if (e.key === "Enter") {
                e.preventDefault();
                if (currentIndex < questions.length - 1) {
                  navigate(1);
                } else {
                  finishTest();
                }
              }
            });

            async function finishTest() {
              saveCurrentInput();

              // Check answered count
              let answeredCount = 0;
              questions.forEach(q => {
                if (answers[q.id] && answers[q.id].trim().length > 0) answeredCount++;
              });

              if (answeredCount < questions.length) {
                const diff = questions.length - answeredCount;
                if (!confirm(`Du hast noch ${diff} Vokabel(n) frei gelassen. Möchtest du den Test trotzdem schon abgeben?`)) {
                  return;
                }
              }

              const payload = {
                studentName: studentName,
                answers: questions.map(q => ({
                  pairID: q.id,
                  answer: (answers[q.id] || "").trim()
                }))
              };

              try {
                const res = await fetch("/api/submit", {
                  method: "POST",
                  headers: { "Content-Type": "application/json" },
                  body: JSON.stringify(payload)
                });
                const result = await res.json();
                displayResults(result);
              } catch(e) {
                alert("Fehler beim Übermitteln der Antworten: " + e.message);
              }
            }

            function displayResults(data) {
              document.getElementById("res-score").textContent = `${data.score}/${data.maxScore}`;
              document.getElementById("res-pct").textContent = `${data.percentage} %`;

              const congrats = document.getElementById("res-congrats");
              if (data.percentage >= 90) congrats.textContent = "Fantastisch, " + data.studentName + "! 🌟";
              else if (data.percentage >= 75) congrats.textContent = "Super gemacht, " + data.studentName + "! 👏";
              else if (data.percentage >= 50) congrats.textContent = "Gute Arbeit, " + data.studentName + "! 👍";
              else congrats.textContent = "Kopf hoch, weiter üben! 💪";

              document.getElementById("plant-icon").textContent = data.levelIcon;
              document.getElementById("plant-title").textContent = data.levelName;
              document.getElementById("plant-text").textContent = data.feedbackText;

              const list = document.getElementById("answer-list");
              list.innerHTML = "";
              (data.answers || []).forEach(a => {
                const card = document.createElement("div");
                card.className = "answer-card " + (a.isCorrect ? "correct" : "incorrect");
                
                const icon = document.createElement("div");
                icon.className = "answer-icon";
                icon.textContent = a.isCorrect ? "✅" : "❌";

                const content = document.createElement("div");
                content.className = "answer-content";

                const prompt = document.createElement("div");
                prompt.className = "answer-prompt";
                prompt.textContent = `${a.promptLang === "DE" ? "🇩🇪" : "🇬🇧"} ${a.prompt}`;

                const typed = document.createElement("div");
                typed.className = "answer-typed";
                typed.textContent = "Deine Eingabe: " + (a.studentAnswer ? `„${a.studentAnswer}“` : "(nichts eingegeben)");

                content.appendChild(prompt);
                content.appendChild(typed);

                if (!a.isCorrect) {
                  const exp = document.createElement("div");
                  exp.className = "answer-expected";
                  if (a.expectedAnswer && a.expectedAnswer.includes("/")) {
                    exp.innerHTML = "Richtig wäre z. B.: <strong>" + a.expectedAnswer + "</strong><br><small style='color:#64748b;font-weight:normal;'>(Eine der durch / getrennten Lösungen hätte gereicht)</small>";
                  } else {
                    exp.textContent = "Richtig: " + a.expectedAnswer;
                  }
                  content.appendChild(exp);
                } else if (a.expectedAnswer && a.expectedAnswer.includes("/") && a.studentAnswer && !a.studentAnswer.includes("/")) {
                  const altInfo = document.createElement("div");
                  altInfo.style.fontSize = "12px";
                  altInfo.style.color = "#059669";
                  altInfo.style.marginTop = "3px";
                  altInfo.innerHTML = "✓ Klasse! Alle Möglichkeiten: " + a.expectedAnswer;
                  content.appendChild(altInfo);
                }

                card.appendChild(icon);
                card.appendChild(content);
                list.appendChild(card);
              });

              showScreen("screen-result");
            }

            function resetToStart() {
              document.getElementById("student-name").value = "";
              answers = {};
              showScreen("screen-intro");
            }

            function showScreen(screenId) {
              document.querySelectorAll(".screen").forEach(s => s.classList.remove("active"));
              document.getElementById(screenId).classList.add("active");
              window.scrollTo(0, 0);
            }
          </script>
        </body>
        </html>
        """
    }
}

private final class ServerState: @unchecked Sendable {
    private let lock = NSLock()
    private var unit: VocabularyUnit? = nil
    private var direction: TestDirection = .germanToEnglish
    private var shuffle: Bool = true
    private var results: [StudentTestResult] = []

    func set(unit: VocabularyUnit, direction: TestDirection, shuffle: Bool) {
        lock.lock()
        self.unit = unit
        self.direction = direction
        self.shuffle = shuffle
        self.results = []
        lock.unlock()
    }

    func clear() {
        lock.lock()
        self.results.removeAll()
        lock.unlock()
    }

    func appendResult(_ res: StudentTestResult) {
        lock.lock()
        self.results.append(res)
        lock.unlock()
    }

    func getSnapshot() -> (unit: VocabularyUnit?, direction: TestDirection, shuffle: Bool, results: [StudentTestResult]) {
        lock.lock()
        defer { lock.unlock() }
        return (unit, direction, shuffle, results)
    }
}
