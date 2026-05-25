<?php

$config['kolab_cache'] = true;
$config['kolab_format_version'] = '3.0';
$config['kolab_freebusy_server'] = null;
$config['kolab_use_subscriptions'] = false;
$config['kolab_skip_namespace'] = null;
$config['kolab_custom_display_names'] = false;
$config['kolab_http_request'] = [];
$config['kolab_messages_cache_bypass'] = 0;
$config['kolab_event_scheduling_properties'] = ['start', 'end', 'allday', 'recurrence', 'location', 'status', 'cancelled'];
$config['kolab_task_scheduling_properties'] = ['start', 'due', 'summary', 'status'];
$config['kolab_users_directory'] = null;
$config['kolab_users_filter'] = '(&(objectclass=kolabInetOrgPerson)(|(uid=%u)(mail=%fu)))';
$config['kolab_users_id_attrib'] = null;
$config['kolab_users_search_attrib'] = ['cn', 'mail', 'alias'];
$config['kolab_users_name_field'] = null;
$config['kolab_users_cache'] = null;
$config['kolab_users_cache_ttl'] = '10d';
$config['kolab_dav_sharing'] = null;
$config['kolab_bonnie_api'] = null;
