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
          key = key.gsub(/__ws__|__hypn__|__coln__/,
                         '__ws__' => ' ',
                         '__hypn__' => '-',
                         '__coln__' => ':')

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
          key = key.gsub(/\W/,
                         ' ' => '__ws__',
                         '-' => '__hypn__',
                         ':' => '__coln__')
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
        end
        field[:name] = field[:name].
                         gsub(/\W/,
                              ' ' => '__ws__',
                              '-' => '__hypn__',
                              ':' => '__coln__')
        field
      end
    end,

    build_object_definition: lambda do |input|
      input.map do |key, value|
        if value.is_a?(Array)
          properties_part = if value[0].is_a?(Hash)
                              {
                                of: 'object',
                                properties: call('build_object_definition',
                                                 value[0])
                              }
                            else
                              { of: 'string' }
                            end
          { name: key, label: key, type: 'array' }.merge(properties_part)
        elsif value.is_a?(Hash)
          {
            name: key,
            label: key,
            type: 'object',
            properties: call('build_object_definition', value)
          }
        else
          { name: key, label: key }
        end
      end.compact
    end
  },

  connection: {
    fields: [
      {
        name: 'base_id',
        hint: "You can find the base ID on the API page. It begins with 'app'",
        optional: false
      },
      {
        name: 'table_id',
        label: 'Table name or ID',
        hint: 'Provide any table name or table ID. Table name is just used ' \
          'to validate your connection credentials.',
        optional: false
      },
      {
        name: 'api_key',
        hint: "You can find the API Key on the <a target='_blank' " \
          "href='https://airtable.com/account'>account</a> page",
        control_type: 'password',
        optional: false
      }
    ],

    base_uri: ->(_connection) { 'https://api.airtable.com' },

    authorization: {
      type: 'custom',

      apply: lambda { |connection|
        headers('Authorization' => "Bearer #{connection['api_key']}")
      }
    }
  },

  test: lambda { |connection|
    get("/v0/#{connection['base_id']}/#{connection['table_id']}",
        maxRecords: 1)
  },

  object_definitions: {
    record: {
      fields: lambda do |connection, config_fields|
        sample_record_url = config_fields['sample_record_url']
        table_id = sample_record_url.scan(/tbl\w+/)[0] || ''
        record_id = sample_record_url.scan(/rec\w+/)[0] || ''
        sample_record = get("/v0/#{connection['base_id']}" \
          "/#{table_id}/#{record_id}")['fields']
        object_fields = call('build_object_definition', sample_record)
        all_fields = [
          { name: 'id' },
          {
            name: 'fields',
            type: 'object',
            properties: object_fields
          },
          { name: 'createdTime', type: 'timestamp' }
        ]

        call('format_schema_field_names', all_fields.compact)
      end
    },

    search_record: {
      fields: lambda do |connection, config_fields|
        sample_record_url = config_fields['sample_record_url']
        table_id = sample_record_url.scan(/tbl\w+/)[0] || ''
        record_id = sample_record_url.scan(/rec\w+/)[0] || ''
        sample_record = get("/v0/#{connection['base_id']}" \
          "/#{table_id}/#{record_id}")['fields']
        object_fields = call('build_object_definition', sample_record).
                          reject do |field|
                            ['object', 'array'].include? field[:type]
                          end
        all_fields = [
          { name: 'id' },
          {
            name: 'fields',
            label: 'Search criterias',
            sticky: true,
            type: 'object',
            properties: object_fields
          },
          { name: 'createdTime', type: 'timestamp' }
        ]

        call('format_schema_field_names', all_fields.compact)
      end
    }
  },

  actions: {
    search_records: {
      description: "Search <span class='provider'>records</span> in " \
        "<span class='provider'>Airtable</span>",
      help: "Search will return results that match all your search " \
        "criteria (max 50).",

      execute: lambda do |connection, input|
        max_records = 50
        input = call('format_api_input_field_names', input)
        sample_record_url = input.delete('sample_record_url')
        table_id = sample_record_url.scan(/tbl\w+/)[0] || ''
        criterias = input['fields']&.map do |key, value|
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
        {
          records: call('format_api_output_field_names',
                        get("/v0/#{connection['base_id']}/#{table_id}",
                            params)&.compact)['records']
        }
      end,

      config_fields: [{
        name: 'sample_record_url',
        hint: "You can find 'Copy record URL' by right-clicking on a " \
          'sample record. This record acts as the blueprint to build ' \
          'the table schema. Choose a record having values for all fields.',
        optional: false
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['search_record'].ignored('id', 'createdTime')
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'records',
          type: 'array',
          of: 'object',
          properties: object_definitions['record']
        }]
      end,

      sample_output: lambda do |connection, input|
        sample_record_url = input['sample_record_url']
        table_id = sample_record_url.scan(/tbl\w+/)[0] || ''
        record_id = sample_record_url.scan(/rec\w+/)[0] || ''
        {
          records: [call('format_api_output_field_names',
                         get("/v0/#{connection['base_id']}/" \
              "#{table_id}/#{record_id}/")) || {}]
        }
      end
    }
  },

  triggers: {
    new_record: {
      subtitle: 'New record',
      description: "New <span class='provider'>record" \
        "</span> in <span class='provider'>Airtable</span>",

      config_fields: [{
        name: 'sample_record_url',
        hint: "You can find 'Copy record URL' by right-clicking on a " \
          'sample record. This record acts as the blueprint to build ' \
          'the table schema. Choose a record having values for all fields.',
        optional: false
      }],

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

      poll: lambda do |connection, input, closure|
        page_size = 100
        offset = closure&.[](0) || 0
        created_since = (closure&.[](1) || input['since'] || 1.hour.ago).
                          to_time.utc.iso8601
        sample_record_url = input['sample_record_url']
        table_id = sample_record_url.scan(/tbl\w+/)[0] || ''
        params = {
          'filterByFormula' => "CREATED_TIME() >= '#{created_since}'",
          'offset' => offset,
          'pageSize' => page_size
        }.compact

        response = call('format_api_output_field_names',
                        get("/v0/#{connection['base_id']}/#{table_id}",
                            params).compact) || {}

        more_pages = response['offset'].present?
        closure = if more_pages
                    [created_since, response['offset']]
                  else
                    [now, nil]
                  end

        {
          events: response['records'],
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: ->(record) { record['id'].to_s },

      output_fields: ->(object_definitions) { object_definitions['record'] },

      sample_output: lambda do |connection, input|
        sample_record_url = input['sample_record_url']
        table_id = sample_record_url.scan(/tbl\w+/)[0] || ''
        record_id = sample_record_url.scan(/rec\w+/)[0] || ''

        call('format_api_output_field_names',
             get("/v0/#{connection['base_id']}/" \
            "#{table_id}/#{record_id}/")) || {}
      end
    }
  }
}
