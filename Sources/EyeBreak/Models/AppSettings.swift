import Foundation

@Observable
final class AppSettings {
    var workDuration: TimeInterval {
        didSet { UserDefaults.standard.set(workDuration, forKey: "workDuration") }
    }
    var breakDuration: TimeInterval {
        didSet { UserDefaults.standard.set(breakDuration, forKey: "breakDuration") }
    }
    var idleThreshold: TimeInterval {
        didSet { UserDefaults.standard.set(idleThreshold, forKey: "idleThreshold") }
    }
    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "isEnabled") }
    }
    var showLiveTimer: Bool {
        didSet { UserDefaults.standard.set(showLiveTimer, forKey: "showLiveTimer") }
    }
    var countMediaAsScreenTime: Bool {
        didSet { UserDefaults.standard.set(countMediaAsScreenTime, forKey: "countMediaAsScreenTime") }
    }
    var showIdleReminder: Bool {
        didSet { UserDefaults.standard.set(showIdleReminder, forKey: "showIdleReminder") }
    }

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "workDuration") == nil {
            defaults.set(Constants.defaultWorkDuration, forKey: "workDuration")
        }
        if defaults.object(forKey: "breakDuration") == nil {
            defaults.set(Constants.defaultBreakDuration, forKey: "breakDuration")
        }
        if defaults.object(forKey: "idleThreshold") == nil {
            defaults.set(Constants.defaultIdleThreshold, forKey: "idleThreshold")
        }
        if defaults.object(forKey: "isEnabled") == nil {
            defaults.set(true, forKey: "isEnabled")
        }
        if defaults.object(forKey: "showLiveTimer") == nil {
            defaults.set(true, forKey: "showLiveTimer")
        }
        if defaults.object(forKey: "countMediaAsScreenTime") == nil {
            defaults.set(false, forKey: "countMediaAsScreenTime")
        }
        if defaults.object(forKey: "showIdleReminder") == nil {
            defaults.set(true, forKey: "showIdleReminder")
        }

        self.workDuration = defaults.double(forKey: "workDuration")
        self.breakDuration = defaults.double(forKey: "breakDuration")
        self.idleThreshold = defaults.double(forKey: "idleThreshold")
        self.isEnabled = defaults.bool(forKey: "isEnabled")
        self.showLiveTimer = defaults.bool(forKey: "showLiveTimer")
        self.countMediaAsScreenTime = defaults.bool(forKey: "countMediaAsScreenTime")
        self.showIdleReminder = defaults.bool(forKey: "showIdleReminder")
    }
}
