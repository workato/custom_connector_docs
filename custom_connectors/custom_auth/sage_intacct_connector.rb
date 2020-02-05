{
  title: 'Sage Intacct (Custom)',

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

    parse_xml_to_hash: lambda do |xml_obj|
      xml_obj['xml']
        &.inject({}) do |hash, (key, value)|
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
        elsif key == 'content!'
          value
        else
          { key => value }
        end
      end&.presence
    end,

    get_object_definition: lambda do |input|
      type_map = {
        'string' => 'string',
        'integer' => 'integer',
        'date' => 'date',
        'boolean' => 'boolean',
        'datetime' => 'date_time',
        'currency' => 'number',
        'number' => 'number'
      }

      control_type_map = {
        'boolean' => 'checkbox',
        'date_time' => 'date_time',
        'date' => 'date',
        'number' => 'number'
      }

      render_input_map = {
        'date' => ->(field) { field&.to_date&.strftime('%m/%d/%Y') },
        'date_time' => lambda do |field|
          field&.to_time&.utc&.strftime('%m/%d/%Y %H:%M:%S')
        end
      }

      parse_output_map = {
        'integer' => 'integer_conversion',
        'date' => ->(field) { field&.to_date(format: '%m/%d/%Y') },
        'date_time' => lambda do |field|
          field&.to_time(format: '%m/%d/%Y %H:%M:%S')
        end,
        'number' => 'float_conversion'
      }

      input.map do |field|
        data_type = type_map[field['externalDataName']]
        hint = unless (description = field['Description'])
                      &.casecmp(label = field['DisplayLabel']) == 0
                 description
               end
        {
          name: (name = field['Name']),
          label: label,
          hint: hint,
          sticky: (name == 'NAME') || (name == 'RECORDNO') ||
            (name == 'DESCRIPTION'),
          render_input: render_input_map[data_type],
          parse_output: parse_output_map[data_type],
          control_type: control_type_map[data_type],
          type: data_type
        }.compact
      end
    end,

    get_api_response_result_element: lambda do |input|
      payload = {
        'control' => {},
        'operation' => {
          'authentication' => {},
          'content' => { 'function' => input }
        }
      }

      post('/ia/xml/xmlgw.phtml', payload)
        .dig('response', 0, 'operation', 0, 'result', 0)
    end,

    get_api_response_data_element: lambda do |input|
      call('get_api_response_result_element', input)&.dig('data', 0)
    end
  },

  connection: {
    fields: [
      { name: 'company_id', optional: false },
      { name: 'login_username', optional: false },
      { name: 'login_password', optional: false, control_type: 'password' },
      { name: 'sender_id', optional: false },
      { name: 'sender_password', optional: false, control_type: 'password' },
      {
        name: 'location_id',
        label: 'Location ID',
        hint: 'If not specified, it takes the top level (all entities). ' \
          'Only applicable to Multi-entity companies.',
        sticky: true
      }
    ],

    authorization: {
      type: 'custom_auth',

      acquire: lambda do |connection|
        payload = {
          'control' => {
            'senderid' => connection['sender_id'],
            'password' => connection['sender_password'],
            'controlid' => 'testControlId',
            'uniqueid' => false,
            'dtdversion' => 3.0
          },
          'operation' => {
            'authentication' => {
              'login' => {
                'userid' => connection['login_username'],
                'companyid' => connection['company_id'],
                'password' => connection['login_password'],
                'locationid' => connection['location_id']
              }.compact
            },
            'content' => {
              'function' => {
                '@controlid' => 'testControlId',
                'getAPISession' => ''
              }
            }
          }
        }.compact
        response_data = post('/ia/xml/xmlgw.phtml', payload)
                        .headers('Content-Type' => 'x-intacct-xml-request')
                        .format_xml('request')
                        .dig('response', 0,
                             'operation', 0,
                             'result', 0,
                             'data', 0)

        {
          session_id: call('parse_xml_to_hash',
                           'xml' => response_data,
                           'array_fields' => ['api'])
            &.dig('api', 0, 'sessionid')
        }
      end,

      refresh_on: [401, /Invalid session/],

      detect_on: [%r{<status>failure</status>}],

      apply: lambda do |connection|
        headers('Content-Type' => 'x-intacct-xml-request')
        payload do |current_payload|
          current_payload&.[]=(
            'control',
            {
              'senderid' => connection['sender_id'],
              'password' => connection['sender_password'],
              'controlid' => 'testControlId',
              'uniqueid' => false,
              'dtdversion' => 3.0
            }
          )
          current_payload&.[]('operation')&.[]=(
            'authentication', { 'sessionid' => connection['session_id'] }
          )
        end
        format_xml('request')
      end
    },

    base_uri: ->(_connection) { 'https://api.intacct.com' }
  },

  test: lambda do |_connection|
    payload = { 'control' => {}, 'operation' => { 'authentication' => {} } }

    post('/ia/xml/xmlgw.phtml', payload)
  end,

  object_definitions: {
    # Contracts
    contract: {
      fields: lambda do |_connection, _config_fields|
        function = {
          '@controlid' => 'testControlId',
          'inspect' => { '@detail' => '1', 'object' => 'CONTRACT' }
        }
        response_data = call('get_api_response_data_element', function)

        call('format_schema_field_names',
             call('get_object_definition',
                  call('parse_xml_to_hash',
                       'xml' => response_data,
                       'array_fields' => ['Field'])
                    &.dig('Type', 'Fields', 'Field')))
      end
    },

    # Contract line
    contract_line: {
      fields: lambda do |_connection, _config_fields|
        function = {
          '@controlid' => 'testControlId',
          'inspect' => { '@detail' => '1', 'object' => 'CONTRACTDETAIL' }
        }
        response_data = call('get_api_response_data_element', function)

        call('get_object_definition',
             call('parse_xml_to_hash',
                  'xml' => response_data,
                  'array_fields' => ['Field'])
               &.dig('Type', 'Fields', 'Field'))
      end
    },

    # Contract expense line
    contract_expense: {
      fields: lambda do |_connection, _config_fields|
        function = {
          '@controlid' => 'testControlId',
          'inspect' => { '@detail' => '1', 'object' => 'CONTRACTEXPENSE' }
        }
        response_data = call('get_api_response_data_element', function)

        call('get_object_definition',
             call('parse_xml_to_hash',
                  'xml' => response_data,
                  'array_fields' => ['Field'])
               &.dig('Type', 'Fields', 'Field'))
      end
    },

    employee: {
      fields: lambda do |_connection, _config_fields|
        function = {
          '@controlid' => 'testControlId',
          'inspect' => { '@detail' => '1', 'object' => 'EMPLOYEE' }
        }
        response_data = call('get_api_response_data_element', function)

        call('format_schema_field_names',
             call('get_object_definition',
                  call('parse_xml_to_hash',
                       'xml' => response_data,
                       'array_fields' => ['Field'])
                    &.dig('Type', 'Fields', 'Field')))
      end
    },

    employee_create: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'EMPLOYEEID', label: 'Employee ID', sticky: true },
          {
            name: 'PERSONALINFO',
            label: 'Personal info',
            hint: 'Contact info',
            optional: false,
            type: 'object',
            properties: [{
              name: 'CONTACTNAME',
              label: 'Contact name',
              hint: 'Contact name of an existing contact',
              optional: false,
              control_type: 'select',
              pick_list: 'contact_names',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'CONTACTNAME',
                label: 'Contact name',
                toggle_hint: 'Use custom value',
                control_type: 'text',
                type: 'string'
              }
            }]
          },
          {
            name: 'STARTDATE',
            label: 'Start date',
            render_input: ->(field) { field&.to_date&.strftime('%m/%d/%Y') },
            parse_output: ->(field) { field&.to_date(format: '%m/%d/%Y') },
            type: 'date'
          },
          { name: 'TITLE', label: 'Title' },
          {
            name: 'SSN',
            label: 'Social Security Number',
            hint: 'Do not include dashes.'
          },
          { name: 'EMPLOYEETYPE', label: 'Employee type' },
          {
            name: 'STATUS',
            label: 'Status',
            hint: 'Default: Active',
            control_type: 'select',
            pick_list: 'statuses',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'STATUS',
              label: 'Status',
              hint: 'Allowed values are: active, inactive',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'BIRTHDATE',
            label: 'Birth date',
            render_input: ->(field) { field&.to_date&.strftime('%m/%d/%Y') },
            parse_output: ->(field) { field&.to_date(format: '%m/%d/%Y') },
            type: 'date'
          },
          {
            name: 'ENDDATE',
            label: 'End date',
            render_input: ->(field) { field&.to_date&.strftime('%m/%d/%Y') },
            parse_output: ->(field) { field&.to_date(format: '%m/%d/%Y') },
            type: 'date'
          },
          {
            name: 'TERMINATIONTYPE',
            label: 'Termination type',
            control_type: 'select',
            pick_list: 'termination_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'TERMINATIONTYPE',
              label: 'Termination type',
              hint: 'Allowed values are: voluntary, involuntary, deceased, ' \
              'disability, and retired.',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'SUPERVISORID',
            label: 'Manager',
            control_type: 'select',
            pick_list: 'employees',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'SUPERVISORID',
              label: "Manager's employee ID",
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'GENDER',
            label: 'Gender',
            control_type: 'select',
            pick_list: 'genders',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'GENDER',
              label: 'Gender',
              hint: 'Allowed values are: male, female',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'DEPARTMENTID',
            label: 'Department',
            control_type: 'select',
            pick_list: 'departments',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'DEPARTMENTID',
              label: 'Department ID',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'LOCATIONID',
            label: 'Location',
            hint: 'Required only when an employee is created at the ' \
              'top level in a multi-entity, multi-base-currency company.',
            sticky: true,
            control_type: 'select',
            pick_list: 'locations',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'LOCATIONID',
              label: 'Location ID',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'CLASSID',
            label: 'Class',
            control_type: 'select',
            pick_list: 'classes',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'CLASSID',
              label: 'Class ID',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'CURRENCY',
            label: 'Currency',
            hint: 'Default currency code'
          },
          { name: 'EARNINGTYPENAME', label: 'Earning type name' },
          {
            name: 'POSTACTUALCOST',
            label: 'Post actual cost',
            hint: 'Default: No',
            control_type: 'checkbox',
            type: 'boolean',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'POSTACTUALCOST',
              label: 'Post actual cost',
              hint: 'Allowed values are: true, false',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'boolean'
            }
          },
          { name: 'NAME1099', label: 'Name 1099', hint: 'Form 1099 name' },
          { name: 'FORM1099TYPE', label: 'Form 1099 type' },
          { name: 'FORM1099BOX', label: 'Form 1099 box' },
          {
            name: 'SUPDOCFOLDERNAME',
            label: 'Supporting doc folder name',
            hint: 'Attachment folder name'
          },
          { name: 'PAYMETHODKEY', label: 'Preferred payment method' },
          {
            name: 'PAYMENTNOTIFY',
            label: 'Payment notify',
            hint: 'Send automatic payment notification. Default: No',
            control_type: 'checkbox',
            type: 'boolean',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'PAYMENTNOTIFY',
              label: 'Payment notify',
              hint: 'Allowed values are: true, false',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'boolean'
            }
          },
          {
            name: 'MERGEPAYMENTREQ',
            label: 'Merge payment requests',
            hint: 'Default: Yes',
            control_type: 'checkbox',
            type: 'boolean',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'MERGEPAYMENTREQ',
              label: 'Merge payment requests',
              hint: 'Allowed values are: true, false',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'boolean'
            }
          },
          {
            name: 'ACHENABLED',
            label: 'ACH enabled',
            hint: 'Default: No',
            control_type: 'checkbox',
            type: 'boolean',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'ACHENABLED',
              label: 'ACH enabled',
              hint: 'Allowed values are: true, false',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'boolean'
            }
          },
          { name: 'ACHBANKROUTINGNUMBER', label: 'ACH bank routing number' },
          { name: 'ACHACCOUNTNUMBER', label: 'ACH account number' },
          { name: 'ACHACCOUNTTYPE', label: 'ACH account type' },
          { name: 'ACHREMITTANCETYPE', label: 'ACH remittance type' },
          {
            name: 'customfields',
            label: 'Custom fields/dimensions',
            sticky: true,
            type: 'array',
            of: 'object',
            properties: [{
              name: 'customfield',
              label: 'Custom field/dimension',
              sticky: true,
              type: 'array',
              of: 'object',
              properties: [
                {
                  name: 'customfieldname',
                  label: 'Custom field/dimension name',
                  hint: 'Integration name of the custom field or ' \
                    'custom dimension. Find integration name in object ' \
                    'definition page of the respective object. Prepend ' \
                    "custom dimension with 'GLDIM'; e.g., if the " \
                    'custom dimension is Rating, use ' \
                    "'<b>GLDIM</b>Rating' as integration name here.",
                  sticky: true
                },
                {
                  name: 'customfieldvalue',
                  label: 'Custom field/dimension value',
                  hint: 'The value of custom field or custom dimension',
                  sticky: true
                }
              ]
            }]
          }
        ]
      end
    },

    employee_get: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'EMPLOYEEID',
            label: 'Employee',
            sticky: true,
            control_type: 'select',
            pick_list: 'employees',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'EMPLOYEEID',
              label: 'Employee ID',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'PERSONALINFO',
            label: 'Personal info',
            hint: 'Contact info',
            type: 'object',
            properties: [
              {
                name: 'CONTACTNAME',
                label: 'Contact name',
                hint: 'Contact name of an existing contact'
              },
              { name: 'PRINTAS', label: 'Print as' },
              { name: 'COMPANYNAME', label: 'Company name' },
              {
                name: 'TAXABLE',
                label: 'Taxable',
                control_type: 'checkbox',
                type: 'boolean',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'TAXABLE',
                  label: 'Taxable',
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'boolean'
                }
              },
              {
                name: 'TAXGROUP',
                label: 'Tax group',
                hint: 'Contact tax group name'
              },
              { name: 'PREFIX', label: 'Prefix' },
              { name: 'FIRSTNAME', label: 'First name' },
              { name: 'LASTNAME', label: 'Last name' },
              { name: 'INITIAL', label: 'Initial', hint: 'Middle name' },
              {
                name: 'PHONE1',
                label: 'Primary phone number',
                control_type: 'phone'
              },
              {
                name: 'PHONE2',
                label: 'Secondary phone number',
                control_type: 'phone'
              },
              {
                name: 'CELLPHONE',
                label: 'Cellphone',
                hint: 'Cellular phone number',
                control_type: 'phone'
              },
              { name: 'PAGER', label: 'Pager', hint: 'Pager number' },
              { name: 'FAX', label: 'Fax', hint: 'Fax number' },
              {
                name: 'EMAIL1',
                label: 'Primary email address',
                control_type: 'email'
              },
              {
                name: 'EMAIL2',
                label: 'Secondary email address',
                control_type: 'email'
              },
              {
                name: 'URL1',
                label: 'Primary URL',
                control_type: 'url'
              },
              {
                name: 'URL2',
                label: 'Secondary URL',
                control_type: 'url'
              },
              {
                name: 'STATUS',
                label: 'Status',
                control_type: 'select',
                pick_list: 'statuses',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'STATUS',
                  label: 'Status',
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'string'
                }
              },
              {
                name: 'MAILADDRESS',
                label: 'Mailing information',
                type: 'object',
                properties: [
                  { name: 'ADDRESS1', label: 'Address line 1' },
                  { name: 'ADDRESS2', label: 'Address line 2' },
                  { name: 'CITY', label: 'City' },
                  { name: 'STATE', label: 'State', hint: 'State/province' },
                  { name: 'ZIP', label: 'Zip', hint: 'Zip/postal code' },
                  { name: 'COUNTRY', label: 'Country' }
                ]
              }
            ]
          },
          {
            name: 'STARTDATE',
            label: 'Start date',
            render_input: ->(field) { field&.to_date&.strftime('%m/%d/%Y') },
            parse_output: ->(field) { field&.to_date(format: '%m/%d/%Y') },
            type: 'date'
          },
          { name: 'TITLE', label: 'Title', sticky: true },
          {
            name: 'SSN',
            label: 'Social Security Number',
            hint: 'Do not include dashes'
          },
          { name: 'EMPLOYEETYPE', label: 'Employee type' },
          {
            name: 'STATUS',
            label: 'Status',
            control_type: 'select',
            pick_list: 'statuses',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'STATUS',
              label: 'Status',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'BIRTHDATE',
            label: 'Birth date',
            render_input: ->(field) { field&.to_date&.strftime('%m/%d/%Y') },
            parse_output: ->(field) { field&.to_date(format: '%m/%d/%Y') },
            type: 'date'
          },
          {
            name: 'ENDDATE',
            label: 'End date',
            render_input: ->(field) { field&.to_date&.strftime('%m/%d/%Y') },
            parse_output: ->(field) { field&.to_date(format: '%m/%d/%Y') },
            type: 'date'
          },
          {
            name: 'TERMINATIONTYPE',
            label: 'Termination type',
            control_type: 'select',
            pick_list: 'termination_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'TERMINATIONTYPE',
              label: 'Termination type',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'SUPERVISORID',
            label: 'Manager',
            control_type: 'select',
            pick_list: 'employees',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'SUPERVISORID',
              label: "Manager's employee ID",
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'GENDER',
            label: 'Gender',
            control_type: 'select',
            pick_list: 'genders',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'GENDER',
              label: 'Gender',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'DEPARTMENTID',
            label: 'Department',
            sticky: true,
            control_type: 'select',
            pick_list: 'departments',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'DEPARTMENTID',
              label: 'Department ID',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'LOCATIONID',
            label: 'Location',
            hint: 'Required only when an employee is created at the ' \
              'top level in a multi-entity, multi-base-currency company.',
            sticky: true,
            control_type: 'select',
            pick_list: 'locations',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'LOCATIONID',
              label: 'Location ID',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'CLASSID',
            label: 'Class',
            sticky: true,
            control_type: 'select',
            pick_list: 'classes',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'CLASSID',
              label: 'Class ID',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'CURRENCY',
            label: 'Currency',
            hint: 'Default currency code'
          },
          { name: 'EARNINGTYPENAME', label: 'Earning type name' },
          {
            name: 'POSTACTUALCOST',
            label: 'Post actual cost',
            control_type: 'checkbox',
            type: 'boolean',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'POSTACTUALCOST',
              label: 'Post actual cost',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'boolean'
            }
          },
          { name: 'NAME1099', label: 'Name 1099', hint: 'Form 1099 name' },
          { name: 'FORM1099TYPE', label: 'Form 1099 type' },
          { name: 'FORM1099BOX', label: 'Form 1099 box' },
          {
            name: 'SUPDOCFOLDERNAME',
            label: 'Supporting doc folder name',
            hint: 'Attachment folder name'
          },
          { name: 'PAYMETHODKEY', label: 'Preferred payment method' },
          {
            name: 'PAYMENTNOTIFY',
            label: 'Payment notify',
            hint: 'Send automatic payment notification',
            control_type: 'checkbox',
            type: 'boolean',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'PAYMENTNOTIFY',
              label: 'Payment notify',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'boolean'
            }
          },
          {
            name: 'MERGEPAYMENTREQ',
            label: 'Merge payment requests',
            control_type: 'checkbox',
            type: 'boolean',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'MERGEPAYMENTREQ',
              label: 'Merge payment requests',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'boolean'
            }
          },
          {
            name: 'ACHENABLED',
            label: 'ACH enabled',
            control_type: 'checkbox',
            type: 'boolean',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'ACHENABLED',
              label: 'ACH enabled',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'boolean'
            }
          },
          { name: 'ACHBANKROUTINGNUMBER', label: 'ACH bank routing number' },
          { name: 'ACHACCOUNTNUMBER', label: 'ACH account number' },
          { name: 'ACHACCOUNTTYPE', label: 'ACH account type' },
          { name: 'ACHREMITTANCETYPE', label: 'ACH remittance type' },
          {
            name: 'WHENCREATED',
            label: 'Created date',
            parse_output: lambda do |field|
              field&.to_time(format: '%m/%d/%Y %H:%M:%S')
            end,
            type: 'timestamp'
          },
          {
            name: 'WHENMODIFIED',
            label: 'Modified date',
            parse_output: lambda do |field|
              field&.to_time(format: '%m/%d/%Y %H:%M:%S')
            end,
            type: 'timestamp'
          },
          { name: 'CREATEDBY', label: 'Created by' },
          { name: 'MODIFIEDBY', label: 'Modified by' }
        ]
      end
    },

    employee_update: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'RECORDNO',
            label: 'Record number',
            sticky: true,
            type: 'integer'
          },
          { name: 'EMPLOYEEID', label: 'Employee ID', sticky: true },
          {
            name: 'PERSONALINFO',
            label: 'Personal info',
            hint: 'Contact info',
            type: 'object',
            properties: [{
              name: 'CONTACTNAME',
              label: 'Contact name',
              hint: 'Contact name of an existing contact',
              control_type: 'select',
              pick_list: 'contact_names',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'CONTACTNAME',
                label: 'Contact name',
                toggle_hint: 'Use custom value',
                control_type: 'text',
                type: 'string'
              }
            }]
          },
          {
            name: 'STARTDATE',
            label: 'Start date',
            render_input: ->(field) { field&.to_date&.strftime('%m/%d/%Y') },
            parse_output: ->(field) { field&.to_date(format: '%m/%d/%Y') },
            type: 'date'
          },
          { name: 'TITLE', label: 'Title', sticky: true },
          {
            name: 'SSN',
            label: 'Social Security Number',
            hint: 'Do not include dashes.'
          },
          { name: 'EMPLOYEETYPE', label: 'Employee type' },
          {
            name: 'STATUS',
            label: 'Status',
            hint: 'Default: Active',
            control_type: 'select',
            pick_list: 'statuses',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'STATUS',
              label: 'Status',
              hint: 'Allowed values are: active, inactive',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'BIRTHDATE',
            label: 'Birth date',
            render_input: ->(field) { field&.to_date&.strftime('%m/%d/%Y') },
            parse_output: ->(field) { field&.to_date(format: '%m/%d/%Y') },
            type: 'date'
          },
          {
            name: 'ENDDATE',
            label: 'End date',
            render_input: ->(field) { field&.to_date&.strftime('%m/%d/%Y') },
            parse_output: ->(field) { field&.to_date(format: '%m/%d/%Y') },
            type: 'date'
          },
          {
            name: 'TERMINATIONTYPE',
            label: 'Termination type',
            control_type: 'select',
            pick_list: 'termination_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'TERMINATIONTYPE',
              label: 'Termination type',
              hint: 'Allowed values are: voluntary, involuntary, deceased, ' \
              'disability, and retired.',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'SUPERVISORID',
            label: 'Manager',
            control_type: 'select',
            pick_list: 'employees',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'SUPERVISORID',
              label: "Manager's employee ID",
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'GENDER',
            label: 'Gender',
            control_type: 'select',
            pick_list: 'genders',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'GENDER',
              label: 'Gender',
              hint: 'Allowed values are: male, female',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'DEPARTMENTID',
            label: 'Department',
            sticky: true,
            control_type: 'select',
            pick_list: 'departments',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'DEPARTMENTID',
              label: 'Department ID',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'LOCATIONID',
            label: 'Location',
            hint: 'Required only when an employee is created at the ' \
              'top level in a multi-entity, multi-base-currency company.',
            sticky: true,
            control_type: 'select',
            pick_list: 'locations',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'LOCATIONID',
              label: 'Location ID',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'CLASSID',
            label: 'Class',
            sticky: true,
            control_type: 'select',
            pick_list: 'classes',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'CLASSID',
              label: 'Class ID',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'CURRENCY',
            label: 'Currency',
            hint: 'Default currency code'
          },
          { name: 'EARNINGTYPENAME', label: 'Earning type name' },
          {
            name: 'POSTACTUALCOST',
            label: 'Post actual cost',
            hint: 'Default: No',
            control_type: 'checkbox',
            type: 'boolean',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'POSTACTUALCOST',
              label: 'Post actual cost',
              hint: 'Allowed values are: true, false',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'boolean'
            }
          },
          { name: 'NAME1099', label: 'Name 1099', hint: 'Form 1099 name' },
          { name: 'FORM1099TYPE', label: 'Form 1099 type' },
          { name: 'FORM1099BOX', label: 'Form 1099 box' },
          {
            name: 'SUPDOCFOLDERNAME',
            label: 'Supporting doc folder name',
            hint: 'Attachment folder name'
          },
          { name: 'PAYMETHODKEY', label: 'Preferred payment method' },
          {
            name: 'PAYMENTNOTIFY',
            label: 'Payment notify',
            hint: 'Send automatic payment notification. Default: No',
            control_type: 'checkbox',
            type: 'boolean',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'PAYMENTNOTIFY',
              label: 'Payment notify',
              hint: 'Allowed values are: true, false',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'boolean'
            }
          },
          {
            name: 'MERGEPAYMENTREQ',
            label: 'Merge payment requests',
            hint: 'Default: Yes',
            control_type: 'checkbox',
            type: 'boolean',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'MERGEPAYMENTREQ',
              label: 'Merge payment requests',
              hint: 'Allowed values are: true, false',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'boolean'
            }
          },
          {
            name: 'ACHENABLED',
            label: 'ACH enabled',
            hint: 'Default: No',
            control_type: 'checkbox',
            type: 'boolean',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'ACHENABLED',
              label: 'ACH enabled',
              hint: 'Allowed values are: true, false',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'boolean'
            }
          },
          { name: 'ACHBANKROUTINGNUMBER', label: 'ACH bank routing number' },
          { name: 'ACHACCOUNTNUMBER', label: 'ACH account number' },
          { name: 'ACHACCOUNTTYPE', label: 'ACH account type' },
          { name: 'ACHREMITTANCETYPE', label: 'ACH remittance type' },
          {
            name: 'customfields',
            label: 'Custom fields/dimensions',
            sticky: true,
            type: 'array',
            of: 'object',
            properties: [{
              name: 'customfield',
              label: 'Custom field/dimension',
              sticky: true,
              type: 'array',
              of: 'object',
              properties: [
                {
                  name: 'customfieldname',
                  label: 'Custom field/dimension name',
                  hint: 'Integration name of the custom field or ' \
                    'custom dimension. Find integration name in object ' \
                    'definition page of the respective object. Prepend ' \
                    "custom dimension with 'GLDIM'; e.g., if the " \
                    'custom dimension is Rating, use ' \
                    "'<b>GLDIM</b>Rating' as integration name here.",
                  sticky: true
                },
                {
                  name: 'customfieldvalue',
                  label: 'Custom field/dimension value',
                  hint: 'The value of custom field or custom dimension',
                  sticky: true
                }
              ]
            }]
          }
        ]
      end
    },

    # Contract MEA Bundle
    contract_mea_bundle: {
      fields: lambda do |_connection, _config_fields|
        function = {
          '@controlid' => 'testControlId',
          'inspect' => { '@detail' => '1', 'object' => 'CONTRACTMEABUNDLE' }
        }
        response_data = call('get_api_response_data_element', function)

        call('format_schema_field_names',
             call('get_object_definition',
                  call('parse_xml_to_hash',
                       'xml' => response_data,
                       'array_fields' => ['Field'])
                    &.dig('Type', 'Fields', 'Field')))
      end
    },

    contract_mea_bundle_create: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'CONTRACTID', label: 'Contract ID' },
          { name: 'NAME' },
          { name: 'DESCRIPTION' },
          {
            name: 'EFFECTIVEDATE',
            label: 'Effective date',
            control_type: 'date',
            type: 'date'
          },
          {
            name: 'ADJUSTMENTPROCESS',
            label: 'Adjustment process',
            sticky: true,
            control_type: 'select',
            pick_list: 'adjustment_process_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'ADJUSTMENTPROCESS',
              label: 'Adjustment process',
              hint: 'Allowed values are: One time, Distributed',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'TYPE',
            label: 'Type',
            default: 'MEA Bundle',
            control_type: 'select',
            pick_list: 'mea_types',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'TYPE',
              label: 'Type',
              hint: 'Allowed value is: MEA Bundle',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            control_type: 'checkbox',
            label: 'Apply to journal 1',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Apply to journal 1',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'APPLYTOJOURNAL1'
            },
            type: 'boolean',
            name: 'APPLYTOJOURNAL1'
          },
          {
            control_type: 'checkbox',
            label: 'Apply to journal 2',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Apply to journal 2',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'APPLYTOJOURNAL2'
            },
            type: 'boolean',
            name: 'APPLYTOJOURNAL2'
          },
          { name: 'COMMENTS' },
          {
            name: 'CONTRACTMEABUNDLEENTRIES',
            label: 'Contract MEA bundle entries',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'CONTRACTDETAILLINENO',
                label: 'Contract detail line number',
                type: 'integer'
              },
              { name: 'BUNDLENO', label: 'Bundle number', type: 'integer' },
              {
                name: 'MEA_AMOUNT',
                label: 'MEA amount',
                control_type: 'number',
                parse_output: 'float_conversion',
                type: 'number'
              }
            ]
          }
        ]
      end
    },

    # Create & Update GL Entry
    gl_batch: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'JOURNAL',
            hint: 'GL journal symbol. This determines the type of journal ' \
            'entry as visible in the UI, for example, Regular, Adjustment, ' \
            'User-defined, Statistical, GAAP, Tax, and so forth.'
          },
          {
            name: 'RECORDNO',
            label: 'Record number',
            hint: "Journal entry 'Record number' to update",
            sticky: true,
            type: 'integer'
          },
          {
            name: 'BATCH_DATE',
            label: 'Batch date',
            hint: 'Posting date',
            sticky: true,
            render_input: ->(field) { field&.to_date&.strftime('%m/%d/%Y') },
            parse_output: ->(field) { field&.to_date(format: '%m/%d/%Y') },
            type: 'date'
          },
          {
            name: 'REVERSEDATE',
            label: 'Reverse date',
            hint: 'Reverse date must be greater than Batch date.',
            render_input: lambda do |field|
              field&.to_date&.strftime('%m/%d/%Y')
            end,
            parse_output: lambda do |field|
              field&.to_date(format: '%m/%d/%Y')
            end,
            type: 'date'
          },
          {
            name: 'BATCH_TITLE',
            label: 'Batch title',
            hint: 'Description of entry',
            sticky: true
          },
          {
            name: 'TAXIMPLICATIONS',
            label: 'Tax implications',
            hint: 'Tax implications. Use None, Inbound for purchase tax, ' \
            'or Outbound for sales tax.(AU, GB only)',
            control_type: 'select',
            pick_list: 'tax_implications',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'TAXIMPLICATIONS',
              label: 'Tax implications',
              hint: 'Tax implications. Use None, Inbound for purchase tax, ' \
              'or Outbound for sales tax.(AU, GB only)',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'VATVENDORID',
            label: 'VAT vendor ID',
            hint: 'Vendor ID when tax implications is set to Inbound for ' \
            'tax on purchases (AU, GB only)'
          },
          {
            name: 'VATCUSTOMERID',
            label: 'VAT customer ID',
            hint: 'Customer ID when tax implications is set to Outbound for ' \
            'tax on sales (AU, GB only)'
          },
          {
            name: 'VATCONTACTID',
            label: 'VAT contact ID',
            hint: 'Contact name for the customer SHIPTO contact for sales ' \
            'journals or the vendor ID for the vendor PAYTO contact for ' \
            'purchase journals (AU, GB only)'
          },
          {
            name: 'HISTORY_COMMENT',
            label: 'History comment',
            hint: 'Comment added to history for this transaction'
          },
          {
            name: 'REFERENCENO',
            label: 'Reference number of transaction',
            sticky: true
          },
          {
            name: 'BASELOCATION_NO',
            label: 'Baselocation number',
            hint: 'Source entity ID. Required if multi-entity enabled and ' \
              'entries do not balance by entity.',
            sticky: true
          },
          { name: 'SUPDOCID', label: 'Attachments ID' },
          {
            name: 'STATE',
            label: 'State',
            hint: 'State to update the entry to. Posted to post to the GL, ' \
              'otherwise Draft.',
            control_type: 'select',
            pick_list: 'update_gl_entry_states',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'STATE',
              label: 'State',
              hint: 'Allowed values are: Draft, Posted',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'ENTRIES',
            hint: 'Must have at least two lines (one debit, one credit).',
            type: 'object',
            properties: [{
              name: 'GLENTRY',
              label: 'GL Entry',
              hint: 'Must have at least two lines (one debit, one credit)',
              optional: false,
              type: 'array',
              of: 'object',
              properties: [
                { name: 'DOCUMENT', label: 'Document number' },
                { name: 'ACCOUNTNO', label: 'Account number', optional: false },
                {
                  name: 'CURRENCY',
                  label: 'Currency',
                  hint: 'Transaction currency code. Required if ' \
                    'multi-currency enabled.'
                },
                {
                  name: 'TRX_AMOUNT',
                  label: 'Transaction amount',
                  hint: 'Absolute value, relates to Transaction type.',
                  optional: false,
                  control_type: 'number',
                  parse_output: 'float_conversion',
                  type: 'number'
                },
                {
                  name: 'TR_TYPE',
                  label: 'Transaction type',
                  optional: false,
                  control_type: 'select',
                  pick_list: 'tr_types',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'TR_TYPE',
                    label: 'Transaction type',
                    hint: 'Allowed values are: 1 (Debit), -1 (Credit).',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'EXCH_RATE_DATE',
                  label: 'Exchange rate date',
                  hint: 'If null, defaults to Batch date',
                  render_input: lambda do |field|
                    field&.to_date&.strftime('%m/%d/%Y')
                  end,
                  parse_output: lambda do |field|
                    field&.to_date(format: '%m/%d/%Y')
                  end,
                  type: 'date'
                },
                {
                  name: 'EXCH_RATE_TYPE_ID',
                  label: 'Exchange rate type ID',
                  hint: 'Required if multi-currency ' \
                    'enabled and EXCHANGE_RATE left blank. ' \
                    '(Default Intacct Daily Rate)'
                },
                {
                  name: 'EXCHANGE_RATE',
                  label: 'Exchange rate',
                  hint: 'Required if multi currency enabled ' \
                  'and Exch rate type ID left blank. Exchange rate amount ' \
                  'to 4 decimals.',
                  control_type: 'number',
                  parse_output: 'float_conversion',
                  type: 'number'
                },
                {
                  name: 'DESCRIPTION',
                  label: 'Description',
                  hint: 'Memo. If left blank, set this value to match Batch ' \
                  'title.'
                },
                {
                  name: 'ALLOCATION',
                  label: 'Allocation ID',
                  hint: 'All other dimension elements are ' \
                  'ignored if allocation is set. Use `Custom` for ' \
                  'custom splits and see `Split` element below.',
                  sticky: true
                },
                {
                  name: 'DEPARTMENT',
                  label: 'Department',
                  control_type: 'select',
                  pick_list: 'departments',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'DEPARTMENT',
                    label: 'Department ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'LOCATION',
                  label: 'Location',
                  hint: 'Required if multi-entity enabled',
                  sticky: true,
                  control_type: 'select',
                  pick_list: 'locations',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'LOCATION',
                    label: 'Location ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'PROJECTID',
                  label: 'Project',
                  control_type: 'select',
                  pick_list: 'projects',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'PROJECTID',
                    label: 'Project ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'TASKID',
                  label: 'Task ID',
                  hint: 'Task ID. Only available when the parent ' \
                  'Project/Project ID is also specified.'
                },
                {
                  name: 'CUSTOMERID',
                  label: 'Customer',
                  control_type: 'select',
                  pick_list: 'customers',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'CUSTOMERID',
                    label: 'Customer ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'VENDORID',
                  label: 'Vendor',
                  control_type: 'select',
                  pick_list: 'vendors',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'VENDORID',
                    label: 'Vendor ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'EMPLOYEEID',
                  label: 'Employee',
                  control_type: 'select',
                  pick_list: 'employees',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'EMPLOYEEID',
                    label: 'Employee ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'ITEMID',
                  label: 'Item',
                  control_type: 'select',
                  pick_list: 'items',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'ITEMID',
                    label: 'Item ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'CLASSID',
                  label: 'Class',
                  control_type: 'select',
                  pick_list: 'classes',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'CLASSID',
                    label: 'Class ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                { name: 'CONTRACTID', label: 'Contract ID' },
                {
                  name: 'WAREHOUSEID',
                  label: 'Warehouse',
                  control_type: 'select',
                  pick_list: 'warehouses',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'WAREHOUSEID',
                    label: 'Warehouse ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'BILLABLE',
                  hint: 'Billable option for project-related transactions ' \
                  'imported into the GL through external systems. Use Yes ' \
                  'for billable transactions (Default: No)',
                  control_type: 'checkbox',
                  type: 'boolean',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'BILLABLE',
                    label: 'Billable',
                    hint: 'Billable option for project-related transactions ' \
                    'imported into the GL through external systems. Use true ' \
                    'for billable transactions (Default: false)',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'boolean'
                  }
                },
                {
                  name: 'SPLIT',
                  label: 'Split',
                  hint: 'Custom allocation split. Required if ALLOCATION ' \
                  'equals Custom. Multiple SPLIT elements may then be passed.',
                  sticky: true,
                  type: 'array',
                  of: 'object',
                  properties: [
                    {
                      name: 'AMOUNT',
                      label: 'Amount',
                      hint: 'A required field. Split transaction amount. ' \
                      'Absolute value. All SPLIT element’s amount values ' \
                      'must sum up to equal GLENTRY element’s Transaction ' \
                      'amount',
                      sticky: true,
                      control_type: 'number',
                      parse_output: 'float_conversion',
                      type: 'number'
                    },
                    {
                      name: 'DEPARTMENT',
                      label: 'Department',
                      control_type: 'select',
                      pick_list: 'departments',
                      toggle_hint: 'Select from list',
                      toggle_field: {
                        name: 'DEPARTMENT',
                        label: 'Department ID',
                        toggle_hint: 'Use custom value',
                        control_type: 'text',
                        type: 'string'
                      }
                    },
                    {
                      name: 'LOCATION',
                      label: 'Location',
                      hint: 'Required if multi-entity enabled',
                      sticky: true,
                      control_type: 'select',
                      pick_list: 'locations',
                      toggle_hint: 'Select from list',
                      toggle_field: {
                        name: 'LOCATION',
                        label: 'Location ID',
                        toggle_hint: 'Use custom value',
                        control_type: 'text',
                        type: 'string'
                      }
                    },
                    {
                      name: 'PROJECTID',
                      label: 'Project',
                      control_type: 'select',
                      pick_list: 'projects',
                      toggle_hint: 'Select from list',
                      toggle_field: {
                        name: 'PROJECTID',
                        label: 'Project ID',
                        toggle_hint: 'Use custom value',
                        control_type: 'text',
                        type: 'string'
                      }
                    },
                    {
                      name: 'TASKID',
                      label: 'Task ID',
                      hint: 'Task ID. Only available when the parent ' \
                      'Project/Project ID is also specified.'
                    },
                    {
                      name: 'CUSTOMERID',
                      label: 'Customer',
                      control_type: 'select',
                      pick_list: 'customers',
                      toggle_hint: 'Select from list',
                      toggle_field: {
                        name: 'CUSTOMERID',
                        label: 'Customer ID',
                        toggle_hint: 'Use custom value',
                        control_type: 'text',
                        type: 'string'
                      }
                    },
                    {
                      name: 'VENDORID',
                      label: 'Vendor',
                      control_type: 'select',
                      pick_list: 'vendors',
                      toggle_hint: 'Select from list',
                      toggle_field: {
                        name: 'VENDORID',
                        label: 'Vendor ID',
                        toggle_hint: 'Use custom value',
                        control_type: 'text',
                        type: 'string'
                      }
                    },
                    {
                      name: 'EMPLOYEEID',
                      label: 'Employee',
                      control_type: 'select',
                      pick_list: 'employees',
                      toggle_hint: 'Select from list',
                      toggle_field: {
                        name: 'EMPLOYEEID',
                        label: 'Employee ID',
                        toggle_hint: 'Use custom value',
                        control_type: 'text',
                        type: 'string'
                      }
                    },
                    {
                      name: 'ITEMID',
                      label: 'Item',
                      control_type: 'select',
                      pick_list: 'items',
                      toggle_hint: 'Select from list',
                      toggle_field: {
                        name: 'ITEMID',
                        label: 'Item ID',
                        toggle_hint: 'Use custom value',
                        control_type: 'text',
                        type: 'string'
                      }
                    },
                    {
                      name: 'CLASSID',
                      label: 'Class',
                      control_type: 'select',
                      pick_list: 'classes',
                      toggle_hint: 'Select from list',
                      toggle_field: {
                        name: 'CLASSID',
                        label: 'Class ID',
                        toggle_hint: 'Use custom value',
                        control_type: 'text',
                        type: 'string'
                      }
                    },
                    { name: 'CONTRACTID', label: 'Contract ID' },
                    {
                      name: 'WAREHOUSEID',
                      label: 'Warehouse',
                      control_type: 'select',
                      pick_list: 'warehouses',
                      toggle_hint: 'Select from list',
                      toggle_field: {
                        name: 'WAREHOUSEID',
                        label: 'Warehouse ID',
                        toggle_hint: 'Use custom value',
                        control_type: 'text',
                        type: 'string'
                      }
                    }
                  ]
                },
                {
                  name: 'customfields',
                  label: 'Custom fields/dimensions',
                  sticky: true,
                  type: 'array',
                  of: 'object',
                  properties: [{
                    name: 'customfield',
                    label: 'Custom field/dimension',
                    sticky: true,
                    type: 'array',
                    of: 'object',
                    properties: [
                      {
                        name: 'customfieldname',
                        label: 'Custom field/dimension name',
                        hint: 'Integration name of the custom field or ' \
                          'custom dimension. Find integration name in object ' \
                          'definition page of the respective object. Prepend ' \
                          "custom dimension with 'GLDIM'; e.g., if the " \
                          'custom dimension is Rating, use ' \
                          "'<b>GLDIM</b>Rating' as integration name here.",
                        sticky: true
                      },
                      {
                        name: 'customfieldvalue',
                        label: 'Custom field/dimension value',
                        hint: 'The value of custom field or custom dimension',
                        sticky: true
                      }
                    ]
                  }]
                },
                {
                  name: 'TAXENTRIES',
                  label: 'Tax entries',
                  hint: 'Tax entry for the line (AU, GB only).',
                  sticky: true,
                  type: 'array',
                  of: 'object',
                  properties: [
                    {
                      name: 'RECORDNO',
                      label: 'Record number',
                      hint: 'Record number of an existing tax entry ' \
                      '(associated with this line) that you want to modify. ' \
                      'You can omit this parameter to create a new tax entry.',
                      type: 'integer'
                    },
                    {
                      name: 'DETAILID',
                      label: 'Detail ID',
                      hint: 'Required field. Tax rate specified via the ' \
                      'unique ID of a tax detail.',
                      sticky: true
                    },
                    {
                      name: 'TRX_TAX',
                      label: 'Transaction tax',
                      hint: 'Transaction tax, which is your manually ' \
                      'calculated value for the tax.',
                      sticky: true,
                      control_type: 'number',
                      parse_output: 'float_conversion',
                      type: 'number'
                    }
                  ]
                }
              ]
            }]
          },
          {
            name: 'customfields',
            label: 'Custom fields/dimensions',
            sticky: true,
            type: 'array',
            of: 'object',
            properties: [{
              name: 'customfield',
              label: 'Custom field/dimension',
              sticky: true,
              type: 'array',
              of: 'object',
              properties: [
                {
                  name: 'customfieldname',
                  label: 'Custom field/dimension name',
                  hint: 'Integration name of the custom field or ' \
                    'custom dimension. Find integration name in object ' \
                    'definition page of the respective object. Prepend ' \
                    "custom dimension with 'GLDIM'; e.g., if the " \
                    'custom dimension is Rating, use ' \
                    "'<b>GLDIM</b>Rating' as integration name here.",
                  sticky: true
                },
                {
                  name: 'customfieldvalue',
                  label: 'Custom field/dimension value',
                  hint: 'The value of custom field or custom dimension',
                  sticky: true
                }
              ]
            }]
          }
        ]
      end
    },

    # Invoice
    invoice: {
      fields: lambda do |_connection, _config_fields|
        function = {
          '@controlid' => 'testControlId',
          'inspect' => { '@detail' => '1', 'object' => 'ARINVOICE' }
        }
        response_data = call('get_api_response_data_element', function)

        call('format_schema_field_names',
             call('get_object_definition',
                  call('parse_xml_to_hash',
                       'xml' => response_data,
                       'array_fields' => ['Field'])
                    &.dig('Type', 'Fields', 'Field')))
      end
    },

    lagacy_create_or_update_response: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'status' },
          { name: 'function' },
          { name: 'controlid', label: 'Control ID' },
          { name: 'key', label: 'Record key' }
        ]
      end
    },

    # Purchase order transaction
    po_txn_header: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: '@key',
            label: 'Key',
            hint: 'Document ID of purchase transaction'
          },
          {
            name: 'datecreated',
            label: 'Date created',
            hint: 'Transaction date',
            render_input: lambda do |field|
              if (raw_date = field&.to_date)
                {
                  'year' => raw_date&.strftime('%Y') || '',
                  'month' => raw_date&.strftime('%m') || '',
                  'day' => raw_date&.strftime('%d') || ''
                }
              end
            end,
            type: 'date'
          },
          {
            name: 'dateposted',
            label: 'Date posted',
            hint: 'GL posting date',
            render_input: lambda do |field|
              if (raw_date = field&.to_date)
                {
                  'year' => raw_date&.strftime('%Y') || '',
                  'month' => raw_date&.strftime('%m') || '',
                  'day' => raw_date&.strftime('%d') || ''
                }
              end
            end,
            type: 'date'
          },
          { name: 'referenceno', label: 'Reference number' },
          { name: 'vendordocno', label: 'Vendor document number' },
          { name: 'termname', label: 'Payment term' },
          {
            name: 'datedue',
            label: 'Due date',
            render_input: lambda do |field|
              if (raw_date = field&.to_date)
                {
                  'year' => raw_date&.strftime('%Y') || '',
                  'month' => raw_date&.strftime('%m') || '',
                  'day' => raw_date&.strftime('%d') || ''
                }
              end
            end,
            type: 'date'
          },
          { name: 'message' },
          { name: 'shippingmethod', label: 'Shipping method' },
          {
            name: 'returnto',
            label: 'Return to contact',
            type: 'object',
            properties: [{
              name: 'contactname',
              label: 'Contact name',
              hint: 'Contact name of an existing contact',
              control_type: 'select',
              pick_list: 'contact_names',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'contactname',
                label: 'Contact name',
                toggle_hint: 'Use custom value',
                control_type: 'text',
                type: 'string'
              }
            }]
          },
          {
            name: 'payto',
            label: 'Pay to contact',
            type: 'object',
            properties: [{
              name: 'contactname',
              label: 'Contact name',
              hint: 'Contact name of an existing contact',
              control_type: 'select',
              pick_list: 'contact_names',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'contactname',
                label: 'Contact name',
                toggle_hint: 'Use custom value',
                control_type: 'text',
                type: 'string'
              }
            }]
          },
          {
            name: 'supdocid',
            label: 'Supporting document ID',
            hint: 'Attachments ID'
          },
          { name: 'externalid', label: 'External ID' },
          { name: 'basecurr', label: 'Base currency code' },
          { name: 'currency', hint: 'Transaction currency code' },
          {
            name: 'exchratedate',
            label: 'Exchange rate date',
            render_input: lambda do |field|
              if (raw_date = field&.to_date)
                {
                  'year' => raw_date&.strftime('%Y') || '',
                  'month' => raw_date&.strftime('%m') || '',
                  'day' => raw_date&.strftime('%d') || ''
                }
              end
            end,
            type: 'date'
          },
          {
            name: 'exchratetype',
            label: 'Exchange rate type',
            hint: 'Do not use if exchange rate is set. ' \
              '(Leave blank to use Intacct Daily Rate)'
          },
          {
            name: 'exchrate',
            label: 'Exchange rate',
            hint: 'Do not use if exchange rate type is set.'
          },
          {
            name: 'customfields',
            label: 'Custom fields/dimensions',
            type: 'array',
            of: 'object',
            properties: [{
              name: 'customfield',
              label: 'Custom field/dimension',
              type: 'array',
              of: 'object',
              properties: [
                {
                  name: 'customfieldname',
                  label: 'Custom field/dimension name',
                  hint: 'Integration name of the custom field or ' \
                    'custom dimension. Find integration name in object ' \
                    'definition page of the respective object. Prepend ' \
                    "custom dimension with 'GLDIM'; e.g., if the " \
                    'custom dimension is Rating, use ' \
                    "'<b>GLDIM</b>Rating' as integration name here."
                },
                {
                  name: 'customfieldvalue',
                  label: 'Custom field/dimension value',
                  hint: 'The value of custom field or custom dimension'
                }
              ]
            }]
          },
          {
            name: 'state',
            label: 'State',
            hint: 'Action Draft, Pending or Closed. (Default depends ' \
              'on transaction definition configuration)',
            control_type: 'select',
            pick_list: 'transaction_states',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'state',
              label: 'State',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          }
        ]
      end
    },

    po_txn_transitem: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: '@key',
            label: 'Key',
            hint: 'Document ID of purchase transaction'
          },
          {
            name: 'updatepotransitems',
            label: 'Transaction items',
            hint: 'Array to create new line items',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'potransitem',
                label: 'Purchase order line items',
                type: 'object',
                properties: [
                  { name: 'itemid', label: 'Item ID' },
                  { name: 'itemdesc', label: 'Item description' },
                  {
                    name: 'taxable',
                    hint: 'Customer must be set up for taxable.',
                    control_type: 'checkbox',
                    type: 'boolean',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'taxable',
                      label: 'Taxable',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'boolean'
                    }
                  },
                  {
                    name: 'warehouseid',
                    label: 'Warehouse',
                    control_type: 'select',
                    pick_list: 'warehouses',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'warehouseid',
                      label: 'Warehouse ID',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'string'
                    }
                  },
                  { name: 'quantity' },
                  { name: 'unit', hint: 'Unit of measure to base quantity' },
                  { name: 'price', control_type: 'number', type: 'number' },
                  {
                    name: 'sourcelinekey',
                    label: 'Source line key',
                    hint: 'Source line to convert this line from. Use the ' \
                      'RECORDNO of the line from the created from ' \
                      'transaction document.'
                  },
                  {
                    name: 'overridetaxamount',
                    label: 'Override tax amount',
                    control_type: 'number',
                    type: 'number'
                  },
                  {
                    name: 'tax',
                    hint: 'Tax amount',
                    control_type: 'number',
                    type: 'number'
                  },
                  {
                    name: 'locationid',
                    label: 'Location',
                    sticky: true,
                    control_type: 'select',
                    pick_list: 'locations',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'locationid',
                      label: 'Location ID',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'string'
                    }
                  },
                  {
                    name: 'departmentid',
                    label: 'Department',
                    control_type: 'select',
                    pick_list: 'departments',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'departmentid',
                      label: 'Department ID',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'string'
                    }
                  },
                  { name: 'memo' },
                  {
                    name: 'form1099',
                    hint: 'Vendor must be set up for 1099s.',
                    control_type: 'checkbox',
                    type: 'boolean',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'form1099',
                      label: 'Form 1099',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'boolean'
                    }
                  },
                  {
                    name: 'customfields',
                    label: 'Custom fields/dimensions',
                    type: 'array',
                    of: 'object',
                    properties: [{
                      name: 'customfield',
                      label: 'Custom field/dimension',
                      type: 'array',
                      of: 'object',
                      properties: [
                        {
                          name: 'customfieldname',
                          label: 'Custom field/dimension name',
                          hint: 'Integration name of the custom field or ' \
                            'custom dimension. Find integration name in ' \
                            'object definition page of the respective ' \
                            "object. Prepend custom dimension with 'GLDIM'; " \
                            'e.g., if the custom dimension is Rating, use ' \
                            "'<b>GLDIM</b>Rating' as integration name here."
                        },
                        {
                          name: 'customfieldvalue',
                          label: 'Custom field/dimension value',
                          hint: 'The value of custom field or custom dimension'
                        }
                      ]
                    }]
                  },
                  {
                    name: 'projectid',
                    label: 'Project',
                    control_type: 'select',
                    pick_list: 'projects',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'projectid',
                      label: 'Project ID',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'string'
                    }
                  },
                  { name: 'customerid', label: 'Customer ID' },
                  { name: 'vendorid', label: 'Vendor ID' },
                  {
                    name: 'employeeid',
                    label: 'Employee',
                    control_type: 'select',
                    pick_list: 'employees',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'employeeid',
                      label: 'Employee ID',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'string'
                    }
                  },
                  {
                    name: 'classid',
                    label: 'Class',
                    control_type: 'select',
                    pick_list: 'classes',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'classid',
                      label: 'Class ID',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'string'
                    }
                  },
                  { name: 'contractid', label: 'Contract ID' },
                  {
                    name: 'billable',
                    control_type: 'checkbox',
                    type: 'boolean',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'billable',
                      label: 'Billable',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'boolean'
                    }
                  }
                ]
              }
            ]
          }
        ]
      end
    },

    po_txn_updatepotransitem: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: '@key',
            label: 'Key',
            hint: 'Document ID of purchase transaction'
          },
          {
            name: 'updatepotransitems',
            label: 'Transaction items',
            hint: 'Array to update the line items',
            optional: false,
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'updatepotransitem',
                label: 'Purchase order line items',
                hint: 'Purchase order line items to update',
                type: 'object',
                properties: [
                  {
                    name: '@line_num',
                    label: 'Line number',
                    type: 'integer',
                    optional: false
                  },
                  { name: 'itemid', label: 'Item ID' },
                  { name: 'itemdesc', label: 'Item description' },
                  {
                    name: 'taxable',
                    hint: 'Customer must be set up for taxable.',
                    control_type: 'checkbox',
                    type: 'boolean',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'taxable',
                      label: 'Taxable',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'boolean'
                    }
                  },
                  {
                    name: 'warehouseid',
                    label: 'Warehouse',
                    control_type: 'select',
                    pick_list: 'warehouses',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'warehouseid',
                      label: 'Warehouse ID',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'string'
                    }
                  },
                  { name: 'quantity' },
                  { name: 'unit', hint: 'Unit of measure to base quantity' },
                  { name: 'price', control_type: 'number', type: 'number' },
                  {
                    name: 'locationid',
                    label: 'Location',
                    sticky: true,
                    control_type: 'select',
                    pick_list: 'locations',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'locationid',
                      label: 'Location ID',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'string'
                    }
                  },
                  {
                    name: 'departmentid',
                    label: 'Department',
                    control_type: 'select',
                    pick_list: 'departments',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'departmentid',
                      label: 'Department ID',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'string'
                    }
                  },
                  { name: 'memo' },
                  {
                    name: 'customfields',
                    label: 'Custom fields/dimensions',
                    type: 'array',
                    of: 'object',
                    properties: [{
                      name: 'customfield',
                      label: 'Custom field/dimension',
                      type: 'array',
                      of: 'object',
                      properties: [
                        {
                          name: 'customfieldname',
                          label: 'Custom field/dimension name',
                          hint: 'Integration name of the custom field or ' \
                            'custom dimension. Find integration name in ' \
                            'object definition page of the respective ' \
                            "object. Prepend custom dimension with 'GLDIM'; " \
                            'e.g., if the custom dimension is Rating, use ' \
                            "'<b>GLDIM</b>Rating' as integration name here."
                        },
                        {
                          name: 'customfieldvalue',
                          label: 'Custom field/dimension value',
                          hint: 'The value of custom field or custom dimension'
                        }
                      ]
                    }]
                  },
                  {
                    name: 'projectid',
                    label: 'Project',
                    control_type: 'select',
                    pick_list: 'projects',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'projectid',
                      label: 'Project ID',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'string'
                    }
                  },
                  { name: 'customerid', label: 'Customer ID' },
                  { name: 'vendorid', label: 'Vendor ID' },
                  {
                    name: 'employeeid',
                    label: 'Employee',
                    control_type: 'select',
                    pick_list: 'employees',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'employeeid',
                      label: 'Employee ID',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'string'
                    }
                  },
                  {
                    name: 'classid',
                    label: 'Class',
                    control_type: 'select',
                    pick_list: 'classes',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'classid',
                      label: 'Class ID',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'string'
                    }
                  },
                  { name: 'contractid', label: 'Contract ID' },
                  {
                    name: 'billable',
                    control_type: 'checkbox',
                    type: 'boolean',
                    toggle_hint: 'Select from list',
                    toggle_field: {
                      name: 'billable',
                      label: 'Billable',
                      toggle_hint: 'Use custom value',
                      control_type: 'text',
                      type: 'boolean'
                    }
                  }
                ]
              }
            ]
          }
        ]
      end
    },

    # Update Stat GL Entry
    stat_gl_batch: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'RECORDNO',
            label: 'Record number',
            hint: "Stat journal entry 'Record number' to update",
            type: 'integer'
          },
          {
            name: 'BATCH_DATE',
            label: 'Batch date',
            hint: 'Posting date',
            render_input: ->(field) { field&.to_date&.strftime('%m/%d/%Y') },
            parse_output: ->(field) { field&.to_date(format: '%m/%d/%Y') },
            type: 'date'
          },
          {
            name: 'BATCH_TITLE',
            label: 'Batch title',
            hint: 'Description of entry'
          },
          {
            name: 'HISTORY_COMMENT',
            label: 'History comment',
            hint: 'Comment added to history for this transaction'
          },
          { name: 'REFERENCENO', label: 'Reference number of transaction' },
          { name: 'SUPDOCID', label: 'Attachments ID' },
          {
            name: 'STATE',
            label: 'State',
            hint: 'State to update the entry to. Posted to post to the GL, ' \
              'otherwise Draft.',
            control_type: 'select',
            pick_list: 'update_gl_entry_states',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'STATE',
              label: 'State',
              toggle_hint: 'Use custom value',
              control_type: 'text',
              type: 'string'
            }
          },
          {
            name: 'ENTRIES',
            hint: 'Must have at least one line',
            type: 'object',
            properties: [{
              name: 'GLENTRY',
              label: 'GL Entry',
              hint: 'Must have at least one line',
              optional: false,
              type: 'array',
              of: 'object',
              properties: [
                { name: 'DOCUMENT', label: 'Document number' },
                { name: 'ACCOUNTNO', label: 'Account number', optional: false },
                {
                  name: 'TRX_AMOUNT',
                  label: 'Transaction amount',
                  hint: 'Absolute value, relates to Transaction type.',
                  optional: false,
                  control_type: 'number',
                  parse_output: 'float_conversion',
                  type: 'number'
                },
                {
                  name: 'TR_TYPE',
                  label: 'Transaction type',
                  hint: "'Debit' for Increase, otherwise 'Credit' for Decrease",
                  optional: false,
                  control_type: 'select',
                  pick_list: 'tr_types',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'TR_TYPE',
                    label: 'Transaction type',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'DESCRIPTION',
                  label: 'Description',
                  hint: 'Memo. If left blank, set this value to match Batch ' \
                    'title.'
                },
                {
                  name: 'ALLOCATION',
                  label: 'Allocation ID',
                  hint: 'All other dimension elements are ' \
                    'ignored if allocation is set.'
                },
                {
                  name: 'DEPARTMENT',
                  label: 'Department',
                  control_type: 'select',
                  pick_list: 'departments',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'DEPARTMENT',
                    label: 'Department ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'LOCATION',
                  label: 'Location',
                  hint: 'Required if multi-entity enabled',
                  sticky: true,
                  control_type: 'select',
                  pick_list: 'locations',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'LOCATION',
                    label: 'Location ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'PROJECTID',
                  label: 'Project',
                  control_type: 'select',
                  pick_list: 'projects',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'PROJECTID',
                    label: 'Project ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'CUSTOMERID',
                  label: 'Customer',
                  control_type: 'select',
                  pick_list: 'customers',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'CUSTOMERID',
                    label: 'Customer ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'VENDORID',
                  label: 'Vendor',
                  control_type: 'select',
                  pick_list: 'vendors',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'VENDORID',
                    label: 'Vendor ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'EMPLOYEEID',
                  label: 'Employee',
                  control_type: 'select',
                  pick_list: 'employees',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'EMPLOYEEID',
                    label: 'Employee ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'ITEMID',
                  label: 'Item',
                  control_type: 'select',
                  pick_list: 'items',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'ITEMID',
                    label: 'Item ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'CLASSID',
                  label: 'Class',
                  control_type: 'select',
                  pick_list: 'classes',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'CLASSID',
                    label: 'Class ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                { name: 'CONTRACTID', label: 'Contract ID' },
                {
                  name: 'WAREHOUSEID',
                  label: 'Warehouse',
                  control_type: 'select',
                  pick_list: 'warehouses',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'WAREHOUSEID',
                    label: 'Warehouse ID',
                    toggle_hint: 'Use custom value',
                    control_type: 'text',
                    type: 'string'
                  }
                },
                {
                  name: 'customfields',
                  label: 'Custom fields/dimensions',
                  type: 'array',
                  of: 'object',
                  properties: [{
                    name: 'customfield',
                    label: 'Custom field/dimension',
                    type: 'array',
                    of: 'object',
                    properties: [
                      {
                        name: 'customfieldname',
                        label: 'Custom field/dimension name',
                        hint: 'Integration name of the custom field or ' \
                          'custom dimension. Find integration name in object ' \
                          'definition page of the respective object. Prepend ' \
                          "custom dimension with 'GLDIM'; e.g., if the " \
                          'custom dimension is Rating, use ' \
                          "'<b>GLDIM</b>Rating' as integration name here."
                      },
                      {
                        name: 'customfieldvalue',
                        label: 'Custom field/dimension value',
                        hint: 'The value of custom field or custom dimension'
                      }
                    ]
                  }]
                }
              ]
            }]
          },
          {
            name: 'customfields',
            label: 'Custom fields/dimensions',
            type: 'array',
            of: 'object',
            properties: [{
              name: 'customfield',
              label: 'Custom field/dimension',
              type: 'array',
              of: 'object',
              properties: [
                {
                  name: 'customfieldname',
                  label: 'Custom field/dimension name',
                  hint: 'Integration name of the custom field or ' \
                    'custom dimension. Find integration name in object ' \
                    'definition page of the respective object. Prepend ' \
                    "custom dimension with 'GLDIM'; e.g., if the " \
                    'custom dimension is Rating, use ' \
                    "'<b>GLDIM</b>Rating' as integration name here."
                },
                {
                  name: 'customfieldvalue',
                  label: 'Custom field/dimension value',
                  hint: 'The value of custom field or custom dimension'
                }
              ]
            }]
          }
        ]
      end
    },

    # Attachment
    supdoc_create: {
      fields: lambda do |_connection, _config_fields|
        [{
          name: 'attachment',
          optional: false,
          type: 'object',
          properties: [
            {
              name: 'supdocid',
              label: 'Supporting document ID',
              hint: 'Required if company does not have ' \
                'attachment autonumbering configured.',
              sticky: true
            },
            {
              name: 'supdocname',
              label: 'Supporting document name',
              hint: 'Name of attachment',
              optional: false
            },
            {
              name: 'supdocfoldername',
              label: 'Folder name',
              hint: 'Folder to create attachment in',
              optional: false
            },
            { name: 'supdocdescription', label: 'Attachment description' },
            {
              name: 'attachments',
              hint: 'Zero to many attachments',
              sticky: true,
              type: 'array',
              of: 'object',
              properties: [{
                name: 'attachment',
                sticky: true,
                type: 'object',
                properties: [
                  {
                    name: 'attachmentname',
                    label: 'Attachment name',
                    hint: 'File name, no period or extension',
                    sticky: true
                  },
                  {
                    name: 'attachmenttype',
                    label: 'Attachment type',
                    hint: 'File extension, no period',
                    sticky: true
                  },
                  {
                    name: 'attachmentdata',
                    label: 'Attachment data',
                    hint: 'Base64-encoded file binary data',
                    sticky: true
                  }
                ]
              }]
            }
          ]
        }]
      end
    },

    supdoc_get: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'supdocid',
            label: 'Supporting document ID',
            hint: 'Required if company does not have ' \
              'attachment autonumbering configured.',
            sticky: true
          },
          {
            name: 'supdocname',
            label: 'Supporting document name',
            hint: 'Name of attachment'
          },
          {
            name: 'folder',
            label: 'Folder name',
            hint: 'Attachment folder name'
          },
          { name: 'description', label: 'Attachment description' },
          {
            name: 'supdocfoldername',
            label: 'Folder name',
            hint: 'Folder to store attachment in'
          },
          { name: 'supdocdescription', label: 'Attachment description' },
          {
            name: 'attachments',
            type: 'object',
            properties: [{
              name: 'attachment',
              hint: 'Zero to many attachments',
              type: 'array',
              properties: [
                {
                  name: 'attachmentname',
                  label: 'Attachment name',
                  hint: 'File name, no period or extension',
                  sticky: true
                },
                {
                  name: 'attachmenttype',
                  label: 'Attachment type',
                  hint: 'File extension, no period',
                  sticky: true
                },
                {
                  name: 'attachmentdata',
                  label: 'Attachment data',
                  hint: 'Base64-encoded file binary data',
                  sticky: true
                }
              ]
            }]
          },
          { name: 'creationdate', label: 'Creation date' },
          { name: 'createdby', label: 'Created by' },
          { name: 'lastmodified', label: 'Last modified' },
          { name: 'lastmodifiedby', label: 'Last modified by' }
        ]
      end
    },

    # Attachment folder
    supdocfolder: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'name',
            label: 'Folder name',
            hint: 'Attachment folder name'
          },
          { name: 'description', label: 'Folder description' },
          {
            name: 'parentfolder',
            label: 'Parent folder name',
            hint: 'Parent attachment folder'
          },
          {
            name: 'supdocfoldername',
            label: 'Folder name',
            hint: 'Attachment folder name'
          },
          { name: 'supdocfolderdescription', label: 'Folder description' },
          {
            name: 'supdocparentfoldername',
            label: 'Parent folder name',
            hint: 'Parent attachment folder'
          },
          { name: 'creationdate', label: 'Creation date' },
          { name: 'createdby', label: 'Created by' },
          { name: 'lastmodified', label: 'Last modified' },
          { name: 'lastmodifiedby', label: 'Last modified by' }
        ]
      end
    },

    update_response: {
      fields: lambda do |_connection, _config_fields|
        [{ name: 'RECORDNO', label: 'Record number' }]
      end
    }
  },

  actions: {
    # Contract related actions
    search_contract: {
      title: 'Search contracts',
      description: "Search <span class='provider'>contracts</span>  in " \
      "<span class='provider'>Sage Intacct (Custom)</span>",
      help: 'Search will return results that match all your search criteria. ' \
      'Returns a maximum of 100 records.<br/><b>Make sure you have  ' \
      'subscribed for "Contract" module in your Sage Intacct instance.</b>',

      execute: lambda do |_connection, input|
        query = call('format_api_input_field_names', input)
                &.map { |key, value| "#{key} = '#{value}'" }
                &.smart_join(' and ') || ''
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACT',
            'fields' => '*',
            'query' => query,
            'pagesize' => '100'
          }
        }
        response_data = call('get_api_response_data_element', function)

        {
          contracts: call('format_api_output_field_names',
                          call('parse_xml_to_hash',
                               'xml' => response_data,
                               'array_fields' => ['contract'])
                            &.[]('contract')) || []
        }
      end,

      input_fields: ->(object_definitions) { object_definitions['contract'] },

      output_fields: lambda do |object_definitions|
        [{
          name: 'contracts',
          type: 'array',
          of: 'object',
          properties: object_definitions['contract']
        }]
      end,

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACT',
            'fields' => '*',
            'query' => '',
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        {
          contracts: call('format_api_output_field_names',
                          call('parse_xml_to_hash',
                               'xml' => response_data,
                               'array_fields' => ['contract'])
                            &.[]('contract')) || []
        }
      end
    },

    get_contract_by_record_number: {
      description: "Get <span class='provider'>contract</span> by record " \
      "number in <span class='provider'>Sage Intacct (Custom)</span>",

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACT',
            'fields' => '*',
            'query' => "RECORDNO = '#{input['RECORDNO']}'",
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        call('format_api_output_field_names',
             call('parse_xml_to_hash',
                  'xml' => response_data,
                  'array_fields' => ['contract'])
                &.dig('contract', 0)) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['contract'].only('RECORDNO').required('RECORDNO')
      end,

      output_fields: ->(object_definitions) { object_definitions['contract'] },

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACT',
            'fields' => '*',
            'query' => '',
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        call('format_api_output_field_names',
             call('parse_xml_to_hash',
                  'xml' => response_data,
                  'array_fields' => ['contract'])
                          &.dig('contract', 0)) || {}
      end
    },

    search_contract_line: {
      title: 'Search contract lines',
      description: "Search <span class='provider'>contract lines</span>  in " \
      "<span class='provider'>Sage Intacct (Custom)</span>",
      help: 'Search will return results that match all your search criteria. ' \
      'Returns a maximum of 100 records.',

      execute: lambda do |_connection, input|
        query = call('format_api_input_field_names', input)
                &.map { |key, value| "#{key} = '#{value}'" }
                &.smart_join(' and ') || ''
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACTDETAIL',
            'fields' => '*',
            'query' => query,
            'pagesize' => '100'
          }
        }
        response_data = call('get_api_response_data_element', function)

        {
          contract_lines: call('format_api_output_field_names',
                               call('parse_xml_to_hash',
                                    'xml' => response_data,
                                    'array_fields' => ['contractdetail'])
                                 &.[]('contractdetail')) || []
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['contract_line']
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'contract_lines',
          type: 'array',
          of: 'object',
          properties: object_definitions['contract_line']
        }]
      end,

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACTDETAIL',
            'fields' => '*',
            'query' => '',
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        {
          contract_lines: call('format_api_output_field_names',
                               call('parse_xml_to_hash',
                                    'xml' => response_data,
                                    'array_fields' => ['contractdetail'])
                                 &.[]('contractdetail')) || []
        }
      end
    },

    get_contract_line_by_record_number: {
      description: "Get <span class='provider'>contract line</span> by " \
      "record number in <span class='provider'>Sage Intacct (Custom)</span>",

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACTDETAIL',
            'fields' => '*',
            'query' => "RECORDNO = '#{input['RECORDNO']}'",
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        call('format_api_output_field_names',
             call('parse_xml_to_hash',
                  'xml' => response_data,
                  'array_fields' => ['contractdetail'])
                &.dig('contractdetail', 0)) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['contract_line']
          .only('RECORDNO')
          .required('RECORDNO')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['contract_line']
      end,

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACTDETAIL',
            'fields' => '*',
            'query' => '',
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        call('format_api_output_field_names',
             call('parse_xml_to_hash',
                  'xml' => response_data,
                  'array_fields' => ['contractdetail'])
               &.dig('contractdetail', 0)) || {}
      end
    },

    search_contract_expense_line: {
      title: 'Search contract expense lines',
      description: "Search <span class='provider'>contract expense</span> " \
      "lines in <span class='provider'>Sage Intacct (Custom)</span>",
      help: 'Search will return results that match all your search criteria. ' \
      'Returns a maximum of 100 records.<br/><b>Make sure you have  ' \
      'subscribed for "Contract" module in your Sage Intacct instance.</b>',

      execute: lambda do |_connection, input|
        query = call('format_api_input_field_names', input)
                &.map { |key, value| "#{key} = '#{value}'" }
                &.smart_join(' and ') || ''
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACTEXPENSE',
            'fields' => '*',
            'query' => query,
            'pagesize' => '100'
          }
        }
        response_data = call('get_api_response_data_element', function)

        {
          contract_expenses: call('format_api_output_field_names',
                                  call('parse_xml_to_hash',
                                       'xml' => response_data,
                                       'array_fields' => ['contractexpense'])
                                    &.[]('contractexpense')) || []
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['contract_expense']
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'contract_expenses',
          type: 'array',
          of: 'object',
          properties: object_definitions['contract_expense']
        }]
      end,

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACTEXPENSE',
            'fields' => '*',
            'query' => '',
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        {
          contract_expenses: call('format_api_output_field_names',
                                  call('parse_xml_to_hash',
                                       'xml' => response_data,
                                       'array_fields' => ['contractexpense'])
                                    &.[]('contractexpense')) || []
        }
      end
    },

    get_contract_expense_line_by_record_number: {
      description: "Get <span class='provider'>contract expense line</span> " \
      "by record number in <span class='provider'>Sage Intacct (Custom)</span>",

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACTEXPENSE',
            'fields' => '*',
            'query' => "RECORDNO = '#{input['RECORDNO']}'",
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        call('format_api_output_field_names',
             call('parse_xml_to_hash',
                  'xml' => response_data,
                  'array_fields' => ['contractexpense'])
                &.dig('contractexpense', 0)) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['contract_expense']
          .only('RECORDNO')
          .required('RECORDNO')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['contract_expense']
      end,

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACTEXPENSE',
            'fields' => '*',
            'query' => '',
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        call('format_api_output_field_names',
             call('parse_xml_to_hash',
                  'xml' => response_data,
                  'array_fields' => ['contractexpense'])
               &.dig('contractexpense', 0)) || {}
      end
    },

    # Attachment related actions
    create_attachments: {
      description: "Create <span class='provider'>attachments</span> in " \
      "<span class='provider'>Sage Intacct (Custom)</span>",
      help: '<b>Pay special attention to enter the values for the ' \
      'fields in the same order as listed below, ' \
      'for the action to be successful!</b>',

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'create_supdoc' => input['attachment']
        }
        response_result = call('get_api_response_result_element', function)

        call('parse_xml_to_hash',
             'xml' => response_result,
             'array_fields' => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['supdoc_create']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['lagacy_create_or_update_response']
      end,

      sample_output: lambda do |_connection, _input|
        {
          status: 'success',
          function: 'create_supdoc',
          controlid: 'testControlId',
          key: 1234
        }
      end
    },

    get_attachment: {
      title: 'Get attachment by ID',
      description: "Get <span class='provider'>attachment</span> by ID in " \
      "<span class='provider'>Sage Intacct (Custom)</span>",

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'get' => { '@object' => 'supdoc', '@key' => input['key'] }
        }
        response_data = call('get_api_response_data_element', function)

        call('parse_xml_to_hash',
             'xml' => response_data,
             'array_fields' => %w[supdoc attachment])&.dig('supdoc', 0) || {}
      end,

      input_fields: lambda do |_object_definitions|
        [{ name: 'key', label: 'Supporting document ID', optional: false }]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['supdoc_get']
          .ignored('supdocfoldername', 'supdocdescription')
      end,

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'get_list' => { '@object' => 'supdoc', '@maxitems' => '1' }
        }
        response_data = call('get_api_response_data_element', function)

        call('parse_xml_to_hash',
             'xml' => response_data,
             'array_fields' => %w[supdoc attachment])&.dig('supdoc', 0) || {}
      end
    },

    update_attachment: {
      description: "Update <span class='provider'>attachment</span> in " \
      "<span class='provider'>Sage Intacct (Custom)</span>",
      help: '<b>Pay special attention to enter the value for the ' \
      'fields in the same order as listed below, ' \
      'for the action to be successful!</b>',

      execute: lambda do |_connection, input|
        function = { '@controlid' => 'testControlId', 'update_supdoc' => input }
        response_result = call('get_api_response_result_element', function)

        call('parse_xml_to_hash',
             'xml' => response_result,
             'array_fields' => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['supdoc_get']
          .ignored('creationdate', 'createdby', 'lastmodified',
                   'lastmodifiedby', 'folder', 'description')
          .required('supdocid')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['lagacy_create_or_update_response']
      end,

      sample_output: lambda do |_connection, _input|
        {
          status: 'success',
          function: 'update_supdoc',
          controlid: 'testControlId',
          key: 1234
        }
      end
    },

    # Attachment folder related actions
    create_attachment_folder: {
      description: "Create <span class='provider'>attachment folder</span> " \
      "in <span class='provider'>Sage Intacct (Custom)</span>",
      help: '<b>Pay special attention to enter the values for the ' \
      'fields in the same order as listed below, ' \
      'for the action to be successful!</b>',

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'create_supdocfolder' => input
        }
        response_result = call('get_api_response_result_element', function)

        call('parse_xml_to_hash',
             'xml' => response_result,
             'array_fields' => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['supdocfolder']
          .ignored('creationdate', 'createdby', 'lastmodified',
                   'lastmodifiedby', 'name', 'description', 'parentfolder')
          .required('supdocfoldername')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['lagacy_create_or_update_response']
      end,

      sample_output: lambda do |_connection, _input|
        {
          status: 'success',
          function: 'create_supdocfolder',
          controlid: 'testControlId',
          key: 1234
        }
      end
    },

    get_attachment_folder: {
      title: 'Get attachment folder by folder name',
      description: "Get <span class='provider'>attachment folder</span> by " \
      "folder name in <span class='provider'>Sage Intacct (Custom)</span>",

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'get' => { '@object' => 'supdocfolder', '@key' => input['key'] }
        }
        response_data = call('get_api_response_data_element', function)

        call('parse_xml_to_hash',
             'xml' => response_data,
             'array_fields' => ['supdocfolder'])&.dig('supdocfolder', 0) || {}
      end,

      input_fields: lambda do |_object_definitions|
        [{ name: 'key', label: 'Folder name', optional: false }]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['supdocfolder']
          .ignored('supdocfoldername', 'supdocfolderdescription',
                   'supdocparentfoldername')
      end,

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'get_list' => { '@object' => 'supdocfolder', '@maxitems' => '1' }
        }
        response_data = call('get_api_response_data_element', function)

        call('parse_xml_to_hash',
             'xml' => response_data,
             'array_fields' => ['supdocfolder'])&.dig('supdocfolder', 0) || {}
      end
    },

    update_attachment_folder: {
      description: "Update <span class='provider'>attachment folder</span> " \
      "in <span class='provider'>Sage Intacct (Custom)</span>",
      help: '<b>Pay special attention to enter the values for the ' \
      'fields in the same order as listed below, ' \
      'for the action to be successful!</b>',

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'update_supdocfolder' => input
        }
        response_result = call('get_api_response_result_element', function)

        call('parse_xml_to_hash',
             'xml' => response_result,
             'array_fields' => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['supdocfolder']
          .ignored('creationdate', 'createdby', 'lastmodified',
                   'lastmodifiedby', 'name', 'description', 'parentfolder')
          .required('supdocfoldername')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['lagacy_create_or_update_response']
      end,

      sample_output: lambda do |_connection, _input|
        {
          status: 'success',
          function: 'update_supdocfolder',
          controlid: 'testControlId',
          key: 1234
        }
      end
    },

    # Employee related actions
    create_employee: {
      description: "Create <span class='provider'>employee</span> in " \
      "<span class='provider'>Sage Intacct (Custom)</span>",

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'create' => { 'EMPLOYEE' => input }
        }
        response_data = call('get_api_response_data_element', function)

        call('parse_xml_to_hash',
             'xml' => response_data,
             'array_fields' => ['employee'])&.dig('employee', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['employee_create']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['employee_get'].only('RECORDNO', 'EMPLOYEEID')
      end,

      sample_output: lambda do |_connection, _input|
        { 'RECORDNO' => 1234, 'EMPLOYEEID' => 'EMP-007' }
      end
    },

    get_employee: {
      title: 'Get employee by record number',
      description: "Get <span class='provider'>employee</span> in " \
      "<span class='provider'>Sage Intacct (Custom)</span>",

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'EMPLOYEE',
            'fields' => '*',
            'query' => "RECORDNO = '#{input['RECORDNO']}'",
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        call('parse_xml_to_hash',
             'xml' => response_data,
             'array_fields' => ['employee'])&.dig('employee', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['employee_get'].only('RECORDNO').required('RECORDNO')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['employee_get']
      end,

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'EMPLOYEE',
            'query' => '',
            'fields' => '*',
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        call('parse_xml_to_hash',
             'xml' => response_data,
             'array_fields' => ['employee'])&.dig('employee', 0) || {}
      end
    },

    search_employees: {
      description: "Search <span class='provider'>employees</span> in " \
      "<span class='provider'>Sage Intacct (Custom)</span>",
      help: 'Search will return results that match all your search criteria. ' \
      'Returns a maximum of 100 records.',

      execute: lambda do |_connection, input|
        query = input&.map { |key, value| "#{key} = '#{value}'" }
                     &.smart_join(' AND ') || ''
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'EMPLOYEE',
            'fields' => '*',
            'query' => query,
            'pagesize' => '100'
          }
        }
        response_data = call('get_api_response_data_element', function)

        {
          employees: call('format_api_output_field_names',
                          call('parse_xml_to_hash',
                               'xml' => response_data,
                               'array_fields' => ['employee'])
                            &.[]('employee')) || []
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['employee_get']
          .only('RECORDNO', 'EMPLOYEEID', 'TITLE', 'DEPARTMENTID',
                'LOCATIONID', 'CLASSID')
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'employees',
          type: 'array',
          of: 'object',
          properties: object_definitions['employee']
        }]
      end,

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'EMPLOYEE',
            'query' => '',
            'fields' => '*',
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        {
          employees: call('parse_xml_to_hash',
                          'xml' => response_data,
                          'array_fields' => ['employee'])['employee'] || []
        }
      end
    },

    update_employee: {
      description: "Update <span class='provider'>employee</span> in " \
      "<span class='provider'>Sage Intacct (Custom)</span>",

      execute: lambda do |_connection, input|
        unless (fields = input.keys)&.include?('RECORDNO') ||
               fields&.include?('EMPLOYEEID')
          error("Either 'Record number' or 'Employee ID' is required.")
        end
        function = {
          '@controlid' => 'testControlId',
          'update' => { 'EMPLOYEE' => input }
        }
        response_data = call('get_api_response_data_element', function)

        call('parse_xml_to_hash',
             'xml' => response_data,
             'array_fields' => ['employee'])&.dig('employee', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['employee_update']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['employee_get'].only('RECORDNO', 'EMPLOYEEID')
      end,

      sample_output: lambda do |_connection, _input|
        { 'RECORDNO' => 1234, 'EMPLOYEEID' => 'EMP-007' }
      end
    },

    # GL Entry
    create_gl_entry: {
      title: 'Create journal entry',
      description: "Create <span class='provider'>journal entry</span> in " \
      "<span class='provider'>Sage Intacct (Custom)</span>",

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'create' => { 'GLBATCH' => input }
        }
        response_data = call('get_api_response_data_element', function)

        call('parse_xml_to_hash',
             'xml' => response_data,
             'array_fields' => ['glbatch'])&.dig('glbatch', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['gl_batch']
          .ignored('RECORDNO')
          .required('JOURNAL', 'BATCH_DATE', 'BATCH_TITLE', 'ENTRIES')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['update_response']
      end,

      sample_output: ->(_connection, _input) { { 'RECORDNO' => 1234 } }
    },

    update_gl_entry: {
      title: 'Update journal entry',
      description: "Update <span class='provider'>journal entry</span> in " \
      "<span class='provider'>Sage Intacct (Custom)</span>",

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'update' => { 'GLBATCH' => input }
        }
        response_data = call('get_api_response_data_element', function)

        call('parse_xml_to_hash',
             'xml' => response_data,
             'array_fields' => ['glbatch'])&.dig('glbatch', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['gl_batch']
          .ignored('JOURNAL', 'REVERSEDATE')
          .required('RECORDNO', 'BATCH_DATE', 'BATCH_TITLE', 'ENTRIES')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['update_response']
      end,

      sample_output: ->(_connection, _input) { { 'RECORDNO' => 1234 } }
    },

    # MEA Allocation
    search_mea_allocations: {
      title: 'Search MEA allocations',
      description: "Search contract <span class='provider'>MEA allocation" \
      "</span>  in <span class='provider'>Sage Intacct (Custom)</span>",
      help: 'Search will return results that match all your search criteria. ' \
      'Returns a maximum of 100 records.<br/><b>Make sure you have  ' \
      'subscribed for "Contract" module in your Sage Intacct instance.</b>',

      execute: lambda do |_connection, input|
        query = call('format_api_input_field_names', input)
                &.map { |key, value| "#{key} = '#{value}'" }
                &.smart_join(' AND ') || ''
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACTMEABUNDLE',
            'fields' => '*',
            'query' => query,
            'pagesize' => '100'
          }
        }
        response_data = call('get_api_response_data_element', function)

        {
          mea_bundles: call('format_api_output_field_names',
                            call('parse_xml_to_hash',
                                 'xml' => response_data,
                                 'array_fields' => ['contractmeabundle'])
                              &.[]('contractmeabundle')) || []
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['contract_mea_bundle']
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'mea_bundles',
          type: 'array',
          of: 'object',
          properties: object_definitions['contract_mea_bundle']
        }]
      end,

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACTMEABUNDLE',
            'fields' => '*',
            'query' => '',
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        {
          mea_bundles: call('format_api_output_field_names',
                            call('parse_xml_to_hash',
                                 'xml' => response_data,
                                 'array_fields' => ['contractmeabundle'])
                              &.[]('contractmeabundle')) || []
        }
      end
    },

    create_mea_allocation: {
      title: 'Create MEA allocations',
      description: "Create contract <span class='provider'>MEA allocation" \
      "</span> in <span class='provider'>Sage Intacct (Custom)</span>",

      execute: lambda do |_connection, input|
        input['CONTRACTMEABUNDLEENTRIES'] = {
          'CONTRACTMEABUNDLEENTRY' => input['CONTRACTMEABUNDLEENTRIES']
        }
        function = {
          '@controlid' => 'testControlId',
          'create' => { 'CONTRACTMEABUNDLE' => input }
        }
        response_result = call('get_api_response_result_element', function)

        call('parse_xml_to_hash',
             'xml' => response_result,
             'array_fields' => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['contract_mea_bundle_create']
      end,

      output_fields: ->(_object_definitions) { [{ name: 'RECORDNO' }] },

      sample_output: ->(_object_definitions, _input) { { RECORDNO: '12345' } }
    },

    # Purchase Order Transaction related actions
    update_purchase_transaction_header: {
      description: "Update <span class='provider'>purchase transaction " \
      "header</span> in <span class='provider'>Sage Intacct (Custom)</span>",
      help: '<b>Pay special attention to enter the values for the ' \
      'fields in the same order as listed below, ' \
      'for the action to be successful!</b>',

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'update_potransaction' => input&.compact
        }
        response_result = call('get_api_response_result_element', function)

        call('parse_xml_to_hash',
             'xml' => response_result,
             'array_fields' => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['po_txn_header'].required('@key')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['lagacy_create_or_update_response']
      end,

      sample_output: lambda do |_connection, _input|
        {
          status: 'success',
          function: 'update_potransaction',
          controlid: 'testControlId',
          key: 1234
        }
      end
    },

    add_purchase_transaction_items: {
      description: "Add <span class='provider'>purchase transaction " \
      "items</span> in <span class='provider'>Sage Intacct (Custom)</span>",
      help: '<b>Pay special attention to enter the values for the ' \
      'fields in the same order as listed below, ' \
      'for the action to be successful!</b>',

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'update_potransaction' => input
        }
        response_result = call('get_api_response_result_element', function)

        call('parse_xml_to_hash',
             'xml' => response_result,
             'array_fields' => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['po_txn_transitem'].required('@key')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['lagacy_create_or_update_response']
      end,

      sample_output: lambda do |_connection, _input|
        {
          status: 'success',
          function: 'update_potransaction',
          controlid: 'testControlId',
          key: 1234
        }
      end
    },

    update_purchase_transaction_items: {
      description: "Update <span class='provider'>purchase transaction " \
      "items</span> in <span class='provider'>Sage Intacct (Custom)</span>",
      help: '<b>Pay special attention to enter the values for the ' \
      'fields in the same order as listed below, ' \
      'for the action to be successful!</b>',

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'update_potransaction' => input
        }
        response_result = call('get_api_response_result_element', function)

        call('parse_xml_to_hash',
             'xml' => response_result,
             'array_fields' => []) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['po_txn_updatepotransitem'].required('@key')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['lagacy_create_or_update_response']
      end,

      sample_output: lambda do |_connection, _input|
        {
          status: 'success',
          function: 'update_potransaction',
          controlid: 'testControlId',
          key: 1234
        }
      end
    },

    # Update Stat GL Entry
    update_stat_gl_entry: {
      title: 'Update statistical journal entry',
      description: "Update <span class='provider'>statistical journal entry" \
      "</span> in <span class='provider'>Sage Intacct (Custom)</span>",

      execute: lambda do |_connection, input|
        function = {
          '@controlid' => 'testControlId',
          'update' => { 'GLBATCH' => input }
        }
        response_data = call('get_api_response_data_element', function)

        call('parse_xml_to_hash',
             'xml' => response_data,
             'array_fields' => [])&.dig('glbatch', 0) || {}
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['stat_gl_batch']
          .required('RECORDNO', 'BATCH_DATE', 'BATCH_TITLE', 'ENTRIES')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['update_response']
      end,

      sample_output: ->(_connection, _input) { { 'RECORDNO' => 1234 } }
    }
  },

  triggers: {
    new_contract: {
      description: "New <span class='provider'>contract</span> in "\
      "<span class='provider'>Sage Intacct (Custom)</span>",
      help: '<b>Make sure you have subscribed for "Contract" ' \
      'module in your Sage Intacct instance.</b>',

      input_fields: lambda do |_object_definitions|
        [{
          name: 'since',
          label: 'When first started, this recipe should pick up events from',
          hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
          sticky: true,
          type: 'timestamp'
        }]
      end,

      poll: lambda do |_connection, input, closure|
        page_size = 50
        created_since = (closure&.[]('created_since') || input['since'] ||
                          1.hour.ago)
        result_id = closure&.[]('result_id')
        function =
          if result_id.present?
            {
              '@controlid' => 'testControlId',
              'readMore' => { 'resultId' => result_id }
            }
          else
            query = 'WHENCREATED >= ' \
            "'#{created_since&.to_time&.utc&.strftime('%m/%d/%Y %H:%M:%S')}' " \
            "and WHENCREATED < #{now&.utc&.strftime('%m/%d/%Y %H:%M:%S')}"

            {
              '@controlid' => 'testControlId',
              'readByQuery' => {
                'object' => 'CONTRACT',
                'fields' => '*',
                'query' => query,
                'pagesize' => page_size
              }
            }
          end
        response_result = call('get_api_response_result_element', function)
        contract_data = call('format_api_output_field_names',
                             call('parse_xml_to_hash',
                                  'xml' => response_result,
                                  'array_fields' => ['contract'])
                               &.[]('data'))
        more_pages = (result_id = contract_data['__resultId'].presence) || false
        closure = if more_pages
                    {
                      'result_id' => result_id,
                      'created_since' => created_since
                    }
                  else
                    { 'result_id' => nil, 'created_since' => now }
                  end

        {
          events: contract_data&.[]('contract'),
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: lambda do |contract|
        "#{contract['RECORDNO']}@#{contract['WHENCREATED']}"
      end,

      output_fields: ->(object_definitions) { object_definitions['contract'] },

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACT',
            'fields' => '*',
            'query' => '',
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        call('format_api_output_field_names',
             call('parse_xml_to_hash',
                  'xml' => response_data,
                  'array_fields' => ['contract'])
               &.dig('contract', 0)) || {}
      end
    },

    new_updated_contract: {
      title: 'New/updated contract',
      description: "New or updated <span class='provider'>contract</span> in "\
      "<span class='provider'>Sage Intacct (Custom)</span>",
      help: '<b>Make sure you have subscribed for "Contract" ' \
      'module in your Sage Intacct instance.</b>',

      input_fields: lambda do |_object_definitions|
        [{
          name: 'since',
          label: 'When first started, this recipe should pick up events from',
          hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
          sticky: true,
          type: 'timestamp'
        }]
      end,

      poll: lambda do |_connection, input, closure|
        page_size = 50
        updated_since = (closure&.[]('updated_since') || input['since'] ||
                          1.hour.ago)
        result_id = closure&.[]('result_id')
        function =
          if result_id.present?
            {
              '@controlid' => 'testControlId',
              'readMore' => { 'resultId' => result_id }
            }
          else
            query = 'WHENMODIFIED >= ' \
            "'#{updated_since&.to_time&.utc&.strftime('%m/%d/%Y %H:%M:%S')}' " \
            "and WHENMODIFIED < #{now&.utc&.strftime('%m/%d/%Y %H:%M:%S')}"
            {
              '@controlid' => 'testControlId',
              'readByQuery' => {
                'object' => 'CONTRACT',
                'fields' => '*',
                'query' => query,
                'pagesize' => page_size
              }
            }
          end
        response_result = call('get_api_response_result_element', function)
        contract_data = call('format_api_output_field_names',
                             call('parse_xml_to_hash',
                                  'xml' => response_result,
                                  'array_fields' => ['contract'])
                               &.[]('data'))
        more_pages = (result_id = contract_data['__resultId'].presence) || false
        closure = if more_pages
                    {
                      'result_id' => result_id,
                      'updated_since' => updated_since
                    }
                  else
                    { 'result_id' => nil, 'updated_since' => now }
                  end

        {
          events: contract_data&.[]('contract'),
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: lambda do |contract|
        "#{contract['RECORDNO']}@#{contract['WHENMODIFIED']}"
      end,

      output_fields: ->(object_definitions) { object_definitions['contract'] },

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'CONTRACT',
            'fields' => '*',
            'query' => '',
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        call('format_api_output_field_names',
             call('parse_xml_to_hash',
                  'xml' => response_data,
                  'array_fields' => ['contract'])
               &.dig('contract', 0)) || {}
      end
    },

    new_updated_invoice: {
      title: 'New/updated invoice',
      description: "New or updated <span class='provider'>invoice</span> in "\
      "<span class='provider'>Sage Intacct (Custom)</span>",

      input_fields: lambda do |_object_definitions|
        [{
          name: 'since',
          label: 'When first started, this recipe should pick up events from',
          hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
          sticky: true,
          type: 'timestamp'
        }]
      end,

      poll: lambda do |_connection, input, closure|
        page_size = 50
        updated_since = (closure&.[]('updated_since') || input['since'] ||
                          1.hour.ago)
        result_id = closure&.[]('result_id')
        function =
          if result_id.present?
            {
              '@controlid' => 'testControlId',
              'readMore' => { 'resultId' => result_id }
            }
          else
            query = 'WHENMODIFIED >= ' \
            "'#{updated_since&.to_time&.utc&.strftime('%m/%d/%Y %H:%M:%S')}' " \
            "and WHENMODIFIED < #{now&.utc&.strftime('%m/%d/%Y %H:%M:%S')}"
            {
              '@controlid' => 'testControlId',
              'readByQuery' => {
                'object' => 'ARINVOICE',
                'fields' => '*',
                'query' => query,
                'pagesize' => page_size
              }
            }
          end
        response_result = call('get_api_response_result_element', function)
        invoice_data = call('format_api_output_field_names',
                            call('parse_xml_to_hash',
                                 'xml' => response_result,
                                 'array_fields' => ['arinvoice'])
                              &.[]('data'))
        more_pages = (result_id = invoice_data['__resultId'].presence) || false
        closure = if more_pages
                    {
                      'result_id' => result_id,
                      'updated_since' => updated_since
                    }
                  else
                    { 'result_id' => nil, 'updated_since' => now }
                  end

        {
          events: invoice_data&.[]('arinvoice'),
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: lambda do |invoice|
        "#{invoice['RECORDNO']}@#{invoice['WHENMODIFIED']}"
      end,

      output_fields: ->(object_definitions) { object_definitions['invoice'] },

      sample_output: lambda do |_connection, _input|
        function = {
          '@controlid' => 'testControlId',
          'readByQuery' => {
            'object' => 'ARINVOICE',
            'fields' => '*',
            'query' => '',
            'pagesize' => '1'
          }
        }
        response_data = call('get_api_response_data_element', function)

        call('format_api_output_field_names',
             call('parse_xml_to_hash',
                  'xml' => response_data,
                  'array_fields' => ['arinvoice'])
                          &.dig('arinvoice', 0)) || {}
      end
    }
  },

  pick_lists: {
    adjustment_process_types: lambda do |_connection|
      [%w[One\ time One\ time], %w[Distributed Distributed]]
    end,

    classes: lambda do |_connection|
      function = {
        '@controlid' => 'testControlId',
        'readByQuery' => {
          'object' => 'CLASS',
          'fields' => 'NAME, CLASSID',
          'query' => "STATUS = 'T'",
          'pagesize' => '1000'
        }
      }
      response_data = call('get_api_response_data_element', function)

      call('parse_xml_to_hash',
           'xml' => response_data,
           'array_fields' => ['class'])
        &.[]('class')
        &.pluck('NAME', 'CLASSID') || []
    end,

    contact_names: lambda do |_connection|
      function = {
        '@controlid' => 'testControlId',
        'readByQuery' => {
          'object' => 'CONTACT',
          'fields' => 'RECORDNO, CONTACTNAME',
          'query' => "STATUS = 'T'",
          'pagesize' => '1000'
        }
      }
      response_data = call('get_api_response_data_element', function)

      call('parse_xml_to_hash',
           'xml' => response_data,
           'array_fields' => ['contact'])
        &.[]('contact')
        &.pluck('CONTACTNAME', 'CONTACTNAME') || []
    end,

    customers: lambda do |_connection|
      function = {
        '@controlid' => 'testControlId',
        'readByQuery' => {
          'object' => 'CUSTOMER',
          'fields' => 'NAME, CUSTOMERID',
          'query' => "STATUS = 'T'",
          'pagesize' => '1000'
        }
      }
      response_data = call('get_api_response_data_element', function)

      call('parse_xml_to_hash',
           'xml' => response_data,
           'array_fields' => ['customer'])
        &.[]('customer')
        &.pluck('NAME', 'CUSTOMERID') || []
    end,

    departments: lambda do |_connection|
      function = {
        '@controlid' => 'testControlId',
        'readByQuery' => {
          'object' => 'DEPARTMENT',
          'fields' => 'TITLE, DEPARTMENTID',
          'query' => "STATUS = 'T'",
          'pagesize' => '1000'
        }
      }
      response_data = call('get_api_response_data_element', function)

      call('parse_xml_to_hash',
           'xml' => response_data,
           'array_fields' => ['department'])
        &.[]('department')
        &.pluck('TITLE', 'DEPARTMENTID') || []
    end,

    employees: lambda do |_connection|
      function = {
        '@controlid' => 'testControlId',
        'readByQuery' => {
          'object' => 'EMPLOYEE',
          'fields' => 'CONTACT_NAME, EMPLOYEEID',
          'query' => "STATUS = 'T'",
          'pagesize' => '1000'
        }
      }
      response_data = call('get_api_response_data_element', function)

      call('parse_xml_to_hash',
           'xml' => response_data,
           'array_fields' => ['employee'])
        &.[]('employee')
        &.pluck('CONTACT_NAME', 'EMPLOYEEID') || []
    end,

    genders: ->(_connection) { [%w[Male male], %w[Female female]] },

    items: lambda do |_connection|
      function = {
        '@controlid' => 'testControlId',
        'readByQuery' => {
          'object' => 'ITEM',
          'fields' => 'NAME, ITEMID',
          'query' => "STATUS = 'T'",
          'pagesize' => '1000'
        }
      }
      response_data = call('get_api_response_data_element', function)

      call('parse_xml_to_hash',
           'xml' => response_data,
           'array_fields' => ['item'])
        &.[]('item')
        &.pluck('NAME', 'ITEMID') || []
    end,

    locations: lambda do |_connection|
      function = {
        '@controlid' => 'testControlId',
        'readByQuery' => {
          'object' => 'LOCATION',
          'fields' => 'NAME, LOCATIONID',
          'query' => "STATUS = 'T'",
          'pagesize' => '1000'
        }
      }
      response_data = call('get_api_response_data_element', function)

      call('parse_xml_to_hash',
           'xml' => response_data,
           'array_fields' => ['location'])
        &.[]('location')
        &.pluck('NAME', 'LOCATIONID') || []
    end,

    projects: lambda do |_connection|
      function = {
        '@controlid' => 'testControlId',
        'readByQuery' => {
          'object' => 'PROJECT',
          'fields' => 'NAME, PROJECTID',
          'query' => "STATUS = 'T'",
          'pagesize' => '1000'
        }
      }
      response_data = call('get_api_response_data_element', function)

      call('parse_xml_to_hash',
           'xml' => response_data,
           'array_fields' => ['project'])
        &.[]('project')
        &.pluck('NAME', 'PROJECTID') || []
    end,

    statuses: ->(_connection) { [%w[Active active], %w[Inactive inactive]] },

    tax_implications: lambda do |_connection|
      [%w[None None], ['Inbound (Purchase tax)', 'Inbound'],
       ['Outbound (Sales tax)', 'Outbound']]
    end,

    termination_types: lambda do |_connection|
      [%w[Voluntary voluntary], %w[Involuntary involuntary],
       %w[Deceased deceased], %w[Disability disability],
       %w[Retired retired]]
    end,

    tr_types: ->(_connection) { [%w[Debit 1], %w[Credit -1]] },

    transaction_states: lambda do |_connection|
      [%w[Draft Draft], %w[Pending Pending], %w[Closed Closed]]
    end,

    update_gl_entry_states: lambda do |_connection|
      [%w[Draft Draft], %w[Posted Posted]]
    end,

    vendors: lambda do |_connection|
      function = {
        '@controlid' => 'testControlId',
        'readByQuery' => {
          'object' => 'VENDOR',
          'fields' => 'NAME, VENDORID',
          'query' => "STATUS = 'T'",
          'pagesize' => '1000'
        }
      }
      response_data = call('get_api_response_data_element', function)

      call('parse_xml_to_hash',
           'xml' => response_data,
           'array_fields' => ['vendor'])
        &.[]('vendor')
        &.pluck('NAME', 'VENDORID') || []
    end,

    warehouses: lambda do |_connection|
      function = {
        '@controlid' => 'testControlId',
        'readByQuery' => {
          'object' => 'WAREHOUSE',
          'fields' => 'NAME, WAREHOUSEID',
          'query' => "STATUS = 'T'",
          'pagesize' => '1000'
        }
      }
      response_data = call('get_api_response_data_element', function)

      call('parse_xml_to_hash',
           'xml' => response_data,
           'array_fields' => ['warehouse'])
        &.[]('warehouse')
        &.pluck('NAME', 'WAREHOUSEID') || []
    end
  }
}
