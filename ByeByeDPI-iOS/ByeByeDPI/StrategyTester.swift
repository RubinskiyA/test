//
//  StrategyTester.swift
//  ByeByeDPI
//
//  Created for testing DPI bypass strategies on iOS
//

import Foundation
import NetworkExtension

/// Результат теста стратегии
struct StrategyTestResult: Identifiable {
    let id = UUID()
    let strategyName: String
    let parameters: [String: String]
    let success: Bool
    let latencyMs: Double?
    let errorMessage: String?
    
    var displayText: String {
        if success {
            if let latency = latencyMs {
                return "✅ \(strategyName) (\(Int(latency))ms)"
            }
            return "✅ \(strategyName)"
        } else {
            return "❌ \(strategyName)" + (errorMessage != nil ? ": \(errorMessage!)" : "")
        }
    }
}

/// Менеджер для автоматического определения лучшей стратегии обхода DPI
class StrategyTester: ObservableObject {
    @Published var isTesting = false
    @Published var currentTestIndex = 0
    @Published var totalTests = 0
    @Published var results: [StrategyTestResult] = []
    @Published var bestStrategy: StrategyTestResult?
    @Published var progress: Double = 0.0
    
    private let testHost = "www.google.com"
    private let testPort = 443
    private let timeout: TimeInterval = 5.0
    
    /// Список стратегий для тестирования
    private let strategiesToTest: [(name: String, args: [String])] = [
        // Базовые тесты без модификаций
        ("No modification", []),
        
        // Десинхронизация TTL
        ("Desync TTL=1", ["-1"]),
        ("Desync TTL=2", ["-2"]),
        ("Desync TTL=3", ["-3"]),
        ("Desync TTL=5", ["-5"]),
        ("Desync TTL=10", ["-10"]),
        
        // Фальшивые пакеты
        ("Fake TLS record", ["--fake-tls"]),
        ("Fake HTTP request", ["--fake-http"]),
        ("Fake with TTL=1", ["--fake-tls", "-1"]),
        ("Fake with TTL=2", ["--fake-tls", "-2"]),
        
        // Разделение пакетов
        ("Split at 1", ["-s", "1"]),
        ("Split at 2", ["-s", "2"]),
        ("Split at 3", ["-s", "3"]),
        ("Split at 5", ["-s", "5"]),
        ("Split at 10", ["-s", "10"]),
        
        // Комбинированные стратегии
        ("Desync+Split", ["-1", "-s", "2"]),
        ("Desync+Fake", ["-2", "--fake-tls"]),
        ("All together", ["-1", "-s", "2", "--fake-tls"]),
        
        // OOO (Out-of-Order) пакеты
        ("OOO offset 1", ["--ooo", "1"]),
        ("OOO offset 2", ["--ooo", "2"]),
        ("OOO+TTL", ["--ooo", "1", "-1"]),
        
        // Специфичные для некоторых провайдеров
        ("Disable SNI", ["--no-sni"]),
        ("Fake SNI", ["--fake-sni"]),
    ]
    
    /// Запустить тестирование всех стратегий
    func startTesting() async {
        await MainActor.run {
            self.isTesting = true
            self.results = []
            self.currentTestIndex = 0
            self.totalTests = strategiesToTest.count
            self.bestStrategy = nil
            self.progress = 0.0
        }
        
        var successfulStrategies: [StrategyTestResult] = []
        
        for (index, strategy) in strategiesToTest.enumerated() {
            await MainActor.run {
                self.currentTestIndex = index + 1
                self.progress = Double(index) / Double(strategiesToTest.count)
            }
            
            print("🧪 Testing strategy: \(strategy.name)")
            
            let result = await testStrategy(name: strategy.name, args: strategy.args)
            
            await MainActor.run {
                self.results.append(result)
                
                if result.success {
                    successfulStrategies.append(result)
                    
                    // Обновляем лучшую стратегию (минимальная задержка)
                    if let currentBest = self.bestStrategy {
                        if let newLatency = result.latencyMs,
                           let bestLatency = currentBest.latencyMs {
                            if newLatency < bestLatency {
                                self.bestStrategy = result
                            }
                        } else if self.bestStrategy == nil {
                            self.bestStrategy = result
                        }
                    } else {
                        self.bestStrategy = result
                    }
                }
            }
        }
        
        await MainActor.run {
            self.isTesting = false
            self.progress = 1.0
            print("✅ Testing completed. Best strategy: \(self.bestStrategy?.strategyName ?? "None found")")
        }
    }
    
    /// Тестирование конкретной стратегии
    private func testStrategy(name: String, args: [String]) async -> StrategyTestResult {
        let startTime = Date()
        
        do {
            // Попытка подключения с использованием byedpi
            let success = try await connectWithStrategy(args: args)
            let latency = Date().timeIntervalSince(startTime) * 1000 // в миллисекундах
            
            if success {
                return StrategyTestResult(
                    strategyName: name,
                    parameters: args.reduce(into: [:]) { dict, arg in
                        dict[arg] = "enabled"
                    },
                    success: true,
                    latencyMs: latency,
                    errorMessage: nil
                )
            } else {
                return StrategyTestResult(
                    strategyName: name,
                    parameters: [:],
                    success: false,
                    latencyMs: nil,
                    errorMessage: "Connection failed"
                )
            }
        } catch {
            return StrategyTestResult(
                strategyName: name,
                parameters: [:],
                success: false,
                latencyMs: nil,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    /// Подключение с использованием конкретной стратегии byedpi
    private func connectWithStrategy(args: [String]) async throws -> Bool {
        // Создаем C-аргументы для byedpi
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Подготовка аргументов для C функции
                let allArgs = ["byedpi"] + args + ["-t", self.testHost, "-p", "\(self.testPort)", "--test"]
                
                let cArgs = allArgs.map { strdup($0) }
                let argv: [UnsafeMutablePointer<CChar>?] = cArgs + [nil]
                
                // Вызов C функции тестирования
                // Примечание: эта функция должна быть реализована в ByeDpiProxy.c
                let result = test_byedpi_strategy(argv, Int32(argv.count - 1))
                
                // Освобождение памяти
                cArgs.forEach { free($0) }
                
                continuation.resume(returning: result == 0)
            }
        }
    }
    
    /// Сохранить лучшую стратегию в настройки
    func saveBestStrategy(to settingsManager: SettingsManager) {
        guard let best = bestStrategy else { return }
        
        // Парсим параметры из названия стратегии или используем preset
        var preset = ByedpiPreset.custom
        
        // Простая эвристика для определения пресета
        if best.strategyName.contains("TTL=1") || best.strategyName.contains("TTL=1,") {
            preset = .desync
        } else if best.strategyName.contains("Fake") {
            preset = .fake
        } else if best.strategyName.contains("Split") {
            preset = .split
        } else if best.strategyName.contains("OOO") {
            preset = .ooo
        } else if best.strategyName.contains("No modification") {
            preset = .none
        }
        
        settingsManager.selectedPreset = preset
        settingsManager.save()
        
        print("💾 Saved best strategy: \(preset.rawValue)")
    }
    
    /// Сброс результатов
    func reset() {
        isTesting = false
        currentTestIndex = 0
        totalTests = 0
        results = []
        bestStrategy = nil
        progress = 0.0
    }
}

// MARK: - C Bridge Function Declaration
// Эта функция должна быть реализована в ByeDpiProxy.c
@_silgen_name("test_byedpi_strategy")
func test_byedpi_strategy(_ argv: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?, _ argc: Int32) -> Int32
