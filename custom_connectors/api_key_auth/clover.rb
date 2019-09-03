{
  title: 'Clover',

  methods: {
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
        hint: 'You can find the API Token by navigating to <b> Setup >> API ' \
          'Tokens</b>. Generate token, if there is not one already generated.',
        control_type: 'password',
        optional: false
      }
    ],

    base_uri: lambda do |connection|
      "https://#{connection['environment']}.clover.com"
    end,

    authorization: {
      type: 'api_key',

      apply: lambda { |connection|
        headers('Authorization' => "Bearer #{connection['api_key']}")
      }
    }
  },

  test: ->(connection) { get("/v3/merchants/#{connection['merchant_id']}") },

  object_definitions: {
    custom_action_input: {
      fields: lambda do |connection, config_fields|
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')

        [
          {
            name: 'path',
            optional: false,
            hint: "Base URI is <b>https://#{connection['environment']}" \
              '.clover.com</b> - path will be appended to this URI. ' \
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
                        properties: input_schema.
                          each { |field| field[:sticky] = true }
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

    employee: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'id',
            sticky: true,
            hint: 'Employee ID'
          },
          {
            name: 'name',
            sticky: true
          },
          { name: 'nickname' },
          { name: 'customId', hint: 'Custom ID of the employee' },
          { name: 'email' },
          {
            control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'inviteSent'
            },
            type: 'boolean',
            name: 'inviteSent'
          },
          {
            name: 'claimedTime',
            control_type: 'date_time',
            hint: 'Timestamp of when this employee claimed their account',
            type: 'number'
          },
          {
            label: 'PIN',
            hint: 'Employee PIN',
            name: 'pin'
          },
          {
            control_type: 'select',
            pick_list: 'roles',
            toggle_hint: 'Select from option list',
            toggle_field: {
              hint: "Valid values: 'EMPLOYEE', 'ADMIN', 'MANAGER', 'OWNER'",
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'string',
              name: 'role'
            },
            name: 'role'
          },
          {
            properties: [
              {
                name: 'elements',
                type: 'array',
                of: 'object',
                properties: [
                  {
                    label: 'HREF',
                    name: 'href'
                  },
                  { name: 'id' },
                  { name: 'name' },
                  { name: 'systemRole' },
                  {
                    properties: [{
                      name: 'id',
                      sticky: true
                    }],
                    label: 'Merchant',
                    type: 'object',
                    name: 'merchant'
                  }
                ]
              }
            ],
            type: 'object',
            name: 'roles'
          },
          {
            control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'isOwner'
            },
            type: 'boolean',
            hint: 'Select Yes if this employee is the owner account.',
            name: 'isOwner'
          },
          {
            properties: [{
              name: 'id',
              sticky: true
            }],
            type: 'object',
            name: 'shifts'
          },
          {
            properties: [
              {
                label: 'HREF',
                name: 'href'
              }
            ],
            type: 'object',
            name: 'orders'
          }
        ]
      end
    },

    shift: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          {
            properties: [
              {
                label: 'HREF',
                name: 'href'
              },
              {
                name: 'id',
                sticky: true
              },
              {
                properties: [
                  {
                    label: 'HREF',
                    name: 'href'
                  }
                ],
                type: 'object',
                name: 'orders'
              }
            ],
            type: 'object',
            name: 'employee'
          },
          {
            name: 'inTime',
            control_type: 'date_time',
            type: 'number'
          },
          {
            label: 'Out time',
            name: 'outTime',
            control_type: 'date_time',
            type: 'number'
          }
        ]
      end
    },

    search_shift: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id', sticky: true },
          { name: 'employee__id' },
          { name: 'employee__name', sticky: true },
          {
            name: 'in_time',
            hint: "Filter shifts with 'in_time' greater than " \
              'the mentioned time here',
            sticky: true,
            control_type: 'date_time',
            type: 'number'
          },
          {
            name: 'out_time',
            hint: "Filter shifts with 'out_time' lesser than " \
              'the mentioned time here',
            sticky: true,
            control_type: 'date_time',
            type: 'number'
          }
        ]
      end
    },

    create_shift: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'employee_id',
            label: 'Employee',
            control_type: 'select',
            optional: false,
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
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'inviteSent'
                },
                type: 'boolean',
                name: 'inviteSent'
              },
              {
                properties: [{ name: 'id' }],
                type: 'object',
                name: 'merchant'
              },
              {
                label: 'Custom ID',
                name: 'customId'
              },
              {
                name: 'employeeCards',
                type: 'array',
                of: 'object',
                label: 'Employee cards',
                properties: [
                  {
                    control_type: 'text',
                    label: 'ID',
                    type: 'string',
                    name: 'id'
                  }
                ]
              },
              {
                label: 'PIN',
                name: 'pin'
              },
              {
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'isOwner'
                },
                type: 'boolean',
                hint: 'Select Yes if this employee is the owner account.',
                name: 'isOwner'
              },
              {
                control_type: 'date_time',
                type: 'number',
                name: 'claimedTime'
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
                control_type: 'date_time',
                type: 'number',
                name: 'deletedTime'
              },
              { name: 'email' }
            ],
            type: 'object',
            name: 'overrideInEmployee',
            hint: 'The employee who overrode the clock in time'
          },
          {
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
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'inviteSent'
                },
                type: 'boolean',
                name: 'inviteSent'
              },
              {
                properties: [{ name: 'id' }],
                type: 'object',
                name: 'merchant'
              },
              { name: 'customId' },
              {
                name: 'employeeCards',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'pin' },
              {
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'isOwner'
                },
                type: 'boolean',
                hint: 'Select Yes if this employee is the owner account.',
                name: 'isOwner'
              },
              {
                control_type: 'date_time',
                type: 'number',
                name: 'claimedTime'
              },
              { name: 'name' },
              { name: 'nickname' },
              {
                name: 'shifts',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'unhashedPin' },
              {
                name: 'orders',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'id' },
              {
                control_type: 'date_time',
                type: 'number',
                name: 'deletedTime'
              },
              { name: 'email' }
            ],
            type: 'object',
            name: 'overrideOutEmployee',
            hint: 'The employee who overrode the clock out time'
          },
          {
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
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'inviteSent'
                },
                type: 'boolean',
                name: 'inviteSent'
              },
              {
                properties: [{ name: 'id' }],
                type: 'object',
                name: 'merchant'
              },
              { name: 'customId' },
              {
                name: 'employeeCards',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              { name: 'pin' },
              {
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'isOwner'
                },
                type: 'boolean',
                hint: 'Select Yes if this employee is the owner account.',
                name: 'isOwner'
              },
              {
                control_type: 'date_time',
                type: 'number',
                name: 'claimedTime'
              },
              { name: 'name' },
              { name: 'nickname' },
              {
                name: 'shifts',
                type: 'array',
                of: 'object',
                properties: [{ name: 'id' }]
              },
              {
                label: 'Unhashed PIN',
                name: 'unhashedPin'
              },
              {
                name: 'orders',
                type: 'array',
                of: 'object',
                label: 'Orders',
                properties: [
                  {
                    control_type: 'text',
                    label: 'ID',
                    type: 'string',
                    name: 'id'
                  }
                ]
              },
              { name: 'id' },
              {
                control_type: 'date_time',
                type: 'number',
                name: 'deletedTime'
              },
              { name: 'email' }
            ],
            type: 'object',
            name: 'employee',
            hint: 'The employee that worked this shift'
          },
          {
            name: 'inTime',
            sticky: true,
            control_type: 'date_time',
            type: 'number'
          },
          {
            name: 'overrideInTime',
            sticky: true,
            control_type: 'date_time',
            type: 'number',
            hint: 'Overridden clock in time'
          },
          {
            name: 'outTime',
            sticky: true,
            control_type: 'date_time',
            type: 'number'
          },
          {
            name: 'overrideOutTime',
            sticky: true,
            control_type: 'date_time',
            type: 'number',
            hint: 'Overridden clock out time'
          },
          {
            name: 'cashTipsCollected',
            sticky: true,
            control_type: 'integer',
            hint: 'Amount of cash tips collected',
            type: 'number'
          },
          {
            control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'serverBanking'
            },
            type: 'boolean',
            hint: 'Whether the employee used server banking',
            name: 'serverBanking'
          }
        ]
      end
    },

    orders: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            control_type: 'number', type: 'integer',
            name: 'clientCreatedTime'
          },
          {
            control_type: 'number', type: 'integer',
            name: 'createdTime'
          },
          { name: 'currency' },
          {
            properties: [{ name: 'id' }],
            type: 'object',
            name: 'employee'
          },
          {
            name: 'groupLineItems',
            type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'groupLineItems',
                type: 'boolean',
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' }
          },
          { name: 'href', label: 'HREF' },
          { name: 'id' },
          {
            name: 'isVat',
            type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'isVat',
                type: 'boolean',
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' }
          },
          {
            name: 'manualTransaction',
            type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'manualTransaction',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' }
          },
          {
            control_type: 'number',
            type: 'integer',
            name: 'modifiedTime'
          },
          {
            name: 'payType',
            control_type: 'select',
            pick_list: 'pay_type',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'payType',
                label: 'Pay type',
                type: :string,
                control_type: 'text',
                toggle_hint: 'Use custom value' }
          },
          { name: 'state' },
          {
            name: 'taxRemoved',
            type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'taxRemoved',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' }
          },
          {
            name: 'testMode',
            type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            toggle_field:
              { name: 'testMode',
                type: :boolean,
                control_type: 'text',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are true or false' }
          },
          {
            control_type: 'number',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'total'
          }
        ]
      end
    }
  },

  actions: {
    # Custom action for Clover
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
        "in <span class='provider'>Clover</span>",

      help: {
        body: 'Build your own Clover action with an HTTP request. The ' \
          'request will be authorized with your Clover connection.',
        learn_more_url: 'https://www.clover.com/api_docs',
        learn_more_text: 'Clover API Documentation'
      },

      execute: lambda do |_connection, input|
        verb = input['verb']
        error("#{verb} not supported") if %w[get post put delete].exclude?(verb)
        data = input.dig('input', 'data').presence || {}

        case verb
        when 'get'
          response =
            get(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact

          if response.is_a?(Array)
            array_name = parse_json(input['output'] || '[]').
                         dig(0, 'name') || 'array'
            { array_name.to_s => response }
          elsif response.is_a?(Hash)
            response
          else
            error('API response is not a JSON')
          end
        when 'post'
          post(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.compact
        when 'put'
          put(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.compact
        when 'delete'
          delete(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
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
        pick_list: %w[get post put delete].map { |verb| [verb.upcase, verb] }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['custom_action_input']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['custom_action_output']
      end
    },

    search_employees: {
      description: "Search <span class='provider'>employees</span> in " \
        "<span class='provider'>Clover</span>",
      help: 'Search will return results that match all your search criteria. ' \
        'Returns a maximum of 100 records.',

      execute: lambda do |connection, input|
        filter = input.map { |key, value| { key => (key + '=' + value).to_s } }.
                 inject(:merge)&.
                 to_param&.
                 gsub(/\w+\=/, 'filter=')

        {
          employees: get("/v3/merchants/#{connection['merchant_id']}/employees",
                         filter)['elements']
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['employee'].
          ignored('employeeCards', 'roles', 'payments', 'shifts', 'orders')
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
          employees: get("/v3/merchants/#{connection['merchant_id']}/employees",
                         limit: 1)['elements']
        }
      end
    },

    get_employee_by_id: {
      description: "Get <span class='provider'>employee</span> by ID " \
        "in <span class='provider'>Clover</span>",

      execute: lambda do |connection, input|
        get("/v3/merchants/#{connection['merchant_id']}" \
            "/employees/#{input['id']}")
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['employee'].only('id').required('id')
      end,

      output_fields: ->(object_definitions) { object_definitions['employee'] },

      sample_output: lambda do |connection, _input|
        get("/v3/merchants/#{connection['merchant_id']}/employees",
            limit: 1).dig('elements', 0) || {}
      end
    },

    create_employee: {
      description: "Create <span class='provider'>employee</span> " \
        "in <span class='provider'>Clover</span>",

      execute: lambda do |connection, input|
        input['claimedTime'] = if (claim_time = input['claimedTime']&.
        to_time&.to_i).present?
                                 claim_time * 1000
                               end
        post("/v3/merchants/#{connection['merchant_id']}/employees",
             input.compact).
          after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['employee'].
          ignored('employeeCards', 'id', 'roles', 'payments', 'shifts',
                  'orders').
          required('name')
      end,

      output_fields: ->(object_definitions) { object_definitions['employee'] },

      sample_output: lambda do |connection, _input|
        get("/v3/merchants/#{connection['merchant_id']}/employees",
            limit: 1).dig('elements', 0) || {}
      end
    },

    update_employee: {
      description: "Update <span class='provider'>employee</span> " \
        "in <span class='provider'>Clover</span>",

      execute: lambda do |connection, input|
        post("/v3/merchants/#{connection['merchant_id']}/employees" \
             "/#{input['id']}", input).
          after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['employee'].
          ignored('roles', 'payments', 'employeeCards', 'shifts', 'orders').
          required('id', 'name')
      end,

      output_fields: ->(object_definitions) { object_definitions['employee'] },

      sample_output: lambda do |connection, _input|
        get("/v3/merchants/#{connection['merchant_id']}/employees",
            limit: 1).dig('elements', 0) || {}
      end
    },

    search_shifts: {
      description: "Search <span class='provider'>shifts</span> in " \
        "<span class='provider'>Clover</span>",
      help: 'Search will return results that match all your search criteria. ' \
        'Returns a maximum of 100 records.',

      execute: lambda do |connection, input|
        in_time = if (in_time = input&.delete('in_time')&.to_time&.to_i).
                     present?
                    in_time * 1000
                  end
        out_time = if (out_time = input&.delete('out_time')&.to_time&.to_i).
                      present?
                     out_time * 1000
                   end
        filter = input.map do |key, value|
                   { key => (key.gsub(/__/, '.') + '=' + value).to_s }
                 end.inject(:merge)&.to_param
        range_filter = {
          in_time: in_time.present? ? "in_time>=#{in_time}" : nil,
          out_time: out_time.present? ? "out_time<=#{out_time}" : nil
        }.compact&.to_param
        filter = [filter, range_filter].smart_join('&').gsub(/\w+\=/, 'filter=')

        {
          shifts: get("/v3/merchants/#{connection['merchant_id']}/shifts",
                      filter).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end['elements']
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['search_shift']
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'shifts',
          type: 'array',
          of: 'object',
          properties: object_definitions['shift']
        }]
      end,

      sample_output: lambda do |connection, _input|
        {
          shifts: get("/v3/merchants/#{connection['merchant_id']}/shifts",
                      limit: 1)['elements']
        }
      end
    },

    create_shift: {
      description: "Create <span class='provider'>shift</span> " \
        "in <span class='provider'>Clover</span>",

      execute: lambda do |connection, input|
        employee_id = input.delete('employee_id')
        %w[inTime overrideInTime outTime overrideOutTime].each do |field|
          input[field] = if (time_field = input[field]&.to_time&.to_i).present?
                           time_field * 1000
                         end
        end
        input['outTime'] = if (out_time = input['outTime']&.to_time&.to_i).
                              present?
                             out_time * 1000
                           end
        post("/v3/merchants/#{connection['merchant_id']}/employees/" \
             "#{employee_id}/shifts", input.compact).
          after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['create_shift']
      end,

      output_fields: ->(object_definitions) { object_definitions['shift'] },

      sample_output: lambda do |connection, input|
        get("/v3/merchants/#{connection['merchant_id']}/employees/" \
            "#{input['employee_id']}/shifts", limit: 1).
          dig('elements', 0) || {}
      end
    }
  },

  triggers: {
    new_shift: {
      title: 'New shift',
      description: "New <span class='provider'>shift" \
        "</span> in <span class='provider'>Clover</span>",
      # API returns records by descending order of creation time.
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
        page_size = 100
        in_time = ((input['since'] || 1.hour.ago)&.to_time&.to_i) * 1000
        shifts = get("/v3/merchants/#{connection['merchant_id']}/employees/" \
                     "#{input['employee_id']}/shifts",
                     limit: page_size,
                     filter: "in_time>=#{in_time}",
                     offset: offset)['elements'] || []

        {
          events: shifts,
          next_page: shifts.size >= page_size ? (offset + page_size) : nil
        }
      end,

      dedup: ->(shift) { shift['id'] },

      output_fields: lambda do |object_definitions|
        object_definitions['shift'].ignored('employee_id')
      end,

      sample_output: lambda do |connection, input|
        get("/v3/merchants/#{connection['merchant_id']}/employees/" \
            "#{input['employee_id']}/shifts", limit: 1).
          dig('elements', 0) || {}
      end
    },

    new_updated_employee: {
      title: 'New/updated employee',
      description: "New/updated <span class='provider'>employee" \
        "</span> in <span class='provider'>Clover</span>",

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
          }
        ]
      end,

      poll: lambda do |connection, input, closure|
        offset = closure&.[]('offset') || 0
        page_size = 100
        since = closure&.[]('since') || ((input['since'] || 1.hour.ago)&.
                  to_time&.to_i) * 1000
        employees = get("/v3/merchants/#{connection['merchant_id']}/employees/",
                        limit: page_size,
                        orderBy: 'modifiedTime',
                        filter: "modifiedTime>=#{since}",
                        offset: offset)['elements'] || []

        more_pages = employees.length >= page_size
        closure = if more_pages
                    { 'offset' =>  offset + page_size, 'since' => since }
                  else
                    { 'offset' =>  0, 'since' => now }
                  end
        {
          events: employees,
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: lambda do |employee|
        "#{employee['id']}@#{employee['modifiedTime'] ||
        Time.now.to_time.to_i * 1000}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['employee']
      end,
      sample_output: lambda do |connection, _input|
        get("/v3/merchants/#{connection['merchant_id']}/employees/", limit: 1).
          dig('elements', 0) || {}
      end
    },

    new_updated_order: {
      title: 'New/updated order',
      description: "New or updated <span class='provider'>order" \
        "</span> in <span class='provider'>Clover</span>",

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
          }
        ]
      end,

      poll: lambda do |connection, input, closure|
        offset = closure&.[]('offset') || 0
        page_size = 100
        since = closure&.[]('since') || ((input['since'] || 1.hour.ago)&.
                  to_time&.to_i) * 1000
        orders = get("/v3/merchants/#{connection['merchant_id']}/orders",
                     limit: page_size,
                     orderBy: 'modifiedTime',
                     filter: "modifiedTime>=#{since}",
                     offset: offset)['elements'] || []

        more_pages = orders.length >= page_size
        closure = if more_pages
                    { 'offset' =>  offset + page_size, 'since' => since }
                  else
                    { 'offset' =>  0, 'since' => now }
                  end
        {
          events: orders,
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: lambda do |orders|
        "#{orders['id']}@#{orders['modifiedTime']}"
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['orders']
      end,
      sample_output: lambda do |connection, _input|
        get("/v3/merchants/#{connection['merchant_id']}/orders", limit: 1).
          dig('elements', 0) || {}
      end
    }
  },

  pick_lists: {
    employees: lambda do |connection|
      get("/v3/merchants/#{connection['merchant_id']}/employees")['elements']&.
        pluck('name', 'id')
    end,
    roles: lambda do |_connection|
      [
        %w[Employee EMPLOYEE],
        %w[Admin ADMIN],
        %w[Manager MANAGER],
        %w[Owner OWNER]
      ]
    end,
    pay_type: lambda do |_connection|
      [%w[Split\ guest SPLIT_GUEST], %w[Split\ item SPLIT_ITEM],
       %w[Split\ custom SPLIT_CUSTOM], %w[Full FULL]]
    end
  }
}
