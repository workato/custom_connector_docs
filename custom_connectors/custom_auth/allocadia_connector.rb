{
  title: 'Allocadia',

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
        name: 'username',
        hint: 'Allocadia app login username',
        optional: false
      },
      {
        name: 'password',
        hint: 'Allocadia app login password',
        optional: false,
        control_type: 'password'
      },
      {
        name: 'environment',
        default: 'api-staging',
        control_type: 'select',
        pick_list: [
          %w[North\ America api-na],
          %w[Europe api-ea],
          %w[Staging api-staging]
        ],
        optional: false
      }
    ],

    base_uri: lambda { |connection|
      "https://#{connection['environment']}.allocadia.com"
    },

    authorization: {
      type: 'custom_auth',

      acquire: lambda do |connection|
        post("https://#{connection['environment']}" \
            '.allocadia.com/v1/token',
             username: connection['username'],
             password: connection['password']).compact
      end,

      refresh_on: [400, 401],

      apply: lambda { |connection|
        headers('Authorization' => "token #{connection['token']}")
      }
    }
  },

  test: ->(_connection) { get('/v1/users')[0] },

  object_definitions: {
    custom_action_input: {
      fields: lambda do |connection, config_fields|
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')

        [
          {
            name: 'path',
            optional: false,
            hint: "Base URI is <b>https://#{connection['environment']}" \
              '.allocadia.com</b> - path will be appended to this URI. ' \
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

    budget: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            control_type: 'text',
            label: 'Notes',
            type: 'string',
            name: 'notes'
          },
          {
            control_type: 'checkbox',
            label: 'Folder',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Folder',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'folder'
            },
            type: 'boolean',
            name: 'folder'
          },
          {
            control_type: 'date_time',
            label: 'Created date',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'createdDate'
          },
          {
            name: '_links',
            type: 'array',
            of: 'object',
            label: 'Links',
            properties: [
              {
                control_type: 'text',
                label: 'Rel',
                type: 'string',
                name: 'rel'
              },
              {
                control_type: 'text',
                label: 'HREF',
                type: 'string',
                name: 'href'
              }
            ]
          },
          {
            control_type: 'text',
            label: 'Name',
            type: 'string',
            name: 'name'
          },
          {
            control_type: 'text',
            label: 'Currency',
            type: 'string',
            name: 'currency'
          },
          {
            sticky: true,
            control_type: 'text',
            label: 'ID',
            type: 'string',
            name: 'id'
          },
          {
            control_type: 'date_time',
            label: 'Updated date',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'updatedDate'
          },
          {
            control_type: 'text',
            label: 'Parent ID',
            type: 'string',
            name: 'parentId'
          }
        ]
      end
    },

    line_item: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            properties: [
              {
                control_type: 'text',
                label: 'Approval status',
                type: 'string',
                name: 'approvalStatus'
              },
              {
                control_type: 'text',
                label: 'Comment',
                type: 'string',
                name: 'comment'
              },
              {
                control_type: 'number',
                label: 'Value',
                parse_output: 'float_conversion',
                type: 'number',
                name: 'value'
              },
              {
                control_type: 'text',
                label: 'Tag ID',
                type: 'string',
                name: 'tagId'
              },
              {
                control_type: 'text',
                label: 'Column name',
                type: 'string',
                name: 'columnName'
              }
            ],
            label: 'Cells',
            type: 'array',
            of: 'object',
            name: 'cells'
          },
          {
            control_type: 'date_time',
            label: 'Created date',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'createdDate'
          },
          {
            name: '_links',
            type: 'array',
            of: 'object',
            label: 'Links',
            properties: [
              {
                control_type: 'text',
                label: 'Rel',
                type: 'string',
                name: 'rel'
              },
              {
                control_type: 'text',
                label: 'HREF',
                type: 'string',
                name: 'href'
              }
            ]
          },
          {
            control_type: 'text',
            label: 'Name',
            type: 'string',
            name: 'name'
          },
          {
            control_type: 'text',
            label: 'ID',
            type: 'string',
            name: 'id'
          },
          {
            name: 'budgetId',
            label: 'Budget',
            control_type: 'select',
            type: 'integer',
            pick_list: 'budgets',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'budgetId',
              label: 'Budget ID',
              toggle_hint: 'Use custom value',
              control_type: 'number',
              type: 'integer'
            }
          },
          {
            control_type: 'date_time',
            label: 'Updated date',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'updatedDate'
          },
          {
            name: 'type',
            label: 'Type',
            default: 'LINE_ITEM',
            control_type: 'select',
            pick_list: 'line_item_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'type',
              label: 'Type',
              hint: 'Allowed values are: LINE_ITEM, CATEGORY, PLACEHOLDER',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            control_type: 'text',
            label: 'Parent ID',
            type: 'string',
            name: 'parentId'
          }
        ]
      end
    },

    line_item_create: {
      fields: lambda do |_connection, config_fields|
        cells_prop = get("/v1/budgets/#{config_fields['budgetId']}/columns" \
          '?$filter=type eq "CURRENCY" and location eq "GRID"')
                     &.map do |field|
                       unless field['readOnly']
                         {
                           name: "f__#{field['id']}",
                           # TODO: fix this label: "#{field['name'].humanize}",
                           label: (field['name']).to_s,
                           sticky: true,
                           control_type: 'number',
                           type: 'number',
                           render_input: 'float_conversion',
                           parse_output: 'float_conversion'
                         }
                       end
                     end&.compact

        [
          {
            name: 'cells',
            sticky: true,
            type: 'object',
            properties: cells_prop
          },
          {
            control_type: 'date_time',
            label: 'Created date',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'createdDate'
          },
          {
            control_type: 'text',
            label: 'Name',
            type: 'string',
            name: 'name'
          },
          {
            name: 'budgetId',
            label: 'Budget',
            control_type: 'select',
            type: 'integer',
            pick_list: 'budgets',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'budgetId',
              label: 'Budget ID',
              toggle_hint: 'Use custom value',
              control_type: 'number',
              type: 'integer'
            }
          },
          {
            control_type: 'date_time',
            label: 'Updated date',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'updatedDate'
          },
          {
            name: 'type',
            label: 'Type',
            default: 'LINE_ITEM',
            control_type: 'select',
            pick_list: 'line_item_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'type',
              label: 'Type',
              hint: 'Allowed values are: LINE_ITEM, CATEGORY, PLACEHOLDER',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            control_type: 'text',
            label: 'Parent ID',
            type: 'string',
            name: 'parentId'
          }
        ]
      end
    },

    line_item_update: {
      fields: lambda do |_connection, config_fields|
        cells_prop = get("/v1/budgets/#{config_fields['budgetId']}/columns" \
          '?$filter=type eq "CURRENCY" and location eq "GRID"')
                     &.map do |field|
                       unless field['readOnly']
                         {
                           name: "f__#{field['id']}",
                           # TODO: fix this label: "#{field['name'].humanize}",
                           label: (field['name']).to_s,
                           sticky: true,
                           control_type: 'number',
                           type: 'number',
                           render_input: 'float_conversion',
                           parse_output: 'float_conversion'
                         }
                       end
                     end&.compact

        [
          {
            name: 'cells',
            sticky: true,
            type: 'object',
            properties: cells_prop
          },
          {
            control_type: 'date_time',
            label: 'Created date',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'createdDate'
          },
          {
            control_type: 'text',
            label: 'Name',
            type: 'string',
            name: 'name'
          },
          {
            control_type: 'text',
            label: 'ID',
            type: 'string',
            name: 'id'
          },
          {
            name: 'budgetId',
            label: 'Budget',
            control_type: 'select',
            type: 'integer',
            pick_list: 'budgets',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'budgetId',
              label: 'Budget ID',
              toggle_hint: 'Use custom value',
              control_type: 'number',
              type: 'integer'
            }
          },
          {
            control_type: 'date_time',
            label: 'Updated date',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'updatedDate'
          },
          {
            name: 'type',
            label: 'Type',
            default: 'LINE_ITEM',
            control_type: 'select',
            pick_list: 'line_item_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'type',
              label: 'Type',
              hint: 'Allowed values are: LINE_ITEM, CATEGORY, PLACEHOLDER',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            control_type: 'text',
            label: 'Parent ID',
            type: 'string',
            name: 'parentId'
          }
        ]
      end
    },

    line_item_get: {
      fields: lambda do |_connection, config_fields|
        cells_prop = get("/v1/budgets/#{config_fields['budgetId']}/columns")
                     &.map do |field|
                       {
                         name: "f__#{field['id']}",
                         # TODO: fix this label: "#{field['name'].humanize}",
                         label: (field['name']).to_s,
                         sticky: true,
                         control_type: 'number',
                         type: 'number',
                         render_input: 'float_conversion',
                         parse_output: 'float_conversion'
                       }
                     end&.compact

        [
          {
            name: 'cells',
            sticky: true,
            type: 'object',
            properties: cells_prop
          },
          {
            control_type: 'date_time',
            label: 'Created date',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'createdDate'
          },
          {
            name: '_links',
            type: 'array',
            of: 'object',
            label: 'Links',
            properties: [
              {
                control_type: 'text',
                label: 'Rel',
                type: 'string',
                name: 'rel'
              },
              {
                control_type: 'text',
                label: 'HREF',
                type: 'string',
                name: 'href'
              }
            ]
          },
          {
            control_type: 'text',
            label: 'Name',
            type: 'string',
            name: 'name'
          },
          {
            control_type: 'text',
            label: 'ID',
            type: 'string',
            name: 'id'
          },
          {
            name: 'budgetId',
            label: 'Budget',
            control_type: 'select',
            type: 'integer',
            pick_list: 'budgets',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'budgetId',
              label: 'Budget ID',
              toggle_hint: 'Use custom value',
              control_type: 'number',
              type: 'integer'
            }
          },
          {
            control_type: 'date_time',
            label: 'Updated date',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time',
            name: 'updatedDate'
          },
          {
            name: 'type',
            label: 'Type',
            default: 'LINE_ITEM',
            control_type: 'select',
            pick_list: 'line_item_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'type',
              label: 'Type',
              hint: 'Allowed values are: LINE_ITEM, CATEGORY, PLACEHOLDER',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            control_type: 'text',
            label: 'Parent ID',
            type: 'string',
            name: 'parentId'
          }
        ]
      end
    }
  },

  actions: {
    # Custom action for Allocadia
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
        "in <span class='provider'>Allocadia</span>",
      # TODO: fix learn_more_url
      help: {
        body: 'Build your own Allocadia action with an HTTP request. The ' \
          'request will be authorized with your Allocadia connection.',
        learn_more_url: 'https://api-staging.allocadia.com' \
          '/v1/docs/secured/index.xml',
        learn_more_text: 'Allocadia API Documentation'
      },

      execute: lambda do |_connection, input|
        verb = input['verb']
        error("#{verb} not supported") if %w[get post put delete].exclude?(verb)
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
        pick_list: %w[get post put delete].map { |verb| [verb.upcase, verb] }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['custom_action_input']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['custom_action_output']
      end
    },

    search_budgets: {
      description: "Search <span class='provider'>budgets</span> " \
        "in <span class='provider'>Allocadia</span>",
      help: 'Fetches the budgets that match the search criteria, ' \
      'for the current user',
      # TODO: check the page_size for this endpoint
      # 'Returns a maximum of 200 budgets.',

      execute: lambda do |_connection, input|
        filter = [input.delete('filter')].compact
        filter = filter.concat(input.map do |key, value|
          if key.include?('Date')
            "#{key} ge \"#{value}\""
          else
            "#{key} eq \"#{value}\""
          end
        end).smart_join(' and ')

        { budgets: get("/v1/budgets?$filter=#{filter}") }
      end,

      input_fields: lambda do |object_definitions|
        [{
          name: 'filter',
          label: 'Filter using custom criteria',
          sticky: true,
          hint: 'Budgets can be filtered based upon property and ' \
          'sub-property values. Strings must be double quoted and ' \
          'all expressions must evaluate to a boolean value. <br>' \
          'Supported operators: <b>eq</b> (Equal), <b>ne</b> (Not ' \
          'equal), <b>gt</b> (Greater than), <b>ge</b> (Greater ' \
          'than or equal), <b>lt</b> (Less than), <b>le</b> ' \
          '(Less than or equal), <b>and</b>, and  <b>or</b>.<br/>' \
          'For example: <b>updatedDate ge "2017-03-10T00:00:00.000Z" and ' \
          'updatedDate lt "2017-03-11T00:00:00.000Z"</b>'
        }].concat(object_definitions['budget']).ignored('_links')
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'budgets',
          type: 'array',
          of: 'object',
          properties: object_definitions['budget']
        }]
      end,

      sample_output: lambda do |_connection, _input|
        { budgets: get('/v1/budgets') }
      end
    },

    get_budget_by_id: {
      description: "Get <span class='provider'>budget by ID</span> " \
        "in <span class='provider'>Allocadia</span>",

      execute: lambda do |_connection, input|
        get("/v1/budgets/#{input['id']}")
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['budget'].only('id').required('id')
      end,

      output_fields: ->(object_definitions) { object_definitions['budget'] },

      sample_output: ->(_connection, _input) { get('/v1/budgets')[0] }
    },

    search_line_items: {
      description: "Search <span class='provider'>line items</span> " \
        "in <span class='provider'>Allocadia</span>",
      help: 'Fetches the line items that match the search criteria.',
      # TODO: check the page_size for this endpoint
      # 'Returns a maximum of 200 line_items.',

      execute: lambda do |_connection, input|
        filter = [input.delete('filter')].compact
        filter = filter.concat(input.map do |key, value|
          if key.include?('Date')
            "#{key} ge \"#{value}\""
          else
            "#{key} eq \"#{value}\""
          end
        end).smart_join(' and ')

        {
          line_items: get("/v1/budgets/#{input['budgetId']}/lineitems" \
            "?$filter=#{filter}")
        }
      end,

      input_fields: lambda do |object_definitions|
        [{
          name: 'filter',
          label: 'Filter using custom criteria',
          sticky: true,
          hint: 'Line items can be filtered based upon property and ' \
          'sub-property values. Strings must be double quoted and ' \
          'all expressions must evaluate to a boolean value. <br>' \
          'Supported operators: <b>eq</b> (Equal), <b>ne</b> (Not ' \
          'equal), <b>gt</b> (Greater than), <b>ge</b> (Greater ' \
          'than or equal), <b>lt</b> (Less than), <b>le</b> ' \
          '(Less than or equal), <b>and</b>, and  <b>or</b>.<br/>' \
          'For example: <b>updatedDate ge "2017-03-10T00:00:00.000Z" and ' \
          'updatedDate lt "2017-03-11T00:00:00.000Z"</b>'
        }].concat(object_definitions['line_item'])
          .ignored('_links')
          .required('budgetId')
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'line_items',
          type: 'array',
          of: 'object',
          properties: object_definitions['line_item'].ignored('cells')
        }]
      end,

      sample_output: lambda do |_connection, _input|
        { line_items: get('/v1/lineitems') }
      end
    },

    get_line_item_by_id: {
      description: "Get <span class='provider'>line item by ID</span> " \
        "in <span class='provider'>Allocadia</span>",

      execute: lambda do |_connection, input|
        line_item = get("/v1/budgets/#{input['budgetId']}/lineitems" \
          "/#{input['id']}")
        line_item['cells'] = line_item['cells']&.map do |key, value|
          { "f__#{key}" => value['value'] }
        end&.compact&.inject(:merge)

        line_item.compact
      end,

      config_fields: [{
        name: 'budgetId',
        label: 'Budget',
        optional: false,
        control_type: 'select',
        type: 'integer',
        pick_list: 'budgets',
        toggle_hint: 'Select from list',
        toggle_field: {
          name: 'budgetId',
          label: 'Budget ID',
          toggle_hint: 'Use custom value',
          control_type: 'number',
          type: 'integer'
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['line_item_get'].only('id').required('id')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['line_item_get']
      end,

      sample_output: ->(_connection, _input) { get('/v1/lineitems')[0] }
    },

    add_line_item: {
      description: "Add <span class='provider'>line item</span> " \
        "in <span class='provider'>Allocadia</span>",

      execute: lambda do |_connection, input|
        input['cells'] = input['cells']&.map do |key, value|
          { key.split(/f__/)[1] => { 'value' => value } }
        end&.compact&.inject(:merge)

        post("/v1/budgets/#{input.delete('budgetId')}/lineitems", input.compact)
          .after_response do |code, body, headers|
          # if /3\d{2} | 4\d{2} | 5\d{2}/.match?(code)
          if code.to_s.match?(/[3-5]\d{2}/)
            error("#{code}: #{body}")
          else
            { location: headers['location'] }
          end
        end
      end,

      config_fields: [{
        name: 'budgetId',
        label: 'Budget',
        optional: false,
        control_type: 'select',
        type: 'integer',
        pick_list: 'budgets',
        toggle_hint: 'Select from list',
        toggle_field: {
          name: 'budgetId',
          label: 'Budget ID',
          toggle_hint: 'Use custom value',
          control_type: 'number',
          type: 'integer'
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['line_item_create']
      end,

      output_fields: ->(_object_definitions) { [{ name: 'location' }] },

      sample_output: lambda do |_connection, _input|
        { location: 'https://api-na.allocadia.com/v1/budgets/12/lineitems/34' }
      end
    },

    update_line_item: {
      description: "Update <span class='provider'>line item" \
        "</span> in <span class='provider'>Allocadia</span>",

      execute: lambda do |_connection, input|
        input['cells'] = input['cells']&.map do |key, value|
          { key.split(/f__/)[1] => { 'value' => value } }
        end&.compact&.inject(:merge)

        put("/v1/budgets/#{input.delete('budgetId')}/lineitems" \
          "/#{input.delete('id')}", input.compact)
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end || {}
      end,

      config_fields: [{
        name: 'budgetId',
        label: 'Budget',
        optional: false,
        control_type: 'select',
        type: 'integer',
        pick_list: 'budgets',
        toggle_hint: 'Select from list',
        toggle_field: {
          name: 'budgetId',
          label: 'Budget ID',
          toggle_hint: 'Use custom value',
          control_type: 'number',
          type: 'integer'
        }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['line_item_update'].required('id')
      end
    }
  },

  pick_lists: {
    budgets: ->(_connection) { get('/v1/budgets')&.pluck('name', 'id') || [] },

    line_item_types: lambda do |_connection|
      [%w[Line\ item LINE_ITEM],
       %w[Category CATEGORY],
       %w[Placeholder PLACEHOLDER]]
    end
  }
}
