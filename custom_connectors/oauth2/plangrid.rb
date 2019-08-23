{
  title: 'PlanGrid',
  connection: {
    fields: [
      {
        name: 'client_id',
        label: 'Client ID',
        optional: false,
        hint: 'To create client id, you need to register an application' \
        ' under Admin Console => Project => Oauth => Create Oauth app'
      },
      {
        name: 'client_secret',
        label: 'Client secret',
        control_type: 'password',
        optional: false,
        hint: 'To create client id, you need to register an application' \
        ' under Admin Console => Project => Oauth => Create Oauth app'
      }
    ],
    authorization: {
      type: 'oauth2',
      authorization_url: lambda do |connection|
        'https://io.plangrid.com/oauth/authorize?response_type=' \
        "code&client_id=#{connection['client_id']}&" \
        'scope=write:projects%20read:profile'
      end,
      acquire: lambda do |connection, auth_code, redirect_uri|
        response = post('https://io.plangrid.com/oauth/token').
                   payload(client_id: connection['client_id'],
                           client_secret: connection['client_secret'],
                           grant_type: 'authorization_code',
                           code: auth_code,
                           redirect_uri: redirect_uri).
                   request_format_www_form_urlencoded
        [response, nil, nil]
      end,
      refresh_on: [401, 403],
      refresh: lambda do |_connection, refresh_token|
        post('https://io.plangrid.com/oauth/token').
          payload(grant_type: 'refresh_token',
                  refresh_token: refresh_token).
          request_format_www_form_urlencoded
      end,
      apply: lambda do |_connection, access_token|
        if current_url.include?('https://io.plangrid.com')
          headers(Authorization: "Bearer #{access_token}",
                  Accept: 'application/vnd.plangrid+json; version=1')
        end
      end
    },
    base_uri: lambda do |_connection|
      'https://io.plangrid.com'
    end
  },
  test: ->(_connection) { get('/me') },
  object_definitions: {
    project: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project ID',
            sticky: true,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'uid',
              type: 'string',
              control_type: 'text',
              sticky: true,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              ' 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'name', label: 'Project Name', sticky: true },
          { name: 'custom_id', label: 'Project Code', sticky: true },
          { name: 'organization_id', label: 'Organization ID' },
          { name: 'type', control_type: 'select',
            label: 'Project Type', sticky: true,
            pick_list: 'project_types',
            toggle_hint: 'Select project type',
            toggle_field: {
              name: 'type',
              label: 'Project type',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Project type with possible values of general,' \
              ' manufacturing, power, water-sewer-waste, industrial-' \
              'petroleum, transportation, hazardous-waste, telecom, ' \
              'education-k-12, education-higher, gov-federal, ' \
              'gov-state-local, or other'
            } },
          { name: 'status', label: 'Project Status', sticky: true },
          { name: 'owner', sticky: true, label: 'Project Owner' },
          { name: 'start_date', type: 'date',
            sticky: true,
            render_input: 'date_conversion',
            parse_output: 'date_conversion',
            label: 'Project Start Date',
            hint: 'Project start date. ISO-8601 date format (YYYY-MM-DD).' },
          { name: 'end_date', type: 'date',
            sticky: true,
            render_input: 'date_conversion',
            parse_output: 'date_conversion',
            label: 'Project End Date',
            hint: 'Project end date. ISO-8601 date format (YYYY-MM-DD).' },
          { name: 'street_1', sticky: true,
            label: 'Street Line 1' },
          { name: 'street_2', sticky: true, label: 'Street line 2' },
          { name: 'city', sticky: true, label: 'Town or City' },
          { name: 'region', sticky: true, label: 'State, Province, or Region' },
          { name: 'postal_code', sticky: true, label: 'Zip or Postal Code' },
          { name: 'country',
            sticky: true,
            hint: 'Project address country in 2-letter ISO 3166 code.' },
          { name: 'latitude' },
          { name: 'longitude' },
          { name: 'updated_at', type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            label: 'Updated at' }
        ]
      end
    },
    document: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'uid', label: 'Document ID' },
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project ID',
            sticky: true,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              sticky: true,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              ' 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'name', label: 'Document Name' },
          { name: 'folder' },
          { name: 'url' },
          { name: 'created_at', type: 'date_time',
            render_input: 'parse_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'created_by', type: 'object', properties: [
            { name: 'uid', label: 'UID' },
            { name: 'url' },
            { name: 'email' }
          ] },
          { name: 'deleted', type: 'boolean' },
          { name: 'updated_at', type: 'date_time',
            render_input: 'parse_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' }
        ]
      end
    },
    task: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'uid', label: 'Task ID' },
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            sticky: true,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              sticky: true,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              ' 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'assignees', type: 'array', of: 'object', properties: [
            { name: 'assignee' }
          ] },
          { name: 'closed_at', type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' },
          { name: 'created_at', type: 'date_time',
            render_input: 'render_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'created_by', type: 'object', properties: [
            { name: 'uid' },
            { name: 'url' },
            { name: 'email' }
          ] },
          { name: 'comments', type: 'object', properties: [
            { name: 'total_count', type: 'integer' },
            { name: 'url' }
          ] },
          { name: 'cost_impact', type: 'number' },
          { name: 'has_cost_impact', type: 'boolean',
            control_type: 'checkbox', toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'cost_impact',
              label: 'Cost impact',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'currency_code',
            hint: 'The ISO-4217 currency code of the cost_impact,' \
            ' Currently only supports USD. maybe null if cost_impact is ' \
            'not specified' },
          { name: 'current_annotation', type: 'object', properties: [
            { name: 'uid' },
            { name: 'color' },
            { name: 'stamp' },
            { name: 'visibility' },
            { name: 'deleted', type: 'boolean',
              control_type: 'checkbox', toggle_hint: 'Select from options list',
              toggle_field: {
                name: 'deleted',
                label: 'Deleted',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false'
              } },
            { name: 'sheet', type: 'object', properties: [
              { name: 'uid' },
              { name: 'url' }
            ] }
          ] },
          { name: 'deleted', type: 'boolean',
            control_type: 'checkbox', toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'deleted',
              label: 'Deleted',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'description' },
          { name: 'due_at', type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' },
          { name: 'followers', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'uid' }
          ] },
          { name: 'issue_list', type: 'object', properties: [
            { name: 'uid' },
            { name: 'url' }
          ] },
          { name: 'number', type: 'number' },
          { name: 'photos', type: 'object', properties: [
            { name: 'total_count', type: 'integer' },
            { name: 'url' }
          ] },
          { name: 'room' },
          { name: 'schedule_impact', type: 'integer' },
          { name: 'has_schedule_impact', type: 'boolean',
            control_type: 'checkbox', toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'has_schedule_impact',
              label: 'Has schedule impact',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'start_date',
            type: 'date_time',
            render_input: 'date_conversion',
            parse_output: 'date_conversion' },
          { name: 'status', control_type: 'select', pick_list:
            %w[open in_review pending closed].select { |op| [op.labelize, op] },
            toggle_hint: 'Select status',
            toggle_field: {
              name: 'status',
              label: 'Status',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are : <b>"open", "in_review", "pending",' \
              ' "closed"</b>.'
            } },
          { name: 'string',
            hint: 'One to two character stamp associated with task.' },
          { name: 'title' },
          { name: 'type', control_type: 'select',
            pick_list: [
              %w[issue issue],
              %w[Planned\ work planned_work],
              %w[other other]
            ],
            toggle_hint: 'Select type',
            toggle_field: {
              name: 'type',
              label: 'Type',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>"issue", "planned_work",' \
              ' "other"</b>.'
            } },
          { name: 'updated_at',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time' },
          { name: 'updated_by', type: 'object', properties: [
            { name: 'uid' },
            { name: 'url' },
            { name: 'email' }
          ] }

        ]
      end
    },
    file_upload: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'uid' },
          { name: 'aws_post_form_arguments', type: 'object',
            properties: [
              { name: 'action' },
              { name: 'fields', type: 'array', of: 'object', properties: [
                { name: 'name' },
                { name: 'value' }
              ] }
            ] },
          { name: 'webhook_url' }
        ]
      end
    },
    annotation: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'uid', label: 'Annotation ID' },
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project ID',
            sticky: true,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              sticky: true,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              ' 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'color' },
          { name: 'stamp' },
          { name: 'visibility' },
          { name: 'deleted', type: 'boolean',
            control_type: 'checkbox', toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'deleted',
              label: 'Deleted',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'sheet', type: 'object', properties: [
            { name: 'uid', label: 'UID' },
            { name: 'url' }
          ] }
        ]
      end
    },
    snapshot: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'uid', label: 'Snapshot ID' },
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project ID',
            sticky: true,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              sticky: true,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              ' 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'title' },
          { name: 'url' },
          { name: 'created_at', type: 'date_time',
            render_input: 'parse_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'created_by', type: 'object', properties: [
            { name: 'uid', label: 'UID' },
            { name: 'url' },
            { name: 'email' }
          ] },
          { name: 'sheet', type: 'object', properties: [
            { name: 'uid', label: 'UID' },
            { name: 'url' }
          ] },
          { name: 'deleted', type: 'boolean',
            control_type: 'checkbox', toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'deleted',
              label: 'Deleted',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } }
        ]
      end
    },
    photo: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'uid', label: 'Photo ID' },
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project ID',
            sticky: true,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              sticky: true,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              ' 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'title' },
          { name: 'url', label: 'URL' },
          { name: 'created_at', type: 'date_time',
            render_input: 'parse_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'created_by', type: 'object', properties: [
            { name: 'uid', label: 'UID' },
            { name: 'url' },
            { name: 'email' }
          ] },
          { name: 'deleted', type: 'boolean' }
        ]
      end
    },
    field_report: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'uid', label: 'File report ID' },
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            sticky: true,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              sticky: true,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              ' 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'title' },
          { name: 'description' },
          { name: 'report_date', type: 'date_time',
            render_input: 'parse_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'field_report_type', type: 'object', properties: [
            { name: 'name' },
            { name: 'project_uid' },
            { name: 'status' },
            { name: 'uid' }
          ] },
          { name: 'pdf_url' },
          { name: 'pdf_form_values', type: 'array', of: 'object',
            properties: [
              { name: 'name' },
              { name: 'value' }
            ] },
          { name: 'pg_form_values', type: 'array', of: 'object', properties: [
            { name: 'pg_equipment_entries', type: 'array', of: 'object',
              properties: [
                { name: 'uid' },
                { name: 'timespan' },
                { name: 'quantity', type: 'integer' },
                { name: 'item' },
                { name: 'description' },
                { name: 'deleted', type: 'boolean',
                  control_type: 'checkbox',
                  toggle_hint: 'Select from options list',
                  toggle_field: {
                    name: 'deleted',
                    label: 'Deleted',
                    type: 'string',
                    control_type: 'text',
                    toggle_hint: 'Use custom value',
                    hint: 'Allowed values are: true, false'
                  } }
              ] },
            { name: 'pg_materials_entries', type: 'array', of: 'object',
              properties: [
                { name: 'uid' },
                { name: 'unit', type: 'integer' },
                { name: 'quantity', type: 'integer' },
                { name: 'item' },
                { name: 'description' },
                { name: 'deleted' }
              ] },
            { name: 'pg_worklog_entries', type: 'array', of: 'object',
              properties: [
                { name: 'uid' },
                { name: 'trade' },
                { name: 'timespan' },
                { name: 'headcount', type: 'integer' },
                { name: 'description' },
                { name: 'deleted', type: 'boolean',
                  control_type: 'checkbox',
                  toggle_hint: 'Select from options list',
                  toggle_field: {
                    name: 'deleted',
                    label: 'Deleted',
                    type: 'string',
                    control_type: 'text',
                    toggle_hint: 'Use custom value',
                    hint: 'Allowed values are: true, false'
                  } }
              ] }
          ] },
          { name: 'attachments', type: 'object', properties: [
            { name: 'total_count', type: 'integer' },
            { name: 'url' }
          ] },
          { name: 'created_by', type: 'object', properties: [
            { name: 'email' },
            { name: 'uid' },
            { name: 'url' }
          ] },
          { name: 'photos', type: 'object', properties: [
            { name: 'total_count', type: 'integer' },
            { name: 'url' }
          ] },
          { name: 'project_uid', label: 'Project ID' },
          { name: 'report_date', type: 'date' },
          { name: 'snapshots', type: 'object', properties: [
            { name: 'total_count', type: 'integer' },
            { name: 'url' }
          ] },
          { name: 'status' },
          { name: 'updated_at', type: 'date_time',
            render_input: 'parse_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'weather', type: 'object', properties: [
            { name: 'humidity', type: 'number' },
            { name: 'precipitation_accumulation', type: 'number' },
            { name: 'precipitation_accumulation_unit' },
            { name: 'speed_unit' },
            { name: 'summary_key' },
            { name: 'temperature_max', type: 'integer' },
            { name: 'temperature_min' },
            { name: 'temperature_unit' },
            { name: 'wind_bearing', type: 'integer' },
            { name: 'wind_gust', type: 'number' },
            { name: 'wind_speed', type: 'number' }
          ] }
        ]
      end
    },
    rfi: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'uid', label: 'RFI ID' },
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            sticky: true,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              sticky: true,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              ' 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'number', type: 'integer' },
          { name: 'status', type: 'object', properties: [
            { name: 'uid' },
            { name: 'label' },
            { name: 'color' }
          ] },
          { name: 'locked', type: 'boolean',
            control_type: 'checkbox', toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'locked',
              label: 'Locked',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'title' },
          { name: 'question' },
          { name: 'answer' },
          { name: 'sent_at', type: 'date_time',
            render_input: 'parse_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp',
            hint: 'Date when the RFI was sent. See ' \
            "<a href='https://developer.plangrid.com/v1.15/docs/" \
            "timestamps-and-timezones' target='_blank'>Timestamps and " \
            'Timezones</a> for accepted date formats' },
          { name: 'due_at', type: 'date_time',
            render_input: 'parse_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'assigned_to_uids',
            hint: 'Array of unique identifiers of users who ' \
            'are RFI assignees.' },
          { name: 'assigned_to', type: 'array', of: 'object',
            properties: [
              { name: 'uid' },
              { name: 'url' },
              { name: 'email' }
            ] },
          { name: 'updated_at', type: 'date_time',
            render_input: 'parse_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp',
            hint: 'Date when the RFI was sent. See ' \
            "<a href='https://developer.plangrid.com/v1.15/docs/" \
            "timestamps-and-timezones' target='_blank'>Timestamps and " \
            'Timezones</a> for accepted date formats' },
          { name: 'updated_by', type: 'object', properties: [
            { name: 'uid' },
            { name: 'url' },
            { name: 'email' }
          ] },
          { name: 'created_at', type: 'date_time',
            render_input: 'parse_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'created_by', type: 'object', properties: [
            { name: 'uid' },
            { name: 'url' },
            { name: 'email' }
          ] },
          { name: 'photos', type: 'object', properties: [
            { name: 'total_count', type: 'integer' },
            { name: 'url' }
          ] },
          { name: 'attachments', type: 'object', properties: [
            { name: 'total_count', type: 'integer' },
            { name: 'url' }
          ] },
          { name: 'snapshots', type: 'object', properties: [
            { name: 'total_count', type: 'integer' },
            { name: 'url' }
          ] },
          { name: 'comments', type: 'object', properties: [
            { name: 'total_count', type: 'integer' },
            { name: 'url' }
          ] }
        ]
      end
    },
    rfi_status: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'uid', label: 'RFI status ID' },
          { name: 'label' },
          { name: 'color' }
        ]
      end
    },
    user: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'uid', label: 'User ID' },
          { name: 'email' },
          { name: 'first_name' },
          { name: 'last_name' },
          { name: 'language' },
          { name: 'role', type: 'object', properties: [
            { name: 'uid' },
            { name: 'url' }
          ] },
          { name: 'removed' }
        ]
      end
    },
    sheet: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'uid', label: 'Sheet ID' },
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project ID',
            sticky: true,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              sticky: true,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              ' 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'name' },
          { name: 'version_name', label: 'Version Name' },
          { name: 'description' },
          { name: 'tags', type: 'array', of: 'string', hint: 'An array of strings representing the' \
            ' tags added to this sheet.' },
          { name: 'published_by', type: 'object', properties: [
            { name: 'uid', label: 'UID' },
            { name: 'url' },
            { name: 'email' }
          ] },
          { name: 'published_at', type: 'date_time',
            render_input: 'parse_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp',
            hint: 'UTC date and time in ISO-8601 format.' },
          { name: 'deleted', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'deleted',
              label: 'Deleted',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'uploaded_file_name', label: 'Uploaded file name' }
        ]
      end
    },
    sheet_packet: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'uid', label: 'Sheet packet ID' },
          { name: 'file_url' },
          { name: 'resource', type: 'object', properties: [
            { name: 'uid' },
            { name: 'url' }
          ] },
          { name: 'status' }
        ]
      end
    },
    custom_action_input: {
      fields: lambda do |_connection, config_fields|
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')

        [
          {
            name: 'path',
            optional: false,
            hint: 'Base URI is <b>https://io.plangrid.com' \
              '</b> - path will be appended to this URI. ' \
              'Use absolute URI to override this base URI.'
          },
          (
            if %w[get delete].include?(config_fields['verb'])
              {
                name: 'input',
                type: 'object',
                control_type: 'form-schema-builder',
                sticky: input_schema.blank?,
                label: 'URL parameters',
                add_field_label: 'Add URL parameter',
                properties: [
                  {
                    name: 'schema',
                    extends_schema: true,
                    sticky: input_schema.blank?
                  },
                  (
                    if input_schema.present?
                      {
                        name: 'data',
                        type: 'object',
                        properties: call('make_schema_builder_fields_sticky',
                                         input_schema)
                      }
                    end
                  )
                ].compact
              }
            else
              {
                name: 'input',
                type: 'object',
                properties: [
                  {
                    name: 'schema',
                    extends_schema: true,
                    schema_neutral: true,
                    control_type: 'schema-designer',
                    sample_data_type: 'json_input',
                    sticky: input_schema.blank?,
                    label: 'Request body parameters',
                    add_field_label: 'Add request body parameter'
                  },
                  (
                    if input_schema.present?
                      {
                        name: 'data',
                        type: 'object',
                        properties: call('make_schema_builder_fields_sticky',
                                         input_schema)
                      }
                    end
                  )
                ].compact
              }
            end
          ),
          {
            name: 'output',
            control_type: 'schema-designer',
            sample_data_type: 'json_http',
            extends_schema: true,
            schema_neutral: true,
            sticky: true
          }
        ]
      end
    },
    custom_action_output: {
      fields: lambda do |_connection, config_fields|
        parse_json(config_fields['output'] || '[]')
      end
    }
  },
  actions: {
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
        "in <span class='provider'>Plangrid</span>",
      help: {
        body: 'Build your own Plangrid action for any Plangrid ' \
        'REST endpoint.',
        learn_more_url: 'https://developer.plangrid.com/docs/',
        learn_more_text: 'The Plangrid API documentation'
      },
      config_fields: [{
        name: 'verb',
        label: 'Request type',
        hint: 'Select HTTP method of the request',
        optional: false,
        control_type: 'select',
        pick_list: %w[get post patch delete].map { |verb| [verb.upcase, verb] }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['custom_action_input']
      end,

      execute: lambda do |_connection, input|
        verb = input['verb']
        error("#{verb} not supported") if %w[get post put delete].exclude?(verb)
        data = input.dig('input', 'data').presence || {}
        case verb
        when 'get'
          response =
            get(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact

          if response.is_a?(Array)
            array_name = parse_json(input['output'] || '[]').
                         dig(0, 'name') || 'array'
            { array_name.to_s => response }
          elsif response.is_a?(Hash)
            response
          else
            error('API response is not a JSON')
          end
        when 'post'
          post(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact
        when 'patch'
          patch(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact
        when 'delete'
          delete(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['custom_action_output']
      end
    },
    create_project: {
      title: 'Create project',
      description: 'Create <span class="provider">project</span> in'\
        ' <span class="provider">PlanGrid</span>',
      help: {
        body: 'Create project action uses the' \
        " <a href='https://developer.plangrid.com/docs/create-project'" \
        " target='_blank'>Create Project</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/create-project',
        learn_more_text: 'Create Project'
      },
      input_fields: lambda do |object_definitions|
        [
          { name: 'add_to_organization', type: 'boolean',
            control_type: 'checkbox', toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'add_to_organization',
              label: 'Add to Organization',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            }
          }
        ].concat(object_definitions['project'].
          ignored('uid', 'updated_at', 'latitude', 'longitude',
                  'organization_id').
          required('name'))
      end,
      execute: lambda do |_connection, input|
        payload = input.each do |key, value|
            input[key].present? || input[key] = nil
          end
        post('projects').payload(payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['project']
      end,
      sample_output: lambda do |_connection, _input|
        get('/projects')&.dig('data', 0) || {}
      end
    },
    update_project: {
      title: 'Update project',
      description: 'Update <span class="provider">project</span> in'\
        ' <span class="provider">PlanGrid</span>',
      help: {
        body: 'Update project action uses the' \
        " <a href='https://developer.plangrid.com/docs/update-project'" \
        " target='_blank'>Update Project</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/update-project',
        learn_more_text: 'Update Project'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['project'].required('uid').
          ignored('updated_at', 'latitude', 'longitude', 'organization_id')
      end,
      execute: lambda do |_connection, input|
        payload = input.each do |key, value|
            input[key].present? || input[key] = nil
          end
        patch("/projects/#{input.delete('uid')}").payload(payload.except('uid')).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['project']
      end,
      sample_output: lambda do |_connection, _input|
        get('/projects')&.dig('data', 0) || {}
      end
    },
    get_project_details: {
      title: 'Get project',
      description: 'Get <span class="provider">project</span>'\
        ' in <span class="provider">PlanGrid</span>',
      help: {
        body: 'Get project action uses the' \
        " <a href='https://developer.plangrid.com/docs/retrieve-a-project'" \
        " target='_blank'>Retrieve a Project</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/retrieve-a-project',
        learn_more_text: 'Retrieve a Project'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['project'].only('uid').required('uid')
      end,
      execute: lambda do |_connection, input|
        get("/projects/#{input['uid']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['project']
      end,
      sample_output: lambda do |_connection, _input|
        get('/projects')&.dig('data', 0) || {}
      end
    },
    upload_document: {
      title: 'Upload document to a project',
      description: 'Upload <span class="provider">document</span> to a'\
        ' <span class="provider">PlanGrid</span> project',
      help: {
        body: 'Upload document to a project action uses the' \
        " <a href='https://developer.plangrid.com/docs/upload-attachment' \
        '-to-project'" \
        " target='_blank'>Upload Document to Project API</a>.",
        learn_more_url: 'https://developer.plangrid.com/docs/upload-' \
        'attachment-to-project',
        learn_more_text: 'Upload Document to Project API'
      },
      summarize_input: %w[file_content],
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid', optional: false,
            label: 'Project',
            control_type: 'select', pick_list: 'project_list',
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Use Project ID e.g. 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'content_type',
            hint: 'Content type of the document\'s file. e.g. for pdf' \
            ' <b>application/pdf</b>', optional: false },
          { name: 'file_content', optional: false },
          { name: 'name', optional: false,
            label: 'Document name',
            hint: 'Name of the document.' },
          { name: 'folder', label: 'Folder', sticky: true,
            control_type: 'select',
            pick_list: 'project_folders',
            pick_list_params: { project_uid: 'project_uid' },
            toggle_hint: 'Select folder',
            hint: 'Folder shows in select options only if at least one file' \
            ' exist in the folder',
            toggle_field: {
              name: 'folder',
              label: 'Project folder',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Folder in project to place the document ' \
              '(case-sensitive). Leave blank to select root folder'
            } },
          { name: 'auto_version', type: 'boolean', sticky: true,
            control_type: 'checkbox',
            toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'auto_version',
              type: 'boolean',
              control_type: 'text',
              label: 'Auto version',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } }
        ]
      end,
      execute: lambda do |_connection, input|
        file_content = input.delete('file_content')
        project_uid = input['project_uid']
        payload = input.except(:project_uid)
        file_upload_info = post("/projects/#{project_uid}/" \
                    'attachments/uploads').
                           headers('Content-type': 'application/json').
                           payload(payload)
        url = file_upload_info&.dig('aws_post_form_arguments', 'action')
        fields = file_upload_info&.dig('aws_post_form_arguments', 'fields')
        # webhook_url = file_upload_info.
        #               dig('aws_post_form_arguments', 'webhook_url')
        headers = fields.map { |o| { o['name'] => o['value'] } }.inject(:merge)
        status =
          post(url).
          payload(key: headers['key'],
                  policy: headers['policy'],
                  signature: headers['signature'],
                  AWSAccessKeyId: headers['AWSAccessKeyId'],
                  'content-type': headers['Content-Type'],
                  'success_action_redirect': headers['success_action_redirect'],
                  'x-amz-server-side-encryption':
                    headers['x-amz-server-side-encryption'],
                  'x-amz-storage-class': headers['x-amz-storage-class'],
                  file: file_content).
          request_format_multipart_form.
          after_response do |_code, response, _response_headers|
            response
          end
        status.merge('project_uid' => project_uid)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['document']
      end,
      sample_output: lambda do |_connection, _input|
        {
          uid: '147a420e-a182-4312-8fa5-4d10064d2f1a',
          name: 'Bender',
          folder: 'Specifications',
          url: 'https://attachment-assets.plangrid.com/147a420e-a182-' \
          '4312-8fa5-4d10064d2f1a.pdf',
          created_at: '2013-05-17T02:30:22+00:00',
          created_by: {
            uid: null,
            url: null,
            email: 'nick@subcontractor.com'
          },
          deleted: false
        }
      end
    },
    update_document: {
      title: 'Update document in a project',
      description: 'Update <span class="provider">document</span> in a'\
        ' <span class="provider">PlanGrid</span> project',
      help: {
        body: 'Update document in a project action uses the' \
        " <a href='https://developer.plangrid.com/docs/update-photo-in-a-" \
        "project' target='_blank'>Update Document to Project API</a>.",
        learn_more_url: 'https://developer.plangrid.com/docs/update-attachment-' \
        'in-a-project',
        learn_more_text: 'Update Document in a Project API'
      },
      summarize_input: %w[file_content],
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid', optional: false,
            label: 'Project',
            control_type: 'select', pick_list: 'project_list',
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Use Project ID e.g. 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'attachment_uid', label: 'Document ID', optional: false },
          { name: 'name', label: 'Document Name',
            hint: 'New name of the document', sticky: true },
          { name: 'folder', label: 'Folder',
            hint: 'New folder of the document', sticky: true }
        ]
      end,
      execute: lambda do |_connection, input|
        project_uid = input.delete('project_uid')
        patch("/projects/#{project_uid}/attachments/" \
              "#{input.delete('attachment_uid')}").
          headers('Content-type': 'application/json').
          payload(input).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.merge('project_uid' => project_uid)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['document']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/attachments")&.dig('data', 0)&.
        merge('project_uid' => id) || {}
      end
    },
    create_rfi: {
      title: 'Create RFI in a project',
      description: 'Create <span class="provider">RFI</span> in'\
        ' a <span class="provider">Plangrid</span> project ',
      help: {
        body: 'Create RFI in project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/create-" \
        "rfi-in-a-project' target='_blank'>Create RFI in Project</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/create-rfi-' \
        'in-a-project',
        learn_more_text: 'Create RFI in a Project'
      },
      input_fields: lambda do |object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'status', label: 'Status',
            hint: 'Use this for create and update rfi status' }
        ].concat(object_definitions['rfi'].
          only('locked', 'title', 'question', 'answer', 'sent_at',
               'due_at', 'assigned_to_uids').
          required('title'))
      end,
      execute: lambda do |_connection, input|
        project_uid = input.delete('project_uid')
        payload = input&.map do |key, val|
          if %w[due_at sent_at].include?(key)
            { key => val.to_time.utc.iso8601 }
          else
            { key => val }
          end
        end&.inject(:merge)
        post("/projects/#{project_uid}/rfis").payload(payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.merge('project_uid' => project_uid)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['rfi']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/rfis")&.dig('data', 0) || {}
      end
    },
    update_rfi: {
      title: 'Update RFI in a project',
      description: 'Update <span class="provider">RFI</span> in'\
        ' a <span class="provider">Plangrid</span> project',
      help: {
        body: 'Update RFI in Project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/update-rfi-in-a-" \
        "project' target='_blank'>patchUpdate RFI in a Project</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/update-' \
        'rfi-in-a-project',
        learn_more_text: 'Update RFI in a Project'
      },
      input_fields: lambda do |object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'status', label: 'Status',
            hint: 'Use this for create and update rfi status' }
        ].concat(object_definitions['rfi'].
          only('uid', 'locked', 'title', 'question', 'answer', 'sent_at',
               'due_at', 'assigned_to_uids').
          required('uid'))
      end,
      execute: lambda do |_connection, input|
        project_uid = input.delete('project_uid')
        rfi_id = input.delete('uid')
        payload = input&.map do |key, val|
          if %w[due_at sent_at].include?(key)
            { key => val.to_time.utc.iso8601 }
          else
            { key => val }
          end
        end&.inject(:merge)
        patch("/projects/#{project_uid}/rfis/#{rfi_id}").payload(payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.merge('project_uid' => project_uid)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['rfi']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/rfis")&.dig('data', 0) || {}
      end
    },
    get_rfi_in_project: {
      title: 'Get RFI in a project',
      description: 'Get <span class="provider">RFI</span> by ID in'\
        ' <span class="provider">Plangrid</span> project',
      help: {
        body: 'Get RFI by ID in a project action uses the' \
        " <a href='https://developer.plangrid.com/docs/" \
        "retrieve-rfis-in-a-project'" \
        " target='_blank'>Retrieve RFI in a Project</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/" \
        "retrieve-rfis-in-a-project',
        learn_more_text: 'Retrieve RFI in a Project'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['rfi'].only('project_uid', 'uid').
          required('project_uid', 'uid')
      end,
      execute: lambda do |_connection, input|
        project_uid = input.delete('project_uid')
        get("/projects/#{project_uid}/rfis/#{input['uid']}")&.
          merge('project_uid' => project_uid)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['rfi']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/rfis")&.dig('data', 0)&.
          merge('project_uid' => id) || {}
      end
    },
    create_task: {
      title: 'Create task in a project',
      description: 'Create <span class="provider">task</span> in'\
        ' <span class="provider">Plangrid</span> project',
      help: {
        body: 'Create task in Project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/create-task-in-a-" \
        "project' target='_blank'>Create task in Project</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/create-task-in-' \
        'a-project',
        learn_more_text: 'Create Task in a Project'
      },
      input_fields: lambda do |object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              ' 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } }
        ].concat(object_definitions['task'].
          only('assigned_to_uids', 'cost_impact', 'description', 'due_at',
               'has_cost_impact', 'has_schedule_impact',
               'issue_list_uid', 'room', 'schedule_impact', 'start_date',
               'status', 'title', 'type'))
      end,
      execute: lambda do |_connection, input|
        project_uid = input.delete('project_uid')
        payload = input&.map do |key, val|
          if %w[due_at].include?(key)
            { key => val.to_time.utc.iso8601 }
          else
            { key => val }
          end
        end&.inject(:merge)
        post("/projects/#{project_uid}/issues").payload(payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.merge('project_uid' => project_uid)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['task']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/issues")&.dig('data', 0)&.
        merge('project_uid' => id) || {}
      end
    },
    update_task: {
      title: 'Update task in a Project',
      description: 'Update <span class="provider">task</span> in'\
        ' <span class="provider">Plangrid</span> project',
      help: {
        body: 'Update task in Project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/update-issue-in-a-" \
        "project' target='_blank'>Create task in Project</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/create-project',
        learn_more_text: 'Update Task in a Project'
      },
      input_fields: lambda do |object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g.' \
              ' 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } }
        ].concat(object_definitions['task'].
          only('uid', 'assigned_to_uids', 'cost_impact', 'description',
               'due_at', 'has_cost_impact', 'has_schedule_impact',
               'issue_list_uid', 'room', 'schedule_impact', 'start_date',
               'status', 'title', 'type').required('uid'))
      end,
      execute: lambda do |_connection, input|
        project_uid = input.delete('project_uid')
        patch("/projects/#{project_uid}/issues/" \
             "#{input.delete('uid')}").payload(input).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.merge('project_uid' => project_uid)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['task']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/issues")&.dig('data', 0)&.
        merge('project_uid' => id) || {}
      end
    },
    get_task: {
      title: 'Get task in a project',
      description: 'Get <span class="provider">task</span> in'\
        ' in a <span class="provider">Plangrid</span> project',
      help: {
        body: 'Get task in a project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/retrieve-issues-in-a-" \
        "project' target='_blank'>Retrieve Task in a Project</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/retrieve-' \
        'issues-in-a-project',
        learn_more_text: 'Retrieve Task in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'issue_uid', label: 'Issue ID', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        project_uid = input.delete('project_uid')
        get("/projects/#{project_uid}/issues/" \
             "#{input['issue_uid']}").
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.merge('project_uid' => project_uid)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['task']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/issues")&.dig('data', 0)&.
        merge('project_uid' => id) || {}
      end
    },
    invite_user_to_project: {
      title: 'Invite a user to a project',
      description: 'Invite <span class="provider">user</span> to'\
        ' project team <span class="provider">Plangrid</span>',
      help: {
        body: 'Invite user to a project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/invite-user-to-'" \
        "project-team' target='_blank'>Invite user in Project team</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/' \
        'invite-user-to-project-team',
        learn_more_text: 'Invite User to Project Team'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'email', optional: false },
          { name: 'role_uid', label: 'Role ID',
            hint: 'Unique identifier of role to assign user on project team' }
        ]
      end,
      execute: lambda do |_connection, input|
        post("/projects/#{input.delete('project_uid')}/users/invites").
          payload(input).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['user']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/users")&.dig('data', 0) || {}
      end
    },
    get_user_in_project: {
      title: 'Get user in project',
      description: 'Get <span class="provider">user</span> in'\
        ' <span class="provider">Plangrid</span> project',
      help: {
        body: 'Get user in project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/retrieve-users-on-a-" \
        "project-team' target='_blank'>Retrieve User on a Project Team</a>.",
        learn_more_url: 'https://developer.plangrid.com/docs/retrieve-' \
        'users-on-a-project-team',
        learn_more_text: 'Retrieve User on a Project Team'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'user_uid', label: 'User ID', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/projects/#{input['project_uid']}/users/" \
             "#{input['user_uid']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['user']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/users")&.dig('data', 0)&.
        merge('project_uid' => id) || {}
      end
    },
    get_snapshot_in_project: {
      title: 'Get snapshot in a project',
      description: 'Get <span class="provider">snapshot</span> in'\
        ' a <span class="provider">PlanGrid</span> project',
      help: {
        body: 'Get snapshot in a project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/retrieve-snapshot-" \
        "in-a-project' target='_blank'>Retrieve Snapshot in a Project</a>.",
        learn_more_url: 'https://developer.plangrid.com/docs/retrieve-' \
        'snapshot-in-a-project',
        learn_more_text: 'Retrieve Snapshot in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'snapshot_uid', label: 'Snapshot ID', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/projects/#{input['project_uid']}/snapshots/" \
             "#{input['snapshot_uid']}")&.merge('project_uid' => input['project_uid'])
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['snapshot']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/snapshots")&.dig('data', 0)&.
        merge('project_uid' => id) || {}
      end
    },
    get_rfi_statuses_in_project: {
      title: 'Get RFI statuses in project',
      description: 'Get <span class="provider">rfi statuses</span> in'\
        ' <span class="provider">Plangrid</span> project',
      help: {
        body: 'Get rfi statuses in project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/retrieve-rfi-statuses-" \
        "in-a-project' target='_blank'>Retrieve RFI Statuses in a Project</a>.",
        learn_more_url: 'https://developer.plangrid.com/docs/retrieve-' \
        'rfi-statuses-in-a-project',
        learn_more_text: 'Retrieve RFI Statuses in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'limit', type: 'integer',
            hint: 'Number of RFI statuses to retrieve. Maximum value of 50.' },
          { name: 'skip', type: 'integer',
            hint: 'Number of RFI statuses to skip in the set of results.' }
        ]
      end,
      execute: lambda do |_connection, input|
        { statuses:
          get("/projects/#{input['project_uid']}/rfis/statuses")['data'] }
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'statuses', type: 'array', of: 'object',
            properties: object_definitions['rfi_status'] }
        ]
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/rfis/statuses")&.dig('data', 0)&.
        merge('project_uid' => id) || {}
      end
    },
    get_roles_on_project: {
      title: 'Get roles on a project',
      description: 'Get <span class="provider">roles</span> on '\
        ' <span class="provider">Plangrid</span> project',
      help: {
        body: 'Get role on a project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/retrieve-role-" \
        "on-a-project' target='_blank'>Retrieve Role on a Project</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/' \
        'retrieve-role-on-a-project',
        learn_more_text: 'Retrieve Role on a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'limit', type: 'integer',
            hint: 'Number of roles to retrieve. Maximum value of 50.' },
          { name: 'skip', type: 'integer',
            hint: 'Number of roles to skip in the set of results.' }
        ]
      end,
      execute: lambda do |_connection, input|
        { roles: get("/projects/#{input.delete('project_uid')}/roles", input) }
      end,
      output_fields: lambda do |_object_definitions|
        [
          { name: 'roles', type: 'array', of: 'object', properties: [
            { name: 'uid' },
            { name: 'label' }
          ] },
          { name: 'total_count' },
          { name: 'next_page_url' }
        ]
      end,
      sample_output: lambda do |_connection, _input|
        { 'roles' => { 'uid' => '9d139e64-cac9-4f23-b4d5-9fd3688b498e',
                       'label' => 'Admin' } }
      end
    },
    get_sheets_in_project: {
      title: 'Get sheets in project',
      description: 'Get <span class="provider">sheets</span> in'\
        ' <span class="provider">Plangrid</span> project',
      help: {
        body: 'Get sheets in project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/retrieve-sheets-" \
        "in-a-project' target='_blank'>Retrieve Sheets in a Project</a>.",
        learn_more_url: 'https://developer.plangrid.com/docs/' \
        'retrieve-sheets-in-a-project',
        learn_more_text: 'Retrieve Sheets in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'limit', type: 'integer',
            hint: 'Number of sheets to retrieve. Maximum value of 50.' },
          { name: 'skip', type: 'integer',
            hint: 'Number of sheets to skip in the set of results' },
          { name: 'updated_after', type: 'date_time',
            hint: 'Only retrieve sheets created/updated after ' \
            'specified UTC date and time.' }
        ]
      end,
      execute: lambda do |_connection, input|
        { sheets: get("/projects/#{input.delete('project_uid')}/sheets",
                      input)['data'] }
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'sheets', type: 'array', of: 'object',
           properties: object_definitions['sheet'] }]
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        {
          sheets: get("/projects/#{id}/sheets?limit=1")&.dig('data', 0)&.
                  merge('project_uid' => id) || {}
        }
      end
    },
    get_sheet_in_project: {
      title: 'Get sheet in a project',
      description: 'Get <span class="provider">sheet</span> in '\
        'a <span class="provider">PlanGrid</span> project',
      help: {
        body: 'Get sheet in a project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/retrieve-a-sheet'" \
        " target='_blank'>Retrieve Sheet in a Project</a>.",
        learn_more_url: 'https://developer.plangrid.com/docs/' \
        'retrieve-a-sheet',
        learn_more_text: 'Retrieve Sheet in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project ID',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'sheet_uid', label: 'Sheet ID', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/projects/#{input['project_uid']}/sheets/#{input['sheet_uid']}")&.
        merge('project_uid' => input['project_uid'])
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['sheet']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/sheets?limit=1")&.dig('data', 0)&.
        merge('project_uid' => id) || {}
      end
    },
    get_project_sheet_packet: {
      title: 'Get project sheet packet',
      description: 'Get project <span class="provider">sheet packet</span> in'\
        ' packet in <span class="provider">Plangrid</span>',
      help: {
        body: 'Get project sheet packet action uses the ' \
        "<a href='https://developer.plangrid.com/docs/retrieve-sheet-packet'" \
        " target='_blank'>Retrieve Sheet Packet API</a>.",
        learn_more_url: 'https://developer.plangrid.com/docs/' \
        'retrieve-sheet-packet',
        learn_more_text: 'Retrieve Sheet Packet'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'packet_uid', type: 'Packet ID' }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/projects/#{input['project_uid']}/sheets/packets/" \
          "#{input['packet_uid']}")
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['sheet_packet']
      end
    },
    get_field_reports_in_project: {
      title: 'Get fields reports in project',
      description: 'Get <span class="provider">field reports</span> in'\
        ' in <span class="provider">Plangrid</span> project',
      help: {
        body: 'Get fields reports in project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/retrieve-field-reports-" \
        "in-a-project' target='_blank'>Retrieve Field Reports in a" \
        ' Project</a> API.',
        learn_more_url: 'https://developer.plangrid.com/docs/retrieve-' \
        'field-reports-in-a-project',
        learn_more_text: 'Retrieve Field Reports in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'updated_after', type: 'date_time',
            hint: 'Only retrieve field reports created/updated after ' \
            'specified UTC date and time.' },
          { name: 'report_date_min', type: 'date_time',
            label: 'Report start date',
            hint: 'Only retrieve field reports between a date range ' \
            'starting with this date in UTC format.' },
          { name: 'report_date_max', type: 'date_time',
            label: 'Report end date',
            hint: 'Only retrieve field reports between a date range ' \
            'starting with this date in UTC format.' },
          { name: 'sort_by', control_type: 'select',
            pick_list:
              %w[report_date updated_at]&.map { |e| [e.labelize, e] },
            toggle_hint: 'Select sort by column',
            toggle_field: {
              name: 'sort_by', type: 'string', control_type: 'text',
              hint: 'Allowed values report_date or updated_at'
            } }
        ]
      end,
      execute: lambda do |_connection, input|
        project_uid = input.delete('project_uid')
        query_params = ''
        input&.map do |key, val|
          if %w[updated_after report_date_min report_date_max].include?(key)
            query_params = query_params + "#{key}=#{val.to_time.utc.iso8601}"
          else
            query_params = query_params + "#{key}=#{val}"
          end
        end
        { field_reports: get("/projects/#{project_uid}/field_reports?" \
          "#{query_params}")['data'] }
      end,
      output_fields: lambda do |object_definitions|
        { name: 'field_reports', type: 'array', of: 'object',
          properties: object_definitions['field_report'] }
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        { field_reports:
          get("/projects/#{id}/rfis/field_reports")&.
          merge('project_uid' => id) || {} }
      end
    },
    upload_photo: {
      title: 'Upload photo to a project',
      description: 'Upload <span class="provider">photo</span> to '\
        ' a <span class="provider">PlanGrid</span> project',
      help: {
        body: 'Upload photo to a project action uses the' \
        " <a href='https://developer.plangrid.com/docs/upload-photo-" \
        "to-project' target='_blank'>Upload Photo to Project</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/upload-photo' \
        '-to-project',
        learn_more_text: 'Upload Photo to Project'
      },
      summarize_input: %w[file_content],
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid', optional: false,
            label: 'Project',
            control_type: 'select', pick_list: 'project_list',
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Use Project ID e.g. 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'content_type', optional: false,
            hint: "Content type of the photo's file" },
          { name: 'file_content', optional: false },
          { name: 'title', optional: false, label: 'Photo title' }
        ]
      end,
      execute: lambda do |_connection, input|
        project_uid = input.delete('project_uid')
        file_content = input.delete('file_content')
        payload = input.except(:project_uid)
        file_upload_info = post("/projects/#{project_uid}/" \
                    'photos/uploads').
                           headers('Content-type': 'application/json').
                           payload(payload)
        url = file_upload_info&.dig('aws_post_form_arguments', 'action')
        fields = file_upload_info&.dig('aws_post_form_arguments', 'fields')
        # webhook_url = file_upload_info.
        #               dig('aws_post_form_arguments', 'webhook_url')
        headers = fields.map { |o| { o['name'] => o['value'] } }.inject(:merge)
        post(url).
          payload(key: headers['key'],
                  policy: headers['policy'],
                  signature: headers['signature'],
                  AWSAccessKeyId: headers['AWSAccessKeyId'],
                  'content-type': headers['Content-Type'],
                  'success_action_redirect': headers['success_action_redirect'],
                  'x-amz-server-side-encryption':
                    headers['x-amz-server-side-encryption'],
                  'x-amz-storage-class': headers['x-amz-storage-class'],
                  file: file_content).
          request_format_multipart_form.
          after_response do |_code, response, _response_headers|
            response
          end&.merge('project_uid' => project_uid)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['photo']
      end,
      sample_output: lambda do |_connection, _input|
        {
          uid: '147a420e-a182-4312-8fa5-4d10064d2f1a',
          title: 'Bongo Drums',
          url: 'https://attachment-assets.plangrid.com/147a420e-a182-' \
          '4312-8fa5-4d10064d2f1a.pdf',
          created_at: '2013-05-17T02:30:22+00:00',
          created_by: {
            uid: null,
            url: null,
            email: 'nick@subcontractor.com'
          },
          deleted: false
        }
      end
    },
    update_photo_metadata: {
      title: 'Update photo in a project',
      description: 'Update <span class="provider">photo</span> in'\
        ' a <span class="provider">PlanGrid</span> project',
      help: {
        body: 'Update photo  action uses the' \
        " <a href='https://developer.plangrid.com/docs/update-photo-in-a-" \
        "project' target='_blank'>Update Photo in a Project API</a>.",
        learn_more_url: 'https://developer.plangrid.com/docs/update-photo-' \
        'in-a-project',
        learn_more_text: 'Update Photo in a Project API'
      },
      summarize_input: %w[file_content],
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid', optional: false,
            label: 'Project',
            control_type: 'select', pick_list: 'project_list',
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Use Project ID e.g. 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'photo_uid', label: 'Photo ID', optional: false },
          { name: 'title', label: 'Photo title',
            hint: 'New title of the photo', sticky: true }
        ]
      end,
      execute: lambda do |_connection, input|
        project_uid = input.delete('project_uid')
        patch("/projects/#{project_uid}/photos/" \
              "#{input.delete('photo_uid')}").
          headers('Content-type': 'application/json').
          payload(input).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.merge('project_uid' => project_uid)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['photo']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/photos")&.dig('data', 0)&.
        merge('project_uid' => id) || {}
      end
    },
    get_photo_details: {
      title: 'Get photo in a project',
      description: 'Get <span class="provider">photo</span> in'\
        ' a <span class="provider">PlanGrid</span> project',
      help: {
        body: 'Get photo action uses the ' \
        "<a href='https://developer.plangrid.com/docs/retrieve-sheets-" \
        "in-a-project' target='_blank'>Retrieve Photo in Project</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/' \
        'retrieve-a-sheet',
        learn_more_text: 'Retrieve Photo in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'photo_uid', label: 'Photo ID', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/projects/#{input['project_uid']}/photos/" \
          "#{input['photo_uid']}")&.merge('project_uid' => input.delete('project_uid'))
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['photo']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/photos")&.dig('data', 0)&.
        merge('project_uid' => id) || {}
      end
    },
    get_document_details: {
      title: 'Get document in a project',
      description: 'Get <span class="provider">document</span>'\
        ' in a <span class="provider">PlanGrid</span> project',
      help: {
        body: 'Get document in a project action uses the ' \
        "<a href='https://developer.plangrid.com/docs/retrieve-sheets-" \
        "in-a-project' target='_blank'>Retrieve Document in a Project</a> API.",
        learn_more_url: 'https://developer.plangrid.com/docs/' \
        'retrieve-a-sheet',
        learn_more_text: 'Retrieve Document in a Project API'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Use project ID',
              hint: 'Provide project ID e.g. ' \
              '0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          { name: 'attachment_uid', label: 'Document ID', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/projects/#{input['project_uid']}/attachments/" \
          "#{input['attachment_uid']}")&.merge('project_uid' => input.delete('project_uid'))
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['document']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/attachments")&.dig('data', 0)&.
        merge('project_uid' => id) || {}
      end
    }
  },
  triggers: {
    new_updated_project: {
      title: 'New or updated project',
      description: 'New or updated <span class="provider">project</span> in'\
        ' <span class="provider">PlanGrid</span>',
      help: {
        body: 'New or updated project trigger uses the' \
        " <a href='https://developer.plangrid.com/docs/list-all-projects'" \
        " target='_blank'>List All Projects API</a>.",
        learn_more_url: 'https://developer.plangrid.com/docs/list-all-projects',
        learn_more_text: 'List All Projects API'
      },
      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'since',
            label: 'When first started, this recipe should pick up events from',
            hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
            sticky: true,
            type: 'timestamp'
          }
        ]
      end,
      poll: lambda do |_connection, input, closure|
        updated_after = closure&.[]('updated_after') ||
                        (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 20
        skip = closure&.[]('skip') || 0
        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   else
                     get('/projects').
                       params(limit: limit,
                              skip: skip,
                              updated_after: updated_after)
                   end
        closure = if (next_page_url = response['next_page_url']).present?
                    { 'skip' => skip + limit,
                      'next_page_url' => next_page_url }
                  else
                    { 'offset' => 0,
                      'updated_after' => now.to_time.utc.iso8601 }
                  end
        {
          events: response['data'] || [],
          next_poll: closure,
          can_poll_more: response['next_page_url'].present?
        }
      end,
      dedup: lambda do |project|
        "#{project['uid']}@#{project['updated_at']}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['project']
      end,
      sample_output: lambda do |_connection, _input|
        get('/projects')&.dig('data', 0) || {}
      end
    },
    new_updated_sheets: {
      title: 'New or updated sheet in a project',
      description: 'New or updated <span class="provider">sheet</span> in '\
        'a <span class="provider">PlanGrid</span> project',
      help: {
        body: 'New or updated sheet in a project trigger uses the' \
        " <a href='https://developer.plangrid.com/docs/retrieve-sheets-in-a-project" \
        " target='_blank'>Retrieve Sheets in a Project" \
        ' </a> API.',
        learn_more_url: 'https://developer.plangrid.com/docs/retrieve-' \
        'sheets-in-a-project',
        learn_more_text: 'Retrieve Sheets in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid', optional: false,
            label: 'Project',
            control_type: 'select', pick_list: 'project_list',
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Use Project ID e.g. 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          {
            name: 'since',
            label: 'When first started, this recipe should pick up events from',
            hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
            sticky: true,
            type: 'timestamp'
          }
        ]
      end,
      poll: lambda do |_connection, input, closure|
        project_uid = closure&.[]('project_uid') || input['project_uid']
        updated_after = closure&.[]('updated_after') ||
                        (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 5
        skip = closure&.[]('skip') || 0
        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   else
                     get("/projects/#{project_uid}/sheets").
                       params(limit: limit,
                              skip: skip,
                              updated_after: updated_after)
                   end
        closure = if (next_page_url = response['next_page_url']).present?
                    { 'skip' => skip + limit,
                      'project_uid' => project_uid,
                      'next_page_url' => next_page_url }
                  else
                    { 'offset' => 0,
                      'project_uid' => project_uid,
                      'updated_after' => now.to_time.utc.iso8601 }
                  end
        sheets = response['data']&.
                map { |o| o.merge('project_uid' => project_uid) }
        {
          events: sheets || [],
          next_poll: closure,
          can_poll_more: response['next_page_url'].present?
        }
      end,
      dedup: lambda do |sheet|
        "#{sheet['uid']}@#{sheet['created_at']}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['sheet']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/sheets")&.dig('data', 0) || {}
      end
    },
    new_updated_documents: {
      title: 'New or updated document in a project',
      description: 'New or updated <span class="provider">document</span> in '\
        'a <span class="provider">PlanGrid</span> project',
      help: {
        body: 'New or updated document in a project trigger uses the' \
        " <a href='https://developer.plangrid.com/docs/retrieve-attachments" \
        "-in-a-project' target='_blank'>Retrieve Documents in a Project" \
        ' </a> API.',
        learn_more_url: 'https://developer.plangrid.com/docs/retrieve-' \
        'attachments-in-a-project',
        learn_more_text: 'Retrieve Documents in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid', optional: false,
            label: 'Project',
            control_type: 'select', pick_list: 'project_list',
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Use Project ID e.g. 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          {
            name: 'since',
            label: 'When first started, this recipe should pick up events from',
            hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
            sticky: true,
            type: 'timestamp'
          }
        ]
      end,
      poll: lambda do |_connection, input, closure|
        project_uid = closure&.[]('project_uid') || input['project_uid']
        updated_after = closure&.[]('updated_after') ||
                        (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 5
        skip = closure&.[]('skip') || 0
        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   else
                     get("/projects/#{project_uid}/attachments").
                       params(limit: limit,
                              skip: skip,
                              updated_after: updated_after)
                   end
        closure = if (next_page_url = response['next_page_url']).present?
                    { 'skip' => skip + limit,
                      'project_uid' => project_uid,
                      'next_page_url' => next_page_url }
                  else
                    { 'offset' => 0,
                      'project_uid' => project_uid,
                      'updated_after' => now.to_time.utc.iso8601 }
                  end
        documents = response['data']&.
                map { |o| o.merge('project_uid' => project_uid) }
        {
          events: documents || [],
          next_poll: closure,
          can_poll_more: response['next_page_url'].present?
        }
      end,
      dedup: lambda do |document|
        "#{document['uid']}@#{document['created_at']}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['document']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/attachments")&.dig('data', 0) || {}
      end
    },
    new_updated_task: {
      title: 'New/updated task in a Project',
      description: 'New/updated <span class="provider">task</span> in a '\
        'Project <span class="provider">Plangrid</span>',
      help: {
        body: 'New/updated task in a Project trigger uses the' \
        " <a href='https://developer.plangrid.com/docs/" \
        "retrieve-issues-in-a-project' target='_blank'>Retrieve Tasks " \
        ' in a Project API</a>.',
        learn_more_url: 'https://developer.plangrid.com/docs/' \
        'retrieve-issues-in-a-project',
        learn_more_text: 'Retrieve Tasks in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid', optional: false,
            label: 'Project',
            control_type: 'select', pick_list: 'project_list',
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Use Project ID e.g. 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          {
            name: 'since',
            label: 'When first started, this recipe should pick up events from',
            hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
            sticky: true,
            type: 'timestamp'
          }
        ]
      end,
      poll: lambda do |_connection, input, closure|
        project_uid = closure&.[]('project_uid') || input['project_uid']
        updated_after = closure&.[]('updated_after') ||
                        (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 10
        skip = closure&.[]('skip') || 0
        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   else
                     get("/projects/#{input.delete('project_uid')}/" \
                     'issues').
                       params(limit: limit,
                              skip: skip,
                              include_annotationless: true,
                              updated_after: updated_after)
                   end
        closure = if (next_page_url = response['next_page_url']).present?
                    { 'skip' => skip + limit,
                      'project_uid' => project_uid,
                      'next_page_url' => next_page_url }
                  else
                    { 'offset' => 0,
                      'project_uid' => project_uid,
                      'updated_after' => now.to_time.utc.iso8601 }
                  end
        tasks = response['data']&.
          map { |o| o.merge('project_uid' => project_uid) }
        {
          events: tasks || [],
          next_poll: closure,
          can_poll_more: response['next_page_url'].present?
        }
      end,
      dedup: lambda do |task|
        "#{task['uid']}@#{task['updated_at']}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['task']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/issues")&.
          dig('data', 0) || {}
      end
    },
    new_updated_annotations: {
      title: 'New or updated annotation in a project',
      description: 'New or updated <span class="provider">annotation</span> '\
        'in a <span class="provider">PlanGrid</span> project',
      help: {
        body: 'New or updated annotation in project trigger uses the' \
        " <a href='https://developer.plangrid.com/docs/" \
        "retrieve-annotations-in-a-project' target='_blank'>Retrieve " \
        ' Annotations in a Project</a> API.',
        learn_more_url: 'https://developer.plangrid.com/docs/' \
        'retrieve-annotations-in-a-project',
        learn_more_text: 'Retrieve Annotations in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid', optional: false,
            label: 'Project',
            control_type: 'select', pick_list: 'project_list',
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Use Project ID e.g. 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          {
            name: 'since',
            label: 'When first started, this recipe should pick up events from',
            hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
            sticky: true,
            type: 'timestamp'
          }
        ]
      end,
      poll: lambda do |_connection, input, closure|
        project_uid = closure&.[]('project_uid') || input['project_uid']
        updated_after = closure&.[]('updated_after') ||
                        (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 10
        skip = closure&.[]('skip') || 0
        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   else
                     get("/projects/#{input.delete('project_uid')}/" \
                     'annotations').
                       params(limit: limit,
                              skip: skip,
                              updated_after: updated_after)
                   end
        closure = if (next_page_url = response['next_page_url']).present?
                    { 'skip' => skip + limit,
                      'project_uid' => project_uid,
                      'next_page_url' => next_page_url }
                  else
                    { 'offset' => 0,
                      'project_uid' => project_uid,
                      'updated_after' => now.to_time.utc.iso8601 }
                  end
        annotations = response['data']&.
          map { |o| o.merge('project_uid' => project_uid) }
        {
          events: annotations || [],
          next_poll: closure,
          can_poll_more: response['next_page_url'].present?
        }
      end,
      dedup: lambda do |annotation|
        "#{annotation['uid']}@#{annotation['updated_at']}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['annotation']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/annotations")&.
          dig('data', 0) || {}
      end
    },
    new_updated_photos: {
      title: 'New or updated photo in a project',
      description: 'New or updated <span class="provider">photo</span> '\
        'in a <span class="provider">PlanGrid</span> project',
      help: {
        body: 'New or updated photo in a project trigger uses the' \
        " <a href='https://developer.plangrid.com/docs/" \
        "retrieve-photos-in-a-project' target='_blank'>Retrieve " \
        ' photos in a Project</a> API.',
        learn_more_url: 'https://developer.plangrid.com/docs/' \
        'retrieve-photos-in-a-project',
        learn_more_text: 'Retrieve Photos in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid', optional: false,
            label: 'Project',
            control_type: 'select', pick_list: 'project_list',
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Use Project ID e.g. 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          {
            name: 'since',
            label: 'When first started, this recipe should pick up events from',
            hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
            sticky: true,
            type: 'timestamp'
          }
        ]
      end,
      poll: lambda do |_connection, input, closure|
        project_uid = closure&.[]('project_uid') || input['project_uid']
        updated_after = closure&.[]('updated_after') ||
                        (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 10
        skip = closure&.[]('skip') || 0
        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   else
                     get("/projects/#{input.delete('project_uid')}/" \
                     'photos').
                       params(limit: limit,
                              skip: skip,
                              updated_after: updated_after)
                   end
        closure = if (next_page_url = response['next_page_url']).present?
                    { 'skip' => skip + limit,
                      'project_uid' => project_uid,
                      'next_page_url' => next_page_url }
                  else
                    { 'offset' => 0,
                      'project_uid' => project_uid,
                      'updated_after' => now.to_time.utc.iso8601 }
                  end
        photos = response['data']&.
          map { |o| o.merge('project_uid' => project_uid) }
        {
          events: photos || [],
          next_poll: closure,
          can_poll_more: response['next_page_url'].present?
        }
      end,
      dedup: lambda do |photo|
        "#{photo['uid']}@#{photo['updated_at']}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['photo']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/photos")&.
          dig('data', 0) || {}
      end
    },
    new_updated_snapshot: {
      title: 'New or updated snapshot in a project',
      description: 'New or updated <span class="provider">snapshot</span> '\
        'in a <span class="provider">PlanGrid</span> project',
      help: {
        body: 'New or updated snapshot in a project trigger uses the' \
        " <a href='https://developer.plangrid.com/docs/" \
        "retrieve-snapshots-in-a-project' target='_blank'>Retrieve " \
        ' Snapshots in a Project</a> API.',
        learn_more_url: 'https://developer.plangrid.com/docs/' \
        'retrieve-snapshots-in-a-project',
        learn_more_text: 'Retrieve Snapshots in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid', optional: false,
            label: 'Project',
            control_type: 'select', pick_list: 'project_list',
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Use Project ID e.g. 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          {
            name: 'since',
            label: 'When first started, this recipe should pick up events from',
            hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
            sticky: true,
            type: 'timestamp'
          }
        ]
      end,
      poll: lambda do |_connection, input, closure|
        project_uid = closure&.[]('project_uid') || input['project_uid']
        updated_after = closure&.[]('updated_after') ||
                        (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 10
        skip = closure&.[]('skip') || 0
        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   else
                     get("/projects/#{input.delete('project_uid')}/" \
                     'snapshots').
                       params(limit: limit,
                              skip: skip,
                              updated_after: updated_after)
                   end
        closure = if (next_page_url = response['next_page_url']).present?
                    { 'skip' => skip + limit,
                      'project_uid' => project_uid,
                      'next_page_url' => next_page_url }
                  else
                    { 'offset' => 0,
                      'project_uid' => project_uid,
                      'updated_after' => now.to_time.utc.iso8601 }
                  end
        snapshots = response['data']&.
          map { |o| o.merge('project_uid' => project_uid) }
        {
          events: snapshots || [],
          next_poll: closure,
          can_poll_more: response['next_page_url'].present?
        }
      end,
      dedup: lambda do |annotation|
        "#{annotation['uid']}@#{annotation['updated_at']}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['snapshot']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/snapshots")&.
          dig('data', 0) || {}
      end
    },
    new_updated_field_report: {
      title: 'New/updated field report in a Project',
      description: 'New/updated <span class="provider">field report</span> '\
        'in <span class="provider">Plangrid</span> Project',
      help: {
        body: 'New/updated field report in Project trigger uses the' \
        " <a href='https://developer.plangrid.com/docs/" \
        "retrieve-field-reports-in-a-project' target='_blank'>Retrieve " \
        'field reports in a Project</a> API.',
        learn_more_url: 'https://developer.plangrid.com/docs/' \
        'retrieve-field-reports-in-a-project',
        learn_more_text: 'Retrieve field reports in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid', optional: false,
            label: 'Project',
            control_type: 'select', pick_list: 'project_list',
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Use Project ID e.g. 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          {
            name: 'since',
            label: 'When first started, this recipe should pick up events from',
            hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
            sticky: true,
            type: 'timestamp'
          }
        ]
      end,
      poll: lambda do |_connection, input, closure|
        project_uid = closure&.[]('project_uid') || input['project_uid']
        updated_after = closure&.[]('updated_after') ||
                        (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 10
        skip = closure&.[]('skip') || 0
        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   else
                     get("/projects/#{input.delete('project_uid')}/" \
                     'field_reports').
                       params(limit: limit,
                              skip: skip,
                              updated_after: updated_after,
                              sort_by: 'updated_at',
                              sort_order: 'asc')
                   end
        closure = if (next_page_url = response['next_page_url']).present?
                    { 'skip' => skip + limit,
                      'project_uid' => project_uid,
                      'next_page_url' => next_page_url }
                  else
                    { 'offset' => 0,
                      'project_uid' => project_uid,
                      'updated_after' => now.to_time.utc.iso8601 }
                  end
        field_reports = response['data']&.
          map { |o| o.merge('project_uid' => project_uid) }
        {
          events: field_reports || [],
          next_poll: closure,
          can_poll_more: response['next_page_url'].present?
        }
      end,
      dedup: lambda do |field_report|
        "#{field_report['uid']}@#{field_report['updated_at']}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['field_report']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/field_reports")&.
          dig('data', 0) || {}
      end
    },
    new_updated_rfi: {
      title: 'New/updated RFI in a Project',
      description: 'New/updated <span class="provider">RFI</span> '\
        'in a <span class="provider">Plangrid</span> Project',
      help: {
        body: 'New/updated RFI in a Project trigger uses the' \
        " <a href='https://developer.plangrid.com/docs/" \
        "retrieve-rfis-in-a-project' target='_blank'>Retrieve " \
        ' RFIs in a Project</a> API.',
        learn_more_url: 'https://developer.plangrid.com/docs/' \
        'retrieve-rfis-in-a-project',
        learn_more_text: 'Retrieve RFIs in a Project'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'project_uid', optional: false,
            label: 'Project',
            control_type: 'select', pick_list: 'project_list',
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_uid',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use project ID',
              hint: 'Use Project ID e.g. 0bbb5bdb-3f87-4b46-9975-90e797ee9ff9'
            } },
          {
            name: 'since',
            label: 'When first started, this recipe should pick up events from',
            hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
            sticky: true,
            type: 'timestamp'
          }
        ]
      end,
      poll: lambda do |_connection, input, closure|
        project_uid = closure&.[]('project_uid') || input['project_uid']
        updated_after = closure&.[]('updated_after') ||
                        (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 10
        skip = closure&.[]('skip') || 0
        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   else
                     get("/projects/#{input.delete('project_uid')}/" \
                     'rfis').
                       params(limit: limit,
                              skip: skip,
                              updated_after: updated_after)
                   end
        closure = if (next_page_url = response['next_page_url']).present?
                    { 'skip' => skip + limit,
                      'project_uid' => project_uid,
                      'next_page_url' => next_page_url }
                  else
                    { 'offset' => 0,
                      'project_uid' => project_uid,
                      'updated_after' => now.to_time.utc.iso8601 }
                  end
        rfis = response['data']&.
          map { |o| o.merge('project_uid' => project_uid) }
        {
          events: rfis || [],
          next_poll: closure,
          can_poll_more: response['next_page_url'].present?
        }
      end,
      dedup: lambda do |rfi|
        "#{rfi['uid']}@#{rfi['updated_at']}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['rfi']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('projects')&.[]('data', 0)&.[]('uid')
        get("/projects/#{id}/rfis")&.
          dig('data', 0) || {}
      end
    }
  },
  pick_lists: {
    project_list: lambda do |_connection|
      get('projects')&.[]('data')&.pluck('name', 'uid')
    end,
    project_types: lambda do |_connection|
      ['general', 'manufacturing', 'power', 'water-sewer-waste',
       'industrial-petroleum', 'transportation', 'hazardous-waste',
       'telecom', 'education-k-12', 'education-higher', 'gov-federal',
       'gov-state-local', 'other'].map { |type| [type.labelize, type] }
    end,
    project_folders: lambda do |_connection, project_uid:|
      if project_uid.length === 36
        folders = get("/projects/#{project_uid}/attachments")['data']&.
                  pluck('folder')&.uniq
        if folders.size > 0
          folders&.map { |folder| [folder || 'Root', folder || ''] }
        else
          [['Root', '']]
        end
      end
    end
  }
}
