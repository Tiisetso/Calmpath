//
//  ContentView.swift
//  Calmpath
//
//  Created by Tiisetso Daniel Murray on 2025/11/15.
//

import SwiftUI
import Combine
import SwiftData
import HealthKit
import WeatherKit
import CoreLocation
import UIKit
import CoreMotion

// MARK: - Models

@Model
final class MigraineLog {
    var timestamp: Date
    var intensity: Double // 0.0 to 1.0
    var stepCount: Int
    var temperature: Double // in Celsius
    var pressure: Double? // in hPa (millibars)
    var humidity: Double? // 0.0 - 1.0 fraction
    var weatherCondition: String? // e.g., clear, rain, cloudy
    // var moonPhase: String? // e.g., waxingGibbous
    var sleepStart: Date?
    var sleepEnd: Date?
    var sleepDuration: Double? // seconds
    var movementState: String? // stationary, walking, running, cycling, automotive, unknown
    var movementConfidence: Int? // 0=low, 1=medium, 2=high
    
    init(
        timestamp: Date,
        intensity: Double = 0.5,
        stepCount: Int = 0,
        temperature: Double = 0.0,
        pressure: Double? = nil,
        humidity: Double? = nil,
        weatherCondition: String? = nil,
        // moonPhase: String? = nil,
        sleepStart: Date? = nil,
        sleepEnd: Date? = nil,
        sleepDuration: Double? = nil,
        movementState: String? = nil,
        movementConfidence: Int? = nil
    ) {
        self.timestamp = timestamp
        self.intensity = intensity
        self.stepCount = stepCount
        self.temperature = temperature
        self.pressure = pressure
        self.humidity = humidity
        self.weatherCondition = weatherCondition
        // self.moonPhase = moonPhase
        self.sleepStart = sleepStart
        self.sleepEnd = sleepEnd
        self.sleepDuration = sleepDuration
        self.movementState = movementState
        self.movementConfidence = movementConfidence
    }
}

// MARK: - Managers

@MainActor
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let typesToRead: Set<HKObjectType> = [stepType, sleepType]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }
    
    func fetchTodayStepCount() async throws -> Int {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let sum = result?.sumQuantity()
                let steps = Int(sum?.doubleValue(for: HKUnit.count()) ?? 0)
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
    }
    
    func ensureAuthorizationForSteps() async throws {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let requestStatus = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKAuthorizationRequestStatus, Error>) in
            healthStore.getRequestStatusForAuthorization(toShare: [], read: [stepType]) { status, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }
        switch requestStatus {
        case .shouldRequest, .unknown:
            try await requestAuthorization()
        case .unnecessary:
            break
        @unknown default:
            try await requestAuthorization()
        }
    }
    
    func ensureAuthorizationForHealthData() async throws {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let requestStatus = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKAuthorizationRequestStatus, Error>) in
            healthStore.getRequestStatusForAuthorization(toShare: [], read: [stepType, sleepType]) { status, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }
        switch requestStatus {
        case .shouldRequest, .unknown:
            try await requestAuthorization()
        case .unnecessary:
            break
        @unknown default:
            try await requestAuthorization()
        }
    }
    
    func fetchLastSleepPeriod() async throws -> (start: Date, end: Date, duration: TimeInterval)? {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let now = Date()
        // Look back 36 hours to capture the most recent main sleep session
        let lookback = now.addingTimeInterval(-36 * 3600)
        let predicate = HKQuery.predicateForSamples(withStart: lookback, end: now, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let categorySamples = samples as? [HKCategorySample], !categorySamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let asleepRawValues: Set<Int>
                if #available(iOS 16.0, *) {
                    asleepRawValues = Set([
                        HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                        HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                        HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                        HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    ])
                } else {
                    asleepRawValues = Set([HKCategoryValueSleepAnalysis.asleep.rawValue])
                }

                let asleepSegments = categorySamples
                    .filter { asleepRawValues.contains($0.value) }
                    .map { ($0.startDate, $0.endDate) }
                    .sorted { $0.0 < $1.0 }

                guard !asleepSegments.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Merge contiguous/overlapping asleep segments into sessions with a small gap tolerance
                let gap: TimeInterval = 30 * 60 // 30 minutes tolerance between segments
                var sessions: [[(Date, Date)]] = []
                var current: [(Date, Date)] = []

                for seg in asleepSegments {
                    if let last = current.last {
                        if seg.0 <= last.1.addingTimeInterval(gap) {
                            current.append(seg)
                        } else {
                            if !current.isEmpty { sessions.append(current) }
                            current = [seg]
                        }
                    } else {
                        current = [seg]
                    }
                }
                if !current.isEmpty { sessions.append(current) }

                struct SessionInfo { let start: Date; let end: Date; let total: TimeInterval }
                let infos: [SessionInfo] = sessions.map { segs in
                    let start = segs.first!.0
                    let end = segs.last!.1
                    let total = segs.reduce(0) { $0 + $1.1.timeIntervalSince($1.0) }
                    return SessionInfo(start: start, end: end, total: total)
                }

                guard let best = infos.max(by: { a, b in
                    if a.total == b.total { return a.end < b.end } // tie-break by recency
                    return a.total < b.total
                }) else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: (best.start, best.end, best.total))
            }
            self.healthStore.execute(query)
        }
    }
}

enum HealthKitError: Error {
    case notAvailable
    case authorizationFailed
}

@MainActor
class WeatherManager: ObservableObject {
    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    private var locationAuthDelegate: LocationDelegate?
    private var locationUpdateDelegate: LocationDelegate?
    
    private class LocationDelegate: NSObject, CLLocationManagerDelegate {
        var authChanged: ((CLAuthorizationStatus) -> Void)?
        var locationReceived: ((CLLocation) -> Void)?
        var locationFailed: ((Error) -> Void)?

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            if #available(iOS 14.0, *) {
                authChanged?(manager.authorizationStatus)
            } else {
                authChanged?(CLLocationManager.authorizationStatus())
            }
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let loc = locations.last {
                locationReceived?(loc)
            }
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            locationFailed?(error)
        }
    }
    
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func currentAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    func ensureLocationAuthorization() async -> Bool {
        let status = currentAuthorizationStatus()
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                let delegate = LocationDelegate()
                delegate.authChanged = { newStatus in
                    if newStatus != .notDetermined {
                        self.locationAuthDelegate = nil
                        continuation.resume(returning: newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways)
                    }
                }
                self.locationAuthDelegate = delegate
                self.locationManager.delegate = delegate
                self.locationManager.requestWhenInUseAuthorization()
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func requestOneLocation(timeout: TimeInterval = 5) async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = LocationDelegate()
            delegate.locationReceived = { loc in
                self.locationUpdateDelegate = nil
                continuation.resume(returning: loc)
            }
            delegate.locationFailed = { error in
                self.locationUpdateDelegate = nil
                continuation.resume(throwing: error)
            }
            self.locationUpdateDelegate = delegate
            self.locationManager.delegate = delegate
            self.locationManager.requestLocation()
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                if self.locationUpdateDelegate != nil {
                    self.locationUpdateDelegate = nil
                    continuation.resume(throwing: WeatherError.locationNotAvailable)
                }
            }
        }
    }
    
    func fetchCurrentTemperature() async throws -> Double {
        if currentAuthorizationStatus() == .notDetermined {
            _ = await ensureLocationAuthorization()
        }
        var location = locationManager.location
        if location == nil {
            // Try to request a single location fix
            location = try? await requestOneLocation()
        }
        guard let resolvedLocation = location else {
            throw WeatherError.locationNotAvailable
        }
        let weather = try await weatherService.weather(for: resolvedLocation)
        return weather.currentWeather.temperature.value
    }
    
    func fetchCurrentWeatherBundle() async throws -> (temperature: Double, humidity: Double?, condition: String?) {
        if currentAuthorizationStatus() == .notDetermined {
            _ = await ensureLocationAuthorization()
        }
        var location = locationManager.location
        if location == nil {
            location = try? await requestOneLocation()
        }
        guard let resolvedLocation = location else {
            throw WeatherError.locationNotAvailable
        }
        let weather = try await weatherService.weather(for: resolvedLocation)
        let temp = weather.currentWeather.temperature.value
        // Current humidity is a fraction 0.0 - 1.0
        let hum = weather.currentWeather.humidity
        // Weather condition as string
        let cond = String(describing: weather.currentWeather.condition)
        // var moon: String? = nil
        // if #available(iOS 16.0, *) {
        //     if let astronomy = try? await weatherService.astronomy(for: resolvedLocation, date: Date()) {
        //         moon = String(describing: astronomy.moonPhase)
        //     }
        // }
        // return (temp, hum, cond, moon)
        return (temp, hum, cond)
    }
    
    // Test WeatherKit independently of device location to diagnose entitlement/JWT issues
    func testWeatherKitConnectivity() async -> Error? {
        let cupertino = CLLocation(latitude: 37.3349, longitude: -122.0090)
        do {
            let weather = try await weatherService.weather(for: cupertino)
            _ = weather.currentWeather.temperature.value
            return nil
        } catch {
            return error
        }
    }

    func isLikelyJWTError(_ error: Error) -> Bool {
        let ns = error as NSError
        return ns.domain.contains("WeatherDaemon.WDSJWTAuthenticatorServiceListener.Errors")
    }
}

enum WeatherError: Error {
    case locationNotAvailable
    case weatherDataUnavailable
}

enum BarometerError: Error {
    case notAvailable
    case noSample
}

@MainActor
final class BarometerManager: ObservableObject {
    private let altimeter = CMAltimeter()

    func fetchCurrentPressure_hPa() async throws -> Double {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            throw BarometerError.notAvailable
        }
        return try await withCheckedThrowingContinuation { continuation in
            altimeter.startRelativeAltitudeUpdates(to: .main) { data, error in
                if let error = error {
                    self.altimeter.stopRelativeAltitudeUpdates()
                    continuation.resume(throwing: error)
                    return
                }
                guard let pressureKPa = data?.pressure.doubleValue else {
                    self.altimeter.stopRelativeAltitudeUpdates()
                    continuation.resume(throwing: BarometerError.noSample)
                    return
                }
                self.altimeter.stopRelativeAltitudeUpdates()
                let hPa = pressureKPa * 10.0 // 1 kPa = 10 hPa (mbar)
                continuation.resume(returning: hPa)
            }
        }
    }
}

@MainActor
final class MovementManager: ObservableObject {
    private let activityManager = CMMotionActivityManager()

    func ensureMotionAuthorization() async -> Bool {
        if #available(iOS 11.0, *) {
            let status = CMMotionActivityManager.authorizationStatus()
            switch status {
            case .authorized:
                return true
            case .denied, .restricted:
                return false
            case .notDetermined:
                return await withCheckedContinuation { continuation in
                    activityManager.startActivityUpdates(to: .main) { _ in
                        self.activityManager.stopActivityUpdates()
                        let newStatus = CMMotionActivityManager.authorizationStatus()
                        continuation.resume(returning: newStatus == .authorized)
                    }
                }
            @unknown default:
                return false
            }
        } else {
            // Fallback: attempt to start/stop updates
            activityManager.startActivityUpdates(to: .main) { _ in
                self.activityManager.stopActivityUpdates()
            }
            return true
        }
    }

    func fetchCurrentMovementState() async -> (state: String, confidence: Int)? {
        return await withCheckedContinuation { continuation in
            let from = Date().addingTimeInterval(-300)
            activityManager.queryActivityStarting(from: from, to: Date(), to: .main) { activities, error in
                guard error == nil, let activities = activities, let last = activities.last else {
                    continuation.resume(returning: nil)
                    return
                }
                let state: String
                if last.automotive { state = "automotive" }
                else if last.cycling { state = "cycling" }
                else if last.running { state = "running" }
                else if last.walking { state = "walking" }
                else if last.stationary { state = "stationary" }
                else { state = "unknown" }

                let confidence: Int
                switch last.confidence {
                case .low: confidence = 0
                case .medium: confidence = 1
                case .high: confidence = 2
                @unknown default: confidence = 0
                }
                continuation.resume(returning: (state, confidence))
            }
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var weatherManager = WeatherManager()
    @StateObject private var barometerManager = BarometerManager()
    @StateObject private var movementManager = MovementManager()
    
    @State private var showingIntensitySlider = false
    @State private var intensity: Double = 0.5
    @State private var isLoggingMigraine = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPermissionsAlert = false
    @State private var permissionsMessage = ""
    @State private var showOpenSettings = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top half with the button
                ZStack {
                    Circle()
                        .fill(Color(red: 0.53, green: 0.81, blue: 0.92)) // Sky blue
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                
                                Text("Log Migraine")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                .frame(height: geometry.size.height / 2)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isLoggingMigraine { return }
                    Task { await ensurePermissionsAndQuickLog() }
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    if isLoggingMigraine { return }
                    Task { await ensurePermissionsAndMaybePresentSlider() }
                }
                .opacity(isLoggingMigraine ? 0.6 : 1.0)
                
                // Bottom half
                Spacer()
            }
        }
        .navigationTitle("Calmpath")
        .sheet(isPresented: $showingIntensitySlider) {
            IntensitySliderView(
                intensity: $intensity,
                onSave: {
                    Task {
                        await logMigraine()
                    }
                    showingIntensitySlider = false
                }
            )
            .presentationDetents([.medium])
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Permissions Required", isPresented: $showPermissionsAlert) {
            if showOpenSettings {
                Button("Open Settings") { openAppSettings() }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(permissionsMessage)
        }
        .task {
            await requestPermissions()
        }
    }
    
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func ensurePermissionsAndQuickLog() async {
        // Allow quick logging in previews without permissions
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            await logMigraine()
            return
        }

        // Ensure HealthKit authorization is available
        do {
            try await healthKitManager.ensureAuthorizationForHealthData()
        } catch {
            permissionsMessage = "Health permissions are required to read your step count. Open the Health app and enable Steps for Calmpath under Apps."
            showOpenSettings = false
            showPermissionsAlert = true
            return
        }

        let locationAuthorized = await weatherManager.ensureLocationAuthorization()
        if !locationAuthorized {
            permissionsMessage = "Location access is denied. To enable weather features, allow location access in Settings."
            showOpenSettings = true
            showPermissionsAlert = true
            return
        }
        
        let motionAuthorized = await movementManager.ensureMotionAuthorization()
        if !motionAuthorized {
            permissionsMessage = "Motion & Fitness access is denied. To log movement state, enable Motion & Fitness in Settings."
            showOpenSettings = true
            showPermissionsAlert = true
            // Continue without movement state
        }
        
        if let wkError = await weatherManager.testWeatherKitConnectivity(), weatherManager.isLikelyJWTError(wkError) {
            permissionsMessage = "WeatherKit isn’t authorized for this build (JWT failed). Try uninstalling the app, cleaning the build, and ensure the WeatherKit capability is enabled for the exact bundle identifier and signing team, then run again."
            showOpenSettings = false
            showPermissionsAlert = true
            // Continue to log with fallback temperature so the user isn’t blocked
        }

        // All good – perform a quick log with current intensity
        await logMigraine()
    }
    
    private func ensurePermissionsAndMaybePresentSlider() async {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            showingIntensitySlider = true
            return
        }

        // Ensure HealthKit authorization is requested again if needed
        do {
            try await healthKitManager.ensureAuthorizationForHealthData()
        } catch {
            permissionsMessage = "Health permissions are required to read your step count. Open the Health app and enable Steps for Calmpath under Apps."
            showOpenSettings = false
            showPermissionsAlert = true
            return
        }

        let locationAuthorized = await weatherManager.ensureLocationAuthorization()
        if !locationAuthorized {
            permissionsMessage = "Location access is denied. To enable weather features, allow location access in Settings."
            showOpenSettings = true
            showPermissionsAlert = true
            return
        }
        
        let motionAuthorized = await movementManager.ensureMotionAuthorization()
        if !motionAuthorized {
            permissionsMessage = "Motion & Fitness access is denied. To log movement state, enable Motion & Fitness in Settings."
            showOpenSettings = true
            showPermissionsAlert = true
            // Continue to allow the user to provide more info; logging will still fall back on temperature
        }
        
        if let wkError = await weatherManager.testWeatherKitConnectivity(), weatherManager.isLikelyJWTError(wkError) {
            permissionsMessage = "WeatherKit isn’t authorized for this build (JWT failed). Try uninstalling the app, cleaning the build, and ensure the WeatherKit capability is enabled for the exact bundle identifier and signing team, then run again."
            showOpenSettings = false
            showPermissionsAlert = true
            // Continue to allow the user to provide more info; logging will still fall back on temperature
        }

        // All good – proceed to show the intensity slider
        showingIntensitySlider = true
    }
    
    private func requestPermissions() async {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        let missing = missingPrivacyUsageDescriptions()
        guard missing.isEmpty else {
            errorMessage = "Missing required Info.plist keys: \(missing.joined(separator: ", ")). Please add them in your target's Info."
            showError = true
            return
        }
        do {
            try await healthKitManager.requestAuthorization()
            weatherManager.requestLocationAuthorization()
        } catch {
            errorMessage = "Failed to request permissions: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func missingPrivacyUsageDescriptions() -> [String] {
        var missing: [String] = []
        let bundle = Bundle.main

        func hasNonEmptyString(for key: String) -> Bool {
            guard let value = bundle.object(forInfoDictionaryKey: key) as? String else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        if !hasNonEmptyString(for: "NSHealthShareUsageDescription") {
            missing.append("NSHealthShareUsageDescription")
        }
        if !hasNonEmptyString(for: "NSLocationWhenInUseUsageDescription") {
            missing.append("NSLocationWhenInUseUsageDescription")
        }
        if !hasNonEmptyString(for: "NSMotionUsageDescription") {
            missing.append("NSMotionUsageDescription")
        }
        return missing
    }
    
    private func logMigraine() async {
        isLoggingMigraine = true
        defer { isLoggingMigraine = false }
        
        do {
            let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            
            let stepCount: Int
            let temperature: Double
            let pressure: Double?
            let humidity: Double?
            let weatherCondition: String?
            // let moonPhase: String?
            let sleepStart: Date?
            let sleepEnd: Date?
            let sleepDuration: Double?
            let movementState: String?
            let movementConfidence: Int?
            
            if isPreview {
                // Mock data for previews
                stepCount = 1234
                temperature = 21.0
                pressure = 1013.2
                humidity = 0.55
                weatherCondition = "clear"
                // moonPhase = "waxingGibbous"
                let now = Date()
                sleepEnd = now
                sleepStart = Calendar.current.date(byAdding: .hour, value: -7, to: now)
                sleepDuration = sleepStart != nil ? now.timeIntervalSince(sleepStart!) : nil
                movementState = "stationary"
                movementConfidence = 2
            } else {
                // Fallbacks if sensors/services are unavailable or fail
                stepCount = (try? await healthKitManager.fetchTodayStepCount()) ?? 0
                if let bundle = try? await weatherManager.fetchCurrentWeatherBundle() {
                    temperature = bundle.temperature
                    humidity = bundle.humidity
                    weatherCondition = bundle.condition
                    // moonPhase = bundle.moonPhase
                } else {
                    temperature = .nan
                    humidity = nil
                    weatherCondition = nil
                    // moonPhase = nil
                }
                pressure = (try? await barometerManager.fetchCurrentPressure_hPa())
                if let sleep = try? await healthKitManager.fetchLastSleepPeriod() {
                    sleepStart = sleep.start
                    sleepEnd = sleep.end
                    sleepDuration = sleep.duration
                } else {
                    sleepStart = nil
                    sleepEnd = nil
                    sleepDuration = nil
                }
                // Motion state
                let motionOK = await movementManager.ensureMotionAuthorization()
                if motionOK, let act = await movementManager.fetchCurrentMovementState() {
                    movementState = act.state
                    movementConfidence = act.confidence
                } else {
                    movementState = nil
                    movementConfidence = nil
                }
            }
            
            // Create migraine log
            let log = MigraineLog(
                timestamp: Date(),
                intensity: intensity,
                stepCount: stepCount,
                temperature: temperature,
                pressure: pressure,
                humidity: humidity,
                weatherCondition: weatherCondition,
                // moonPhase: moonPhase,
                sleepStart: sleepStart,
                sleepEnd: sleepEnd,
                sleepDuration: sleepDuration,
                movementState: movementState,
                movementConfidence: movementConfidence
            )
            
            modelContext.insert(log)
            try modelContext.save()
            
            // Reset intensity for next time
            intensity = 0.5
            
        } catch {
            errorMessage = "Failed to log migraine: \(error.localizedDescription)"
            showError = true
        }
    }
}

struct IntensitySliderView: View {
    @Binding var intensity: Double
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text("Migraine Intensity")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(intensityDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    // Intensity indicator
                    ZStack {
                        Circle()
                            .fill(intensityColor.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .fill(intensityColor)
                            .frame(width: 80, height: 80)
                        
                        Text("\(Int(intensity * 10))")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "speaker.wave.1.fill")
                                .foregroundColor(.secondary)
                            
                            Slider(value: $intensity, in: 0...1)
                                .tint(intensityColor)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Mild")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Severe")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button(action: onSave) {
                    Text("Save Migraine Log")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(red: 0.53, green: 0.81, blue: 0.92))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var intensityDescription: String {
        switch intensity {
        case 0..<0.2:
            return "Very Mild"
        case 0.2..<0.4:
            return "Mild"
        case 0.4..<0.6:
            return "Moderate"
        case 0.6..<0.8:
            return "Severe"
        default:
            return "Very Severe"
        }
    }
    
    private var intensityColor: Color {
        switch intensity {
        case 0..<0.3:
            return .green
        case 0.3..<0.5:
            return .yellow
        case 0.5..<0.7:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Logs View

struct LogsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MigraineLog.timestamp, order: .reverse) private var logs: [MigraineLog]
    
    var body: some View {
        NavigationStack {
            List {
                if logs.isEmpty {
                    ContentUnavailableView {
                        Label("No Migraine Logs", systemImage: "brain.head.profile")
                    } description: {
                        Text("Tap the button on the Home tab to log a migraine.")
                    }
                } else {
                    ForEach(logs) { log in
                        NavigationLink {
                            MigraineDetailView(log: log)
                        } label: {
                            MigraineLogRow(log: log)
                        }
                    }
                    .onDelete(perform: deleteLogs)
                }
            }
            .navigationTitle("Logs")
            .toolbar {
                if !logs.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
        }
    }
    
    private func deleteLogs(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(logs[index])
            }
        }
    }
}

struct MigraineLogRow: View {
    let log: MigraineLog
    
    var body: some View {
        HStack(spacing: 16) {
            // Intensity indicator circle
            ZStack {
                Circle()
                    .fill(intensityColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Circle()
                    .fill(intensityColor)
                    .frame(width: 40, height: 40)
                
                Text("\(Int(log.intensity * 10))")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(log.timestamp, style: .date)
                    .font(.headline)
                
                Text(log.timestamp, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Label("\(log.stepCount)", systemImage: "figure.walk")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let duration = log.sleepDuration {
                        let hours = duration / 3600.0
                        Label(String(format: "%.1fh", hours), systemImage: "bed.double.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let cond = log.weatherCondition {
                        Image(systemName: weatherSymbol(for: cond))
                            .foregroundColor(.secondary)
                            .imageScale(.small)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var intensityColor: Color {
        switch log.intensity {
        case 0..<0.3:
            return .green
        case 0.3..<0.5:
            return .yellow
        case 0.5..<0.7:
            return .orange
        default:
            return .red
        }
    }
    
    private func weatherSymbol(for condition: String) -> String {
        let c = condition.lowercased()
        if c.contains("thunder") { return "cloud.bolt.rain.fill" }
        if c.contains("rain") || c.contains("shower") { return "cloud.rain.fill" }
        if c.contains("snow") || c.contains("sleet") { return "cloud.snow.fill" }
        if c.contains("fog") || c.contains("haze") { return "cloud.fog.fill" }
        if c.contains("wind") { return "wind" }
        if c.contains("cloud") { return "cloud.fill" }
        if c.contains("clear") || c.contains("sun") { return "sun.max.fill" }
        return "cloud.sun.fill"
    }
}

struct MigraineDetailView: View {
    let log: MigraineLog
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Date")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(log.timestamp, style: .date)
                }
                
                HStack {
                    Text("Time")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(log.timestamp, style: .time)
                }
            }
            
            Section("Intensity") {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(intensityColor.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .fill(intensityColor)
                            .frame(width: 80, height: 80)
                        
                        Text("\(Int(log.intensity * 10))")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Text(intensityDescription)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    
                    HStack {
                        Text("Mild")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(intensityColor)
                                    .frame(width: geometry.size.width * log.intensity, height: 4)
                            }
                        }
                        .frame(height: 4)
                        
                        Text("Severe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Health Data") {
                HStack {
                    Label("Steps Today", systemImage: "figure.walk")
                    Spacer()
                    Text("\(log.stepCount)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Temperature", systemImage: "thermometer")
                    Spacer()
                    Text(String(format: "%.1f°C", log.temperature))
                        .foregroundColor(.secondary)
                }
                
                if let pressure = log.pressure {
                    HStack {
                        Label("Pressure", systemImage: "gauge")
                        Spacer()
                        Text(String(format: "%.1f hPa", pressure))
                            .foregroundColor(.secondary)
                    }
                }
                if let h = log.humidity {
                    HStack {
                        Label("Humidity", systemImage: "humidity")
                        Spacer()
                        Text(String(format: "%.0f%%", h * 100))
                            .foregroundColor(.secondary)
                    }
                }
                if let cond = log.weatherCondition {
                    HStack {
                        Label("Conditions", systemImage: "cloud.sun")
                        Spacer()
                        Text(cond.replacingOccurrences(of: "_", with: " ").capitalized)
                            .foregroundColor(.secondary)
                    }
                }
                /*
                if let moon = log.moonPhase {
                    HStack {
                        Label("Moon Phase", systemImage: "moonphase.waxing.gibbous")
                        Spacer()
                        Text(moon.replacingOccurrences(of: "_", with: " ").capitalized)
                            .foregroundColor(.secondary)
                    }
                }
                */
                
                if let state = log.movementState {
                    HStack {
                        Label("Movement", systemImage: "figure.walk")
                        Spacer()
                        Text(state.capitalized)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Sleep") {
                if let start = log.sleepStart, let end = log.sleepEnd, let duration = log.sleepDuration {
                    HStack {
                        Label("Bedtime", systemImage: "bed.double.fill")
                        Spacer()
                        Text(start, style: .time)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Wake", systemImage: "alarm")
                        Spacer()
                        Text(end, style: .time)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Total Sleep", systemImage: "clock")
                        Spacer()
                        let hours = duration / 3600.0
                        Text(String(format: "%.1f hours", hours))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No recent sleep data available")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Migraine Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var intensityDescription: String {
        switch log.intensity {
        case 0..<0.2:
            return "Very Mild"
        case 0.2..<0.4:
            return "Mild"
        case 0.4..<0.6:
            return "Moderate"
        case 0.6..<0.8:
            return "Severe"
        default:
            return "Very Severe"
        }
    }
    
    private var intensityColor: Color {
        switch log.intensity {
        case 0..<0.3:
            return .green
        case 0.3..<0.5:
            return .yellow
        case 0.5..<0.7:
            return .orange
        default:
            return .red
        }
    }
}

// Inserted MeView here before Main Content View marker
struct MeView: View {
    @Query private var logs: [MigraineLog]
    @State private var showingSettings = false

    private var averageIntensity: Double? {
        guard !logs.isEmpty else { return nil }
        let sum = logs.reduce(0.0) { $0 + $1.intensity }
        return sum / Double(logs.count)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                VStack {
                    HStack(alignment: .top, spacing: 12) {
                        // Recorded Migraines card (left)
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(red: 0.53, green: 0.81, blue: 0.92))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            VStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(.white)
                                    Text("Recorded Migraines")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .layoutPriority(1)
                                }
                                Text("\(logs.count)")
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(24)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)

                        // Average Intensity card (right)
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(red: 0.53, green: 0.81, blue: 0.92))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            VStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "gauge")
                                        .foregroundColor(.white)
                                    Text("Average Intensity")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .layoutPriority(1)
                                }
                                Text(averageIntensity.map { String(format: "%.1f", $0 * 10) } ?? "—")
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(24)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                    }
                    Spacer()
                }
                .padding()
                .navigationTitle("Me")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                        .accessibilityLabel("Settings")
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
            }
        }
    }
}

struct SettingsView: View {
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    HStack {
                        Text("Build Number")
                        Spacer()
                        Text(buildNumber)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Main Content View

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            LogsView()
                .tabItem {
                    Label("Logs", systemImage: "list.bullet.clipboard")
                }
            
            MeView()
                .tabItem {
                    Label("Me", systemImage: "person.crop.circle.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MigraineLog.self, inMemory: true)
}
