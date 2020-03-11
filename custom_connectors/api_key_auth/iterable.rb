{
  title: 'Iterable',

  connection: {
    fields: [
      {
        name: 'api_key',
        label: 'API key',
        control_type: 'password',
        optional: false,
        hint: 'Get your <b>standard</b> API key <a href="https://app.' \
        'iterable.com/settings/apiKeys" target="_blank">here</a>.'
      }
    ],

    authorization: {
      type: 'api_key',
      credentials: ->(connection) { headers(api_key: connection['api_key']) }
    },
    base_uri: lambda do
      'https://api.iterable.com'
    end
  },

  test: lambda do
    get('/api/channels')
  end,

  methods: {
    format_api_input_field_names: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call('format_api_input_field_names', array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call('format_api_input_field_names', value)
          { key.gsub('_', '.') => value }
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
          { key.gsub('.', '_') => value }
        end.inject(:merge)
      else
        input
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
    end,
    custom_input_schema: lambda do |input|
      input_schema =
        case input['object_name']
        when 'users'
          parse_json(input&.
            dig('users', 'dataFields', 'input', 'schema') || '[]')
        when 'subscribers'
          parse_json(input&.
            dig('subscribers', 'dataFields', 'input', 'schema') || '[]')
        when 'catalog_item'
          parse_json(input&.
            dig('value', 'input', 'schema') || input&.
              dig('update', 'input', 'schema') || '[]')
        else
          parse_json(input&.
            dig('dataFields', 'input', 'schema') || '[]')
        end
      [
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
                  properties: call('make_schema_builder_fields_sticky',
                                   input_schema)
                }
              end
            )
          ].compact
        }
      ]
    end,
    custom_output_schema: lambda do |_input|
      [
        {
          name: 'output',
          label: 'Custom fields',
          control_type: 'schema-designer',
          sample_data_type: 'json_http',
          hint: 'Use this to define your custom fields from the output. E.g. <b>dataFields</b>',
          extends_schema: true,
          schema_neutral: true,
          sticky: true
        }
      ]
    end,
    response_schema: lambda do |input|
      if input['response_schema'].present?
        parse_json(input['response_schema'])
      else
        parse_json(input['output'] || '[]')
      end
    end,
    format_unix_to_utc_time: lambda do |input|
      date_fields = %w[createdAt updatedAt startAt endedAt lastModified]
      if input.is_a?(Array)
        input.map do |array_value|
          call('format_unix_to_utc_time', array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call('format_unix_to_utc_time', value)
          if date_fields.include?(key)
            { key => (value.to_i / 1000).to_i.to_time.utc }
          else
            { key => value }
          end
        end.inject(:merge)
      else
        input
      end
    end,
    format_date_time_field: lambda do |input|
      input&.to_time&.utc&.strftime('%Y-%m-%d %H:%M:%S') || ''
    end,

    ### SCHEMAS ###
    list: lambda do |_input|
      [
        { name: 'id' },
        { name: 'name' },
        { name: 'createdAt', type: 'datetime' },
        { name: 'listType' }
      ]
    end,
    event: lambda do |_input|
      [
        { name: 'email', sticky: true,
          hint: 'Either email or userId must be passed in to identify the user. If both are ' \
            'passed in, email takes precedence.' },
        { name: 'eventName', sticky: true, optional: false },
        { name: 'id', sticky: true,
          hint: 'Optional event ID. If an event exists with that ID, the event will be updated. ' \
            'If none is specified, a new ID will automatically be generated and returned.' },
        {
          sticky: true,
          control_type: 'date_time',
          hint: 'Time event happened. Set to the time event was received if unspecified.',
          type: 'date_time',
          name: 'createdAt'
        },
        { name: 'userId', sticky: true },
        {
          sticky: true,
          control_type: 'number',
          label: 'Campaign ID',
          parse_output: 'float_conversion',
          type: 'number',
          name: 'campaignId'
        },
        {
          sticky: true,
          control_type: 'number',
          label: 'Template ID',
          parse_output: 'float_conversion',
          type: 'number',
          name: 'templateId'
        }
      ]
    end,
    user: lambda do |_input|
      [
        { name: 'email' },
        { name: 'userId' },
        { name: 'mergeNestedObjects', type: 'boolean' },
        { name: 'correlationId' }
      ]
    end,
    catalog_item: lambda do |_input|
      [
        { name: 'catalogName' },
        { name: 'itemId' },
        { control_type: 'number', parse_output: 'float_conversion', type: 'number', name: 'size' },
        { control_type: 'date_time', render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
          type: 'date_time', name: 'lastModified' }
      ]
    end,
    channel: lambda do |_input|
      [
        { control_type: 'number', parse_output: 'float_conversion',
          type: 'number', name: 'id' },
        { name: 'name' },
        { name: 'channelType' },
        { name: 'messageMedium' }
      ]
    end,
    message_type: lambda do |_input|
      [
        { name: 'id', type: 'integer' },
        { name: 'name' },
        { name: 'channelId', type: 'integer' }
      ]
    end,

    ### CREATE METHODS ###
    format_create_payload: lambda do |input|
      case input['object_name']
      when 'list'
        input
      when 'campaign'
        lists = %w[listIds suppressionListIds]
        input.map do |key, value|
          if lists.include?(key)
            { key => value.split(',').map do |ids|
                       [ids.to_i]
                     end.flatten }
          elsif key.include?('sendAt')
            { key => call('format_date_time_field', value) }
          elsif key.include?('dataFields')
            { key => value&.dig('input', 'data') }
          else
            { key => value }
          end
        end.inject(:merge)
      when 'event'
        formatted_input = input.map do |key, value|
          if %w[dataFields].include?(key)
            { key => value&.dig('input', 'data') }
          elsif key == 'createdAt'
            { key => value.to_time.to_i }
          else
            { key => value }
          end
        end.inject(:merge)
        payload = call('format_api_input_field_names',
                       formatted_input).compact
        payload
      else
        {}
      end
    end,
    create_endpoint: lambda do |input|
      case input['object_name']
      when 'list'
        '/api/lists'
      when 'campaign'
        '/api/campaigns/create'
      when 'event'
        '/api/events/track'
      when 'catalog'
        "/api/catalogs/#{input['catalogName']}"
      end
    end,
    sample_create_record: lambda do |input|
      case input['object_name']
      when 'list'
        { "listId": '432438' }
      when 'campaign'
        { "campaignId": '432438' }
      when 'event'
        {
          "msg": 'Event with id: 1a3c9d2705754a74kadf53d9276f7e12 tracked.',
          "code": 'Success',
          "params": { "id": '1a3c9d2705754a749adf53k9276f7e12' }
        }
      when 'catalog'
        {
          "msg": 'Catalog with id: 1a3c9d2705754a74kadf53d9276f7e12 created.',
          "code": 'Success',
          "params": { "id": '2688', "name": 'TEST-catalog', "url": '/api/catalogs/TEST-catalog' }
        }
      end
    end,
    create_object_output: lambda do |input|
      case input['object_name']
      when 'list'
        [{ name: 'listId', type: 'integer' }]
      when 'campaign'
        [{ name: 'campaignId', type: 'integer' }]
      when 'event'
        [{ name: 'msg', label: 'Message' },
         { name: 'code' },
         { name: 'params', type: 'object', properties: [
           { name: 'id' }
         ] }]
      when 'catalog'
        [{ name: 'msg', label: 'Message' },
         { name: 'code' },
         { name: 'params', type: 'object', properties: [
           { name: 'id' },
           { name: 'name' },
           { name: 'url' }
         ] }]
      end
    end,
    create_list_schema: lambda do |_input|
      [{ name: 'name', label: 'List name', optional: false }]
    end,
    create_campaign_schema: lambda do |input|
      [
        { name: 'name', optional: false, label: 'Campaign name' },
        { name: 'listIds',
          control_type: 'multiselect',
          pick_list: 'project_lists',
          delimiter: ',',
          type: 'string',
          optional: false,
          label: 'List IDs',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'listIds',
            label: 'List IDs',
            type: :string,
            control_type: 'text',
            optional: false,
            toggle_hint: 'Use List IDs',
            hint: 'Please enter list IDs with commas as delimiter and without spaces.'
          } },
        { control_type: 'number',
          label: 'Template ID',
          type: 'number',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          optional: false,
          name: 'templateId' },
        { name: 'suppressionListIds',
          control_type: 'multiselect',
          pick_list: 'project_lists',
          delimiter: ',',
          type: 'string',
          hint: 'Optional IDs of lists of users that this campaign should not send emails to.',
          optional: true,
          label: 'Suppression list IDs',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'suppressionListIds',
            label: 'Suppression list IDs',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use List IDs',
            hint: 'Please enter list IDs with commas as delimiter and without spaces.'
          } },
        { name: 'sendAt',
          hint: 'When to send the message, it can be up to 7 days in the future. ' \
            'If in the past, email is sent immediately.',
          control_type: 'date_time' },
        { name: 'sendMode',
          control_type: 'select',
          pick_list: 'send_mode',
          hint: 'Send campaign based on project time zone or recipient time zone.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'sendMode',
            label: 'Send mode',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Valid values are: <b>ProjectTimeZone</b> or <b>RecipientTimeZone</b>'
          } },
        { name: 'startTimeZone',
          control_type: 'select',
          pick_list: 'timezones',
          hint: 'The starting time zone in for recipient time zone-based sends.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'startTimeZone',
            label: 'Start time zone',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Enter timezone in IANA format. Click <a href="https://en.wikipedia.org/wiki' \
              '/List_of_tz_database_time_zones" target="_blank" >here</a> to learn more.'
          } },
        { name: 'defaultTimeZone',
          control_type: 'select',
          pick_list: 'timezones',
          hint: 'The fallback time zone for recipient time zone-based sends if the recipient does not ' \
            'have time zone set.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'defaultTimeZone',
            label: 'Default time zone',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Enter timezone in IANA format. Click <a href="https://en.wikipedia.org/wiki' \
              '/List_of_tz_database_time_zones" target="_blank" >here</a> to learn more.'
          } },
        { name: 'dataFields', type: 'object', extends_schema: true,
          properties: call('custom_input_schema', input) }
      ]
    end,
    create_event_schema: lambda do |input|
      call('event', '').
        concat([{ name: 'dataFields', type: 'object', extends_schema: true,
                  hint: 'Additional data associated with event (i.e. item amount, item quantity). ' \
                    'For events of the same name, ' \
                    'identically named data fields must be of the same type',
                  properties: call('custom_input_schema', input) }])
    end,
    create_catalog_schema: lambda do |_input|
      [{ name: 'catalogName', optional: false, hint: 'Catalog names have a maximum length of 255 characters ' \
          'and must contain only alphanumeric characters and dashes.' }]
    end,

    ### UPDATE METHODS ###
    format_update_payload: lambda do |input|
      case input['object_name']
      when 'catalog_item'
        payload = input.map do |key, val|
          if ['value'].include?(key)
            { key => val&.dig('input', 'data') }
          else
            {}
          end
        end.inject(:merge)
        payload
      when 'user_subscription'
        payload = input.map do |key, val|
          if %w[emailListIds unsubscribedChannelIds unsubscribedMessageTypeIds subscribedMessageTypeIds].
             include?(key)
            value = val.split(',')&.map { |id| id.to_i }
            { key => value }
          else
            { key => val }
          end
        end.inject(:merge)
        payload
      else
        {}
      end
    end,
    update_endpoint: lambda do |input|
      case input['object_name']
      when 'catalog_item'
        catalog_name = input.delete('catalogName')
        item_id = input.delete('itemId')
        "/api/catalogs/#{catalog_name}/items/#{item_id}"
      when 'user_subscription'
        '/api/users/updateSubscriptions'
      end
    end,
    sample_update_record: lambda do |input|
      case input['object_name']
      when 'catalog_item'
        {
          "msg": 'Response description',
          "code": 'Success',
          "params": {
            "catalogName": 'TEST-catalog',
            "itemId": 'TEST-catalog-item',
            "url": '/api/catalogs/TEST-catalog/items/TEST-catalog-item'
          }
        }
      when 'user_subscription'
        {
          "msg": 'Response description',
          "code": 'Success',
          "params": {}
        }
      end
    end,
    update_object_output: lambda do |input|
      case input['object_name']
      when 'catalog_item'
        [{ name: 'msg', label: 'Message' },
         { name: 'code' },
         { name: 'params', type: 'object', properties: [
           { name: 'catalogName' },
           { name: 'itemId' },
           { name: 'url' }
         ] }]
      when 'user_subscription'
        [{ name: 'msg', label: 'Message' },
         { name: 'code' },
         { name: 'params', type: 'object' }]
      end
    end,
    update_catalog_item_schema: lambda do |input|
      [
        { name: 'value', type: 'object', extends_schema: true, optional: false,
          hint: 'JSON representation of the catalog item.',
          properties: call('custom_input_schema', input) },
        { name: 'catalogName', optional: false },
        { name: 'itemId', optional: false,
          hint: "A catalog item's ID must be unique, contain only alphanumeric characters " \
            'and dashes, and have a maximum length of 255 characters.' }
      ]
    end,
    update_user_subscription_schema: lambda do |_input|
      [
        { name: 'email', sticky: true },
        { name: 'userId', sticky: true },
        { name: 'emailListIds',
          control_type: 'multiselect',
          pick_list: 'project_lists',
          delimiter: ',',
          type: 'string',
          sticky: true,
          hint: 'Lists that a user is subscribed to.',
          label: 'Email list IDs',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'emailListIds',
            label: 'Email list IDs',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use List IDs',
            hint: 'Please enter list IDs separated by commas and without spaces.'
          } },
        { name: 'unsubscribedChannelIds',
          control_type: 'multiselect',
          pick_list: 'channels',
          delimiter: ',',
          type: 'string',
          sticky: true,
          hint: 'Email channel IDs to unsubscribe from.',
          label: 'Unsubscribed channel IDs',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'unsubscribedChannelIds',
            label: 'Unsubscribed channel IDs',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use List IDs',
            hint: 'Please enter Channel IDs separated by commas and without spaces.'
          } },
        { name: 'unsubscribedMessageTypeIds',
          control_type: 'multiselect',
          pick_list: 'message_types',
          delimiter: ',',
          type: 'string',
          sticky: true,
          hint: 'Individual message type IDs to unsubscribe (does not impact channel subscriptions).',
          label: 'Unsubscribed message type IDs',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'unsubscribedMessageTypeIds',
            label: 'Unsubscribed message type IDs',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use Message type IDs',
            hint: 'Please enter Message type IDs separated by commas and without spaces.'
          } },
        { name: 'subscribedMessageTypeIds',
          control_type: 'multiselect',
          pick_list: 'message_types',
          delimiter: ',',
          type: 'string',
          sticky: true,
          hint: 'Individual message type IDs to subscribe (does not impact channel subscriptions). ' \
            'To set a value for this field, first have your CSM enable the opt-in message types feature. ' \
            'Otherwise, attempting to set this field causes an error.',
          label: 'Subscribed message type IDs',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'subscribedMessageTypeIds',
            label: 'Subscribed message type IDs',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use Message type IDs',
            hint: 'Please enter Message type IDs separated by commas and without spaces.'
          } },
        { name: 'campaignId', sticky: true, control_type: 'select',
          label: 'Campaign',
          pick_list: 'campaigns',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Campaign to attribute unsubscribes.',
          toggle_hint: 'Select campaign',
          toggle_field: {
            name: 'campaignId', label: 'Campaign ID',
            control_type: 'number',
            type: 'integer',
            optional: true,
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Please enter Campaign ID.'
          } },
        { name: 'templateId',
          control_type: 'number',
          type: 'integer',
          sticky: true,
          hint: 'Template to attribute unsubscribes.',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion' }
      ]
    end,

    ### UPSERT METHODS ###
    format_upsert_payload: lambda do |input|
      case input['object_name']
      when 'user'
        payload = input.map do |key, val|
          if ['dataFields'].include?(key)
            { key => val&.dig('input', 'data') }
          else
            { key => val }
          end
        end.inject(:merge)
        payload
      when 'catalog_item'
        payload = input.map do |key, val|
          if ['update'].include?(key)
            { key => val&.dig('input', 'data') }
          else
            {}
          end
        end.inject(:merge)
        payload
      else
        {}
      end
    end,
    upsert_endpoint: lambda do |input|
      case input['object_name']
      when 'user'
        '/api/users/update'
      when 'catalog_item'
        catalog_name = input.delete('catalogName')
        item_id = input.delete('itemId')
        "/api/catalogs/#{catalog_name}/items/#{item_id}"
      end
    end,
    sample_upsert_record: lambda do |input|
      case input['object_name']
      when 'user'
        {
          "msg": 'Message',
          "code": 'Success',
          "params": {}
        }
      when 'catalog_item'
        {
          "msg": 'Response description',
          "code": 'Success',
          "params": {
            "catalogName": 'TEST-catalog',
            "itemId": 'TEST-catalog-item',
            "url": '/api/catalogs/TEST-catalog/items/TEST-catalog-item'
          }
        }
      end
    end,
    upsert_object_output: lambda do |input|
      case input['object_name']
      when 'user'
        [{ name: 'msg', label: 'Message' },
         { name: 'code' },
         { name: 'params', type: 'object' }]
      when 'catalog_item'
        [{ name: 'msg', label: 'Message' },
         { name: 'code' },
         { name: 'params', type: 'object', properties: [
           { name: 'catalogName' },
           { name: 'itemId' },
           { name: 'url' }
         ] }]
      end
    end,
    upsert_user_schema: lambda do |input|
      [
        { name: 'email', control_type: 'email',
          label: 'Email address', sticky: true,
          hint: 'An email must be set unless a profile already exists' \
            ' with a userId set. In which case, a lookup from userId ' \
            'to email is performed.' },
        { name: 'userId', sticky: true,
          hint: 'Optional user ID, typically your ' \
            'database generated ID. Either email or user ID must be ' \
            'specified.' },
        { name: 'preferUserId', type: 'boolean',
          sticky: true,
          control_type: 'checkbox',
          hint: 'Create a new user with the specified user ID if ' \
          'the user does not exist yet.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'preferUserId',
                label: 'Prefer user ID',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' } },
        { name: 'mergeNestedObjects', type: 'boolean',
          sticky: true,
          control_type: 'checkbox',
          hint: 'Merge top level objects instead of overwriting.',
          toggle_hint: 'Select from list',
          toggle_field:
              { name: 'mergeNestedObjects',
                label: 'Merge nested objects',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' } },
        { name: 'dataFields', type: 'object', extends_schema: true,
          properties: call('custom_input_schema', input) }
      ]
    end,
    upsert_catalog_item_schema: lambda do |input|
      [
        { name: 'update', type: 'object', extends_schema: true, optional: false,
          hint: 'JSON representation of the catalog item.',
          properties: call('custom_input_schema', input) },
        { name: 'catalogName', optional: false },
        { name: 'itemId', optional: false,
          hint: "A catalog item's ID must be unique, contain only alphanumeric characters " \
            'and dashes, and have a maximum length of 255 characters.' }
      ]
    end,

    ### SEARCH METHODS ###
    format_search_params: lambda do |input|
      case input['object_name']
      when 'events'
        { limit: input['limit'] }
      when 'catalogs'
        {
          page: input['page'],
          pageSize: input['pageSize']
        }
      when 'catalog_items'
        {
          page: input['page'],
          pageSize: input['pageSize'],
          orderBy: input['orderBy'],
          sortAscending: input['sortAscending']
        }
      end
    end,
    search_endpoint: lambda do |input|
      case input['object_name']
      when 'campaigns'
        '/api/campaigns'
      when 'events'
        "/api/events/#{input['email']}"
      when 'channels'
        '/api/channels'
      when 'catalogs'
        '/api/catalogs'
      when 'catalog_items'
        "/api/catalogs/#{input['catalog_name']}/items"
      when 'lists'
        '/api/lists'
      when 'message_types'
        '/api/messageTypes'
      end
    end,
    sample_search_record: lambda do |input|
      case input['object_name']
      when 'campaigns'
        response = get('/api/campaigns')
        result = parse_json(response.to_json)
        call('format_unix_to_utc_time', result)
      when 'channels'
        get('/api/channels')
      when 'catalogs'
        get('/api/catalogs')&.dig('params')
      when 'catalog_items'
        catalog_name = get('/api/catalogs')&.dig('params', 'catalogNames', 0, 'name')
        response = get("/api/catalogs/#{catalog_name}/items")&.dig('params')
        result = parse_json(response.to_json)
        call('format_unix_to_utc_time', result)
      when 'lists'
        get('/api/lists')
      when 'message_types'
        get('/api/messageTypes')
      end
    end,
    search_object_output: lambda do |input|
      case input['object_name']
      when 'campaigns'
        [
          { name: 'campaigns', type: 'array', of: 'object',
            properties: [
              { control_type: 'number', type: 'number', name: 'id' },
              { control_type: 'date_time', type: 'date_time', name: 'createdAt' },
              { control_type: 'date_time', type: 'date_time', name: 'updatedAt' },
              { control_type: 'date_time', type: 'date_time', name: 'startAt' },
              { control_type: 'date_time', type: 'date_time', name: 'endedAt' },
              { name: 'name' },
              { control_type: 'number', parse_output: 'float_conversion',
                type: 'number', name: 'templateId' },
              { name: 'messageMedium' },
              { name: 'createdByUserId' },
              { name: 'campaignState' },
              { control_type: 'number', parse_output: 'float_conversion',
                type: 'number', name: 'sendSize' },
              { control_type: 'number', parse_output: 'float_conversion',
                type: 'number', name: 'recurringCampaignId' },
              { control_type: 'number', parse_output: 'float_conversion',
                type: 'number', name: 'workflowId' },
              { name: 'labels', type: 'array', of: 'string', control_type: 'text' },
              { name: 'listIds', type: 'array', of: 'number', control_type: 'text',
                label: 'List IDs', parse_output: 'float_conversion' },
              { name: 'suppressionListIds', type: 'array', of: 'number', control_type: 'text',
                label: 'Suppression list IDs', parse_output: 'float_conversion' },
              { name: 'type' }
            ] }
        ]
      when 'events'
        call('response_schema', input)
      when 'channels'
        [
          { name: 'channels', type: 'array', of: 'object',
            properties: call('channel', '') }
        ]
      when 'catalogs'
        [{ name: 'catalogNames', type: 'array', of: 'object',
           properties: [{ name: 'name' }] }]
      when 'catalog_items'
        [
          {
            name: 'catalogItemsWithProperties',
            label: 'Catalog items',
            type: 'array',
            of: 'object',
            properties: call('catalog_item', '').
              concat([
                       { name: 'value',
                         label: 'Custom fields',
                         type: 'object',
                         properties: call('response_schema', input) }
                     ])
          }
        ]
      when 'lists'
        [
          { name: 'lists', type: 'array', of: 'object',
            properties: call('list', '') }
        ]
      when 'message_types'
        [
          { name: 'messageTypes', type: 'array', of: 'object',
            properties: call('message_type', '') }
        ]
      end
    end,
    search_campaigns_schema: lambda do |_input|
      []
    end,
    search_events_schema: lambda do |_input|
      [
        { name: 'email', label: 'Email address', optional: false,
          hint: 'Email of the user whose events you are retrieving.' },
        { name: 'limit', hint: 'The number of events to retrieve. (Max is 200)', sticky: true },
        {
          name: 'response_schema',
          label: 'Response Schema',
          control_type: 'schema-designer',
          sample_data_type: 'json',
          optional: true,
          sticky: true,
          empty_schema_title: 'Describe your response schema in JSON',
          empty_schema_message: '<button type="button" ' \
            'data-action="generateSchema">Use sample JSON</button> to ' \
            'generate fields at once.<br>Response Schema should match the ' \
            '<a href="https://api.iterable.com/api/docs#events_User_events" target="_blank">response syntax</a> ' \
            'specified by the API.'
        }
      ]
    end,
    search_catalogs_schema: lambda do |_input|
      [
        { name: 'page', hint: 'Page number to list (starting at 1).', sticky: true },
        { name: 'pageSize', hint: 'Number of results to display per page (defaults to 10).', sticky: true }
      ]
    end,
    search_catalog_items_schema: lambda do |_input|
      [
        { name: 'catalogName', optionl: false },
        { name: 'page', hint: 'Page number to list (starting at 1).', sticky: true },
        { name: 'pageSize', hint: 'Number of results to display per page (defaults to 10).', sticky: true },
        { name: 'orderBy', hint: 'Field by which results should be ordered. To also use the <b>Sort ascending</b> ' \
            'parameter, this field must have a defined type.' },
        {
          name: 'sortAscending',
          control_type: 'checkbox',
          type: 'boolean',
          hint: 'Sort results by ascending (Defaults to false).',
          sticky: true,
          toggle_hint: 'Select value',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_field: {
            name: 'sortAscending',
            label: 'Sort ascending',
            toggle_hint: 'Use custom value',
            hint: 'Valid values are <b>true</b> or <b>false</b>',
            control_type: 'text',
            type: 'string',
            optional: true,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion'
          }
        }
      ].concat(call('custom_output_schema', ''))
    end,

    ### RETRIEVE METHODS ###
    format_get_params: lambda do |input|
      case input['object_name']
      when 'user'
        { email: input['email'] }
      when 'email'
        { email: input['email'], messageId: input['messageId'] }
      end
    end,
    get_endpoint: lambda do |input|
      case input['object_name']
      when 'user'
        '/api/users/getByEmail'
      when 'email'
        '/api/email/viewInBrowser'
      when 'catalog_item'
        catalog_name = input.delete('catalogName')
        item_id = input.delete('itemId')
        "/api/catalogs/#{catalog_name}/items/#{item_id}"
      end
    end,
    sample_get_record: lambda do |input|
      case input['object_name']
      when 'user'
        {
          "email": 'email@test.com',
          "dataFields": 'Custom data fields',
          "userId": '58124',
          "mergeNestedObjects": 'true',
          "correlationId": 'XXXXXX'
        }
      when 'catalog_item'
        catalog_name = get('/api/catalogs')&.dig('params', 'catalogNames', 0, 'name')
        get("/api/catalogs/#{catalog_name}/items")&.dig('params', 'catalogItemsWithProperties', 0)
      end
    end,
    get_object_output: lambda do |input|
      case input['object_name']
      when 'user'
        call('user', '').
          concat([
                   { name: 'dataFields',
                     label: 'Custom fields',
                     type: 'object',
                     properties: call('response_schema', input) }
                 ])
      when 'catalog_item'
        call('catalog_item', '').
          concat([
                   { name: 'value',
                     label: 'Custom fields',
                     type: 'object',
                     properties: call('response_schema', input) }
                 ])
      when 'email'
        { name: 'content', label: 'Email contents in raw format' }
      end
    end,
    get_user_schema: lambda do |_input|
      [
        { name: 'email', optional: false }
      ].concat(call('custom_output_schema', ''))
    end,
    get_catalog_item_schema: lambda do |_input|
      [
        { name: 'catalogName', optional: false },
        { name: 'itemId', optional: false }
      ].concat(call('custom_output_schema', ''))
    end,
    get_email_schema: lambda do |_input|
      [
        { name: 'email', label: 'Email address', hint: "User's email", optional: false },
        { name: 'messageId', hint: 'ID of the sent message.', optional: false }
      ]
    end,

    ### DELETE METHODS ###
    format_delete_params: lambda do |input|
      case input['object_name']
      when 'user'
        { email: input['email'] }
      when 'catalog_item'
        { catalogName: input['catalogName'],
          itemId: input['itemId'] }
      end
    end,
    delete_endpoint: lambda do |input|
      case input['object_name']
      when 'user'
        email = input.delete('email')
        "/api/users/#{email}"
      when 'catalog_item'
        catalog_name = input.delete('catalogName')
        item_id = input.delete('itemId')
        "/api/catalogs/#{catalog_name}/items/#{item_id}"
      end
    end,
    sample_delete_record: lambda do |_input|
      {
        "msg": 'Response description',
        "code": 'Success',
        "params": {}
      }
    end,
    delete_object_output: lambda do |_input|
      [{ name: 'msg', label: 'Message' },
       { name: 'code' },
       { name: 'params', type: 'object', properties: [] }]
    end,
    delete_user_schema: lambda do |_input|
      [
        { name: 'email', label: 'Email address', optional: false }
      ]
    end,
    delete_catalog_item_schema: lambda do |_input|
      [
        { name: 'catalogName', optional: false },
        { name: 'itemId', optional: false }
      ]
    end,

    ### SEND OBJECT METHODS ###
    format_send_payload: lambda do |input|
      payload = input.map do |key, value|
        if %w[sendAt].include?(key)
          { key => call('format_date_time_field', value) }
        elsif %w[dataFields].include?(key)
          { key => value&.dig('input', 'data') }
        else
          { key => value }
        end
      end.inject(:merge)

      payload
    end,
    send_endpoint: lambda do |input|
      case input['object_name']
      when 'sms'
        '/api/sms/target'
      when 'email'
        '/api/email/target'
      when 'webpush'
        '/api/webPush/target'
      when 'in_app'
        '/api/inApp/target'
      end
    end,
    sample_send_record: lambda do |_input|
      {
        "msg": 'Response description',
        "code": 'Success',
        "params": {}
      }
    end,
    send_object_output: lambda do |_input|
      [{ name: 'msg', label: 'Message' },
       { name: 'code' },
       { name: 'params', type: 'object', properties: [] }]
    end,
    send_schema: lambda do |input|
      [
        { name: 'campaignId',
          control_type: 'select',
          pick_list: 'campaigns',
          label: 'Campaign',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Select campaign to use.',
          optional: false,
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'campaignId',
            label: 'Campaign ID',
            type: 'integer',
            control_type: 'number',
            optional: false,
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Please enter campaign ID.'
          } },
        { name: 'recipientEmail', type: 'string',
          control_type: 'email', optional: false },
        { name: 'sendAt', type: 'date_time',
          control_type: 'date_time',
          hint: 'Schedule the message for up to 365 days in the future. ' \
          'If set in the past, message is sent immediately.',
          optional: true, sticky: true },
        {
          name: 'allowRepeatMarketingSends',
          type: :boolean,
          control_type: 'checkbox',
          optional: true,
          sticky: true,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from options',
          hint: 'Allow repeat marketing sends? Defaults to true.',
          toggle_field: {
            name: 'allowRepeatMarketingSends',
            label: 'Allow repeat marketing sends?',
            type: 'string',
            optional: true,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true and false.'
          }
        },
        { name: 'dataFields', type: 'object', extends_schema: true,
          properties: call('custom_input_schema', input),
          sticky: true }
      ]
    end,

    ### BULK UPSERT METHODS ###
    format_bulk_upsert_payload: lambda do |input|
      case input['object_name']
      when 'users'
        payload = input['users']&.map do |object|
          object.map do |key, val|
            if ['dataFields'].include?(key)
              { key => val&.dig('input', 'data') }
            else
              { key => val }
            end
          end.inject(:merge)
        end
        { users: payload }
      else
        {}
      end
    end,
    bulk_upsert_endpoint: lambda do |input|
      case input['object_name']
      when 'users'
        '/api/users/bulkUpdate'
      end
    end,
    sample_bulk_upsert_record: lambda do |input|
      case input['object_name']
      when 'users'
        {
          successCount: 1,
          failCount: 0,
          invalidEmails: ['test@test.com'],
          invalidUserIds: ['000001']
        }
      end
    end,
    bulk_upsert_object_output: lambda do |input|
      case input['object_name']
      when 'users'
        [{ name: 'successCount', type: 'integer' },
         { name: 'failCount', type: 'integer' },
         { name: 'invalidEmails', type: 'array', of: 'string' },
         { name: 'invalidUserIds', type: 'array', of: 'string' }]
      end
    end,
    bulk_upsert_user_schema: lambda do |input|
      [
        {
          name: 'users', type: 'array', of: 'object', list_mode_toggle: false,
          properties: [
            { name: 'email', control_type: 'email',
              label: 'Email address', sticky: true,
              hint: 'An email must be set unless a profile already exists' \
                ' with a userId set. In which case, a lookup from userId ' \
                'to email is performed.' },
            { name: 'userId', sticky: true,
              hint: 'Optional user ID, typically your ' \
                'database generated ID. Either email or user ID must be ' \
                'specified.' },
            { name: 'preferUserId', type: 'boolean', sticky: true,
              control_type: 'checkbox',
              hint: 'Create a new user with the specified userId if ' \
              'the user does not exist yet.',
              toggle_hint: 'Select from list',
              toggle_field:
                  { name: 'preferUserId',
                    label: 'Prefer user ID',
                    type: :boolean,
                    control_type: 'text',
                    optional: true,
                    render_input: 'boolean_conversion',
                    toggle_hint: 'Use custom value',
                    hint: 'Allowed values are true or false' } },
            { name: 'mergeNestedObjects', type: 'boolean', sticky: true,
              control_type: 'checkbox',
              hint: 'Merge top level objects instead of overwriting.',
              toggle_hint: 'Select from list',
              toggle_field:
                  { name: 'mergeNestedObjects',
                    label: 'Merge nested objects',
                    type: :boolean,
                    control_type: 'text',
                    optional: true,
                    render_input: 'boolean_conversion',
                    toggle_hint: 'Use custom value',
                    hint: 'Allowed values are true or false' } },
            { name: 'dataFields', type: 'object', extends_schema: true,
              properties: call('custom_input_schema', input) }
          ]
        }
      ]
    end,

    ### BULK UPDATE METHODS ###
    format_bulk_update_payload: lambda do |input|
      case input['object_name']
      when 'user_subscriptions'
        payload = input['updateSubscriptionsRequests'].map do |items|
          items.map do |key, val|
            if %w[emailListIds unsubscribedChannelIds unsubscribedMessageTypeIds subscribedMessageTypeIds].
               include?(key)
              value = val.split(',')&.map { |id| id.to_i }
              { key => value }
            else
              { key => val }
            end
          end&.inject(:merge)
        end
        { updateSubscriptionsRequests: payload }
      else
        {}
      end
    end,
    bulk_update_endpoint: lambda do |input|
      case input['object_name']
      when 'user_subscriptions'
        '/api/users/bulkUpdateSubscriptions'
      end
    end,
    sample_bulk_update_record: lambda do |input|
      case input['object_name']
      when 'user_subscriptions'
        {
          "successCount": 0,
          "failCount": 0,
          "invalidEmails": [
            'string'
          ],
          "invalidUserIds": [
            'string'
          ],
          "validEmailFailures": [
            'string'
          ],
          "validUserIdFailures": [
            'string'
          ]
        }
      end
    end,
    bulk_update_object_output: lambda do |input|
      case input['object_name']
      when 'user_subscriptions'
        [{ control_type: 'number',
           type: 'number',
           name: 'successCount' },
         { control_type: 'number',
           type: 'number',
           name: 'failCount' },
         { name: 'invalidEmails',
           type: 'array',
           of: 'string' },
         { name: 'invalidUserIds',
           type: 'array',
           of: 'string',
           label: 'Invalid user IDs' },
         { name: 'validEmailFailures',
           type: 'array',
           of: 'string' },
         { name: 'validUserIdFailures',
           type: 'array',
           of: 'string',
           label: 'Valid user ID failures' }]
      end
    end,
    bulk_update_user_subscriptions_schema: lambda do |_input|
      [
        { name: 'updateSubscriptionsRequests', type: 'array', of: 'object', optional: false, properties: [
          { name: 'email', sticky: true },
          { name: 'userId', sticky: true },
          { name: 'emailListIds',
            control_type: 'multiselect',
            pick_list: 'project_lists',
            delimiter: ',',
            type: 'string',
            sticky: true,
            hint: 'Lists that a user is subscribed to.',
            label: 'Email list IDs',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'emailListIds',
              label: 'Email list IDs',
              type: :string,
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use List IDs',
              hint: 'Please enter list IDs separated by commas and without spaces.'
            } },
          { name: 'unsubscribedChannelIds',
            control_type: 'multiselect',
            pick_list: 'channels',
            delimiter: ',',
            type: 'string',
            sticky: true,
            hint: 'Email channel IDs to unsubscribe from.',
            label: 'Unsubscribed channel IDs',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'unsubscribedChannelIds',
              label: 'Unsubscribed channel IDs',
              type: :string,
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use List IDs',
              hint: 'Please enter Channel IDs separated by commas and without spaces.'
            } },
          { name: 'unsubscribedMessageTypeIds',
            control_type: 'multiselect',
            pick_list: 'message_types',
            delimiter: ',',
            type: 'string',
            sticky: true,
            hint: 'Individual message type IDs to unsubscribe (does not impact channel subscriptions).',
            label: 'Unsubscribed message type IDs',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'unsubscribedMessageTypeIds',
              label: 'Unsubscribed message type IDs',
              type: :string,
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use Message type IDs',
              hint: 'Please enter Message type IDs separated by commas and without spaces.'
            } },
          { name: 'subscribedMessageTypeIds',
            control_type: 'multiselect',
            pick_list: 'message_types',
            delimiter: ',',
            type: 'string',
            sticky: true,
            hint: 'Individual message type IDs to subscribe (does not impact channel subscriptions). ' \
              'To set a value for this field, first have your CSM enable the opt-in message types feature. ' \
              'Otherwise, attempting to set this field causes an error.',
            label: 'Subscribed message type IDs',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'subscribedMessageTypeIds',
              label: 'Subscribed message type IDs',
              type: :string,
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use Message type IDs',
              hint: 'Please enter Message type IDs separated by commas and without spaces.'
            } },
          { name: 'campaignId', sticky: true, control_type: 'select',
            label: 'Campaign',
            pick_list: 'campaigns',
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion',
            hint: 'Campaign to attribute unsubscribes.',
            toggle_hint: 'Select campaign',
            toggle_field: {
              name: 'campaignId', label: 'Campaign ID',
              control_type: 'number',
              type: 'integer',
              optional: true,
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              toggle_hint: 'Use custom value',
              hint: 'Please enter Campaign ID.'
            } },
          { name: 'templateId',
            control_type: 'number',
            type: 'integer',
            sticky: true,
            hint: 'Template to attribute unsubscribes.',
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion' }
        ] }
      ]
    end,

    ### EXPORT DATA METHODS ###
    retrieve_csv_headers: lambda do |input|
      input&.delete('range')
      input&.delete('startDateTime')
      input&.delete('endDateTime')
      input['range'] = 'Today'
      params = call('format_export_data_params', input&.compact)
      response = get('/api/export/data.csv',
                     params&.except('object_name', 'export_format', 'export_report_raw')).
                 response_format_raw.after_error_response(/.*/) do |code, body, _header, message|
                   if code == 429
                     error('Iterable API timed out. Please wait for a minute and try again.')
                   else
                     error("#{message}: #{body}")
                   end
                 end
      result = response&.gsub(/[\r\n]+/, '___')&.split('___')
      result[0]&.split(',')
    end,
    format_export_data_params: lambda do |input|
      case input['object_name']
      when 'csv_json'
        if input['export_format'] == 'CSV'
          input['delimiter'] = ','
          payload = input.map do |key, value|
            if %w[date_range].include?(key)
              value.map do |k, v|
                { k => call('format_date_time_field', v) }
              end.inject(:merge)
            elsif value == 'custom_date'
              {}
            elsif %w[omitFields].include?(key)
              { key => value.to_s.gsub(/["\\\[\]]/, '').gsub(', ', ',') }
            else
              { key => value }
            end
          end.inject(:merge)
          payload
        elsif input['export_format'] == 'JSON'
          input['export_format'] = 'CSV'
          params = call('format_export_data_params', input)
          params.except('delimiter')
        else
          input['export_format'] = 'CSV'
          call('format_export_data_params', input)
        end
      when 'user_events'
        input
      end
    end,
    export_data_endpoint: lambda do |input|
      case input['object_name']
      when 'csv_json'
        if input['export_format'] == 'JSON'
          '/api/export/data.json'
        else
          '/api/export/data.csv'
        end
      when 'user_events'
        '/api/export/userEvents'
      end
    end,
    sample_export_data_record: lambda do |input|
      case input['object_name']
      when 'csv_json'
        if input['export_report_raw'] == 'false' || input['export_report_raw'].blank?
          hash = {}
          headers = call('retrieve_csv_headers', input)
          sample_data = headers&.map do |key, _value|
            hash[key] = "#{key} values"
            hash
          end
          { lines: sample_data }
        else
          { data: 'Sample data' }
        end
      when 'user_events'
        { json: 'Sample data' }
      end
    end,
    export_data_object_output: lambda do |input|
      case input['object_name']
      when 'csv_json'
        if input['export_format'] == 'CSV'
          [{ name: 'data', label: 'CSV data' }]
        elsif input['export_format'] == 'JSON'
          [{ name: 'data', label: 'JSON data' }]
        elsif input['dataTypeName'].present? || input['export_report_raw'] == 'false'
          headers = call('retrieve_csv_headers', input)
          rows = headers&.map do |field|
            { name: field }
          end
          [{
            name: 'lines',
            type: 'array',
            of: 'object',
            properties: rows || []
          }]
        else
          [{
            name: 'lines',
            type: 'array',
            of: 'object',
            properties: []
          }]
        end
      when 'user_events'
        [{ name: 'data', label: 'JSON data' }]
      end
    end,
    export_data_csv_json_schema: lambda do |input|
      date_range = input['range']
      export_report_raw = input['export_report_raw']
      data_type_name = input['dataTypeName']
      columns = data_type_name.present? ? call('retrieve_csv_headers', input.except('omitFields'))&.map { |fields| [fields.labelize, fields] } : []
      [
        { name: 'dataTypeName',
          label: 'Data type',
          control_type: 'select',
          pick_list: 'data_type_name',
          extends_schema: true,
          optional: false },
        { name: 'range',
          label: 'Date range',
          control_type: 'select',
          pick_list: [
            %w[Today Today],
            %w[Yesterday Yesterday],
            %w[All All],
            %w[Custom\ date custom_date]
          ],
          optional: false,
          extends_schema: true },
        if data_type_name.present?
          {
            name: 'export_report_raw',
            label: 'Export data in raw format',
            type: :boolean,
            control_type: 'checkbox',
            sticky: true,
            optional: true,
            extends_schema: true,
            toggle_hint: 'Select from options',
            hint: 'Select <b>Yes</b> to export data in raw format.',
            toggle_field: {
              name: 'export_report_raw',
              label: 'Export data in raw format',
              type: 'string',
              control_type: 'text',
              optional: true,
              extends_schema: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true and false.'
            }
          }
        end,
        if export_report_raw == 'true'
          {
            name: 'export_format', optional: false, control_type: 'select',
            pick_list: [
              %w[CSV CSV],
              %w[JSON JSON]
            ],
            label: 'File format',
            extends_schema: true,
            toggle_hint: 'Select from options',
            hint: 'The file format the report should be in.',
            toggle_field: {
              name: 'export_format',
              label: 'Export format',
              type: 'string',
              extends_schema: true,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: CSV and JSON'
            }
          }
        end,
        if date_range == 'custom_date'
          { name: 'date_range', optional: false, type: :object,
            hint: 'The custom date range to retrieve the report.',
            properties: [
              { name: 'endDateTime', label: 'End date', optional: false,
                type: 'date_time', control_type: 'date_time',
                hint: 'The latest date in the date range to retrieve the report.' },
              { name: 'startDateTime', label: 'Start date', optional: false,
                type: 'date_time', control_type: 'date_time',
                hint: 'The earliest date in the date range to retrieve the report.' }
            ] }
        end,
        { name: 'omitFields',
          label: 'Fields to skip',
          hint: 'Fields to omit, comma separated',
          sticky: true,
          extends_schema: true,
          control_type: 'multiselect',
          pick_list: columns,
          toggle_hint: 'Select from options',
          toggle_field: {
            name: 'omitFields',
            label: 'Fields to skip',
            type: 'string',
            extends_schema: true,
            optional: true,
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Please enter API field names separated by commas, without spaces.'
          } },
        { name: 'campaignId', hint: 'If provided, only export data from this campaign.',
          sticky: true }
      ].compact
    end,
    export_data_user_events_schema: lambda do |_input|
      [
        { name: 'email', label: 'Email address', optional: false },
        { name: 'includeCustomEvents',
          type: 'boolean',
          control_type: 'checkbox',
          sticky: true,
          hint: 'Defaults to false.',
          toggle_hint: 'Select from options',
          toggle_field: {
            name: 'includeCustomEvents',
            label: 'Include custom events',
            type: 'string',
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true and false.'
          } }
      ]
    end
  },

  object_definitions: {
    list: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'name' },
          { name: 'createdAt', type: 'datetime' },
          { name: 'listType' }
        ]
      end
    },
    channel: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id', type: 'integer' },
          { name: 'name' },
          { name: 'channelType' },
          { name: 'messageMedium' }
        ]
      end
    },
    user: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'email' },
          { name: 'userId' },
          { name: 'mergeNestedObjects', type: 'integer' },
          { name: 'correlationId' }
        ]
      end
    },
    subscription: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'email', sticky: true },
          { name: 'userId', sticky: true },
          {
            name: 'emailListIds',
            label: 'Email list IDs',
            hint: 'Specify IDs separated by commas, without any spaces.',
            sticky: true
          },
          {
            name: 'unsubscribedChannelIds',
            label: 'Unsubscribed channel IDs',
            hint: 'Specify IDs separated by commas, without any spaces.',
            sticky: true
          },
          {
            name: 'unsubscribedMessageTypeIds',
            label: 'Unsubscribed message type IDs',
            hint: 'Specify IDs separated by commas, without any spaces.',
            sticky: true
          },
          {
            name: 'campaignId',
            control_type: 'number',
            type: 'integer',
            sticky: true,
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion'
          },
          {
            name: 'templateId',
            control_type: 'number',
            type: 'integer',
            sticky: true,
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion'
          }
        ]
      end
    },
    event: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'email', sticky: true },
          { name: 'eventName', sticky: true },
          { name: 'id', sticky: true },
          {
            sticky: true,
            control_type: 'date_time',
            type: 'date_time',
            name: 'createdAt'
          },
          { name: 'userId', sticky: true },
          {
            sticky: true,
            control_type: 'number',
            label: 'Campaign ID',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'campaignId'
          },
          {
            sticky: true,
            control_type: 'number',
            label: 'Template ID',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'templateId'
          }
        ]
      end
    },
    custom_request_output: {
      fields: lambda do |_connection, config_fields|
        parse_json(config_fields['output'] || '[]')
      end
    },
    custom_input_schema: {
      fields: lambda do |_connection, config_fields|
        input_schema =
          if config_fields['users'].present?
            parse_json(config_fields.
              dig('users', 'dataFields', 'input', 'schema') || '[]')
          elsif config_fields['subscribers'].present?
            parse_json(config_fields.
              dig('subscribers', 'dataFields', 'input', 'schema') || '[]')
          else
            parse_json(config_fields.
              dig('dataFields', 'input', 'schema') || '[]')
          end
        [
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
                    properties: call('make_schema_builder_fields_sticky',
                                     input_schema)
                  }
                end
              )
            ].compact
          }
        ]
      end
    },
    custom_output_schema: {
      fields: lambda do |_connection, _config_fields|
        [
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

    ### CREATE OBJECT ###
    create_object: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object_name']
        when 'list'
          call('create_list_schema', '')
        when 'campaign'
          call('create_campaign_schema', config_fields)
        when 'event'
          call('create_event_schema', config_fields)
        when 'catalog'
          call('create_catalog_schema', '')
        end
      end
    },
    object_create_output: {
      fields: lambda do |_connection, config_fields|
        call('create_object_output', config_fields)
      end
    },

    ### UPDATE OBJECT ###
    update_object: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object_name']
        when 'catalog_item'
          call('update_catalog_item_schema', config_fields)
        when 'user_subscription'
          call('update_user_subscription_schema', config_fields)
        end
      end
    },
    object_update_output: {
      fields: lambda do |_connection, config_fields|
        call('update_object_output', config_fields)
      end
    },

    ### UPSERT OBJECT ###
    upsert_object: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object_name']
        when 'user'
          call('upsert_user_schema', config_fields)
        when 'catalog_item'
          call('upsert_catalog_item_schema', config_fields)
        end
      end
    },
    object_upsert_output: {
      fields: lambda do |_connection, config_fields|
        call('upsert_object_output', config_fields)
      end
    },

    ### SEARCH OBJECT ###
    search_object: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object_name']
        when 'campaigns'
          call('search_campaigns_schema', '')
        when 'events'
          call('search_events_schema', '')
        when 'catalogs'
          call('search_catalogs_schema', '')
        when 'catalog_items'
          call('search_catalog_items_schema', '')
        else
          []
        end
      end
    },
    object_search_output: {
      fields: lambda do |_connection, config_fields|
        call('search_object_output', config_fields)
      end
    },

    ### RETRIEVE OBJECT ###
    get_object: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object_name']
        when 'user'
          call('get_user_schema', '')
        when 'catalog_item'
          call('get_catalog_item_schema', '')
        when 'email'
          call('get_email_schema', '')
        end
      end
    },
    object_get_output: {
      fields: lambda do |_connection, config_fields|
        call('get_object_output', config_fields)
      end
    },

    ### DELETE OBJECT ###
    delete_object: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object_name']
        when 'user'
          call('delete_user_schema', '')
        when 'catalog_item'
          call('delete_catalog_item_schema', '')
        end
      end
    },
    object_delete_output: {
      fields: lambda do |_connection, config_fields|
        call('delete_object_output', config_fields)
      end
    },

    ### SEND OBJECT ###
    send_object: {
      fields: lambda do |_connection, config_fields|
        call('send_schema', config_fields)
      end
    },
    object_send_output: {
      fields: lambda do |_connection, config_fields|
        call('send_object_output', config_fields)
      end
    },

    ### BULK UPSERT OBJECT ###
    bulk_upsert_object: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object_name']
        when 'users'
          call('bulk_upsert_user_schema', config_fields)
        end
      end
    },
    object_bulk_upsert_output: {
      fields: lambda do |_connection, config_fields|
        call('bulk_upsert_object_output', config_fields)
      end
    },

    ### BULK UPDATE OBJECT ###
    bulk_update_object: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object_name']
        when 'user_subscriptions'
          call('bulk_update_user_subscriptions_schema', config_fields)
        end
      end
    },
    object_bulk_update_output: {
      fields: lambda do |_connection, config_fields|
        call('bulk_update_object_output', config_fields)
      end
    },

    ### EXPORT DATA OBJECT ###
    export_data_object: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object_name']
        when 'csv_json'
          call('export_data_csv_json_schema', config_fields)
        when 'user_events'
          call('export_data_user_events_schema', config_fields)
        end
      end
    },
    object_export_data_output: {
      fields: lambda do |_connection, config_fields|
        call('export_data_object_output', config_fields)
      end
    },

    ### OTHER OBJECT ###
    subscribe: {
      fields: lambda do |_connection, config_fields|
        subscription_group = config_fields&.dig('subscriptionGroup') || ''
        [
          {
            name: 'subscriptionGroup',
            label: 'Subscription group',
            control_type: 'select',
            pick_list: [
              %w[Email\ list emailList],
              %w[Message\ type messageType],
              %w[Message\ channel messageChannel]
            ],
            optional: false,
            extends_schema: true,
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'subscriptionGroup',
              label: 'Subscription group',
              type: 'string',
              control_type: 'text',
              optional: false,
              extends_schema: true,
              toggle_hint: 'Use custom value',
              hint: 'Valid values are: <b>emailList</b>, <b>messageType</b> or <b>messageChannel</b>'
            }
          },
          case subscription_group
          when 'emailList'
            {
              name: 'subscriptionGroupId',
              label: 'Email list',
              control_type: 'select',
              pick_list: 'project_lists',
              optional: false,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'subscriptionGroupId',
                label: 'Email list ID',
                type: 'string',
                control_type: 'text',
                optional: false,
                toggle_hint: 'Use custom value',
                hint: 'Please enter the Email list ID.'
              }
            }
          when 'messageType'
            {
              name: 'subscriptionGroupId',
              label: 'Message type',
              control_type: 'select',
              pick_list: 'message_types',
              optional: false,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'subscriptionGroupId',
                label: 'Message type ID',
                type: 'string',
                control_type: 'text',
                optional: false,
                toggle_hint: 'Use custom value',
                hint: 'Please enter the Message type ID.'
              }
            }
          when 'messageChannel'
            {
              name: 'subscriptionGroupId',
              label: 'Message channel',
              control_type: 'select',
              pick_list: 'channels',
              optional: false,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'subscriptionGroupId',
                label: 'Message channel ID',
                type: 'string',
                control_type: 'text',
                optional: false,
                toggle_hint: 'Use custom value',
                hint: 'Please enter the Message channel ID.'
              }
            }
          end,
          { name: 'userEmail', label: 'Email address', optional: false }
        ].compact
      end
    }
  },

  actions: {
    create_record: {
      description: lambda do |_input, pick_lists|
        "Create <span class='provider'>#{pick_lists['object_name']&.downcase || 'record'}" \
        "</span> in <span class='provider'>Iterable</span>"\
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'List' => 'Creates a new static list.',
          'Campaign' => 'Creates a new campaign.',
          'Event' => 'Events are created asynchronously and processed separately from single event ' \
            '(non-bulk) endpoint.',
          'Catalog' => 'Create a catalog. Each catalog in a project must have a unique name. <br> This ' \
          'feature needs to be enabled in your Iterable account. Please contact your  ' \
          'Iterable Customer success manager(CSM) for more information.'
        }[pick_lists['object_name']] || ''

        { body: help.present? ? help : 'Please select object from the list.' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          pick_list: 'create_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['create_object']
      end,
      execute: lambda do |_connection, input|
        payload = call('format_create_payload', input)&.compact
        post(call('create_endpoint', input), payload&.except('object_name')).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_create_output']
      end,
      sample_output: lambda do |_connection, input|
        call('sample_create_record', input) || []
      end
    },
    update_record: {
      description: lambda do |_input, pick_lists|
        "Update <span class='provider'>#{pick_lists['object_name']&.downcase || 'record'}" \
        "</span> in <span class='provider'>Iterable</span>"\
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'Catalog item' => ' Replace the specified catalog item in the given catalog. <br> ' \
            'It will be replaced by the value provided in the request body. Do not use periods in field names. <br> ' \
            'This feature needs to be enabled in your Iterable account. Please contact your  Iterable Customer ' \
            'success manager(CSM) for more information.',
          'User subscription' => 'Update user subscriptions. <br> <b>NOTE:</b> Overwrites existing data if ' \
            'the field is provided and not null.'
        }[pick_lists['object_name']] || ''

        { body: help.present? ? help : 'Please select object from the list.' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          pick_list: 'update_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['update_object']
      end,
      execute: lambda do |_connection, input|
        payload = call('format_update_payload', input)&.compact
        if input['object_name'] == 'user_subscription'
          post(call('update_endpoint', input), payload&.except('object_name')).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        else
          put(call('update_endpoint', input), payload&.except('object_name')).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_update_output']
      end,
      sample_output: lambda do |_connection, input|
        call('sample_update_record', input) || []
      end
    },
    upsert_record: {
      description: lambda do |_input, pick_lists|
        "Upsert <span class='provider'>#{pick_lists['object_name']&.downcase || 'record'}" \
        "</span> in <span class='provider'>Iterable</span>"\
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'User' => 'Update user data or adds a user if none exists. Data is merged, ' \
            'missing fields are not deleted. <br> ' \
            'Types of data fields must match the types sent in previous requests, ' \
            'across all data fields in the project.',
          'Catalog item' => 'Create or update the specified catalog item in the given catalog. <br> ' \
            'If the catalog item already exists, its fields will be updated with the values provided in the ' \
            'request body. <br> Previously existing fields not included in the request body will remain as is. ' \
            'Do not use periods in field names. <br> This feature needs to be enabled in your Iterable account. ' \
            'Please contact your  Iterable Customer success manager(CSM) for more information.'
        }[pick_lists['object_name']] || ''

        { body: help.present? ? help : 'Please select object from the list.' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          pick_list: 'upsert_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['upsert_object']
      end,
      execute: lambda do |_connection, input|
        payload = call('format_upsert_payload', input)&.compact
        case input['object_name']
        when 'user'
          post(call('upsert_endpoint', input), payload&.except('object_name')).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when 'catalog_item'
          patch(call('upsert_endpoint', input), payload&.except('object_name')).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_upsert_output']
      end,
      sample_output: lambda do |_connection, input|
        call('sample_upsert_record', input) || []
      end
    },
    search_record: {
      description: lambda do |_input, pick_lists|
        "Search <span class='provider'>#{pick_lists['object_name']&.downcase || 'record'}" \
        "</span> in <span class='provider'>Iterable</span>"\
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'Campaigns' => 'List campaigns in a project.',
          'Events' => 'Get events for a specific user.',
          'Channels' => 'Get all message channels within the project.',
          'Catalogs' => 'List catalog names in a project. <br> This feature needs ' \
          'to be enabled in your Iterable account. Please contact your  Iterable ' \
          'Customer success manager(CSM) for more information.',
          'Catalog items' => 'Get the catalog items for a catalog. <br> This feature ' \
          'needs to be enabled in your Iterable account. Please contact your  Iterable ' \
          'Customer success manager(CSM) for more information.',
          'Lists' => 'Get all lists within a project.',
          'Message types' => 'List all message types within a project.'
        }[pick_lists['object_name']] || ''

        { body: help.present? ? help : 'Please select object from the list.' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          pick_list: 'search_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['search_object']
      end,
      execute: lambda do |_connection, input|
        params = call('format_search_params', input)&.compact
        response = get(call('search_endpoint', input), params).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end
        result = parse_json(response.to_json)
        result = call('format_unix_to_utc_time', result)
        case input['object_name']
        when 'catalogs'
          { catalogNames: result&.dig('params', 'catalogNames') }
        when 'catalog_items'
          { catalogItemsWithProperties: result&.dig('params', 'catalogItemsWithProperties') }
        else
          result
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_search_output']
      end,
      sample_output: lambda do |_connection, input|
        call('sample_search_record', input) || []
      end
    },
    retrieve_record: {
      description: lambda do |_input, pick_lists|
        "Retrieve <span class='provider'>#{pick_lists['object_name']&.downcase || 'record'}" \
        "</span> in <span class='provider'>Iterable</span>"\
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'User' => 'Get a user by their email address.',
          'Catalog item' => 'Get a specific catalog item from the given catalog. <br> ' \
          'This feature needs to be enabled in your Iterable account. Please contact ' \
          'your  Iterable Customer success manager(CSM) for more information.',
          'Email' => 'Retrieve a rendered version of a previously sent email in raw HTML format.'
        }[pick_lists['object_name']] || ''

        { body: help.present? ? help : 'Please select object from the list.' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          pick_list: 'get_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['get_object']
      end,
      execute: lambda do |_connection, input|
        params = call('format_get_params', input)&.compact
        response = if input['object_name'] == 'email'
                     get(call('get_endpoint', input), params).response_format_raw.
                       after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message}: #{body}")
                       end
                   else
                     get(call('get_endpoint', input), params).
                       after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message}: #{body}")
                       end
                   end
        if input['object_name'] == 'email'
          { content: response }
        else
          result = parse_json(response.to_json)
          result = call('format_unix_to_utc_time', result)
          case input['object_name']
          when 'user'
            result&.dig('user')
          when 'catalog_item'
            result&.dig('params')
          end
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_get_output']
      end,
      sample_output: lambda do |_connection, input|
        call('sample_get_record', input) || []
      end
    },
    delete_record: {
      description: lambda do |_input, pick_lists|
        "Delete <span class='provider'>#{pick_lists['object_name']&.downcase || 'record'}" \
        "</span> in <span class='provider'>Iterable</span>"\
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'User' => 'Deletes a specific user by email address.',
          'Catalog item' => 'Deletes the specified item from the catalog. Data may not be deleted immediately. <br> ' \
            'This feature needs to be enabled in your Iterable account. Please contact your  Iterable Customer ' \
            'success manager(CSM) for more information.'
        }[pick_lists['object_name']] || ''

        { body: help.present? ? help : 'Please select object from the list.' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          pick_list: 'delete_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['delete_object']
      end,
      execute: lambda do |_connection, input|
        params = call('format_delete_params', input)&.compact
        delete(call('delete_endpoint', input), params).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_delete_output']
      end,
      sample_output: lambda do |_connection, input|
        call('sample_delete_record', input) || []
      end
    },
    send_object: {
      description: lambda do |_input, pick_lists|
        "Send <span class='provider'>#{pick_lists['object_name']&.downcase || 'object'}" \
        "</span> in <span class='provider'>Iterable</span>"\
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'SMS notification' => 'Send an SMS notification to a specific user. <br> Request ' \
            'data fields will override user profile data fields.A reference to the user profile ' \
            'is provided via the <b>profile</b> field, to help resolve field collisions. <br> ' \
            'This feature needs to be enabled in your Iterable account. Please contact your  ' \
            'Iterable Customer success manager(CSM) for more information.',
          'Email' => 'Send an email to a specific email address. <br> Request data fields will ' \
            'override user profile data fields. A reference to the user profile is provided via ' \
            'the <b>profile</b> field, to help resolve field collisions.',
          'In-app notification' => 'Send an in-app notification to a specific user. <br> Request ' \
            'data fields will override user profile data fields. A reference to the user profile is ' \
            'provided via the <b>profile</b> field, to help resolve field collisions.',
          'Webpush notification' => 'Send an web push notification to a specific user. <br> Request ' \
            'data fields will override user profile data fields. A reference to the user profile is ' \
            'provided via the <b>profile</b> field, to help resolve field collisions.'
        }[pick_lists['object_name']] || ''

        { body: help.present? ? help : 'Please select object from the list.' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          pick_list: 'send_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['send_object']
      end,
      execute: lambda do |_connection, input|
        params = call('format_send_payload', input)&.compact
        post(call('send_endpoint', input), params).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_send_output']
      end,
      sample_output: lambda do |_connection, input|
        call('sample_send_record', input) || []
      end
    },
    bulk_upsert: {
      description: lambda do |_input, pick_lists|
        "Bulk upsert <span class='provider'>#{pick_lists['object_name']&.downcase || 'records'}" \
        "</span> in <span class='provider'>Iterable</span>"\
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'Users' => '<b>WARNING:</b> This will overwrite (instead of merging) existing data if ' \
            'the provided fields are not null.'
        }[pick_lists['object_name']] || ''

        { body: help.present? ? help : 'Please select object from the list.' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          pick_list: 'bulk_upsert_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['bulk_upsert_object']
      end,
      execute: lambda do |_connection, input|
        payload = call('format_bulk_upsert_payload', input)&.compact
        post(call('bulk_upsert_endpoint', input), payload&.except('object_name')).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_bulk_upsert_output']
      end,
      sample_output: lambda do |_connection, input|
        call('sample_bulk_upsert_record', input) || []
      end
    },
    bulk_update: {
      description: lambda do |_input, pick_lists|
        "Bulk upsert <span class='provider'>#{pick_lists['object_name']&.downcase || 'records'}" \
        "</span> in <span class='provider'>Iterable</span>"\
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'User subscriptions' => '<b>WARNING:</b> This will overwrite (instead of merging) existing ' \
            'data if the provided fields are not null.'
        }[pick_lists['object_name']] || ''

        { body: help.present? ? help : 'Please select object from the list.' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          pick_list: 'bulk_update_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['bulk_update_object']
      end,
      execute: lambda do |_connection, input|
        payload = call('format_bulk_update_payload', input)&.compact
        post(call('bulk_update_endpoint', input), payload&.except('object_name')).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_bulk_update_output']
      end,
      sample_output: lambda do |_connection, input|
        call('sample_bulk_update_record', input) || []
      end
    },
    subscribe_a_user: {
      title: 'Subscribe a user',
      description: 'Subscribe  a <span class="provider">user</span> to a group in' \
        ' <span class="provider">Iterable</span>',
      help: {
        body: 'Updates a user to be subscribed to the provided subscription group entity.'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['subscribe']
      end,
      execute: lambda do |_connection, input|
        patch("/api/subscriptions/#{input['subscriptionGroup']}/#{input['subscriptionGroupId']}/user/#{input['userEmail']}").
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'msg', label: 'Message' },
         { name: 'code' },
         { name: 'params', type: 'object' }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          "msg": 'Successfully enqueue subscription event for EmailList: 123 user: first.last@test.com',
          "code": 'Success',
          "params": 'null'
        }
      end

    },
    unsubscribe_a_user: {
      title: 'Unsubscribe a user',
      description: 'Unsubscribe  a <span class="provider">user</span> to a group in' \
        ' <span class="provider">Iterable</span>',
      help: {
        body: 'Updates a user to be unsubscribed to the provided subscription group entity.'
      },
      input_fields: lambda do |object_definitions|
        object_definitions['subscribe']
      end,
      execute: lambda do |_connection, input|
        delete("/api/subscriptions/#{input['subscriptionGroup']}/#{input['subscriptionGroupId']}/user/#{input['userEmail']}").
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'msg', label: 'Message' },
         { name: 'code' },
         { name: 'params', type: 'object' }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          "msg": 'Successfully enqueue subscription event for EmailList: 123 user: first.last@test.com',
          "code": 'Success',
          "params": 'null'
        }
      end

    },
    add_subscribers_to_list: {
      title: 'Add subscribers to list',
      description: 'Add <span class="provider">subscribers</span> to a list in' \
        ' <span class="provider">Iterable</span>',
      help: {
        body: 'Add specific subscribers to a list.'
      },
      input_fields: lambda do |object_definitions|
        [
          { name: 'listId', label: 'List',
            control_type: 'select',
            optional: false,
            pick_list: 'project_lists',
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
                { name: 'listId',
                  label: 'List ID',
                  type: :integer,
                  control_type: 'number',
                  optional: false,
                  stickty: true,
                  render_input: 'integer_conversion',
                  parse_output: 'integer_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'e.g. 296240' } },
          { name: 'subscribers', type: 'array', of: 'object',
            properties: [
              { name: 'email', control_type: 'email', label: 'Email address',
                sticky: true,
                hint: 'An email must be set unless a profile already exists' \
                ' with a userId set. In which case, a lookup from userId ' \
                'to email is performed.' },
              { name: 'userId',
                sticky: true, hint: 'Optional user ID, typically your ' \
                'database generated ID. Either email or user ID must be ' \
                'specified.' },
              { name: 'preferUserId', type: 'boolean', sticky: true,
                control_type: 'checkbox',
                hint: 'Create a new user with the specified user ID if ' \
                'the user does not exist yet.',
                toggle_hint: 'Select from list',
                toggle_field:
                    { name: 'preferUserId',
                      label: 'Prefer user ID',
                      type: :boolean,
                      control_type: 'text',
                      optional: true,
                      render_input: 'boolean_conversion',
                      toggle_hint: 'Use custom value',
                      hint: 'Allowed values are true or false' } },
              { name: 'mergeNestedObjects', type: 'boolean', sticky: true,
                control_type: 'checkbox',
                hint: 'Merge top level objects instead of overwriting',
                toggle_hint: 'Select from list',
                toggle_field:
                    { name: 'mergeNestedObjects',
                      label: 'Merge nested objects',
                      type: :boolean,
                      control_type: 'text',
                      optional: true,
                      render_input: 'boolean_conversion',
                      toggle_hint: 'Use custom value',
                      hint: 'Allowed values are true or false' } },
              { name: 'dataFields', type: 'object', extends_schema: true,
                properties: object_definitions['custom_input_schema'] }
            ] }
        ]
      end,
      execute: lambda do |_connection, input|
        subscribers_items = input.delete('subscribers').map do |items|
          items.map do |key, value|
            if ['dataFields'].include?(key)
              { key => value&.dig('input', 'data') }
            else
              { key => value }
            end
          end&.inject(:merge)
        end
        payload = { listId: input['listId'], subscribers: subscribers_items }

        post('/api/lists/subscribe').payload(payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |_object_definitions|
        [
          { name: 'successCount', type: 'integer' },
          { name: 'failCount', type: 'integer' },
          { name: 'invalidEmails', type: 'array' },
          { name: 'invalidUserIds', type: 'array', label: 'Invalid user IDs' }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        {
          successCount: 1,
          failCount: 0,
          invalidEmails: ['test@test.com'],
          invalidUserIds: ['000001']
        }
      end

    },
    export_data: {
      description: lambda do |_input, pick_lists|
        "Export <span class='provider'>#{pick_lists['object_name']&.downcase || 'data'}" \
        "</span> in <span class='provider'>Iterable</span>"\
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'CSV/JSON' => 'For CSV format - Export campaign analytics data in CSV format. ' \
            '<br> For JSON format - Export campaign analytics data in JSON format, one entry per ' \
            'line. <br> <b>Rate limit:</b> 4 requests/minute, per project.',
          'User events' => 'Export all events in JSON format for a user. One event per line.'
        }[pick_lists['object_name']] || ''

        { body: help.present? ? help : 'Please select object from the list.' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          pick_list: 'export_data_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['export_data_object']
      end,
      execute: lambda do |_connection, input|
        params = call('format_export_data_params', input&.compact)
        response = get(call('export_data_endpoint', input),
                       params&.except('object_name', 'export_format', 'export_report_raw')).
                   response_format_raw.
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end
        if input['export_report_raw'] == 'true' || input['object_name'] == 'user_events'
          { data: response }
        else
          result = response.gsub(/[\r\n]+/, '___').split('___')
          hash = {}
          rows = result.pop(result.length - 1).map do |items|
            items.split(',')
          end
          headers = result[0]&.split(',')
          parsed_csv = rows.map do |items|
            headers.zip(items) { |a, b| hash[a] = b }
            hash
          end
          { lines: parsed_csv }
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_export_data_output']
      end,
      sample_output: lambda do |_connection, input|
        call('sample_export_data_record', input) || []
      end
    }
  },

  webhook_keys: lambda do |_params, _headers, payload|
    payload['eventName'] || payload['workflowId']
  end,

  triggers: {
    new_object: {
      title: 'New object',
      description: 'New <span class="provider">system webhook event</span> in ' \
      '<span class="provider">Iterable</span>',
      help: {
        body: "Captures <a href='https://support.iterable.com/hc/en-us/" \
        "articles/208013936-System-Webhooks'>system webhook events</a> from" \
        ' Iterable. Configure Iterable to send webhooks to your Workato <b>' \
        "static webhook URI</b>, click <a href='https://www.workato.com/" \
        "custom_adapters'>here</a> for more details.",
        learn_more_url: 'https://support.iterable.com/hc/en-us/articles/' \
        '208013936-System-Webhooks',
        learn_more_text: 'System webhooks in Iterable'
      },
      input_fields: lambda do |object_definitions|
        [
          {
            name: 'eventName',
            label: 'Event name',
            control_type: 'select',
            pick_list: 'event_list',
            optional: false,
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'eventName',
              label: 'Event name',
              type: 'string',
              control_type: 'text',
              optional: false,
              toggle_hint: 'Use custom value',
              hint: 'For example: <b>emailOpen, smsBounce, etc</b>. For more' \
              " details click <a href='https://support.iterable.com/hc/" \
              "en-us/articles/208013936-System-Webhooks#emailOpen'>here</a>."
            }
          }
        ].concat(object_definitions['custom_output_schema']).compact
      end,

      webhook_key: lambda do |_connection, input|
        input['eventName']
      end,

      webhook_notification: lambda do |_connection, payload|
        payload
      end,

      dedup: lambda do |_payload|
        Time.now.to_f
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['custom_request_output']
      end
    },
    new_workflow: {
      title: 'New workflow',
      description: 'New <span class="provider">workflow event</span> in ' \
      '<span class="provider">Iterable</span>',
      help: {
        body: "Captures <a href='https://support.iterable.com/hc/en-us/" \
        "articles/205480275-Workflow-Webhooks-'>workflow webhook events</a> from" \
        ' Iterable. Configure Iterable to send webhooks to your Workato <b>' \
        "static webhook URI</b>, click <a href='https://www.workato.com/" \
        "custom_adapters'>here</a> for more details.",
        learn_more_url: 'https://support.iterable.com/hc/en-us/articles/205480275-Workflow-Webhooks-',
        learn_more_text: 'Workflow webhooks in Iterable'
      },
      input_fields: lambda do |object_definitions|
        [
          {
            name: 'workflowId',
            label: 'Workflow ID',
            control_type: 'number',
            type: 'integer',
            optional: false,
            help: 'You can find the workflow ID from the browser URL of the' \
            ' worklow ID is 44008 in https://app.iterable.com/workflows/44008/edit'
          }
        ].concat(object_definitions['custom_output_schema']).compact
      end,

      webhook_key: lambda do |_connection, input|
        input['workflowId']
      end,

      webhook_notification: lambda do |_connection, payload|
        payload
      end,

      dedup: lambda do |_payload|
        Time.now.to_f
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['custom_request_output']
      end
    }
  },

  pick_lists: {
    channels: ->(_connection) { get('/api/channels')&.dig('channels')&.pluck('name', 'id') },
    message_types: ->(_connection) { get('/api/messageTypes')&.dig('messageTypes')&.pluck('name', 'id') },
    campaigns: ->(_connection) { get('/api/campaigns')&.dig('campaigns')&.pluck('name', 'id') },
    project_lists: ->(_connection) { get('/api/lists')&.dig('lists')&.pluck('name', 'id') },
    event_list: lambda do |_connection|
      [
        ['Triggered/Blast send', 'emailSend'],
        ['Push send', 'pushSend'],
        ['Push send skip', 'pushSendSkip'],
        ['SMS send', 'smsSend'],
        ['SMS send skip', 'smsSendSkip'],
        ['Email open', 'emailOpen'],
        ['Email send skip', 'emailSendSkip'],
        ['Push open', 'pushOpen'],
        ['Email click', 'emailClick'],
        ['Hosted unsubscribe click', 'hostedUnsubscribeClick'],
        ['Email complaint (i.e. spam)', 'emailComplaint'],
        ['Push uninstall', 'pushUninstall'],
        ['SMS received', 'smsReceived'],
        ['Email bounce', 'emailBounce'],
        ['Push bounce', 'pushBounce'],
        ['SMS bounce', 'smsBounce'],
        ['Email subscribe', 'emailSubscribe'],
        ['Email unsubscribe', 'emailUnsubscribe'],
        ['In-App click', 'inAppClick'],
        ['In-App open', 'inAppOpen'],
        ['In-App send', 'inAppSend'],
        ['In-App send skip', 'inAppSendSkip'],
        ['Web push send', 'webPushSend'],
        ['Web push send skip', 'webPushSendSkip']
      ]
    end,
    locales: lambda do |_connection|
      [
        %w[None NONE], %w[Oromo om], %w[Abkhazian ab], %w[Afar aa],
        %w[Afrikaans af], %w[Albanian sq], %w[Amharic am], %w[Arabic ar],
        %w[Armenian hy], %w[Assamese as], %w[Aymara ay], %w[Azerbaijani az],
        %w[Bashkir ba], %w[Basque eu], %w[Bengali bn], %w[Bhutani dz],
        %w[Bihari bh], %w[Bislama bi], %w[Breton br], %w[Bulgarian bg],
        %w[Burmese my], %w[Byelorussian be], %w[Cambodian km], %w[Catalan ca],
        %w[Chinese zh], %w[Corsican co], %w[Croatian hr], %w[Czech cs],
        %w[Danish da], %w[Dutch nl], %w[English en], %w[Esperanto eo],
        %w[Estonian et], %w[Faeroese fo], %w[Fiji fj], %w[Finnish fi],
        %w[French fr], %w[Frisian fy], %w[Galician gl], %w[Georgian ka],
        %w[German de], %w[Greek el], %w[Greenlandic kl], %w[Guarani gn],
        %w[Gujarati gu], %w[Hausa ha], %w[Hebrew he], %w[Hindi hi],
        %w[Hungarian hu], %w[Icelandic is], %w[Indonesian id],
        %w[Interlingua ia], %w[Interlingue ie], %w[Inupiak ik],
        %w[Inuktitut iu], %w[Irish ga], %w[Italian it], %w[Japanese ja],
        %w[Javanese jw], %w[Kannada kn], %w[Kashmiri ks], %w[Kazakh kk],
        %w[Kinyarwanda rw], %w[Kirghiz ky], %w[Kirundi rn], %w[Korean ko],
        %w[Kurdish ku], %w[Laothian lo], %w[Latin la], %w[Latvian lv],
        %w[Lingala ln], %w[Lithuanian lt], %w[Macedonian mk], %w[Malagasy mg],
        %w[Malay ms], %w[Malayalam ml], %w[Maltese mt], %w[Maori mi],
        %w[Marathi mr], %w[Moldavian mo], %w[Mongolian mn], %w[Nauru na],
        %w[Nepali ne], %w[Norwegian no], %w[Occitan oc], %w[Oriya or],
        %w[Pashto ps], %w[Persian fa], %w[Polish pl], %w[Portuguese pt],
        %w[Punjabi pa], %w[Quechua qu], %w[Rhaeto-Romance rm],
        %w[Romanian ro], %w[Russian ru], %w[Samoan sm], %w[Sangro sg],
        %w[Sanskrit sa], %w[Scots Gaelic gd], %w[Serbian sr],
        %w[Serbo-Croatian sh], %w[Sesotho st], %w[Setswana tn], %w[Shona sn],
        %w[Sindhi sd], %w[Singhalese si], %w[Siswati ss], %w[Slovak sk],
        %w[Slovenian sl], %w[Somali so], %w[Spanish es], %w[Sudanese su],
        %w[Swahili sw], %w[Swedish sv], %w[Tagalog tl], %w[Tajik tg],
        %w[Tamil ta], %w[Tatar tt], %w[Tegulu te], %w[Thai th], %w[Tibetan bo],
        %w[Tigrinya ti], %w[Tonga to], %w[Tsonga ts], %w[Turkish tr],
        %w[Turkmen tk], %w[Twi tw], %w[Uigur ug], %w[Ukrainian uk],
        %w[Urdu ur], %w[Uzbek uz], %w[Vietnamese vi], %w[Volapuk vo],
        %w[Welch cy], %w[Wolof wo], %w[Xhosa xh], %w[Yiddish yi],
        %w[Yoruba yo], %w[Zhuang za], %w[Zulu zu]
      ]
    end,
    send_mode: lambda do |_connection|
      [
        %w[Project\ time\ zone ProjectTimeZone],
        %w[Recipient\ time\ zone RecipientTimeZone]
      ]
    end,
    timezones: lambda do |_connection|
      [
        %w[Africa/Abidjan Africa/Abidjan],
        %w[Africa/Accra Africa/Accra],
        %w[Africa/Algiers Africa/Algiers],
        %w[Africa/Bissau Africa/Bissau],
        %w[Africa/Cairo Africa/Cairo],
        %w[Africa/Casablanca Africa/Casablanca],
        %w[Africa/Ceuta Africa/Ceuta],
        %w[Africa/El_Aaiun Africa/El_Aaiun],
        %w[Africa/Johannesburg Africa/Johannesburg],
        %w[Africa/Juba Africa/Juba],
        %w[Africa/Khartoum Africa/Khartoum],
        %w[Africa/Lagos Africa/Lagos],
        %w[Africa/Maputo Africa/Maputo],
        %w[Africa/Monrovia Africa/Monrovia],
        %w[Africa/Nairobi Africa/Nairobi],
        %w[Africa/Ndjamena Africa/Ndjamena],
        %w[Africa/Tripoli Africa/Tripoli],
        %w[Africa/Tunis Africa/Tunis],
        %w[Africa/Windhoek Africa/Windhoek],
        %w[America/Adak America/Adak],
        %w[America/Anchorage America/Anchorage],
        %w[America/Araguaina America/Araguaina],
        %w[America/Argentina/Buenos_Aires America/Argentina/Buenos_Aires],
        %w[America/Argentina/Catamarca America/Argentina/Catamarca],
        %w[America/Argentina/Cordoba America/Argentina/Cordoba],
        %w[America/Argentina/Jujuy America/Argentina/Jujuy],
        %w[America/Argentina/La_Rioja America/Argentina/La_Rioja],
        %w[America/Argentina/Mendoza America/Argentina/Mendoza],
        %w[America/Argentina/Rio_Gallegos America/Argentina/Rio_Gallegos],
        %w[America/Argentina/Salta America/Argentina/Salta],
        %w[America/Argentina/San_Juan America/Argentina/San_Juan],
        %w[America/Argentina/San_Luis America/Argentina/San_Luis],
        %w[America/Argentina/Tucuman America/Argentina/Tucuman],
        %w[America/Argentina/Ushuaia America/Argentina/Ushuaia],
        %w[America/Asuncion America/Asuncion],
        %w[America/Atikokan America/Atikokan],
        %w[America/Bahia America/Bahia],
        %w[America/Bahia_Banderas America/Bahia_Banderas],
        %w[America/Barbados America/Barbados],
        %w[America/Belem America/Belem],
        %w[America/Belize America/Belize],
        %w[America/Blanc-Sablon America/Blanc-Sablon],
        %w[America/Boa_Vista America/Boa_Vista],
        %w[America/Bogota America/Bogota],
        %w[America/Boise America/Boise],
        %w[America/Cambridge_Bay America/Cambridge_Bay],
        %w[America/Campo_Grande America/Campo_Grande],
        %w[America/Cancun America/Cancun],
        %w[America/Caracas America/Caracas],
        %w[America/Cayenne America/Cayenne],
        %w[America/Chicago America/Chicago],
        %w[America/Chihuahua America/Chihuahua],
        %w[America/Costa_Rica America/Costa_Rica],
        %w[America/Creston America/Creston],
        %w[America/Cuiaba America/Cuiaba],
        %w[America/Curacao America/Curacao],
        %w[America/Danmarkshavn America/Danmarkshavn],
        %w[America/Dawson America/Dawson],
        %w[America/Dawson_Creek America/Dawson_Creek],
        %w[America/Denver America/Denver],
        %w[America/Detroit America/Detroit],
        %w[America/Edmonton America/Edmonton],
        %w[America/Eirunepe America/Eirunepe],
        %w[America/El_Salvador America/El_Salvador],
        %w[America/Fort_Nelson America/Fort_Nelson],
        %w[America/Fortaleza America/Fortaleza],
        %w[America/Glace_Bay America/Glace_Bay],
        %w[America/Godthab America/Godthab],
        %w[America/Goose_Bay America/Goose_Bay],
        %w[America/Grand_Turk America/Grand_Turk],
        %w[America/Guatemala America/Guatemala],
        %w[America/Guayaquil America/Guayaquil],
        %w[America/Guyana America/Guyana],
        %w[America/Halifax America/Halifax],
        %w[America/Havana America/Havana],
        %w[America/Hermosillo America/Hermosillo],
        %w[America/Indiana/Indianapolis America/Indiana/Indianapolis],
        %w[America/Indiana/Knox America/Indiana/Knox],
        %w[America/Indiana/Marengo America/Indiana/Marengo],
        %w[America/Indiana/Petersburg America/Indiana/Petersburg],
        %w[America/Indiana/Tell_City America/Indiana/Tell_City],
        %w[America/Indiana/Vevay America/Indiana/Vevay],
        %w[America/Indiana/Vincennes America/Indiana/Vincennes],
        %w[America/Indiana/Winamac America/Indiana/Winamac],
        %w[America/Inuvik America/Inuvik],
        %w[America/Iqaluit America/Iqaluit],
        %w[America/Jamaica America/Jamaica],
        %w[America/Juneau America/Juneau],
        %w[America/Kentucky/Louisville America/Kentucky/Louisville],
        %w[America/Kentucky/Monticello America/Kentucky/Monticello],
        %w[America/La_Paz America/La_Paz],
        %w[America/Lima America/Lima],
        %w[America/Los_Angeles America/Los_Angeles],
        %w[America/Maceio America/Maceio],
        %w[America/Managua America/Managua],
        %w[America/Manaus America/Manaus],
        %w[America/Martinique America/Martinique],
        %w[America/Matamoros America/Matamoros],
        %w[America/Mazatlan America/Mazatlan],
        %w[America/Menominee America/Menominee],
        %w[America/Merida America/Merida],
        %w[America/Metlakatla America/Metlakatla],
        %w[America/Mexico_City America/Mexico_City],
        %w[America/Miquelon America/Miquelon],
        %w[America/Moncton America/Moncton],
        %w[America/Monterrey America/Monterrey],
        %w[America/Montevideo America/Montevideo],
        %w[America/Nassau America/Nassau],
        %w[America/New_York America/New_York],
        %w[America/Nipigon America/Nipigon],
        %w[America/Nome America/Nome],
        %w[America/Noronha America/Noronha],
        %w[America/North_Dakota/Beulah America/North_Dakota/Beulah],
        %w[America/North_Dakota/Center America/North_Dakota/Center],
        %w[America/North_Dakota/New_Salem America/North_Dakota/New_Salem],
        %w[America/Ojinaga America/Ojinaga],
        %w[America/Panama America/Panama],
        %w[America/Pangnirtung America/Pangnirtung],
        %w[America/Paramaribo America/Paramaribo],
        %w[America/Phoenix America/Phoenix],
        %w[America/Port_of_Spain America/Port_of_Spain],
        %w[America/Port-au-Prince America/Port-au-Prince],
        %w[America/Porto_Velho America/Porto_Velho],
        %w[America/Puerto_Rico America/Puerto_Rico],
        %w[America/Punta_Arenas America/Punta_Arenas],
        %w[America/Rainy_River America/Rainy_River],
        %w[America/Rankin_Inlet America/Rankin_Inlet],
        %w[America/Recife America/Recife],
        %w[America/Regina America/Regina],
        %w[America/Resolute America/Resolute],
        %w[America/Rio_Branco America/Rio_Branco],
        %w[America/Santarem America/Santarem],
        %w[America/Santiago America/Santiago],
        %w[America/Santo_Domingo America/Santo_Domingo],
        %w[America/Sao_Paulo America/Sao_Paulo],
        %w[America/Scoresbysund America/Scoresbysund],
        %w[America/Sitka America/Sitka],
        %w[America/St_Johns America/St_Johns],
        %w[America/Swift_Current America/Swift_Current],
        %w[America/Tegucigalpa America/Tegucigalpa],
        %w[America/Thule America/Thule],
        %w[America/Thunder_Bay America/Thunder_Bay],
        %w[America/Tijuana America/Tijuana],
        %w[America/Toronto America/Toronto],
        %w[America/Vancouver America/Vancouver],
        %w[America/Whitehorse America/Whitehorse],
        %w[America/Winnipeg America/Winnipeg],
        %w[America/Yakutat America/Yakutat],
        %w[America/Yellowknife America/Yellowknife],
        %w[Antarctica/Casey Antarctica/Casey],
        %w[Antarctica/Davis Antarctica/Davis],
        %w[Antarctica/DumontDUrville Antarctica/DumontDUrville],
        %w[Antarctica/Macquarie Antarctica/Macquarie],
        %w[Antarctica/Mawson Antarctica/Mawson],
        %w[Antarctica/Palmer Antarctica/Palmer],
        %w[Antarctica/Rothera Antarctica/Rothera],
        %w[Antarctica/Syowa Antarctica/Syowa],
        %w[Antarctica/Troll Antarctica/Troll],
        %w[Antarctica/Vostok Antarctica/Vostok],
        %w[Asia/Almaty Asia/Almaty],
        %w[Asia/Amman Asia/Amman],
        %w[Asia/Anadyr Asia/Anadyr],
        %w[Asia/Aqtau Asia/Aqtau],
        %w[Asia/Aqtobe Asia/Aqtobe],
        %w[Asia/Ashgabat Asia/Ashgabat],
        %w[Asia/Atyrau Asia/Atyrau],
        %w[Asia/Baghdad Asia/Baghdad],
        %w[Asia/Baku Asia/Baku],
        %w[Asia/Bangkok Asia/Bangkok],
        %w[Asia/Barnaul Asia/Barnaul],
        %w[Asia/Beirut Asia/Beirut],
        %w[Asia/Bishkek Asia/Bishkek],
        %w[Asia/Brunei Asia/Brunei],
        %w[Asia/Chita Asia/Chita],
        %w[Asia/Choibalsan Asia/Choibalsan],
        %w[Asia/Colombo Asia/Colombo],
        %w[Asia/Damascus Asia/Damascus],
        %w[Asia/Dhaka Asia/Dhaka],
        %w[Asia/Dili Asia/Dili],
        %w[Asia/Dubai Asia/Dubai],
        %w[Asia/Dushanbe Asia/Dushanbe],
        %w[Asia/Famagusta Asia/Famagusta],
        %w[Asia/Gaza Asia/Gaza],
        %w[Asia/Hebron Asia/Hebron],
        %w[Asia/Ho_Chi_Minh Asia/Ho_Chi_Minh],
        %w[Asia/Hong_Kong Asia/Hong_Kong],
        %w[Asia/Hovd Asia/Hovd],
        %w[Asia/Irkutsk Asia/Irkutsk],
        %w[Asia/Jakarta Asia/Jakarta],
        %w[Asia/Jayapura Asia/Jayapura],
        %w[Asia/Jerusalem Asia/Jerusalem],
        %w[Asia/Kabul Asia/Kabul],
        %w[Asia/Kamchatka Asia/Kamchatka],
        %w[Asia/Karachi Asia/Karachi],
        %w[Asia/Kathmandu Asia/Kathmandu],
        %w[Asia/Khandyga Asia/Khandyga],
        %w[Asia/Kolkata Asia/Kolkata],
        %w[Asia/Krasnoyarsk Asia/Krasnoyarsk],
        %w[Asia/Kuala_Lumpur Asia/Kuala_Lumpur],
        %w[Asia/Kuching Asia/Kuching],
        %w[Asia/Macau Asia/Macau],
        %w[Asia/Magadan Asia/Magadan],
        %w[Asia/Makassar Asia/Makassar],
        %w[Asia/Manila Asia/Manila],
        %w[Asia/Novokuznetsk Asia/Novokuznetsk],
        %w[Asia/Novosibirsk Asia/Novosibirsk],
        %w[Asia/Omsk Asia/Omsk],
        %w[Asia/Oral Asia/Oral],
        %w[Asia/Pontianak Asia/Pontianak],
        %w[Asia/Pyongyang Asia/Pyongyang],
        %w[Asia/Qatar Asia/Qatar],
        %w[Asia/Qyzylorda Asia/Qyzylorda],
        %w[Asia/Riyadh Asia/Riyadh],
        %w[Asia/Sakhalin Asia/Sakhalin],
        %w[Asia/Samarkand Asia/Samarkand],
        %w[Asia/Seoul Asia/Seoul],
        %w[Asia/Shanghai Asia/Shanghai],
        %w[Asia/Singapore Asia/Singapore],
        %w[Asia/Srednekolymsk Asia/Srednekolymsk],
        %w[Asia/Taipei Asia/Taipei],
        %w[Asia/Tashkent Asia/Tashkent],
        %w[Asia/Tbilisi Asia/Tbilisi],
        %w[Asia/Tehran Asia/Tehran],
        %w[Asia/Thimphu Asia/Thimphu],
        %w[Asia/Tokyo Asia/Tokyo],
        %w[Asia/Tomsk Asia/Tomsk],
        %w[Asia/Ulaanbaatar Asia/Ulaanbaatar],
        %w[Asia/Urumqi Asia/Urumqi],
        %w[Asia/Ust-Nera Asia/Ust-Nera],
        %w[Asia/Vladivostok Asia/Vladivostok],
        %w[Asia/Yakutsk Asia/Yakutsk],
        %w[Asia/Yangon Asia/Yangon],
        %w[Asia/Yekaterinburg Asia/Yekaterinburg],
        %w[Asia/Yerevan Asia/Yerevan],
        %w[Atlantic/Azores Atlantic/Azores],
        %w[Atlantic/Bermuda Atlantic/Bermuda],
        %w[Atlantic/Canary Atlantic/Canary],
        %w[Atlantic/Cape_Verde Atlantic/Cape_Verde],
        %w[Atlantic/Faroe Atlantic/Faroe],
        %w[Atlantic/Madeira Atlantic/Madeira],
        %w[Atlantic/Reykjavik Atlantic/Reykjavik],
        %w[Atlantic/South_Georgia Atlantic/South_Georgia],
        %w[Atlantic/Stanley Atlantic/Stanley],
        %w[Australia/Adelaide Australia/Adelaide],
        %w[Australia/Brisbane Australia/Brisbane],
        %w[Australia/Broken_Hill Australia/Broken_Hill],
        %w[Australia/Currie Australia/Currie],
        %w[Australia/Darwin Australia/Darwin],
        %w[Australia/Eucla Australia/Eucla],
        %w[Australia/Hobart Australia/Hobart],
        %w[Australia/Lindeman Australia/Lindeman],
        %w[Australia/Lord_Howe Australia/Lord_Howe],
        %w[Australia/Melbourne Australia/Melbourne],
        %w[Australia/Perth Australia/Perth],
        %w[Australia/Sydney Australia/Sydney],
        %w[Europe/Amsterdam Europe/Amsterdam],
        %w[Europe/Andorra Europe/Andorra],
        %w[Europe/Astrakhan Europe/Astrakhan],
        %w[Europe/Athens Europe/Athens],
        %w[Europe/Belgrade Europe/Belgrade],
        %w[Europe/Berlin Europe/Berlin],
        %w[Europe/Brussels Europe/Brussels],
        %w[Europe/Bucharest Europe/Bucharest],
        %w[Europe/Budapest Europe/Budapest],
        %w[Europe/Chisinau Europe/Chisinau],
        %w[Europe/Copenhagen Europe/Copenhagen],
        %w[Europe/Dublin Europe/Dublin],
        %w[Europe/Gibraltar Europe/Gibraltar],
        %w[Europe/Helsinki Europe/Helsinki],
        %w[Europe/Istanbul Europe/Istanbul],
        %w[Europe/Kaliningrad Europe/Kaliningrad],
        %w[Europe/Kiev Europe/Kiev],
        %w[Europe/Kirov Europe/Kirov],
        %w[Europe/Lisbon Europe/Lisbon],
        %w[Europe/London Europe/London],
        %w[Europe/Luxembourg Europe/Luxembourg],
        %w[Europe/Madrid Europe/Madrid],
        %w[Europe/Malta Europe/Malta],
        %w[Europe/Minsk Europe/Minsk],
        %w[Europe/Monaco Europe/Monaco],
        %w[Europe/Moscow Europe/Moscow],
        %w[Asia/Nicosia Asia/Nicosia],
        %w[Europe/Oslo Europe/Oslo],
        %w[Europe/Paris Europe/Paris],
        %w[Europe/Prague Europe/Prague],
        %w[Europe/Riga Europe/Riga],
        %w[Europe/Rome Europe/Rome],
        %w[Europe/Samara Europe/Samara],
        %w[Europe/Saratov Europe/Saratov],
        %w[Europe/Simferopol Europe/Simferopol],
        %w[Europe/Sofia Europe/Sofia],
        %w[Europe/Stockholm Europe/Stockholm],
        %w[Europe/Tallinn Europe/Tallinn],
        %w[Europe/Tirane Europe/Tirane],
        %w[Europe/Ulyanovsk Europe/Ulyanovsk],
        %w[Europe/Uzhgorod Europe/Uzhgorod],
        %w[Europe/Vienna Europe/Vienna],
        %w[Europe/Vilnius Europe/Vilnius],
        %w[Europe/Volgograd Europe/Volgograd],
        %w[Europe/Warsaw Europe/Warsaw],
        %w[Europe/Zaporozhye Europe/Zaporozhye],
        %w[Europe/Zurich Europe/Zurich],
        %w[Indian/Chagos Indian/Chagos],
        %w[Indian/Christmas Indian/Christmas],
        %w[Indian/Cocos Indian/Cocos],
        %w[Indian/Kerguelen Indian/Kerguelen],
        %w[Indian/Mahe Indian/Mahe],
        %w[Indian/Maldives Indian/Maldives],
        %w[Indian/Mauritius Indian/Mauritius],
        %w[Indian/Reunion Indian/Reunion],
        %w[Pacific/Apia Pacific/Apia],
        %w[Pacific/Auckland Pacific/Auckland],
        %w[Pacific/Bougainville Pacific/Bougainville],
        %w[Pacific/Chatham Pacific/Chatham],
        %w[Pacific/Chuuk Pacific/Chuuk],
        %w[Pacific/Easter Pacific/Easter],
        %w[Pacific/Efate Pacific/Efate],
        %w[Pacific/Enderbury Pacific/Enderbury],
        %w[Pacific/Fakaofo Pacific/Fakaofo],
        %w[Pacific/Fiji Pacific/Fiji],
        %w[Pacific/Funafuti Pacific/Funafuti],
        %w[Pacific/Galapagos Pacific/Galapagos],
        %w[Pacific/Gambier Pacific/Gambier],
        %w[Pacific/Guadalcanal Pacific/Guadalcanal],
        %w[Pacific/Guam Pacific/Guam],
        %w[Pacific/Honolulu Pacific/Honolulu],
        %w[Pacific/Kiritimati Pacific/Kiritimati],
        %w[Pacific/Kosrae Pacific/Kosrae],
        %w[Pacific/Kwajalein Pacific/Kwajalein],
        %w[Pacific/Majuro Pacific/Majuro],
        %w[Pacific/Marquesas Pacific/Marquesas],
        %w[Pacific/Nauru Pacific/Nauru],
        %w[Pacific/Niue Pacific/Niue],
        %w[Pacific/Norfolk Pacific/Norfolk],
        %w[Pacific/Noumea Pacific/Noumea],
        %w[Pacific/Pago_Pago Pacific/Pago_Pago],
        %w[Pacific/Palau Pacific/Palau],
        %w[Pacific/Pitcairn Pacific/Pitcairn],
        %w[Pacific/Pohnpei Pacific/Pohnpei],
        %w[Pacific/Port_Moresby Pacific/Port_Moresby],
        %w[Pacific/Rarotonga Pacific/Rarotonga],
        %w[Pacific/Tahiti Pacific/Tahiti],
        %w[Pacific/Tarawa Pacific/Tarawa],
        %w[Pacific/Tongatapu Pacific/Tongatapu],
        %w[Pacific/Wake Pacific/Wake],
        %w[Pacific/Wallis Pacific/Wallis]
      ]
    end,
    data_type_name: lambda do |_connection|
      [
        %w[Email\ send emailSend],
        %w[Email\ open emailOpen],
        %w[Email\ click emailClick],
        %w[Email\ complaint emailComplaint],
        %w[Email\ bounce emailBounce],
        %w[Email\ send\ skip emailSendSkip],
        %w[Hosted\ unsubscribe\ click hostedUnsubscribeClick],
        %w[Push\ send pushSend],
        %w[Push\ open pushOpen],
        %w[Push\ uninstall pushUninstall],
        %w[Push\ bounce pushBounce],
        %w[Push\ send\ skip pushSendSkip],
        %w[In\ app\ send inAppSend],
        %w[In\ app\ send\ skip inAppSendSkip],
        %w[In\ app\ open inAppOpen],
        %w[In\ app\ click inAppClick],
        %w[In\ app\ close inAppClose],
        %w[In\ app\ delete inAppDelete],
        %w[In\ app\ delivery inAppDelivery],
        %w[Inbox\ session inboxSession],
        %w[Inbox\ message\ impression inboxMessageImpression],
        %w[SMS\ send smsSend],
        %w[SMS\ bounce smsBounce],
        %w[SMS\ send\ skip smsSendSkip],
        %w[SMS\ received smsReceived],
        %w[Web\ push\ send webPushSend],
        %w[Web\ push\ send\ skip webPushSendSkip],
        %w[Web\ push\ click webPushClick],
        %w[Email\ subscribe emailSubscribe],
        %w[Email\ unsubscribe emailUnSubscribe],
        %w[Purchase purchase],
        %w[Custom\ event customEvent],
        %w[User user]
      ]
    end,
    create_object_list: lambda do |_connection|
      [
        %w[List list],
        %w[Campaign campaign],
        %w[Event event],
        %w[Catalog catalog]
      ]
    end,
    update_object_list: lambda do |_connection|
      [
        %w[Catalog\ item catalog_item],
        %w[User\ subscription user_subscription]
      ]
    end,
    upsert_object_list: lambda do |_connection|
      [
        %w[User user],
        %w[Catalog\ item catalog_item]
      ]
    end,
    search_object_list: lambda do |_connection|
      [
        %w[Campaigns campaigns],
        %w[Events events],
        %w[Channels channels],
        %w[Catalogs catalogs],
        %w[Catalog\ items catalog_items],
        %w[Lists lists],
        %w[Message\ types message_types]
      ]
    end,
    get_object_list: lambda do |_connection|
      [
        %w[User user],
        %w[Catalog\ item catalog_item],
        %w[Email email]
      ]
    end,
    delete_object_list: lambda do |_connection|
      [
        %w[User user],
        %w[Catalog\ item catalog_item]
      ]
    end,
    send_object_list: lambda do |_connection|
      [
        %w[SMS\ notification sms],
        %w[Email email],
        %w[Webpush\ notification webpush],
        %w[In-app\ notification in_app]
      ]
    end,
    bulk_upsert_object_list: lambda do |_connection|
      [
        %w[Users users]
      ]
    end,
    bulk_update_object_list: lambda do |_connection|
      [
        %w[User\ subscriptions user_subscriptions]
      ]
    end,
    export_data_object_list: lambda do
      [
        %w[CSV/JSON csv_json],
        %w[User\ events user_events]
      ]
    end
  }
}
