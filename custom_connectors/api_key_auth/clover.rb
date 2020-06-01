{
  title: 'Clover',

  methods: {
    ##############################################################
    # Helper methods                                             #
    ##############################################################
    # This method is for Custom action
    make_schema_builder_fields_sticky: lambda do |schema|
      schema.map do |field|
        if field['properties'].present?
          field['properties'] = call('make_schema_builder_fields_sticky',
                                     field['properties'])
        end
        field['sticky'] = true

        field
      end
    end,

    # Formats input/output schema to replace any special characters in name,
    # without changing other attributes (method required for custom action)
    format_schema: lambda do |input|
      input&.map do |field|
        if (props = field[:properties])
          field[:properties] = call('format_schema', props)
        elsif (props = field['properties'])
          field['properties'] = call('format_schema', props)
        end
        if (name = field[:name])
          field[:label] = field[:label].presence || name.labelize
          field[:name] = name
                         .gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        elsif (name = field['name'])
          field['label'] = field['label'].presence || name.labelize
          field['name'] = name
                          .gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        end

        field
      end
    end,

    # Formats payload to inject any special characters that previously removed
    format_payload: lambda do |payload|
      if payload.is_a?(Array)
        payload.map do |array_value|
          call('format_payload', array_value)
        end
      elsif payload.is_a?(Hash)
        payload.each_with_object({}) do |(key, value), hash|
          key = key.gsub(/__\w+__/) do |string|
            string.gsub(/__/, '').decode_hex.as_utf8
          end
          if value.is_a?(Array) || value.is_a?(Hash)
            value = call('format_payload', value)
          end
          hash[key] = value
        end
      end
    end,

    # Formats response to replace any special characters with valid strings
    # (method required for custom action)
    format_response: lambda do |response|
      response = response&.compact unless response.is_a?(String) || response
      if response.is_a?(Array)
        response.map do |array_value|
          call('format_response', array_value)
        end
      elsif response.is_a?(Hash)
        response.each_with_object({}) do |(key, value), hash|
          key = key.gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
          if value.is_a?(Array) || value.is_a?(Hash)
            value = call('format_response', value)
          end
          hash[key] = value
        end
      else
        response
      end
    end,

    render_time_input: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call('render_time_input', array_value)
        end
      elsif input.is_a?(Hash)
        input.each_with_object({}) do |(key, value), hash|
          value = call('render_time_input', value)
          hash[key] = if key.downcase.include?('time')
                        value.to_time.to_i * 1000 if value&.to_time
                      else
                        value
                      end
        end
      else
        input
      end
    end,

    format_query_params: lambda do |input|
      input&.each_with_object({}) do |(key, value), hash|
        hash[key] = "#{key}=#{value}"
      end&.to_param&.gsub(/\w+\=|\w+\.\w+\=/, 'filter=')
    end
  },

  connection: {
    fields: [
      {
        name: 'merchant_id',
        label: 'Merchant ID',
        hint: 'The merchant ID is part of the URL used to access the Clover ' \
          'merchant website. E.g.: https://sandbox.dev.clover.com' \
          '/home/m/<b>{Merchant_ID}</b>',
        optional: false
      },
      {
        name: 'environment',
        control_type: 'select',
        pick_list: [
          %w[Production-US api],
          %w[Production-Europe api.eu],
          %w[Sandbox apisandbox.dev]
        ],
        optional: false
      },
      {
        name: 'api_key',
        hint: 'You can find the API Token by navigating to <b> Setup > API ' \
          'Tokens</b>. Generate token, if there is not one already generated.',
        control_type: 'password',
        optional: false
      }
    ],

    base_uri: lambda do |connection|
      "https://#{connection['environment']}.clover.com/v3/"
    end,

    authorization: {
      type: 'api_key',

      apply: lambda { |connection|
        headers('Authorization' => "Bearer #{connection['api_key']}")
      }
    }
  },

  test: ->(connection) { get("merchants/#{connection['merchant_id']}") },

  object_definitions: {
    custom_action_input: {
      fields: lambda do |connection, config_fields|
        verb = config_fields['verb']
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')
        data_props =
          input_schema.map do |field|
            if config_fields['request_type'] == 'multipart' &&
               field['binary_content'] == 'true'
              field['type'] = 'object'
              field['properties'] = [
                { name: 'file_content', optional: false },
                {
                  name: 'content_type',
                  default: 'text/plain',
                  sticky: true
                },
                { name: 'original_filename', sticky: true }
              ]
            end
            field
          end
        data_props = call('make_schema_builder_fields_sticky', data_props)
        input_data =
          if input_schema.present?
            if input_schema.dig(0, 'type') == 'array' &&
               input_schema.dig(0, 'details', 'fake_array')
              {
                name: 'data',
                type: 'array',
                of: 'object',
                properties: data_props.dig(0, 'properties')
              }
            else
              { name: 'data', type: 'object', properties: data_props }
            end
          end

        [
          {
            name: 'path',
            hint: 'Base URI is <b>' \
            "https://#{connection['environment']}.clover.com/v3/" \
            '</b> - path will be appended to this URI. Use absolute URI to ' \
            'override this base URI.',
            optional: false
          },
          if %w[post put patch].include?(verb)
            {
              name: 'request_type',
              default: 'json',
              sticky: true,
              extends_schema: true,
              control_type: 'select',
              pick_list: [
                ['JSON request body', 'json'],
                ['URL encoded form', 'url_encoded_form'],
                ['Mutipart form', 'multipart'],
                ['Raw request body', 'raw']
              ]
            }
          end,
          {
            name: 'response_type',
            default: 'json',
            sticky: false,
            extends_schema: true,
            control_type: 'select',
            pick_list: [['JSON response', 'json'], ['Raw response', 'raw']]
          },
          if %w[get options delete].include?(verb)
            {
              name: 'input',
              label: 'Request URL parameters',
              sticky: true,
              add_field_label: 'Add URL parameter',
              control_type: 'form-schema-builder',
              type: 'object',
              properties: [
                {
                  name: 'schema',
                  sticky: input_schema.blank?,
                  extends_schema: true
                },
                input_data
              ].compact
            }
          else
            {
              name: 'input',
              label: 'Request body parameters',
              sticky: true,
              type: 'object',
              properties:
                if config_fields['request_type'] == 'raw'
                  [{
                    name: 'data',
                    sticky: true,
                    control_type: 'text-area',
                    type: 'string'
                  }]
                else
                  [
                    {
                      name: 'schema',
                      sticky: input_schema.blank?,
                      extends_schema: true,
                      schema_neutral: true,
                      control_type: 'schema-designer',
                      sample_data_type: 'json_input',
                      custom_properties:
                        if config_fields['request_type'] == 'multipart'
                          [{
                            name: 'binary_content',
                            label: 'File attachment',
                            default: false,
                            optional: true,
                            sticky: true,
                            render_input: 'boolean_conversion',
                            parse_output: 'boolean_conversion',
                            control_type: 'checkbox',
                            type: 'boolean'
                          }]
                        end
                    },
                    input_data
                  ].compact
                end
            }
          end,
          {
            name: 'request_headers',
            sticky: false,
            extends_schema: true,
            control_type: 'key_value',
            empty_list_title: 'Does this HTTP request require headers?',
            empty_list_text: 'Refer to the API documentation and add ' \
            'required headers to this HTTP request',
            item_label: 'Header',
            type: 'array',
            of: 'object',
            properties: [{ name: 'key' }, { name: 'value' }]
          },
          unless config_fields['response_type'] == 'raw'
            {
              name: 'output',
              label: 'Response body',
              sticky: true,
              extends_schema: true,
              schema_neutral: true,
              control_type: 'schema-designer',
              sample_data_type: 'json_input'
            }
          end,
          {
            name: 'response_headers',
            sticky: false,
            extends_schema: true,
            schema_neutral: true,
            control_type: 'schema-designer',
            sample_data_type: 'json_input'
          }
        ].compact
      end
    },

    custom_action_output: {
      fields: lambda do |_connection, config_fields|
        response_body = { name: 'body' }

        [
          if config_fields['response_type'] == 'raw'
            response_body
          elsif (output = config_fields['output'])
            output_schema = call('format_schema', parse_json(output))
            if output_schema.dig(0, 'type') == 'array' &&
               output_schema.dig(0, 'details', 'fake_array')
              response_body[:type] = 'array'
              response_body[:properties] = output_schema.dig(0, 'properties')
            else
              response_body[:type] = 'object'
              response_body[:properties] = output_schema
            end

            response_body
          end,
          if (headers = config_fields['response_headers'])
            header_props = parse_json(headers)&.map do |field|
              if field[:name].present?
                field[:name] = field[:name].gsub(/\W/, '_').downcase
              elsif field['name'].present?
                field['name'] = field['name'].gsub(/\W/, '_').downcase
              end
              field
            end

            { name: 'headers', type: 'object', properties: header_props }
          end
        ].compact
      end
    },

    employee: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id', sticky: true },
          { name: 'name', sticky: true },
          { name: 'nickname'  },
          { name: 'customId'  },
          { name: 'email', control_type: 'email' },
          {
            name: 'inviteSent',
            control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'inviteSent',
              label: 'Invite sent',
              hint: 'Allowed values are: true, false.',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean'
            },
            type: 'boolean'
          },
          {
            name: 'claimedTime',
            hint: 'Timestamp of when this employee claimed their account',
            control_type: 'date_time',
            type: 'number'
          },
          { name: 'pin', label: 'PIN', hint: 'Employee PIN' },
          {
            name: 'role',
            control_type: 'select',
            pick_list: 'roles',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'role',
              label: 'Role',
              hint: 'Valid values: EMPLOYEE, ADMIN, MANAGER, OWNER',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'string'
            }
          },
          {
            name: 'roles',
            type: 'object',
            properties: [
              {
                name: 'elements',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'href', label: 'HREF', control_type: 'url' },
                  { name: 'id' },
                  { name: 'name' },
                  { name: 'systemRole' },
                  {
                    name: 'merchant',
                    type: 'object',
                    properties: [{ name: 'id', sticky: true }]
                  }
                ]
              }
            ]
          },
          {
            name: 'isOwner',
            hint: 'Select Yes if this employee is the owner account.',
            control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'isOwner',
              label: 'Is owner',
              hint: 'Allowed values are: true, false.',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean'
            },
            type: 'boolean'
          },
          {
            name: 'shifts',
            type: 'object',
            properties: [{ name: 'id', sticky: true }]
          },
          {
            name: 'orders',
            type: 'object',
            properties: [{ name: 'href', label: 'HREF', control_type: 'url' }]
          }
        ]
      end
    },

    search_shift: {
      fields: lambda do |_connection, _config_fields|
        search_shift = [
          { name: 'id', sticky: true },
          { name: 'employee.id', label: 'Employee ID' },
          { name: 'employee.name', label: 'Employee name', sticky: true },
          {
            name: 'in_time',
            hint: "Filter shifts with 'In time' greater than " \
            'the mentioned time here',
            sticky: true,
            control_type: 'date_time',
            type: 'date_time'
          },
          {
            name: 'out_time',
            hint: "Filter shifts with 'Out time' lesser than " \
            'the mentioned time here',
            sticky: true,
            control_type: 'date_time',
            type: 'date_time'
          },
          {
            name: 'after_time',
            hint: "Filter shifts with 'In time' greater than " \
            'the mentioned time here',
            control_type: 'date_time',
            type: 'date_time'
          },
          {
            name: 'before_time',
            hint: "Filter shifts with 'Out time' lesser than " \
            'the mentioned time here',
            control_type: 'date_time',
            type: 'date_time'
          }
        ]

        call('format_schema', search_shift)
      end
    },

    shift: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'employee_id',
            label: 'Employee',
            control_type: 'select',
            pick_list: 'employees',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'employee_id',
              label: 'Employee ID',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'overrideInEmployee',
            type: 'object',
            properties: [
              { name: 'role' },
              {
                name: 'roles',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              {
                name: 'payments',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              {
                name: 'inviteSent',
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'inviteSent',
                  label: 'Invite sent',
                  hint: 'Allowed values are: true, false.',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean'
                },
                type: 'boolean'
              },
              {
                name: 'merchant',
                type: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'customId' },
              {
                name: 'employeeCards',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'pin', label: 'PIN' },
              {
                name: 'isOwner',
                hint: 'Select Yes if this employee is the owner account.',
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'isOwner',
                  label: 'Is owner',
                  hint: 'Allowed values are: true, false.',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean'
                },
                type: 'boolean'
              },
              {
                name: 'claimedTime',
                control_type: 'date_time',
                type: 'number'
              },
              { name: 'name' },
              { name: 'nickname' },
              {
                name: 'shifts',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'unhashedPin', label: 'Unhashed PIN' },
              {
                name: 'orders',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'id' },
              {
                name: 'deletedTime',
                control_type: 'date_time',
                type: 'number'
              },
              { name: 'email', control_type: 'email' }
            ]
          },
          {
            name: 'overrideOutEmployee',
            type: 'object',
            properties: [
              { name: 'role' },
              {
                name: 'roles',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              {
                name: 'payments',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              {
                name: 'inviteSent',
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'inviteSent',
                  label: 'Invite sent',
                  hint: 'Allowed values are: true, false.',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean'
                },
                type: 'boolean'
              },
              {
                name: 'merchant',
                type: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'customId' },
              {
                name: 'employeeCards',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'pin', label: 'PIN' },
              {
                name: 'isOwner',
                hint: 'Select Yes if this employee is the owner account.',
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'isOwner',
                  label: 'Is owner',
                  hint: 'Allowed values are: true, false.',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean'
                },
                type: 'boolean'
              },
              {
                name: 'claimedTime',
                control_type: 'date_time',
                type: 'number'
              },
              { name: 'name' },
              { name: 'nickname' },
              {
                name: 'shifts',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'unhashedPin', label: 'Unhashed PIN' },
              {
                name: 'orders',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'id' },
              {
                name: 'deletedTime',
                control_type: 'date_time',
                type: 'number'
              },
              { name: 'email', control_type: 'email' }
            ]
          },
          {
            name: 'employee',
            type: 'object',
            properties: [
              { name: 'role' },
              {
                name: 'roles',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              {
                name: 'payments',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              {
                name: 'inviteSent',
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'inviteSent',
                  label: 'Invite sent',
                  hint: 'Allowed values are: true, false.',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean'
                },
                type: 'boolean'
              },
              {
                name: 'merchant',
                type: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'customId' },
              {
                name: 'employeeCards',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              {
                name: 'pin',
                label: 'PIN'
              },
              {
                name: 'isOwner',
                hint: 'Select Yes if this employee is the owner account.',
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'isOwner',
                  label: 'Is owner',
                  hint: 'Allowed values are: true, false.',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean'
                },
                type: 'boolean'
              },
              {
                name: 'claimedTime',
                control_type: 'date_time',
                type: 'number'
              },
              { name: 'name' },
              { name: 'nickname' },
              {
                name: 'shifts',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'unhashedPin', label: 'Unhashed PIN' },
              {
                name: 'orders',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'id' },
              {
                name: 'deletedTime',
                control_type: 'date_time',
                type: 'number'
              },
              { name: 'email', control_type: 'email' }
            ]
          },
          {
            name: 'inTime',
            sticky: true,
            control_type: 'date_time',
            type: 'number'
          },
          {
            name: 'overrideInTime',
            label: 'Override In time',
            sticky: true,
            control_type: 'date_time',
            type: 'number'
          },
          {
            name: 'outTime',
            sticky: true,
            control_type: 'date_time',
            type: 'number'
          },
          {
            name: 'overrideOutTime',
            label: 'Override Out time',
            sticky: true,
            control_type: 'date_time',
            type: 'number'
          },
          {
            name: 'cashTipsCollected',
            hint: 'Amount of cash tips collected',
            sticky: true,
            control_type: 'number',
            type: 'number'
          },
          {
            name: 'serverBanking',
            hint: 'Whether the employee used server banking',
            control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'serverBanking',
              label: 'Server banking',
              hint: 'Allowed values are: true, false.',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean'
            },
            type: 'boolean'
          }
        ]
      end
    }
  },

  actions: {
    # Custom action for Clover
    custom_action: {
      subtitle: 'Build your own Clover action with a HTTP request',

      description: lambda do |object_value, _object_label|
        "<span class='provider'>" \
        "#{object_value[:action_name] || 'Custom action'}</span> in " \
        "<span class='provider'>Clover</span>"
      end,

      help: {
        body: 'Build your own Clover action with a HTTP request. ' \
        'The request will be authorized with your Clover connection.',
        learn_more_url: 'https://www.clover.com/api_docs',
        learn_more_text: 'Clover API documentation'
      },

      config_fields: [
        {
          name: 'action_name',
          hint: "Give this action you're building a descriptive name, e.g. " \
          'create record, get record',
          default: 'Custom action',
          optional: false,
          schema_neutral: true
        },
        {
          name: 'verb',
          label: 'Method',
          hint: 'Select HTTP method of the request',
          optional: false,
          control_type: 'select',
          pick_list: %w[get post put patch options delete]
            .map { |verb| [verb.upcase, verb] }
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['custom_action_input']
      end,

      execute: lambda do |_connection, input|
        verb = input['verb']
        if %w[get post put patch options delete].exclude?(verb)
          error("#{verb.upcase} not supported")
        end
        path = input['path']
        data = input.dig('input', 'data') || {}
        if input['request_type'] == 'multipart'
          data = data.each_with_object({}) do |(key, val), hash|
            hash[key] = if val.is_a?(Hash)
                          [val[:file_content],
                           val[:content_type],
                           val[:original_filename]]
                        else
                          val
                        end
          end
        end
        request_headers = input['request_headers']
          &.each_with_object({}) do |item, hash|
          hash[item['key']] = item['value']
        end || {}
        request = case verb
                  when 'get'
                    get(path, data)
                  when 'post'
                    if input['request_type'] == 'raw'
                      post(path).request_body(data)
                    else
                      post(path, data)
                    end
                  when 'put'
                    if input['request_type'] == 'raw'
                      put(path).request_body(data)
                    else
                      put(path, data)
                    end
                  when 'patch'
                    if input['request_type'] == 'raw'
                      patch(path).request_body(data)
                    else
                      patch(path, data)
                    end
                  when 'options'
                    options(path, data)
                  when 'delete'
                    delete(path, data)
                  end.headers(request_headers)
        request = case input['request_type']
                  when 'url_encoded_form'
                    request.request_format_www_form_urlencoded
                  when 'multipart'
                    request.request_format_multipart_form
                  else
                    request
                  end
        response =
          if input['response_type'] == 'raw'
            request.response_format_raw
          else
            request
          end
          .after_error_response(/.*/) do |code, body, headers, message|
            error({ code: code, message: message, body: body, headers: headers }
              .to_json)
          end

        response.after_response do |_code, res_body, res_headers|
          {
            body: res_body ? call('format_response', res_body) : nil,
            headers: res_headers
          }
        end
      end,

      output_fields: lambda do |object_definition|
        object_definition['custom_action_output']
      end
    },

    search_employees: {
      description: "Search <span class='provider'>employees</span> in " \
      "<span class='provider'>Clover</span>",
      help: 'Search will return results that match all your search criteria. ' \
      'Returns a maximum of 100 records.',

      execute: lambda do |connection, input|
        filter = call('format_query_params', call('render_time_input', input))

        {
          employees: get("merchants/#{connection['merchant_id']}/employees",
                         filter)
            .after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end['elements']
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['employee']
          .only('id', 'name', 'nickname', 'customId', 'email', 'pin')
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'employees',
          type: 'array',
          of: 'object',
          properties: object_definitions['employee']
        }]
      end,

      sample_output: lambda do |connection, _input|
        {
          employees: get("merchants/#{connection['merchant_id']}/employees",
                         limit: 1)['elements']
        }
      end
    },

    get_employee_by_id: {
      description: "Get <span class='provider'>employee</span> by ID " \
      "in <span class='provider'>Clover</span>",

      execute: lambda do |connection, input|
        get("merchants/#{connection['merchant_id']}" \
            "/employees/#{input['id']}")
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['employee'].only('id').required('id')
      end,

      output_fields: ->(object_definitions) { object_definitions['employee'] },

      sample_output: lambda do |connection, _input|
        get("merchants/#{connection['merchant_id']}/employees",
            limit: 1).dig('elements', 0) || {}
      end
    },

    create_employee: {
      description: "Create <span class='provider'>employee</span> " \
      "in <span class='provider'>Clover</span>",

      execute: lambda do |connection, input|
        post("merchants/#{connection['merchant_id']}/employees",
             call('render_time_input', input))
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['employee']
          .ignored('employeeCards', 'id', 'roles', 'payments', 'shifts',
                   'orders')
          .required('name')
      end,

      output_fields: ->(object_definitions) { object_definitions['employee'] },

      sample_output: lambda do |connection, _input|
        get("merchants/#{connection['merchant_id']}/employees",
            limit: 1).dig('elements', 0) || {}
      end
    },

    update_employee: {
      description: "Update <span class='provider'>employee</span> " \
      "in <span class='provider'>Clover</span>",

      execute: lambda do |connection, input|
        post("merchants/#{connection['merchant_id']}/employees" \
             "/#{input['id']}", call('render_time_input', input))
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['employee']
          .ignored('roles', 'payments', 'employeeCards', 'shifts', 'orders')
          .required('id', 'name')
      end,

      output_fields: ->(object_definitions) { object_definitions['employee'] },

      sample_output: lambda do |connection, _input|
        get("merchants/#{connection['merchant_id']}/employees",
            limit: 1).dig('elements', 0) || {}
      end
    },

    search_shifts: {
      description: "Search <span class='provider'>shifts</span> in " \
      "<span class='provider'>Clover</span>",
      help: 'Search will return results that match all your search criteria. ' \
      'Returns a maximum of 100 records.',

      execute: lambda do |connection, input|
        input = call('render_time_input', call('format_payload', input))
        time_range = {
          in_time: if (in_time = input.delete('in_time'))
                     "in_time>=#{in_time}"
                   end,
          out_time: if (out_time = input.delete('out_time'))
                      "out_time<=#{out_time}"
                    end
        }.compact&.to_param
        filter = call('format_query_params', input)
        filter = [filter, time_range].join('&').gsub(/\w+\=/, 'filter=')

        {
          shifts: get("merchants/#{connection['merchant_id']}/shifts",
                      filter)
            .after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end['elements']
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['search_shift'].ignored('after_time', 'before_time')
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'shifts',
          type: 'array',
          of: 'object',
          properties: object_definitions['shift'].ignored('employee_id')
        }]
      end,

      sample_output: lambda do |connection, _input|
        {
          shifts: get("merchants/#{connection['merchant_id']}/shifts",
                      limit: 1)['elements']
        }
      end
    },

    search_shifts_in_bulk: {
      description: "Search <span class='provider'>shifts</span> in bulk in " \
      "<span class='provider'>Clover</span>",
      help: 'Search will return results that match all your search criteria.' \
      "<br/>This action uses the Clover <a href='https://docs.clover.com/" \
      "clover-platform/reference/employees-1#merchantgetallshiftscsv-1'>" \
      'Get .csv of all shifts API</a>. Search results are returned in ' \
      'full as a CSV stream. You can write the CSV stream to a file using ' \
      'a file connector, e.g. Box, SFTP. You can also parse it to use as ' \
      'a list of data in Workato using the <b>Parse CSV</b> action in the ' \
      '<b>CSV by Workato</b> utility connector.',

      input_fields: lambda do |object_definitions|
        object_definitions['search_shift']
          .ignored('id', 'in_time', 'out_time')
          .required('after_time', 'before_time')
      end,

      execute: lambda do |connection, input|
        input = call('render_time_input', call('format_payload', input))
        time_range = {
          afterTime: input.delete('after_time'),
          beforeTime: input.delete('before_time')
        }.to_param
        filter = call('format_query_params', input)

        {
          csv_results: get("merchants/#{connection['merchant_id']}" \
                           '/shifts.csv', [filter, time_range].join('&'))
            .response_format_raw
            .after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        }
      end,

      output_fields: lambda do |_object_definitions|
        [{ name: 'csv_results', label: 'CSV results' }]
      end,

      sample_output: ->(_connection, _input) { { csv_results: 'CSV data...' } },

      summarize_output: ['csv_results']
    },

    create_shift: {
      description: "Create <span class='provider'>shift</span> " \
      "in <span class='provider'>Clover</span>",

      execute: lambda do |connection, input|
        post("merchants/#{connection['merchant_id']}/employees/" \
             "#{input.delete('employee_id')}/shifts",
             call('render_time_input', input))
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['shift'].required('employee_id')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['shift'].ignored('employee_id')
      end,

      sample_output: lambda do |connection, input|
        get("merchants/#{connection['merchant_id']}/employees/" \
            "#{input['employee_id']}/shifts", limit: 1)
          .dig('elements', 0) || {}
      end
    }
  },

  triggers: {
    new_shift: {
      title: 'New shift',
      description: "New <span class='provider'>shift" \
      "</span> in <span class='provider'>Clover</span>",
      # https://docs.clover.com/clover-platform/docs/sorting-collections says -
      # The default sort order is descending by creation time.
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
            type: 'date_time'
          },
          {
            name: 'employee_id',
            label: 'Employee',
            optional: false,
            control_type: 'select',
            pick_list: 'employees',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'employee_id',
              label: 'Employee ID',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          }
        ]
      end,

      poll: lambda do |connection, input, offset|
        offset ||= 0
        # page_size hard limit = 1000; setting it to max. here
        page_size = 1000
        in_time = (input['since'] || 1.hour.ago).to_time.to_i * 1000
        shifts = get("merchants/#{connection['merchant_id']}/employees/" \
                     "#{input['employee_id']}/shifts",
                     limit: page_size,
                     filter: "in_time>=#{in_time}",
                     offset: offset)['elements'] || []

        {
          events: shifts,
          next_page: shifts.size >= page_size ? (offset + page_size) : nil
        }
      end,

      document_id: ->(shift) { shift['id'] },

      sort_by: ->(shift) { shift['inTime'] },

      output_fields: lambda do |object_definitions|
        object_definitions['shift'].ignored('employee_id')
      end,

      sample_output: lambda do |connection, input|
        get("merchants/#{connection['merchant_id']}/employees/" \
            "#{input['employee_id']}/shifts", limit: 1)
          .dig('elements', 0) || {}
      end
    }
  },

  pick_lists: {
    employees: lambda do |connection|
      get("merchants/#{connection['merchant_id']}/employees")['elements']
        &.pluck('name', 'id')
    end,

    roles: lambda do |_connection|
      [
        %w[Employee EMPLOYEE],
        %w[Admin ADMIN],
        %w[Manager MANAGER],
        %w[Owner OWNER]
      ]
    end
  }
}
