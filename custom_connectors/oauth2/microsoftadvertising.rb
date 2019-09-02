{
  title: 'Microsoft Advertising',

  connection: {
    fields: [
      {
        name: 'client_id',
        hint: 'The application (client) ID that the Azure portal assigned your'\
          ' app.<br/>To get your client ID, follow the instructions ' \
          "<a href='https://docs.microsoft.com/en-us/advertising/guides/" \
          "authentication-oauth-live-connect?view=bingads-13' target='_blank'>"\
          'here</a>.',
        optional: false
      },
      {
        name: 'client_secret',
        hint: 'The application secret that you created in the app registration'\
          ' portal for your app.<br/>To get your client secret, follow the ' \
          "instructions <a href='https://docs.microsoft.com/en-us/advertising/"\
          "guides/authentication-oauth-live-connect?view=bingads-13' "\
          "target='_blank'>here</a>.",
        optional: false,
        control_type: 'password'
      },
      {
        name: 'developer_token',
        optional: false,
        control_type: 'password',
        hint: "Click <a href='https://docs.microsoft.com/en-us/advertising/' " \
          "guides/get-started?view=bingads-13#get-developer-token' " \
          "target='_blank'>here</a> to generate developer token."
      },
      {
        name: 'account_id',
        optional: false,
        hint: "Click <a href='https://docs.microsoft.com/en-us/advertising/' " \
          "guides/get-started?view=bingads-13#get-ids' " \
          "target='_blank'>here</a> and follow the steps to get account ID."
      },
      {
        name: 'environment', label: 'Environment',
        optional: false, control_type: 'select',
        pick_list: [%w[Production api], %w[Sandbox api.sandbox]]
      }
    ],
    authorization: {
      type: 'oauth2',

      authorization_url: lambda do |connection|
        'https://login.live.com/oauth20_authorize.srf?' \
        "client_id=#{connection['client_id']}&scope=bingads.manage" \
        '&response_type=code&redirect_uri=https://www.workato.com/oauth/callback'
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        post('https://login.live.com/oauth20_token.srf').
          payload(client_id: connection['client_id'],
                  client_secret: connection['client_secret'],
                  grant_type: 'authorization_code',
                  code: auth_code,
                  scope: 'bingads.manage',
                  redirect_uri: redirect_uri).
          headers(Accept: 'application/json').
          request_format_www_form_urlencoded
      end,
      refresh: lambda do |connection, refresh_token|
        post('https://login.live.com/oauth20_token.srf').
          payload(client_id: connection['client_id'],
                  client_secret: connection['client_secret'],
                  scope: 'bingads.manage',
                  grant_type: 'refresh_token',
                  refresh_token: refresh_token).
          headers(Accept: 'application/json').
          request_format_www_form_urlencoded
      end,

      refresh_on: [401, 500, /AuthenticationTokenExpired/,
                   /'AuthenticationTokenExpired'/,
                   /undefined method `with_indifferent_access' for/,
                   /'undefined method `with_indifferent_access' for '/,
                   /\<ErrorCode\>AuthenticationTokenExpired/,
                   /'Authentication token expired. Please renew it or ' \
                   'obtain a new token'/,
                   /Authentication token expired\. Please renew it or obtain' \
                   ' a new token/],

      apply: lambda do |_connection, access_token|
        headers('Authorization': "Bearer #{access_token}",
                'Content-Type': 'text/xml')

        payload do |current_payload|
          current_payload['s:Header'][0]&.[]=(
            'AuthenticationToken',
            [
              {
                '@i:nil' => 'false',
                "content!": access_token
              }
            ]
          )
        end
        format_xml('s:Envelope',
                   '@xmlns:s' => 'http://schemas.xmlsoap.org/soap/envelope/',
                   '@xmlns:i' => 'http://www.w3.org/2001/XMLSchema-instance',
                   strip_response_namespaces: true)
      end
    },
    base_uri: lambda do |connection|
      "https://reporting.#{connection['environment']}.bingads.microsoft.com"
    end
  },

  methods: {
    parse_xml_to_hash: lambda do |xml_obj|
      xml_obj['xml']&.
        reject { |key, _value| key[/^@/] }&.
        inject({}) do |hash, (key, value)|
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
        else
          value
        end
      end&.presence
    end,
    build_xml_report_columns: lambda do |input|
      columns = input['columns']&.split(',')&.map do |column|
        { 'content!' => column }
      end
      case input['report_request_type']
      when 'AdPerformanceReportRequest'
        { '@i:nil': 'false',
          'AdPerformanceReportColumn' => columns }
      when 'AudiencePerformanceReportRequest'
        { '@i:nil': 'false',
          'AdPerformanceReportColumn' => columns }
      when 'KeywordPerformanceReportRequest'
        { '@i:nil': 'false',
          'KeywordPerformanceReportColumn' => columns }
      when 'AgeGenderAudienceReportRequest'
        { '@i:nil': 'false',
          'AgeGenderAudienceReportColumn' => columns }
      end
    end,
    build_account_ids_xml: lambda do |input|
      account_ids = input&.dig('scope', 'account_ids')&.split(',')&.
        map do |column|
          { 'content!' => column }
        end
      { '@i:nil': 'false',
        '@xmlns:a1': 'http://schemas.microsoft.com/2003/10/Serialization/Arrays',
        'a1:long' => account_ids }
    end,
    build_ad_performancereport_request: lambda do |input|
      {
        '@i:nil': 'false',
        "@i:type": input['report_request_type'],
        'ExcludeColumnHeaders': [{
          '@i:nil': 'false',
          "content!": input['exclude_column_header'].presence || false
        }],
        'ExcludeReportFooter': [{
          '@i:nil': 'false',
          "content!": input['exclude_report_footer'].presence || false
        }],
        'ExcludeReportHeader': [{
          '@i:nil': 'false',
          "content!": input['exclude_report_header'].presence || false
        }],
        'Format': [{
          '@i:nil': 'false',
          "content!": input['format'].presence || 'Csv'
        }],
        'ReportName': [{
          '@i:nil': 'false',
          "content!": input['report_name'].presence ||
            "#{input['report_request_type']}-#{now.to_time.iso8601}"
        }],
        'ReturnOnlyCompleteData': [{
          '@i:nil': 'false',
          "content!": input['return_only_complete_data'].presence || false
        }],
        'Aggregation': [{
          "content!": input['aggregation'].presence || 'Summary'
        }],
        'Columns': [call('build_xml_report_columns', input)],
        'Scope': [{
          '@i:nil': 'false',
          'AccountIds': [call('build_account_ids_xml', input)]
        }],
        'Time': [
          if input.dig('time', 'predefined_time').present?
            { '@i:nil': 'false',
              'PredefinedTime': [{
                'content!': input.dig('time', 'predefined_time')
              }],
              'ReportTimeZone': [{
                'content!':
                input.
                  dig('time', 'report_timezone') || 'PacificTimeUSCanadaTijuana'
              }] }
          else
            start_time = input.dig('time', 'from')
            end_time = input.dig('time', 'to')
            { '@i:nil': 'false',
              'CustomDateRangeEnd': [{
                '@i:nil': 'false',
                'Day': [{ "content!": end_time&.to_time&.strftime('%d') }],
                'Month': [{ "content!": end_time&.to_time&.strftime('%m') }],
                'Year': [{  "content!": end_time&.to_time&.strftime('%Y') }]
              }],
              'CustomDateRangeStart': [{
                '@i:nil': 'false',
                'Day': [{ "content!": start_time&.to_time&.strftime('%d') }],
                'Month': [{ "content!": start_time&.to_time&.strftime('%m') }],
                'Year': [{  "content!": start_time&.to_time&.strftime('%Y') }]
              }],
              'ReportTimeZone': [{
                'content!':
                input.
                  dig('time', 'report_timezone') || 'PacificTimeUSCanadaTijuana'
              }] }
          end
        ]
      }
    end,
    build_audience_performance_report_request: lambda do |input|
      {
        '@i:nil': 'false',
        "@i:type": input['report_request_type'],
        'ExcludeColumnHeaders': [{
          '@i:nil': 'false',
          "content!": input['exclude_column_header'].presence || false
        }],
        'ExcludeReportFooter': [{
          '@i:nil': 'false',
          "content!": input['exclude_report_footer'].presence || false
        }],
        'ExcludeReportHeader': [{
          '@i:nil': 'false',
          "content!": input['exclude_report_header'].presence || false
        }],
        'Format': [{
          '@i:nil': 'false',
          "content!": input['format'].presence || 'Csv'
        }],
        'ReportName': [{
          '@i:nil': 'false',
          "content!": input['report_name'].presence ||
            "{input['report_request_type']}-#{now.to_time.iso8601}"
        }],
        'ReturnOnlyCompleteData': [{
          '@i:nil': 'false',
          "content!": input['return_only_complete_data'].presence || false
        }],
        'Aggregation': [{
          "content!": input['aggregation'].presence || 'Summary'
        }],
        'Columns': [call('build_xml_report_columns', input)],
        'Scope': [{
          '@i:nil': 'false',
          'AccountIds': [call('build_account_ids_xml', input)]
        }],
        'Time': [
          if input.dig('time', 'predefined_time').present?
            { '@i:nil': 'false',
              'PredefinedTime': [{
                'content!': input.dig('time', 'predefined_time')
              }],
              'ReportTimeZone': [{
                'content!':
                input.
                  dig('time', 'report_timezone') || 'PacificTimeUSCanadaTijuana'
              }] }
          else
            start_time = input.dig('time', 'from')
            end_time = input.dig('time', 'to')
            { '@i:nil': 'false',
              'CustomDateRangeEnd': [{
                '@i:nil': 'false',
                'Day': [{ "content!": end_time&.to_time&.strftime('%d') }],
                'Month': [{ "content!": end_time&.to_time&.strftime('%m') }],
                'Year': [{  "content!": end_time&.to_time&.strftime('%Y') }]
              }],
              'CustomDateRangeStart': [{
                '@i:nil': 'false',
                'Day': [{ "content!": start_time&.to_time&.strftime('%d') }],
                'Month': [{ "content!": start_time&.to_time&.strftime('%m') }],
                'Year': [{  "content!": start_time&.to_time&.strftime('%Y') }]
              }],
              'ReportTimeZone': [{
                'content!':
                input.
                  dig('time', 'report_timezone') || 'PacificTimeUSCanadaTijuana'
              }] }
          end
        ]
      }
    end,
    build_keyword_performance_report_request: lambda do |input|
      {
        '@i:nil': 'false',
        "@i:type": input['report_request_type'],
        'ExcludeColumnHeaders': [{
          '@i:nil': 'false',
          "content!": input['exclude_column_header'].presence || false
        }],
        'ExcludeReportFooter': [{
          '@i:nil': 'false',
          "content!": input['exclude_report_footer'].presence || false
        }],
        'ExcludeReportHeader': [{
          '@i:nil': 'false',
          "content!": input['exclude_report_header'].presence || false
        }],
        'Format': [{
          '@i:nil': 'false',
          "content!": input['format'].presence || 'Csv'
        }],
        'ReportName': [{
          '@i:nil': 'false',
          "content!": input['report_name'].presence ||
            "#{input['report_request_type']}-#{now.to_time.iso8601}"
        }],
        'ReturnOnlyCompleteData': [{
          '@i:nil': 'false',
          "content!": input['return_only_complete_data'].presence || false
        }],
        'Aggregation': [{
          "content!": input['aggregation'].presence || 'Summary'
        }],
        'Columns': [call('build_xml_report_columns', input)],
        'Scope': [{
          '@i:nil': 'false',
          'AccountIds': [call('build_account_ids_xml', input)]
        }],
        'Time': [
          if input.dig('time', 'predefined_time').present?
            { '@i:nil': 'false',
              'PredefinedTime': [{
                'content!': input.dig('time', 'predefined_time')
              }],
              'ReportTimeZone': [{
                'content!':
                input.
                  dig('time', 'report_timezone') || 'PacificTimeUSCanadaTijuana'
              }] }
          else
            start_time = input.dig('time', 'from')
            end_time = input.dig('time', 'to')
            { '@i:nil': 'false',
              'CustomDateRangeEnd': [{
                '@i:nil': 'false',
                'Day': [{ "content!": end_time&.to_time&.strftime('%d') }],
                'Month': [{ "content!": end_time&.to_time&.strftime('%m') }],
                'Year': [{  "content!": end_time&.to_time&.strftime('%Y') }]
              }],
              'CustomDateRangeStart': [{
                '@i:nil': 'false',
                'Day': [{ "content!": start_time&.to_time&.strftime('%d') }],
                'Month': [{ "content!": start_time&.to_time&.strftime('%m') }],
                'Year': [{  "content!": start_time&.to_time&.strftime('%Y') }]
              }],
              'ReportTimeZone': [{
                'content!':
                input.
                  dig('time', 'report_timezone') || 'PacificTimeUSCanadaTijuana'
              }] }
          end
        ]
      }
    end,
    build_age_gender_audience_report_request: lambda do |input|
      {
        '@i:nil': 'false',
        "@i:type": input['report_request_type'],
        'ExcludeColumnHeaders': [{
          '@i:nil': 'false',
          "content!": input['exclude_column_header'].presence || false
        }],
        'ExcludeReportFooter': [{
          '@i:nil': 'false',
          "content!": input['exclude_report_footer'].presence || false
        }],
        'ExcludeReportHeader': [{
          '@i:nil': 'false',
          "content!": input['exclude_report_header'].presence || false
        }],
        'Format': [{
          '@i:nil': 'false',
          "content!": input['format'].presence || 'Csv'
        }],
        'ReportName': [{
          '@i:nil': 'false',
          "content!": input['report_name'].presence ||
            "#{input['report_request_type']}-#{now.to_time.iso8601}"
        }],
        'ReturnOnlyCompleteData': [{
          '@i:nil': 'false',
          "content!": input['return_only_complete_data'].presence || false
        }],
        'Aggregation': [{
          "content!": input['aggregation'].presence || 'Summary'
        }],
        'Columns': [call('build_xml_report_columns', input)],
        'Scope': [{
          '@i:nil': 'false',
          'AccountIds': [call('build_account_ids_xml', input)]
        }],
        'Time': [
          if input.dig('time', 'predefined_time').present?
            { '@i:nil': 'false',
              'PredefinedTime': [{
                'content!': input.dig('time', 'predefined_time')
              }],
              'ReportTimeZone': [{
                'content!':
                input.
                  dig('time', 'report_timezone') || 'PacificTimeUSCanadaTijuana'
              }] }
          else
            start_time = input.dig('time', 'from')
            end_time = input.dig('time', 'to')
            { '@i:nil': 'false',
              'CustomDateRangeEnd': [{
                '@i:nil': 'false',
                'Day': [{ "content!": end_time&.to_time&.strftime('%d') }],
                'Month': [{ "content!": end_time&.to_time&.strftime('%m') }],
                'Year': [{  "content!": end_time&.to_time&.strftime('%Y') }]
              }],
              'CustomDateRangeStart': [{
                '@i:nil': 'false',
                'Day': [{ "content!": start_time&.to_time&.strftime('%d') }],
                'Month': [{ "content!": start_time&.to_time&.strftime('%m') }],
                'Year': [{  "content!": start_time&.to_time&.strftime('%Y') }]
              }],
              'ReportTimeZone': [{
                'content!':
                input.
                  dig('time', 'report_timezone') || 'PacificTimeUSCanadaTijuana'
              }] }
          end
        ]
      }
    end,
    build_report_request: lambda do |input|
      case input['report_request_type']
      when 'AdPerformanceReportRequest'
        call('build_ad_performancereport_request', input)
      when 'AudiencePerformanceReportRequest'
        call('build_audience_performance_report_request', input)
      when 'KeywordPerformanceReportRequest'
        call('build_keyword_performance_report_request', input)
      when 'AgeGenderAudienceReportRequest'
        call('build_age_gender_audience_report_request', input)
      end
    end
  },

  object_definitions: {
    account_info: {
      fields: lambda do
        [
          { name: 'Id', label: 'Account ID', type: 'integer' },
          { name: 'Name' },
          { name: 'Number' },
          { name: 'AccountLifeCycleStatus', control_type: 'select',
            pick_list: 'account_cifecycle_statuses',
            toggle_hint: 'Select account lifecycle status',
            toggle_field: {
              name: 'AccountLifeCycleStatus',
              type: 'string',
              control_type: 'text',
              label: 'Account lifecycle status',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: Draft, Active, Inactive, Pause,' \
              ' Pending, Suspended'
            } },
          { name: 'PauseReason',
            label: 'Pause reason',
            control_type: 'select',
            pick_list: 'pause_reasons',
            toggle_hint: 'Select pause reason',
            toggle_field: {
              name: 'PauseReason',
              type: 'integer',
              label: 'Pause reason code',
              toggle_hint: 'Use custom value',
              hint: 'e.g. 1'
            } }
        ]
      end
    },
    fitler_fields: {
      fields: lambda do |_connection, config_fileds|
        case config_fileds['report_request_type']
        when 'KeywordPerformanceReportRequest'
          [
            { name: 'AccountStatus' },
            { name: 'AdDistribution' },
            { name: 'AdGroupStatus' },
            { name: 'AdRelevance',
              hint: 'Provide comma separated list of values' },
            { name: 'AdType' },
            { name: 'BidMatchType' },
            { name: 'BidStrategyType' },
            { name: 'CampaignStatus' },
            { name: 'DeliveredMatchType' },
            { name: 'DeviceType' },
            { name: 'ExpectedCtr',
              hint: 'Provide comma separated list of values' },
            { name: 'KeywordStatus' },
            { name: 'Keywords',
              hint: 'Provide comma separated list of values' },
            { name: 'LandingPageExperience',
              hint: 'Provide comma separated list of values' },
            { name: 'Language' },
            { name: 'QualityScore',
              hint: 'Provide comma separated list of values' }
          ]
        when 'AdPerformanceReportRequest'
          [
            { name: 'AccountStatus' },
            { name: 'AdDistribution' },
            { name: 'AdGroupStatus' },
            { name: 'AdStatus' },
            { name: 'AdType' },
            { name: 'CampaignStatus' },
            { name: 'DeviceType' },
            { name: 'Language' }
          ]
        when 'AudiencePerformanceReportRequest'
          [
            { name: 'AccountStatus' },
            { name: 'AdGroupStatus' },
            { name: 'CampaignStatus' }
          ]
        when 'AgeGenderAudienceReportRequest'
          [
            { name: 'AccountStatus' },
            { name: 'AdDistribution' },
            { name: 'AdGroupStatus' },
            { name: 'CampaignStatus' },
            { name: 'Language' }
          ]
        end
      end
    }
  },
  test: lambda do |connection|
    post("https://clientcenter.#{connection['environment']}." \
         'bingads.microsoft.com' \
         '/Api/CustomerManagement/v13/CustomerManagementService.svc').
      payload(
        's:Header': [{
          '@xmlns': 'https://bingads.microsoft.com/Customer/v13',
          'Action': [{
            '@mustUnderstand': '1',
            "content!": 'GetAccountsInfo'
          }],
          'AuthenticationToken': [{
            '@i:nil': 'false',
            "content!": []
          }],
          'DeveloperToken': [{
            '@i:nil': 'false',
            "content!": connection['developer_token']
          }]
        }],
        's:Body': [{
          'GetAccountsInfoRequest': [{
            '@xmlns': 'https://bingads.microsoft.com/Customer/v13',
            'AccountId': [{
              '@i:nil': 'false',
              "content!": connection['account_id']
            }]
          }]
        }]
      ).
      headers('Content-Type': 'text/xml',
              SOAPAction: 'GetAccountsInfo').
      format_xml('s:Envelope',
                 '@xmlns:s' => 'http://schemas.xmlsoap.org/soap/envelope/',
                 '@xmlns:i' => 'http://www.w3.org/2001/XMLSchema-instance',
                 strip_response_namespaces: true).
      after_error_response(/.*/) do |_code, body, _header, _message|
        body
      end
  end,
  actions: {
    get_accounts_by_customer_id: {
      title: 'Get customer accounts',
      description: "Get customer <span class='provider'>accounts</span> in" \
      ' Microsoft Advertising',
      help: {
        body: 'Retrieves information about accounts under or managed by a ' \
        'customer ID in Microsoft Advertising, for example the name and ' \
        'identifier of the account.<br/>This action uses Get Account Info ' \
        'API. Learn more by clicking the link below.',
        learn_more_text: 'Get Accounts Info API',
        learn_more_url: 'https://docs.microsoft.com/en-us/advertising/' \
        'customer-management-service/getaccountsinfo?view=bingads-13'
      },
      input_fields: lambda { |_object_definitions|
        [
          { name: 'customer_id', optional: false,
            hint: 'Provide customer ID.' },
          { name: 'only_parent_accounts', control_type: 'checkbox',
            type: :boolean,
            sticky: true,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            hint: 'Only include accounts directly created by ' \
              'customer. Default value is false.',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'only_parent_accounts',
              label: 'Only parent accounts',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter custom value',
              hint: 'Allowed values are: true or false'
            } }
        ]
      },
      execute: lambda { |connection, input|
        response =
          post("https://clientcenter.#{connection['environment']}.bingads" \
                '.microsoft.com' \
               '/Api/CustomerManagement/v13/CustomerManagementService.svc').
          payload(
            's:Header': [{
              '@xmlns': 'https://bingads.microsoft.com/Customer/v13',
              'Action': [{
                '@mustUnderstand': '1',
                "content!": 'GetAccountsInfo'
              }],
              'AuthenticationToken': [{
                '@i:nil': 'false',
                "content!": []
              }],
              'DeveloperToken': [{
                '@i:nil': 'false',
                "content!": connection['developer_token']
              }]
            }],
            's:Body': [{
              'GetAccountsInfoRequest': [{
                '@xmlns': 'https://bingads.microsoft.com/Customer/v13',
                'CustomerId': [{
                  '@i:nil': 'false',
                  "content!": input['customer_id']
                }],
                'OnlyParentAccounts': [{
                  '@i:nil': 'false',
                  "content!": input['only_parent_accounts'].presence || false
                }]
              }]
            }]
          ).
          headers(SOAPAction: 'GetAccountsInfo').
          after_error_response(/.*/) do |_code, body, _header, _message|
            error(body)
          end
        response_hash = call('parse_xml_to_hash',
                             'xml' => response,
                             'array_fields' => ['AccountInfo'])
        if (message = response_hash&.
        dig('Envelope', 'Body', 'Fault', 'detail',
            'AdApiFaultDetail', 'Errors', 'AdApiError', 'Message')).present?
          error(message)
        end
        accounts = response_hash&.
                   dig('Envelope', 'Body', 'GetAccountsInfoResponse',
                       'AccountsInfo', 'AccountInfo') || []
        { accounts: accounts }
      },
      output_fields: lambda { |object_definitions|
        [{ name: 'accounts', type: :array, of: :object,
           properties: object_definitions['account_info'] }]
      },
      sample_output: lambda { |_connection, _input|
        {
          accounts: [
            {
              'Id': '2980157',
              'Name': 'Student Loan Refinancing',
              'Number': 'X000UMS8',
              'AccountLifeCycleStatus': 'Active',
              'PauseReason': ''
            }
          ]
        }
      }
    },
    submit_report_request: {
      title: 'Submit a report request',
      subtitle: 'Submit a request for a report to Microsoft Advertising',
      description: "Submit <span class='provider'>report request</span> in " \
      ' Microsoft Advertising',
      help: {
        body: 'This action specifies the details for a report from Microsoft' \
        ' Advertising. There are many fields for customizing the report, but' \
        ' specifying the report request type is the most important. Each' \
        ' report request type has columns that can be chosen to be included' \
        ' in the report; some are unique to a report type, some are not.' \
        ' Beyond that, a scope must be specified by using account IDs, ad' \
        ' group IDs or campaign IDs. Finally, a time frame for the ' \
        'information to be retrieved into the report would also need to be' \
        ' specified.',
        learn_more_text: 'Submit Report Request API',
        learn_more_url: 'https://docs.microsoft.com/en-us/advertising/' \
        'reporting-service/submitgeneratereport?view=bingads-13'
      },
      input_fields: lambda { |_object_definitions|
        [
          { name: 'customer_id',
            optional: false,
            hint: 'The identifier of the customer that contains and owns' \
            ' the account. If you manage an account of another customer, you' \
            ' should use that customer ID instead of your own customer ID.' },
          { name: 'report_request_type', control_type: 'select',
            optional: false, pick_list: 'report_types',
            toggle_hint: 'Select report',
            hint: 'The report type to request for.',
            toggle_field: {
              name: 'report_request_type',
              label: 'Report type',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: AdPerformanceReportRequest, ' \
              'AgeGenderAudienceReportRequest, ' \
              'AudiencePerformanceReportRequest, ' \
              'KeywordPerformanceReportRequest'
            } },
          { name: 'aggregation',
            control_type: 'select',
            optional: false,
            pick_list: 'aggregation_list',
            toggle_hint: 'Select aggregation',
            hint: 'Determines how the data should be aggregated according to ' \
            'time frames. The default aggregation is Summary.<br/>It is ' \
            'important to note that if you do not include TimePeriod in the ' \
            'list of<b>Columns</b>, the aggregation you chose will be ignored '\
            'and Summary aggregation will be used regardless',
            toggle_field: {
              name: 'aggregation',
              label: 'Aggregation',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: Summary, Hourly, Daily, Weekly, ' \
              'Monthly, Yearly, HourOfDay, DayOfWeek, WeeklyStartingMonday.' \
              ' Default value is Summary'
            } },
          { name: 'columns', control_type: 'multiselect', delimiter: ',',
            optional: false, pick_list: 'column_list',
            pick_list_params: { report_request_type: 'report_request_type' },
            toggle_hint: 'Select from options',
            hint: 'The list of attributes to include in the report',
            toggle_field: {
              name: 'columns',
              label: 'Columns',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter custom value',
              hint: 'Enter column names separated by comma. the order of the' \
              ' columns should be maintained as per doc, otherwise, it gives' \
              ' Internal server error. click ' \
              "<a href='https://docs.microsoft.com/en-us/advertising/guides/" \
              "report-types?view=bingads-13' target='_blank'>here</a> " \
              'more details.'
            } },
          { name: 'report_name', sticky: true,
            hint: 'The name of the report. The name is' \
            ' included in the report header' \
            ' If you do not specify a report name, the system generates a ' \
            'name in the form, <b>ReportType-ReportDateTime</b>. The' \
            ' maximum length of the report name is 200. ' },
          { name: 'format',
            sticky: true,
            control_type: 'select', pick_list: 'format_list',
            label: 'Report format',
            toggle_hint: 'Select from options',
            hint: 'The format of the report data. The report will be ' \
            'downloaded as a zip file.The default value is CSV. ',
            toggle_field: {
              name: 'format',
              label: 'Report format',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'The default value is CSV. Allowed values are: Xml,' \
              ' Csv, Tsv'
            } },
          { name: 'exclude_column_header',
            sticky: true,
            control_type: 'checkbox',
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            hint: 'Determines whether or not the downloaded report should' \
            ' contain header descriptions for each column.' \
            'Set this property true if you want the report column headers' \
            ' excluded from the downloaded report. The default value is false.',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'exclude_column_header',
              label: 'Exclude column header',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Set this property true if you want the report column ' \
              'headers excluded from the downloaded report. The default ' \
              'value is false. Allowed values are: true or false'
            } },
          { name: 'exclude_report_header',
            sticky: true,
            control_type: 'checkbox',
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            hint: 'Determines whether or not the downloaded report should' \
            ' contain header metadata such as report name, date range,' \
            ' and aggregation. Set this property true if you want the report' \
            ' header metadata excluded from the downloaded report. ' \
            'The default value is false.  ',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'exclude_report_header',
              label: 'Exclude report header',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Set this property true if you want the report header ' \
              'metadata excluded from the downloaded report. The default' \
              ' value is false. Allowed values are: true or false'
            } },
          { name: 'exclude_report_footer',
            sticky: true,
            control_type: 'checkbox',
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            hint: 'Exclude the row containing Microsoft trademark',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'exclude_report_footer',
              label: 'Exclude report footer',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter custom value',
              hint: 'Allowed values are: true or false'
            } },
          { name: 'return_only_complete_data',
            sticky: true,
            control_type: 'checkbox',
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            hint: 'Determines whether or not the service must ensure that' \
            ' all the data has been processed and is available. Defult value' \
            ' is true.',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'return_only_complete_data',
              label: 'Return complete data only',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Determines whether or not the service must ensure that' \
              ' all the data has been processed and is available. Allowed' \
              ' values are: true or false'
            } },
          { name: 'scope', sticky: true, type: :object,
            hint: 'The entity scope of the report',
            properties: [
              { name: 'account_ids', sticky: true,
                hint: 'The list of account IDs whereby data'\
              ' is to be retrieved and included in the report. Separate each' \
              ' account ID with a comma separator. A list of up to 1,000 ' \
              'account identifiers to include in the report. ' },
              { name: 'ad_groups', type: :array, of: :object, properties: [
                { name: 'AccountId', type: 'integer' },
                { name: 'AdGroupId', type: 'integer' },
                { name: 'CampaignId', type: 'integer' }
              ], hint: 'The list of ad groups whereby data is to be retrieved' \
              ' and included in the report. A list of up to 300 ad groups to ' \
              'include in the report.' },
              { name: 'campaigns', type: :array, of: :object, properties: [
                { name: 'AccountId', type: 'integer' },
                { name: 'CampaignId', type: 'integer' }
              ], hint: 'The list of ad groups whereby data is to be retrieved' \
              ' and included in the report. A list of up to 300 ad groups to ' \
              'include in the report.' }
            ] },
          { name: 'time',
            type: 'object',
            label: 'Report time period',
            optional: false,
            properties: [
              { name: 'from', type: 'date',
                sticky: true,
                hint: 'From is required when you provide To date. Use From' \
                ' and To or Predefined time, but not both' },
              { name: 'to', type: 'date',
                sticky: true,
                hint: 'To is required when you provide From date. Use From' \
                ' and To or Predefined time, but not both' },
              { name: 'predefined_time',
                sticky: true,
                label: 'Predefined time',
                control_type: 'select',
                pick_list: 'time_list',
                toggle_hint: 'Select time',
                toggle_field: {
                  name: 'predefined_time',
                  type: 'string',
                  control_type: 'text',
                  label: 'Predefine time',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: Today, Yesterday, LastSevenDays,' \
                  'ThisWeek, LastWeek, Last14Days, Last30Days, LastFourWeeks,' \
                  'ThisMonth, LastMonth, LastThreeMonths, LastSixMonths,' \
                  ' ThisYear, LastYear, ThisWeekStartingMonday, ' \
                  'LastWeekStartingMonday, LastFourWeeksStartingMonday'
                },
                hint: 'Use Predefined time or From and To, but not both' },
              { name: 'report_timezone',
                sticky: true,
                control_type: 'select',
                pick_list: 'timezone',
                toggle_hint: 'Select from options',
                hint: 'Time zone to apply to the date range.',
                toggle_field: {
                  name: 'report_timezone',
                  label: 'Report timezone',
                  type: 'string',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: "Click <a href='https://docs.microsoft.com/en-us/" \
                  'advertising/reporting-service/reporttimezone?view=bingads' \
                  "-13 target='_blank'>here</a> to find the report timezone " \
                  'values. Use enumeration value field. the default time zone' \
                  '  is <b>PacificTimeUSCanadaTijuana</b>'
                } }
            ],
            hint: 'Choose the predefined date ranges for data to be included' \
            ' in the report.<br/>For a list of the time periods that you can ' \
            "specify for each aggregation type, see <a href='https://docs." \
            'microsoft.com/en-us/advertising/guides/reports?view=bingads-' \
            "13#aggregation-time' target='_blank'>Aggregation and Time.</a>" }
        ]
      },
      execute: lambda { |connection, input|
        report_request = call('build_report_request', input)
        response =
          post('/Api/Advertiser/Reporting/v13/ReportingService.svc').
          payload(
            's:Header': [{
              '@xmlns': 'https://bingads.microsoft.com/Reporting/v13',
              'Action': [{
                '@mustUnderstand': '1',
                "content!": 'SubmitGenerateReport'
              }],
              'AuthenticationToken': [{
                '@i:nil': 'false',
                "content!": []
              }],
              'CustomerAccountId': [{
                '@i:nil': 'false',
                "content!": connection['account_id']
              }],
              'CustomerId': [{
                '@i:nil': 'false',
                "content!": input['customer_id']
              }],
              'DeveloperToken': [{
                '@i:nil': 'false',
                "content!": connection['developer_token']
              }]
            }],
            's:Body': [{
              'SubmitGenerateReportRequest': [{
                '@xmlns': 'https://bingads.microsoft.com/Reporting/v13',
                'ReportRequest': [
                  report_request
                ]
              }]
            }]
          ).
          headers(SOAPAction: 'SubmitGenerateReport').
          after_error_response(/.*/) do |code, body, _header, message|
            error("#{code}: #{body} - #{message}")
          end&.dig('Envelope', 0, 'Body', 0)
        call('parse_xml_to_hash',
             'xml' => response&.dig('SubmitGenerateReportResponse', 0),
             'array_fields' => []) || {}
      },
      output_fields: lambda { |_object_definitions|
        [{ name: 'ReportRequestId' }]
      },
      sample_output: lambda { |_connection, _input|
        { ReportRequestId: '68859941401' }
      }
    },
    get_status_of_report: {
      title: 'Get status of a report request',
      description: "Get the status of <span class='provider'>report request" \
      '</span> in Microsoft Advertising',
      help: {
        body: 'Poll Microsoft Advertising for a successful report ' \
        'generation.<br/>This action uses Poll Report API. ' \
        'Learn more by clicking the link below.',
        learn_more_text: 'Poll Report API',
        learn_more_url: 'https://docs.microsoft.com/en-us/advertising/' \
        'reporting-service/pollgeneratereport?view=bingads-13'
      },
      input_fields: lambda { |_object_definitions|
        [
          { name: 'customer_id', optional: false,
            hint: 'Enter your customer ID.' },
          { name: 'report_request_id', optional: false,
            hint: 'Enter the report request ID obtained from the Submit ' \
            'report request action.' }
        ]
      },
      execute: lambda { |connection, input|
        response =
          post('/Api/Advertiser/Reporting/v13/ReportingService.svc').
          payload(
            's:Header': [{
              '@xmlns': 'https://bingads.microsoft.com/Reporting/v13',
              'Action': [{
                '@mustUnderstand': '1',
                "content!": 'PollGenerateReport'
              }],
              'AuthenticationToken': [{
                '@i:nil': 'false',
                "content!": connection['oauth_access_token']
              }],
              'CustomerAccountId': [{
                '@i:nil': 'false',
                "content!": connection['account_id']
              }],
              'CustomerId': [{
                '@i:nil': 'false',
                "content!": input['customer_id']
              }],
              'DeveloperToken': [{
                '@i:nil': 'false',
                "content!": connection['developer_token']
              }]
            }],
            's:Body': [{
              'PollGenerateReportRequest': [{
                '@xmlns': 'https://bingads.microsoft.com/Reporting/v13',
                'ReportRequestId': [{
                  '@i:nil': 'false',
                  "content!": input['report_request_id']
                }]
              }]
            }]
          ).
          headers(SOAPAction: 'PollGenerateReport').
          after_error_response(/.*/) do |_code, body, _header, _message|
            error(body)
          end
        result = call('parse_xml_to_hash',
                      'xml' => response,
                      'array_fields' => []) || {}
        result&.dig('Envelope', 'Body', 'PollGenerateReportResponse',
                    'ReportRequestStatus')
      },
      output_fields: lambda { |_object_definitions|
        [
          { name: 'ReportDownloadUrl' },
          { name: 'status' }
        ]
      },
      sample_output: lambda { |_connection, _input|
        { 'ReportDownloadUrl': '', 'status': 'Success' }
      }
    }
  },

  triggers: {
  },
  pick_lists: {
    pause_reasons: lambda do
      [
        ['The user paused the account', 1],
        ['The billing service paused the account', 2],
        ['The user and billing service paused the account', 4]
      ]
    end,
    account_cifecycle_statuses: lambda do
      [
        %w[Draft Draft], %w[Active Active], %w[Inactive Inactive],
        %w[Pause Pause], %w[Pending Pending], %w[Suspended Suspended]
      ]
    end,
    report_types: lambda do
      [
        %w[Ad\ performance\ report AdPerformanceReportRequest],
        %w[Age\ gender\ audience\ report AgeGenderAudienceReportRequest],
        %w[Audience\ performance\ report AudiencePerformanceReportRequest],
        %w[Keyword\ performance\ report KeywordPerformanceReportRequest]
      ]
    end,
    column_list: lambda do |_connection, report_request_type:|
      {
        'AdPerformanceReportRequest' => [
          %w[AccountName AccountName],
          %w[CampaignName CampaignName],
          %w[CampaignId CampaignId],
          %w[AdGroupName AdGroupName],
          %w[AdGroupId AdGroupId],
          %w[AdId AdId],
          %w[AdStatus AdStatus],
          %w[AdType AdType],
          %w[CampaignType CampaignType],
          %w[DeviceOS DeviceOS],
          %w[AdDistribution AdDistribution],
          %w[Impressions Impressions],
          %w[Clicks Clicks],
          %w[Spend Spend],
          %w[Ctr Ctr],
          %w[AverageCpc AverageCpc],
          %w[AveragePosition AveragePosition],
          %w[Conversions Conversions],
          %w[ConversionRate ConversionRate],
          %w[CostPerAssist CostPerAssist],
          %w[AllConversions AllConversions],
          %w[TimePeriod TimePeriod]
        ],
        'AgeGenderAudienceReportRequest' => [
          %w[AccountName AccountName],
          %w[CampaignName CampaignName],
          %w[CampaignId CampaignId],
          %w[AdGroupName AdGroupName],
          %w[AdGroupId AdGroupId],
          %w[AgeGroup AgeGroup],
          %w[Gender Gender],
          %w[Impressions Impressions],
          %w[Clicks Clicks],
          %w[Spend Spend],
          %w[Conversions Conversions],
          %w[AllConversions AllConversions],
          %w[TimePeriod TimePeriod]
        ],
        'AudiencePerformanceReportRequest' => [
          %w[AccountName AccountName],
          %w[CampaignName CampaignName],
          %w[CampaignId CampaignId],
          %w[AdGroupName AdGroupName],
          %w[AdGroupId AdGroupId],
          %w[AudienceName AudienceName],
          %w[AudienceId AudienceId],
          %w[TargetingSetting TargetingSetting],
          %w[AudienceType AudienceType],
          %w[Impressions Impressions],
          %w[Clicks Clicks],
          %w[Spend Spend],
          %w[Ctr Ctr],
          %w[AverageCpc AverageCpc],
          %w[AveragePosition AveragePosition],
          %w[CostPerConversion CostPerConversion],
          %w[Conversions Conversions],
          %w[ConversionRate ConversionRate],
          %w[AllConversions AllConversions],
          %w[TimePeriod TimePeriod]
        ],
        'KeywordPerformanceReportRequest' => [
          %w[AccountName AccountName],
          %w[CampaignName CampaignName],
          %w[CampaignId CampaignId],
          %w[AdGroupName AdGroupName],
          %w[AdGroupId AdGroupId],
          %w[AdId AdId],
          %w[Keyword Keyword],
          %w[KeywordId KeywordId],
          %w[AdDistribution AdDistribution],
          %w[Impressions Impressions],
          %w[Clicks Clicks],
          %w[Spend Spend],
          %w[Ctr Ctr],
          %w[AverageCpc AverageCpc],
          %w[AveragePosition AveragePosition],
          %w[Conversions Conversions],
          %w[ConversionRate ConversionRate],
          %w[CostPerAssist CostPerAssist],
          %w[AllConversions AllConversions],
          %w[TimePeriod TimePeriod]
        ]
      }[report_request_type]
    end,
    filter_list: lambda do |_connection, report_request_type:|
      {
        'AdPerformanceReportRequest' => [
          %w[AccountStatus AccountStatus],
          %w[AdDistribution AdDistribution],
          %w[AdGroupStatus AdGroupStatus],
          %w[AdStatus AdStatus],
          %w[AdType AdType],
          %w[CampaignStatus CampaignStatus],
          %w[DeviceType DeviceType],
          %w[Language Language]
        ],
        'AgeGenderAudienceReportRequest' => [
          %w[AccountStatus AccountStatus],
          %w[AdDistribution AdDistribution],
          %w[AdGroupStatus AdGroupStatus],
          %w[CampaignStatus CampaignStatus],
          %w[Language Language]
        ],
        'AudiencePerformanceReportRequest' => [
          %w[AccountStatus AccountStatus],
          %w[AdGroupStatus],
          %w[CampaignStatus]
        ],
        'KeywordPerformanceReportRequest' => [
          %w[AccountStatus AccountStatus],
          %w[AdDistribution AdDistribution],
          %w[AdGroupStatus AdGroupStatus],
          %w[AdRelevance AdRelevance],
          %w[AdType AdType],
          %w[BidMatchType BidMatchType],
          %w[BidStrategyType BidStrategyType],
          %w[CampaignStatus CampaignStatus],
          %w[DeliveredMatchType DeliveredMatchType],
          %w[DeviceType DeviceType],
          %w[ExpectedCtr ExpectedCtr],
          %w[Keywords Keywords],
          %w[KeywordStatus KeywordStatus],
          %w[LandingPageExperience LandingPageExperience],
          %w[Language Language],
          %w[QualityScore QualityScore]
        ]
      }[report_request_type]
    end,
    format_list: lambda do
      [
        %w[XML Xml],
        %w[CSV Csv],
        %w[TSV Tsv]
      ]
    end,
    aggregation_list: lambda do
      [
        %w[Summary Summary],
        %w[Hourly Hourly],
        %w[Daily Daily],
        %w[Weekly Weekly],
        %w[Monthly Monthly],
        %w[Yearly Yearly],
        %w[Hour\ of\ day HourOfDay],
        %w[Day\ of\ week DayOfWeek],
        %w[Weekly\ starting\ monday WeeklyStartingMonday]
      ]
    end,
    time_list: lambda do
      [
        %w[Today Today],
        %w[Yesterday Yesterday],
        %w[Last\ seven\ days LastSevenDays],
        %w[This\ week ThisWeek],
        %w[Last\ week LastWeek],
        %w[Last\ 14\ days Last14Days],
        %w[Last\ 30\ days Last30Days],
        %w[Last\ four\ weeks LastFourWeeks],
        %w[This\ month ThisMonth],
        %w[Last\ month LastMonth],
        %w[Last\ three\ months LastThreeMonths],
        %w[Last\ six\ months LastSixMonths],
        %w[This\ year ThisYear],
        %w[Last\ year LastYear],
        %w[This\ week\ starting\ monday ThisWeekStartingMonday],
        %w[Last\ week\ starting\ monday LastWeekStartingMonday],
        %w[LastFourWeeksStartingMonday LastFourWeeksStartingMonday]
      ]
    end,
    timezone: lambda do
      [
        %w[AbuDhabiMuscat AbuDhabiMuscat],
        %w[Adelaide Adelaide],
        %w[Alaska Alaska],
        %w[AlmatyNovosibirsk AlmatyNovosibirsk],
        %w[AmsterdamBerlinBernRomeStockholmVienna
           AmsterdamBerlinBernRomeStockholmVienna],
        %w[Arizona Arizona],
        %w[AstanaDhaka AstanaDhaka],
        %w[AthensIslandanbulMinsk AthensIslandanbulMinsk],
        %w[AtlanticTimeCanada AtlanticTimeCanada],
        %w[AucklandWellington AucklandWellington],
        %w[Azores Azores],
        %w[Baghdad Baghdad],
        %w[BakuTbilisiYerevan BakuTbilisiYerevan],
        %w[BangkokHanoiJakarta BangkokHanoiJakarta],
        %w[BeijingChongqingHongKongUrumqi BeijingChongqingHongKongUrumqi],
        %w[BelgradeBratislavaBudapestLjubljanaPrague
           BelgradeBratislavaBudapestLjubljanaPrague],
        %w[BogotaLimaQuito BogotaLimaQuito]
      ]
    end
  }
}
