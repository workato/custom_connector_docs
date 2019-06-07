{
  title: 'BlackLine Reports',

  connection: {
    fields: [
      {
        name: 'environment',
        control_type: 'select',
        pick_list: [%w[Production us], %w[Sandbox sbus]],
        optional: false
      },
      {
        name: 'data_center',
        hint: 'Ex: 2, if the app URL is ' \
          'https://subdomain.us<b>2</b>.blackline.com/',
        optional: false
      },
      { name: 'username', optional: false },
      {
        name: 'api_key',
        label: 'API key',
        hint: 'Login to app as System Admin and generate an API key by ' \
          'navigating to - System > Users Admin Grid > User > User Information',
        control_type: 'password',
        optional: false
      },
      {
        name: 'client_id',
        hint: 'Ex: subdomain, if the app URL is ' \
          'https://<b>subdomain</b>.us2.blackline.com',
        optional: false
      },
      { name: 'client_secret', control_type: 'password', optional: false },
      {
        name: 'user_scope',
        hint: 'Ex: ReportsAPI instance_ABCD-1234-5AC6-7D89-1C0A2345B6AB',
        optional: false
      }
    ],

    base_uri: lambda do |connection|
      "https://#{connection['environment']}#{connection['data_center']}" \
        '.api.blackline.com'
    end,

    authorization: {
      type: 'custom',

      acquire: lambda do |connection|
        auth_header =
          "#{connection['client_id']}:#{connection['client_secret']}".
          encode_base64
        response = post('/authorize/connect/token').
                   headers('Content-Type' =>
                           'application/x-www-form-urlencoded',
                           'Authorization' => "Basic #{auth_header}").
                   payload(grant_type: 'password',
                           password: connection['api_key'],
                           scope: connection['user_scope'],
                           username: connection['username']).
                   request_format_www_form_urlencoded

        { access_token: response['access_token'] }
      end,

      refresh_on: [401],

      apply: lambda do |connection|
        headers('Authorization' => "Bearer #{connection['access_token']}")
      end
    }
  },

  object_definitions: {
    report: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            control_type: 'text',
            label: 'End time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'endTime'
          },
          {
            name: 'exportUrls',
            type: 'array',
            of: 'object',
            label: 'Export URLs',
            properties: [{ name: 'type' }, { name: 'url', label: 'URL' }]
          },
          {
            control_type: 'number',
            label: 'ID',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'id'
          },
          { name: 'message' },
          { name: 'name' },
          { name: 'notes' },
          {
            control_type: 'text',
            label: 'Start time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'startTime'
          },
          { name: 'status' }
        ]
      end
    }
  },

  test: ->(_connection) { get('/api/queryruns') },

  actions: {
    get_report_content: {
      title: 'Get report content in CSV',
      description: "Get <span class='provider'>report content (CSV)</span> " \
        "in <span class='provider'>BlackLine Reports</span>",

      execute: lambda do |_connection, input|
        {
          content: get("/api/completedqueryrun/#{input['report_id']}/CSV").
            response_format_raw.
            encode.to_s.gsub(/�/, '')
        }
      end,

      input_fields: lambda do |_connection|
        [{ name: 'report_id',
           type: 'integer',
           optional: false,
           hint: 'Only reports with CSV ExportURLs can be used' }]
      end,

      output_fields: ->(_object_definitions) { [{ name: 'content' }] },

      sample_output: lambda do |_connection, _input|
        { content: 'EUR	0.99	01/01/2000	M' }
      end
    },

    list_reports: {
      description: "List <span class='provider'>reports</span> " \
        "in <span class='provider'>BlackLine Reports</span>",

      execute: lambda do |_connection, _input|
        {
          reports: get('/api/queryruns').
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        }
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'reports',
          type: 'array',
          of: 'object',
          properties: object_definitions['report']
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          'endTime' => '2019-01-01T23:16:05.543Z',
          'exportUrls' => [],
          'id' => 123_456,
          'message' => '',
          'name' => 'User Access',
          'notes' => 'User Access - List of users showing their current ' \
            'authorized Roles',
          'startTime' => '2019-01-01T23:16:03.433Z',
          'status' => 'Complete'
        }
      end
    }
  }
}
