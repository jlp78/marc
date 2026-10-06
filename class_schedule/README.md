# MARC Meeting Automation System

A Google Apps Script-based automation engine for the Murray Amateur Radio Club (MARC) to manage meeting schedules, communications, and public-facing data exports.

## Overview

This project automates the workflow for club meeting coordination. It bridges the gap between a Google Sheets-based master schedule and the various communication channels used by club members (Email, Slack, Google Calendar, and the Club Website).

## Core Features

- **Automated Rotation:** A monthly script creates new meeting entries based on a rolling 6-month buffer, handling the 1st through 4th Thursday rotation logic[cite: 3].
- **Cross-Platform Notifications:** Sends automated meeting announcements to club mailing lists and the club Slack channel every Monday[cite: 3].
- **Calendar Integration:** Dynamically updates the club's Google Calendar event with specific meeting topics, instructors, and summaries[cite: 3].
- **Public Export & Website Feed:** Automatically syncs clean schedule data to an "Export" sheet and provides a real-time JSON web endpoint (`doGet`) to feed the club website dynamically[cite: 1, 3].
- **Logistics Handling:** Support for alternate meeting locations (e.g., field days) and times, overriding standard Zoom/Station #81 details when specified[cite: 3].

## File Structure

- `rotateSchedule.gs`: Handles the creation of future meeting slots and the cleanup of past entries[cite: 3].
- `sendMeetingEmail.gs`: Contains the logic for weekly email announcements, Slack webhooks, and Google Calendar event updates[cite: 3].
- `exportSync.gs`: Manages the automated synchronization between the internal `Schedule` sheet and the public export views[cite: 3].
- `GetNextMeetings.js`: Implements the web app `doGet` endpoint to query upcoming meetings from the `Schedule` (and fallback `Future`) sheets, returning a clean JSON array of the next three events[cite: 1].
- `snippit.php`: WordPress snippet containing the shortcode logic (`[upcoming_meetings]`) that fetches, transiently caches (1-hour), and renders the dynamic meeting list on the club website[cite: 2].

## Configuration & Secrets

The system utilizes Global Constants for easy maintenance. Key variables located at the top of the scripts include:

| Variable | Description |
| :--- | :--- |
| `ZOOM_LINK` | The static recurring Zoom meeting URL. |
| `ZOOM_ID` | Meeting ID for member reference. |
| `ZOOM_PASS` | Meeting passcode. |
| `CALENDAR_ID` | The unique ID for the MARC Events Google Calendar. |
| `SLACK_WEBHOOK_URL` | The integration URL for the club Slack channel. |
| `MAIL_DESTINATION` | The To: address for the e-mail. |

*Note: For enhanced security, these can be migrated to the Apps Script **Script Properties** service[cite: 3].*

## Setup Instructions

1.  **Spreadsheet Setup:** Ensure your Google Sheet has a `Schedule` tab, a `Future` tab, and an `Export` tab[cite: 1, 3].
2.  **Script Attachment:** Open `Extensions > Apps Script` in your Google Sheet and paste the project files[cite: 1, 3].
3.  **Triggers:**
    * Set `rotateMARCSchedule` to run on a **Time-driven** trigger (Monthly on the 1st)[cite: 3].
    * Set `sendMARCWeeklyUpdate` to run on a **Time-driven** trigger (Weekly on Mondays)[cite: 3].
    * Set `onEditTrigger` to run **From spreadsheet** on the **On edit** event[cite: 3].
4.  **Web App Deployment (for Website Integration):**
    * In the Apps Script editor, go to **Deploy > New deployment**, select **Web app**.
    * Set **Execute as:** to *Me* and **Who has access:** to *Anyone*. Copy the resulting Web App URL.
5.  **WordPress Integration:**
    * Install a code snippets plugin or use your child theme to add the contents of `snippit.php`[cite: 2].
    * Replace the placeholder URL in `snippit.php` with your Google Apps Script Web App URL[cite: 2].
    * Place the `[upcoming_meetings]` shortcode on any page or post where you want the list to appear[cite: 2].
6.  **Authorizing:** Run any function manually once in the editor to grant the necessary permissions for Gmail, Calendar, and Drive access.

## Maintenance

To change meeting details, simply edit the `Schedule` sheet. The automated backend and JSON feed will reflect updates instantly. If you modify the script logic for the web endpoint, make sure to create a **New version** when managing your Apps Script deployment. If the Zoom credentials change, update the Global Constants at the top of the relevant script file.

---
**73 de KD7ZWV**[cite: 3]
