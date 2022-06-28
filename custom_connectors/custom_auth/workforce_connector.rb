{
  title: 'Workforce',
  secure_tunnel: true,
  connection: {
    fields: [
      { name: 'user_name',
        optional: false },
      { name: 'password',
        optional: false,
        control_type: 'password' },
      { name: 'base_url',
        optional: false,
        label: 'Host name',
        hint: 'hint: host name, e.g. https://abc.workforcehosting.eu' }
    ],
    authorization: {
      type: 'none'
    },
    base_uri: lambda do |connection|
      connection['base_url']
    end
  },
  test: lambda do |_|
    true
  end,
  methods: {
    build_request_fields_xml: lambda do |input|
      details = input&.dig('detailRequest', 'details')&.map do |items|
        {
          'xsd1:hours': [{
            "content!": items['hours']
          }],
          'xsd1:inTime': [{
            'xsd2:day': [{
              "content!": items['inTime']&.strftime('%d')
            }],
            'xsd2:month': [{
              "content!": items['inTime']&.strftime('%m')
            }],
            'xsd2:year': [{
              "content!": items['inTime']&.strftime('%Y')
            }],
            'xsd2:hours': [{
              "content!": items['inTime']&.strftime('%H')
            }],
            'xsd2:minutes': [{
              "content!": items['inTime']&.strftime('%M')
            }],
            'xsd2:seconds': [{
              "content!": items['inTime']&.strftime('%S')
            }]
          }],
          'xsd1:outTime': [{
            'xsd2:day': [{
              "content!": items['outTime']&.strftime('%d')
            }],
            'xsd2:month': [{
              "content!": items['outTime']&.strftime('%m')
            }],
            'xsd2:year': [{
              "content!": items['outTime']&.strftime('%Y')
            }],
            'xsd2:hours': [{
              "content!": items['outTime']&.strftime('%H')
            }],
            'xsd2:minutes': [{
              "content!": items['outTime']&.strftime('%M')
            }],
            'xsd2:seconds': [{
              "content!": items['outTime']&.strftime('%S')
            }]
          }],
          'xsd1:payCode': [{
            'xsd2:policyId': [{
              "content!": items['payCode']
            }]
          }],
          'xsd1:workDate': [{
            'xsd2:day': [{
              "content!": items['workDate']&.strftime('%d')
            }],
            'xsd2:month': [{
              "content!": items['workDate']&.strftime('%m')
            }],
            'xsd2:year': [{
              "content!": items['workDate']&.strftime('%Y')
            }]
          }]
        }
      end
      {
        'xsd1:assignmentId': [{
          'xsd2:id': [{
            "content!": input&.dig('detailRequest', 'assignmentId')
          }]
        }],
        'xsd1:comments': [{
          "content!": input&.dig('detailRequest', 'comments')
        }],
        'xsd1:details' => details
      }
    end,
    extract_multipart_boundary: lambda do |input|
      content_type = input.dig('content_type')
      if not content_type.present?
        error('Response error:Content-Type not found in HTTP response headers')
      end
      multipart_form_boundary = content_type.scan(/(?<=boundary=\")(.*?)(?=\")/).dig(0, 0)
      if not multipart_form_boundary.present?
        error('Response error:Multipart form boundary not found')
      else
        multipart_form_boundary
      end
    end,
    generate_xml_payload: lambda do |input|
      idc_service = input.dig(:idc_service)
      document_element = input.dig(:document_element)
      if not (idc_service.present? and document_element.present?)
        error('IdcService or Document content not present')
      end
      {
        "@xmlns:ns1": 'http://schemas.xmlsoap.org/soap/envelope/',
        "ns1:Body": [{
          "ns2:GenericRequest": [{
            "@xmlns:ns2": 'http://www.oracle.com/UCM',
            "@webKey": 'cs',
            "ns2:Service": [{
              "@IdcService": idc_service,
              "content!": document_element
            }]
          }]
        }]
      }
    end,
    extract_content_headers: lambda do |input|
      content_headers_string = input.strip.split(/^\s*$(?:\r\n?|\n)/m).dig(0)
      if not content_headers_string.blank?
        {
          content_headers: content_headers_string.scan(/([\w-]+): (.*)/).map do |i|
            {
              key: i.dig(0),
              value: i.dig(1)
            }
          end
        }
      end
    end,
    extract_content_body: lambda do |input|
      content_body = input.strip.split(/^\s*$(?:\r\n?|\n)/m).dig(1)
      content_body.blank? ? nil : { content_body: content_body }
    end,
    extract_multipart_parts: lambda do |input|
      body = input.dig(:body)
      multipart_form_boundary = input.dig(:multipart_form_boundary).present? ? input.dig(:multipart_form_boundary) : "--#{call(:extract_multipart_boundary, input.dig(:headers))}"
      content_strings = body.split(multipart_form_boundary)[1..-2]
      parts = content_strings.map do |i|
        call(:extract_content_headers, i).merge(
          call(:extract_content_body, i)
        )
      end
      parts
    end
  },
  object_definitions: {
    submit_time_off_request: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'acknowledgments' },
          { name: 'comments' },
          { name: 'detailRequest', label: 'Request details', type: 'object',
            properties: [
              { name: 'assignmentId', type: 'integer' },
              { name: 'caseId', type: 'integer' },
              { name: 'comments' },
              { name: 'details', label: 'Time off items', type: 'array', of: 'object', properties: [
                { name: 'hours', type: 'number' },
                { name: 'inTime', type: 'date_time' },
                { name: 'outTime', type: 'date_time' },
                { name: 'payCode', hint: 'The ID of the pay code for which the specific detail' \
                  ' record is entered against.' },
                { name: 'workDate', type: 'date' }
              ] }
            ] },
          { name: 'requestDateRange', type: 'object', properties: [
            { name: 'startDate', type: 'date',
              hint: 'The day, month, and year of the first date of the time off request.' },
            { name: 'endDate', type: 'date',
              hint: 'The day, month, and year of the last date of the time off request.' }
          ] }
        ]
      end
    },
    submmit_time_off_response: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'detailedErrorMessage' },
          { name: 'operationSuccessful' },
          { name: 'resultCode' },
          { name: 'resultDescription' },
          { name: 'result', type: 'object', properties: [
            { name: 'detailResponse', type: 'object', properties: [
              { name: 'acknowledgments', type: 'array', of: 'object', properties: [
                { name: 'acknowledgmentId', type: 'integer', hint: 'A configured ID for a type of acknowledgment.' },
                { name: 'acknowledgmentLabel', hint: 'A configured, short description of the acknowledgment type.' },
                { name: 'displayMethod' },
                { name: 'informationLabel' },
                { name: 'informationText' },
                { name: 'informationUrl' },
                { name: 'payCode' }
              ] },
              { name: 'assignmentId', type: 'object', properties: [
                { name: 'id' }
              ] },
              { name: 'banks', type: 'array', of: 'object', properties: [
                { name: 'bankId', type: 'integer' },
                { name: 'label' },
                { name: 'maxWarningThreshold', type: 'number' },
                { name: 'minWarningThreshold', type: 'number' },
                { name: 'transactions', type: 'array', of: 'object', properties: [
                  { name: 'amount', type: 'number' },
                  { name: 'newBalance', type: 'number' },
                  { name: 'sourceDescription' },
                  { name: 'type' },
                  { name: 'workDate', type: 'object', properties: [
                    { name: 'day', type: 'integer' },
                    { name: 'month', type: 'integer' },
                    { name: 'year', type: 'integer' }
                  ] }
                ] },
                { name: 'unitsDescription' },
                { name: 'unitsFormatPattern' }
              ] },
              { name: 'bankUsages', type: 'array', of: 'object', properties: [
                { name: 'bankId', type: 'integer' },
                { name: 'amount', type: 'number' }
              ] },
              { name: 'caseId', type: 'object', propeties: [
                { name: 'id' }
              ] },
              { name: 'details', type: 'array', of: 'object', properties: [
                { name: 'hours' },
                { name: 'inTime', type: 'object', properties: [
                  { name: 'day', type: 'integer' },
                  { name: 'month', type: 'integer' },
                  { name: 'year', type: 'integer' },
                  { name: 'hours', type: 'integer' },
                  { name: 'minutes', type: 'integer' },
                  { name: 'seconds', type: 'integer' }
                ] },
                { name: 'outTime', type: 'object', properties: [
                  { name: 'day', type: 'integer' },
                  { name: 'month', type: 'integer' },
                  { name: 'year', type: 'integer' },
                  { name: 'hours', type: 'integer' },
                  { name: 'minutes', type: 'integer' },
                  { name: 'seconds', type: 'integer' }
                ] },
                { name: 'payCode' },
                { name: 'workDate', type: 'object', properties: [
                  { name: 'day', type: 'integer' },
                  { name: 'month', type: 'integer' },
                  { name: 'year', type: 'integer' }
                ] }
              ] },
              { name: 'exceptions', type: 'array', of: 'object', properties: [
                { name: 'message' },
                { name: 'severity' },
                { name: 'workDate', type: 'object', properties: [
                  { name: 'day', type: 'integer' },
                  { name: 'month', type: 'integer' },
                  { name: 'year', type: 'integer' }
                ] }
              ] },
              { name: 'historyEvents', type: 'array', of: 'object', properties: [
                { name: 'comments' },
                { name: 'status' },
                { name: 'userName' },
                { name: 'workDate', type: 'object', properties: [
                  { name: 'day', type: 'integer' },
                  { name: 'month', type: 'integer' },
                  { name: 'year', type: 'integer' }
                ] }
              ] },
              { name: 'permissions', type: 'object', properties: [
                { name: 'canApprove', type: 'boolean' },
                { name: 'canCancel', type: 'boolean' },
                { name: 'canReject', type: 'boolean' },
                { name: 'canSubmit', type: 'boolean' }
              ] },
              { name: 'showExceptionsAndBanks', type: 'boolean' },
              { name: 'status' }
            ] },
            { name: 'statusResponse', type: 'object', propeties: [
              { name: 'ERROR_MESSAGE' },
              { name: 'STATUS' }
            ] },
            { name: 'timeOffRequestId', type: 'object', properties: [
              { name: 'id' }
            ] }
          ] }
        ]
      end
    },
    time_off_request_details: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'detailedErrorMessage' },
          { name: 'operationSuccessful' },
          { name: 'resultCode' },
          { name: 'resultDescription' },
          { name: 'result', type: 'object', properties: [
            { name: 'assignmentInfo', type: 'object', properties: [
              { name: 'assignmentId', type: 'object', properties: [
                { name: 'id' }
              ] },
              { name: 'assignmentDescription' }
            ] },
            { name: 'bankBalances', type: 'array', of: 'object', properties: [
              { name: 'balance', type: 'number' },
              { name: 'bankName' }
            ] },
            { name: 'comments' },
            { name: 'employeeDisplayInfo', type: 'object', properties: [
              { name: 'displayEmployee' },
              { name: 'employeeId', type: 'object', properties: [
                { name: 'id' }
              ] },
              { name: 'firstName' },
              { name: 'lastName' }
            ] },
            { name: 'requestDateTime', type: 'object', properties: [
              { name: 'day', type: 'integer' },
              { name: 'month', type: 'integer' },
              { name: 'year', type: 'integer' },
              { name: 'hours', type: 'integer' },
              { name: 'minutes', type: 'integer' },
              { name: 'seconds', type: 'integer' }
            ] },
            { name: 'timeOffHours', type: 'array', of: 'object', properties: [
              { name: 'endDateTime', type: 'object', properties: [
                { name: 'day', type: 'integer' },
                { name: 'month', type: 'integer' },
                { name: 'year', type: 'integer' },
                { name: 'hours', type: 'integer' },
                { name: 'minutes', type: 'integer' },
                { name: 'seconds', type: 'integer' }
              ] },
              { name: 'hours', type: 'number' },
              { name: 'payCode' },
              { name: 'startDateTime', type: 'object', properties: [
                { name: 'day', type: 'integer' },
                { name: 'month', type: 'integer' },
                { name: 'year', type: 'integer' },
                { name: 'hours', type: 'integer' },
                { name: 'minutes', type: 'integer' },
                { name: 'seconds', type: 'integer' }
              ] },
              { name: 'workDate', type: 'object', properties: [
                { name: 'day', type: 'integer' },
                { name: 'month', type: 'integer' },
                { name: 'year', type: 'integer' }
              ] }
            ] },
            { name: 'timeOffRequestId', type: 'object', properties: [
              { name: 'id' }
            ] },
            { name: 'torEndDate', label: 'Time of request end date',
              type: 'object', properties: [
                { name: 'day', type: 'integer' },
                { name: 'month', type: 'integer' },
                { name: 'year', type: 'integer' }
              ] },
            { name: 'torStartDate', label: 'Time of request start date',
              type: 'object', properties: [
                { name: 'day', type: 'integer' },
                { name: 'month', type: 'integer' },
                { name: 'year', type: 'integer' }
              ] },
            { name: 'torExceptions', type: 'array', of: 'object', properties: [
              { name: 'dateTime', type: 'object', properties: [
                { name: 'day', type: 'integer' },
                { name: 'month', type: 'integer' },
                { name: 'year', type: 'integer' },
                { name: 'hours', type: 'integer' },
                { name: 'minutes', type: 'integer' },
                { name: 'seconds', type: 'integer' }
              ] },
              { name: 'message' },
              { name: 'severity', type: 'object', properties: [
                { name: 'exception_severity' }
              ] },
              { name: 'torStatus', label: 'Time off request status', type: 'object', properties: [
                { name: 'time_off_request_status' }
              ] }
            ] }
          ] }
        ]
      end
    },
    multipart_form_parts: {
      fields: lambda do |_|
        [
          { name: 'multipart_form_boundary' },
          {
            name: 'multipart_form_parts', type: 'array', of: 'object', properties: [
              {
                name: 'content_headers', type: 'array', of: 'object', properties: [
                  { name: 'key' },
                  { name: 'value' }
                ]
              },
              { name: 'content_body' }
            ]
          },
          { name: 'code' },
          { name: 'headers', type: 'object' },
          { name: 'body' }
        ]
      end
    }
  },
  actions: {
    submit_timeoff_request: {
      title: 'Submits a time off request',
      input_fields: lambda do |object_definitions|
        object_definitions['submit_time_off_request']
      end,
      execute: lambda do |connection, input|
        nonce = "#{now.to_i}workato"
        created_time = now.to_time.strftime('%Y-%m-%dT%H:%M:%SZ')
        password_digest = (nonce + created_time + connection['password']).sha1.encode_base64

        post('/workforce/services/E2G_submitTimeOffRequest').
          payload("soapenv:Header": [{
                    'wsse:Security': [{
                      '@xmlns:wsse': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                      '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                      '@soapenv:mustUnderstand': '1',
                      'wsse:UsernameToken': [{
                        '@wsu:Id': 'UsernameToken-CBF92886ABADBFD1E715712314369112',
                        '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                        'wsse:Username': [{
                          "content!": connection['user_name']
                        }],
                        'wsse:Password': [{
                          '@Type':
                            'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest',
                          "content!": password_digest
                        }],
                        'wsse:Nonce': [{
                          '@EncodingType': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary',
                          "content!": nonce.base64
                        }],
                        'wsu:Created': [{
                          "content!": created_time
                        }]
                      }]
                    }]
                  }],
                  "soapenv:Body": [{
                    'xsd:E2G_submitTimeOffRequest': [{
                      'xsd:submitRequest': [{
                        'xsd1:detailRequest':
                          [call('build_request_fields_xml', input)],
                        'xsd1:requestDateRange': [{
                          'xsd1:endDate': [{
                            'xsd2:day': [{
                              "content!": input&.
                              dig('requestDateRange', 'endDate')&.
                              strftime('%d')
                            }],
                            'xsd2:month': [{
                              "content!": input&.
                              dig('requestDateRange', 'endDate')&.
                              strftime('%m')
                            }],
                            'xsd2:year': [{
                              "content!": input&.
                              dig('requestDateRange', 'endDate')&.
                              strftime('%Y')
                            }]
                          }],
                          'xsd1:startDate': [{
                            'xsd2:day': [{
                              "content!": input&.
                              dig('requestDateRange', 'startDate')&.
                              strftime('%d')
                            }],
                            'xsd2:month': [{
                              "content!": input&.
                              dig('requestDateRange', 'startDate')&.
                              strftime('%m')
                            }],
                            'xsd2:year': [{
                              "content!": input&.
                              dig('requestDateRange', 'startDate')&.
                              strftime('%Y')
                            }]
                          }]
                        }]
                      }]
                    }]
                  }]).
          headers('Content-Type': 'text/xml;charset=UTF-8').
          format_xml('soapenv:Envelope',
                     '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                     '@xmlns:xsd' => 'http://services.workforcesoftware.com/xsd',
                     '@xmlns:xsd1' => 'http://ws.apache.org/axis2/xsd',
                     '@xmlns:xsd2' => 'http://data.service.webservices.workforcesoftware.com/xsd',
                     strip_response_namespaces: true).
          response_format_raw.after_response do |code, body, headers|
            if code.to_i != 200
              error("#{code}:#{body}")
            else
              multipart_form_boundary = "--#{call(:extract_multipart_boundary, headers)}"
              {
                multipart_form_boundary: multipart_form_boundary,
                multipart_form_parts:
                  call(:extract_multipart_parts,
                       { multipart_form_boundary: multipart_form_boundary, body: body }),
                code: code,
                headers: headers,
                body: body
              }
            end
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['multipart_form_parts']
      end
    },
    approve_time_off_request: {
      title: 'Approves the time-off request',
      help: 'User invoking this action must have one of the following ' \
      'system features assigned in order to successfully perform the ' \
      'operation<br/><b>E2G_TIMEOFF_REQUEST_APPROVAL</b',
      input_fields: lambda do |_object_definitions|
        [
          { name: 'managerComments', optional: false },
          { name: 'timeOffRequestId', type: 'integer', optional: false }
        ]
      end,
      execute: lambda do |connection, input|
        nonce = "#{now.to_i}workto"
        created_time = now.to_time.strftime('%Y-%m-%dT%H:%M:%SZ')
        password_digest = (nonce + created_time + connection['password']).sha1.encode_base64

        post('/workforce/services/E2G_approveTimeOffRequest').
          payload("soapenv:Header": [{
                    'wsse:Security': [{
                      '@xmlns:wsse': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                      '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                      '@soapenv:mustUnderstand': '1',
                      'wsse:UsernameToken': [{
                        '@wsu:Id': 'UsernameToken-CBF92886ABADBFD1E715712314369112',
                        '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                        'wsse:Username': [{
                          "content!": connection['user_name']
                        }],
                        'wsse:Password': [{
                          '@Type': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest',
                          "content!": password_digest
                        }],
                        'wsse:Nonce': [{
                          '@EncodingType': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary',
                          "content!": nonce.base64
                        }],
                        'wsu:Created': [{
                          "content!": created_time
                        }]
                      }]
                    }]
                  }],
                  "soapenv:Body": [{
                    'xsd:E2G_approveTimeOffRequest': [{
                      'xsd:timeOffRequestParams': [{
                        'xsd1:managerComments': [{
                          "content!": input['managerComments']
                        }],
                        'xsd1:timeOffRequestId': [{
                          'xsd2:id': [{
                            "content!": input['timeOffRequestId']
                          }]
                        }]
                      }]
                    }]
                  }]).
          headers('Content-Type': 'text/xml;charset=UTF-8').
          format_xml('soapenv:Envelope',
                     '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                     '@xmlns:xsd' => 'http://services.workforcesoftware.com/xsd',
                     '@xmlns:xsd1' => 'http://ws.apache.org/axis2/xsd',
                     '@xmlns:xsd2' => 'http://data.service.webservices.workforcesoftware.com/xsd',
                     strip_response_namespaces: true).
          response_format_raw.after_response do |code, body, headers|
            if code.to_i != 200
              error("#{code}:#{body}")
            else
              multipart_form_boundary = "--#{call(:extract_multipart_boundary, headers)}"
              {
                multipart_form_boundary: multipart_form_boundary,
                multipart_form_parts: call(:extract_multipart_parts,
                                           { multipart_form_boundary: multipart_form_boundary, body: body }),
                code: code,
                headers: headers,
                body: body
              }
            end
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['multipart_form_parts']
      end
    },
    reject_timeoff_request: {
      title: 'Rejects the time-off request',
      help: 'User invoking this action must have one of the following ' \
      'system features assigned in order to successfully perform the ' \
      'operation<br/><b>E2G_TIMEOFF_REQUEST_APPROVAL</b',
      input_fields: lambda do |_object_definitions|
        [
          { name: 'managerComments', optional: false },
          { name: 'timeOffRequestId', type: 'integer', optional: false }
        ]
      end,
      execute: lambda do |connection, input|
        nonce = "#{now.to_i}workto"
        created_time = now.to_time.strftime('%Y-%m-%dT%H:%M:%SZ')
        password_digest = (nonce + created_time + connection['password']).sha1.encode_base64

        post('/workforce/services/E2G_rejectTimeOffRequest.E2G_rejectTimeOffRequestHttpsSoap12Endpoint/').
          payload("soapenv:Header": [{
                    'wsse:Security': [{
                      '@xmlns:wsse': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                      '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                      '@soapenv:mustUnderstand': '1',
                      'wsse:UsernameToken': [{
                        '@wsu:Id': 'UsernameToken-CBF92886ABADBFD1E715712314369112',
                        '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                        'wsse:Username': [{
                          "content!": connection['user_name']
                        }],
                        'wsse:Password': [{
                          '@Type': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest',
                          "content!": password_digest
                        }],
                        'wsse:Nonce': [{
                          '@EncodingType': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary',
                          "content!": nonce.base64
                        }],
                        'wsu:Created': [{
                          "content!": created_time
                        }]
                      }]
                    }]
                  }],
                  "soapenv:Body": [{
                    'xsd:E2G_rejectTimeOffRequest': [{
                      'xsd:timeOffRequestParams': [{
                        'xsd1:managerComments': [{
                          "content!": input['managerComments']
                        }],
                        'xsd1:timeOffRequestId': [{
                          'xsd2:id': [{
                            "content!": input['timeOffRequestId']
                          }]
                        }]
                      }]
                    }]
                  }]).
          headers('Content-Type': 'text/xml;charset=UTF-8').
          format_xml('soapenv:Envelope',
                     '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                     '@xmlns:xsd' => 'http://services.workforcesoftware.com/xsd',
                     '@xmlns:xsd1' => 'http://ws.apache.org/axis2/xsd',
                     '@xmlns:xsd2' => 'http://data.service.webservices.workforcesoftware.com/xsd',
                     strip_response_namespaces: true).
          response_format_raw.after_response do |code, body, headers|
            if code.to_i != 200
              error("#{code}:#{body}")
            else
              multipart_form_boundary = "--#{call(:extract_multipart_boundary, headers)}"
              {
                multipart_form_boundary: multipart_form_boundary,
                multipart_form_parts: call(:extract_multipart_parts,
                                           { multipart_form_boundary: multipart_form_boundary, body: body }),
                code: code,
                headers: headers,
                body: body
              }
            end
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['multipart_form_parts']
      end
    },
    change_time_off_request_status: {
      title: 'Changes a time-off request status',
      input_fields: lambda do |_object_definitions|
        [
          { name: 'comments', optional: true, sticky: true },
          {
            name: 'newStatus',
            label: 'New status',
            control_type: 'select',
            pick_list: [
              %w[Approved APPROVED],
              %w[Rejected REJECTED],
              %w[Cancelled CANCELLED]
            ],
            optional: false,
            hint: 'The status is changed only if the user is allowed to change the time off request status.',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'newStatus',
              label: 'New status',
              type: 'string',
              control_type: 'text',
              optional: false,
              toggle_hint: 'Use custom value',
              hint: 'Valid values are: REJECTED, APPROVED or CANCELLED.'
            }
          },
          { name: 'requestId', label: 'Time-off request ID', optional: false }
        ]
      end,
      execute: lambda do |connection, input|
        nonce = "#{now.to_i}workto"
        created_time = now.to_time.strftime('%Y-%m-%dT%H:%M:%SZ')
        password_digest = (nonce + created_time + connection['password']).sha1.encode_base64

        post('/workforce/services/E2G_changeTimeOffRequestStatus').
          payload("soapenv:Header": [{
                    'wsse:Security': [{
                      '@xmlns:wsse': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                      '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                      '@soapenv:mustUnderstand': '1',
                      'wsse:UsernameToken': [{
                        '@wsu:Id': 'UsernameToken-CBF92886ABADBFD1E715712314369112',
                        '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                        'wsse:Username': [{
                          "content!": connection['user_name']
                        }],
                        'wsse:Password': [{
                          '@Type': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest',
                          "content!": password_digest
                        }],
                        'wsse:Nonce': [{
                          '@EncodingType': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary',
                          "content!": nonce.base64
                        }],
                        'wsu:Created': [{
                          "content!": created_time
                        }]
                      }]
                    }]
                  }],
                  "soapenv:Body": [{
                    'xsd:E2G_changeTimeOffRequestStatus': [{
                      'xsd:statusChangeRequest': [{
                        'xsd1:comments': [{
                          "content!": input['comments']
                        }],
                        'xsd1:newStatus': [{
                          'xsd2:time_off_request_status': [{
                            "content!": input['newStatus']
                          }]
                        }],
                        'xsd1:requestId': [{
                          'xsd2:id': [{
                            "content!": input['requestId']
                          }]
                        }]
                      }]
                    }]
                  }]).
          headers('Content-Type': 'text/xml;charset=UTF-8').
          format_xml('soapenv:Envelope',
                     '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                     '@xmlns:xsd' => 'http://services.workforcesoftware.com/xsd',
                     '@xmlns:xsd1' => 'http://ws.apache.org/axis2/xsd',
                     '@xmlns:xsd2' => 'http://data.service.webservices.workforcesoftware.com/xsd',
                     strip_response_namespaces: true).
          response_format_raw.after_response do |code, body, headers|
            if code.to_i != 200
              error("#{code}:#{body}")
            else
              multipart_form_boundary = "--#{call(:extract_multipart_boundary, headers)}"
              {
                multipart_form_boundary: multipart_form_boundary,
                multipart_form_parts: call(:extract_multipart_parts,
                                           { multipart_form_boundary: multipart_form_boundary, body: body }),
                code: code,
                headers: headers,
                body: body
              }
            end
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['multipart_form_parts']
      end
    },
    get_timeoff_request_details: {
      title: 'Gets details for a time off request',
      hint: 'User invoking this service must have one of the following system' \
      ' features assigned in order to successfully perform the operation.<br/>' \
      'E2G_TIMEOFF_REQUEST_APPROVAL',
      input_fields: lambda do |_object_definitions|
        [
          { name: 'timeOffRequestId', type: 'integer', optional: false },
          { name: 'userId', hint: 'User ID to be used for Impersonation.', label: 'User ID' }
        ]
      end,
      execute: lambda do |connection, input|
        nonce = "#{now.to_i}workto"
        created_time = now.to_time.strftime('%Y-%m-%dT%H:%M:%SZ')
        password_digest = (nonce + created_time + connection['password']).sha1.encode_base64

        post('/workforce/services/E2G_getTimeOffRequestDetails').
          payload("soapenv:Header": [{
                    'wsse:Security': [{
                      '@xmlns:wsse': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                      '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                      '@soapenv:mustUnderstand': '1',
                      'wsse:UsernameToken': [{
                        '@wsu:Id': 'UsernameToken-CBF92886ABADBFD1E715712314369112',
                        '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                        'wsse:Username': [{
                          "content!": connection['user_name']
                        }],
                        'wsse:Password': [{
                          '@Type': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest',
                          "content!": password_digest
                        }],
                        'wsse:Nonce': [{
                          '@EncodingType': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary',
                          "content!": nonce.base64
                        }],
                        'wsu:Created': [{
                          "content!": created_time
                        }]
                      }]
                    }],
                    'wfswse:Impersonate': [{
                      '@xmlns:wfswse': 'http://services.workforcesoftware.com/xsd',
                      'wfswse:UserId': [{
                        "content!": input['userId']
                      }]
                    }]
                  }],
                  "soapenv:Body": [{
                    'xsd:E2G_getTimeOffRequestDetails': [{
                      'xsd:timeOffRequestId': [{
                        'xsd1:id': [{ "content!": input['timeOffRequestId'] }]
                      }]
                    }]
                  }]).
          headers('Content-Type': 'text/xml;charset=UTF-8').
          format_xml('soapenv:Envelope',
                     '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                     '@xmlns:xsd' => 'http://services.workforcesoftware.com/xsd',
                     '@xmlns:xsd1' => 'http://data.service.webservices.workforcesoftware.com/xsd',
                     strip_response_namespaces: true).
          response_format_raw.after_response do |code, body, headers|
            if code.to_i != 200
              error("#{code}:#{body}")
            else
              multipart_form_boundary = "--#{call(:extract_multipart_boundary, headers)}"
              {
                multipart_form_boundary: multipart_form_boundary,
                multipart_form_parts:
                  call(:extract_multipart_parts, { multipart_form_boundary: multipart_form_boundary, body: body }),
                code: code,
                headers: headers,
                body: body
              }
            end
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['multipart_form_parts']
      end
    },
    validate_token: {

      execute: lambda do |connection|
        nonce = now.to_i.to_s + 'workto'
        created_time = now.to_time.strftime('%Y-%m-%dT%H:%M:%SZ')
        password_digest = (nonce + created_time + connection['password']).sha1.encode_base64

        post('/workforce/services/E2G_getEmployeeList/').
          payload("soapenv:Header": [{
                    'wsse:Security': [{
                      '@xmlns:wsse': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                      '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                      '@soapenv:mustUnderstand': '1',
                      'wsse:UsernameToken': [{
                        '@wsu:Id': 'UsernameToken-CBF92886ABADBFD1E715712314369112',
                        '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                        'wsse:Username': [{
                          "content!": connection['user_name']
                        }],
                        'wsse:Password': [{
                          '@Type': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest',
                          "content!": password_digest
                        }],
                        'wsse:Nonce': [{
                          '@EncodingType': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary',
                          "content!": nonce.base64
                        }],
                        'wsu:Created': [{
                          "content!": created_time
                        }]
                      }]
                    }]
                  }],
                  "soapenv:Body": [{
                    'xsd:E2G_getEmployeeList': [{
                      "content!": nil
                    }]
                  }]).
          headers('Content-Type': 'text/xml;charset=UTF-8',
                  'Accept': 'gzip,deflate').
          format_xml('soapenv:Envelope',
                     '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                     '@xmlns:xsd' => 'http://services.workforcesoftware.com/xsd',
                     strip_response_namespaces: true).
          response_format_raw.after_response do |code, body, headers|
            if code.to_i != 200
              error("#{code}:#{body}")
            else
              multipart_form_boundary = "--#{call(:extract_multipart_boundary, headers)}"
              {
                multipart_form_boundary: multipart_form_boundary,
                multipart_form_parts: call(:extract_multipart_parts, { multipart_form_boundary: multipart_form_boundary, body: body }),
                code: code,
                headers: headers,
                body: body
              }
            end
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['multipart_form_parts']
      end
    },
    get_version: {
      execute: lambda do |connection|
        nonce = now.to_i.to_s + 'workto'
        created_time = now.to_time.strftime('%Y-%m-%dT%H:%M:%SZ')
        password_digest = (nonce + created_time + connection['password']).sha1.encode_base64

        post('https://central-dev.workforcehosting.eu/workforce/services/E2G_getVersion/').
          payload("soapenv:Header": [{
                    'wsse:Security': [{
                      '@xmlns:wsse': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                      '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                      '@soapenv:mustUnderstand': '1',
                      'wsse:UsernameToken': [{
                        '@wsu:Id': 'UsernameToken-CBF92886ABADBFD1E715712314369112',
                        '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                        'wsse:Username': [{
                          "content!": connection['user_name']
                        }],
                        'wsse:Password': [{
                          '@Type': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest',
                          "content!": password_digest
                        }],
                        'wsse:Nonce': [{
                          '@EncodingType': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary',
                          "content!": nonce.base64
                        }],
                        'wsu:Created': [{
                          "content!": created_time
                        }]
                      }]
                    }]
                  }],
                  "soapenv:Body": [{
                    'xsd:getVersion': [{}]
                  }]).
          headers('Content-Type': 'text/xml;charset=UTF-8',
                  'Accept': 'gzip,deflate',
                  'SOAPAction': 'urn:E2G_getVersion').
          format_xml('soapenv:Envelope',
                     '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                     '@xmlns:xsd' => 'http://services.workforcesoftware.com/xsd',
                     strip_response_namespaces: true).
          response_format_raw.after_response do |code, body, headers|
            if code.to_i != 200
              error("#{code}:#{body}")
            else
              multipart_form_boundary = "--#{call(:extract_multipart_boundary, headers)}"
              {
                multipart_form_boundary: multipart_form_boundary,
                multipart_form_parts: call(:extract_multipart_parts, { multipart_form_boundary: multipart_form_boundary, body: body }),
                code: code,
                headers: headers,
                body: body
              }
            end
          end
      end
    },
    get_leave_balances: {
      title: 'Get leave balance by employee',
      input_fields: lambda do |_object_definitions|
        [
          { name: 'employeeMatchValue', label: 'Employee ID', optional: false },
          { name: 'startDate', type: 'date', label: 'Start date', optional: false },
          { name: 'endDate', type: 'date', label: 'End date', optional: false }
        ]
      end,
      execute: lambda do |connection, input|
        nonce = "#{now.to_i}workto"
        created_time = now.to_time.strftime('%Y-%m-%dT%H:%M:%SZ')
        password_digest = (nonce + created_time + connection['password']).sha1.encode_base64
        post('/workforce/services/E2G_getBankBalances').
          payload("soapenv:Header": [{
                    'wsse:Security': [{
                      '@xmlns:wsse': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                      '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                      '@soapenv:mustUnderstand': '1',
                      'wsse:UsernameToken': [{
                        '@wsu:Id': 'UsernameToken-CBF92886ABADBFD1E715712314369112',
                        '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                        'wsse:Username': [{
                          "content!": connection['user_name']
                        }],
                        'wsse:Password': [{
                          '@Type': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest',
                          "content!": password_digest
                        }],
                        'wsse:Nonce': [{
                          '@EncodingType': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary',
                          "content!": nonce.base64
                        }],
                        'wsu:Created': [{
                          "content!": created_time
                        }]
                      }]
                    }]
                  }],
                  "soapenv:Body": [{
                    'xsd:E2G_getBankBalances': [{
                      'xsd:payload': [{
                        'xsd1:dateRange': [{
                          'xsd1:endDate': [{
                            'xsd2:day': [{
                              "content!": input['endDate']&.strftime('%d')
                            }],
                            'xsd2:month': [{
                              "content!": input['endDate']&.strftime('%m')
                            }],
                            'xsd2:year': [{
                              "content!": input['endDate']&.strftime('%Y')
                            }]
                          }],
                          'xsd1:startDate': [{
                            'xsd2:day': [{
                              "content!": input['startDate']&.strftime('%d')
                            }],
                            'xsd2:month': [{
                              "content!": input['startDate']&.strftime('%m')
                            }],
                            'xsd2:year': [{
                              "content!": input['startDate']&.strftime('%Y')
                            }]
                          }]
                        }],
                        'xsd1:employeeMatchValue': [{
                          "content!": input['employeeMatchValue']
                        }]
                      }]
                    }]
                  }]).
          headers('Content-Type': 'text/xml;charset=UTF-8').
          format_xml('soapenv:Envelope',
                     '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                     '@xmlns:xsd' => 'http://services.workforcesoftware.com/xsd',
                     '@xmlns:xsd1' => 'http://ws.apache.org/axis2/xsd',
                     '@xmlns:xsd2' => 'http://data.service.webservices.workforcesoftware.com/xsd',
                     strip_response_namespaces: true).
          response_format_raw.after_response do |code, body, headers|
            if code.to_i != 200
              error("#{code}:#{body}")
            else
              multipart_form_boundary = "--#{call(:extract_multipart_boundary, headers)}"
              {
                multipart_form_boundary: multipart_form_boundary,
                multipart_form_parts:
                  call(:extract_multipart_parts, { multipart_form_boundary: multipart_form_boundary, body: body }),
                code: code,
                headers: headers,
                body: body
              }
            end
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['multipart_form_parts']
      end
    },
    get_periods: {
      title: 'Get periods by employee',
      input_fields: lambda do |_object_definitions|
        [
          { name: 'asgnmtInfo', label: 'Assignment info', type: 'object',
            optional: false, sticky: true,
            properties: [
              { name: 'assignmentDescription' },
              { name: 'assignmentId' }
            ] },
          { name: 'numberOfPriorPeriods', type: 'number', sticky: true,
            hint: 'Number of prior periods needed to be fetched along with' \
              ' the period for which requestDate belongs.' },
          { name: 'requestDate', type: 'date', optional: false,
            hint: 'The date for which the period must be fetched.' }
        ]
      end,
      execute: lambda do |connection, input|
        nonce = "#{now.to_i}workto"
        created_time = now.to_time.strftime('%Y-%m-%dT%H:%M:%SZ')
        password_digest = (nonce + created_time + connection['password']).sha1.encode_base64
        post('/workforce/services/E2G_getPeriods').
          payload("soapenv:Header": [{
                    'wsse:Security': [{
                      '@xmlns:wsse': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                      '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                      '@soapenv:mustUnderstand': '1',
                      'wsse:UsernameToken': [{
                        '@wsu:Id': 'UsernameToken-CBF92886ABADBFD1E715712314369112',
                        '@xmlns:wsu': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                        'wsse:Username': [{
                          "content!": connection['user_name']
                        }],
                        'wsse:Password': [{
                          '@Type': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest',
                          "content!": password_digest
                        }],
                        'wsse:Nonce': [{
                          '@EncodingType': 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary',
                          "content!": nonce.base64
                        }],
                        'wsu:Created': [{
                          "content!": created_time
                        }]
                      }]
                    }]
                  }],
                  "soapenv:Body": [{
                    'xsd:E2G_getPeriods': [{
                      'xsd:request': [{
                        'xsd1:asgnmtInfo': [{
                          'xsd1:assignmentDescription': [{
                            "content!": input&.dig('asgnmtInfo', 'assignmentDescription')
                          }],
                          'xsd1:assignmentId': [{
                            'xsd2:id': [{
                              "content!": input&.dig('asgnmtInfo', 'assignmentId')
                            }]
                          }]
                        }],
                        'xsd1:requestDate': [{
                          'xsd2:day': [{
                            "content!": input['requestDate']&.strftime('%d')
                          }],
                          'xsd2:month': [{
                            "content!": input['requestDate']&.strftime('%m')
                          }],
                          'xsd2:year': [{
                            "content!": input['requestDate']&.strftime('%Y')
                          }]
                        }],
                        'xsd1:numberOfPriorPeriods': [{
                          "content!": input['numberOfPriorPeriods']
                        }]
                      }]
                    }]
                  }]).
          headers('Content-Type': 'text/xml;charset=UTF-8').
          format_xml('soapenv:Envelope',
                     '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                     '@xmlns:xsd' => 'http://services.workforcesoftware.com/xsd',
                     '@xmlns:xsd1' => 'http://ws.apache.org/axis2/xsd',
                     '@xmlns:xsd2' => 'http://data.service.webservices.workforcesoftware.com/xsd',
                     strip_response_namespaces: true).
          response_format_raw.after_response do |code, body, headers|
            if code.to_i != 200
              error("#{code}:#{body}")
            else
              multipart_form_boundary = "--#{call(:extract_multipart_boundary, headers)}"
              {
                multipart_form_boundary: multipart_form_boundary,
                multipart_form_parts:
                  call(:extract_multipart_parts, { multipart_form_boundary: multipart_form_boundary, body: body }),
                code: code,
                headers: headers,
                body: body
              }
            end
          end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['multipart_form_parts']
      end
    }
  }
}
