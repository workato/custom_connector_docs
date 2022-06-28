{
  title: 'BIM 360',

  connection: {
    authorization: {
      type: 'oauth2',

      authorization_url: lambda do |connection|
        'https://developer.api.autodesk.com/authentication/v1/authorize?response_type=' \
        "code&scope=user:read account:read data:write data:write data:read data:create account:write"
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        post('https://developer.api.autodesk.com/authentication/v1/gettoken').
          payload(client_id: "#{'client_id'}",
                  client_secret: "#{'client_secret'}",
                  grant_type: 'authorization_code',
                  code: auth_code,
                  redirect_uri: redirect_uri).request_format_www_form_urlencoded
      end,

      refresh_on: [401, 403],

      refresh: lambda do |connection, refresh_token|
        post('https://developer.api.autodesk.com/authentication/v1/refreshtoken').
          payload(client_id: "#{'client_id'}",
                  client_secret: "#{'client_secret'}",
                  grant_type: 'refresh_token',
                  refresh_token: refresh_token,
                  scope: 'user:read account:read data:read data:write account:write').request_format_www_form_urlencoded
      end,

      apply: lambda do |_connection, access_token|
        if current_url.include?('https://developer.api.autodesk.com/cost/')
          headers('Authorization': "Bearer #{access_token}", 'Content-Type' => 'application/json')
        else
          headers('Authorization': "Bearer #{access_token}", 'Content-Type' => 'application/vnd.api+json')
        end
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

    format_output_response: lambda do |res, keys|
      keys.each do |key|
        res[key] = res[key]&.map { |value| { 'value' => value } } if res&.has_key?(key)
      end
    end,

    format_search: lambda do |input|
      if input.is_a?(Hash)
        input.each_with_object({}) do |(key, value), hash|
          value = call('format_search', value)
          if %w[limit offset].include?(key)
            hash["page[#{key}]"] = value
          elsif %w[include_voided assigned_to target_urn due_date synced_after
                   created_at created_by search
                   ng_issue_type_id ng_issue_subtype_id status].include?(key)
            hash["filter[#{key}]"] = value
          elsif key == "rfis"
            hash["fields[#{key}]"] = value
          else
            hash[key] = value
          end
        end
      else
        input
      end
    end,

    format_cost_search: lambda do |input|
      if input.is_a?(Hash)
        input.each_with_object({}) do |(key, value), hash|
          value = call('format_search', value)
          if %w[rootId externalSystem externalId code
                contractId mainContractId budgetStatus costStatus
                changeOrderId budgetId associationId associationType
                latest signed lastModifiedSince].include?(key)
            hash["filter[#{key}]"] = value
          else
            hash[key] = value
          end
        end
      else
        input
      end
    end,

    make_schema_builder_fields_sticky: lambda do |input|
      input.map do |field|
        if field[:properties].present?
          field[:properties] = call('make_schema_builder_fields_sticky', field[:properties])
        elsif field['properties'].present?
          field['properties'] = call('make_schema_builder_fields_sticky', field['properties'])
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
          'versionUrn': 'dXJuOmFkc2sud2lwcWE6ZnMuZmlsZTp2Zi5wZjNmclUwZ1RaYU9vdEtYZzJoMUZ3P3ZlcnNpb249MQ',
          'resourceId': "urn:adsk.viewing:fs.file:dXJuOmFkc2sud2lwcWE6ZnMuZmlsZTp2Zi5wZjNmclUwZ1RaYU9vdEtYZzJoMUZ3P3ZlcnNpb249MQ/output' \
          '/qXP_ZA5_3EqJoq5zqvnLHA/h8YAl4KMcEe9-L5SaEXY6A.pdf",
          'link': "https://developer.api.autodesk.com/modelderivative/v2/designdata/dXJuOmFkc2sud2lwcWE6ZnMuZmlsZTp2Zi5wZjNmclUwZ1RaYU9v' \
          'dEtYZzJoMUZ3P3ZlcnNpb249MQ/manifest/urn%3Aadsk.viewing%3Afs.file%3AdXJuOmFkc2sud2lwcWE6ZnMuZmlsZTp2Zi5wZjNmclUwZ1RaYU9vdEtYZzJo' \
          'MUZ3P3ZlcnNpb249MQ%2Foutput%2FqXP_ZA5_3EqJoq5zqvnLHA%2Fh8YAl4KMcEe9-L5SaEXY6A.pdf"
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
            { name: 'name' },
            { name: 'scopes', type: 'array', of: 'object', properties:[
              { name: "value" }
            ] },
            { name: 'extension', type: 'object', properties: [
              { name: 'type' },
              { name: 'version' },
              { name: 'schema', type: 'object', properties: [
                { name: 'href' }
              ] }
            ] }
          ] },
          { name: 'links', type: 'object', properties:[
            { name: 'self', type: 'object', properties:[
              { name: 'href' }
            ] }
          ] },
          { name: 'relationships', type: 'object', properties: [
            { name: 'hub', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'id', label: 'Hub ID' }
              ] },
              { name: 'links', type: 'object', properties:[
                { name: 'self', type: 'object', properties:[
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'rootFolder', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'id', label: 'Root folder ID' },
                { name: 'type' }
              ] },
              { name: 'meta', type: 'object', properties: [
                { name: 'link', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'topFolders', type: 'object', properties: [
              { name: 'links', type: 'object', properties: [
                { name: 'related', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'issues', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'type' },
                { name: 'id', label: 'Issues container ID' }
              ] },
              { name: 'meta', type: 'object', properties: [
                { name: 'link', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'submittals', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'type' },
                { name: 'id', label: 'Submittals container ID' }
              ] },
              { name: 'meta', type: 'object', properties: [
                { name: 'link', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'rfis', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'type' },
                { name: 'id', label: 'RFIs container ID' }
              ] },
              { name: 'meta', type: 'object', properties: [
                { name: 'link', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'markups', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'type' },
                { name: 'id', label: 'Markups container ID' }
              ] },
              { name: 'meta', type: 'object', properties: [
                { name: 'link', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'checklists', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'type' },
                { name: 'id', label: 'Checklists container ID' }
              ] },
              { name: 'meta', type: 'object', properties: [
                { name: 'link', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'cost', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'type' },
                { name: 'id', label: 'Cost container ID' }
              ] },
              { name: 'meta', type: 'object', properties: [
                { name: 'link', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'location', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'type' },
                { name: 'id', label: 'Locations container ID' }
              ] }
            ] },
            { name: 'meta', type: 'object', properties: [
                { name: 'link', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
          ] }
        ]
      end
    },

    issue: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id', label: 'Issue ID' },
          { name: 'type' },
          { name: 'links', type: 'object', properties:[
            { name: 'self' }
          ] },
          { name: 'attributes', type: 'object', properties: [
            { name: 'created_at', type: 'date_time',
              hint: 'The timestamp of the date and time the issue was created, in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'synced_at', type: 'date_time',
              hint: 'The date and time the issue was synced with BIM 360, in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'updated_at', type: 'date_time',
              hint: 'The last time the issue’s attributes were updated, in <b>the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'close_version', type: :integer, control_type: :integer,
              hint: 'The version of the issue when it was closed.' },
            { name: 'closed_at', type: 'date_time',
              hint: 'The timestamp of the data and time the issue was closed, in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'closed_by',
              hint: 'The Autodesk ID of the user who closed the issue.' },
            { name: 'created_by',
              hint: 'The Autodesk ID of the user who created the issue.' },
            { name: 'opened_at' },
            { name: 'opened_by' },
            { name: 'updated_by' },
            { name: 'starting_version', type: 'integer',
              hint: 'The first version of the issue' },
            { name: 'title', label: 'Issue title' },
            { name: 'description',
              hint: 'The description of the purpose of the issue.' },
            { name: 'location_description',
              hint: 'The location of the issue.' },
            { name: 'markup_metadata' },
            { name: 'tags' },
            { name: 'resource_urns' },
            { name: 'target_urn',
              hint: 'The item ID of the document associated with the pushpin issue.' },
            { name: 'target_urn_page' },
            { name: 'collection_urn' },
            { name: 'snapshot_urn' },
            { name: 'due_date', type: 'date_time',
              hint: 'The timestamp of the issue’s specified due date, in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'identifier', type: 'integer',
              hint: 'The identifier of the issue.' },
            { name: 'status', control_type: 'select',
              pick_list: 'issue_status_list',
              toggle_hint: 'Select status',
              toggle_field: {
                name: 'status', label: 'Status', type: 'string',
                control_type: 'text', toggle_hint: 'Enter status value',
                hint: 'Allowed values are :<b>open, work_complete, ready_to_inspect, not_approved, close in_dispute, void</b>.'
              } },
            { name: 'assigned_to', hint: 'The Autodesk ID of the user' },
            { name: 'assigned_to_type',
              hint: 'The type of subject this issue is assigned to. Possible values: user, company, role' },
            { name: 'answer' },
            { name: 'answered_at', type: 'date_time',
              hint: 'The date and time the issue was answered, in the following format: <b>YYYY-MM-DDThh:mm:ss.sz</b>.',
              render_input: 'render_iso8601_timestamp',
              parse_output: 'parse_iso8601_timestamp' },
            { name: 'answered_by',
              hint: 'The user who suggested an answer for the issue.' },
            { name: 'pushpin_attributes' },
            { name: 'owner',
              hint: 'The Autodesk ID of the user who owns this issue.' },
            { name: 'issue_type_id' },
            { name: 'issue_type' },
            { name: 'issue_sub_type' },
            { name: 'root_cause_id' },
            { name: 'root_cause' },
            { name: 'quality_urns' },
            { name: 'permitted_statuses', type: 'array', of: 'object', properties: [
              { name: "value" }],
              hint: 'A list of statuses accessible to the current user.' },
            { name: 'permitted_attributes', type: 'array', of: 'object', properties: [
              { name: "value" }],
              hint: 'A list of attributes accessible to the current user.' },
            { name: 'comment_count', type: 'integer',
              hint: 'The number of comments added to this issue.' },
            { name: 'attachment_count', type: 'integer', control_type: 'integer',
              hint: 'The number of attachments added to this issue.' },
            { name: 'permitted_actions', type: 'array', of: 'object', properties: [
              { name: "value" }],
              hint: 'The actions that are permitted for the issue in this state.' },
            { name: 'lbs_location',
              hint: 'The ID of the location that relates to the issue.' },
            { name: 'sheet_metadata' },
            { name: 'ng_issue_type_id', label: 'Issue type ID',
              hint: 'The ID of the issue type.' },
            { name: 'ng_issue_subtype_id', label: 'Issue subtype ID',
              hint: 'The ID of the issue subtype' },
            { name: 'issue_template_id' },
            { name: 'trades' },
            { name: 'comments_attributes' },
            { name: 'attachments_attributes' }
          ] },
          { name: 'relationships', type: 'object', properties:[
            { name: 'container', type: 'object', properties:[
              { name: 'links', type: 'object', properties:[
                { name: 'self' },
                { name: 'related' }
              ] }
            ] },
            { name: 'attachments', type: 'object', properties:[
              { name: 'links', type: 'object', properties:[
                { name: 'self' },
                { name: 'related' }
              ] }
            ] },
            { name: 'activity_batches', type: 'object', properties:[
              { name: 'links', type: 'object', properties:[
                { name: 'self' },
                { name: 'related' }
              ] }
            ] },
            { name: 'comments', type: 'object', properties:[
              { name: 'links', type: 'object', properties:[
                { name: 'self' },
                { name: 'related' }
              ] }
            ] },
            { name: 'root_cause_obj', label: "Root cause object", type: 'object', properties:[
              { name: 'links', type: 'object', properties:[
                { name: 'self' },
                { name: 'related' }
              ] }
            ] },
            { name: 'changesets', type: 'object', properties:[
              { name: 'links', type: 'object', properties:[
                { name: 'self' },
                { name: 'related' }
              ] }
            ] },
            { name: 'issue_type_obj', label: "Issue type object", type: 'object', properties:[
              { name: 'links', type: 'object', properties:[
                { name: 'self' },
                { name: 'related' }
              ] }
            ] }
          ] },
          # To Do
          { name: 'custom_attributes', type: 'array', of: 'object', properties: [
            { name: 'value' }
          ] },
          { name: 'trades', type: 'array', of: 'object', properties: [
            { name: 'value' }
          ] },
          { name: 'comments_attributes' },
          { name: 'attachments_attributes' }
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
            pick_list: %w[draft open].map { |option| [option.labelize, option] },
            toggle_hint: 'Select status',
            toggle_field: {
              name: 'status', label: 'Status', type: 'string',
              control_type: 'text', toggle_hint: 'Enter status value',
              hint: 'The status of the issue. Possible values:<b>draft, open</b>. The default is draft'
            } },
          { name: 'starting_version', type: 'integer',
            hint: 'The first version of the issue' },
          { name: 'due_date', type: 'date_time',
            hint: 'The timestamp of the date and time the issue created.',
            render_input: 'render_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'location_description' },
          { name: 'created_at', type: 'date_time',
            hint: 'The timestamp of the date and time the issue created.',
            render_input: 'render_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'assigned_to',
            hint: 'The Autodesk ID (uid) of the user you want to assign to this issue. If you specify this attribute you need to also specify assigned_to_type.' },
          { name: 'assigned_to_type',
            hint: 'The type of subject this issue is assigned to. Possible values: <b>user</b>. If you specify this attribute you need to also specify assigned_to.' },
          { name: 'owner',
            hint: 'The BIM 360 ID of the user who owns this issue.' },
          { name: 'root_cause_id',
            hint: 'The ID of the type of root cause for this issue.' }
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
              control_type: 'text', toggle_hint: 'Enter status value',
              hint: 'The status of the issue. Possible values:<b>draft, open</b>. The default is draft'
            } },
          { name: 'due_date', type: 'date_time',
            hint: 'The timestamp of the date and time the issue updated.',
            render_input: 'render_iso8601_timestamp',
            parse_output: 'parse_iso8601_timestamp' },
          { name: 'location_description' },
          { name: 'assigned_to',
            hint: 'The Autodesk ID (uid) of the user you want to assign to this issue. If you specify this attribute you need to also specify assigned_to_type.' },
          { name: 'assigned_to_type',
            hint: 'The type of subject this issue is assigned to. Possible values: <b>user</b>. If you specify this attribute you need to also specify assigned_to.' },
          { name: 'owner',
            hint: 'The BIM 360 ID of the user who owns this issue.' },
          { name: 'ng_issue_type_id', label: 'Issue type ID',
            hint: 'The ID of the issue type. You can only configure this attribute when the issue is in draft state' },
          { name: 'ng_issue_subtype_id', label: 'Issue subtype ID',
            hint: 'The ID of the issue subtype. You can configure this attribute when the issue is in draft or open state' },
          { name: 'root_cause_id',
            hint: 'The ID of the type of root cause for this issue.' },
          { name: 'close_version' }
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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of c8b0c73d-3ae9 translates '\
              'to a hub ID of b.c8b0c73d-3ae9. Get account ID from admin page.'
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
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          { name: 'target_urn', sticky: true },
          { name: 'due_date', type: 'date_time',
            sticky: true,
            hint: 'Retrieves issues due by the specified due date.' },
          { name: 'synced_after', type: 'date_time',
            sticky: true,
            hint: 'Retrieves issues updated after the specified date' },
          { name: 'created_at', type: 'date_time',
            sticky: true,
            hint: 'Retrieves issues created after the specified date.' },
          { name: 'created_by',
            sticky: true,
            hint: 'Retrieves issues created by the user. matchValue is the unique identifier of the user who created the issue.' },
          { name: 'ng_issue_type_id', label: 'Issue type ID',
            sticky: true,
            hint: 'Retrieves issues associated with the specified issue type' },
          { name: 'ng_issue_subtype_id', label: 'Issue subtype ID',
            sticky: true,
            hint: 'Retrieves issues associated with the specified issue subtype.' },
          { name: 'limit', type: 'integer',
            sticky: true,
            hint: 'Number of issues to return in the response. Acceptable values: 1-100. Default value: 10' },
          { name: 'offset',
            sticky: true,
            hint: 'The page number that you want to begin issue results from.' },
          { name: 'sort',
            sticky: true,
            hint: 'Sort the issues by status, created_at, and updated_a. To sort in descending order add a <b>-</b> before the sort criteria' },
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
              change_on_blur: true,
              control_type: 'text',
              optional: true,
              hint: 'Multiple values separated by comma.',
              toggle_hint: 'Comma separated list of values. Allowed values are: <b>attachments, comments, container</b>.'
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
              change_on_blur: true,
              toggle_hint: 'Enter hub ID',
              hint: 'Provide hub id for example, b.baf-0871-4aca-82e8-3dd6db00.'
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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter container ID',
              hint: 'Provide container id e.g. b.baf-0871-4aca-82e8-3dd6db00.'
            }
          },
          { name: 'folder_id',
            label: 'Folder',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select folder',
            tree_options: { selectable_folder: true },
            pick_list: :folders,
            optional: false,
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              label: 'Folder ID',
              toggle_hint: 'Enter folder ID',
              hint: 'Get ID from folder page.'
            } }
        ]
      end
    },

    folder_file: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id', label: 'Item ID' },
          { name: 'type', label: 'Item type' },
          { name: 'attributes', type: 'object', properties: [
            { name: 'displayName', label: 'Name' },
            { name: 'createTime', label: 'Created at', type: 'date_time' },
            { name: 'createUserId', label: 'Created by (User ID)' },
            { name: 'createUserName', label: 'Created by (User name)' },
            { name: 'lastModifiedTime',
              label: 'Last modified at', type: 'date_time' },
            { name: 'lastModifiedUserId', label: 'Last modified by (User ID)' },
            { name: 'lastModifiedUserName',
              label: 'Last modified by (User Name)' },
            { name: 'lastModifiedTimeRollup', type: 'date_time' },
            { name: 'objectCount', type: 'integer' },
            { name: 'hidden', type: 'boolean', control_type: 'checkbox' },
            { name: 'reserved', type: 'boolean', control_type: 'checkbox' },
            { name: 'extension', type: 'object', properties: [
              { name: 'version' },
              { name: 'type' },
              { name: 'schema', type: 'object', properties:[
                { name: 'href' }
              ] },
              { name: 'data', type: 'object', properties: [
                { name: 'sourceFileName' },
                { name: 'visibleTypes', type: 'array', of: 'object', properties: [{ name: "value" }] },
                { name: 'actions', type: 'array', of: 'object', properties: [{ name: "value" }] },
                { name: 'allowedTypes', type: 'array', of: 'object', properties: [{ name: "value" }] }
              ] }
            ] }
          ] },
          { name: 'links', type: 'object', properties:[
            { name: 'self', type: 'object', properties:[
              { name: 'href' }
            ] }
          ] },
          { name: 'relationships', type: 'object', properties:[
            { name: 'tip', type: 'object', properties: [
              { name: 'data', type: 'object', properties:[
                { name: 'type' },
                { name: 'id' }
              ] },
              { name: 'links', type: 'object', properties:[
                { name: 'related', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'versions', type: 'object', properties:[
              { name: 'links', type: 'object', properties:[
                { name: 'related', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'parent', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'type' },
                { name: 'id' }
              ] },
              { name: 'links', type: 'object', properties: [
                { name: 'related', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'refs', type: 'object', properties: [
              { name: 'links', type: 'object', properties: [
                { name: 'self', type: 'object', properties: [
                  { name: 'href' }
                ] },
                { name: 'related', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'links', type: 'object', properties: [
              { name: 'links', type: 'object', properties: [
                { name: 'self', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'contents', type: 'object', properties:[
              { name: 'links', type: 'object', properties: [
                { name: 'related', type: 'object', properties: [
                  { name: 'href' }
                ]}
              ] }
            ] }
          ] }
        ]
      end
    },

    item: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'jsonapi', type: 'object', properties: [
            { name: 'version' }
          ] },
          { name: 'links', type: 'object', properties: [
            { name: 'self', type: 'object', properties: [
              { name: 'href' }
            ] }
          ] },
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', label: 'Item ID' },
            { name: 'attributes', type: 'object', properties: [
              { name: 'displayName', label: 'Name' },
              { name: 'createTime', label: 'Created at', type: 'date_time' },
              { name: 'createUserId', label: 'Created by (User ID)' },
              { name: 'createUserName', label: 'Created by (User name)' },
              { name: 'lastModifiedTime',
                label: 'Last modified at', type: 'date_time' },
              { name: 'lastModifiedUserId',
                label: 'Last modified by (User ID)' },
              { name: 'lastModifiedUserName',
                label: 'Last modified by (User Name)' },
              { name: 'hidden', type: 'boolean', control_type: 'checkbox' },
              { name: 'reserved', type: 'boolean', control_type: 'checkbox' },
              { name: 'extension', type: 'object', properties: [
                { name: 'version' },
                { name: 'type' },
                { name: 'schema', type: 'object', properties: [
                  { name: 'href' }
                ] },
                { name: 'data', type: 'object', properties: [
                  { name: 'sourceFileName' }
                ] }
              ] }
            ] },
            { name: 'links', type: 'object', properties: [
              { name: 'self', type: 'object', properties: [
                { name: 'href' }
              ] }
            ] },
            { name: 'relationships', type: 'object', properties: [
              { name: 'tip', type: 'object', properties: [
              { name: 'data', type: 'object', properties:[
                { name: 'type' },
                { name: 'id' }
              ] },
              { name: 'links', type: 'object', properties:[
                { name: 'related', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'versions', type: 'object', properties:[
              { name: 'links', type: 'object', properties:[
                { name: 'related', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'parent', type: 'object', properties: [
              { name: 'data', type: 'object', properties: [
                { name: 'type' },
                { name: 'id' }
              ] },
              { name: 'links', type: 'object', properties: [
                { name: 'related', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'refs', type: 'object', properties: [
              { name: 'links', type: 'object', properties: [
                { name: 'self', type: 'object', properties: [
                  { name: 'href' }
                ] },
                { name: 'related', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] },
            { name: 'links', type: 'object', properties: [
              { name: 'links', type: 'object', properties: [
                { name: 'self', type: 'object', properties: [
                  { name: 'href' }
                ] }
              ] }
            ] }
            ] }
          ] },
          { name: 'included', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'id' },
            { name: 'attributes', type: 'object', properties: [
              { name: 'name' },
              { name: 'displayName' },
              { name: 'createTime', type: 'date_time' },
              { name: 'createUserId' },
              { name: 'createUserName' },
              { name: 'lastModifiedTime', type: 'date_time' },
              { name: 'lastModifiedUserId' },
              { name: 'lastModifiedUserName' },
              { name: 'versionNumber', type: 'integer' },
              { name: 'storageSize', type: 'integer' },
              { name: 'fileType' },
              { name: 'extension', type: 'object', properties: [
                { name: 'type' },
                { name: 'version' },
                { name: 'schema', type: 'object', properties: [
                  { name: 'href' }
                ] },
                { name: 'data', type: 'object', properties: [
                  { name: 'processState' },
                  { name: 'extractionState' },
                  { name: 'splittingState' },
                  { name: 'reviewState' },
                  { name: 'revisionDisplayLabel' },
                  { name: 'sourceFileName' }
                ] }
              ] }
            ] },
            { name: 'links', type: 'object', properties: [
              { name: 'self', type: 'object', properties: [
                { name: 'href' }
              ] }
            ] },
            { name: 'relationships', type: 'object', properties: [
              { name: 'item', type: 'object', properties: [
                { name: 'data', type: 'object', properties: [
                  { name: 'type' },
                  { name: 'id' }
                ] },
                { name: 'links', type: 'object', properties: [
                  { name: 'related', type: 'object', properties: [
                    { name: 'href' }
                  ] }
                ] }
              ] },
              { name: 'links', type: 'object', properties: [
                { name: 'links', type: 'object', properties: [
                  { name: 'self', type: 'object', properties: [
                    { name: 'href' }
                  ] }
                ] }
              ] },
              { name: 'refs', type: 'object', properties: [
                { name: 'links', type: 'object', properties: [
                  { name: 'self', type: 'object', properties: [
                    { name: 'href' }
                  ] },
                  { name: 'related', type: 'object', properties: [
                    { name: 'href' }
                  ] }
                ] }
              ] },
              { name: 'downloadFormats', type: 'object', properties: [
                { name: 'links', type: 'object', properties: [
                  { name: 'related', type: 'object', properties: [
                    { name: 'href' }
                  ] }
                ] }
              ] },
              { name: 'derivatives', type: 'object', properties: [
                { name: 'data', type: 'object', properties: [
                  { name: 'type' },
                  { name: 'id' }
                ] },
                { name: 'meta', type: 'object', properties: [
                  { name: 'link', type: 'object', properties: [
                    { name: 'href' }
                  ] }
                ] }
              ] },
              { name: 'thumbnails', type: 'object', properties: [
                { name: 'data', type: 'object', properties: [
                  { name: 'type' },
                  { name: 'id' }
                ] },
                { name: 'meta', type: 'object', properties: [
                  { name: 'link', type: 'object', properties: [
                    { name: 'href' }
                  ] }
                ] }
              ] },
              { name: 'storage', type: 'object', properties: [
                { name: 'data', type: 'object', properties: [
                  { name: 'type' },
                  { name: 'id' }
                ] },
                { name: 'meta', type: 'object', properties: [
                  { name: 'link', type: 'object', properties: [
                    { name: 'href' }
                  ] }
                ] }
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

    budget: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'parentId' },
          { name: 'code' },
          { name: 'name' },
          { name: 'description' },
          { name: 'quantity', type: 'number'  },
          { name: 'unitPrice' },
          { name: 'unit' },
          { name: 'originalAmount', type: 'number' },
          { name: 'internalAdjustment', type: 'number' },
          { name: 'approvedOwnerChanges', type: 'number' },
          { name: 'pendingOwnerChanges' , type: 'number'},
          { name: 'originalCommitment', type: 'number' },
          { name: 'approvedChangeOrders', type: 'number' },
          { name: 'approvedInScopeChangeOrders', type: 'number' },
          { name: 'pendingChangeOrders', type: 'number' },
          { name: 'reserves', type: 'number' },
          { name: 'actualCost', type: 'number' },
          { name: 'mainContractId' },
          { name: 'adjustments', type: 'object', properties: [
            { name: 'total', type: 'number'},
            { name: 'details', type: 'array', of: 'objects', properties: [
              { name: 'quantity', type: 'number' },
              { name: 'unitPrice', type: 'number' },
              { name: 'unit' }
            ]},
            { name: 'updatedAt', type: 'date_time'}
          ]},
          { name: 'uncommited', type: 'number' },
          { name: 'revised', type: 'number' },
          { name: 'projectedCost', type: 'number' },
          { name: 'projectedBudget', type: 'number' },
          { name: 'forecastFinalCost', type: 'number' },
          { name: 'forecastVariance', type: 'number' },
          { name: 'forecastCostComplete', type: 'number' },
          { name: 'varianceTotal', type: 'number' },
          { name: 'externalId' },
          { name: 'externalSystem' },
          { name: 'createdAt', type: 'date_time' },
          { name: 'updatedAt', type: 'date_time' }
        ]
      end
    },

    contract: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'code' },
          { name: 'name' },
          { name: 'description' },
          { name: 'companyId' },
          { name: 'type' },
          { name: 'contactId' },
          { name: 'signedBy' },
          { name: 'ownerId' },
          { name: 'statusId' },
          { name: 'status' },
          { name: 'changedBy' },
          { name: 'creatorId' },
          { name: 'awarded', type: 'number' },
          { name: 'changes', type: 'number' },
          { name: 'total', type: 'number' },
          { name: 'originalBudget', type: 'number' },
          { name: 'internalAdjustment', type: 'number' },
          { name: 'approvedOwnerChanges', type: 'number' },
          { name: 'pendingOwnerChanges', type: 'number' },
          { name: 'approvedChangeOrders', type: 'number' },
          { name: 'approvedInScopeChangeOrders', type: 'number' },
          { name: 'pendingChangeOrders', type: 'number' },
          { name: 'reserves', type: 'number' },
          { name: 'actualCost', type: 'number' },
          { name: 'uncommitted', type: 'number' },
          { name: 'revised', type: 'number' },
          { name: 'projectedCost', type: 'number' },
          { name: 'projectedBudget', type: 'number' },
          { name: 'forecastFinalCost', type: 'number' },
          { name: 'forecastVariance', type: 'number' },
          { name: 'forecastCostComplete', type: 'number' },
          { name: 'varianceTotal', type: 'number' },
          { name: 'awardedAt', type: 'date_time' },
          { name: 'statusChangedAt', type: 'date_time' },
          { name: 'documentGeneratedAt', type: 'date_time' },
          { name: 'sentAt', type: 'date_time' },
          { name: 'respondedAt', type: 'date_time' },
          { name: 'returnedAt', type: 'date_time' },
          { name: 'onsiteAt', type: 'date_time' },
          { name: 'offsiteAt', type: 'date_time' },
          { name: 'procuredAt', type: 'date_time' },
          { name: 'approvedAt', type: 'date_time' },
          { name: 'scopeOfWork' },
          { name: 'note' },
          { name: 'budgets', type: 'array', of: 'object', properties: [
            { name: 'id' },
            { name: 'mainContractId' }
          ]},
          { name: 'adjustments', type: 'array', of: 'object', properties: [
            { name: 'total', type: 'number' },
            { name: 'details', type: 'array', of: 'object', properties: [
              { name: 'quantity', type: 'number' },
              { name: 'unitPrice', type: 'number' },
              { name: 'unit' }
            ]},
            { name: 'updatedAt', type: 'date_time' }
          ]},
          { name: 'externalId' },
          { name: 'externalSystem' },
          { name: 'createdAt', type: 'date_time' },
          { name: 'updatedAt', type: 'date_time' }
        ]
      end
    },

    change_order: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'number' },
          { name: 'name' },
          { name: 'description' },
          { name: 'scope' },
          { name: 'creatorId' },
          { name: 'ownerId' },
          { name: 'changedBy' },
          { name: 'budgetStatus' },
          { name: 'costStatus' },
          { name: 'estimated', type: 'number' },
          { name: 'proposed', type: 'number' },
          { name: 'submitted', type: 'number' },
          { name: 'approved', type: 'number' },
          { name: 'committed', type: 'number' },
          { name: 'scopeOfWork' },
          { name: 'note' },
          { name: 'externalId' },
          { name: 'externalSystem' },
          { name: 'createdAt', type: 'date_time' },
          { name: 'updatedAt', type: 'date_time' },
          { name: 'properties', type: 'array', of: 'object', properties: [
            { name: 'name' },
            { name: 'builtIn', type: 'boolean' },
            { name: 'position', type: 'number' },
            { name: 'propertyDefinitionId'},
            { name: 'type'},
            { name: 'value'}
          ]},
          { name: 'costItems', type: 'array', of: 'object', properties: [
            { name: 'id' }
          ]}
        ]
      end
    },

    cost_item: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'number' },
          { name: 'name' },
          { name: 'description' },
          { name: 'budgetStatus' },
          { name: 'costStatus' },
          { name: 'scope' },
          { name: 'type' },
          { name: 'isMarkup', type: 'boolean' },
          { name: 'estimated', type: 'number' },
          { name: 'proposed', type: 'number' },
          { name: 'submitted', type: 'number' },
          { name: 'approved', type: 'number' },
          { name: 'committed', type: 'number' },
          { name: 'scopeOfWork' },
          { name: 'note' },
          { name: 'createdAt', type: 'date_time' },
          { name: 'updatedAt', type: 'date_time' }
        ]
      end
    },

    cost_attachment: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'folderId' },
          { name: 'urn' },
          { name: 'type' },
          { name: 'name' },
          { name: 'associationId', label: 'Object ID' },
          { name: 'associationType', label: 'Object Type' },
          { name: 'createdAt', type: 'date_time' },
          { name: 'updatedAt', type: 'date_time' }
        ]
      end
    },

    cost_document: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'templateId' },
          { name: 'recipientId' },
          { name: 'signedBy' },
          { name: 'urn' },
          { name: 'signedUrn' },
          { name: 'status' },
          { name: 'jobId' },
          { name: 'errorInfo', type: 'object', properties: [
            { name: 'code' },
            { name: 'message' },
            { name: 'detail' }
          ]},
          { name: 'associationId', label: 'Object ID' },
          { name: 'associationType', label: 'Object Type' },
          { name: 'createdAt', type: 'date_time' },
          { name: 'updatedAt', type: 'date_time' }
        ]
      end
    },

    cost_file_packages: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'recipient' },
          { name: 'urn' },
          { name: 'errorInfo', type: 'object', properties: [
            { name: 'code' },
            { name: 'message' },
            { name: 'detail' }
          ]},
          { name: 'items', type: 'array', of: 'object', properties: [
            { name: 'id' },
            { name: 'urn' },
            { name: 'name' },
            { name: 'type' },
            { name: 'createdAt', type: 'date_time' },
            { name: 'updatedAt', type: 'date_time' }
          ]},
          { name: 'createdAt', type: 'date_time' },
          { name: 'updatedAt', type: 'date_time' }
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
            hint: 'Base URI is https://developer.api.autodesk.com - path will be appended to this URI. Use absolute URI to override this base URI.'
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
                        properties: call('make_schema_builder_fields_sticky', input_schema)
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
      description: "Custom <span class='provider'>action</span> in <span class='provider'>BIM 360</span>",

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
        if %w[get post patch delete].exclude?(input['verb'])
          error("#{input['verb']} not supported")
        end
        data = input.dig('input', 'data').presence || {}
        case input['verb']
        when 'get'
          response = get(input['path'], data).
                       after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message}: #{body}")
                       end.compact
          if response.is_a?(Array)
            array_name = parse_json(input['output'] || '[]').dig(0, 'name') || 'array'
            { array_name.to_s => response }
          elsif response.is_a?(Hash)
            response
          else
            error('API response is not a JSON')
          end
        when 'post'
          post(input['path'], data).after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.compact
        when 'patch'
          patch(input['path'], data).after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.compact
        when 'delete'
          delete(input['path'], data).after_error_response(/.*/) do |_code, body, _header, message|
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

      description: 'Search <span class="provider">issues</span> in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'Retrieves information about all the BIM 360 issues in a project, including details about their associated comments and attachments.'
      },

      input_fields: lambda do |object_definitions|
        object_definitions['search_criteria']
      end,

      execute: lambda do |_connection, input|
        filter_criteria = call('format_search', input.except('hub_id', 'project_id'))
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")&.dig('data', 'relationships', 'issues', 'data', 'id') || {}
        issues = if container_id.present?
                   get("/issues/v1/containers/#{container_id}/quality-issues", filter_criteria)['data']&.each do |issue|
                     call(:format_output_response, issue['attributes'], %w(permitted_statuses permitted_actions permitted_attributes custom_attributes trades))
                     issue
                   end
                 end
        { issues: issues }&.merge({ hub_id: input['hub_id'], container_id: container_id, project_id: input['project_id'] })
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
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")&.dig('data', 'relationships', 'issues', 'data', 'id') || {}
        { issues: get("/issues/v1/containers/#{container_id}/quality-issues?page[limit]=1")&.dig('data', 0) || {} }
      end

    },

    create_issue_in_project: {
      title: 'Create issue in a project',

      description: 'Create <span class="provider">issue</span> in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'Adds a BIM 360 issue to a project. You can create both document-related (pushpin) issues, and project-related issues.'
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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
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
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          { name: 'ng_issue_type_id',
            label: 'Issue type',
            control_type: 'select',
            pick_list: 'issue_type',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            optional: false,
            toggle_hint: 'Select issue type',
            toggle_field: {
              name: 'ng_issue_type_id',
              label: 'Issue type ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter issue type ID',
              hint: 'The ID of the issue type for example, <b>2e310a74-90e1-484a-aa87-9e9205ec2372</b>.'
            }
          },
          { name: 'ng_issue_subtype_id',
            label: 'Issue subtype',
            control_type: 'select',
            pick_list: 'issue_sub_type',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id', ng_issue_type_id: 'ng_issue_type_id' },
            optional: false,
            toggle_hint: 'Select issue subtype',
            toggle_field: {
              name: 'ng_issue_subtype_id',
              label: 'Issue subtype ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter issue subtype ID',
              hint: 'The ID of the issue subtype for example, <b>ac0c58ec-cac0-4fea-a555-ecc97fa1bc1a</b>.'
            }
          }
        ].concat(object_definitions['create_issue'].required('title'))
      end,

      execute: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")&.dig('data', 'relationships', 'issues', 'data', 'id')
        response = if container_id.present?
                     post("/issues/v1/containers/#{container_id}/quality-issues").
                       payload(data: { type: 'quality_issues', attributes: input.except('hub_id', 'project_id') }).
                       headers('Content-Type': 'application/vnd.api+json').after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message}: #{body}")
                       end['data']&.merge({ container_id: container_id, hub_id: input['hub_id'] })
                   end
        call("format_output_response", response&.[]('attributes'), %w(permitted_statuses permitted_actions permitted_attributes custom_attributes trades))
        response
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ].concat(object_definitions['issue'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects")&.dig('data', 0, 'relationships', 'issues', 'data', 'id') || {}
        get("/issues/v1/containers/#{container_id}/quality-issues?page[limit]=1")&.dig('data', 0) || {}
      end
    },

    update_issue_in_project: {
      title: 'Update issue in a project',

      description: 'Update <span class="provider">issue</span> in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'BIM 360 issues are managed either in the BIM 360 Document Management module or the BIM 360 Field Management module.</br>The following users can update issues:' \
        '</br><ul>Project admins</ul></ul>Project members who are assigned either create, view and create, or full control Field Management permissions.</ul>'
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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
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
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'id', label: 'Issue ID',
            optional: false
          },
          { name: 'ng_issue_type_id',
            label: 'Issue type',
            control_type: 'select',
            pick_list: 'issue_type',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            optional: true,
            hint: "Within BIM 360, once an Issue has been created, its Issue type cannot be updated." \
            " Only issues in <b>draft</b> mode can have its type updated.",
            toggle_hint: 'Select issue type',
            toggle_field: {
              name: 'ng_issue_type_id',
              label: 'Issue type ID',
              type: 'string',
              control_type: 'text',
              change_on_blur: true,
              toggle_hint: 'Enter issue type ID',
              hint: "The ID of the issue type for example, <b>2e310a74-90e1-484a-aa87-9e9205ec2372</b>. Within BIM 360, " \
              "once an Issue has been created, its Issue type cannot be updated." \
              " Only issues in <b>draft</b> mode can have its type updated."
            }
          },
          { name: 'ng_issue_subtype_id',
            label: 'Issue subtype',
            control_type: 'select',
            pick_list: 'issue_sub_type',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id', ng_issue_type_id: 'ng_issue_type_id' },
            optional: false,
            toggle_hint: 'Select issue subtype',
            toggle_field: {
              name: 'ng_issue_subtype_id',
              label: 'Issue subtype ID',
              type: 'string',
              control_type: 'text',
              change_on_blur: true,
              toggle_hint: 'Enter issue subtype ID',
              hint: 'The ID of the issue subtype for example, <b>ac0c58ec-cac0-4fea-a555-ecc97fa1bc1a</b>.'
            }
          }
        ].concat(object_definitions['update_issue'].ignored('id', 'ng_issue_type_id', 'ng_issue_subtype_id'))
      end,

      execute: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")&.dig('data', 'relationships', 'issues', 'data', 'id')
        response = if container_id.present?
                     patch("/issues/v1/containers/#{container_id}/quality-issues/#{input['id']}").
                       payload(data: { id: input['id'], type: 'quality_issues', attributes: input.except('hub_id', 'project_id', 'id') }).
                       headers('Content-Type': 'application/vnd.api+json').after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message}: #{body}")
                       end['data']&.merge({ hub_id: input['hub_id'], container_id: container_id })
                   end
        call("format_output_response", response&.[]('attributes'), %w(permitted_statuses permitted_actions permitted_attributes custom_attributes trades))
        response
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ].concat(object_definitions['issue'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects")&.dig('data', 0, 'relationships', 'issues', 'data', 'id') || {}
        get("/issues/v1/containers/#{container_id}/quality-issues?page[limit]=1")&.dig('data', 0) || {}
      end
    },

    get_issue_in_project: {
      title: 'Get issue in a project',

      description: 'Get <span class="provider">issue</span> in a project in <span class="provider">BIM 360</span>',

      help: 'Retrieves detailed information about a single BIM 360 issue.',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          { name: 'issue_id',
            optional: false,
            hint: 'Get ID from url of the issue page.'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")&.dig('data', 'relationships', 'issues', 'data', 'id')
        response = if container_id.present?
                     get("/issues/v1/containers/#{container_id}/quality-issues/#{input['issue_id']}").after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end['data'].merge(hub_id: input['hub_id'], container_id: container_id)
                   end
        call("format_output_response", response&.[]('attributes'), %w(permitted_statuses permitted_actions permitted_attributes custom_attributes trades))
        response
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ].concat(object_definitions['issue'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects")&.dig('data', 0, 'relationships', 'issues', 'data', 'id') || {}
        get("/issues/v1/containers/#{container_id}/quality-issues?page[limit]=1")&.dig('data', 0) || {}
      end
    },

    get_project_details: {
      title: 'Get project details',

      description: 'Get <span class="provider">project</span> details in <span class="provider">BIM 360</span>',
      help: 'Retrieves detailed information about a project.',

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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          }
        ]
      end,

      execute: lambda do |_connection, input|
        response = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}").after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end['data']
        call("format_output_response", response['attributes'], %w(scopes))
        response
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['project']
      end,

      sample_output: lambda do |_connection, _input|
        id = get('/project/v1/hubs')&.dig('data', 0, 'id')
        id.present? ? get("/project/v1/hubs/#{id}/projects")&.dig('data', 0) : {}
      end
    },

    download_drawing_export: {
      title: 'Download drawing export in a project',

      description: 'Download <span class="provider">drawing export</span> in a project in <span class="provider">BIM 360</span>',

      input_fields: lambda do |_object_definitions|
        [
          { name: 'export_link', label: 'Export link', optional: false }
        ]
      end,

      execute: lambda do |_connection, input|
        file_content = get(input['export_link']).headers('Accept-Encoding': 'Accept-Encoding:gzip').response_format_raw.
                         after_error_response(/.*/) do |_code, body, _header, message|
                           error("#{message}: #{body}")
                         end
        { content: file_content }
      end,

      output_fields: lambda do |_object_definitions|
        [{ name: 'content' }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          "content": "<file-content>"
        }
      end
    },

    export_project_plan: {
      title: 'Export drawing in a project',

      description: 'Export <span class="provider">drawing</span> in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'Note that you can only export a page from a PDF file that was uploaded to the Plans folder or to a folder nested under the ' \
        'Plans folder. BIM 360 Document Management splits these files into separate pages (sheets) when they are uploaded, and assigns a separate ID to each page.'
      },

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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          { name: 'folder_id',
            label: 'Folder name',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select folder',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            tree_options: { selectable_folder: true },
            pick_list: :folders_list,
            optional: false,
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              label: 'Folder ID',
              toggle_hint: 'Enter folder ID',
              hint: 'Get ID from url of the folder page.'
            } },
          {
            name: 'item_id',
            label: 'File name',
            control_type: 'select',
            pick_list: 'folder_items',
            pick_list_params: { project_id: 'project_id', folder_id: 'folder_id' },
            optional: false,
            toggle_hint: 'Select file',
            toggle_field: {
              name: 'item_id',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              label: 'File ID',
              toggle_hint: 'Enter file ID',
              hint: 'Use file/item ID.'
            }
          },
          {
            name: 'version_number',
            control_type: 'select',
            pick_list: 'item_versions',
            sticky: true,
            pick_list_params: { project_id: 'project_id', item_id: 'item_id' },
            hint: "Latest version will be used if no value is selected.",
            optional: true,
            toggle_hint: 'Select version',
            toggle_field: {
              name: 'version_number',
              label: 'Version number',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              optional: true,
              toggle_hint: 'Enter version number',
              hint: 'Latest version will be used if no value is specified.'
            }
          },
          {
            name: 'includeMarkups', control_type: 'checkbox',
            type: 'boolean', label: 'Include markups',
            sticky: true,
            hint: 'Include markups in the export',
            toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'includeMarkups',
              label: 'Include markups',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter value to include markups',
              hint: 'Allowed values are <b>true, false</b>.'
            }
          },
          {
            name: 'includeHyperlinks', control_type: 'checkbox',
            type: 'boolean', label: 'Include hyperlinks',
            sticky: true,
            hint: 'Include hyperlinks in the export',
            toggle_hint: 'Select from options list',
            toggle_field: {
              name: 'includeHyperlinks',
              label: 'Include hyperlinks',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter value to include hyperlinks',
              hint: 'Allowed values are <b>true, false</b>.'
            }
          }
        ],

      execute: lambda do |_connection, input|
        #  Step 1 find the version id of the file to export
        version_number = input['version_number'] || get("/data/v1/projects/#{input['project_id']}/items/#{input['item_id']}/versions")&.dig('data', 0, 'id')
        version_url = version_number.encode_url.gsub("+", "%20")
        # Step 2 upload the file
        # create payload with `true`/`false` booleansversion_number
        input_payload = { 'version_number' => false }
        input.except('hub_id', 'folder_id', 'project_id', 'item_id', 'version_number')&.map do |key, value|
          input_payload[key] = value.is_true?
        end
        post("/bim360/docs/v1/projects/#{input['project_id'].gsub('b.', '')}/versions/#{version_url}/exports").payload(input_payload).
          headers('content-type': 'application/json').after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.merge({ hub_id: input['hub_id'], project_id: input['project_id'], item_id: input['item_id'] })
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

      description: 'Get <span class="provider">folder info</span> in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'Returns the folder by ID for any folder within a given project. All folders or sub-folders within a project are associated' \
        ' with their own unique ID, including the root folder.'
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
              change_on_blur: true,
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
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
              change_on_blur: true,
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          { name: 'folder_id',
            label: 'Folder',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select folder',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            tree_options: { selectable_folder: true },
            pick_list: :folders_list,
            optional: false,
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              control_type: 'text',
              label: 'Folder ID',
              change_on_blur: true,
              toggle_hint: 'Enter folder ID',
              hint: 'Get ID from url of the folder page.'
            } }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/data/v1/projects/#{input['project_id']}/folders/#{input['folder_id']}")['data']&.
          merge({ hub_id: input['hub_id'], project_id: input['project_id'], folder_id: input['folder_id'] })
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' },
          { name: 'folder_id' }
        ].concat(object_definitions['folder_file'])
      end,

      sample_output: lambda do |_connection, input|
        get("project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}/topFolders?filter[type]=folders")&.dig('data', 0) || {}
      end
    },

    get_folder_contents: {
      description: 'Get <span class="provider">folder</span> contents in <span class="provider">BIM 360</span>',

      help: {
        body: 'Returns a collection of items and folders within a folder. Items represent word documents, fusion design files, drawings, spreadsheets, etc.'
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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
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
              change_on_blur: true,
              control_type: 'text',
              label: 'Folder ID',
              toggle_hint: 'Enter Folder ID',
              hint: 'Get ID from url of the folder page.'
            } },
          { name: 'filters',
            label: 'Filters',
            control_type: 'text',
            sticky: true,
            hint: 'Enter filters for the search. A list of filters can be' \
            ' found <a href="https://forge.autodesk.com/en/docs/data/v2/' \
            'developers_guide/filtering" target_blank">here</a>.' }
        ]
      end,

      execute: lambda do |_connection, input|
        get("/data/v1/projects/#{input['project_id']}/folders/#{input['folder_id']}/contents?#{input['filters']}")&.
          merge({ hub_id: input['hub_id'], project_id: input['project_id'], folder_id: input['folder_id'] })
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
        folder_id = get("project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}/topFolders?filter[type]=folders")&.dig('data', 0, 'id') || {}
        folder_id.present? ? get("/data/v1/projects/#{input['project_id']}/folders/#{folder_id}/contents") : {}
      end
    },

    get_document_in_project: {
      title: 'Get document in a project',

      description: 'Get <span class="provider">document</span> in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'Retrieves metadata for a specified item. Items represent word documents, fusion design files, drawings, spreadsheets, etc.'
      },

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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          { name: 'folder_id',
            label: 'Folder',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select folder',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            tree_options: { selectable_folder: true },
            pick_list: :folders_list,
            optional: false,
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              control_type: 'text',
              label: 'Folder ID',
              change_on_blur: true,
              toggle_hint: 'Enter folder ID',
              hint: 'Get ID from url of the folder page.'
            } },
          { name: 'item_id',
            label: 'File name',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select Item',
            pick_list: :folder_items,
            pick_list_params: { project_id: 'project_id', folder_id: 'folder_id' },
            optional: false,
            toggle_field: {
              name: 'item_id',
              type: 'string',
              control_type: 'text',
              change_on_blur: true,
              label: 'File ID',
              toggle_hint: 'Enter file ID',
              hint: 'Provide file ID.'
            } }
        ],

      execute: lambda do |_connection, input|
        get("/data/v1/projects/#{input['project_id']}/items/#{input['item_id']}")&.merge({ project_id: input['project_id'], hub_id: input['hub_id'] })
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' }
        ].concat(object_definitions['item'])
      end,

      sample_output: lambda do |_connection, input|
        get("/data/v1/projects/#{input['project_id']}/items/#{input['item_id']}")
      end
    },

    get_drawing_export_status: {
      title: 'Get drawing export status in a project',

      description: 'Get <span class="provider">drawing export status</span> in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action returns the status of a PDF export job, as well  as data you need to download the exported file when the export is complete.'
      },

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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'folder_id',
            label: 'Folder name',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select folder',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            tree_options: { selectable_folder: true },
            pick_list: :folders_list,
            optional: false,
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              label: 'Folder ID',
              toggle_hint: 'Enter folder ID',
              hint: 'Get ID from url of the folder page.'
            }
          },
          {
            name: 'item_id',
            label: 'File name',
            control_type: 'select',
            pick_list: 'folder_items',
            pick_list_params: { project_id: 'project_id', folder_id: 'folder_id' },
            optional: false,
            toggle_hint: 'Select file',
            toggle_field: {
              name: 'item_id',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              label: 'File ID',
              toggle_hint: 'Enter file ID',
              hint: 'Use file or item ID.'
            }
          },
          {
            name: 'version_number',
            control_type: 'select',
            pick_list: 'item_versions',
            sticky: true,
            pick_list_params: { project_id: 'project_id', item_id: 'item_id' },
            hint: "Latest version will be used if no value is selected.",
            optional: true,
            toggle_hint: 'Select version',
            toggle_field: {
              name: 'version_number',
              label: 'Version number',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              optional: true,
              toggle_hint: 'Enter version number',
              hint: 'Latest version will be used if no value is specified.'
            }
          }
        ],

      input_fields: lambda do |_object_definitions|
        [
          { name: 'export_id', optional: false }
        ]
      end,

      execute: lambda do |_connection, input|
        version_number = input['version_number'] || get("/data/v1/projects/#{input['project_id']}/items/#{input['item_id']}/versions")&.dig('data', 0, 'id')
        version_url = version_number.split('?').first.encode_url.gsub("+", "%20")
        # version_url = version_number.encode_url
        project_id = input['project_id'].split('.').last
        get("/bim360/docs/v1/projects/#{project_id}/versions/#{version_url}/exports/#{input['export_id']}").
          merge(hub_id: input['hub_id'], project_id: input['project_id'], item_id: input['item_id'])
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
      title: 'Download document in a project',

      description: 'Download <span class="provider">document</span> in a project in <span class="provider">BIM 360</span>',

      help: 'Retrieve the content of a specific document in the project folder. This content can be used to upload the attachment into another application in subsequent recipe steps.',

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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
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
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          { name: 'folder_id',
            label: 'Folder name',
            control_type: 'tree',
            hint: 'Select folder',
            toggle_hint: 'Select folder',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            optional: false,
            tree_options: { selectable_folder: true },
            pick_list: :folders_list,
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              control_type: 'text',
              change_on_blur: true,
              label: 'Folder ID',
              toggle_hint: 'Enter folder ID',
              hint: 'Get ID from url of the folder page.'
            } },
          { name: 'item_id',
            label: 'File',
            control_type: 'tree',
            hint: 'Select file',
            toggle_hint: 'Select file',
            pick_list: :folder_items,
            pick_list_params: { project_id: 'project_id', folder_id: 'folder_id' },
            optional: false,
            toggle_field: {
              name: 'item_id',
              type: 'string',
              control_type: 'text',
              change_on_blur: true,
              label: 'File ID',
              toggle_hint: 'Enter file ID',
              hint: 'Get file ID from url of the file page.'
            } }
        ],

      execute: lambda do |_connection, input|
        # 1 find the storage location of the item
        file_url = get("/data/v1/projects/#{input['project_id']}/items/#{input['item_id']}")&.
                     dig('included', 0, 'relationships', 'storage', 'meta', 'link', 'href')
        if file_url.present?
          { content: get(file_url).headers('Accept-Encoding': 'Accept-Encoding:gzip').
                       response_format_raw.
                       after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message}: #{body}")
                       end }
        else
          error('File does not exist')
        end
      end,

      output_fields: lambda do |_object_definitions|
        [{ name: 'content' }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          "content": "<file-content>"
        }
      end
    },

    upload_document_to_project: {
      title: 'Upload document to a project',

      description: 'Upload <span class="provider">document</span> to a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'Note that you cannot upload documents to the root folder in BIM 360 Docs; you can only upload documents to the Project Files ' \
        'folder or to a folder nested under the Project Files folder'
      },

      config_fields: [
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
            change_on_blur: true,
            control_type: 'text',
            toggle_hint: 'Enter hub ID',
            hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
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
            change_on_blur: true,
            toggle_hint: 'Enter project ID',
            hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
          }
        },
        { name: 'folder_id',
          label: 'Folder name',
          control_type: 'tree',
          hint: 'Select folder',
          toggle_hint: 'Select folder',
          pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
          tree_options: { selectable_folder: true },
          pick_list: :folders_list,
          optional: false,
          toggle_field: {
            name: 'folder_id',
            type: 'string',
            control_type: 'text',
            label: 'Folder ID',
            change_on_blur: true,
            toggle_hint: 'Enter folder ID',
            hint: 'Use folder ID.'
          } }
      ],

      input_fields: lambda do |_object_definitions|
        [
          { name: 'file_name', optional: false, label: 'File name',
            hint: 'File name should include extension of the file. e.g. <b>my_file.jpg</b>. The name of the file (1-255 characters). ' \
            'Reserved characters: <, >, :, ", /, \, |, ?, *, `, \n, \r, \t, \0, \f, ¢, ™, $, ®' },
          { name: 'file_content', optional: false },
          { name: 'file_extension', control_type: 'select',
            pick_list: 'file_types',
            optional: false,
            toggle_hint: 'Select file extension',
            toggle_field: {
              name: 'file_extension',
              type: 'string',
              control_type: 'text',
              label: 'File extension',
              toggle_hint: 'Enter file extension value',
              hint: 'Only relevant for creating files - the type of file extension. <br/>. For BIM 360 Docs files, use ' \
              'items:autodesk.bim360:File.<br/>For all other services, use items:autodesk.core:File.'
            } },
          { name: 'version_type', label: 'Type of version',
            hint: 'Only relevant for creating files - the type of version.',
            control_type: 'select',
            pick_list: 'version_types',
            optional: false,
            toggle_hint: 'Select version type',
            toggle_field: {
              name: 'version_type',
              label: 'Type of version',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter version type value',
              hint: 'Only relevant for creating files - the type of version.<br/>For BIM 360 Docs files, use versions:autodesk.bim360:File' \
              '<br/>For A360 composite design files, use versions:autodesk.a360:CompositeDesign<br/>' \
              'For A360 Personal, Fusion Team, or BIM 360 Team files, use versions:autodesk.core:File.'
            } },
          { name: 'extension_type_version',
            hint: 'The version of the version extension type. The current version is 1.0 ' }

        ]
      end,

      execute: lambda do |_connection, input|
        # 1 create storage location
        hub_id = input.delete('hub_id')
        project_id = input.delete('project_id').gsub('b:', '')
        response_storage = post("https://developer.api.autodesk.com/data/v1/projects/#{project_id}/storage").
                             headers('Content-Type' => 'application/vnd.api+json', 'Accept' => 'application/vnd.api+json').
                             payload('jsonapi' => { 'version' => '1.0' },
                                     'data' => {
                                       'type' => 'objects',
                                       'attributes' => { 'name' => input['file_name'] },
                                       'relationships' => {
                                         'target' => {
                                           'data' => { 'type' => 'folders', 'id' => input['folder_id'] }
                                         }
                                       }
                                     }).
                             after_error_response(/.*/) do |_code, body, _header, message|
                               error("#{message}: #{body}")
                             end
        object_id = response_storage&.dig('data', 'id')

        # 2 Upload file to storage location
        bucket_key = object_id.split('/').first.split('object:').last
        object_name = object_id.split('/').last
        response = put("https://developer.api.autodesk.com/oss/v2/buckets/#{bucket_key}/objects/#{object_name}").
                     request_body(input['file_content']).
                     headers('Content-Type' => 'application/octet-stream').
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end
        # 3 create a first version of the File
        # folder_urn = get("/data/v1/projects/#{input['project_id']}/folders" \
        #                  "/#{input['folder_id']}")['data']

        post("/data/v1/projects/#{project_id}/items").
          payload('jsonapi' => { 'version' => '1.0' },
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
                          'type' => input['version_type'],
                          'version' => input['extension_type_version'] || '1.0'
                        }
                      },
                      'relationships' => {
                        'storage' => {
                          'data' => {
                            'type' => 'objects',
                            'id' => response['objectId']
                          }
                        }
                      }
                    }
                  ]).
          headers('Content-Type' => 'application/vnd.api+json', 'Accept' => 'application/vnd.api+json').
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.dig('data')&.merge({ hub_id: hub_id, project_id: project_id })
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' }
        ].concat(object_definitions['folder_file'])
      end
    },

    search_budgets_in_project: {
      title: 'Search budgets in a project',

      description: 'Search <span class="provider">budgets</span> in a project in' \
      ' <span class="provider">BIM 360</span>',

      help: {
        body: 'This action searches for budgets in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'rootId',
            hint: 'Filter by related subitems for the given root item ID.' \
            ' Separate multiple IDs with commas.'
          },
          {
            name: 'externalSystem',
            hint: 'Filter by name of source if used in system integration.'
          },
          {
            name: 'externalId',
            hint: 'Filter by item ID in the external system. ' \
            'Separate multiple IDs with commas.'
          },
          {
            name: 'code',
            hint: 'Filter by item code.'
          },
          {
            name: 'offset',
            type: 'number',
            hint: 'Number of items to skip before starting to collect the result set.'
          },
          {
            name: 'limit',
            type: 'number',
            hint: 'Number of items to return.'
          },
          {
            name: 'lastModifiedSince',
            hint: 'Filter to include only items updated since this datetime.',
            type: 'date_time'
          },
          {
            name: 'sort',
            hint: 'Order of items to sort. Each item can be followed by a direction modifier' \
            ' of either asc or desc. If no direction is specified then asc is assumed.'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        filter_criteria = call('format_cost_search', input.except('hub_id', 'project_id'))
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                       &.dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     get("/cost/v1/containers/#{container_id}/budgets", filter_criteria)
                     .after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end.merge(hub_id: input['hub_id'], container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat([
          { name: 'results', type: 'array', of: 'object', properties: object_definitions['budget'] },
          { name: 'pagination', type: 'object', properties: [
            { name: 'totalResults', type: 'number' },
            { name: 'limit', type: 'number' },
            { name: 'offset', type: 'number' }
          ]}
        ])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/budgets?limit=1") || {})
         .merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    get_budget_in_project: {
      title: 'Get budget in a project',

      description: 'Get <span class="provider">budget</span> in a project' \
      ' in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action returns a budget in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'budget_id',
            label: 'Budget ID',
            optional: false,
            sticky: true
          }
        ]
      end,

      execute: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     get("/cost/v1/containers/#{container_id}/budgets/#{input['budget_id']}")
                     .after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end.merge(hub_id: input['hub_id'], container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat(object_definitions['budget'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/budgets?limit=1") || {})
         .dig('results', 0).merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    create_budget_in_project: {
      title: 'Create budget in a project',

      description: 'Create <span class="provider">budget</span> in a ' \
      'project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action creates a budget in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'code',
            optional: false,
            sticky: true,
            hint: 'Unique code that is compliant with the budget code template' \
            ' defined by the project admin. Max length of 255 characters.'
          },
          {
            name: 'name',
            optional: false,
            sticky: true,
            hint: 'Name of the budget. Max length of 1024 characters.'
          },
          {
            name: 'parentId',
            sticky: true,
            hint: 'ID of the parent budget. Used only when creating sub-budgets.'
          },
          {
            name: 'quantity',
            sticky: true,
            type: 'integer',
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion',
            hint: 'Quantity of labor, material, etc, that is planned for a budget.'
          },
          {
            name: 'description',
            sticky: true,
            hint: 'Description of the budget.'
          },
          {
            name: 'unitPrice',
            sticky: true,
            type: 'integer',
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion',
            hint: 'Unit price of a budget.'
          },
          {
            name: 'unit',
            sticky: true,
            hint: 'Unit of measure used in the budget.'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        project_id = input.delete('project_id')

        container_id = get("/project/v1/hubs/#{hub_id}/projects/#{project_id}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     post("/cost/v1/containers/#{container_id}/budgets")
                     .payload(input)
                     .after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end.merge(hub_id: hub_id, container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat(object_definitions['budget'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
         .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/budgets?limit=1") || {})
         .dig('results', 0).merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    update_budget_in_project: {
      title: 'Update budget in a project',

      description: 'Update <span class="provider">budget</span> in a project' \
      ' in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action updates a budget in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'budgetId',
            optional: false,
            sticky: true,
            hint: 'ID of the budget to update.'
          },
          {
            name: 'name',
            sticky: true,
            hint: 'Name of the budget. Max length of 1024 characters.'
          },
          {
            name: 'code',
            sticky: true,
            hint: 'Unique code that is compliant with the budget code template ' \
            'defined by the project admin. Max length of 255 characters.'
          },
          {
            name: 'parentId',
            sticky: true,
            hint: 'ID of the parent budget. Used only when creating sub-budgets.'
          },
          {
            name: 'quantity',
            sticky: true,
            type: 'integer',
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion',
            hint: 'Quantity of labor, material, etc, that is planned for a budget.'
          },
          {
            name: 'description',
            sticky: true,
            hint: 'Description of the budget.'
          },
          {
            name: 'unitPrice',
            sticky: true,
            type: 'integer',
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion',
            hint: 'Unit price of a budget.'
          },
          {
            name: 'unit',
            sticky: true,
            hint: 'Unit of measure used in the budget.'
          },
          {
            name: 'actualCost',
            sticky: true,
            type: 'integer',
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion',
            hint: 'Total amount of actual cost of the budget.'
          },
          {
            name: 'adjustments',
            sticky: true,
            hint: 'Items to make and explain adjustments to actual cost ' \
            'amounts to make forecast more accurate.',
            type: 'object', properties: [
              { name: 'details', type: 'array', of: 'object', properties: [
                {
                  name: 'quantity',
                  sticky: true,
                  type: 'integer',
                  render_input: 'integer_conversion',
                  parse_output: 'integer_conversion',
                  hint: 'Quantity of actual adjustment.'
                },
                {
                  name: 'unitPrice',
                  sticky: true,
                  type: 'number',
                  type: 'integer',
                  render_input: 'integer_conversion',
                  parse_output: 'integer_conversion',
                  hint: 'Unit price of the actual adjustment.'
                },
                {
                  name: 'unit',
                  sticky: true,
                  hint: 'Unit of measurement of the actual adjustment.'
                }
              ]}
            ]
          }
        ]
      end,

      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        project_id = input.delete('project_id')
        budget_id = input.delete('budgetId')

        container_id = get("/project/v1/hubs/#{hub_id}/projects/#{project_id}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     patch("/cost/v1/containers/#{container_id}/budgets/#{budget_id}")
                      .headers("Content-Type": "application/json")
                      .payload(input)
                      .after_error_response(/.*/) do |_code, body, _header, message|
                        error("#{message}: #{body}")
                      end.merge(hub_id: hub_id, container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat(object_definitions['budget'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/budgets?limit=1") || {})
         .dig('results', 0).merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    search_contracts_in_project: {
      title: 'Search contracts in a project',

      description: 'Search <span class="provider">contracts</span> in a ' \
      'project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action searches for contracts in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'externalSystem',
            hint: 'Filter by name of source if used in system integration.'
          },
          {
            name: 'externalId',
            hint: 'Filter by item ID in the external system.' \
            ' Separate multiple IDs with commas.'
          },
          {
            name: 'code',
            hint: 'Filter by item code.'
          },
          {
            name: 'include',
            hint: 'Resources to include in the response.',
            control_type: 'multiselect',
            pick_list: [
              ['Budgets', 'budgets'],
              ['Attributes', 'attributes']
            ],
            delimiter: ','
          },
          {
            name: 'offset',
            type: 'number',
            hint: 'Number of items to skip before starting to ' \
            'collect the result set.'
          },
          {
            name: 'limit',
            type: 'number',
            hint: 'Number of items to return.'
          },
          {
            name: 'lastModifiedSince',
            hint: 'Filter to include only items updated since this datetime.',
            type: 'date_time'
          },
          {
            name: 'lastModifiedSince',
            hint: 'Filter to include only items updated since this datetime.',
            type: 'date_time'
          },
          {
            name: 'lastModifiedSince',
            hint: 'Filter to include only items updated since this datetime.',
            type: 'date_time'
          },
          {
            name: 'sort',
            hint: 'Order of items to sort. Each item can be followed by a ' \
            'direction modifier of either asc or desc. If no direction is ' \
            'specified then asc is assumed.'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        filter_criteria = call('format_cost_search', input.except('hub_id', 'project_id'))

        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     get("/cost/v1/containers/#{container_id}/contracts", filter_criteria)
                      .after_error_response(/.*/) do |_code, body, _header, message|
                        error("#{message}: #{body}")
                      end.merge(hub_id: input['hub_id'], container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat([
          { name: 'results', type: 'array', of: 'object', properties: object_definitions['contract'] },
          { name: 'pagination', type: 'object', properties: [
            { name: 'totalResults', type: 'number' },
            { name: 'limit', type: 'number' },
            { name: 'offset', type: 'number' },
            { name: 'nextUrl' }
          ]}
        ])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                       .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/contracts?limit=1") || {})
         .merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    get_contract_in_project: {
      title: 'Get contract in a project',

      description: 'Get <span class="provider">contract</span> in a ' \
      'project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action returns a contract in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'contract_id',
            label: 'Contract ID',
            optional: false,
            sticky: true
          }
        ]
      end,

      execute: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                       .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     get("/cost/v1/containers/#{container_id}/contracts/#{input['contract_id']}")
                     .after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end.merge(hub_id: input['hub_id'], container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat(object_definitions['contract'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
        .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/contracts?limit=1") || {})
        .dig('results', 0).merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    create_contract_in_project: {
      title: 'Create contract in a project',

      description: 'Create <span class="provider">contract</span> in a ' \
      'project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action creates a contract in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'code',
            optional: false,
            sticky: true,
            hint: 'Code of the contract. Max lenght of 255 characters.'
          },
          {
            name: 'name',
            optional: false,
            sticky: true,
            hint: 'Name of the contract. Max length of 1024 characters.'
          },
          {
            name: 'description',
            sticky: true,
            hint: 'Description of the contract. Max length of 2048 characters.'
          },
          {
            name: 'companyId',
            sticky: true,
            hint: 'ID of the supplier company managed by the BIM 360 admin.'
          },
          {
            name: 'type',
            sticky: true,
            hint: 'Type of the contract as specified by the project admin.'
          },
          {
            name: 'contactId',
            sticky: true,
            hint: 'ID of the user in BIM 360 for the contact of the supplier.'
          },
          {
            name: 'signedBy',
            sticky: true,
            hint: 'ID of the user in BIM 360 who signed the contract.'
          },
          {
            name: 'ownerId',
            sticky: true,
            hint: 'ID of the user in BIM 360 who is responsible for the purchase.'
          },
          {
            name: 'status',
            sticky: true,
            control_type: 'select',
            pick_list: 'contract_status',
            toggle_hint: 'Select status',
            toggle_field: {
              name: 'status',
              label: 'Status',
              change_on_blur: true,
              control_type: 'text',
              type: 'string',
              toggle_hint: 'Enter status',
              hint: 'Status of the contract. Possible values include:' \
              ' draft, open, sent, executed, closed.'
            }
          }
        ]
      end,

      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        project_id = input.delete('project_id')

        container_id = get("/project/v1/hubs/#{hub_id}/projects/#{project_id}")
                       .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     post("/cost/v1/containers/#{container_id}/contracts")
                      .payload(input)
                      .after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end.merge(hub_id: hub_id, container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat(object_definitions['contract'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                       .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/contracts?limit=1") || {})
         .dig('results', 0).merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    update_contract_in_project: {
      title: 'Update contract in a project',

      description: 'Update <span class="provider">contract</span> in a ' \
      'project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action updates a contract in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'contractId',
            optional: false,
            sticky: true,
            hint: 'ID of the budget to update.'
          },
          {
            name: 'code',
            sticky: true,
            hint: 'Code of the contract. Max lenght of 255 characters.'
          },
          {
            name: 'name',
            sticky: true,
            hint: 'Name of the contract. Max length of 1024 characters.'
          },
          {
            name: 'description',
            sticky: true,
            hint: 'Description of the contract. Max length of 2048 characters.'
          },
          {
            name: 'companyId',
            sticky: true,
            hint: 'ID of the supplier company managed by the BIM 360 admin.'
          },
          {
            name: 'type',
            sticky: true,
            hint: 'Type of the contract as specified by the project admin.'
          },
          {
            name: 'contactId',
            sticky: true,
            hint: 'ID of the user in BIM 360 for the contact of the supplier.'
          },
          {
            name: 'signedBy',
            sticky: true,
            hint: 'ID of the user in BIM 360 who signed the contract.'
          },
          {
            name: 'ownerId',
            sticky: true,
            hint: 'ID of the user in BIM 360 who is responsible for the purchase.'
          },
          {
            name: 'status',
            sticky: true,
            control_type: 'select',
            pick_list: 'contract_status',
            toggle_hint: 'Select status',
            toggle_field: {
              name: 'status',
              label: 'Status',
              change_on_blur: true,
              control_type: 'text',
              type: 'string',
              toggle_hint: 'Enter status',
              hint: 'Status of the contract. Possible values include:' \
              ' draft, open, sent, executed, closed.'
            }
          }
        ]
      end,

      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        project_id = input.delete('project_id')
        contract_id = input.delete('contractId')

        container_id = get("/project/v1/hubs/#{hub_id}/projects/#{project_id}")
                       .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     patch("/cost/v1/containers/#{container_id}/contracts/#{contract_id}")
                      .payload(input)
                      .after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end.merge(hub_id: hub_id, container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat(object_definitions['contract'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                       .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/contracts?limit=1") || {})
         .dig('results', 0).merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    search_change_orders_in_project: {
      title: 'Search change orders in a project',

      description: 'Search <span class="provider">change orders</span>' \
      ' in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action searches for change orders in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'type',
            label: 'Change Order Type',
            control_type: 'select',
            pick_list: 'change_order_types',
            optional: false,
            sticky: true,
            toggle_hint: 'Select type',
            toggle_field: {
              name: 'type',
              label: 'Change Order Type',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter type',
              hint: 'Enter the change order type name. ' \
              'Possible values are: pco, rfq, rco, oco, sco.'
            }
          },
          {
            name: 'externalSystem',
            label: 'External System',
            hint: 'Filter by name of source if used in system integration.'
          },
          {
            name: 'externalId',
            label: 'External ID',
            hint: 'Filter by item ID in the external system. ' \
            'Separate multiple IDs with commas.'
          },
          {
            name: 'contractId',
            label: 'Contract ID',
            hint: 'Filter by contract ID. ' \
            'Separate multiple IDs with commas.'
          },
          {
            name: 'mainContractId',
            label: 'Main Contract ID',
            hint: 'Filter by main contract ID. Separate multiple IDs with commas.'
          },
          {
            name: 'budgetStatus',
            label: 'Budget Status',
            hint: 'Filter by budget status code. Separate multiple codes with commas.'
          },
          {
            name: 'costStatus',
            label: 'Cost Status',
            hint: 'Filter by cost status code. Separate multiple codes with commas.'
          },
          {
            name: 'include',
            hint: 'Resources to include in the response.',
            control_type: 'multiselect',
            pick_list: [
              ['Cost Items', 'costItems'],
              ['Attributes', 'attributes']
            ],
            delimiter: ','
          },
          {
            name: 'offset',
            type: 'number',
            hint: 'Number of items to skip before starting to collect the result set.'
          },
          {
            name: 'limit',
            type: 'number',
            hint: 'Number of items to return.'
          },
          {
            name: 'lastModifiedSince',
            hint: 'Filter to include only items updated since this datetime.',
            type: 'date_time'
          },
          {
            name: 'lastModifiedSince',
            hint: 'Filter to include only items updated since this datetime.',
            type: 'date_time'
          },
          {
            name: 'sort',
            hint: 'Order of items to sort. Each item can be followed by a direction modifier' \
            ' of either asc or desc. If no direction is specified then asc is assumed.'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        filter_criteria = call('format_cost_search', input.except('hub_id', 'project_id'))

        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                       .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     get("/cost/v1/containers/#{container_id}/change-orders/#{input['type']}", filter_criteria)
                      .after_error_response(/.*/) do |_code, body, _header, message|
                        error("#{message}: #{body}")
                      end.merge(hub_id: input['hub_id'], container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat([
          { name: 'results', type: 'array', of: 'object', properties: object_definitions['change_order'] },
          { name: 'pagination', type: 'object', properties: [
            { name: 'totalResults', type: 'number' },
            { name: 'limit', type: 'number' },
            { name: 'offset', type: 'number' },
            { name: 'nextUrl' }
          ]}
        ])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")&.dig('data', 'relationships', 'cost', 'data', 'id') || {}
        (get("/cost/v1/containers/#{container_id}/change-orders/pco?limit=1") || {})&.merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    get_change_order_in_project: {
      title: 'Get change order in a project',

      description: 'Get <span class="provider">change order</span>' \
      ' in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action returns a change order in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'type',
            label: 'Change Order Type',
            control_type: 'select',
            pick_list: 'change_order_types',
            optional: false,
            sticky: true,
            toggle_hint: 'Select type',
            toggle_field: {
              name: 'type',
              label: 'Change Order Type',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter type name',
              hint: 'Enter the change order type name. ' \
              'Possible values are: pco, rfq, rco, oco, sco.'
            }
          },
          {
            name: 'id',
            label: 'Change Order ID',
            optional: false,
            sticky: true
          }
        ]
      end,

      execute: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                       .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     get("/cost/v1/containers/#{container_id}/change-orders/#{input['type']}/#{input['id']}")
                      .after_error_response(/.*/) do |_code, body, _header, message|
                        error("#{message}: #{body}")
                      end.merge(hub_id: input['hub_id'], container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat(object_definitions['change_order'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}
        (get("/cost/v1/containers/#{container_id}/change-orders/pco?limit=1") || {})
          .dig('results', 0).merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    create_change_order_in_project: {
      title: 'Create change order in a project',

      description: 'Create <span class="provider">change order</span>' \
      ' in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action creates a change order in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'type',
            label: 'Change Order Type',
            control_type: 'select',
            pick_list: 'change_order_types',
            optional: false,
            sticky: true,
            toggle_hint: 'Select type',
            toggle_field: {
              name: 'type',
              label: 'Change Order Type',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter type name',
              hint: 'Enter the change order type name. ' \
              'Possible values are: pco, rfq, rco, oco, sco.'
            }
          },
          {
            name: 'name',
            sticky: true,
            hint: 'Name of the change order. Max length of 1024 characters.'
          },
          {
            name: 'description',
            sticky: true,
            hint: 'Description of the change order. Max length of 2048 characters.'
          },
          {
            name: 'scope',
            sticky: true,
            label: 'Scope',
            hint: 'Scope of the change order.',
            control_type: 'select',
            pick_list: 'change_order_scope',
            toggle_hint: 'Select scope',
            toggle_field: {
              name: 'scope',
              label: 'Scope',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter type name',
              hint: 'Enter scope of change order. ' \
              'Possible values are: out, in, tbd, contigency.'
            }
          },
          {
            name: 'scopeOfWork',
            optional: true,
            sticky: true,
            hint: 'Scope of work of the change order.'
          },
          {
            name: 'note',
            optional: true,
            sticky: true,
            hint: 'Additional notes to the change order.'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        project_id = input.delete('project_id')
        type = input.delete('type')

        container_id = get("/project/v1/hubs/#{hub_id}/projects/#{project_id}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     post("/cost/v1/containers/#{container_id}/change-orders/#{type}")
                      .payload(input)
                      .after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end.merge(hub_id: hub_id, container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat(object_definitions['change_order'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}
        (get("/cost/v1/containers/#{container_id}/change-orders/pco?limit=1") || {})
          .dig('results', 0).merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    update_change_order_in_project: {
      title: 'Update change order in a project',

      description: 'Update <span class="provider">change order</span>' \
      ' in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action updates a change order in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'type',
            label: 'Change Order Type',
            control_type: 'select',
            pick_list: 'change_order_types',
            optional: false,
            sticky: true,
            toggle_hint: 'Select type',
            toggle_field: {
              name: 'type',
              label: 'Change Order Type',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter type name',
              hint: 'Enter the change order type name. ' \
              'Possible values are: pco, rfq, rco, oco, sco.'
            }
          },
          {
            name: 'id',
            label: 'Change Order ID',
            optional: false,
            sticky: true,
            hint: 'ID of the change order. Max length of 1024 characters.'
          },
          {
            name: 'name',
            sticky: true,
            hint: 'Name of the change order. Max length of 1024 characters.'
          },
          {
            name: 'description',
            sticky: true,
            hint: 'Description of the change order. Max length of 2048 characters.'
          },
          {
            name: 'scope',
            sticky: true,
            label: 'Scope',
            hint: 'Scope of the change order.',
            control_type: 'select',
            pick_list: 'change_order_scope',
            toggle_hint: 'Select scope',
            toggle_field: {
              name: 'scope',
              label: 'Scope',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter type name',
              hint: 'Enter scope of change order. ' \
              'Possible values are: out, in, tbd, contigency.'
            }
          },
          {
            name: 'scopeOfWork',
            sticky: true,
            hint: 'Scope of work of the change order.'
          },
          {
            name: 'note',
            sticky: true,
            hint: 'Additional notes to the change order.'
          },
          {
            name: 'recipients',
            sticky: true,
            hint: 'Users who will receive the generated documents.',
            type: 'array', of: 'object', properties: [
              { name: 'id', hint: 'ID of the user in BIM 360.' },
              { name: 'isDefault', type: 'boolean', hint: 'Indicate whether the user is the default recipient.'}
            ]
          }
        ]
      end,

      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        project_id = input.delete('project_id')
        type = input.delete('type')
        id = input.delete('id')

        container_id = get("/project/v1/hubs/#{hub_id}/projects/#{project_id}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     patch("/cost/v1/containers/#{container_id}/change-orders/#{type}/#{id}")
                      .payload(input)
                      .after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end.merge(hub_id: hub_id, container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat(object_definitions['change_order'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/change-orders/pco?limit=1") || {})
          .dig('results', 0).merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    search_cost_items_in_project: {
      title: 'Search cost items in a project',

      description: 'Search <span class="provider">cost items</span>' \
      ' in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action searches for cost items in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'changeOrderId',
            label: 'Change Order',
            hint: 'Filter by change order ID. Separate multiple IDs with commas.'
          },
          {
            name: 'budgetId',
            label: 'Budget',
            hint: 'Filter by budget ID. Separate multiple IDs with commas.'
          },
          {
            name: 'externalSystem',
            label: 'External System',
            hint: 'Filter by name of source if used in system integration.'
          },
          {
            name: 'externalId',
            label: 'External ID',
            hint: 'Filter by item ID in the external system. ' \
            'Separate multiple IDs with commas.'
          },
          {
            name: 'include',
            hint: 'Resources to include in the response.',
            control_type: 'multiselect',
            pick_list: [
              ['Budgets', 'budgets'],
              ['Change Orders', 'changeOrders'],
              ['Attributes', 'attributes']
            ],
            delimiter: ','
          },
          {
            name: 'offset',
            type: 'number',
            hint: 'Number of items to skip before starting to collect the result set.'
          },
          {
            name: 'limit',
            type: 'number',
            hint: 'Number of items to return.'
          },
          {
            name: 'sort',
            hint: 'Order of items to sort. Each item can be followed by ' \
            'a direction modifier of either asc or desc. ' \
            'If no direction is specified then asc is assumed.'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        filter_criteria = call('format_cost_search', input.except('hub_id', 'project_id', 'type'))

        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     get("/cost/v1/containers/#{container_id}/cost-items", filter_criteria)
                      .after_error_response(/.*/) do |_code, body, _header, message|
                        error("#{message}: #{body}")
                      end.merge(hub_id: input['hub_id'], container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat([
          { name: 'results', type: 'array', of: 'object', properties: object_definitions['cost_item'] },
          { name: 'pagination', type: 'object', properties: [
            { name: 'totalResults', type: 'number' },
            { name: 'limit', type: 'number' },
            { name: 'offset', type: 'number' },
            { name: 'nextUrl' }
          ]}
        ])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/cost-items?limit=1") || {})
          .merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    get_cost_item_in_project: {
      title: 'Get cost item in a project',

      description: 'Get <span class="provider">cost item</span>' \
      ' in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action returns a cost item in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'id',
            label: 'Cost Item ID',
            optional: false,
            sticky: true
          }
        ]
      end,

      execute: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     get("/cost/v1/containers/#{container_id}/cost-items/#{input['id']}")
                      .after_error_response(/.*/) do |_code, body, _header, message|
                        error("#{message}: #{body}")
                      end.merge(hub_id: input['hub_id'], container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat(object_definitions['cost_item'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}
        (get("/cost/v1/containers/#{container_id}/cost-items?limit=1") || {})
          .dig('results', 0).merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    create_cost_item_in_project: {
      title: 'Create cost item in a project',

      description: 'Create <span class="provider">cost item</span>' \
      ' in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action creates a cost item in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'name',
            optional: false,
            sticky: true,
            hint: 'Name of the cost item. Max length of 1024 characters.'
          },
          {
            name: 'changeOrderId',
            sticky: true,
            hint: 'ID of the change order that the cost item is created in.'
          },
          {
            name: 'budgetId',
            sticky: true,
            hint: 'ID of the budget that the cost item is linked to.'
          },
          {
            name: 'description',
            sticky: true,
            hint: 'Description of the cost item. Max length of 2048 characters.'
          },
          {
            name: 'estimated',
            sticky: true,
            type: 'number',
            hint: 'Rough estimation of this item without a quotation.'
          },
          {
            name: 'proposed',
            sticky: true,
            type: 'number',
            hint: 'Quoted cost of the cost item.'
          },
          {
            name: 'submitted',
            sticky: true,
            type: 'number',
            hint: 'Amount submitted to the owner for approval.'
          },
          {
            name: 'approved',
            sticky: true,
            type: 'number',
            hint: 'Amount approved by the owner.'
          },
          {
            name: 'committed',
            sticky: true,
            type: 'number',
            hint: 'Amount committed to the supplier.'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        project_id = input.delete('project_id')

        container_id = get("/project/v1/hubs/#{hub_id}/projects/#{project_id}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')
        response = if container_id.present?
                     post("/cost/v1/containers/#{container_id}/cost-items")
                      .payload(input)
                      .after_error_response(/.*/) do |_code, body, _header, message|
                        error("#{message}: #{body}")
                      end.merge(hub_id: hub_id, container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat(object_definitions['cost_item'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/cost-items?limit=1") || {})
          .dig('results', 0).merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    update_cost_item_in_project: {
      title: 'Update cost item in a project',

      description: 'Update <span class="provider">cost item</span>' \
      ' in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action updates a cost item in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'id',
            label: 'Cost Item ID',
            optional: false,
            sticky: true
          },
          {
            name: 'name',
            sticky: true,
            hint: 'Name of the cost item. Max length of 1024 characters.'
          },
          {
            name: 'changeOrderId',
            sticky: true,
            hint: 'ID of the change order that the cost item is created in.'
          },
          {
            name: 'budgetId',
            sticky: true,
            hint: 'ID of the budget that the cost item is linked to.'
          },
          {
            name: 'description',
            sticky: true,
            hint: 'Description of the cost item. Max length of 2048 characters.'
          },
          {
            name: 'estimated',
            sticky: true,
            type: 'number',
            hint: 'Rough estimation of this item without a quotation.'
          },
          {
            name: 'proposed',
            sticky: true,
            type: 'number',
            hint: 'Quoted cost of the cost item.'
          },
          {
            name: 'submitted',
            sticky: true,
            type: 'number',
            hint: 'Amount submitted to the owner for approval.'
          },
          {
            name: 'approved',
            sticky: true,
            type: 'number',
            hint: 'Amount approved by the owner.'
          },
          {
            name: 'committed',
            sticky: true,
            type: 'number',
            hint: 'Amount committed to the supplier.'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        project_id = input.delete('project_id')
        cost_item_id = input.delete('id')

        container_id = get("/project/v1/hubs/#{hub_id}/projects/#{project_id}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     patch("/cost/v1/containers/#{container_id}/cost-items/#{cost_item_id}")
                      .payload(input)
                      .after_error_response(/.*/) do |_code, body, _header, message|
                        error("#{message}: #{body}")
                      end.merge(hub_id: hub_id, container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat(object_definitions['cost_item'])
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}
        (get("/cost/v1/containers/#{container_id}/cost-items?limit=1") || {})
          .dig('results', 0).merge(hub_id: input['hub_id'], container_id: container_id)
      end
    },

    get_cost_attachments_in_project: {
      title: 'Get cost attachments in a project',

      description: 'Get <span class="provider">cost attachments</span>' \
      ' in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action returns all attachments associated with a cost in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'associationId',
            label: 'Object ID',
            optional: false,
            sticky: true,
            hint: 'Object ID of the budget, contract, or cost item.'
          },
          {
            name: 'associationType',
            label: 'Object Type',
            optional: false,
            sticky: true,
            control_type: 'select',
            pick_list: 'cost_association_types',
            toggle_hint: 'Select object type',
            toggle_field: {
              name: 'associationType',
              label: 'Object Type',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter object type',
              hint: 'Possible values are: Budget, Contract, CostItem, ' \
              'FormInstance, Payment, BudgetPayment'
            }
          },
          {
            name: 'lastModifiedSince',
            hint: 'Filter to include only items updated since this datetime.',
            type: 'date_time'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        filter_criteria = call('format_cost_search', input.except('hub_id', 'project_id', 'associationId', 'associationType'))
        container_id = get("/project/v1/hubs/#{input.delete('hub_id')}/projects/#{input.delete('project_id')}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')

        filter_criteria['associationType'] = input['associationType']
        filter_criteria['associationId'] = input['associationId']
        response = if container_id.present?
                     get("/cost/v1/containers/#{container_id}/attachments", filter_criteria)
                       .after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message}: #{body}")
                       end
                   end
        { results: response }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'results', type: 'array', 
            of: 'object', properties: object_definitions['cost_attachment'] }
        ]
      end,

      sample_output: lambda do |_connection|
        {
          results: [
            {
              "id": "F2D2ED17-C763-465B-8FAB-251C5A35D42F",
              "folderId": "8E34872D-A56F-4096-B675-476F50F4EF51",
              "urn": "urn:adsk.wipprod:fs.file:vf.PMbRnoPZR2mKDhau2uw4SQ?version=1",
              "type": "Upload",
              "name": "Architecture",
              "associationId": "EDC42DF6-277A-436A-A50D-EF57F35E1248",
              "associationType": "Budget",
              "createdAt": "2019-01-06T01:24:22.678Z",
              "updatedAt": "2019-09-05T01:00:12.989Z"
            }
          ]
        }
      end
    },

    create_cost_attachment_in_project: {
      title: 'Create cost attachment in a project',

      description: 'Create <span class="provider">cost attachment</span>' \
      ' in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action creates an attachment to a cost object in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'name',
            optional: false,
            sticky: true,
            hint: 'Name of the attachment. Max length of 255 characters.'
          },
          {
            name: 'urn',
            optional: false,
            sticky: true,
            hint: 'Version URN of the BIM 360 Docs file.'
          },
          {
            name: 'associationId',
            optional: false,
            sticky: true,
            hint: 'Object ID of the budget, contract, or cost item.'
          },
          {
            name: 'associationType',
            label: 'Object Type',
            optional: false,
            sticky: true,
            control_type: 'select',
            pick_list: 'cost_association_types',
            toggle_hint: 'Select object type',
            toggle_field: {
              name: 'associationType',
              label: 'Object Type',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter object type',
              hint: 'Possible values are: Budget, Contract, CostItem,' \
              ' FormInstance, Payment, BudgetPayment'
            }
          }
        ]
      end,

      execute: lambda do |_connection, input|
        hub_id = input.delete('hub_id')
        project_id = input.delete('project_id')
        container_id = get("/project/v1/hubs/#{hub_id}/projects/#{project_id}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')

        attachment_folder = post("/cost/v1/containers/#{container_id}/attachment-folders")
                              .payload(
                                'associationId' => input['associationId'],
                                'associationType' => input['associationType']
                              )
                              .dig('id')

        response = if container_id.present?
                     post("/cost/v1/containers/#{container_id}/attachments")
                       .payload(
                          'name': input['name'],
                          'folderId': attachment_folder,
                          'urn': input['urn'],
                          'associationId': input['associationId'],
                          'associationType': input['associationType']
                        )
                        .after_error_response(/.*/) do |_code, body, _header, message|
                          error("#{message}: #{body}")
                       end.merge(hub_id: hub_id, container_id: container_id)
                   end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'container_id' }
        ]
        .concat(object_definitions['cost_attachment'])
      end,

      sample_output: lambda do |_connection|
        {
          'id': 'F2D2ED17-C763-465B-8FAB-251C5A35D42F',
          'folderId': '8E34872D-A56F-4096-B675-476F50F4EF51',
          'urn': 'urn:adsk.wipprod:fs.file:vf.PMbRnoPZR2mKDhau2uw4SQ?version=1',
          'type': 'Upload',
          'name': 'Architecture',
          'associationId': 'EDC42DF6-277A-436A-A50D-EF57F35E1248',
          'associationType': 'Budget',
          'createdAt': '2019-01-06T01:24:22.678Z',
          'updatedAt': '2019-09-05T01:00:12.989Z'
        }
      end
    },

    get_cost_documents_in_project: {
      title: 'Get cost documents in a project',

      description: 'Get <span class="provider">generated cost documents</span>' \
      ' in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action returns generated documents associated with cost in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'associationId',
            label: 'Object ID',
            optional: false,
            sticky: true,
            hint: 'Object ID of the item, such as budget, contract, or cost item.'
          },
          {
            name: 'associationType',
            label: 'Object Type',
            optional: false,
            sticky: true,
            control_type: 'select',
            pick_list: 'cost_association_types',
            toggle_hint: 'Select object type',
            toggle_field: {
              name: 'associationType',
              label: 'Object Type',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter object type',
              hint: 'Possible values are: Budget, Contract, CostItem, ' \
              'FormInstance, Payment, BudgetPayment'
            }
          },
          {
            name: 'latest',
            label: 'Latest Version',
            sticky: true,
            type: 'boolean',
            control_type: 'checkbox',
            hint: 'Return only the latest version of a document if it has ' \
            'been generated multiple times.'
          },
          {
            name: 'signed',
            label: 'Signed Documents',
            sticky: true,
            type: 'boolean',
            control_type: 'checkbox',
            hint: 'Return only documents that have been signed.'
          },
          {
            name: 'lastModifiedSince',
            hint: 'Filter to include only items updated since this datetime.',
            type: 'date_time'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        filter_criteria = call('format_cost_search', input.except('hub_id', 'project_id', 'associationId', 'associationType'))
        container_id = get("/project/v1/hubs/#{input.delete('hub_id')}/projects/#{input.delete('project_id')}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')

        filter_criteria['associationType'] = input['associationType']
        filter_criteria['associationId'] = input['associationId']
        response = if container_id.present?
                     get("/cost/v1/containers/#{container_id}/documents", filter_criteria)
                       .after_error_response(/.*/) do |_code, body, _header, message|
                          error("#{message}: #{body}")
                       end
                   end
        { results: response }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'results', type: 'array', of: 'object',
            properties: object_definitions['cost_document'] }
        ]
      end,

      sample_output: lambda do |_connection|
        {
          "results": [
            {
              "id": "1df59db0-9484-11e8-a7ec-7ddae203e404",
              "templateId": "1df59db0-9484-11e8-a7ec-7ddae203e404",
              "recipientId": "GF8XKPKWM38E",
              "signedBy": "CED9LVTLHNXV",
              "urn": "urn:adsk.wipprod:fs.file:vf.PMbRnoPZR2mKDhau2uw4SQ?version=1",
              "signedUrn": "urn:adsk.wipprod:fs.file:vf.PMbRnoPZR2mKDhau2uw4SQ?version=1",
              "status": "Completed",
              "jobId": 1,
              "errorInfo": {
                "code": "missingTemplate",
                "message": "Couldn't generate the document because the template is invalid.",
                "detail": "Got timeout for POST upload URL."
              },
              "associationId": "EDC42DF6-277A-436A-A50D-EF57F35E1248",
              "associationType": "Budget",
              "createdAt": "2019-01-06T01:24:22.678Z",
              "updatedAt": "2019-09-05T01:00:12.989Z"
            }
          ]
        }
      end
    },

    download_cost_document_in_project: {
      title: 'Download cost document in a project',

      description: 'Download <span class="provider">generated cost document</span>' \
      ' in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action downloads generated document associated with cost in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'urn',
            optional: false,
            sticky: true,
            hint: 'The URN ID of the generated cost document.'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        file_url = get("/data/v1/projects/#{input['project_id']}/versions/#{input['urn'].encode_url}")
                   .dig('data', 'relationships', 'storage', 'meta', 'link', 'href')

        if file_url.present?
          { content: get(file_url).headers('Accept-Encoding': 'Accept-Encoding:gzip')
                       .response_format_raw
                       .after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message}: #{body}")
                       end }
        else
          error('File does not exist')
        end
      end,

      output_fields: lambda do |_object_definitions|
        [{ name: 'content' }]
      end,

      sample_output: lambda do |_connection|
        {
          "content": "<file-content>"
        }
      end
    },

    search_cost_file_packages_in_project: {
      title: 'Search cost file packages in a project',

      description: 'Search <span class="provider">cost file packages</span>' \
      ' in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'This action returns file packages of cost objects in a project.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false,
            toggle_hint: 'Select hub',
            toggle_field: {
              name: 'hub_id',
              label: 'Hub ID',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter hub ID',
              hint: 'Get account ID from admin page. To convert an account ID into a hub ID you need to add a “b.” prefix. For example, an account ID of '\
              '<b>c8b0c73d-3ae9</b> translates to a hub ID of <b>b.c8b0c73d-3ae9</b>.'
            }
          },
          {
            name: 'project_id',
            label: 'Project',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false,
            toggle_hint: 'Select project',
            toggle_field: {
              name: 'project_id',
              label: 'Project ID',
              change_on_blur: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter project ID',
              hint: 'Get ID from url of the project page. For example, a project ID is <b>b.baf-0871-4aca-82e8-3dd6db</b>.'
            }
          },
          {
            name: 'associationId',
            label: 'Object ID',
            sticky: true,
            optional: false,
            hint: 'The ID associated with a specific a budget, contract, ' \
            'cost item, etc.'
          },
          {
            name: 'associationType',
            label: 'Object Type',
            sticky: true,
            optional: false,
            control_type: 'select',
            pick_list: 'cost_association_types',
            toggle_hint: 'Select object type',
            toggle_field: {
              name: 'associationType',
              label: 'Object Type',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter object type',
              hint: 'Possible values are: Budget, Contract, CostItem, ' \
              'FormInstance, Payment, BudgetPayment'
            }
          },
          {
            name: 'lastModifiedSince',
            hint: 'Filter to include only items updated since this datetime.',
            type: 'date_time'
          }
        ]
      end,

      execute: lambda do |_connection, input|
        filter_criteria = call('format_cost_search', input.except('hub_id', 'project_id'))
        container_id = get("/project/v1/hubs/#{input.delete('hub_id')}/projects/#{input.delete('project_id')}")
                        .dig('data', 'relationships', 'cost', 'data', 'id')

        response = if container_id.present?
                     get("/cost/v1/containers/#{container_id}/file-packages", filter_criteria)
                       .after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message}: #{body}")
                       end
                   end
        { results: response }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'results', type: 'array', of: 'object',
            properties: object_definitions['cost_file_packages'] }
        ]
      end,

      sample_output: lambda do |_connection, input|
        {
          "results": [
            {
              "id": "a2e16076-d5bb-44b3-b451-fb1fb390e4fc",
              "recipient": "GF8XKPKWM38E",
              "urn": "urn:adsk.wipprod:fs.file:vf.PMbRnoPZR2mKDhau2uw4SQ?version=1",
              "errorInfo": {
                "code": "missingTemplate",
                "message": "Couldn't generate the document because the template is invalid.",
                "detail": "Got timeout for POST upload URL."
              },
              "items": [
                {
                  "id": "a2e16076-d5bb-44b3-b451-fb1fb390e4fc",
                  "urn": "urn:adsk.wipprod:fs.file:vf.PMbRnoPZR2mKDhau2uw4SQ?version=1",
                  "name": "GC_001.John-Smith.docx",
                  "type": "Document",
                  "createdAt": "2019-01-06T01:24:22.678Z",
                  "updatedAt": "2019-09-05T01:00:12.989Z"
                }
              ],
              "createdAt": "2019-01-06T01:24:22.678Z",
              "updatedAt": "2019-09-05T01:00:12.989Z"
            }
          ]
        }
      end
    }

  },

  triggers: {
    new_updated_issue_in_project: {
      title: 'New or updated issue in a project',

      description: 'New or updated <span class="provider">issue</span> in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'Triggers when an issue in a project is created or updated.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false
          },
          {
            name: 'project_id',
            label: 'Project name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false
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
        closure ||= {}
        updated_after = closure['updated_after'] || (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 100

        response = if closure['next_page_url'].present?
                     get(closure['next_page_url'])
                   else
                     closure['container_id'] ||= get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")&.
                                                   dig('data', 'relationships', 'issues', 'data', 'id')
                     get("/issues/v1/containers/#{closure['container_id']}/quality-issues").
                       params(page: { limit: limit, offset: closure['offset'] || 0 },
                              filter: { synced_after: updated_after },
                              sort: 'updated_at',
                              included: input['include'])
                   end

        if (next_page_url = response.dig('links', 'next')).present?
          closure['next_page_url'] = next_page_url
        else
          closure['offset'] = 0
          closure['updated_after'] = Array.wrap(response['data']).last.dig('attributes', 'updated_at')
        end

        issues = response['data']&.map do |out|
          call(:format_output_response,
               out['attributes'],
               %w(permitted_statuses permitted_actions permitted_attributes custom_attributes trades))
          out.merge(project_id: input['project_id'], hub_id: input['hub_id'], container_id: closure['container_id'])
        end
        {
          events: issues || [],
          next_poll: closure,
          can_poll_more: response.dig('links', 'next').present?
        }

      end,

      dedup: lambda do |issue|
        "#{issue['id']}@#{issue.dig('attributes', 'updated_at')}"
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' },
          { name: 'container_id' }
        ].concat(object_definitions['issue']).compact
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")&.dig('data', 'relationships', 'issues', 'data', 'id') || {}
        get("/issues/v1/containers/#{container_id}/quality-issues?page[limit]=1")&.dig('data', 0) || {}
      end
    },

    new_updated_document_in_project: {
      title: 'New or updated document in a project folder',

      description: 'New or updated <span class="provider">document</span> in a project folder in <span class="provider">BIM 360</span>',

      help: 'Triggers when a document in a project folder is created or updated.',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false
          },
          {
            name: 'project_id',
            label: 'Project name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false
          },
          { name: 'folder_id',
            label: 'Folder',
            control_type: 'tree',
            hint: 'Select the folder to monitor for documents. Sub-folders will also be monitored.',
            pick_list_params: { hub_id: 'hub_id', project_id: 'project_id' },
            tree_options: { selectable_folder: true },
            pick_list: :folders_list,
            optional: false
          },
          {
            name: 'since',
            label: 'When first started, this recipe should pick up events from',
            hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago.',
            sticky: true,
            type: 'timestamp'
          }
        ]
      end,

      poll: lambda do |_connection, input, closure|
        closure ||= {}
        last_modified_time = closure['updated_after'] || (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 100

        response = if closure['next_page_url'].present?
                     get(closure['next_page_url'])
                   else
                     get("/data/v1/projects/#{input['project_id']}/folders/#{input['folder_id']}/contents",
                         "filter[type]=items&filter[lastModifiedTimeRollup]-ge=#{last_modified_time}&page[limit]=#{limit}&page[number]=#{closure['number'] || 0}")
                   end

        items = response['data']&.map do |out|
          call(:format_output_response, out.dig('attributes', 'extension', 'data'),
               %w(visibleTypes actions allowedTypes))
          out.merge(project_id: input['project_id'], hub_id: input['hub_id'], folder_id: input['folder_id'])
        end&.sort_by { |res| res.dig('attributes', 'lastModifiedTime') }
        if (next_page_url = response.dig('links', 'next')).present?
          closure['next_page_url'] = next_page_url
        else
          closure['number'] = 0
          closure['updated_after'] = Array.wrap(response['data']).last.dig('attributes', 'lastModifiedTime')
        end
        {
          events: items || [],
          next_poll: closure,
          can_poll_more: response.dig('links', 'next').present?
        }
      end,

      dedup: lambda do |item|
        "#{item['id']}@#{item.dig('attributes', 'lastModifiedTime')}"
      end,

      output_fields: lambda do |object_definitions|
        [{ name: 'hub_id' }, { name: 'project_id' }, { name: 'folder_id' }].
          concat(object_definitions['folder_file']).
          compact
      end,

      sample_output: lambda do |_connection, input|
        get("/data/v1/projects/#{input['project_id']}/folders/#{input['folder_id']}/contents?page[limit]=1")&.dig('data', 0) || {}
      end
    },

    new_updated_budget_in_project: {
      title: 'New or updated budget in a project',

      description: 'New or updated <span class="provider">budget</span> in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'Triggers when a budget in a project is created or updated.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false
          },
          {
            name: 'project_id',
            label: 'Project name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false
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
        closure ||= {}
        updated_after = closure['updated_after'] || (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 100

        response = if closure['next_page_url'].present?
                     get(closure['next_page_url'])
                   else
                     closure['container_id'] ||= get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")&.
                                                   dig('data', 'relationships', 'cost', 'data', 'id')

                     get("/cost/v1/containers/#{closure['container_id']}/budgets").
                       params(limit: limit,
                              offset: closure['offset'] || 0,
                              filter: { lastModifiedSince: updated_after },
                              sort: 'updatedAt')
                   end

        if (next_page_url = response.dig('pagination', 'nextUrl')).present?
          closure['next_page_url'] = next_page_url
        else
          closure['offset'] = 0
          closure['updated_after'] = (Array.wrap(response['results']).last||{}).dig('updatedAt')
        end

        records = response['results']&.map do |out|
          out.merge(project_id: input['project_id'], hub_id: input['hub_id'])
        end
        {
          events: records || [],
          next_poll: closure,
          can_poll_more: response.dig('pagination', 'nextUrl').present?
        }

      end,

      dedup: lambda do |record|
        "#{record['id']}@#{record.dig('updatedAt')}"
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' }
        ].concat(object_definitions['budget']).compact
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/budgets?limit]=1")&.dig('results', 0) || {})
          .merge(hub_id: input['hub_id'], project_id: input['project_id'])
      end
    },

    new_updated_contract_in_project: {
      title: 'New or updated contract in a project',

      description: 'New or updated <span class="provider">contract</span> in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'Triggers when a contract in a project is created or updated.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false
          },
          {
            name: 'project_id',
            label: 'Project name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false
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
        closure ||= {}
        updated_after = closure['updated_after'] || (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 100

        response = if closure['next_page_url'].present?
                     get(closure['next_page_url'])
                   else
                     closure['container_id'] ||= get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")&.
                                                   dig('data', 'relationships', 'cost', 'data', 'id')

                     get("/cost/v1/containers/#{closure['container_id']}/contracts").
                       params(limit: limit,
                              offset: closure['offset'] || 0,
                              filter: { lastModifiedSince: updated_after },
                              sort: 'updatedAt')
                   end

        if (next_page_url = response.dig('pagination', 'nextUrl')).present?
          closure['next_page_url'] = next_page_url
        else
          closure['offset'] = 0
          closure['updated_after'] = (Array.wrap(response['results']).last||{}).dig('updatedAt')
        end

        records = response['results']&.map do |out|
          out.merge(project_id: input['project_id'], hub_id: input['hub_id'])
        end
        {
          events: records || [],
          next_poll: closure,
          can_poll_more: response.dig('pagination', 'nextUrl').present?
        }

      end,

      dedup: lambda do |record|
        "#{record['id']}@#{record.dig('updatedAt')}"
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' }
        ].concat(object_definitions['contract']).compact
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/contracts?limit]=1")&.dig('results', 0) || {})
          .merge(hub_id: input['hub_id'], project_id: input['project_id'])
      end
    },

    new_updated_change_order_in_project: {
      title: 'New or updated change order in a project',

      description: 'New or updated <span class="provider">change order</span> in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'Triggers when a change order in a project is created or updated.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false
          },
          {
            name: 'project_id',
            label: 'Project name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false
          },
          {
            name: 'type',
            label: 'Change Order Type',
            control_type: 'select',
            pick_list: 'change_order_types',
            optional: false,
            sticky: true,
            toggle_hint: 'Select type',
            toggle_field: {
              name: 'type',
              label: 'Change Order Type',
              type: 'string',
              change_on_blur: true,
              control_type: 'text',
              toggle_hint: 'Enter type name'
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
        closure ||= {}
        updated_after = closure['updated_after'] || (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 100

        response = if closure['next_page_url'].present?
                     get(closure['next_page_url'])
                   else
                     closure['container_id'] ||= get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")&.
                                                   dig('data', 'relationships', 'cost', 'data', 'id')

                     get("/cost/v1/containers/#{closure['container_id']}/change-orders/#{input['type']}").
                       params(limit: limit,
                              offset: closure['offset'] || 0,
                              filter: { lastModifiedSince: updated_after },
                              sort: 'updatedAt')
                   end

        if (next_page_url = response.dig('pagination', 'nextUrl')).present?
          closure['next_page_url'] = next_page_url
        else
          closure['offset'] = 0
          closure['updated_after'] = (Array.wrap(response['results']).last||{}).dig('updatedAt')
        end

        records = response['results']&.map do |out|
          out.merge(project_id: input['project_id'], hub_id: input['hub_id'])
        end
        {
          events: records || [],
          next_poll: closure,
          can_poll_more: response.dig('pagination', 'nextUrl').present?
        }

      end,

      dedup: lambda do |record|
        "#{record['id']}@#{record.dig('updatedAt')}"
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' }
        ].concat(object_definitions['change_order']).compact
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/change-orders/pco?limit]=1")&.dig('results', 0) || {})
          .merge(hub_id: input['hub_id'], project_id: input['project_id'])
      end
    },

    new_updated_cost_item_in_project: {
      title: 'New or updated cost item in a project',

      description: 'New or updated <span class="provider">cost item</span> in a project in <span class="provider">BIM 360</span>',

      help: {
        body: 'Triggers when a cost item in a project is created or updated.'
      },

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'hub_id',
            label: 'Hub name',
            control_type: 'select',
            pick_list: 'hub_list',
            optional: false
          },
          {
            name: 'project_id',
            label: 'Project name',
            control_type: 'select',
            pick_list: 'project_list',
            pick_list_params: { hub_id: 'hub_id' },
            optional: false
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
        closure ||= {}
        updated_after = closure['updated_after'] || (input['since'] || 1.hour.ago).to_time.utc.iso8601
        limit = 100

        response = if closure['next_page_url'].present?
                     get(closure['next_page_url'])
                   else
                     closure['container_id'] ||= get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")&.
                                                   dig('data', 'relationships', 'cost', 'data', 'id')

                     get("/cost/v1/containers/#{closure['container_id']}/cost-items").
                       params(limit: limit,
                              offset: closure['offset'] || 0,
                              filter: { lastModifiedSince: updated_after },
                              sort: 'updatedAt')
                   end

        if (next_page_url = response.dig('pagination', 'nextUrl')).present?
          closure['next_page_url'] = next_page_url
        else
          closure['offset'] = 0
          closure['updated_after'] = (Array.wrap(response['results']).last||{}).dig('updatedAt')
        end

        records = response['results']&.map do |out|
          out.merge(project_id: input['project_id'], hub_id: input['hub_id'])
        end
        {
          events: records || [],
          next_poll: closure,
          can_poll_more: response.dig('pagination', 'nextUrl').present?
        }

      end,

      dedup: lambda do |record|
        "#{record['id']}@#{record.dig('updatedAt')}"
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'hub_id' },
          { name: 'project_id' }
        ].concat(object_definitions['cost_item']).compact
      end,

      sample_output: lambda do |_connection, input|
        container_id = get("/project/v1/hubs/#{input['hub_id']}/projects/#{input['project_id']}")
                        .dig('data', 'relationships', 'cost', 'data', 'id') || {}

        (get("/cost/v1/containers/#{container_id}/cost-items?limit]=1")&.dig('results', 0) || {})
          .merge(hub_id: input['hub_id'], project_id: input['project_id'])
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
        get("/data/v1/projects/#{project_id}/folders/#{folder_id}/contents?filter[type]=items")['data']&.map do |item|
          [item.dig('attributes', 'displayName'), item['id']]
        end
      end
    end,

    item_versions: lambda do |_connection, project_id:, item_id:|
      get("/data/v1/projects/#{project_id}/items/#{item_id}/versions")['data']&.map do |version|
        ["Version #{version.dig('attributes', 'versionNumber')}", version.dig('id')]
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
      if args[:project_id].length == 38
        if (parent_id = args&.[](:__parent_id)).present?
          get("/data/v1/projects/#{args[:project_id]}/folders/#{parent_id}/contents?filter[type]=folders")['data']&.
            map do |folder|
              [folder.dig('attributes', 'displayName'), folder['id'], nil, true]
            end
        else
          get("project/v1/hubs/#{args[:hub_id]}/projects/#{args[:project_id]}/topFolders?filter[type]=folders")['data']&.
            map do |folder|
              [folder.dig('attributes', 'displayName'), folder['id'], nil, true]
            end || []
        end
      end
    end,

    issue_child_objects: lambda do |_connection|
      %w[attachments comments container]&.map { |option| [option.labelize, option] }
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
          [project.dig('attributes', 'name'), project.dig('relationships', 'issues', 'data', 'id')]
        end
      end
    end,

    issue_type: lambda do |_connection, hub_id:, project_id:|
      container_id = get("/project/v1/hubs/#{hub_id}/projects/#{project_id}")&.dig('data', 'relationships', 'issues', 'data', 'id')
      if container_id.present?
        get("issues/v1/containers/#{container_id}/ng-issue-types")['results']&.map do |issue|
          [issue['title'], issue['id']]
        end
      end
    end,

    issue_sub_type: lambda do |_connection, hub_id:, project_id:, ng_issue_type_id:|
      container_id = get("/project/v1/hubs/#{hub_id}/projects/#{project_id}")&.dig('data', 'relationships', 'issues', 'data', 'id')
      if container_id.present?
        issue_type = get("issues/v1/containers/#{container_id}/ng-issue-types?include=subtypes")['results']&.select { |issue| issue['id'] == ng_issue_type_id }.first
        issue_type['subtypes']&.map do |subtype|
          [subtype['title'], subtype['id']]
        end
      end
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
    end,

    change_order_types: lambda do |_connection|
      %w[pco rfq rco oco sco]&.map { |el| [el.upcase, el] }
    end,

    cost_association_types: lambda do |_connection|
      [
        ['Budget', 'Budget'],
        ['Contract', 'Contract'],
        ['Cost Item', 'CostItem'],
        ['Form Instance', 'FormInstance'],
        ['Payment', 'Payment'],
        ['Budget Payment', 'BudgetPayment']
      ]
    end,

    contract_status: lambda do |_connection|
      %w[draft open sent executed closed]&.map { |el| [el.labelize, el] }
    end,

    change_order_scope: lambda do |_connection|
      %w[in out tbd contigency]&.map { |el| [el.labelize, el] }
    end
  }
}
