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
import MapKit
import EventKit

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
    var locationLatitude: Double?
    var locationLongitude: Double?
    // var moonPhase: String? // e.g., waxingGibbous
    var sleepStart: Date?
    var sleepEnd: Date?
    var sleepDuration: Double? // seconds
    var movementState: String? // stationary, walking, running, cycling, automotive, unknown
    var movementConfidence: Int? // 0=low, 1=medium, 2=high
    var painDescription: String? // qualitative pain description (e.g., pulsing, pressure, sharp, burning, electric, dull)
    var painLocations: [String]? // multiple pain locations selected by user
    var painLocation: String? // single selected pain location
    var onsetPattern: String? // sudden, gradual, tension-became-migraine, woke-up-with-it, stress-trigger
    var mood: String? // brain fog, word-finding difficulty, irritability, anxiety surge, fatigue wave, feeling detached, slowed thinking
    var lightSensitivity: Bool // default false
    var soundSensitivity: Bool // default false
    var smellSensitivity: Bool // default false
    var motionSensitivity: Bool // default false
    // Facial symptoms
    var eyeTearing: Bool // default false
    var eyeDrooping: Bool // default false
    var nasalCongestion: Bool // default false
    var flushedFace: Bool // default false
    var restlessness: Bool // default false
    // Aura symptoms
    var auraZigzags: Bool // default false
    var auraSparkles: Bool // default false
    var auraBlockedVision: Bool // default false
    var auraNumbness: Bool // default false
    var auraSpeechTrouble: Bool // default false
    var auraDistortedShapes: Bool // default false
    // Prodrome symptoms (before pain)
    var prodromeCravings: Bool // default false
    var prodromeYawning: Bool // default false
    var prodromePeeing: Bool // default false
    var prodromeNeckStiffness: Bool // default false
    var prodromeMoodChange: Bool // default false
    var prodromeEnergyChange: Bool // default false
    // Human-readable summary of relevant calendar events (titles and locations)
    var calendarContext: String?
    
    var averageHeartRate: Double? // bpm (24h average)
    var maxHeartRate: Double? // bpm (24h max)
    var restingHeartRate: Double? // bpm (most recent)
    var heartRateVariability: Double? // ms (SDNN average over 24h)
    var cyclePhase: String? // e.g., menstruation, ovulation, luteal, follicular
    
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
        movementConfidence: Int? = nil,
        painDescription: String? = nil,
        painLocations: [String]? = nil,
        painLocation: String? = nil,
        onsetPattern: String? = nil,
        mood: String? = nil,
        lightSensitivity: Bool = false,
        soundSensitivity: Bool = false,
        smellSensitivity: Bool = false,
        motionSensitivity: Bool = false,
        eyeTearing: Bool = false,
        eyeDrooping: Bool = false,
        nasalCongestion: Bool = false,
        flushedFace: Bool = false,
        restlessness: Bool = false,
        auraZigzags: Bool = false,
        auraSparkles: Bool = false,
        auraBlockedVision: Bool = false,
        auraNumbness: Bool = false,
        auraSpeechTrouble: Bool = false,
        auraDistortedShapes: Bool = false,
        prodromeCravings: Bool = false,
        prodromeYawning: Bool = false,
        prodromePeeing: Bool = false,
        prodromeNeckStiffness: Bool = false,
        prodromeMoodChange: Bool = false,
        prodromeEnergyChange: Bool = false,
        averageHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        restingHeartRate: Double? = nil,
        heartRateVariability: Double? = nil,
        cyclePhase: String? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        calendarContext: String? = nil
    ) {
        self.timestamp = timestamp
        self.intensity = intensity
        self.stepCount = stepCount
        self.temperature = temperature
        self.pressure = pressure
        self.humidity = humidity
        self.weatherCondition = weatherCondition
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        // self.moonPhase = moonPhase
        self.sleepStart = sleepStart
        self.sleepEnd = sleepEnd
        self.sleepDuration = sleepDuration
        self.movementState = movementState
        self.movementConfidence = movementConfidence
        self.painDescription = painDescription
        self.painLocations = painLocations
        self.painLocation = painLocation
        self.onsetPattern = onsetPattern
        self.mood = mood
        self.lightSensitivity = lightSensitivity
        self.soundSensitivity = soundSensitivity
        self.smellSensitivity = smellSensitivity
        self.motionSensitivity = motionSensitivity
        self.eyeTearing = eyeTearing
        self.eyeDrooping = eyeDrooping
        self.nasalCongestion = nasalCongestion
        self.flushedFace = flushedFace
        self.restlessness = restlessness
        self.auraZigzags = auraZigzags
        self.auraSparkles = auraSparkles
        self.auraBlockedVision = auraBlockedVision
        self.auraNumbness = auraNumbness
        self.auraSpeechTrouble = auraSpeechTrouble
        self.auraDistortedShapes = auraDistortedShapes
        self.prodromeCravings = prodromeCravings
        self.prodromeYawning = prodromeYawning
        self.prodromePeeing = prodromePeeing
        self.prodromeNeckStiffness = prodromeNeckStiffness
        self.prodromeMoodChange = prodromeMoodChange
        self.prodromeEnergyChange = prodromeEnergyChange
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.restingHeartRate = restingHeartRate
        self.heartRateVariability = heartRateVariability
        self.cyclePhase = cyclePhase
        self.calendarContext = calendarContext
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
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let bleedingType = HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
        let ovulationTestType = HKObjectType.categoryType(forIdentifier: .ovulationTestResult)!
        let cervicalMucusType = HKObjectType.categoryType(forIdentifier: .cervicalMucusQuality)!
        let sexualActivityType = HKObjectType.categoryType(forIdentifier: .sexualActivity)!
        let intermenstrualBleedingType = HKObjectType.categoryType(forIdentifier: .intermenstrualBleeding)!
        // let menstrualSymptomsType = HKObjectType.categoryType(forIdentifier: .menstruation)!
        
        let typesToRead: Set<HKObjectType> = [stepType, sleepType, hrType, rhrType, hrvType, bleedingType, ovulationTestType, cervicalMucusType, sexualActivityType, intermenstrualBleedingType]
        
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
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let bleedingType = HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
        let ovulationTestType = HKObjectType.categoryType(forIdentifier: .ovulationTestResult)!
        let cervicalMucusType = HKObjectType.categoryType(forIdentifier: .cervicalMucusQuality)!
        let sexualActivityType = HKObjectType.categoryType(forIdentifier: .sexualActivity)!
        let intermenstrualBleedingType = HKObjectType.categoryType(forIdentifier: .intermenstrualBleeding)!
        // let menstrualSymptomsType = HKObjectType.categoryType(forIdentifier: .menstruation)!
        
        let requestStatus = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKAuthorizationRequestStatus, Error>) in
            healthStore.getRequestStatusForAuthorization(toShare: [], read: [stepType, sleepType, hrType, rhrType, hrvType, bleedingType, ovulationTestType, cervicalMucusType, sexualActivityType, intermenstrualBleedingType]) { status, error in
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
    
    func fetchHeartRateStatsLast24h() async throws -> (average: Double?, max: Double?) {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let now = Date()
        let lookback = now.addingTimeInterval(-24 * 3600)
        let predicate = HKQuery.predicateForSamples(withStart: lookback, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: hrType, quantitySamplePredicate: predicate, options: [.discreteAverage, .discreteMax]) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let stats = result else {
                    continuation.resume(returning: (nil, nil))
                    return
                }
                let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let avg = stats.averageQuantity()?.doubleValue(for: unit)
                let max = stats.maximumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: (avg, max))
            }
            self.healthStore.execute(query)
        }
    }
    
    func fetchMostRecentRestingHeartRate() async throws -> Double? {
        let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let now = Date()
        let lookback = now.addingTimeInterval(-7 * 24 * 3600) // last 7 days fallback
        let predicate = HKQuery.predicateForSamples(withStart: lookback, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: rhrType, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let quantitySample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let bpm = quantitySample.quantity.doubleValue(for: unit)
                continuation.resume(returning: bpm)
            }
            self.healthStore.execute(query)
        }
    }
    
    func fetchHRVAverageLast24h() async throws -> Double? {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let now = Date()
        let lookback = now.addingTimeInterval(-24 * 3600)
        let predicate = HKQuery.predicateForSamples(withStart: lookback, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: hrvType, quantitySamplePredicate: predicate, options: [.discreteAverage]) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let stats = result else {
                    continuation.resume(returning: nil)
                    return
                }
                let unit = HKUnit.secondUnit(with: .milli)
                let avg = stats.averageQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: avg)
            }
            self.healthStore.execute(query)
        }
    }

    func currentCyclePhase(at date: Date = Date()) async -> String? {
        // Determine a coarse cycle phase using recent menstrual flow samples.
        guard let bleedingType = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else { return nil }
        let lookback = date.addingTimeInterval(-90 * 24 * 3600) // 90 days lookback
        let predicate = HKQuery.predicateForSamples(withStart: lookback, end: date, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: bleedingType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                guard error == nil, let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                // Find the most recent bleeding window
                let bleedingValues: Set<Int> = Set([
                    HKCategoryValueVaginalBleeding.heavy.rawValue,
                    HKCategoryValueVaginalBleeding.medium.rawValue,
                    HKCategoryValueVaginalBleeding.light.rawValue,
                    HKCategoryValueVaginalBleeding.unspecified.rawValue
                ])
                // Group contiguous bleeding days to identify last period start
                let calendar = Calendar.current
                let bleedingDays = samples
                    .filter { bleedingValues.contains($0.value) }
                    .map { calendar.startOfDay(for: $0.startDate) }
                guard let lastBleedDay = bleedingDays.first else {
                    continuation.resume(returning: nil)
                    return
                }
                let daysSince = calendar.dateComponents([.day], from: lastBleedDay, to: calendar.startOfDay(for: date)).day ?? 0
                // Heuristic phase labeling
                let phase: String
                switch daysSince {
                case 0...5:
                    phase = "Menstruation"
                case 6...13:
                    phase = "Follicular"
                case 14...16:
                    phase = "Ovulation"
                default:
                    phase = "Luteal"
                }
                continuation.resume(returning: phase)
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

    func requestOneLocation(timeout: TimeInterval = 10) async throws -> CLLocation {
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
    
    func lastKnownLocation() -> CLLocation? {
        return locationManager.location
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

@MainActor
final class CalendarManager: ObservableObject {
    private let store = EKEventStore()

    func ensureCalendarAuthorization() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            // Pre–iOS 17 full access
            return true
        case .notDetermined:
            if #available(iOS 17.0, *) {
                return await withCheckedContinuation { continuation in
                    self.store.requestFullAccessToEvents { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
            } else {
                return await withCheckedContinuation { continuation in
                    self.store.requestAccess(to: .event) { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
            }
        case .denied, .restricted:
            return false
        case .fullAccess:
            return true
        case .writeOnly:
            // Write-only cannot read events; return false for our read use case
            return false
        @unknown default:
            return false
        }
    }

    func fetchContextSummary(at date: Date) async -> String? {
        // Only proceed if we have (or can obtain) authorization
        guard await ensureCalendarAuthorization() else { return nil }

        // Look back 3 days and forward 1 day to capture overlaps
        let start = date.addingTimeInterval(-3 * 24 * 3600)
        let end = date.addingTimeInterval(1 * 24 * 3600)
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = store.events(matching: predicate)

        // Prefer events overlapping the migraine timestamp
        let overlapping = events.filter { $0.startDate <= date && $0.endDate >= date }
        if !overlapping.isEmpty {
            let lines = overlapping.sorted { $0.startDate < $1.startDate }.map { summarize($0) }
            return lines.joined(separator: "\n")
        }

        // Otherwise, take recent events that ended within the last 3 days, prioritizing longest duration
        let recent = events.filter { $0.endDate <= date && $0.startDate >= start }
        guard !recent.isEmpty else { return nil }
        let top = recent.sorted { a, b in
            let da = a.endDate.timeIntervalSince(a.startDate)
            let db = b.endDate.timeIntervalSince(b.startDate)
            if da == db { return a.endDate > b.endDate } // tie-break by recency
            return da > db
        }.prefix(3)
        let lines = top.map { summarize($0) }
        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }

    private func summarize(_ event: EKEvent) -> String {
        let rawTitle = (event.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let title = rawTitle.isEmpty ? "(No Title)" : rawTitle
        if event.isAllDay {
            return "\(title) (All Day)"
        } else {
            let duration = max(0, event.endDate.timeIntervalSince(event.startDate))
            return "\(title) (\(formatDuration(duration)))"
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        // Format as Xm, Xh, Xh Ym, Xd, or Xd Yh depending on length
        let totalMinutes = Int(seconds / 60)
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours < 24 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        let days = hours / 24
        let remHours = hours % 24
        return remHours > 0 ? "\(days)d \(remHours)h" : "\(days)d"
    }
}

// MARK: - Home View

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var weatherManager = WeatherManager()
    @StateObject private var barometerManager = BarometerManager()
    @StateObject private var movementManager = MovementManager()
    @StateObject private var calendarManager = CalendarManager()
    
    @State private var showingIntensitySlider = false
    @State private var intensity: Double = 0.5
    @State private var isLoggingMigraine = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPermissionsAlert = false
    @State private var permissionsMessage = ""
    @State private var showOpenSettings = false

    @AppStorage("homeCircleHeightFactor") private var homeCircleHeightFactor: Double = 0.71
    
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
                .frame(height: geometry.size.height * homeCircleHeightFactor)
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
        
        let calendarAuthorized = await calendarManager.ensureCalendarAuthorization()
        if !calendarAuthorized {
            permissionsMessage = "Calendar access is denied. To include calendar context in logs, allow Calendar access in Settings."
            showOpenSettings = true
            showPermissionsAlert = true
            // Continue without calendar context
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
        
        let calendarAuthorized = await calendarManager.ensureCalendarAuthorization()
        if !calendarAuthorized {
            permissionsMessage = "Calendar access is denied. To include calendar context in logs, allow Calendar access in Settings."
            showOpenSettings = true
            showPermissionsAlert = true
            // Continue to allow the user to provide more info; logging will still proceed without calendar context
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
        if !hasNonEmptyString(for: "NSCalendarsUsageDescription") {
            missing.append("NSCalendarsUsageDescription")
        }
        return missing
    }
    
    private func logMigraine() async {
        isLoggingMigraine = true
        defer { isLoggingMigraine = false }
        
        do {
            var locationLatitude: Double? = nil
            var locationLongitude: Double? = nil
            
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
            let painDescription: String?
            let painLocations: [String]?
            let painLocation: String?
            
            let averageHeartRate: Double?
            let maxHeartRate: Double?
            let restingHeartRate: Double?
            let heartRateVariability: Double?
            let cyclePhase: String?
            
            let calendarContext: String?
            
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
                painDescription = "Pulsing / throbbing"
                painLocations = ["One side"]
                painLocation = "One side"
                
                calendarContext = nil
                
                averageHeartRate = 72
                maxHeartRate = 134
                restingHeartRate = 58
                heartRateVariability = 55
                cyclePhase = "Follicular"
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
                painDescription = nil
                painLocations = nil
                painLocation = nil
                
                let hrStats = try? await healthKitManager.fetchHeartRateStatsLast24h()
                averageHeartRate = hrStats?.average
                maxHeartRate = hrStats?.max
                restingHeartRate = try? await healthKitManager.fetchMostRecentRestingHeartRate()
                heartRateVariability = try? await healthKitManager.fetchHRVAverageLast24h()
                // Cycle phase (if permission and data present)
                if let phase = await healthKitManager.currentCyclePhase(at: Date()) {
                    cyclePhase = phase
                } else {
                    cyclePhase = nil
                }
                
                if let last = weatherManager.lastKnownLocation() {
                    locationLatitude = last.coordinate.latitude
                    locationLongitude = last.coordinate.longitude
                } else if let loc = try? await weatherManager.requestOneLocation(timeout: 10) {
                    locationLatitude = loc.coordinate.latitude
                    locationLongitude = loc.coordinate.longitude
                }
                
                calendarContext = await calendarManager.fetchContextSummary(at: Date())
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
                movementConfidence: movementConfidence,
                painDescription: painDescription,
                painLocations: painLocations,
                painLocation: painLocation,
                averageHeartRate: averageHeartRate,
                maxHeartRate: maxHeartRate,
                restingHeartRate: restingHeartRate,
                heartRateVariability: heartRateVariability,
                cyclePhase: cyclePhase,
                locationLatitude: locationLatitude,
                locationLongitude: locationLongitude,
                calendarContext: calendarContext
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
                    ForEach(logs.indices, id: \.self) { index in
                        let log = logs[index]
                        NavigationLink {
                            MigraineDetailView(log: log)
                        } label: {
                            MigraineLogRow(log: log)
                        }
                        .listRowSeparator(index == 0 ? .hidden : .visible, edges: .top)
                        .listRowSeparator(index == logs.count - 1 ? .hidden : .visible, edges: .bottom)
                    }
                    .onDelete(perform: deleteLogs)
                }
            }
            .listStyle(.plain)
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
                        HStack(spacing: 4) {
                            Image(systemName: weatherSymbol(for: cond))
                                .imageScale(.small)
                            if log.temperature.isFinite {
                                Text(String(format: "%.0f°C", log.temperature))
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
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
    @Environment(\.modelContext) private var modelContext
    @Bindable var log: MigraineLog
    private let painOptions: [String] = [
        "Pulsing / throbbing",
        "Pressure / tight",
        "Sharp / stabbing",
        "Burning",
        "Electric / shooting",
        "Dull / aching"
    ]
    private let painLocationOptions: [String] = [
        "One side",
        "Both sides",
        "Behind eye",
        "Forehead",
        "Back of head",
        "Neck involvement",
        "Spread over time"
    ]
    
    private let onsetPatternOptions: [String] = [
        "Sudden",
        "Gradual",
        "Started as tension, became migraine",
        "Woke up with it",
        "Stress trigger"
    ]
    
    private let moodOptions: [String] = [
        "Brain fog",
        "Word-finding difficulty",
        "Irritability",
        "Anxiety surge",
        "Fatigue wave",
        "Feeling \"Detached\"",
        "Slowed thinking"
    ]
    
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
                    
                    // Adjustable intensity slider
                    VStack(alignment: .leading, spacing: 12) {
                        if #available(iOS 17.0, *) {
                            Slider(value: $log.intensity, in: 0...1)
                                .tint(intensityColor)
                                .onChange(of: log.intensity) { _, _ in
                                    try? modelContext.save()
                                }
                                .padding(.horizontal, 16)
                        } else {
                            Slider(value: $log.intensity, in: 0...1)
                                .tint(intensityColor)
                                .onChange(of: log.intensity) { _ in
                                    try? modelContext.save()
                                }
                                .padding(.horizontal, 16)
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
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 8)
                .listRowSeparator(.hidden)
            }
            
            Section("Describe your Experience") {
                // Pain Description (single selection)
                if #available(iOS 17.0, *) {
                    Picker("Pain Description", selection: $log.painDescription) {
                        Text("None").tag(nil as String?)
                        ForEach(painOptions, id: \.self) { option in
                            Text(option).tag(Optional(option))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: log.painDescription) { _, _ in
                        try? modelContext.save()
                    }
                } else {
                    Picker("Pain Description", selection: $log.painDescription) {
                        Text("None").tag(nil as String?)
                        ForEach(painOptions, id: \.self) { option in
                            Text(option).tag(Optional(option))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: log.painDescription) { _ in
                        try? modelContext.save()
                    }
                }

                // Pain Location (single selection)
                if #available(iOS 17.0, *) {
                    Picker("Pain Location", selection: $log.painLocation) {
                        Text("None").tag(nil as String?)
                        ForEach(painLocationOptions, id: \.self) { option in
                            Text(option).tag(Optional(option))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: log.painLocation) { _, _ in
                        try? modelContext.save()
                    }
                } else {
                    Picker("Pain Location", selection: $log.painLocation) {
                        Text("None").tag(nil as String?)
                        ForEach(painLocationOptions, id: \.self) { option in
                            Text(option).tag(Optional(option))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: log.painLocation) { _ in
                        try? modelContext.save()
                    }
                }
                
                // Onset Pattern (single selection)
                if #available(iOS 17.0, *) {
                    Picker("Onset Pattern", selection: $log.onsetPattern) {
                        Text("None").tag(nil as String?)
                        ForEach(onsetPatternOptions, id: \.self) { option in
                            Text(option).tag(Optional(option))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: log.onsetPattern) { _, _ in
                        try? modelContext.save()
                    }
                } else {
                    Picker("Onset Pattern", selection: $log.onsetPattern) {
                        Text("None").tag(nil as String?)
                        ForEach(onsetPatternOptions, id: \.self) { option in
                            Text(option).tag(Optional(option))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: log.onsetPattern) { _ in
                        try? modelContext.save()
                    }
                }
                
                // Mood (single selection)
                if #available(iOS 17.0, *) {
                    Picker("Mood", selection: $log.mood) {
                        Text("None").tag(nil as String?)
                        ForEach(moodOptions, id: \.self) { option in
                            Text(option).tag(Optional(option))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: log.mood) { _, _ in
                        try? modelContext.save()
                    }
                } else {
                    Picker("Mood", selection: $log.mood) {
                        Text("None").tag(nil as String?)
                        ForEach(moodOptions, id: \.self) { option in
                            Text(option).tag(Optional(option))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: log.mood) { _ in
                        try? modelContext.save()
                    }
                }
            }
            
            Section("Sensory Experience") {
                if #available(iOS 17.0, *) {
                    Toggle("Light sensitivity", isOn: $log.lightSensitivity)
                        .onChange(of: log.lightSensitivity) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Sound sensitivity", isOn: $log.soundSensitivity)
                        .onChange(of: log.soundSensitivity) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Smell sensitivity", isOn: $log.smellSensitivity)
                        .onChange(of: log.smellSensitivity) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Motion sensitivity", isOn: $log.motionSensitivity)
                        .onChange(of: log.motionSensitivity) { _, _ in
                            try? modelContext.save()
                        }
                } else {
                    Toggle("Light sensitivity", isOn: $log.lightSensitivity)
                        .onChange(of: log.lightSensitivity) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Sound sensitivity", isOn: $log.soundSensitivity)
                        .onChange(of: log.soundSensitivity) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Smell sensitivity", isOn: $log.smellSensitivity)
                        .onChange(of: log.smellSensitivity) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Motion sensitivity", isOn: $log.motionSensitivity)
                        .onChange(of: log.motionSensitivity) { _ in
                            try? modelContext.save()
                        }
                }
            }
            
            Section("Facial Symptoms") {
                if #available(iOS 17.0, *) {
                    Toggle("Eye tearing", isOn: $log.eyeTearing)
                        .onChange(of: log.eyeTearing) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Eye drooping", isOn: $log.eyeDrooping)
                        .onChange(of: log.eyeDrooping) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Nasal congestion/runny nose", isOn: $log.nasalCongestion)
                        .onChange(of: log.nasalCongestion) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Flushed face", isOn: $log.flushedFace)
                        .onChange(of: log.flushedFace) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Restlessness", isOn: $log.restlessness)
                        .onChange(of: log.restlessness) { _, _ in
                            try? modelContext.save()
                        }
                } else {
                    Toggle("Eye tearing", isOn: $log.eyeTearing)
                        .onChange(of: log.eyeTearing) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Eye drooping", isOn: $log.eyeDrooping)
                        .onChange(of: log.eyeDrooping) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Nasal congestion/runny nose", isOn: $log.nasalCongestion)
                        .onChange(of: log.nasalCongestion) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Flushed face", isOn: $log.flushedFace)
                        .onChange(of: log.flushedFace) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Restlessness", isOn: $log.restlessness)
                        .onChange(of: log.restlessness) { _ in
                            try? modelContext.save()
                        }
                }
            }
            
            Section("Aura Description") {
                if #available(iOS 17.0, *) {
                    Toggle("Zig-zags", isOn: $log.auraZigzags)
                        .onChange(of: log.auraZigzags) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Sparkles", isOn: $log.auraSparkles)
                        .onChange(of: log.auraSparkles) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Blocked vision", isOn: $log.auraBlockedVision)
                        .onChange(of: log.auraBlockedVision) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Numbness", isOn: $log.auraNumbness)
                        .onChange(of: log.auraNumbness) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Speech trouble", isOn: $log.auraSpeechTrouble)
                        .onChange(of: log.auraSpeechTrouble) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Distorted shapes", isOn: $log.auraDistortedShapes)
                        .onChange(of: log.auraDistortedShapes) { _, _ in
                            try? modelContext.save()
                        }
                } else {
                    Toggle("Zig-zags", isOn: $log.auraZigzags)
                        .onChange(of: log.auraZigzags) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Sparkles", isOn: $log.auraSparkles)
                        .onChange(of: log.auraSparkles) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Blocked vision", isOn: $log.auraBlockedVision)
                        .onChange(of: log.auraBlockedVision) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Numbness", isOn: $log.auraNumbness)
                        .onChange(of: log.auraNumbness) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Speech trouble", isOn: $log.auraSpeechTrouble)
                        .onChange(of: log.auraSpeechTrouble) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Distorted shapes", isOn: $log.auraDistortedShapes)
                        .onChange(of: log.auraDistortedShapes) { _ in
                            try? modelContext.save()
                        }
                }
            }
            
            Section("Before Pain I Felt") {
                if #available(iOS 17.0, *) {
                    Toggle("Cravings", isOn: $log.prodromeCravings)
                        .onChange(of: log.prodromeCravings) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Sudden yawning", isOn: $log.prodromeYawning)
                        .onChange(of: log.prodromeYawning) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Peeing more often", isOn: $log.prodromePeeing)
                        .onChange(of: log.prodromePeeing) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Neck stiffness", isOn: $log.prodromeNeckStiffness)
                        .onChange(of: log.prodromeNeckStiffness) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Mood change", isOn: $log.prodromeMoodChange)
                        .onChange(of: log.prodromeMoodChange) { _, _ in
                            try? modelContext.save()
                        }
                    Toggle("Energy spike or crash", isOn: $log.prodromeEnergyChange)
                        .onChange(of: log.prodromeEnergyChange) { _, _ in
                            try? modelContext.save()
                        }
                } else {
                    Toggle("Cravings", isOn: $log.prodromeCravings)
                        .onChange(of: log.prodromeCravings) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Sudden yawning", isOn: $log.prodromeYawning)
                        .onChange(of: log.prodromeYawning) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Peeing more often", isOn: $log.prodromePeeing)
                        .onChange(of: log.prodromePeeing) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Neck stiffness", isOn: $log.prodromeNeckStiffness)
                        .onChange(of: log.prodromeNeckStiffness) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Mood change", isOn: $log.prodromeMoodChange)
                        .onChange(of: log.prodromeMoodChange) { _ in
                            try? modelContext.save()
                        }
                    Toggle("Energy spike or crash", isOn: $log.prodromeEnergyChange)
                        .onChange(of: log.prodromeEnergyChange) { _ in
                            try? modelContext.save()
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
            
            Section("Heart") {
                if let avg = log.averageHeartRate {
                    HStack {
                        Label("Avg Heart Rate", systemImage: "heart.fill")
                        Spacer()
                        Text(String(format: "%.0f bpm", avg))
                            .foregroundColor(.secondary)
                    }
                }
                if let mx = log.maxHeartRate {
                    HStack {
                        Label("Max Heart Rate", systemImage: "heart.circle")
                        Spacer()
                        Text(String(format: "%.0f bpm", mx))
                            .foregroundColor(.secondary)
                    }
                }
                if let rhr = log.restingHeartRate {
                    HStack {
                        Label("Resting Heart Rate", systemImage: "heart")
                        Spacer()
                        Text(String(format: "%.0f bpm", rhr))
                            .foregroundColor(.secondary)
                    }
                }
                if let hrv = log.heartRateVariability {
                    HStack {
                        Label("HRV (SDNN)", systemImage: "waveform.path.ecg")
                        Spacer()
                        Text(String(format: "%.0f ms", hrv))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let phase = log.cyclePhase {
                Section("Cycle Tracking") {
                    HStack {
                        Label("Cycle Phase", systemImage: "drop.fill")
                        Spacer()
                        Text(phase)
                            .foregroundColor(.secondary)
                    }
                }
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
                
                if let state = log.movementState {
                    HStack {
                        Label("Movement", systemImage: "figure.walk")
                        Spacer()
                        Text(state.capitalized)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Build a list of calendar context lines and show a count in the header
            let calendarLines: [String] = {
                guard let ctx = log.calendarContext else { return [] }
                return ctx
                    .components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }()
            Section("Calendar Context\(calendarLines.isEmpty ? "" : " (\(calendarLines.count))")") {
                if calendarLines.isEmpty {
                    Text("No relevant calendar events recorded")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(calendarLines.enumerated()), id: \.offset) { _, line in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            Text(line)
                        }
                    }
                }
            }
            
            Section("Location") {
                if let lat = log.locationLatitude, let lon = log.locationLongitude {
                    LocationMapView(latitude: lat, longitude: lon)
                } else {
                    Text("No location recorded")
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

struct LocationMapView: View {
    let latitude: Double
    let longitude: Double

    var body: some View {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        Map(initialPosition: .region(region)) {
            Marker(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude), coordinate: coordinate)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .allowsHitTesting(false)
        .accessibilityLabel("Approximate location")
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

    private var averageIntensityColor: Color {
        guard let avg = averageIntensity else { return Color.gray.opacity(0.6) }
        switch avg {
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
    
    private func secondsIntoDay(_ date: Date) -> Double {
        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let h = comps.hour ?? 0
        let m = comps.minute ?? 0
        let s = comps.second ?? 0
        return Double(h * 3600 + m * 60 + s)
    }

    private func timeString(fromSeconds seconds: Double) -> String {
        let base = Calendar.current.startOfDay(for: Date())
        let date = base.addingTimeInterval(seconds.truncatingRemainder(dividingBy: 86400))
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func mode<T: Hashable>(_ values: [T]) -> T? {
        guard !values.isEmpty else { return nil }
        let counts = values.reduce(into: [T: Int]()) { $0[$1, default: 0] += 1 }
        return counts.max { a, b in
            if a.value == b.value { return String(describing: a.key) < String(describing: b.key) }
            return a.value < b.value
        }?.key
    }

    private func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2.0
        } else {
            return sorted[mid]
        }
    }

    // Deleted median onset properties and replaced with mode-based onset hour and weekday
    
    private var mostCommonOnsetHour: (hour: Int, count: Int)? {
        guard !logs.isEmpty else { return nil }
        var counts: [Int: Int] = [:]
        for log in logs {
            let h = Calendar.current.component(.hour, from: log.timestamp)
            counts[h, default: 0] += 1
        }
        guard let best = counts.max(by: { a, b in
            if a.value == b.value { return a.key > b.key } // tie-break: earlier hour wins
            return a.value < b.value
        }) else { return nil }
        return (best.key, best.value)
    }

    private var mostCommonOnsetHourLabel: String? {
        guard let best = mostCommonOnsetHour else { return nil }
        let base = Calendar.current.startOfDay(for: Date())
        let date = Calendar.current.date(byAdding: .hour, value: best.hour, to: base) ?? base
        let fmt = DateFormatter()
        fmt.setLocalizedDateFormatFromTemplate("ha")
        return fmt.string(from: date)
    }

    private var mostCommonOnsetHourIcon: String {
        guard let best = mostCommonOnsetHour else { return "clock" }
        let h = best.hour
        return (h >= 6 && h < 18) ? "sun.max.fill" : "moon.stars.fill"
    }

    private var mostCommonOnsetHourDisplay: String? {
        guard let best = mostCommonOnsetHour, let label = mostCommonOnsetHourLabel else { return nil }
        return "\(label) (\(best.count))"
    }

    private var mostCommonWeekday: (weekday: Int, count: Int)? {
        guard !logs.isEmpty else { return nil }
        var counts: [Int: Int] = [:]
        for log in logs {
            let w = Calendar.current.component(.weekday, from: log.timestamp) // 1=Sunday
            counts[w, default: 0] += 1
        }
        guard let best = counts.max(by: { a, b in
            if a.value == b.value { return a.key > b.key } // tie-break: earlier weekday wins
            return a.value < b.value
        }) else { return nil }
        return (best.key, best.value)
    }

    private var mostCommonWeekdayString: String? {
        guard let best = mostCommonWeekday else { return nil }
        let symbols = DateFormatter().weekdaySymbols ?? []
        let idx = max(1, min(7, best.weekday)) - 1
        guard idx >= 0 && idx < symbols.count else { return nil }
        return symbols[idx]
    }

    private var averageBedtimeString: String? {
        let times = logs.compactMap { $0.sleepStart }.map { secondsIntoDay($0) }
        guard !times.isEmpty else { return nil }
        let avg = times.reduce(0, +) / Double(times.count)
        return timeString(fromSeconds: avg)
    }

    private var averageWakeTimeString: String? {
        let times = logs.compactMap { $0.sleepEnd }.map { secondsIntoDay($0) }
        guard !times.isEmpty else { return nil }
        let avg = times.reduce(0, +) / Double(times.count)
        return timeString(fromSeconds: avg)
    }

    private var averageTotalSleepString: String? {
        let durations = logs.compactMap { $0.sleepDuration }
        guard !durations.isEmpty else { return nil }
        let avg = durations.reduce(0, +) / Double(durations.count)
        return String(format: "%.1fh", avg / 3600.0)
    }

    private var averageHRVString: String? {
        let values = logs.compactMap { $0.heartRateVariability }
        guard !values.isEmpty else { return nil }
        let avg = values.reduce(0, +) / Double(values.count)
        return String(format: "%.0f ms", avg)
    }

    private var averageRestingHRString: String? {
        let values = logs.compactMap { $0.restingHeartRate }
        guard !values.isEmpty else { return nil }
        let avg = values.reduce(0, +) / Double(values.count)
        return String(format: "%.0f bpm", avg)
    }

    private var averageStepsString: String? {
        guard !logs.isEmpty else { return nil }
        let avg = logs.map { Double($0.stepCount) }.reduce(0, +) / Double(logs.count)
        return String(format: "%.0f", avg)
    }

    private var medianConditionString: String? {
        let values = logs.compactMap { $0.weatherCondition }
        guard let m = mode(values) else { return nil }
        return m.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var medianMovementString: String? {
        let values = logs.compactMap { $0.movementState }
        guard let m = mode(values) else { return nil }
        return m.capitalized
    }

    private var temperatureRangeString: String? {
        let temps = logs.map { $0.temperature }.filter { $0.isFinite }
        guard let minV = temps.min(), let maxV = temps.max() else { return nil }
        return String(format: "%.0f–%.0f°C", minV, maxV)
    }

    private var pressureRangeString: String? {
        let pressures = logs.compactMap { $0.pressure }
        guard let minV = pressures.min(), let maxV = pressures.max() else { return nil }
        return String(format: "%.0f–%.0f hPa", minV, maxV)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Summary
                    Text("Summary")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        MetricCard(
                            title: "Recorded Migraines",
                            icon: "brain.head.profile",
                            value: "\(logs.count)",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                        MetricCard(
                            title: "Average Intensity",
                            icon: "gearshape",
                            value: averageIntensity.map { String(format: "%.1f", $0 * 10) } ?? "—",
                            background: averageIntensityColor
                        )
                        MetricCard(
                            title: "Peak Onset Hour",
                            icon: mostCommonOnsetHourIcon,
                            value: mostCommonOnsetHourDisplay ?? "—",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                        MetricCard(
                            title: "Common Weekday",
                            icon: "calendar",
                            value: mostCommonWeekdayString ?? "—",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                    }

                    // Sleep
                    Text("Sleep")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        MetricCard(
                            title: "Average Bed Time",
                            icon: "bed.double.fill",
                            value: averageBedtimeString ?? "—",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                        MetricCard(
                            title: "Average Wake Time",
                            icon: "alarm",
                            value: averageWakeTimeString ?? "—",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                        MetricCard(
                            title: "Average Total Sleep",
                            icon: "clock",
                            value: averageTotalSleepString ?? "—",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                    }

                    // Heart
                    Text("Heart")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        MetricCard(
                            title: "Average HRV",
                            icon: "waveform.path.ecg",
                            value: averageHRVString ?? "—",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                        MetricCard(
                            title: "Average Resting HR",
                            icon: "heart",
                            value: averageRestingHRString ?? "—",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                    }

                    // Activity
                    Text("Activity")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        MetricCard(
                            title: "Average Steps",
                            icon: "figure.walk",
                            value: averageStepsString ?? "—",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                        MetricCard(
                            title: "Movement State",
                            icon: "figure.walk",
                            value: medianMovementString ?? "—",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                    }

                    // Cycle Tracking
                    Text("Cycle Tracking")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        let phases = logs.compactMap { $0.cyclePhase }
                        let commonPhase = mode(phases)
                        MetricCard(
                            title: "Common Cycle Phase",
                            icon: "drop.fill",
                            value: commonPhase ?? "—",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                    }
                    
                    // Environment
                    Text("Environment")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        MetricCard(
                            title: "Median Conditions",
                            icon: "cloud.sun",
                            value: medianConditionString ?? "—",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                        MetricCard(
                            title: "Temperature Range",
                            icon: "thermometer",
                            value: temperatureRangeString ?? "—",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                        MetricCard(
                            title: "Pressure Range",
                            icon: "gauge",
                            value: pressureRangeString ?? "—",
                            background: Color(red: 0.53, green: 0.81, blue: 0.92)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
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

struct MetricCard: View {
    let title: String
    let icon: String
    let value: String
    let background: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(background)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                }
                Spacer()
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct SettingsView: View {
    @AppStorage("homeCircleHeightFactor") private var homeCircleHeightFactor: Double = 0.71

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
                Section("Home Button Position") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Vertical Position")
                            Spacer()
                            Text(String(format: "%.2f", homeCircleHeightFactor))
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $homeCircleHeightFactor, in: 0.6...1.2, step: 0.01)
                        Text("Lower values move the button up; higher values move it down.")
                            .font(.footnote)
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
                    Label("Record", systemImage: "largecircle.fill.circle")
                }
            
            LogsView()
                .tabItem {
                    Label("Logs", systemImage: "list.bullet.clipboard")
                }
            
            MeView()
                .tabItem {
                    Label("Analytics", systemImage: "person.crop.circle.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MigraineLog.self, inMemory: true)
}

