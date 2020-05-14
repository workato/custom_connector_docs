{
  title: 'Kizen',

  connection: {
    fields: [
      {
        name: 'business_id',
        control_type: 'password',
        optional: false,
        hint: 'Found on the API keys settings page' \
        ' <a href="https://app.kizen.com/business/api-keys", ' \
        'target="_blank">here</a>'
      },
      {
        name: 'user_id',
        optional: false,
        hint: 'Found on the API keys settings page ' \
        '<a href="https://app.kizen.com/business/api-keys",' \
        ' target="_blank">here</a>'
      },
      {
        name: 'api_key',
        label: 'API key',
        control_type: 'password',
        optional: false,
        hint: 'Found on the API keys settings page ' \
        '<a href="https://app.kizen.com/business/api-keys", ' \
        ' target="_blank">here</a>'
      }
    ],

    authorization: {
      type: 'custom_auth',

      apply: lambda do |connection|
        headers('X-USER-ID': connection['user_id'],
                'X-API-KEY': connection['api_key'],
                'X-BUSINESS-ID': connection['business_id'])
      end
    },

    base_uri: lambda do
      'https://app.kizen.com'
    end
  },

  methods: {

    format_input: lambda do |input|
      if input['custom_fields'].present?
        input['custom_fields'] = input['custom_fields'].map do |key, value|
          key = key.gsub(/^f_/, '').gsub(/_/, '-')
          { key => value }
        end.inject(:merge)
      end
      input
    end,

    format_output: lambda do |result|
      if result['custom_fields'].present?
        result['custom_fields'] = result['custom_fields']
                                    &.values
                                    &.each_with_object({}) do |obj, h|
          h["f_#{obj['field_id'].gsub(/-/, '_')}"] = obj['value']
        end
      end
      result
    end,

    get_custom_fields: lambda do |url|
      get(url)&.
        map do |field|
          { name: "f_#{field['id'].gsub(/-/, '_')}",
            label: field['name'].labelize,
            type: field['type'],
            custom: true }
        end
    end,

    get_trigger_custom_fields: lambda do |url|
      get(url)&.
        map do |field|
          { name: field['handle'],
            label: field['name'].labelize,
            type: field['type'],
            custom: true }
        end
    end
  },

  object_definitions: {

    object_input: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object']
        when 'deal'
          [
            { name: 'name',
              label: 'Deal name',
              optional: false },
            { name: 'amount',
              type: 'integer',
              control_type: 'integer',
              label: 'Deal amount' },
            { name: 'owner',
              control_type: 'select',
              pick_list: 'owners',
              toggle_hint: 'Select from picklist',
              toggle_field: {
                name: 'owner',
                label: 'Owner',
                control_type: 'text',
                type: 'string',
                toggle_hint: 'Use custom value',
                optional: true
              } },
            { name: 'pipeline',
              label: 'Pipeline',
              control_type: 'select',
              pick_list: 'pipelines',
              optional: false,
              toggle_hint: 'Select from picklist',
              toggle_field: {
                name: 'pipeline',
                label: 'Pipeline',
                control_type: 'text',
                type: 'string',
                toggle_hint: 'Use custom value',
                optional: false
              } },
            { name: 'stage',
              control_type: 'select',
              pick_list: 'stages',
              pick_list_params: { pipeline: 'pipeline' },
              optional: false,
              toggle_hint: 'Select from picklist',
              toggle_field: {
                name: 'stage',
                label: 'Stage',
                control_type: 'text',
                type: 'string',
                toggle_hint: 'Use custom value',
                optional: false
              } },
            { name: 'reason_lost',
              control_type: 'select',
              pick_list: 'reason_losts',
              pick_list_params: { pipeline: 'pipeline' },
              toggle_hint: 'Select from picklist',
              toggle_field: {
                name: 'reason_lost',
                label: 'Reason lost',
                control_type: 'text',
                type: 'string',
                toggle_hint: 'Use custom value',
                optional: true
              } },
            { name: 'close_date',
              label: 'Close date',
              type: 'date_time',
              ontrol_type: 'date' },
            { name: 'estimated_close_date',
              label: 'Estimated close date',
              type: 'date_time',
              control_type: 'date' },
            { name: 'primary_client',
              label: 'Primary contact',
              control_type: 'select',
              pick_list: 'clients',
              toggle_hint: 'Select from picklist',
              toggle_field: {
                name: 'primary_client',
                label: 'Primary contact',
                control_type: 'text',
                type: 'string',
                toggle_hint: 'Use custom value',
                optional: true
              } },
            { name: 'primary_company',
              label: 'Primary company',
              control_type: 'select',
              pick_list: 'companies',
              toggle_hint: 'Select from picklist',
              toggle_field: {
                name: 'primary_company',
                label: 'Primary company',
                control_type: 'text',
                type: 'string',
                toggle_hint: 'Use custom value',
                optional: true
              } },
            { name: 'order', type: 'integer', control_type: 'integer' },
            { name: 'custom_fields',
              type: 'object',
              properties:
              call('get_custom_fields', '/api/deal-custom-field') }
          ]
        when 'company'
          [
            { name: 'name',
              label: 'Company name',
              sticky: true },
            { name: 'email', control_type: 'email' },
            { name: 'mobile_phone',
              label: 'Mobile phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'business_phone',
              label: 'Business phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'custom_fields',
              type: 'object',
              properties:
              call('get_custom_fields', '/api/company-field') }
          ]
        when 'client'
          [
            { name: 'first_name',
              label: 'First name',
              sticky: true },
            { name: 'last_name',
              label: 'Last name',
              sticky: true },
            { name: 'email',
              sticky: true,
              control_type: 'email' },
            { name: 'full_name', label: 'Full name' },
            { name: 'mobile_phone',
              label: 'Mobile phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'business_phone',
              label: 'Business phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'home_phone',
              label: 'Home phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'birthday',
              type: 'date',
              control_type: 'date' },
            { name: 'timezone' },
            { name: 'custom_fields',
              type: 'object',
              properties:
              call('get_custom_fields', '/api/client-field') }
          ]
        end
      end
    },

    object_output: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object']
        when 'deal'
          [
            { name: 'id', label: 'Deal ID' },
            { name: 'name', label: 'Deal name' },
            { name: 'amount',
              type: 'integer',
              control_type: 'integer',
              label: 'Deal amount' },
            { name: 'owner' },
            { name: 'primary_client' },
            { name: 'primary_company' },
            { name: 'close_date',
              type: 'date_time',
              control_type: 'date' },
            { name: 'estimated_close_date',
              type: 'date_time',
              control_type: 'date_time' },
            { name: 'created',
              label: 'Created date',
              type: 'date_time',
              control_type: 'date_time' },
            { name: 'updated',
              label: 'Updated date',
              type: 'date_time',
              control_type: 'date_time' },
            { name: 'stage' },
            { name: 'order', type: 'integer', control_type: 'integer' },
            { name: 'pipeline' },
            { name: 'status', type: 'integer', control_type: 'integer' },
            { name: 'reason_lost' },
            { name: 'companies', type: 'array', of: 'object', properties:
              [
                { name: 'name' }
              ] },
            { name: 'clients', type: 'array', of: 'object', properties:
              [
                { name: 'name' }
              ] },
            { name: 'custom_fields',
              type: 'object',
              properties:
              call('get_custom_fields', '/api/deal-custom-field') }
          ]
        when 'company'
          [
            { name: 'id', label: 'Company ID' },
            { name: 'name', label: 'Company name' },
            { name: 'email', control_type: 'email' },
            { name: 'mobile_phone',
              label: 'Mobile phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'business_phone',
              label: 'Business phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'addresses', type: 'array', of: 'object', properties:
              [
                { name: 'full_name' },
                { name: 'street_address_2' },
                { name: 'street_address' },
                { name: 'city' },
                { name: 'postal_code' },
                { name: 'state' },
                { name: 'country' }
              ] },
            { name: 'tags', type: 'array', of: 'object', properties:
              [
                { name: 'name' },
                { name: 'id' }
              ] },
            { name: 'domains', type: 'array', of: 'object', properties:
              [
                { name: 'name' },
                { name: 'id' }
              ] },
            { name: 'created',
              label: 'Created date',
              type: 'date_time',
              control_type: 'date_time' },
            { name: 'custom_fields',
              type: 'object',
              properties:
              call('get_custom_fields', '/api/company-field') }
          ]
        when 'client'
          [
            { name: 'id', label: 'Contact ID' },
            { name: 'first_name', label: 'First name' },
            { name: 'last_name', label: 'Last name' },
            { name: 'full_name', label: 'Full name' },
            { name: 'birthday', type: 'date' },
            { name: 'display_name', label: 'Display name' },
            { name: 'email', control_type: 'email' },
            { name: 'mobile_phone',
              label: 'Mobile phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'business_phone',
              label: 'Business phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'home_phone',
              label: 'Home phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'company',
              hint: 'The company at which the candidate currently works' },
            { name: 'titles',
              hint: 'The candidate’s current title',
              type: 'array',
              of: 'object',
              properties:
              [
                { name: 'name' },
                { name: 'id' }
              ] },
            { name: 'tags',
              type: 'array',
              of: 'object',
              properties:
              [
                { name: 'name' },
                { name: 'id' }
              ] },
            { name: 'timezone' },
            { name: 'email_status' },
            { name: 'email_is_blacklisted',
              type: 'boolean',
              control_type: 'checkbox' },
            { name: 'created',
              label: 'Created date', 
              type: 'date_time',
              control_type: 'date_time' },
            { name: 'custom_fields',
              type: 'object',
              properties:
              call('get_custom_fields', '/api/client-field') }
          ]
        end
      end
    },

    trigger_output: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object']
        when 'deal'
          [
            { name: 'id', label: 'Deal ID' },
            { name: 'name', label: 'Deal name' },
            { name: 'amount',
              type: 'integer',
              control_type: 'integer',
              label: 'Deal amount' },
            { name: 'owner' },
            { name: 'primary_client' },
            { name: 'primary_company' },
            { name: 'close_date',
              type: 'date_time',
              control_type: 'date' },
            { name: 'estimated_close_date',
              type: 'date_time',
              control_type: 'date_time' },
            { name: 'created',
              label: 'Created date',
              type: 'date_time',
              control_type: 'date_time' },
            { name: 'updated',
              label: 'Updated date',
              type: 'date_time',
              control_type: 'date_time' },
            { name: 'stage' },
            { name: 'order', type: 'integer', control_type: 'integer' },
            { name: 'pipeline' },
            { name: 'status', type: 'integer', control_type: 'integer' },
            { name: 'reason_lost' },
            { name: 'companies', type: 'array', of: 'object', properties:
              [
                { name: 'name' }
              ] },
            { name: 'clients', type: 'array', of: 'object', properties:
              [
                { name: 'name' }
              ] },
            { name: 'custom', label: 'Custom fields',
              type: 'object',
              properties:
              call('get_trigger_custom_fields', '/api/deal-custom-field') }
          ]
        when 'company'
          [
            { name: 'id', label: 'Company ID' },
            { name: 'name', label: 'Company name' },
            { name: 'email', control_type: 'email' },
            { name: 'mobile_phone',
              label: 'Mobile phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'business_phone',
              label: 'Business phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'addresses', type: 'array', of: 'object', properties:
              [
                { name: 'full_name' },
                { name: 'street_address_2' },
                { name: 'street_address' },
                { name: 'city' },
                { name: 'postal_code' },
                { name: 'state' },
                { name: 'country' }
              ] },
            { name: 'created', type: 'date_time', control_type: 'date_time' },
            { name: 'custom', label: 'Custom fields',
              type: 'object',
              properties:
              call('get_trigger_custom_fields', '/api/company-field') }
          ]
        when 'client'
          [
            { name: 'id', label: 'Contact ID' },
            { name: 'first_name', label: 'First name' },
            { name: 'last_name', label: 'Last name' },
            { name: 'full_name', label: 'Full name' },
            { name: 'birthday', type: 'date' },
            { name: 'display_name', label: 'Display name' },
            { name: 'email', control_type: 'email' },
            { name: 'mobile_phone',
              label: 'Mobile phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'business_phone',
              label: 'Business phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'home_phone',
              label: 'Home phone',
              type: 'integer',
              control_type: 'integer' },
            { name: 'company',
              hint: 'The company at which the candidate currently works' },
            { name: 'titles',
              hint: 'The candidate’s current title',
              type: 'array',
              of: 'object',
              properties:
                [
                  { name: 'name' },
                  { name: 'id' }
                ] },
            { name: 'tags',
              type: 'array',
              of: 'object',
              properties:
                [
                  { name: 'name' },
                  { name: 'id' }
                ] },
            { name: 'domains',
              type: 'array',
              of: 'object',
              properties:
                [
                  { name: 'name' },
                  { name: 'id' }
                ] },
            { name: 'timezone' },
            { name: 'email_status' },
            { name: 'email_is_blacklisted',
              type: 'boolean',
              control_type: 'checkbox' },
            { name: 'created', type: 'date_time', control_type: 'date_time' },
            { name: 'custom', label: 'Custom fields',
              type: 'object',
              properties:
              call('get_trigger_custom_fields', '/api/client-field') }
          ]
        end
      end
    }
  },

  test: -> { get('/api/client-list') },

  actions: {

    create_object: {
      title: 'Create object',
      subtitle: 'Create an object in Kizen',
      description: lambda do |_connection, objects|
        "Create <span class='provider'>" \
        "#{objects['object']&.downcase || 'object'}" \
        "</span> in <span class='provider'>Kizen</span>"
      end,
      help: lambda do |_, objects|
        "Create #{objects['object']&.downcase || 'object'} in Kizen."
      end,

      config_fields: [
        {
          name: 'object',
          label: 'Object',
          optional: false,
          pick_list: 'kizen_objects',
          control_type: :select,
          hint: 'Select the object from picklist.'
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['object_input'].ignored('id')
      end,

      execute: lambda do |_connection, input|
        payload = call('format_input', input)
        result = post("/api/#{input['object']}", payload)
                 .after_error_response(/.*/) do |_code, body, _header, message|
                   error("#{message}: #{body}")
                 end
        call('format_output', result)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['object_output']
      end,

      sample_output: lambda do |_connection, input|
        get("https://api.kizen.com/#{input['object']}?page=1&page_size=1")
          .dig('results', 0)
      end
    },

    update_object: {
      title: 'Update object',
      subtitle: 'Update an object in Kizen',
      description: lambda do |_connection, objects|
        "Update <span class='provider'>" \
        "#{objects['object']&.downcase || 'object'}</span>" \
        "in <span class='provider'>Kizen</span>"
      end,
      help: lambda do |_, objects|
        "Update #{objects['object']&.downcase || 'object'} in Kizen."
      end,

      config_fields: [
        {
          name: 'object',
          label: 'Object',
          optional: false,
          pick_list: 'kizen_objects',
          control_type: :select,
          hint: 'Select the object from picklist.'
        }
      ],

      input_fields: lambda do |object_definitions|
        [
          { name: 'id', sticky: true, optional: false }
        ].concat(object_definitions['object_input'])
      end,

      execute: lambda do |_connection, input|
        payload = call('format_input', input)
        result = put("/api/#{input['object']}/#{input['id']}", payload)
                 .after_error_response(/.*/) do |_code, body, _header, message|
                   error("#{message}: #{body}")
                 end
        call('format_output', result)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['object_output']
      end,

      sample_output: lambda do |_connection, input|
        get("https://api.kizen.com/#{input['object']}?page=1&page_size=1")
          .dig('results', 0)
      end
    }
  },

  triggers: {
    new_object: {
      title: 'New object',
      subtitle: 'New object in Kizen',
      description: lambda do |_connection, objects|
        "New <span class='provider'>" \
        "#{objects['object']&.downcase || 'object'}" \
        "</span> in <span class='provider'>Kizen</span>"
      end,
      help: lambda do |_, objects|
        "Triggers when #{objects['object']&.downcase || 'an object'} " \
        'is created in Kizen.'
      end,

      config_fields: [
        {
          name: 'object',
          label: 'Object',
          optional: false,
          pick_list: 'kizen_objects',
          control_type: :select,
          hint: 'Select the object from picklist.'
        },
        { ngIf: 'input.object == "deal"',
          name: 'pipeline',
          label: 'Pipeline',
          control_type: 'select',
          pick_list: 'pipelines',
          optional: true,
          sticky: true,
          hint: 'Required to filter deals.',
          toggle_hint: 'Select from picklist',
          toggle_field: {
            name: 'pipeline',
            label: 'Pipeline',
            control_type: 'text',
            type: 'string',
            toggle_hint: 'Use custom value',
            optional: true,
            sticky: true,
            hint: 'Required to filter deals.'
          } },
        {
          name: 'since',
          label: 'When first started, this recipe should pick up events from',
          type: 'timestamp',
          optional: true,
          sticky: true,
          since_field: true,
          hint: 'When you start recipe for the first time, it picks up ' \
                'trigger events from this specified date and time.<br> <b>' \
                'Once recipe has been run or tested, value cannot be changed.' \
                '</b> If left blank, trigger picks up events from 1 hour ago.'
        }
      ],

      poll: lambda do |_connection, input, closure|
        closure ||= {}
        page_size = 200
        page = 1
        query = {
          'version': 1,
          'filters': {
            'fields': [{
              'field': 'created',
              'condition': '>',
              'values': [
                (closure[:last_created_date].presence ||
                  input[:since].presence ||
                  1.hour.ago)
                  .to_time.utc.iso8601
              ]
            }]
          }
        }.to_json
        params = {
          'page' => page,
          'page_size' => page_size,
          'order_by' => 'created',
          'ordering' => 'created'
        }.merge(
          if input['object'] == 'deal'
            { 'group_config' => query, 'pipeline' => input['pipeline'] }
          else
            { 'contact_group_config' => query }
          end
        )
        response = get("https://app.kizen.com/api/#{input['object']}", params)
        records = response&.[]('results') || []
        closure[:last_created_date] = records.last['created']
        {
          events: records,
          next_poll: closure,
          can_poll_more: records.size >= page_size
        }
      end,

      dedup: lambda do |object|
        object['id']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['trigger_output']
      end,

      sample_output: lambda do |_connection, input|
        get("https://api.kizen.com/#{input['object']}?page=1&page_size=1")
          .dig('results', 0)
      end
    }
  },

  pick_lists: {
    pipelines: lambda do |_connection|
      get('/api/deal-pipeline')['results']&.map do |res|
        [res['name'].presence || 'unknown', res['id']]
      end
    end,

    companies: lambda do |_connection|
      get('/api/company')['results']&.map do |res|
        [res['name'].presence || 'unknown', res['id']]
      end
    end,

    clients: lambda do |_connection|
      get('/api/client')['results']&.map do |res|
        [res['display_name'].presence || 'unknown', res['id']]
      end
    end,

    stages: lambda do |_connection, pipeline|
      get("/api/deal-pipeline/#{pipeline}")['stages']&.map do |res|
        [res['name'].presence || 'unknown', res['id']]
      end
    end,

    reason_losts: lambda do |_connection, pipeline|
      get("/api/deal-pipeline/#{pipeline}")['reasons_lost']&.map do |res|
        [res['name'].presence || 'unknown', res['id']]
      end
    end,

    owners: lambda do |_connection|
      get('/api/team')&.map do |res|
        [res['full_name'].presence || 'unknown', res['id']]
      end
    end,

    kizen_objects: lambda do
      [
        %w[Deal deal],
        %w[Company company],
        %w[Contact client]
      ]
    end
  }
}
