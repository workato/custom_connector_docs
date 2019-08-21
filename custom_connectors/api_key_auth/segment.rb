{
  title: 'Segment',

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

    get_formatted_update_data: lambda do |input|
      key = input.keys[0]
      data = input[key]

      {
        update_mask: {
          paths: call('get_update_mask_path', 'data' => data, 'root' => key)
        },
        key => data
      }
    end,

    get_update_mask_path: lambda do |input|
      root = input['root']

      input['data'].keys.map { |key| "#{root}.#{key}" }
    end,

    get_common_fields_sample_data: lambda do
      {
        'anonymousId' => '507f191e810c19729de860ea',
        'context' => {
          'active' => true,
          'app' => {
            'name' => 'InitechGlobal',
            'version' => '545',
            'build' => '3.0.1.545',
            'namespace' => 'com.production.segment'
          },
          'campaign' => {
            'name' => 'TPS Innovation Newsletter',
            'source' => 'Newsletter',
            'medium' => 'email',
            'term' => 'tps reports',
            'content' => 'image link'
          },
          'device' => {
            'id' => 'B5372DB0-C21E-11E4-8DFC-AA07A5B093DB',
            'advertisingId' => '7A3CBEA0-BDF5-11E4-8DFC-AA07A5B093DB',
            'adTrackingEnabled' => true,
            'manufacturer' => 'Apple',
            'model' => 'iPhone7,2',
            'name' => 'maguro',
            'type' => 'ios',
            'token' => 'ff15bc0c20c4aa6cd50854ff165fd265c838e5405bfeb95710' \
            '66395b8c9da449'
          },
          'ip' => '8.8.8.8',
          'library' => {
            'name' => 'analytics.js',
            'version' => '2.11.1'
          },
          'locale' => 'nl-NL',
          'location' => {
            'city' => 'San Francisco',
            'country' => 'United States',
            'latitude' => 40.2964197,
            'longitude' => -76.9411617,
            'speed' => 0
          },
          'network' => {
            'bluetooth' => false,
            'carrier' => 'T-Mobile NL',
            'cellular' => true,
            'wifi' => false
          },
          'os' => {
            'name' => 'iPhone OS',
            'version' => '8.1.3'
          },
          'page' => {
            'path' => '/academy/',
            'referrer' => '',
            'search' => '',
            'title' => 'Analytics Academy',
            'url' => 'https://segment.com/academy/'
          },
          'referrer' => {
            'id' => 'ABCD582CDEFFFF01919',
            'type' => 'dataxu'
          },
          'screen' => {
            'width' => 320,
            'height' => 568,
            'density' => 2
          },
          'groupId' => '12345',
          'timezone' => 'Europe/Amsterdam',
          'userAgent' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac ' \
          'OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 ' \
          'Mobile/13B143 Safari/601.1'
        },
        'integrations' => {
          'All' => true,
          'Mixpanel' => false,
          'Salesforce' => false
        },
        'messageId' => '022bb90c-bbac-11e4-8dfc-aa07a5b093db',
        'receivedAt' => '2015-12-10T04:08:31.909Z',
        'sentAt' => '2015-12-10T04:08:31.581Z',
        'timestamp' => '2015-12-10T04:08:31.905Z',
        'userId' => '97980cfea0067',
        'version' => 2
      }
    end
  },

  connection: {
    fields: [
      {
        name: 'workspace',
        hint: 'Provide the workspace name here. You can find workspace name ' \
        'from instance URL, eg: if instance URL is https://app.segment.com' \
        '/<b>acme</b>/home, then acme is your workspace.',
        optional: false
      },
      {
        name: 'access_token',
        hint: 'Create access token by navigating to - Workspace ' \
        'Settings > Access Management > Tokens.',
        optional: false,
        control_type: 'password'
      }
    ],

    authorization: {
      type: 'api_key',

      apply: lambda do |connection|
        headers('Authorization' => "Bearer #{connection['access_token']}")
      end
    },

    base_uri: ->(_connection) { 'https://platform.segmentapis.com' }
  },

  test: ->(connection) { get("/v1beta/workspaces/#{connection['workspace']}") },

  object_definitions: {
    alias: {
      fields: ->(_connection, _config_fields) { [{ name: 'previousId' }] }
    },

    common_fields: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'anonymousId' },
          {
            name: 'context',
            type: 'object',
            properties: [
              {
                name: 'active',
                control_type: 'checkbox',
                type: 'boolean',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  label: 'Active',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'active'
                }
              },
              {
                name: 'app',
                type: 'object',
                properties: [
                  { name: 'name' },
                  { name: 'version' },
                  { name: 'build' },
                  { name: 'namespace' }
                ]
              },
              {
                name: 'campaign',
                type: 'object',
                properties: [
                  { name: 'name' },
                  { name: 'source' },
                  { name: 'medium' },
                  { name: 'term' },
                  { name: 'content' }
                ]
              },
              {
                name: 'device',
                type: 'object',
                properties: [
                  { name: 'id' },
                  { name: 'advertisingId' },
                  {
                    name: 'adTrackingEnabled',
                    control_type: 'checkbox',
                    type: 'boolean',
                    toggle_hint: 'Select from option list',
                    toggle_field: {
                      label: 'Ad tracking enabled',
                      control_type: 'text',
                      toggle_hint: 'Use custom value',
                      type: 'boolean',
                      name: 'adTrackingEnabled'
                    }
                  },
                  { name: 'manufacturer' },
                  { name: 'model' },
                  { name: 'name' },
                  { name: 'type' },
                  { name: 'token' }
                ]
              },
              { name: 'ip', label: 'IP' },
              {
                name: 'library',
                type: 'object',
                properties: [{ name: 'name' }, { name: 'version' }]
              },
              { name: 'locale' },
              {
                name: 'location',
                type: 'object',
                properties: [
                  { name: 'city' },
                  { name: 'country' },
                  {
                    name: 'latitude',
                    parse_output: 'float_conversion',
                    type: 'number'
                  },
                  {
                    name: 'longitude',
                    parse_output: 'float_conversion',
                    type: 'number'
                  },
                  {
                    name: 'speed',
                    parse_output: 'float_conversion',
                    type: 'number'
                  }
                ]
              },
              {
                name: 'network',
                type: 'object',
                properties: [
                  {
                    name: 'bluetooth',
                    control_type: 'checkbox',
                    type: 'boolean',
                    toggle_hint: 'Select from option list',
                    toggle_field: {
                      label: 'Bluetooth',
                      control_type: 'text',
                      toggle_hint: 'Use custom value',
                      type: 'boolean',
                      name: 'bluetooth'
                    }
                  },
                  { name: 'carrier' },
                  {
                    name: 'cellular',
                    type: 'boolean',
                    control_type: 'checkbox',
                    toggle_hint: 'Select from option list',
                    toggle_field: {
                      label: 'Cellular',
                      control_type: 'text',
                      toggle_hint: 'Use custom value',
                      type: 'boolean',
                      name: 'cellular'
                    }
                  },
                  {
                    name: 'wifi',
                    label: 'Wi-Fi',
                    control_type: 'checkbox',
                    type: 'boolean',
                    toggle_hint: 'Select from option list',
                    toggle_field: {
                      label: 'Wi-Fi',
                      control_type: 'text',
                      toggle_hint: 'Use custom value',
                      type: 'boolean',
                      name: 'wifi'
                    }
                  }
                ]
              },
              {
                name: 'os',
                label: 'OS',
                type: 'object',
                properties: [{ name: 'name' }, { name: 'version' }]
              },
              {
                name: 'page',
                label: 'Page',
                type: 'object',
                properties: [
                  { name: 'hash' },
                  { name: 'path' },
                  { name: 'referrer' },
                  { name: 'search' },
                  { name: 'title' },
                  { name: 'url', label: 'URL' }
                ]
              },
              {
                name: 'referrer',
                type: 'object',
                properties: [{ name: 'id' }, { name: 'type' }]
              },
              {
                name: 'screen',
                type: 'object',
                properties: [
                  {
                    name: 'width',
                    parse_output: 'float_conversion',
                    type: 'number'
                  },
                  {
                    name: 'height',
                    parse_output: 'float_conversion',
                    type: 'number'
                  },
                  {
                    name: 'density',
                    parse_output: 'float_conversion',
                    type: 'number'
                  }
                ]
              },
              { name: 'timezone' },
              { name: 'groupId' },
              {
                name: 'traits',
                type: 'object',
                properties: [
                  {
                    name: 'address',
                    type: 'object',
                    properties: [
                      { name: 'street' },
                      { name: 'city' },
                      { name: 'state' },
                      { name: 'postalCode' },
                      { name: 'country' }
                    ]
                  },
                  { name: 'age', type: 'number' },
                  { name: 'avatar', control_type: 'url' },
                  { name: 'birthday', control_type: 'date', type: 'date' },
                  {
                    name: 'company',
                    type: 'object',
                    properties: [
                      { name: 'name' },
                      { name: 'id' },
                      { name: 'industry' },
                      { name: 'employee_count', type: 'number' },
                      { name: 'plan' }
                    ]
                  },
                  {
                    name: 'createdAt',
                    control_type: 'date_time',
                    render_input: 'date_time_conversion',
                    parse_output: 'date_time_conversion',
                    type: 'date_time'
                  },
                  { name: 'description' },
                  { name: 'email', control_type: 'email' },
                  { name: 'firstName' },
                  { name: 'gender' },
                  { name: 'id' },
                  { name: 'lastName' },
                  { name: 'name' },
                  { name: 'phone', control_type: 'phone' },
                  { name: 'title' },
                  { name: 'username' },
                  { name: 'website' }
                ]
              },
              { name: 'userAgent' }
            ]
          },
          {
            name: 'integrations',
            type: 'object',
            properties: [
              {
                name: 'All',
                control_type: 'checkbox',
                type: 'boolean',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'All',
                  label: 'All',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean'
                }
              },
              {
                name: 'Mixpanel',
                control_type: 'checkbox',
                type: 'boolean',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'Mixpanel',
                  label: 'Mixpanel',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean'
                }
              },
              {
                name: 'Salesforce',
                type: 'boolean',
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'Salesforce',
                  label: 'Salesforce',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean'
                }
              }
            ]
          },
          { name: 'messageId' },
          {
            name: 'receivedAt',
            control_type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time'
          },
          {
            name: 'sentAt',
            control_type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time'
          },
          {
            name: 'timestamp',
            control_type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time'
          },
          { name: 'type' },
          { name: 'userId' },
          {
            name: 'version',
            control_type: 'number',
            parse_output: 'float_conversion',
            type: 'number'
          }
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
            hint: 'Base URI is <b>https://platform.segmentapis.com</b> - ' \
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

    destination: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'name',
            hint: 'Fully qualified destination name, e.g. ' \
            'workspaces/acme/sources/javascript/destinations/workato/',
            sticky: true
          },
          { name: 'parent' },
          { name: 'display_name', sticky: true },
          {
            name: 'enabled',
            sticky: true,
            control_type: 'checkbox',
            type: 'boolean',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'enabled',
              label: 'Enabled',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean'
            }
          },
          {
            name: 'connection_mode',
            sticky: true,
            control_type: 'select',
            pick_list: 'connection_modes',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'connection_mode',
              label: 'Connection mode',
              hint: 'Allowed values are: CLOUD, DEVICE',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'config',
            sticky: true,
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'name',
                hint: 'Fully qualified config name, e.g. ' \
                'workspaces/acme/sources/javascript/destinations/workato' \
                '/config/apiKey'
              },
              { name: 'display_name', sticky: true },
              { name: 'value', sticky: true },
              # TODO: revisit this later... { name: 'type' }
            ]
          },
          { name: 'create_time', type: 'date_time' },
          { name: 'update_time', type: 'date_time' }
        ]
      end
    },

    identify: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'traits',
            type: 'object',
            properties: [
              {
                name: 'address',
                type: 'object',
                properties: [
                  { name: 'street' },
                  { name: 'city' },
                  { name: 'state' },
                  { name: 'postalCode' },
                  { name: 'country' }
                ]
              },
              { name: 'age', type: 'number' },
              { name: 'avatar', control_type: 'url' },
              { name: 'birthday', control_type: 'date', type: 'date' },
              {
                name: 'company',
                type: 'object',
                properties: [
                  { name: 'name' },
                  { name: 'id' },
                  { name: 'industry' },
                  { name: 'employee_count', type: 'number' },
                  { name: 'plan' }
                ]
              },
              {
                name: 'createdAt',
                control_type: 'date_time',
                render_input: 'date_time_conversion',
                parse_output: 'date_time_conversion',
                type: 'date_time'
              },
              { name: 'description' },
              { name: 'email', control_type: 'email' },
              { name: 'firstName' },
              { name: 'gender' },
              { name: 'id' },
              { name: 'lastName' },
              { name: 'name' },
              { name: 'phone', control_type: 'phone' },
              { name: 'title' },
              { name: 'username' },
              { name: 'website' },
              {
                name: 'logins',
                parse_output: 'float_conversion',
                type: 'number'
              },
              { name: 'plan' }
            ]
          },
          { name: 'channel' }
        ]
      end
    },

    group: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'groupId' },
          {
            name: 'traits',
            type: 'object',
            properties: [
              {
                name: 'address',
                type: 'object',
                properties: [
                  { name: 'street' },
                  { name: 'city' },
                  { name: 'state' },
                  { name: 'postalCode' },
                  { name: 'country' }
                ]
              },
              { name: 'avatar', control_type: 'url' },
              {
                name: 'createdAt',
                control_type: 'date_time',
                render_input: 'date_time_conversion',
                parse_output: 'date_time_conversion',
                type: 'date_time'
              },
              { name: 'description' },
              { name: 'email', control_type: 'email' },
              { name: 'employees' },
              { name: 'id' },
              { name: 'industry' },
              { name: 'name' },
              { name: 'phone', control_type: 'phone' },
              { name: 'website' },
              { name: 'plan' }
            ]
          },
          { name: 'channel' }
        ]
      end
    },

    page: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'name' },
          {
            name: 'properties',
            type: 'object',
            properties: [
              { name: 'name' },
              { name: 'path' },
              { name: 'referrer' },
              { name: 'search' },
              { name: 'title' },
              { name: 'url', label: 'URL' },
              { name: 'keywords', type: 'array', of: 'string' }
            ]
          },
          { name: 'channel' }
        ]
      end
    },

    screen: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'name' },
          {
            name: 'properties',
            type: 'object',
            properties: [{ name: 'name' }, { name: 'variation' }]
          },
          { name: 'channel' }
        ]
      end
    },

    source: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'name' },
          { name: 'parent' },
          { name: 'catalog_name' },
          { name: 'write_keys', type: 'array', of: 'string' },
          {
            name: 'library_config',
            type: 'object',
            properties: [
              {
                name: 'metrics_enabled',
                control_type: 'checkbox',
                type: 'boolean',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'metrics_enabled',
                  label: 'Metrics enabled',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean'
                }
              },
              {
                name: 'retry_queue',
                control_type: 'checkbox',
                type: 'boolean',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'retry_queue',
                  label: 'Retry queue',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean'
                }
              },
              {
                name: 'cross_domain_id_enabled',
                control_type: 'checkbox',
                type: 'boolean',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'cross_domain_id_enabled',
                  label: 'Cross domain ID enabled',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean'
                }
              },
              { name: 'api_host', label: 'API host' }
            ]
          },
          { name: 'create_time', control_type: 'date_time', type: 'date_time' }
        ]
      end
    },

    track: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'event' },
          {
            name: 'properties',
            type: 'object',
            properties: [
              { name: 'name' },
              { name: 'title' },
              { name: 'plan' },
              { name: 'accountType' },
              { name: 'revenue', type: 'number' },
              { name: 'currency' },
              { name: 'value', type: 'number' }
            ]
          }
        ]
      end
    }
  },

  actions: {
    # Custom action for Segment
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
      "in <span class='provider'>Segment</span>",

      help: {
        body: 'Build your own Segment action with an HTTP request. The ' \
          'request will be authorized with your Segment connection.',
        learn_more_url: 'https://segment.com/docs/config-api/',
        learn_more_text: 'Segment API Documentation'
      },

      execute: lambda do |_connection, input|
        verb = input['verb']
        data = input.dig('input', 'data').presence || {}

        case verb
        when 'get'
          response =
            get(input['path'], data)
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
          post(input['path'], data)
            .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.compact
        when 'put'
          put(input['path'], data)
            .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.compact
        when 'patch'
          patch(input['path'], data)
            .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.compact
        when 'delete'
          delete(input['path'], data)
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
        pick_list: %w[get post put patch delete]
          .map { |verb| [verb.upcase, verb] }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['custom_action_input']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['custom_action_output']
      end
    },

    # Destinations
    create_destination: {
      description: "Create <span class='provider'>destination</span> " \
      "in <span class='provider'>Segment</span>",

      execute: lambda do |_connection, input|
        post("/v1beta/#{input.delete('source')}/destinations",
             destination: input)
      end,

      input_fields: lambda do |object_definitions|
        [{
          name: 'source',
          optional: false,
          control_type: 'select',
          pick_list: 'sources',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'source',
            label: 'Source',
            hint: 'Fully qualified source name, e.g. ' \
            'workspaces/acme/sources/javascript',
            toggle_hint: 'Use custom value',
            control_type: 'text',
            type: 'string'
          }
        }].concat(object_definitions['destination']
          .ignored('parent', 'display_name', 'create_time', 'update_time')
          .required('name', 'connection_mode'))
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['destination']
      end,

      sample_output: lambda do |connection, _input|
        source = get("/v1beta/workspaces/#{connection['workspace']}/sources",
                     page_size: 1)&.dig('sources', 0, 'name')
        get("/v1beta/#{source}/destinations", page_size: 1)
          .dig('destinations', 0)
      end
    },

    create_workato_destination: {
      title: 'Create Workato destination',
      description: "Create <span class='provider'>Workato</span> " \
      "destination in <span class='provider'>Segment</span>",

      execute: lambda do |_connection, input|
        if (api_key = input['api_key']).length < 8
          error("Please double check your API key. It should be at least 8 ' \
          'characters long.")
        end
        workato_dest = {
          name: "#{input['source']}/destinations/workato",
          enabled: true,
          connection_mode: 'CLOUD',
          config: [
            {
              name: "#{input['source']}/destinations/workato/config" \
              '/staticWebhookUri',
              value: input['static_webhook_uri']
            },
            {
              name: "#{input['source']}/destinations/workato/config/apiKey",
              value: api_key
            }
          ]
        }

        post("/v1beta/#{input.delete('source')}/destinations",
             destination: workato_dest)
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'source',
            optional: false,
            control_type: 'select',
            pick_list: 'sources',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'source',
              label: 'Source',
              hint: 'Fully qualified source name, e.g. ' \
              'workspaces/acme/sources/javascript',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'api_key',
            label: 'API key',
            hint: 'Provide a string with a minimum 8-characters long as ' \
            'API key for the Segment destination connection settings. Later, ' \
            'this key is used to validate incoming requests in the triggers.',
            control_type: 'password',
            optional: false
          },
          {
            name: 'static_webhook_uri',
            label: 'Static webhook URI',
            hint: 'Provide static webhook URI of the Segment connector ' \
            'installed in your account. Go to <b>Tools > Connector SDK > ' \
            'Segment</b> and copy the static webhook URI.',
            optional: false
          }
        ]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['destination']
      end,

      sample_output: lambda do |connection, _input|
        source = get("/v1beta/workspaces/#{connection['workspace']}/sources",
                     page_size: 1)&.dig('sources', 0, 'name')
        get("/v1beta/#{source}/destinations", page_size: 1)
          .dig('destinations', 0)
      end
    },

    get_destinations_by_source: {
      description: "Get <span class='provider'>destinations</span> by source " \
      "in <span class='provider'>Segment</span>",

      execute: lambda do |_connection, input|
        get("/v1beta/#{input['source']}/destinations")
      end,

      input_fields: lambda do |_object_definitions|
        [{
          name: 'source',
          optional: false,
          control_type: 'select',
          pick_list: 'sources',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'source',
            label: 'Source',
            hint: 'Fully qualified source name, e.g. ' \
            'workspaces/acme/sources/javascript',
            toggle_hint: 'Use custom value',
            control_type: 'text',
            type: 'string'
          }
        }]
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'destinations',
          type: 'array',
          of: 'object',
          properties: object_definitions['destination']
        }]
      end,

      sample_output: lambda do |connection, _input|
        source = get("/v1beta/workspaces/#{connection['workspace']}/sources",
                     page_size: 1)&.dig('sources', 0, 'name')
        get("/v1beta/#{source}/destinations", page_size: 1)
      end
    },

    update_destination: {
      description: "Update <span class='provider'>destination</span> " \
      "in <span class='provider'>Segment</span>",

      execute: lambda do |_connection, input|
        input.delete('source')
        destination = input.delete('destination')
        patch("/v1beta/#{destination}",
              call('get_formatted_update_data', destination: input))
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      input_fields: lambda do |object_definitions|
        [
          {
            name: 'source',
            optional: false,
            control_type: 'select',
            pick_list: 'sources',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'source',
              label: 'Source',
              hint: 'Fully qualified source name, e.g. ' \
              'workspaces/acme/sources/javascript',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'destination',
            optional: false,
            control_type: 'select',
            pick_list: 'destinations',
            pick_list_params: { source: 'source' },
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'destination',
              label: 'Destination',
              hint: 'Fully qualified source name, e.g. ' \
              'workspaces/acme/sources/javascript/destinations/workato',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          }
        ].concat(object_definitions['destination']
                 .ignored('name', 'parent', 'display_name', 'create_time',
                          'update_time'))
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['destination']
      end,

      sample_output: lambda do |connection, _input|
        source = get("/v1beta/workspaces/#{connection['workspace']}/sources",
                     page_size: 1)&.dig('sources', 0, 'name')
        get("/v1beta/#{source}/destinations", page_size: 1)
          .dig('destinations', 0)
      end
    },

    # Sources
    list_sources: {
      description: "List <span class='provider'>sources</span> in " \
      "<span class='provider'>Segment</span>",

      execute: lambda do |connection, _input|
        get("/v1beta/workspaces/#{connection['workspace']}/sources")
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'sources',
          type: 'array',
          of: 'object',
          properties: object_definitions['source']
        }]
      end,

      sample_output: lambda do |connection, _input|
        get("/v1beta/workspaces/#{connection['workspace']}/sources",
            page_size: 1)
      end
    },

    get_source_by_name: {
      description: "Get <span class='provider'>source</span> " \
      "by name in <span class='provider'>Segment</span>",

      execute: lambda do |_connection, input|
        get("/v1beta/#{input['name']}")
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      input_fields: lambda do |_object_definitions|
        [{
          name: 'name',
          hint: 'Fully qualified source name, e.g. ' \
          'workspaces/acme/sources/javascript',
          optional: false
        }]
      end,

      output_fields: ->(object_definitions) { object_definitions['source'] },

      sample_output: lambda do |connection, _input|
        get("/v1beta/workspaces/#{connection['workspace']}/sources",
            page_size: 1)
      end
    }
  },

  webhook_keys: lambda do |_params, headers, payload|
    "type=#{payload['type']};auth=#{headers['Authorization']}"
  end,

  triggers: {
    new_alias_event: {
      description: "New <span class='provider'>alias</span> event " \
      "in <span class='provider'>Segment</span>",
      help: 'An <b>active</b> Workato destination is required to use this ' \
      'trigger',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'source',
            optional: false,
            control_type: 'select',
            pick_list: 'sources',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'source',
              label: 'Source',
              hint: 'Fully qualified source name, e.g. ' \
              'workspaces/acme/sources/javascript',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'api_key',
            label: 'Destination',
            optional: false,
            control_type: 'select',
            pick_list: 'destination_api_key',
            pick_list_params: { source: 'source' }
          }
        ]
      end,

      webhook_key: lambda do |_connection, input|
        "type=alias;auth=Basic #{"#{input['api_key']}:".encode_base64}"
      end,

      webhook_notification: ->(_connection, payload) { payload },

      dedup: ->(event) { "#{event['type']}@#{event['messageId']}" },

      output_fields: lambda do |object_definitions|
        object_definitions['alias']
          .concat(object_definitions['common_fields'])
      end,

      sample_output: lambda do |_connection, _input|
        call('get_common_fields_sample_data')
          .merge('type' => 'alias',
                 'previousId' => 'jen@email.com',
                 'userId' => '507f191e81')
      end
    },

    new_group_event: {
      description: "New <span class='provider'>group</span> event " \
      "in <span class='provider'>Segment</span>",
      help: 'An <b>active</b> Workato destination is required to use this ' \
      'trigger',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'source',
            optional: false,
            control_type: 'select',
            pick_list: 'sources',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'source',
              label: 'Source',
              hint: 'Fully qualified source name, e.g. ' \
              'workspaces/acme/sources/javascript',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'api_key',
            label: 'Destination',
            optional: false,
            control_type: 'select',
            pick_list: 'destination_api_key',
            pick_list_params: { source: 'source' }
          }
        ]
      end,

      webhook_key: lambda do |_connection, input|
        "type=group;auth=Basic #{"#{input['api_key']}:".encode_base64}"
      end,

      webhook_notification: ->(_connection, payload) { payload },

      dedup: ->(event) { "#{event['type']}@#{event['messageId']}" },

      output_fields: lambda do |object_definitions|
        object_definitions['group']
          .concat(object_definitions['common_fields'])
      end,

      sample_output: lambda do |_connection, _input|
        call('get_common_fields_sample_data')
          .merge('type' => 'group',
                 'groupId' => '0e8c78ea9d97a7b8185e8632',
                 'traits' => {
                   'name' => 'Initech',
                   'industry' => 'Technology',
                   'employees' => 329,
                   'plan' => 'enterprise',
                   'total billed' => 830
                 })
      end
    },

    new_identify_event: {
      description: "New <span class='provider'>identify</span> event " \
      "in <span class='provider'>Segment</span>",
      help: 'An <b>active</b> Workato destination is required to use this ' \
      'trigger',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'source',
            optional: false,
            control_type: 'select',
            pick_list: 'sources',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'source',
              label: 'Source',
              hint: 'Fully qualified source name, e.g. ' \
              'workspaces/acme/sources/javascript',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'api_key',
            label: 'Destination',
            optional: false,
            control_type: 'select',
            pick_list: 'destination_api_key',
            pick_list_params: { source: 'source' }
          }
        ]
      end,

      webhook_key: lambda do |_connection, input|
        "type=identify;auth=Basic #{"#{input['api_key']}:".encode_base64}"
      end,

      webhook_notification: ->(_connection, payload) { payload },

      dedup: ->(event) { "#{event['type']}@#{event['messageId']}" },

      output_fields: lambda do |object_definitions|
        object_definitions['identify']
          .concat(object_definitions['common_fields'])
      end,

      sample_output: lambda do |_connection, _input|
        call('get_common_fields_sample_data')
          .merge('type' => 'identify',
                 'traits' => {
                   'name' => 'Peter Gibbons',
                   'email' => 'peter@initech.com',
                   'plan' => 'premium',
                   'logins' => 5
                 },
                 'userId' => '97980cfea0067')
      end
    },

    new_page_event: {
      description: "New <span class='provider'>page</span> event " \
      "in <span class='provider'>Segment</span>",
      help: 'An <b>active</b> Workato destination is required to use this ' \
      'trigger',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'source',
            optional: false,
            control_type: 'select',
            pick_list: 'sources',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'source',
              label: 'Source',
              hint: 'Fully qualified source name, e.g. ' \
              'workspaces/acme/sources/javascript',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'api_key',
            label: 'Destination',
            optional: false,
            control_type: 'select',
            pick_list: 'destination_api_key',
            pick_list_params: { source: 'source' }
          }
        ]
      end,

      webhook_key: lambda do |_connection, input|
        "type=page;auth=Basic #{"#{input['api_key']}:".encode_base64}"
      end,

      webhook_notification: ->(_connection, payload) { payload },

      dedup: ->(event) { "#{event['type']}@#{event['messageId']}" },

      output_fields: lambda do |object_definitions|
        object_definitions['page']
          .concat(object_definitions['common_fields'])
      end,

      sample_output: lambda do |_connection, _input|
        call('get_common_fields_sample_data')
          .merge('type' => 'page',
                 'name' => 'Home',
                 'properties' => {
                   'title' => 'Welcome | Initech',
                   'url' => 'http://www.initech.com'
                 })
      end
    },

    new_track_event: {
      description: "New <span class='provider'>track</span> event " \
      "in <span class='provider'>Segment</span>",
      help: 'An <b>active</b> Workato destination is required to use this ' \
      'trigger',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'source',
            optional: false,
            control_type: 'select',
            pick_list: 'sources',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'source',
              label: 'Source',
              hint: 'Fully qualified source name, e.g. ' \
              'workspaces/acme/sources/javascript',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'api_key',
            label: 'Destination',
            optional: false,
            control_type: 'select',
            pick_list: 'destination_api_key',
            pick_list_params: { source: 'source' }
          }
        ]
      end,

      webhook_key: lambda do |_connection, input|
        "type=track;auth=Basic #{"#{input['api_key']}:".encode_base64}"
      end,

      webhook_notification: ->(_connection, payload) { payload },

      dedup: ->(event) { "#{event['type']}@#{event['messageId']}" },

      output_fields: lambda do |object_definitions|
        object_definitions['track']
          .concat(object_definitions['common_fields'])
      end,

      sample_output: lambda do |_connection, _input|
        call('get_common_fields_sample_data')
          .merge('type' => 'track',
                 'event' => 'Registered',
                 'properties' => {
                   'plan' => 'Pro Annual',
                   'accountType' => 'Facebook'
                 })
      end
    },

    new_screen_event: {
      description: "New <span class='provider'>screen</span> event " \
      "in <span class='provider'>Segment</span>",
      help: 'An <b>active</b> Workato destination is required to use this ' \
      'trigger',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'source',
            optional: false,
            control_type: 'select',
            pick_list: 'sources',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'source',
              label: 'Source',
              hint: 'Fully qualified source name, e.g. ' \
              'workspaces/acme/sources/javascript',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'api_key',
            label: 'Destination',
            optional: false,
            control_type: 'select',
            pick_list: 'destination_api_key',
            pick_list_params: { source: 'source' }
          }
        ]
      end,

      webhook_key: lambda do |_connection, input|
        "type=screen;auth=Basic #{"#{input['api_key']}:".encode_base64}"
      end,

      webhook_notification: ->(_connection, payload) { payload },

      dedup: ->(event) { "#{event['type']}@#{event['messageId']}" },

      output_fields: lambda do |object_definitions|
        object_definitions['screen']
          .concat(object_definitions['common_fields'])
      end,

      sample_output: lambda do |_connection, _input|
        call('get_common_fields_sample_data')
          .merge('type' => 'screen',
                 'name' => 'Home',
                 'properties' => {
                   'Feed Type' => 'private'
                 })
      end
    }
  },

  pick_lists: {
    connection_modes: lambda do |_connection|
      [%w[Cloud CLOUD], %w[Device DEVICE]]
    end,

    destination_api_key: lambda do |_connection, source:|
      workato_dest =
        get("/v1beta/#{source}/destinations/workato")
        .after_error_response(/.*/) do |code, body, _header, message|
          if code == 404
            error('Workato is not set-up as destination for the selected ' \
            'source, use `Create Workato destination` action to fix it.')
          else
            error("#{message}: #{body}")
          end
        end || []

      [[workato_dest['display_name'], workato_dest['config']
                &.where('display_name' => 'API Key')
                &.dig(0, 'value')]]
    end,

    destinations: lambda do |_connection, source:|
      get("/v1beta/#{source}/destinations")
      &.[]('destinations')
      &.pluck('display_name', 'name') || []
    end,

    sources: lambda do |connection|
      get("/v1beta/workspaces/#{connection['workspace']}/sources")
      &.[]('sources')
      &.pluck('display_name', 'name') || []
    end
  }
}
