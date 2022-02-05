//
//  Home.swift
//  TaskManager
//
//  Created by kazunari_ueeda on 2022/01/10.
//

import SwiftUI

struct Home: View {
    @StateObject var taskModel: TaskViewModel = TaskViewModel()
    
    private let calendar: Calendar
    private let monthDayFormatter: DateFormatter
    private let dayFormatter: DateFormatter
    private let weekDayFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    
    @State private var selectedDate = Self.now
    private static var now = Date() // Cache now
    
    init(calendar: Calendar) {
        self.calendar = calendar
        self.monthDayFormatter = DateFormatter(dateFormat: "MM/dd", calendar: calendar)
        self.dayFormatter = DateFormatter(dateFormat: "d", calendar: calendar)
        self.weekDayFormatter = DateFormatter(dateFormat: "EEE", calendar: calendar)
        self.timeFormatter = DateFormatter(dateFormat: "H:mm", calendar: calendar)
    }
    
    var body: some View {
        VStack {
            ScrollView() {
                HStack {
                    VStack(alignment: .center, spacing: 10) {
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(.gray)
                        
                        Text("Today")
                            .font(.title.bold())
                    }
                    
                    Spacer()
                }
                .padding(.leading)
                
                CalendarWeekListView(
                    calendar: calendar,
                    date: $selectedDate,
                    content: { date in
                        Button(action: {
                            selectedDate = date
                            
                            withAnimation {
                                taskModel.currentDay = date
                            }
                        }) {
                            VStack(spacing: 10) {
                                Text(dayFormatter.string(from: date))
                                    .font(.system(size: 15))
                                    .fontWeight(.semibold)
                                
                                Text(weekDayFormatter.string(from: date))
                                    .font(.system(size: 14))
                                
                                Circle()
                                    .fill(.white)
                                    .frame(width: 8, height: 8)
                                    .opacity(calendar.isDate(date, inSameDayAs: selectedDate) ? 1 : 0)
                                
                            }
                            .foregroundStyle(calendar.isDate(date, inSameDayAs: selectedDate) ? .primary : .secondary)
                            .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : .black)
                            .frame(width: 45, height: 90)
                            .background(
                                ZStack {
                                    if calendar.isDate(date, inSameDayAs: selectedDate) {
                                        Capsule()
                                            .fill(Color("CardColor2"))
                                    }
                                }
                            )
                        }
                    },
                    title: { date in
                        HStack {
                            Text(monthDayFormatter.string(from: selectedDate))
                                .font(.headline)
                                .padding(5)
                            Spacer()
                        }
                        .padding([.bottom, .leading], 10)
                    }, weekSwitcher: { date in
                        Button {
                            withAnimation(.easeIn) {
                                guard let newDate = calendar.date(
                                    byAdding: .weekOfMonth,
                                    value: -1,
                                    to: selectedDate
                                ) else {
                                    return
                                }
                                
                                selectedDate = newDate
                            }
                        } label: {
                            Label(
                                title: { Text("Previous") },
                                icon: { Image(systemName: "chevron.left") }
                            )
                                .labelStyle(IconOnlyLabelStyle())
                                .padding(.horizontal)
                        }
                        Button {
                            withAnimation(.easeIn) {
                                guard let newDate = calendar.date(
                                    byAdding: .weekOfMonth,
                                    value: 1,
                                    to: selectedDate
                                ) else {
                                    return
                                }
                                
                                selectedDate = newDate
                            }
                        } label: {
                            Label(
                                title: { Text("Next") },
                                icon: { Image(systemName: "chevron.right") }
                            )
                                .labelStyle(IconOnlyLabelStyle())
                                .padding(.horizontal)
                        }
                    }
                )
                
                TasksView()
            }
        }
    }
    
    func TasksView() -> some View {
        LazyVStack(spacing: 10) {
            if let tasks = taskModel.filteredTasks {
                if tasks.isEmpty {
                    Text("No Task")
                        .font(.system(size: 16))
                        .fontWeight(.light)
                        .offset(y: 100)
                } else {
                    ForEach(tasks) { task in
                        TaskCardView(task: task)
                    }
                }
            } else {
                ProgressView()
                    .offset(y: 100)
            }
        }
        .padding()
        .padding(10)
        // MARK: - Updating Tasks
        .onChange(of: taskModel.currentDay) { newValue in
            taskModel.filterTodayTasks()
        }
    }
    
    func TaskCardView(task: Task) -> some View {
        HStack(alignment: .top, spacing: 25) {
            VStack(spacing: 10) {
                Button(action: {

                }, label: {
                    Image(systemName: task.doneFlag ? "checkmark" : "")
                        .font(.caption)
                        .frame(width: 5, height: 5)
                        .foregroundColor(.black)
                        .padding(10)
                        .background(
                            Circle()
                                .foregroundColor(.blue.opacity(0.38))
                        )
                })

                Rectangle()
                    .fill(.black)
                    .frame(width: 3)
            }

            VStack {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(task.title)
                            .font(.title2).bold()

                        Text(task.description)
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(task.date.formatted(date: .omitted, time: .shortened))
                }

                Divider()

            }
            .foregroundStyle(taskModel.isCurrentHour(date: task.date) ? .white : .black)
            .padding(taskModel.isCurrentHour(date: task.date) ? 15 : 0)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color("CardColor"), Color("CardColor2")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .opacity(taskModel.isCurrentHour(date: task.date) ? 1 : 0)
                    .cornerRadius(20)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
    }
}
    
    
// MARK: - Component

public struct CalendarWeekListView<Day: View, Title: View, WeekSwiter: View>: View {
    // Injected dependencies
    private var calendar: Calendar
    @Binding private var date: Date
    private let content: (Date) -> Day
    private let title: (Date) -> Title
    private let weekSwitcher: (Date) -> WeekSwiter
    
    // Constants
    private let daysInWeek = 7
    
    public init(
        calendar: Calendar,
        date: Binding<Date>,
        @ViewBuilder content: @escaping (Date) -> Day,
        @ViewBuilder title: @escaping (Date) -> Title,
        @ViewBuilder weekSwitcher: @escaping (Date) -> WeekSwiter
    ) {
        self.calendar = calendar
        self._date = date
        self.content = content
        self.title = title
        self.weekSwitcher = weekSwitcher
    }
    
    public var body: some View {
        let month = date.startOfMonth(using: calendar)
        let days = makeDays()
        
        VStack {
            HStack {
                self.title(month)
                self.weekSwitcher(month)
            }
            HStack {
                ForEach(days, id: \.self) { date in
                    content(date)
                }
                
            }
            
            Divider()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
    
// MARK: - Conformances
    
extension CalendarWeekListView: Equatable {
    public static func == (lhs: CalendarWeekListView<Day, Title, WeekSwiter>, rhs: CalendarWeekListView<Day, Title, WeekSwiter>) -> Bool {
        lhs.calendar == rhs.calendar && lhs.date == rhs.date
    }
}
    
// MARK: - Helpers
    
private extension CalendarWeekListView {
    func makeDays() -> [Date] {
        guard let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: date),
                let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: firstWeek.end - 1)
        else {
            return []
        }
            
        let dateInterval = DateInterval(start: firstWeek.start, end: lastWeek.end)
            
        print(calendar.generateDays(for: dateInterval))
            
        return calendar.generateDays(for: dateInterval)
    }
}
    
private extension Calendar {
    func generateDates(
        for dateInterval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates = [dateInterval.start]
            
        enumerateDates(
            startingAfter: dateInterval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            guard let date = date else { return }
                
            guard date < dateInterval.end else {
                stop = true
                return
            }
                
            dates.append(date)
        }
            
        return dates
    }
        
    func generateDays(for dateInterval: DateInterval) -> [Date] {
        generateDates(
            for: dateInterval,
                matching: dateComponents([.hour, .minute, .second], from: dateInterval.start)
        )
    }
}
    
private extension Date {
    func startOfMonth(using calendar: Calendar) -> Date {
        calendar.date(
            from: calendar.dateComponents([.year, .month], from: self)
        ) ?? self
    }
        
    func startOfDayTime(using calendar: Calendar) -> Date {
        calendar.date(
            from: calendar.dateComponents([.hour, .minute], from: self)
        ) ?? self
    }
}
    
private extension DateFormatter {
    convenience init(dateFormat: String, calendar: Calendar) {
        self.init()
        self.dateFormat = dateFormat
        self.calendar = calendar
    }
}
// MARK: - Previews

#if DEBUG
struct CalendarWeekView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Home(calendar: Calendar(identifier: .gregorian))
        }
    }
}
#endif
