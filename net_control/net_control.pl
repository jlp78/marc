#! /usr/bin/perl

use strict;

use CGI qw(:standard);
use POSIX qw(strftime);
use Carp;

use Google::RestApi;
use Google::RestApi::SheetsApi4;
use Data::Dumper;

my $config_dir = '/home/jlp/lib/net_control';
my ($auth_client_id, $auth_client_secret);
open(CONF, "$config_dir/oauth") or die "no configuration file: $!\n";
while (<CONF>) {
  chomp;
  my ($key, $val) = split(m/=/, $_);
  if ($key eq 'client_id') {
    $auth_client_id = $val;
  } elsif ($key eq 'client_secret') {
    $auth_client_secret = $val;
  }
}
close(CONF);

my $meeting_day = 4;            # like crontab, 4 == Thursday
my ($meeting_hour, $meeting_min) = (18, 30); # 6:30 PM
my $one_day = 60 * 60 * 24;     # seconds per day
my $one_week = $one_day * 7;    # seconds per week

# main program
if (defined(param('NetControlOperator')) and
    param('NetControlOperator') ne '') {
  &print_doc;
} else {
  &print_form;
}
exit;


sub print_form {
  ### calculate when the next meeting will be, set the defaults for the form

  my ($stamp, $sec, $min, $hour, $mday, $mon, $year, $wday, $yday,
      $isdst, $calculated_next_meeting_type, $month, $suffix,
      $calculated_next_meeting_date, $target_date, $meeting_data,
      $calculated_next_meeting_topic, $net_control_operator,
      $next_meeting_type, $next_meeting_topic, $next_meeting_date,
      $training, $training_operator, $submit, $reset);

  $stamp = time;
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($stamp);
  # find next Thursday
  if ($wday == $meeting_day) {
    # meeting is today, has it happened yet?
    if ($hour > $meeting_hour and $min > $meeting_min) {
      $wday++;                  # fake it and get the next one
    }
    # else, hasn't happened yet, still report today
  }
  while ($wday != $meeting_day) {
    $stamp += $one_day;
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($stamp);
  }
  if ($mday >= 1 and $mday <= 7) {
    $calculated_next_meeting_type = 'first';
  } elsif ($mday >= 8 and $mday <= 14) {
    $calculated_next_meeting_type = 'second';
  } elsif ($mday >= 15 and $mday <= 21) {
    $calculated_next_meeting_type = 'third';
  } else {
    # need to advance to the first Thursday of the month
    while ($mday > 7) {
      $stamp += $one_week;
      ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($stamp);
    }
    $calculated_next_meeting_type = 'first';
  }
  $month = strftime('%B', localtime($stamp)); # localized
  if ($mday % 10 == 1) {
    $suffix = 'st';
  } elsif ($mday % 10 == 2) {
    $suffix = 'nd';
  } elsif ($mday % 10 == 3) {
    $suffix = 'rd';
  } else {
    $suffix = 'th';
  }
  $calculated_next_meeting_date = sprintf('%s %d%s', $month, $mday, $suffix);
  $target_date = strftime('%e %B %Y', localtime($stamp));
  $target_date =~ s/^\s*//;     # trim leading white space

  # look up the next meeting topic from the spreadsheet
  $meeting_data = get_meeting_topic($target_date);
  $calculated_next_meeting_topic = $meeting_data->[2]
    if defined($meeting_data);


  $net_control_operator = textfield(-name => 'NetControlOperator',
                                    -default => '',
                                    -size => 32,
                                    -maxlength => 32);
  $next_meeting_type = radio_group(-name => 'NextMeetingType',
                                   -values => ['first', 'second', 'third'],
                                   -default => $calculated_next_meeting_type);
  $next_meeting_topic = textfield(-name => 'NextMeetingTopic',
                                  -default => $calculated_next_meeting_topic,,
                                  -size => 64,
                                  -maxlength => 128);
  $next_meeting_date = textfield(-name => 'NextMeetingDate',
                                 -default => $calculated_next_meeting_date,
                                 -size => 20,
                                 -maxlength => 32);
  $training = radio_group(-name => 'Training',
                          -values => ['will', 'will not'],
                          -default => 'will not');
  $training_operator = textfield(-name => 'TrainingOperator',
                                 -default => 'N/A',
                                 -size => 32,
                                 -maxlength => 32);
  $submit = submit(-name => 'Generate',
                   -value => 'Generate');
  $reset = reset();

  print header;
  print start_html(-title => 'Net Control Script Generator');

  print q(
<h1>Net Control Script Generator</h1>
<p>Fill in the appropriate fields below, then click "Generate" and
the Net Control script will be displayed.</p>
);
  print start_form();

  # double q used on purpose here for variable interpolation
  print qq(<table>
  <tr><td>Net Control Operator:</td><td>$net_control_operator
      <i>required</i></td></tr>
  <tr><td colspan=2>Next meeting is a $next_meeting_type Thursday</td></tr>
  <tr><td>Next Meeting Topic:</td><td>$next_meeting_topic</td></tr>
  <tr><td colspan=2>&nbsp;&nbsp;if you don&rsquo;t have the next meeting
topic, you can find it here: <a
href="https://www.murrayarc.org/meeting-schedule-and-location/);
  print qq(#schedule-of-classes">Meeting
Schedule and Location</a><br>
&nbsp;&nbsp;if you still can&rsquo;t find it, leave it blank</td></tr>
  <tr><td>Next Meeting Date:</td><td>$next_meeting_date</td></tr>
  <tr><td colspan=2>Training $training be provided</td></tr>
  <tr><td>Training Provided By:</td><td>$training_operator</td></tr>
  <tr><td colspan=2>$submit $reset</td></tr>
</table>
);

  print end_form;
  print end_html;
}


sub print_doc {
  print header;
  print q(<html>
  <head>
    <meta content="text/html; charset=UTF-8" http-equiv="content-type">
    <style type="text/css">
      ol {
        margin: 0;
        padding: 0
      }

      table td,
      table th {
        padding: 0
      }

      .c14 {
        border-right-style: solid;
        padding: 5pt 5pt 5pt 5pt;
        border-bottom-color: #000000;
        border-top-width: 1pt;
        border-right-width: 1pt;
        border-left-color: #000000;
        vertical-align: top;
        border-right-color: #000000;
        border-left-width: 1pt;
        border-top-style: solid;
        border-left-style: solid;
        border-bottom-width: 1pt;
        width: 242.2pt;
        border-top-color: #000000;
        border-bottom-style: solid
      }

      .c9 {
        border-right-style: solid;
        padding: 5pt 5pt 5pt 5pt;
        border-bottom-color: #000000;
        border-top-width: 1pt;
        border-right-width: 1pt;
        border-left-color: #000000;
        vertical-align: top;
        border-right-color: #000000;
        border-left-width: 1pt;
        border-top-style: solid;
        border-left-style: solid;
        border-bottom-width: 1pt;
        width: 316.5pt;
        border-top-color: #000000;
        border-bottom-style: solid
      }

      .c15 {
        border-right-style: solid;
        padding: 5pt 5pt 5pt 5pt;
        border-bottom-color: #000000;
        border-top-width: 1pt;
        border-right-width: 1pt;
        border-left-color: #000000;
        vertical-align: top;
        border-right-color: #000000;
        border-left-width: 1pt;
        border-top-style: solid;
        border-left-style: solid;
        border-bottom-width: 1pt;
        width: 79.5pt;
        border-top-color: #000000;
        border-bottom-style: solid
      }

      .c7 {
        border-right-style: solid;
        padding: 5pt 5pt 5pt 5pt;
        border-bottom-color: #000000;
        border-top-width: 1pt;
        border-right-width: 1pt;
        border-left-color: #000000;
        vertical-align: top;
        border-right-color: #000000;
        border-left-width: 1pt;
        border-top-style: solid;
        border-left-style: solid;
        border-bottom-width: 1pt;
        width: 156pt;
        border-top-color: #000000;
        border-bottom-style: solid
      }

      .c12 {
        border-right-style: solid;
        padding: 5pt 5pt 5pt 5pt;
        border-bottom-color: #000000;
        border-top-width: 1pt;
        border-right-width: 1pt;
        border-left-color: #000000;
        vertical-align: top;
        border-right-color: #000000;
        border-left-width: 1pt;
        border-top-style: solid;
        border-left-style: solid;
        border-bottom-width: 1pt;
        width: 151.5pt;
        border-top-color: #000000;
        border-bottom-style: solid
      }

      .c10 {
        border-right-style: solid;
        padding: 5pt 5pt 5pt 5pt;
        border-bottom-color: #000000;
        border-top-width: 1pt;
        border-right-width: 1pt;
        border-left-color: #000000;
        vertical-align: top;
        border-right-color: #000000;
        border-left-width: 1pt;
        border-top-style: solid;
        border-left-style: solid;
        border-bottom-width: 1pt;
        width: 146.2pt;
        border-top-color: #000000;
        border-bottom-style: solid
      }

      .c11 {
        -webkit-text-decoration-skip: none;
        color: #000000;
        font-weight: 400;
        text-decoration: underline;
        vertical-align: baseline;
        text-decoration-skip-ink: none;
        font-size: 11pt;
        font-family: "Arial";
        font-style: normal
      }

      .c0 {
        color: #ff0000;
        font-weight: 400;
        text-decoration: none;
        vertical-align: baseline;
        font-size: 11pt;
        font-family: "Arial";
        font-style: italic
      }

      .c19 {
        color: #000000;
        font-weight: 700;
        text-decoration: none;
        vertical-align: baseline;
        font-size: 11pt;
        font-family: "Arial";
        font-style: normal
      }

      .c3 {
        color: #000000;
        font-weight: 400;
        text-decoration: none;
        vertical-align: baseline;
        font-size: 11pt;
        font-family: "Arial";
        font-style: normal
      }

      .c1 {
        padding-top: 0pt;
        padding-bottom: 0pt;
        line-height: 1.15;
        orphans: 2;
        widows: 2;
        text-align: left
      }

      .c20 {
        font-weight: 400;
        text-decoration: none;
        vertical-align: baseline;
        font-size: 11pt;
        font-family: "Arial";
        font-style: normal
      }

      .c8 {
        padding-top: 0pt;
        padding-bottom: 0pt;
        line-height: 1.0;
        text-align: left
      }

      .c6 {
        border-spacing: 0;
        border-collapse: collapse;
        margin-right: auto
      }

      .c23 {
        background-color: #ffffff;
        max-width: 468pt;
        padding: 36pt 72pt 36pt 72pt
      }

      .c5 {
        font-style: italic;
        color: #ff0000;
        font-weight: 700
      }

      .c13 {
        text-decoration-skip-ink: none;
        -webkit-text-decoration-skip: none;
        text-decoration: underline
      }

      .c16 {
        color: #0000ff;
        font-weight: 700
      }

      .c18 {
        color: #ff0000;
        font-style: italic
      }

      .c2 {
        height: 11pt
      }

      .c22 {
        font-weight: 700
      }

      .c4 {
        height: 0pt
      }

      .c17 {
        color: #0000ff
      }

      .c21 {
        height: 14.9pt
      }

      .title {
        padding-top: 0pt;
        color: #000000;
        font-size: 26pt;
        padding-bottom: 3pt;
        font-family: "Arial";
        line-height: 1.15;
        page-break-after: avoid;
        orphans: 2;
        widows: 2;
        text-align: left
      }

      .subtitle {
        padding-top: 0pt;
        color: #666666;
        font-size: 15pt;
        padding-bottom: 16pt;
        font-family: "Arial";
        line-height: 1.15;
        page-break-after: avoid;
        orphans: 2;
        widows: 2;
        text-align: left
      }

      li {
        color: #000000;
        font-size: 11pt;
        font-family: "Arial"
      }

      p {
        margin: 0;
        color: #000000;
        font-size: 11pt;
        font-family: "Arial"
      }

      h1 {
        padding-top: 20pt;
        color: #000000;
        font-size: 20pt;
        padding-bottom: 6pt;
        font-family: "Arial";
        line-height: 1.15;
        page-break-after: avoid;
        orphans: 2;
        widows: 2;
        text-align: left
      }

      h2 {
        padding-top: 18pt;
        color: #000000;
        font-size: 16pt;
        padding-bottom: 6pt;
        font-family: "Arial";
        line-height: 1.15;
        page-break-after: avoid;
        orphans: 2;
        widows: 2;
        text-align: left
      }

      h3 {
        padding-top: 16pt;
        color: #434343;
        font-size: 14pt;
        padding-bottom: 4pt;
        font-family: "Arial";
        line-height: 1.15;
        page-break-after: avoid;
        orphans: 2;
        widows: 2;
        text-align: left
      }

      h4 {
        padding-top: 14pt;
        color: #666666;
        font-size: 12pt;
        padding-bottom: 4pt;
        font-family: "Arial";
        line-height: 1.15;
        page-break-after: avoid;
        orphans: 2;
        widows: 2;
        text-align: left
      }

      h5 {
        padding-top: 12pt;
        color: #666666;
        font-size: 11pt;
        padding-bottom: 4pt;
        font-family: "Arial";
        line-height: 1.15;
        page-break-after: avoid;
        orphans: 2;
        widows: 2;
        text-align: left
      }

      h6 {
        padding-top: 12pt;
        color: #666666;
        font-size: 11pt;
        padding-bottom: 4pt;
        font-family: "Arial";
        line-height: 1.15;
        page-break-after: avoid;
        font-style: italic;
        orphans: 2;
        widows: 2;
        text-align: left
      }
    </style>
  </head>
  <body class="c23">
    <p class="c1">
      <span class="c3">Sunday Night Net Control Script</span>
    </p>
    <p class="c1">
      <span class="c3">Murray Amateur Radio Club</span>
    </p>
    <p class="c1">
      <span class="c3">Revision: May 2022</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span>Net Control Operator: &nbsp;</span>
      <span class="c13">
);
  print param('NetControlOperator');
  print q(</span>
    </p>
    <p class="c1">
      <span>Next meeting is a );
  if (param('NextMeetingType') eq 'first') {
      print q(</span><span>&#10004;</span><span class="c3">);
  } else {
      print q(&#9634;);
  }
  print q(&nbsp;first, );
  if (param('NextMeetingType') eq 'second') {
      print q(</span><span>&#10004;</span><span class="c3">);
  } else {
      print q(&#9634;);
  }
  print q(&nbsp;second, or );
  if (param('NextMeetingType') eq 'third') {
      print q(</span><span>&#10004;</span><span class="c3">);
  } else {
      print q(&#9634;);
  }
  print q(&nbsp;third Thursday.</span>
    </p>
    <p class="c1">
      <span>Next Meeting Topic: &nbsp;</span>
      <span class="c11">);
  print param('NextMeetingTopic');;
  print q(</span>
    </p>
    <p class="c1">
      <span>Next Meeting Date: &nbsp;</span>
      <span class="c11">);
  print param('NextMeetingDate');
  print q(</span>
    </p>
    <p class="c1">
      <span class="c3">Training </span><span class="c13">);
  print param('Training');
  print q(</span><span class="c3"> be provided during this net.</span>
    </p>);
  if (param('Training') eq 'will') {
    print q(<p class="c1"><span
class="c1">Training will be provided by: &nbsp;</span><span class="c13">);
    print param('TrainingOperator');
    print q(</span></p>);
  }
  print q(    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c3">INSTRUCTIONS</span>
    </p>
    <p class="c1">
      <span class="c3">If this is your first time doing the net, or
it has been a while, please </span><span class="c22">read this entire
document</span><span class="c3"> so you are familiar with the various
sections.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c3">The following provides information on how to
read the MARC script below. As always, if you have questions, please
contact our Secretary, Brad (KJ7RPV) at KJ7RPV@yahoo.com or any member
of the board. &nbsp;Note that while you are doing the net, you will be
operating under our club call sign, N7MRY. &nbsp;You will still need
to ID at the beginning and end of the net with your own call
sign. &nbsp;In addition, if the net takes more than an hour, you will
need to identify at least once per hour with your own call sign.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <a id="t.827bf7da763e440927a54d1c498e827494117b98"></a>
    <a id="t.0"></a>
    <table class="c6">
      <tbody>
        <tr class="c4">
          <td class="c12" colspan="1" rowspan="1">
            <p class="c8">
              <span class="c3">AS WRITTEN IN SCRIPT</span>
            </p>
          </td>
          <td class="c9" colspan="1" rowspan="1">
            <p class="c8">
              <span class="c3">WHAT IS MEANT</span>
            </p>
          </td>
        </tr>
        <tr class="c4">
          <td class="c12" colspan="1" rowspan="1">
            <p class="c8">
              <span class="c3">[ Text in Square Brackets ]</span>
            </p>
          </td>
          <td class="c9" colspan="1" rowspan="1">
            <p class="c8">
              <span class="c3">Identifies sections of the
script&hellip; don&rsquo;t read this text.</span>
            </p>
          </td>
        </tr>
        <tr class="c4">
          <td class="c12" colspan="1" rowspan="1">
            <p class="c8">
              <span class="c0">Italic Red Text</span>
            </p>
          </td>
          <td class="c9" colspan="1" rowspan="1">
            <p class="c8">
              <span class="c3">This is instructional text for you,
the net control. &nbsp;Do not read this text out loud.</span>
            </p>
          </td>
        </tr>
        <tr class="c4">
          <td class="c12" colspan="1" rowspan="1">
            <p class="c8">
              <span class="c3">Regular Text</span>
            </p>
          </td>
          <td class="c9" colspan="1" rowspan="1">
            <p class="c8">
              <span class="c3">This is the text that you read
aloud. &nbsp;Feel free to ad-lib as desired.</span>
            </p>
          </td>
        </tr>
        <tr class="c4">
          <td class="c12" colspan="1" rowspan="1">
            <p class="c8">
              <span>[ </span>
              <span class="c18">Pause for reset</span>
              <span class="c3">&nbsp;]</span>
            </p>
          </td>
          <td class="c9" colspan="1" rowspan="1">
            <p class="c8">
              <span class="c3">Unkey and wait two or three
seconds. &nbsp;This is done to allow the repeater to reset so you
don&rsquo;t get cut off in the middle of a section and to allow
anyone with urgent traffic to break in.</span>
            </p>
            <p class="c8 c2">
              <span class="c3"></span>
            </p>
            <p class="c8">
              <span class="c3">You do NOT need to wait for this
to pause&hellip; pause whenever you feel like it.</span>
            </p>
          </td>
        </tr>
        <tr class="c4">
          <td class="c12" colspan="1" rowspan="1">
            <p class="c8">
              <span class="c20 c17">Blue Text</span>
            </p>
          </td>
          <td class="c9" colspan="1" rowspan="1">
            <p class="c8">
              <span class="c3">This is to be read if someone will
be providing training. &nbsp;If there is no training planned, skip
this section.</span>
            </p>
          </td>
        </tr>
      </tbody>
    </table>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <hr style="page-break-before:always;display:none;">
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c3">[ Preamble ]</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c3">Calling the Murray Amateur Radio Club Sunday
evening net. This net meets every Sunday evening at 8 PM on this
repeater, 147.16 megaHertz, positive offset, with a tone of 127.3
Hertz. Thanks to the Salt Lake Crossroads Amateur Radio Club for
allowing us to use this repeater, which is located on Ensign Peak.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span>This net is open to all licensed amateurs. I am </span>
      <span class="c22">);
  print param('NetControlOperator');
  print q(</span><span class="c3">, control operator for tonight&#39;s
net, operating under our club callsign, November 7 Mike Romeo Yankee.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span>This is a directed net. Please do not transmit without
approval from net control. If you need to interrupt the net for emergency
traffic at any time, wait for a pause when the repeater drops, and
announce, &quot;break with urgent traffic.&quot; &nbsp;[ </span>
      <span class="c18">Pause for reset </span>
      <span class="c3">]</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c3">This net is sponsored by the Murray Amateur Radio
Club. For details and contact info, visit our website, murrayarc.org.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c3">We hold club meetings in-person at Murray Fire
Station Number 81. The address is 4848 South Box Elder Street,
approximately 35 West. We meet at 6:30 PM Mountain Time on the first
three Thursdays of each month.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span>Meeting announcements are sent to the marc-announce mailing
list. &nbsp;See the web site for details. &nbsp;[ </span>
      <span class="c18">Pause for reset</span>
      <span class="c3">&nbsp;]</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c3">[ Upcoming Meeting Information ]</span>
    </p>
    <p class="c1">
      <span class="c0"></span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span>Our next meeting will be on </span><span class="c22">);
  print param('NextMeetingDate');
  print q(</span><span>. &nbsp;);
  if (param('NextMeetingTopic') ne '') {
      print q(The topic of the meeting will be </span><span class="c22">);
      print param('NextMeetingTopic');
      print q(</span><span>.  );
  }
  print q(The meeting
will start at 6:30 PM, and we will have a brief net prior to the
meeting at 6:00 PM );

  my $nmt = param('NextMeetingType');
  if ($nmt eq 'first' ) {
    print q(on our club&rsquo;s repeater, 223.96 MHz, with a tone of 103.5 Hz);
  } elsif ($nmt eq 'second') {
    print q(on 223.44 MHz simplex, with no tone);
  } elsif ($nmt eq 'third') {
    print q(on 147.6 MHz simplex, with no tone);
  } else {
    die "unknown Next Meeting Type parameter: $nmt\n";
  }
  print q(.</span></p>);

  if (param('Training') eq 'will') {
    print q(<p class="c1 c2">
      <span class="c3"></span>
    </p>
<p class="c1">
      <span class="c3">[ TRAINING read the following in blue ]</span>
    </p>
    <p class="c1">
      <span class="c17">After our roll call, we will have some brief
instruction from </span>
      <span class="c16">);
    print param('TrainingOperator');
    print q(</span><span class="c17 c20">.</span>
    </p>);
  }

  print q(<p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span>[ </span>
      <span class="c18">Pause for reset</span>
      <span class="c3">&nbsp;]</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c3">[ Roll Call and Traffic ]</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c3">This is N7MRY, Net Control for the Murray Amateur
Radio Club Sunday evening net. We&#39;ll now proceed with roll call.
I&rsquo;ll call your name and call sign. When you respond, let me know
if you have traffic, and I&rsquo;ll get back to you after the roll
call.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c3">After roll call, I will ask for any visitors. If
you are new to our net, give me your call sign slowly, in standard
phonetics, so I can copy it down.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c0">During roll call, jot down the name and call
of those people who said they have traffic. After roll call, turn the
net over to anyone who has traffic. Call on each one in turn to discuss
their traffic. </span>
    </p>
    <p class="c1 c2">
      <span class="c0"></span>
    </p>
    <p class="c1">
      <span class="c0">As an example, if Gordon has club announcements
he will state during roll call that he has traffic and that he would
like to be the last person to give his traffic. Once all others are
done with their traffic simply turn the time over to Gordon at the end.
When Gordon is done he will turn it back to the Net Control Station,
which is you :-&#41;</span>
    </p>
    <p class="c1 c2">
      <span class="c0"></span>
    </p>
    <p class="c1">
      <span class="c0">Make sure to give the station(s) with traffic
an opportunity to sign at the end of their &#8310;traffic. &nbsp;If
they have not, remind them to do so before moving on to the next station
with traffic.</span>
    </p>
    <p class="c1 c2">
      <span class="c0"></span>
    </p>
    <p class="c1">
      <span class="c5">You also need to ID, as N7MRY, if the roll call
takes more than 10 minutes. &nbsp;</span>
      <span class="c0">It is a good idea to do it about halfway through
the roll, or whenever you hear the repeater ID.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
);

  if (param('Training') eq 'will') {
    print q(    <p class="c1">
      <span class="c3">[ TRAINING read the following in blue ]</span>
    </p>
    <p class="c1">
      <span class="c17">This is N7MRY, Net Control for the Murray Amateur
Radio Club Sunday evening net. I am now going to turn the net over to </span>
      <span class="c16">);
    print param('TrainingOperator');
    print q(</span><span class="c17"> for our training.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>);
  }
  print q(    <p class="c1">
      <span class="c3">[ After Roll Call and Training (if any) ]</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c3">This is N7MRY, Net Control for the Murray Amateur
Radio Club Sunday evening net. Before I close this net, are there any
more late check-ins? &nbsp;If so, please come now with your call sign,
name and location.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c0">Accept additional check-ins and visitors as
above.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c3">[ ENDING ]</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c3">We&#39;ll now close this session of the Murray
Amateur Radio Club Sunday evening net. &nbsp;Thanks again to the Salt
Lake Crossroads Amateur Radio Club for the use of this repeater.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span>73 to all. &nbsp;This is </span>
      <span class="c22">);
  print param('NetControlOperator');
  print q(</span><span class="c3">, control operator for N7MRY, wishing all
a good evening, and returning this repeater to normal amateur radio
use.</span>
    </p>
    <p class="c1 c2">
      <span class="c3"></span>
    </p>
    <p class="c1">
      <span class="c0">It is generally a good idea to stand by for a few
minutes after the net is complete in case there are additional calls for
you.</span>
    </p></body></html>);
}

# argument is meeting date in this format:  "19 May 2022"
# NOTE, no commas!
#
# return is undef if date not found
# return is arrayref containing date, type, topic, instructor
sub get_meeting_topic() {
  my $target_date = shift;

  my %auth = (
    class        => 'OAuth2Client',
    client_id    => $auth_client_id,
    client_secret => $auth_client_secret,
    token_file    => "$config_dir/token_file",
  );

  my $rest_api = Google::RestApi->new(
    auth         => \%auth,
    timeout      => 10,
#   throttle     => 1,
  );

  my $sheets_api = Google::RestApi::SheetsApi4->new(api => $rest_api);
  my $sheet = $sheets_api->open_spreadsheet(title => 'MARC Class Schedule');
  my $ws = $sheet->open_worksheet(name => 'Schedule');

  my $date_col = $ws->range_col(1);
  my $range = $date_col->values();
  my @dates = @{$range};

  my $target_row;
  for (my $count = 0; $count <= $#dates; $count++) {
    if ($dates[$count] eq $target_date) {
      $target_row = $count + 1;
      # print "found $target_date at row $target_row\n";
      last;
    }
  }
  return unless defined $target_row;

  my $row = $ws->range_row({row => $target_row});
  return([$row->values()->[0], $row->values()->[1],
          $row->values()->[2], $row->values()->[3]]);
}
