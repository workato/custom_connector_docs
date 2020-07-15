{
  title: 'OpenAir',
  connection: {
    fields: [
      {
        name: 'api_namespace',
        optional: false
      },
      { name: 'api_key', optional: false, control_type: 'password',
        hint: 'Please contact Open Air Support to request API access and Key' },
      { name: 'company', optional: false },
      { name: 'user', label: 'User name', optional: false },
      { name: 'password', control_type: 'password', label: 'User password', optional: false },
      { name: 'client', optional: false },
      { name: 'base_uri', label: 'Base URL',
        optional: false,
        hint: 'e.g. </b>https://acme.app.sandbox.openair.com</b>' },
      { name: 'wsdl_uri', label: 'WSDL URL',
        optional: false,
        hint: 'Provide WSDL URL. WSDL can be found in your account' \
        ' under, Administration > Global Settings > Account > Integration: ' \
        'Import/Export. Click on Account specific WSDL copy the URL.' \
        'e.g. https://acme.app.openair.com/wsdl.pl?cdi=BZ53IvZNZi4Kt;r=aE2nu2h6689;_CH34=1 ' },
      {
        name: 'version',
        label: 'Webservices API Version',
        optional: false,
        hint: 'e.g. 1.0'
      }
    ],
    authorization: {
      type: 'custom_auth',
      acquire: lambda do |connection|
        session_id =
          post('/soap').
          payload('soap:Header': [{}],
                  'soap:Body': [{
                    'oair:login': [{
                      '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
                      'login_par': [{
                        '@xsi:type': 'perl:LoginParams',
                        '@xmlns:perl': 'http://namespaces.soaplite.com/perl',
                        'api_namespace': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['api_namespace']
                        }],
                        'api_key': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['api_key']
                        }],
                        'company': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['company']
                        }],
                        'user': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['user']
                        }],
                        'password': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['password']
                        }],
                        'client': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['client']
                        }],
                        'version': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['version']
                        }]
                      }]
                    }]
                  }]).
          headers('Content-type': 'text/xml').
          format_xml('soap:Envelope',
                     '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                     '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                     '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                     '@xmlns:oair' => 'https://www.openair.com/OAirService',
                     strip_response_namespaces: true)&.
          dig('Envelope', 0, 'Body', 0,
            'loginResponse', 0, 'loginReturn', 0, 'sessionId', 0, 'content!')
        {
          session_id: session_id
        }
      end,

      refresh: lambda do |connection, _refresh_token|
        session_id =
          post('/soap').
          payload('soap:Header': [{}],
                  'soap:Body': [{
                    'oair:login': [{
                      '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
                      'login_par': [{
                        '@xsi:type': 'perl:LoginParams',
                        '@xmlns:perl': 'http://namespaces.soaplite.com/perl',
                        'api_namespace': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['api_namespace']
                        }],
                        'api_key': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['api_key']
                        }],
                        'company': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['company']
                        }],
                        'user': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['user']
                        }],
                        'password': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['password']
                        }],
                        'client': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['client']
                        }],
                        'version': [{
                          '@xsi:type': 'xsd:string',
                          'content!': connection['version']
                        }]
                      }]
                    }]
                  }]).
          headers('Content-type': 'text/xml').
          format_xml('soap:Envelope',
                     '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                     '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                     '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                     '@xmlns:oair' => 'https://www.openair.com/OAirService',
                     strip_response_namespaces: true)&.
          dig('Envelope', 0, 'Body', 0,
            'loginResponse', 0, 'loginReturn', 0, 'sessionId', 0, 'content!')
        {
          session_id: session_id
        }
      end,

      refresh_on: [500],

      apply: lambda do |connection|
        headers('Content-Type': 'text/xml')

        payload do |current_payload|
          if current_payload.present?
            current_payload['soap:Header'][0]&.[]=(
              'SessionHeader',
              [
                {
                  '@xsi:type' => 'perl:SessionHeader',
                  '@xmlns:perl' => 'http://namespaces.soaplite.com/perl',
                  'sessionId' => [{
                    '@xsi:type' => 'xsd:string',
                    'content!': connection['session_id']
                  }]
                }
              ]
            )
          end
        end
        format_xml('soap:Envelope',
                   '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                   '@xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                   '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                   '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                   '@xmlns:oair' => 'https://www.openair.com/OAirService',
                   '@xmlns:tns' => 'http://namespaces.soaplite.com/perl',
                   '@xmlns:types' => 'http://namespaces.soaplite.com/perl/encodedTypes',
                   strip_response_namespaces: true)
      end
    },
    base_uri: lambda do |connection|
      connection['base_uri']
    end
  },

  test: lambda do |_connection|
    post('/soap').
      payload('soap:Header': [{}],
              'soap:Body': [{
                'oair:whoami': [{
                  '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/'
                }]
              }])&.
      dig('Envelope', 0, 'Body', 0, 'whoamiResponse', 0, 'whoamiReturn')
  end,

  methods: {
    format_xml_response_to_json: lambda do |input|
      input&.map do |object|
        object&.each_with_object({}) do |value, hash|
          hash[value[0]] = value.dig(1, 0, 'content!') if value[1].is_a? Array
        end
      end
    end,

    get_object_schema: lambda do |connection, input|
      schema = get(connection['wsdl_uri']).response_format_xml
      complex_type = schema.dig('definitions', 0, 'types', 0, 'schema', 0, 'complexType')
      object = complex_type.select { |obj| obj['@name'] == "oa#{input['object']}" }&.
        dig(0, 'complexContent', 0, 'extension', 0, 'sequence', 0, 'element')

      object.map do |fields|
        next if fields['@type'] == 'tns1:ArrayOfoaBase' ||
                fields['@name'] == 'deleted'
        { name: fields['@name'] }
      end&.compact
    end,

    construct_array_payload: lambda do |array_type, object_type, input|
      [
        {
          '@soapenc:arrayType': array_type,
          'Item': input&.map { |inp| call('construct_hash_payload', object_type, inp) }
        }
      ]
    end,

    construct_hash_payload: lambda do |object_type, input|
      input&.each_with_object({}) do |obj, hash|
        hash[obj[0]] = [{ '@xsi:type': 'xsd:string', 'content!': obj[1] }]
      end&.merge('@xsi:type': object_type || 'xsd:string')
    end,

    create_user: lambda do |connection|
      schema = get(connection['wsdl_uri']).response_format_xml

      complex_type = schema.dig('definitions', 0, 'types', 0,
                                'schema', 0, 'complexType')
      user = complex_type.select { |val| val['@name'] == 'oaUser' }&.
        dig(0, 'complexContent', 0, 'extension', 0, 'sequence', 0, 'element')
      company = complex_type.select { |val| val['@name'] == 'oaCompany' }&.
        dig(0, 'complexContent', 0, 'extension', 0, 'sequence', 0, 'element')

      user_input = user.map do |field|
        if field['@type'] == 'tns1:ArrayOfoaBase'
          {
            name: field['@name'], type: 'array', of: 'object',
            properties: [
              { name: 'name' },
              { name: 'value' }
            ]
          }
        else
          { name: field['@name'] }
        end
      end
      company_input = company.map do |field|
        if field['@type'] == 'tns1:ArrayOfoaBase'
          {
            name: field['@name'], type: 'array', of: 'object',
            properties: [
              { name: 'name' },
              { name: 'value' }
            ]
          }
        else
          { name: field['@name'] }
        end
      end

      [
        {
          name: 'user', type: 'object', sticky: true,
          properties: user_input.sort_by { |obj| obj['name'] || obj[:name] }
        },
        {
          name: 'company', type: 'object', sticky: true,
          properties: company_input.sort_by { |obj| obj['name'] || obj[:name] }
        }
      ]
    end,

    get_trigger_payload: lambda do |input, trigger_name|
      {
        'soap:Header': [{}],
        'soap:Body': [{
          '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
          'oair:read': [{
            '@xmlns:oair': 'http://sandbox.openair.com/OAirService',
            'method': [{
              '@soapenc:arrayType': 'tns:ReadRequest[1]',
              'Item': [{
                '@xsi:type': 'tns:ReadRequest',
                'method': [{ '@xsi:type': 'xsd:string', 'content!': 'all' }],
                'attributes': [{
                  '@soapenc:arrayType' => 'tns:Attribute[3]',
                  'Item' => [
                    {
                      '@type' => 'tns:Attribute',
                      'name' => [{ '@xsi:type' => 'xsd:string', 'content!' => 'limit' }],
                      'value' => [{ '@xsi:type' => 'xsd:string', 'content!' => '10' }]
                    },
                    {
                      '@type' => 'tns:Attribute',
                      'name' => [{ '@xsi:type' => 'xsd:string', 'content!' => 'filter' }],
                      'value' => [{ '@xsi:type' => 'xsd:string', 'content!' => 'newer-than' }]
                    },
                    {
                      '@type' => 'tns:Attribute',
                      'name' => [{ '@xsi:type' => 'xsd:string', 'content!' => 'field' }],
                      'value' => [{ '@xsi:type' => 'xsd:string', 'content!' => trigger_name }]
                    }
                  ]
                }],
                'type': [{ '@xsi:type': 'xsd:string', 'content!': input['object'] }],
                'objects': [{
                  '@soapenc:arrayType': 'tns:oaBase[1]',
                  'Item' => [{
                    '@xsi:type' => 'tns:oaDate',
                    'hour' => [{
                      '@type' => 'xsd:string',
                      'content!' => input['filter_date']&.strftime('%H')
                    }],
                    'minute' => [{
                      '@type' => 'xsd:string',
                      'content!' => input['filter_date']&.strftime('%M')
                    }],
                    'month' => [{
                      '@type' => 'xsd:string',
                      'content!' => input['filter_date']&.strftime('%m')
                    }],
                    'second' => [{
                      '@type' => 'xsd:string',
                      'content!' => input['filter_date']&.strftime('%S')
                    }],
                    'day' => [{
                      '@type' => 'xsd:string',
                      'content!' => input['filter_date']&.strftime('%d')
                    }],
                    'year' => [{
                      '@type' => 'xsd:string',
                      'content!' => input['filter_date']&.strftime('%Y')
                    }]
                  }]
                }]
              }]
            }]
          }]
        }]
      }
    end,

    format_date_fields: lambda do |input|
      input&.map do |field|
        date = field['value'].to_time
        { '@xsi:type' => 'tns:oaDate',
          'hour' => [{ '@xsi:type' => 'xsd:string',
                       'content!' => date.strftime('%k') }],
          'minute' => [{ '@xsi:type' => 'xsd:string',
                         'content!' => date.strftime('%M') }],
          'month' => [{ '@xsi:type' => 'xsd:string',
                        'content!' => date.strftime('%m') }],
          'second' => [{ '@xsi:type' => 'xsd:string',
                         'content!' => date.strftime('%S') }],
          'day' => [{ '@xsi:type' => 'xsd:string',
                      'content!' => date.strftime('%d') }],
          'year' => [{ '@xsi:type' => 'xsd:string',
                       'content!' => date.strftime('%Y') }] }
      end
    end,

    get_read_payload: lambda do |input|
      date_filters = input['object_fields'].delete('date_filters')
      {
        'soap:Header': [{}],
        'soap:Body': [{
          '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
          'oair:read': [{
            '@xmlns:oair': 'http://sandbox.openair.com/OAirService',
            'method': [{
              '@soapenc:arrayType': 'tns:ReadRequest[1]',
              'Item': [{
                '@xsi:type': 'tns:ReadRequest',
                'method': [{ '@xsi:type': 'xsd:string', 'content!': input['method'] }],
                'attributes': call('construct_array_payload',
                                   "tns:Attribute[#{input['attributes'].length}]",
                                   'tns:Attribute', input['attributes']),
                'type': [{ '@xsi:type': 'xsd:string', 'content!': input['object'] }],
                'objects': if input['object_fields'].present? || date_filters.present?
                             [{
                               '@soapenc:arrayType':
                               "tns:oaBase[#{(date_filters&.size || 0) + 1}]",
                               'Item': [call('construct_hash_payload',
                                             "tns:oa#{input['object']}",
                                             input['object_fields'])]&.
                                        concat(call('format_date_fields',
                                                    date_filters))
                             }]
                           else
                             []
                           end
              }]
            }]
          }]
        }]
      }
    end,

    create_user_payload: lambda do |input|
      {
        'soap:Header': [{}],
        'soap:Body': [{
          '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
          'oair:createUser': [{
            '@xmlns:oair': 'http://sandbox.openair.com/OAirService',
            'user': [call('construct_hash_payload',
                          'tns:oaUser', input['user'])],
            'company': [call('construct_hash_payload',
                             'tns:oaCompany', input['company'])]
          }]
        }]
      }
    end,

    get_create_payload: lambda do |input|
      {
        'soap:Header': [{}],
        'soap:Body': [{
          '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
          'oair:add': [{
            '@xmlns:oair': 'http://sandbox.openair.com/OAirService',
            'objects': [{
              '@soapenc:arrayType': 'tns:oaBase[1]',
              'Item': [call('construct_hash_payload',
                            "tns:oa#{input['object']}",
                            input.except('object'))]
            }]
          }]
        }]
      }
    end,

    get_update_payload: lambda do |input|
      {
        'soap:Header': [{}],
        'soap:Body': [{
          '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
          'oair:modify': [{
            '@xmlns:oair': 'http://sandbox.openair.com/OAirService',
            'attributes': [{
              '@soapenc:arrayType': 'tns:Attribute[1]',
              'Item': [{
                '@xsi:type': 'tns:Attribute',
                'name': [{ '@xsi:type': 'xsd:string', 'content!': 'update_custom' }],
                'value': [{ '@xsi:type': 'xsd:string', 'content!': '1' }]
              }]
            }],
            'objects': [{
              '@soapenc:arrayType': 'tns:oaBase[1]',
              'Item': [call('construct_hash_payload',
                            "tns:oa#{input['object']}",
                            input.except('object'))]
            }]
          }]
        }]
      }
    end,

    get_upsert_payload: lambda do |input|
      {
        'soap:Header': [{}],
        'soap:Body': [{
          '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
          'oair:upsert': [{
            '@xmlns:oair': 'http://sandbox.openair.com/OAirService',
            'attributes': [{
              '@soapenc:arrayType': 'tns:Attribute[2]',
              'Item': [
                {
                  '@xsi:type': 'tns:Attribute',
                  'name': [{ '@xsi:type': 'xsd:string', 'content!': 'update_custom' }],
                  'value': [{ '@xsi:type': 'xsd:string', 'content!': '1' }]
                },
                {
                  '@xsi:type': 'tns:Attribute',
                  'name': [{ '@xsi:type': 'xsd:string', 'content!': 'lookup' }],
                  'value': [{ '@xsi:type': 'xsd:string', 'content!': 'externalid' }]
                }
              ]
            }],
            'objects': [{
              '@soapenc:arrayType': 'tns:oaBase[1]',
              'Item': [call('construct_hash_payload',
                            "tns:oa#{input['object']}",
                            input.except('object'))]
            }]
          }]
        }]
      }
    end,

    get_delete_payload: lambda do |input|
      {
        'soap:Header': [{}],
        'soap:Body': [{
          '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
          'oair:delete': [{
            '@xmlns:oair': 'http://sandbox.openair.com/OAirService',
            'objects': [{
              '@soapenc:arrayType': 'tns:oaBase[1]',
              'Item': [call('construct_hash_payload',
                            "tns:oa#{input['object']}",
                            input.except('object'))]
            }]
          }]
        }]
      }
    end,

    get_submit_payload: lambda do |input|
      {
        'soap:Header': [{}],
        'soap:Body': [{
          '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
          'oair:submit': [{
            '@xmlns:oair': 'http://sandbox.openair.com/OAirService',
            'requests': [{
              '@soapenc:arrayType': 'tns:SubmitRequest[1]',
              'Item': [{
                '@xsi:type': 'tns:SubmitRequest',
                'attributes': call('construct_array_payload', 'tns:Attribute[1]',
                                   'tns:Attribute', input['attributes']),
                'submit': [{
                  '@xsi:type': "tns:oa#{input['object']}",
                  'id': [{ '@xsi:type': 'xsd:string', 'content!': input['id'] }]
                }],
                'approval': [{
                  '@xsi:type': 'tns:oaApproval',
                  'cc': [{ '@xsi:type': 'xsd:string', 'content!': input['cc'] }],
                  'notes': [{ '@xsi:type': 'xsd:string', 'content!': input['notes'] }]
                }]
              }]
            }]
          }]
        }]
      }
    end,

    get_approve_payload: lambda do |input|
      {
        'soap:Header': [{}],
        'soap:Body': [{
          '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
          'oair:approve': [{
            '@xmlns:oair': 'http://sandbox.openair.com/OAirService',
            'requests': [{
              '@soapenc:arrayType': 'tns:ApproveRequest[1]',
              'Item': [{
                '@xsi:type': 'tns:ApproveRequest',
                'attributes': call('construct_array_payload', 'tns:Attribute[1]',
                                   'tns:Attribute', input['attributes']),
                'approve': [{
                  '@xsi:type': "tns:oa#{input['object']}",
                  'id': [{ '@xsi:type': 'xsd:string', 'content!': input['id'] }]
                }],
                'approval': [{
                  '@xsi:type': 'tns:oaApproval',
                  'cc': [{ '@xsi:type': 'xsd:string', 'content!': input['cc'] }],
                  'notes': [{ '@xsi:type': 'xsd:string', 'content!': input['notes'] }]
                }]
              }]
            }]
          }]
        }]
      }
    end,

    get_reject_payload: lambda do |input|
      {
        'soap:Header': [{}],
        'soap:Body': [{
          '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
          'oair:reject': [{
            '@xmlns:oair': 'http://sandbox.openair.com/OAirService',
            'requests': [{
              '@soapenc:arrayType': 'tns:RejectRequest[1]',
              'Item': [{
                '@xsi:type': 'tns:RejectRequest',
                'attributes': call('construct_array_payload', 'tns:Attribute[1]',
                                   'tns:Attribute', input['attributes']),
                'reject': [{
                  '@xsi:type': "tns:oa#{input['object']}",
                  'id': [{ '@xsi:type': 'xsd:string', 'content!': input['id'] }]
                }],
                'approval': [{
                  '@xsi:type': 'tns:oaApproval',
                  'cc': [{ '@xsi:type': 'xsd:string', 'content!': input['cc'] }],
                  'notes': [{ '@xsi:type': 'xsd:string', 'content!': input['notes'] }]
                }]
              }]
            }]
          }]
        }]
      }
    end,

    get_unapprove_payload: lambda do |input|
      {
        'soap:Header': [{}],
        'soap:Body': [{
          '@soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/',
          'oair:unapprove': [{
            '@xmlns:oair': 'http://sandbox.openair.com/OAirService',
            'requests': [{
              '@soapenc:arrayType': 'tns:UnapproveRequest[1]',
              'Item': [{
                '@xsi:type': 'tns:UnapproveRequest',
                'attributes': call('construct_array_payload', 'tns:Attribute[1]',
                                   'tns:Attribute', input['attributes']),
                'unapprove': [{
                  '@xsi:type': "tns:oa#{input['object']}",
                  'id': [{ '@xsi:type': 'xsd:string', 'content!': input['id'] }]
                }],
                'approval': [{
                  '@xsi:type': 'tns:oaApproval',
                  'cc': [{ '@xsi:type': 'xsd:string', 'content!': input['cc'] }],
                  'notes': [{ '@xsi:type': 'xsd:string', 'content!': input['notes'] }]
                }]
              }]
            }]
          }]
        }]
      }
    end,

    sample_output: lambda do |input, response_type|
      if response_type == 'read_result'
        payload = call('get_read_payload',
                       input.merge('method' => 'all',
                                   'attributes': [{ 'name': 'limit', 'value': '1' }]))
        response = post('/soap').headers('Content-Type': 'text/xml').payload(payload).
                   format_xml('soap:Envelope',
                              '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                              '@xmlns:tns' => 'http://namespaces.soaplite.com/perl',
                              '@xmlns:types' => 'http://namespaces.soaplite.com/perl/encodedTypes',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance')

        call('format_xml_response_to_json', response.
            dig('Envelope', 0, 'Body', 0, 'readResponse',
                0, 'Array', 0, 'ReadResult', 0, 'objects', 0, 'item'))&.first
      elsif response_type == 'update_result'
        {
          id: '123',
          status: 'A'
        }
      elsif response_type == 'approval_result'
        {
          id: '123',
          approval_status: 'A',
          approval_warnings: 'The timesheet has less than 1hrs on it',
          log: "#{input['object']} was submitted and approved"
        }
      end
    end,

    format_search_input: lambda do |input|
      formatted_input = {
        'method' => input.delete('method'),
        'object' => input.delete('object')
      }
      limit = if input['offset'].present?
                "#{input.delete('offset')},#{input.delete('limit')}"
              else
                input.delete('limit')
              end
      formatted_input['attributes'] = [
        {
          'name' => 'limit',
          'value' => limit
        },
        {
          'name' => 'deleted',
          'value' => input.delete('deleted')
        },
        {
          'name' => 'include_flags',
          'value' => input.delete('include_flags')
        },
        {
          'name' => 'include_nondeleted',
          'value' => input.delete('include_nondeleted')
        },
        {
          'name' => 'filter',
          'value' => input.delete('filter')
        },
        {
          'name' => 'filter',
          'value' => input.dig('date_filters')&.
            pluck('operator')&.join(',')
        },
        {
          'name' => 'field',
          'value' => input.dig('date_filters')&.
            pluck('field')&.join(',')
        },
        {
          'name' => 'with_project_only',
          'value' => input.delete('with_project_only')
        }
      ].reject { |obj| obj['value'].blank? }

      formatted_input['object_fields'] = input
      formatted_input
    end,

    format_approval_response: lambda do |response, result_type|
      if response&.dig('item', 0, 'errors', 0, '@nil') == 'true' ||
         response&.dig(result_type, 0, 'errors', 0, '@nil') == 'true'

        response = response&.dig(result_type, 0)
        {
          id: response.dig('id', 0, 'content!'),
          approval_status: response.dig('approval_status', 0, 'content!'),
          approval_warnings: response.dig('approval_warnings', 0, 'content!'),
          log: response.dig('log', 0, 'content!')
        }
      else
        error = response.dig('item', 0, 'errors', 0, 'item', 0) ||
                response.dig(result_type, 0, 'errors', 0, 'item', 0)
        response = response&.dig(result_type, 0)
        error("Error code: #{error.dig('code', 0, 'content!')}, " \
            "#{response.dig('approval_errors', 0, 'content!') ||
            response.dig('approval_warnings', 0, 'content!') ||
            call('error_messages',
                 error.dig('code', 0, 'content!'))}")
      end
    end,

    error_messages: lambda do |input|
      {
        0 => 'Success The operation was successful',
        1 => 'Unknown Error',
        2 => 'Auth failed, or was left out of the request',
        3 => 'too many arguments were passed to a command than the command accepts',
        4 => 'too few arguments Fewer arguments were passed to a command than were expected',
        5 => 'Unknown Command There is no command by that name, request failed',
        6 => 'Access from an invalid URL',
        7 => 'Invalid OffLine version Please upgrade your version of OpenAir OffLine',
        8 => 'Failure',
        9 => 'Logged out',
        10 => 'Invalid parameters Invalid parameters were used, please consult documentation',
        201 => 'invalid company Create the company first, then create users',
        202 => 'duplicate user nick A user with this nickname already exists, try another one',
        203 => 'too few arguments You need to specify both a Company object and a User object',
        204 => 'Namespace error Users must be created in the same namespace as the company',
        205 => 'Workschedule error Invalid account workschedule specified',
        301 => 'This company nick is already in use, try another one',
        302 => 'too few arguments You need to specify both a Company and User object',
        303 => 'please pick a different password',
        304 => 'Not enabled CreateAccount operation is not permitted',
        401 => 'Auth failed, The combination of usernick/companynick/password doesn\'t exist',
        402 => 'Old TB login Internal TB error',
        403 => 'No Company name supplied N/A',
        404 => 'No User name supplied N/A',
        405 => 'No User Password supplied N/A',
        406 => 'Invalid Company name N/A',
        408 => 'Bad Password N/A',
        409 => 'Account Canceled This account has been canceled',
        410 => 'Inactive user This user has been made inactive by their administrator',
        411 => 'Account conflict, contact customer service',
        412 => 'This account is not associated with the namespace provided',
        413 => 'This user is not allowed to access the API functionality',
        414 => 'The service is temporarily unavailable, please try back in a few minutes',
        415 => 'Account archived This account is archived',
        416 => 'This user has been locked, please contact your Account Administrator',
        417 => 'Restricted IP address Access is not allow from this IP address',
        418 => 'Invalid uid session The uid passed in is not valid, please login',
        419 => 'Authentication failed, please retry If used, a new session ID may be required',
        420 => 'Authentication failed',
        421 => 'Account misconfiguration or invalid assertion',
        422 => 'LDAP server unavailable Unable to connect LDAP server',
        423 => 'No permissions to read ServerStatus data',
        501 => 'API authentication required API access must first be authenticated',
        502 => 'The request element must contain key & name attributes',
        503 => 'Invalid or missing key attribute N/A',
        504 => 'Invalid or missing namespace attribute N/A',
        505 => 'The namespace and key do not match N/A',
        506 => 'Authentication key disabled. Please contact support for more information',
        555 => 'You have exceeded the limit set for the account for input objects',
        556 => 'XML API rate limit exceeded',
        601 => 'Invalid id/code, There isn\'t a record matching the id or code',
        602 => 'Invalid field',
        603 => 'Invalid type or method',
        604 => 'Attachment size exceeds space available',
        605 => 'Limit clause must be specified',
        606 => 'Projections are running, please try again in a few minutes',
        701 => 'Cannot delete, failed dependency check',
        702 => 'Invalid note, The note could not be deleted',
        801 => 'Not a valid Customer ID',
        802 => 'This Envelope number is already taken',
        803 => 'This user does not have permission to modify the record',
        804 => 'Not a valid Item type. The only valid types are R and M',
        805 => 'The reference number is already in use, please select a different one',
        806 => 'Already accepted by signer',
        807 => 'Invalid payment type',
        808 => 'The note you are trying to modify is not valid',
        809 => 'The timesheet you specified for this task does not exist',
        810 => 'The index you specified doesn\'t exist in that table',
        811 => 'One or more IDs in the predecessor list could not be found',
        812 => 'The parentid field has an id that is not valid',
        813 => 'The projectid specified doesn\'t exist, or was deleted',
        814 => 'This id_number is already in use for this project',
        815 => 'The Projecttask you specified does not exist',
        816 => 'The role_id or type you specified is invalid',
        817 => 'The envelope id specified does not exist',
        818 => 'A user with this nickname already exists, try another one',
        819 => 'This slip is part of an Invoice, and cannot be deleted',
        820 => 'The envelope cannot be modified because it is no longer open',
        821 => 'Timesheet not open',
        822 => 'This slip cannot be edited',
        823 => 'The slip is already in an invoice, and cannot be moved to another invoice',
        824 => 'Must specify name or company',
        825 => 'The invoice ID specified does not exist',
        826 => 'Date is required',
        827 => 'Reimbursements can only be applied after the envelope is approved',
        828 => 'This Invoice number is already taken',
        829 => 'Not a valid user. The user you specified is invalid',
        830 => 'Not a valid booking type. The booking type you specified is invalid',
        831 => 'No startdate or enddate specified',
        832 => 'Startdate must be before enddate',
        833 => 'Percentage must be specified',
        834 => 'Hours must be specified',
        835 => 'Only owner can edit this project',
        836 => 'You must have permission to add entity',
        837 => 'Not a valid account currency',
        838 => 'Not allowed to have more than one current costs per user',
        840 => 'The primary filter set you specified is invalid',
        841 => 'Invalid email. Email is a required field',
        842 => 'Invalid period. Period is a required field',
        843 => 'Invalid timing. Timing is a required field',
        844 => 'Invalid leave accrual rule. leave_accrual_ruleid is a required field',
        845 => 'Invalid task. Task is a required field',
        846 => 'Your account or role is not configured for non-po purchase items',
        847 => 'Purhaseorderid must be blank',
        848 => 'Only non_po purchase items can be added/modified',
        849 => 'Another record with the same date range already exists',
        850 => 'Another record already exists as a default for this user and group',
        851 => 'The tag group attribute you specified is invalid',
        852 => 'Another record with the same external_id is already present',
        853 => 'Invalid Loaded Cost parameters',
        854 => 'Too many records requested',
        855 => 'Number of commands passed in is greater than the account limit for the API',
        856 => 'The start or end dates you specified overlap with an existing record',
        857 => 'The date range specified exceeded maximum allowed',
        858 => 'ForexInput error Please note the update error',
        859 => 'The customer id specified doesn\'t exist or was deleted',
        860 => 'default_for_entity and start and end dates are mutually exclusive',
        861 => 'The customer id specified does not match the parent invoice customer id',
        862 => 'Invalid project id',
        863 => 'The invoice specified is already associated with a different project',
        864 => 'Error while saving user workschedule',
        865 => 'Invalid workdays',
        866 => 'Invalid workdays or workshours',
        867 => 'Distinct workhours not enabled',
        868 => 'Type must be filled and one of (project, user, customer)',
        869 => 'Invalid value for primary_user_filter',
        870 => 'Invalid value for primary_dropdown_filter',
        871 => 'The number of argument objects must equal the number of filter clauses',
        872 => 'Invalid cost type. There is no cost type with specified id',
        873 => 'Invalid period. Period must be specified',
        874 => 'Schedule request error',
        875 => 'Repeat error',
        876 => 'Attachment size is too small',
        877 => 'project_group_id specified does not exist',
        878 => 'Purchaseorder not open',
        879 => 'The purchaseorder_id specified does not exist',
        880 => 'Non-PO purchase items must have a positive quality',
        881 => 'Specified parent ID does not exist or parent is in a different workspace',
        882 => 'Specified reference slip doesn\'t exist or was deleted',
        883 => 'Specified portfolio project ID is invalid',
        884 => 'Portfolio project cannot be subordinated to another portfolio project',
        885 => 'Invalid purchase item. Mandatory date is missing in purchase item',
        886 => 'Project task type mismatch',
        887 => 'This project assignment profile ID is already taken for the project',
        888 => 'Timesheet task invalid date',
        889 => 'Ticket cannot be modified',
        890 => 'User cannot be modified This user cannot be edited',
        891 => 'Invalid user The user id specified does not exist',
        892 => 'Invalid envelope The envelope id specified does not exist',
        893 => 'Invalid receipt The receipt id specified does not exist',
        894 => 'Invalid timesheet The timesheet id specified does not exist',
        895 => 'Invalid customerpo The customerpo id specified does not exist',
        896 => 'Agreement cannot be modified This agreement cannot be edited',
        897 => 'Customerpo cannot be modified This customerpo cannot be edited',
        898 => 'Invalid workspace The workspace id specified does not exist',
        899 => 'Invalid expense policy The expense_policy id specified does not exist',
        900 => 'Invalid item The item id specified does not exist',
        947 => 'Project already has an expense policy',
        948 => 'Duplicate itemid for expense policy',
        949 => 'Invalid Resourceprofile_type ID specified',
        950 => 'Invalid Attribute ID specified',
        951 => 'Duplicate Attribute for Resourceprofile_type',
        1200 => 'Condition not met',
        1400 => 'Please specify a valid start_end_month_ts flag for the Timesheet.',
        1401 => 'Specified associated_tmid is invalid',
        1402 => 'Non-overlapping timesheet',
        1403 => 'Cannot modify timesheet with associated_tmid',
        1404 => 'Invalid time Time must be a valid value.',
        1405 => 'Illegal time range Start time must be before end time.',
        1406 => 'No permission to edit time data',
        1407 => 'The hours do not match the start and end time.',
        901 => 'The combination of uid, app, arg, and page is not valid',
        902 => 'A valid record could not be created from the arg passed',
        903 => 'The user does not have access to that page',
        904 => 'This Purchaseorder number is already taken',
        905 => 'Invalid purchaseorder The purchaseorder id specified does not exist',
        906 => 'Invalid Cost Center The cost_centerid specified does not exist',
        907 => 'Invalid Contact First name, Last name and email are required fields',
        908 => 'Invalid Name Please specify a valid name for the record',
        909 => 'Invalid Contact The contact must exist, and belong to the same Customer',
        910 => 'One or more lookup fields specified for the record do not exist',
        911 => 'Timesheet ID must be specified to edit a task',
        912 => 'Invalid type Specified Type must be set',
        913 => 'Invalid project task specified for a project',
        914 => 'Invalid resourceprofile_type_id specified',
        916 => 'Table specified does not have external_id field',
        917 => 'This Issue number is already taken',
        918 => 'No description specified Issue description must be set',
        919 => 'Only one default issue stage is permitted',
        920 => 'No rate card ID specified Rate card ID must be specified',
        921 => 'The supplied job code is already in use for the associated rate card',
        922 => 'Invalid job code specified An existing job code must be specified',
        923 => 'Invalid rate card specified An existing rate card must be specified',
        924 => 'No job code ID specified Job code ID must be specified',
        925 => 'A valid project ID must be supplied for the template project ID',
        926 => 'User cost must contain a valid value',
        927 => 'User cost start date must not be before any previous cost start date',
        928 => 'Invalid project group ID for workspace user',
        929 => 'Only project group ID or user ID can be set',
        930 => 'Generic flag cannot be modified',
        931 => 'Duplicate project assignment A user can only be assigned to a project o',
        932 => 'Only admin users may update proxies',
        933 => 'The proxy user id you specified is invalid',
        934 => 'Error while creating project from template',
        935 => 'User tag start date must not be before any previous tag start date',
        936 => 'Error while creating project group assignments',
        937 => 'Invalid agreement ID specified',
        938 => 'A unique project_id and agreement_id pair must be specified',
        939 => 'View is not allowed for this user',
        941 => 'Invalid timezone specified for user',
        942 => 'Loaded costs not allowed for generic resources',
        943 => 'Project names must be unique by customer',
        944 => 'Invalid date. Date must be a valid value',
        945 => 'Invalid Project budget group ID specified',
        946 => 'Invalid project budget rule ID specified',
        960 => 'Invalid Resource attachment type Allowed types: CV',
        961 => 'Each user can have only one resource attachment of given type',
        962 => 'ResourceAttachment cannot by modified',
        963 => 'Invalid attachment id. This attachment id does not exist',
        964 => 'Invalid ResourceAttachment id. This ResourceAttachment id does not exist',
        1001 => 'Invalid state Record could not be submitted',
        1002 => 'Submit/Approve error.. There are errors associated with this request',
        1003 => 'Submit/Approve warning. There are warnings associated with this request',
        1050 => 'Invalid hierarchy node specified Please specify a valid hierarchy node',
        1051 => 'You cannot assign multiple nodes within one hierarchy',
        1100 => 'Invalid value specified for a checkbox custom field',
        1101 => 'Value specified is not on the list of values for this',
        1102 => 'Custom field could not be saved',
        1103 => 'Modification of the field specified is not supported',
        1104 => 'This custom field value is not unique You must enter a unique value',
        1105 => 'Value specified is not on the list of values',
        1106 => 'One or more inline custom fields failed to be updated',
        1300 => 'Invalid filter set specified Please specify a valid filter set',
        2001 => 'Invalid argument passed Please make sure to pass valid arguments',
        2002 => 'Invalid format passed Please make sure to pass valid format'
      }[input.to_i]
    end
  },

  object_definitions: {
    trigger_object_output: {
      fields: lambda do |connection, config_fields|
        next [] if config_fields.blank?
        call('get_object_schema', connection, config_fields).
          sort_by { |obj| obj['name'] || obj[:name] }
      end
    },

    read_object_input: {
      fields: lambda do |connection, config_fields|
        schema = [
          {
            name: 'method', control_type: :select, pick_list:
            [
              %w[All all],
              %w[Equal\ to equal\ to],
              %w[Not\ equal\ to not\ equal\ to]
            ],
            optional: false,
            toggle_hint: 'Select method',
            toggle_field: {
              name: 'method',
              label: 'Method',
              type: :string,
              control_type: 'text',
              optional: false,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: all, equal to, not equal to'
            }
          },
          { name: 'limit', label: 'Maximum records',
            optional: false, sticky: true,
            hint: 'The maximum number of records returned in response. ' \
            'e.g. 100. Range between 1 and 1000.' },
          { name: 'offset', sticky: true,
            hint: 'The offset of the first record to return' },
          {
            name: 'deleted', control_type: :select,
            pick_list: 'boolean_list',
            hint: 'Returns deleted records.',
            toggle_hint: 'Select a value',
            toggle_field: {
              name: 'deleted',
              label: 'Deleted',
              type: :string,
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 0, 1'
            }
          },
          {
            name: 'include_flags', control_type: :select,
            pick_list: 'boolean_list',
            hint: 'Returns account or user switches, by default those are ' \
            'not populated.',
            toggle_hint: 'Select a value',
            toggle_field: {
              name: 'include_flags',
              label: 'Include flags',
              type: :string,
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 0, 1'
            }
          },
          {
            name: 'include_nondeleted', control_type: :select,
            pick_list: 'boolean_list',
            hint: 'Returns all records, deleted and nondeleted. It works in ' \
            'conjunction with the "deleted" attribute.',
            toggle_hint: 'Select a value',
            toggle_field: {
              name: 'include_nondeleted',
              label: 'Include non deleted',
              type: :string,
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 0, 1'
            }
          },
          {
            name: 'filter',
            control_type: 'multiselect',
            label: 'Filter',
            pick_list: 'search_filter_list',
            pick_list_params: {},
            delimiter: ',',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'filter',
              label: 'Filter',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'User Custom Values',
              hint: 'Multiple values separated by '\
                'comma e.g. open-envelopes,approved-envelopes'
            }
          },
          {
            name: 'date_filters', type: 'array', of: 'object',
            sticky: true, list_mode: 'static',
            item_label: 'Date Filter',
            add_field_label: 'Add date filter',
            properties: [
              { name: 'field', type: 'string',
                control_type: 'select',
                optional: false,
                pick_list: call('get_object_schema', connection, config_fields).
                  map { |field| [field[:name].labelize, field[:name]] },
                hint: 'Select the date field, e.g. Created. Otherwise search ' \
                'throws error.',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'field',
                  label: 'Field',
                  type: 'string',
                  control_type: 'text',
                  optional: false,
                  toggle_hint: 'Use Custom Values',
                  hint: 'Provide record date field to filter, e.g. <b>created.</b>'
                } },
              { name: 'operator', type: 'string',
                control_type: 'select',
                optional: false,
                pick_list: [
                  ['Newer than', 'newer-than'],
                  ['Older than', 'older-than'],
                  ['Equal to', 'date-equal-to'],
                  ['Not equal to', 'date-not-equal-to']
                ],
                hint: 'Select the operator.',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'operator',
                  label: 'Operator',
                  type: 'string',
                  control_type: 'text',
                  optional: false,
                  toggle_hint: 'Use Custom Values',
                  hint: 'Allowed values: <b>newer-than, older-than, ' \
                  'date-equal-to, date-not-equal-to</b>.'
                } },
              { name: 'value', type: 'date_time', optional: false }
            ]
          },
          {
            name: 'with_project_only', control_type: :select,
            pick_list: 'boolean_list',
            toggle_hint: 'Select a value',
            hint: 'Returns customers which have associated project records.',
            toggle_field: {
              name: 'with_project_only',
              label: 'With project only',
              type: :string,
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: 0, 1'
            }
          }
        ].concat(call('get_object_schema', connection, config_fields).
          sort_by { |obj| obj['name'] || obj[:name] })

        if config_fields['object'] == 'Customer'
          schema
        else
          schema.ignored('with_project_only')
        end
      end
    },

    read_object_output: {
      fields: lambda do |connection, config_fields|
        next [] if config_fields.blank?

        [
          {
            name: 'records', label: config_fields['object'].pluralize, type: 'array', of: 'object',
            properties: call('get_object_schema', connection, config_fields).
              sort_by { |obj| obj['name'] || obj[:name] }
          }
        ]
      end
    },

    create_object_input: {
      fields: lambda do |connection, config_fields|
        next [] if config_fields.blank?
        if config_fields['object'] == 'User'
          call('create_user', connection)
        else
          call('get_object_schema', connection, config_fields).
            ignored('id', 'created', 'updated').sort_by { |obj| obj['name'] || obj[:name] }
        end
      end
    },

    create_object_output: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'status' }
        ]
      end
    },

    update_object_input: {
      fields: lambda do |connection, config_fields|
        next [] if config_fields.blank?
        call('get_object_schema', connection, config_fields).
          ignored('created', 'updated').required('id').sort_by { |obj| obj['name'] || obj[:name] }
      end
    },

    update_object_output: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'status' }
        ]
      end
    },

    upsert_object_input: {
      fields: lambda do |connection, config_fields|
        next [] if config_fields.blank?
        call('get_object_schema', connection, config_fields).
          ignored('id', 'created', 'updated').sort_by { |obj| obj['name'] || obj[:name] }
      end
    },

    upsert_object_output: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'status' }
        ]
      end
    },

    delete_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        [{ name: 'id', optional: false,
           hint: "The ID of a #{config_fields['object']}. e.g. 123" }]
      end
    },

    delete_object_output: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'message' },
          { name: 'status' }
        ]
      end
    },

    approval_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        [
          {
            name: 'id', optional: false,
            hint: "The ID of a #{config_fields['object']}. e.g. 123"
          },
          { name: 'cc', sticky: true },
          { name: 'notes', sticky: true },
          {
            name: 'attributes', type: 'array', of: 'object',
            properties: [
              { name: 'name' },
              { name: 'value' }
            ]
          }
        ]
      end
    },

    approval_object_output: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'id' },
          { name: 'approval_status' },
          { name: 'approval_warnings' },
          { name: 'log' }
        ]
      end
    }
  },

  actions: {
    search_object: {
      title: 'Search objects',
      subtitle: 'Search objects in OpenAir',
      description: lambda do |_connection, search_object_list|
        'Search <span class="provider">' \
        "#{search_object_list[:object]&.pluralize || 'objects'}</span> " \
        'in <span class="provider">OpenAir</span>'
      end,
      help: 'Search will fetch maximum of 1000 records. Use <b>Date filters</b>' \
      ' to fetch records based on date fields.',

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :search_object_list,
          hint: 'Select the object from list.'
        }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['read_object_input']
      end,
      execute: lambda do |_connection, input|
        formatted_input = call('format_search_input', input)
        payload = call('get_read_payload', formatted_input)
        response = post('/soap').headers('Content-Type': 'text/xml').payload(payload).
                   format_xml('soap:Envelope',
                              '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                              '@xmlns:tns' => 'http://namespaces.soaplite.com/perl',
                              '@xmlns:types' => 'http://namespaces.soaplite.com/perl/encodedTypes',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance')&.
          dig('Envelope', 0, 'Body', 0, 'readResponse', 0, 'Array', 0)

        if response&.dig('item', 0, 'errors', 0, '@nil') == 'true' ||
           response&.dig('ReadResult', 0, 'errors', 0, '@nil') == 'true'
          { records: call('format_xml_response_to_json',
                          response.dig('ReadResult', 0, 'objects', 0, 'item')) || [] }
        else
          error = response.dig('item', 0, 'errors', 0, 'item', 0) ||
                  response.dig('ReadResult', 0, 'errors', 0, 'item', 0)
          error(error.dig('text', 0, 'content!') ||
            call('error_messages', error.dig('code', 0, 'content!')))
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['read_object_output']
      end,

      sample_output: lambda do |_connection, input|
        { records: [call('sample_output', input, 'read_result')] }
      end
    },

    create_object: {
      title: 'Create object',
      subtitle: 'Create object in OpenAir',
      description: lambda do |_connection, create_object_list|
        "Create <span class='provider'>#{create_object_list[:object] || 'object'}</span> "\
          'in <span class="provider">OpenAir</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :create_object_list,
          hint: 'Select the object from list.'
        }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['create_object_input']
      end,
      execute: lambda do |_connection, input|
        payload = if input['object'] == 'User'
                    call('create_user_payload', input)
                  else
                    call('get_create_payload', input)
                  end
        response = post('/soap').headers('Content-Type': 'text/xml').payload(payload).
                   format_xml('soap:Envelope',
                              '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                              '@xmlns:tns' => 'http://namespaces.soaplite.com/perl',
                              '@xmlns:types' => 'http://namespaces.soaplite.com/perl/encodedTypes',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance')
        response = if input['object'] == 'User'
                     response&.dig('Envelope', 0, 'Body', 0, 'createUserResponse', 0)
                   else
                     response&.dig('Envelope', 0, 'Body', 0, 'addResponse', 0, 'Array', 0)
                   end
        if response&.dig('item', 0, 'errors', 0, '@nil') == 'true' ||
           response&.dig('UpdateResult', 0, 'errors', 0, '@nil') == 'true'
          response = response&.dig('UpdateResult', 0)
          {
            id: response.dig('id', 0, 'content!'),
            status: response.dig('status', 0, 'content!')
          }
        else
          error = response.dig('item', 0, 'errors', 0, 'item', 0) ||
                  response.dig('UpdateResult', 0, 'errors', 0, 'item', 0)
          error(call('error_messages', error.dig('code', 0, 'content!')))
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['create_object_output']
      end,

      sample_output: lambda do |_connection, input|
        call('sample_output', input, 'update_result')
      end
    },

    update_object: {
      title: 'Update object',
      subtitle: 'Update object in OpenAir',
      description: lambda do |_connection, update_object_list|
        "Update <span class='provider'>#{update_object_list[:object] || 'object'}</span> "\
          'in <span class="provider">OpenAir</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :update_object_list,
          hint: 'Select the object from list.'
        }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['update_object_input']
      end,
      execute: lambda do |_connection, input|
        payload = call('get_update_payload', input)
        response = post('/soap').headers('Content-Type': 'text/xml').payload(payload).
                   format_xml('soap:Envelope',
                              '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                              '@xmlns:tns' => 'http://namespaces.soaplite.com/perl',
                              '@xmlns:types' => 'http://namespaces.soaplite.com/perl/encodedTypes',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance')&.
          dig('Envelope', 0, 'Body', 0, 'modifyResponse', 0, 'Array', 0)

        if response&.dig('item', 0, 'errors', 0, '@nil') == 'true' ||
           response&.dig('UpdateResult', 0, 'errors', 0, '@nil') == 'true'
          response = response&.dig('UpdateResult', 0)
          {
            id: response.dig('id', 0, 'content!'),
            status: response.dig('status', 0, 'content!')
          }
        else
          error = response.dig('item', 0, 'errors', 0, 'item', 0) ||
                  response.dig('UpdateResult', 0, 'errors', 0, 'item', 0)
          error(call('error_messages', error.dig('code', 0, 'content!')))
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['update_object_output']
      end,

      sample_output: lambda do |_connection, input|
        call('sample_output', input, 'update_result')
      end
    },

    upsert_object: {
      title: 'Upsert object',
      subtitle: 'Upsert object in OpenAir',
      description: lambda do |_connection, upsert_object_list|
        "Upsert <span class='provider'>#{upsert_object_list[:object] || 'object'}</span> "\
          'in <span class="provider">OpenAir</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :upsert_object_list,
          hint: 'Select the object from list.'
        }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['upsert_object_input']
      end,
      execute: lambda do |_connection, input|
        payload = call('get_upsert_payload', input)
        response = post('/soap').headers('Content-Type': 'text/xml').payload(payload).
                   format_xml('soap:Envelope',
                              '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                              '@xmlns:tns' => 'http://namespaces.soaplite.com/perl',
                              '@xmlns:types' => 'http://namespaces.soaplite.com/perl/encodedTypes',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance')&.
          dig('Envelope', 0, 'Body', 0, 'upsertResponse', 0, 'Array', 0)

        if response&.dig('item', 0, 'errors', 0, '@nil') == 'true' ||
           response&.dig('UpdateResult', 0, 'errors', 0, '@nil') == 'true'
          response = response&.dig('UpdateResult', 0)
          {
            id: response.dig('id', 0, 'content!'),
            status: response.dig('status', 0, 'content!')
          }
        else
          error = response.dig('item', 0, 'errors', 0, 'item', 0) ||
                  response.dig('UpdateResult', 0, 'errors', 0, 'item', 0)
          error(call('error_messages', error.dig('code', 0, 'content!')))
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['upsert_object_output']
      end,

      sample_output: lambda do |_connection, input|
        call('sample_output', input, 'update_result')
      end
    },

    delete_object: {
      title: 'Delete object',
      subtitle: 'Delete object in OpenAir',
      description: lambda do |_connection, delete_object_list|
        "Delete <span class='provider'>#{delete_object_list[:object] || 'object'}</span> "\
          'in <span class="provider">OpenAir</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :delete_object_list,
          hint: 'Select the object from list.'
        }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['delete_object_input']
      end,
      execute: lambda do |_connection, input|
        payload = call('get_delete_payload', input)
        response = post('/soap').headers('Content-Type': 'text/xml').payload(payload).
                   format_xml('soap:Envelope',
                              '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                              '@xmlns:tns' => 'http://namespaces.soaplite.com/perl',
                              '@xmlns:types' => 'http://namespaces.soaplite.com/perl/encodedTypes',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance')&.
          dig('Envelope', 0, 'Body', 0, 'deleteResponse', 0, 'Array', 0)

        if response&.dig('item', 0, 'errors', 0, '@nil') == 'true' ||
           response&.dig('UpdateResult', 0, 'errors', 0, '@nil') == 'true'
          {
            message: 'Deleted successfully',
            status: response.dig('UpdateResult', 0, 'status', 0, 'content!')
          }
        else
          error = response.dig('item', 0, 'errors', 0, 'item', 0) ||
                  response.dig('UpdateResult', 0, 'errors', 0, 'item', 0)
          error(call('error_messages', error.dig('code', 0, 'content!')))
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['delete_object_output']
      end,

      sample_output: lambda do |_connection, _input|
        {
          message: 'Deleted successfully',
          status: 'D'
        }
      end
    },

    submit_object: {
      title: 'Submit object',
      subtitle: 'Submit object in OpenAir',
      description: lambda do |_connection, approval_object_list|
        "Submit <span class='provider'>#{approval_object_list[:object] || 'object'}</span> "\
          'in <span class="provider">OpenAir</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :approval_object_list,
          hint: 'Select the object from list.'
        }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['approval_object_input']
      end,
      execute: lambda do |_connection, input|
        payload = call('get_submit_payload', input)
        response = post('/soap').headers('Content-Type': 'text/xml').payload(payload).
                   format_xml('soap:Envelope',
                              '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                              '@xmlns:tns' => 'http://namespaces.soaplite.com/perl',
                              '@xmlns:types' => 'http://namespaces.soaplite.com/perl/encodedTypes',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance')&.
          dig('Envelope', 0, 'Body', 0, 'submitResponse', 0, 'Array', 0)

        call('format_approval_response', response, 'SubmitResult')
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['approval_object_output']
      end,

      sample_output: lambda do |_connection, input|
        call('sample_output', input, 'approval_result')
      end
    },

    approve_object: {
      title: 'Approve object',
      subtitle: 'Approve object in OpenAir',
      description: lambda do |_connection, approval_object_list|
        "Approve <span class='provider'>#{approval_object_list[:object] || 'object'}</span> "\
          'in <span class="provider">OpenAir</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :approval_object_list,
          hint: 'Select the object from list.'
        }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['approval_object_input']
      end,
      execute: lambda do |_connection, input|
        payload = call('get_approve_payload', input)
        response = post('/soap').headers('Content-Type': 'text/xml').payload(payload).
                   format_xml('soap:Envelope',
                              '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                              '@xmlns:tns' => 'http://namespaces.soaplite.com/perl',
                              '@xmlns:types' => 'http://namespaces.soaplite.com/perl/encodedTypes',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance')&.
          dig('Envelope', 0, 'Body', 0, 'approveResponse', 0, 'Array', 0)

        call('format_approval_response', response, 'ApproveResult')
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['approval_object_output']
      end,

      sample_output: lambda do |_connection, input|
        call('sample_output', input, 'approval_result')
      end
    },

    reject_object: {
      title: 'Reject object',
      subtitle: 'Reject object in OpenAir',
      description: lambda do |_connection, approval_object_list|
        "Reject <span class='provider'>#{approval_object_list[:object] || 'object'}</span> "\
          'in <span class="provider">OpenAir</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :approval_object_list,
          hint: 'Select the object from list.'
        }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['approval_object_input']
      end,
      execute: lambda do |_connection, input|
        payload = call('get_reject_payload', input)
        response = post('/soap').headers('Content-Type': 'text/xml').payload(payload).
                   format_xml('soap:Envelope',
                              '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                              '@xmlns:tns' => 'http://namespaces.soaplite.com/perl',
                              '@xmlns:types' => 'http://namespaces.soaplite.com/perl/encodedTypes',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance')&.
          dig('Envelope', 0, 'Body', 0, 'rejectResponse', 0, 'Array', 0)

        call('format_approval_response', response, 'RejectResult')
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['approval_object_output']
      end,

      sample_output: lambda do |_connection, input|
        call('sample_output', input, 'approval_result')
      end
    },

    unapprove_object: {
      title: 'Unapprove object',
      subtitle: 'Unapprove object in OpenAir',
      description: lambda do |_connection, approval_object_list|
        "Unapprove <span class='provider'>#{approval_object_list[:object] || 'object'}</span> "\
          'in <span class="provider">OpenAir</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :approval_object_list,
          hint: 'Select the object from list.'
        }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['approval_object_input']
      end,
      execute: lambda do |_connection, input|
        payload = call('get_unapprove_payload', input)
        response = post('/soap').headers('Content-Type': 'text/xml').payload(payload).
                   format_xml('soap:Envelope',
                              '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                              '@xmlns:tns' => 'http://namespaces.soaplite.com/perl',
                              '@xmlns:types' => 'http://namespaces.soaplite.com/perl/encodedTypes',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance')&.
          dig('Envelope', 0, 'Body', 0, 'unapproveResponse', 0, 'Array', 0)

        call('format_approval_response', response, 'UnapproveResult')
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['approval_object_output']
      end,

      sample_output: lambda do |_connection, input|
        call('sample_output', input, 'approval_result')
      end
    }
  },

  triggers: {
    new_object: {
      title: 'New object',
      subtitle: 'Triggers when an object is created.',
      description: lambda do |_connection, trigger_object_list|
        "New <span class='provider'>#{trigger_object_list[:object] || 'object'}</span> "\
          ' in <span class="provider">OpenAir</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :trigger_object_list,
          hint: 'Select the object from list.'
        }
      ],

      input_fields: lambda do |_object_definition|
        [{
          name: 'since',
          type: 'timestamp',
          label: 'When first started, this recipe should pick up events from',
          hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
          sticky: true
        }]
      end,

      poll: lambda do |_connection, input, closure|
        closure ||= {}
        created_after = closure['created_after'] ||
                        (input['since'] || 1.hour.ago).to_time.
                        in_time_zone('America/New_York').iso8601
        limit = 100

        payload = call('get_trigger_payload',
                       input.merge('filter_date':
              created_after.to_time.in_time_zone('America/New_York')), 'created')
        response = post('/soap').headers('Content-Type': 'text/xml').payload(payload).
                   format_xml('soap:Envelope',
                              '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                              '@xmlns:tns' => 'http://namespaces.soaplite.com/perl',
                              '@xmlns:types' => 'http://namespaces.soaplite.com/perl/encodedTypes',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance')&.
          dig('Envelope', 0, 'Body', 0, 'readResponse', 0, 'Array', 0)

        records = call('format_xml_response_to_json',
                       response.dig('ReadResult', 0, 'objects', 0, 'item'))

        has_more = records.present? ? (records.size >= limit) : false
        # Time.now could miss some records. So, we are using last record's time.
        created_after = if records.present?
                          records.last['created'].to_time.iso8601
                        else
                          now.to_time.in_time_zone('America/New_York').iso8601
                        end
        closure = { 'created_after': created_after }

        {
          events: records.presence || [],
          next_poll: closure,
          can_poll_more: has_more
        }
      end,

      dedup: lambda do |record|
        "#{record['id']}@#{record['created']}"
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['trigger_object_output']
      end,

      sample_output: lambda do |_connection, input|
        call('sample_output', input, 'read_result')
      end
    },

    new_or_updated_object: {
      title: 'New/updated object',
      subtitle: 'Triggers when an object is created or updated.',
      description: lambda do |_connection, trigger_object_list|
        "New or updated <span class='provider'>#{trigger_object_list[:object] || 'object'}</span> "\
          ' in <span class="provider">OpenAir</span>'
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :trigger_object_list,
          hint: 'Select the object from list.'
        }
      ],

      input_fields: lambda do |_object_definition|
        [{
          name: 'since',
          type: 'timestamp',
          label: 'When first started, this recipe should pick up events from',
          hint: 'When you start recipe for the first time, ' \
            'it picks up trigger events from this specified date and time. ' \
            'Leave empty to get records created or updated one hour ago',
          sticky: true
        }]
      end,

      poll: lambda do |_connection, input, closure|
        closure ||= {}
        updated_after = closure['updated_after'] ||
                        (input['since'] || 1.hour.ago).to_time.
                        in_time_zone('America/New_York').iso8601
        limit = 100

        payload = call('get_trigger_payload',
                       input.merge('filter_date': updated_after.to_time),
                       'updated')
        response = post('/soap').headers('Content-Type': 'text/xml').payload(payload).
                   format_xml('soap:Envelope',
                              '@xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                              '@xmlns:tns' => 'http://namespaces.soaplite.com/perl',
                              '@xmlns:types' => 'http://namespaces.soaplite.com/perl/encodedTypes',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance')&.
          dig('Envelope', 0, 'Body', 0, 'readResponse', 0, 'Array', 0)

        records = call('format_xml_response_to_json',
                       response.dig('ReadResult', 0, 'objects', 0, 'item'))

        if records.present?
          records = records.sort_by { |obj| obj['updated'] || obj[:updated] }
          updated_after = if records.present?
                            records.last['updated'].to_time.iso8601
                          else
                            now.to_time.in_time_zone('America/New_York').iso8601
                          end
        end
        has_more = records.present? ? (records.size >= limit) : false
        closure = { 'updated_after': updated_after }

        {
          events: records.presence || [],
          next_poll: closure,
          can_poll_more: has_more
        }
      end,

      dedup: lambda do |record|
        "#{record['id']}@#{record['updated']}"
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['trigger_object_output']
      end,

      sample_output: lambda do |_connection, input|
        call('sample_output', input, 'read_result')
      end
    }
  },

  pick_lists: {
    trigger_object_list: lambda do |_connection|
      [
        %w[Project Project],
        %w[Project\ Task Projecttask],
        %w[User User],
        %w[Customer Customer],
        %w[Envelope Envelope],
        %w[Invoice Invoice],
        %w[Timesheet Timesheet],
        %w[Time\ Type Timetype],
        %w[Cost\ Type Costtype]
      ]
    end,

    search_object_list: lambda do |_connection|
      [
        %w[Project Project],
        %w[Project\ Task Projecttask],
        %w[User User],
        %w[Customer Customer],
        %w[Envelope Envelope],
        %w[Invoice Invoice],
        %w[Timesheet Timesheet],
        %w[Time\ Type Timetype],
        %w[Cost\ Type Costtype],
        %w[Currency Currency]
      ]
    end,

    create_object_list: lambda do |_connection|
      [
        %w[Project Project],
        %w[Project\ Task Projecttask],
        %w[User User],
        %w[Customer Customer],
        %w[Envelope Envelope],
        %w[Invoice Invoice],
        %w[Timesheet Timesheet],
        %w[Time\ Type Timetype],
        %w[Cost\ Type Costtype]
      ]
    end,

    update_object_list: lambda do |_connection|
      [
        %w[Project Project],
        %w[Project\ Task Projecttask],
        %w[User User],
        %w[Customer Customer],
        %w[Envelope Envelope],
        %w[Invoice Invoice],
        %w[Timesheet Timesheet],
        %w[Time\ Type Timetype],
        %w[Cost\ Type Costtype]
      ]
    end,

    delete_object_list: lambda do |_connection|
      [
        %w[Project Project],
        %w[Project\ Task Projecttask],
        %w[User User],
        %w[Customer Customer],
        %w[Envelope Envelope],
        %w[Invoice Invoice],
        %w[Timesheet Timesheet],
        %w[Time\ Type Timetype]
      ]
    end,

    upsert_object_list: lambda do |_connection|
      [
        %w[Project Project],
        %w[Project\ Task Projecttask],
        %w[User User],
        %w[Customer Customer],
        %w[Envelope Envelope],
        %w[Invoice Invoice],
        %w[Timesheet Timesheet],
        %w[Time\ Type Timetype],
        %w[Cost\ Type Costtype]
      ]
    end,

    approval_object_list: lambda do |_connection|
      [
        %w[Envelope Envelope],
        %w[Invoice Invoice],
        %w[Timesheet Timesheet]
      ]
    end,

    search_filter_list: lambda do |_connection|
      [
        %w[Open\ envelopes open-envelopes],
        %w[Approved\ envelopes approved-envelopes],
        %w[Rejected\ envelopes rejected-envelopes],
        %w[Submitted\ envelopes submitted-envelopes],
        %w[Non\ reimbursed\ envelopes nonreimbursed-envelopes],
        %w[Reimbursable\ envelopes reimbursable-envelopes],
        %w[Open\ slips open-slips],
        %w[Approved\ slips approved-slips],
        %w[Open\ timesheets open-timesheets],
        %w[Approved\ timesheets approved-timesheets],
        %w[Rejected\ timesheets rejected-timesheets],
        %w[Submitted\ timesheets submitted-timesheets],
        %w[Not\ exported not-exported],
        ['Approved revenue recognition transactions',
         'approved-revenue-recognitiontransactions']
      ]
    end,

    boolean_list: lambda do |_connection|
      [
        %w[True 1],
        %w[False 0]
      ]
    end
  }
}
