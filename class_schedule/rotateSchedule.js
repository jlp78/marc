function rotateMARCSchedule() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const scheduleSheet = ss.getSheetByName("Schedule");
  const archiveSheet = ss.getSheetByName("Archive");
  const futureSheet = ss.getSheetByName("Future");
  
  const now = new Date();
  const currentMonth = now.getMonth();
  const currentYear = now.getFullYear();

  // Define window: Prev, Current, Next
  const prevMonthDate = new Date(currentYear, currentMonth - 1, 1);
  const nextMonthPlusOneDate = new Date(currentYear, currentMonth + 2, 1);

  // 1. Move old rows from Schedule to Archive
  let scheduleData = scheduleSheet.getDataRange().getValues();
  let rowsToArchive = [];
  for (let i = scheduleData.length - 1; i >= 1; i--) {
    let rowDate = new Date(scheduleData[i][1]);
    if (rowDate < prevMonthDate) {
      rowsToArchive.push(scheduleData[i]);
      scheduleSheet.deleteRow(i + 1);
    }
  }

  if (rowsToArchive.length > 0) {
    rowsToArchive.reverse().forEach(row => {
      let rowYear = new Date(row[1]).getFullYear();
      let lastRow = archiveSheet.getLastRow();
      let lastVal = archiveSheet.getRange(lastRow, 1).getValue();
      if (rowYear > lastVal && typeof lastVal === 'number') {
        insertYearHeader(archiveSheet, rowYear);
      }
      archiveSheet.appendRow(row);
    });
  }

  // 2. Move upcoming rows from Future to Schedule
  let futureData = futureSheet.getDataRange().getValues();
  for (let j = futureData.length - 1; j >= 1; j--) {
    if (!futureData[j][1]) continue; 
    let rowDate = new Date(futureData[j][1]);
    if (rowDate < nextMonthPlusOneDate) {
      scheduleSheet.appendRow(futureData[j]);
      futureSheet.deleteRow(j + 1);
    }
  }

  // 3. Replenish Future sheet to ensure 6-month buffer
  replenishFutureSheet(futureSheet);

  // 4. Sort Schedule
  const lastRowSched = scheduleSheet.getLastRow();
  if (lastRowSched > 1) {
    scheduleSheet.getRange(2, 1, lastRowSched - 1, 7).sort({column: 2, ascending: true});
  }

  // 5. Update Export Sheet
  updateExportSheet();
}

function replenishFutureSheet(sheet) {
  const now = new Date();
  const meetingTypes = ["Basic Topics", "Advanced Topics", "General Meeting", "Elmer's Night"];
  
  // Find the latest date currently in Future or Schedule
  let latestDate = new Date(now.getFullYear(), now.getMonth() + 2, 1); 
  let data = sheet.getDataRange().getValues();
  
  for (let i = 1; i < data.length; i++) {
    let d = new Date(data[i][1]);
    if (d > latestDate) latestDate = d;
  }

  // Target: 6 months from now
  const targetDate = new Date(now.getFullYear(), now.getMonth() + 7, 1);

  // Iterate month by month until target is met
  let checkDate = new Date(latestDate.getFullYear(), latestDate.getMonth() + 1, 1);
  
  while (checkDate < targetDate) {
    let year = checkDate.getFullYear();
    let month = checkDate.getMonth();
    let thursdaysFound = 0;

    // Loop through days of the month to find the first 4 Thursdays
    for (let day = 1; day <= 31; day++) {
      let d = new Date(year, month, day);
      if (d.getMonth() !== month) break; // End of month
      
      if (d.getDay() === 4) { // 4 = Thursday
        thursdaysFound++;
        if (thursdaysFound <= 4) {
          sheet.appendRow([meetingTypes[thursdaysFound - 1], d, "", "", "", "", ""]);
        }
      }
    }
    checkDate.setMonth(checkDate.getMonth() + 1);
  }
}

function insertYearHeader(sheet, year) {
  let startRow = sheet.getLastRow() + 1;
  sheet.appendRow([year]);
  sheet.insertRowsAfter(startRow, 2);
  let range = sheet.getRange(startRow, 1, 3, 4);
  range.merge().setHorizontalAlignment("center").setVerticalAlignment("middle")
       .setFontSize(36);
}

