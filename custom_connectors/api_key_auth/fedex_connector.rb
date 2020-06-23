{
  title: 'FedEx',

  connection: {
    fields: [
      {
        name: 'authentication_key',
        label: 'Authentication key',
        control_type: 'string',
        type: 'string',
        hint: 'Please find the authentication key ' \
          '<a href="https://www.fedex.com/en-us/developer/web-services/process.html#production" ' \
          'target="_blank">here</a>.',
        optional: false
      },
      {
        name: 'password',
        control_type: 'password',
        type: 'string',
        hint: 'Please find the password ' \
          '<a href="https://www.fedex.com/en-us/developer/web-services/process.html#production" ' \
          'target="_blank">here</a>.',
        optional: false
      },
      {
        name: 'account_number',
        control_type: 'string',
        type: 'string',
        hint: 'Please find the account number ' \
          '<a href="https://www.fedex.com/en-us/developer/web-services/process.html#production" ' \
          'target="_blank">here</a>.',
        optional: false
      },
      {
        name: 'meter_number',
        control_type: 'string',
        type: 'string',
        hint: 'Please find the meter number ' \
          '<a href="https://www.fedex.com/en-us/developer/web-services/process.html#production" ' \
          'target="_blank">here</a>.',
        optional: false
      },
      {
        name: 'environment',
        optional: false,
        label: 'Environment',
        control_type: 'select',
        pick_list: [
          %w[Testing testing],
          %w[Production production]
        ],
        toggle_hint: 'Select from list',
        toggle_field: {
          name: 'environment',
          label: 'Environment',
          type: :string,
          control_type: 'text',
          optional: false,
          toggle_hint: 'Use custom value',
          hint: 'Allowed values are: testing and production.'
        }
      }
    ],

    authorization: {
      type: 'api_key'
    },

    base_uri: lambda do |connection|
      connection['environment'] == 'production' ? 'https://ws.fedex.com' : 'https://wsbeta.fedex.com'
    end
  },

  test: lambda do |_connection|
    true
  end,

  methods: {
    web_authentication: lambda do |connection, version|
      [
        {
          "v#{version}:ParentCredential" => [
            {
              "v#{version}:Key" => [
                {
                  'content!' => connection['authentication_key']
                }
              ],
              "v#{version}:Password" => [
                {
                  'content!' => connection['password']
                }
              ]
            }
          ],
          "v#{version}:UserCredential" => [
            {
              "v#{version}:Key" => [
                {
                  'content!' => connection['authentication_key']
                }
              ],
              "v#{version}:Password" => [
                {
                  'content!' => connection['password']
                }
              ]
            }
          ]
        }
      ]
    end,

    client_details: lambda do |connection, version|
      [
        {
          "v#{version}:AccountNumber" => [
            {
              'content!' => connection['account_number']
            }
          ],
          "v#{version}:MeterNumber" => [
            {
              'content!' => connection['meter_number']
            }
          ],
          "v#{version}:Localization" => [
            {
              "v#{version}:LanguageCode" => [
                {
                  'content!' => 'EN'
                }
              ],
              "v#{version}:LocaleCode" => [
                {
                  'content!' => 'EM'
                }
              ]
            }
          ]
        }
      ]
    end,

    transaction_details: lambda do |_connection, version, customer_transaction_id|
      [
        {
          "v#{version}:CustomerTransactionId" => [
            {
              'content!' => customer_transaction_id
            }
          ]
        }
      ]
    end,

    version_details: lambda do |_connection, version, service_id|
      [
        {
          "v#{version}:ServiceId" => [
            {
              'content!' => service_id
            }
          ],
          "v#{version}:Major" => [
            {
              'content!' => version
            }
          ],
          "v#{version}:Intermediate" => [
            {
              'content!' => '0'
            }
          ],
          "v#{version}:Minor" => [
            {
              'content!' => '0'
            }
          ]
        }
      ]
    end,

    parse_simple_type: lambda do |value, metadata, name|
      simple_type = metadata.dig('xs:schema', 0, 'xs:simpleType')
      elements = simple_type.select { |element| element['@name'] == value }
      pick_list = elements&.first&.dig('xs:restriction', 0, 'xs:enumeration')&.
                  map { |val| [val['@value'], val['@value']] }

      if pick_list.present?
        {
          name: name,
          control_type: :select,
          pick_list: pick_list,
          toggle_hint: 'Select type',
          toggle_field: {
            name: name,
            label: name.labelize,
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: "Allowed values are: #{pick_list.map { |pl| pl[0] }[0..4].join(', ')}"
          }
        }
      end
    end,

    parse_complex_type: lambda do |value, metadata|
      complex_type = metadata.dig('xs:schema', 0, 'xs:complexType')
      elements = complex_type.select { |element| element['@name'] == value }&.first

      if elements.present?
        elements&.dig('xs:sequence', 0, 'xs:element')&.map do |element|
          type = element['@type']

          if %w[ns:WebAuthenticationDetail ns:ClientDetail ns:TransactionDetail ns:VersionId].
             include? type
            next
          elsif %w[xs:string xs:decimal xs:dateTime xs:boolean xs:date xs:nonNegativeInteger
                   xs:time xs:positiveInteger xs:int xs:duration xs:base64Binary].include? type
            types = {
              'xs:string' => 'string',
              'xs:decimal' => 'number',
              'xs:dateTime' => 'date_time',
              'xs:boolean' => 'boolean',
              'xs:date' => 'string',
              'xs:nonNegativeInteger' => 'integer',
              'xs:time' => 'string',
              'xs:positiveInteger' => 'integer',
              'xs:int' => 'integer',
              'xs:duration' => 'time',
              'xs:base64Binary' => 'string'
            }

            if types[type] == 'date_time'
              {
                name: element['@name'],
                type: 'date_time',
                control_type: 'date_time',
                render_input: 'date_time_conversion',
                parse_output: 'date_time_conversion'
              }
            elsif types[type] == 'boolean'
              {
                name: element['@name'], type: 'boolean',
                control_type: 'checkbox',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Select from list',
                toggle_field:
                {
                  name: element['@name'],
                  label: element['@name'].labelize,
                  type: :boolean,
                  control_type: 'text',
                  optional: true,
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are true or false'
                }
              }
            elsif element['@maxOccurs'].present?
              hint = "Max #{element['@maxOccurs'] == 'unbounded' ? 99 : element['@maxOccurs']}"
              {
                name: element['@name'], type: 'array', of: 'object', hint: hint,
                item_label: element['@name'].labelize,
                add_item_label: "Add #{element['@name']}",
                empty_list_title: "#{element['@name'].labelize} list is empty",
                properties: [
                  { name: 'value', type: types[type] }
                ]
              }
            else
              {
                name: element['@name'], type: types[type], control_type: types[type]
              }
            end
          else
            data = call('parse_complex_type', type.split(':')[1], metadata)
            if data.present? && element['@maxOccurs'].present?
              hint = "Max #{element['@maxOccurs'] == 'unbounded' ? 99 : element['@maxOccurs']}"
              {
                name: element['@name'], type: 'array', of: 'object', hint: hint,
                item_label: element['@name'].labelize,
                add_item_label: "Add #{element['@name']}",
                empty_list_title: "#{element['@name'].labelize} list is empty",
                properties: data
              }
            elsif data.present?
              {
                name: element['@name'], type: 'object',
                properties: data
              }
            else
              call('parse_simple_type', type.split(':')[1],
                   metadata, element['@name'])
            end
          end
        end
      end
    end,

    request_schema_xml: lambda do |connection, input, version, input_schema|
      {
        'soapenv:Header' => [
          {}
        ],
        'soapenv:Body' => [
          {
            "v#{version}:#{input.delete('request_name')}" => [
              {
                "v#{version}:WebAuthenticationDetail" => call('web_authentication', connection,
                                                              version),
                "v#{version}:ClientDetail" => call('client_details', connection, version),
                "v#{version}:TransactionDetail" => call('transaction_details', connection, version,
                                                        input.delete('CustomerTransactionId')),
                "v#{version}:Version" => call('version_details', connection, version,
                                              input.delete('ServiceId'))
              }.merge(call('build_request_xml', input, version, input_schema))
            ]
          }
        ]
      }
    end,

    build_request_xml: lambda do |input, version, input_schema|
      input_schema.each_with_object({}) do |schema, hash|
        if input[schema['name']].present?
          if schema['type'].to_s == 'object'
            hash["v#{version}:#{schema['name']}"] = call('build_request_xml', input[schema['name']],
                                                         version, schema['properties'])
          elsif schema['type'].to_s == 'array'
            if input[schema['name']].first.keys == ['value']
              hash["v#{version}:#{schema['name']}"] = input[schema['name']].map { |value| { 'content!' => value['value'] } }
            else
              hash["v#{version}:#{schema['name']}"] = input[schema['name']].map { |val| call('build_request_xml', val, version, schema['properties']) }
            end
          else
            hash["v#{version}:#{schema['name']}"] = [{ 'content!' => input[schema['name']].to_s }]
          end
        end
      end
    end,

    build_response_json: lambda do |output, output_schema|
      output_schema.each_with_object({}) do |schema, hash|
        if output[schema['name']]
          if schema['type'].to_s == 'object'
            hash[schema['name']] = output[schema['name']].map { |value| call('build_response_json', value, schema['properties']) }.first
          elsif schema['type'].to_s == 'array'
            if output[schema['name']].first.keys == ['value']
              hash[schema['name']] = output[schema['name']].map { |value| { 'value' => value[['content!']] } }
            else
              hash[schema['name']] = output[schema['name']].map { |val| call('build_response_json', val, schema['properties']) }
            end
          else
            hash[schema['name']] = output[schema['name']].dig(0, 'content!')
          end
        end
      end
    end,

    process_input_schema: lambda do |input|
      request_name = {
        'process_shipment' => 'ProcessShipmentRequest',
        'process_tag' => 'ProcessTagRequest'
      }[input['object']]

      metadata = get('https://www.fedex.com/us/developer/downloads/xml/2019/advanced/ShipService_v25.xsd').response_format_xml
      call('parse_complex_type', request_name, metadata)&.compact
    end,

    process_output_schema: lambda do |input|
      request_name = {
        'process_shipment' => 'ProcessShipmentReply',
        'process_tag' => 'ProcessTagReply'
      }[input['object']]

      metadata = get('https://www.fedex.com/us/developer/downloads/xml/2019/advanced/ShipService_v25.xsd').response_format_xml
      call('parse_complex_type', request_name, metadata)&.compact
    end,

    delete_input_schema: lambda do |input|
      request_name = {
        'delete_shipment' => 'DeleteShipmentRequest',
        'delete_tag' => 'DeleteTagRequest'
      }[input['object']]

      metadata = get('https://www.fedex.com/us/developer/downloads/xml/2019/advanced/ShipService_v25.xsd').response_format_xml
      call('parse_complex_type', request_name, metadata)&.compact
    end,

    create_input_schema: lambda do |input|
      request_name = {
        'create_pickup' => 'CreatePickupRequest'
      }[input['object']]

      metadata = get('https://www.fedex.com/us/developer/downloads/xml/2019/advanced/PickupService_v20.xsd').response_format_xml
      call('parse_complex_type', request_name, metadata)&.compact
    end,

    create_output_schema: lambda do |input|
      request_name = {
        'create_pickup' => 'CreatePickupReply'
      }[input['object']]

      metadata = get('https://www.fedex.com/us/developer/downloads/xml/2019/advanced/PickupService_v20.xsd').response_format_xml
      call('parse_complex_type', request_name, metadata)&.compact
    end,

    cancel_input_schema: lambda do |input|
      request_name = {
        'cancel_pickup' => 'CancelPickupRequest'
      }[input['object']]

      metadata = get('https://www.fedex.com/us/developer/downloads/xml/2019/advanced/PickupService_v20.xsd').response_format_xml
      call('parse_complex_type', request_name, metadata)&.compact
    end,

    cancel_output_schema: lambda do |input|
      request_name = {
        'cancel_pickup' => 'CancelPickupReply'
      }[input['object']]

      metadata = get('https://www.fedex.com/us/developer/downloads/xml/2019/advanced/PickupService_v20.xsd').response_format_xml
      call('parse_complex_type', request_name, metadata)&.compact
    end,

    pickup_availability_input_schema: lambda do |_input|
      metadata = get('https://www.fedex.com/us/developer/downloads/xml/2019/advanced/PickupService_v20.xsd').response_format_xml
      call('parse_complex_type', 'PickupAvailabilityRequest', metadata)&.compact
    end,

    pickup_availability_output_schema: lambda do |_input|
      metadata = get('https://www.fedex.com/us/developer/downloads/xml/2019/advanced/PickupService_v20.xsd').response_format_xml
      call('parse_complex_type', 'PickupAvailabilityReply', metadata)&.compact
    end,

    track_input_schema: lambda do |input|
      request_name = {
        'track_shipment' => 'TrackRequest',
        'get_tracking_documents' => 'GetTrackingDocumentsRequest',
        'send_notifications' => 'SendNotificationsRequest'
      }[input['object']]

      metadata = get('https://www.fedex.com/us/developer/downloads/xml/2019/standard/TrackService_v18.xsd').response_format_xml
      call('parse_complex_type', request_name, metadata)&.compact
    end,

    track_output_schema: lambda do |input|
      request_name = {
        'track_shipment' => 'TrackReply',
        'get_tracking_documents' => 'GetTrackingDocumentsReply',
        'send_notifications' => 'SendNotificationsReply'
      }[input['object']]

      metadata = get('https://www.fedex.com/us/developer/downloads/xml/2019/standard/TrackService_v18.xsd').response_format_xml
      call('parse_complex_type', request_name, metadata)&.compact
    end,

    delete_shipment_output_schema: lambda do |_input|
      [
        {
          name: 'HighestSeverity',
          label: 'Highest severity',
          control_type: :select,
          pick_list: [
            %w[ERROR ERROR],
            %w[FAILURE FAILURE],
            %w[NOTE NOTE],
            %w[SUCCESS SUCCESS],
            %w[WARNING WARNING]
          ],
          toggle_hint: 'Select type',
          toggle_field: {
            name: 'HighestSeverity',
            label: 'Highest severity',
            type: :string, control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value'
          }
        },
        {
          name: 'Notifications',
          type: 'object',
          properties: [{
            name: 'Severity',
            control_type: :select,
            pick_list: [
              %w[ERROR ERROR],
              %w[FAILURE FAILURE],
              %w[NOTE NOTE],
              %w[SUCCESS SUCCESS],
              %w[WARNING WARNING]
            ],
            toggle_hint: 'Select type',
            toggle_field: {
              name: 'Severity',
              label: 'Severity',
              type: :string, control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value'
            }
          }, {
            name: 'Source',
            type: 'string'
          }, {
            name: 'Code',
            type: 'string'
          }, {
            name: 'Message',
            type: 'string'
          }, {
            name: 'LocalizedMessage',
            type: 'string'
          }]
        }
      ]
    end,

    authentication_error_output: lambda do |output_data|
      output_data.each_with_object({}) do |output, hash|
        next if output.first.split(':').first == '@xmlns'
        hash[output.first] = if output.dig(1, 0, 'content!')
                               output.dig(1, 0, 'content!')
                             else
                               call('authentication_error_output', output[1][0])
                             end
      end
    end
  },

  object_definitions: {
    process_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call('process_input_schema', config_fields)
      end
    },

    process_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call('process_output_schema', config_fields)
      end
    },

    delete_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call('delete_input_schema', config_fields)
      end
    },

    delete_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call('delete_shipment_output_schema', config_fields)
      end
    },

    create_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call('create_input_schema', config_fields)
      end
    },

    create_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call('create_output_schema', config_fields)
      end
    },

    cancel_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call('cancel_input_schema', config_fields)
      end
    },

    cancel_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call('cancel_output_schema', config_fields)
      end
    },

    pickup_availability_input: {
      fields: lambda do |_connection|
        call('pickup_availability_input_schema', 'input')
      end
    },

    pickup_availability_output: {
      fields: lambda do |_connection|
        call('pickup_availability_output_schema', 'input')
      end
    },

    track_shipment_input: {
      fields: lambda do |_connection|
        call('track_input_schema', { 'object' => 'track_shipment' })
      end
    },

    track_shipment_output: {
      fields: lambda do |_connection|
        call('track_output_schema', { 'object' => 'track_shipment' })
      end
    },

    get_tracking_documents_input: {
      fields: lambda do |_connection|
        call('track_input_schema', { 'object' => 'get_tracking_documents' })
      end
    },

    get_tracking_documents_output: {
      fields: lambda do |_connection|
        call('track_output_schema', { 'object' => 'get_tracking_documents' })
      end
    },

    send_notifications_input: {
      fields: lambda do |_connection|
        call('track_input_schema', { 'object' => 'send_notifications' })
      end
    },

    send_notifications_output: {
      fields: lambda do |_connection|
        call('track_output_schema', { 'object' => 'send_notifications' })
      end
    }
  },

  actions: {
    process_object: {
      title: 'Process object',
      subtitle: 'Process object in FedEx',
      description: lambda do |_connection, create_object_list|
        "<span class='provider'>#{create_object_list[:object] || 'Process object'}</span> in " \
          "<span class='provider'>FedEx</span>"
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'process_object_list',
          hint: 'Select the object type from picklist.'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['process_object_input']
      end,

      execute: lambda do |connection, input, input_schema, output_schema|
        version = 23
        request_name = {
          'process_shipment' => 'ProcessShipmentRequest',
          'process_tag' => 'ProcessTagRequest'
        }[input.delete('object')]

        input = input.merge({ 'request_name' => request_name.to_s,
                              'CustomerTransactionId' => "#{request_name}_2264",
                              'ServiceId' => 'ship' })
        payload = call('request_schema_xml', connection, input, version, input_schema)
        response = post('/web-services').payload(payload).
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              "@xmlns:v#{version}" => "http://fedex.com/ws/ship/v#{version}")&.
          after_response do |_code, body, _headers|
            result = body.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
            if %w[ERROR FAILURE].include? result.dig("v#{version}:HighestSeverity", 0, 'content!')
              error(call('authentication_error_output', body.dig('SOAP-ENV:Envelope', 0,
                                                                 'SOAP-ENV:Body', 0).first[1][0]))
            elsif %w[ERROR FAILURE].include? result.dig('HighestSeverity', 0, 'content!')
              error(call('build_response_json', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema))
            else
              body
            end
          end&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end

        output = call('build_response_json', response.
          dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema)
        output.present? ? output : response.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
      end,

      output_fields: lambda do |object_definition|
        object_definition['process_object_output']
      end
    },

    delete_object: {
      title: 'Delete object',
      subtitle: 'Delete object in FedEx',
      description: lambda do |_connection, delete_object_list|
        "<span class='provider'>#{delete_object_list[:object] || 'Delete object'}</span> in " \
          "<span class='provider'>FedEx</span>"
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'delete_object_list',
          hint: 'Select the object type from picklist.'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['delete_object_input']
      end,

      execute: lambda do |connection, input, input_schema, output_schema|
        version = 23
        request_name = {
          'delete_shipment' => 'DeleteShipmentRequest',
          'delete_tag' => 'DeleteTagRequest'
        }[input.delete('object')]

        input = input.merge({ 'request_name' => request_name.to_s,
                              'CustomerTransactionId' => "#{request_name}_2264",
                              'ServiceId' => 'ship' })
        payload = call('request_schema_xml', connection, input, version, input_schema)
        response = post('/web-services').payload(payload).
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              "@xmlns:v#{version}" => "http://fedex.com/ws/ship/v#{version}")&.
          after_response do |_code, body, _headers|
            result = body.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
            if %w[ERROR FAILURE].include? result.dig("v#{version}:HighestSeverity", 0, 'content!')
              error(call('authentication_error_output', body.dig('SOAP-ENV:Envelope', 0,
                                                                 'SOAP-ENV:Body', 0).first[1][0]))
            elsif %w[ERROR FAILURE].include? result.dig('HighestSeverity', 0, 'content!')
              error(call('build_response_json', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema))
            else
              body
            end
          end&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end

        output = call('build_response_json', response.
          dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema)
        output.present? ? output : response.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
      end,

      output_fields: lambda do |object_definition|
        object_definition['delete_object_output']
      end
    },

    create_object: {
      title: 'Create object',
      subtitle: 'Create object in FedEx',
      description: lambda do |_connection, create_object_list|
        "<span class='provider'>#{create_object_list[:object] || 'Create object'}</span> in " \
          "<span class='provider'>FedEx</span>"
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'create_object_list',
          hint: 'Select the object type from picklist.'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['create_object_input']
      end,

      execute: lambda do |connection, input, input_schema, output_schema|
        version = 17
        request_name = {
          'create_pickup' => 'CreatePickupRequest'
        }[input.delete('object')]
        input = input.merge({ request_name: request_name.to_s,
                              CustomerTransactionId: "#{request_name}_v17", ServiceId: 'disp' })
        payload = call('request_schema_xml', connection, input, version, input_schema)
        response = post('/web-services').payload(payload).
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              "@xmlns:v#{version}" => "http://fedex.com/ws/pickup/v#{version}")&.
          after_response do |_code, body, _headers|
            result = body.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
            if %w[ERROR FAILURE].include? result.dig("v#{version}:HighestSeverity", 0, 'content!')
              error(call('authentication_error_output', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]))
            elsif %w[ERROR FAILURE].include? result.dig('HighestSeverity', 0, 'content!')
              error(call('build_response_json', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema))
            else
              body
            end
          end&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end

        output = call('build_response_json', response.
          dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema)
        output.present? ? output : response.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
      end,

      output_fields: lambda do |object_definition|
        object_definition['create_object_output']
      end
    },

    cancel_object: {
      title: 'Cancel object',
      subtitle: 'Cancel object in FedEx',
      description: lambda do |_connection, cancel_object_list|
        "<span class='provider'>#{cancel_object_list[:object] || 'Cancel object'}</span> in " \
          "<span class='provider'>FedEx</span>"
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'cancel_object_list',
          hint: 'Select the object type from picklist.'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['cancel_object_input']
      end,

      execute: lambda do |connection, input, input_schema, output_schema|
        version = 17
        request_name = {
          'cancel_pickup' => 'CancelPickupRequest'
        }[input.delete('object')]
        input = input.merge({ request_name: request_name.to_s,
                              CustomerTransactionId: "#{request_name}_v17", ServiceId: 'disp' })
        payload = call('request_schema_xml', connection, input, version, input_schema)
        response = post('/web-services').payload(payload).
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              "@xmlns:v#{version}" => "http://fedex.com/ws/pickup/v#{version}")&.
          after_response do |_code, body, _headers|
            result = body.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
            if %w[ERROR FAILURE].include? result.dig("v#{version}:HighestSeverity", 0, 'content!')
              error(call('authentication_error_output', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]))
            elsif %w[ERROR FAILURE].include? result.dig('HighestSeverity', 0, 'content!')
              error(call('build_response_json', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema))
            else
              body
            end
          end&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end

        output = call('build_response_json', response.
          dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema)
        output.present? ? output : response.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
      end,

      output_fields: lambda do |object_definition|
        object_definition['cancel_object_output']
      end
    },

    pickup_availability: {
      title: 'Pickup availability',
      subtitle: 'Pickup availability in FedEx',
      description: "<span class='provider'>Pickup availability</span> in " \
      "<span class='provider'>FedEx</span>",

      input_fields: lambda do |object_definition|
        object_definition['pickup_availability_input']
      end,

      execute: lambda do |connection, input, input_schema, output_schema|
        version = 17
        request_name = 'PickupAvailabilityRequest'
        input = input.merge({ request_name: request_name.to_s,
                              CustomerTransactionId: "#{request_name}_v17", ServiceId: 'disp' })
        payload = call('request_schema_xml', connection, input, version, input_schema)
        response = post('/web-services').payload(payload).
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              "@xmlns:v#{version}" => "http://fedex.com/ws/pickup/v#{version}")&.
          after_response do |_code, body, _headers|
            result = body.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
            if %w[ERROR FAILURE].include? result.dig("v#{version}:HighestSeverity", 0, 'content!')
              error(call('authentication_error_output', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]))
            elsif %w[ERROR FAILURE].include? result.dig('HighestSeverity', 0, 'content!')
              error(call('build_response_json', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema))
            else
              body
            end
          end&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end

        output = call('build_response_json', response.
          dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema)
        output.present? ? output : response.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
      end,

      output_fields: lambda do |object_definition|
        object_definition['pickup_availability_output']
      end
    },

    track_shipment: {
      title: 'Track shipment',
      subtitle: 'Track shipment by number in FedEx',
      description: "Track <span class='provider'>shipment</span> by number in " \
          "<span class='provider'>FedEx</span>",

      input_fields: lambda do |object_definition|
        object_definition['track_shipment_input']
      end,

      execute: lambda do |connection, input, input_schema, output_schema|
        version = 16
        request_name = 'TrackRequest'
        customer_transaction_id = 'Track By Number_v16'

        input = input.merge({ 'request_name' => request_name.to_s,
                              'CustomerTransactionId' => customer_transaction_id,
                              'ServiceId' => 'trck' })
        payload = call('request_schema_xml', connection, input, version, input_schema)
        response = post('/web-services').payload(payload).
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              "@xmlns:v#{version}" => "http://fedex.com/ws/track/v#{version}")&.
          after_response do |_code, body, _headers|
            result = body.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
            if %w[ERROR FAILURE].include? result.dig("v#{version}:HighestSeverity", 0, 'content!')
              error(call('authentication_error_output', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]))
            elsif %w[ERROR FAILURE].include? result.dig('HighestSeverity', 0, 'content!')
              error(call('build_response_json', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema))
            else
              body
            end
          end&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end

        output = call('build_response_json', response.
          dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema)
        output.present? ? output : response.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
      end,

      output_fields: lambda do |object_definition|
        object_definition['track_shipment_output']
      end
    },

    get_tracking_documents: {
      title: 'Get tracking documents',
      subtitle: 'Get tracking documents in FedEx',
      description: "<span class='provider'>Get tracking documents</span> in " \
          "<span class='provider'>FedEx</span>",

      input_fields: lambda do |object_definition|
        object_definition['get_tracking_documents_input']
      end,

      execute: lambda do |connection, input, input_schema, output_schema|
        version = 16
        request_name = 'GetTrackingDocumentsRequest'
        customer_transaction_id = 'SignatureProofOfDeliveryLetterRequestEmail_v14'

        input = input.merge({ 'request_name' => request_name.to_s,
                              'CustomerTransactionId' => customer_transaction_id,
                              'ServiceId' => 'trck' })
        payload = call('request_schema_xml', connection, input, version, input_schema)
        response = post('/web-services').payload(payload).
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              "@xmlns:v#{version}" => "http://fedex.com/ws/track/v#{version}")&.
          after_response do |_code, body, _headers|
            result = body.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
            if %w[ERROR FAILURE].include? result.dig("v#{version}:HighestSeverity", 0, 'content!')
              error(call('authentication_error_output', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]))
            elsif %w[ERROR FAILURE].include? result.dig('HighestSeverity', 0, 'content!')
              error(call('build_response_json', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema))
            else
              body
            end
          end&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end

        output = call('build_response_json', response.
          dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema)
        output.present? ? output : response.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
      end,

      output_fields: lambda do |object_definition|
        object_definition['get_tracking_documents_output']
      end
    },

    send_notifications: {
      title: 'Send notifications',
      subtitle: 'Send notifications in FedEx',
      description: "<span class='provider'>Send notifications</span> in " \
          "<span class='provider'>FedEx</span>",

      input_fields: lambda do |object_definition|
        object_definition['send_notifications_input']
      end,

      execute: lambda do |connection, input, input_schema, output_schema|
        version = 16
        request_name = 'SendNotificationsRequest'
        customer_transaction_id = 'SendNotificationsRequest_v9'

        input = input.merge({ 'request_name' => request_name.to_s,
                              'CustomerTransactionId' => customer_transaction_id,
                              'ServiceId' => 'trck' })
        payload = call('request_schema_xml', connection, input, version, input_schema)
        response = post('/web-services').payload(payload).
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              "@xmlns:v#{version}" => "http://fedex.com/ws/track/v#{version}")&.
          after_response do |_code, body, _headers|
            result = body.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
            if %w[ERROR FAILURE].include? result.dig("v#{version}:HighestSeverity", 0, 'content!')
              error(call('authentication_error_output', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]))
            elsif %w[ERROR FAILURE].include? result.dig('HighestSeverity', 0, 'content!')
              error(call('build_response_json', body.
                dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema))
            else
              body
            end
          end&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end

        output = call('build_response_json', response.
          dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0], output_schema)
        output.present? ? output : response.dig('SOAP-ENV:Envelope', 0, 'SOAP-ENV:Body', 0).first[1][0]
      end,

      output_fields: lambda do |object_definition|
        object_definition['send_notifications_output']
      end
    }
  },

  triggers: {},

  pick_lists: {
    process_object_list: lambda do
      [
        %w[Process\ shipment process_shipment],
        %w[Process\ tag process_tag]
      ]
    end,

    delete_object_list: lambda do
      [
        %w[Delete\ shipment delete_shipment],
        %w[Delete\ tag delete_tag]
      ]
    end,

    create_object_list: lambda do
      [
        %w[Create\ pickup create_pickup]
      ]
    end,

    cancel_object_list: lambda do
      [
        %w[Cancel\ pickup cancel_pickup]
      ]
    end
  }
}
