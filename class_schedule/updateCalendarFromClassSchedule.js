function updateCalendar() {
  /* this is attached to the MARC Class Schedule spreadsheet */
  var sheet = SpreadsheetApp.getActiveSpreadsheet();
  SpreadsheetApp.setActiveSheet(sheet.getSheetByName("ExportToCalendar"));

  /* this is the MARC Events calendar */
  var calendarId = "3b618afa004dbe05ffbce5eb1f888ee2d9b7541ab01a4d012cf1f81c48d6eac4@group.calendar.google.com";
  var eventCal = CalendarApp.getCalendarById(calendarId);
  
  var meetings = sheet.getRange('D1:I12').getValues();
  
  for (x=0; x<meetings.length; x++) {
       
       var meeting = meetings[x];
       var startTime = meeting[0];
       var endTime = meeting[1];
       var meetingType = meeting[2];
       var meetingTopic = meeting[3];
       var meetingInstructor = meeting[4];
       var meetingLocation = meeting[5];
       var meetingDesciption;
       var meetingOptions;

       if (meetingLocation == "") {
         meetingLocation = "Murray Fire Department Station 81"
       }

       if (meetingTopic == "") {
         meetingDescription = "To Be Announced";
       } else {
         meetingDescription = meetingTopic;
       }

       if (meetingInstructor == "") {
         meetingDescription += ", " + meetingInstructor;
       }

       meetingOptions = {location: meetingLocation,
                         description: meetingDescription};
      
       eventCal.createEvent(meetingType, startTime, endTime, meetingOptions);
  }
}
