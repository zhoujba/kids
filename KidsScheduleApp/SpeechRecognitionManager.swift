import Foundation
import Speech
import AVFoundation

class SpeechRecognitionManager: ObservableObject {
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var errorMessage = ""
    @Published var hasPermission = false

    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    init() {
        // 完全延迟初始化，避免在应用启动时创建任何音频相关对象
    }
    
    // 请求权限
    func requestPermissions() {
        // 先检查当前权限状态
        let authStatus = SFSpeechRecognizer.authorizationStatus()

        switch authStatus {
        case .authorized:
            // 已授权，直接请求麦克风权限
            DispatchQueue.main.async {
                self.initializeSpeechRecognizer()
                self.requestMicrophonePermission()
            }
        case .notDetermined:
            // 未确定，请求权限
            SFSpeechRecognizer.requestAuthorization { [weak self] newStatus in
                DispatchQueue.main.async {
                    switch newStatus {
                    case .authorized:
                        self?.initializeSpeechRecognizer()
                        self?.requestMicrophonePermission()
                    case .denied, .restricted:
                        self?.hasPermission = false
                        self?.errorMessage = "需要语音识别权限才能使用此功能"
                    case .notDetermined:
                        self?.hasPermission = false
                        self?.errorMessage = "权限状态未确定"
                    @unknown default:
                        self?.hasPermission = false
                        self?.errorMessage = "未知的权限状态"
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.hasPermission = false
                self.errorMessage = "语音识别权限被拒绝，请在设置中开启"
            }
        @unknown default:
            DispatchQueue.main.async {
                self.hasPermission = false
                self.errorMessage = "未知的权限状态"
            }
        }
    }

    private func initializeSpeechRecognizer() {
        guard speechRecognizer == nil else { return }
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    }
    
    private func requestMicrophonePermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                    if !granted {
                        self?.errorMessage = "需要麦克风权限才能录音"
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                    if !granted {
                        self?.errorMessage = "需要麦克风权限才能录音"
                    }
                }
            }
        }
    }
    
    // 开始录音识别
    func startRecording() {
        guard hasPermission else {
            errorMessage = "没有必要的权限"
            return
        }

        // 确保语音识别器已初始化
        if speechRecognizer == nil {
            initializeSpeechRecognizer()
        }

        // 确保音频引擎已初始化
        if audioEngine == nil {
            audioEngine = AVAudioEngine()
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "语音识别不可用"
            return
        }

        guard let engine = audioEngine else {
            errorMessage = "音频引擎初始化失败"
            return
        }
        
        // 停止之前的任务
        stopRecording()
        
        do {
            // 配置音频会话
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // 创建识别请求
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                errorMessage = "无法创建识别请求"
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            // 配置音频引擎
            let inputNode = engine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            // 确保音频引擎已停止并清除之前的 tap
            if engine.isRunning {
                engine.stop()
            }
            inputNode.removeTap(onBus: 0)

            // 安装新的 tap
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak recognitionRequest] buffer, _ in
                recognitionRequest?.append(buffer)
            }

            // 开始音频引擎
            engine.prepare()
            try engine.start()
            
            // 开始识别
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let result = result {
                        self?.recognizedText = result.bestTranscription.formattedString
                        // 如果识别成功，清除错误信息
                        if !result.bestTranscription.formattedString.isEmpty {
                            self?.errorMessage = ""
                        }
                    }

                    // 只有在没有识别到文本且有错误时才显示错误
                    if let error = error {
                        if self?.recognizedText.isEmpty ?? true {
                            self?.errorMessage = "识别错误: \(error.localizedDescription)"
                        }
                        self?.stopRecording()
                    }
                }
            }
            
            isRecording = true
            errorMessage = ""
            
        } catch {
            errorMessage = "录音启动失败: \(error.localizedDescription)"
            // 确保清理状态
            if let audioEngine = self.audioEngine {
                if audioEngine.isRunning {
                    audioEngine.stop()
                }
                audioEngine.inputNode.removeTap(onBus: 0)
            }
        }
    }
    
    // 停止录音识别
    func stopRecording() {
        // 停止音频引擎
        if let audioEngine = audioEngine, audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // 结束识别请求
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // 取消识别任务
        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false

        // 重置音频会话
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("音频会话重置失败: \(error)")
        }
    }
    
    // 清除识别结果
    func clearText() {
        recognizedText = ""
        errorMessage = ""
    }
}
