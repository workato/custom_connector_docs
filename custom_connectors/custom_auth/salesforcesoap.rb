{
  title: 'Salesforce (Custom SOAP)',

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

    get_api_response_body_element: lambda do |input|
      endpoint = input.dig('connection', 'server_url') ||
                 "https://#{input.dig('connection', 'environment')}" \
                 '.salesforce.com/services/Soap/c' \
                 "/#{input.dig('connection', 'api_version')}"

      post(endpoint, input['payload'])
        .after_error_response(/.*/) do |_code, body, _header, message|
        error("#{message}: #{body}")
      end&.dig('Envelope', 0, 'Body', 0)
    end,

    validate_response: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call('validate_response', array_value)
        end
      elsif input.is_a?(Hash)
        if (error = input['errors'].presence)
          error("#{error['statusCode']}: #{error['message']}")
        else
          input
        end
      end
    end
  },

  connection: {
    fields: [
      { name: 'username', optional: false },
      { name: 'password', optional: false, control_type: 'password' },
      {
        name: 'security_token',
        hint: 'In Salesforce Lightning, navigate to the top navigation bar ' \
        'go to [Your name] > Settings > My Personal Information > ' \
        'Reset My Security Token.',
        optional: false,
        control_type: 'password'
      },
      {
        name: 'environment',
        default: 'login',
        control_type: 'select',
        pick_list: [%w[Production login], %w[Sandbox test]],
        optional: false
      },
      {
        name: 'api_version',
        label: 'API version number',
        hint: 'In Salesforce Lightning, navigate to Setup > Integrations > ' \
        'API > Generate Enterprise WSDL -- the first couple of lines are ' \
        'comments and it will tell you what API version you connect with.',
        default: 46.0,
        optional: false,
        type: 'number',
        control_type: 'number'
      }
    ],

    authorization: {
      type: 'custom_auth',

      acquire: lambda do |connection|
        payload = {
          'soapenv:Header' => {},
          'soapenv:Body' => {
            'urn:login' => {
              'urn:username' => connection['username'],
              "urn:password":
                "#{connection['password']}#{connection['security_token']}"
            }
          }
        }
        response_data = post("https://#{connection['environment']}" \
        ".salesforce.com/services/Soap/c/#{connection['api_version']}", payload)
                        .headers('Content-type' => 'text/xml',
                                 'SOAPAction' => 'test')
                        .format_xml('soapenv:Envelope',
                                    '@xmlns:soapenv' =>
                                      'http://schemas.xmlsoap.org/soap/envelope/',
                                    '@xmlns:urn' =>
                                      'urn:enterprise.soap.sforce.com',
                                    strip_response_namespaces: true)
                        .dig('Envelope', 0,
                             'Body', 0,
                             'loginResponse', 0,
                             'result', 0)
        result = call('format_api_output_field_names',
                      call('parse_xml_to_hash',
                           'xml' => response_data,
                           'array_fields' => []))

        { session_id: result['sessionId'], server_url: result['serverUrl'] }
      end,

      refresh_on: [500, 400, 401, 405, /soapenv:Fault/],

      apply: lambda do |connection|
        payload do |current_payload|
          current_payload&.[]=(
            'soapenv:Header',
            {
              'urn:SessionHeader' => {
                'urn:sessionId' => connection['session_id']
              }
            }
          )
        end
        headers('Content-type' => 'text/xml', 'SOAPAction' => 'test')
        format_xml('soapenv:Envelope',
                   '@xmlns:soapenv' =>
                     'http://schemas.xmlsoap.org/soap/envelope/',
                   '@xmlns:urn' => 'urn:enterprise.soap.sforce.com',
                   strip_response_namespaces: true)
      end
    }
  },

  test: lambda do |connection|
    payload = {
      'soapenv:Header' => {},
      'soapenv:Body' => {
        'urn:login' => {
          'urn:username' => connection['username'],
          "urn:password":
            "#{connection['password']}#{connection['security_token']}"
        }
      }
    }

    post("https://#{connection['environment']}" \
    ".salesforce.com/services/Soap/c/#{connection['api_version']}", payload)
  end,

  object_definitions: {
    convert_lead: {
      fields: lambda do |connection, _config_fields|
        payload = {
          'soapenv:Header' => {},
          'soapenv:Body' => {
            'urn:query' => {
              'urn:queryString' => 'SELECT Id, MasterLabel ' \
                'FROM LeadStatus WHERE IsConverted=true'
            }
          }
        }
        response_data = call('get_api_response_body_element',
                             'payload' => payload,
                             'connection' => connection)
        converted_statuses = call('parse_xml_to_hash',
                                  'xml' => response_data,
                                  'array_fields' => ['records'])
                                 &.dig('queryResponse', 'result', 'records')
                                 &.pluck('MasterLabel', 'MasterLabel') || []

        convert_lead_schema = [
          {
            name: 'urn:leadConverts',
            label: 'Lead converts',
            optional: false,
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'urn:accountId',
                label: 'Account ID',
                hint: 'ID of the Account into which the lead will be merged. ' \
                  'Required only when updating an existing account, ' \
                  'including person accounts. If no accountID is specified, ' \
                  'then this action creates a new account.'
              },
              {
                name: 'urn:contactId',
                label: 'Contact ID',
                hint: 'ID of the Contact into which the lead will be merged ' \
                  '(this contact must be associated with the specified ' \
                  'accountId, and an accountId must be specified). Required ' \
                  'only when updating an existing contact. If no contactID ' \
                  'is specified, then thi action creates a new contact that ' \
                  'is implicitly associated with the Account.'
              },
              {
                name: 'urn:convertedStatus',
                label: 'Converted status',
                optional: false,
                control_type: 'select',
                pick_list: converted_statuses,
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'urn:convertedStatus',
                  label: 'Converted status',
                  hint: 'Valid LeadStatus value for a converted lead',
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'string'
                }
              },
              {
                name: 'urn:doNotCreateOpportunity',
                label: 'Do not create opportunity',
                default: false,
                control_type: 'checkbox',
                type: 'boolean',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'urn:doNotCreateOpportunity',
                  label: 'Do not create opportunity',
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'boolean'
                }
              },
              { name: 'urn:leadId', label: 'Lead ID', optional: false },
              {
                name: 'urn:opportunityId',
                label: 'Opportunity ID',
                hint: 'The ID of an existing opportunity to relate to the ' \
                  'lead. The opportunityId and opportunityName arguments are ' \
                  'mutually exclusive. Specifying a value for both results ' \
                  "in an error. If 'doNotCreateOpportunity' argument is " \
                  "'Yes', then no Opportunity is created and this field must " \
                  'be left blank; otherwise, an error is returned.'
              },
              {
                name: 'urn:opportunityName',
                label: 'Opportunity name',
                hint: 'Name of the opportunity to create. If no name is ' \
                  'specified, then this value defaults to the company name ' \
                  'of the lead. The maximum length of this field is 80 ' \
                  "characters. The 'opportunityId' and 'opportunityName' " \
                  'arguments are mutually exclusive. Specifying a value for ' \
                  "both results in an error. If 'doNotCreateOpportunity' " \
                  "argument is 'Yes', then no Opportunity is created and " \
                  'this field must be left blank; otherwise, an error is ' \
                  'returned.'
              },
              {
                name: 'urn:overwriteLeadSource',
                label: 'Overwrite lead source',
                hint: 'Specifies whether to overwrite the LeadSource field ' \
                  'on the target Contact object with the contents of the ' \
                  'LeadSource field in the source Lead object (Yes), or not ' \
                  "(No). To set this field to 'Yes', the client application " \
                  "must specify a 'contactId' for the target contact.",
                default: false,
                control_type: 'checkbox',
                type: 'boolean',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'urn:overwriteLeadSource',
                  label: 'Overwrite lead source',
                  hint: 'Specifies whether to overwrite the LeadSource ' \
                    'field on the target Contact object with the contents of ' \
                    'the LeadSource field in the source Lead object (true), ' \
                    'or not (false, the default). To set this field ' \
                    "to 'true', the client application must specify " \
                    "a 'contactId' for the target contact.",
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'boolean'
                }
              },
              {
                name: 'urn:ownerId',
                label: 'Owner ID',
                hint: 'Specifies the ID of the person to own any newly ' \
                  "created account, contact, and opportunity. If 'ownerId' " \
                  'is not specified, then the owner of the new object will ' \
                  'be the owner of the lead. Not applicable when merging ' \
                  "with existing objects—if an 'ownerId' is specified, this " \
                  "action does not overwrite the 'ownerId' field in an " \
                  'existing account or contact.'
              },
              {
                name: 'urn:sendNotificationEmail',
                label: 'Send notification email',
                default: false,
                control_type: 'checkbox',
                type: 'boolean',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'urn:sendNotificationEmail',
                  label: 'Send notification email',
                  hint: 'Specifies whether to send a notification email to ' \
                    'the owner specified in the ownerId (true) or not ' \
                    '(false, the default).',
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'boolean'
                }
              }
            ]
          }
        ]

        call('format_schema_field_names', convert_lead_schema)
      end
    }
  },

  actions: {
    convert_leads: {
      description: "Convert <span class='provider'>leads</span> " \
        "in <span class='provider'>Salesforce (Custom SOAP)</span>",

      execute: lambda do |connection, input|
        payload = {
          'soapenv:Header' => {},
          'soapenv:Body' => {
            'urn:convertLead' => call('format_api_input_field_names', input)
          }
        }
        response_data = call('get_api_response_body_element',
                             'payload' => payload,
                             'connection' => connection)

        {
          convert_leads: call('validate_response',
                              call('format_api_output_field_names',
                                   call('parse_xml_to_hash',
                                        'xml' => response_data,
                                        'array_fields' => ['result']))
                              .dig('convertLeadResponse', 'result'))
        }
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['convert_lead']
      end,

      output_fields: lambda do |_object_definitions|
        [{
          name: 'convert_leads',
          type: 'array',
          of: 'object',
          properties: [
            { name: 'accountId', label: 'Account ID' },
            { name: 'contactId', label: 'Contact ID' },
            { name: 'leadId', label: 'Lead ID' },
            { name: 'opportunityId', label: 'Opportunity ID' }
          ]
        }]
      end,

      sample_output: lambda do |_connection, _input|
        {
          'convert_leads' => [{
            'accountId' => '0017F00001m0YopQAE',
            'contactId' => '0037F00001R0j9wQAB',
            'leadId' => '00Q7F00000KBcUlUAL',
            'opportunityId' => '0067F00000OpJ9oQAF'
          }]
        }
      end
    }
  }
}
