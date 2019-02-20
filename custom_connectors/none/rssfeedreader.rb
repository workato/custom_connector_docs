{
  title: 'RSS Feed Reader 2.0',

  methods: {
    parse_xml_to_hash: lambda do |xml_obj|
      xml_obj['xml']&.
        inject({}) do |hash, (key, value)|
        if value.is_a?(Array)
          hash.merge(if (array_fields = xml_obj['array_fields'])&.include?(key)
                       {
                         key => value.map do |inner_hash|
                                  call('parse_xml_to_hash',
                                       'xml' => inner_hash,
                                       'array_fields' => array_fields)
                                end
                       }
                     else
                       {
                         key => call('parse_xml_to_hash',
                                     'xml' => value[0],
                                     'array_fields' => array_fields)
                       }
                     end)
        else
          value
        end
      end&.presence
    end,

    format_api_output_field_names: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call('format_api_output_field_names',  array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call('format_api_output_field_names', value)
          { key.gsub(/[!@#$%^&*(),.?":{}|<>]/, '_') => value }
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
          field[:name] = field[:name].gsub(/[!@#$%^&*(),.?":{}|<>]/, '_')
        elsif field['name'].present?
          field['name'] = field['name'].gsub(/[!@#$%^&*(),.?":{}|<>]/, '_')
        end
        field
      end
    end
  },

  connection: { authorization: { type: 'no_auth' } },

  test: ->(_connection) { true },

  object_definitions: {
    item: {
      fields: lambda do |_connection, _config_fields|
        item_fields = [
          { name: 'author' },
          { name: 'category' },
          { name: 'comments' },
          { name: 'description' },
          {
            type: 'object',
            name: 'enclosure',
            properties: [
              { name: '@length', label: 'Length' },
              { name: '@type', label: 'Type' },
              { name: '@url', label: 'URL' }
            ]
          },
          { name: 'guid', label: 'GUID' },
          { name: 'link' },
          {
            control_type: 'text',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'pubDate'
          },
          { name: 'source' },
          { name: 'title' }
        ]

        call('format_schema_field_names', item_fields.compact)
      end
    },

    channel: {
      fields: lambda do |_connection, _config_fields|
        channel_fields = [
          { name: 'title' },
          { name: 'link' },
          { name: 'description' },
          { name: 'language' },
          { name: 'copyright' },
          { name: 'managingEditor' },
          {
            control_type: 'text',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'pubDate'
          },
          {
            control_type: 'text',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'lastBuildDate'
          },
          { name: 'category' },
          { name: 'generator' },
          { name: 'docs' },
          {
            type: 'object',
            name: 'cloud',
            properties: [
              { name: '@domain', label: 'Domain' },
              { name: '@path', label: 'Path' },
              { name: '@url', label: 'URL' },
              { name: '@port', label: 'Port' },
              { name: '@protocol', label: 'Protocol' },
              { name: '@registerProcedure', label: 'Register procedure' }
            ]
          },
          {
            control_type: 'text',
            label: 'Time to live',
            type: 'string',
            name: 'ttl'
          },
          {
            name: 'image',
            type: 'object',
            properties: [
              { name: 'link' },
              { name: 'title' },
              { name: 'url' },
              { name: 'description' },
              { name: 'height' },
              { name: 'width' }
            ]
          },
          { name: 'language' },
          { name: 'rating' },
          {
            type: 'object',
            name: 'textInput',
            properties: [
              { name: 'description' },
              { name: 'link' },
              { name: 'name' },
              { name: 'title' }
            ]
          },
          { name: 'webMaster' },
          {
            name: 'item',
            type: 'array',
            of: 'object',
            properties: [
              { name: 'author' },
              { name: 'category' },
              { name: 'comments' },
              { name: 'description' },
              {
                type: 'object',
                name: 'enclosure',
                properties: [
                  { name: '@length', label: 'Length' },
                  { name: '@type', label: 'Type' },
                  { name: '@url', label: 'URL' }
                ]
              },
              { name: 'guid', label: 'GUID' },
              { name: 'link' },
              {
                control_type: 'text',
                render_input: 'date_time_conversion',
                parse_output: 'date_time_conversion',
                type: 'date_time',
                name: 'pubDate'
              },
              { name: 'source' },
              { name: 'title' }
            ]
          }
        ]

        call('format_schema_field_names', channel_fields.compact)
      end
    }
  },

  actions: {
    get_feed: {
      description: "Get <span class='provider'>items</span> from feed in " \
        "<span class='provider'>RSS Feed Reader 2.0</span>",

      input_fields: lambda do |_object_definitions|
        [{
          name: 'feed_url',
          label: 'Feed URL',
          type: 'string',
          control_type: 'url',
          optional: false,
          hint: 'E.g. <b>https://status.workato.com/history.rss</b>'
        }]
      end,

      execute: lambda do |_connection, input|
        {
          channel: call('format_api_output_field_names',
                        call('parse_xml_to_hash',
                             'xml' => get(input['feed_url'])
                                   .response_format_xml
                                   .dig('rss', 0, 'channel', 0),
                             'array_fields' => ['item'])&.compact)
        }
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'channel',
          type: 'object',
          properties: object_definitions['channel']
        }]
      end,

      sample_output: lambda do |_connection, input|
        {
          channel: [call('format_api_output_field_names',
                         call('parse_xml_to_hash',
                              'xml' => get(input['feed_url'])
                                    .response_format_xml
                                    .dig('rss', 0, 'channel', 0),
                              'array_fields' => ['item'])&.compact)] || []
        }
      end
    }
  },

  triggers: {
    new_item_in_feed: {
      description: "New <span class='provider'>item</span> in" \
        "<span class='provider'>RSS Feed Reader 2.0</span>",
      type: 'paging_desc',

      input_fields: lambda do |_object_definitions|
        [{
          name: 'feed_url',
          label: 'Feed URL',
          type: 'string',
          control_type: 'url',
          optional: false,
          hint: 'E.g. <b>https://status.workato.com/history.rss</b>'
        }]
      end,

      poll: lambda do |_connection, input, _page|
        items = call('format_api_output_field_names',
                     call('parse_xml_to_hash',
                          'xml' => get(input['feed_url'])
                                .response_format_xml
                                .dig('rss', 0, 'channel', 0),
                          'array_fields' => ['item'])&.compact)&.[]('item')

        { events: items || [], next_page: nil }
      end,

      document_id: lambda do |item|
        "#{item['guid']}@#{item['title']}@#{item['description']}"
      end,

      sort_by: ->(item) { item['pubDate'] },

      output_fields: ->(object_definitions) { object_definitions['item'] },

      sample_output: lambda do |_connection, input|
        call('format_api_output_field_names',
             call('parse_xml_to_hash',
                  'xml' => get(input['feed_url'])
                        .response_format_xml
                        .dig('rss', 0, 'channel', 0),
                  'array_fields' => ['item'])&.dig('item', 0)) || {}
      end
    }
  }
}
