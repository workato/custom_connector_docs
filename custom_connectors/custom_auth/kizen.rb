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
    
    format_payload: lambda do |payload|
      if payload.is_a?(Array)
        payload.map do |array_value|
          call('format_payload', array_value)
        end
      elsif payload.is_a?(Hash)
        payload.map do |key, value|
          key = call('inject_special_characters', key)
          if value.is_a?(Array) || value.is_a?(Hash)
            value = call('format_payload', value)
          end
          { key => value }
        end.inject(:merge)
      end
    end,
    
    format_schema: lambda do |schema|
      if schema.is_a?(Array)
        schema.map do |array_value|
          call('format_schema', array_value)
        end
      elsif schema.is_a?(Hash)
        schema.map do |key, value|
          if %w[name].include?(key.to_s)
            value = call('replace_special_characters', value.to_s)
          elsif %w[properties toggle_field].include?(key.to_s)
            value = call('format_schema', value)
          end
          { key => value }
        end.inject(:merge)
      end
    end,
    
    replace_special_characters: lambda do |input|
      input.gsub(/[-<>!@#$%^&*()+={}:;'"`~,.?|]/,
                 '-' => '__hyp__',
                 '<' => '__lt__',
                 '>' => '__gt__',
                 '!' => '__excl__',
                 '@' => '__at__',
                 '#' => '__hashtag__',
                 '$' => '__dollar__',
                 '%' => '__percent__',
                 '^' => '__pwr__',
                 '&' => '__amper__',
                 '*' => '__star__',
                 '(' => '__lbracket__',
                 ')' => '__rbracket__',
                 '+' => '__plus__',
                 '=' => '__eq__',
                 '{' => '__rcrbrack__',
                 '}' => '__lcrbrack__',
                 ';' => '__semicol__',
                 '\'' => '__apost__',
                 '`' => '__bckquot__',
                 '~' => '__tilde__',
                 ',' => '__comma__',
                 '.' => '__period__',
                 '?' => '__qmark__',
                 '|' => '__pipe__',
                 ':' => '__colon__',
                 '\"' => '__quote__')
    end,
    
    inject_special_characters: lambda do |input|
      input.gsub(
        /(__hyp__|__lt__|__gt__|__excl__|__at__|__hashtag__|__dollar__|\__percent__|__pwr__|__amper__|__star__|__lbracket__|__rbracket__|__plus__|__eq__|__rcrbrack__|__lcrbrack__|__semicol__|__apost__|__bckquot__|__tilde__|__comma__|__period__|__qmark__|__pipe__|__colon__|__quote__|__slash__|__bslash__)/,
        '__hyp__' => '-',
        '__lt__' => '<',
        '__gt__' => '>',
        '__excl__' => '!',
        '__at__' => '@',
        '__hashtag__' => '#',
        '__dollar__' => '$',
        '__percent__' => '%',
        '__pwr__' => '^',
        '__amper__' => '&',
        '__star__' => '*',
        '__lbracket__' => '(',
        '__rbracket__' => ')',
        '__plus__' => '+',
        '__eq__' => '=',
        '__rcrbrack__' => '{',
        '__lcrbrack__' => '}',
        '__semicol__' => ';',
        '__apost__' => '\'',
        '__bckquot__' => '`',
        '__tilde__' => '~',
        '__comma__' => ',',
        '__period__' => '.',
        '__qmark__' => '?',
        '__pipe__' => '|',
        '__colon__' => ':',
        '__quote__' => '"'
      )
    end,
    
    
    format_response: lambda do |payload|
      if payload.is_a?(Array)
        payload.map do |array_value|
          call('format_response', array_value)
        end
      elsif payload.is_a?(Hash)
        payload.map do |key, value|
          key = call('replace_special_characters', key)
          if value.is_a?(Array) || value.is_a?(Hash)
            value = call('format_response', value)
          end
          { key => value }
        end.inject(:merge)
      end
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

      
    log_activity_input: {
      fields: lambda do |_|
        custom_fields = get('/api/activity-type')&.
          map do |field|
            { name: "#{field['id']}~#{field['uid']}",
              label: field['name'], type: field['type'] }
          end
        standard_fields = [
          { name: 'client', label: 'Contact ID', optional: false },
          { name: 'activity_type_id',label: 'Activity', control_type: 'select', pick_list: 'activities', optional: false, toggle_hint: 'Select from list',
          toggle_field:{
            name: 'activity_id', label: 'Activity id', type: :string, control_type: "text", optional:false, toggle_hint: "Use Activity ID"}
           },
          { name: 'custom_fields',
            type: 'object', properties: custom_fields }
        ]
        call('format_schema', standard_fields)
      end
    },
    
    contact_fields_output: {
      fields: lambda do |_|
        custom_fields = get('/api/client-field')&.
          map do |field|
            { name: field['id'],
              label: field['name'], type: field['type'] }
          end
        standard_fields = [
          { name: 'id', type: 'integer', control_type: 'number',
            label: 'Contact id' },
          { name: 'first_name' },
          { name: 'last_name' },
          { name: 'email' },
          { name: 'mobile_phone' },
          { name: 'company',
            hint: 'The company at which the candidate currently works' },
          { name: 'titles', hint: 'The candidate’s current title' },
          { name: 'created', type: 'date_time', control_type: 'date_time' },
          { name: 'custom_fields',
            type: 'object', properties: custom_fields }
        ]
        call('format_schema', standard_fields)
      end
    },
    
    
    company_fields_trigger_output: {
      fields: lambda do |_|
        custom_fields = get('/api/company-field')&.
          map do |field|
            { name: field['handle'],
              label: field['name'], type: field['type'] }
          end
        standard_fields = [
          { name: 'id', type: 'integer', control_type: 'number',
            label: 'Company id' },
          { name: 'name',label: 'Company Name' },
          { name: 'business_phone' },
          { name: 'email' },
          { name: 'mobile_phone' },
          { name: 'custom', label: 'Custom fields',
            type: 'object', properties: custom_fields }
        ]
        call('format_schema', standard_fields)
      end
    },
    
    contact_fields_trigger_output: {
      fields: lambda do |_|
        custom_fields = get('/api/client-field')&.
          map do |field|
            { name: field['handle'],
              label: field['name'], type: field['type'] }
          end
        standard_fields = [
          { name: 'id',  label: 'Contact id' },
          { name: 'first_name' },
          { name: 'last_name' },
          { name: 'email' },
          { name: 'mobile_phone' },
          { name: 'company',
            hint: 'The company at which the candidate currently works' },
          { name: 'titles', hint: 'The candidate’s current title' },
          { name: 'created', type: 'date_time', control_type: 'date_time' },
          { name: 'custom', label: 'Custom fields',
            type: 'object', properties: custom_fields }
        ]
        call('format_schema', standard_fields)
      end
    },
    
    deal_fields_trigger_output: {
      fields: lambda do |_|
        custom_fields = get('/api/deal-custom-field')&.
          map do |field|
            { name: field['handle'],
              label: field['name'], type: field['type'] }
          end
        standard_fields = [
          { name: 'id', type: 'integer', control_type: 'number',
            label: 'Deal ID' },
          { name: 'name',label: 'Deal Name' },
          { name: 'amount',type: 'float' },
          { name: 'owner' },
          { name: 'stage' },
          { name: 'pipeline' },
          { name: 'custom', label: 'Custom fields',
            type: 'object', properties: custom_fields }
        ]
        call('format_schema', standard_fields)
      end
    },
    
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
    },
    log_interaction: { # This is new
      title: 'Log an interaction',
      subtitle: 'Log an interaction',
      description: lambda do
        "Log <span class='provider'>an interaction</span> in <span class='provider'>Kizen</span>"
      end,
      input_fields: lambda do
        [
          { name: 'client_id', Label: 'Contact ID', optional: false },
          { name: 'business_id', Label: 'Business ID', optional: false },
          { name: 'name', Label: 'Interaction Name', optional: false },
          { name: 'property_label1', Label: 'Property Label 1', optional: true },
          { name: 'property_label2', Label: 'Property Label 2', optional: true },
          { name: 'property_input1', Label: 'Property Input 1', optional: true },
          { name: 'property_input2', Label: 'Property Input 2', optional: true },
        ]
      end,
      execute: lambda do |_connection, input|
        post('https://app.kizen.com/api/interaction')
             .payload(
               'business_id': input['business_id'],
               'client_id': input['client_id'],
               'name': input['name'],
               'properties': {
                 "#{input["property_label1"]}"=> input["property_input1"],    
                 "#{input["property_label2"]}"=> input["property_input2"]}                  
             )
      end, 
      output_fields: lambda do
        [
          { name: 'id'}
        ]
      end,
    },

  add_custom_lead_source: { # This is new here
    title: 'Add Custom Lead Source to a Contact',
    subtitle: 'Add Custom Lead Source to a Contact',
    description: lambda do
      "Add <span class='provider'>Custom Lead Source</span> to a <span class='provider'>Contact</span>"
    end,

    input_fields: lambda do
      [
        { name: 'client_id', Label: 'Contact ID', optional: false },
        { name: 'source', 
          Label: 'Custom Lead Source', 
          control_type: 'select',
          pick_list: 'lead_sources',
          hint: 'To add Custom Lead Sources, navigate inside a contact record and add a custom source',
          optional: false},
        { name: 'campaign', Label: 'Campaign Name', optional: true },
        { name: 'medium', Label: 'Medium', optional: true },
        { name: 'term', Label: 'Term', optional: true },
        { name: 'content', Label: 'Content', optional: true }
      ]
    end,
    execute: lambda do |_connection, input|
      post('https://app.kizen.com/api/lead-source-custom-source')
           .payload(
             'client': input['client_id'],
             'source': input['source'],
             'campaign': input['campaign'],
             'medium': input['medium'],  
             'term': input['term'],  
             'content': input['content'],  
           )
    end, 

    output_fields: lambda do
      [
        { name: 'id' },
        { name: 'client', Label: 'Contact ID' }
      ]
    end,
  },
log_activity: { # This is new
  title: 'Log an Activity',
  subtitle: 'Log an Activity',
  description: lambda do
    "Log <span class='provider'>an activity</span> in <span class='provider'>Kizen</span>"
  end,

  input_fields: lambda do |object_definitions|
    object_definitions['log_activity_input']
  end,
      
  execute: lambda do |_connection, input|
    format_payload = call('format_payload', input)
    payload = format_payload.map do |key, value|
      if key.include?('custom_fields')
        custom_fields = value&.map do |k, v|
          { k.split('~').last =>
              {
                'field_id' => k.split('~').first,
                'value' => v
              } }
        end&.inject(:merge)
        { 'custom_fields' => custom_fields }
      else
        { key => value }
      end
    end.inject(:merge)
    result = post('/api/logged-activity', payload)
      
    formatted_response =
      result.map do |key, value|
        if key.include?('custom_fields')
          custom_fields = value.values&.map do |object|
            { object['field_id'] => object['value'] }
          end&.inject(:merge)
          { 'custom_fields' => custom_fields }
        else
          { key => value }
        end
      end&.inject(:merge)
    call('format_response', formatted_response.compact)
  end,
    
  output_fields: lambda do
    [
      { name: "id"}
    ]
  end,
},
find_contact_by_email: { # This is new
  title: 'Find contact by email',
  subtitle: 'Find a contact in Kizen by email',
  description: lambda do
    "Find a contact <span class='provider'>contact</span> in <span class='provider'>Kizen by email</span>"
  end,

  input_fields: lambda do 
    [
      {
        name: 'email',
        label: 'Contact Email',
        optional: false
      }
    ]
  end,
      
  execute: lambda do |connection, input|
    results = get("https://app.kizen.com/api/client?email=#{input["email"]}")
    records = results["results"]
    puts records
    {
      events: records
    }
  end,

  output_fields: lambda do |object_definitions|
    { name: "events", type: "array", of: "object",
      properties: object_definitions["contact_fields_trigger_output"] }
  end
},
find_contact_by_id: { # This is new
  title: 'Find contact by ID',
  subtitle: 'Find a contact in Kizen by ID',
  description: lambda do
    "Find a contact <span class='provider'>contact</span> in <span class='provider'>Kizen by ID</span>"
  end,
      
  input_fields: lambda do 
    [
      {
        name: 'id',
        label: 'Contact ID',
        optional: false
      }
    ]
  end,
      
  execute: lambda do |connection, input|
    result = get('https://app.kizen.com/api/client/#{input["id"]}')

    formatted_response =
      result.map do |key, value|
        if key.include?('custom_fields')
          custom_fields = value.values&.map do |object|
            { object['field_id'] => object['value'] }
          end&.inject(:merge)
          { 'custom_fields' => custom_fields }
        else
          { key => value }
        end
      end&.inject(:merge)
    call('format_response', formatted_response.compact)
  end,
    
  output_fields: lambda do |object_definitions|
    object_definitions['contact_fields_output']
  end
},
find_company_by_name: { # This is new
  title: 'Find company by name',
  subtitle: 'Find a company in Kizen by name',
  description: lambda do
    "Find a company <span class='provider'>contact</span> in Kizen"
  end,
      
  input_fields: lambda do 
    [
      {
        name: 'name',
        label: 'Company Name',
        optional: false
      }
    ]
  end,
      
  execute: lambda do |connection, input|
    results = get("https://app.kizen.com/api/company?search=#{input["name"]}")
    records = results["results"]
    puts records
    {
      events: records
    }
  end,
    
  output_fields: lambda do |object_definitions|
    { name: "events", type: "array", of: "object",
      properties: object_definitions["company_fields_trigger_output"] }
  end
},

find_deal_by_name: { # This is new
  title: 'Find deal by name',
  subtitle: 'Find a deal in Kizen by name',
  description: lambda do
    "Find a deal <span class='provider'>contact</span> in <span class='provider'>Kizen by name</span>"
  end,
      
  input_fields: lambda do 
    [
      {
        name: 'name',
        label: 'Deal Name',
        optional: false
      }
    ]
  end,
      
  execute: lambda do |connection, input|
    results = get("https://app.kizen.com/api/deal?search=#{input["name"]}")
    records = results["results"]
    puts records
    {
      events: records
    }
  end,

  output_fields: lambda do |object_definitions|
    { name: 'events', type: 'array', of: 'object',
      properties: object_definitions['deal_fields_trigger_output'] }
  end
},

create_order: { # This is new
  title: 'Create order',

  input_fields: lambda do
    [
      { name: 'email', optional: false },
      { name: 'order_status',
        optional: false, 
        control_type: "select",
        pick_list: "order_status" },
      { name: 'order_number', optional: false, hint: 'Must be an integer' },
      { name: 'created', optional: false, hint: '(YYYY-MM-DD)' },
      { name: 'sku', label: "SKU", optional: false },
      { name: 'name', optional: false, label: 'Product Name' },
      { name: 'price', optional: false },
      { name: 'quantity', 
        optional: false, 
        hint: 'This must be a number without decimal places. Example - 1.00 will not work.' }
    ]
  end,

  execute: lambda do |_connection, input|
    post('https://app.kizen.com/api/commerce/orders')
      .payload(
        'order_status': input['order_status'],
        'order_number': input['order_number'],
        'created': input['created'],
        'client': { 'email': input['email'] },
         'upload': true,
         'line_items': [
           { 'price': input['price'],
             'sku': input['sku'],
             'name': input['name'],
             'quantity': input['quantity'] }
         ]
      )
  end,

  output_fields: lambda do
    [
      { name: 'id' },
      { name: 'cart' },
      { name: 'client' }
    ]
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
    },
    new_order: {         
      title: 'New Order',
      subtitle: 'New Order in Kizen',
      description: lambda do
        "New <span class='provider'>Order</span> in <span class='provider'>Kizen</span>"
      end,

      poll: lambda do |_connection, _input, page|
        page_size = 50
        page ||= 1
        response = get('https://app.kizen.com/api/commerce/orders')
                   .params(order_by: 'created', 
                     order_type: 'asc',
                     page: page,
                     per_page: page_size
                   )
        records = response&.[]('results') || []
        page = records.size >= page_size ? page + 1 : 1 
        {
          events: records,
          next_page: page,
          can_poll_more: records.size >= page_size
        }
      end,
      
      dedup: lambda do |contact|
        contact['id']
      end,
      
      output_fields: lambda do
        [
          { name: 'id' },
          { name: 'client' },  
        ]
      end
    },

    new_scheduled_activity: { # I'm having trouble parsing the output
      title: 'New Scheduled Activity',
      subtitle: 'New Scheduled Activity in Kizen',
      description: lambda do
        "New <span class='provider'>scheduled activity in Kizen</span>"
      end,

      input_fields: lambda do
        [
          { name: 'activities',
            label: 'Activities',
            control_type: 'select',
            pick_list: 'activities',
            optional: false }
        ]
      end,

      poll: lambda do |_connection, input, page|
        page_size = 50
        activity_id = input['activities']
        page ||= 1
        response = get("https://app.kizen.com/api/scheduled-activity?activity_type=#{activity_id}")
                   .params(order_by: 'created',
                          order_type: 'asc',
                          page: page,
                          per_page: page_size)

        puts response
        records = response&.[]('results') || []
        page = records.size >= page_size ? page + 1 : page
        {
          events: records,
          next_page: page,
          can_poll_more: records.size >= page_size
        }
      end,

      dedup: lambda do |deal|
        deal['id']
      end,

      output_fields: lambda do
        [
          { name: 'id' },
          { name: 'assigned_to' },
          { name: 'client' }, # This is an array that needs to be split up.
          { name: 'company' }, # Need workato's help on this one.
          { name: 'deal' },
          { name: 'scheduled' }
        ]
      end

    },

updated_contact: {# This is new

  input_fields: ->() {
  },

  poll: ->(connection, input, last_updated_since) {
    updated_since = last_updated_since || input['since'] || Time.now

    contacts = get('https://app.kizen.com/api/client-field-revision')
               .params(
                 order_by: 'updated_at',
                 order_type: 'asc', 
                 per_page: 2,
                 updated_since: updated_since.to_time.utc.iso8601
               )
    contacts = contacts['results']

    next_updated_since = contacts.last['updated_at'] unless contacts.blank?

    {
      events: contacts,
      next_poll: next_updated_since,
      can_poll_more: contacts.length >= 2
    }
  },

  dedup: ->(contacts) {
    contacts['id']
  },

  output_fields: lambda do
    [
      {
        name: 'id'
      },
      {
        name: 'client'
      },
      {
        name: 'custom_field_name'
      },
      {
        name: 'custom_field'
      },
      {
        name: 'new_value'
      }
    ]
  end
},

new_logged_activity: {# I'm having trouble parsing the output on this
  title: 'New Logged Activity', # Will need help from Workato
  subtitle: 'New Logged Activity in Kizen',
  description: lambda do
    "New <span class='provider'>logged activity in Kizen"
  end,

  input_fields: lambda do
    [
      {
        name: 'activities',
        label: 'Activities',
        control_type: 'select',
        pick_list: 'activities',
        optional: false
      }
    ]
  end,
  # The output is an array that needs to be split up. How can I do this?
  # Need workato's help on this one
  poll: lambda do |_connection, input, page|
    page_size = 50
    activity_id = input['activities']
    puts activity_id
    page ||= 1
    response = get("https://app.kizen.com/api/logged-activity?activity_type_id=#{activity_id}")
               .params(
                 order_by: 'created',
                 order_type: 'asc',
                 page: page,
                 per_page: page_size
               )
    puts response
    records = response&.[]('results') || []
    page = records.size >= page_size ? page + 1 : page
    {
      events: records,
      next_page: page,
      can_poll_more: records.size >= page_size
    }
  end,

  dedup: lambda do |deal|
    deal['id']
  end,

  output_fields: lambda do
    [
      { name: 'id' },
      { name: 'activity_type' },
      { name: 'client' },
      { name: 'company' },
      { name: 'deal' },
      { name: 'employee' },
      { name: 'created' }
    ]
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
    
    activities: lambda do |_connection|
      url = 'https://app.kizen.com/api/activity-type?fields=id,name,created'
      get(url).pluck('name', 'id')
    end,

    lead_sources: lambda do |_connection|
      url = 'https://app.kizen.com/api/lead-source-custom-source-type'
      get(url)['results'].pluck('name', 'id')
    end,
    
    
    order_status: lambda do |_connection|
      [
        # Display name, value
        ['paid', 'paid']
      ]
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
