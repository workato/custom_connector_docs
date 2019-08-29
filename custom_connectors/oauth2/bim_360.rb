{
  title: 'BIM 360',
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
      },
      {
        name: 'account_id',
        optional: false,
        hint: 'The account ID of the project. This corresponds to hub ID in' \
        ' the Data Management API. To convert a hub ID into an account ID ' \
        'you need to remove the “b.” prefix. For example, a hub ID of ' \
        'b.c8b0c73d-3ae9 translates to an account ID of c8b0c73d-3ae9.'
      }
    ],
    authorization: {
      type: 'oauth2',
      authorization_url: lambda do |connection|
        scopes = 'user:read account:read data:write data:write data:read' \
        ' data:create account:write'
        'https://developer.api.autodesk.com/authentication/v1/authorize?' \
        'response_type=' \
        "code&client_id=#{connection['client_id']}&" \
        "scope=#{scopes}"
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        response = post('https://developer.api.autodesk.com/authentication/' \
          'v1/gettoken').
                   payload(client_id: connection['client_id'],
                           client_secret: connection['client_secret'],
                           grant_type: 'authorization_code',
                           code: auth_code,
                           redirect_uri: redirect_uri).
                   request_format_www_form_urlencoded
        [response, nil, nil]
      end,
      refresh_on: [401, 403],
      refresh: lambda do |connection, refresh_token|
        scopes = 'user:read account:read data:read data:write account:write'
        post('https://developer.api.autodesk.com/authentication/v1/' \
             'refreshtoken').
          payload(client_id: connection['client_id'],
                  client_secret: connection['client_secret'],
                  grant_type: 'refresh_token',
                  refresh_token: refresh_token,
                  scope: scopes).
          request_format_www_form_urlencoded
      end,
      apply: lambda do |_connection, access_token|
        headers(Authorization: "Bearer #{access_token}")
        # headers(Authorization: "Bearer #{access_token}",
        #         'Content-Type': 'application/vnd.api+json')
      end
    },
    base_uri: lambda do |_connection|
      'https://developer.api.autodesk.com'
    end
  },
  test: lambda do |_connection|
    get('/userprofile/v1/users/@me')
  end,
  methods: {
    format_search: lambda do |input|
      if input.is_a?(Hash)
        input.map do |key, value|
          value = call('format_search', value)
          if %w[limit offset].include?(key)
            { "page[#{key}]" => value }
          elsif %w[include_voided assigned_to target_urn due_date synced_after
                   created_at created_by search
                   ng_issue_type_id ng_issue_subtype_id status].include?(key)
            { "filter[#{key}]" => value }
          elsif %w[rfis].include?(key)
            { "fields[#{key}]" => value }
          else
            { key => value }
          end
        end.inject(:merge)
      else
        input
      end
    end,
    make_schema_builder_fields_sticky: lambda do |input|
      input.map do |field|
        if field[:properties].present?
          field[:properties] = call('make_schema_builder_fields_sticky',
                                    field[:properties])
        elsif field['properties'].present?
          field['properties'] = call('make_schema_builder_fields_sticky',
                                     field['properties'])
        end
        field[:sticky] = true
        field
      end
    end,
    sample_data_export_job: lambda do
      {
        'id': '433d07ec-32a2-44eb-a5eb-b41090bfe932',
        'status': 'completed',
        'data': {
          'versionUrn': 'dXJuOmFkc2sud2lwcWE6ZnMuZmlsZTp2Zi5wZjNm' \
          'clUwZ1RaYU9vdEtYZzJoMUZ3P3ZlcnNpb249MQ',
          'resourceId': "urn:adsk.viewing:fs.file:dXJuOmFkc2sud2lwcWE6Zn' \
          'MuZmlsZTp2Zi5wZjNmclUwZ1RaYU9vdEtYZzJoMUZ3P3ZlcnNpb249MQ/output' \
          '/qXP_ZA5_3EqJoq5zqvnLHA/h8YAl4KMcEe9-L5SaEXY6A.pdf",
          'link': "https://developer.api.autodesk.com/modelderivative/v2/' \
          'designdata/dXJuOmFkc2sud2lwcWE6ZnMuZmlsZTp2Zi5wZjNmclUwZ1RaYU9v' \
          'dEtYZzJoMUZ3P3ZlcnNpb249MQ/manifest/urn%3Aadsk.viewing%3Afs.file' \
          '%3AdXJuOmFkc2sud2lwcWE6ZnMuZmlsZTp2Zi5wZjNmclUwZ1RaYU9vdEtYZzJo' \
          'MUZ3P3ZlcnNpb249MQ%2Foutput%2FqXP_ZA5_3EqJoq5zqvnLHA%2Fh8YAl4KM' \
          'cEe9-L5SaEXY6A.pdf"
        }
      }
    end
  },
  object_definitions: {
    project: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id', label: 'Project ID' },
          { name: 'type' },
          { name: 'attributes', type: 'object', properties: [
            { name: 'name' }
          ]},
          { name: 'relationships', type: 'object', properties: [
            { name: 'hub', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'id', label: 'Hub ID' }
              ]}
            ]},
            { name: 'rootFolder', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'id', label: 'Root Folder ID' }
              ]}
            ]},
            { name: 'issues', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'id', label: 'Issues Container ID' }
              ]}
            ]},
            { name: 'submittals', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'id', label: 'Submittals Container ID' }
              ]}
            ]},
            { name: 'rfis', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'id', label: 'RFIs Container ID' }
              ]}
            ]},
            { name: 'markups', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'id', label: 'Markups Container ID' }
              ]}
            ]},
            { name: 'checklists', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'id', label: 'Checklists Container ID' }
              ]}
            ]},
            { name: 'cost', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'id', label: 'Cost Container ID' }
              ]}
            ]},
            { name: 'location', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'id', label: 'Locations Container ID' }
              ]}
            ]}
          ]}

          # These are not correct
          # { name: 'name', label: 'Project name' },
          # { name: 'start_date', type: 'date' },
          # { name: 'end_date', type: 'date' },
          # { name: 'project_type',
          #   control_type: 'select', pick_list: 'project_types',
          #   toggle_hint: 'Select project type',
          #   toggle_field: {
          #     name: 'project_type',
          #     type: 'string',
          #     control_type: 'text',
          #     label: 'Project type',
          #     toggle_hint: 'Use custom value'
          #   },
          #   hint: 'Refer to the preconfigured ' \
          #   "project_type list in the <a href='https://forge.autodesk." \
          #   "com/en/docs/bim360/v1/overview/parameters' target= '_blank'>" \
          #   'Parameters</a> guide' },
          # { name: 'value', label: 'Monetary value' },
          # { name: 'currency', control_type: 'select',
          #   pick_list: 'currency_list',
          #   toggle_hint: 'Select currency',
          #   toggle_field: {
          #     name: 'currency',
          #     type: 'string',
          #     control_type: 'text',
          #     label: 'Project type',
          #     toggle_hint: 'Use custom value'
          #   } },
          # { name: 'status', control_type: 'select',
          #   pick_list: 'status_list',
          #   toggle_hint: 'Select status',
          #   toggle_field: {
          #     name: 'status',
          #     type: 'string',
          #     control_type: 'text',
          #     label: 'Status',
          #     toggle_hint: 'Use custom value'
          #   } },
          # { name: 'job_number' },
          # { name: 'address_line_1' },
          # { name: 'address_line_2' },
          # { name: 'city' },
          # { name: 'state_or_province' },
          # { name: 'postal_code' },
          # { name: 'country' },
          # { name: 'postal_code' },
          # { name: 'country' },
          # { name: 'business_unit_id' },
          # { name: 'timezone', hint: 'Refer to the preconfigured ' \
          # "project_type list in the <a href='https://forge.autodesk." \
          # "com/en/docs/bim360/v1/overview/parameters' target= '_blank'>" \
          # 'Parameters</a> guide' },
          # { name: 'language', control_type: 'select', pick_list:
          #   [%w[English en], %w[German de]] },
          # { name: 'construction_type', hint: 'Refer to the preconfigured ' \
          #   "project_type list in the <a href='https://forge.autodesk." \
          #   "com/en/docs/bim360/v1/overview/parameters' target= '_blank'>" \
          #   'Parameters</a> guide' },
          # { name: 'contract_type', hint: 'Refer to the preconfigured ' \
          #   "project_type list in the <a href='https://forge.autodesk." \
          #   "com/en/docs/bim360/v1/overview/parameters' target= '_blank'>" \
          #   'Parameters</a> guide' },
          # { name: 'last_sign_in', hint: 'Timestamp of the last sign in,' \
          #   ' YYYY-MM-DDThh:mm:ss.sssZ format' }
        ]
      end
    },
    issue: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id', label: 'Issue ID' },
          { name: 'attributes', type: 'object', properties: [
            { name: 'created_at', type: 'date_time',
              hint: 'The timestamp of the date and time the issue was ' \
              'created, in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'synced_at', type: 'date_time',
              hint: 'The date and time the issue was synced with BIM 360, ' \
              'in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'updated_at', type: 'date_time',
              hint: 'The last time the issue’s attributes were updated, in '\
              '<b>the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'close_version',
              hint: 'The version of the issue when it was closed.' },
            { name: 'closed_at', type: 'date_time',
              hint: 'The timestamp of the data and time the issue was ' \
              'closed, in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'closed_by',
              hint: 'The Autodesk ID of the user who closed the issue.' },
            { name: 'created_by',
              hint: 'The Autodesk ID of the user who created the issue.' },
            { name: 'starting_version', type: 'integer',
              hint: 'The first version of the issue' },
            { name: 'title', label: 'Issue title' },
            { name: 'description',
              hint: 'The description of the purpose of the issue.' },
            { name: 'location_description',
              hint: 'The location of the issue.' },
            { name: 'target_urn',
              hint: 'The item ID of the document associated with the ' \
              'pushpin issue.' },
            { name: 'due_date', type: 'date_time',
              hint: 'The timestamp of the issue’s specified due date,' \
              ' in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'identifier', type: 'integer',
              hint: 'The identifier of the issue.' },
            { name: 'status', control_type: 'select',
              pick_list: 'issue_status_list',
              toggle_hint: 'Select status',
              toggle_field: {
                name: 'status', label: 'Status', type: 'string',
                control_type: 'text', toggle_hint: 'Use custom value',
                hint: 'Allowed values are :<b>open, work_complete,
                ready_to_inspect, not_approved, close in_dispute, void</b>.'
              } },
            { name: 'assigned_to', hint: 'The Autodesk ID of the user' },
            { name: 'assigned_to_type', hint: 'The type of subject this ' \
              'issue is assigned to. Possible values: user, company, role' },
            { name: 'answer' },
            { name: 'answered_at', type: 'date_time',
              hint: 'The date and time the issue was answered, in the ' \
              'following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>.',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'answered_by',
              hint: 'The user who suggested an answer for the issue.' },
            { name: 'pushpin_attributes',
              hint: 'The type and location of the pushpin' },
            { name: 'owner',
              hint: 'The Autodesk ID of the user who owns this issue.' },
            { name: 'root_cause_id' },
            { name: 'root_cause' },
            { name: 'quality_urns', type: 'object' },
            { name: 'permitted_statuses', type: 'array', of: 'string',
              hint: 'A list of statuses accessible to the current user.' },
            { name: 'permitted_attributes', type: 'array', of: 'string',
              hint: 'A list of attributes accessible to the current user.' },
            { name: 'comment_count', type: 'integer',
              hint: 'The number of comments added to this issue.' },
            { name: 'attachment_count',
              hint: 'The number of attachments added to this issue.' },
            { name: 'permitted_actions',
              hint: 'The actions that are permitted for the issue in' \
              ' this state.' },
            { name: 'lbs_location',
              hint: 'The ID of the location that relates to the issue.' },
            { name: 'sheet_metadata' },
            { name: 'ng_issue_type_id', label: 'Issue type ID',
              hint: 'The ID of the issue type.' },
            { name: 'ng_issue_subtype_id', label: 'Issue subtype ID',
              hint: 'The ID of the issue subtype' }
          ] },
          # To Do
          { name: 'custom_attributes', type: 'array', of: 'object' },
          { name: 'trades', type: 'array', of: 'object' },
          { name: 'comments_attributes', type: 'array', of: 'object',
            properties: [
              { name: 'id', label: 'Comment ID' },
              { name: 'type' },
              { name: 'attributes', type: 'object', properties: [
                { name: 'created_at', type: 'date_time',
                  hint: 'The timestamp of the date and time the issue was ' \
                  'created, in the following format: ' \
                  '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                  render_input: 'render_iso8601_timestamp',
                  parse_output: 'parse_iso8601_timestamp' },
                { name: 'synced_at', type: 'date_time',
                  hint: 'The timestamp of the date and time the issue was ' \
                  'synced, in the following format: ' \
                  '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                  render_input: 'render_iso8601_timestamp',
                  parse_output: 'parse_iso8601_timestamp' },
                { name: 'updated_at', type: 'date_time',
                  hint: 'The timestamp of the date and time the issue was ' \
                  'updated, in the following format: ' \
                  '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                  render_input: 'render_iso8601_timestamp',
                  parse_output: 'parse_iso8601_timestamp' },
                { name: 'issue_id' },
                { name: 'rfi_id' },
                { name: 'body' },
                { name: 'created_by',
                  hint: 'The ID of the user who created the attachment.' }
              ] }
            ] },
          { name: 'attachments_attributes', type: 'array', of: 'object',
            properties: [
              { name: 'id', label: 'Attachment ID' },
              { name: 'type' },
              { name: 'attributes', type: 'object', properties: [
                { name: 'created_at', type: 'date_time',
                  hint: 'The timestamp of the date and time the issue was ' \
                  'created, in the following format: ' \
                  '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                  render_input: 'render_iso8601_timestamp',
                  parse_output: 'parse_iso8601_timestamp' },
                { name: 'created_by' },
                { name: 'synced_at', type: 'date_time',
                  hint: 'The timestamp of the date and time the issue was ' \
                  'synced, in the following format: ' \
                  '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                  render_input: 'render_iso8601_timestamp',
                  parse_output: 'parse_iso8601_timestamp' },
                { name: 'updated_at', type: 'date_time',
                  hint: 'The timestamp of the date and time the issue was ' \
                  'updated, in the following format: ' \
                  '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                  render_input: 'render_iso8601_timestamp',
                  parse_output: 'parse_iso8601_timestamp' },
                { name: 'attachment_type' },
                { name: 'deleted_at', type: 'date_time',
                  hint: 'The timestamp of the date and time the issue was ' \
                  'deleted, in the following format: ' \
                  '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                  render_input: 'render_iso8601_timestamp',
                  parse_output: 'parse_iso8601_timestamp' },
                { name: 'deleted_by', hint: 'The ID of the user who deleted' \
                  ' the attachment. This is only relevant for deleted' \
                  ' attachments.' },
                { name: 'rfi_id' },
                { name: 'name' },
                { name: 'resource_urns', type: 'array', of: 'string' },
                { name: 'url' },
                { name: 'urn' },
                { name: 'urn_page' },
                { name: 'urn_type' },
                { name: 'urn_version' },
                { name: 'permitted_actions' }
              ] }
            ] }
        ]
      end
    },
    create_issue: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'title', label: 'Issue title' },
          { name: 'description',
            hint: 'The description of the purpose of the issue.' },
          { name: 'status', control_type: 'select',
            pick_list: %w[draft open].
              map { |option| [option.labelize, option] },
            toggle_hint: 'Select status',
            toggle_field: {
              name: 'status', label: 'Status', type: 'string',
              control_type: 'text', toggle_hint: 'Use custom value',
              hint: 'The status of the issue. Possible values:<b>draft, ' \
              'open</b>. The default is draft'
            } },
          { name: 'starting_version', type: 'integer',
            hint: 'The first version of the issue' },
          { name: 'due_date', type: 'date_time',
            hint: 'The timestamp of the issue’s specified due date,' \
            ' in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
            render_input: 'render_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'location_description' },
          { name: 'created_at', type: 'date_time',
            hint: 'The timestamp of the date and time the issue was ' \
            'created, in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
            render_input: 'render_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'assigned_to',
            hint: 'The Autodesk ID (uid) of the user you want to assign' \
            ' to this issue.' },
          { name: 'assigned_to_type', hint: 'The type of subject this ' \
            'issue is assigned to. Possible values: user, company, role' },
          { name: 'owner',
            hint: 'The BIM 360 ID of the user who owns this issue.' },
          { name: 'ng_issue_type_id', label: 'Issue type ID',
            hint: 'The ID of the issue type.' },
          { name: 'ng_issue_subtype_id', label: 'Issue subtype ID',
            hint: 'The ID of the issue subtype' },
          { name: 'root_cause_id',
            hint: 'The ID of the type of root cause for this issue.' },
          { name: 'quality_urns', type: 'object' }
        ]
      end
    },
    update_issue: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id', label: 'Issue ID',
            optional: 'false' },
          { name: 'title', label: 'Issue title',
            optional: 'false' },
          { name: 'description',
            hint: 'The description of the purpose of the issue.' },
          { name: 'status', control_type: 'select',
            pick_list: 'issue_status_list',
            toggle_hint: 'Select status',
            toggle_field: {
              name: 'status', label: 'Status', type: 'string',
              control_type: 'text', toggle_hint: 'Use custom value',
              hint: 'The status of the issue. Possible values:<b>draft, ' \
              'open</b>. The default is draft'
            } },
          { name: 'due_date', type: 'date_time',
            hint: 'The timestamp of the issue’s specified due date,' \
            ' in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
            render_input: 'render_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'location_description' },
          { name: 'assigned_to',
            hint: 'The Autodesk ID (uid) of the user you want to assign' \
            ' to this issue.' },
          { name: 'assigned_to_type', hint: 'The type of subject this ' \
            'issue is assigned to. Possible values: user, company, role' },
          { name: 'owner',
            hint: 'The BIM 360 ID of the user who owns this issue.' },
          { name: 'ng_issue_type_id', label: 'Issue type ID',
            hint: 'The ID of the issue type. You can only configure this' \
            ' attribute when the issue is in draft state' },
          { name: 'ng_issue_subtype_id', label: 'Issue subtype ID',
            hint: 'The ID of the issue subtype. You can configure this ' \
            'attribute when the issue is in draft or open state' },
          { name: 'root_cause_id',
            hint: 'The ID of the type of root cause for this issue.' },
          { name: 'quality_urns', type: 'object' },
          { name: 'close_version' }
        ]
      end
    },
    rfi: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id', label: 'RFI ID' },
          { name: 'attributes', type: 'object', properties: [
            { name: 'created_at', type: 'date_time',
              hint: 'The timestamp of the date and time the issue was ' \
              'created, in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'synced_at', type: 'date_time',
              hint: 'The date and time the issue was synced with BIM 360, ' \
              'in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'updated_at', type: 'date_time',
              hint: 'The last time the issue’s attributes were updated, in '\
              '<b>the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'answer', hint: 'An answer for the RFI.' },
            { name: 'answered_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp',
              hint: 'The last time the RFI answer attribute was updated, ' \
              'in the following format: <b>YYYY-MM-DDThh:mm:ss.sz<\b>.' },
            { name: 'answered_by',
              hint: 'The Autodesk ID of the user who updated the RFI answer' \
              ' attribute' },
            { name: 'manager',
              hint: 'The last actual manager (GC) of the RFI' },
            { name: 'reviewer',
              hint: 'The last actual reviewer (CM or Arch) of the RFI.' },
            { name: 'assigned_to', hint: 'The Autodesk ID of the user' },
            { name: 'assigned_to_type',
              control_type: 'select',
              pick_list: 'assigned_type_list',
              toggle_hint: 'Select assigned type',
              toggle_field: {
                name: 'assigned_to_type',
                type: 'string',
                control_type: 'text',
                label: 'Assigned Type',
                toggle_hint: 'Use custom value',
                hint: 'The type of assignee the RFI is assigned to. ' \
                'Possible values: <b>user, company, role</b>'
              } },
            { name: 'assignees', type: 'array', of: 'object', properties: [
              { name: 'id' },
              { name: 'type' }
            ] },
            { name: 'attachment_count',
              hint: 'The number of attachments associated with the RFI.' },
            { name: 'close_version' },
            { name: 'closed_at', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp',
              hint: 'The timestamp of the date and time the RFI was closed' },
            { name: 'closed_by',
              hint: 'The Autodesk ID of the user who closed the RFI.' },
            { name: 'co_reviewers', hint: 'A list of alternative reviewers.' \
              ' Provide comma separated list of values.' },
            { name: 'collection_urn' },
            { name: 'comment_count',
              hint: 'The number of comments added to the RFI.' },
            { name: 'created_by',
              hint: 'The Autodesk ID of the user who created the RFI.' },
            { name: 'description' },
            { name: 'due_date', type: 'date_time',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp',
              hint: 'The timestamp of the due date for the RFI, in the ' \
              'following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>' },
            { name: 'identifier',
              hint: 'The identifier of the RFI. This corresponds to the RFI' \
              ' ID number in the UI' },
            { name: 'custom_identifier',
              hint: 'A custom identifier of the RFI selected by the user.' },
            { name: 'identifier_minor', type: 'integer' },
            { name: 'location_description',
              hint: 'A description of the location of the RFI in the ' \
              'construction project.' },
            { name: 'markup_metadata' },
            { name: 'permitted_actions', hint: 'A list of actions that are' \
              ' permitted for the user.' },
            { name: 'permitted_attributes',
              hint: 'A list of attributes the user can modify.' },
            { name: 'permitted_statuses', hint: 'array of strings' },
            { name: 'permitted_transitions', type: 'array', of: 'object',
              hint: 'A list of potential transitions.',
              properties: [
                { name: 'id' },
                { name: 'is_specific_assignee', control_type: 'checkbox',
                  hint: 'Is the RFI can be assigned to a specific user',
                  type: 'boolean', toggle_hint: 'Select from options list',
                  toggle_field: {
                    name: 'is_specific_assignee',
                    type: 'string',
                    control_type: 'text',
                    label: 'Specific assignee',
                    hint: 'Is the RFI can be assigned to a specific user',
                    toggle_hint: 'Provide custom vlaue. ' \
                    'Allowed values are <b>true, false</b>'
                  } },
                { name: 'status', control_type: 'select',
                  pick_list: 'rfi_transaction_status_list',
                  hint: 'The status of the RFI after the transition',
                  toggle_hint: 'Select status',
                  toggle_field: {
                    name: 'status',
                    label: 'Status',
                    type: 'string',
                    control_type: 'text',
                    toggle_hint: 'Provie custom value',
                    hint: 'Possible values: <b>draft, submitted, open, ' \
                    'rejected, answered, closed, void</b>'
                  } },
                { name: 'title' },
                { name: 'assignees', type: 'array', of: 'object', properties: [
                  { name: 'id' },
                  { name: 'type' }
                ] },
                { name: 'pushpin_attributes', type: 'object' },
                { name: 'resource_urns', hint: 'List of urns' },
                { name: 'sheet_metadata', type: 'object' },
                { name: 'starting_version',
                  hint: 'The first version of the RFI' },
                { name: 'suggested_answer',
                  hint: 'The suggested answer for the RFI.' },
                { name: 'tags' },
                { name: 'target_urn' },
                { name: 'target_urn_page' },
                { name: 'title' }
              ] },
            { name: 'pushpin_attributes', type: 'object', properties: [
              { name: 'type' },
              { name: 'location', type: 'object', properties: [
                { name: 'x', type: 'number' },
                { name: 'y', type: 'number' },
                { name: 'z', type: 'number' }
              ] },
              { name: 'resource_urns' },
              { name: 'sheet_metadata', type: 'object' },
              { name: 'starting_version',
                hint: 'The first version of the RFI.' },
              { name: 'transition_attributes', type: 'array', of: 'object',
                properties: [
                  { name: 'id' },
                  { name: 'is_specific_assignee', control_type: 'checkbox',
                    hint: 'Is the RFI can be assigned to a specific user',
                    type: 'boolean', toggle_hint: 'Select from options list',
                    toggle_field: {
                      name: 'is_specific_assignee',
                      type: 'string',
                      control_type: 'text',
                      label: 'Specific assignee',
                      hint: 'Is the RFI can be assigned to a specific user',
                      toggle_hint: 'Provide custom vlaue. ' \
                      'Allowed values are <b>true, false</b>'
                    } },
                  { name: 'status', control_type: 'select',
                    pick_list: 'rfi_transaction_status_list',
                    hint: 'The status of the RFI after the transition',
                    toggle_hint: 'Select status',
                    toggle_field: {
                      name: 'status',
                      label: 'Status',
                      type: 'string',
                      control_type: 'text',
                      toggle_hint: 'Provie custom value',
                      hint: 'Possible values: <b>draft, submitted, open, ' \
                      'rejected, answered, closed, void</b>'
                    } },
                  { name: 'title' },
                  { name: 'is_required', control_type: 'checkbox',
                    type: 'boolean', toggle_hint: 'Select from options list',
                    toggle_field: {
                      name: 'is_required',
                      type: 'string',
                      control_type: 'text',
                      label: 'Is required',
                      toggle_hint: 'Provide custom vlaue. ' \
                      'Allowed values are <b>true, false</b>'
                    } }
                ] },
              { name: 'workflow_state', type: 'object', properties: [
                { name: 'id' },
                { name: 'title' },
                { name: 'short_title' },
                { name: 'name' }
              ] },
              { name: 'is_specific_assignee' },
              { name: 'object_id' },
              { name: 'viewer_state' },
              { name: 'created_at', type: 'date_time' },
              { name: 'created_by' },
              { name: 'created_doc_version', type: 'integer' },
              { name: 'hidden_at', type: 'date_time' },
              { name: 'hidden_by' },
              { name: 'hidden_doc_version', type: 'integer' }
            ] },
            { name: 'resource_urns', hint: 'array of strings' },
            # TO UPDATE
            { name: 'resource_urns' },
            { name: 'sheet_metadata', type: 'object' },
            { name: 'starting_version' },
            { name: 'status', control_type: 'select',
              pick_list: 'rfi_transaction_status_list',
              hint: 'The status of the RFI after the transition',
              toggle_hint: 'Select status',
              toggle_field: {
                name: 'status',
                label: 'Status',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Provie custom value',
                hint: 'Possible values: <b>draft, submitted, open, ' \
                'rejected, answered, closed, void</b>'
              } },
            { name: 'suggested_answer' },
            { name: 'tags', hint: 'array of strings' },
            { name: 'target_urn' },
            { name: 'target_urn_page' },
            { name: 'title' },
            { name: 'workflow_state', type: 'object', properties: [
              { name: 'id' },
              { name: 'title' },
              { name: 'short_title' },
              { name: 'name' }
            ] },
            { name: 'current_allowed_assignees', type: 'array', of: 'object',
              properties: [
                { name: 'id' },
                { name: 'type' }
              ] },
            { name: 'distribution_list',
              hint: 'Provide comma separated list of IDs' },
            { name: 'comments_attributes', type: 'array', of: 'object',
              properties: [
                { name: 'id', label: 'Attachment ID' },
                { name: 'type' },
                { name: 'attributes', type: 'object', properties: [
                  { name: 'created_at', type: 'date_time',
                    hint: 'The timestamp of the date and time the issue was ' \
                    'created, in the following format: ' \
                    '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                    render_input: 'render_iso8601_timestamp',
                    parse_output: 'parse_iso8601_timestamp' },
                  { name: 'created_by' },
                  { name: 'synced_at', type: 'date_time',
                    hint: 'The timestamp of the date and time the issue was ' \
                    'synced, in the following format: ' \
                    '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                    render_input: 'render_iso8601_timestamp',
                    parse_output: 'parse_iso8601_timestamp' },
                  { name: 'updated_at', type: 'date_time',
                    hint: 'The timestamp of the date and time the issue was ' \
                    'updated, in the following format: ' \
                    '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                    render_input: 'render_iso8601_timestamp',
                    parse_output: 'parse_iso8601_timestamp' },
                  { name: 'rfi_id' },
                  { name: 'body' }
                ] }
              ] },
            { name: 'attachments_attributes', type: 'array', of: 'object',
              properties: [
                { name: 'id', label: 'Comment ID' },
                { name: 'type' },
                { name: 'attributes', type: 'object', properties: [
                  { name: 'created_at', type: 'date_time',
                    hint: 'The timestamp of the date and time the issue was ' \
                    'created, in the following format: ' \
                    '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                    render_input: 'render_iso8601_timestamp',
                    parse_output: 'parse_iso8601_timestamp' },
                  { name: 'created_by' },
                  { name: 'synced_at', type: 'date_time',
                    hint: 'The timestamp of the date and time the issue was ' \
                    'synced, in the following format: ' \
                    '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                    render_input: 'render_iso8601_timestamp',
                    parse_output: 'parse_iso8601_timestamp' },
                  { name: 'updated_at', type: 'date_time',
                    hint: 'The timestamp of the date and time the issue was ' \
                    'updated, in the following format: ' \
                    '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                    render_input: 'render_iso8601_timestamp',
                    parse_output: 'parse_iso8601_timestamp' },
                  { name: 'attachment_type' },
                  { name: 'deleted_at', type: 'date_time',
                    hint: 'The timestamp of the date and time the issue was ' \
                    'deleted, in the following format: ' \
                    '<b>YYYY-MM-DDThh:mm:ss.sz</b>',
                    render_input: 'render_iso8601_timestamp',
                    parse_output: 'parse_iso8601_timestamp' },
                  { name: 'deleted_by', hint: 'The ID of the user who deleted' \
                    ' the attachment. This is only relevant for deleted' \
                    ' attachments.' },
                  { name: 'rfi_id' },
                  { name: 'name' },
                  { name: 'resource_urns', type: 'array', of: 'string' },
                  { name: 'url' },
                  { name: 'urn' },
                  { name: 'urn_page' },
                  { name: 'urn_type' },
                  { name: 'urn_version' },
                  { name: 'permitted_actions' }
                ] }
              ] }
          ] }
        ]
      end
    },
    modify_rfi: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'title' },
          { name: 'description', label: 'Question' },
          { name: 'suggested_answer', label: 'Suggested Answer' },
          { name: 'answer', hint: 'An answer for the RFI.' },
          { name: 'assigned_to',
            hint: 'The Autodesk ID of the user you want to assign ' \
            'the RFI to.' },
          { name: 'location_description' },
          { name: 'due_date', type: 'date_time',
            render_input: 'render_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp',
            hint: 'The timestamp of the due date for the RFI, in the ' \
            'following format: YYYY-MM-DDThh:mm:ss.sz.' },
          { name: 'distribution_list',
            hint: 'Provide comma seaprated list of values multiple values' },
          { name: 'transition_id',
            hint: 'This field is mandatory when tranistioning the RFI.' },
          { name: 'co_reviewers',
            hint: 'Add members who can contribute to the RFI response. ' \
            'Note that although you can only add co-reviewers in the UI ' \
            'when the RFI is in open status, you can use the endpoint to' \
            ' also set up co-reviewers in other statuses.' \
            'To delete all co-reviewers, call the endpoint with an empty' \
            ' array.' },
          { name: 'reserve_custom_identifier',
            hint: 'This field allows to reserve a custom identifier for ' \
            'future use (for example, in draft or submitted status). No ' \
            'other RFI will be able to use or reserve this identifier for' \
            ' 2 minutes.' },
          { name: 'custom_identifier',
            hint: 'Identifier of the RFI given by user. When non-present in' \
            ' transitions to any status, except “draft” or “submitted”, ' \
            'will be populated automatically.' }
        ]
      end
    },
    search_criteria: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'hub_id',
            label: 'Hub name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. <b>b.baf-0871-4aca-82e8-3dd6db00<b>'
            }
          },
          {
            name: 'project_id',
            label: 'Project name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide project ID e.g. <b>b.baf-0871-4aca-82e8-3dd6db</b>'
            }
          },
          { name: 'target_urn', sticky: true },
          { name: 'due_date',
            sticky: true,
            hint: 'Retrieves issues due by the specified due date. matchValue' \
            ' is the timestamp of the due date in the following format' \
            ' : YYYY-MM-DDThh:mm:ss.sz, or a date range in the following' \
            ' format: YYYY-MM-DDThh:mm:ss.sz...YYYY-MM-DDThh:mm:ss.sz.' },
          { name: 'synced_after', type: 'date_time',
            sticky: true,
            hint: 'Retrieves issues updated after the specified date' },
          { name: 'created_at',
            sticky: true,
            hint: 'Retrieves issues created after the specified due date.' \
            ' matchValue' \
            ' is the timestamp of the due date in the following format' \
            ' : YYYY-MM-DDThh:mm:ss.sz, or a date range in the following' \
            ' format: YYYY-MM-DDThh:mm:ss.sz...YYYY-MM-DDThh:mm:ss.sz.' },
          { name: 'created_by',
            sticky: true,
            hint: 'Retrieves issues created by the user.' \
            ' matchValue is the unique identifier of the user who ' \
            'created the issue.' },
          { name: 'ng_issue_type_id',
            sticky: true,
            hint: 'Retrieves issues associated with the specified issue type' },
          { name: 'ng_issue_subtype_id',
            sticky: true,
            hint: 'Retrieves issues associated with the specified ' \
            'issue subtype.' },
          { name: 'limit', type: 'integer',
            sticky: true,
            hint: 'Number of issues to return in the response.' \
            ' Acceptable values: 1-100. Default value: 10' },
          { name: 'offset',
            sticky: true,
            hint: 'The page number that you want to begin' \
            ' issue results from.' },
          { name: 'sort',
            sticky: true,
            hint: 'Sort the issues by status, created_at,' \
            ' and updated_a. To sort in descending order add a ' \
            '<b>-</b> before the sort criteria' },
          {
            name: 'include',
            sticky: true,
            label: 'Include additional data',
            control_type: 'multiselect',
            pick_list: 'issue_child_objects',
            pick_list_params: {},
            delimiter: ',',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'include',
              label: 'Include additinal data',
              type: :string,
              control_type: 'text',
              optional: true,
              hint: 'Multiple values separated by comma.',
              toggle_hint: 'Comma separated list of values. Allowed values ' \
               'are: <b>attachments, comments, container</b>'
            }
          }
        ]
      end
    },
    rfis_criteria: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'status', control_type: 'select',
            pick_list: 'rfi_status_list',
            sticky: true,
            hint: 'Retrieves RFIs with the specified status',
            toggle_hint: 'Select status',
            toggle_field: {
              name: 'status',
              label: 'Status',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are <br>draft, open, close</b>.'
            }
          },
          {
            name: 'include_voided', control_type: 'checkbox',
            type: 'boolean',
            sticky: true,
            hint: 'Include voided RFIs in the response. true returns ' \
            'voided RFIs; false does not return voided RFIs',
            toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'include_voided',
              label: 'Include voided',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are <b>true, false</b>.' \
              ' Note that <b>status</b> overrides this filter'
            }
          },
          { name: 'target_urn', sticky: true,
            hint: 'Retrieves RFIs in the project that' \
            ' were linked to the specified document or documents, using' \
            'the documents`s URN. e.g. <b>urn:adsk.wipprod:dm.lineage:' \
            'tFbo9zuDTW-nPh45gnM4gA</b>' },
          { name: 'assigned_to', sticky: true,
            hint: 'Retrieves RFIs in the project that' \
            " were assigned to the specified user, using the user's " \
            ' Autodesk ID. e.g <b>PER8KQPK2JRT</b>' },
          { name: 'created_at', sticky: true,
            hint: 'Retrieves RFIs created at the specfied date. matchValue ' \
            'is the timestamp of the date in the following format: ' \
            'YYYY-MM-DDThh:mm:ss.sz, or a date range in the following' \
            ' format: YYYY-MM-DDThh:mm:ss.sz...YYYY-MM-DDThh:mm:ss.sz.' },
          { name: 'due_date', sticky: true,
            hint: 'Retrieves RFIs due by the specified due date. matchValue' \
            ' is the timestamp of the due date in the following format' \
            ' : YYYY-MM-DDThh:mm:ss.sz, or a date range in the following' \
            ' format: YYYY-MM-DDThh:mm:ss.sz...YYYY-MM-DDThh:mm:ss.sz.' },
          { name: 'search', sticky: true,
            hint: 'Free search in RFIs of the current container. The search' \
            ' is been performed in identifier, title, description and ' \
            'answer fields.' },
          { name: 'sort', sticky: true,
            hint: 'Sort the issues by <b>status, due_date,' \
            ' and title, target_urn, location_description, identifier,' \
            ' created_at, updated_at</b>. To sort in descending order add a ' \
            '<b>-</b> before the sort criteria. Separate multiple values' \
            ' with commas' },
          { name: 'limit', type: 'integer', sticky: true,
            hint: 'The number of RFIs to return in the response payload.' \
            ' Acceptable values: 1-100. Default value: 10' },
          { name: 'offset', sticky: true,
            hint: 'the page number that you want to begin RFI results from.' },
          {
            name: 'include', sticky: true,
            label: 'Include additional data',
            control_type: 'multiselect',
            pick_list: 'rfi_child_objects',
            pick_list_params: {},
            delimiter: ',',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'include',
              label: 'Include additinal data',
              type: :string,
              control_type: 'text',
              optional: true,
              hint: 'Multiple values separated by comma.',
              toggle_hint: 'Comma separated list of values. Allowed values ' \
               'are: <b>attachments, comments,activity_batches, container'
            }
          }
        ]
      end
    },
    hub_container_ids: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'hub_id',
            label: 'Hub name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'container_id',
            label: 'Project name',
            control_type: 'select',
            pick_list: 'issue_container_lists',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select container',
            toggle_field: {
              name: 'container_id',
              label: 'Container ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide container id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          { name: 'folder_id',
            label: 'Folder',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select Folder',
            tree_options: { selectable_folder: true },
            pick_list: :folders,
            optional: false,
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              control_type: 'text',
              label: 'Folder ID',
              toggle_hint: 'Use Folder ID',
              hint: 'Use Folder ID'
            } }
        ]
      end
    },
    folder_file: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id', label: 'Item ID' },
          { name: 'type', label: 'Item Type' },
          { name: 'attributes', type: 'object', properties: [
            # { name: 'type' },
            # { name: 'name' },
            { name: 'displayName', label: 'Name' },
            { name: 'createTime', label: 'Created at', type: 'date_time' },
            { name: 'createUserId', label: 'Created by (User ID)' },
            { name: 'createUserName', label: 'Created by (User Name)' },
            { name: 'lastModifiedTime',
              label: 'Last modified at', type: 'date_time' },
            { name: 'lastModifiedUserId', label: 'Last modified by (User ID)' },
            { name: 'lastModifiedUserName',
              label: 'Last modified by (User Name)' },
            # { name: 'lastModifiedTimeRollup', type: 'date_time' },
            # { name: 'objectCount', type: 'integer' },
            { name: 'hidden', type: 'boolean', control_type: 'checkbox' },
            { name: 'reserved', type: 'boolean', control_type: 'checkbox' },
            { name: 'extension', type: 'object', properties: [
              # { name: 'type' },
              { name: 'version' } # ,
              # { name: 'data', type: 'object', properties: [
              #   { name: 'sourceFileName', hint: 'Applicable for file' },
              #   { name: 'visibleTypes', hint: 'Array of strings' },
              #   { name: 'actions', hint: 'Array of strings' },
              #   { name: 'allowedTypes', hint: 'Array of strings' }
              # ] }
            ] }
          ] }
        ]
      end
    },
    item: {
      fields: lambda do |_connection, _config_fields|
        [
          # { name: 'included', type: 'array', of: 'object',
          #  properties: [
          #    { name: 'type' },
          #    { name: 'id' },
          #    { name: 'relationships', type: 'object', properties: [
          #      { name: 'item', type: 'object', properties: [
          #        { name: 'data', type: 'object', properties: [
          #          { name: 'type' },
          #          { name: 'id' }
          #        ] },
          #        { name: 'links', type: 'object', properties: [
          #          { name: 'related', type: 'object', properties: [
          #            { name: 'href' }
          #          ] }
          #        ] }
          #      ] },
          #      { name: 'refs', type: 'object', properties: [
          #        { name: 'links', type: 'object', properties: [
          #          { name: 'self', type: 'object', properties: [
          #            { name: 'href' }
          #          ] },
          #          { name: 'related', type: 'object', properties: [
          #            { name: 'href' }
          #          ] }
          #        ] }
          #      ] },
          #      { name: 'storage', type: 'object', properties: [
          #        { name: 'meta', type: 'object', properties: [
          #          { name: 'link', type: 'object', properties: [
          #            { name: 'href' }
          #          ] }
          #        ] },
          #        { name: 'data', type: 'object', properties: [
          #          { name: 'type' },
          #          { name: 'id' }
          #        ] }
          #      ] },
          #      { name: 'links', type: 'object', properties: [
          #        { name: 'self', type: 'object', properties: [
          #          { name: 'href' }
          #        ] }
          #      ] }
          #    ] }
          #  ] },
          { name: 'data', type: 'object', properties: [
            { name: 'id', label: 'Item ID' },
            # { name: 'type' },
            # { name: 'relationships', type: 'object', properties: [
            #   { name: 'refs', type: 'object', properties: [
            #     { name: 'links', type: 'object', properties: [
            #       { name: 'self', type: 'object', properties: [
            #         { name: 'href' }
            #       ] },
            #       { name: 'related', type: 'object', properties: [
            #         { name: 'href' }
            #       ] }
            #     ] }
            #   ] },
            #   { name: 'tip', type: 'object', properties: [
            #     { name: 'data', type: 'object', properties: [
            #       { name: 'type' },
            #       { name: 'id' }
            #     ] },
            #     { name: 'links', type: 'object', properties: [
            #       { name: 'related', type: 'object', properties: [
            #         { name: 'href' }
            #       ] }
            #     ] }
            #   ] },
            #   { name: 'links', type: 'object', properties: [
            #     { name: 'self', type: 'object', properties: [
            #       { name: 'href' }
            #     ] }
            #   ] },
            #   { name: 'parent', type: 'object', properties: [
            #     { name: 'data', properties: [
            #       { name: 'type' },
            #       { name: 'id' }
            #     ] },
            #     { name: 'links', type: 'object', properties: [
            #       { name: 'related', type: 'object', properties: [
            #         { name: 'href' }
            #       ] }
            #     ] }
            #   ] },
            #   { name: 'versions', type: 'object', properties: [
            #     { name: 'links', type: 'object', properties: [
            #       { name: 'related', type: 'object', properties: [
            #         { name: 'href' }
            #       ] }
            #     ] }
            #   ] }
            # ] },

            { name: 'attributes', type: 'object', properties: [
              # { name: 'type' },
              # { name: 'name' },
              { name: 'displayName', label: 'Name' },
              { name: 'createTime', label: 'Created at', type: 'date_time' },
              { name: 'createUserId', label: 'Created by (User ID)' },
              { name: 'createUserName', label: 'Created by (User Name)' },
              { name: 'lastModifiedTime',
                label: 'Last modified at', type: 'date_time' },
              { name: 'lastModifiedUserId',
                label: 'Last modified by (User ID)' },
              { name: 'lastModifiedUserName',
                label: 'Last modified by (User Name)' },
              # { name: 'lastModifiedTimeRollup', type: 'date_time' },
              # { name: 'objectCount', type: 'integer' },
              { name: 'hidden', type: 'boolean', control_type: 'checkbox' },
              { name: 'reserved', type: 'boolean', control_type: 'checkbox' },
              # { name: 'pathInProject', label: 'Path' },
              { name: 'extension', type: 'object', properties: [
                # { name: 'type' },
                { name: 'version' } # ,
                # { name: 'data', type: 'object', properties: [
                #   { name: 'sourceFileName', hint: 'Applicable for file' },
                #   { name: 'visibleTypes', hint: 'Array of strings' },
                #   { name: 'actions', hint: 'Array of strings' },
                #   { name: 'allowedTypes', hint: 'Array of strings' }
                # ] }
              ] }
            ] }
          ] }

        ]
      end
    },
    version: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'type' },
          { name: 'id' },
          { name: 'attributes', type: 'object', properties: [
            { name: 'name' },
            { name: 'displayName' },
            { name: 'createTime', type: 'date_time' },
            { name: 'createUserId' },
            { name: 'createUserName' },
            { name: 'lastModifiedTime' },
            { name: 'lastModifiedUserId' },
            { name: 'lastModifiedUserName' },
            { name: 'versionNumber', type: 'integer' },
            { name: 'storageSize' },
            { name: 'fileType' },
            { name: 'extension', type: 'object', properties: [
              { name: 'type' },
              { name: 'version' },
              { name: 'data', type: 'object', properties: [
                { name: 'processState' },
                { name: 'extractionState' },
                { name: 'splittingState' },
                { name: 'reviewState' },
                { name: 'revisionDisplayLabel' },
                { name: 'sourceFileName' }
              ] }
            ] }
          ] }
        ]
      end
    },
    export_status: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id', label: 'Export job ID' },
          { name: 'status' },
          { name: 'data', type: 'object', properties: [
            { name: 'versionUrn', label: 'Version URN' },
            { name: 'resourceId' },
            { name: 'link' }
          ] }
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
            hint: 'Base URI is https://developer.api.autodesk.com - ' \
            'path will be appended to this URI. ' \
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
                        properties: input_schema.
                        each { |field| field[:sticky] = true }
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
        "in <span class='provider'>BIM 360</span>",
      help: {
        body: 'Build your own BIM 360 action with an HTTP request',
        learn_more_url: 'https://forge.autodesk.com/en/docs/bim360/v1/reference/http/',
        learn_more_text: 'BIM 360 API Documentation'
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
        if %w[get post patch delete].exclude?(verb)
          error("#{verb} not supported")
        end
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
    search_issues_in_project: {
      title: 'Search issues in a project',
      description: 'Search <span class="provider">issues</span> in'\
        ' a project in <span class="provider">BIM 360</span>',
      help: {
        body: 'Retrieves information about all the BIM 360 issues in a ' \
        'project, including details about their associated comments ' \
        'and attachments.'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['search_criteria']
      end,
      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        project_id = input.delete('project_id')
        filter_criteria = call('format_search', input)
        container_id = get("/project/v1/hubs/#{hub_id}" \
                           "/projects/#{project_id}")&.
                       dig('data', 'relationships', 'issues', 'data', 'id')
        { issues: get("/issues/v1/containers/#{container_id}/quality-issues",
                      filter_criteria)['data'] }&.
                  merge({ hub_id: hub_id, container_id: container_id,
                          project_id: project_id })
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' },
          { name: 'container_id' },
          { name: 'issues', type: 'array', of: 'object',
            properties: object_definitions['issue'] }
        ]
      end,
      sample_output: lambda do |_connection, input|
        project_id = input['project_id']
        container_id = get("/project/v1/#{input['hub_id']}" \
                           "/projects/#{project_id}")&.
                       dig('data', 'relationships', 'issues', 'data', 'id')
        { issues: get("/issues/v1/containers/#{container_id}/" \
                      'quality-issues?page[limit]=1')&.dig('data', 0) || {} }
      end

    },
    create_issue_in_project: {
      title: 'Create issue in a project',
      description: 'Create <span class="provider">issue</span> in'\
        ' a project in <span class="provider">BIM 360</span>',
      help: {
        body: 'Adds a BIM 360 issue to a project. You can create both ' \
        'document-related (pushpin) issues, and project-related issues.'
      },
      input_fields: lambda do |object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub Name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'container_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'issue_container_lists',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'container_id',
              label: 'Container ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide container id e.g. ' \
              'edac0659-639a-4a87-8614-d2c521b246b0'
            }
          }
        ].concat(object_definitions['create_issue'].
          required('title', 'ng_issue_type_id', 'ng_issue_subtype_id'))
      end,
      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        container_id = input.delete('container_id')
        payload = {
          type: 'quality_issues',
          attributes: input
        }
        post("/issues/v1/containers/#{container_id}/quality-issues").
          payload({ data: payload }).
          headers('Content-Type': 'application/vnd.api+json').
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end['data']&.merge({ container_id: container_id, hub_id: hub_id })
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ].concat(object_definitions['issue'])
      end,
      sample_output: lambda do |_connection, input|
        project_id = input['project_id']
        container_id = get("/project/v1/#{input['hub_id']}" \
                           "/projects/#{project_id}")&.
                       dig('data', 'relationships', 'issues', 'data', 'id')
        get("/issues/v1/containers/#{container_id}/" \
            'quality-issues?page[limit]=1')&.dig('data', 0) || {}
      end
    },
    update_issue_in_project: {
      title: 'Updated issue in a project',
      description: 'Update <span class="provider">issue</span> in'\
        ' a project in <span class="provider">BIM 360</span>',
      help: {
        body: 'BIM 360 issues are managed either in the BIM 360 Document' \
        ' Management module or the BIM 360 Field Management module.</br>' \
        'The following users can update issues:</br>' \
        '<ul>Project admins</ul>' \
        '</ul>Project members who are assigned either create, view and ' \
        'create, or full control Field Management permissions.</ul>'
      },
      input_fields: lambda do |object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'container_id',
            label: 'Container name',
            control_type: 'select',
            pick_list: 'issue_container_lists',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select container',
            toggle_field: {
              name: 'container_id',
              label: 'Container ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide container id e.g. baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'id', label: 'Issue ID',
            optional: false
          }
        ].concat(object_definitions['update_issue'].ignored('id'))
      end,
      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        container_id = input.delete('container_id')
        id = input.delete('id')
        payload = {
          id: id,
          type: 'quality_issues',
          attributes: input
        }
        patch("/issues/v1/containers/#{container_id}/" \
              "quality-issues/#{id}").
          payload({ data: payload }).
          headers('Content-Type': 'application/vnd.api+json').
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end['data']&.merge({ hub_id: hub_id, container_id: container_id })
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ].concat(object_definitions['issue'])
      end,
      sample_output: lambda do |_connection, input|
        project_id = input['project_id']
        container_id = get("/project/v1/#{input['hub_id']}" \
                           "/projects/#{project_id}")&.
                       dig('data', 'relationships', 'issues', 'data', 'id')
        get("/issues/v1/containers/#{container_id}/" \
            'quality-issues?page[limit]=1')&.dig('data', 0) || {}
      end
    },
    get_issue_in_project: {
      description: 'Get <span class="provider">issue</span> in a project in'\
        ' <span class="provider">BIM 360</span>',
      help: {
        body: 'Retrieves detailed information about a single BIM 360 issue. ' \
        'Get issue action uses the' \
        " <a href='https://forge.autodesk.com/en/docs/bim360/v1/reference/" \
        "http/field-issues-:id-GET/' target='_blank'>Get issue" \
        '</a> API.'
      },
      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'container_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'issue_container_lists',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'container_id',
              label: 'Container ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide container id e.g. ' \
              'edac0659-639a-4a87-8614-d2c521b246b0'
            }
          },
          { name: 'issue_id', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/issues/v1/containers/#{input['container_id']}/" \
            "quality-issues/#{input['issue_id']}").
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end['data'].
          merge({ hub_id: input['hub_id'],
                  container_id: input['container_id'] })
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ].concat(object_definitions['issue'])
      end,
      sample_output: lambda do |_connection, input|
        project_id = input['project_id']
        container_id = get("/project/v1/#{input['hub_id']}" \
                           "/projects/#{project_id}")&.
                       dig('data', 'relationships', 'issues', 'data', 'id')
        get("/issues/v1/containers/#{container_id}/" \
            'quality-issues?page[limit]=1')&.dig('data', 0) || {}
      end
    },
    get_project_details: {
      description: 'Get <span class="provider">project</span> details in'\
        ' <span class="provider">BIM 360</span>',
      help: {
        body: 'Returns a project for a given project_id. Note that for ' \
        'BIM 360 Docs, a hub ID corresponds to an account ID in the BIM ' \
        '360 API. To convert an account ID into a hub ID you need to add' \
        ' a “b.” prefix. For example, an account ID of c8b0c73d-3ae9 ' \
        'translates to a hub ID of b.c8b0c73d-3ae9.'
      },
      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub Name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'project_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint:
              'Provide project id e.g. <b>b.baf-0871-4aca-82e8-3dd6db00</b>'
            }
          }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/project/v1/hubs/#{input['hub_id']}/projects/" \
          "#{input['project_id']}").
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end['data']
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['project']
      end,
      sample_output: lambda do |_connection, _input|
        id = get('/project/v1/hubs')&.dig('data', 0)&.[]('id')
        get("/project/v1/hubs/#{id}/projects")&.dig('data', 0) || {}
      end
    },
    search_rfis_in_project: {
      title: 'Search RFIs in project',
      description: 'Search <span class="provider">RFIs</span> in a project in'\
        ' <span class="provider">BIM 360</span>',
      help: {
        body: 'Retrieves information about all the BIM 360 RFIs (requests ' \
        'for information) in a project, including details about their ' \
        'associated comments and attachments.'
      },
      input_fields: lambda do |object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'container_id',
            label: 'Container name',
            control_type: 'select',
            pick_list: 'rfis_container_lists',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select container',
            toggle_field: {
              name: 'container_id',
              label: 'Container ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide container id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          }
        ].concat(object_definitions['rfis_criteria'])
      end,
      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        container_id = input.delete('container_id')
        filter_criteria = call('format_search', input)
        { rfis: get("/bim360/rfis/v1/containers/#{container_id}/rfis",
                    filter_criteria)['data'] }&.
                merge({ hub_id: hub_id, container_id: container_id })
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' },
          { name: 'rfis', label: 'RFIs', type: 'array', of: 'object',
            properties: object_definitions['rfi'] }
        ]
      end,
      sample_output: lambda do |_connection, input|
        { rfis:
          get("/bim360/rfis/v1/containers/#{input['container_id']}/rfis")&.
          dig('data', 0) || {} }
      end
    },
    get_rfi_in_project: {
      title: 'Get RFI in a project',
      description: 'Get <span class="provider">RFI</span> in'\
        ' a project in <span class="provider">BIM 360</span>',
      help: {
        body: 'Retrieves detailed information about a single BIM 360 RFI' \
        ' (request for information).'
      },
      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub Name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'container_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'rfis_container_lists',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'container_id',
              label: 'Container ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide container ID e.g. ' \
              'edac0659-639a-4a87-8614-d2c521b246b0'
            }
          },
          { name: 'id', optional: false, label: 'RFI ID' }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/bim360/rfis/v1/containers/#{input['container_id']}/rfis/" \
            "#{input['id']}").
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end['data']&.
          merge({ hub_id: input['hub_id'],
                  container_id: input['container_id'] })
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'hub_id' }, { name: 'container_id' }].
          concat(object_definitions['rfi'])
      end,
      sample_output: lambda do |_connection, input|
        get("/bim360/rfis/v1/containers/#{input['container_id']}/rfis")&.
          dig('data', 0) || {}
      end
    },
    create_rfi_in_project: {
      title: 'Create RFI in a project',
      description: 'Create <span class="provider">RFI</span> in'\
        ' a project in <span class="provider">BIM 360</span>',
      help: {
        body: 'Adds a BIM 360 RFI (request for information) to a project. ' \
        'Users can create RFIs if they have been assigned either creator ' \
        '(sc) or manager (gc) workflow roles. Project admins are ' \
        'automatically assigned the creator workflow role.'
      },
      input_fields: lambda do |object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub Name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'container_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'rfis_container_lists',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'container_id',
              label: 'Container ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide container ID e.g. ' \
              'edac0659-639a-4a87-8614-d2c521b246b0'
            }
          }
        ].concat(object_definitions['modify_rfi'].
          ignored('transition_id', 'assigned_to', 'answer'))
      end,
      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        container_id = input.delete('container_id')
        input_payload = input&.map do |key, value|
          if %w[distribution_list co_reviewers].include?(key)
            { key => value.split(',') }
          else
            { key => value }
          end
        end&.inject(:merge)
        payload = {
          type: 'rfis',
          attributes: input_payload
        }
        post("/bim360/rfis/v1/containers/#{container_id}/rfis").
          payload({ data: payload }).
          headers('Content-Type': 'application/vnd.api+json').
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end['data']&.merge({ hub_id: hub_id, container_id: container_id })
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'hub_id' }, { name: 'container_id' }]&.
          concat(object_definitions['rfi'])
      end,
      sample_output: lambda do |_connection, input|
        get("/bim360/rfis/v1/containers/#{input['container_id']}/rfis")&.
          dig('data', 0) || {}
      end
    },
    update_rfi_in_project: {
      title: 'Updated RFI in a project',
      description: 'Update <span class="provider">RFI</span> in a project in'\
        ' <span class="provider">BIM 360</span>',
      help: {
        body: 'Updates a BIM 360 Project Management RFI. If the RFI is in ' \
        'Draft status, it can only be updated by the user who created the ' \
        'RFI. For all other statuses, it can only be updated by the user who' \
        ' was assigned to the RFI.'
      },
      input_fields: lambda do |object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub Name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'container_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'rfis_container_lists',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'container_id',
              label: 'Container ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide container ID e.g. ' \
              'edac0659-639a-4a87-8614-d2c521b246b0'
            }
          },
          { name: 'id', optional: false, label: 'RFI ID' }
        ].concat(object_definitions['modify_rfi'].
          ignored('suggested_answer'))
      end,
      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        container_id = input.delete('container_id')
        id = input.delete('id')
        input_payload = input&.map do |key, value|
          if %w[distribution_list co_reviewers].include?(key)
            { key => value.split(',') }
          else
            { key => value }
          end
        end&.inject(:merge)
        payload = {
          id: id,
          type: 'rfis',
          attributes: input_payload
        }
        patch("/bim360/rfis/v1/containers/#{container_id}/rfis/#{id}").
          payload({ data: payload }).
          headers('Content-Type': 'application/vnd.api+json').
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end['data'].merge({ hub_id: hub_id, container_id: container_id })
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'hub_id' }, { name: 'container_id' }]&.
          concat(object_definitions['rfi'])
      end,
      sample_output: lambda do |_connection, input|
        get("/bim360/rfis/v1/containers/#{input['container_id']}/rfis")&.
          dig('data', 0) || {}
      end
    },
    export_project_plan: {
      title: 'Export drawing in a project',
      description: 'Export <span class="provider">drawing</span> in'\
        ' a project in <span class="provider">BIM 360</span>',
      help: {
        body: 'Note that you can only export a page from a PDF file that ' \
        'was uploaded to the Plans folder or to a folder nested under the ' \
        'Plans folder. BIM 360 Document Management splits these files into ' \
        'separate pages (sheets) when they are uploaded, and assigns a ' \
        'separate ID to each page.'
      },
      config_fields:
        [
          {
            name: 'hub_id',
            label: 'Hub Name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'project_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint:
              'Provide project id e.g. <b>b.baf-0871-4aca-82e8-3dd6db00</b>'
            }
          },
          { name: 'folder_id',
            label: 'Folder Name',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select Folder',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            tree_options: { selectable_folder: true },
            pick_list: :folders_list,
            optional: false,
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              control_type: 'text',
              label: 'Folder ID',
              toggle_hint: 'Use Folder ID',
              hint: 'Use Folder ID'
            } },
          {
            name: 'item_id',
            label: 'File name',
            control_type: 'select',
            pick_list: 'folder_items',
            pick_list_params: { project_id: 'project_id',
                                folder_id: 'folder_id' },
            optional: false,
            toggle_hint: 'Select file',
            toggle_field: {
              name: 'item_id',
              type: 'string',
              control_type: 'text',
              label: 'File ID',
              toggle_hint: 'Use file ID',
              hint: 'Use file/item ID'
            }
          },
          {
            name: 'version_number',
            control_type: 'select',
            pick_list: 'item_versions',
            sticky: true,
            pick_list_params: { project_id: 'project_id', item_id: 'item_id' },
            optional: true,
            toggle_hint: 'Select version',
            toggle_field: {
              name: 'version_number',
              label: 'Version number',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Use version number'
            }
          },
          {
            name: 'includeMarkups', control_type: 'checkbox',
            type: 'boolean', label: 'Include Markups',
            sticky: true,
            hint: 'Include markups in the export',
            toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'includeMarkups',
              label: 'Include Markups',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are <b>true, false</b>.'
            }
          },
          {
            name: 'includeHyperlinks', control_type: 'checkbox',
            type: 'boolean', label: 'Include Hyperlinks',
            sticky: true,
            hint: 'Include hyperlinks in the export',
            toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'includeHyperlinks',
              label: 'Include Hyperlinks',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are <b>true, false</b>.'
            }
          }
        ],
      execute: lambda do |_connection, input|
        #  Step 1 find the version id of the file to export
        hub_id = input.delete('hub_id')
        input.delete('folder_id')
        version_number = input['version_number'] || get('/data/v1/projects/' \
          "#{input['project_id']}/items/#{input['item_id']}/" \
            'versions')&.dig('data', 0, 'id')
        version_url = version_number.encode_url
        # Step 2 upload the file
        project_id = input.delete('project_id').gsub('b.', '')
          item_id = input.delete('item_id')
        # create payload with `true`/`false` booleans
        input_payload = {}
        input&.map do |key, value|
            if value.to_s.downcase === 'true'
              input_payload[key] = true
            else
              input_payload[key] = false
            end
          end
        post("/bim360/docs/v1/projects/#{project_id}/versions" \
          "/#{version_url}/exports").
          payload(input_payload).
          headers('content-type': 'application/json').
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.merge({ hub_id: hub_id }).merge({ project_id: 'b.' + project_id }).merge({ item_id: item_id })
      end,
      output_fields: lambda do |_object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' },
          { name: 'item_id' },
          { name: 'id', label: 'Export ID' },
          { name: 'status' }
        ]
      end,
      sample_output: lambda do |_connection, _input|
        {
          "id": '345eb2fb-d5b0-44c9-a50a-2c792d833f3f',
          "status": 'committed'
        }
      end
    },
    get_folder_details: {
      title: 'Get folder info in a project',
      description: 'Get <span class="provider">folder info</span> in'\
        ' a project in <span class="provider">BIM 360</span>',
      help: {
        body: 'Returns the folder by ID for any folder within a given ' \
        'project. All folders or sub-folders within a project are associated' \
        ' with their own unique ID, including the root folder.'
      },
      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub Name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'project_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint:
              'Provide project id e.g. <b>b.baf-0871-4aca-82e8-3dd6db00</b>'
            }
          },
          { name: 'folder_id',
            label: 'Folder',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select Folder',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            tree_options: { selectable_folder: true },
            pick_list: :folders_list,
            optional: false,
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              control_type: 'text',
              label: 'Folder ID',
              toggle_hint: 'Use Folder ID',
              hint: 'Use Folder ID'
            } }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/data/v1/projects/#{input['project_id']}/folders" \
            "/#{input['folder_id']}")['data']&.
          merge({ hub_id: input['hub_id'], project_id: input['project_id'],
                  folder_id: input['folder_id'] })
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' },
          { name: 'folder_id' }
        ].concat(object_definitions['folder_file'])
      end,
      sample_output: lambda do |_connection, input|
        get("project/v1/hubs/#{input['hub_id']}/projects/" \
            "#{input['project_id']}/topFolders?filter[type]=folders")&.
          dig('data', 0) || {}
      end
    },
    get_folder_contents: {
      description: 'Get <span class="provider">folder</span> contents in'\
        ' <span class="provider">BIM 360</span>',
      help: {
        body: 'Returns a collection of items and folders within a folder.' \
        ' Items represent word documents, fusion design files, drawings,' \
        ' spreadsheets, etc.'
      },
      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub Name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'project_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint:
              'Provide project id e.g. <b>b.baf-0871-4aca-82e8-3dd6db00</b>'
            }
          },
          { name: 'folder_id',
            label: 'Folder',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select Folder',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            tree_options: { selectable_folder: true },
            pick_list: :folders_list,
            optional: false,
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              control_type: 'text',
              label: 'Folder ID',
              toggle_hint: 'Use Folder ID',
              hint: 'Use Folder ID'
            } },
          { name: 'filters',
            label: 'Filters',
            control_type: 'text',
            sticky: true,
            hint: 'Enter filters for the search. A list of filters can be' \
            ' found at https://forge.autodesk.com/en/docs/data/v2/' \
            'developers_guide/filtering.' }
        ]
      end,
      execute: lambda do |_connection, input|
        get("/data/v1/projects/#{input['project_id']}/folders" \
            "/#{input['folder_id']}/contents?#{input['filters']}")&.
          merge({ hub_id: input['hub_id'], project_id: input['project_id'],
                  folder_id: input['folder_id'] })
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' },
          { name: 'folder_id' },
          { name: 'data', type: 'array', of: 'object',
            properties: object_definitions['folder_file'] }
        ]
      end,
      sample_output: lambda do |_connection, input|
        folder_id = get("project/v1/hubs/#{input['hub_id']}/projects/" \
                        "#{input['project_id']}/" \
                        'topFolders?filter[type]=folders')&.
                    dig('data', 0, 'id')
        get("/data/v1/projects/#{input['project_id']}/folders" \
            "/#{folder_id}/contents")
      end
    },
    get_document_in_project: {
      title: 'Get document in a project',
      description: 'Get <span class="provider">document</span> in'\
        ' a project in <span class="provider">BIM 360</span>',
      help: {
        body: 'Retrieves metadata for a specified item. Items represent ' \
        'word documents, fusion design files, drawings, spreadsheets, etc.'
      },
      config_fields:
        [
          {
            name: 'hub_id',
            label: 'Hub Name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'project_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint:
              'Provide project id e.g. <b>b.baf-0871-4aca-82e8-3dd6db00</b>'
            }
          },
          { name: 'folder_id',
            label: 'Folder',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select Folder',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            tree_options: { selectable_folder: true },
            pick_list: :folders_list,
            optional: true,
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              control_type: 'text',
              label: 'Folder ID',
              toggle_hint: 'Use Folder ID',
              hint: 'Use Folder ID'
            } },
          { name: 'item_id',
            label: 'File name',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select Item',
            pick_list: :folder_items,
            pick_list_params: { project_id: 'project_id',
                                folder_id: 'folder_id' },
            optional: false,
            toggle_field: {
              name: 'item_id',
              type: 'string',
              control_type: 'text',
              label: 'File ID',
              toggle_hint: 'Use file ID',
              hint: 'Provide file ID'
            } }
        ],
      execute: lambda do |_connection, input|
        get("/data/v1/projects/#{input['project_id']}/items/" \
            "#{input['item_id']}")&.
          merge({ project_id: input['project_id'], hub_id: input['hub_id'] })
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' }
        ].concat(object_definitions['item'])
      end,
      sample_output: lambda do |_connection, input|
        get("/data/v1/projects/#{input['project_id']}/items/" \
            "#{input['item_id']}")
      end
    },
    get_drawing_export_status: {
      title: 'Get drawaing export status in a project',
      description: 'Get <span class="provider">drwaing export status</span> in'\
        ' a project in <span class="provider">BIM 360</span>',
      help: {
        body: 'This action returns the status of a PDF export job, as well' \
        '  as data you need to download the exported file when the export is ' \
        'complete.'
      },
      config_fields:
        [
          {
            name: 'hub_id',
            label: 'Hub Name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'project_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint:
              'Provide project id e.g. <b>b.baf-0871-4aca-82e8-3dd6db00</b>'
            }
          },
          {
            name: 'item_id',
            label: 'File Name',
            control_type: 'select',
            pick_list: 'folder_items',
            pick_list_params: { project_id: 'project_id',
                                folder_id: 'folder_id' },
            optional: false,
            toggle_hint: 'Select file',
            toggle_field: {
              name: 'item_id',
              type: 'string',
              control_type: 'text',
              label: 'File ID',
              toggle_hint: 'Use file ID',
              hint: 'Use File/Item ID'
            }
          }
        ],
      input_fields: lambda do |_object_definitions|
        [
          { name: 'export_id', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        version_number = input['version_urn'] || get('/data/v1/projects/' \
          "#{input['project_id']}/items/#{input['item_id']}/" \
            'versions')&.dig('data', 0, 'id')
        version_url = version_number.split('?').first.encode_url
        # version_url = version_number.encode_url
        project_id = input['project_id'].split('.').last
        get("/bim360/docs/v1/projects/#{project_id}/versions/" \
          "#{version_url}/exports/#{input['export_id']}").
          merge({ hub_id: input['hub_id'] }).
          merge({ project_id: input['project_id'] }).
          merge({ item_id: input['item_id'] })
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' },
          { name: 'item_id' }
        ].concat(object_definitions['export_status'])
      end,
      sample_output: lambda do |_connection, _input|
        call('sample_data_export_job')
      end
    },
    download_document: {
      description: 'Download <span class="provider">document</span> in'\
        ' a project in <span class="provider">BIM 360</span>',
      config_fields:
        [
          {
            name: 'hub_id',
            label: 'Hub name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'project_id',
            label: 'Project name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint:
              'Provide project id e.g. <b>b.baf-0871-4aca-82e8-3dd6db00</b>'
            }
          },
          { name: 'folder_id',
            label: 'Folder',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select Folder',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            tree_options: { selectable_folder: true },
            pick_list: :folders_list,
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              control_type: 'text',
              label: 'Folder ID',
              toggle_hint: 'Use Folder ID',
              hint: 'Use Folder ID'
            } },
          { name: 'item_id',
            label: 'File name',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select Folder',
            pick_list: :folder_items,
            pick_list_params: { project_id: 'project_id',
                                folder_id: 'folder_id' },
            optional: false,
            toggle_field: {
              name: 'item_id',
              type: 'string',
              control_type: 'text',
              label: 'File ID',
              toggle_hint: 'Use file ID',
              hint: 'Provide file ID'
            } }
        ],
      execute: lambda do |_connection, input|
        # 1 find the storage location of the item
        file_url = get("/data/v1/projects/#{input['project_id']}/items/" \
                       "#{input['item_id']}")&.
                   dig('included', 0, 'relationships', 'storage', 'meta',
                       'link', 'href')
        if file_url.present?
          file_content =
            get(file_url).headers('Accept-Encoding': 'Accept-Encoding:gzip').
            response_format_raw.
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        else
          error('Invalid URL')
        end
        { content: file_content }
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'content' }]
      end
    },
    upload_document_to_project: {
      title: 'Upload document to a project',
      description: 'Upload <span class="provider">document</span> to a project'\
        ' in <span class="provider">BIM 360</span>',
      help: {
        body: 'Note that you cannot upload documents to the root folder in ' \
        'BIM 360 Docs; you can only upload documents to the Project Files ' \
        'folder or to a folder nested under the Project Files folder'
      },
      config_fields: [
        {
          name: 'hub_id',
          label: 'Hub Name',
          control_type: 'select',
          pick_list: 'hub_list',
          optional: false,
          toggle_hint: 'Select hub',
          toggle_field: {
            name: 'hub_id',
            label: 'Hub ID',
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
          }
        },
        {
          name: 'project_id',
          label: 'Project Name',
          control_type: 'select',
          pick_list: 'project_list',
          pick_list_params: { hub_id: 'hub_id' },
          optional: false,
          toggle_hint: 'Select project',
          toggle_field: {
            name: 'project_id',
            label: 'Project ID',
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint:
            'Provide project id e.g. <b>b.baf-0871-4aca-82e8-3dd6db00</b>'
          }
        },
        { name: 'folder_id',
          label: 'Folder',
          control_type: 'tree',
          hint: 'Select folder',
          toggle_hint: 'Select Folder',
          pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
          tree_options: { selectable_folder: true },
          pick_list: :folders_list,
          optional: false,
          toggle_field: {
            name: 'folder_id',
            type: 'string',
            control_type: 'text',
            label: 'Folder ID',
            toggle_hint: 'Use Folder ID',
            hint: 'Use Folder ID'
          } }
      ],
      input_fields: lambda do |_object_definitions|
        [
          { name: 'file_name', optional: false, label: 'File Name',
            hint: 'File name should include extension of the file. e.g. ' \
            '<b>my_file.jpg</b>. The name of the file (1-255 characters). ' \
            'Reserved characters: <, >, :, ", /, \, |, ?, *, `, \n, \r, \t,' \
            ' \0, \f, ¢, ™, $, ®' },
          { name: 'file_content', optional: false },
          { name: 'file_extension', control_type: 'select',
            pick_list: 'file_types',
            toggle_hint: 'Select file extension',
            toggle_field: {
              name: 'file_extension',
              type: 'string',
              control_type: 'text',
              label: 'File extension',
              toggle_hint: 'Use custom value',
              hint: 'Only relevant for creating files - the type of file ' \
              'extension. <br/>. For BIM 360 Docs files, use ' \
              'items:autodesk.bim360:File.<br/>' \
              'For all other services, use items:autodesk.core:File.'
            } },
          # { name: 'resource_type', label: 'Type of the resource',
          #   control_type: 'select', pick_list: 'resource_types',
          #   toggle_hint: 'Select resource type',
          #   toggle_field: {
          #     name: 'resource_type',
          #     label: 'Resource type',
          #     type: 'string',
          #     control_type: 'text',
          #     toggle_hint: 'Use custom value',
          #     hint: 'The type of the resource. Possible values: attachment,' \
          #     ' overlay'
          #   } },
          # { name: 'file_extension_version',
          #   hint: 'The version of the file extension type. The current ' \
          #   'version is 1.0.' },
          { name: 'version_type', label: 'Type of version',
            hint: 'Only relevant for creating files - the type of version.',
            control_type: 'select',
            pick_list: 'version_types',
            toggle_hint: 'Select version type',
            toggle_field: {
              name: 'version_type',
              label: 'Type of version',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Only relevant for creating files - the type of version.' \
              '<br/>For BIM 360 Docs files, use versions:autodesk.bim360:File' \
              '<br/>For A360 composite design files, use versions:autodesk.' \
              'a360:CompositeDesign<br/>' \
              'For A360 Personal, Fusion Team, or BIM 360 Team files, use' \
              ' versions:autodesk.core:File.'
            } },
          { name: 'extension_type_version',
            hint: 'The version of the version extension type. The current ' \
            'version is 1.0 ' }

        ]
      end,
      execute: lambda do |_connection, input|
        # 1 create storage location
        payload = {
          'jsonapi' => { 'version': '1.0' },
          'data' => {
            'type' => 'objects',
            'attributes' => {
              'name': input['file_name']
            },
            'relationships' => {
              'target' => {
                'data' => {
                  'type' => 'folders',
                  'id' => input['folder_id']
                }
              }
            }
          }
        }
        hub_id = input.delete('hub_id')
        project_id = input.delete('project_id').gsub('b:', '')
        response_storage =
          post('https://developer.api.autodesk.com/data/v1/' \
               "projects/#{project_id}/storage").
          headers('Content-Type': 'application/vnd.api+json',
                  'Accept': 'application/vnd.api+json').
          payload(payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
        object_id = response_storage&.dig('data', 'id')

        # 2 Upload file to storage location
        bucket_key = object_id.split('/').first.split('object:').last
        object_name = object_id.split('/').last
        response = put('https://developer.api.autodesk.com/oss/v2/buckets/' \
                       "#{bucket_key}/objects/#{object_name}",
                       input['file_content']).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end
        object_urn = response['objectId']
        # 3 create a first version of the File
        # folder_urn = get("/data/v1/projects/#{input['project_id']}/folders" \
        #                  "/#{input['folder_id']}")['data']
        version_payload = {
          'jsonapi' => { 'version' => '1.0' },
          'data' => {
            # type of the resource
            'type' => 'items',
            # The attributes of the data object.
            'attributes' => {
              'displayName' => input['file_name'],
              # Extended information on the resource.
              'extension' =>
              {
                # relevant for creating files
                'type' => input['file_extension'],
                'version' => '1.0'
              }
            },
            'relationships' => {
              # The information on the tip version of this resource.
              'tip' => {
                'data' => {
                  'type' => 'versions',
                  'id' => '1'
                }
              },
              # Information on the parent resource of this resource.
              'parent' => {
                'data' => {
                  'type' => 'folders',
                  # The URN of the parent folder in which you want to create
                  # a version of a file or to copy a file to.
                  'id' => input['folder_id']
                }
              }
            }
          },
          'included' => [
            {
              'type' => 'versions',
              'id' => '1',
              'attributes' => {
                'name' => input['file_name'],
                'extension' => {
                  # input['object_type']
                  'type' => input['version_type'],
                  'version' => input['extension_type_version'] || '1.0'
                }
              },
              'relationships' => {
                'storage' => {
                  'data' => {
                    'type' => 'objects',
                    'id' => object_urn
                  }
                } # ,
                # 'refs' => {
                #   'data' => {
                #     'type' => 'versions',
                #     'id' => 'version_urn'
                #   }
                # }
              }
            }
          ]
        }
        user_id = get('/userprofile/v1/users/@me')['userId']
        # item_id =
        post("/data/v1/projects/#{project_id}/items").
          payload(version_payload).
          headers('Content-Type': 'application/vnd.api+json',
                  Accept: 'application/vnd.api+json',
                  'x-user-id': user_id).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.dig('data')&.merge({ hub_id: hub_id, project_id: project_id })
        # 4 Update version of the file
        # update_version = {
        #   'jsonapi' => '1.0',
        #   'data' => {
        #     'type' => 'versions',
        #     'attributes': {
        #       'extension' => {
        #         'type' => 'versions:autodesk.core:File"',
        #         'version' => '1.0'
        #       }
        #     },
        #     'relationships' => {
        #       'item' => {
        #         'data' => {
        #           'type' => 'items',
        #           'id' => item_id
        #         }
        #       },
        #       'storage' => {
        #         'data' => {
        #           'type' => 'objects',
        #           'id' => object_urn
        #         }
        #       }
        #     }
        #   }
        # }
        # post("/data/v1/projects/#{project_id}/versions").
        #   payload(update_version).
        #   after_error_response(/.*/) do |_code, body, _header, message|
        #     error("#{message}: #{body}")
        #   end
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' }
        ].concat(object_definitions['folder_file'])
      end
    }
  },
  triggers: {
    new_rfi_in_project: {
      title: 'New RFI in a project',
      description: 'New <span class="provider">RFI</span> in'\
        ' a project in <span class="provider">BIM 360</span>',
      help: {
        body: 'Triggers when a RFI in a project is created.'
      },
      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub Name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'project_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide project id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
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
        hub_id = closure&.[]('hub_id') || input['hub_id']
        project_id = closure&.[]('project_id') || input['project_id']
        container_id = closure&.[]('container_id') ||
                       get("/project/v1/hubs/#{input['hub_id']}" \
                           "/projects/#{project_id}")&.
                       dig('data', 'relationships', 'issues', 'data', 'id')
        from_date = closure&.[]('from_date') ||
                    (input['since'] || 1.hour.ago).
                    to_time.strftime('%Y-%m-%dT%H:%M:%H.%s%z')
        limit = 10
        skip = closure&.[]('skip') || 0
        include = closure&.[]('include') || input['include']
        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   else
                     get("/bim360/rfis/v1/containers/#{container_id}/rfis").
                       params(page: { limit: limit,
                                      skip: skip },
                              filter: {
                                created_at: from_date
                              },
                              include: 'attachments,comments',
                              sort: 'created_at')
                   end
        closure = if (next_page_url = response.dig('links', 'next')).present?
                    { 'skip' => skip + limit,
                      'container_id' => container_id,
                      'project_id' => project_id,
                      'hub_id' => hub_id,
                      'include' => include,
                      'from_date' => from_date,
                      'next_page_url' => next_page_url }
                  else
                    { 'offset' => 0,
                      'include' => include,
                      'from_date' => now.to_time.
                        strftime('%Y-%m-%dT%H:%M:%H.%s%z'),
                      'container_id' => container_id,
                      'project_id' => project_id,
                      'hub_id' => hub_id }
                  end
        rfis = response['data']&.
               map do |o|
                 o.merge({ project_id: project_id, hub_id: hub_id,
                           container_id: container_id })
               end
        {
          events: rfis || [],
          next_poll: closure,
          can_poll_more: response.dig('links', 'next').present?
        }
      end,
      dedup: lambda do |rfi|
        "#{rfi['id']}@#{rfi.dig('attributes', 'created_at')}"
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'hub_id' }, { name: 'project_id' }, { name: 'container_id' }].
          concat(object_definitions['rfi'])
      end,
      sample_output: lambda do |_connection, input|
        project_id = input['project_id']
        container_id = get("/project/v1/hubs/#{input['hub_id']}" \
                           "/projects/#{project_id}")&.
                       dig('data', 'relationships', 'issues', 'data', 'id')
        get("/bim360/rfis/v1/containers/#{container_id}/rfis")&.
          dig('data', 0) || {}
      end
    },
    new_updated_issue_in_project: {
      title: 'New or updated issue in a project',
      description: 'New or updated <span class="provider">issue</span> in'\
        ' a project in <span class="provider">BIM 360</span>',
      help: {
        body: 'Triggers when a issue in a project is created or updated.'
      },
      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub Name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'project_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide project id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
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
        hub_id = closure&.[]('hub_id') || input['hub_id']
        project_id = closure&.[]('project_id') || input['project_id']
        container_id = closure&.[]('container_id') ||
                       get("/project/v1/hubs/#{input['hub_id']}" \
                           "/projects/#{project_id}")&.
                       dig('data', 'relationships', 'issues', 'data', 'id')
        updated_after = closure&.[]('updated_after') ||
                        (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 10
        skip = closure&.[]('skip') || 0
        include = closure&.[]('include') || input['include']
        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   else
                     get("/issues/v1/containers/#{container_id}/" \
                         'quality-issues').
                       params(page: { limit: limit,
                                      skip: skip },
                              filter: { synced_after: updated_after },
                              sort: 'updated_at',
                              included: include)
                   end
        closure = if (next_page_url = response.dig('links', 'next')).present?
                    { 'skip' => skip + limit,
                      'container_id' => container_id,
                      'project_id' => project_id,
                      'hub_id' => hub_id,
                      'include' => include,
                      'next_page_url' => next_page_url }
                  else
                    { 'offset' => 0,
                      'container_id' => container_id,
                      'project_id' => project_id,
                      'hub_id' => hub_id,
                      'include' => include,
                      'updated_after' => now.to_time.utc.iso8601 }
                  end
        issues = response['data']&.
                 map do |o|
                   o.merge({ project_id: project_id, hub_id: hub_id,
                             container_id: container_id })
                 end
        {
          events: issues || [],
          next_poll: closure,
          can_poll_more: response.dig('links', 'next').present?
        }
      end,
      dedup: lambda do |issue|
        "#{issue['id']}&#{issue.dig('attributes', 'updated_at')}"
      end,
      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' },
          { name: 'container_id' }
        ].concat(object_definitions['issue']).compact
      end,
      sample_output: lambda do |_connection, input|
        project_id = input['project_id']
        container_id = get("/project/v1/#{input['hub_id']}" \
                           "/projects/#{project_id}")&.
                       dig('relationships', 'rfis', 'data', 'id')
        get("/issues/v1/containers/#{container_id}/" \
            'quality-issues?page[limit]=1')&.dig('data', 0) || {}
      end
    },
    new_updated_document_in_project: {
      title: 'New or updated document in a project folder',
      description: 'New or updated <span class="provider">document</span> in'\
        ' a project folder in <span class="provider">BIM 360</span>',
      help: {
        body: 'Triggers when a document in a project is created or updated' \
        ' in the specified folder.'
      },
      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub Name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide hub id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          {
            name: 'project_id',
            label: 'Project Name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Provide project id e.g. b.baf-0871-4aca-82e8-3dd6db00'
            }
          },
          { name: 'folder_id',
            label: 'Folder',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select Folder',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            tree_options: { selectable_folder: true },
            pick_list: :folders_list,
            optional: false,
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              control_type: 'text',
              label: 'Folder ID',
              toggle_hint: 'Use Folder ID',
              hint: 'Use Folder ID'
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
        hub_id = closure&.[]('hub_id') || input['hub_id']
        project_id = closure&.[]('project_id') || input['project_id']
        folder_id = closure&.[]('folder_id') || input['folder_id']

        last_modified_time = closure&.[]('updated_after') ||
                             (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 10
        skip = closure&.[]('skip') || 0
        include = closure&.[]('include') || input['include']

        response = if (next_page_url = closure&.[]('next_page_url')).present?
                     get(next_page_url)
                   else
                     query_params =
                       'filter[type]=items&filter[lastModifiedTimeRollup]-ge=' \
                       "#{last_modified_time}&" \
                       "page[limit]=#{limit}&page[skip]=#{skip}"
                     get("/data/v1/projects/#{project_id}/folders/" \
                       "#{folder_id}/contents", query_params)
                   end

        items = response['data']&.
          map do |o|
            o.merge({ project_id: project_id, hub_id: hub_id,
                      folder_id: folder_id })
          end
        closure = if (next_page_url = response.dig('links', 'next')).present?
                    { 'skip' => skip + limit,
                      'folder_id' => folder_id,
                      'project_id' => project_id,
                      'hub_id' => hub_id,
                      'include' => include,
                      'next_page_url' => next_page_url }
                  else
                    { 'offset' => 0,
                      'folder_id' => folder_id,
                      'project_id' => project_id,
                      'hub_id' => hub_id,
                      'include' => include,
                      'updated_after' => now.to_time.utc.iso8601 }
                  end
        {
          events: items || [],
          next_poll: closure,
          can_poll_more: response.dig('links', 'next').present?
        }
      end,
      dedup: lambda do |item|
        "#{item['id']}&#{item.dig('attributes', 'lastModifiedTime')}"
      end,
      output_fields: lambda do |object_definitions|
        [{ name: 'hub_id' }, { name: 'project_id' }, { name: 'folder_id' }].
          concat(object_definitions['folder_file']).
          compact
      end,
      sample_output: lambda do |_connection, input|
        get("/data/v1/projects/#{input['project_id']}/folders/" \
          "#{input['folder_id']}/contents?page[limit]=1")&.dig('data', 0) || {}
      end
    }
  },
  pick_lists: {
    hub_list: lambda do |_connection|
      get('/project/v1/hubs')['data']&.map do |hub|
        [hub.dig('attributes', 'name'), hub['id']]
      end
    end,
    file_types: lambda do |_connection|
      [
        ['BIM 360 Docs files', 'items:autodesk.bim360:File'],
        ['All other service', 'items:autodesk.core:File']
      ]
    end,
    folder_items: lambda do |_connection, project_id:, folder_id:|
      if project_id.length == 38 && folder_id.present?
        get("/data/v1/projects/#{project_id}/folders/#{folder_id}/" \
            'contents?filter[type]=items')['data']&.
          map do |item|
            [item.dig('attributes', 'displayName'), item['id']]
          end
      end
    end,
    item_versions: lambda do |_connection, project_id:, item_id:|
      get("/data/v1/projects/#{project_id}/items/#{item_id}/" \
         'versions')['data']&.
        map do |version|
        ["Version #{version.dig('attributes', 'versionNumber')}",
         version.dig('id')]
      end
    end,
    version_types: lambda do |_connection|
      [
        ['BIM 360 Docs files', 'versions:autodesk.bim360:File'],
        ['A360 composite design files',
         'versions:autodesk.a360:CompositeDesign'],
        ['A360 Personal, Fusion Team', 'versions:autodesk.core:File'],
        ['BIM 360 Team files', 'versions:autodesk.core:File']
      ]
    end,
    resource_types: lambda do |_connection|
      %w[attachment overlay].map { |type| [type.labelize, type] }
    end,
    folders_list: lambda do |_connection, **args|
      hub_id = args[:hub_id]
      project_id = args[:project_id]
      parent_id = args&.[](:__parent_id)
      if project_id.length == 38
        if parent_id.present?
          get("/data/v1/projects/#{project_id}/folders/#{parent_id}/" \
              'contents?filter[type]=folders')['data']&.
            map do |folder|
              [folder.dig('attributes', 'displayName'),
               folder['id'], folder['id'], true]
            end
        else
          get("project/v1/hubs/#{hub_id}/projects/#{project_id}/" \
              'topFolders?filter[type]=folders')['data']&.
            map do |folder|
              [folder.dig('attributes', 'displayName'),
               folder['id'], folder['id'], true]
            end || []
        end
      end
    end,
    rfi_child_objects: lambda do |_connection|
      %w[attachments comments activity_batches container]&.
      map { |option| [option.labelize, option] }
    end,
    rfi_transaction_status_list: lambda do |_connection|
      %w[draft submitted open rejected answered closed void]&.
      map { |option| [option.labelize, option] }
    end,
    issue_child_objects: lambda do |_connection|
      %w[attachments comments container]&.
      map { |option| [option.labelize, option] }
    end,
    project_list: lambda do |_connection, hub_id:|
      if hub_id.length == 38
        get("project/v1/hubs/#{hub_id}/projects")['data']&.map do |project|
          [project.dig('attributes', 'name'), project['id']]
        end
      end
    end,
    issue_container_lists: lambda do |_connection, hub_id:|
      if hub_id.length == 38
        get("project/v1/hubs/#{hub_id}/projects")['data']&.map do |project|
          [project.dig('attributes', 'name'),
           project.dig('relationships', 'issues', 'data', 'id')]
        end
      end
    end,
    rfis_container_lists: lambda do |_connection, hub_id:|
      if hub_id.length == 38
        get("project/v1/hubs/#{hub_id}/projects")['data']&.map do |project|
          [project.dig('attributes', 'name'),
           project.dig('relationships', 'rfis', 'data', 'id')]
        end
      end
    end,
    rfi_objects: lambda do |_connection|
      %w[attachments comments activity_batches container]&.
      map { |option| [option.labelize, option] }
    end,
    project_types: lambda do
      [
        %w[Commercial Commercial], ['Convention Center', 'Convention Center'],
        ['Data Center', 'Data Center'], ['Hotel / Motel', 'Hotel / Motel'],
        %w[Office Office],
        ['Parking Structure / Garage', 'Parking Structure / Garage'],
        ['Performing Arts', 'Performing Arts'], %w[Retail Retail],
        ['Stadium/Arena', 'Stadium/Arena'], ['Theme Park', 'Theme Park'],
        ['Warehouse (non-manufacturing)', 'Warehouse (non-manufacturing)'],
        %w[Healthcare Healthcare],
        ['Assisted Living / Nursing Home', 'Assisted Living / Nursing Home'],
        %w[Hospital Hospital], ['Medical Laboratory', 'Medical Laboratory'],
        ['Medical Office', 'Medical Office'],
        ['OutPatient Surgery Center', 'OutPatient Surgery Center'],
        %w[Institutional Institutional], ['Court House', 'Court House'],
        %w[Dormitory Dormitory], ['Education Facility', 'Education Facility'],
        ['Government Building', 'Government Building'], %w[Library Library],
        ['Military Facility', 'Military Facility'], %w[Museum Museum],
        ['Prison / Correctional Facility', 'Prison / Correctional Facility'],
        ['Recreation Building', 'Recreation Building'],
        ['Religious Building', 'Religious Building'],
        ['Research Facility / Laboratory', 'Research Facility / Laboratory'],
        %w[Residential Residential],
        ['Multi-Family Housing', 'Multi-Family Housing'],
        ['Single-Family Housing', 'Single-Family Housing'],
        %w[Infrastructure Infrastructure], %w[Airport Airport],
        %w[Bridge Bridge], ['Canal / Waterway', 'Canal / Waterway'],
        ['Dams / Flood Control / Reservoirs',
         'Dams / Flood Control / Reservoirs'],
        ['Harbor / River Development', 'Harbor / River Development'],
        %w[Rail Rail], %w[Seaport Seaport],
        ['Streets / Roads / Highways', 'Streets / Roads / Highways'],
        ['Transportation Building', 'Transportation Building'],
        %w[Tunnel Tunnel], ['Waste Water / Sewers', 'Waste Water / Sewers'],
        ['Water Supply', 'Water Supply'],
        ['Industrial & Energy', 'Industrial & Energy'],
        ['Manufacturing / Factory', 'Manufacturing / Factory'],
        ['Oil & Gas', 'Oil & Gas'],
        %w[Plant Plant], ['Power Plant', 'Power Plant'],
        ['Solar Far', 'Solar Far'], %w[Utilities Utilities],
        ['Wind Farm', 'Wind Farm'], ['Sample Projects', 'Sample Projects'],
        ['Demonstration Project', 'Demonstration Project'],
        ['Template Project', 'Template Project'],
        ['Training Project', 'Training Project']
      ]
    end,
    assigned_type_list: lambda do |_connection|
      %w[user company role]&.map { |el| [el.labelize, el] }
    end,
    rfi_status_list: lambda do |_connection|
      %w[draft open close]&.map { |el| [el.labelize, el] }
    end,
    status_list: lambda do |_connection|
      %w[active pending inactive archived]&.map { |el| [el.labelize, el] }
    end,
    issue_status_list: lambda do |_connection|
      %w[open work_complete ready_to_inspect not_approved close in_dispute
         void]&.map { |el| [el.labelize, el] }
    end,
    service_types: lambda do |_connection|
      [
        ['Field Service', 'field'],
        ['Glue Service', 'glue'],
        ['Schedule Service', 'schedule'],
        ['Plan Service', 'plan'],
        ['Docs Service', 'doc_manager']
      ]
    end
  }
}
