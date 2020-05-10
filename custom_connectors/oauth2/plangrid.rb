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
    get_input_schema: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object']
        when 'rfi_status'
          [
            { name: 'limit', type: 'integer', control_type: 'integer',
              hint: 'Number of RFI statuses to retrieve. Maximum value of 50.' },
            { name: 'skip', type: 'integer', control_type: 'integer',
              hint: 'Number of RFI statuses to skip in the set of results.' }
          ]
        when 'field_report'
          [
            { name: 'template_uid', label: 'Field Report Template ID',
              hint: 'Only retrieve field reports for the specified template ID.'},
            { name: 'report_date_min', type: 'date',
              label: 'Report Start Date',
              hint: 'Only retrieve field reports between a date range starting with this date in UTC format.' },
            { name: 'report_date_max', type: 'date',
              label: 'Report End Date',
              hint: 'Only retrieve field reports between a date range ending with this date in UTC format.' },
            { name: 'updated_after', label: 'Updated After', type: 'date_time',
              hint: 'Only retrieve field reports created/updated after specified UTC date and time.' },
            { name: 'skip', type: 'integer',
              hint: 'Number of records to skip.' },
            { name: 'limit', type: 'integer',
              hint: 'Number of records to retrieve.' },
            {
              name: 'sort_by', label: 'Sort by column', control_type: 'select',
              pick_list:
              %w[report_date updated_at]&.map { |e| [e.labelize, e] },
              toggle_hint: 'Select column',
              toggle_field: {
                name: 'sort_by', label: 'Sort by column', type: 'string', control_type: 'text',
                toggle_hint: 'Enter column',
                hint: 'Allowed values <b>report_date</b> or <b>updated_at</b>.'
              }
            },
            {
              name: 'sort_order', label: 'Sort by order', control_type: 'select',
              pick_list: [%w[Ascending asc], %w[Descending desc]],
              toggle_hint: 'Select order',
              toggle_field: {
                name: 'sort_by', label: 'Sort by order', type: 'string', control_type: 'text',
                toggle_hint: 'Enter order',
                hint: 'Allowed values <b>Ascending</b> or <b>Descending</b>.'
              }
            },
            {
              name: 'output_schema',
              control_type: 'schema-designer',
              extends_schema: true,
              label: 'PDF field values',
              hint: 'Manually define the values expected of your PDF field values in the field report.',
              optional: true
            }
          ]
        when 'field_report_template'
          [
            { name: 'updated_after', label: 'Updated After', type: 'date_time',
              hint: 'Only retrieve field reports created/updated after specified UTC date and time.' },
            { name: 'updated_before', label: 'Updated Before', type: 'date_time',
              hint: 'Only retrieve field reports created/updated before specified UTC date and time.' },
            { name: 'skip', type: 'integer',
              hint: 'Number of records to skip.' },
            { name: 'limit', type: 'integer',
              hint: 'Number of records to retrieve.' }
          ]
        when 'field_reports/export'
          [{ name: 'uid', label: 'Export ID', optional: false }]
        when 'role', 'project'
          []
        when 'submittals/item'
          [{ name: 'uids', label: 'Submittal Item ID', optional: false }]
        when 'submittals/package'
          [{ name: 'uid', label: 'Submittal Package ID', optional: false,
             hint: 'ID can be found at the end of the url.' }]
        when 'submittals_file_group'
          [
            { name: 'uid', label: 'Submittal Package ID', optional: false,
              hint: 'ID can be found at the end of the url.' },
            { name: 'created_after', type: 'date_time',
              hint: 'Only return file groups created after the specified date.' }
          ]
        else
          [{ name: "uid", label: "#{config_fields['object'].labelize} ID", optional: false,
             hint: 'ID can be found at the end of the url.' }]
        end
      end
    },

    get_output_schema: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object']
        when 'project'
          [
            {
              name: 'uid',
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
                toggle_hint: 'Enter project ID',
                hint: 'Provide project ID. For example, <b>0bbb5bdb-3f87-4b46-9975-90e797ee9ff9</b>'
              }
            },
            { name: 'name', label: 'Project Name', sticky: true },
            { name: 'custom_id', label: 'Project Code', sticky: true },
            { name: 'organization_id', label: 'Organization ID' },
            {
              name: 'type', control_type: 'select',
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
              }
            },
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
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp',
              label: 'Updated at' }
          ]
        when 'attachment'
          [
            { name: 'uid', label: 'Document ID' },
            { name: "project_uid", label: "Project ID" },
            { name: 'name', label: 'Document Name' },
            { name: 'folder' },
            { name: 'url' },
            { name: 'created_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            {
              name: 'created_by', type: 'object', properties: [
                { name: 'uid', label: 'UID' },
                { name: 'url' },
                { name: 'email' }
              ]
            },
            { name: 'deleted', type: 'boolean', control_type: 'checkbox' }
          ]
        when 'issue'
          [
            { name: 'uid', label: 'Task ID' },
            { name: "project_uid", label: "Project ID" },
            { name: 'number', type: 'integer' },
            { name: 'title' },
            {
              name: 'status', control_type: 'select', pick_list:
              %w[open in_review pending closed].select { |op| [op.labelize, op] },
              toggle_hint: 'Select status',
              toggle_field: {
                name: 'status',
                label: 'Status',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are : <b>"open", "in_review", "pending", "closed"</b>.'
              }
            },
            {
              name: 'type', control_type: 'select',
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
                hint: 'Allowed values are: <b>"issue", "planned_work", "other"</b>.'
              }
            },
            {
              name: 'assignees', type: 'array', of: 'object', properties: [
                { name: 'uid', label: 'Assignee ID' },
                { name: 'type' }
              ]
            },
            {
              name: 'followers', label: 'Watchers', type: 'array', of: 'object', properties: [
                { name: 'uid', label: 'Follower ID' },
                { name: 'type' }
              ]
            },
            { name: 'room', label: 'Location' },
            { name: 'start_date', label: 'Start Date',
              type: 'date_time',
              render_input: 'date_conversion',
              parse_output: 'date_conversion' },
            { name: 'closed_at', type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion' },
            { name: 'due_at', type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion' },
            { name: 'string', label: 'Stamp',
              hint: 'One to two character stamp associated with task.' },
            {
              name: 'issue_list', label: 'Task List', type: 'object', properties: [
                { name: 'uid', label: 'Task List ID' },
                { name: 'url' }
              ]
            },
            { name: 'description' },
            { name: 'cost_impact', label: 'Cost Impact', type: 'integer' },
            {
              name: 'has_cost_impact', label: 'Has Cost Impact?', type: 'boolean',
              control_type: 'checkbox'
            },
            { name: 'currency_code', label: 'Currency Code',
              hint: 'The ISO-4217 currency code of the cost_impact,' \
                ' Currently only supports USD. maybe null if cost_impact is ' \
                'not specified' },
            { name: 'schedule_impact', label: 'Schedule Impact', type: 'integer' },
            {
              name: 'has_schedule_impact', label: 'Has Schedule Impact?', type: 'boolean',
              control_type: 'checkbox'
            },
            {
              name: 'current_annotation', type: 'object', properties: [
                { name: 'uid', label: 'Annotation ID' },
                { name: 'color' },
                { name: 'stamp' },
                { name: 'visibility' },
                {
                  name: 'deleted', type: 'boolean',
                  control_type: 'checkbox'
                },
                {
                  name: 'sheet', type: 'object', properties: [
                    { name: 'uid', label: 'Sheet ID' },
                    { name: 'url' }
                  ]
                }
              ]
            },
            {
              name: 'comments', type: 'object', properties: [
                { name: 'total_count', type: 'integer' },
                { name: 'url' }
              ]
            },
            {
              name: 'photos', type: 'object', properties: [
                { name: 'total_count', type: 'integer' },
                { name: 'url' }
              ]
            },
            {
              name: 'deleted', type: 'boolean',
              control_type: 'checkbox'
            },
            { name: 'created_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            {
              name: 'created_by', type: 'object', properties: [
                { name: 'uid', label: 'UID' },
                { name: 'url' },
                { name: 'email' }
              ]
            },
            { name: 'updated_at',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp',
              type: 'date_time' },
            {
              name: 'updated_by', type: 'object', properties: [
                { name: 'uid' },
                { name: 'url' },
                { name: 'email' }
              ]
            }
          ]
        when 'file_upload'
          [
            { name: 'uid' },
            {
              name: 'aws_post_form_arguments', type: 'object',
              properties: [
                { name: 'action' },
                { name: 'fields', type: 'array', of: 'object', properties: [
                  { name: 'name' },
                  { name: 'value' }
                ] }
              ]
            },
            { name: "project_uid", label: "Project ID" },
            { name: 'webhook_url' }
          ]
        when 'annotation'
          [
            { name: 'uid', label: 'Annotation ID' },
            { name: "project_uid", label: "Project ID" },
            { name: 'color' },
            { name: 'stamp' },
            { name: 'visibility' },
            {
              name: 'deleted', type: 'boolean',
              control_type: 'checkbox'
            },
            {
              name: 'sheet', type: 'object', properties: [
                { name: 'uid', label: 'Sheet ID' },
                { name: 'url' }
              ]
            }
          ]
        when 'snapshot'
          [
            { name: 'uid', label: 'Snapshot ID' },
            { name: "project_uid", label: "Project ID" },
            { name: 'title' },
            { name: 'url' },
            { name: 'created_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            {
              name: 'created_by', type: 'object', properties: [
                { name: 'uid', label: 'UID' },
                { name: 'url' },
                { name: 'email' }
              ]
            },
            {
              name: 'sheet', type: 'object', properties: [
                { name: 'uid', label: 'Sheet ID' },
                { name: 'url' }
              ]
            },
            {
              name: 'deleted', type: 'boolean',
              control_type: 'checkbox'
            }
          ]
        when 'photo'
          [
            { name: 'uid', label: 'Photo ID' },
            { name: "project_uid", label: "Project ID" },
            { name: 'title' },
            { name: 'url', label: 'URL' },
            { name: 'created_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            {
              name: 'created_by', type: 'object', properties: [
                { name: 'uid', label: 'UID' },
                { name: 'url' },
                { name: 'email' }
              ]
            },
            { name: 'deleted', type: 'boolean' }
          ]
        when 'field_report'
          [
            { name: 'uid', label: 'Field Report ID' },
            { name: "project_uid", label: "Project ID" },
            { name: 'title' },
            { name: 'description' },
            { name: 'report_date', label: 'Report Date', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'status' },
            {
              name: 'field_report_type', label: 'Field Report Type', type: 'object', properties: [
                { name: 'name' },
                { name: 'status' },
                { name: 'uid', label: 'Field Report ID' },
                { name: 'project_uid' },
                { name: 'template_type' }
              ]
            },
            { name: 'pdf_url', label: 'PDF URL' },
            {
              name: 'pdf_form_values', label: 'PDF Form Values', type: 'array', of: 'object',
              properties: [
                { name: 'name' },
                { name: 'value' }
              ]
            },
            {
              name: 'pdf_form_fields', label: 'PDF Field Values', type: 'object'
            },
            {
              name: 'pg_form_values', type: 'object', properties: [
                {
                  name: 'pg_worklog_entries', label: 'Work Log Entries', type: 'array', of: 'object',
                  properties: [
                    { name: 'trade' },
                    { name: 'timespan' },
                    { name: 'headcount', type: 'integer' },
                    { name: 'description' },
                    {
                      name: 'deleted', type: 'boolean',
                      control_type: 'checkbox'
                    },
                    { name: 'uid' }
                  ]
                },
                {
                  name: 'pg_materials_entries', label: 'Material Entries', type: 'array', of: 'object',
                  properties: [
                    { name: 'unit', type: 'integer' },
                    { name: 'quantity', type: 'integer' },
                    { name: 'item' },
                    { name: 'description' },
                    { name: 'deleted', type: "boolean", control_type: 'checkbox' },
                    { name: 'uid' }
                  ]
                },
                {
                  name: 'pg_equipment_entries', label: 'Equipment Entries', type: 'array', of: 'object',
                  properties: [
                    { name: 'timespan' },
                    { name: 'quantity', type: 'integer' },
                    { name: 'item' },
                    { name: 'description' },
                    {
                      name: 'deleted', type: 'boolean',
                      control_type: 'checkbox'
                    },
                    { name: 'uid' }
                  ]
                }
              ]
            },
            {
              name: 'custom_items', label: 'Custom Form Items', type: 'array',
              of: 'object', properties: [
                { name: 'section_label', label: 'Section Name' },
                { name: 'item_label', label: 'Item Label' },
                { name: 'value_name', label: 'Value Name' },
                { name: 'notes' },
                { name: 'text_val', label: 'Text Value' },
                { name: 'choice_val', label: 'Choice Value' },
                { name: 'number_val', label: 'Number Value', type: 'number' },
                { name: 'date_val', label: 'Date Value', type: 'date_time' },
                { name: 'array_val', label: 'Array Value', type: 'array',
                  of: 'string' },
                { name: 'toggle_val', label: 'Toggle Value', type: 'integer' }
              ]
            },
            {
              name: 'attachments', type: 'object', properties: [
                { name: 'total_count', type: 'integer' },
                { name: 'url' }
              ]
            },
            {
              name: 'photos', type: 'object', properties: [
                { name: 'total_count', type: 'integer' },
                { name: 'url' }
              ]
            },
            {
              name: 'snapshots', type: 'object', properties: [
                { name: 'total_count', type: 'integer' },
                { name: 'url' }
              ]
            },
            {
              name: 'created_by', type: 'object', properties: [
                { name: 'email' },
                { name: 'uid', label: 'UID' },
                { name: 'url' }
              ]
            },
            { name: 'updated_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            {
              name: 'weather', type: 'object', properties: [
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
              ]
            }
          ]
        when 'field_report_template'
          [
            { name: 'uid', label: 'Field Report Template ID' },
            { name: 'name' },
            { name: 'field_reports', label: 'Field Reports',
              type: 'object', properties: [
                { name: 'url' }
              ]
            },
            { name: 'is_pdf', label: 'Is PDF', type: 'boolean' },
            { name: 'pdf_url', label: 'PDF URL' },
            { name: 'template_type', label: 'Template Type' },
            { name: 'status' },
            { name: 'group_permissions', label: 'Group Permissions',
              type: 'array', of: 'object', properties: [
                { name: 'permissions', type: 'array', of: 'string' },
                { name: 'role_name', label: 'Role Name' },
                { name: 'role_uid', label: 'Role UID' }
              ]
            },
            { name: 'user_permissions', label: 'User Permissions',
              type: 'array', of: 'object', properties: [
                { name: 'permissions', type: 'array', of:' string' },
                { name: 'user_id', label: 'User UID'}
              ]
            },
            { name: 'created_by', label: 'Created By', type: 'object',
              properties: [
                { name: 'email' },
                { name: 'uid' },
                { name: 'url' }
              ]
            },
            { name: 'updated_at', label: 'Updated At', type: 'date_time' }
          ]
        when 'field_reports/export'
          [
            { name: 'uid', label: 'Export ID' },
            { name: 'project_uid', label: 'Project ID' },
            { name: 'status' },
            { name: 'file_url' },
            { name: 'resource_url' }
          ]
        when 'rfi'
          [
            { name: 'uid', label: 'RFI ID' },
            { name: "project_uid", label: "Project ID" },
            { name: 'number', type: 'integer' },
            {
              name: 'status', type: 'object', properties: [
                { name: 'uid', label: 'Status ID' },
                { name: 'label' },
                { name: 'color' }
              ]
            },
            {
              name: 'locked', type: 'boolean',
              control_type: 'checkbox'
            },
            { name: 'title' },
            { name: 'question' },
            { name: 'answer' },
            { name: 'sent_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp',
              hint: 'Date when the RFI was sent. See ' \
                "<a href='https://developer.plangrid.com/v1.15/docs/" \
                "timestamps-and-timezones' target='_blank'>Timestamps and " \
                'Timezones</a> for accepted date formats' },
            { name: 'due_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            {
              name: 'assigned_to', type: 'array', of: 'object',
              properties: [
                { name: 'uid', label: 'UID' },
                { name: 'url' },
                { name: 'email' }
              ]
            },
            { name: 'updated_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp',
              hint: 'Date when the RFI was sent. See ' \
                "<a href='https://developer.plangrid.com/v1.15/docs/" \
                "timestamps-and-timezones' target='_blank'>Timestamps and " \
                'Timezones</a> for accepted date formats' },
            {
              name: 'updated_by', type: 'object', properties: [
                { name: 'uid', label: 'UID' },
                { name: 'url' },
                { name: 'email' }
              ]
            },
            { name: 'created_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            {
              name: 'created_by', type: 'object', properties: [
                { name: 'uid', label: 'UID' },
                { name: 'url' },
                { name: 'email' }
              ]
            },
            {
              name: 'photos', type: 'object', properties: [
                { name: 'total_count', type: 'integer' },
                { name: 'url' }
              ]
            },
            {
              name: 'attachments', type: 'object', properties: [
                { name: 'total_count', type: 'integer' },
                { name: 'url' }
              ]
            },
            {
              name: 'snapshots', type: 'object', properties: [
                { name: 'total_count', type: 'integer' },
                { name: 'url' }
              ]
            },
            {
              name: 'comments', type: 'object', properties: [
                { name: 'total_count', type: 'integer' },
                { name: 'url' }
              ]
            }
          ]
        when 'rfi_status'
          [
            { name: 'uid', label: 'RFI status ID' },
            { name: 'label' },
            { name: 'color' },
            { name: "project_uid", label: "Project ID" }
          ]
        when 'user', 'user_invite'
          [
            { name: 'uid', label: 'User ID' },
            { name: "project_uid", label: "Project ID" },
            { name: 'email' },
            { name: 'first_name', label: 'First Name' },
            { name: 'last_name', label: 'Last Name' },
            { name: 'language' },
            {
              name: 'role', type: 'object', properties: [
                { name: 'uid', label: 'role ID' },
                { name: 'url' }
              ]
            },
            { name: 'removed', label: 'Removed?', type: 'boolean' }
          ]
        when 'sheet'
          [
            { name: 'uid', label: 'Sheet ID' },
            { name: "project_uid", label: "Project ID" },
            { name: 'name' },
            { name: 'version_name', label: 'Version Name' },
            { name: 'description' },
            { name: 'tags', type: 'array', of: 'string', hint: 'An array of strings representing the' \
                    ' tags added to this sheet.' },
            {
              name: 'published_by', type: 'object', properties: [
                { name: 'uid', label: 'UID' },
                { name: 'url' },
                { name: 'email' }
              ]
            },
            { name: 'published_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp',
              hint: 'UTC date and time in ISO-8601 format.' },
            {
              name: 'deleted', type: 'boolean',
              control_type: 'checkbox'
            },
            { name: 'uploaded_file_name', label: 'Uploaded file name' },
            { name: 'history_set_uid', label: 'History set ID' }
          ]
        when 'sheet_packet'
          [
            { name: 'uid', label: 'Sheet Packet ID' },
            { name: "project_uid", label: "Project ID" },
            { name: 'status' },
            { name: 'file_url', label: 'File URL' },
            {
              name: 'resource', type: 'object', properties: [
                { name: 'uid', label: 'Resource ID' },
                { name: 'url' }
              ]
            }
          ]
        when 'issue_list'
          [
            { name: "uid", label: "Task List ID" },
            { name: "project_uid", label: "Project ID" },
            { name: "name", label: "Name" },
            { name: "deleted", label: "Deleted", type: "boolean", control_type: 'checkbox' }
          ]
        when 'role'
          [
            { name: 'uid', label: 'Role ID' },
            { name: 'label', label: 'Role' },
            { name: "project_uid", label: "Project ID" }
          ]
        when 'sheet_upload'
          [
            { name: 'uid', label: 'Sheet Version Upload ID' },
            { name: 'complete_url', label: 'Upload Completion URL' },
            { name: 'status' },
            { name: "project_uid", label: "Project ID" },
            {
              name: 'file_upload_requests', label: 'File Upload Requests',
              type: 'array', of: 'object', properties: [
                { name: 'uid', label: 'File Upload ID' },
                { name: 'upload_status', label: 'File Upload Status' },
                { name: 'url', label: 'File Upload URL' }
              ]
            }
          ]
        when 'version_upload'
          [
            { name: 'uid', label: 'Sheet Version ID' },
            { name: "project_uid", label: "Project ID" },
            { name: 'status', label: 'Status' }
          ]
        when 'submittals/package'
          [
            { name: 'uid', label: 'Submittal Package ID' },
            { name: 'project_uid', label: 'Project ID' },
            { name: 'name' },
            { name: 'spec_section' },
            { name: 'spec_section_name' },
            { name: 'custom_id' },
            { name: 'version' },
            { name: 'ball_in_court_status' },
            { name: 'lead_time_days', type: 'integer' },
            { name: 'submittals_due_date', type: 'date_time' },
            { name: 'required_on_job_date', type: 'date_time' },
            { name: 'transmission_status' },
            { name: 'is_voided', type: 'boolean'  },
            { name: 'items', type: 'object', properties: [
              { name: 'uids', type: 'array', of: 'string' },
              { name: 'url' },
              { name: 'total_count', type: 'integer'}
            ]},
            { name: 'visible_file_group_uid' },
            { name: 'design_review_due_date', type: 'date_time' },
            { name: 'general_contractor_review_due_date', type: 'date_time' },
            { name: 'latest_review', type: 'object', properties: [
              { name: 'uid', label: 'Review ID' },
              { name: 'created_at', type: 'date_time' },
              { name: 'created_by', type: 'object', properties: [
                { name: 'uid' },
                { name: 'url' }
              ]},
              { name: 'file_group_uid' },
              { name: 'is_official_review' },
              { name: 'package_version' },
              { name: 'review_response_uid' },
              { name: 'reviewed_by', type: 'object', properties: [
                { name: 'type' },
                { name: 'uid' },
                { name: 'url' }
              ]}
            ]},
            { name: 'latest_review_response_uid' },
            { name: 'received_from_design_at', type: 'date_time'  },
            { name: 'sent_to_design_at', type: 'date_time'  },
            { name: 'received_from_sub_at', type: 'date_time'  },
            { name: 'returned_to_sub_at', type: 'date_time'  },
            { name: 'managers', type: 'array', of: 'object', properties: [
                { name: 'type' },
                { name: 'uid' },
                { name: 'url' }
            ]},
            { name: 'reviewers', type: 'array', of: 'object', properties: [
                { name: 'type' },
                { name: 'uid' },
                { name: 'url' }
            ]},
            { name: 'submitters', type: 'array', of: 'object', properties: [
                { name: 'type' },
                { name: 'uid' },
                { name: 'url' }
            ]},
            { name: 'unioned_watchers', type: 'array', of: 'object', properties: [
                { name: 'type' },
                { name: 'uid' },
                { name: 'url' }
            ]},
            { name: 'watchers', type: 'array', of: 'object', properties: [
                { name: 'type' },
                { name: 'uid' },
                { name: 'url' }
            ]},
            { name: 'created_at', type: 'date_time' },
            { name: 'created_by', type: 'object', properties: [
              { name: 'uid' },
              { name: 'url' }
            ]},
            { name: 'published_at', type: 'date_time' },
            { name: 'updated_at', type: 'date_time' },
            { name: 'updated_by', type: 'object', properties: [
              { name: 'uid' },
              { name: 'url' }
            ]}
          ]
        when 'submittals/item'
          [
            { name: 'uid', label: 'Submittal Item ID' },
            { name: 'project_uid', label: 'Project ID' },
            { name: 'name' },
            { name: 'description' },
            { name: 'spec_bullet' },
            { name: 'spec_doc' },
            { name: 'spec_heading' },
            { name: 'spec_page' },
            { name: 'spec_section' },
            { name: 'spec_section_name' },
            { name: 'spec_subsection_name' },
            { name: 'lead_time_days', type:'integer' },
            { name: 'required_on_job_date', type: 'date_time' },
            { name: 'submittal_due_date', type: 'date_time' },
            { name: 'submittals_type' },
            { name: 'package', type: 'object', properties: [
              { name: 'uid' },
              { name: 'url' }
            ]},
            { name: 'design_review_due_date', type: 'date_time' },
            { name: 'general_contractor_review_due_date', type: 'date_time' },
            { name: 'reviewers', type: 'array', of: 'object', properties: [
                { name: 'type' },
                { name: 'uid' },
                { name: 'url' }
            ]},
            { name: 'managers', type: 'array', of: 'object', properties: [
                { name: 'type' },
                { name: 'uid' },
                { name: 'url' }
            ]},
            { name: 'submitters', type: 'array', of: 'object', properties: [
                { name: 'type' },
                { name: 'uid' },
                { name: 'url' }
            ]},
            { name: 'watchers', type: 'array', of: 'object', properties: [
                { name: 'type' },
                { name: 'uid' },
                { name: 'url' }
            ]},
            { name: 'created_at' },
            { name: 'created_by', type: 'object', properties: [
              { name: 'uid' },
              { name: 'url' }
            ]}
          ]
        when 'submittals_file_group'
          [
            { name: 'package_uid', label: 'Submittal Package ID' },
            { name: 'project_uid', label: 'Project ID' },
            { name: 'data', label: 'File Groups',
              type: 'array', of: 'object', properties: [
                { name: 'uid', label: 'File Group ID' },
                { name: 'files', type: 'array', of: 'object', properties: [
                  { name: 'document_uid', label: 'Document ID' },
                  { name: 'name' },
                  { name: 'url' },
                  { name: 'created_at', type: 'date_time' },
                  { name: 'file_group_uid' }
                ]},
                { name: 'package', type: 'object', properties: [
                  { name: 'uid' },
                  { name: 'url' }
                ]},
                { name: 'upload_completed', type: 'boolean'}
              ]
            },
            { name: 'total_count' },
            { name: 'next_page_url' }
          ]
        when 'submittals_review_status'
          [
            { name: 'package_uid', label: 'Submittal Package ID' },
            { name: 'project_uid', label: 'Project ID' },
            { name: 'data', label: 'Review Status',
              type: 'array', of: 'object', properties: [
                { name: 'uid', label: 'Review ID' },
                { name: 'review_response_uid', label: 'Review Response ID' },
                { name: 'is_official_review', type: 'boolean' },
                { name: 'package_version', type: 'integer' },
                { name: 'file_group_uid', label: 'File Group ID' },
                { name: 'created_at' },
                { name: 'created_by', type: 'object', properties: [
                  { name: 'uid', label: 'User ID' },
                  { name: 'url' }
                ]}
              ]
            },
            { name: 'total_count' },
            { name: 'next_page_url' }
          ]
        end
      end
    },

    create_input_schema: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object']
        when 'project'
          [
            { name: 'name', label: 'Project Name', sticky: true, optional: false },
            { name: 'custom_id', label: 'Project Code', sticky: true },
            {
              name: 'type', control_type: 'select',
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
              }
            },
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
            {
              name: 'add_to_organization', type: 'boolean', sticky: true,
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
          ]
        when 'rfi'
          [
            {
              name: 'locked', type: 'boolean',
              control_type: 'checkbox', toggle_hint: 'Select from options list',
              toggle_field: {
                name: 'locked',
                label: 'Locked',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false'
              }
            },
            { name: 'title', optional: false },
            { name: 'question' },
            { name: 'answer' },
            { name: 'sent_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp',
              hint: 'Date when the RFI was sent. See ' \
              "<a href='https://developer.plangrid.com/v1.15/docs/" \
              "timestamps-and-timezones' target='_blank'>Timestamps and " \
              'Timezones</a> for accepted date formats' },
            { name: 'due_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'assigned_to_uids', hint: "A comma separated list of user IDs." },
            { name: 'status', label: 'Status',
              hint: "Uid's of the RFI's initial status. Defaults to the first RFI status in the project" }
          ]
        when 'issue'
          [
            { name: 'title' },
            {
              name: 'status', control_type: 'select', pick_list:
              %w[open in_review pending closed].select { |op| [op.labelize, op] },
              toggle_hint: 'Select status',
              toggle_field: {
                name: 'status',
                label: 'Status',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are : <b>"open", "in_review", "pending", "closed"</b>.'
              }
            },
            {
              name: 'type', control_type: 'select',
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
                hint: 'Allowed values are: <b>"issue", "planned_work", "other"</b>.'
              }
            },
            { name: 'room', label: 'Location' },
            { name: 'start_date', label: 'Start Date',
              type: 'date_time',
              render_input: 'date_conversion',
              parse_output: 'date_conversion' },
            { name: 'due_at', type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion' },
            { name: 'description' },
            { name: 'cost_impact', label: 'Cost Impact', type: 'number' },
            {
              name: 'has_cost_impact', label: 'Has Cost Impact?', type: 'boolean',
              control_type: 'checkbox', toggle_hint: 'Select from options list',
              toggle_field: {
                name: 'has_cost_impact',
                label: 'Has cost impact?',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false'
              }
            },
            { name: 'schedule_impact', label: 'Schedule Impact', type: 'integer' },
            {
              name: 'has_schedule_impact', label: 'Has Schedule Impact?', type: 'boolean',
              control_type: 'checkbox', toggle_hint: 'Select from options list',
              toggle_field: {
                name: 'has_schedule_impact',
                label: 'Has schedule impact',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false'
              }
            },
            { name: 'assigned_to_uids', hint: "A comma separated list of user IDs." },
            { name: 'issue_list_uid', label: 'Task List ID', sticky: true }
          ]
        when 'sheet_packet'
          [
            { name: 'sheet_uids', label: 'Sheet IDs', optional: false,
              type: 'string',
              hint: 'A comma separated list of sheet IDs.' },
            {
              name: 'include_annotations', label: 'Include annotations?', type: 'boolean', sticky: true,
              control_type: 'checkbox', toggle_hint: 'Select from options list',
              toggle_field: {
                name: 'include_annotations',
                label: 'Include annotations?',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false'
              }
            },
          ]
        when 'issue_list'
          [
            { name: 'name', optional: false }
          ]
        when 'sheet_upload'
          [
            { name: 'num_files', label: 'Number of PDFs', type: 'integer', optional: false },
            { name: 'version_name', label: 'Version Name', optional: false }
          ]
        when 'user_invite'
          [
            { name: 'email', optional: false },
            { name: 'role_uid', label: 'Role ID', sticky: true,
              hint: 'Unique identifier of role to assign user on project team' },
            { name: 'first_name' },
            { name: 'last_name' },
            { name: 'language' }
          ]
        when 'submittals/package'
          [
            { name: 'name', optional: false,
              hint: 'The name of the submittal package.' },
            { name: 'custom_id', optional: false,
              hint: 'A custom ID for the submittal package.' },
            { name: 'item_uids', optional: false, label: 'Submittal Item IDs',
              hint: 'The IDs of the specific submittal items to include in the submittal package. ' \
              'Separate each item with a comma.' },
            { name: 'ball_in_court_status',
              hint: "Reference to the role of the user from whom the next step is expected." \
              " Can be 'manager', 'submitter', or 'reviewer'." },
            { name: 'design_review_due_date', type: 'date',
              hint: 'Due date for the design review.' },
            { name: 'file_group_uid',
              hint: 'UID of the file group to associate with this submittal package.' },
            { name: 'general_contractor_review_due_date', type: 'date',
              hint: "Due date of the general contractor's review." },
            { name: 'lead_time_days', type: 'integer',
              hint: 'Number of days of lead time provided for this submittal package.' },
            { name: 'notes' },
            { name: 'required_on_job_date', type: 'date',
              hint: 'The date when the submitted material is required on the job.' },
            { name: 'submittal_due_date', type: 'date',
              hint: 'Due date for this submittal package.' },
            { name: 'managers', type: 'array', of: 'object',
              hint: 'An array of objects describing users assigned the role of manager.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            },
            { name: 'reviewers', type: 'array', of: 'object',
              hint: 'An array of objects describing users assigned the role of reviewer.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            },
            { name: 'watchers', type: 'array', of: 'object',
              hint: 'An array of objects describing users assigned the role of watcher.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            }
          ]
        when 'submittals/item'
          [
            { name: 'name', optional: false,
              hint: 'Name of the submittal item.' },
            { name: 'description',
              hint: 'Description of the submittal package.' },
            { name: 'package_uid',
              hint: 'ID of the submittal package to which this item should be associated.' },
            { name: 'submittal_due_date', type: 'date',
              hint: 'Date when the submittal is due.' },
            { name: 'lead_time_days', type: 'integer',
              hint: 'The number of days of lead time provided for this submittal item.' },
            { name: 'required_on_job_date', type: 'date',
              hint: 'The date when the submitted material is required on the job.' },
            { name: 'design_review_due_date', type: 'date',
              hint: 'The date when the design review is due.' },
            { name: 'general_contractor_review_due_date', type: 'date',
              hint: 'The date when the general contractor\'s review is due.' },
            { name: 'managers', type: 'array', of: 'object',
              hint: 'An array of objects describing users assigned the role of manager.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            },
            { name: 'reviewers', type: 'array', of: 'object',
              hint: 'A list describing users assigned the role of reviewer.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            },
            { name: 'submitters', type: 'array', of: 'object',
              hint: 'A list describing users assigned the role of submitter.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            },
            { name: 'watchers', type: 'array', of: 'object',
              hint: 'A list describing users assigned the role of watcher.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            }
          ]
        when 'field_reports/export'
          [
            { name: 'field_report_uids', label: 'Field Report IDs', optional: false,
              hint: 'A comma separated list of field report IDs.' },
            {
              name: 'file_type',
              control_type: 'select',
              pick_list: 'field_report_export_file_type',
              sticky: true,
              hint: 'Select the file type of the export',
            },
            {
              name: 'timezone',
              control_type: 'select',
              pick_list: 'timezones',
              sticky: true,
              toggle_hint: 'Select timezone',
              toggle_field: {
                name: 'timezone',
                type: 'string',
                label: 'Timezone',
                control_type: 'text',
                optional: false,
                toggle_hint: 'Enter timezone',
                hint: 'A valid timezone. See fill list ' \
                '<a href="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones">here</a>.'
              }
            }
          ]
        else
          []
        end.concat(
          if config_fields['object'] != 'project'
            [
              {
                name: 'project_uid',
                control_type: 'select',
                pick_list: 'project_list',
                label: 'Project',
                optional: false,
                hint: 'If your project is not in top 50, use project ID toggle',
                toggle_hint: 'Select project',
                toggle_field: {
                  name: 'project_uid',
                  type: 'string',
                  control_type: 'text',
                  optional: false,
                  label: 'Project ID',
                  toggle_hint: 'Enter project ID',
                  hint: 'Provide project ID. For example, <b>0bbb5bdb-3f87-4b46-9975-90e797ee9ff9</b>'
                }
              }
            ]
          else
            []
          end
        )
      end
    },

    update_input_schema: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object']
        when 'project'
          [
            { name: 'name', label: 'Project Name', sticky: true },
            { name: 'custom_id', label: 'Project Code', sticky: true },
            {
              name: 'type', control_type: 'select',
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
              }
            },
            { name: 'status', label: 'Project Status', sticky: true },
            { name: 'owner', sticky: true, label: 'Project Owner' },
            { name: 'start_date', type: 'date',
              sticky: true,
              render_input: 'date_conversion',
              parse_output: 'date_conversion',
              label: 'Project Start Date',
              hint: 'Project start date. ISO-8601 date format (DD-MM-YYYY).' },
            { name: 'end_date', type: 'date',
              sticky: true,
              render_input: 'date_conversion',
              parse_output: 'date_conversion',
              label: 'Project End Date',
              hint: 'Project end date. ISO-8601 date format (DD-MM-YYYY).' },
            { name: 'street_1', sticky: true,
              label: 'Street Line 1' },
            { name: 'street_2', sticky: true, label: 'Street line 2' },
            { name: 'city', sticky: true, label: 'Town or City' },
            { name: 'region', sticky: true, label: 'State, Province, or Region' },
            { name: 'postal_code', sticky: true, label: 'Zip or Postal Code' },
            { name: 'country',
              sticky: true,
              hint: 'Project address country in 2-letter ISO 3166 code.' }
          ]
        when 'rfi'
          [
            {
              name: 'locked', type: 'boolean',
              control_type: 'checkbox', toggle_hint: 'Select from options list',
              toggle_field: {
                name: 'locked',
                label: 'Locked',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false'
              }
            },
            { name: 'title', optional: false },
            { name: 'question' },
            { name: 'answer' },
            { name: 'sent_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp',
              hint: 'Date when the RFI was sent. See ' \
              "<a href='https://developer.plangrid.com/v1.15/docs/" \
              "timestamps-and-timezones' target='_blank'>Timestamps and " \
              'Timezones</a> for accepted date formats' },
            { name: 'due_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'assigned_to_uids', hint: "A comma separated list of user IDs." },
            { name: 'status', label: 'Status',
              hint: "Uid's of the RFI's initial status. Defaults to the first RFI status in the project" }
          ]
        when 'issue'
          [
            { name: 'title' },
            {
              name: 'status', control_type: 'select', pick_list:
              %w[open in_review pending closed].select { |op| [op.labelize, op] },
              toggle_hint: 'Select status',
              toggle_field: {
                name: 'status',
                label: 'Status',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are : <b>"open", "in_review", "pending", "closed"</b>.'
              }
            },
            {
              name: 'type', control_type: 'select',
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
                hint: 'Allowed values are: <b>"issue", "planned_work", "other"</b>.'
              }
            },
            { name: 'room', label: 'Location' },
            { name: 'start_date', label: 'Start Date',
              type: 'date_time',
              render_input: 'date_conversion',
              parse_output: 'date_conversion' },
            { name: 'due_at', type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion' },
            { name: 'description' },
            { name: 'cost_impact', label: 'Cost Impact', type: 'number' },
            {
              name: 'has_cost_impact', label: 'Has Cost Impact?', type: 'boolean',
              control_type: 'checkbox', toggle_hint: 'Select from options list',
              toggle_field: {
                name: 'has_cost_impact',
                label: 'Has cost impact',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false'
              }
            },
            { name: 'schedule_impact', label: 'Schedule Impact', type: 'integer',
              hint: "The task's schedule impact in seconds, if it has one." },
            {
              name: 'has_schedule_impact', label: 'Has Schedule Impact?', type: 'boolean',
              control_type: 'checkbox', toggle_hint: 'Select from options list',
              toggle_field: {
                name: 'has_schedule_impact',
                label: 'Has schedule impact',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false'
              }
            },
            { name: 'assigned_to_uids', hint: "A comma separated list of user IDs." },
            { name: 'issue_list_uid', label: 'Task List ID', sticky: true }
          ]
        when 'sheet_packet'
          [
            { name: 'sheet_uids', label: 'Sheet IDs', optional: false,
              type: 'string',
              hint: 'A comma separated list of sheet IDs.' },
            {
              name: 'include_annotations', label: 'Include annotations?', type: 'boolean', sticky: true,
              control_type: 'checkbox', toggle_hint: 'Select from options list',
              toggle_field: {
                name: 'include_annotations',
                label: 'Include annotations?',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false'
              }
            },
          ]
        when 'issue_list'
          [
            { name: 'name', optional: false }
          ]
        when 'sheet_upload'
          [
            { name: 'num_files', label: 'Number of PDFs', type: 'integer', optional: false },
            { name: 'version_name', label: 'Version Name', optional: false }
          ]
        when 'photo'
          [
            { name: 'title', label: 'Photo title',
              hint: 'New title of the photo', sticky: true }
          ]
        when 'submittals/package'
          [
            { name: 'name',
              hint: 'The name of the submittal package.' },
            { name: 'custom_id',
              hint: 'A custom ID for the submittal package.' },
            { name: 'item_uids', label: 'Submittal Item IDs', type: 'array',
              hint: 'The UIDs of the specific items to include in the submittal package.' },
            { name: 'ball_in_court_status',
              hint: 'Reference to the role of the user from whom the next step is expected.' \
              ' Can be \'manager\', \'submitter\', or \'reviewer\'.' },
            { name: 'design_review_due_date', type: 'date',
              hint: 'Due date for the design review.' },
            { name: 'file_group_uid',
              hint: 'UID of the file group to associate with this submittal package.' },
            { name: 'general_contractor_review_due_date', type: 'date',
              hint: 'Due date of the general contractor\'s review.' },
            { name: 'lead_time_days', type: 'integer',
              hint: 'Number of days of lead time provided for this submittal package.' },
            { name: 'notes' },
            { name: 'required_on_job_date', type: 'date',
              hint: 'The date when the submitted material is required on the job.' },
            { name: 'submittal_due_date', type: 'date',
              hint: 'Due date for this submittal package.' },
            { name: 'managers', type: 'array', of: 'object',
              hint: 'An array of objects describing users assigned the role of manager.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            },
            { name: 'reviewers', type: 'array', of: 'object',
              hint: 'An array of objects describing users assigned the role of reviewer.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            },
            { name: 'watchers', type: 'array', of: 'object',
              hint: 'An array of objects describing users assigned the role of watcher.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            }
          ]
        when 'submittals/item'
          [
            { name: 'name',
              hint: 'Name of the submittal item.' },
            { name: 'description',
              hint: 'Description of the submittal package.' },
            { name: 'package_uid', label: 'Submittal Package ID',
              hint: 'ID of the submittal package to which this item should be associated.' },
            { name: 'submittal_due_date', type: 'date',
              hint: 'Date when the submittal is due.' },
            { name: 'lead_time_days', type: 'integer',
              hint: 'The number of days of lead time provided for this submittal item.' },
            { name: 'required_on_job_date', type: 'date',
              hint: 'The date when the submitted material is required on the job.' },
            { name: 'design_review_due_date', type: 'date',
              hint: 'The date when the design review is due.' },
            { name: 'general_contractor_review_due_date', type: 'date',
              hint: 'The date when the general contractor\'s review is due.' },
            { name: 'managers', type: 'array', of: 'object',
              hint: 'An array of objects describing users assigned the role of manager.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            },
            { name: 'reviewers', type: 'array', of: 'object',
              hint: 'A list describing users assigned the role of reviewer.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            },
            { name: 'submitters', type: 'array', of: 'object',
              hint: 'A list describing users assigned the role of submitter.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            },
            { name: 'watchers', type: 'array', of: 'object',
              hint: 'A list describing users assigned the role of watcher.',
              properties: [
                { name: 'type', hint: 'Can be `user` or `group`.' },
                { name: 'uid', hint: 'ID of either the user or group' }
              ]
            }
          ]
        else
          []
        end.concat(
          [
            {
              name: 'project_uid',
              control_type: 'select',
              pick_list: 'project_list',
              label: 'Project',
              optional: false,
              hint: 'If your project is not in top 50, use project ID toggle.',
              toggle_hint: 'Select project',
              toggle_field: {
                name: 'project_uid',
                type: 'string',
                control_type: 'text',
                optional: false,
                label: 'Project ID',
                toggle_hint: 'Enter project ID',
                hint: 'Provide project ID. For example, <b>0bbb5bdb-3f87-4b46-9975-90e797ee9ff9</b>'
              }
            }
          ]
        ).concat(
          case config_fields['object']
          when 'submittals/package'
            [{ name: 'uid', label: 'Submittal Package ID', optional: false }]
          when 'submittals/item'
            [{ name: 'uid', label: 'Submittal Item ID', optional: false }]
          else
            [{ name: 'uid', label: "#{config_fields['object'].labelize} ID", optional: false }]
          end
        )
      end
    },

    upload_input_schema: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object']
        when 'attachment'
          [
            { name: 'content_type',
              hint: 'Content type of the document\'s file. Example for pdf <b>application/pdf</b>',
              optional: false },
            { name: 'file_content', optional: false },
            { name: 'name', optional: false,
              label: 'Document name',
              hint: 'Name of the document.' },
            {
              name: 'folder', label: 'Folder', sticky: true,
              control_type: 'select',
              pick_list: 'project_folders',
              pick_list_params: { project_uid: 'project_uid' },
              toggle_hint: 'Select folder',
              hint: 'Folder shows in select options only if at least one file exist in the folder',
              toggle_field: {
                name: 'folder',
                label: 'Project folder',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Folder in project to place the document ' \
                '(case-sensitive). Leave blank to select root folder'
              }
            },
            {
              name: 'auto_version', type: 'boolean', sticky: true,
              control_type: 'checkbox',
              toggle_hint: 'Select from options list',
              toggle_field: {
                name: 'auto_version',
                type: 'boolean',
                control_type: 'text',
                label: 'Auto version',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false'
              }
            }
          ]
        when 'photo'
          [
            { name: 'content_type', optional: false,
              hint: "Content type of the photo's file" },
            { name: 'file_content', optional: false },
            { name: 'title', optional: false, label: 'Photo title' }
          ]
        when 'file_upload'
          [
            { name: 'ver_upload_uid', label: 'Sheet Version Upload ID', optional: false },
            { name: 'file_upload_request_uid', label: 'File Upload ID', optional: false },
            { name: 'file_name', label: 'File Name', optional: false },
            { name: 'file_content', label: 'File Content', optional: false }
          ]
        when 'version_upload'
          [
            { name: 'ver_upload_uid', label: 'Sheet Version Upload ID', optional: false }
          ]
        else
          []
        end.concat(
          [
            {
              name: 'project_uid',
              control_type: 'select',
              pick_list: 'project_list',
              label: 'Project',
              optional: false,
              hint: 'If your project is not in top 50, use project ID toggle.',
              toggle_hint: 'Select project',
              toggle_field: {
                name: 'project_uid',
                type: 'string',
                control_type: 'text',
                optional: false,
                label: 'Project ID',
                toggle_hint: 'Enter project ID',
                hint: 'Provide project ID. For example, <b>0bbb5bdb-3f87-4b46-9975-90e797ee9ff9</b>'
              }
            }
          ]
        )
      end
    },

    download_input_schema: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object']
        when 'field_reports/export'
          [{ name: 'uid', label: 'Export ID', optional: false }]
        when 'sheets/packet'
          [{ name: 'uid', label: "Sheet Packet ID", optional: false,
               hint: 'Ensure the status of the sheet packet export is `complete` before downloading.' }]
        else
          [{ name: 'uid', label: "#{config_fields['object'].labelize} ID", optional: false }]
        end
      end
    },

    trigger_input: {
      fields: lambda do |_connection, config_fields|
        if config_fields['object'] != 'project'
          [
            {
              name: 'project_uid', optional: false,
              label: 'Project',
              control_type: 'select', pick_list: 'project_list',
              hint: 'If your project is not in top 50, use project ID toggle.',
              toggle_hint: 'Select project',
              toggle_field: {
                name: 'project_uid',
                label: 'Project ID',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Enter project ID',
                hint: 'Provide project ID. For example, <b>0bbb5bdb-3f87-4b46-9975-90e797ee9ff9</b>'
              }
            },
            {
              name: 'output_schema',
              control_type: 'schema-designer',
              ngIf: 'input.object == "field_report"',
              extends_schema: true,
              label: 'PDF field values',
              hint: 'Manually define the values expected of your PDF field values in the field report.',
              optional: true
            }
          ]
        else
          []
        end
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
      description: "Custom <span class='provider'>action</span> in <span class='provider'>Plangrid</span>",
      help: {
        body: 'Build your own Plangrid action for any Plangrid REST endpoint.',
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
        error("#{input['verb']} not supported") if %w[get post patch delete].exclude?(input['verb'])
        data = input.dig('input', 'data').presence || {}
        case input['verb']
        when 'get'
          response = get(input['path'], data).
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

    create_object: {
      title: 'Create object',
      description: lambda do |_, objects|
        "Create <span class='provider'>#{objects['object']&.downcase || 'object'}</span> in <span class='provider'>PlanGrid</span>"
      end,
      help: "Create object in PlanGrid",

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object',
          control_type: 'select',
          pick_list: 'create_object_list',
          hint: 'Select the object from picklist.'
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['create_input_schema']
      end,

      execute: lambda do |_connection, input|
        if input['object'] == 'submittals/package'
          input['item_uids'] = input['item_uids'].split(',')
        end

        if input['object'] == 'field_reports/export'
          input['field_report_uids'] = input['field_report_uids'].split(',')
        end
        
        payload =
          input.except('project_uid', 'object').each_with_object({}) do |(key, val), hash|
            hash[key] = if %w[due_at sent_at].include?(key)
                          val.to_time.utc.iso8601
                        elsif %w[sheet_uids assigned_to_uids].include?(key)
                          val.split(",")
                        else
                          val
                        end
          end
        case input['object']
        when 'project'
          post('/projects').payload(payload).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when 'sheet_packet', 'sheet_upload', 'user_invite'
          path = input['object'].split("_")
          post("/projects/#{input['project_uid']}/#{path.first.pluralize}/#{path.last.pluralize}").payload(payload).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end

        when 'field_reports/export'
          post("/projects/#{input['project_uid']}/field_reports/export").payload(payload).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        else
          post("/projects/#{input['project_uid']}/#{input['object'].pluralize}").payload(payload).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        end.merge('project_uid' => input['project_uid'])
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['get_output_schema']
      end,

      sample_output: lambda do |_connection, input|
        call(:get_sample_output, input['object'], input['project_uid'] || "")
      end
    },

    update_object: {
      title: 'Update object',
      description: lambda do |_, objects|
        "Update <span class='provider'>#{objects['object']&.downcase || 'object'}</span> in <span class='provider'>PlanGrid</span>"
      end,
      help: "Update object in PlanGrid",

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object',
          control_type: 'select',
          pick_list: 'update_object_list',
          hint: 'Select the object from picklist.'
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['update_input_schema']
      end,

      execute: lambda do |_connection, input|
        payload =
          input.except('project_uid', 'uid', 'object').each_with_object({}) do |(key, val), hash|
            hash[key] = %w[due_at sent_at].include?(key) ? val.to_time.utc.iso8601 : val
          end
        if input['object'] == 'project'
          patch("/projects/#{input['project_uid']}").payload(payload).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        else
          patch("/projects/#{input['project_uid']}/#{input['object'].pluralize}/#{input['uid']}").payload(payload).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        end.merge('project_uid' => input['project_uid'])
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['get_output_schema']
      end,

      sample_output: lambda do |_connection, input|
        call(:get_sample_output, input['object'], input['project_uid'] || "")
      end
    },

    get_object: {
      title: 'Get object by ID',
      description: lambda do |_, objects|
        "Get <span class='provider'>#{objects['object']&.downcase || 'object'}</span> in <span class='provider'>PlanGrid</span>"
      end,
      help: "Get object by ID in PlanGrid",

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object',
          control_type: 'select',
          pick_list: 'get_objects',
          toggle_hint: 'Select object',
          hint: 'Select the object from picklist.'
        }
      ],

      input_fields: lambda do |object_definitions|
        [
          {
            name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            hint: 'If your project is not in top 50, use project ID toggle.',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Enter project ID',
              hint: 'Provide project ID. For example, <b>0bbb5bdb-3f87-4b46-9975-90e797ee9ff9</b>'
            }
          },
        ].concat(object_definitions['get_input_schema'])
      end,

      execute: lambda do |_connection, input|
        params =
          input.except('project_uid', 'object').each_with_object({}) do |(key, val), hash|
            hash[key] = %w[updated_after].include?(key) ? val.to_time.utc.iso8601 : val
          end
        case input['object']
        when 'project'
          get("/projects/#{input['project_uid']}")
        when 'field_reports/export'
          get("/projects/#{input['project_uid']}/field_reports/export/#{input['uid']}")
        when 'sheet_packet'
          get("/projects/#{input['project_uid']}/sheets/packets/#{input['uid']}")
        when 'submittals/item'
          get("/projects/#{input['project_uid']}/submittals/items?uids=#{input['uids']}").dig('data',0)
        when 'submittals_file_group'
          get("/projects/#{input['project_uid']}/submittals/packages/#{input['uid']}/file_groups")
          .merge('package_uid' => input['uid'])
        when 'submittals_history'
          get("/projects/#{input['project_uid']}/submittals/packages/#{input['uid']}/history")
          .merge('package_uid' => input['uid'])
        when 'submittals_review_status'
          get("/projects/#{input['project_uid']}/submittals/packages/#{input['uid']}/reviews")
          .merge('package_uid' => input['uid'])
        else
          get("/projects/#{input['project_uid']}/#{input['object'].pluralize}/#{input['uid']}")
        end.merge('project_uid' => input['project_uid'])
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['get_output_schema']
      end,

      sample_output: lambda do |_connection, input|
        call(:get_sample_output, input['object'], input['project_uid'] || "")
      end
    },

    search_objects: {
      title: 'Search objects',
      description: lambda do |_, objects|
        "Search <span class='provider'>#{objects['object']&.downcase&.pluralize || 'objects'}</span> in <span class='provider'>PlanGrid</span>"
      end,
      help: "Search objects in PlanGrid",

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object',
          control_type: 'select',
          pick_list: 'search_objects',
          toggle_hint: 'Select object',
          hint: 'Select the object from picklist.'
        }
      ],

      input_fields: lambda do |object_definitions|
        [
          {
            name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            hint: 'If your project is not in top 50, use project ID toggle.',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Enter project ID',
              hint: 'Provide project ID. For example, <b>0bbb5bdb-3f87-4b46-9975-90e797ee9ff9</b>'
            }
          }
        ].concat(object_definitions['get_input_schema'])
      end,

      execute: lambda do |_connection, input|
        params =
          input.except('project_uid', 'object', 'output_schema').each_with_object({}) do |(key, val), hash|
            hash[key] = %w[updated_after].include?(key) ? val.to_time.utc.iso8601 : val
          end
        case input['object']
        when 'rfi_status'
          response = get("/projects/#{input['project_uid']}/rfis/statuses", params)
          { data: response['data'], total_count: response['total_count'], next_page_url: response['next_page_url'] }
        when 'field_report'
          response = get("/projects/#{input['project_uid']}/#{input['object'].pluralize}", params)
          results = response['data']
          results.map do |field_report|
            field_report.merge('pdf_form_fields' => field_report['pdf_form_values']&.map { |a| { a['name'] => a['value'] } }&.inject(:merge))
          end
          { data: results, total_count: response['total_count'], next_page_url: response['next_page_url'] }
        else
          response = get("/projects/#{input['project_uid']}/#{input['object'].pluralize}", params)
          { data: response['data'], total_count: response['total_count'], next_page_url: response['next_page_url'] }
        end.merge('project_uid' => input['project_uid'])
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: 'data', label: 'Results', type: 'array', of: 'object', properties: object_definitions['get_output_schema']
          },
          { name: 'total_count', label: 'Total Count', type: 'integer' },
          { name: 'next_page_url', label: 'Next Page URL' }
        ]
      end,

      sample_output: lambda do |_connection, input|
        { "data" => Array.wrap(call(:get_sample_output, input['object'], input['project_uid'] || "")) }
      end
    },

    upload_object: {
      title: 'Upload object',
      description: lambda do |_, objects|
        "Upload <span class='provider'>#{objects['object']&.downcase || 'object'}</span> in <span class='provider'>PlanGrid</span>"
      end,
      help: "Upload object in PlanGrid",

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object',
          control_type: 'select',
          pick_list: 'upload_object_list',
          hint: 'Select the object from picklist.'
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['upload_input_schema']
      end,

      execute: lambda do |_connection, input|
        case input['object']
        when 'file_upload'
          file_upload_info = post("/projects/#{input['project_uid']}/sheets/" \
                               "uploads/#{input.delete('ver_upload_uid')}/" \
                               "files/#{input.delete('file_upload_request_uid')}").
                               headers('Content-Type': 'application/json').
                               payload(file_name: input.delete('file_name'))
          call(:get_upload_object, file_upload_info, input)
        when 'photo', 'attachment'
          file_upload_info = post("/projects/#{input['project_uid']}/#{input['object'].pluralize}/uploads").
                               headers('Content-type': 'application/json').
                               payload(input.except('project_uid', 'file_content', 'object'))
          call(:get_upload_object, file_upload_info, input)
        else
          post("/projects/#{input['project_uid']}/sheets/uploads/#{input['ver_upload_uid']}/completions")
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['get_output_schema']
      end,

      sample_output: lambda do |_connection, input|
        call(:get_sample_output, input['object'], input['project_uid'] || "")
      end
    },

    download_object: {
      title: 'Download object',
      description: lambda do |_, objects|
        "Download <span class='provider'>#{objects['object']&.downcase || 'object'}</span> in <span class='provider'>PlanGrid</span>"
      end,
      help: "Download object in PlanGrid",

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object',
          control_type: 'select',
          pick_list: 'download_object_list',
          toggle_hint: 'Select object',
          hint: 'Select the object from picklist.'
        }
      ],

      input_fields: lambda do |object_definitions|
        [
          {
            name: 'project_uid',
            control_type: 'select',
            pick_list: 'project_list',
            label: 'Project',
            optional: false,
            toggle_hint: 'Select project',
            hint: 'If your project is not in top 50, use project ID toggle.',
            toggle_field: {
              name: 'project_uid',
              type: 'string',
              control_type: 'text',
              optional: false,
              label: 'Project ID',
              toggle_hint: 'Enter project ID',
              hint: 'Provide project ID. For example, <b>0bbb5bdb-3f87-4b46-9975-90e797ee9ff9</b>'
            }
          },
        ].concat(object_definitions['download_input_schema'])
      end,

      execute: lambda do |_connection, input|
        case input['object']
        when 'field_reports/export'
          record = get("/projects/#{input['project_uid']}/field_reports/export/#{input['uid']}")
          file_content = get(record['url'] || record['file_url']).
          response_format_raw.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
          { content: file_content }
        else
          record = get("/projects/#{input['project_uid']}/#{input['object'].pluralize}/#{input['uid']}")
          file_content = get(record['url'] || record['file_url']).
          response_format_raw.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
          { content: file_content }
        end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'content', label: 'File Contents' }
        ]
      end
    }
  },

  triggers: {
    new_object: {
      title: 'New object in PlanGrid',
      description: lambda do |_, objects|
        "New <span class='provider'>#{objects['object']&.downcase || 'object'}</span> in <span class='provider'>PlanGrid</span>"
      end,
      help: "Triggers when an object is created",

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object',
          control_type: 'select',
          pick_list: 'object_list',
          hint: 'Select the object from picklist.'
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['trigger_input'].concat(
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
        )
      end,
      poll: lambda do |_connection, input, closure|
        updated_after = closure&.[]('updated_after') ||
                        (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 10
        skip = closure&.[]('skip') || 0
        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   elsif input['object'] == 'project'
                     get("/projects").params(limit: limit, skip: skip, updated_after: updated_after)
                   elsif input['object'] == 'issue'
                     get("/projects/#{input['project_uid']}/#{input['object'].pluralize}").
                       params(limit: limit, skip: skip, updated_after: updated_after, include_annotationless: true)
                   elsif input['object'] == 'field_report'
                     get("/projects/#{input['project_uid']}/#{input['object'].pluralize}").
                       params(limit: limit, skip: skip, updated_after: updated_after)
                   else
                     get("/projects/#{input['project_uid']}/#{input['object'].pluralize}").
                       params(limit: limit, skip: skip, updated_after: updated_after)
                   end
        closure = if (next_page_url = response['next_page_url']).present?
                    { 'skip' => skip + limit,
                      'next_page_url' => next_page_url }
                  else
                    { 'skip' => 0,
                      'updated_after' => response['data']&.
                                           last&.[]('created_at') || response['data']&.last&.[]('published_at') }
                  end
        objects = if input['object'] == 'field_report'
                    response['data']&.map do |field_report|
                      field_report.merge('pdf_form_fields' => field_report['pdf_form_values']&.map { |a| { a['name'] => a['value'] } }&.inject(:merge),
                                         'project_uid' => input['project_uid'])
                    end
                  else
                    response['data']&.map { |o| o.merge('project_uid' => input['project_uid']) }
                  end
        {
          events: objects || [],
          next_poll: closure,
          can_poll_more: response['next_page_url'].present?
        }
      end,
      dedup: lambda do |object|
        object['uid']
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['get_output_schema']
      end,
      sample_output: lambda do |_connection, input|
        call(:get_sample_output, input['object'], input['project_uid'] || "")
      end
    },

    new_updated_object: {
      title: 'New or updated object in PlanGrid',
      description: lambda do |_, objects|
        "New or updated <span class='provider'>#{objects['object']&.downcase || 'object'}</span> in <span class='provider'>PlanGrid</span>"
      end,
      help: "Triggers when an object is created or updated",

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object',
          control_type: 'select',
          pick_list: 'object_list_new',
          hint: 'Select the object from picklist.'
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['trigger_input'].concat(
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
        )
      end,
      poll: lambda do |_connection, input, closure|
        updated_after = closure&.[]('updated_after') ||
                        (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 10
        skip = closure&.[]('skip') || 0
        update_time = Time.now.utc.iso8601
        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   elsif input['object'] == 'project'
                     get("/projects").params(limit: limit, skip: skip, updated_after: updated_after)
                   elsif input['object'] == 'issue'
                     get("/projects/#{input['project_uid']}/#{input['object'].pluralize}").
                       params(limit: limit, skip: skip, updated_after: updated_after, include_annotationless: true)
                   elsif input['object'] == 'field_report'
                     get("/projects/#{input['project_uid']}/#{input['object'].pluralize}").
                       params(limit: limit, skip: skip, updated_after: updated_after)
                   else
                     get("/projects/#{input['project_uid']}/#{input['object'].pluralize}").
                       params(limit: limit, skip: skip, updated_after: updated_after)
                   end
        object_update_time = ['annotation', 'sheet', 'attachment'].include? input['object']
        closure = if (next_page_url = response['next_page_url']).present?
                    { 'skip' => skip + limit,
                      'next_page_url' => next_page_url }
                  else
                    { 'skip' => 0,
                      'updated_after' =>  object_update_time ? update_time : response['data']&.last&.[]('updated_at') }
                  end
        project_hash = { 'project_uid' => input['project_uid'] }
        project_hash["updated_after"] = (closure["updated_after"] || updated_after) if ['annotation', 'sheet', 'attachment'].include? input['object']
        objects = if input['object'] == 'field_report'
                    response['data']&.map do |field_report|
                      field_report.merge('pdf_form_fields' => field_report['pdf_form_values']&.map { |a| { a['name'] => a['value'] } }&.inject(:merge),
                                         'project_uid' => input['project_uid'])
                    end
                  else
                    response['data']&.map { |o| o.merge('project_uid' => input['project_uid']) }
                  end
        {
          events: objects || [],
          next_poll: closure,
          can_poll_more: response['next_page_url'].present?
        }
      end,
      dedup: lambda do |object|
        "#{object['uid']}@#{(object['updated_after'] || object['updated_at'])}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['get_output_schema']
      end,
      sample_output: lambda do |_connection, input|
        call(:get_sample_output, input['object'], input['project_uid'] || "")
      end
    },
  },

  methods: {
    get_sample_output: lambda do |object, project_uid|
      case object
      when 'project'
        get('/projects')&.dig('data', 0)
      when 'field_report'
        results = get("/projects/#{project_uid}/field_reports").dig('data', 0)&.merge('project_uid' => project_uid)
      when 'rfi_status'
        get("/projects/#{project_uid}/rfis/statuses")&.dig('data', 0)&.merge('project_uid' => project_uid)
      when 'user_invite'
        get("/projects/#{project_uid}/users")&.dig('data', 0)&.merge('project_uid' => project_uid)
      when 'sheet_packet'
        {
          "data" => [
            {
              uid: "92cf7193-af0c-42fc-a3ab-7ef5149da720",
              file_url: "https://packet-assets.plangrid.com/92cf7193-af0c-42fc-a3ab-7ef5149da720.pdf",
              resource: {
                uid: "92cf7193-af0c-42fc-a3ab-7ef5149da720",
                url: "https://io.plangrid.com/projects/da48fcc3-7af1-4fd6-a083-70195468718a/sheets/" \
                     "packets/92cf7193-af0c-42fc-a3ab-7ef5149da720"
              },
              status: "incomplete"
            }
          ]
        }
      when 'sheet_upload'
        {
          "data" => [
            {
              uid: "d050ed4d-425b-4cd2-a46a-1113be6ed37c",
              complete_url: "https://io.plangrid.com/projects/5a77d1aa-44ef-4d0f-904a-839015d82dbb/sheets/uploads/d050ed4d-425b-4cd2-a46a-1113be6ed37c/completions",
              status: "incomplete",
              file_upload_requests: [
                {
                  uid: "cba96343-bfaf-4f95-805a-dd49169944c0",
                  upload_status: "issued",
                  url: "https://io.plangrid.com/projects/5a77d1aa-44ef-4d0f-904a-839015d82dbb/sheets/uploads/d050ed4d-425b-4cd2-a46a-1113be6ed37c/files/cba96343-bfaf-4f95-805a-dd49169944c0"
                }
              ]
            }
          ]
        }
      when 'version_upload'
        {
          "data" => [
            {
              uid: "f23f1677-cb77-425f-bdd5-626a9fba8e83",
              complete_url: "https://io.plangrid.com/projects/5a77d1aa-44ef-4d0f-904a-839015d82dbb/sheets/uploads/f23f1677-cb77-425f-bdd5-626a9fba8e83/completions",
              status: "complete"
            }
          ]
        }
      else
        get("/projects/#{project_uid}/#{object.pluralize}")&.dig('data', 0)&.merge('project_uid' => project_uid)
      end
    end,

    get_upload_object: lambda do |file_upload_info, input|
      headers = file_upload_info&.dig('aws_post_form_arguments', 'fields')&.
                  each_with_object({}) do |obj, hash|
                    hash[obj['name']] = obj['value']
                  end
      post(file_upload_info&.dig('aws_post_form_arguments', 'action')).
        payload(key: headers['key'],
                policy: headers['policy'],
                signature: headers['signature'],
                AWSAccessKeyId: headers['AWSAccessKeyId'],
                'content-type': headers['Content-Type'],
                'success_action_redirect': headers['success_action_redirect'],
                'x-amz-server-side-encryption':
                  headers['x-amz-server-side-encryption'],
                'x-amz-storage-class': headers['x-amz-storage-class'],
                file: input['file_content']).
        request_format_multipart_form.
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    make_schema_builder_fields_sticky: lambda do |input|
      input.map do |field|
        if field[:properties].present?
          field[:properties] = call("make_schema_builder_fields_sticky",
                                    field[:properties])
        elsif field["properties"].present?
          field["properties"] = call("make_schema_builder_fields_sticky",
                                     field["properties"])
        end
        field[:sticky] = true
        field
      end
    end
  },

  pick_lists: {
    create_object_list: lambda do |_connection|
      [
        ['Project', 'project'],
        ['Field Report Export', 'field_reports/export'],
        ['Invite User', 'user_invite'],
        ['RFI', 'rfi'],
        ['Task List', 'issue_list'],
        ['Task', 'issue'],
        ['Sheet Packet', 'sheet_packet'],
        ['Sheet Version', 'sheet_upload'],
        ['Submittal Item', 'submittals/item'],
        ['Submittal Package', 'submittals/package']
      ]
    end,

    update_object_list: lambda do |_connection|
      [
        ['Project', 'project'],
        ['Photo', 'photo'],
        ['RFI', 'rfi'],
        ['Task List', 'issue_list'],
        ['Task', 'issue'],
        ['Submittal Package', 'submittals/package'],
        ['Submittal Item', 'submittals/item']
      ]
    end,

    upload_object_list: lambda do |_connection|
      [
        ['Document', 'attachment'],
        ['Photo', 'photo'],
        ['File to Sheet Version', 'file_upload'],
        ['Complete Sheet Version', 'version_upload']
      ]
    end,

    get_objects: lambda do |_connection|
      [["Project", "project"], ["RFI", "rfi"], ["Task", "issue"], ["User", "user"],
       ["Snapshot", "snapshot"], ["Sheet", "sheet"], ["Sheet Packet", "sheet_packet"],
       ["Photo", "photo"], ["Document", "attachment"], ["Task_list", "issue_list"]]
    end,

    search_objects: lambda do |_connection|
      [
        ['Field Report', 'field_report'],
        ['Field Report Template', 'field_report_template'],
        ['RFI Status', 'rfi_status'],
        ['Role', 'role']
      ]
    end,

    download_object_list: lambda do |_connection|
      [
        ['Document', 'attachment'],
        ['Field Report Export', 'field_reports/export'],
        ['Sheet Packet', 'sheets/packet']
      ]
    end,

    object_list: lambda do |_connection|
      [["Project", "project"], ["Sheet", "sheet"], ["Document", "attachment"], ["Task", "issue"], ["RFI", "rfi"],
       ["Annotation", "annotation"], ["Photo", "photo"], ["Snapshot", "snapshot"], ["Field Report", "field_report"]]
    end,

    object_list_new: lambda do |_connection|
      [["Project", "project"], ["Task", "issue"], ["RFI", "rfi"], ["Sheet", "sheet"], ["Field Report", "field_report"],
       ["Document", "attachment"], ["Annotation", "annotation"]]
    end,

    project_list: lambda do |_connection|
      get('/projects')&.[]('data')&.pluck('name', 'uid')
    end,

    project_types: lambda do |_connection|
      ['general', 'manufacturing', 'power', 'water-sewer-waste',
       'industrial-petroleum', 'transportation', 'hazardous-waste',
       'telecom', 'education-k-12', 'education-higher', 'gov-federal',
       'gov-state-local', 'other'].map { |type| [type.labelize, type] }
    end,
    
    download_object_list: lambda do |_connection|
      [
        ['Document', 'attachment'],
        ['Field Report Export', 'field_reports/export'],
        ['Sheet Packet', 'sheets/packet']
      ]
    end,

    project_folders: lambda do |_connection, project_uid:|
      if project_uid.length == 36
        folders = get("/projects/#{project_uid}/attachments")['data']&.
                  pluck('folder')&.uniq
        folders.size > 0 ? folders&.map { |folder| [folder || 'Root', folder || ''] } : [['Root', '']]
      end
    end,

    field_report_export_file_type: lambda do |_connection|
      [
        [ 'PDF', 'pdf' ],
        [ 'XLSL', 'xlsx' ]
      ]
    end,

    timezones: lambda do |_connection|
      [
        ['America/Los_Angeles','America/Los_Angeles'],
        ['America/Denver','America/Denver'],
        ['America/Phoenix','America/Phoenix'],
        ['America/Chicago','America/Chicago'],
        ['America/Mexico_City','America/Mexico_City'],
        ['America/New_York','America/New_York']
      ]
    end
  }
}
