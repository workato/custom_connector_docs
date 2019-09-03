{
  title: 'Gravity Forms',

  connection: {
    fields: [
      {
        name: 'consumer_key',
        optional: false,
        hint: 'Get your <b>consumer key</b> after creating your API key under' \
        ' Forms -> Settings -> REST API.'
      },
      {
        name: 'consumer_secret',
        optional: false,
        control_type: 'password',
        hint: 'Get your <b>consumer secret</b> after creating your API key ' \
        'under Forms -> Settings -> REST API.'
      },
      {
        name: 'domain',
        control_type: 'subdomain',
        hint: 'e.g. http://mydomain.com/wordpress or http://mydomain.com',
        optional: false,
        url: ''
      }
    ],

    authorization: {
      type: 'basic_auth',
      credentials: lambda do |connection|
        token = "#{connection['consumer_key']}:" \
        "#{connection['consumer_secret']}".encode_base64
        headers('Authorization': "Basic #{token}")
      end
    },
    base_uri: lambda do |connection|
      "https://#{connection['domain']}/wp-json/gf/v2/"
    end
  },
  methods: {
    compress_hash: lambda do |input|
      flat_fields = []
      input&.map do |field|
        if field[:type] == 'object'
          field[:properties]&.map do |property|
            flat_fields << property
          end
        else
          flat_fields << field
        end
      end
      flat_fields
    end,
    compress_labels: lambda do |input|
      input&.map do |key, value|
        if value.is_a?(Hash)
          value&.map do |k, v|
            { k => v }
          end&.inject(:merge)
        else
          { key => value }
        end
      end&.inject(:merge)
    end,
    format_schema_field_names: lambda do |input|
      input&.map do |field|
        if field[:properties].present?
          field[:properties] =
            call('format_schema_field_names', field[:properties])
        end
        if field[:name].to_s.include?('.')
          field[:name] = field[:name].gsub('.', '__dot__')
        end
        field
      end
    end,
    format_output_field_names: lambda do |input|
      if input['entries'].is_a?(Array)

        input['entries']&.map do |array_value|
          call('format_output_field_names',
               'entries' => array_value, 'labels' => input['labels'])
        end
      elsif input['entries'].is_a?(Hash)

        labels_hash = call('compress_labels', input['labels'])
        labels_array = "'#{labels_hash.pluck(0).join("','")}"

        input['entries']&.map do |key, value|
          if labels_array.include?(key)
            key = if key.to_s.include?('.')
                    key.gsub('.', '__dot__')
                  else
                    "id_#{key}"
                  end
          end
          { key => value }
        end&.inject(:merge)
      else
        input
      end
    end,
    format_input_field_names: lambda do |input|
      input&.map do |key, value|
        key = if key.to_s.include?('__dot__')
                key.gsub('__dot__', '.')
              elsif key.to_s.include?('id_')
                key.gsub('id_', '')
              else
                key
              end
        { key => value }
      end&.inject(:merge)
    end,
    build_object_field: lambda do |field|
      field['id'] = "id_#{field['id']}"
      element = {
        name: field['id'],
        label: field['label'] || field['type'],
        optional: %w[1 true].exclude?(field['isRequired'].to_s)
      }
      case field['type']
      when 'date'
        { type:  'date_time' }
      when 'number', 'quantity', 'total'
        { type:  'number' }
      when 'option', 'radio', 'list', 'quiz', 'select'
        choice_list = field['choices']&.map do |choice|
          [choice['text'], choice['value']]
        end
        { type: 'string', control_type: 'select',
          pick_list: choice_list,
          toggle_hint: 'Select from list',
          toggle_field: {
            name: field['id'],
            type: 'string',
            control_type: 'text',
            label: field['label'] || field['type'],
            toggle_hint: 'Use custom value'
          } }
      when 'multiselect'
        choice_list = field['choices']&.map do |choice|
          [choice['text'], choice['value']]
        end
        { type: 'string', control_type: 'multiselect',
          ddelimiter: ',', pick_list: choice_list }
      when 'name', 'product', 'time', 'address', 'password', 'survey'
        name_fields = field['inputs']&.
        map do |el|
          choice_list = el['choices']&.map do |choice|
            [choice['text'], choice['value']]
          end
          {
            name: el['id'],
            label: el['label'],
            type: 'string',
            control_type: el['choices'].present? ? 'select' : 'text',
            pick_list: el['choices'].present? ? choice_list : ''
          }
        end
        {
          type: 'object',
          properties: name_fields
        }
      else
        {}
      end&.merge(element)
    end,
    create_form_schema: lambda {
      [
        { name: 'title' },
        { name: 'description' },
        { name: 'labelPlacement' },
        { name: 'descriptionPlacement' },
        { name: 'fields', type: :array, of: :object, properties: [
          { name: 'type' },
          { name: 'id', label: 'Field ID' },
          { name: 'label' },
          { name: 'adminLabel' },
          { name: 'isRequired', control_type: 'checkbox',
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'isRequired',
              label: 'Is required',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'size', control_type: 'select',
            pick_list: 'sizes',
            toggle_hint: 'Select size',
            toggle_field: {
              name: 'size',
              label: 'Size',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: small, medium, large'
            } },
          { name: 'enableChoiceValue', control_type: 'checkbox',
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'enableChoiceValue',
              label: 'Enable choice value',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'errorMessage' },
          { name: 'visibility' },
          { name: 'inputs' },
          { name: 'formId', type: 'integer' },
          { name: 'description' },
          { name: 'allowsPrepopulate', control_type: 'checkbox',
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'allowsPrepopulate',
              label: 'Allows prepopulate',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'inputMask' },
          { name: 'inputMaskValue' },
          { name: 'inputType' },
          { name: 'labelPlacement' },
          { name: 'descriptionPlacement' },
          { name: 'subLabelPlacement' },
          { name: 'placeholder' },
          { name: 'cssClass' },
          { name: 'inputName' },
          { name: 'noDuplicates', control_type: 'checkbox',
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'noDuplicates',
              label: 'No duplicates',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'defaultValue' },
          { name: 'choices', type: 'array', of: :object, properties: [
            { name: 'text' },
            { name: 'value' },
            { name: 'isSelected ', control_type: 'checkbox',
              type: :boolean,
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Select from option list',
              toggle_field: {
                name: 'isSelected ',
                label: 'Is selected ',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false'
              } }
          ] },
          { name: 'conditionalLogic' },
          { name: 'content' },
          { name: 'productField', type: 'integer' },
          { name: 'enablePasswordInput', control_type: 'checkbox',
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'enablePasswordInput',
              label: 'Enable password input',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'maxLength', type: 'integer' },
          { name: 'multipleFiles' },
          { name: 'maxFiles' },
          { name: 'calculationFormula' },
          { name: 'calculationRounding' },
          { name: 'enableCalculation', control_type: 'checkbox',
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'enableCalculation',
              label: 'Enable calculation',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'disableQuantity', control_type: 'checkbox',
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'disableQuantity',
              label: 'Disable quantity',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'displayAllCategories', control_type: 'checkbox',
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'displayAllCategories',
              label: 'Display all categories',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true, false'
            } },
          { name: 'useRichTextEditor' },
          { name: 'pageNumber', type: 'integer' }
        ] },
        { name: 'version' },
        { name: 'id', label: 'Form ID' },
        { name: 'useCurrentUserAsAuthor', control_type: 'checkbox',
          type: :boolean,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'useCurrentUserAsAuthor',
            label: 'Use current user as author',
            type: 'integer',
            control_type: 'number',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: 0, 1'
          } },
        { name: 'postContentTemplateEnabled', control_type: 'checkbox',
          type: :boolean,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'postContentTemplateEnabled',
            label: 'Post content template enabled',
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false'
          } },
        { name: 'postTitleTemplateEnabled', control_type: 'checkbox',
          type: :boolean,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'postTitleTemplateEnabled',
            label: 'Post title template enabled',
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false'
          } },
        { name: 'postTitleTemplate' },
        { name: 'postContentTemplate' },
        { name: 'postAuthor', type: 'integer' },
        { name: 'postCategory', type: 'integer' },
        { name: 'postStatus',
          control_type: 'select',
          pick_list: 'post_statuses',
          optional: false,
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'postStatus',
            type: 'string',
            control_type: 'text',
            optional: false,
            toggle_hint: 'Use custom value',
            hint: 'Valid values are: draft, pending, publish'
          } },
        { name: 'lastPageButton' },
        { name: 'pagination' },
        { name: 'firstPageCssClass' },
        { name: 'subLabelPlacement' },
        { name: 'cssClass' },
        { name: 'enableHoneypot', control_type: 'checkbox',
          type: :boolean,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'enableHoneypot',
            label: 'Enable honeypot',
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false'
          } },
        { name: 'enableAnimation', control_type: 'checkbox',
          type: :boolean,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'enableAnimation',
            label: 'Enable animation',
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false'
          } },
        { name: 'limitEntries', control_type: 'checkbox',
          type: :boolean,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'limitEntries',
            label: 'Limit entries',
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false'
          } },
        { name: 'limitEntriesCount', type: 'integer' },
        { name: 'limitEntriesPeriod' },
        { name: 'limitEntriesMessage' },
        { name: 'scheduleForm', control_type: 'checkbox',
          type: :boolean,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'scheduleForm',
            label: 'Schedule form',
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false'
          } },
        { name: 'scheduleStart' },
        { name: 'scheduleStartHour', type: 'integer' },
        { name: 'scheduleStartMinute', type: 'integer' },
        { name: 'scheduleStartAmpm' },
        { name: 'scheduleEnd' },
        { name: 'scheduleEndHour', type: 'integer' },
        { name: 'scheduleEndMinute', type: 'integer' },
        { name: 'scheduleEndAmpm' },
        { name: 'scheduleMessage' },
        { name: 'requireLogin', control_type: 'checkbox',
          type: :boolean,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'requireLogin',
            label: 'Require login',
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false'
          } },
        { name: 'requireLoginMessage' },
        { name: 'nextFieldId', type: 'integer' },
        { name: 'is_active', control_type: 'checkbox',
          type: :boolean,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'is_active',
            label: 'Is active',
            type: 'integer',
            control_type: 'number',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: 0, 1'
          } },
        { name: 'date_created', type: 'date_time' },
        { name: 'is_trash', control_type: 'checkbox',
          type: :boolean,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'is_trash',
            label: 'Is trash',
            type: 'integer',
            control_type: 'number',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: 0, 1'
          } }
      ]
    }
  },

  object_definitions: {
    entry: {
      fields: lambda do |_connection, config|
        fields = get("forms/#{config['form_id']}")['fields']&.
        reject { |field| field['type'] == 'section' }&.
        map do |field|
          call('build_object_field', field)
        end
        call('compress_hash', call('format_schema_field_names', fields))
      end
    },
    form: {
      fields: lambda do |_connection, _config|
        call('create_form_schema')
      end
    },
    forms: {
      fields: lambda do |_connection|
        [
          { name: 'id', label: 'Form ID', type: 'integer' },
          { name: 'title' },
          { name: 'entries', type: 'integer' }
        ]
      end
    },
    custom_action_input: {
      fields: lambda do |connection, config_fields|
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')

        [
          {
            name: 'path',
            optional: false,
            hint: "Base URI is <b>https://#{connection['domain']}/wp-json/gf/" \
                  'v2/</b> - path will be appended to this URI. Use absolute ' \
                  'URI to override this base URI.'
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
                        properties:
                        input_schema.each { |field| field[:sticky] = true }
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
    create_standard_schema: {
      fields: lambda do |_connection|
        [
          { name: 'id', type: 'integer' },
          { name: 'form_id', type: 'integer', label: 'Form ID' },
          { name: 'post_id', type: 'integer', label: 'Post ID' },
          { name: 'date_created', type: 'date_time' },
          { name: 'date_updated', type: 'date_time' },
          { name: 'is_starred', control_type: 'select',
            pick_list: 'boolean_picklist',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'is_starred',
              label: 'Is starred',
              type: 'integer',
              control_type: 'integer',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 0, 1'
            } },
          { name: 'is_read', control_type: 'select',
            pick_list: 'boolean_picklist',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'is_read',
              label: 'Is read',
              type: 'integer',
              control_type: 'integer',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 0, 1'
            } },
          { name: 'ip', label: 'IP' },
          { name: 'source_url', label: 'Source URL' },
          { name: 'user_agent' },
          { name: 'currency', label: 'Currency code', control_type: 'select',
            pick_list: [%w[USD USD], %w[EUR EUR]],
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'currency',
              label: 'Currency code',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: USD, EUR'
            } },
          { name: 'payment_status', control_type: 'select',
            pick_list: 'payment_statuses',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'payment_status',
              label: 'Payment status',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: Authorized, Paid, ' \
              'Processing, Pending, Active, Expired, Failed, ' \
              'Cancelled, Approved, Reversed, Refunded, Voided'
            } },
          { name: 'payment_date', type: 'date_time' },
          { name: 'payment_amount', type: 'number' },
          { name: 'payment_method' },
          { name: 'transaction_id', label: 'Transaction ID' },
          { name: 'is_fulfilled', control_type: 'select',
            pick_list: 'boolean_picklist',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'is_fulfilled',
              label: 'Is fulfilled',
              type: 'integer',
              control_type: 'integer',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 0, 1'
            } },
          { name: 'created_by' },
          { name: 'transaction_type', label: 'Transaction type code',
            control_type: 'select',
            pick_list: 'transaction_types',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'transaction_type',
              label: 'Transaction type code',
              type: 'integer',
              control_type: 'number',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 1, 2. 1 for one time ' \
                'payments, 2 for subscriptions.'
            } },
          { name: 'status', control_type: 'select',
            pick_list: 'entry_status',
            toggle_hint: 'Select from options',
            toggle_field: {
              name: 'status',
              label: 'Status',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: active, spam, trash'
            } }
        ]
      end
    }
  },

  test: ->(_connection) { get('forms?include[1]') },

  actions: {
    get_entry: {
      description: "Get <span class='provider'>entry</span> by ID in" \
      ' Gravity Forms',
      help: {
        body: 'Gets an entry specified by entry ID.',
        learn_more_text: 'Get Entries by ID API',
        learn_more_url: 'https://docs.gravityforms.com/rest-api-v2/#get-entries-entry-id-'
      },
      config_fields: [
        {
          name: 'form_id',
          label: 'Form',
          control_type: 'select',
          pick_list: 'forms',
          optional: false,
          sticky: true,
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'form_id',
            label: 'Form ID',
            type: :integer,
            control_type: 'number',
            optional: false,
            toggle_hint: 'Use custom value',
            hint: 'Enter valid form ID only (e.g. 1)'
          }
        }
      ],
      input_fields: lambda { |_object_definitions|
        { name: 'entry_id', type: 'integer', control_type: 'integer',
          optional: false }
      },
      execute: lambda { |_connection, input|
        response = get("entries/#{input['entry_id']}?_labels=1").
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end
        labels = response.delete('_labels')
        call('format_output_field_names',
             'entries' => call('compress_labels', response), 'labels' => labels)
      },
      output_fields: lambda { |object_definitions|
        object_definitions['entry'].
          concat(object_definitions['create_standard_schema'])
      },
      sample_output: lambda { |_connection, input|
        response = get("entries?form_ids[0]=#{input['form_id']}&_labels=1")&.
        dig('entries', 0) || {}
        labels = response.delete('_labels')
        call('format_output_field_names',
             'entries' => call('compress_labels', response), 'labels' => labels)
      }
    },
    create_entry: {
      description: "Create <span class='provider'>entry</span> in" \
      ' Gravity Forms',
      help: {
        body: 'Creates a single entry.',
        learn_more_text: 'Create Entries API',
        learn_more_url: 'https://docs.gravityforms.com/rest-api-v2/#post-forms-form-id-entries'
      },
      config_fields: [
        {
          name: 'form_id', label: 'Form',
          control_type: 'select',
          pick_list: 'forms',
          optional: false,
          sticky: true,
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'form_id',
            label: 'Form ID',
            type: :integer,
            control_type: 'number',
            optional: false,
            toggle_hint: 'Use custom value',
            hint: 'Enter valid form ID only (e.g. 1)'
          }
        }
      ],
      input_fields: lambda { |object_definitions|
        object_definitions['entry']
      },
      execute: lambda { |_connection, input|
        entry = call('format_input_field_names', input)
        response = post("forms/#{entry.delete('form_id')}/entries", entry).
                   follow_redirection.
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end
        labels = get("forms/#{input.delete('form_id')}/" \
        'entries?_labels=1')['_labels']
        entry_hash = call('compress_labels', response)
        call('format_output_field_names',
             'entries' => entry_hash, 'labels' => labels)
      },
      output_fields: lambda { |object_definitions|
        object_definitions['create_standard_schema'].only('id', 'form_id').
          concat(object_definitions['entry'])
      },
      sample_output: lambda { |_connection, input|
        response = get("entries?form_ids[0]=#{input['form_id']}&_labels=1")&.
        dig('entries', 0) || {}
        labels = response.delete('_labels')
        call('format_output_field_names',
             'entries' => call('compress_labels', response), 'labels' => labels)
      }
    },
    update_entry: {
      description: "Update <span class='provider'>entry</span> in" \
      ' Gravity Forms',
      help: {
        body: 'Updates an entry based on the specified entry ID.<br/><b>Note:' \
        '</b> Fields with values not provided <b>WILL BE BLANKED OUT.</b>',
        learn_more_text: 'Update Entries API',
        learn_more_url: 'https://docs.gravityforms.com/rest-api-v2/#put-entries-entry-id-'
      },
      config_fields: [
        {
          name: 'form_id', label: 'Form',
          control_type: 'select',
          pick_list: 'forms',
          optional: false,
          sticky: true,
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'form_id',
            label: 'Form ID',
            type: :integer,
            control_type: 'number',
            optional: false,
            toggle_hint: 'Use custom value',
            hint: 'Enter valid form ID only (e.g. 1)'
          }
        }
      ],
      input_fields: lambda { |object_definitions|
        object_definitions['entry'].concat(
          object_definitions['create_standard_schema']
        ).required('id').ignored('date_created', 'date_updated')
      },
      execute: lambda { |_connection, input|
        entry = call('format_input_field_names', input)
        response = put("entries/#{entry.delete('id')}", entry).
                   follow_redirection.
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end
        labels = get("forms/#{input.delete('form_id')}/" \
        'entries?_labels=1')['_labels']
        entry_hash = call('compress_labels', response)
        call('format_output_field_names',
             'entries' => entry_hash, 'labels' => labels)
      },
      output_fields: lambda { |object_definitions|
        object_definitions['entry'].concat(
          object_definitions['create_standard_schema']
        )
      },
      sample_output: lambda { |_connection, input|
        response = get("entries?form_ids[0]=#{input['form_id']}&_labels=1")&.
        dig('entries', 0) || {}
        labels = response.delete('_labels')
        call('format_output_field_names',
             'entries' => call('compress_labels', response), 'labels' => labels)
      }
    },
    get_form_by_ID: {
      description: "Get a <span class='provider'>form</span> by ID in" \
      ' Gravity Forms',
      help: {
        body: 'Retrieves the details of a form based on form ID.',
        learn_more_text: 'Get Form API',
        learn_more_url: 'https://docs.gravityforms.com/rest-api-v2/#get-forms-form-id-'
      },
      input_fields: lambda { |object_definitions|
        object_definitions['form'].only('id').required('id')
      },
      execute: lambda { |_connection, input|
        get("forms/#{input['id']}").
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      },
      output_fields: lambda { |object_definitions|
        object_definitions['form']
      },
      sample_output: lambda { |_connection, _input|
        get('forms/1') || {}
      }
    },
    list_forms: {
      description: "List all <span class='provider'>forms</span> in" \
      ' Gravity Forms',
      help: {
        body: 'List the details of all forms.',
        learn_more_text: 'Form API',
        learn_more_url: 'https://docs.gravityforms.com/rest-api-v2/#get-forms'
      },
      execute: lambda { |_connection, _input|
        forms = get('forms')&.map do |items|
          items[1]&.map do |key, value|
            { key => value }
          end&.inject(:merge)
        end
        { forms: forms }
      },
      output_fields: lambda { |object_definitions|
        { name: 'forms', type: :array, of: :object,
          properties: object_definitions['forms'] }
      },
      sample_output: lambda { |_connection, _input|
        { forms: { 'id': 4, 'title': 'Multi-Page Form', 'entries': 2 } }
      }
    },
    search_entries: {
      description: "Search <span class='provider'>entries</span> in" \
      ' Gravity Forms',
      help: {
        body: 'Searches entries in Gravity Forms for the specified criteria.',
        learn_more_text: 'Get Entries API',
        learn_more_url: 'https://docs.gravityforms.com/rest-api-v2/#get-forms-form-id-entries'
      },
      config_fields: [
        {
          name: 'form_id', label: 'Form',
          control_type: 'select',
          pick_list: 'forms',
          optional: false,
          toggle_hint: 'Select form',
          toggle_field: {
            name: 'form_id',
            label: 'Form ID',
            type: :integer,
            control_type: 'integer',
            optional: false,
            toggle_hint: 'Use custom value',
            hint: 'Enter valid form ID only (e.g. 1)'
          }
        }
      ],
      input_fields: lambda { |_object_definitions|
        [
          { name: 'search', sticky: true, type: :object, properties: [
            { name: 'field_filters', type: :array, of: :object, properties: [
              { name: 'key', hint: 'The field ID' },
              { name: 'value', hint: 'The value to search for' },
              { name: 'operator', control_type: 'select',
                hint: 'The comparison operator to use',
                pick_list: 'operators',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'operator',
                  label: 'Operator',
                  type: 'string',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: 'Valid values are: is, isnot and contains'
                } }
            ] }
          ] },
          { name: 'sorting', type: :object, properties: [
            { name: 'key', type: 'integer',
              control_type: 'integer', hint: 'The key by which to sort.' },
            { name: 'direction', control_type: 'select',
              pick_list: 'directions',
              toggle_hint: 'Select from option list',
              toggle_field: {
                name: 'direction',
                label: 'Direction',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: ASC, DESC'
              } },
            { name: 'is_numeric', control_type: 'checkbox',
              type: :boolean, hint: 'If the key is numeric',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'is_numeric',
                label: 'Is numeric',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false'
              } }
          ] },
          { name: 'paging', type: :object, properties: [
            { name: 'page_size', type: 'integer',
              control_type: 'integer', hint: 'The number of results per page' },
            { name: 'current_page', type: 'integer',
              control_type: 'integer',
              hint: 'The current page from which to pull details.' },
            { name: 'offset', type: 'integer', control_type: 'integer',
              hint: 'The offset to begin with.' }
          ] }
        ]
      },
      execute: lambda { |_connection, input|
        searchfield = input.delete('search')
        response = get("forms/#{input.delete('form_id')}/entries?_labels=1").
                   params(input.merge(search: searchfield.to_s.gsub('=>', ':').
                   encode_url))
        entries = call('format_output_field_names',
                       'entries' => response['entries'] || [],
                       'labels' => response['_labels'])

        { entries: entries }
      },
      output_fields: lambda { |object_definitions|
        [
          {
            name: 'entries',
            type: :array, of: :object,
            properties: object_definitions['entry'].concat(
              object_definitions['create_standard_schema']
            )
          }
        ]
      },
      sample_output: lambda { |_connection, input|
        response = get("entries?form_ids[0]=#{input['form_id']}&_labels=1")&.
        dig('entries', 0) || {}
        labels = response.delete('_labels')
        { entries: call('format_output_field_names',
                        'entries' => call('compress_labels', response),
                        'labels' => labels) }
      }
    },
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
        "in <span class='provider'>Gravity Forms</span>",
      help: 'Build your own Gravity Forms action with a HTTP request.<br>' \
        "<a href='https://docs.gravityforms.com/category/developers/'" \
        "rest-api/ target='_blank'>Gravity Forms API documentation</a> ",

      config_fields: [{
        name: 'verb',
        label: 'Request type',
        hint: 'Select HTTP method of the request',
        optional: false,
        control_type: 'select',
        pick_list: %w[get post put delete].map { |v| [v.upcase, v] }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['custom_action_input']
      end,

      execute: lambda do |_connection, input|
        verb = input['verb']
        if %w[get post put patch delete].exclude?(verb)
          error("#{verb} not supported")
        end
        data = input.dig('input', 'data').presence || {}

        case verb
        when 'get'
          get(input['path'], data).
            after_error_response(/[3-9]\d\d/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when 'post'
          post(input['path'], data).
            after_error_response(/[3-9]\d\d/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when 'put'
          put(input['path'], data).
            after_error_response(/[3-9]\d\d/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when 'delete'
          delete(input['path'], data).
            after_error_response(/[3-9]\d\d/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['custom_action_output']
      end
    }
  },

  triggers: {
    new_entry: {
      description: "New <span class='provider'>entry</span> in " \
      "<span class='provider'>Gravity Forms</span>",
      help: {
        body: 'Triggers when a new entry is added in Gravity Form.',
        learn_more_url: 'https://docs.gravityforms.com/rest-api-v2/#get-entries',
        learn_more_text: 'Get Entries API'
      },
      type: :paging_desc,
      config_fields: [
        {
          name: 'form_id',
          label: 'Form',
          control_type: 'select',
          pick_list: 'forms',
          optional: false,
          toggle_hint: 'Select form',
          toggle_field: {
            name: 'form_id',
            label: 'Form ID',
            type: :integer,
            control_type: 'number',
            optional: false,
            toggle_hint: 'Use custom value',
            hint: 'Enter valid form ID only (e.g. 1)'
          }
        }
      ],
      poll: lambda do |_connection, input, page|
        page_size = 20
        page ||= 0
        offset = page * page_size
        response = get("forms/#{input['form_id']}/entries?_labels=1" \
          "&paging[page_size]=#{page_size}&paging[offset]=#{offset}" \
          '&sorting[key]=id&sorting[direction]=DESC')
        entries = call('format_output_field_names',
                       'entries' => response&.[]('entries'),
                       'labels' => response['_labels'])
        {
          events: entries,
          next_page: offset < response['total_count'] ? page + 1 : nil
        }
      end,
      document_id: ->(entry) { entry['id'] },
      sort_by: ->(entry) { entry['id'] },
      output_fields: ->(object_definitions) { object_definitions['entry'] },
      sample_output: lambda do |_connection, _input|
        form = get('forms')&.first
        get("entries?form_ids[0]=#{form['id']}")&.dig('entries', 0)
      end
    }
  },

  pick_lists: {
    forms: lambda { |_connection|
      get('forms').map do |_key, value|
        [value['title'], value['id'].to_s]
      end
    },
    operators: lambda { |_connection|
      [
        %w[is is],
        %w[is\ not isnot],
        %w[contains contains]
      ]
    },
    post_statuses: lambda { |_connection|
      [
        %w[Draft draft],
        %w[Pending pending],
        %w[Publish publish]
      ]
    },
    sizes: lambda { |_connection|
      [
        %w[Small small],
        %w[Medium medium],
        %w[Large large]
      ]
    },
    entry_status: lambda { |_connection|
      [
        %w[Active active],
        %w[Spam spam],
        %w[Trash trash]
      ]
    },
    payment_statuses: lambda { |_connection|
      [
        %w[Authorized Authorized],
        %w[Paid Paid],
        %w[Processing Processing],
        %w[Pending Pending],
        %w[Active Active],
        %w[Expired Expired],
        %w[Failed Failed],
        %w[Cancelled Cancelled],
        %w[Approved Approved],
        %w[Reversed Reversed],
        %w[Refunded Refunded],
        %w[Voided Voided]
      ]
    },
    transaction_types: lambda { |_connection|
      [
        ['One time payment', 1],
        ['Subscriptions', 2]
      ]
    },
    boolean_picklist: lambda { |_connection|
      [
        ['Yes', 1],
        ['No', 0]
      ]
    },
    directions: lambda { |_connection|
      [
        %w[Ascending ASC],
        %w[Descendiing DESC]
      ]
    }
  }
}
