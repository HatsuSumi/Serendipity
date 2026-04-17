bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int getDaysInMonth(DateTime month) {
  return DateTime(month.year, month.month + 1, 0).day;
}

int getFirstWeekdayOfMonth(DateTime month) {
  return DateTime(month.year, month.month, 1).weekday % 7;
}

bool canGoToNextMonth(DateTime currentMonth, DateTime now) {
  final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
  return nextMonth.isBefore(DateTime(now.year, now.month + 1));
}

bool isCheckedIn(DateTime date, List<DateTime> checkInDates) {
  return checkInDates.any((checkedDate) => isSameDay(checkedDate, date));
}

bool isPartOfStreak(DateTime date, List<DateTime> checkInDates) {
  if (!isCheckedIn(date, checkInDates)) {
    return false;
  }

  final previousDay = date.subtract(const Duration(days: 1));
  final nextDay = date.add(const Duration(days: 1));

  return isCheckedIn(previousDay, checkInDates) ||
      isCheckedIn(nextDay, checkInDates);
}

bool isStreakStart(DateTime date, List<DateTime> checkInDates) {
  return isPartOfStreak(date, checkInDates) &&
      !isPartOfStreak(date.subtract(const Duration(days: 1)), checkInDates);
}

bool isStreakEnd(DateTime date, List<DateTime> checkInDates) {
  return isPartOfStreak(date, checkInDates) &&
      !isPartOfStreak(date.add(const Duration(days: 1)), checkInDates);
}

