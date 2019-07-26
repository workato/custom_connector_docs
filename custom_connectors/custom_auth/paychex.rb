{
  title: 'Paychex',

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
    end,

    render_date_input: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call('render_date_input', array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call('render_date_input', value)
          if key.downcase.include?('date')
            { key => value&.to_time&.utc&.iso8601 }
          else
            { key => value }
          end
        end.inject(:merge)
      else
        input
      end
    end
  },

  connection: {
    fields: [
      {
        name: 'client_id',
        hint: "The application's API key.",
        optional: false
      },
      { name: 'client_secret', optional: false, control_type: 'password' },
      {
        name: 'api_base_uri',
        label: 'API base URI',
        hint: 'Base URI, e.g.: https://<b>api.n1.paychex.com</b>.',
        control_type: 'subdomain',
        optional: false
      }
    ],

    authorization: {
      type: 'custom_auth',

      acquire: lambda do |connection|
        post("https://#{connection['api_base_uri']}/auth/oauth/v2/token",
             grant_type: 'client_credentials',
             client_id: connection['client_id'],
             client_secret: connection['client_secret'])
          .request_format_www_form_urlencoded
      end,

      refresh_on: [401, /Unauthorized./],

      apply: lambda do |connection|
        headers(Authorization: "Bearer #{connection['access_token']}")
      end
    },

    base_uri: ->(connection) { "https://#{connection['api_base_uri']}" }
  },

  test: ->(_connection) { get('/companies', limit: 1) },

  object_definitions: {
    check: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'payPeriodId' },
          { name: 'workerId', sticky: true },
          { name: 'checkCorrelationId' },
          { name: 'blockAutoDistribution' },
          {
            name: 'earnings',
            sticky: true,
            type: 'array',
            of: 'object',
            label: 'Earnings',
            properties: [
              { name: 'checkComponentId', sticky: true },
              { name: 'componentId', sticky: true },
              { name: 'name', sticky: true },
              { name: 'classificationType', sticky: true },
              { name: 'effectOnPay' },
              { name: 'payRate' },
              { name: 'payRateId' },
              { name: 'payHours' },
              { name: 'payUnits' },
              { name: 'payAmount' },
              {
                properties: [
                  { name: 'organizationId' },
                  { name: 'name' },
                  { name: 'number' },
                  { name: 'label' },
                  {
                    properties: [
                      { name: 'rel' },
                      { name: 'href', label: 'HREF' }
                    ],
                    type: 'array',
                    of: 'object',
                    name: 'organization'
                  }
                ],
                type: 'object',
                name: 'organization'
              },
              { name: 'lineDate', control_type: 'date', type: 'date_time' },
              {
                name: 'memoed',
                control_type: 'checkbox',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                type: 'boolean',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'memoed',
                  label: 'Memoed',
                  type: :boolean,
                  control_type: 'text',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false'
                }
              },
              { name: 'jobId' },
              { name: 'laborAssignmentId' }
            ]
          }
        ]
      end
    },

    communication: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'communicationId' },
          {
            name: 'type',
            sticky: true,
            control_type: 'select',
            pick_list: 'communication_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'type',
              label: 'Type',
              hint: 'Allowed values are: STREET_ADDRESS, PO_BOX_ADDRESS, ' \
                'PHONE, MOBILE_PHONE, FAX, EMAIL, PAGER',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'usageType',
            sticky: true,
            control_type: 'select',
            pick_list: 'usage_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'usageType',
              label: 'Usage type',
              hint: 'Allowed values are: PERSONAL, BUSINESS',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          { name: 'dialCountry' },
          { name: 'dialArea' },
          { name: 'dialNumber' },
          { name: 'dialExtension' },
          { name: 'uri', label: 'URI' },
          { name: 'streetLineOne' },
          { name: 'streetLineTwo' },
          { name: 'postOfficeBox' },
          { name: 'city' },
          { name: 'countrySubdivisionCode' },
          { name: 'postalCode' },
          { name: 'countryCode' }
        ]
      end
    },

    company: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'companyId' },
          { name: 'legalName' },
          { name: 'displayId' },
          {
            properties: [
              {
                name: 'legalIdType',
                label: 'Legal ID Type',
                control_type: 'select',
                pick_list: 'legal_id_type',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'legalIdType',
                  label: 'Legal ID Type',
                  hint: 'Allowed values are: SSN, SIN, FEIN, SSNLast4',
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'string'
                }
              },
              { name: 'legalIdValue' }
            ],
            type: 'object', name: 'legalId'
          },
          {
            name: 'communications',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'type',
                control_type: 'select',
                pick_list: 'communication_types',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'type',
                  label: 'Type',
                  hint: 'Allowed values are: STREET_ADDRESS, PO_BOX_ADDRESS, ' \
                    'PHONE, MOBILE_PHONE, FAX, EMAIL, PAGER',
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'string'
                }
              },
              {
                name: 'usageType',
                control_type: 'select',
                pick_list: 'usage_types',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'usageType',
                  label: 'Usage type',
                  hint: 'Allowed values are: PERSONAL, BUSINESS',
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'string'
                }
              },
              { name: 'dialCountry' },
              { name: 'dialArea' },
              { name: 'dialNumber' },
              { name: 'dialExtension' },
              { name: 'uri', label: 'URI' },
              { name: 'streetLineOne' },
              { name: 'streetLineTwo' },
              { name: 'postOfficeBox' },
              { name: 'city' },
              { name: 'countrySubdivisionCode' },
              { name: 'postalCode' },
              { name: 'countryCode' }
            ]
          }
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
            hint: "Base URI is https://<b>#{connection['api_base_uri']}" \
              '</b> - path will be appended to this URI. ' \
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

    pay_component: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'componentId' },
          { name: 'name' },
          {
            name: 'classificationType',
            label: 'Classification type',
            control_type: 'select',
            pick_list: 'classification_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'classificationType',
              label: 'Classification type',
              hint: "Find all allowed values <a href='https://developer" \
              '.paychex.com/api-documentation-and-exploration/api-references' \
              "/payroll/paycomponents'>here</a>.",
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          { name: 'description' },
          {
            name: 'effectOnPay',
            label: 'Effect on pay',
            control_type: 'select',
            pick_list: 'effect_on_pay_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'effectOnPay',
              label: 'Effect on pay',
              hint: 'Allowed values are: ADDITION, REDUCTION, ' \
                'EMPLOYER_INFORMATIONAL, ADDITION_WITH_IN_OUT',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          { name: 'startDate', control_type: 'date', type: 'date_time' },
          { name: 'endDate', control_type: 'date', type: 'date_time' },
          { name: 'appliesToWorkerTypes', hint: 'Comma seperated list values' }
        ]
      end
    },

    pay_period: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'payPeriodId' },
          {
            name: 'intervalCode',
            label: 'Interval code',
            sticky: true,
            control_type: 'select',
            pick_list: 'interval_code',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'intervalCode',
              label: 'Interval code',
              hint: 'Frequency of the payroll period. Allowed values are: ' \
              'ANNUAL, BI_WEEKLY, MONTHLYQUARTERLY, SEMI_ANNUAL, ' \
              'SEMI_MONTHLY, WEEKLY',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'status',
            label: 'Status',
            sticky: true,
            control_type: 'select',
            pick_list: 'pay_period_status',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'status',
              label: 'Status',
              hint: 'The current state of the associated pay period' \
              'Allowed values are: COMPLETED, COMPLETED_BY_MEC, ENTRY' \
              'INITIAL, PROCESSING, REISSUED, RELEASED, REVERSED',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          { name: 'description' },
          { name: 'startDate', control_type: 'date', type: 'date_time' },
          { name: 'endDate', control_type: 'date', type: 'date_time' },
          { name: 'submitByDate', control_type: 'date', type: 'date_time' },
          { name: 'checkDate', control_type: 'date', type: 'date_time' },
          {
            control_type: 'number',
            label: 'Check count',
            parse_output: 'float_conversion',
            type: 'number',
            name: 'checkCount'
          }
        ]
      end
    },

    worker: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'workerId' },
          { name: 'employeeId', sticky: true },
          {
            name: 'workerType',
            label: 'Worker type',
            sticky: true,
            control_type: 'select',
            pick_list: 'worker_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'workerType',
              label: 'Worker type',
              hint: 'Allowed values are: EMPLOYEE, CONTRACTOR',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'employmentType',
            label: 'Employment type',
            control_type: 'select',
            pick_list: 'employment_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'employmentType',
              label: 'Employment type',
              hint: 'Allowed values are: FULL_TIME, PART_TIME',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'exemptionType',
            label: 'Exemption type',
            sticky: true,
            control_type: 'select',
            pick_list: 'exemption_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'employmentType',
              label: 'Employment type',
              hint: 'Allowed values are: EXEMPT, NON_EXEMPT',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          { name: 'birthDate', control_type: 'date', type: 'date_time' },
          { name: 'clockId' },
          {
            name: 'sex',
            label: 'Sex',
            control_type: 'select',
            pick_list: 'genders',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'sex',
              label: 'Sex',
              hint: 'Allowed values are: MALE, FEMALE, UNKNOWN, NOT_SPECIFIED',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'ethnicityCode',
            label: 'Ethnicity code',
            control_type: 'select',
            pick_list: 'ethnicity_code',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'ethnicityCode',
              label: 'Ethnicity code',
              hint: 'Allowed values are: HISPANIC_OR_LATINO, ' \
              'WHITE_NOT_OF_HISPANIC_ORIGIN, BLACK_OR_AFRICAN_AMERICAN, ' \
              'NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLAND, ' \
              'AMERICAN_INDIAN_OR_ALASKAN_NATIVE, TWO_OR_MORE_RACES' \
              'ASIAN_OR_PACIFIC_ISLANDER',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          { name: 'hireDate', control_type: 'date', type: 'date_time' },
          {
            properties: [
              { name: 'familyName' },
              { name: 'middleName' },
              { name: 'givenName' },
              { name: 'preferredName' },
              { name: 'qualificationAffixCode' },
              { name: 'titleAffixCode' }
            ],
            type: 'object',
            name: 'name'
          },
          {
            properties: [
              {
                name: 'legalIdType',
                label: 'Legal ID Type',
                control_type: 'select',
                pick_list: 'legal_id_type',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'legalIdType',
                  label: 'Legal ID Type',
                  hint: 'Allowed values are: SSN, SIN, FEIN, SSNLast4',
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'string'
                }
              },
              { name: 'legalIdValue' }
            ],
            label: 'Legal ID',
            type: 'object',
            name: 'legalId'
          },
          {
            properties: [
              { name: 'workerStatusId' },
              {
                name: 'statusType',
                label: 'Status type',
                control_type: 'select',
                pick_list: 'status_types',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'statusType',
                  label: 'Status type',
                  hint: 'Allowed values are: ACTIVE, INACTIVE, TERMINATED, ' \
                  'TRANSFERRED, PENDING, IN_PROGRESS',
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'string'
                }
              },
              {
                name: 'statusReason',
                label: 'Status reason',
                hint: "The 'Status reason' is a dependent field of " \
                "'Status type'. Find all allowed values <a href='https://" \
                'developer.paychex.com/api-documentation-and-exploration' \
                "/api-references/workers'>here</a>.",
                control_type: 'select',
                pick_list: 'status_reasons',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'statusReason',
                  label: 'Status reason',
                  hint: "Find all allowed values <a href='https://developer" \
                  '.paychex.com/api-documentation-and-exploration' \
                  "/api-references/workers'>here</a>.",
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'string'
                }
              },
              {
                name: 'effectiveDate', type: 'date'
              }
            ],
            type: 'object',
            name: 'currentStatus'
          },
          { name: 'laborAssignmentId' },
          { name: 'locationId' },
          { name: 'jobId' },
          {
            properties: [{ name: 'jobTitleId' }, { name: 'title' }],
            type: 'object',
            name: 'job'
          },
          {
            properties: [{ name: 'organizationId' }, { name: 'name' }],
            label: 'Organization',
            type: 'object',
            name: 'organization'
          },
          {
            properties: [
              { name: 'workerId' },
              {
                properties: [{ name: 'familyName' }, { name: 'givenName' }],
                type: 'object',
                name: 'name'
              }
            ],
            type: 'object',
            name: 'supervisor'
          },
          {
            name: 'links',
            type: 'array',
            of: 'object',
            properties: [{ name: 'rel' }, { name: 'href', label: 'HREF' }]
          }
        ]
      end
    },

    worker_create: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'employeeId' },
          { name: 'clockId' },
          {
            name: 'workerType',
            label: 'Worker type',
            control_type: 'select',
            pick_list: 'worker_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'workerType',
              label: 'Worker type',
              hint: 'Allowed values are: EMPLOYEE, CONTRACTOR',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'employmentType',
            label: 'Employment type',
            control_type: 'select',
            pick_list: 'employment_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'employmentType',
              label: 'Employment type',
              hint: 'Allowed values are: FULL_TIME, PART_TIME',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'exemptionType',
            label: 'Exemption type',
            control_type: 'select',
            pick_list: 'exemption_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'employmentType',
              label: 'Employment type',
              hint: 'Allowed values are: EXEMPT, NON_EXEMPT',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          { name: 'hireDate', control_type: 'date', type: 'date_time' },
          { name: 'birthDate', control_type: 'date', type: 'date_time' },
          { name: 'laborAssignmentId' },
          { name: 'locationId' },
          { name: 'jobId' },
          {
            name: 'sex',
            control_type: 'select',
            pick_list: 'genders',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'sex',
              label: 'Sex',
              hint: 'Allowed values are: MALE, FEMALE, UNKNOWN, NOT_SPECIFIED',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'ethnicityCode',
            label: 'Ethnicity code',
            control_type: 'select',
            pick_list: 'ethnicity_code',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'ethnicityCode',
              label: 'Ethnicity code',
              hint: 'Allowed values are: HISPANIC_OR_LATINO, ' \
              'WHITE_NOT_OF_HISPANIC_ORIGIN, BLACK_OR_AFRICAN_AMERICAN, ' \
              'NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLAND, ' \
              'AMERICAN_INDIAN_OR_ALASKAN_NATIVE, TWO_OR_MORE_RACES' \
              'ASIAN_OR_PACIFIC_ISLANDER',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            properties: [
              { name: 'familyName', optional: false },
              { name: 'middleName' },
              { name: 'givenName', optional: false },
              { name: 'preferredName' },
              { name: 'qualificationAffixCode' },
              { name: 'titleAffixCode' }
            ],
            type: 'object',
            name: 'name'
          },
          {
            properties: [
              { name: 'workerStatusId' },
              {
                name: 'statusType',
                label: 'Status type',
                control_type: 'select',
                pick_list: 'status_types',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'statusType',
                  label: 'Status type',
                  hint: 'Allowed values are: ACTIVE, INACTIVE, TERMINATED, ' \
                  'TRANSFERRED, PENDING, IN_PROGRESS',
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'string'
                }
              },
              {
                name: 'statusReason',
                label: 'Status reason',
                hint: "The 'Status reason' is a dependent field of " \
                "'Status type'. Find all allowed values <a href='https://" \
                'developer.paychex.com/api-documentation-and-exploration' \
                "/api-references/workers'>here</a>.",
                control_type: 'select',
                pick_list: 'status_reasons',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'statusReason',
                  label: 'Status reason',
                  hint: "Find all allowed values <a href='https://developer" \
                  '.paychex.com/api-documentation-and-exploration' \
                  "/api-references/workers'>here</a>.",
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'string'
                }
              },
              { name: 'effectiveDate', control_type: 'date', type: 'date_time' }
            ],
            type: 'object',
            name: 'currentStatus'
          },
          {
            properties: [
              {
                name: 'legalIdType',
                label: 'Legal ID Type',
                control_type: 'select',
                pick_list: 'legal_id_type',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'legalIdType',
                  label: 'Legal ID Type',
                  hint: 'Allowed values are: SSN, SIN, FEIN, SSNLast4',
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'string'
                }
              },
              { name: 'legalIdValue' }
            ],
            type: 'object',
            name: 'legalId'
          },
          {
            properties: [{ name: 'organizationId' }, { name: 'name' }],
            type: 'object',
            name: 'organization'
          },
          {
            properties: [{ name: 'jobTitleId' }, { name: 'title' }],
            type: 'object',
            name: 'job'
          },
          {
            properties: [
              { name: 'workerId' },
              {
                properties: [{ name: 'familyName' }, { name: 'givenName' }],
                type: 'object',
                name: 'name'
              }
            ],
            type: 'object',
            name: 'supervisor'
          }
        ]
      end
    }
  },

  actions: {
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
        "in <span class='provider'>Paychex</span>",
      help: 'Build your own Paychex action with a HTTP request. <br>' \
        " <br> <a href='https://developer.paychex.com" \
        "/api-documentation-and-exploration/api-references' target='_blank'>" \
        'Paychex API Documentation</a>',

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
        pick_list: %w[get post patch delete].map { |verb| [verb.upcase, verb] }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['custom_action_input']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['custom_action_output']
      end
    },

    create_check: {
      description: "Create <span class='provider'>check</span> " \
        "in <span class='provider'>Paychex</span>",

      execute: lambda do |_connection, input|
        post("/workers/#{input['workerId']}/checks",
             call('render_date_input', input))
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end.dig('content', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['check'].required('workerId', 'payPeriodId')
      end,

      output_fields: ->(object_definitions) { object_definitions['check'] },

      sample_output: lambda do |_connection, _input|
        company_id = get('/companies', limit: 1).dig('content', 0, 'companyId')
        worker_id = get("/companies/#{company_id}/workers", limit: 1)
                    .dig('content', 0, 'workerId')
        payperiods_id = get("/companies/#{company_id}/payperiods", limit: 1)
                        .dig('content', 0, 'payPeriodId')
        get("/workers/#{worker_id}/checks",
            'payperiodid' => payperiods_id,
            'limit' => 1).dig('content', 0) || {}
      end
    },

    create_communication: {
      description: "Create <span class='provider'>communication</span> of " \
        "worker in <span class='provider'>Paychex</span>",
      help: 'Details of information varies on what comminication '  \
            'type you select  <br>'  \
            'For street address, it consists of a street address, up to two,' \
            'lines or PO Box, plus city, state, ZIP code and ' \
            'Country Code. <br>' \
            'For email, please provide URI <br>' \
            'For Phone, Mobile phone, Fax and Pager, the dial country, ' \
            'dial area and dial number are required',

      execute: lambda do |_connection, input|
        post("/workers/#{input.delete('workerId')}/communications",
             call('render_date_input', input))
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end.dig('content', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        [{
          control_type: 'text',
          label: 'Worker ID',
          type: 'string',
          name: 'workerId'
        }].concat(object_definitions['communication'])
          .ignored('communicationId')
          .required('workerId', 'type', 'usageType')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['communication']
      end,

      sample_output: lambda do |_connection, _input|
        company_id = get('/companies', limit: 1).dig('content', 0, 'companyId')
        worker_id = get("/companies/#{company_id}/workers", limit: 1)
                    .dig('content', 0, 'workerId')
        get("/workers/#{worker_id}/communications", limit: 1)
          .dig('content', 0) || {}
      end
    },

    get_communications_of_worker_by_id: {
      description: "Get <span class='provider'>communications</span> " \
        "of worker by ID in <span class='provider'>Paychex</span>",

      execute: lambda do |_connection, input|
        {
          communications: get("/workers/#{input['workerId']}/communications")
            .after_error_response(/.*/) do |_code, body, _header, message|
                            error("#{message}: #{body}")
                          end['content'] || []
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['worker'].only('workerId').required('workerId')
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'communications',
          type: 'array',
          of: 'object',
          properties: object_definitions['communication']
        }]
      end,

      sample_output: lambda do |_connection, _input|
        company_id = get('/companies', limit: 1).dig('content', 0, 'companyId')
        worker_id = get("/companies/#{company_id}/workers", limit: 1)
                    .dig('content', 0, 'workerId')
        {
          communications: get("/workers/#{worker_id}/communications", limit: 1)
            .dig('content', 0) || {}
        }
      end
    },

    search_pay_components: {
      description: "Search <span class='provider'>pay components</span> " \
        "in <span class='provider'>Paychex</span>",

      execute: lambda do |_connection, input|
        company_id = input.delete('company_id')
        {
          pay_components: get("/companies/#{company_id}/paycomponents", input)
            .[]('content')
        }
      end,

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'company_id',
            label: 'Company',
            control_type: 'select',
            optional: false,
            pick_list: 'companies',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'company_id',
              label: 'Company ID',
              toggle_hint: 'Use custom value',
              control_type: 'number',
              optional: false,
              type: 'string'
            }
          },
          {
            name: 'effectonpay',
            label: 'Effect on Pay',
            control_type: 'select',
            optional: false,
            pick_list: 'effect_on_pay_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'effectonpay',
              label: 'Effect on Pay',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              optional: false,
              type: 'string',
              hint: 'The effect that the pay component will have on the ' \
              'check amount. Allowed values are: <br\>ADDITION: Adds to pay ' \
              '<br\>REDUCTION: Reduces pay <br\>EMPLOYER_INFORMATIONAL: ' \
              'No effect on pay <br\>ADDITION_WITH_IN_OUT: Adds to pay ' \
              'for tax calculations, but is subtracted from net'
            }
          }
        ]
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'pay_components',
          type: 'array',
          of: 'object',
          properties: object_definitions['pay_component']
        }]
      end,

      sample_output: lambda do |_connection, _input|
        company_id = get('/companies', limit: 1).dig('content', 0, 'companyId')
        {
          pay_components: get("/companies/#{company_id}/paycomponents",
                              limit: 1)['content'] || []
        }
      end
    },

    get_pay_component_by_id: {
      description: "Get <span class='provider'>pay component</span> " \
        "by ID in <span class='provider'>Paychex</span>",

      execute: lambda do |_connection, input|
        get("/companies/#{input['company_id']}/paycomponents/" \
          "#{input['componentId']}")
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.dig('content', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        [{
          name: 'company_id',
          label: 'Company',
          control_type: 'select',
          optional: false,
          pick_list: 'companies',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'company_id',
            label: 'Company ID',
            toggle_hint: 'Use custom value',
            control_type: 'number',
            optional: false,
            type: 'string'
          }
        }].concat(object_definitions['pay_component'].only('componentId')
          .required('componentId'))
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['pay_component']
      end,

      sample_output: lambda do |_connection, _input|
        company_id = get('/companies', limit: 1).dig('content', 0, 'companyId')
        get("/companies/#{company_id}/paycomponents",
            limit: 1).dig('content', 0) || {}
      end
    },

    search_pay_periods: {
      description: "Search <span class='provider'>pay periods</span> " \
        "in <span class='provider'>Paychex</span>",

      execute: lambda do |_connection, input|
        company_id = input.delete('company_id')
        {
          pay_periods: get("/companies/#{company_id}/payperiods", input)
            .[]('content')
        }
      end,

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'company_id',
            label: 'Company',
            control_type: 'select',
            optional: false,
            pick_list: 'companies',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'company_id',
              label: 'Company ID',
              toggle_hint: 'Use custom value',
              control_type: 'number',
              optional: false,
              type: 'string'
            }
          },
          {
            name: 'from',
            label: 'Start date',
            hint: 'The beginning of the search date range using the ' \
              'Payperiod start date',
            type: 'date',
            sticky: true
          },
          {
            name: 'to',
            label: 'End date',
            hint: 'The ending of the search date range using the ' \
              'Payperiod end date',
            type: 'date',
            sticky: true
          }
        ]
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'pay_periods',
          type: 'array',
          of: 'object',
          properties: object_definitions['pay_period']
        }]
      end,

      sample_output: lambda do |_connection, _input|
        company_id = get('/companies', limit: 1).dig('content', 0, 'companyId')
        {
          pay_periods: get("/companies/#{company_id}/payperiods",
                           limit: 1)['content'] || []
        }
      end
    },

    get_pay_period_by_id: {
      description: "Get <span class='provider'>pay period</span> " \
        "by ID in <span class='provider'>Paychex</span>",

      execute: lambda do |_connection, input|
        get("/companies/#{input['company_id']}/payperiods/" \
          "#{input['payPeriodId']}")
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.dig('content', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        [{
          name: 'company_id',
          label: 'Company',
          control_type: 'select',
          optional: false,
          pick_list: 'companies',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'company_id',
            label: 'Company ID',
            toggle_hint: 'Use custom value',
            control_type: 'number',
            optional: false,
            type: 'string'
          }
        }].concat(object_definitions['pay_period'].only('payPeriodId')
            .required('payPeriodId'))
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['pay_period']
      end,

      sample_output: lambda do |_connection, _input|
        company_id = get('/companies', limit: 1).dig('content', 0, 'companyId')
        get("/companies/#{company_id}/payperiods", limit: 1)
          .dig('content', 0) || {}
      end
    },

    search_workers: {
      description: "Search <span class='provider'>workers</span> " \
        "in <span class='provider'>Paychex</span>",

      execute: lambda do |_connection, input|
        {
          workers: get("/companies/#{input.delete('company_id')}/workers",
                       input)
            .after_error_response(/404/) do |_code, _body, _header, _message|
              {}
            end['content'] || []
        }
      end,

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'company_id',
            label: 'Company',
            optional: false,
            control_type: 'select',
            pick_list: 'companies',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'company_id',
              label: 'Company ID',
              toggle_hint: 'Use custom value',
              control_type: 'number',
              type: 'string'
            }
          },
          { name: 'employeeId', sticky: true }
        ]
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'workers',
          type: 'array',
          of: 'object',
          properties: object_definitions['worker']
        }]
      end,

      sample_output: lambda do |_connection, _input|
        company_id = get('/companies', limit: 1).dig('content', 0, 'companyId')
        {
          workers: get("/companies/#{company_id}/workers",
                       limit: 1)['content'] || []
        }
      end
    },

    get_worker_by_id: {
      description: "Get <span class='provider'>worker</span> by ID " \
        "in <span class='provider'>Paychex</span>",

      execute: lambda do |_connection, input|
        get("/workers/#{input['workerId']}")
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.dig('content', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['worker'].only('workerId').required('workerId')
      end,

      output_fields: ->(object_definitions) { object_definitions['worker'] },

      sample_output: lambda do |_connection, _input|
        company_id = get('/companies', limit: 1).dig('content', 0, 'companyId')
        get("/companies/#{company_id}/workers", limit: 1)
          .dig('content', 0) || {}
      end
    },

    create_worker: {
      description: "Create <span class='provider'>worker</span> " \
        "in <span class='provider'>Paychex</span>",
      help: 'These workers will be added with an IN_PROGRESS status ' \
        'assigned to them.  IN_PROGRESS workers will pre-populated within ' \
        'Paychex Flex and will require someone to complete them to be ' \
        'fully available with the Flex platform.  Paychex Flex UI will ' \
        'hold a majority of validation, rules, and enforced required fields ' \
        'based on the clients configuration.',

      execute: lambda do |_connection, input|
        post("/companies/#{input.delete('company_id')}/workers",
             [call('render_date_input', input)])
          .after_error_response(/.*/) do |_code, body, _headers, message|
          error("#{message}: #{body}")
        end.dig('content', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        [{
          name: 'company_id',
          label: 'Company',
          control_type: 'select',
          optional: false,
          pick_list: 'companies',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'company_id',
            label: 'Company ID',
            toggle_hint: 'Use custom value',
            control_type: 'number',
            type: 'string'
          }
        }].concat(object_definitions['worker_create'])
          .required('name', 'workerType')
      end,

      output_fields: ->(object_definitions) { object_definitions['worker'] },

      sample_output: lambda do |_connection, _input|
        company_id = get('/companies', limit: 1).dig('content', 0, 'companyId')
        get("/companies/#{company_id}/workers", limit: 1)
          .dig('content', 0) || {}
      end
    },

    update_non_inprocess_worker: {
      title: 'Update (non - in progress status) worker',
      description: "Update (non - in progress status)<span class='provider'>" \
        "worker</span> in <span class='provider'>Paychex</span>",
      help: 'Update a unique worker (employee and contractor) that your ' \
        'application has been granted access to modify',

      execute: lambda do |_connection, input|
        patch("/workers/#{input.delete('workerId')}",
              call('render_date_input', input))
          .after_error_response(/.*/) do |_code, body, _headers, message|
          error("#{message}: #{body}")
        end.dig('content', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['worker']
          .ignored('workerType', 'laborAssignmentId', 'locationId', 'jobId',
                   'exemptionType', 'hireDate', 'sex', 'ethnicityCode',
                   'legalId', 'supervisor', 'links')
          .required('workerId')
      end,

      output_fields: ->(object_definitions) { object_definitions['worker'] },

      sample_output: lambda do |_connection, _input|
        company_id = get('/companies', limit: 1).dig('content', 0, 'companyId')
        get("/companies/#{company_id}/workers", limit: 1)
          .dig('content', 0) || {}
      end
    },

    update_inprocess_worker: {
      title: 'Update worker',
      description: "Update <span class='provider'>worker</span> in " \
        "<span class='provider'>Paychex</span>",
      help: 'Update a unique worker (employee and contractor) that your ' \
        'application has been granted access to modify',

      execute: lambda do |_connection, input|
        patch("/workers/#{input.delete('workerId')}",
              call('render_date_input', input))
          .after_error_response(/.*/) do |_code, body, _headers, message|
          error("#{message}: #{body}")
        end.dig('content', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['worker']
          .ignored('workerType', 'laborAssignmentId', 'locationId', 'jobId',
                   'currentStatus')
          .required('workerId')
      end,

      output_fields: ->(object_definitions) { object_definitions['worker'] },

      sample_output: lambda do |_connection, _input|
        company_id = get('/companies', limit: 1).dig('content', 0, 'companyId')
        get("/companies/#{company_id}/workers", limit: 1)
          .dig('content', 0) || {}
      end
    },

    get_company_by_display_id: {
      description: "Get <span class='provider'>company</span> by display ID " \
        "in <span class='provider'>Paychex</span>",

      execute: lambda do |_connection, input|
        get('/companies', 'displayid' => input['display_id'])
          .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.dig('content', 0) || {}
      end,

      input_fields: lambda do |_object_definitions|
        { name: 'display_id', optional: false }
      end,

      output_fields: ->(object_definitions) { object_definitions['company'] },

      sample_output: lambda do |_connection, _input|
        get('/companies', limit: 1).dig('content', 0)
      end
    }
  },

  triggers: {
    new_worker: {
      description: "New <span class='provider'>worker" \
        "</span> in <span class='provider'>Paychex</span>",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'company_id',
            label: 'Company',
            control_type: 'select',
            optional: false,
            pick_list: 'companies',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'company_id',
              label: 'Company ID',
              toggle_hint: 'Use custom value',
              control_type: 'number',
              type: 'string'
            }
          }
          # Check time-to-time, if the bug is resolved in Paychex API
          # At the moment: The data filter using `since` is intentionally
          # removed, coz API doesn't take offset along with `to` and `from` date
          # filter params
          # {
          #   name: 'since',
          # label: 'When first started, this recipe should pick up events from',
          #   hint: 'When you start recipe for the first time, ' \
          #   'it picks up trigger events from this specified date and time. ' \
          #   'Leave empty to get records created one hour ago',
          #   sticky: true,
          #   type: 'date_time'
          # }
        ]
      end,

      poll: lambda do |_connection, input, closure|
        page_size = 100
        closure ||= {}
        response =
          if (next_page = closure['next_page']).present?
            get(next_page)
              .headers('ETag' => closure['e_tag'])
              .after_response do |_code, body, headers|
              {
                'workers' => body&.[]('content') || [],
                'next_page' => body&.
                  []('links')&.
                  where('rel' => 'next')&.
                  dig(0, 'href'),
                'e_tag' => headers['etag'] || ''
              }.compact
            end
          else
            get("/companies/#{input['company_id']}/workers?",
                offset: 0,
                limit: page_size)
              .after_response do |_code, body, headers|
              {
                'workers' => body&.[]('content') || [],
                'next_page' => body&.
                  []('links')&.
                  where('rel' => 'next')&.
                  dig(0, 'href'),
                'e_tag' => headers['etag'] || ''
              }.compact
            end
          end

        {
          events: response.delete('workers'),
          next_poll: response,
          can_poll_more: response['next_page'].present?
        }
      end,

      dedup: ->(worker) { worker['workerId'] },

      output_fields: ->(object_definitions) { object_definitions['worker'] },

      sample_output: lambda do |_connection, _input|
        company_id = get('/companies').dig('content', 0, 'companyId')
        get("/companies/#{company_id}/workers", limit: 1)
          .dig('content', 0) || {}
      end
    },

    updated_worker_status: {
      description: "Updated worker <span class='provider'>status" \
        "</span> in <span class='provider'>Paychex</span>",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'company_id',
            label: 'Company',
            control_type: 'select',
            optional: false,
            pick_list: 'companies',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'company_id',
              label: 'Company ID',
              toggle_hint: 'Use custom value',
              control_type: 'number',
              type: 'string'
            }
          }
        ]
      end,

      poll: lambda do |_connection, input, closure|
        page_size = 10
        closure ||= {}
        response =
          if (next_page = closure['next_page']).present?
            get(next_page)
              .headers('ETag' => closure['e_tag'])
              .after_response do |_code, body, headers|
              {
                'workers' => body&.[]('content') || [],
                'next_page' => body&.
                  []('links')&.
                  where('rel' => 'next')&.
                  dig(0, 'href'),
                'e_tag' => headers['etag'] || ''
              }.compact
            end
          else
            get("/companies/#{input['company_id']}/workers",
                offset: 0,
                limit: page_size)
              .after_response do |_code, body, headers|
              {
                'workers' => body&.[]('content') || [],
                'next_page' => body&.
                  []('links')&.
                  where('rel' => 'next')&.
                  dig(0, 'href'),
                'e_tag' => headers['etag'] || ''
              }.compact
            end
          end

        {
          events: response.delete('workers'),
          next_poll: response,
          can_poll_more: response['next_page'].present?
        }
      end,

      dedup: lambda do |worker|
        "#{worker['workerId']}@#{worker['currentStatus']['statusType']}" \
          "@#{worker['currentStatus']['effectiveDate']}"
      end,

      output_fields: ->(object_definitions) { object_definitions['worker'] },

      sample_output: lambda do |_connection|
        company_id = get('/companies').dig('content', 0, 'companyId')
        get("/companies/#{company_id}/workers", limit: 1)
          .dig('content', 0) || {}
      end
    }
  },

  pick_lists: {
    companies: lambda do |_connection|
      get('/companies')['content']&.pluck('legalName', 'companyId') || []
    end,

    communication_types: lambda do |_connection|
      [%w[Street\ address STREET_ADDRESS], %w[PO\ box\ address PO_BOX_ADDRESS],
       %w[Phone PHONE], %w[Mobile\ phone MOBILE_PHONE],
       %w[Fax FAX], %w[Email EMAIL], %w[Pager PAGER]]
    end,

    employment_types: lambda do |_connection|
      [%w[Full\ time FULL_TIME], %w[Part\ time PART_TIME]]
    end,

    exemption_types: lambda do |_connection|
      [%w[Exempt EXEMPT], %w[Non\ exempt NON_EXEMPT]]
    end,

    status_types: lambda do |_connection|
      [%w[Active ACTIVE],
       %w[Inactive INACTIVE],
       %w[Terminated TERMINATED],
       %w[Transferred TRANSFERRED],
       %w[Pending PENDING],
       %w[In\ progress IN_PROGRESS]]
    end,

    status_reasons: lambda do |_connection|
      [%w[Hired HIRED], %w[Return\ to\ work RETURN_TO_WORK],
       %w[Rehired REHIRED], %w[Activate\ employee ACTIVATE_EMP],
       %w[Begin\ contract BEGIN_CONTRACT],
       %w[Resume\ contract RESUME_CONTRACT],
       %w[Activate\ IC ACTIVATE_IC],
       %w[Disability DISABILITY], %w[Inactivate INACTIVATE],
       %w[Jury\ duty JURY_DUTY], %w[Adoption\ leave ADOPTION_LEAVE],
       %w[education\ leave EDUCATION_LEAVE], %w[Family\ leave FAMILY_LEAVE],
       %w[Maternity\ leave MATERNITY_LEAVE], %w[Medial\ leave MEDICAL_LEAVE],
       %w[Military\ leave MILITARY_LEAVE],
       %w[Paternity\ leave PATERNITY_LEAVE],
       %w[Seasonal\ employmeny SEASONAL_EMPLOYMENT],
       %w[Contract\ on-hold CONTRACT_ON_HOLD],
       %w[Student\ on\ break STUDENT_ON_BREAK],
       %w[Work\ is\ slow WORK_IS_SLOW], %w[Custom\ unknown CUSTOM_UNKNOWN],
       %w[Termination TERMINATION], %w[Discharged DISCHARGED],
       %w[Resigned RESIGNED], %w[Retired RETIRED], %w[DECEASED DECEASED],
       %w[PEO\ services\ cancelled PEO_SERVICES_CANCELLED],
       %w[Terminate\ contract TERMINATE_CONTRACT],
       %w[Employee\ transfer EMPLOYEE_TRANSFER],
       %w[Pending\ hire PENDING_HIRE], %w[Pending\ rehire PENDING_REHIRE],
       %w[Pending\ contract PENDING_CONTRACT],
       %w[Pending\ hire PENDING_HIRE], %w[Pending\ sync PENDING_SYNC]]
    end,

    genders: lambda do |_connection|
      [%w[Male MALE], %w[Female FEMALE],
       %w[Unknown UNKNOWN], %w[Not\ specified NOT_SPECIFIED]]
    end,

    usage_types: lambda do |_connection|
      [%w[Personal PERSONAL], %w[Business BUSINESS]]
    end,

    worker_types: lambda do |_connection|
      [%w[Employee EMPLOYEE], %w[Contractor CONTRACTOR]]
    end,

    effect_on_pay_types: lambda do |_connection|
      [%w[Adds\ to\ pay ADDITION], %w[Reduces\ pay REDUCTION],
       %w[No\ effect\ on\ pay EMPLOYER_INFORMATIONAL],
       %w[Adds\ to\ pay\ for\ tax\ calculations ADDITION_WITH_IN_OUT]]
    end,

    classification_types: lambda do |_connection|
      [%w[1099 _1099], %w[1099\ Miscellaneous _1099_MISC], %w[401K _401K],
       %w[403B _403_B_], %w[414H _414H],
       %w[457\ Plan\ contribution _457_PLAN_CONTRIBUTIONS],
       %w[457\ Plan\ distribution _457_PLAN_DISTRIBUTIONS],
       %w[401K _401K], %w[501C\ trust _501C_TRUST],
       %w[Cafeteria\ plans CAFETERIA_PLANS], %w[Deduction DEDUCTION],
       %w[Draw DRAW], %w[Earnings EARNINGS],
       %w[Eduactional\ assistance EDUCATIONAL_ASSISTANCE],
       %w[Federal\ Health\ savings\ account FEDERAL_HEALTH_SAVINGS_ACCOUNT],
       %w[Fringe\ benefits FRINGE_BENEFITS], %w[Garnishment GARNISHMENTS],
       %w[Informational INFORMATIONAL], %w[IRA IRA], %w[IRC\ 105 IRC_105],
       %w[IRC\ 106 IRC_106], %w[IRC\ 129\ cafeteria IRC_129_CAFETERIA],
       %w[IRC\ 129\ fringe IRC_129_FRINGE],
       %w[IRC\ 137\ adoption\ assistance IRC_137_ADOPTION_ASSISTANCE],
       %w[IRC\ 137\ fringe\ benefits IRC_137_FRINGE_BENEFITS],
       %w[IRC\ 79\ group\ life\ insurance IRC_79_GROUP_TERM_LIFE_INSURANCE],
       %w[Miscellaneous MISCELLANEOUS], %w[Moving\ expenses MOVING_EXPENSES],
       %w[Non\ qualifed\ deferred\ compasation\ contributions
          NON_QUALIFIED_DEFERRED_COMPENSATION_CONTRIBUTIONS],
       %w[Non\ qualifed\ deferred\ compasation\ distributions
          NON_QUALIFIED_DEFERRED_COMPENSATION_DISTRIBUTIONS],
       %w[Private\ disability PRIVATE_DISABILITY], %w[Regular REGULAR],
       %w[Reimbursement REIMBURSEMENT], %w[Retirement RETIREMENT],
       %w[Sick\ pay SICK_PAY], %w[Stock\ options STOCK_OPTIONS],
       %w[Supplemental SUPPLEMENTAL], %w[Tips TIPS],
       %w[Transformation\ benefits TRANSPORTATION_BENEFIT],
       %w[Union\ dues UNION_DUES]]
    end,

    interval_code: lambda do |_connection|
      [%w[Annual ANNUAL], %w[Bi\ weekly BI_WEEKLY], %w[Monthly MONTHLY],
       %w[Quarterly QUARTERLY], %w[Semi\ annual SEMI_ANNUAL],
       %w[Semi\ monthly SEMI_MONTHLY], %w[Weekly WEEKLY]]
    end,

    pay_period_status: lambda do |_connection|
      [%w[Completed COMPLETED], %w[Completed\ by\ mec COMPLETED_BY_MEC],
       %w[Entry ENTRY], %w[Initial INITIAL], %w[Processing PROCESSING],
       %w[Reissued REISSUED], %w[Released RELEASED], %w[Reversed REVERSED]]
    end,

    ethnicity_code: lambda do |_connection|
      [%w[Hispanic\ or\ Latino HISPANIC_OR_LATINO],
       %w[White\ not\ of\ Hispanic\ origin WHITE_NOT_OF_HISPANIC_ORIGIN],
       %w[Black\ or\ African\ American BLACK_OR_AFRICAN_AMERICAN],
       %w[Native\ Hawaiian\ or\ other\ Pacific\ Island
          NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLAND],
       %w[American\ Indian\ or\ Alaskan\ Native
          AMERICAN_INDIAN_OR_ALASKAN_NATIVE],
       %w[Two\ or\ more\ races TWO_OR_MORE_RACES],
       %w[Asian\ or\ Pacific\ Islander ASIAN_OR_PACIFIC_ISLANDER]]
    end,

    legal_id_type: lambda do |_connection|
      [%w[Social\ Security\ Number SSN], %w[Social\ Insurance\ Number SIN],
       %w[Federal\ Employer\ Identification\ Number\ (EIN) FEIN],
       %w[Last\ 4\ digits\ of\ the\ Social\ Security\ Number SSNLast4]]
    end
  }
}
