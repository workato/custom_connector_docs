{
  title: 'Rally',

  connection: {
    fields: [
      {
        name: 'api_key',
        hint: "Get your API keys from <a href='https://rally1.rallydev.com/" \
          "login/accounts/index.html#/keys' target='_blank'>here</a>. ",
        control_type: 'password',
        optional: false
      },
      {
        name: 'base_url',
        hint: 'Base URL of Rally instance. e.g. rally1.rallydev.com',
        control_type: 'url',
        optional: false
      }
    ],

    base_uri: ->(connection) { "https://#{connection['base_url']}" },

    authorization: {
      type: 'api_key',

      apply: lambda do |connection|
        headers('zsessionid' => connection['api_key'])
      end
    }
  },

  test: lambda do |_connection|
    get('https://rally1.rallydev.com/slm/webservice/v2.0/user')
  end,

  methods: {
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

    generate_schema: lambda do |input|
      type = {
        'DATE' => 'date',
        'INTEGER' => 'integer',
        'RAW' => 'string',
        'STRING' => 'string',
        'OBJECT' => 'object',
        'BOOLEAN' => 'boolean',
        'COLLECTION' => %w[create update].include?(input['action']) ? 'array' : 'object',
        'TEXT' => 'string',
        'DECIMAL' => 'number',
        'RATING' => 'string',
        'STATE' => 'string',
        'QUANTITY' => 'number',
        'BINARY_DATA' => 'string'
      }

      selected_fields = input['schema'].select { |obj| obj['_refObjectName'] == input['object'] }.
                        first&.[]('Attributes')

      if input['level'] <= 2
        if %w[create update].include? input['action']
          selected_fields = selected_fields.reject do |obj|
            obj['ReadOnly'] || (input['level'] != 1 && %w[COLLECTION OBJECT].include?(obj['AttributeType']))
          end
        end
        selected_fields.map do |field|
          optional = true
          if input['action'] == 'create' && input['level'] == 1
            optional = %w[COLLECTION OBJECT].include?(field['AttributeType']) || !field['Required']
          end

          if field['AllowedValueType'].blank? && field['AllowedValues'].is_a?(Array) && field['AllowedValues'].present?
            {
              name: field['ElementName'],
              label: field['Name'],
              control_type: 'select',
              optional: optional,
              pick_list: field['AllowedValues'].map { |val| [val['StringValue'], val['StringValue']] },
              toggle_hint: 'Select from list',
              toggle_field: {
                name: field['_refObjectName'],
                label: field['Name'],
                type: type[field['AttributeType']],
                control_type: type[field['AttributeType']] == 'string' ? 'text' : type[field['AttributeType']],
                optional: optional,
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: ' \
                  "#{field['AllowedValues'][0..4].map { |val| val['StringValue'] }.join(', ')}"
              }
            }
          elsif type[field['AttributeType']] == 'boolean'
            {
              name: field['ElementName'],
              label: field['Name'],
              type: 'boolean',
              control_type: 'checkbox',
              optional: optional,
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Select from list',
              toggle_field:
                  {
                    name: field['ElementName'],
                    label: field['Name'],
                    type: :boolean,
                    control_type: 'text',
                    optional: optional,
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Use custom value',
                    hint: 'Allowed values are true or false'
                  }
            }
          else
            {
              name: field['ElementName'],
              label: field['Name'],
              type: type[field['AttributeType']],
              control_type: type[field['AttributeType']] == 'string' ? 'text' : type[field['AttributeType']],
              of: ('object' if type[field['AttributeType']] == 'array'),
              optional: optional,
              properties: if %w[COLLECTION OBJECT].include?(field['AttributeType'])
                            [{ name: '_ref', label: "#{field['ElementName']} reference" }]
                          end
            }
          end
        end
      end
    end
  },
  object_definitions: {

    search_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        [{ name: 'query', hint: 'Query string. For e.g. Name contains "Workato"', sticky: true }]
      end
    },

    search_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        [
          {
            name: 'records',
            label: config_fields['object'].pluralize,
            type: 'array', of: 'object',
            properties: [
              {
                name: '_ref', label: "#{config_fields['object']} reference",
                hint: "Reference link of #{config_fields['object']}."
              },
              {
                name: '_refObjectUUID', label: 'UUID',
                hint: "UUID of #{config_fields['object']}"
              },
              {
                name: '_refObjectName', label: 'Name',
                hint: "Name of #{config_fields['object']}"
              },
              {
                name: '_type', label: 'Type',
                hint: 'Object type'
              }
            ]
          }
        ]
      end
    },

    create_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        workspace_id = get('/slm/webservice/v2.0/Workspace').
                       dig('QueryResult', 'Results', 0, '_ref')&.split('/')&.last

        schema = get("/slm/schema/v2.0/workspace/#{workspace_id}").
                 dig('QueryResult', 'Results')

        call('generate_schema',
             'schema' => schema,
             'action' => 'create',
             'object' => config_fields['object'],
             'level' => 1)
      end
    },

    create_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        workspace_id = get('/slm/webservice/v2.0/Workspace').
                       dig('QueryResult', 'Results', 0, '_ref')&.split('/')&.last

        schema = get("/slm/schema/v2.0/workspace/#{workspace_id}").
                 dig('QueryResult', 'Results')

        call('generate_schema',
             'schema' => schema,
             'operation' => 'read',
             'object' => config_fields['object'],
             'level' => 1).concat([{
                                    name: '_ref',
                                    label: "#{config_fields['object']} reference",
                                    optional: false
                                  }])
      end
    },

    update_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        workspace_id = get('/slm/webservice/v2.0/Workspace').
                       dig('QueryResult', 'Results', 0, '_ref')&.split('/')&.last

        schema = get("/slm/schema/v2.0/workspace/#{workspace_id}").
                 dig('QueryResult', 'Results')

        call('generate_schema',
             'schema' => schema,
             'action' => 'update',
             'object' => config_fields['object'],
             'level' => 1).concat([{
                                    name: 'id',
                                    label: "#{config_fields['object']} ID",
                                    optional: false
                                  }])
      end
    },

    update_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        workspace_id = get('/slm/webservice/v2.0/Workspace').
                       dig('QueryResult', 'Results', 0, '_ref')&.split('/')&.last

        schema = get("/slm/schema/v2.0/workspace/#{workspace_id}").
                 dig('QueryResult', 'Results')

        call('generate_schema',
             'schema' => schema,
             'operation' => 'read',
             'object' => config_fields['object'],
             'level' => 1).concat([{
                                    name: '_ref',
                                    label: "#{config_fields['object']} reference",
                                    optional: false
                                  }])
      end
    },

    get_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        [{ name: 'id', label: "#{config_fields['object']} ID", optional: false }]
      end
    },

    get_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        workspace_id = get('/slm/webservice/v2.0/Workspace').
                       dig('QueryResult', 'Results', 0, '_ref')&.split('/')&.last

        schema = get("/slm/schema/v2.0/workspace/#{workspace_id}").
                 dig('QueryResult', 'Results')

        call('generate_schema',
             'schema' => schema,
             'operation' => 'read',
             'object' => config_fields['object'],
             'level' => 1).concat([{
                                    name: '_ref',
                                    label: "#{config_fields['object']} reference",
                                    optional: false
                                  }])
      end
    },

    delete_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        [{ name: 'id', label: "#{config_fields['object']} ID", optional: false }]
      end
    },

    delete_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        [{ name: 'message' }]
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
            "https://#{connection['base_url']}" \
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
    }
  },

  actions: {
    search_object: {
      title: 'Search object',
      subtitle: 'Search object in Rally',
      description: lambda do |_connection, search_object_list|
        "Search <span class='provider'>#{search_object_list[:object]&.downcase&.pluralize || 'objects'}" \
        '</span> in <span class="provider">Rally</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :search_object_list,
          hint: 'Select the object from list.'
        },
        {
          name: 'project',
          label: 'Project',
          control_type: 'tree',
          hint: 'Select project',
          toggle_hint: 'Select Project',
          tree_options: { selectable_folder: true },
          pick_list: :projects,
          optional: false,
          toggle_field: {
            name: 'project',
            optional: false,
            type: 'string',
            control_type: 'text',
            label: 'Project ID',
            toggle_hint: 'Use Project ID',
            hint: 'Use Project ID. e.g. 368960979984'
          }
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['search_object_input']
      end,

      execute: lambda do |connection, input|
        query = input['query'].present? ? "(#{input['query']&.encode_url})" : ''
        response = get("/slm/webservice/v2.0/#{input['object']}?query=#{query}").
                   params(project: "https://#{connection['base_url']}/slm" \
                   "/webservice/v2.0/project/#{input['project']}")&.
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end

        if response.dig('QueryResult', 'Errors').present?
          error(response.dig('QueryResult', 'Errors').to_s)
        else
          { records: response.dig('QueryResult', 'Results') }
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['search_object_output']
      end,

      sample_output: lambda do |_connection, input|
        { records: get("/slm/webservice/v2.0/#{input['object']}").dig('QueryResult', 'Results') }
      end
    },

    create_object: {
      title: 'Create object',
      subtitle: 'Create object in Rally',
      description: lambda do |_connection, create_object_list|
        "Create <span class='provider'>#{create_object_list[:object]&.downcase || 'object'}</span> "\
          'in <span class="provider">Rally</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :create_object_list,
          hint: 'Select the object from list.'
        },
        {
          name: 'project',
          label: 'Project',
          control_type: 'tree',
          hint: 'Select project',
          toggle_hint: 'Select Project',
          tree_options: { selectable_folder: true },
          pick_list: :projects,
          optional: false,
          toggle_field: {
            name: 'project',
            optional: false,
            type: 'string',
            control_type: 'text',
            label: 'Project ID',
            toggle_hint: 'Use Project ID',
            hint: 'Use Project ID. e.g. 368960979984'
          }
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['create_object_input']
      end,

      execute: lambda do |connection, input, _is, _os|
        response = post("/slm/webservice/v2.0/#{input['object']}/create",
                        input.delete('object').to_s => input.except('project')).
                   params(project: "https://#{connection['base_url']}/slm" \
                        "/webservice/v2.0/project/#{input['project']}")&.
                    after_error_response(/.*/) do |_code, body, _header, message|
                      error("#{message}: #{body}")
                    end

        if response.dig('CreateResult', 'Errors').present?
          error(response.dig('CreateResult', 'Errors').to_s)
        else
          response.dig('CreateResult', 'Object')
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['create_object_output']
      end,

      sample_output: lambda do |_connection, input|
        get(get("/slm/webservice/v2.0/#{input['object']}").
            dig('QueryResult', 'Results', 0, '_ref'))&.[](input['object'])
      end
    },

    update_object: {
      title: 'Update object',
      subtitle: 'Update object in Rally',
      description: lambda do |_connection, update_object_list|
        "Update <span class='provider'>#{update_object_list[:object]&.downcase || 'object'}</span> "\
          'in <span class="provider">Rally</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :update_object_list,
          hint: 'Select the object from list.'
        },
        {
          name: 'project',
          label: 'Project',
          control_type: 'tree',
          hint: 'Select project',
          toggle_hint: 'Select Project',
          tree_options: { selectable_folder: true },
          pick_list: :projects,
          optional: false,
          toggle_field: {
            name: 'project',
            optional: false,
            type: 'string',
            control_type: 'text',
            label: 'Project ID',
            toggle_hint: 'Use Project ID',
            hint: 'Use Project ID. e.g. 368960979984'
          }
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['update_object_input']
      end,

      execute: lambda do |connection, input|
        response = post("/slm/webservice/v2.0/#{input['object']}/#{input.delete('id')}",
                        input.delete('object').to_s => input.except('project')).
                   params(project: "https://#{connection['base_url']}/slm" \
                        "/webservice/v2.0/project/#{input['project']}")&.
                    after_error_response(/.*/) do |_code, body, _header, message|
                      error("#{message}: #{body}")
                    end

        if response.dig('OperationResult', 'Errors').present?
          error(response.dig('OperationResult', 'Errors').to_s)
        else
          response.dig('OperationResult', 'Object')
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['create_object_output']
      end,

      sample_output: lambda do |_connection, input|
        get(get("/slm/webservice/v2.0/#{input['object']}").
            dig('QueryResult', 'Results', 0, '_ref'))&.[](input['object'])
      end
    },

    get_object: {
      title: 'Get object',
      subtitle: 'Get object in Rally',
      description: lambda do |_connection, get_object_list|
        "Get <span class='provider'>#{get_object_list[:object]&.downcase || 'object'}</span> "\
          'in <span class="provider">Rally</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :get_object_list,
          hint: 'Select the object from list.'
        },
        {
          name: 'project',
          label: 'Project',
          control_type: 'tree',
          hint: 'Select project',
          toggle_hint: 'Select Project',
          tree_options: { selectable_folder: true },
          pick_list: :projects,
          optional: false,
          toggle_field: {
            name: 'project',
            optional: false,
            type: 'string',
            control_type: 'text',
            label: 'Project ID',
            toggle_hint: 'Use Project ID',
            hint: 'Use Project ID. e.g. 368960979984'
          }
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['get_object_input']
      end,

      execute: lambda do |_connection, input|
        response = get("/slm/webservice/v2.0/#{input['object']}/#{input['id']}")&.
                    after_error_response(/.*/) do |_code, body, _header, message|
                      error("#{message}: #{body}")
                    end

        if response.dig('OperationResult', 'Errors').present?
          error(response.dig('OperationResult', 'Errors').to_s)
        else
          response.dig(input['object'])
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['get_object_output']
      end,

      sample_output: lambda do |_connection, input|
        get(get("/slm/webservice/v2.0/#{input['object']}").
            dig('QueryResult', 'Results', 0, '_ref'))&.[](input['object'])
      end
    },

    delete_object: {
      title: 'Delete object',
      subtitle: 'Delete object in Rally',
      description: lambda do |_connection, delete_object_list|
        "Delete <span class='provider'>#{delete_object_list[:object]&.downcase || 'object'}</span> "\
          'in <span class="provider">Rally</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :delete_object_list,
          hint: 'Select the object from list.'
        },
        {
          name: 'project',
          label: 'Project',
          control_type: 'tree',
          hint: 'Select project',
          toggle_hint: 'Select Project',
          tree_options: { selectable_folder: true },
          pick_list: :projects,
          optional: false,
          toggle_field: {
            name: 'project',
            optional: false,
            type: 'string',
            control_type: 'text',
            label: 'Project ID',
            toggle_hint: 'Use Project ID',
            hint: 'Use Project ID. e.g. 368960979984'
          }
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['delete_object_input']
      end,

      execute: lambda do |_connection, input|
        response = delete("/slm/webservice/v2.0/#{input['object']}/#{input['id']}")&.
                    after_error_response(/.*/) do |_code, body, _header, message|
                      error("#{message}: #{body}")
                    end

        if response.dig('OperationResult', 'Errors').present?
          error(response.dig('OperationResult', 'Errors').to_s)
        else
          { message: "#{input['object']} deleted sucessfully" }
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['delete_object_output']
      end,

      sample_output: lambda do |_connection, input|
        { message: "#{input['object']} deleted sucessfully" }
      end
    },

    custom_action: {
      subtitle: 'Build your own Rally action with a HTTP request',

      description: lambda do |object_value, _object_label|
        "<span class='provider'>" \
        "#{object_value[:action_name] || 'Custom action'}</span> in " \
        "<span class='provider'>Rally</span>"
      end,

      help: {
        body: 'Build your own Rally action with a HTTP request. ' \
        'The request will be authorized with your Rally connection.',
        learn_more_url: 'https://rally1.rallydev.com/slm/doc/webservice',
        learn_more_text: 'Rally API documentation'
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
          pick_list: %w[get post delete].
            map { |verb| [verb.upcase, verb] }
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
    new_or_updated_object: {
      title: 'New/updated object',
      subtitle: 'Triggers when an object is created or updated.',
      description: lambda do |_connection, trigger_object_list|
        "New or updated <span class='provider'>#{trigger_object_list[:object]&.downcase || 'object'}</span> "\
        ' in <span class="provider">Rally</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :trigger_object_list,
          hint: 'Select the object from list.'
        },
        {
          name: 'project',
          label: 'Project',
          control_type: 'tree',
          hint: 'Select project',
          toggle_hint: 'Select Project',
          tree_options: { selectable_folder: true },
          pick_list: :projects,
          optional: false,
          toggle_field: {
            name: 'project',
            optional: false,
            type: 'string',
            control_type: 'text',
            label: 'Project ID',
            toggle_hint: 'Use Project ID',
            hint: 'Use Project ID. e.g. 368960979984'
          }
        }
      ],

      input_fields: lambda do |_object_definition|
        [{
          name: 'since',
          type: 'timestamp',
          label: 'When first started, this recipe should pick up events from',
          hint: 'When you start recipe for the first time, ' \
          'it picks up trigger events from this specified date and time. ' \
          'Leave empty to get records created or updated one hour ago',
          sticky: true
        }]
      end,

      poll: lambda do |connection, input, closure|
        closure ||= {}
        updated_after = closure&.[]('updated_after') ||
                        (input['since'] || 1.hour.ago).to_time.iso8601
        limit = 50

        response = get("/slm/webservice/v2.0/#{input['object']}",
                       project: "https://#{connection['base_url']}/slm" \
                       "/webservice/v2.0/project/#{input['project']}",
                       order: 'LastUpdateDate asc',
                       pagesize: limit,
                       query: "(LastUpdateDate >= #{updated_after})")&.
                       dig('QueryResult', 'Results')

        records = response.map do |record|
          get(record['_ref'])&.[](response.dig(0, '_type'))
        end&.compact

        has_more = records.present? ? (records.size >= limit) : false
        updated_after = records.last['LastUpdateDate'].to_time.iso8601 if records.present?
        closure = { 'updated_after': updated_after }

        {
          events: records.presence || [],
          next_poll: closure,
          can_poll_more: has_more
        }
      end,

      dedup: lambda do |record|
        "#{record['ObjectID']}@#{record['LastUpdateDate']}"
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['get_object_output']
      end,

      sample_output: lambda do |_connection, input|
        get(get("/slm/webservice/v2.0/#{input['object']}").
            dig('QueryResult', 'Results', 0, '_ref'))&.[](input['object'])
      end
    }
  },

  pick_lists: {
    trigger_object_list: lambda do |_connection|
      [
        %w[Defect Defect],
        %w[User\ Story HierarchicalRequirement],
        %w[Task Task],
        %w[Test\ case TestCase],
        %w[Portfolio\ item PortfolioItem],
        %w[Test\ set TestSet],
        %w[Release Release],
        %w[Iteration Iteration],
        %w[Milestone Milestone],
        %w[Change\ set Changeset],
        %w[Test\ case\ result TestCaseResult]
      ]
    end,

    search_object_list: lambda do |_connection|
      [
        %w[Defect Defect],
        %w[User\ Story HierarchicalRequirement],
        %w[Tag Tag],
        %w[Task Task],
        %w[Test\ case TestCase],
        %w[Portfolio\ item PortfolioItem],
        %w[Test\ set TestSet],
        %w[Release Release],
        %w[Iteration Iteration],
        %w[Milestone Milestone],
        %w[Change\ set Changeset],
        %w[Test\ case\ result TestCaseResult],
        %w[Workspace Workspace],
        %w[Change Change],
        %w[User User],
        %w[Artifact Artifact],
        %w[SCMRepository SCMRepository],
        %w[Revision Revision],
        %w[Attachment Attachment],
        %w[Project Project],
        %w[Release Release],
        %w[Attachment Attachment],
        %w[Requirement Requirement]
      ]
    end,

    create_object_list: lambda do |_connection|
      [
        %w[Defect Defect],
        %w[User\ Story HierarchicalRequirement],
        %w[Tag Tag],
        %w[Task Task],
        %w[Test\ case TestCase],
        %w[Test\ set TestSet],
        %w[Release Release],
        %w[Iteration Iteration],
        %w[Milestone Milestone],
        %w[Change\ set Changeset],
        %w[Test\ case\ result TestCaseResult],
        %w[Change Change],
        %w[SCMRepository SCMRepository],
        %w[Attachment Attachment],
        %w[Attachment\ content AttachmentContent]
      ]
    end,

    update_object_list: lambda do |_connection|
      [
        %w[Defect Defect],
        %w[User\ Story HierarchicalRequirement],
        %w[Tag Tag],
        %w[Task Task],
        %w[Test\ case TestCase],
        %w[Test\ set TestSet],
        %w[Release Release],
        %w[Iteration Iteration],
        %w[Milestone Milestone],
        %w[Change\ set Changeset],
        %w[Attachment Attachment],
        %w[Test\ case\ result TestCaseResult]
      ]
    end,

    get_object_list: lambda do |_connection|
      [
        %w[Defect Defect],
        %w[User\ Story HierarchicalRequirement],
        %w[Tag Tag],
        %w[Task Task],
        %w[Test\ case TestCase],
        %w[Portfolio\ item PortfolioItem],
        %w[Test\ set TestSet],
        %w[Release Release],
        %w[Iteration Iteration],
        %w[Milestone Milestone],
        %w[Change\ set Changeset],
        %w[Test\ case\ result TestCaseResult],
        %w[Workspace Workspace],
        %w[Change Change],
        %w[Attachment Attachment],
        %w[Attachment\ content AttachmentContent]
      ]
    end,

    delete_object_list: lambda do |_connection|
      [
        %w[Defect Defect],
        %w[User\ Story HierarchicalRequirement],
        %w[Task Task],
        %w[Test\ case TestCase],
        %w[Portfolio\ item PortfolioItem],
        %w[Test\ set TestSet],
        %w[Release Release],
        %w[Iteration Iteration],
        %w[Milestone Milestone],
        %w[Change\ set Changeset],
        %w[Test\ case\ result TestCaseResult],
        %w[Attachment Attachment],
        %w[Attachment\ content AttachmentContent]
      ]
    end,

    projects: lambda do |_connection, **args|
      if (parent_id = args&.[](:__parent_id).presence)
        get('/slm/webservice/v2.0/project/' \
            "#{parent_id}/children").
          params('fetch': 'Name,ObjectID,Parent').
          dig('QueryResult', 'Results')&.
          map do |field|
            [field['Name'], field['ObjectID'], field['ObjectID'], true]
          end
      else
        get('/slm/webservice/v2.0/project').
          params('fetch': 'Name,ObjectID,Parent',
                 'query': '(Parent = null)').dig('QueryResult', 'Results')&.
          map do |field|
            [field['Name'], field['ObjectID'], field['ObjectID'], true]
          end
      end
    end
  }
}
