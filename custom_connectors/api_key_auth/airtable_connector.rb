{
  title: 'Airtable',

  methods: {
    format_api_input_field_names: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call('format_api_input_field_names', array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call('format_api_input_field_names', value)
          key = key.gsub(/__\w+__/) do |string|
            string.gsub(/__/, '').decode_hex.as_utf8
          end
          { key => value }
        end.inject(:merge)
      else
        input
      end
    end,

    format_api_output_field_names: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call('format_api_output_field_names',  array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call('format_api_output_field_names', value)
          key = key.gsub(/\W/) { |string| "__#{string.encode_hex}__" }
          { key => value }
        end.inject(:merge)
      else
        input
      end
    end,

    format_schema_field_names: lambda do |input|
      input.map do |field|
        if field[:properties].present?
          field[:properties] = call('format_schema_field_names',
                                    field[:properties])
        elsif field['properties'].present?
          field['properties'] = call('format_schema_field_names',
                                     field['properties'])
        end
        if field[:name].present?
          field[:name] = field[:name]
                         .gsub(/\W/) { |string| "__#{string.encode_hex}__" }
        elsif field['name'].present?
          field['name'] = field['name']
                          .gsub(/\W/) { |string| "__#{string.encode_hex}__" }
        end
        field
      end
    end,

    build_object_definition: lambda do |input|
      type_map = {
        'singleLineText' => 'string',
        'email' => 'string',
        'url' => 'string',
        'multilineText' => 'string',
        'number' => 'number',
        'currency' => 'string',
        'singleSelect' => 'string',
        'multipleSelects' => 'string',
        'singleCollaborator' => 'string',
        'multipleCollaborators' => 'string',
        'multipleRecordLinks' => 'string',
        'date' => 'date',
        'dateTime' => 'timestamp',
        'phoneNumber' => 'string',
        'multipleAttachments' => 'string',
        'checkbox' => 'boolean',
        'barcode' => 'string',
        'formula' => 'string',
        'rollup' => 'string',
        'count' => 'integer',
        'lookup' => 'string',
        'autoNumber' => 'integer'
      }
      control_type_map = type_map = {
        'singleLineText' => 'text',
        'email' => 'email',
        'url' => 'string',
        'multilineText' => 'text-area',
        'number' => 'number',
        'currency' => 'text',
        'singleSelect' => 'text',
        'multipleSelects' => 'text',
        'singleCollaborator' => 'text',
        'multipleCollaborators' => 'text',
        'multipleRecordLinks' => 'text',
        'date' => 'date',
        'dateTime' => 'date_time',
        'phoneNumber' => 'phone',
        'multipleAttachments' => 'text',
        'checkbox' => 'checkbox',
        'barcode' => 'text',
        'formula' => 'text',
        'rollup' => 'text',
        'count' => 'integer',
        'lookup' => 'text',
        'autoNumber' => 'integer'
      }
      type_conversion_map = {
        'string' => nil,
        'boolean' => 'boolean_conversion',
        'integer' => 'integer_conversion',
        'number' => 'float_conversion',
        'date' => 'date_conversion',
        'timestamp' => 'date_time_conversion'
      }

      input&.map do |field|
        {
          name: (name = field['name']),
          label: name,
          sticky: ((lowercase_name = name.downcase).include? 'id') ||
            (lowercase_name.include? 'name'),
          type: (type = type_map[field['type']]),
          control_type: control_type_map[type],
          render_input: (conversion = type_conversion_map[type]),
          parse_output: conversion
        }.compact
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
    end
  },

  connection: {
    fields: [{
      name: 'api_key',
      hint: "You can find the API Key on the <a target='_blank' " \
          "href='https://airtable.com/account'>account</a> page",
      control_type: 'password',
      optional: false
    }],

    base_uri: ->(_connection) { 'https://api.airtable.com' },

    authorization: {
      type: 'api_key',

      apply: lambda { |connection|
        headers('Authorization' => "Bearer #{connection['api_key']}")
      }
    }
  },

  test: ->(_connection) { get('/v0/meta/bases') },

  object_definitions: {
    custom_action_input: {
      fields: lambda do |_connection, config_fields|
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')

        [
          {
            name: 'path',
            optional: false,
            hint: 'Base URI is <b>https://api.airtable.com</b> - ' \
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

    record: {
      fields: lambda do |_connection, config_fields|
        schema = get("v0/meta/bases/#{config_fields['base_id']}/tables")
                 .[]('tables')
        fields = schema.where('id' => config_fields['table_id'])
                       .dig(0, 'fields')

        all_fields = [
          { name: 'id' },
          {
            name: 'fields',
            type: 'object',
            properties: call('build_object_definition', fields)
          },
          { name: 'createdTime', type: 'timestamp' }
        ]

        call('format_schema_field_names', all_fields)
      end
    },

    search_record: {
      fields: lambda do |_connection, config_fields|
        schema = get("v0/meta/bases/#{config_fields['base_id']}/tables")
                 .[]('tables')
        fields = schema.where('id' => config_fields['table_id'])
                       .dig(0, 'fields')

        call('format_schema_field_names',
             call('build_object_definition', fields))
      end
    }
  },

  actions: {
    # Custom action for Airtable
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
        "in <span class='provider'>Airtable</span>",

      help: {
        body: 'Build your own Airtable action with a HTTP request. The ' \
          'request will be authorized with your Airtable connection.',
        learn_more_url: 'https://airtable.com/api',
        learn_more_text: 'Airtable API Documentation'
      },

      execute: lambda do |_connection, input|
        verb = input['verb']
        if %w[get post put patch delete].exclude?(verb)
          error("#{verb} not supported")
        end
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

    search_records: {
      description: "Search <span class='provider'>records</span> in " \
        "<span class='provider'>Airtable</span>",
      help: 'The search will return results (max 50), that match all your ' \
        'search criteria',

      execute: lambda do |_connection, input|
        base_id = input.delete('base_id')
        table_id = input.delete('table_id')
        max_records = 50
        input = call('format_api_input_field_names', input)
        criterias = input&.map do |key, value|
          if key[/\W/]
            "{#{key}}='#{value}'"
          else
            "#{key}='#{value}'"
          end
        end&.join(', ')

        params = if criterias.present?
                   {
                     'filterByFormula' => "AND(#{criterias})",
                     'maxRecords' => max_records
                   }
                 else
                   { 'maxRecords' => max_records }
                 end

        call('format_api_output_field_names',
             get("/v0/#{base_id}/#{table_id}/", params).compact)
      end,

      config_fields: [
        {
          name: 'base_id',
          label: 'Base',
          optional: false,
          control_type: 'select',
          pick_list: 'bases',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'base_id',
            label: 'Base ID',
            toggle_hint: 'Use custom value',
            control_type: 'text',
            type: 'string'
          }
        },
        {
          name: 'table_id',
          label: 'Table',
          optional: false,
          control_type: 'select',
          pick_list: 'tables',
          pick_list_params: { base_id: 'base_id' },
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'table_id',
            label: 'Table ID',
            toggle_hint: 'Use custom value',
            control_type: 'text',
            type: 'string'
          }
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['search_record']
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'records',
          type: 'array',
          of: 'object',
          properties: object_definitions['record']
        }]
      end,

      sample_output: lambda do |_connection, input|
        call('format_api_output_field_names',
             get("/v0/#{input['base_id']}/#{input['table_id']}/",
                 'maxRecords' => 1).compact)
      end
    }
  },

  triggers: {
    new_record: {
      description: "New <span class='provider'>record" \
        "</span> in <span class='provider'>Airtable</span>",

      config_fields: [
        {
          name: 'base_id',
          label: 'Base',
          optional: false,
          control_type: 'select',
          pick_list: 'bases',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'base_id',
            label: 'Base ID',
            toggle_hint: 'Use custom value',
            control_type: 'text',
            type: 'string'
          }
        },
        {
          name: 'table_id',
          label: 'Table',
          optional: false,
          control_type: 'select',
          pick_list: 'tables',
          pick_list_params: { base_id: 'base_id' },
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'table_id',
            label: 'Table ID',
            toggle_hint: 'Use custom value',
            control_type: 'text',
            type: 'string'
          }
        }
      ],

      input_fields: lambda do |_connection|
        [{
          name: 'since',
          label: 'From',
          type: 'timestamp',
          optional: true,
          sticky: true,
          hint: 'Get records created since given date/time. ' \
            'Leave empty to get records created one hour ago'
        }]
      end,

      poll: lambda do |_connection, input, closure|
        page_size = 100
        offset = closure&.[]('offset') || 0
        created_since = (closure&.[]('since') || input['since'] || 1.hour.ago)
                        .to_time.utc.iso8601
        params = {
          'filterByFormula' => "CREATED_TIME() >= '#{created_since}'",
          'offset' => offset,
          'pageSize' => page_size
        }.compact
        response = call('format_api_output_field_names',
                        get("/v0/#{input['base_id']}/#{input['table_id']}/",
                            params).compact) || {}
        closure = if (more_pages = response['offset'].present?)
                    { 'since' => created_since, 'offset' => response['offset'] }
                  else
                    { 'since' => now, 'offset' => nil }
                  end

        {
          events: response['records'],
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: ->(record) { record['id'].to_s },

      output_fields: ->(object_definitions) { object_definitions['record'] },

      sample_output: lambda do |_connection, input|
        call('format_api_output_field_names',
             get("/v0/#{input['base_id']}/#{input['table_id']}/",
                 'maxRecords' => 1).compact).dig('records', 0)
      end
    }
  },

  pick_lists: {
    bases: lambda do |_connection|
      get('/v0/meta/bases')['bases']&.pluck('name', 'id')
    end,

    tables: lambda do |_connection, base_id:|
      get("/v0/meta/bases/#{base_id}/tables")['tables']&.pluck('name', 'id')
    end
  }
}
