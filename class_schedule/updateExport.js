/**
 * Core function to rebuild the Export sheet based on the Schedule sheet.
 */
function updateExportSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const scheduleSheet = ss.getSheetByName("Schedule");
  let exportSheet = ss.getSheetByName("Export");
  
  // If Export sheet doesn't exist, create it
  if (!exportSheet) {
    exportSheet = ss.insertSheet("Export");
  } else {
    exportSheet.clear({contentsOnly: true, formatOnly: false});
  }
  
  const scheduleData = scheduleSheet.getDataRange().getValues();
  if (scheduleData.length <= 1) return; // Nothing to process if only headers exist
  
  const exportRows = [];
  
  // Define Headers for the Export Sheet (Mapping Schedule Columns B, C+E, D)
  // Schedule: B (Date), C (Topic), D (Presenter), E (Summary)
  // Export will become: A (Date), B (Topic & Summary), C (Presenter)
  exportRows.push(["Date", "Topic", "Presenter"]);
  
  // Process data rows (skip header row 0)
  for (let i = 1; i < scheduleData.length; i++) {
    const row = scheduleData[i];
    
    const dateVal = row[1];      // Column B
    const topicVal = row[2];     // Column C
    const presenterVal = row[3]; // Column D
    const summaryVal = row[4];   // Column E
    
    // Rule: Remove/skip rows that don't have a topic
    if (!topicVal || topicVal.toString().trim() === "") {
      continue;
    }
    
    // Format the Topic column to include the summary text if it exists
    let combinedTopic = topicVal;
    if (summaryVal && summaryVal.toString().trim() !== "") {
      combinedTopic = `${topicVal} - ${summaryVal}`;
    }
    
    // Push the allowed columns to our export array
    exportRows.push([dateVal, combinedTopic, presenterVal]);
  }
  
  // Write the clean data to the Export sheet
  if (exportRows.length > 0) {
    exportSheet.getRange(1, 1, exportRows.length, exportRows[0].length).setValues(exportRows);
    
    // Format the Date column so it looks correct on the website
    exportSheet.getRange(2, 1, exportRows.length - 1, 1).setNumberFormat("M/d/yyyy");
    
    // Optional: Bold the headers
    exportSheet.getRange(1, 1, 1, 3).setFontWeight("bold");
  }
}

/**
 * Trigger function that responds to manual edits on the spreadsheet.
 */
function onEditTrigger(e) {
  const sheetName = e.range.getSheet().getName();
  
  // Only trigger if the manual edit happened on the Schedule sheet
  if (sheetName === "Schedule") {
    updateExportSheet();
  }
}
