import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("dailyReminderEnabled") private var reminderEnabled = false
    @AppStorage("dailyReminderHour") private var reminderHour = 20
    @AppStorage("dailyReminderMinute") private var reminderMinute = 0

    @State private var showingPermissionAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Daily Reminder", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled {
                                requestNotificationPermission()
                            } else {
                                cancelReminder()
                            }
                        }

                    if reminderEnabled {
                        DatePicker(
                            "Time",
                            selection: Binding(
                                get: { dateFromComponents() },
                                set: { updateComponents(from: $0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: reminderHour) { _, _ in scheduleReminder() }
                        .onChange(of: reminderMinute) { _, _ in scheduleReminder() }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get a daily reminder to write in your diary")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {
                    reminderEnabled = false
                }
            } message: {
                Text("Please enable notifications in Settings to receive daily reminders")
            }
        }
    }

    private func dateFromComponents() -> Date {
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        return Calendar.current.date(from: components) ?? Date()
    }

    private func updateComponents(from date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        reminderHour = components.hour ?? 20
        reminderMinute = components.minute ?? 0
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    scheduleReminder()
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }

    private func scheduleReminder() {
        guard reminderEnabled else { return }

        cancelReminder()

        let content = UNMutableNotificationContent()
        content.title = "Time to write"
        content.body = "How are you feeling today?"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyDiaryReminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyDiaryReminder"])
    }
}
