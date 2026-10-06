<?php

function render_marc_upcoming_meetings() {
    $url = '<INSERT WEB APP URL HERE>';
    
    // Fetch the JSON feed (with a short transient cache so it loads fast)
    $response = get_transient('marc_upcoming_meetings');
    if (false === $response) {
        $api_response = wp_remote_get($url);
        if (is_wp_error($api_response)) {
            return '<p>Unable to load upcoming meetings at this time.</p>';
        }
        $response = wp_remote_retrieve_body($api_response);
        set_transient('marc_upcoming_meetings', $response, HOUR_IN_SECONDS); // Caches for 1 hour
    }
    
    $meetings = json_decode($response, true);
    if (empty($meetings)) {
        return '<p>No upcoming meetings scheduled right now.</p>';
    }
    
    $html = '<ul class="marc-meeting-list">';
    foreach ($meetings as $meeting) {
        $html .= '<li>' . esc_html($meeting['topic']) . ' - ' . esc_html($meeting['date']) . ' </li>';
    }
    $html .= '</ul>';
    
    return $html;
}

add_shortcode('upcoming_meetings', 'render_marc_upcoming_meetings');

>
