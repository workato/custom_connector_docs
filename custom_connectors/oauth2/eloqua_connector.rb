# frozen_string_literal: true

{
  title: 'Eloqua',

  connection: {
    fields: [
      { name: 'client_id', optional: false,
        hint: 'The <b>client ID</b> created in the Eloqua application.' },
      { name: 'client_secret', control_type: 'password', optional: false,
        hint: 'The <b>client secret</b> key created in the Eloqua application' }
    ],

    authorization: {
      type: 'Oauth2',

      authorization_url: lambda do |connection|
        params = {
          response_type: 'code',
          client_id: connection['client_id'],
          redirect_uri: 'https://www.workato.com/oauth/callback'
        }.to_param

        'https://login.eloqua.com/auth/oauth2/authorize?' + params
      end,

      acquire: lambda do |connection, auth_code|
        header = "#{connection['client_id']}:#{connection['client_secret']}"
        response = post('https://login.eloqua.com/auth/oauth2/token').
                     payload(
                       grant_type: 'authorization_code',
                       redirect_uri: 'https://www.workato.com/oauth/callback',
                       code: auth_code
                     ).request_format_www_form_urlencoded.
                     headers('Authorization': "Basic #{header.encode_base64}")

        session = get('https://login.eloqua.com/id')&.
                    headers('Authorization': "Bearer #{response['access_token']}")

        [
          {
            access_token: response['access_token'],
            refresh_token: response['refresh_token']
          },
          nil,
          { base_url: session.dig('urls', 'base'),
            user_id: session.dig('user', 'id') }
        ]
      end,

      refresh_on: [401, 403],

      refresh: lambda do |connection, refresh_token|
        header = "#{connection['client_id']}:#{connection['client_secret']}"
        post('https://login.eloqua.com/auth/oauth2/token').
          payload(
            grant_type: 'refresh_token',
            refresh_token: refresh_token,
            redirect_uri: 'https://www.workato.com/oauth/callback'
          ).request_format_www_form_urlencoded.
          headers('Authorization': "Basic #{header.encode_base64}")
      end,

      apply: lambda do |_connection, access_token|
        headers('Authorization': "Bearer #{access_token}")
      end
    },
    base_uri: lambda do |connection|
      connection['base_url']
    end
  },

  test: lambda do |connection|
    get("/api/REST/1.0/system/user/#{connection['user_id']}")
  end,

  object_definitions: {

    create_record_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if call('is_standard_objects', config_fields)
          if config_fields['object'] == 'contact'
            call("#{config_fields['object']}_schema", 'input')&.
                 ignored('id')&.required('emailAddress')
          elsif config_fields['object'] == 'external_activity'
            call("#{config_fields['object']}_schema", 'input')&.
                 ignored('id')&.
                 required('name', 'assetName', 'assetType', 'activityType',
                          'campaignId', 'contactId')
          elsif config_fields['object'] == 'contact_field'
            call("#{config_fields['object']}_schema", 'input')&.
                 ignored('id')&.required('name', 'updateType', 'displayType', 'dataType')
          elsif config_fields['object'] == 'event_registrant'
            call("#{config_fields['object']}_schema", config_fields, 'input')&.
                 ignored('id')&.required('name')
          else
            call("#{config_fields['object']}_schema", 'input')&.
                 ignored('id')&.required('name')
          end
        else
          [
            { name: 'accountId', sticky: true },
            { name: 'contactId', sticky: true }
          ].concat(call('custom_object_input_schema', config_fields, 'create'))
        end
      end
    },

    create_record_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if call('is_standard_objects', config_fields)
          if config_fields['object'] == 'event_registrant'
            call("#{config_fields['object']}_schema", config_fields, 'output')
          else
            call("#{config_fields['object']}_schema", 'output')
          end
        else
          call('custom_object_output_schema', config_fields)
        end
      end
    },

    update_record_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if call('is_standard_objects', config_fields)
          if config_fields['object'] == 'event_registrant'
            [{ name: 'id', label: 'Event registrant ID',
               type: 'integer', control_type: 'integer',
               render_input: 'integer_conversion', optional: false }].
              concat(call("#{config_fields['object']}_schema", config_fields, 'input'))
          else
            [{ name: 'id', label: "#{config_fields['object'].labelize} ID",
               type: 'integer', control_type: 'integer',
               render_input: 'integer_conversion', optional: false }].
              concat(call("#{config_fields['object']}_schema", 'input'))
          end
        else
          [
            { name: 'id', optional: false,
              label: 'Record ID',
              hint: 'Provide record id e.g. 101' },
            { name: 'accountId', sticky: true },
            { name: 'contactId', sticky: true }
          ].concat(call('custom_object_input_schema', config_fields, 'update')).compact
        end
      end
    },

    search_record_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if config_fields['object'] == 'event_registrant'
          [{ name: 'parentId', label: 'Parent event', optional: false,
             type: 'string', control_type: 'select',
             extends_schema: true,
             pick_list: 'event_parentid', toggle_hint: 'Select from list',
             hint: 'Name of the parent event',
             toggle_field: {
               name: 'parentId',
               label: 'Parent ID',
               optional: false,
               extends_schema: true,
               change_on_blur: true,
               type: 'string',
               control_type: 'text',
               toggle_hint: 'Use custom value',
               hint: 'Id of the parent event'
             } }].concat(call('search_input'))
        else
          call('search_input')
        end
      end
    },

    search_record_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if call('is_standard_objects', config_fields)
          if config_fields['object'] == 'event_registrant'
            [
              {
                name: 'elements', label: config_fields['object']&.labelize&.pluralize,
                type: 'array', of: 'object',
                properties: call("#{config_fields['object']}_schema", config_fields, 'output')
              }
            ]
          else
            [
              {
                name: 'elements', label: config_fields['object']&.labelize&.pluralize,
                type: 'array', of: 'object',
                properties: call("#{config_fields['object']}_schema", 'output')
              }
            ]
          end
        else
          [{ name: 'records', type: 'array', of: 'object',
             label: 'Records',
             properties: call('custom_object_output_schema', config_fields) }]
        end
      end
    },

    get_record_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if config_fields['object'] == 'event_registrant'
          [{ name: 'parentId', label: 'Parent event', optional: false,
             type: 'string', control_type: 'select',
             extends_schema: true,
             pick_list: 'event_parentid', toggle_hint: 'Select from list',
             hint: 'Name of the parent event',
             toggle_field: {
               name: 'parentId',
               label: 'Parent ID',
               optional: false,
               extends_schema: true,
               change_on_blur: true,
               type: 'string',
               control_type: 'text',
               toggle_hint: 'Use custom value',
               hint: 'Id of the parent event'
             } }].concat(call('get_input', config_fields))
        elsif config_fields['object'] == 'contact_activity'
          [
            { name: 'count', type: 'integer', control_type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              hint: 'Maximum number of entities to return. Must be less than or ' \
                    'equal to 1000 and greater than or equal to 1.' },
            { name: 'startDate', type: 'date_time', optional: false,
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              hint: 'The start date and time' },
            { name: 'endDate', type: 'date_time', optional: false,
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              hint: 'The end date and time' },
            { name: 'type', optional: false,
              hint: 'The type of activity you wish to retrieve from the specified ' \
                    'contact: emailOpen, emailSend, emailClickThrough, ' \
                    'emailSubscribe, emailUnsubscribe, formSubmit, ' \
                    'webVisit, or campaignMembership.' }
          ].concat(call('get_input', config_fields))
        else
          call('get_input', config_fields)
        end
      end
    },

    get_record_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if call('is_standard_objects', config_fields)
          if config_fields['object'] == 'event_registrant'
            call("#{config_fields['object']}_schema", config_fields, 'output')
          else
            call("#{config_fields['object']}_schema", 'output')
          end
        else
          call('custom_object_output_schema', config_fields)
        end
      end
    },

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
            "#{connection['base_uri']}" \
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
                            control_type: 'checkbox',
                            type: 'boolean',
                            render_input: 'boolean_conversion',
                            parse_output: 'boolean_conversion'
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
    }
  },

  actions: {
    create_object: {
      title: 'Create record',
      subtitle: 'Create any standard or custom record e.g. contact in Eloqua. ',
      description: lambda do |_connection, create_object_list|
        "Create <span class='provider'>#{create_object_list[:object] || 'record'}" \
        "</span> in <span class='provider'>Eloqua</span>"
      end,
      help: 'Create any standard or custom record in Eloqua e.g. contact. Select the object to' \
            ' create, then provide the data for creating the record.',
      config_fields: [
        { name: 'object', optional: false,
          label: 'Object', control_type: 'select',
          pick_list: 'create_object_list',
          hint: 'Select any Eloqua object, e.g. account' }
      ],
      input_fields: lambda do |object_definition|
        object_definition['create_record_input']
      end,
      output_fields: lambda do |object_definition|
        object_definition['create_record_output']
      end,
      execute: lambda do |_connection, input, e_i_s, e_o_s|
        payload = call('custom_input_parser', input, call('get_date_time_fields', e_i_s))
        if call('is_standard_objects', input)
          url = call('create_url', input)
          if %w[account contact event_registrant].include?(input['object'])
            payload['fieldValues'] = payload['fieldValues']&.map do |key, value|
              { id: key.delete('c_'),
                value: value }
            end
          end
          if input['object'] == 'event_registrant'
            error('Provide at least one value to create record') if input.except('object', 'parentId').blank?
          end
          response = post(url, payload.except('object'))&.
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end&.presence || {}
          if %w[account contact event_registrant].include?(input['object'])
            response['fieldValues'] = call('field_value_parser', response.delete('fieldValues'))
          end
          call('custom_output_parser', response, call('get_date_time_fields', e_o_s))
        else
          error('Provide at least one value to create record') if input.except('object', 'contactId', 'accountId').blank?
          date_time_fields_input = call('get_date_time_fields', e_i_s)
          field_values = input&.
            except('object', 'contactId', 'accountId')&.
            map do |key, value|
              if date_time_fields_input.include?(key)
                { 'id' => key, 'value' => value&.to_i }
              else
                { 'id' => key, 'value' => value }
              end
            end
          payload = { type: 'CustomObjectData',
                      contactId: input.delete('contactId'),
                      accountId: input.delete('accountId'),
                      fieldValues: field_values }
          response = post("api/REST/2.0/data/customObject/#{input['object']}/instance", payload).
                       after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message}: #{body}")
                       end
          call('format_custom_object_records', response, call('get_date_time_fields', e_o_s))
        end
      end,
      sample_output: lambda do |_connection, input, e_o_s|
        if call('is_standard_objects', input)
          response = call('search_sample_output', input)&.
            []('elements')&.first
          call('custom_output_parser', response, call('get_date_time_fields', e_o_s))
        else
          record = call('sample_custom_object_record', input)
          call('format_custom_object_records', record, call('get_date_time_fields', e_o_s))
        end
      end
    },

    update_object: {
      title: 'Update record',
      subtitle: 'Update any standard or custom record in Eloqua. e.g. contact',
      description: lambda do |_connection, update_object_list|
        "Update <span class='provider'>#{update_object_list[:object] || 'record'}" \
        "</span> by ID in <span class='provider'>Eloqua</span>"
      end,
      help: lambda do |_connection, update_object_list|
        'Update any standard or custom record in Eloqua. e.g. contact, via its via' \
        " #{update_object_list[:object]} ID."
      end,
      config_fields: [
        { name: 'object', optional: false,
          label: 'Object', control_type: 'select',
          pick_list: 'update_object_list',
          hint: 'Select any Eloqua object e.g. account' }
      ],
      input_fields: lambda do |object_definition|
        object_definition['update_record_input']
      end,
      output_fields: lambda do |object_definition|
        object_definition['create_record_output']
      end,
      execute: lambda do |_connection, input, e_i_s, e_o_s|
        payload = call('custom_input_parser', input,
                       call('get_date_time_fields', e_i_s))
        if call('is_standard_objects', input)
          url = call('get_url', input)
          if %w[account contact event_registrant].include?(input['object'])
            payload['fieldValues'] = payload['fieldValues']&.map do |key, value|
              { id: key.delete('c_'),
                value: value }
            end
          end
          if input['object'] == 'event_registrant'
            error('Provide at least one value to update record') if input.except('object', 'parentId', 'id').blank?
          end
          response = put(url, payload.except('object'))&.
                       after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message}: #{body}")
                       end&.presence || {}
          if %w[account contact event_registrant].include?(input['object'])
            response['fieldValues'] = call('field_value_parser', response.delete('fieldValues'))
          end
          call('custom_output_parser', response,
               call('get_date_time_fields', e_o_s))
        else
          date_time_fields_input = call('get_date_time_fields', e_i_s)
          field_values = input&.
            except('object', 'id', 'contactId', 'accountId')&.
            map do |key, value|
              if date_time_fields_input.include?(key)
                { 'id' => key, 'value' => value&.to_i }
              else
                { 'id' => key, 'value' => value }
              end
            end
          payload = { type: 'CustomObjectData',
                      contactId: input.delete('contactId'),
                      accountId: input.delete('accountId'),
                      fieldValues: field_values }
          response = put("api/REST/2.0/data/customObject/#{input['object']}/" \
                          "instance/#{input['id']}", payload)&.
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end
          call('format_custom_object_records', response, call('get_date_time_fields', e_o_s))
        end
      end,
      sample_output: lambda do |_connection, input, e_o_s|
        if call('is_standard_objects', input)
          response = call('search_sample_output', input)&.
            []('elements')&.first
          call('custom_output_parser', response, call('get_date_time_fields', e_o_s))
        else
          record = call('sample_custom_object_record', input)
          call('format_custom_object_records', record, call('get_date_time_fields', e_o_s))
        end
      end
    },

    get_object_by_id: {
      title: 'Get record details',
      subtitle: 'Retrieve the details of any standard or custom record, e.g. account via its Eloqua ID',
      description: lambda do |_connection, get_object_list|
        "Get details of specific <span class='provider'>#{get_object_list[:object] || 'record'}" \
        "</span> in <span class='provider'>Eloqua</span>"
      end,
      help: 'Retrieve the details of any standard or custom record, e.g. account, via its Eloqua ID.',
      config_fields: [
        { name: 'object', optional: false,
          control_type: 'select',
          pick_list: 'get_object_list',
          hint: 'Select any Eloqua object, e.g. account' }
      ],
      input_fields: lambda do |object_definition|
        object_definition['get_record_input']
      end,
      output_fields: lambda do |object_definition|
        object_definition['get_record_output']
      end,
      execute: lambda do |_connection, input, e_i_s, e_o_s|
        payload = call('custom_input_parser', input,
                       call('get_date_time_fields', e_i_s))
        if call('is_standard_objects', input)
          url = call('get_url', input)
          response = if input['object'] == 'contact_activity'
                       get(url, payload.except('object'))&.
                                   after_error_response(/.*/) do |_code, body, _header, message|
                                     error("#{message}: #{body}")
                                   end&.presence || {}
                     else
                       get(url, input.except('object'))&.
                          after_error_response(/.*/) do |_code, body, _header, message|
                            error("#{message}: #{body}")
                          end&.presence || {}
                     end
          if %w[account contact event_registrant].include?(input['object'])
            response['fieldValues'] = call('field_value_parser', response.delete('fieldValues'))
          end
          call('custom_output_parser', response,
               call('get_date_time_fields', e_o_s))
        else
          response = get("api/REST/2.0/data/customObject/#{input['object']}/" \
                          "instance/#{input['id']}")&.
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end
          call('format_custom_object_records', response, call('get_date_time_fields', e_o_s))
        end
      end,
      sample_output: lambda do |_connection, input, e_o_s|
        if call('is_standard_objects', input)
          response = call('search_sample_output', input)&.
            []('elements')&.first
          call('custom_output_parser', response,
               call('get_date_time_fields', e_o_s))
        else
          record = call('sample_custom_object_record', input)
          call('format_custom_object_records', record, call('get_date_time_fields', e_o_s))
        end
      end
    },

    search_object: {
      title: 'Search records',
      subtitle: 'Retrieve a list of records, e.g. accounts in Eloqua, that matches' \
      ' your search criteria',
      description: lambda do |_connection, search_object_list|
        object = search_object_list[:object]
        "Search <span class='provider'>#{object || 'an object'}" \
        "</span> in <span class='provider'>Eloqua</span>"
      end,
      help: lambda do |_connection, search_object_list|
        if search_object_list[:object] == 'event_registrant'
          'Retrieves the registrants (records) for an event specified by the <b>parent Id</b>' \
          ' that match the criteria specified by the query parameters'
        else
          'The Search records action returns results that match all your search' \
          ' criteria. The number of returned records defaults to a limit of 200. ' \
          'Use the <b>depth</b> parameter when making the request to specify the record' \
          ' information returned in the response.'
        end
      end,
      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Search for',
          control_type: 'select',
          pick_list: 'search_object_list',
          hint: 'Select the Eloqua object to search for, then specify at least one field to match'
        }
      ],
      input_fields: lambda do |object_definition|
        object_definition['search_record_input']
      end,
      output_fields: lambda do |object_definition|
        object_definition['search_record_output']
      end,
      execute: lambda do |_connection, input, _e_i_s, e_o_s|
        if call('is_standard_objects', input)
          url = call('search_url', input)
          response = get(url, input.except('object'))&.
                         after_error_response(/.*/) do |_code, body, _header, message|
                           error("#{message}: #{body}")
                         end.presence || {}
          if %w[account contact event_registrant].include?(input['object'])
            response['elements'].each do |element|
              element['fieldValues'] = call('field_value_parser', element.delete('fieldValues'))
            end
          end
          call('custom_output_parser', response, call('get_date_time_fields', e_o_s))
        else
          response = get("/api/REST/2.0/data/customObject/#{input['object']}/instances",
                         input.except('object'))&.
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end
          { records: call('format_custom_object_records', response['elements'],
                          call('get_date_time_fields', e_o_s)) }
        end
      end,
      sample_output: lambda do |_connection, input, e_o_s|
        if call('is_standard_objects', input)
          response = call('search_sample_output', input)
          { elements: call('custom_output_parser', response['elements'],
                           call('get_date_time_fields', e_o_s)) }
        else
          record = call('sample_custom_object_record', input)
          { records: call('format_custom_object_records', record,
                          call('get_date_time_fields', e_o_s)) }
        end
      end
    },

    delete_object: {
      title: 'Delete record',
      subtitle: 'Delete any standard or custom record in Eloqua. e.g. contact via its <b>record ID</b>',
      description: lambda do |_connection, delete_object_list|
        "Delete <span class='provider'>#{delete_object_list[:object] || 'record'}" \
        "</span> in <span class='provider'>Eloqua</span>"
      end,
      help: 'Delete any standard or custom record, e.g. contact, in Eloqua.',
      config_fields: [
        { name: 'object', optional: false,
          label: 'Object type', control_type: 'select',
          pick_list: 'delete_object_list',
          hint: 'Select the object type from list.' }
      ],
      input_fields: lambda do |object_definition|
        object_definition['get_record_input'].ignored('depth')
      end,
      execute: lambda do |_connection, input|
        if call('is_standard_objects', input)
          delete(call('get_url', input))&.
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end&.after_response do |_code, _body, _headers|
              { status: 'Success' }
            end
        else
          delete("/api/REST/2.0/data/customObject/#{input['object']}" \
                 "/instance/#{input['id']}")&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.after_response do |_code, _body, _headers|
            { status: 'Success' }
          end
        end
      end,
      output_fields: lambda do |_object_definition|
        [
          { name: 'status' }
        ]
      end,
      sample_output: lambda do |_connection, _input|
        { status: 'Success' }
      end
    },

    custom_action: {
      subtitle: 'Build your own Eloqua action with a HTTP request',

      description: lambda do |object_value, _object_label|
        "<span class='provider'>" \
        "#{object_value[:action_name] || 'Custom action'}</span> in " \
        "<span class='provider'>Eloqua</span>"
      end,

      help: {
        body: 'Build your own Eloqua action with a HTTP request. ' \
              'The request will be authorized with your Eloqua connection.',
        learn_more_url: 'https://docs.oracle.com/en/cloud/saas/marketing/eloqua-rest-api/',
        learn_more_text: 'Eloqua API documentation'
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
          pick_list: %w[get post put delete].map { |verb| [verb.upcase, verb] }
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
        request_headers = input['request_headers']&.
        each_with_object({}) do |item, hash|
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
          end.
            after_error_response(/.*/) do |code, body, headers, message|
            error({ code: code, message: message, body: body, headers: headers }.to_json)
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
    }
  },

  triggers: {

    new_objects: {
      title: 'New record',
      subtitle: 'Triggers when a selected Eloqua object, e.g. account is created',
      description: lambda do |_input, trigger_object_list|
        "New <span class='provider'>" \
        "#{trigger_object_list[:object] || 'record'}" \
        "</span> in <span class='provider'>Eloqua</span>"
      end,
      help: lambda do |_input, trigger_object_list|
        "Triggers when selected #{trigger_object_list[:object] || 'record'}  is created."
      end,
      config_fields: [{
        name: 'object',
        optional: false,
        control_type: 'select',
        pick_list: 'trigger_object_list',
        hint: 'Select any Eloqua object, e.g. account'
      }],
      input_fields: lambda do |_object_definition|
        [
          {
            name: 'since',
            label: 'When first started, this recipe should pick up events from',
            hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created one hour ago',
            sticky: true,
            type: 'timestamp'
          }
        ]
      end,
      poll: lambda do |_connection, input, closure|
        page_size = 100
        page = closure&.[]('page') || 1
        last_created_at = closure&.[]('last_created_at') ||
                            ((input['since'].presence || 1.hour.ago)).in_time_zone('America/New_York').
                              strftime('%Y-%m-%d %H:%M:%S')
        result = if call('is_standard_objects', input)
                   schema = call("#{input['object']}_schema", 'output')
                   response = get(call('search_url', input),
                                  search: 'createdAt>' + "'" + last_created_at + "'",
                                  count: page_size,
                                  page: page,
                                  depth: 'complete',
                                  orderBy: 'createdAt')&.
                               after_error_response(/.*/) do |_code, body, _header, message|
                                 error("#{message}: #{body}")
                               end
                   call('custom_output_parser', response['elements'],
                        call('get_date_time_fields', schema))
                 else
                   date_fields = closure&.[]('date_fields') || call('get_date_time_fields',
                                                                    call('custom_object_output_schema', input))
                   response = get("/api/REST/2.0/data/customObject/#{input['object']}/instances",
                                  search: 'createdAt>' + "'" + last_created_at + "'",
                                  count: page_size,
                                  page: page,
                                  depth: 'complete',
                                  orderBy: 'createdAt')&.
                              after_error_response(/.*/) do |_code, body, _header, message|
                                error("#{message}: #{body}")
                              end
                   call('format_custom_object_records', response['elements'], date_fields)
                 end
        closure = if (has_more = page * page_size < response['total'])
                    { 'page' => page + 1,
                      'date_fields' => date_fields,
                      'last_created_at' => last_created_at }
                  else
                    last_created_at =
                      (result&.dig(-1, 'createdAt') ||
                        Time.now).in_time_zone('America/New_York').strftime('%Y-%m-%d %H:%M:%S')
                    { 'page' => 1,
                      'date_fields' => date_fields,
                      'last_created_at' => last_created_at }
                  end
        {
          events: result,
          next_poll: closure,
          can_poll_more: has_more
        }
      end,
      dedup: lambda do |result|
        result['id']
      end,

      output_fields: lambda do |object_definition|
        object_definition['get_record_output']
      end,
      sample_output: lambda do |_connection, input, e_o_s|
        if call('is_standard_objects', input)
          response = call('search_sample_output', input)&.
            []('elements')&.first
          call('custom_output_parser', response, call('get_date_time_fields', e_o_s))
        else
          record = get("/api/REST/1.0/data/customObject/#{input['id']}",
                       count: 1, page: 1, orderBy: 'updatedAt')&.dig('elements', 0)
          call('format_custom_object_records', record, call('get_date_time_fields',
                                                            call('custom_object_output_schema', input)))
        end
      end
    },

    new_or_updated_objects: {
      title: 'New/updated record',
      subtitle: 'Triggers when a selected Eloqua object, e.g. account is created/updated',
      description: lambda do |_input, trigger_object_list|
        "New/updated <span class='provider'>" \
        "#{trigger_object_list[:object] || 'record'}" \
        "</span> in <span class='provider'>Eloqua</span>"
      end,
      help: lambda do |_input, trigger_object_list|
        "Triggers when selected #{trigger_object_list[:object] || 'record'}" \
        '  is created/updated.'
      end,
      config_fields: [{
        name: 'object',
        optional: false,
        control_type: 'select',
        pick_list: 'trigger_object_list',
        hint: 'Select any Eloqua object, e.g. account'
      }],
      input_fields: lambda do |_object_definition|
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
        page_size = 100
        page = closure&.[]('page') || 1
        result = if call('is_standard_objects', input)
                   schema = call("#{input['object']}_schema", 'output')
                   last_updated_at = (closure&.[]('last_updated_at') ||
                                        (input['since'].presence || 1.hour.ago)).to_i
                   response = get(call('search_url', input),
                                  'lastUpdatedAt' => last_updated_at,
                                  'count' => page_size,
                                  'page' => page,
                                  'orderBy' => 'updatedAt')&.
                               after_error_response(/.*/) do |_code, body, _header, message|
                                 error("#{message}: #{body}")
                               end
                   call('custom_output_parser', response['elements'],
                        call('get_date_time_fields', schema))
                 else
                   last_updated_at = (closure&.[]('last_update_at') || (input['since'].presence ||
                                       1.hour.ago)).in_time_zone('America/New_York').
                                       strftime('%Y-%m-%d %H:%M:%S')
                   date_fields = closure&.[]('date_fields') || call('get_date_time_fields',
                                                                    call('custom_object_output_schema', input))
                   response = get("/api/REST/1.0/data/customObject/#{input['object']}",
                                  search: 'ModifiedAt>' + "'" + last_updated_at + "'",
                                  count: page_size,
                                  page: page,
                                  orderBy: 'updatedAt')&.
                              after_error_response(/.*/) do |_code, body, _header, message|
                                error("#{message}: #{body}")
                              end
                   call('format_custom_object_records', response['elements'], date_fields)
                 end
        closure = if (has_more = page * page_size < response['total'])
                    { 'page' => page + 1,
                      'date_fields' => date_fields,
                      'last_updated_at' => last_updated_at }
                  else
                    last_updated_at =
                      (result&.dig(-1, 'updatedAt') || Time.now)
                    { 'page' => 1,
                      'date_fields' => date_fields,
                      'last_updated_at' => last_updated_at }
                  end
        {
          events: result,
          next_poll: closure,
          can_poll_more: has_more
        }
      end,
      dedup: lambda do |result|
        "#{result['id']}@#{result['updatedAt']}"
      end,
      output_fields: lambda do |object_definition|
        object_definition['get_record_output']
      end,
      sample_output: lambda do |_connection, input, e_o_s|
        if call('is_standard_objects', input)
          response = call('search_sample_output', input)&.
            []('elements')&.first
          call('custom_output_parser', response, call('get_date_time_fields', e_o_s))
        else
          record = get("/api/REST/1.0/data/customObject/#{input['id']}",
                       count: 1, page: 1, orderBy: 'updatedAt')&.dig('elements', 0)
          call('format_custom_object_records', record, call('get_date_time_fields',
                                                            call('custom_object_output_schema', input)))
        end
      end
    }

  },

  pick_lists: {
    update_object_list: lambda do
      %w[account campaign contact event event_registrant program account_group
         contact_segment contact_list external_asset contact_field].
        map { |key| [key.labelize, key] }.concat(
          get('/api/REST/2.0/assets/customObjects')&.[]('elements')&.map do |items|
            [items['name'], items['id']]
          end
        )
    end,

    get_object_list: lambda do
      %w[account campaign contact event event_registrant program account_group
         contact_segment contact_list external_asset contact_field
         external_activity contact_activity].map { |key| [key.labelize, key] }.
        concat(get('/api/REST/2.0/assets/customObjects')&.[]('elements')&.
            map { |element| [element['name'], element['id']] })
    end,

    create_object_list: lambda do
      %w[account campaign contact event event_registrant program account_group
         contact_segment contact_list external_activity external_asset
         contact_field].map { |key| [key.labelize, key] }.
        concat(get('/api/REST/2.0/assets/customObjects')&.[]('elements')&.
            map { |element| [element['name'], element['id']] })
    end,

    search_object_list: lambda do
      %w[account campaign contact event event_registrant program account_group
         contact_segment contact_list external_asset visitor contact_field
         email].map { |key| [key.labelize, key] }.
        concat(get('/api/REST/2.0/assets/customObjects')&.[]('elements')&.
            map { |element| [element['name'], element['id']] })
    end,

    delete_object_list: lambda do
      %w[account campaign contact event event_registrant program account_group
         contact_segment contact_list external_asset
         contact_field].map { |key| [key.labelize, key] }.
        concat(get('/api/REST/2.0/assets/customObjects')&.[]('elements')&.
            map { |element| [element['name'], element['id']] })
    end,

    trigger_object_list: lambda do
      %w[account campaign contact event program account_group
         contact_segment contact_list external_asset contact_field
         email].
        map { |key| [key.labelize, key] }.
        concat(get('/api/REST/2.0/assets/customObjects')&.[]('elements')&.
           map { |element| [element['name'], element['id']] })
    end,

    depth: lambda do
      %w[minimal partial complete].map { |key| [key.labelize, key] }
    end,

    current_status: lambda do
      %w[Active Draft Scheduled Completed].map { |key| [key, key] }
    end,

    scope: lambda do
      %w[local global].map { |key| [key.labelize, key] }
    end,

    render_mode: lambda do
      %w[fixed flow].map { |key| [key.labelize, key] }
    end,

    event_parentid: lambda do
      get('/api/REST/2.0/assets/eventRegistrations')&.[]('elements')&.
      map { |element| [element['name'], element['id']] }
    end
  },

  methods: {

    is_standard_objects: lambda do |input|
      %w[account campaign contact event event_registrant program account_group
         contact_segment contact_list external_asset contact_field external_activity
         contact_activity visitor email]&.include?(input['object'])
    end,

    sample_custom_object_record: lambda do |input|
      get("/api/REST/2.0/data/customObject/#{input['object']}/instances").
        params(count: 1)&.dig('elements', 0) || {}
    end,

    custom_object_input_schema: lambda do |input, _type|
      get("/api/REST/2.0/assets/customObject/#{input['object']}").
        params(depth: 'complete')&.[]('fields')&.
        map do |field|
          case field['dataType']
          when 'largeText'
            { type: 'string', control_type: 'text-area' }
          when 'date'
            { type: 'date_time' }
          when 'numeric'
            { type: 'number', hint: 'Decimal Field (up to 4 decimal places)' }
          when 'number'
            { type: 'integer', hint: 'Integer Field (no decimals, but negative numbers allowed)' }
          else
            case field['displayType']
            when 'checkbox'
              { control_type: 'select',
                pick_list: [
                  ['Checked', field['checkedValue']],
                  ['Unchecked', field['uncheckedValue']]
                ],
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: field['id'],
                  label: field['name'],
                  type: 'string',
                  control_type: 'text',
                  optional: true,
                  toggle_hint: 'Use custom value',
                  hint: "Allowed values are: for Checked - #{field['checkedValue']}," \
                    " Unchecked - #{field['uncheckedValue']}"
                } }
            when 'singleSelect'
              pick_list = call('get_picklist_options', field['optionListId']) || []
              { control_type: 'select',
                pick_list: pick_list,
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: field['id'],
                  label: field['name'],
                  type: 'string',
                  control_type: 'text',
                  optional: true,
                  toggle_hint: 'Use custom value',
                  hint: 'Provide code e.g.' \
                  "#{pick_list&.first(10)&.map { |option| option&.join(':- ') }&.smart_join('; ')}"
                } }
            else
              { type: 'string' }
            end
          end&.merge({ name: field['id'], label: field['name'] })
        end
    end,

    get_picklist_options: lambda do |option_list_id|
      get("/api/REST/1.0/assets/optionList/#{option_list_id}")&.[]('elements')&.
        select { |element| element['value'].present? }&.
        map { |item| [item['displayName'], item['value']] }
    end,

    format_custom_object_records: lambda do |input, date_fields|
      if input.is_a?(Array)
        input.map do |array_value|
          call('format_custom_object_records', array_value, date_fields)
        end
      else
        record = input.delete('fieldValues')&.map do |item|
          if date_fields&.include?(item['id'])
            { item['id'] => item['value'].blank? ? nil : item['value']&.to_i&.to_time&.in_time_zone('America/New_York')&.strftime('%Y-%m-%d %H:%M:%S.%L') }
          else
            { item['id'] => item['value'] }
          end
        end&.inject(:merge)
        input['createdAt'] = input.delete('createdAt')&.to_i&.to_time&.
            in_time_zone('America/New_York')&.strftime('%Y-%m-%d %H:%M:%S.%L') || nil
        input['updatedAt'] = input.delete('updatedAt')&.to_i&.to_time&.
            in_time_zone('America/New_York')&.strftime('%Y-%m-%d %H:%M:%S.%L') || nil
        input['unique_id'] = "#{input['id']}@#{record[:date_modified] || Time.now.in_time_zone('America/New_York')&.
              strftime('%Y-%m-%d %H:%M:%S.%L')}"
        record.merge(input)
      end
    end,

    custom_object_output_schema: lambda do |input|
      standard_fields = [
        { name: 'id' },
        { name: 'accountId' },
        { name: 'contactId' },
        { name: 'customObjectRecordStatus' },
        { name: 'isMapped' },
        { name: 'uniqueCode' },
        { name: 'createdAt', type: 'date_time' },
        { name: 'updatedAt', type: 'date_time' }
      ]
      custom_fields =
        get("/api/REST/2.0/assets/customObject/#{input['object']}").
          params(depth: 'complete')&.[]('fields')&.
        map do |field|
          case field['dataType']
          when 'largeText'
            { type: 'string', control_type: 'text-area' }
          when 'date'
            { type: 'date_time', hint: 'Date Field (DD/MM/YYYY)' }
          when 'numeric'
            { type: 'number', hint: 'Decimal Field (up to 4 decimal places)' }
          when 'number'
            { type: 'integer', hint: 'Integer Field (no decimals, but negative numbers allowed)' }
          else
            { type: 'string' }
          end&.merge({ name: field['id'], label: field['name'] })
        end
      standard_fields.concat(custom_fields).compact
    end,

    custom_input_parser: lambda do |input, date_time_fields|
      if input.is_a?(Array)
        input.map do |array_value|
          call('custom_input_parser', array_value, date_time_fields)
        end
      elsif input.is_a?(Hash)
        input.each_with_object({}) do |(key, value), hash|
          hash[key] = if date_time_fields.include?(key)
                        value&.to_i
                      elsif value.is_a?(Array) || value.is_a?(Hash)
                        call('custom_input_parser', value, date_time_fields)
                      else
                        value
                      end
        end
      end
    end,

    custom_output_parser: lambda do |payload, date_time_fields|
      if payload.is_a?(Array)
        payload.map do |array_value|
          call('custom_output_parser', array_value, date_time_fields)
        end
      elsif payload.is_a?(Hash)
        payload.each_with_object({}) do |(key, value), hash|
          hash[key] = if date_time_fields.include?(key)
                        value&.to_i&.to_time
                      elsif value.is_a?(Array) || value.is_a?(Hash)
                        call('custom_output_parser', value, date_time_fields)
                      else
                        value
                      end
        end
      else
        { 'value' => payload }
      end
    end,

    field_value_parser: lambda do |response|
      response.each_with_object({}) do |arr, hash|
        hash["c_#{arr['id']}"] = arr['value']
      end
    end,

    get_date_time_fields: lambda do |schema|
      schema.map do |field|
        if field['properties'].present?
          call('get_date_time_fields', field['properties'])
        elsif field['type'] == :date_time || field['type'] == 'date_time' ||
              field['type'] == :date || field['type'] == 'date' ||
              field[:type] == 'date_time'
          field['name'].presence || field[:name]
        end
      end.flatten.compact
    end,

    search_url: lambda do |input|
      object_name = input['object']
      case object_name
      when 'account'
        '/api/REST/1.0/data/accounts'
      when 'contact'
        '/api/REST/1.0/data/contacts'
      when 'campaign'
        '/api/REST/2.0/assets/campaigns'
      when 'event'
        '/api/REST/2.0/assets/eventRegistrations'
      when 'event_registrant'
        "/api/REST/2.0/data/eventRegistration/#{input['parentId']}/instances"
      when 'program'
        '/api/REST/2.0/assets/programs'
      when 'account_group'
        '/api/REST/2.0/assets/account/groups'
      when 'contact_segment'
        '/api/REST/2.0/assets/contact/segments'
      when 'contact_list'
        '/api/REST/1.0/assets/contact/lists'
      when 'external_asset'
        '/api/REST/2.0/assets/externals'
      when 'contact_field'
        '/api/REST/1.0/assets/contact/fields'
      when 'visitor'
        '/api/REST/2.0/data/visitors'
      when 'email'
        '/api/REST/2.0/assets/emails'
      end
    end,

    get_url: lambda do |input|
      object_name = input['object']
      case object_name
      when 'account'
        "/api/REST/1.0/data/#{object_name}/#{input.delete('id')}"
      when 'contact'
        "/api/REST/1.0/data/#{object_name}/#{input.delete('id')}"
      when 'campaign'
        "/api/REST/2.0/assets/#{object_name}/#{input.delete('id')}"
      when 'event'
        "/api/REST/2.0/assets/eventRegistration/#{input.delete('id')}"
      when 'event_registrant'
        "/api/REST/2.0/data/eventRegistration/#{input['parentId']}/instance/#{input.delete('id')}"
      when 'program'
        "/api/REST/2.0/assets/program/#{input.delete('id')}"
      when 'account_group'
        "/api/REST/2.0/assets/account/group/#{input.delete('id')}"
      when 'contact_segment'
        "/api/REST/2.0/assets/contact/segment/#{input.delete('id')}"
      when 'contact_list'
        "/api/REST/1.0/assets/contact/list/#{input.delete('id')}"
      when 'external_asset'
        "/api/REST/2.0/assets/external/#{input.delete('id')}"
      when 'contact_field'
        "/api/REST/1.0/assets/contact/field/#{input.delete('id')}"
      when 'external_activity'
        "/api/REST/2.0/data/activity/#{input.delete('id')}"
      when 'contact_activity'
        "/api/REST/1.0/data/activities/contact/#{input.delete('id')}"
      end
    end,

    create_url: lambda do |input|
      object_name = input['object']
      case object_name
      when 'account'
        "/api/REST/1.0/data/#{object_name}"
      when 'contact'
        "/api/REST/1.0/data/#{object_name}"
      when 'campaign'
        "/api/REST/2.0/assets/#{object_name}"
      when 'event'
        '/api/REST/2.0/assets/eventRegistration'
      when 'event_registrant'
        "/api/REST/2.0/data/eventRegistration/#{input.delete('parentId')}/instance"
      when 'program'
        "/api/REST/2.0/assets/#{object_name}"
      when 'account_group'
        '/api/REST/2.0/assets/account/group'
      when 'contact_segment'
        '/api/REST/2.0/assets/contact/segment'
      when 'contact_list'
        '/api/REST/1.0/assets/contact/list'
      when 'external_activity'
        '/api/REST/2.0/data/activity'
      when 'external_asset'
        '/api/REST/2.0/assets/external'
      when 'contact_field'
        '/api/REST/1.0/assets/contact/field'
      end
    end,

    accounts_field_values: lambda do |input|
      fields = get("/api/REST/1.0/assets/#{input}/fields?depth=complete")
      fields['elements'].map do |arr|
        if arr['isStandard'] == "false" && arr['isReadOnly'] == "false"
          if arr['dataType'] == 'date'
            { name: "c_#{arr['id']}", label: arr['name'], sticky: true,
              type: 'date_time', render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion' }
          elsif arr['dataType'] == 'integer'
            { name: "c_#{arr['id']}", label: arr['name'], sticky: true,
              type: 'integer', render_input: 'integer_conversion',
              parse_output: 'integer_conversion' }
          elsif arr['dataType'] == 'numeric'
            { name: "c_#{arr['id']}", label: arr['name'], sticky: true,
              type: 'number', control_type: 'number',
              render_input: 'float_conversion',
              parse_output: 'float_conversion' }
          else
            { name: "c_#{arr['id']}", label: arr['name'], sticky: true }
          end
        end
      end.compact
    end,

    campaigns_field_values: lambda do
      [
        { name: 'type', hint: "The asset's type in Eloqua" },
        { name: 'value',
          hint: 'The value to set the corresponding field id to. ' \
                'Date values must be submitted as a unix timestamp.' },
        { name: 'id' },
        { name: 'name', hint: 'Name of the field value.' }
      ]
    end,

    campaigns_elements: lambda do |schema|
      fields = [
        { name: 'id' },
        { name: 'type',
          hint: "The asset's type in Eloqua." },
        { name: 'currentStatus',
          hint: "The campaign element's current status." },
        { name: 'name',
          hint: 'Name of the campaign element.' },
        { name: 'description',
          hint: 'The description of the campaign element.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [
            { name: 'value',
              hint: 'The permissions for the campaign element granted to your ' \
                    'current instance.' }
          ] },
        { name: 'folderId' },
        { name: 'sourceTemplateId',
          hint: 'The id of the source template.' },
        { name: 'createdBy' },
        { name: 'createdAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'updatedBy' },
        { name: 'updatedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'accessedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'scheduledFor', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'depth' },
        { name: 'position', type: 'array', of: 'object',
          properties: [
            { name: 'type',
              hint: "The campaign element's type." },
            { name: 'x', label: 'X axis',
              hint: 'The position of the campaign element on the x axis.' },
            { name: 'y', label: 'Y axis',
              hint: 'The position of the campaign element on the y axis.' }
          ] },
        { name: 'outputTerminals', type: 'array', of: 'object',
          item_label: 'Output terminals',
          add_item_label: 'Add output terminals',
          empty_list_title: 'Output terminals list is empty',
          properties: call('campaigns_output_terminals', schema) },
        { name: 'memberCount',
          hint: 'Amount of members within the campaign element.' },
        { name: 'memberErrorCount',
          hint: "Campaign element field's member error count description" }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'folderId', 'createdAt', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'scheduledFor', 'depth',
                         'permissions')
      else
        fields
      end
    end,

    campaigns_output_terminals: lambda do |schema|
      fields = [
        { name: 'id' },
        { name: 'type',
          hint: "The asset's type in Eloqua. " },
        { name: 'currentStatus',
          hint: "The campaign output terminal's current status." },
        { name: 'name',
          hint: 'Name of the campaign output terminal.' },
        { name: 'description',
          hint: 'The description of the campaign output terminal.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [
            { name: 'value',
              hint: 'The permissions for the campaign element granted to your ' \
                    'current instance.' }
          ] },
        { name: 'folderId' },
        { name: 'sourceTemplateId',
          hint: 'The id of the source template.' },
        { name: 'createdBy' },
        { name: 'createdAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'updatedBy' },
        { name: 'updatedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'accessedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'scheduledFor', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'depth' },
        { name: 'terminalType',
          hint: 'The campaign output terminal type.' },
        { name: 'connectedType',
          hint: "The campaign output terminal's connection type." },
        { name: 'connectedId',
          hint: 'The connected id of the campaign output terminal.' }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'folderId', 'createdAt', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'scheduledFor', 'depth',
                         'permissions')
      else
        fields
      end
    end,

    events_fields: lambda do |schema|
      fields = [
        { name: 'id' },
        { name: 'type',
          hint: "The asset's type in Eloqua. " },
        { name: 'currentStatus',
          hint: 'This property is not used for custom object fields.' },
        { name: 'description',
          hint: 'This property is not used for custom object fields.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [
            { name: 'value',
              hint: 'The permissions for the event element granted to your ' \
                    'current instance.' }
          ] },
        { name: 'folderId' },
        { name: 'sourceTemplateId',
          hint: 'This property is not used for custom object fields.' },
        { name: 'createdBy' },
        { name: 'createdAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'updatedBy' },
        { name: 'updatedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'accessedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'scheduledFor', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'depth' },
        { name: 'name',
          hint: 'The name of the custom object field.' },
        { name: 'displayType',
          hint: "The custom object field's display type." },
        { name: 'dataType',
          hint: "The custom object field's data type." },
        { name: 'defaultValue',
          hint: "The custom object field's default value." },
        { name: 'internalName',
          hint: "The custom object field's internal name." },
        { name: 'optionListId',
          hint: 'The option list id for a single select custom object field.' },
        { name: 'checkedValue',
          hint: 'The checked value of a checkbox custom object field.' },
        { name: 'uncheckedValue',
          hint: 'The unchecked value of a checkbox custom object field.' }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'folderId', 'createdAt', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'scheduledFor', 'depth',
                         'permissions')
      else
        fields
      end
    end,

    events_sessions: lambda do |schema|
      fields = [
        { name: 'id' },
        { name: 'type', hint: "The asset's type in Eloqua." },
        { name: 'currentStatus',
          hint: 'This property is not used for event sessions.' },
        { name: 'name',
          hint: 'The name of the session.' },
        { name: 'description',
          hint: 'This property is not used for event sessions.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [
            { name: 'value',
              hint: 'The permissions for the event element granted to your ' \
                    'current instance.' }
          ] },
        { name: 'folderId' },
        { name: 'sourceTemplateId',
          hint: 'This property is not used for event sessions.' },
        { name: 'createdBy' },
        { name: 'createdAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'updatedBy' },
        { name: 'updatedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'accessedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'scheduledFor', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'depth' },
        { name: 'participantsLimit', type: 'integer',
          control_type: 'integer', render_input: 'integer',
          hint: 'The maximum number of participants per session.' }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'folderId', 'createdAt', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'scheduledFor', 'depth',
                         'permissions')
      else
        fields
      end
    end,

    events_session_fields: lambda do |schema|
      fields = [
        { name: 'id' },
        { name: 'type',
          hint: "The asset's type in Eloqua." },
        { name: 'currentStatus',
          hint: 'This property is not used for event session fields.' },
        { name: 'name',
          hint: 'The name of the session field within an event.' },
        { name: 'description',
          hint: 'This property is not used for event session fields.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [
            { name: 'value',
              hint: 'The permissions for the event element granted to your ' \
                    'current instance.' }
          ] },
        { name: 'folderId' },
        { name: 'sourceTemplateId',
          hint: 'This property is not used for event session fields.' },
        { name: 'createdBy' },
        { name: 'createdAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'updatedBy' },
        { name: 'updatedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'accessedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'scheduledFor', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'depth' },
        { name: 'dataType',
          hint: 'The DataType of the session field.' },
        { name: 'outputFormat', type: 'object',
          properties: [
            { name: 'type' },
            { name: 'currentStatus' },
            { name: 'id' },
            { name: 'format' },
            { name: 'dataType' }
          ] }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'folderId', 'createdAt', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'scheduledFor', 'depth',
                         'permissions')
      else
        fields
      end
    end,

    events_session_field_values: lambda do |schema|
      fields = [
        { name: 'id' },
        { name: 'type',
          hint: "The asset's type in Eloqua." },
        { name: 'currentStatus',
          hint: 'This property is not used for event session field values.' },
        { name: 'name',
          hint: 'This property is not used for event session field values.' },
        { name: 'description',
          hint: 'This property is not used for event session field values.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [
            { name: 'value',
              hint: 'The permissions for the event element granted to your ' \
                    'current instance.' }
          ] },
        { name: 'folderId' },
        { name: 'sourceTemplateId',
          hint: 'This property is not used for event session field values.' },
        { name: 'createdBy' },
        { name: 'createdAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'updatedBy' },
        { name: 'updatedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'accessedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'scheduledFor', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'depth' },
        { name: 'sessionId',
          hint: 'The SessionId of the session within an event for which ' \
                'field value is passed.' },
        { name: 'sessionFieldId',
          hint: 'The SessionFieldId of the field. The session field ' \
                'must be created first before creating session field values.' },
        { name: 'value',
          hint: 'The value for the event session field.' }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'folderId', 'createdAt', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'scheduledFor', 'depth',
                         'permissions')
      else
        fields
      end
    end,

    account_schema: lambda do |schema|
      fields = [
        { name: 'type', label: 'Account type', sticky: true,
          hint: "The asset's type in Eloqua." },
        { name: 'id', label: 'Account ID' },
        { name: 'currentStatus', sticky: true,
          hint: "The account's current status." },
        { name: 'name', sticky: true,
          hint: 'The name of the account.' },
        { name: 'description', sticky: true,
          hint: 'The description of the account.' },
        { name: 'permissions', sticky: true,
          hint: 'The permissions for the account granted to your current ' \
                'instance.' },
        { name: 'createdBy' },
        { name: 'createdAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'updatedBy' },
        { name: 'updatedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'accessedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'depth' },
        { name: 'fieldValues', type: 'object',
          properties: call('accounts_field_values', 'account') },
        { name: 'address1',
          hint: "The account's first address." },
        { name: 'address2',
          hint: "The account's second address." },
        { name: 'address3',
          hint: "The account's third address." },
        { name: 'city',
          hint: "The account's city." },
        { name: 'province',
          hint: "The account's province." },
        { name: 'postalCode',
          hint: "The account's postal code." },
        { name: 'country',
          hint: "The account's country." },
        { name: 'businessPhone',
          hint: "The account's business phone number." }
      ]
      if schema == 'input'
        fields&.ignored('createdBy', 'type', 'createdAt', 'updatedBy', 'updatedAt',
                         'accessedAt', 'depth', 'permissions', 'id')
      else
        fields
      end
    end,

    contact_schema: lambda do |schema|
      fields = [
        { name: 'type', label: 'Contact type', sticky: true,
          hint: "The asset's type in Eloqua." },
        { name: 'id', label: 'Contact ID' },
        { name: 'currentStatus', sticky: true,
          hint: "The contact's current status." },
        { name: 'name', sticky: true,
          hint: 'The name of the contact.' },
        { name: 'description', sticky: true,
          hint: 'The description of the contact.' },
        { name: 'permissions', sticky: true,
          hint: 'The permissions for the contact granted to your ' \
                'current instance.' },
        { name: 'createdBy' },
        { name: 'createdAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'updatedBy' },
        { name: 'updatedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'accessedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'depth' },
        { name: 'firstName', sticky: true,
          hint: "The contact's first name." },
        { name: 'lastName', sticky: true,
          hint: "The contact's last name." },
        { name: 'emailAddress', optional: false,
          hint: "The contact's email address." },
        { name: 'emailFormatPreference',
          hint: "The contact's email format preference." },
        { name: 'isSubscribed',
          hint: 'Whether or not the contact is subscribed.' },
        { name: 'isBounceback',
          hint: 'Whether or not the contact has any associated bouncebacks.' },
        { name: 'accountName',
          hint: 'The account name in which the contact belongs.' },
        { name: 'accountId',
          hint: 'The account id in which the contact belongs.' },
        { name: 'title',
          hint: "The contact's title." },
        { name: 'subscriptionDate', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: "The contact's subscription date." },
        { name: 'unsubscriptionDate', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: "The contact's unsubscription date." },
        { name: 'bouncebackDate', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: "The contact's bounceback date." },
        { name: 'fieldValues', type: 'object',
          properties: call('accounts_field_values', 'contact') },
        { name: 'address1',
          hint: "The contact's first address." },
        { name: 'address2',
          hint: "The contact's second address." },
        { name: 'address3',
          hint: "The contact's third address." },
        { name: 'city',
          hint: "The contact's city." },
        { name: 'province',
          hint: "The contact's province." },
        { name: 'postalCode',
          hint: "The contact's postal code." },
        { name: 'country',
          hint: "The contact's country." },
        { name: 'businessPhone',
          hint: "The contact's business phone number." },
        { name: 'mobilePhone',
          hint: "The contact's mobile phone number." },
        { name: 'fax',
          hint: "The contact's fax number." },
        { name: 'salesPerson',
          hint: "The contact's account representative." }
      ]
      if schema == 'input'
        fields&.ignored('createdBy', 'type', 'createdAt', 'updatedBy',
                         'updatedAt', 'accessedAt', 'depth', 'permissions', 'id')
      else
        fields
      end
    end,

    campaign_schema: lambda do |schema|
      fields = [
        { name: 'id', label: 'Campaign ID' },
        { name: 'type', label: 'Campaign type', sticky: true,
          hint: "The asset's type in Eloqua." },
        { name: 'currentStatus', sticky: true,
          type: 'string', control_type: 'select',
          pick_list: 'current_status', toggle_hint: 'Select from list',
          hint: "The campaign's current status: Active, Draft, " \
                'Scheduled, or Completed',
          toggle_field: {
            name: 'currentStatus',
            label: 'Current status',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "The campaign's current status: Active, Draft, " \
                  'Scheduled, or Completed'
          } },
        { name: 'name', sticky: true,
          hint: 'The name of the campaign.' },
        { name: 'description', sticky: true,
          hint: 'The description of the campaign.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [
            { name: 'value',
              hint: 'The permissions for the campaign element granted to ' \
                    'your current instance.' }
          ] },
        { name: 'folderId' },
        { name: 'sourceTemplateId', sticky: true,
          hint: 'Id of the template used to create the asset.' },
        { name: 'createdBy' },
        { name: 'createdAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'updatedBy' },
        { name: 'updatedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'accessedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'scheduledFor', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'depth' },
        { name: 'elements', type: 'array', of: 'object', sticky: true,
          item_label: 'Elements',
          add_item_label: 'Add elements',
          empty_list_title: 'Elements list is empty',
          properties: call('campaigns_elements', schema) },
        {
          name: 'isReadOnly',
          type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          hint: 'Whether or not the program is read only.',
          toggle_field: {
            name: 'isReadOnly',
            label: 'Is read only',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false.'
          }
        },
        { name: 'runAsUserId',
          hint: 'The login id of the user to activate the campaign.' },
        { name: 'startAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          hint: 'The date time for which the campaign will activate,' \
                ' expressed in Unix time.' },
        { name: 'endAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the campaign will end.' },
        { name: 'budgetedCost',
          hint: "The campaign's projected cost." },
        { name: 'actualCost',
          hint: "The campaign's actual cost." },
        { name: 'isMemberAllowedReEntry',
          hint: 'Whether or not members are allowed to re-enter the campaign.' },
        { name: 'fieldValues', type: 'array', of: 'object',
          item_label: 'Field values',
          add_item_label: 'Add fields values',
          empty_list_title: 'Fields values list is empty',
          properties: call('campaigns_field_values') },
        { name: 'campaignType', sticky: true,
          hint: "The campaign's type." },
        { name: 'product',
          hint: "The campaign's product value." },
        { name: 'region',
          hint: "The campaign's region value." },
        { name: 'clrEndDate', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The end date of the clr.' },
        { name: 'crmId',
          hint: 'The id of the customer relationship management application.' },
        { name: 'isSyncedWithCRM',
          hint: 'Whether or not the campaign is synced with a customer '\
                'relationship management application.' },
        { name: 'isIncludedInROI',
          hint: 'Whether or not the campaign is included in return on investment.' },
        { name: 'badgeId',
          hint: 'The badge id of the campaign.' },
        { name: 'isEmailMarketingCampaign',
          hint: 'Whether or not the campaign is an email marketing campaign.' },
        { name: 'campaignCategory',
          hint: 'Defines whether a Campaign is simple or multi-step. '\
                'The value <code>emailMarketing</code> should be used for '\
                'simple campaigns, and <code>contact</code> for '\
                'multi-step campaigns.' },
        { name: 'firstActivation', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'memberCount' }
      ]
      if schema == 'input'
        fields&.ignored('createdBy', 'type', 'createdAt', 'updatedBy', 'permissions',
                         'updatedAt', 'accessedAt', 'depth', 'folderId',
                         'scheduledFor', 'firstActivation', 'memberCount', 'id')
      else
        fields
      end
    end,

    event_schema: lambda do |schema|
      fields = [
        { name: 'id', label: 'Event ID' },
        { name: 'type', label: 'Event type', sticky: true,
          hint: "The asset's type in Eloqua. " },
        { name: 'currentStatus', sticky: true,
          hint: 'This property is not used for events.' },
        { name: 'name', sticky: true,
          hint: 'The name of the event.' },
        { name: 'description', sticky: true,
          hint: 'The description of the event.' },
        { name: 'permissions', type: 'array', of: 'object', sticky: true,
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [
            { name: 'value',
              hint: 'The permissions for the event element granted to your ' \
                    'current instance.' }
          ] },
        { name: 'folderId' },
        { name: 'sourceTemplateId',
          hint: 'This property is not used for events.' },
        { name: 'createdBy' },
        { name: 'createdAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'updatedBy' },
        { name: 'updatedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'accessedAt', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'scheduledFor', type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'depth' },
        { name: 'fields', type: 'array', of: 'object', sticky: true,
          item_label: 'Fields',
          add_item_label: 'Add fields',
          empty_list_title: 'Fields list is empty',
          properties: call('events_fields', schema) },
        { name: 'sessions', type: 'array', of: 'object',
          item_label: 'Sessions',
          add_item_label: 'Add sessions',
          empty_list_title: 'Sessions list is empty',
          properties: call('events_sessions', schema) },
        { name: 'sessionFields', type: 'array', of: 'object',
          item_label: 'Session fields',
          add_item_label: 'Add session fields',
          empty_list_title: 'Session fields list is empty',
          properties: call('events_session_fields', schema) },
        { name: 'sessionFieldValues', type: 'array', of: 'object',
          item_label: 'Session field values',
          add_item_label: 'Add session fields values',
          empty_list_title: 'Session fields values list is empty',
          properties: call('events_session_field_values', schema) },
        { name: 'emailAddressFieldId',
          hint: 'The field id that contains the Email Address. Use the desired' \
                " custom object field's negative id as the value for this parameter." },
        { name: 'uniqueCodeFieldId',
          hint: 'The field id that contains the unique identifier. ' \
                "Use the desired custom object field's negative id as the value" \
                ' for this parameter.' },
        { name: 'eventGroupByFieldId',
          hint: 'The id of the field used to organize multiple sessions. ' \
                "Use the desired custom object field's negative id as " \
                'the value for this parameter.' }
      ]
      if schema == 'input'
        fields&.ignored('folderId', 'type', 'createdAt', 'createdBy', 'updatedBy', 'depth',
                         'updatedAt', 'accessedAt', 'scheduledFor', 'permissions',
                         'type', 'id')
      else
        fields
      end
    end,

    event_registrant_field_values: lambda do |input|
      if input['parentId'].present?
        fields = get("/api/REST/2.0/assets/eventRegistration/#{input['parentId']}")
        call('customobject_input', fields)
      else
        []
      end
    end,

    event_registrant_schema: lambda do |input, schema|
      fields = [
        { name: 'parentId', label: 'Parent event', optional: false,
          type: 'string', control_type: 'select',
          extends_schema: true,
          pick_list: 'event_parentid', toggle_hint: 'Select from list',
          hint: 'Name of the parent event',
          toggle_field: {
            name: 'parentId',
            label: 'Parent ID',
            optional: false,
            extends_schema: true,
            change_on_blur: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Id of the parent event'
          } },
        { name: 'type', sticky: true,
          hint: "The asset's type in Eloqua." },
        { name: 'id', sticky: true, hint: 'Id of the event registrant.' },
        { name: 'currentStatus', sticky: true,
          hint: 'This property is not used for event registrants.' },
        { name: 'name', hint: 'The name of the event registrant.' },
        { name: 'description', sticky: true,
          hint: 'This property is not used for event registrants.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [{ name: 'value' }] },
        { name: 'folderId', sticky: true,
          hint: 'This property is not used for event registrants.' },
        { name: 'sourceTemplateId', sticky: true,
          hint: 'This property is not used for event registrants.' },
        { name: 'createdBy',
          hint: 'This property is not used for event registrants.' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the event registrant was created, ' \
                'expressed in Unix time.' },
        { name: 'updatedBy',
          hint: 'This property is not used for event registrants.' },
        { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Unix timestamp for the date and time the event registrant ' \
                'was last updated.' },
        { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'This property is not used for event registrants.' },
        { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'This property is not used for event registrants.' },
        { name: 'depth',
          hint: 'This property is not used for event registrants.' },
        { name: 'contactId', sticky: true,
          hint: 'The contact record Id associated to this event registrant. '\
                "Use the desired contact's id as the value for this parameter." },
        { name: 'accountId',
          hint: 'The account record Id associated to this event registrant.' },
        { name: 'uniqueCode',
          hint: 'The unique value associated to the event registrant.' },
        { name: 'customObjectRecordStatus',
          hint: 'The status of the event registrant. ' \
                'Only returned when creating or updating an event registrant.' },
        { name: 'fieldValues', type: 'object',
          properties: call('event_registrant_field_values', input) },
        { name: 'isMapped',
          hint: 'Whether or not the event registrant is mapped to a ' \
                'contact or account.' }
      ]

      objects = call('event_registrant_field_values', input)
      if objects.presence
        if schema == 'input'
          fields&.ignored('id', 'type', 'folderId', 'createdAt', 'createdBy', 'updatedBy',
                           'updatedAt', 'accessedAt', 'scheduledFor', 'depth',
                           'permissions')
        else
          fields&.ignored('parentId')
        end
      else
        if schema == 'output'
          []
        else
          fields.only('parentId')
        end
      end
    end,

    program_schema: lambda do |schema|
      fields = [
        { name: 'type', label: 'Program type',
          sticky: true, hint: "The asset's type in Eloqua." },
        { name: 'id', label: 'Program ID',
          sticky: true, hint: 'Id of the program.' },
        { name: 'currentStatus', sticky: true,
          type: 'string', control_type: 'select',
          pick_list: 'current_status', toggle_hint: 'Select from list',
          hint: "The campaign's current status: Active, Draft, " \
                'Scheduled, or Completed',
          toggle_field: {
            name: 'currentStatus',
            label: 'Current status',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "The campaign's current status: Active, Draft, " \
                  'Scheduled, or Completed'
          } },
        { name: 'name', sticky: true, hint: 'The name of the program.' },
        { name: 'description', sticky: true,
          hint: 'The description of the program.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [
            { name: 'value' }
          ] },
        { name: 'folderId', sticky: true,
          hint: 'The folder id of the folder which contains the program.' },
        { name: 'sourceTemplateId', sticky: true,
          hint: 'Id of the template used to create the asset.' },
        { name: 'createdBy',
          hint: 'The login id of the user who created the program.' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the program was created, ' \
                'expressed in Unix time.' },
        { name: 'updatedBy',
          hint: 'The login id of the user that last updated the program.' },
        { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Unix timestamp for the date and time the ' \
                'program was last updated.' },
        { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the program was last accessed, ' \
                'expressed in Unix time.' },
        { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date the program is scheduled.' },
        { name: 'depth', sticky: true,
          type: 'string', control_type: 'select',
          default: 'complete',
          pick_list: 'depth', toggle_hint: 'Select from list',
          hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                'retrieve entities at three different levels of depth: ' \
                'minimal, partial, and complete. ',
          toggle_field: {
            name: 'depth',
            label: 'Depth',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            default: 'complete',
            toggle_hint: 'Use custom value',
            hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                  'retrieve entities at three different levels of depth: ' \
                  'minimal, partial, and complete. '
          } },
        { name: 'elements', type: 'array', of: 'object',
          item_label: 'Elements',
          add_item_label: 'Add elements',
          empty_list_title: 'Elements list is empty',
          properties: call('campaigns_elements', schema) },
        {
          name: 'isReadOnly',
          type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          hint: 'Whether or not the program is read only.',
          toggle_field: {
            name: 'isReadOnly',
            label: 'Is read only',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false.'
          }
        },
        { name: 'runAsUserId', sticky: true,
          hint: 'The login id of the user to activate the program.' },
        { name: 'isMemberAllowedDuplicates',
          hint: 'Whether contacts are allowed to enter the program more ' \
                'than once. If false, once a contact enters the program, ' \
                'the contact cannot enter the program again from another ' \
                'entry point.' },
        { name: 'defaultEntityType', sticky: true,
          hint: 'The program type, possible values are Contact or ' \
                'CustomObjectRecords.' },
        { name: 'defaultEntityId',
          hint: 'The id of the custom object data set. Only used for ' \
                'custom object programs.' }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'folderId', 'createdAt', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'scheduledFor', 'depth',
                         'permissions')
      else
        fields
      end
    end,

    visitor_schema: lambda do |_schema|
      [
        { name: 'type', label: 'Visitor type',
          sticky: true, hint: "The visitor's type in Eloqua." },
        { name: 'visitorId', sticky: true, hint: 'The Id of the visitor profile.' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the visitor was created, expressed in Unix time.' },
        { name: 'contactId',
          hint: 'The contact record Id associated to this profile, if any.' },
        { name: 'id', type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The id of the visitor.' }
      ]
    end,

    account_group_schema: lambda do |schema|
      fields = [
        { name: 'type', label: 'Account group type',
          sticky: true, hint: "The asset's type in Eloqua." },
        { name: 'id', label: 'Account group ID',
          sticky: true, hint: 'Id of the account group.' },
        { name: 'currentStatus', sticky: true,
          hint: "The account group's current status." },
        { name: 'name', sticky: true, hint: "The account group's name." },
        { name: 'description', sticky: true,
          hint: 'The description of the account group.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [
            { name: 'value' }
          ] },
        { name: 'folderId',
          hint: 'The folder id of the folder which contains the ' \
                'account group.' },
        { name: 'sourceTemplateId', sticky: true,
          hint: 'Id of the template used to create the account group.' },
        { name: 'createdBy',
          hint: 'The login id of the user who created the account group.' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the account group was created, ' \
                'expressed in Unix time.' },
        { name: 'updatedBy',
          hint: 'The login id of the user that last updated the ' \
                'account group.' },
        { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Unix timestamp for the date and time the account ' \
                'group was last updated.' },
        { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the account group was last accessed, ' \
                'expressed in Unix time.' },
        { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date the account group is scheduled.' },
        { name: 'depth', sticky: true,
          type: 'string', control_type: 'select',
          default: 'complete',
          pick_list: 'depth', toggle_hint: 'Select from list',
          hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                'retrieve entities at three different levels of depth: ' \
                'minimal, partial, and complete. ',
          toggle_field: {
            name: 'depth',
            label: 'Depth',
            sticky: true,
            optional: true,
            type: 'string',
            control_type: 'text',
            default: 'complete',
            toggle_hint: 'Use custom value',
            hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                  'retrieve entities at three different levels of depth: ' \
                  'minimal, partial, and complete. '
          } },
        { name: 'count',
          hint: 'The number of companies within the account group.' },
        { name: 'isArchived',
          hint: 'The account group is archived or not.' }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'folderId', 'createdAt', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'scheduledFor', 'depth',
                         'permissions')
      else
        fields
      end
    end,

    contact_segment_elements: lambda do |schema|
      fields = [
        { name: 'type', hint: "The asset's type in Eloqua." },
        { name: 'id', hint: 'Id of the contact segment element.' },
        { name: 'currentStatus',
          hint: "The contact segment element's current status." },
        { name: 'name',
          hint: 'This property is not used for contact segment elements.' },
        { name: 'description',
          hint: 'This property is not used for contact segment elements.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [
            { name: 'value' }
          ] },
        { name: 'folderId',
          hint: 'The folder id of the folder which contains the contact ' \
                'segment element.' },
        { name: 'sourceTemplateId',
          hint: 'This property is not used for contact segment elements.' },
        { name: 'createdBy',
          hint: 'The login id of the user who created the contact ' \
                'segment element.' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the contact segment element was ' \
                'created, expressed in Unix time.' },
        { name: 'updatedBy',
          hint: 'The login id of the user that last updated the ' \
                'contact segment element.' },
        { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Unix timestamp for the date and time the contact ' \
                'segment element was last updated.' },
        { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'This property is not used for contact segment elements.' },
        { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'This property is not used for contact segment elements.' },
        { name: 'depth', sticky: true,
          type: 'string', control_type: 'select',
          default: 'complete',
          pick_list: 'depth', toggle_hint: 'Select from list',
          hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                'retrieve entities at three different levels of depth: ' \
                'minimal, partial, and complete. ',
          toggle_field: {
            name: 'depth',
            label: 'Depth',
            sticky: true,
            optional: true,
            type: 'string',
            control_type: 'text',
            default: 'complete',
            toggle_hint: 'Use custom value',
            hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                  'retrieve entities at three different levels of depth: ' \
                  'minimal, partial, and complete. '
          } },
        { name: 'isIncluded',
          hint: 'The total amount of contacts within the segment element.' },
        { name: 'count',
          hint: 'The number of contacts in the contact segment element.' },
        { name: 'lastCalculatedAt', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the contact segment element was ' \
                'last calculated.' }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'folderId', 'createdAt', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'scheduledFor', 'depth',
                         'permissions')
      else
        fields
      end
    end,

    contact_segment_schema: lambda do |schema|
      fields = [
        { name: 'type', label: 'Contact segment type',
          sticky: true, hint: "The asset's type in Eloqua." },
        { name: 'id', label: 'Contact segment ID',
          sticky: true, hint: 'Id of the contact segment.' },
        { name: 'currentStatus', sticky: true,
          hint: 'This property is not used for contact segments.' },
        { name: 'name', hint: "The contact segment's name." },
        { name: 'description', sticky: true,
          hint: 'This property is not used for contact segments.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [
            { name: 'value' }
          ] },
        { name: 'folderId',
          hint: 'The folder id of the folder which contains the contact segment.' },
        { name: 'sourceTemplateId', sticky: true,
          hint: 'This property is not used for contact segments.' },
        { name: 'createdBy',
          hint: 'The login id of the user who created the contact segment.' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the contact segment was created, ' \
                'expressed in Unix time.' },
        { name: 'updatedBy',
          hint: 'The login id of the user that last updated the contact segment.' },
        { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Unix timestamp for the date and time the contact segment ' \
                'was last updated.' },
        { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'This property is not used for contact segments.' },
        { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'This property is not used for contact segments.' },
        { name: 'depth', sticky: true,
          type: 'string', control_type: 'select',
          default: 'complete',
          pick_list: 'depth', toggle_hint: 'Select from list',
          hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                'retrieve entities at three different levels of depth: ' \
                'minimal, partial, and complete. ',
          toggle_field: {
            name: 'depth',
            label: 'Depth',
            sticky: true,
            optional: true,
            type: 'string',
            control_type: 'text',
            default: 'complete',
            toggle_hint: 'Use custom value',
            hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                  'retrieve entities at three different levels of depth: ' \
                  'minimal, partial, and complete. '
          } },
        { name: 'elements', type: 'array', of: 'object',
          item_label: 'Elements',
          add_item_label: 'Add elements',
          empty_list_title: 'Elements list is empty',
          properties: call('contact_segment_elements', schema) },
        { name: 'count', hint: 'The number of contacts in the contact segment.' },
        { name: 'lastCalculatedAt',
          hint: 'The date and time of the most recent calculation.' },
        { name: 'isStale',
          hint: 'Whether or not the contact segment has been refreshed in the ' \
                'last 24 hours by the user performing the request.' }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'folderId', 'createdAt', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'scheduledFor', 'depth',
                         'permissions')
      else
        fields
      end
    end,

    contact_list_schema: lambda do |schema|
      fields = [
        { name: 'type', label: 'contact list type',
          sticky: true, hint: "The asset's type in Eloqua." },
        { name: 'id', label: 'Contact list ID',
          sticky: true, hint: 'Id of the contact list.' },
        { name: 'currentStatus', sticky: true, hint: "The contact list's current status." },
        { name: 'name', sticky: true, hint: "The contact list's name." },
        { name: 'description', sticky: true,
          hint: 'The description of the contact list.' },
        { name: 'permissions',
          hint: 'The permissions for the contact list granted to your ' \
                'current instance.' },
        { name: 'createdBy',
          hint: 'The login id of the user who created the contact list.' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the contact segment was created, ' \
                'expressed in Unix time.' },
        { name: 'updatedBy',
          hint: 'The login id of the user that last updated the contact list.' },
        { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Unix timestamp for the date and time the contact list ' \
                'was last updated.' },
        { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the contact list was last accessed, ' \
                'expressed in Unix time.' },
        { name: 'depth', sticky: true,
          type: 'string', control_type: 'select',
          default: 'complete',
          pick_list: 'depth', toggle_hint: 'Select from list',
          hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                'retrieve entities at three different levels of depth: ' \
                'minimal, partial, and complete. ',
          toggle_field: {
            name: 'depth',
            label: 'Depth',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            default: 'complete',
            toggle_hint: 'Use custom value',
            hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                  'retrieve entities at three different levels of depth: ' \
                  'minimal, partial, and complete. '
          } },
        { name: 'scope', sticky: true,
          type: 'string', control_type: 'select',
          pick_list: 'scope', toggle_hint: 'Select from list',
          hint: "The contact list's scope: either local or global.",
          toggle_field: {
            name: 'scope',
            label: 'Scope',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "The contact list's scope: either local or global."
          } },
        { name: 'count', sticky: true,
          hint: 'The number of contacts in the contact list.' },
        { name: 'membershipAdditions', type: 'array', of: 'object',
          item_label: 'Membershipadditions',
          add_item_label: 'Add membershipAdditions',
          empty_list_title: 'Membershipadditions list is empty',
          properties: [
            { name: 'value' }
          ] },
        { name: 'membershipDeletions', type: 'array', of: 'object',
          item_label: 'Membershipdeletions',
          add_item_label: 'Add membershipDeletions',
          empty_list_title: 'Membershipdeletions list is empty',
          properties: [
            { name: 'value' }
          ] },
        { name: 'dataLookupId', hint: "The contact list's data lookup Id." }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'createdAt', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'code', 'depth',
                         'permissions')
      else
        fields
      end
    end,

    external_activity_schema: lambda do |schema|
      fields = [
        { name: 'type', label: 'External activity type',
          sticky: true, hint: "The asset's type in Eloqua." },
        { name: 'id', label: 'External activity ID',
          sticky: true, hint: 'Id of the external activity.' },
        { name: 'currentStatus',
          hint: "The external activity's current status." },
        { name: 'name', sticky: true,
          hint: 'The name of the external activity.' },
        { name: 'description', sticky: true,
          hint: 'The description of the external activity.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [
            { name: 'value' }
          ] },
        { name: 'folderId',
          hint: 'The folder id of the folder which contains the ' \
                'external activity.' },
        { name: 'sourceTemplateId', sticky: true,
          hint: 'Id of the template used to create the external activity.' },
        { name: 'createdBy', sticky: true,
          hint: 'The login id of the user who created the ' \
                'external activity.' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the external activity was created, ' \
                'expressed in Unix time.' },
        { name: 'updatedBy',
          hint: 'The login id of the user that last updated the ' \
                'external activity.' },
        { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Unix timestamp for the date and time the external ' \
                'activity was last updated.' },
        { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the external activity was last ' \
                'accessed, expressed in Unix time.' },
        { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date the external activity is scheduled.' },
        { name: 'depth', sticky: true,
          type: 'string', control_type: 'select',
          default: 'complete',
          pick_list: 'depth', toggle_hint: 'Select from list',
          hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                'retrieve entities at three different levels of depth: ' \
                'minimal, partial, and complete. ',
          toggle_field: {
            name: 'depth',
            label: 'Depth',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            default: 'complete',
            toggle_hint: 'Use custom value',
            hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                  'retrieve entities at three different levels of depth: ' \
                  'minimal, partial, and complete. '
          } },
        { name: 'campaignId', sticky: true,
          type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Id of the associated campaign. ' \
                'This value must correspond to a valid campaign.' },
        { name: 'assetName', sticky: true,
          hint: 'The name of the associated asset.' },
        { name: 'assetType', sticky: true,
          hint: 'The type of the associated asset.' },
        { name: 'activityType', sticky: true,
          hint: "The activity's type." },
        { name: 'activityDate', sticky: true,
          type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date the external activity was performed by the ' \
                'associated contact.' },
        { name: 'contactId', sticky: true,
          type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The id of the contact who performed the activity. ' \
                'This value must correspond to a valid contact.' },
        { name: 'fieldValues', type: 'array', of: 'object',
          item_label: 'Fieldvalues',
          add_item_label: 'Add fieldValues',
          empty_list_title: 'Fieldvalues list is empty',
          properties: [
            { name: 'value' }
          ] }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'folderId', 'createdAt', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'scheduledFor', 'depth',
                         'permissions')
      else
        fields
      end
    end,

    contact_field_schema: lambda do |schema|
      fields = [
        { name: 'type', label: 'Contact field type', sticky: true,
          hint: "The asset's type in Eloqua." },
        { name: 'id', label: 'Contact field ID', sticky: true,
          hint: 'Id of the contact field.' },
        { name: 'currentStatus', sticky: true,
          hint: "The email footer's current status." },
        { name: 'name', sticky: true,
          hint: 'The name of the contact field.' },
        { name: 'description', sticky: true,
          hint: 'The description of the contact field.' },
        { name: 'permissions', sticky: true,
          hint: 'The permissions for the contact field granted to your ' \
                'current instance.' },
        { name: 'createdBy',
          hint: 'The login id of the user who created the contact field.' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the contact field was created, ' \
                'expressed in Unix time.' },
        { name: 'updatedBy',
          hint: 'The login id of the user that last updated the ' \
                'contact field.' },
        { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Unix timestamp for the date and time the contact ' \
                'field was last updated.' },
        { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the contact field was last accessed, ' \
                'expressed in Unix time.' },
        { name: 'depth', sticky: true,
          type: 'string', control_type: 'select',
          default: 'complete',
          pick_list: 'depth', toggle_hint: 'Select from list',
          hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                'retrieve entities at three different levels of depth: ' \
                'minimal, partial, and complete. ',
          toggle_field: {
            name: 'depth',
            label: 'Depth',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            default: 'complete',
            toggle_hint: 'Use custom value',
            hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                  'retrieve entities at three different levels of depth: ' \
                  'minimal, partial, and complete. '
          } },
        { name: 'internalName', sticky: true,
          hint: "The contact field's internal name." },
        { name: 'optionListId',
          hint: 'The id of the associated option list.' },
        { name: 'checkedValue', sticky: true,
          hint: 'The checked value.' },
        { name: 'uncheckedValue',
          hint: 'The unchecked value of a checkbox custom object field.' },
        { name: 'displayType', optional: false,
          hint: "The contact field's display type." },
        { name: 'dataType', optional: false,
          hint: "The contact field's data type." },
        { name: 'defaultValue',
          hint: "The contact field's default value." },
        { name: 'isReadOnly',
          hint: 'Whether or not the contact field is read only.' },
        { name: 'isRequired',
          hint: 'Whether or not the contact field is required.' },
        { name: 'isStandard',
          hint: 'Whether or not the contact field is standard.' },
        { name: 'outputFormatId',
          hint: 'The id of the output format.' },
        { name: 'isPopulatedInOutlookPlugin',
          hint: 'Whether or not the contact field is populated in the ' \
                'Oracle Eloqua Outlook plugin.' },
        { name: 'updateType', optional: false,
          hint: 'Denotes under what circumstances the contact ' \
                'field is updated.' },
        { name: 'showTrustedVisitorsOnly',
          hint: 'Whether or not a contact field is displayed only ' \
                'to trusted visitors.' }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'createdAt', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'depth', 'permissions')
      else
        fields
      end
    end,

    contact_activity_schema: lambda do |_schema|
      [
        { name: 'type', label: 'Contact activity type',
          hint: "The asset's type in Eloqua." },
        { name: 'id', label: 'Contact activity ID',
          hint: 'Id of the activity.' },
        { name: 'contact',
          hint: 'Id of the contact whose activity is being returned expressed' \
                ' in 10 digit integer Unix time.' },
        { name: 'activityType', hint: "The activity's type." },
        { name: 'activityDate',
          hint: 'The date the activity was performed expressed in 10 digit ' \
                'integer Unix time.' },
        { name: 'asset', hint: 'Id of the associated asset.' },
        { name: 'assetType', hint: 'Type of the associated asset.' },
        { name: 'details', type: 'array', of: 'object',
          item_label: 'Details',
          add_item_label: 'Add details',
          empty_list_title: 'Details list is empty',
          properties: [
            { name: 'value' }
          ] }
      ]
    end,

    external_asset_schema: lambda do |schema|
      fields = [
        { name: 'type', label: 'External asset type', sticky: true,
          hint: "The asset's type in Eloqua." },
        { name: 'id', label: 'External asset ID', sticky: true,
          hint: 'Id of the external asset.' },
        { name: 'currentStatus', sticky: true,
          hint: "The external asset's current status." },
        { name: 'description',
          hint: 'The description of the external asset.' },
        { name: 'permissions', type: 'array', of: 'object',
          item_label: 'Permissions',
          add_item_label: 'Add permissions',
          empty_list_title: 'Permissions list is empty',
          properties: [{ name: 'value' }] },
        { name: 'folderId',
          hint: 'The folder id of the folder which contains the ' \
                'external asset.' },
        { name: 'sourceTemplateId',
          hint: 'Id of the template used to create the external asset.' },
        { name: 'createdBy',
          hint: 'The login id of the user who created the external asset.' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the external asset was created, ' \
                'expressed in Unix time.' },
        { name: 'updatedBy',
          hint: 'The login id of the user that last updated ' \
                'the external asset.' },
        { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Unix timestamp for the date and time the external ' \
                'asset was last updated.' },
        { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date and time the external asset was last accessed, ' \
                'expressed in Unix time.' },
        { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'The date the external asset is scheduled.' },
        { name: 'depth', sticky: true,
          type: 'string', control_type: 'select',
          default: 'complete',
          pick_list: 'depth', toggle_hint: 'Select from list',
          hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                'retrieve entities at three different levels of depth: ' \
                'minimal, partial, and complete. ',
          toggle_field: {
            name: 'depth',
            label: 'Depth',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            default: 'complete',
            toggle_hint: 'Use custom value',
            hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                  'retrieve entities at three different levels of depth: ' \
                  'minimal, partial, and complete. '
          } },
        { name: 'externalAssetTypeId', sticky: 'true',
          hint: 'Id of the external asset type.' },
        { name: 'name',
          hint: 'The name of the external asset.' }
      ]
      if schema == 'input'
        fields&.ignored('id', 'type', 'createdAt', 'folderId', 'createdBy', 'updatedBy',
                         'updatedAt', 'accessedAt', 'scheduledFor', 'depth',
                         'permissions')
      else
        fields
      end
    end,

    email_contectsection_schema: lambda do
      [
        { name: 'type' },
        { name: 'id' },
        { name: 'currentStatus' },
        { name: 'name' },
        { name: 'description' },
        { name: 'permissions', type: 'array', of: 'object',
          properties: [{ name: 'value' }] },
        { name: 'folderId' },
        { name: 'sourceTemplateId' },
        { name: 'createdBy' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'updatedBy' },
        { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'depth' },
        { name: 'contentHtml' },
        { name: 'contentText' },
        { name: 'scope' },
        { name: 'forms', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'id' },
            { name: 'currentStatus' },
            { name: 'name' },
            { name: 'description' },
            { name: 'permissions', type: 'array', of: 'object',
              properties: [{ name: 'value' }] },
            { name: 'folderId' },
            { name: 'sourceTemplateId' },
            { name: 'createdBy' },
            { name: 'createdAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'updatedBy' },
            { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'depth' },
            { name: 'htmlName' },
            { name: 'processingType' },
            { name: 'submitFailedLandingPageId' },
            { name: 'size', type: 'object',
              properties: [
                { name: 'type' },
                { name: 'width' },
                { name: 'height' }
              ] },
            { name: 'html' },
            { name: 'style' },
            { name: 'elements', type: 'array', of: 'object',
              properties: [
                { name: 'type' },
                { name: 'id' },
                { name: 'currentStatus' },
                { name: 'name' },
                { name: 'description' },
                { name: 'permissions', type: 'array', of: 'object',
                  properties: [{ name: 'value' }] },
                { name: 'folderId' },
                { name: 'sourceTemplateId' },
                { name: 'createdBy' },
                { name: 'createdAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'updatedBy' },
                { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'depth' },
                { name: 'instructions' },
                { name: 'style' }
              ] },
            { name: 'processingSteps', type: 'array', of: 'object',
              properties: [
                { name: 'type' },
                { name: 'id' },
                { name: 'currentStatus' },
                { name: 'name' },
                { name: 'permissions', type: 'array', of: 'object',
                  properties: [{ name: 'value' }] },
                { name: 'folderId' },
                { name: 'sourceTemplateId' },
                { name: 'createdBy' },
                { name: 'createdAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'updatedBy' },
                { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'depth' },
                { name: 'execute' },
                { name: 'condition', type: 'array', of: 'object',
                  properties: [
                    { name: 'type' },
                    { name: 'isConditionallyNegated' },
                    { name: 'conditionalFieldCriteria', type: 'array', of: 'object',
                      properties: [
                        { name: 'type' },
                        { name: 'id' },
                        { name: 'currentStatus' },
                        { name: 'name' },
                        { name: 'description' },
                        { name: 'permissions', type: 'array', of: 'object',
                          properties: [{ name: 'value' }] },
                        { name: 'folderId' },
                        { name: 'sourceTemplateId' },
                        { name: 'createdBy' },
                        { name: 'createdAt', type: 'date_time',
                          control_type: 'date_time',
                          parse_output: 'date_time_conversion' },
                        { name: 'updatedBy' },
                        { name: 'updatedAt', type: 'date_time',
                          control_type: 'date_time',
                          parse_output: 'date_time_conversion' },
                        { name: 'accessedAt', type: 'date_time',
                          control_type: 'date_time',
                          parse_output: 'date_time_conversion' },
                        { name: 'scheduledFor', type: 'date_time',
                          control_type: 'date_time',
                          parse_output: 'date_time_conversion' },
                        { name: 'depth' },
                        { name: 'fieldId' },
                        { name: 'condition', type: 'array', of: 'object',
                          properties: [{ name: 'value' }] }
                      ] }
                  ] },
                { name: 'description' },
                { name: 'hasValidationIssue' }
              ] },
            { name: 'defaultKeyFieldMapping', type: 'array', of: 'object',
              properties: [
                { name: 'type' },
                { name: 'id' },
                { name: 'currentStatus' },
                { name: 'name' },
                { name: 'description' },
                { name: 'permissions', type: 'array', of: 'object',
                  properties: [{ name: 'value' }] },
                { name: 'folderId' },
                { name: 'sourceTemplateId' },
                { name: 'createdBy' },
                { name: 'createdAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'updatedBy' },
                { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'depth' },
                { name: 'sourceFormFieldId' },
                { name: 'updateType' },
                { name: 'targetEntityFieldId' }
              ] },
            { name: 'externalIntegrationUrl' },
            { name: 'customCSS' },
            { name: 'isHidden' },
            { name: 'formJson' },
            { name: 'isResponsive' }
          ] },
        { name: 'images', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'id' },
            { name: 'currentStatus' },
            { name: 'name' },
            { name: 'description' },
            { name: 'permissions', type: 'array', of: 'object',
              properties: [{ name: 'value' }] },
            { name: 'folderId' },
            { name: 'sourceTemplateId' },
            { name: 'createdBy' },
            { name: 'createdAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'updatedBy' },
            { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'depth' },
            { name: 'fullImageUrl' },
            { name: 'size', type: 'object',
              properties: [
                { name: 'type' },
                { name: 'width' },
                { name: 'height' }
              ] },
            { name: 'thumbnailUrl' },
            { name: 'source' },
            { name: 'syncDate' }
          ] },
        { name: 'hyperlinks', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'id' },
            { name: 'currentStatus' },
            { name: 'name' },
            { name: 'description' },
            { name: 'permissions', type: 'array', of: 'object',
              properties: [{ name: 'value' }] },
            { name: 'folderId' },
            { name: 'sourceTemplateId' },
            { name: 'createdBy' },
            { name: 'createdAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'updatedBy' },
            { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'depth' },
            { name: 'href' },
            { name: 'hyperlinkType' },
            { name: 'referencedEntityId' }
          ] },
        { name: 'files', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'id' },
            { name: 'currentStatus' },
            { name: 'name' },
            { name: 'description' },
            { name: 'permissions', type: 'array', of: 'object',
              properties: [{ name: 'value' }] },
            { name: 'folderId' },
            { name: 'sourceTemplateId' },
            { name: 'createdBy' },
            { name: 'createdAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'updatedBy' },
            { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'depth' },
            { name: 'fileName' },
            { name: 'link' },
            { name: 'trackedLink' },
            { name: 'redirectLink' }
          ] },
        { name: 'size', type: 'object',
          properties: [
            { name: 'type' },
            { name: 'width' },
            { name: 'height' }
          ] }
      ]
    end,

    email_schema: lambda do |_schema|
      [
        { name: 'type' },
        { name: 'id' },
        { name: 'currentStatus' },
        { name: 'name' },
        { name: 'description' },
        { name: 'permissions', type: 'array', of: 'object',
          properties: [{ name: 'value' }] },
        { name: 'folderId' },
        { name: 'sourceTemplateId' },
        { name: 'createdBy' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'updatedBy' },
        { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'depth', sticky: true,
          type: 'string', control_type: 'select',
          default: 'complete',
          pick_list: 'depth', toggle_hint: 'Select from list',
          hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                'retrieve entities at three different levels of depth: ' \
                'minimal, partial, and complete. ',
          toggle_field: {
            name: 'depth',
            label: 'Depth',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            default: 'complete',
            toggle_hint: 'Use custom value',
            hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                  'retrieve entities at three different levels of depth: ' \
                  'minimal, partial, and complete. '
          } },
        { name: 'subject' },
        { name: 'previewText' },
        { name: 'senderName' },
        { name: 'senderEmail' },
        { name: 'replyToName' },
        { name: 'replyToEmail' },
        { name: 'bounceBackEmail' },
        { name: 'virtualMTAId' },
        { name: 'htmlContent', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'contentSource' }
          ] },
        { name: 'plainText' },
        { name: 'isPlainTextEditable' },
        { name: 'sendPlainTextOnly' },
        { name: 'isTracked' },
        { name: 'isPrivate' },
        { name: 'layout' },
        { name: 'style' },
        { name: 'forms', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'id' },
            { name: 'currentStatus' },
            { name: 'name' },
            { name: 'description' },
            { name: 'permissions', type: 'array', of: 'object',
              properties: [{ name: 'value' }] },
            { name: 'folderId' },
            { name: 'sourceTemplateId' },
            { name: 'createdBy' },
            { name: 'createdAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'updatedBy' },
            { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'depth' },
            { name: 'htmlName' },
            { name: 'processingType' },
            { name: 'submitFailedLandingPageId' },
            { name: 'size', type: 'object',
              properties: [
                { name: 'type' },
                { name: 'width' },
                { name: 'height' }
              ] },
            { name: 'html' },
            { name: 'style' },
            { name: 'elements', type: 'array', of: 'object',
              properties: [
                { name: 'type' },
                { name: 'id' },
                { name: 'currentStatus' },
                { name: 'name' },
                { name: 'description' },
                { name: 'permissions', type: 'array', of: 'object',
                  properties: [{ name: 'value' }] },
                { name: 'folderId' },
                { name: 'sourceTemplateId' },
                { name: 'createdBy' },
                { name: 'createdAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'updatedBy' },
                { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'depth' },
                { name: 'instructions' },
                { name: 'style' }
              ] },
            { name: 'processingSteps', type: 'array', of: 'object',
              properties: [
                { name: 'type' },
                { name: 'id' },
                { name: 'currentStatus' },
                { name: 'name' },
                { name: 'permissions', type: 'array', of: 'object',
                  properties: [{ name: 'value' }] },
                { name: 'folderId' },
                { name: 'sourceTemplateId' },
                { name: 'createdBy' },
                { name: 'createdAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'updatedBy' },
                { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'depth' },
                { name: 'execute' },
                { name: 'condition', type: 'array', of: 'object',
                  properties: [
                    { name: 'type' },
                    { name: 'isConditionallyNegated' },
                    { name: 'conditionalFieldCriteria', type: 'array', of: 'object',
                      properties: [
                        { name: 'type' },
                        { name: 'id' },
                        { name: 'currentStatus' },
                        { name: 'name' },
                        { name: 'description' },
                        { name: 'permissions', type: 'array', of: 'object',
                          properties: [{ name: 'value' }] },
                        { name: 'folderId' },
                        { name: 'sourceTemplateId' },
                        { name: 'createdBy' },
                        { name: 'createdAt', type: 'date_time',
                          control_type: 'date_time',
                          parse_output: 'date_time_conversion' },
                        { name: 'updatedBy' },
                        { name: 'updatedAt', type: 'date_time',
                          control_type: 'date_time',
                          parse_output: 'date_time_conversion' },
                        { name: 'accessedAt', type: 'date_time',
                          control_type: 'date_time',
                          parse_output: 'date_time_conversion' },
                        { name: 'scheduledFor', type: 'date_time',
                          control_type: 'date_time',
                          parse_output: 'date_time_conversion' },
                        { name: 'depth' },
                        { name: 'fieldId' },
                        { name: 'condition', type: 'array', of: 'object',
                          properties: [{ name: 'value' }] }
                      ] }
                  ] },
                { name: 'description' },
                { name: 'hasValidationIssue' }
              ] },
            { name: 'defaultKeyFieldMapping', type: 'array', of: 'object',
              properties: [
                { name: 'type' },
                { name: 'id' },
                { name: 'currentStatus' },
                { name: 'name' },
                { name: 'description' },
                { name: 'permissions', type: 'array', of: 'object',
                  properties: [{ name: 'value' }] },
                { name: 'folderId' },
                { name: 'sourceTemplateId' },
                { name: 'createdBy' },
                { name: 'createdAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'updatedBy' },
                { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'depth' },
                { name: 'sourceFormFieldId' },
                { name: 'updateType' },
                { name: 'targetEntityFieldId' }
              ] },
            { name: 'externalIntegrationUrl' },
            { name: 'customCSS' },
            { name: 'isHidden' },
            { name: 'formJson' },
            { name: 'isResponsive' }
          ] },
        { name: 'images', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'id' },
            { name: 'currentStatus' },
            { name: 'name' },
            { name: 'description' },
            { name: 'permissions', type: 'array', of: 'object',
              properties: [{ name: 'value' }] },
            { name: 'folderId' },
            { name: 'sourceTemplateId' },
            { name: 'createdBy' },
            { name: 'createdAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'updatedBy' },
            { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'depth' },
            { name: 'fullImageUrl' },
            { name: 'size', type: 'object',
              properties: [
                { name: 'type' },
                { name: 'width' },
                { name: 'height' }
              ] },
            { name: 'thumbnailUrl' },
            { name: 'source' },
            { name: 'syncDate' }
          ] },
        { name: 'hyperlinks', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'id' },
            { name: 'currentStatus' },
            { name: 'name' },
            { name: 'description' },
            { name: 'permissions', type: 'array', of: 'object',
              properties: [{ name: 'value' }] },
            { name: 'folderId' },
            { name: 'sourceTemplateId' },
            { name: 'createdBy' },
            { name: 'createdAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'updatedBy' },
            { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'depth' },
            { name: 'href' },
            { name: 'hyperlinkType' },
            { name: 'referencedEntityId' }
          ] },
        { name: 'contentSections', type: 'array', of: 'object',
          properties: call('email_contectsection_schema') },
        { name: 'dynamicContents', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'id' },
            { name: 'currentStatus' },
            { name: 'name' },
            { name: 'description' },
            { name: 'permissions', type: 'array', of: 'object',
              properties: [{ name: 'value' }] },
            { name: 'folderId' },
            { name: 'sourceTemplateId' },
            { name: 'createdBy' },
            { name: 'createdAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'updatedBy' },
            { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'depth' },
            { name: 'defaultContentSection', type: 'object',
              properties: call('email_contectsection_schema') },
            { name: 'rules', type: 'array', of: 'object',
              properties: [
                { name: 'type' },
                { name: 'currentStatus' },
                { name: 'id' },
                { name: 'depth' },
                { name: 'contentSection', type: 'array', of: 'object', properties: [] },
                { name: 'criteria', type: 'array', of: 'object',
                  properties: [
                    { name: 'type' },
                    { name: 'id' },
                    { name: 'currentStatus' },
                    { name: 'name' },
                    { name: 'description' },
                    { name: 'permissions', type: 'array', of: 'object',
                      properties: [{ name: 'value' }] },
                    { name: 'folderId' },
                    { name: 'sourceTemplateId' },
                    { name: 'createdBy' },
                    { name: 'createdAt', type: 'date_time', control_type: 'date_time',
                      parse_output: 'date_time_conversion' },
                    { name: 'updatedBy' },
                    { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
                      parse_output: 'date_time_conversion' },
                    { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
                      parse_output: 'date_time_conversion' },
                    { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
                      parse_output: 'date_time_conversion' },
                    { name: 'depth' }
                  ] },
                { name: 'statement' },
                { name: 'name' }
              ] },
            { name: 'isContentPublic', type: 'boolean', control_type: 'checkbox',
              parse_output: 'boolean_conversion' }
          ] },
        { name: 'files', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'id' },
            { name: 'currentStatus' },
            { name: 'name' },
            { name: 'description' },
            { name: 'permissions', type: 'array', of: 'object',
              properties: [{ name: 'value' }] },
            { name: 'folderId' },
            { name: 'sourceTemplateId' },
            { name: 'createdBy' },
            { name: 'createdAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'updatedBy' },
            { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'depth' },
            { name: 'fileName' },
            { name: 'link' },
            { name: 'trackedLink' },
            { name: 'redirectLink' }
          ] },
        { name: 'contentServiceInstances', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'id' },
            { name: 'componentId' },
            { name: 'configurationUrl' },
            { name: 'configurationUrlModalSize' },
            { name: 'editorImageUrl' },
            { name: 'height' },
            { name: 'width' },
            { name: 'enabledConfigStatus' },
            { name: 'appStatus' },
            { name: 'requiresConfiguration' }
          ] },
        { name: 'emailHeaderId' },
        { name: 'emailFooterId' },
        { name: 'emailGroupId' },
        { name: 'encodingId' },
        { name: 'fieldMerges', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'id' },
            { name: 'currentStatus' },
            { name: 'name' },
            { name: 'description' },
            { name: 'permissions', type: 'array', of: 'object',
              properties: [{ name: 'value' }] },
            { name: 'folderId' },
            { name: 'sourceTemplateId' },
            { name: 'createdBy' },
            { name: 'createdAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'updatedBy' },
            { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'depth' },
            { name: 'syntax' },
            { name: 'defaultValue' },
            { name: 'contactFieldId' },
            { name: 'accountFieldId' },
            { name: 'eventId' },
            { name: 'eventFieldId' },
            { name: 'eventSessionFieldId' },
            { name: 'customObjectId' },
            { name: 'customObjectFieldId' },
            { name: 'mergeType' },
            { name: 'customObjectSort' },
            { name: 'queryStringKey' },
            { name: 'fieldConditions', type: 'array', of: 'object',
              properties: [
                { name: 'type' },
                { name: 'id' },
                { name: 'currentStatus' },
                { name: 'name' },
                { name: 'description' },
                { name: 'permissions', type: 'array', of: 'object',
                  properties: [{ name: 'value' }] },
                { name: 'folderId' },
                { name: 'sourceTemplateId' },
                { name: 'createdBy' },
                { name: 'createdAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'updatedBy' },
                { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'depth' },
                { name: 'fieldId' },
                { name: 'condition', type: 'array', of: 'object',
                  properties: [{ name: 'value' }] }
              ] },
            { name: 'allowUrlsInValue' }
          ] },
        { name: 'attachments', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'id' },
            { name: 'currentStatus' },
            { name: 'name' },
            { name: 'description' },
            { name: 'permissions', type: 'array', of: 'object',
              properties: [{ name: 'value' }] },
            { name: 'folderId' },
            { name: 'sourceTemplateId' },
            { name: 'createdBy' },
            { name: 'createdAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'updatedBy' },
            { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'depth' },
            { name: 'fileName' },
            { name: 'link' },
            { name: 'trackedLink' },
            { name: 'redirectLink' }
          ] },
        { name: 'isContentProtected' },
        { name: 'renderMode', sticky: true,
          type: 'string', control_type: 'select',
          pick_list: 'render_mode', toggle_hint: 'Select from list',
          hint: 'The layout of the email when it is sent or previewed.',
          toggle_field: {
            name: 'renderMode',
            label: 'Render mode',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            default: 'complete',
            toggle_hint: 'Use custom value',
            hint: 'The layout of the email when it is sent or previewed.' \
                  "Allowed values are 'fixed' or 'flow'."
          } },
        { name: 'archive' }
      ]
    end,

    search_sample_output: lambda do |input|
      get(call('search_url', input), limit: 1)
    end,

    customobject_input: lambda do |input|
      input['fields']&.map do |items|
        if items['dataType'] == 'date'
          { name: "c_#{items['id']}", label: items['name'],
            type: 'date_time', render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' }
        elsif items['dataType'] == 'integer'
          { name: "c_#{items['id']}", label: items['name'],
            type: 'integer', render_input: 'integer_conversion',
            parse_output: 'integer_conversion' }
        else
          { name: "c_#{items['id']}", label: items['name'] }
        end
      end
    end,

    customobject_output_parser: lambda do |input|
      input['fieldValues'] = input['fieldValues']&.
                             each_with_object({}) do |items, hash|
                               hash["c_#{items['id']}"] = items['value']
                             end
      input
    end,

    customobject_output: lambda do |input|
      [
        { name: 'type' },
        { name: 'id' },
        { name: 'currentStatus' },
        { name: 'name' },
        { name: 'description' },
        { name: 'permissions', type: 'array', of: 'object',
          properties: [
            { name: 'value' }
          ] },
        { name: 'folderId' },
        { name: 'sourceTemplateId' },
        { name: 'createdBy' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'updatedBy' },
        { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'accessedAt', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'scheduledFor', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'depth' },
        { name: 'contactId' },
        { name: 'accountId' },
        { name: 'uniqueCode' },
        { name: 'customObjectRecordStatus' },
        { name: 'fieldValues', type: 'array', of: 'object',
          properties: call('customobject_input', input) },
        { name: 'isMapped' }
      ]
    end,

    get_input: lambda do |_input|
      [
        { name: 'id', optional: false, type: 'integer',
          control_type: 'integer', label: 'ID' },
        { name: 'depth', sticky: true,
          type: 'string', control_type: 'select',
          default: 'complete',
          pick_list: 'depth', toggle_hint: 'Select from list',
          hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                'retrieve entities at three different levels of depth: ' \
                'minimal, partial, and complete. ',
          toggle_field: {
            name: 'depth',
            label: 'Depth',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            default: 'complete',
            toggle_hint: 'Use custom value',
            hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                  'retrieve entities at three different levels of depth: ' \
                  'minimal, partial, and complete. '
          } }
      ]
    end,

    search_input: lambda do
      [
        { name: 'search', sticky: true, label: 'Search criteria',
          hint: 'Specify the search criteria used to retrieve entities. See the <a href=' \
          "'https://docs.oracle.com/cloud/latest/marketingcs_gs/OMCAB/index.html#" \
          "CSHID=SearchParam' target='_blank'>tutorial</a> for information about using" \
          ' this parameter.' },
        { name: 'depth', sticky: true,
          type: 'string', control_type: 'select',
          default: 'complete',
          pick_list: 'depth', toggle_hint: 'Select from list',
          hint: 'Level of details returned by the request. Eloqua APIs can ' \
                'retrieve entities at three different levels of depth: ' \
                'minimal, partial, and complete. ',
          toggle_field: {
            name: 'depth',
            label: 'Depth',
            optional: true,
            type: 'string',
            control_type: 'text',
            default: 'complete',
            toggle_hint: 'Use custom value',
            hint: 'Level of detail returned by the request. Eloqua APIs can ' \
                  'retrieve entities at three different levels of depth: ' \
                  'minimal, partial, and complete. '
          } },
        { name: 'orderBy', sticky: true,
          hint: 'Specifies the field by which list results are ordered. e.g. CreatedAt' },
        { name: 'count', sticky: true, type: 'integer',
          hint: 'Maximum number of entities to return. Must be less than or equal' \
          ' to 1000 and greater than or equal to 1.' },
        { name: 'page', sticky: true, type: 'integer',
          hint: 'Specify which page of custom object data assets to return ' \
          '(the count parameter defines the number of custom object data assets' \
          ' per page). If the page parameter is not supplied, 1 will be used by' \
          ' default.' }
      ]
    end,

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

    format_schema: lambda do |input|
      input&.map do |field|
        if (props = field[:properties])
          field[:properties] = call('format_schema', props)
        elsif (props = field['properties'])
          field['properties'] = call('format_schema', props)
        end
        if (name = field[:name])
          field[:label] = field[:label].presence || name.labelize
          field[:name] = name.
                           gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        elsif (name = field['name'])
          field['label'] = field['label'].presence || name.labelize
          field['name'] = name.
                            gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        end

        field
      end
    end,

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
          value = call('format_payload', value) if value.is_a?(Array) || value.is_a?(Hash)
          hash[key] = value
        end
      end
    end,

    format_response: lambda do |response|
      response = response&.compact unless response.is_a?(String) || response
      if response.is_a?(Array)
        response.map do |array_value|
          call('format_response', array_value)
        end
      elsif response.is_a?(Hash)
        response.each_with_object({}) do |(key, value), hash|
          key = key.gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
          value = call('format_response', value) if value.is_a?(Array) || value.is_a?(Hash)
          hash[key] = value
        end
      else
        response
      end
    end

  }
}
