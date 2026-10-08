function doGet(e) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName("Schedule"); 
  let data = sheet.getDataRange().getValues();
  
  // Calculate the date for the upcoming Thursday
  const today = new Date();
  const daysUntilThursday = (4 - today.getDay() + 7) % 7;
  const targetDate = new Date(today);
  targetDate.setDate(today.getDate() + daysUntilThursday);
  targetDate.setHours(0, 0, 0, 0);

  var upcomingMeetings = [];
  const howMany = 3;

  // find rows for upcoming meetings
  for (let i = 1; i < data.length; i++) {
    let rowDate = new Date(data[i][1]);
    rowDate.setHours(0, 0, 0, 0);

    if (upcomingMeetings.length > 0 || rowDate.getTime() === targetDate.getTime()) {
      // no meeting entry on this day
      if (data[i][2] === "") {
        continue;
      }
      // we are at the next meeting date OR we have already started collecting meeting info
      upcomingMeetings.push({
        date: Utilities.formatDate(rowDate, Session.getScriptTimeZone(), "d MMMM yyyy"),
        topic: data[i][2],
      });
    }

    // stop when we have three or we run out
    if (upcomingMeetings.length === howMany) {
      break;
    }
  }

  if (upcomingMeetings.length < howMany) {
    // we didn't find enough in the current schedule, look at Future, next
    sheet = ss.getSheetByName("Future");
    data = sheet.getDataRange().getValues();

    for (let i = 1; i < data.length; i++) {
      let rowDate = new Date(data[i][1]);
      rowDate.setHours(0, 0, 0, 0);

      if (data[i][2] === "") {
        continue;
      }

      upcomingMeetings.push({
        date: Utilities.formatDate(rowDate, Session.getScriptTimeZone(), "d MMMM yyyy"),
        topic: data[i][2],
      });

      if (upcomingMeetings.length === howMany) {
        break;
      }
    }
  }

  return ContentService.createTextOutput(JSON.stringify(upcomingMeetings))
    .setMimeType(ContentService.MimeType.JSON);
}
