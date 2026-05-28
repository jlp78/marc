MARC - Murray Amateur Radio Club

These scripts and programs are used to support and maintain the MARC web
site, located at https://www.murrayarc.org/

net_control
: generate the net control script for the Sunday evening net

class_schedule
: the class schedule is kept in a Google Docs spreadsheet.  these scripts automatically update the class schedule, pulling from the Future tab to Schedule, pushing from Schedule to Archive, and updating the Export tab when changes are made.  also automatically sends the e-mail to marc-announce and utah-multi-arc each Monday and sends a notification to the Utah Amateur Radio Slack #upcoming_meetings channel.  these functions are implelented in Google App Script and attached directly to the spreadsheet.
