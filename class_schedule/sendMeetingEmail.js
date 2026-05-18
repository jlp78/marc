// --- CONFIGURATION/SECRETS ---
const ZOOM_LINK = "<INSERT ZOOM LINK HERE>";
const ZOOM_MEETING_ID = "<INSERT ZOOM MEETING ID HERE>";
const ZOOM_PASSCODE = "<INSERT ZOOM PASSCODE HERE>";
const CALENDAR_ID = "<INSERT CALENDAR ID HERE>";
const SLACK_WEBHOOK_URL = "<INSERT SLACK WEBHOOK URL HERE>";

// --- END CONFIGURATION ---


function sendMARCWeeklyUpdate() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("Schedule"); 
  const data = sheet.getDataRange().getValues();
  
  // Calculate the date for the upcoming Thursday
  const today = new Date();
  const daysUntilThursday = (4 - today.getDay() + 7) % 7;
  const targetDate = new Date(today);
  targetDate.setDate(today.getDate() + daysUntilThursday);
  targetDate.setHours(0, 0, 0, 0);

  // Hardcoded default fallback for the Zoom link
  let zoomDetails = "Zoom Link: ${ZOOM_LINK}\n" +
      "Meeting ID: ${ZOOM_MEETING_ID}\n" +
      "Passcode: ${ZOOM_PASSCODE}";
  
  let meetingInfo = null;

  // 1. Locate the correct row based on Date (Column B / Index 1)
  for (let i = 1; i < data.length; i++) {
    let rowDate = new Date(data[i][1]);
    rowDate.setHours(0, 0, 0, 0);
    
    if (rowDate.getTime() === targetDate.getTime()) {
      const altLocation = data[i][5];
      const altTime = data[i][6];
      
      meetingInfo = {
        dateStr: Utilities.formatDate(rowDate, Session.getScriptTimeZone(), "dd MMM yyyy").toUpperCase(),
        topic: data[i][2],
        instructor: data[i][3] || "TBD",
        comments: data[i][4] ? "  " + data[i][4] : "",
        location: altLocation || "Murray Fire Station #81, located at 4848 S Box Elder St (35 W)",
        time: altTime || "6:30 PM",
        isAsUsual: (!altLocation && !altTime) ,
	altLocation: altLocation,
      };
      break;
    }
  }

  if (!meetingInfo || meetingInfo.topic === "") {
    Logger.log("No meeting found for this Thursday.");
    return;
  }


  // 2. Calendar Integration, update the calendar event for this week
  // with dynamic details and get the full description for the iCal
  // attachment
  const fullDescription = updateCalendarEvent(
    targetDate,
    meetingInfo.topic,
    meetingInfo.instructor,
    meetingInfo.comments,
    meetingInfo.altLocation
  );
  const icsAttachment = createIcalAttachment(
    targetDate,
    meetingInfo.topic,
    fullDescription,
    meetingInfo.altLocation
  );


  // 3. Construct the Email
  const asUsualSuffix = meetingInfo.isAsUsual ? ", as usual" : "";
  // const mailingLists = "marc-announce@freelists.org, utah-multi-arc@freelists.org";
  const mailingLists = "jlp@jay-one.org";
  
  const emailSubject = `Upcoming MARC Meeting: ${meetingInfo.topic}`;
  const emailBody = `Greetings, Folks!

This week, MARC will be meeting at ${meetingInfo.time} at ${meetingInfo.location} on Thursday, ${meetingInfo.dateStr}${asUsualSuffix}. The meeting topic will be "${meetingInfo.topic}".${meetingInfo.comments}  ${meetingInfo.instructor} will be teaching. The meeting will be on Zoom, see details below.

There will be a check in net on the club repeater (223.96 MHz, negative 1.6 MHz offset, tone 103.5 Hz) prior to the meeting at 6:00.

${zoomDetails}

Hope to see everyone there!

73 de KD7ZWV
  -jan-
--
Jan (KD7ZWV)
Vice President
Murray Amateur Radio Club (MARC)
https://www.murrayarc.org/
`;

  GmailApp.sendEmail(
    mailingLists,
    emailSubject,
    emailBody,
    {
      name: "Jan (KD7ZWV)",
      attachments: [icsAttachment]
    }
  );

  // 4. Send to Slack
  const slackWebhookUrl = "${SLACK_WEBHOOK_URL}";
  const slackText = `*MARC meeting this Thursday (${meetingInfo.dateStr}), ${meetingInfo.time}*
*Location:* ${meetingInfo.location}.
*Topic:* ${meetingInfo.topic}
*Presenter:* ${meetingInfo.instructor}`;

  const payload = {
    "text": slackText,
    "username": "MARC-meeting-bot",
    "icon_emoji": ":spiral_calendar_pad:"
  };

  const options = {
    "method": "post",
    "contentType": "application/json",
    "payload": JSON.stringify(payload)
  };

  UrlFetchApp.fetch(slackWebhookUrl, options);
}

/**
 * Updates the specific calendar instance for this week's meeting with
 * dynamic details.
 * @param {Date} targetDate The Thursday date of the meeting.
 * @param {string} topic The meeting topic.
 * @param {string} presenter The meeting presenter.
 * @param {string} summary The topic summary.
 * @param {string} altLocation Any alternate location notes (optional).
 * @return {string} The full combined description text (useful for the
 * iCal file).
 */
function updateCalendarEvent(targetDate, topic, presenter, summary, altLocation) {
  const calendarId = "${CALENDAR_ID}";
  const calendar = CalendarApp.getCalendarById(calendarId);
  
  // Set time window for that Thursday to find the event (6:30 PM - 8:00 PM)
  const startTime = new Date(targetDate);
  startTime.setHours(18, 30, 0, 0);
  const endTime = new Date(targetDate);
  endTime.setHours(20, 0, 0, 0);
  
  const events = calendar.getEvents(startTime, endTime);
  
  // The static Zoom boilerplate text
  const boilerplate = `MARC meets the first three Thursdays of each month.  The first week we cover beginner's topics that would be helpful to the new or prospective ham.  The second week, we cover more advanced topics that are often of general interest, but are focused on more in depth examination of various topics.  The third week is our general business meeting and includes discussions of topics of general interest to club members and others.  We will occasionally have guest presenters for these meetings.  These meetings are generally carried on Zoom (link below) and will often be recorded and published to the News section of the club web site.

We have reserved the fourth Thursday of each month for an Elmer's night, allowing people to meet for detailed one on one interaction.  This is an ad hoc meeting and will likely not be on Zoom.

Zoom Link:  ${ZOOM_LINK}
Meeting ID: ${ZOOM_MEETING_ID}
Passcode: ${ZOOM_PASSCODE}
`;
  
  // Build the dynamic header
  let dynamicHeader = `Tonight's Topic: ${topic}\n`;
  dynamicHeader += `Presenter: ${presenter}\n`;
  if (summary) dynamicHeader += `Summary: ${summary}\n`;
  if (altLocation) dynamicHeader += `⚠️ Location Note: ${altLocation}\n`;
  dynamicHeader += `----------------------------------------\n\n`;
  
  const fullDescription = dynamicHeader + boilerplate;
  
  if (events.length > 0) {
    const event = events[0]; // Grab this specific week's instance
    
    // Update Title and Description for this instance only
    event.setTitle(`MARC Meeting: ${topic}`);
    event.setDescription(fullDescription);
    
    // If an alternate location exists, update the location field for this week
    if (altLocation) {
      event.setLocation(altLocation);
    } else {
      event.setLocation("${ZOOM_LINK}");
    }
  }
  
  return fullDescription;
}

/**
 * Generates an iCal string and converts it to a file blob attachment.
 */
function createIcalAttachment(targetDate, topic, description, altLocation) {
  const start = new Date(targetDate);
  start.setHours(18, 30, 0);
  const end = new Date(targetDate);
  end.setHours(20, 0, 0);
  
  // Format dates to UTC style required by iCal (YYYYMMDDTHMMSSZ)
  const formatICalDate = (date) => date.toISOString().replace(/[-:]/g, "").split(".")[0] + "Z";
  
  const strStart = formatICalDate(start);
  const strEnd = formatICalDate(end);
  const strStamp = formatICalDate(new Date());
  
  const location = altLocation || "${ZOOM_LINK}";
  
  // Escape newlines for the iCal format
  const escapedDescription = description.replace(/\n/g, "\\n");

  const icsLines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Murray ARC//Meeting Automation//EN",
    "BEGIN:VEVENT",
    `UID:marc-meeting-${start.getTime()}@murrayarc.org`,
    `DTSTAMP:${strStamp}`,
    `DTSTART:${strStart}`,
    `DTEND:${strEnd}`,
    `SUMMARY:MARC Meeting: ${topic}`,
    `DESCRIPTION:${escapedDescription}`,
    `LOCATION:${location}`,
    "END:VEVENT",
    "END:VCALENDAR"
  ];
  
  const icsContent = icsLines.join("\r\n");
  
  // Create the attachment blob
  return Utilities.newBlob(icsContent, "text/calendar", "invite.ics");
}
