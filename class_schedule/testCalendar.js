function testCalendar() {
  const calendarId = "3b618afa004dbe05ffbce5eb1f888ee2d9b7541ab01a4d012cf1f81c48d6eac4@group.calendar.google.com";
  const cal = CalendarApp.getCalendarById(calendarId);
  if (cal) {
    Logger.log("Success! Connected to: " + cal.getName());
  } else {
    Logger.log("Connection failed. Check permissions or ID.");
  }
}
