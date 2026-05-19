# MARC Meeting Automation System

A Google Apps Script-based automation engine for the Murray Amateur Radio Club (MARC) to manage meeting schedules, communications, and public-facing data exports.

## Overview

This project automates the workflow for club meeting coordination. It bridges the gap between a Google Sheets-based master schedule and the various communication channels used by club members (Email, Slack, Google Calendar, and the Club Website).

## Core Features

- **Automated Rotation:** A monthly script creates new meeting entries based on a rolling 6-month buffer, handling the 1st through 4th Thursday rotation logic.
- **Cross-Platform Notifications:** Sends automated meeting announcements to club mailing lists and the club Slack channel every Monday.
- **Calendar Integration:** Dynamically updates the club's Google Calendar event with specific meeting topics, instructors, and summaries.
- **Public Export:** Automatically syncs a clean, stripped-down version of the schedule to an "Export" sheet for integration with the club website.
- **Logistics Handling:** Support for alternate meeting locations (e.g., field days) and times, overriding standard Zoom/Station #81 details when specified.

## File Structure

- `rotateSchedule.gs`: Handles the creation of future meeting slots and the cleanup of past entries.
- `sendMeetingEmail.gs`: Contains the logic for weekly email announcements, Slack webhooks, and Google Calendar event updates.
- `exportSync.gs`: Manages the automated synchronization between the internal `Schedule` sheet and the public `Export` sheet.

## Configuration & Secrets

The system utilizes Global Constants for easy maintenance. Key variables located at the top of the scripts include:

| Variable | Description |
| :--- | :--- |
| `ZOOM_LINK` | The static recurring Zoom meeting URL. |
| `ZOOM_ID` | Meeting ID for member reference. |
| `ZOOM_PASS` | Meeting passcode. |
| `CALENDAR_ID` | The unique ID for the MARC Events Google Calendar. |
| `SLACK_WEBHOOK_URL` | The integration URL for the club Slack channel. |

*Note: For enhanced security, these can be migrated to the Apps Script **Script Properties** service.*

## Setup Instructions

1.  **Spreadsheet Setup:** Ensure your Google Sheet has a `Schedule` tab and an `Export` tab.
2.  **Script Attachment:** Open `Extensions > Apps Script` in your Google Sheet and paste the project files.
3.  **Triggers:**
    * Set `rotateMARCSchedule` to run on a **Time-driven** trigger (Monthly on the 1st).
    * Set `sendMARCWeeklyUpdate` to run on a **Time-driven** trigger (Weekly on Mondays).
    * Set `onEditTrigger` to run **From spreadsheet** on the **On edit** event.
4.  **Authorizing:** Run any function manually once in the editor to grant the necessary permissions for Gmail, Calendar, and Drive access.

## Maintenance

To change meeting details, simply edit the `Schedule` sheet. The system will detect changes and update the `Export` sheet automatically. If the Zoom credentials change, update the Global Constants at the top of the relevant script file.

---
**73 de KD7ZWV**
