{
  title: 'Duo Security',

  methods: {
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

    get_formatted_date: lambda do |input|
      # format date to RFC2822 format
      input['date'].strftime('%a, %d %b %Y %T %z')
    end,

    genarate_signature: lambda do |input|
      connection = input['connection']
      signature = [
        input['date'],
        input['method'],
        "api-#{connection['subdomain']}.duosecurity.com",
        input['endpoint'],
        input['data'].to_param
      ]
                  .join("\n")
                  .hmac_sha1(connection['secret_key'])
                  .encode_hex

      "#{connection['integration_key']}:#{signature}".encode_base64
    end
  },

  connection: {
    fields: [
      {
        name: 'subdomain',
        optional: true,
        hint: 'Find subdomain from instance URL, e.g. if instance URL' \
          'is https://admin-<b>12345dc5</b>.duosecurity.com,' \
          ' subdomain is 12345dc5'
      },
      {
        name: 'integration_key',
        control_type: 'password',
        hint: "Find integration key from 'Admin API' application page, ' \
          'Go to applications page (https://admin-12345dc5.duosecurity.com/' \
          'applications) and then select Admin API"
      },
      {
        name: 'secret_key',
        control_type: 'password',
        hint: "Find secret key from 'Admin API' application page, ' \
          'Go to applications page (https://admin-12345dc5.duosecurity.com/' \
          'applications) and then select Admin API"
      }
    ],

    base_uri: lambda do |connection|
      "https://api-#{connection['subdomain']}.duosecurity.com"
    end,

    authorization: {
      type: 'custom_auth',

      acquire: ->(_connection) { {} },

      apply: ->(_connection) {}
    }
  },

  object_definitions: {
    authlog: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'access_device',
            type: 'object',
            properties: [
              { name: 'browser' },
              { name: 'browser_version' },
              { name: 'flash_version' },
              { name: 'ip', label: 'IP' },
              { name: 'java_version' },
              {
                name: 'location',
                type: 'object',
                properties: [
                  { name: 'city' },
                  { name: 'country' },
                  { name: 'state' }
                ]
              },
              { name: 'os', label: 'Operating system' },
              { name: 'os_version', label: 'Operating system version' }
            ]
          },
          {
            name: 'application',
            type: 'object',
            properties: [{ name: 'key' }, { name: 'name' }]
          },
          {
            name: 'auth_device',
            type: 'object',
            properties: [
              { name: 'ip', label: 'Internet protocol' },
              {
                name: 'location',
                type: 'object',
                properties: [
                  { name: 'city' },
                  { name: 'country' },
                  { name: 'state' }
                ]
              },
              { name: 'name' }
            ]
          },
          { name: 'event_type' },
          { name: 'factor' },
          { name: 'reason' },
          { name: 'result' },
          {
            control_type: 'number',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'timestamp'
          },
          { name: 'trusted_endpoint_status' },
          { name: 'txid', label: 'Transaction ID' },
          {
            name: 'user',
            type: 'object',
            properties: [{ name: 'key' }, { name: 'name' }]
          }
        ]
      end
    },

    custom_action_input: {
      fields: lambda do |connection, config_fields|
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')

        [
          {
            name: 'path',
            optional: false,
            hint: "Base URI is <b>https://api-#{connection['subdomain']}." \
              'duosecurity.com</b> - path will be appended to this URI.' \
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
                        properties: input_schema
                          .each { |field| field[:sticky] = true }
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
    },

    user: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'alias1' },
          { name: 'alias2' },
          { name: 'alias3' },
          { name: 'alias4' },
          {
            control_type: 'number',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'created',
            label: 'Date created'
          },
          { name: 'email' },
          { name: 'firstname' },
          {
            name: 'groups',
            type: 'array',
            of: 'object',
            properties: [
              { name: 'desc', label: 'Description' },
              { name: 'name', label: 'Group name' }
            ]
          },
          {
            control_type: 'number',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'last_directory_sync'
          },
          {
            control_type: 'number',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'last_login'
          },
          { name: 'lastname' },
          { name: 'notes' },
          {
            name: 'phones',
            type: 'array',
            of: 'object',
            properties: [
              { name: 'phone_id', hint: 'Unique ID for phone number' },
              { name: 'number', hint: 'Phone number' },
              { name: 'extension', hint: 'Phone extension' },
              { name: 'name' },
              { name: 'postdelay', label: 'Post-delay' },
              { name: 'predelay', label: 'Pre-delay' },
              { name: 'type' },
              {
                name: 'capabilities',
                type: 'array',
                of: 'string',
                control_type: 'text'
              },
              { name: 'platform' },
              {
                name: 'activated',
                control_type: 'checkbox',
                type: 'boolean',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'activated'
                }
              },
              {
                name: 'sms_passcodes_sent',
                control_type: 'checkbox',
                type: 'boolean',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'sms_passcodes_sent'
                }
              }
            ]
          },
          { name: 'realname', label: 'Real name' },
          {
            name: 'status',
            hint: '<b>"active"</b> - The user must complete ' \
              'secondary authentication.  <br/> <b>"bypass"</b> - '\
              'The user will bypass secondary authentication after completing '\
              'primary authentication. <br/> <b>"disabled"</b>  - The user  '\
              'will not be able to log in. <br/> <b>"locked out"</b> - '\
              'The user has been automatically locked out due to excessive '\
              'authentication attempts.',
            control_type: 'select',
            pick_list: 'statuses',
            toggle_hint: 'Select from list',
            toggle_field: {
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'string',
              name: 'status',
              hint: 'Any one of these - "active", "bypass", "disabled" or ' \
              '"locked out".<br/> <b>"active"</b> - The user must complete ' \
              'secondary authentication.  <br/> <b>"bypass"</b> - '\
              'The user will bypass secondary authentication after completing '\
              'primary authentication. <br/> <b>"disabled"</b>  - '\
              'The user will not be able to log in. <br/> <b>"locked out"</b> '\
              '- The user has been automatically locked out due to excessive '\
              'authentication attempts.'
            }
          },
          {
            name: 'tokens',
            type: 'array',
            of: 'object',
            properties: [
              { name: 'serial' },
              { name: 'token_id' },
              { name: 'type' }
            ]
          },
          { name: 'user_id' },
          { name: 'username' }
        ]
      end
    }
  },

  test: lambda do |connection|
    endpoint = '/admin/v1/users'
    data = { limit: 1 }
    formatted_date = call('get_formatted_date', 'date' => now)
    basic_auth_header = call('genarate_signature',
                             'connection' => connection,
                             'endpoint' => endpoint,
                             'method' => 'GET',
                             'data' => data,
                             'date' => formatted_date)

    get(endpoint, data)
      .headers('Date' => formatted_date,
               'Authorization' => "Basic #{basic_auth_header}")
  end,

  actions: {
    # Custom action for Duo Security
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
        "in <span class='provider'>Duo Security</span>",
      help: 'Build your own Duo Security action with a HTTP request. <br>' \
        " <br> <a href='https://duo.com/docs/adminapi'" \
        " target='_blank'>Duo Security API Documentation</a>.",

      execute: lambda do |connection, input|
        verb = input['verb']
        error("#{verb} not supported") if %w[get post delete].exclude?(verb)
        data = input.dig('input', 'data').presence || {}

        case verb
        when 'get'
          endpoint = input['path']
          formatted_date = call('get_formatted_date', 'date' => now)
          basic_auth_header = call('genarate_signature',
                                   'connection' => connection,
                                   'endpoint' => endpoint,
                                   'method' => 'GET',
                                   'data' => data,
                                   'date' => formatted_date)

          response =
            get(endpoint, data)
            .headers('Date' => formatted_date,
                     'Authorization' => "Basic #{basic_auth_header}")
            .after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact

          if response.is_a?(Array)
            array_name = parse_json(input['output'] || '[]')
                         .dig(0, 'name') || 'array'
            { array_name.to_s => response }
          elsif response.is_a?(Hash)
            response
          else
            error('API response is not a JSON')
          end
        when 'post'
          endpoint = input['path']
          formatted_date = call('get_formatted_date', 'date' => now)
          basic_auth_header = call('genarate_signature',
                                   'connection' => connection,
                                   'endpoint' => endpoint,
                                   'method' => 'POST',
                                   'data' => data,
                                   'date' => formatted_date)

          post(endpoint, data)
            .headers('Date' => formatted_date,
                     'Authorization' => "Basic #{basic_auth_header}")
            .request_format_www_form_urlencoded
            .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.compact
        when 'delete'
          endpoint = input['path']
          formatted_date = call('get_formatted_date', 'date' => now)
          basic_auth_header = call('genarate_signature',
                                   'connection' => connection,
                                   'endpoint' => endpoint,
                                   'method' => 'DELETE',
                                   'data' => data,
                                   'date' => formatted_date)

          delete(endpoint, data)
            .headers('Date' => formatted_date,
                     'Authorization' => "Basic #{basic_auth_header}")
            .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.compact
        end
      end,

      config_fields: [{
        name: 'verb',
        label: 'Request type',
        hint: 'Select HTTP method of the request',
        optional: false,
        control_type: 'select',
        pick_list: %w[get post delete].map { |verb| [verb.upcase, verb] }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['custom_action_input']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['custom_action_output']
      end
    },

    search_users: {
      description: "Search <span class='provider'>users</span> " \
        "in <span class='provider'>Duo Security</span>",
      help: "Fetches the users that match the search criteria. Returns a \
        maximum of 100 records.<br/>
        <b> Note: Check if you have required permissions enabled under Settings
        section of Admin API application page</b>",

      execute: lambda do |connection, input|
        endpoint = '/admin/v1/users'
        formatted_date = call('get_formatted_date', 'date' => now)
        basic_auth_header = call('genarate_signature',
                                 'connection' => connection,
                                 'endpoint' => endpoint,
                                 'method' => 'GET',
                                 'data' => input,
                                 'date' => formatted_date)

        {
          users: get(endpoint, input)
            .headers('Date' => formatted_date,
                     'Authorization' => "Basic #{basic_auth_header}")
            .[]('response')
        }
      end,

      input_fields: lambda do |_object_definitions|
        [{
          name: 'username',
          hint: 'Specify a username to look up a single user',
          sticky: true
        }]
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'users',
          type: 'array',
          of: 'object',
          properties: object_definitions['user']
        }]
      end,

      sample_output: lambda do |connection, _input|
        endpoint = '/admin/v1/users'
        data = { limit: 1 }
        formatted_date = call('get_formatted_date', 'date' => now)
        basic_auth_header = call('genarate_signature',
                                 'connection' => connection,
                                 'endpoint' => endpoint,
                                 'method' => 'GET',
                                 'data' => data,
                                 'date' => formatted_date)

        {
          users: get(endpoint, data)
            .headers('Date' => formatted_date,
                     'Authorization' => "Basic #{basic_auth_header}")
            .[]('response')
        }
      end
    },

    update_user: {
      description: "Update <span class='provider'>user</span> " \
        "in <span class='provider'>Duo Security</span>",

      input_fields: lambda do |object_definitions|
        object_definitions['user']
          .only('user_id', 'username', 'alias1', 'alias2', 'alias3', 'alias4',
                'realname', 'email', 'status', 'notes', 'firstname', 'lastname')
          .required('user_id')
      end,

      execute: lambda do |connection, input|
        user_id = input.delete('user_id')
        endpoint = "/admin/v1/users/#{user_id}"
        formatted_date = call('get_formatted_date', 'date' => now)
        basic_auth_header = call('genarate_signature',
                                 'connection' => connection,
                                 'endpoint' => endpoint,
                                 'method' => 'POST',
                                 'data' => input,
                                 'date' => formatted_date)

        post(endpoint, input)
          .headers('Date' => formatted_date,
                   'Authorization' => "Basic #{basic_auth_header}")
          .request_format_www_form_urlencoded
          .[]('response')
      end,

      output_fields: ->(object_definitions) { object_definitions['user'] },

      sample_output: lambda do |connection, _input|
        endpoint = '/admin/v1/users'
        data = { limit: 1 }
        formatted_date = call('get_formatted_date', 'date' => now)
        basic_auth_header = call('genarate_signature',
                                 'connection' => connection,
                                 'endpoint' => endpoint,
                                 'method' => 'GET',
                                 'data' => data,
                                 'date' => formatted_date)

        get(endpoint, data)
          .headers('Date' => formatted_date,
                   'Authorization' => "Basic #{basic_auth_header}")
          .dig('response', 0)
      end
    }
  },

  triggers: {
    new_authentication_event: {
      description: "New <span class='provider'>authentication</span> event " \
        "in <span class='provider'>Duo Security</span>",
      type: 'paging_desc',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'since',
            label: 'When first started, this recipe should pick up events from',
            hint: 'When you start recipe for the first time, it picks up ' \
              'trigger events from this specified date and time. Leave ' \
              'empty to get events created one hour ago',
            sticky: true,
            optional: true,
            type: 'timestamp'
          },
          {
            name: 'results',
            hint: 'The result of an authentication attempt. One of:' \
            '<b>"sucess"</b> - Return “successful“ authentication '\
            'events.  <br/> <b>"denied"</b>  - Return “denied“ authentication '\
            'events. <br/> <b>"fraud"</b> - Return “fraudulent“ ' \
            'authentication events.',
            sticky: true,
            control_type: 'select',
            pick_list: 'results'
          }
        ]
      end,

      poll: lambda do |connection, input, next_offset|
        page_size = 1000
        data = {
          limit: page_size,
          sort: 'ts:desc',
          mintime: (input['since'] || 1.hour.ago).to_i * 1000,
          maxtime: next_offset.presence || (now.to_i * 1000 - 1),
          results: input['results'],
          event_types: 'authentication'
        }.compact
        endpoint = '/admin/v2/logs/authentication'
        formatted_date = call('get_formatted_date', 'date' => now)
        basic_auth_header = call('genarate_signature',
                                 'connection' => connection,
                                 'endpoint' => endpoint,
                                 'method' => 'GET',
                                 'data' => data,
                                 'date' => formatted_date)

        response = get(endpoint, data)
                   .headers('Date' => formatted_date,
                            'Authorization' => "Basic #{basic_auth_header}")
                   .[]('response')
        next_page_exist = (response.dig('metadata', 'total_objects') || 0) >
                          page_size

        {
          events: response['authlogs'],
          next_page: if next_page_exist
                       response.dig('metadata', 'next_offset', 0)
                     end
        }
      end,

      document_id: ->(authlog) { authlog['txid'] },

      sort_by: ->(authlog) { authlog['timestamp'] },

      output_fields: ->(object_definitions) { object_definitions['authlog'] },

      sample_output: lambda do |connection, input|
        data = {
          limit: 1,
          sort: 'ts:desc',
          mintime: (input['since'] || 1.hour.ago).to_i * 1000,
          maxtime: (now.to_i * 1000 - 1),
          results: 'success',
          event_types: 'authentication'
        }.compact
        endpoint = '/admin/v2/logs/authentication'
        formatted_date = call('get_formatted_date', 'date' => now)
        basic_auth_header = call('genarate_signature',
                                 'connection' => connection,
                                 'endpoint' => endpoint,
                                 'method' => 'GET',
                                 'data' => data,
                                 'date' => formatted_date)

        get('/admin/v2/logs/authentication', data)
          .headers('Date' => formatted_date,
                   'Authorization' => "Basic #{basic_auth_header}")
          .dig('response', 'authlogs', 0) || {}
      end
    }
  },

  pick_lists: {
    statuses: lambda do |_connection|
      [%w[Active active], %w[Bypass bypass],
       %w[Disabled disabled], %w[Locked\ out locked\ out]]
    end,

    results: lambda do |_connection|
      [%w[Sucess sucess], %w[Denied denied], %w[Fraud fraud]]
    end
  }
}
