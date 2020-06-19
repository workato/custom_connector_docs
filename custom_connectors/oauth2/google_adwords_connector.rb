{
  title: 'AdWords',

  connection: {
    fields: [
      {
        name: 'client_id',
        hint: 'You can find your client ID by logging in to your ' \
          "<a href='https://console.developers.google.com/' " \
          "target='_blank'>Google Developers Console</a> account. " \
          "After logging in, click on 'Credentials' to show your " \
          'OAuth 2.0 client IDs. <br> Alternatively, you can create your ' \
          "Oauth 2.0 credentials by clicking on 'Create credentials' => " \
          "'Oauth client ID'. <br> Please use <b>https://www.workato.com/" \
          'oauth/callback</b> for the redirect URI when registering your ' \
          'OAuth client. <br> More information about authentication ' \
          "can be found <a href='https://developers.google.com/identity/" \
          "protocols/OAuth2?hl=en_US' target='_blank'>here</a>.",
        optional: false
      },
      {
        name: 'client_secret',
        hint: 'You can find your client secret by logging in to your ' \
          "<a href='https://console.developers.google.com/' " \
          "target='_blank'>Google Developers Console</a> account. " \
          "After logging in, click on 'Credentials' to show your " \
          'OAuth 2.0 client IDs and select your desired account name. ' \
          '<br> Alternatively, you can create your ' \
          "Oauth 2.0 credentials by clicking on 'Create credentials' => " \
          "'Oauth client ID'. <br> More information about authentication " \
          "can be found <a href='https://developers.google.com/identity/" \
          "protocols/OAuth2?hl=en_US' target='_blank'>here</a>.",
        optional: false,
        control_type: 'password'
      },
      {
        name: 'developer_token',
        control_type: 'password',
        optional: false,
        hint: 'The developer token generated when you signed up for ' \
          'AdWords API. You must have a Google Ads manager account to apply ' \
          'for access to the API. <br> Sign in ' \
          "<a href='https://ads.google.com/home/tools/manager-accounts/' " \
          "target='_blank'>here</a> then navigate to <b>TOOLS & " \
          'SETTINGS > SETUP > API Center</b>. The API Center option will ' \
          'appear only for Google Ads Manager Accounts. <br> ' \
          "Click <a href='https://support.google.com/google-ads/" \
          "answer/7459399' target='_blank'>here</a> for more information " \
          'on how to create your Google Ads manager account. <br> More ' \
          "information abour Developer tokens here <a href='https://" \
          "developers.google.com/adwords/api/docs/guides/signup' " \
          "target='_blank'>here</a>."
      },
      {
        name: 'manager_account_customer_id',
        hint: 'Customer ID of the target Google Ads manager account. ' \
          'It must be the customer ID for the manager account overseeing ' \
          'the underlying advertising accounts. <br> The manager account ' \
          "customer ID can be found <a href='https://ads.google.com/" \
          "aw/accountaccess/managers' target='_blank'>here</a>. <br> There " \
          'may be several manager accounts. It is advisable to pick the ' \
          'manager account linked to your team and the ID is a 10 digit ' \
          'string in the form XXX-XXX-XXXX.',
        optional: false
      }
    ],

    authorization: {
      type: 'oauth2',

      authorization_url: lambda do |connection|
        scopes = ['https://www.googleapis.com/auth/adwords'].smart_join(' ')

        'https://accounts.google.com/o/oauth2/auth?' \
        "client_id=#{connection['client_id']}" \
        "&scope=#{scopes}" \
        '&response_type=code' \
        '&prompt=consent' \
        '&access_type=offline'
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        response = post('https://accounts.google.com/o/oauth2/token').
                   payload(client_id: connection['client_id'],
                           client_secret: connection['client_secret'],
                           grant_type: 'authorization_code',
                           code: auth_code,
                           scope: 'https://www.googleapis.com/auth/adwords',
                           redirect_uri: redirect_uri).
                   headers('Content-Type': 'application/x-www-form-urlencoded').
                   request_format_www_form_urlencoded
        [response, nil, { oauth_refresh_token: response['refresh_token'] }]
      end,
      refresh: lambda do |connection, refresh_token|
        post('https://accounts.google.com/o/oauth2/token').
          payload(client_id: connection['client_id'],
                  client_secret: connection['client_secret'],
                  scope: 'https://www.googleapis.com/auth/adwords',
                  grant_type: 'refresh_token',
                  refresh_token: refresh_token).
          headers('Content-Type': 'application/x-www-form-urlencoded').
          request_format_www_form_urlencoded
      end,

      refresh_on: [401, /OAUTH_TOKEN_INVALID/],
      detect_on: [/OAUTH_TOKEN_INVALID/],

      apply: lambda do |connection, access_token|
        headers(Authorization: "Bearer #{access_token}",
                'developerToken': connection['developer_token'])
      end
    },
    base_uri: lambda do
      'https://adwords.google.com/api/adwords/'
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

    build_account_fields_xml: lambda do |input|
      account_fields = input&.dig('fields')&.split(',')&.map do |column|
        { 'content!' => column }
      end
      { 'fields' => account_fields }
    end,

    build_ad_fields_xml: lambda do |input|
      fields = 'Id,AdType,AccentColor,AllowFlexibleColor,BusinessName,' \
      'CallToActionText,CreativeFinalAppUrls,CreativeFinalMobileUrls,' \
      'CreativeFinalUrlSuffix,CreativeFinalUrls,CreativeTrackingUrlTemplate,' \
      'CreativeUrlCustomParameters,Description,DisplayUrl,' \
      'ExpandedDynamicSearchCreativeDescription2,ExpandedTextAdDescription2,' \
      'ExpandedTextAdHeadlinePart3,FormatSetting,LongHeadline,MainColor,' \
      'HeadlinePart1,HeadlinePart2,MultiAssetResponsiveDisplayAdAccentColor,' \
      'MultiAssetResponsiveDisplayAdAllowFlexibleColor,' \
      'MultiAssetResponsiveDisplayAdBusinessName,' \
      'MultiAssetResponsiveDisplayAdCallToActionText,' \
      'MultiAssetResponsiveDisplayAdDescriptions,' \
      'MultiAssetResponsiveDisplayAdDynamicSettingsPricePrefix,' \
      'MultiAssetResponsiveDisplayAdDynamicSettingsPromoText,' \
      'MultiAssetResponsiveDisplayAdFormatSetting,' \
      'MultiAssetResponsiveDisplayAdHeadlines,' \
      'MultiAssetResponsiveDisplayAdLandscapeLogoImages,' \
      'MultiAssetResponsiveDisplayAdLogoImages,' \
      'MultiAssetResponsiveDisplayAdLongHeadline,' \
      'MultiAssetResponsiveDisplayAdMainColor,' \
      'MultiAssetResponsiveDisplayAdMarketingImages,' \
      'MultiAssetResponsiveDisplayAdSquareMarketingImages,' \
      'MultiAssetResponsiveDisplayAdYouTubeVideos,Path1,Path2,' \
      'ResponsiveSearchAdDescriptions,ResponsiveSearchAdHeadlines,' \
      'ResponsiveSearchAdPath1,ResponsiveSearchAdPath2,ShortHeadline,' \
      'UniversalAppAdDescriptions,UniversalAppAdHeadlines,' \
      'UniversalAppAdHtml5MediaBundles,UniversalAppAdImages,' \
      'UniversalAppAdMandatoryAdText,UniversalAppAdYouTubeVideos,Url'

      ad_fields = fields.split(',')&.map do |items|
        { 'content!' => items }
      end
      {
        'fields' => ad_fields,
        'predicates': [{
          'field' => { 'content!' => 'Id' },
          'operator' => { 'content!' => 'GREATER_THAN_EQUALS' },
          'values' => { 'content!' => input['since'] }
        }],
        'ordering': [{
          'field' => { 'content!' => 'Id' },
          'sortOrder' => { 'content!' => 'ASCENDING' }
        }],
        'paging': [{
          'startIndex' => { 'content!' => input['offset'] },
          'numberResults' => { 'content!' => input['page_size'] }
        }]
      }
    end,

    build_campaign_fields_xml: lambda do |input|
      fields = 'Id,Name,AdServingOptimizationStatus,Advertising' \
               'ChannelSubType,AdvertisingChannelType,Amount,AppId,' \
               'AppVendor,BaseCampaignId,BiddingStrategyGoalType,' \
               'BiddingStrategyId,BiddingStrategyName,' \
               'BiddingStrategyType,BudgetId,BudgetName,' \
               'BudgetReferenceCount,BudgetStatus,CampaignGroupId,' \
               'CampaignTrialType,DeliveryMethod,Eligible,EndDate,' \
               'EnhancedCpcEnabled,FinalUrlSuffix,' \
               'FrequencyCapMaxImpressions,IsBudgetExplicitlyShared,' \
               'Labels,Level,MaximizeConversionValueTargetRoas,' \
               'RejectionReasons,SelectiveOptimization,ServingStatus,' \
               'Settings,StartDate,Status,TargetContentNetwork,' \
               'TargetCpa,TargetCpaMaxCpcBidCeiling,' \
               'TargetCpaMaxCpcBidFloor,TargetGoogleSearch,' \
               'TargetPartnerSearchNetwork,TargetRoas,' \
               'TargetRoasBidCeiling,TargetRoasBidFloor,' \
               'TargetSearchNetwork,TargetSpendBidCeiling,' \
               'TargetSpendSpendTarget,TimeUnit,TrackingUrlTemplate,' \
               'UrlCustomParameters,VanityPharmaDisplayUrlMode,' \
               'VanityPharmaText,ViewableCpmEnabled'

      campaign_fields = fields.split(',')&.map do |items|
        { 'content!' => items }
      end
      predicates =
        input&.map do |key, value|
          {
            'field' => { 'content!' => key },
            'operator' => { 'content!' => 'EQUALS' },
            'values' => { 'content!' => value }
          }
        end
      {
        'fields' => campaign_fields,
        'predicates': predicates,
        'ordering': [{
          'field' => { 'content!' => 'Id' },
          'sortOrder' => { 'content!' => 'ASCENDING' }
        }],
        'paging': [{
          'startIndex' => { 'content!' => 0 },
          'numberResults' => { 'content!' => 500 }
        }]
      }
    end,

    build_report_query: lambda do |input|
      operator_map = %w[CONTAINS_ALL CONTAINS_ANY CONTAINS_NONE IN NOT_IN]
      date_range =
        if input['date_range_type'] == 'CUSTOM_DATE'
          min_date = input&.dig('date_range', 'min')
          max_date = input&.dig('date_range', 'max')

          min_date_formatted = if min_date.present?
                                 min_date&.to_date&.strftime('%Y%m%d')
                               else
                                 '19700101'
                               end
          max_date_formatted = if max_date.present?
                                 max_date&.to_date&.strftime('%Y%m%d')
                               else
                                 today.to_date&.strftime('%Y%m%d')
                               end

          "#{min_date_formatted},#{max_date_formatted}"
        elsif input['date_range_type'] == 'ALL_TIME'
          nil
        else
          input['date_range_type']
        end
      during_clause = date_range.blank? ? '' : "DURING #{date_range}"

      predicates = input['predicates']&.map do |items|
        if operator_map.include?(items['operator'])
          values = items['values'].split(',')
          "#{items['field']} #{items['operator']} #{values}"
        elsif items['operator'] == '_eq_'
          "#{items['field']} = '#{items['values']}'"
        else
          "#{items['field']} #{items['operator']} '#{items['values']}'"
        end
      end&.split(',')&.smart_join(' and ')

      fields = (call 'build_report_fields',
                     'client_customer_id' => input['client_customer_id'],
                     'developer_token' => input['developer_token'],
                     'report_type' => input['report_type'])&.
               map do |ele|
                 ele[1]
               end&.smart_join(',')
      query_fields = input['fields'] || fields
      query =
        if input['predicates'].present?
          "SELECT #{query_fields} \
          FROM #{input['report_type']} \
          WHERE #{predicates} \
          #{during_clause}"
        else
          "SELECT #{query_fields} \
          FROM #{input['report_type']} \
          #{during_clause}"
        end
      query
    end,

    build_query: lambda do |input, service|
      operator_map = %w[CONTAINS_ALL CONTAINS_ANY CONTAINS_NONE IN NOT_IN]

      predicates = input['predicates']&.map do |items|
        if operator_map.include?(items['operator'])
          values = items['value'].split(',')
          "#{items['field']} #{items['operator']} #{values}"
        elsif items['operator'] == '_eq_'
          "#{items['field']} = '#{items['value']}'"
        else
          "#{items['field']} #{items['operator']} '#{items['value']}'"
        end
      end&.split(',')&.smart_join(' and ')

      fields = case service['service']
               when 'AdwordsUserListService'
                 'AccessReason,AccountUserListStatus,AppId,ClosingReason,ConversionTypes,DataSourceType,' \
                 'DataUploadResult,DateSpecificListEndDate,DateSpecificListRule,DateSpecificListStartDate,' \
                 'Description,ExpressionListRule,Id,IntegrationCode,IsEligibleForDisplay,IsEligibleForSearch,' \
                 'IsReadOnly,ListType,MembershipLifeSpan,Name,PrepopulationStatus,Rules,SeedListSize,' \
                 'SeedUserListDescription,SeedUserListId,SeedUserListName,SeedUserListStatus,Size,SizeForSearch,' \
                 'SizeRange,SizeRangeForSearch,Status,UploadKeyType'
               when 'CampaignService'
                 'Id,Name,AdServingOptimizationStatus,AdvertisingChannelSubType,AdvertisingChannelType,Amount,AppId,' \
                 'AppVendor,BaseCampaignId,BiddingStrategyGoalType,BiddingStrategyId,BiddingStrategyName,' \
                 'BiddingStrategyType,BudgetId,BudgetName,BudgetReferenceCount,BudgetStatus,CampaignGroupId,' \
                 'CampaignTrialType,DeliveryMethod,Eligible,EndDate,EnhancedCpcEnabled,FinalUrlSuffix,' \
                 'FrequencyCapMaxImpressions,IsBudgetExplicitlyShared,Labels,Level,MaximizeConversionValueTargetRoas,' \
                 'RejectionReasons,SelectiveOptimization,ServingStatus,Settings,StartDate,Status,TargetContentNetwork,' \
                 'TargetCpa,TargetCpaMaxCpcBidCeiling,TargetCpaMaxCpcBidFloor,TargetGoogleSearch,' \
                 'TargetPartnerSearchNetwork,TargetRoas,TargetRoasBidCeiling,TargetRoasBidFloor,' \
                 'TargetSearchNetwork,TargetSpendBidCeiling,TargetSpendSpendTarget,TimeUnit,TrackingUrlTemplate,' \
                 'UrlCustomParameters,VanityPharmaDisplayUrlMode,VanityPharmaText,ViewableCpmEnabled'
               end

      query_fields = input['fields'] || fields
      ordering_field = input['ordering']&.[]('field') || 'Id'
      sort_order = input['ordering']&.[]('sortOrder') || 'ASC'
      start_index = input['paging']&.[]('startIndex') || 0
      number_results = input['paging']&.[]('numberResults') || 100

      query =
        if input['predicates'].present?
          "SELECT #{query_fields} \
          WHERE #{predicates} \
          ORDER BY #{ordering_field} #{sort_order} \
          LIMIT #{start_index},#{number_results}"
        else
          "SELECT #{query_fields} \
          ORDER BY #{ordering_field} #{sort_order} \
          LIMIT #{start_index},#{number_results}"
        end
      query
    end,

    build_report_fields: lambda do |input|
      response = post('cm/v201809/ReportDefinitionService').
                 payload(
                   'soapenv:Header': [{
                     'ns1:RequestHeader': [{
                       '@xmlns:ns1': 'https://adwords.google.com/api/adwords/cm/v201809',
                       '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                       '@soapenv:mustUnderstand': '0',
                       'ns1:clientCustomerId': [{
                         "content!": input['client_customer_id']
                       }],
                       'ns1:developerToken': [{
                         "content!": input['developer_token']
                       }],
                       'ns1:userAgent': [{
                         "content!": 'Workato'
                       }],
                       'ns1:validateOnly': [{
                         "content!": false
                       }],
                       'ns1:partialFailure': [{
                         "content!": false
                       }]
                     }]
                   }],
                   'soapenv:Body': [{
                     'getReportFields': [{
                       '@xmlns': 'https://adwords.google.com/api/adwords/cm/v201809',
                       'reportType': [{
                         "content!": input['report_type']
                       }]
                     }]
                   }]
                 ).
                 headers('Content-Type': 'text/xml').
                 format_xml('soapenv:Envelope',
                            '@xmlns:soapenv' => 'http://schemas.xmlsoap.org' \
                            '/soap/envelope/',
                            '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                            '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema' \
                            '-instance',
                            strip_response_namespaces: true).
                 after_error_response(/.*/) do |_code, body, _header, message|
                   error("#{message}: #{body}")
                 end&.dig('Envelope', 0, 'Body', 0) || {}
      fields = response&.dig('getReportFieldsResponse', 0, 'rval')&.
      map do |fieldinfo|
        call('parse_xml_to_hash',
             'xml' => fieldinfo,
             'array_fields' => %w[enumValues enumValuePairs
                                  exclusiveFields]) || {}
      end

      fields&.select do |field|
        field['canSelect'] == 'true'
      end&.pluck('displayFieldName', 'fieldName')
    end,

    build_report_fields_xml: lambda do |input|
      response = post('cm/v201809/ReportDefinitionService').
                 payload(
                   'soapenv:Header': [{
                     'ns1:RequestHeader': [{
                       '@xmlns:ns1': 'https://adwords.google.com/api/adwords/cm/v201809',
                       '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                       '@soapenv:mustUnderstand': '0',
                       'ns1:clientCustomerId': [{
                         "content!": input['client_customer_id']
                       }],
                       'ns1:developerToken': [{
                         "content!": input['developer_token']
                       }],
                       'ns1:userAgent': [{
                         "content!": 'Workato'
                       }],
                       'ns1:validateOnly': [{
                         "content!": false
                       }],
                       'ns1:partialFailure': [{
                         "content!": false
                       }]
                     }]
                   }],
                   'soapenv:Body': [{
                     'getReportFields': [{
                       '@xmlns': 'https://adwords.google.com/api/adwords/cm/v201809',
                       'reportType': [{
                         "content!": input['report_type']
                       }]
                     }]
                   }]
                 ).
                 headers('Content-Type': 'text/xml').
                 format_xml('soapenv:Envelope',
                            '@xmlns:soapenv' => 'http://schemas.xmlsoap.org' \
                            '/soap/envelope/',
                            '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                            '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema' \
                            '-instance',
                            strip_response_namespaces: true).
                 after_error_response(/.*/) do |_code, body, _header, message|
                   error("#{message}: #{body}")
                 end&.dig('Envelope', 0, 'Body', 0) || {}
      fields = response&.dig('getReportFieldsResponse', 0, 'rval')&.
      map do |fieldinfo|
        call('parse_xml_to_hash',
             'xml' => fieldinfo,
             'array_fields' => %w[enumValues enumValuePairs
                                  exclusiveFields]) || {}
      end

      fields&.select do |field|
        field['canSelect'] == 'true'
      end&.pluck('fieldName', 'xmlAttributeName')
    end,

    build_report_fields_query: lambda do |input|
      response = post('cm/v201809/ReportDefinitionService').
                 payload(
                   'soapenv:Header': [{
                     'ns1:RequestHeader': [{
                       '@xmlns:ns1': 'https://adwords.google.com/api/adwords/cm/v201809',
                       '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                       '@soapenv:mustUnderstand': '0',
                       'ns1:clientCustomerId': [{
                         "content!": input['client_customer_id']
                       }],
                       'ns1:developerToken': [{
                         "content!": input['developer_token']
                       }],
                       'ns1:userAgent': [{
                         "content!": 'Workato'
                       }],
                       'ns1:validateOnly': [{
                         "content!": false
                       }],
                       'ns1:partialFailure': [{
                         "content!": false
                       }]
                     }]
                   }],
                   'soapenv:Body': [{
                     'getReportFields': [{
                       '@xmlns': 'https://adwords.google.com/api/adwords/cm/v201809',
                       'reportType': [{
                         "content!": input['report_type']
                       }]
                     }]
                   }]
                 ).
                 headers('Content-Type': 'text/xml').
                 format_xml('soapenv:Envelope',
                            '@xmlns:soapenv' => 'http://schemas.xmlsoap.org' \
                            '/soap/envelope/',
                            '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                            '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema' \
                            '-instance',
                            strip_response_namespaces: true).
                 after_error_response(/.*/) do |_code, body, _header, message|
                   error("#{message}: #{body}")
                 end&.dig('Envelope', 0, 'Body', 0) || {}
      fields = response&.dig('getReportFieldsResponse', 0, 'rval')&.
      map do |fieldinfo|
        call('parse_xml_to_hash',
             'xml' => fieldinfo,
             'array_fields' => %w[enumValues enumValuePairs
                                  exclusiveFields]) || {}
      end

      fields&.select do |field|
        field['canFilter'] == 'true'
      end&.pluck('displayFieldName', 'fieldName')
    end,

    format_report_output: lambda do |input|
      input.inject({}) do |memo, (key, value)|
        formatted =
          if value.is_a?(Hash)
            call(:format_report_output, value)
          elsif value.is_a?(Array)
            value.map { |item| call(:format_report_output, item) }
          else
            value
          end
        memo.merge(key.to_s.gsub(/@/, '') => formatted)
      end&.map do |key, value|
        if %w[report-name table date-range report].include?(key)
          { key => value[0] }
        elsif key == 'columns'
          { key => value[0] }
        else
          { key => value }
        end
      end&.inject(:merge)
    end,

    build_campaign_fields: lambda do |input|
      input.inject({}) do |memo, (key, value)|
        formatted =
          if value.is_a?(Hash)
            call(:build_campaign_fields, value)
          elsif value.is_a?(Array)
            value.map do |items|
              call(:build_campaign_fields, items)
            end
          elsif %w[Ids].include?(key)
            values = value&.split(',')&.map do |items|
              { 'content!' => items }
            end
            { 'content!' => values }
          else
            { 'content!' => value }
          end
        memo.merge(key => formatted)
      end
    end,

    build_members_fields: lambda do |input|
      hashed_keys = %w[hashedEmail hashedPhoneNumber hashedFirstName hashedLastName]
      input.inject({}) do |memo, (key, value)|
        formatted =
          if value.is_a?(Hash)
            call(:build_members_fields, value)
          elsif value.is_a?(Array)
            value.map do |items|
              call(:build_members_fields, items)
            end
          elsif hashed_keys.include?(key)
            { 'content!' => "#{value.downcase.encode_sha256.encode_hex}" }
          else
            { 'content!' => value }
          end
        memo.merge('ns1:' + key => formatted)
      end
    end,

    build_user_list_fields: lambda do |input|
      list_type = input['list_type']
      input.inject({}) do |memo, (key, value)|
        formatted =
          if value.is_a?(Hash)
            call(:build_user_list_fields, value)
          elsif value.is_a?(Array)
            value.map do |items|
              call(:build_user_list_fields, items)
            end
          elsif %w[startDate endDate].include?(key)
            { 'content!' => value.to_time.strftime('%Y%m%d') }
          else
            { 'content!' => value }
          end
        memo.merge('ns1:' + key => formatted)
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
          { key.gsub('.', '_').gsub('-', '_') => value }
        end.inject(:merge)
      else
        input
      end
    end,

    retrieve_customer_id: lambda do |input|
      response = post('mcm/v201809/ManagedCustomerService').
                 payload(
                   'soapenv:Header': [{
                     'ns1:RequestHeader': [{
                       '@xmlns:ns1': 'https://adwords.google.com/api/adwords/mcm/v201809',
                       '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                       '@soapenv:mustUnderstand': '0',
                       'ns1:clientCustomerId': [{
                         "content!": input['manager_account_customer_id']
                       }],
                       'ns1:developerToken': [{
                         "content!": input['developer_token']
                       }],
                       'ns1:userAgent': [{
                         "content!": 'Workato'
                       }],
                       'ns1:validateOnly': [{
                         "content!": false
                       }],
                       'ns1:partialFailure': [{
                         "content!": false
                       }]
                     }]
                   }],
                   'soapenv:Body': [{
                     'get': [{
                       '@xmlns': 'https://adwords.google.com/api/adwords/mcm/v201809',
                       'serviceSelector': [{
                         'fields': [{
                           "content!": 'CustomerId'
                         }]
                       }]
                     }]
                   }]
                 ).
                 headers('clientCustomerId':
                           input['manager_account_customer_id'],
                         'Content-Type': 'text/xml').
                 format_xml('soapenv:Envelope',
                            '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                            '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                            '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                            strip_response_namespaces: true)&.
                 dig('Envelope', 0, 'Body', 0) || {}

      accounts = response&.dig('getResponse', 0, 'rval', 0, 'entries')&.
        map do |accountinfo|
          call('parse_xml_to_hash',
               'xml' => accountinfo,
               'array_fields' => []) || {}
        end
      accounts&.dig(1, 'customerId')
    end,

    build_sample_output: lambda do |input|
      if %w[CampaignService AdGroupService].include?(input['service'])
        response = post("cm/v201809/#{input['service']}").
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/cm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": input['customer_id']
                         }],
                         'ns1:developerToken': [{
                           "content!": input['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'query': [{
                         '@xmlns': 'https://adwords.google.com/api/adwords/cm/v201809',
                         'query': [{
                           "content!": "SELECT #{input['fields']}
                                       LIMIT 0,1"
                         }]
                       }]
                     }]
                   ).
                   headers('Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org' \
                              '/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/' \
                              'XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}

        response&.dig('queryResponse', 0, 'rval', 0, 'entries')&.
          map do |fieldinfo|
            call('parse_xml_to_hash',
                 'xml' => fieldinfo,
                 'array_fields' => %w[settings labels details]) || {}
          end&.dig(0)
      elsif input['service'] == 'AdService'
        response = post("cm/v201809/#{input['service']}").
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/cm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": input['customer_id']
                         }],
                         'ns1:developerToken': [{
                           "content!": input['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'get': [{
                         '@xmlns': 'https://adwords.google.com/api/adwords/cm/v201809',
                         'serviceSelector': [call('build_ad_fields_xml',
                                                  'offset' => 0,
                                                  'page_size' => 1,
                                                  'since' => 0)]
                       }]
                     }]
                   ).
                   headers('Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org' \
                              '/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/' \
                              'XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}

        response&.dig('getResponse', 0, 'rval', 0, 'entries')&.
          map do |fieldinfo|
            call('parse_xml_to_hash',
                 'xml' => fieldinfo,
                 'array_fields' => %w[finalUrls finalMobileUrls
                                      finalAppUrls urlData productImages
                                      productVideoList marketingImages
                                      squareMarketingImages logoImages
                                      landscapeLogoImages headlines
                                      descriptions youTubeVideos
                                      adAttributes templateElements
                                      images videos html5MediaBundles
                                      parameters dimensions urls fields]) || {}
          end&.dig(0)
      elsif input['service'] == 'AdwordsUserListService'
        response = post("rm/v201809/#{input['service']}").
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/rm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": input['customer_id']
                         }],
                         'ns1:developerToken': [{
                           "content!": input['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'query': [{
                         '@xmlns': 'https://adwords.google.com/api/adwords/rm/v201809',
                         'query': [{
                           "content!": "SELECT #{input['fields']}
                                       LIMIT 0,1"
                         }]
                       }]
                     }]
                   ).
                   headers('Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org' \
                              '/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/' \
                              'XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}

        response&.dig('queryResponse', 0, 'rval', 0, 'entries')&.
          map do |fieldinfo|
            call('parse_xml_to_hash',
                 'xml' => fieldinfo,
                 'array_fields' => %w[rules ruleOperands conversionTypes groups items]) || {}
          end&.dig(0)
      else
        []
      end
    end,

    build_download_report_sample_output: lambda do |input|
      headers = {
        clientCustomerId: input['client_customer_id'],
        skipReportHeader: false,
        skipColumnHeader: false,
        skipReportSummary: false,
        useRawEnumValues: false
      }.compact

      date_range =
        if input['date_range_type'] == 'CUSTOM_DATE'
          min_date = input&.dig('date_range', 'min')
          max_date = input&.dig('date_range', 'max')

          min_date_formatted = if min_date.present?
                                 min_date&.to_date&.strftime('%Y%m%d')
                               else
                                 '19700101'
                               end
          max_date_formatted = if max_date.present?
                                 max_date&.to_date&.strftime('%Y%m%d')
                               else
                                 today.to_date&.strftime('%Y%m%d')
                               end

          "#{min_date_formatted},#{max_date_formatted}"
        elsif input['date_range_type'] == 'ALL_TIME'
          nil
        else
          input['date_range_type']
        end
      during_clause = date_range.blank? ? '' : "DURING #{date_range}"

      report_query =
        "SELECT #{input['fields']} \
        FROM #{input['report_type']} \
        #{during_clause}"

      response = post('reportdownload/v201809').
                 payload(__fmt: 'XML',
                         __rdquery: report_query).
                 headers(headers).
                 request_format_multipart_form.response_format_xml.
                 after_error_response(/.*/) do |_code, body, _header, message|
                   error("#{message}: #{body}")
                 end
      report = call('format_report_output', response)
      call('format_api_output_field_names',
           report&.compact)
    end,

    user_list: lambda do |_input|
      [
        {
          name: 'client_customer_id',
          hint: 'Customer ID of the target Google Ads account, typically ' \
            'in the form of "123-456-7890". <b>It must be the advertising ' \
            'account being managed by your manager account.</b>',
          optional: false
        },
        { name: 'list_type', optional: false, control_type: 'select',
          hint: 'Please select the list type.', extends_schema: true,
          pick_list: [
            %w[CRM\ based\ user\ list CrmBasedUserList],
            %w[Logical\ user\ list LogicalUserList],
            %w[Basic\ user\ list BasicUserList],
            %w[Rule\ based\ user\ list RuleBasedUserList],
            %w[Combined\ rule\ user\ list CombinedRuleUserList],
            %w[Date\ specific\ rule\ user\ list DateSpecificRuleUserList],
            %w[Expression\ rule\ user\ list ExpressionRuleUserList],
            %w[Similar\ user\ list SimilarUserList]
          ] },
        { name: 'id', type: 'integer', control_type: 'integer', sticky: true, hint: 'User list identifier' },
        { name: 'isReadOnly', type: 'boolean' },
        { name: 'name', sticky: true, hint: 'Name of the user list' },
        { name: 'description', sticky: true, hint: 'Description of this user list.' },
        { name: 'status', sticky: true, control_type: 'select',
          hint: 'Membership status of this user list. Indicates whether a user list is open or active. ' \
            'Only open user lists can accumulate more users and can be targeted to.',
          pick_list: [
            %w[Open OPEN],
            %w[Closed CLOSED]
          ],
          toggle_hint: 'Select from options',
          toggle_field: {
            name: 'status', label: 'Status', type: 'string', optional: true,
            control_type: 'text', toggle_hint: 'Use custom value',
            hint: 'Allowed values are: OPEN, CLOSED'
          } },
        { name: 'integrationCode', sticky: true, hint: 'An ID from external system. ' \
            'It is used by user list sellers to correlate IDs on their systems.' },
        { name: 'accessReason' },
        { name: 'accountUserListStatus', sticky: true, control_type: 'select',
          hint: 'Indicates if this share is still active. When a UserList is shared with the user this ' \
          'field is set to Active. Later the userList owner can decide to revoke the share and make ' \
          'it Inactive. The default value of this field is set to Active.',
          pick_list: [
            %w[Active ACTIVE],
            %w[Inactive INACTIVE]
          ],
          toggle_hint: 'Select from options',
          toggle_field: {
            name: 'accountUserListStatus', label: 'Account user list status', type: 'string', optional: true,
            control_type: 'text', toggle_hint: 'Use custom value',
            hint: 'Allowed values are: ACTIVE, INACTIVE'
          } },
        { name: 'membershipLifeSpan', sticky: true, hint: "Number of days a user's cookie stays on your " \
          'list since its most recent addition to the list. This field must be between 0 and 540 inclusive. ' \
          'However, for CRM based userlists, this field can be set to 10000 which means no expiration.' },
        { name: 'size', type: 'integer', control_type: 'integer' },
        { name: 'sizeRange' },
        { name: 'sizeForSearch' },
        { name: 'sizeRangeForSearch' },
        { name: 'listType' },
        { name: 'isEligibleForSearch', hint: 'A flag that indicates this user list is eligible for Google Search Network.',
          sticky: true,
          control_type: 'checkbox',
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'isEligibleForSearch',
            control_type: 'text',
            type: 'boolean',
            label: 'Is eligible for search',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          } },
        { name: 'isEligibleForDisplay', type: 'boolean' },
        { name: 'closingReason', sticky: true, control_type: 'select',
          hint: 'Indicating the reason why this user list membership status is closed. ' \
          'It is only populated on lists that were automatically closed due to inactivity, ' \
          'and will be cleared once the list membership status becomes open.',
          pick_list: [
            %w[Unknown UNKNOWN],
            %w[Unused\ list UNUSED_LIST]
          ],
          toggle_hint: 'Select from options',
          toggle_field: {
            name: 'closingReason', label: 'Closing reason', type: 'string', optional: true,
            control_type: 'text', toggle_hint: 'Use custom value',
            hint: 'Allowed values are: UNKNOWN, UNUSED_LIST'
          } },
        ### CrmBasedUserList ###
        { name: 'appId', sticky: true, hint: 'A string that uniquely identifies a mobile application from which the ' \
          'data was collected to AdWords API. For iOS, the ID string is the 9 digit string that appears ' \
          'at the end of an App Store URL (e.g., "476943146" for "Flood-It! 2" whose App Store link is ' \
          'http://itunes.apple.com/us/app/flood-it!-2/id476943146). For Android, the ID string is the ' \
          'application\'s package name (e.g., "com.labpixies.colordrips" for "Color Drips" given Google ' \
          'Play link https://play.google.com/store/apps/details?id=com.labpixies.colordrips).' },
        { name: 'uploadKeyType', sticky: true, control_type: 'select',
          hint: 'Matching key type of the list.',
          pick_list: [
            %w[Unknown UNKNOWN],
            %w[Contact\ info CONTACT_INFO],
            %w[CRM\ ID CRM_ID],
            %w[Mobile\ advertising\ ID MOBILE_ADVERTISING_ID]
          ],
          toggle_hint: 'Select from options',
          toggle_field: {
            name: 'uploadKeyType', label: 'Upload key type', type: 'string', optional: true,
            control_type: 'text', toggle_hint: 'Use custom value',
            hint: 'Allowed values are: UNKNOWN, CONTACT_INFO, CRM_ID, MOBILE_ADVERTISING_ID'
          } },
        { name: 'dataSourceType', sticky: true, control_type: 'select',
          hint: 'Data source of the list. Default value is FIRST_PARTY. ' \
          'Only whitelisted customers can create third party sourced CRM lists.',
          pick_list: [
            %w[Unknown UNKNOWN],
            %w[First\ party FIRST_PARTY],
            %w[Third\ party\ credit\ bureau THIRD_PARTY_CREDIT_BUREAU],
            %w[Third\ party\ voter\ file THIRD_PARTY_VOTER_FILE]
          ],
          toggle_hint: 'Select from options',
          toggle_field: {
            name: 'dataSourceType', label: 'Data source type', type: 'string', optional: true,
            control_type: 'text', toggle_hint: 'Use custom value',
            hint: 'Allowed values are: UNKNOWN, FIRST_PARTY, THIRD_PARTY_CREDIT_BUREAU, THIRD_PARTY_VOTER_FILE'
          } },
        { name: 'dataUploadResult', type: 'object', properties: [
          { name: 'uploadStatus' },
          { name: 'removeAllStatus' }
        ] },
        ### LogicalUserList ###
        { name: 'rules', type: 'array', of: 'object', hint: 'Logical list rules that define this user list. ' \
          'The rules are defined as logical operator (ALL/ANY/NONE) and a list of user lists.', sticky: true,
          properties: [
            { name: 'operator', sticky: true, control_type: 'select',
              hint: 'The logical operator of the rule.',
              pick_list: [
                %w[All ALL],
                %w[Any ANY],
                %w[None NONE],
                %w[Unknown UNKNOWN]
              ],
              toggle_hint: 'Select from options',
              toggle_field: {
                name: 'operator', label: 'Operator', type: 'string', optional: true,
                control_type: 'text', toggle_hint: 'Use custom value',
                hint: 'Allowed values are: ALL, ANY, NONE, UNKNOWN'
              } },
            { name: 'ruleOperands', type: 'array', of: 'object', sticky: true, properties: [
              { name: 'UserList', type: 'object',
                properties: [
                  { name: 'id', type: 'integer', control_type: 'integer', sticky: true },
                  { name: 'name', sticky: true, hint: 'Name of the user list' },
                  { name: 'description', sticky: true, hint: 'Description of this user list.' },
                  { name: 'status', sticky: true, control_type: 'select',
                    hint: 'Membership status of this user list. Indicates whether a user list is open or active. ' \
                      'Only open user lists can accumulate more users and can be targeted to.',
                    pick_list: [
                      %w[Open OPEN],
                      %w[Closed CLOSED]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'status', label: 'Status', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: OPEN, CLOSED'
                    } },
                  { name: 'integrationCode', sticky: true, hint: 'An ID from external system. ' \
                      'It is used by user list sellers to correlate IDs on their systems.' },
                  { name: 'accountUserListStatus', sticky: true, control_type: 'select',
                    hint: 'Indicates if this share is still active. When a UserList is shared with the user this ' \
                    'field is set to Active. Later the userList owner can decide to revoke the share and make ' \
                    'it Inactive. The default value of this field is set to Active.',
                    pick_list: [
                      %w[Active ACTIVE],
                      %w[Inactive INACTIVE]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'accountUserListStatus', label: 'Account user list status', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: ACTIVE, INACTIVE'
                    } },
                  { name: 'membershipLifeSpan', sticky: true, hint: "Number of days a user's cookie stays on your " \
                    'list since its most recent addition to the list. This field must be between 0 and 540 inclusive. ' \
                    'However, for CRM based userlists, this field can be set to 10000 which means no expiration.' },
                  { name: 'isEligibleForSearch', hint: 'A flag that indicates this user list is eligible for Google Search Network.',
                    sticky: true,
                    control_type: 'checkbox',
                    type: 'boolean',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Select from list',
                    toggle_field:
                    {
                      name: 'isEligibleForSearch',
                      control_type: 'text',
                      type: 'boolean',
                      label: 'Is eligible for search',
                      render_input: 'boolean_conversion',
                      parse_output: 'boolean_conversion',
                      toggle_hint: 'Use custom value',
                      optional: true,
                      hint: 'Allowed values are: true, false'
                    } },
                  { name: 'closingReason', sticky: true, control_type: 'select',
                    hint: 'Indicating the reason why this user list membership status is closed. ' \
                    'It is only populated on lists that were automatically closed due to inactivity, ' \
                    'and will be cleared once the list membership status becomes open.',
                    pick_list: [
                      %w[Unknown UNKNOWN],
                      %w[Unused\ list UNUSED_LIST]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'closingReason', label: 'Closing reason', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: UNKNOWN, UNUSED_LIST'
                    } },
                  { name: 'appId', sticky: true, hint: 'A string that uniquely identifies a mobile application from which the ' \
                    'data was collected to AdWords API. For iOS, the ID string is the 9 digit string that appears ' \
                    'at the end of an App Store URL (e.g., "476943146" for "Flood-It! 2" whose App Store link is ' \
                    'http://itunes.apple.com/us/app/flood-it!-2/id476943146). For Android, the ID string is the ' \
                    'application\'s package name (e.g., "com.labpixies.colordrips" for "Color Drips" given Google ' \
                    'Play link https://play.google.com/store/apps/details?id=com.labpixies.colordrips).' },
                  { name: 'uploadKeyType', sticky: true, control_type: 'select',
                    hint: 'Matching key type of the list.',
                    pick_list: [
                      %w[Unknown UNKNOWN],
                      %w[Contact\ info CONTACT_INFO],
                      %w[CRM\ ID CRM_ID],
                      %w[Mobile\ advertising\ ID MOBILE_ADVERTISING_ID]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'uploadKeyType', label: 'Upload key type', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: UNKNOWN, CONTACT_INFO, CRM_ID, MOBILE_ADVERTISING_ID'
                    } },
                  { name: 'dataSourceType', sticky: true, control_type: 'select',
                    hint: 'Data source of the list. Default value is FIRST_PARTY. ' \
                    'Only whitelisted customers can create third party sourced CRM lists.',
                    pick_list: [
                      %w[Unknown UNKNOWN],
                      %w[First\ party FIRST_PARTY],
                      %w[Third\ party\ credit\ bureau THIRD_PARTY_CREDIT_BUREAU],
                      %w[Third\ party\ voter\ file THIRD_PARTY_VOTER_FILE]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'dataSourceType', label: 'Data source type', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: UNKNOWN, FIRST_PARTY, THIRD_PARTY_CREDIT_BUREAU, THIRD_PARTY_VOTER_FILE'
                    } },
                  { name: 'dataUploadResult', type: 'object', properties: [
                    { name: 'uploadStatus' },
                    { name: 'removeAllStatus' }
                  ] },
                  { name: 'conversionTypes', type: 'array', of: 'object', sticky: true, properties: [
                    { name: 'id', hint: 'Conversion type ID', sticky: true },
                    { name: 'name', hint: 'Name of this conversion type', sticky: true },
                    { name: 'category' }
                  ] },
                  { name: 'prepopulationStatus', sticky: true, control_type: 'select',
                    hint: 'Status of pre-population. The field is default to <b>None</b> if not set which means ' \
                    'the previous users will not be considered. If set to <b>Requested</b>, past site visitors or ' \
                    'app users who match the list definition will be included in the list (works on the ' \
                    'Display Network only). This will only pre-populate past users within up to the last 30 ' \
                    "days, depending on the list's membership duration and the date when the remarketing tag is added.",
                    pick_list: [
                      %w[None NONE],
                      %w[Requested REQUESTED]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'prepopulationStatus', label: 'Prepopulation status', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: NONE, REQUESTED'
                    } },
                  { name: 'leftOperand', type: 'object', sticky: true, properties: [
                    { name: 'groups', type: 'array', of: 'object', sticky: true, properties: [
                      { name: 'items', type: 'array', of: 'object', hint: 'Please provide one rule item type only per item.',
                        sticky: true, properties: [
                          { name: 'DateRuleItem', type: 'object', sticky: true, properties: [
                            { name: 'key', sticky: true, type: 'object', properties: [
                              { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                                'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                                'underscore or UTF8 code that is greater than 127.<br>' \
                                "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                            ] },
                            { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                              pick_list: [
                                %w[Equals EQUALS],
                                %w[Not\ equal NOT_EQUAL],
                                %w[Before BEFORE],
                                %w[After AFTER],
                                %w[Unknown UNKNOWN]
                              ],
                              toggle_hint: 'Select from options',
                              toggle_field: {
                                name: 'op', label: 'Operator', type: 'string', optional: true,
                                control_type: 'text', toggle_hint: 'Use custom value',
                                hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                              } },
                            { name: 'value', sticky: true, hint: "The right hand side of date rule item. The date's format should be YYYYMMDD." },
                            { name: 'relativeValue', sticky: true, type: 'object',
                              hint: 'The relative date value of the right hand side. The value field will override this field when both are present.',
                              properties: [{ name: 'offsetInDays', sticky: true, control_type: 'integer', type: 'integer', hint: 'Number of days offset from current date.' }] }
                          ] },
                          { name: 'NumberRuleItem', type: 'object', sticky: true, properties: [
                            { name: 'key', sticky: true, type: 'object', properties: [
                              { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                                'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                                'underscore or UTF8 code that is greater than 127. <br>' \
                                "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                            ] },
                            { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                              pick_list: [
                                %w[Equals EQUALS],
                                %w[Not\ equal NOT_EQUAL],
                                %w[Less\ than LESS_THAN],
                                %w[Less\ than\ or\ equal LESS_THAN_OR_EQUAL],
                                %w[Greater\ than GREATER_THAN],
                                %w[Greater\ than\ or\ equal GREATER_THAN_OR_EQUAL],
                                %w[Unknown UNKNOWN]
                              ],
                              toggle_hint: 'Select from options',
                              toggle_field: {
                                name: 'op', label: 'Operator', type: 'string', optional: true,
                                control_type: 'text', toggle_hint: 'Use custom value',
                                hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                              } },
                            { name: 'value', sticky: true }
                          ] },
                          { name: 'StringRuleItem', type: 'object', sticky: true, properties: [
                            { name: 'key', sticky: true, type: 'object', properties: [
                              { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                                'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                                'underscore or UTF8 code that is greater than 127.<br>' \
                                "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                            ] },
                            { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                              pick_list: [
                                %w[Equals EQUALS],
                                %w[Contains CONTAINS],
                                %w[Starts\ with STARTS_WITH],
                                %w[Ends\ with ENDS_WITH],
                                %w[Not\ equal NOT_EQUAL],
                                %w[Not\ contain NOT_CONTAIN],
                                %w[Not\ starts\ with NOT_START_WITH],
                                %w[Not\ ends\ with NOT_END_WITH],
                                %w[Unknown UNKNOWN]
                              ],
                              toggle_hint: 'Select from options',
                              toggle_field: {
                                name: 'op', label: 'Operator', type: 'string', optional: true,
                                control_type: 'text', toggle_hint: 'Use custom value',
                                hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                              } },
                            { name: 'value', sticky: true, hint: 'The right hand side of the string rule item. ' \
                              'For URL/Referrer URL, value can not contain illegal URL chars such as: "()\'\"\t".' }
                          ] }
                        ] }
                    ] },
                    { name: 'ruleType', sticky: true, control_type: 'select',
                      hint: 'Rule type is used to determine how to group rule item groups and rule items inside ' \
                      'rule item group. Currently, conjunctive normal form (AND of ORs) is only supported for ' \
                      'ExpressionRuleUserList. If no ruleType is specified, it will be treated as disjunctive ' \
                      'normal form (OR of ANDs), namely rule item groups are ORed together and inside each ' \
                      'rule item group, rule items are ANDed together.',
                      pick_list: [
                        %w[Conjunctive\ normal\ form CNF],
                        %w[Disjunctive\ normal\ form DNF],
                        %w[Unknown UNKNOWN]
                      ],
                      toggle_hint: 'Select from options',
                      toggle_field: {
                        name: 'ruleType', label: 'Rule type', type: 'string', optional: true,
                        control_type: 'text', toggle_hint: 'Use custom value',
                        hint: 'Allowed values are: CNF, DNF, UNKNOWN'
                      } }
                  ] },
                  { name: 'rightOperand', type: 'object', sticky: true, properties: [
                    { name: 'groups', type: 'array', of: 'object', sticky: true, properties: [
                      { name: 'items', type: 'array', of: 'object', hint: 'Please provide one rule item type only per item.',
                        sticky: true, properties: [
                          { name: 'DateRuleItem', type: 'object', sticky: true, properties: [
                            { name: 'key', sticky: true, type: 'object', properties: [
                              { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                                'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                                'underscore or UTF8 code that is greater than 127.<br>' \
                                "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                            ] },
                            { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                              pick_list: [
                                %w[Equals EQUALS],
                                %w[Not\ equal NOT_EQUAL],
                                %w[Before BEFORE],
                                %w[After AFTER],
                                %w[Unknown UNKNOWN]
                              ],
                              toggle_hint: 'Select from options',
                              toggle_field: {
                                name: 'op', label: 'Operator', type: 'string', optional: true,
                                control_type: 'text', toggle_hint: 'Use custom value',
                                hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                              } },
                            { name: 'value', sticky: true, hint: "The right hand side of date rule item. The date's format should be YYYYMMDD." },
                            { name: 'relativeValue', sticky: true, type: 'object',
                              hint: 'The relative date value of the right hand side. The value field will override this field when both are present.',
                              properties: [{ name: 'offsetInDays', sticky: true, control_type: 'integer', type: 'integer', hint: 'Number of days offset from current date.' }] }
                          ] },
                          { name: 'NumberRuleItem', type: 'object', sticky: true, properties: [
                            { name: 'key', sticky: true, type: 'object', properties: [
                              { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                                'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                                'underscore or UTF8 code that is greater than 127.<br>' \
                                "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                            ] },
                            { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                              pick_list: [
                                %w[Equals EQUALS],
                                %w[Not\ equal NOT_EQUAL],
                                %w[Less\ than LESS_THAN],
                                %w[Less\ than\ or\ equal LESS_THAN_OR_EQUAL],
                                %w[Greater\ than GREATER_THAN],
                                %w[Greater\ than\ or\ equal GREATER_THAN_OR_EQUAL],
                                %w[Unknown UNKNOWN]
                              ],
                              toggle_hint: 'Select from options',
                              toggle_field: {
                                name: 'op', label: 'Operator', type: 'string', optional: true,
                                control_type: 'text', toggle_hint: 'Use custom value',
                                hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                              } },
                            { name: 'value', sticky: true }
                          ] },
                          { name: 'StringRuleItem', type: 'object', sticky: true, properties: [
                            { name: 'key', sticky: true, type: 'object', properties: [
                              { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                                'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                                'underscore or UTF8 code that is greater than 127.<br>' \
                                "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                            ] },
                            { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                              pick_list: [
                                %w[Equals EQUALS],
                                %w[Contains CONTAINS],
                                %w[Starts\ with STARTS_WITH],
                                %w[Ends\ with ENDS_WITH],
                                %w[Not\ equal NOT_EQUAL],
                                %w[Not\ contain NOT_CONTAIN],
                                %w[Not\ starts\ with NOT_START_WITH],
                                %w[Not\ ends\ with NOT_END_WITH],
                                %w[Unknown UNKNOWN]
                              ],
                              toggle_hint: 'Select from options',
                              toggle_field: {
                                name: 'op', label: 'Operator', type: 'string', optional: true,
                                control_type: 'text', toggle_hint: 'Use custom value',
                                hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                              } },
                            { name: 'value', sticky: true, hint: 'The right hand side of the string rule item. ' \
                              'For URL/Referrer URL, value can not contain illegal URL chars such as: "()\'\"\t".' }
                          ] }
                        ] }
                    ] },
                    { name: 'ruleType', sticky: true, control_type: 'select',
                      hint: 'Rule type is used to determine how to group rule item groups and rule items inside ' \
                      'rule item group. Currently, conjunctive normal form (AND of ORs) is only supported for ' \
                      'ExpressionRuleUserList. If no ruleType is specified, it will be treated as disjunctive ' \
                      'normal form (OR of ANDs), namely rule item groups are ORed together and inside each ' \
                      'rule item group, rule items are ANDed together.',
                      pick_list: [
                        %w[Conjunctive\ normal\ form CNF],
                        %w[Disjunctive\ normal\ form DNF],
                        %w[Unknown UNKNOWN]
                      ],
                      toggle_hint: 'Select from options',
                      toggle_field: {
                        name: 'ruleType', label: 'Rule type', type: 'string', optional: true,
                        control_type: 'text', toggle_hint: 'Use custom value',
                        hint: 'Allowed values are: CNF, DNF, UNKNOWN'
                      } }
                  ] },
                  { name: 'ruleOperator', sticky: true, control_type: 'select',
                    pick_list: [
                      %w[Conjunctive\ normal\ form CNF],
                      %w[Disjunctive\ normal\ form DNF],
                      %w[Unknown UNKNOWN]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'ruleOperator', label: 'Rule operator', type: 'string', sticky: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: CNF, DNF, UNKNOWN'
                    } },
                  { name: 'rule', type: 'object', sticky: true, properties: [
                    { name: 'groups', type: 'array', of: 'object', sticky: true, properties: [
                      { name: 'items', type: 'array', of: 'object', hint: 'Please provide one rule item type only per item.',
                        sticky: true, properties: [
                          { name: 'DateRuleItem', type: 'object', sticky: true, properties: [
                            { name: 'key', sticky: true, type: 'object', properties: [
                              { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                                'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                                'underscore or UTF8 code that is greater than 127.<br>' \
                                "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                            ] },
                            { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                              pick_list: [
                                %w[Equals EQUALS],
                                %w[Not\ equal NOT_EQUAL],
                                %w[Before BEFORE],
                                %w[After AFTER],
                                %w[Unknown UNKNOWN]
                              ],
                              toggle_hint: 'Select from options',
                              toggle_field: {
                                name: 'op', label: 'Operator', type: 'string', optional: true,
                                control_type: 'text', toggle_hint: 'Use custom value',
                                hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                              } },
                            { name: 'value', sticky: true, hint: "The right hand side of date rule item. The date's format should be YYYYMMDD." },
                            { name: 'relativeValue', sticky: true, type: 'object',
                              hint: 'The relative date value of the right hand side. The value field will override this field when both are present.',
                              properties: [{ name: 'offsetInDays', sticky: true, control_type: 'integer', type: 'integer', hint: 'Number of days offset from current date.' }] }
                          ] },
                          { name: 'NumberRuleItem', type: 'object', sticky: true, properties: [
                            { name: 'key', sticky: true, type: 'object', properties: [
                              { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                                'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                                'underscore or UTF8 code that is greater than 127.<br>' \
                                "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                            ] },
                            { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                              pick_list: [
                                %w[Equals EQUALS],
                                %w[Not\ equal NOT_EQUAL],
                                %w[Less\ than LESS_THAN],
                                %w[Less\ than\ or\ equal LESS_THAN_OR_EQUAL],
                                %w[Greater\ than GREATER_THAN],
                                %w[Greater\ than\ or\ equal GREATER_THAN_OR_EQUAL],
                                %w[Unknown UNKNOWN]
                              ],
                              toggle_hint: 'Select from options',
                              toggle_field: {
                                name: 'op', label: 'Operator', type: 'string', optional: true,
                                control_type: 'text', toggle_hint: 'Use custom value',
                                hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                              } },
                            { name: 'value', sticky: true }
                          ] },
                          { name: 'StringRuleItem', type: 'object', sticky: true, properties: [
                            { name: 'key', sticky: true, type: 'object', properties: [
                              { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                                'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                                'underscore or UTF8 code that is greater than 127.<br>' \
                                "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                            ] },
                            { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                              pick_list: [
                                %w[Equals EQUALS],
                                %w[Contains CONTAINS],
                                %w[Starts\ with STARTS_WITH],
                                %w[Ends\ with ENDS_WITH],
                                %w[Not\ equal NOT_EQUAL],
                                %w[Not\ contain NOT_CONTAIN],
                                %w[Not\ starts\ with NOT_START_WITH],
                                %w[Not\ ends\ with NOT_END_WITH],
                                %w[Unknown UNKNOWN]
                              ],
                              toggle_hint: 'Select from options',
                              toggle_field: {
                                name: 'op', label: 'Operator', type: 'string', optional: true,
                                control_type: 'text', toggle_hint: 'Use custom value',
                                hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                              } },
                            { name: 'value', sticky: true, hint: 'The right hand side of the string rule item. ' \
                              'For URL/Referrer URL, value can not contain illegal URL chars such as: "()\'\"\t".' }
                          ] }
                        ] }
                    ] },
                    { name: 'ruleType', sticky: true, control_type: 'select',
                      hint: 'Rule type is used to determine how to group rule item groups and rule items inside ' \
                      'rule item group. Currently, conjunctive normal form (AND of ORs) is only supported for ' \
                      'ExpressionRuleUserList. If no ruleType is specified, it will be treated as disjunctive ' \
                      'normal form (OR of ANDs), namely rule item groups are ORed together and inside each ' \
                      'rule item group, rule items are ANDed together.',
                      pick_list: [
                        %w[Conjunctive\ normal\ form CNF],
                        %w[Disjunctive\ normal\ form DNF],
                        %w[Unknown UNKNOWN]
                      ],
                      toggle_hint: 'Select from options',
                      toggle_field: {
                        name: 'ruleType', label: 'Rule type', type: 'string', optional: true,
                        control_type: 'text', toggle_hint: 'Use custom value',
                        hint: 'Allowed values are: CNF, DNF, UNKNOWN'
                      } }
                  ] },
                  { name: 'startDate', type: 'date', control_type: 'date', sticky: true,
                    hint: 'Start date of users visit. If set to 01/01/2000, then includes all users before <b>End date</b>.' },
                  { name: 'endDate', type: 'date', control_type: 'date', sticky: true,
                    hint: 'End date of users visit. If set to 12/30/2037, then includes all users after <b>Start date</b>.' },
                  { name: 'seedUserListId', sticky: true, type: 'integer', control_type: 'integer',
                    hint: 'Seed user list ID from which this list is derived.' },
                  { name: 'seedUserListName' },
                  { name: 'seedUserListDescription' },
                  { name: 'seedUserListStatus' },
                  { name: 'seedListSize' }
                ] }
            ] }
          ] },
        ### BasicUserList ###
        { name: 'conversionTypes', type: 'array', of: 'object', sticky: true, properties: [
          { name: 'id', hint: 'Conversion type ID', sticky: true },
          { name: 'name', hint: 'Name of this conversion type', sticky: true },
          { name: 'category' }
        ] },
        ### RuleBasedUserList ###
        { name: 'prepopulationStatus', sticky: true, control_type: 'select',
          hint: 'Status of pre-population. The field is default to <b>None</b> if not set which means ' \
          'the previous users will not be considered. If set to <b>Requested</b>, past site visitors or ' \
          'app users who match the list definition will be included in the list (works on the ' \
          'Display Network only). This will only pre-populate past users within up to the last 30 ' \
          "days, depending on the list's membership duration and the date when the remarketing tag is added.",
          pick_list: [
            %w[None NONE],
            %w[Requested REQUESTED]
          ],
          toggle_hint: 'Select from options',
          toggle_field: {
            name: 'prepopulationStatus', label: 'Prepopulation status', type: 'string', optional: true,
            control_type: 'text', toggle_hint: 'Use custom value',
            hint: 'Allowed values are: NONE, REQUESTED'
          } },
        ### CombinedRuleUserList ###
        { name: 'leftOperand', type: 'object', sticky: true, properties: [
          { name: 'groups', type: 'array', of: 'object', sticky: true, properties: [
            { name: 'items', type: 'array', of: 'object', hint: 'Please provide one rule item type only per item.',
              sticky: true, properties: [
                { name: 'DateRuleItem', type: 'object', sticky: true, properties: [
                  { name: 'key', sticky: true, type: 'object', properties: [
                    { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                      'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                      'underscore or UTF8 code that is greater than 127.<br>' \
                      "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                  ] },
                  { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                    pick_list: [
                      %w[Equals EQUALS],
                      %w[Not\ equal NOT_EQUAL],
                      %w[Before BEFORE],
                      %w[After AFTER],
                      %w[Unknown UNKNOWN]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'op', label: 'Operator', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                    } },
                  { name: 'value', sticky: true, hint: "The right hand side of date rule item. The date's format should be YYYYMMDD." },
                  { name: 'relativeValue', sticky: true, type: 'object',
                    hint: 'The relative date value of the right hand side. The value field will override this field when both are present.',
                    properties: [{ name: 'offsetInDays', sticky: true, control_type: 'integer', type: 'integer', hint: 'Number of days offset from current date.' }] }
                ] },
                { name: 'NumberRuleItem', type: 'object', sticky: true, properties: [
                  { name: 'key', sticky: true, type: 'object', properties: [
                    { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                      'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                      'underscore or UTF8 code that is greater than 127. <br>' \
                      "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                  ] },
                  { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                    pick_list: [
                      %w[Equals EQUALS],
                      %w[Not\ equal NOT_EQUAL],
                      %w[Less\ than LESS_THAN],
                      %w[Less\ than\ or\ equal LESS_THAN_OR_EQUAL],
                      %w[Greater\ than GREATER_THAN],
                      %w[Greater\ than\ or\ equal GREATER_THAN_OR_EQUAL],
                      %w[Unknown UNKNOWN]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'op', label: 'Operator', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                    } },
                  { name: 'value', sticky: true }
                ] },
                { name: 'StringRuleItem', type: 'object', sticky: true, properties: [
                  { name: 'key', sticky: true, type: 'object', properties: [
                    { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                      'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                      'underscore or UTF8 code that is greater than 127.<br>' \
                      "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                  ] },
                  { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                    pick_list: [
                      %w[Equals EQUALS],
                      %w[Contains CONTAINS],
                      %w[Starts\ with STARTS_WITH],
                      %w[Ends\ with ENDS_WITH],
                      %w[Not\ equal NOT_EQUAL],
                      %w[Not\ contain NOT_CONTAIN],
                      %w[Not\ starts\ with NOT_START_WITH],
                      %w[Not\ ends\ with NOT_END_WITH],
                      %w[Unknown UNKNOWN]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'op', label: 'Operator', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                    } },
                  { name: 'value', sticky: true, hint: 'The right hand side of the string rule item. ' \
                    'For URL/Referrer URL, value can not contain illegal URL chars such as: "()\'\"\t".' }
                ] }
              ] }
          ] },
          { name: 'ruleType', sticky: true, control_type: 'select',
            hint: 'Rule type is used to determine how to group rule item groups and rule items inside ' \
            'rule item group. Currently, conjunctive normal form (AND of ORs) is only supported for ' \
            'ExpressionRuleUserList. If no ruleType is specified, it will be treated as disjunctive ' \
            'normal form (OR of ANDs), namely rule item groups are ORed together and inside each ' \
            'rule item group, rule items are ANDed together.',
            pick_list: [
              %w[Conjunctive\ normal\ form CNF],
              %w[Disjunctive\ normal\ form DNF],
              %w[Unknown UNKNOWN]
            ],
            toggle_hint: 'Select from options',
            toggle_field: {
              name: 'ruleType', label: 'Rule type', type: 'string', optional: true,
              control_type: 'text', toggle_hint: 'Use custom value',
              hint: 'Allowed values are: CNF, DNF, UNKNOWN'
            } }
        ] },
        { name: 'rightOperand', type: 'object', sticky: true, properties: [
          { name: 'groups', type: 'array', of: 'object', sticky: true, properties: [
            { name: 'items', type: 'array', of: 'object', hint: 'Please provide one rule item type only per item.',
              sticky: true, properties: [
                { name: 'DateRuleItem', type: 'object', sticky: true, properties: [
                  { name: 'key', sticky: true, type: 'object', properties: [
                    { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                      'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                      'underscore or UTF8 code that is greater than 127.<br>' \
                      "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                  ] },
                  { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                    pick_list: [
                      %w[Equals EQUALS],
                      %w[Not\ equal NOT_EQUAL],
                      %w[Before BEFORE],
                      %w[After AFTER],
                      %w[Unknown UNKNOWN]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'op', label: 'Operator', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                    } },
                  { name: 'value', sticky: true, hint: "The right hand side of date rule item. The date's format should be YYYYMMDD." },
                  { name: 'relativeValue', sticky: true, type: 'object',
                    hint: 'The relative date value of the right hand side. The value field will override this field when both are present.',
                    properties: [{ name: 'offsetInDays', sticky: true, control_type: 'integer', type: 'integer', hint: 'Number of days offset from current date.' }] }
                ] },
                { name: 'NumberRuleItem', type: 'object', sticky: true, properties: [
                  { name: 'key', sticky: true, type: 'object', properties: [
                    { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                      'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                      'underscore or UTF8 code that is greater than 127.<br>' \
                      "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                  ] },
                  { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                    pick_list: [
                      %w[Equals EQUALS],
                      %w[Not\ equal NOT_EQUAL],
                      %w[Less\ than LESS_THAN],
                      %w[Less\ than\ or\ equal LESS_THAN_OR_EQUAL],
                      %w[Greater\ than GREATER_THAN],
                      %w[Greater\ than\ or\ equal GREATER_THAN_OR_EQUAL],
                      %w[Unknown UNKNOWN]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'op', label: 'Operator', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                    } },
                  { name: 'value', sticky: true }
                ] },
                { name: 'StringRuleItem', type: 'object', sticky: true, properties: [
                  { name: 'key', sticky: true, type: 'object', properties: [
                    { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                      'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                      'underscore or UTF8 code that is greater than 127.<br>' \
                      "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                  ] },
                  { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                    pick_list: [
                      %w[Equals EQUALS],
                      %w[Contains CONTAINS],
                      %w[Starts\ with STARTS_WITH],
                      %w[Ends\ with ENDS_WITH],
                      %w[Not\ equal NOT_EQUAL],
                      %w[Not\ contain NOT_CONTAIN],
                      %w[Not\ starts\ with NOT_START_WITH],
                      %w[Not\ ends\ with NOT_END_WITH],
                      %w[Unknown UNKNOWN]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'op', label: 'Operator', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                    } },
                  { name: 'value', sticky: true, hint: 'The right hand side of the string rule item. ' \
                    'For URL/Referrer URL, value can not contain illegal URL chars such as: "()\'\"\t".' }
                ] }
              ] }
          ] },
          { name: 'ruleType', sticky: true, control_type: 'select',
            hint: 'Rule type is used to determine how to group rule item groups and rule items inside ' \
            'rule item group. Currently, conjunctive normal form (AND of ORs) is only supported for ' \
            'ExpressionRuleUserList. If no ruleType is specified, it will be treated as disjunctive ' \
            'normal form (OR of ANDs), namely rule item groups are ORed together and inside each ' \
            'rule item group, rule items are ANDed together.',
            pick_list: [
              %w[Conjunctive\ normal\ form CNF],
              %w[Disjunctive\ normal\ form DNF],
              %w[Unknown UNKNOWN]
            ],
            toggle_hint: 'Select from options',
            toggle_field: {
              name: 'ruleType', label: 'Rule type', type: 'string', optional: true,
              control_type: 'text', toggle_hint: 'Use custom value',
              hint: 'Allowed values are: CNF, DNF, UNKNOWN'
            } }
        ] },
        { name: 'ruleOperator', sticky: true, control_type: 'select',
          pick_list: [
            %w[Conjunctive\ normal\ form CNF],
            %w[Disjunctive\ normal\ form DNF],
            %w[Unknown UNKNOWN]
          ],
          toggle_hint: 'Select from options',
          toggle_field: {
            name: 'ruleOperator', label: 'Rule operator', type: 'string', sticky: true,
            control_type: 'text', toggle_hint: 'Use custom value',
            hint: 'Allowed values are: CNF, DNF, UNKNOWN'
          } },
        ### DateSpecificRuleUserList ###
        { name: 'rule', type: 'object', sticky: true, properties: [
          { name: 'groups', type: 'array', of: 'object', sticky: true, properties: [
            { name: 'items', type: 'array', of: 'object', hint: 'Please provide one rule item type only per item.',
              sticky: true, properties: [
                { name: 'DateRuleItem', type: 'object', sticky: true, properties: [
                  { name: 'key', sticky: true, type: 'object', properties: [
                    { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                      'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                      'underscore or UTF8 code that is greater than 127.<br>' \
                      "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                  ] },
                  { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                    pick_list: [
                      %w[Equals EQUALS],
                      %w[Not\ equal NOT_EQUAL],
                      %w[Before BEFORE],
                      %w[After AFTER],
                      %w[Unknown UNKNOWN]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'op', label: 'Operator', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                    } },
                  { name: 'value', sticky: true, hint: "The right hand side of date rule item. The date's format should be YYYYMMDD." },
                  { name: 'relativeValue', sticky: true, type: 'object',
                    hint: 'The relative date value of the right hand side. The value field will override this field when both are present.',
                    properties: [{ name: 'offsetInDays', sticky: true, control_type: 'integer', type: 'integer', hint: 'Number of days offset from current date.' }] }
                ] },
                { name: 'NumberRuleItem', type: 'object', sticky: true, properties: [
                  { name: 'key', sticky: true, type: 'object', properties: [
                    { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                      'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                      'underscore or UTF8 code that is greater than 127.<br>' \
                      "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                  ] },
                  { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                    pick_list: [
                      %w[Equals EQUALS],
                      %w[Not\ equal NOT_EQUAL],
                      %w[Less\ than LESS_THAN],
                      %w[Less\ than\ or\ equal LESS_THAN_OR_EQUAL],
                      %w[Greater\ than GREATER_THAN],
                      %w[Greater\ than\ or\ equal GREATER_THAN_OR_EQUAL],
                      %w[Unknown UNKNOWN]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'op', label: 'Operator', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                    } },
                  { name: 'value', sticky: true }
                ] },
                { name: 'StringRuleItem', type: 'object', sticky: true, properties: [
                  { name: 'key', sticky: true, type: 'object', properties: [
                    { name: 'name', sticky: true, hint: 'A name must begin with US-ascii letters or underscore ' \
                      'or UTF8 code that is greater than 127 and consist of US-ascii letters or digits or ' \
                      'underscore or UTF8 code that is greater than 127.<br>' \
                      "For websites, there are two built-in parameters URL (name = 'url__') and referrer URL (name = 'ref_url__')." }
                  ] },
                  { name: 'op', label: 'Operator', sticky: true, control_type: 'select',
                    pick_list: [
                      %w[Equals EQUALS],
                      %w[Contains CONTAINS],
                      %w[Starts\ with STARTS_WITH],
                      %w[Ends\ with ENDS_WITH],
                      %w[Not\ equal NOT_EQUAL],
                      %w[Not\ contain NOT_CONTAIN],
                      %w[Not\ starts\ with NOT_START_WITH],
                      %w[Not\ ends\ with NOT_END_WITH],
                      %w[Unknown UNKNOWN]
                    ],
                    toggle_hint: 'Select from options',
                    toggle_field: {
                      name: 'op', label: 'Operator', type: 'string', optional: true,
                      control_type: 'text', toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: EQUALS, NOT_EQUAL, BEFORE, AFTER, UNKNOWN'
                    } },
                  { name: 'value', sticky: true, hint: 'The right hand side of the string rule item. ' \
                    'For URL/Referrer URL, value can not contain illegal URL chars such as: "()\'\"\t".' }
                ] }
              ] }
          ] },
          { name: 'ruleType', sticky: true, control_type: 'select',
            hint: 'Rule type is used to determine how to group rule item groups and rule items inside ' \
            'rule item group. Currently, conjunctive normal form (AND of ORs) is only supported for ' \
            'ExpressionRuleUserList. If no ruleType is specified, it will be treated as disjunctive ' \
            'normal form (OR of ANDs), namely rule item groups are ORed together and inside each ' \
            'rule item group, rule items are ANDed together.',
            pick_list: [
              %w[Conjunctive\ normal\ form CNF],
              %w[Disjunctive\ normal\ form DNF],
              %w[Unknown UNKNOWN]
            ],
            toggle_hint: 'Select from options',
            toggle_field: {
              name: 'ruleType', label: 'Rule type', type: 'string', optional: true,
              control_type: 'text', toggle_hint: 'Use custom value',
              hint: 'Allowed values are: CNF, DNF, UNKNOWN'
            } }
        ] },
        { name: 'startDate', type: 'date', control_type: 'date', sticky: true,
          hint: 'Start date of users visit. If set to 01/01/2000, then includes all users before <b>End date</b>.' },
        { name: 'endDate', type: 'date', control_type: 'date', sticky: true,
          hint: 'End date of users visit. If set to 12/30/2037, then includes all users after <b>Start date</b>.' },
        ### ExpressionRuleUserList ###
        # { name: 'rule', type: 'object', sticky: true, properties: [] },
        ### SimilarUserList ###
        { name: 'seedUserListId', sticky: true, type: 'integer', control_type: 'integer',
          hint: 'Seed user list ID from which this list is derived.' },
        { name: 'seedUserListName' },
        { name: 'seedUserListDescription' },
        { name: 'seedUserListStatus' },
        { name: 'seedListSize' }
      ]
    end
  },

  object_definitions: {
    account_info: {
      fields: lambda do |_object_definitions|
        [
          {
            name: 'accountLabels', label: 'Account labels', type: 'array',
            of: 'object',
            properties: [
              { name: 'id', type: 'integer' },
              { name: 'name' }
            ]
          },
          { name: 'canManageClients', type: 'boolean' },
          { name: 'currencyCode' },
          { name: 'customerId', type: 'integer' },
          { name: 'dateTimeZone', label: 'Date/timezone' },
          { name: 'name' },
          { name: 'testAccount', label: 'Is test account', type: 'boolean' }
        ]
      end
    },
    report_definition: {
      fields: lambda do |_object_definition, config_fields|
        report_with_date = %w[
          ACCOUNT_PERFORMANCE_REPORT ADGROUP_PERFORMANCE_REPORT
          AD_CUSTOMIZERS_FEED_ITEM_REPORT AD_PERFORMANCE_REPORT
          AGE_RANGE_PERFORMANCE_REPORT AUDIENCE_PERFORMANCE_REPORT
          AUTOMATIC_PLACEMENTS_PERFORMANCE_REPORT BID_GOAL_PERFORMANCE_REPORT
          CALL_METRICS_CALL_DETAILS_REPORT CAMPAIGN_AD_SCHEDULE_TARGET_REPORT
          CAMPAIGN_LOCATION_TARGET_REPORT CAMPAIGN_PERFORMANCE_REPORT
          CREATIVE_CONVERSION_REPORT VIDEO_PERFORMANCE_REPORT
          CRITERIA_PERFORMANCE_REPORT DISPLAY_KEYWORD_PERFORMANCE_REPORT
          DISPLAY_TOPICS_PERFORMANCE_REPORT FINAL_URL_REPORT
          GENDER_PERFORMANCE_REPORT GEO_PERFORMANCE_REPORT
          KEYWORDLESS_CATEGORY_REPORT KEYWORDLESS_QUERY_REPORT
          KEYWORDS_PERFORMANCE_REPORT LANDING_PAGE_REPORT
          MARKETPLACE_PERFORMANCE_REPORT PAID_ORGANIC_QUERY_REPORT
          PARENTAL_STATUS_PERFORMANCE_REPORT PLACEHOLDER_FEED_ITEM_REPORT
          PLACEHOLDER_REPORT PLACEMENT_PERFORMANCE_REPORT
          PRODUCT_PARTITION_REPORT SEARCH_QUERY_PERFORMANCE_REPORT
          SHOPPING_PERFORMANCE_REPORT TOP_CONTENT_PERFORMANCE_REPORT
          URL_PERFORMANCE_REPORT USER_AD_DISTANCE_REPORT
        ]
        date_range = config_fields.dig('date_range_type') || '[]'
        report_type = config_fields.dig('report_type') || nil
        download_report_raw = config_fields.dig('download_report_raw') || nil
        [
          {
            name: 'client_customer_id', optional: false, type: 'integer',
            control_type: 'number', extends_schema: true,
            hint: '<b>The client customer ID of the advertising account ' \
              'from which data should be included in the report.</b> This is ' \
              'not the same client customer ID as the one specified ' \
              'in the connection; that is for a manager account. ' \
              "Click <a href='https://support.google.com/google-ads/" \
              "answer/1704344?hl=en' target='_blank'>here</a> " \
              'to learn more on how to get your client customer ID.'
          },
          {
            name: 'report_type', optional: false, control_type: 'select',
            pick_list: 'report_types', extends_schema: true,
            hint: 'The report type to download.',
            toggle_hint: 'Select report type',
            toggle_field: {
              name: 'report_type', label: 'Report type', type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Enter API field name. Click <a href=' \
                "'https://developers.google.com/adwords/api/docs/appendix/" \
                "reports#available-reports' target='_blank'>here</a> for " \
                'all available reports.'
            }
          },
          if report_with_date.include?(report_type)
            {
              name: 'date_range_type', optional: false, control_type: 'select',
              pick_list: 'date_range_types', extends_schema: true,
              hint: 'Pick the predefined date ranges that data should be ' \
              'included in the report. Select <b>All time</b> to get data ' \
              'for all dates.<br> <b>NOTE:</b> <b>All time</b> is only ' \
              'allowed if the fields selected does not include the ' \
              '<b>Date</b> or <b>Week</b> column.'
            }
          elsif report_type == 'CLICK_PERFORMANCE_REPORT'
            {
              name: 'date_range_type', optional: false, control_type: 'select',
              pick_list: [
                %w[Today TODAY],
                %w[Yesterday YESTERDAY],
                %w[Custom\ date CUSTOM_DATE]
              ],
              extends_schema: true,
              hint: 'Pick the predefined date ranges that data should be ' \
              'included in the report. <br><b>Note: Click performance report ' \
              'can be run only for a single day and only for dates up to 90 ' \
              'days before the time of the request.</b><br> Please use ' \
              '<b>Custom date</b> to define specific dates other than ' \
              '<b>Today</b> and <b>Yesterday.</b>'
            }
          elsif report_type.blank?
            nil
          else
            {
              name: 'date_range_type', optional: false, control_type: 'select',
              pick_list: [%w[All\ time ALL_TIME]], extends_schema: true,
              hint: 'Pick the predefined date ranges that data should be ' \
              'included in the report.'
            }
          end,
          if date_range == 'CUSTOM_DATE'
            {
              name: 'date_range', sticky: true, optional: true, type: :object,
              hint: 'The custom date range to retrieve the report.',
              properties: [
                {
                  name: 'min', label: 'Minimum date', optional: true,
                  sticky: true, type: 'date', control_type: 'date',
                  hint: 'The latest date in the date range to retrieve the ' \
                  'report. Not specifying this field returns <b>"' \
                  'Start of UTC time"</b> by default.'
                },
                {
                  name: 'max', label: 'Maximum date', optional: true,
                  sticky: true, type: 'date', control_type: 'date',
                  hint: 'The earliest date in the date range to retrieve the ' \
                    'report. Not specifying this field returns ' \
                    '<b>"Today"</b> by default.'
                }
              ]
            }
          end,
          {
            name: 'fields', control_type: 'multiselect', delimiter: ',',
            optional: false, sticky: true, extends_schema: true,
            pick_list: 'report_fields',
            pick_list_params: { report_type: 'report_type' },
            toggle_hint: 'Select from options',
            hint: 'The list of fields to include in the report.',
            toggle_field: {
              name: 'fields', label: 'Field names', type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Enter field names separated by comma. Click <a href=' \
                "'https://developers.google.com/adwords/api/docs/appendix/" \
                "reports#available-reports' target='_blank'>here</a> for " \
                'more details.'
            }
          },
          {
            name: 'predicates', control_type: 'static-list', sticky: true,
            type: :array, optional: true,
            properties: [
              {
                name: 'field', optional: false, control_type: 'select',
                pick_list: 'report_fields_query',
                pick_list_params: { report_type: 'report_type' },
                toggle_hint: 'Select from options',
                hint: 'The field to filter on.',
                toggle_field: {
                  name: 'field', label: 'Field name', type: 'string',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: "Enter field name. Click <a href='https://developers" \
                    '.google.com/adwords/api/docs/appendix/reports#available' \
                    "-reports' target='_blank'>here</a> for more details."
                }
              },
              {
                name: 'operator', optional: false, control_type: 'select',
                pick_list: 'predicate_operators',
                toggle_hint: 'Select from options',
                hint: 'The operator used to filter on. To prevent' \
                  ' calculation accuracy issues, fields whose data' \
                  ' type is <b>Double</b> can be used only with the' \
                  ' following operators in predicates: <b>LESS_THAN</b>' \
                  ' or <b>GREATER_THAN</b>.',
                toggle_field: {
                  name: 'operator', label: 'Operator', type: 'string',
                  control_type: 'text', toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: EQUALS, NOT_EQUALS, IN, NOT_IN, ' \
                    'GREATER_THAN, GREATER_THAN_EQUALS, LESS_THAN, ' \
                    'LESS_THAN_EQUALS, STARTS_WITH, STARTS_WITH_IGNORE_CASE, ' \
                    'CONTAINS, CONTAINS_IGNORE_CASE, DOES_NOT_CONTAIN, ' \
                    'DOES_NOT_CONTAIN_IGNORE_CASE, CONTAINS_ANY, ' \
                    'CONTAINS_ALL, or CONTAINS_NONE.'
                }
              },
              {
                name: 'values', optional: false,
                hint: 'The value(s) used to filter on. Operators CONTAINS_ALL, ' \
                  'CONTAINS_ANY, CONTAINS_NONE, IN and NOT_IN take multiple ' \
                  'values. All others take a single value. Specify ' \
                  'them separated by commas, without any spaces. Read ' \
                  "more about your report type <a href='https://developers." \
                  'google.com/adwords/api/docs/appendix/reports#available-' \
                  "reports' target='_blank'>here</a> to find out the values " \
                  'accepted by the API.'
              }
            ],
            item_label: 'Predicate', add_item_label: 'Add another predicate',
            empty_list_title: 'Specify predicates',
            empty_list_text: 'Click the button below to add predicates. ' \
              'Predicates are treated as inclusive (AND) conditions.',
            hint: 'Use predicates to filter the report. A predicate is ' \
              'comprised of a report field, an operator, and values. If a ' \
              'predicate contains an invalid ID, the call will result in an ' \
              'empty response, and not in a failure or an error message.'
          },
          {
            name: 'download_report_raw',
            label: 'Download report in raw format',
            type: :boolean,
            control_type: 'checkbox',
            sticky: true,
            optional: true,
            extends_schema: true,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from options',
            hint: 'Select <b>Yes</b> to download report in raw format.' \
              ' Default value is No.',
            toggle_field: {
              name: 'download_report_raw',
              label: 'Download report in raw format',
              type: 'string',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              control_type: 'text',
              optional: true,
              extends_schema: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true and false.'
            }
          },
          if download_report_raw == 'true'
            {
              name: 'download_format', optional: false, control_type: 'select',
              pick_list: 'downloadable_formats',
              label: 'File format',
              toggle_hint: 'Select from options',
              hint: 'The file format the report should be in.',
              toggle_field: {
                name: 'download_format',
                label: 'Download format',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: CSVFOREXCEL, CSV, TSV, XML, ' \
                  'GZIPPED_CSV and GZIPPED_XML.'
              }
            }
          end,
          {
            name: 'skip_report_header',
            type: :boolean,
            control_type: 'checkbox',
            optional: true,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from options',
            hint: 'Exclude header row containing the report name and ' \
              'date range in the report. Default value is false.',
            toggle_field: {
              name: 'skip_report_header',
              label: 'Skip report header',
              type: 'string',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true and false.'
            }
          },
          {
            name: 'skip_column_header',
            type: :boolean,
            optional: true,
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from options',
            hint: 'Exclude column row containing field names in the ' \
              'report. Default value is false.',
            toggle_field: {
              name: 'skip_column_header',
              label: 'Skip column header',
              type: 'string',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true and false.'
            }
          },
          {
            name: 'skip_report_summary',
            type: :boolean,
            control_type: 'checkbox',
            optional: true,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from options',
            hint: 'Exclude summary row containing report totals ' \
              'in the report. Default value is false.',
            toggle_field: {
              name: 'skip_report_summary',
              label: 'Skip report summary',
              type: 'string',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true and false.'
            }
          },
          {
            name: 'use_raw_enum_values',
            label: 'Use display name',
            control_type: 'checkbox',
            optional: true,
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from options',
            hint: "Replaces each field's column header name with " \
              'the display name seen in the UI instead of the API name.' \
              ' Default value is false.',
            toggle_field: {
              name: 'use_raw_enum_values',
              label: 'Use display name',
              type: 'string',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true and false.'
            }
          },
          {
            name: 'include_zero_impressions',
            control_type: 'checkbox',
            optional: true,
            type: :boolean,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from options',
            hint: '<b>NOTE: Not all report types support this ' \
              "field; leave blank if it doesn't. Check your report type " \
              "<a href='https://developers.google.com/adwords/api/docs/" \
              "appendix/reports#available-reports' target='_blank'>here</a> " \
              'to learn more</b>. Include rows where all specified metric ' \
              'fields are zero, provided the requested fields and predicates ' \
              'support zero impressions. <br> Default value is blank; the ' \
              "resultant report's behaviour is decribed <a href='https://" \
              'developers.google.com/adwords/api/docs/guides/zeroimpression' \
              "-structure-reports' target='_blank'>here</a>.",
            toggle_field: {
              name: 'include_zero_impressions',
              label: 'Include zero impressions',
              type: 'string',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true and false.'
            }
          }
        ].compact
      end
    },
    downloaded_report: {
      fields: lambda do |connection, config_fields|
        xml_fields =
          config_fields['fields']&.split(',')&.map do |field|
            fields = (call 'build_report_fields_xml',
                           'client_customer_id' =>
                             connection['manager_account_customer_id'],
                           'developer_token' => connection['developer_token'],
                           'report_type' => config_fields['report_type'])&.
                     inject({}) do |hash, (key, value)|
                       hash[key] = value
                       hash
                     end
            fields[field]
          end

        rows = xml_fields&.map do |field|
          { name: field }
        end

        if config_fields['download_report_raw'] == 'true'
          [{ name: 'downloaded_report' }]
        else
          [
            {
              properties: [
                {
                  properties: [
                    { name: 'name' }
                  ],
                  type: 'object',
                  name: 'report_name'
                },
                {
                  properties: [
                    { name: 'date' }
                  ],
                  type: 'object',
                  name: 'date_range'
                },
                {
                  properties: [
                    {
                      properties: [
                        {
                          name: 'column',
                          type: 'array',
                          of: 'object',
                          properties: [
                            { name: 'name' },
                            { name: 'display' }
                          ]
                        }
                      ],
                      type: 'object',
                      name: 'columns'
                    },
                    {
                      name: 'row',
                      type: 'array',
                      of: 'object',
                      properties: rows || []
                    }
                  ],
                  type: 'object',
                  name: 'table'
                }
              ],
              type: 'object',
              name: 'report'
            }
          ]
        end
      end
    },
    campaigns: {
      fields: lambda do |_object_definitions|
        [
          {
            name: 'id',
            type: 'integer',
            parse_output: 'integer_conversion'
          },
          { name: 'name' },
          { name: 'status' },
          { name: 'servingStatus' },
          {
            type: 'date_time',
            name: 'startDate'
          },
          {
            type: 'date_time',
            name: 'endDate'
          },
          {
            name: 'labels',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'id',
                type: 'integer',
                parse_output: 'integer_conversion'
              },
              { name: 'name' },
              { name: 'status' },
              { name: 'Label_Type', label: 'Label type' },
              {
                name: 'attribute',
                type: 'object',
                properties: [
                  {
                    name: 'LabelAttribute_Type',
                    label: 'Label attribute type'
                  },
                  { name: 'backgroundColor' },
                  { name: 'description' }
                ]
              }
            ]
          },
          {
            properties: [
              { name: 'budgetId' },
              { name: 'name' },
              {
                properties: [
                  {
                    label: 'Comparable value type',
                    name: 'ComparableValue_Type'
                  },
                  { name: 'microAmount' }
                ],
                type: 'object',
                name: 'amount'
              },
              { name: 'deliveryMethod' },
              { name: 'referenceCount' },
              {
                label: 'Is explicitly shared',
                type: 'boolean',
                name: 'isExplicitlyShared'
              },
              { name: 'status' }
            ],
            type: 'object',
            name: 'budget'
          },
          {
            properties: [
              {
                type: 'boolean',
                name: 'eligible'
              },
              { name: 'rejectionReasons' }
            ],
            type: 'object',
            name: 'conversionOptimizerEligibility'
          },
          { name: 'adServingOptimizationStatus' },
          {
            properties: [
              {
                type: 'number',
                name: 'impressions'
              },
              { name: 'timeUnit' },
              { name: 'level' }
            ],
            type: 'object',
            name: 'frequencyCap'
          },
          {
            name: 'settings',
            type: 'array',
            of: 'object',
            properties: [
              {
                label: 'Setting type',
                name: 'Setting_Type'
              },
              { name: 'positiveGeoTargetType' },
              { name: 'negativeGeoTargetType' },
              { name: 'domainName' },
              { name: 'languageCode' },
              { name: 'useSuppliedUrlsOnly', label: 'Use supplied URLs only' },
              { name: 'pageFeed' },
              { name: 'appId' },
              { name: 'appVendor' },
              { name: 'description1' },
              { name: 'description2' },
              { name: 'description3' },
              { name: 'description4' },
              {
                name: 'youtubeVideoMediaIds',
                label: 'Youtube video media IDs',
                type: 'array'
              },
              {
                name: 'imageMediaIds',
                label: 'Image media IDs',
                type: 'array'
              },
              { name: 'universalAppBiddingStrategyGoalType' },
              {
                name: 'youtubeVideoMediaIdsOps',
                label: 'Youtube video media IDs ops',
                type: 'object',
                properties: [
                  { name: 'clear', type: 'boolean' },
                  { name: 'operators', type: 'array' }
                ]
              },
              {
                name: 'imageMediaIdsOps',
                label: 'Image media IDs ops',
                type: 'object',
                properties: [
                  { name: 'clear', type: 'boolean' },
                  { name: 'operators', type: 'array' }
                ]
              },
              {
                name: 'adsPolicyDecisions',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'universalAppCampaignAsset' },
                  { name: 'assetId' },
                  {
                    name: 'policyTopicEntries',
                    type: 'array',
                    of: 'object',
                    properties: [
                      { name: 'policyTopicEntryType' },
                      { name: 'policyTopicId' },
                      { name: 'policyTopicName' },
                      { name: 'policyTopicHelpCenterUrl' },
                      {
                        name: 'policyTopicEvidences',
                        type: 'array',
                        of: 'object',
                        properties: [
                          { name: 'policyTopicEvidenceType', type: 'array' },
                          { name: 'evidenceTextList', type: 'array' },
                          {
                            name: 'policyTopicEvidenceDestination' \
                              'MismatchUrlTypes',
                            type: 'array'
                          },
                          {
                            name: 'policyTopicConstraints',
                            type: 'array',
                            of: 'object',
                            properties: [
                              { name: 'constraintType' },
                              { name: 'PolicyTopicConstraint_Type' }
                            ]
                          }
                        ]
                      }
                    ]
                  }
                ]
              },
              { name: 'optIn', type: 'boolean' },
              {
                name: 'merchantId',
                type: 'integer',
                parse_output: 'integer_conversion'
              },
              { name: 'salesCountry' },
              {
                name: 'campaignPriority',
                type: 'integer',
                parse_output: 'integer_conversion'
              },
              { name: 'enableLocal', type: 'boolean' },
              {
                name: 'details',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'criterionTypeGroup' },
                  { name: 'targetAll', type: 'boolean' }
                ]
              },
              { name: 'trackingUrl' }
            ]
          },
          { name: 'advertisingChannelType' },
          { name: 'advertisingChannelSubType' },
          {
            properties: [
              {
                label: 'Target Google search',
                name: 'targetGoogleSearch'
              },
              { name: 'targetSearchNetwork' },
              { name: 'targetContentNetwork' },
              { name: 'targetPartnerSearchNetwork' }
            ],
            type: 'object',
            name: 'networkSetting'
          },
          {
            properties: [
              { name: 'biddingStrategyType' },
              {
                name: 'biddingStrategyId',
                type: 'integer',
                parse_output: 'integer_conversion'
              },
              { name: 'biddingStrategyName' },
              { name: 'biddingStrategySource' },
              { name: 'targetRoasOverride', type: 'number' },
              {
                name: 'bids',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'Bids_Type', label: 'Bids type' },
                  { name: 'bid', type: 'number' },
                  { name: 'bidSource' },
                  { name: 'cpcBidSource', label: 'CPC bid source' },
                  { name: 'cpmBidSource', label: 'CPM bid source' }
                ]
              },
              {
                properties: [
                  {
                    label: 'Bidding scheme type',
                    name: 'BiddingScheme_Type'
                  },
                  { name: 'targetRoas', type: 'number' },
                  { name: 'strategyGoal' },
                  { name: 'bidCeiling', type: 'number' },
                  { name: 'bidModifier' },
                  { name: 'bidChangesForRaisesOnly', type: 'boolean' },
                  { name: 'raiseBidWhenBudgetConstrained', type: 'boolean' },
                  { name: 'raiseBidWhenLowQualityScore', type: 'boolean' },
                  { name: 'targetCpa', label: 'Target CPA', type: 'number' },
                  {
                    name: 'maxCpcBidCeiling',
                    label: 'Max CPC bid ceiling',
                    type: 'number'
                  },
                  {
                    name: 'maxCpcBidFloor',
                    label: 'Max CPC bid floor',
                    type: 'number'
                  },
                  { name: 'targetOutrankShare', type: 'integer' },
                  { name: 'competitorDomain' },
                  { name: 'bidFloor', type: 'number' },
                  { name: 'spendTarget', type: 'number' },
                  {
                    label: 'Enhanced CPC enabled',
                    type: 'boolean',
                    name: 'enhancedCpcEnabled'
                  },
                  {
                    label: 'Viewable CPM enabled',
                    type: 'boolean',
                    name: 'viewableCpmEnabled'
                  }
                ],
                type: 'object',
                name: 'biddingScheme'
              }
            ],
            type: 'object',
            name: 'biddingStrategyConfiguration'
          },
          {
            properties: [
              {
                type: 'boolean',
                name: 'doReplace'
              },
              {
                name: 'parameters',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  { name: 'value' },
                  { name: 'isRemove', type: 'boolean' }
                ]
              }
            ],
            type: 'object',
            name: 'urlCustomParameters'
          },
          {
            properties: [
              { name: 'vanityPharmaDisplayUrlMode' },
              { name: 'vanityPharmaText' }
            ],
            type: 'object',
            name: 'vanityPharma'
          },
          {
            properties: [
              { name: 'biddingStrategyGoalType' },
              { name: 'appId' },
              { name: 'appVendor' }
            ],
            type: 'object',
            name: 'universalAppCampaignInfo'
          },
          {
            properties: [
              {
                name: 'conversionTypeIdsOps',
                type: 'object',
                properties: [
                  { name: 'clear', type: 'boolean' },
                  {
                    name: 'operators',
                    type: 'array',
                    of: 'string'
                  }
                ]
              },
              {
                name: 'conversionTypeIds',
                type: 'array',
                of: 'string'
              }
            ],
            type: 'object',
            name: 'selectiveOptimization'
          },
          { name: 'campaignTrialType' },
          { name: 'trackingUrlTemplate' },
          { name: 'finalUrlSuffix', label: 'Final URL suffix' },
          {
            name: 'campaignGroupId',
            type: 'integer',
            parse_output: 'integer_conversion'
          },
          {
            name: 'baseCampaignId',
            type: 'integer',
            parse_output: 'integer_conversion'
          }
        ]
      end
    },
    campaigns_fields: {
      fields: lambda do |_object_definitions, config_fields|
        bidding_strategy_type = config_fields&.
          dig('biddingStrategyConfiguration', 'biddingStrategyType') || '[]'
        bidding_scheme_fields = [
          {
            name: 'enhancedCpcEnabled',
            label: 'Enhanced CPC enabled',
            type: :boolean,
            control_type: 'checkbox',
            sticky: true,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from options',
            hint: 'The enhanced CPC bidding option for the ' \
              'campaign, which enables bids to be enhanced based ' \
              'on conversion optimizer data.',
            toggle_field: {
              name: 'enhancedCpcEnabled',
              label: 'Enhanced CPC enabled',
              type: 'string',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true and false.'
            }
          },
          {
            name: 'targetRoas',
            label: 'Target ROAS',
            control_type: 'number',
            type: 'number',
            hint: 'The target return on ad spend (ROAS).  If set, ' \
              'the bid strategy will maximize revenue while ' \
              'averaging the target return on ad spend.'
          },
          {
            name: 'strategyGoal',
            control_type: 'select',
            sticky: true,
            extends_schema: true,
            pick_list: [
              %w[Page\ one PAGE_ONE],
              %w[Page\ one\ promoted PAGE_ONE_PROMOTED]
            ],
            toggle_hint: 'Select from options',
            hint: 'Specifies the strategy goal: where ' \
              'impressions are desired to be shown on search ' \
              'result pages.',
            toggle_field: {
              name: 'strategyGoal',
              type: 'string',
              optional: true,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: PAGE_ONE and ' \
                'PAGE_ONE_PROMOTED.'
            }
          },
          {
            name: 'bidCeiling',
            type: 'object',
            hint: 'Strategy maximum bid limit in advertiser ' \
              'local currency micro units.',
            properties: [
              {
                name: 'microAmount',
                control_type: 'integer',
                type: 'integer',
                hint: 'Amount in micros. One million is ' \
                  'equivalent to one unit.'
              }
            ]
          },
          {
            name: 'bidModifier',
            control_type: 'integer',
            type: 'integer',
            hint: 'Bid Multiplier to be applied to the relevant ' \
              'bid estimate (depending on the strategyGoal) ' \
              "in determining a keyword's new max cpc bid."
          },
          {
            name: 'bidChangesForRaisesOnly',
            type: :boolean,
            control_type: 'checkbox',
            sticky: true,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from options',
            hint: 'Controls whether the strategy always follows ' \
              'bid estimate changes, or only increases. ',
            toggle_field: {
              name: 'bidChangesForRaisesOnly',
              label: 'Bid changes for raises only',
              type: 'string',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true and false.'
            }
          },
          {
            name: 'raiseBidWhenBudgetConstrained',
            type: :boolean,
            control_type: 'checkbox',
            sticky: true,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from options',
            hint: 'Controls whether the strategy is allowed to ' \
              'raise bids when the throttling rate of the budget ' \
              'it is serving out of rises above a threshold.',
            toggle_field: {
              name: 'raiseBidWhenBudgetConstrained',
              label: 'Raise bid when budget constrained',
              type: 'string',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true and false.'
            }
          },
          {
            name: 'raiseBidWhenLowQualityScore',
            type: :boolean,
            control_type: 'checkbox',
            sticky: true,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Select from options',
            hint: 'Controls whether the strategy is allowed to ' \
              'raise bids on keywords with lower-range quality ' \
              'scores.',
            toggle_field: {
              name: 'raiseBidWhenLowQualityScore',
              label: 'Raise bid when low quality score',
              type: 'string',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true and false.'
            }
          },
          {
            name: 'targetCpa',
            label: 'Target CPA',
            hint: 'Average cost per acquisition (CPA) target.',
            type: 'object',
            properties: [
              {
                name: 'microAmount',
                control_type: 'integer',
                type: 'integer',
                hint: 'Amount in micros. One million is ' \
                  'equivalent to one unit.'
              }
            ]
          },
          {
            name: 'maxCpcBidCeiling',
            label: 'Max CPC bid ceiling',
            hint: 'Maximum cpc bid limit that applies to all ' \
              'keywords managed by the strategy.',
            type: 'object',
            properties: [
              {
                name: 'microAmount',
                control_type: 'integer',
                type: 'integer',
                hint: 'Amount in micros. One million is ' \
                  'equivalent to one unit.'
              }
            ]
          },
          {
            name: 'maxCpcBidFloor',
            label: 'Max CPC bid floor',
            hint: 'Minimum cpc bid limit that applies to ' \
              'all keywords managed by the strategy.',
            type: 'object',
            properties: [
              {
                name: 'microAmount',
                control_type: 'integer',
                type: 'integer',
                hint: 'Amount in micros. One million is ' \
                  'equivalent to one unit.'
              }
            ]
          },
          {
            name: 'targetOutrankShare',
            control_type: 'integer',
            type: 'integer',
            hint: 'Specifies the target fraction (in micros) ' \
              'of auctions where the advertiser should outrank ' \
              'the competitor. This field must be between 1 ' \
              'and 1000000, inclusive. '
          },
          {
            name: 'competitorDomain',
            hint: "Competitor's visible domain URL."
          },
          {
            name: 'bidFloor',
            type: 'object',
            hint: 'Minimum bid limit that applies to all ' \
              'keywords managed by the strategy.',
            properties: [
              {
                name: 'microAmount',
                control_type: 'integer',
                type: 'integer',
                hint: 'Amount in micros. One million is ' \
                  'equivalent to one unit.'
              }
            ]
          },
          {
            name: 'spendTarget',
            type: 'object',
            hint: 'A spend target under which to maximize clicks.',
            properties: [
              {
                name: 'microAmount',
                control_type: 'integer',
                type: 'integer',
                hint: 'Amount in micros. One million is ' \
                  'equivalent to one unit.'
              }
            ]
          }
        ]
        bidding_scheme_properties =
          case bidding_strategy_type
          when 'MANUAL_CPC'
            bidding_scheme_fields.only('enhancedCpcEnabled')
          when 'MAXIMIZE_CONVERSION_VALUE'
            bidding_scheme_fields.only('targetRoas')
          when 'PAGE_ONE_PROMOTED'
            bidding_scheme_fields.only('strategyGoal', 'bidCeiling',
                                       'bidModifier', 'bidChangesForRaisesOnly',
                                       'raiseBidWhenBudgetConstrained',
                                       'raiseBidWhenLowQualityScore')
          when 'TARGET_CPA'
            bidding_scheme_fields.only('targetCpa', 'maxCpcBidCeiling',
                                       'maxCpcBidFloor')
          when 'TARGET_OUTRANK_SHARE'
            bidding_scheme_fields.only('targetOutrankShare', 'competitorDomain',
                                       'maxCpcBidCeiling',
                                       'bidChangesForRaisesOnly',
                                       'raiseBidWhenLowQualityScore')
          when 'TARGET_ROAS'
            bidding_scheme_fields.only('bidCeiling', 'bidFloor', 'targetRoas')
          when 'TARGET_SPEND'
            bidding_scheme_fields.only('spendTarget', 'bidCeiling')
          end

        [
          {
            name: 'client_customer_id',
            hint: 'Customer ID of the target Google Ads account, typically ' \
              'in the form of "123-456-7890". <b>It must be the advertising ' \
              'account being managed by your manager account.</b>',
            optional: false
          },
          {
            name: 'id',
            control_type: 'integer',
            type: 'integer',
            parse_output: 'integer_conversion',
            sticky: true
          },
          {
            name: 'name',
            sticky: true
          },
          {
            name: 'status',
            control_type: 'select',
            sticky: true,
            pick_list: [
              %w[Enabled ENABLED],
              %w[Paused PAUSED],
              %w[Removed REMOVED]
            ],
            toggle_hint: 'Select from options',
            hint: 'Status of this campaign. On add, defaults to <b>ENABLED.<b>',
            toggle_field: {
              name: 'status',
              label: 'Status',
              type: 'string',
              optional: true,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: ENABLED, PAUSED, and REMOVED'
            }
          },
          {
            control_type: 'date',
            type: 'date',
            hint: 'Date the campaign begins. On add, defaults to the ' \
              "current day in the parent account's local timezone.",
            sticky: true,
            name: 'startDate'
          },
          {
            control_type: 'date',
            type: 'date',
            hint: 'Date the campaign ends. On add, defaults to 12/30/2037, ' \
              'which means the campaign will run indefinitely.',
            sticky: true,
            name: 'endDate'
          },
          {
            name: 'labels',
            type: 'array',
            of: 'object',
            sticky: true,
            properties: [
              {
                name: 'id',
                label: 'Label ID',
                control_type: 'integer',
                type: 'integer',
                sticky: true,
                hint: 'This field is required when used in ' \
                  '<b>UPDATE</b> operation.',
                parse_output: 'integer_conversion'
              },
              {
                name: 'name',
                sticky: true
              },
              {
                name: 'attribute',
                type: 'object',
                properties: [
                  {
                    name: 'backgroundColor',
                    hint: 'Background color of the label in RGB format.'
                  },
                  {
                    name: 'description',
                    hint: 'A short description of the label.'
                  }
                ]
              }
            ]
          },
          {
            name: 'adServingOptimizationStatus',
            control_type: 'select',
            sticky: true,
            pick_list: 'ad_serving_optimization_status',
            toggle_hint: 'Select from options',
            hint: 'Ad serving optimization status.',
            toggle_field: {
              name: 'adServingOptimizationStatus',
              label: 'Ad serving optimization status',
              type: 'string',
              optional: true,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: OPTIMIZE, CONVERSION_OPTIMIZE, ' \
                'ROTATE, ROTATE_INDEFINITELY, and UNAVAILABLE'
            }
          },
          {
            properties: [
              {
                control_type: 'number',
                type: 'number',
                hint: 'Maximum number of impressions allowed during the time ' \
                  'range by this cap. To remove the frequency cap on a ' \
                  'campaign, set this field to 0.',
                name: 'impressions'
              },
              {
                name: 'timeUnit',
                control_type: 'select',
                sticky: true,
                pick_list: [
                  %w[Day DAY],
                  %w[Week WEEK],
                  %w[Month MONTH]
                ],
                toggle_hint: 'Select from options',
                hint: 'Unit of time the cap is defined at.',
                toggle_field: {
                  name: 'timeUnit',
                  label: 'Time unit',
                  type: 'string',
                  optional: true,
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: DAY, WEEK, and MONTH.'
                }
              },
              {
                name: 'level',
                control_type: 'select',
                sticky: true,
                pick_list: [
                  %w[Creative CREATIVE],
                  %w[AdGroup ADGROUP],
                  %w[Campaign CAMPAIGN]
                ],
                toggle_hint: 'Select from options',
                hint: 'The level on which the cap is to be applied ' \
                  '(creative/adgroup). Cap is applied to all the entities ' \
                  'of this level in the campaign.',
                toggle_field: {
                  name: 'level',
                  label: 'Level',
                  type: 'string',
                  optional: true,
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: CREATIVE, ADGROUP, and CAMPAIGN.'
                }
              }
            ],
            type: 'object',
            sticky: true,
            name: 'frequencyCap'
          },
          {
            name: 'settings',
            type: 'array',
            hint: 'List of settings for the campaign.',
            of: 'object',
            properties: [
              {
                name: '@xsi:type',
                label: 'Setting type',
                control_type: 'select',
                pick_list: 'settings_type',
                toggle_hint: 'Select from options',
                hint: 'Select setting type',
                toggle_field: {
                  name: '@xsi:type',
                  label: 'Setting type',
                  type: 'string',
                  control_type: 'text',
                  optional: true,
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: DynamicSearchAdsSetting, ' \
                    'GeoTargetTypeSetting, UniversalAppCampaignSetting, ' \
                    'RealTimeBiddingSetting, ShoppingSetting, ' \
                    'TargetingSetting, and TrackingSetting.'
                }
              },
              {
                name: 'domainName',
                hint: 'The Internet domain name that this setting ' \
                  'represents. E.g. "google.com" or "www.google.com".'
              },
              {
                name: 'languageCode',
                hint: 'A language code that indicates what language ' \
                  'the contents of the domain is in. E.g. "en"'
              },
              {
                name: 'useSuppliedUrlsOnly',
                label: 'Use supplied URLs only',
                type: :boolean,
                control_type: 'checkbox',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Select from options',
                hint: 'A toggle for the advertiser to decide if they want ' \
                  'this campaign to use the advertiser supplied URLs only.',
                toggle_field: {
                  name: 'useSuppliedUrlsOnly',
                  label: 'Use supplied URLs only',
                  type: 'string',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  control_type: 'text',
                  optional: true,
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true and false.'
                }
              },
              {
                name: 'positiveGeoTargetType',
                control_type: 'select',
                pick_list: [
                  %w[Do\ not\ care DONT_CARE],
                  %w[Area\ of\ interest AREA_OF_INTEREST],
                  %w[Location\ of\ presence LOCATION_OF_PRESENCE]
                ],
                label: 'Positive geo target type',
                toggle_hint: 'Select from options',
                hint: 'The setting used for positive geotargeting in ' \
                  'this particular campaign.',
                toggle_field: {
                  name: 'positiveGeoTargetType',
                  label: 'Positive geo target type',
                  type: 'string',
                  optional: true,
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: DONT_CARE, AREA_OF_INTEREST, ' \
                    'and LOCATION_OF_PRESENCE'
                }
              },
              {
                name: 'negativeGeoTargetType',
                control_type: 'select',
                pick_list: [
                  %w[Do\ not\ care DONT_CARE],
                  %w[Location\ of\ presence LOCATION_OF_PRESENCE]
                ],
                label: 'Negative geo target type',
                toggle_hint: 'Select from options',
                hint: 'The setting used for negative geotargeting in ' \
                  'this particular campaign.',
                toggle_field: {
                  name: 'negativeGeoTargetType',
                  label: 'Negative geo target type',
                  type: 'string',
                  optional: true,
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: DONT_CARE and LOCATION_OF_PRESENCE'
                }
              },
              {
                name: 'appId',
                hint: 'A string that uniquely identifies a mobile application.'
              },
              {
                name: 'appVendor',
                control_type: 'select',
                pick_list: [
                  %w[Vendor\ unknown VENDOR_UNKNOWN],
                  %w[Vendor\ Apple\ app\ store VENDOR_APPLE_APP_STORE],
                  %w[Vendor\ Google\ market VENDOR_GOOGLE_MARKET]
                ],
                toggle_hint: 'Select from options',
                hint: 'The vendor, i.e. application store that distributes ' \
                  'this specific app.',
                toggle_field: {
                  name: 'appVendor',
                  label: 'App vendor',
                  type: 'string',
                  optional: true,
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: VENDOR_UNKNOWN, ' \
                    'VENDOR_APPLE_APP_STORE and VENDOR_GOOGLE_MARKET'
                }
              },
              {
                name: 'description1',
                hint: 'A description line of your mobile application ' \
                  'promotion ad(s).'
              },
              {
                name: 'description2',
                hint: 'A description line of your mobile application ' \
                  'promotion ad(s).'
              },
              {
                name: 'description3',
                hint: 'A description line of your mobile application ' \
                  'promotion ad(s).'
              },
              {
                name: 'description4',
                hint: 'A description line of your mobile application ' \
                  'promotion ad(s).'
              },
              {
                name: 'youtubeVideoMediaIds',
                label: 'Youtube video media IDs',
                hint: 'MediaIds for YouTube videos to be shown to users ' \
                  'when advertising on video networks. <br> Enter IDs ' \
                  'separated by commas without spaces.'
              },
              {
                name: 'imageMediaIds',
                label: 'Image media IDs',
                hint: 'MediaIds for landscape images to be used in ' \
                  'creatives to be shown to users when advertising ' \
                  'on display networks. <br> Enter IDs separated by ' \
                  'commas without spaces.'
              },
              {
                name: 'universalAppBiddingStrategyGoalType',
                control_type: 'select',
                pick_list: 'bidding_strategy_goal_type',
                toggle_hint: 'Select from options',
                hint: 'Represents the goal towards which the bidding ' \
                  'strategy, of this universal app campaign, should ' \
                  'optimize for.',
                toggle_field: {
                  name: 'universalAppBiddingStrategyGoalType',
                  label: 'Universal app bidding strategy goal type',
                  type: 'string',
                  optional: true,
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: ' \
                    'OPTIMIZE_FOR_INSTALL_CONVERSION_VOLUME, ' \
                    'OPTIMIZE_FOR_IN_APP_CONVERSION_VOLUME, ' \
                    'OPTIMIZE_FOR_TOTAL_CONVERSION_VALUE, ' \
                    'OPTIMIZE_FOR_TARGET_IN_APP_CONVERSION, ' \
                    'OPTIMIZE_FOR_RETURN_ON_ADVERTISING_SPEND'
                }
              },
              {
                name: 'youtubeVideoMediaIdsOps',
                label: 'Youtube video media IDs ops',
                type: 'object',
                hint: 'Operations for YouTube Video MediaIds.',
                properties: [
                  {
                    name: 'clear',
                    label: 'Clear',
                    type: :boolean,
                    control_type: 'checkbox',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Select from options',
                    hint: 'Indicates that all contents of the list should ' \
                      'be deleted. If this is true, the list will be ' \
                      'cleared first, then proceed to the operators.',
                    toggle_field: {
                      name: 'clear',
                      label: 'Clear',
                      type: 'string',
                      render_input: 'boolean_conversion',
                      parse_output: 'boolean_conversion',
                      control_type: 'text',
                      optional: true,
                      toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: true and false.'
                    }
                  },
                  {
                    name: 'operators',
                    control_type: 'select',
                    pick_list: [
                      %w[Put PUT],
                      %w[Remove REMOVE],
                      %w[Update UPDATE]
                    ],
                    label: 'Operators',
                    toggle_hint: 'Select from options',
                    hint: 'The desired behavior of each element in the ' \
                      'POJO list that this ListOperation corresponds to. ',
                    toggle_field: {
                      name: 'operators',
                      label: 'Operators',
                      type: 'string',
                      optional: true,
                      control_type: 'text',
                      toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: PUT, REMOVE and UPDATE.'
                    }
                  }
                ]
              },
              {
                name: 'imageMediaIdsOps',
                label: 'Image media IDs ops',
                type: 'object',
                hint: 'Operations for Image MediaIds.',
                properties: [
                  {
                    name: 'clear',
                    label: 'Clear',
                    type: :boolean,
                    control_type: 'checkbox',
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Select from options',
                    hint: 'Indicates that all contents of the list should ' \
                      'be deleted. If this is true, the list will be ' \
                      'cleared first, then proceed to the operators.',
                    toggle_field: {
                      name: 'clear',
                      label: 'Clear',
                      type: 'string',
                      render_input: 'boolean_conversion',
                      parse_output: 'boolean_conversion',
                      control_type: 'text',
                      optional: true,
                      toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: true and false.'
                    }
                  },
                  {
                    name: 'operators',
                    control_type: 'select',
                    pick_list: [
                      %w[Put PUT],
                      %w[Remove REMOVE],
                      %w[Update UPDATE]
                    ],
                    label: 'Operators',
                    toggle_hint: 'Select from options',
                    hint: 'The desired behavior of each element in the ' \
                      'POJO list that this ListOperation corresponds to. ',
                    toggle_field: {
                      name: 'operators',
                      label: 'Operators',
                      type: 'string',
                      optional: true,
                      control_type: 'text',
                      toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: PUT, REMOVE and UPDATE.'
                    }
                  }
                ]
              },
              {
                name: 'adsPolicyDecisions',
                type: 'array',
                of: 'object',
                hint: 'Ads policy decisions associated with asset(s).',
                properties: [
                  {
                    name: 'universalAppCampaignAsset',
                    control_type: 'select',
                    pick_list: 'app_campaign_asset',
                    toggle_hint: 'Select from options',
                    hint: 'Used to identify assets that are associated ' \
                      'with the Ads Policy decisions.',
                    toggle_field: {
                      name: 'universalAppCampaignAsset',
                      label: 'Universal app campaign asset',
                      type: 'string',
                      optional: true,
                      control_type: 'text',
                      toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: COMBINATION, ' \
                        'APP_DESTINATION, APP_ASSETS, DESCRIPTION_1, ' \
                        'DESCRIPTION_2, DESCRIPTION_3, DESCRIPTION_4, ' \
                        'VIDEO and IMAGE.'
                    }
                  },
                  {
                    name: 'assetId',
                    hint: 'Unique identifier, which when combined with ' \
                      'the UniversalAppCampaignAsset, can be used to ' \
                      'uniquely identify the exact asset.'
                  },
                  {
                    name: 'policyTopicEntries',
                    type: 'array',
                    of: 'object',
                    properties: [
                      {
                        name: 'policyTopicEntryType',
                        control_type: 'select',
                        pick_list: [
                          %w[Prohibited PROHIBITED],
                          %w[Limited LIMITED]
                        ],
                        toggle_hint: 'Select from options',
                        hint: 'The type of the policy topic entry.',
                        toggle_field: {
                          name: 'policyTopicEntryType',
                          label: 'Policy topic entry type',
                          type: 'string',
                          optional: true,
                          control_type: 'text',
                          toggle_hint: 'Use custom value',
                          hint: 'Allowed values are: PROHIBITED and LIMITED.'
                        }
                      },
                      { name: 'policyTopicId' },
                      {
                        name: 'policyTopicName',
                        hint: 'The policy topic name (in English).'
                      },
                      {
                        name: 'policyTopicHelpCenterUrl',
                        hint: 'URL of the help center article describing ' \
                          'this policy topic entry.'
                      },
                      {
                        name: 'policyTopicConstraints',
                        type: 'array',
                        of: 'object',
                        properties: [
                          {
                            name: 'constraintType',
                            control_type: 'select',
                            pick_list: 'constraint_type',
                            toggle_hint: 'Select from options',
                            toggle_field: {
                              name: 'constraintType',
                              label: 'Constraint type',
                              type: 'string',
                              optional: true,
                              control_type: 'text',
                              toggle_hint: 'Use custom value',
                              hint: 'Allowed values are: COUNTRY, RESELLER, ' \
                                'CERTIFICATE_MISSING_IN_COUNTRY, ' \
                                'CERTIFICATE_DOMAIN_MISMATCH_IN_COUNTRY, ' \
                                'CERTIFICATE_MISSING, UNKNOWN and ' \
                                'CERTIFICATE_DOMAIN_MISMATCH.'
                            }
                          }
                        ]
                      }
                    ]
                  }
                ]
              },
              {
                name: 'optIn',
                type: :boolean,
                control_type: 'checkbox',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Select from options',
                hint: 'Whether the campaign is opted in to real-time bidding.',
                toggle_field: {
                  name: 'optIn',
                  label: 'Opt in',
                  type: 'string',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  control_type: 'text',
                  optional: true,
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true and false.'
                }
              },
              {
                name: 'merchantId',
                type: 'integer',
                hint: 'ID of the Merchant Center account.'
              },
              {
                name: 'salesCountry',
                hint: 'Sales country of products to include in the ' \
                  'campaign. This field is required for Shopping campaigns.'
              },
              {
                name: 'campaignPriority',
                type: 'integer',
                hint: 'Priority of the campaign. Campaigns with ' \
                  'numerically higher priorities take precedence over ' \
                  'those with lower priorities.'
              },
              {
                name: 'enableLocal',
                type: :boolean,
                control_type: 'checkbox',
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Select from options',
                hint: 'Whether to include local products.',
                toggle_field: {
                  name: 'enableLocal',
                  label: 'Enable local',
                  type: 'string',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  control_type: 'text',
                  optional: true,
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true and false.'
                }
              },
              {
                name: 'details',
                type: 'array',
                of: 'object',
                hint: 'The list of per-criterion-type-group ' \
                  'targeting settings.',
                properties: [
                  {
                    name: 'criterionTypeGroup',
                    control_type: 'select',
                    pick_list: 'criterion_type_group',
                    toggle_hint: 'Select from options',
                    hint: 'The criterion type group that these ' \
                      'settings apply to.',
                    toggle_field: {
                      name: 'criterionTypeGroup',
                      label: 'Criterion type group',
                      type: 'string',
                      optional: true,
                      control_type: 'text',
                      toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: KEYWORD, ' \
                        'USER_INTEREST_AND_LIST, VERTICAL, GENDER, ' \
                        'AGE_RANGE, PLACEMENT, PARENT, INCOME_RANGE, ' \
                        'NONE and UNKNOWN.'
                    }
                  },
                  {
                    name: 'targetAll',
                    type: :boolean,
                    control_type: 'checkbox',
                    optional: true,
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Select from options',
                    hint: 'If true, criteria of this type can be used to ' \
                      'modify bidding but will not restrict targeting of ' \
                      'ads. This is equivalent to "Bid only" in the AdWords ' \
                      'user interface. If false, restricts your ads to ' \
                      'showing only for the criteria you have selected ' \
                      'for this CriterionTypeGroup. ',
                    toggle_field: {
                      name: 'targetAll',
                      label: 'Target all',
                      type: 'string',
                      render_input: 'boolean_conversion',
                      parse_output: 'boolean_conversion',
                      control_type: 'text',
                      optional: true,
                      toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: true and false.'
                    }
                  }
                ]
              },
              {
                name: 'trackingUrl',
                label: 'Tracking URL',
                hint: 'The url used for dynamic tracking. Specify "NONE" ' \
                  'to clear existing url.'
              }
            ]
          },
          {
            name: 'advertisingChannelType',
            control_type: 'select',
            sticky: true,
            pick_list: [
              %w[Search SEARCH],
              %w[Display DISPLAY],
              %w[Shopping SHOPPING],
              %w[Multi\ channel MULTI_CHANNEL]
            ],
            toggle_hint: 'Select from options',
            hint: 'The primary serving target for ads within this campaign.',
            toggle_field: {
              name: 'advertisingChannelType',
              label: 'Advertising channel type',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: SEARCH, DISPLAY, SHOPPING, ' \
                'and MULTI_CHANNEL.'
            }
          },
          {
            name: 'advertisingChannelSubType',
            control_type: 'select',
            sticky: true,
            pick_list: 'advertising_channel_subtype',
            toggle_hint: 'Select from options',
            hint: 'Optional refinement of Advertising channel type.',
            toggle_field: {
              name: 'advertisingChannelSubType',
              type: 'string',
              optional: true,
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: SEARCH_MOBILE_APP, ' \
                'DISPLAY_MOBILE_APP, SEARCH_EXPRESS, DISPLAY_EXPRESS, ' \
                'UNIVERSAL_APP_CAMPAIGN, DISPLAY_SMART_CAMPAIGN, ' \
                'SHOPPING_GOAL_OPTIMIZED_ADS, and DISPLAY_GMAIL_AD '
            }
          },
          {
            properties: [
              {
                name: 'targetGoogleSearch',
                label: 'Target Google search',
                type: :boolean,
                control_type: 'checkbox',
                sticky: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Select from options',
                hint: 'Ads will be served with Google.com search results.',
                toggle_field: {
                  name: 'targetGoogleSearch',
                  label: 'Target Google search',
                  type: 'string',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  control_type: 'text',
                  optional: true,
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true and false.'
                }
              },
              {
                name: 'targetSearchNetwork',
                type: :boolean,
                control_type: 'checkbox',
                sticky: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Select from options',
                hint: 'Ads will be served on partner sites in the ' \
                  'Google Search Network',
                toggle_field: {
                  name: 'targetSearchNetwork',
                  label: 'Target search network',
                  type: 'string',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  control_type: 'text',
                  optional: true,
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true and false.'
                }
              },
              {
                name: 'targetContentNetwork',
                type: :boolean,
                control_type: 'checkbox',
                sticky: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Select from options',
                hint: 'Ads will be served on specified placements in ' \
                  'the Google Display Network.',
                toggle_field: {
                  name: 'targetContentNetwork',
                  label: 'Target content network',
                  type: 'string',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  control_type: 'text',
                  optional: true,
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true and false.'
                }
              },
              {
                name: 'targetPartnerSearchNetwork',
                type: :boolean,
                control_type: 'checkbox',
                sticky: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Select from options',
                hint: 'Ads will be served on the Google Partner Network. ' \
                  'This is available to only some specific Google partner ' \
                  'accounts.',
                toggle_field: {
                  name: 'targetPartnerSearchNetwork',
                  label: 'Target partner search network',
                  type: 'string',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  control_type: 'text',
                  optional: true,
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true and false.'
                }
              }
            ],
            type: 'object',
            name: 'networkSetting'
          },
          {
            properties: [
              {
                name: 'biddingStrategyType',
                control_type: 'select',
                sticky: true,
                extends_schema: true,
                pick_list: 'bidding_strategy_type',
                toggle_hint: 'Select from options',
                hint: 'The type of the bidding strategy to be attached.',
                toggle_field: {
                  name: 'biddingStrategyType',
                  label: 'Bidding strategy type',
                  type: 'string',
                  extends_schema: true,
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: MANUAL_CPC, MANUAL_CPM, ' \
                    'PAGE_ONE_PROMOTED, TARGET_SPEND, TARGET_CPA, ' \
                    'TARGET_ROAS, MAXIMIZE_CONVERSIONS, ' \
                    'MAXIMIZE_CONVERSION_VALUE, TARGET_OUTRANK_SHARE, and NONE'
                }
              },
              {
                name: 'biddingStrategyId',
                type: 'integer',
                control_type: 'integer',
                hint: 'Id of the bidding strategy to be associated ' \
                  'with the campaign',
                parse_output: 'integer_conversion'
              },
              {
                type: 'object',
                name: 'biddingScheme',
                properties: bidding_scheme_properties&.
                  concat([{ name: '@xsi:type',
                            label: 'Bidding scheme type',
                            control_type: 'select',
                            pick_list: 'bidding_scheme_type',
                            toggle_hint: 'Select from options',
                            hint: 'Select setting type',
                            toggle_field: {
                              name: '@xsi:type',
                              label: 'Bidding scheme type',
                              type: 'string',
                              control_type: 'text',
                              optional: true,
                              toggle_hint: 'Use custom value',
                              hint: 'Allowed values are: ' \
                                'ManualCpcBiddingScheme, ' \
                                'ManualCpmBiddingScheme, ' \
                                'PageOnePromotedBiddingScheme, ' \
                                'TargetCpaBiddingScheme, ' \
                                'TargetRoasBiddingScheme, ' \
                                'TargetSpendBiddingScheme, ' \
                                'MaximizeConversionValueBiddingScheme, ' \
                                'MaximizeConversionsBiddingScheme and ' \
                                'TargetOutrankShareBiddingScheme.'
                            } }])
              }
            ].compact,
            type: 'object',
            name: 'biddingStrategyConfiguration'
          },
          {
            properties: [
              {
                name: 'doReplace',
                type: :boolean,
                control_type: 'checkbox',
                sticky: true,
                optional: true,
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Select from options',
                hint: 'On Update operation, indicates that the current ' \
                  'parameters should be cleared and replaced with ' \
                  'these parameters.',
                toggle_field: {
                  name: 'doReplace',
                  label: 'Do replace',
                  type: 'string',
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  control_type: 'text',
                  optional: true,
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true and false.'
                }
              },
              {
                name: 'parameters',
                type: 'array',
                of: 'object',
                hint: 'On update, all parameters can be cleared by ' \
                  'providing an empty or null list and setting ' \
                  '<b>Do replace</b> to true.',
                properties: [
                  {
                    name: 'key',
                    sticky: true,
                    hint: 'The parameter key to be mapped.'
                  },
                  {
                    name: 'value',
                    sticky: true,
                    hint: 'The value this parameter should be mapped to. ' \
                      'It should be null if isRemove is true.'
                  },
                  {
                    name: 'isRemove',
                    type: :boolean,
                    control_type: 'checkbox',
                    sticky: true,
                    optional: true,
                    render_input: 'boolean_conversion',
                    parse_output: 'boolean_conversion',
                    toggle_hint: 'Select from options',
                    hint: 'On Update operation, indicates that the parameter ' \
                      'should be removed from the existing parameters. ' \
                      'If set to true, the value field must be null.',
                    toggle_field: {
                      name: 'isRemove',
                      label: 'Is remove',
                      type: 'string',
                      render_input: 'boolean_conversion',
                      parse_output: 'boolean_conversion',
                      control_type: 'text',
                      optional: true,
                      toggle_hint: 'Use custom value',
                      hint: 'Allowed values are: true and false.'
                    }
                  }
                ]
              }
            ],
            type: 'object',
            name: 'urlCustomParameters'
          },
          {
            properties: [
              {
                name: 'vanityPharmaDisplayUrlMode',
                label: 'Vanity pharma display URL mode',
                control_type: 'select',
                pick_list: [
                  %w[Manufacturer\ website\ URL MANUFACTURER_WEBSITE_URL],
                  %w[Website\ description WEBSITE_DESCRIPTION]
                ],
                toggle_hint: 'Select from options',
                hint: 'The display mode for vanity pharma URLs.',
                toggle_field: {
                  name: 'vanityPharmaDisplayUrlMode',
                  label: 'Vanity pharma display URL mode',
                  type: 'string',
                  optional: true,
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: MANUFACTURER_WEBSITE_URL and ' \
                    'WEBSITE_DESCRIPTION'
                }
              },
              {
                name: 'vanityPharmaText',
                control_type: 'select',
                pick_list: 'vanity_pharma_text',
                toggle_hint: 'Select from options',
                hint: 'The text that will be displayed in display URL of ' \
                  'the text ad when website description is the selected ' \
                  'display mode for vanity pharma URLs.',
                toggle_field: {
                  name: 'vanityPharmaText',
                  label: 'Vanity pharma text',
                  type: 'string',
                  optional: true,
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: ' \
                  'PRESCRIPTION_TREATMENT_WEBSITE_EN, ' \
                  'PRESCRIPTION_TREATMENT_WEBSITE_ES, ' \
                  'PRESCRIPTION_DEVICE_WEBSITE_EN, ' \
                  'PRESCRIPTION_DEVICE_WEBSITE_ES, ' \
                  'MEDICAL_DEVICE_WEBSITE_EN, MEDICAL_DEVICE_WEBSITE_ES, ' \
                  'PREVENTATIVE_TREATMENT_WEBSITE_EN, ' \
                  'PREVENTATIVE_TREATMENT_WEBSITE_ES, ' \
                  'PRESCRIPTION_CONTRACEPTION_WEBSITE_EN, ' \
                  'PRESCRIPTION_CONTRACEPTION_WEBSITE_ES, ' \
                  'PRESCRIPTION_VACCINE_WEBSITE_EN, ' \
                  'PRESCRIPTION_VACCINE_WEBSITE_ES, '
                }
              }
            ],
            type: 'object',
            name: 'vanityPharma'
          },
          {
            properties: [
              {
                name: 'biddingStrategyGoalType',
                control_type: 'select',
                pick_list: 'bidding_strategy_goal_type',
                toggle_hint: 'Select from options',
                hint: 'Represents the goal which the bidding strategy of ' \
                  'this app campaign should optimize towards.',
                toggle_field: {
                  name: 'biddingStrategyGoalType',
                  label: 'Bidding strategy goal type',
                  type: 'string',
                  optional: true,
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: ' \
                    'OPTIMIZE_FOR_INSTALL_CONVERSION_VOLUME, ' \
                    'OPTIMIZE_FOR_IN_APP_CONVERSION_VOLUME, ' \
                    'OPTIMIZE_FOR_TOTAL_CONVERSION_VALUE, ' \
                    'OPTIMIZE_FOR_TARGET_IN_APP_CONVERSION, and ' \
                    'OPTIMIZE_FOR_RETURN_ON_ADVERTISING_SPEND'
                }
              },
              {
                name: 'appId',
                hint: 'A string that uniquely identifies a mobile application.'
              },
              {
                name: 'appVendor',
                control_type: 'select',
                pick_list: [
                  %w[Vendor\ unknown VENDOR_UNKNOWN],
                  %w[Vendor\ Apple\ app\ store VENDOR_APPLE_APP_STORE],
                  %w[Vendor\ Google\ market VENDOR_GOOGLE_MARKET]
                ],
                toggle_hint: 'Select from options',
                hint: 'The vendor, i.e. application store that distributes ' \
                  'this specific app.',
                toggle_field: {
                  name: 'appVendor',
                  label: 'App vendor',
                  type: 'string',
                  optional: true,
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: VENDOR_UNKNOWN, ' \
                    'VENDOR_APPLE_APP_STORE and VENDOR_GOOGLE_MARKET'
                }
              }
            ],
            type: 'object',
            hint: 'Stores information specific to Universal App Campaigns.',
            name: 'universalAppCampaignInfo'
          },
          {
            name: 'trackingUrlTemplate',
            sticky: true,
            hint: 'URL template for constructing a tracking URL. <br> ' \
              'Example: https://www.trackingtemplate.foo/?url={lpurl}&id=5 '
          },
          {
            name: 'finalUrlSuffix',
            label: 'Final URL suffix',
            hint: 'URL template for appending params to Final URL. <br> ' \
              'Example: param1=value1&field2=value2'
          },
          {
            name: 'campaignGroupId',
            control_type: 'integer',
            type: 'integer',
            hint: 'ID of the campaign group this campaign belongs to.'
          },
          {
            properties: [
              { name: 'budgetId' }
            ],
            type: 'object',
            hint: 'Current base budget of campaign',
            name: 'budget'
          }
        ].compact
      end
    },
    adgroups: {
      fields: lambda do |_object_definitions|
        [
          {
            parse_output: 'integer_conversion',
            type: 'integer',
            name: 'id'
          },
          {
            parse_output: 'integer_conversion',
            type: 'integer',
            name: 'campaignId'
          },
          { name: 'campaignName' },
          { name: 'name' },
          { name: 'status' },
          {
            name: 'settings',
            type: 'array',
            of: 'object',
            properties: [
              { name: 'Setting_Type' },
              { name: 'optIn', type: 'boolean' },
              {
                name: 'details',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'criterionTypeGroup' },
                  { name: 'targetAll', type: 'boolean' }
                ]
              }
            ]
          },
          {
            name: 'labels',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'id',
                type: 'integer',
                parse_output: 'integer_conversion'
              },
              { name: 'name' },
              { name: 'status' },
              { name: 'Label_Type', label: 'Label type' },
              {
                name: 'attribute',
                type: 'object',
                properties: [
                  {
                    name: 'LabelAttribute_Type',
                    label: 'Label attribute type'
                  },
                  { name: 'backgroundColor' },
                  { name: 'description' }
                ]
              }
            ]
          },
          {
            properties: [
              { name: 'biddingStrategyType' },
              {
                name: 'biddingStrategyId',
                type: 'integer',
                parse_output: 'integer_conversion'
              },
              { name: 'biddingStrategyName' },
              { name: 'biddingStrategySource' },
              { name: 'targetRoasOverride', type: 'number' },
              {
                name: 'bids',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'Bids_Type', label: 'Bids type' },
                  { name: 'bid', type: 'number' },
                  { name: 'bidSource' },
                  { name: 'cpcBidSource', label: 'CPC bid source' },
                  { name: 'cpmBidSource', label: 'CPM bid source' }
                ]
              },
              {
                properties: [
                  {
                    label: 'Bidding scheme type',
                    name: 'BiddingScheme_Type'
                  },
                  { name: 'targetRoas', type: 'number' },
                  { name: 'strategyGoal' },
                  { name: 'bidCeiling', type: 'number' },
                  { name: 'bidModifier' },
                  { name: 'bidChangesForRaisesOnly', type: 'boolean' },
                  { name: 'raiseBidWhenBudgetConstrained', type: 'boolean' },
                  { name: 'raiseBidWhenLowQualityScore', type: 'boolean' },
                  { name: 'targetCpa', label: 'Target CPA', type: 'number' },
                  {
                    name: 'maxCpcBidCeiling',
                    label: 'Max CPC bid ceiling',
                    type: 'number'
                  },
                  {
                    name: 'maxCpcBidFloor',
                    label: 'Max CPC bid floor',
                    type: 'number'
                  },
                  { name: 'targetOutrankShare', type: 'integer' },
                  { name: 'competitorDomain' },
                  { name: 'bidFloor', type: 'number' },
                  { name: 'spendTarget', type: 'number' },
                  {
                    label: 'Enhanced CPC enabled',
                    type: 'boolean',
                    name: 'enhancedCpcEnabled'
                  },
                  {
                    label: 'Viewable CPM enabled',
                    type: 'boolean',
                    name: 'viewableCpmEnabled'
                  }
                ],
                type: 'object',
                name: 'biddingScheme'
              }
            ],
            type: 'object',
            name: 'biddingStrategyConfiguration'
          },
          {
            parse_output: 'integer_conversion',
            type: 'integer',
            name: 'baseCampaignId'
          },
          {
            properties: [
              {
                type: 'boolean',
                name: 'doReplace'
              },
              {
                name: 'parameters',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  { name: 'value' },
                  { name: 'isRemove', type: 'boolean' }
                ]
              }
            ],
            type: 'object',
            name: 'urlCustomParameters'
          },
          { name: 'baseAdGroupId' },
          { name: 'contentBidCriterionTypeGroup' },
          { name: 'adGroupType' },
          { name: 'trackingUrlTemplate' },
          { name: 'finalUrlSuffix', label: 'Final URL suffix' },
          { name: 'adGroupAdRotationMode' }
        ]
      end
    },
    ads: {
      fields: lambda do |_object_definitions|
        [
          {
            parse_output: 'integer_conversion',
            type: 'integer',
            name: 'id'
          },
          { name: 'url' },
          { name: 'displayUrl' },
          {
            type: 'array',
            label: 'Final URLs',
            name: 'finalUrls'
          },
          {
            name: 'finalMobileUrls',
            type: 'array',
            label: 'Final mobile URLs'
          },
          {
            name: 'finalAppUrls',
            label: 'Final app URLs',
            type: 'array',
            of: 'object',
            properties: [
              { name: 'url' },
              { name: 'osType' }
            ]
          },
          { name: 'trackingUrlTemplate' },
          { name: 'finalUrlSuffix', label: 'Final URL suffix' },
          {
            properties: [
              {
                type: 'boolean',
                name: 'doReplace'
              },
              {
                name: 'parameters',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  { name: 'value' },
                  { name: 'isRemove', type: 'boolean' }
                ]
              }
            ],
            type: 'object',
            name: 'urlCustomParameters'
          },
          {
            properties: [
              { name: 'urlId', label: 'URL ID' },
              { name: 'trackingUrlTemplate' },
              {
                name: 'finalUrls',
                label: 'Final URLs',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'urls', type: 'array', label: 'URLs' }
                ]
              },
              {
                name: 'finalMobileUrls',
                label: 'Final mobile URLs',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'urls', type: 'array', label: 'URLs' }
                ]
              }
            ],
            type: 'array',
            of: 'object',
            name: 'urlData'
          },
          { name: 'automated', type: 'boolean' },
          { name: 'type' },
          {
            parse_output: 'integer_conversion',
            type: 'integer',
            name: 'devicePreference'
          },
          { name: 'systemManagedEntitySource' },
          { name: 'Ad_Type' },
          { name: 'countryCode' },
          { name: 'phoneNumber' },
          { name: 'businessName' },
          { name: 'description1' },
          { name: 'description2' },
          { name: 'callTracked', type: 'boolean' },
          { name: 'disableCallConversion', type: 'boolean' },
          {
            parse_output: 'integer_conversion',
            type: 'integer',
            name: 'conversionTypeId'
          },
          { name: 'phoneNumberVerificationUrl' },
          { name: 'name' },
          { name: 'deprecatedAdType' },
          { name: 'description' },
          { name: 'description2' },
          { name: 'headlinePart1' },
          { name: 'headlinePart2' },
          { name: 'headlinePart3' },
          { name: 'path1' },
          { name: 'path2' },
          {
            name: 'teaser',
            type: 'object',
            properties: [
              { name: 'headline' },
              { name: 'description' },
              { name: 'businessName' },
              {
                name: 'logoImage',
                type: 'object',
                properties: [
                  { name: 'mediaId', type: 'integer' },
                  { name: 'type' },
                  { name: 'referenceId', type: 'integer' },
                  {
                    name: 'dimensions',
                    type: 'array',
                    of: 'object',
                    properties: [
                      { name: 'key' },
                      {
                        name: 'value',
                        type: 'object',
                        properties: [
                          { name: 'width' },
                          { name: 'height' }
                        ]
                      }
                    ]
                  },
                  {
                    name: 'urls',
                    label: 'URLs',
                    type: 'array',
                    of: 'object',
                    properties: [
                      { name: 'key' },
                      { name: 'value' }
                    ]
                  },
                  { name: 'mimeType' },
                  { name: 'sourceUrl' },
                  { name: 'name' },
                  { name: 'fileSize', type: 'integer' },
                  { name: 'creationTime' },
                  { name: 'Media_Type' },
                  { name: 'data' }
                ]
              }
            ]
          },
          {
            name: 'headerImage',
            type: 'object',
            properties: [
              { name: 'mediaId', type: 'integer' },
              { name: 'type' },
              { name: 'referenceId', type: 'integer' },
              {
                name: 'dimensions',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  {
                    name: 'value',
                    type: 'object',
                    properties: [
                      { name: 'width' },
                      { name: 'height' }
                    ]
                  }
                ]
              },
              {
                name: 'urls',
                label: 'URLs',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  { name: 'value' }
                ]
              },
              { name: 'mimeType' },
              { name: 'sourceUrl' },
              { name: 'name' },
              { name: 'fileSize', type: 'integer' },
              { name: 'creationTime' },
              { name: 'Media_Type' },
              { name: 'data' }
            ]
          },
          {
            name: 'marketingImage',
            type: 'object',
            properties: [
              { name: 'mediaId', type: 'integer' },
              { name: 'type' },
              { name: 'referenceId', type: 'integer' },
              {
                name: 'dimensions',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  {
                    name: 'value',
                    type: 'object',
                    properties: [
                      { name: 'width' },
                      { name: 'height' }
                    ]
                  }
                ]
              },
              {
                name: 'urls',
                label: 'URLs',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  { name: 'value' }
                ]
              },
              { name: 'mimeType' },
              { name: 'sourceUrl' },
              { name: 'name' },
              { name: 'fileSize', type: 'integer' },
              { name: 'creationTime' },
              { name: 'Media_Type' },
              { name: 'data' }
            ]
          },
          { name: 'marketingImageHeadline' },
          { name: 'marketingImageDescription' },
          {
            name: 'marketingImageDisplayCallToAction',
            type: 'object',
            properties: [
              { name: 'text' },
              { name: 'textColor' },
              { name: 'urlId' }
            ]
          },
          {
            name: 'productImages',
            type: 'array',
            of: 'object',
            properties: [
              { name: 'description' },
              {
                name: 'productImage',
                type: 'object',
                properties: [
                  { name: 'mediaId', type: 'integer' },
                  { name: 'type' },
                  { name: 'referenceId', type: 'integer' },
                  {
                    name: 'dimensions',
                    type: 'array',
                    of: 'object',
                    properties: [
                      { name: 'key' },
                      {
                        name: 'value',
                        type: 'object',
                        properties: [
                          { name: 'width' },
                          { name: 'height' }
                        ]
                      }
                    ]
                  },
                  {
                    name: 'urls',
                    label: 'URLs',
                    type: 'array',
                    of: 'object',
                    properties: [
                      { name: 'key' },
                      { name: 'value' }
                    ]
                  },
                  { name: 'mimeType' },
                  { name: 'sourceUrl' },
                  { name: 'name' },
                  { name: 'fileSize', type: 'integer' },
                  { name: 'creationTime' },
                  { name: 'Media_Type' },
                  { name: 'data' }
                ]
              },
              {
                name: 'displayCallToAction',
                type: 'object',
                properties: [
                  { name: 'text' },
                  { name: 'textColor' },
                  { name: 'urlId' }
                ]
              }
            ]
          },
          {
            name: 'productVideoList',
            type: 'array',
            of: 'object',
            properties: [
              { name: 'mediaId', type: 'integer' },
              { name: 'type' },
              { name: 'referenceId', type: 'integer' },
              {
                name: 'dimensions',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  {
                    name: 'value',
                    type: 'object',
                    properties: [
                      { name: 'width' },
                      { name: 'height' }
                    ]
                  }
                ]
              },
              {
                name: 'urls',
                label: 'URLs',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  { name: 'value' }
                ]
              },
              { name: 'mimeType' },
              { name: 'sourceUrl' },
              { name: 'name' },
              { name: 'fileSize', type: 'integer' },
              { name: 'creationTime' },
              { name: 'Media_Type' },
              { name: 'durationMillis', type: 'integer' },
              { name: 'streamingUrl' },
              { name: 'readyToPlayOnTheWeb', type: 'boolean' },
              { name: 'industryStandardCommercialIdentifier' },
              { name: 'advertisingId' },
              { name: 'youTubeVideoIdString', label: 'YouTube video ID string' }
            ]
          },
          { name: 'adToCopyImageFrom', type: 'integer' },
          {
            name: 'image',
            type: 'object',
            properties: [
              { name: 'mediaId', type: 'integer' },
              { name: 'type' },
              { name: 'referenceId', type: 'integer' },
              {
                name: 'dimensions',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  {
                    name: 'value',
                    type: 'object',
                    properties: [
                      { name: 'width' },
                      { name: 'height' }
                    ]
                  }
                ]
              },
              {
                name: 'urls',
                label: 'URLs',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  { name: 'value' }
                ]
              },
              { name: 'mimeType' },
              { name: 'sourceUrl' },
              { name: 'name' },
              { name: 'fileSize', type: 'integer' },
              { name: 'creationTime' },
              { name: 'Media_Type' },
              { name: 'data' }
            ]
          },
          { name: 'businessName' },
          { name: 'mainColor' },
          { name: 'accentColor' },
          { name: 'allowFlexibleColor' },
          { name: 'callToActionText' },
          { name: 'dynamicSettingsPricePrefix' },
          { name: 'dynamicSettingsPromoText' },
          { name: 'formatSetting' },
          {
            name: 'marketingImages',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          {
            name: 'squareMarketingImages',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          {
            name: 'logoImages',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          {
            name: 'landscapeLogoImages',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          {
            name: 'headlines',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          {
            name: 'descriptions',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          {
            name: 'images',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          {
            name: 'videos',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          {
            name: 'html5MediaBundles',
            label: 'HTML5 media bundles',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          {
            name: 'mandatoryAdText',
            type: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          {
            name: 'youTubeVideos',
            label: 'YouTube videos',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          {
            name: 'longHeadline',
            type: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          {
            name: 'marketingImage',
            type: 'object',
            properties: [
              { name: 'mediaId', type: 'integer' },
              { name: 'type' },
              { name: 'referenceId', type: 'integer' },
              {
                name: 'dimensions',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  {
                    name: 'value',
                    type: 'object',
                    properties: [
                      { name: 'width' },
                      { name: 'height' }
                    ]
                  }
                ]
              },
              {
                name: 'urls',
                label: 'URLs',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  { name: 'value' }
                ]
              },
              { name: 'mimeType' },
              { name: 'sourceUrl' },
              { name: 'name' },
              { name: 'fileSize', type: 'integer' },
              { name: 'creationTime' },
              { name: 'Media_Type' },
              { name: 'data' }
            ]
          },
          {
            name: 'squareMarketingImage',
            type: 'object',
            properties: [
              { name: 'mediaId', type: 'integer' },
              { name: 'type' },
              { name: 'referenceId', type: 'integer' },
              {
                name: 'dimensions',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  {
                    name: 'value',
                    type: 'object',
                    properties: [
                      { name: 'width' },
                      { name: 'height' }
                    ]
                  }
                ]
              },
              {
                name: 'urls',
                label: 'URLs',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  { name: 'value' }
                ]
              },
              { name: 'mimeType' },
              { name: 'sourceUrl' },
              { name: 'name' },
              { name: 'fileSize', type: 'integer' },
              { name: 'creationTime' },
              { name: 'Media_Type' },
              { name: 'data' }
            ]
          },
          {
            name: 'logoImage',
            type: 'object',
            properties: [
              { name: 'mediaId', type: 'integer' },
              { name: 'type' },
              { name: 'referenceId', type: 'integer' },
              {
                name: 'dimensions',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  {
                    name: 'value',
                    type: 'object',
                    properties: [
                      { name: 'width' },
                      { name: 'height' }
                    ]
                  }
                ]
              },
              {
                name: 'urls',
                label: 'URLs',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  { name: 'value' }
                ]
              },
              { name: 'mimeType' },
              { name: 'sourceUrl' },
              { name: 'name' },
              { name: 'fileSize', type: 'integer' },
              { name: 'creationTime' },
              { name: 'Media_Type' },
              { name: 'data' }
            ]
          },
          { name: 'shortHeadline' },
          { name: 'longHeadline' },
          {
            name: 'dynamicDisplayAdSettings',
            type: 'object',
            properties: [
              { name: 'pricePrefix' },
              { name: 'promoText' },
              {
                name: 'landscapeLogoImage',
                type: 'object',
                properties: [
                  {
                    name: 'asset',
                    type: 'object',
                    properties: [
                      { name: 'assetId' },
                      { name: 'assetName' },
                      { name: 'assetSubtype' },
                      { name: 'assetStatus' },
                      { name: 'Asset_Type' }
                    ]
                  },
                  {
                    name: 'assetPolicySummaryInfo',
                    type: 'object',
                    properties: [
                      { name: 'reviewState' },
                      { name: 'denormalizedStatus' },
                      { name: 'combinedApprovalStatus' },
                      { name: 'PolicySummaryInfo_Type' }
                    ]
                  },
                  { name: 'pinnedField' },
                  { name: 'assetPerformanceLabel' }
                ]
              }
            ]
          },
          {
            name: 'dimensions',
            type: 'object',
            properties: [
              { name: 'key' },
              {
                name: 'value',
                type: 'object',
                properties: [
                  { name: 'width' },
                  { name: 'height' }
                ]
              }
            ]
          },
          { name: 'snippet' },
          { name: 'impressionBeaconUrl' },
          { name: 'adDuration', type: 'integer' },
          { name: 'certifiedVendorFormatId', type: 'integer' },
          { name: 'sourceUrl' },
          { name: 'richMediaAdType' },
          { name: 'adAttributes', type: 'array' },
          { name: 'headline' },
          {
            name: 'collapsedImage',
            type: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          {
            name: 'expandedImage',
            type: 'object',
            properties: [
              {
                name: 'asset',
                type: 'object',
                properties: [
                  { name: 'assetId' },
                  { name: 'assetName' },
                  { name: 'assetSubtype' },
                  { name: 'assetStatus' },
                  { name: 'Asset_Type' }
                ]
              },
              {
                name: 'assetPolicySummaryInfo',
                type: 'object',
                properties: [
                  { name: 'reviewState' },
                  { name: 'denormalizedStatus' },
                  { name: 'combinedApprovalStatus' },
                  { name: 'PolicySummaryInfo_Type' }
                ]
              },
              { name: 'pinnedField' },
              { name: 'assetPerformanceLabel' }
            ]
          },
          { name: 'templateId', type: 'integer' },
          {
            name: 'adUnionId',
            type: 'object',
            properties: [
              { name: 'id' },
              { name: 'AdUnionId_Type' }
            ]
          },
          {
            name: 'templateElements',
            type: 'array',
            of: 'object',
            properties: [
              { name: 'uniqueName' },
              {
                name: 'fields',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'name' },
                  { name: 'type' },
                  { name: 'fieldText' },
                  {
                    name: 'fieldMedia',
                    type: 'object',
                    properties: [
                      { name: 'mediaId', type: 'integer' },
                      { name: 'type' },
                      { name: 'referenceId', type: 'integer' },
                      {
                        name: 'dimensions',
                        type: 'array',
                        of: 'object',
                        properties: [
                          { name: 'key' },
                          {
                            name: 'value',
                            type: 'object',
                            properties: [
                              { name: 'width' },
                              { name: 'height' }
                            ]
                          }
                        ]
                      },
                      {
                        name: 'urls',
                        label: 'URLs',
                        type: 'array',
                        of: 'object',
                        properties: [
                          { name: 'key' },
                          { name: 'value' }
                        ]
                      },
                      { name: 'mimeType' },
                      { name: 'sourceUrl' },
                      { name: 'name' },
                      { name: 'fileSize', type: 'integer' },
                      { name: 'creationTime' },
                      { name: 'Media_Type' },
                      { name: 'data' },
                      { name: 'durationMillis', type: 'integer' },
                      { name: 'streamingUrl' },
                      { name: 'readyToPlayOnTheWeb', type: 'boolean' },
                      { name: 'industryStandardCommercialIdentifier' },
                      { name: 'advertisingId' },
                      {
                        name: 'youTubeVideoIdString',
                        label: 'YouTube video ID string'
                      },
                      { name: 'mediaBundleUrl' },
                      { name: 'entryPoint' }
                    ]
                  }
                ]
              }
            ]
          },
          {
            name: 'adAsImage',
            type: 'object',
            properties: [
              { name: 'mediaId', type: 'integer' },
              { name: 'type' },
              { name: 'referenceId', type: 'integer' },
              {
                name: 'dimensions',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  {
                    name: 'value',
                    type: 'object',
                    properties: [
                      { name: 'width' },
                      { name: 'height' }
                    ]
                  }
                ]
              },
              {
                name: 'urls',
                label: 'URLs',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'key' },
                  { name: 'value' }
                ]
              },
              { name: 'mimeType' },
              { name: 'sourceUrl' },
              { name: 'name' },
              { name: 'fileSize', type: 'integer' },
              { name: 'creationTime' },
              { name: 'Media_Type' },
              { name: 'data' }
            ]
          },
          {
            name: 'dimensions',
            type: 'object',
            properties: [
              { name: 'key' },
              {
                name: 'value',
                type: 'object',
                properties: [
                  { name: 'width' },
                  { name: 'height' }
                ]
              }
            ]
          },
          { name: 'duration', type: 'integer' },
          { name: 'originAdId', type: 'integer' }
        ]
      end
    },
    create_user_list: {
      fields: lambda do |_object_definitions, config_fields|
        list_type = config_fields.dig('list_type') || 'default'
        default = call('user_list', '').
                  only('name', 'description', 'status', 'integrationCode', 'closingReason', 'client_customer_id',
                       'accountUserListStatus', 'membershipLifeSpan', 'isEligibleForSearch', 'list_type')
        case list_type
        when 'default'
          default
        when 'CrmBasedUserList'
          default.concat(call('user_list', '').only('appId', 'uploadKeyType', 'dataSourceType').required('appId'))
        when 'LogicalUserList'
          default.concat(call('user_list', '').only('rules').required('rules'))
        when 'BasicUserList'
          default.concat(call('user_list', '').only('conversionTypes').required('conversionTypes'))
        when 'RuleBasedUserList'
          default.concat(call('user_list', '').only('prepopulationStatus'))
        when 'CombinedRuleUserList'
          default.concat(call('user_list', '').only('prepopulationStatus', 'leftOperand', 'rightOperand', 'ruleOperator').required('leftOperand', 'rightOperand', 'ruleOperator'))
        when 'DateSpecificRuleUserList'
          default.concat(call('user_list', '').only('prepopulationStatus', 'rule', 'startDate', 'endDate').required('rule', 'startDate', 'endDate'))
        when 'ExpressionRuleUserList'
          default.concat(call('user_list', '').only('prepopulationStatus', 'rule').required('rule'))
        when 'SimilarUserList'
          default.concat(call('user_list', '').only('seedUserListId').required('seedUserListId'))
        else
          default
        end
      end
    },
    update_user_list: {
      fields: lambda do |_object_definitions, config_fields|
        list_type = config_fields.dig('list_type') || 'default'
        default = call('user_list', '').
                  only('id', 'name', 'description', 'status', 'integrationCode', 'closingReason', 'client_customer_id',
                       'accountUserListStatus', 'membershipLifeSpan', 'isEligibleForSearch', 'list_type').required('id')
        case list_type
        when 'default'
          default
        when 'CrmBasedUserList'
          default.concat(call('user_list', '').only('appId'))
        when 'LogicalUserList'
          default.concat(call('user_list', '').only('rules'))
        when 'BasicUserList'
          default.concat(call('user_list', '').only('conversionTypes'))
        when 'RuleBasedUserList'
          default.concat(call('user_list', '').only('prepopulationStatus'))
        when 'CombinedRuleUserList'
          default.concat(call('user_list', '').only('prepopulationStatus', 'leftOperand', 'rightOperand', 'ruleOperator'))
        when 'DateSpecificRuleUserList'
          default.concat(call('user_list', '').only('prepopulationStatus', 'rule', 'startDate', 'endDate'))
        when 'ExpressionRuleUserList'
          default.concat(call('user_list', '').only('prepopulationStatus', 'rule'))
        when 'SimilarUserList'
          default.concat(call('user_list', '').only('seedUserListId').required('seedUserListId'))
        else
          default
        end
      end
    },
    add_members_to_user_list: {
      fields: lambda do |_object_definitions|
        [
          {
            name: 'client_customer_id',
            hint: 'Customer ID of the target Google Ads account, typically ' \
              'in the form of "123-456-7890". <b>It must be the advertising ' \
              'account being managed by your manager account.</b>',
            optional: false
          },
          { name: 'userListId', optional: false, hint: 'The ID of the user list to add members to.' },
          { name: 'membersList', type: 'array', of: 'object', optional: false, properties: [
            { name: 'hashedEmail', sticky: true, label: 'Email address', control_type: 'email' },
            { name: 'mobileId', sticky: true, hint: 'Mobile device ID (advertising ID/IDFA).' },
            { name: 'hashedPhoneNumber', sticky: true, label: 'Phone number', control_type: 'phone' },
            { name: 'userId', sticky: true, hint: 'Advertiser generated and assigned user ID. Accessible to whitelisted clients only.' },
            { name: 'addressInfo', label: 'Address', sticky: true, type: 'object', properties: [
              { name: 'hashedFirstName', optional: false, label: 'First name' },
              { name: 'hashedLastName', optional: false, label: 'Last name' },
              { name: 'zipCode', optional: false },
              { name: 'countryCode', label: 'Country', optional: false, control_type: 'select',
                pick_list: 'country_codes',
                toggle_hint: 'Select from options',
                toggle_field: {
                  name: 'countryCode', label: 'Country code', type: 'string', optional: false,
                  control_type: 'text', toggle_hint: 'Use custom value',
                  hint: "2-letter country code in ISO-3166-1 alpha-2 of the member's address.<br>" \
                   "Click <a href='https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2' target='_blank'>here</a> to learn more."
                } }
            ] }
          ] }
        ]
      end
    },
    user_list_output: {
      fields: lambda do |_object_definitions|
        call('user_list', '').ignored('list_type', 'client_customer_id')
      end
    },
    add_offline_conversion: {
      fields: lambda do |_object_definitions|
        [
          {
            name: 'client_customer_id',
            hint: 'Customer ID of the target Google Ads account, typically ' \
              'in the form of "123-456-7890". <b>It must be the advertising ' \
              'account being managed by your manager account.</b>',
            optional: false
          },
          { name: 'googleClickId', optional: false, hint: 'The google click ID associated with this conversion, ' \
            'as captured from the landing page.<br>If your account has auto-tagging turned on, the google click ' \
            'ID can be obtained from a query parameter called <b>gclid</b>.' },
          { name: 'conversionName', optional: false, hint: 'The type associated with this conversion.<br>' \
            'It is valid to report multiple conversions for the same google click ID, since visitors may ' \
            'trigger multiple conversions for a click. These conversions names are generated in the front end by advertisers.' },
          { name: 'conversionTime', type: 'date_time', control_type: 'date_time', optional: false,
            parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp',
            hint: 'The time that this conversion occurred at.<br>This has to be after the click time. ' \
            'A time in the future is not allowed.<br><b>Timezone</b> field is required when this field is used.' },
          { name: 'conversionValue', type: 'number', control_type: 'number', sticky: true,
            hint: 'This conversions value for the advertiser.' },
          { name: 'externalAttributionCredit', type: 'number', control_type: 'number', sticky: true,
            hint: 'This field can only be set for conversions actions which use external attribution. ' \
            'It represents the fraction of the conversion that is attributed to each AdWords click. ' \
            'Its value must be greater than 0 and less than or equal to 1.' },
          { name: 'externalAttributionModel', sticky: true,
            hint: 'This field can only be set for conversions actions which use external attribution. ' \
            'It specifies the attribution model name.' },
          { name: 'conversionCurrencyCode', label: 'Conversion currency', sticky: true, control_type: 'select',
            hint: 'The currency that the advertiser associates with the conversion value.',
            pick_list: 'currency_codes',
            toggle_hint: 'Select from options',
            toggle_field: {
              name: 'conversionCurrencyCode', label: 'Conversion currency code', type: 'string', optional: true,
              control_type: 'text', toggle_hint: 'Use custom value',
              hint: 'Please enter the ISO 4217 3-character currency code. ' \
              "Click <a href='https://en.wikipedia.org/wiki/ISO_4217' target='_blank'>here</a> to learn more."
            } },
          { name: 'timezone', label: 'Timezone', optional: false, control_type: 'select',
            pick_list: 'timezones',
            toggle_hint: 'Select from options',
            toggle_field: {
              name: 'timezone', label: 'Timezone', type: 'string', optional: false,
              control_type: 'text', toggle_hint: 'Use custom value',
              hint: 'Please enter the timezone. ' \
              "Click <a href='https://developers.google.com/adwords/api/docs/appendix/codes-formats' target='_blank'>here</a> to learn more."
            } }
        ]
      end
    }
  },

  test: lambda { |connection|
    post('mcm/v201809/ManagedCustomerService').
      payload(
        'soapenv:Header': [{
          'ns1:RequestHeader': [{
            '@xmlns:ns1': 'https://adwords.google.com/api/adwords/mcm/v201809',
            '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
            '@soapenv:mustUnderstand': '0',
            'ns1:clientCustomerId': [{
              "content!": connection['manager_account_customer_id']
            }],
            'ns1:developerToken': [{
              "content!": connection['developer_token']
            }],
            'ns1:userAgent': [{
              "content!": 'Workato'
            }],
            'ns1:validateOnly': [{
              "content!": false
            }],
            'ns1:partialFailure': [{
              "content!": false
            }]
          }]
        }],
        'soapenv:Body': [{
          'get': [{
            '@xmlns': 'https://adwords.google.com/api/adwords/mcm/v201809',
            'serviceSelector': [{
              'fields': [{
                "content!": 'CustomerId'
              }]
            }]
          }]
        }]
      ).
      headers('clientCustomerId': connection['manager_account_customer_id'],
              'Content-Type': 'text/xml').
      format_xml('soapenv:Envelope',
                 '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                 '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                 '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                 strip_response_namespaces: true).
      after_error_response(/.*/) do |_code, body, _header, message|
        error("#{message}: #{body}")
      end&.dig('Envelope', 0, 'Body')
  },

  actions: {
    get_accounts_by_customer_id: {
      title: 'Get customer accounts',
      subtitle: 'Get customer accounts',
      description: "Get customer <span class='provider'>accounts</span> in " \
        'Google Ads',
      help: {
        body: 'Retrieve information about customer accounts associated ' \
          'with a client customer ID in Google Ads. Customer accounts are ' \
          'split into manager and advertising account; both are returned ' \
          'in this action. This action uses the <b>get</b> method in the ' \
          'Managed Customer Service. Currently only supports <b>fields</b> ' \
          'in the <b>selector</b>. Learn more by clicking the link below.',
        learn_more_text: 'Managed Customer Service',
        learn_more_url: 'https://developers.google.com/adwords/api/docs/' \
          'reference/v201809/ManagedCustomerService'
      },
      input_fields: lambda { |_object_definitions|
        [
          {
            name: 'user_agent', optional: false,
            hint: 'Set this as your application name and version in order ' \
              'to help AdWords find your requests when diagnosing a problem.'
          },
          {
            name: 'fields', control_type: 'multiselect', delimiter: ',',
            optional: false,
            pick_list: 'account_selector_fields',
            toggle_hint: 'Select from options',
            hint: 'The fields to retrieve from your customer accounts.',
            toggle_field: {
              name: 'fields',
              label: 'Fields',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Enter field names separated by comma. Click ' \
              "<a href='https://developers.google.com/adwords/api/" \
              "docs/appendix/selectorfields#v201809-ManagedCustomerService' " \
              "target='_blank'>here</a> for more details."
            }
          },
          {
            name: 'validate_only',
            sticky: true,
            type: :boolean,
            optional: true,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'checkbox',
            hint: 'Use this field to use the action to validate ' \
              'user-provided data. Default is false.',
            toggle_hint: 'Select from options',
            toggle_field: {
              name: 'validate_only',
              label: 'Validate only',
              type: 'string',
              optional: true,
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true or false.'
            }
          },
          {
            name: 'partial_failure',
            sticky: true,
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            type: :boolean, optional: true,
            hint: 'All operations that are free of errors are performed ' \
              'and failing operations have their errors returned. This ' \
              'header is ignored for non-mutate operations. ' \
              'Default value is false.',
            toggle_hint: 'Select from options',
            toggle_field: {
              name: 'partial_failure',
              label: 'Partial failure',
              type: 'string',
              optional: true,
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: true or false.'
            }
          }
        ]
      },
      execute: lambda { |connection, input|
        response = post('mcm/v201809/ManagedCustomerService').
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/mcm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": connection['manager_account_customer_id']
                         }],
                         'ns1:developerToken': [{
                           "content!": connection['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": input['user_agent'] || 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": input['validate_only'] || false
                         }],
                         'ns1:partialFailure': [{
                           "content!": input['partial_failure'] || false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'get': [{
                         '@xmlns': 'https://adwords.google.com/api/adwords/mcm/v201809',
                         'serviceSelector': [call('build_account_fields_xml',
                                                  input)]
                       }]
                     }]
                   ).
                   headers('clientCustomerId':
                             connection['manager_account_customer_id'],
                           'Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}
        accounts = response&.dig('getResponse', 0, 'rval', 0, 'entries')&.
        map do |accountinfo|
          call('parse_xml_to_hash',
               'xml' => accountinfo,
               'array_fields' => ['accountLabels']) || {}
        end

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
              'customerId': '6298421071',
              'name': 'Mortgages',
              'accountLabels': [],
              'canManageClients': false,
              'currencyCode': 'USD',
              'dateTimeZone': 'America/Los_Angeles',
              'testAccount': false
            }
          ]
        }
      }
    },
    get_campaigns: {
      title: 'Get campaigns',
      subtitle: 'Get campaigns',
      description: "Get <span class='provider'>campaigns</span> in " \
        'Google Ads',
      help: {
        body: 'Retrieve information about a campaign associated ' \
          'with a client customer ID in Google Ads. Use the ' \
          '<b>Campaign ID</b> or <b>Campaign name</b> field to retrieve ' \
          'information of a specific campaign. ' \
          'Leave it empty to search for all records. <br> ' \
          'Returned list is limited to 500 records.',
        learn_more_text: 'Campaign Service',
        learn_more_url: 'https://developers.google.com/adwords/api/docs/' \
          'reference/v201809/CampaignService'
      },
      input_fields: lambda { |_object_definitions|
        [
          {
            name: 'client_customer_id',
            hint: 'Customer ID of the target Google Ads account, typically ' \
              'in the form of "123-456-7890". <b>It must be the advertising ' \
              'account being managed by your manager account.</b>',
            optional: false
          },
          {
            name: 'fields', control_type: 'multiselect', delimiter: ',',
            optional: true, sticky: true,
            pick_list: 'campaign_fields',
            toggle_hint: 'Select from options',
            hint: 'The list of fields to include in the result. All fields will be returned by default.',
            toggle_field: {
              name: 'fields', label: 'Field names', type: 'string',
              control_type: 'text', optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Enter field names separated by comma. Click <a href=' \
                "'https://developers.google.com/adwords/api/docs/appendix/selectorfields#v201809' " \
                "target='_blank'>here</a> for more details."
            }
          },
          {
            name: 'predicates', list_mode: 'static', sticky: true,
            type: :array, optional: true,
            properties: [
              {
                name: 'field', optional: false, control_type: 'select',
                pick_list: 'campaign_fields_query',
                toggle_hint: 'Select from options',
                hint: 'The field to filter on.',
                toggle_field: {
                  name: 'field', label: 'Field name', type: 'string',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: "Enter field name. Click <a href='https://developers.google.com/adwords/api/" \
                    "docs/appendix/selectorfields#v201809' " \
                    "target='_blank'>here</a> for more details."
                }
              },
              {
                name: 'operator', optional: false, control_type: 'select',
                pick_list: 'predicate_operators',
                toggle_hint: 'Select from options',
                hint: 'The operator used to filter on. To prevent' \
                  ' calculation accuracy issues, fields whose data' \
                  ' type is <b>Double</b> can be used only with the' \
                  ' following operators in predicates: <b>LESS_THAN</b>' \
                  ' or <b>GREATER_THAN</b>.',
                toggle_field: {
                  name: 'operator', label: 'Operator', type: 'string',
                  control_type: 'text', toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: EQUALS, NOT_EQUALS, IN, NOT_IN, ' \
                    'GREATER_THAN, GREATER_THAN_EQUALS, LESS_THAN, ' \
                    'LESS_THAN_EQUALS, STARTS_WITH, STARTS_WITH_IGNORE_CASE, ' \
                    'CONTAINS, CONTAINS_IGNORE_CASE, DOES_NOT_CONTAIN, ' \
                    'DOES_NOT_CONTAIN_IGNORE_CASE, CONTAINS_ANY, ' \
                    'CONTAINS_ALL, or CONTAINS_NONE.'
                }
              },
              {
                name: 'value', optional: false,
                hint: 'The value(s) used to filter on. Operators <b>CONTAINS_ALL</b>, ' \
                  '<b>CONTAINS_ANY</b>, <b>CONTAINS_NONE</b>, <b>IN</b> and <b>NOT_IN</b> take multiple ' \
                  'values. <b>Specify them separated by commas, without any spaces<b>.<br>' \
                  'All other operators take a single value.'
              }
            ],
            item_label: 'Predicate', add_item_label: 'Add another predicate',
            empty_list_title: 'Specify predicates',
            empty_list_text: 'Click the button below to add predicates. ' \
              'Predicates are treated as inclusive (AND) conditions.',
            hint: 'Use predicates to filter the user lists. A predicate is ' \
              'comprised of a field, an operator, and values. If a ' \
              'predicate contains an invalid ID, the call will result in an ' \
              'empty response, and not in a failure or an error message.'
          },
          { name: 'ordering', sticky: true, type: 'object', properties: [
            {
              name: 'field', control_type: 'select',
              optional: true, sticky: true,
              pick_list: 'campaign_fields',
              toggle_hint: 'Select from options',
              hint: 'The field to sort the results on.',
              toggle_field: {
                name: 'field', label: 'Field name', type: 'string',
                control_type: 'text', optional: true,
                toggle_hint: 'Use custom value',
                hint: 'Enter field name. Click <a href=' \
                  "'https://developers.google.com/adwords/api/docs/appendix/selectorfields#v201809' " \
                  "target='_blank'>here</a> for more details."
              }
            },
            { name: 'sortOrder', sticky: true, control_type: 'select',
              hint: 'The order to sort the results on.',
              pick_list: [
                %w[Descending DESC],
                %w[Ascending ASC]
              ],
              toggle_hint: 'Select from options',
              toggle_field: {
                name: 'sortOrder', label: 'Sort order', type: 'string', optional: true,
                control_type: 'text', toggle_hint: 'Use custom value',
                hint: 'Allowed values are: DESC, ASC'
              } }
          ] },
          { name: 'paging', sticky: true, type: 'object', properties: [
            { name: 'startIndex', type: 'integer', control_type: 'integer', default: '0',
              hint: 'Index of the first result to return in this page.<br>' \
              'The value must be greater than or equal to 0.<br>' \
              'The default value is 0, which means it will start from the first item.' },
            { name: 'numberResults', label: 'Page size', type: 'integer', control_type: 'integer', default: '100',
              hint: 'Maximum number of results to return in this page. ' \
                'Set this to a reasonable value to limit the number of results returned per page.<br>' \
                'The default value is 100.' }
          ] }
        ]
      },
      execute: lambda { |connection, input|
        client_customer_id = input.delete('client_customer_id')
        response = post('cm/v201809/CampaignService').
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/cm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": client_customer_id
                         }],
                         'ns1:developerToken': [{
                           "content!": connection['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'query': [{
                         '@xmlns': 'https://adwords.google.com/api/adwords/cm/v201809',
                         'query': [{
                           "content!": call('build_query', input, 'service' => 'CampaignService')
                         }]
                       }]
                     }]
                   ).
                   headers('clientCustomerId':
                             connection['manager_account_customer_id'],
                           'Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}
        campaigns = response&.dig('queryResponse', 0, 'rval', 0, 'entries')&.
        map do |campaigninfo|
          call('parse_xml_to_hash',
               'xml' => campaigninfo,
               'array_fields' => %w[settings labels parameters conversionTypeIds
                                    operators bids details youtubeVideoMediaIds
                                    imageMediaIds]) || {}
        end

        { campaigns: campaigns }
      },
      output_fields: lambda { |object_definitions|
        [{ name: 'campaigns', type: :array, of: :object,
           properties: object_definitions['campaigns'] }]
      },
      sample_output: lambda { |connection, _input|
        customer_id = call('retrieve_customer_id',
                           'manager_account_customer_id' =>
                             connection['manager_account_customer_id'],
                           'developer_token' => connection['developer_token'])

        fields = 'Id,Name,AdServingOptimizationStatus,Advertising' \
                 'ChannelSubType,AdvertisingChannelType,Amount,AppId,' \
                 'AppVendor,BaseCampaignId,BiddingStrategyGoalType,' \
                 'BiddingStrategyId,BiddingStrategyName,' \
                 'BiddingStrategyType,BudgetId,BudgetName,' \
                 'BudgetReferenceCount,BudgetStatus,CampaignGroupId,' \
                 'CampaignTrialType,DeliveryMethod,Eligible,EndDate,' \
                 'EnhancedCpcEnabled,FinalUrlSuffix,' \
                 'FrequencyCapMaxImpressions,IsBudgetExplicitlyShared,' \
                 'Labels,Level,MaximizeConversionValueTargetRoas,' \
                 'RejectionReasons,SelectiveOptimization,ServingStatus,' \
                 'Settings,StartDate,Status,TargetContentNetwork,' \
                 'TargetCpa,TargetCpaMaxCpcBidCeiling,' \
                 'TargetCpaMaxCpcBidFloor,TargetGoogleSearch,' \
                 'TargetPartnerSearchNetwork,TargetRoas,' \
                 'TargetRoasBidCeiling,TargetRoasBidFloor,' \
                 'TargetSearchNetwork,TargetSpendBidCeiling,' \
                 'TargetSpendSpendTarget,TimeUnit,TrackingUrlTemplate,' \
                 'UrlCustomParameters,VanityPharmaDisplayUrlMode,' \
                 'VanityPharmaText,ViewableCpmEnabled'

        {
          campaigns: call('build_sample_output',
                          'service' => 'CampaignService',
                          'fields' => fields,
                          'customer_id' => customer_id,
                          'developer_token' => connection['developer_token'])
        }
      }
    },
    get_user_list: {
      title: 'Get user lists',
      subtitle: 'Get user lists',
      description: "Get <span class='provider'>user lists</span> in " \
        'Google Ads',
      help: {
        body: 'Retrieve information about user lists associated ' \
          'with a client customer ID in Google Ads. Use the ' \
          '<b>Predicates</b> field to retrieve ' \
          'information of specific user lists based on criteria. ' \
          'Leave it empty to search for all records.',
        learn_more_text: 'User list Service',
        learn_more_url: 'https://developers.google.com/adwords/api/docs/' \
          'reference/v201809/AdwordsUserListService'
      },
      input_fields: lambda { |_object_definitions|
        [
          {
            name: 'client_customer_id',
            hint: 'Customer ID of the target Google Ads account, typically ' \
              'in the form of "123-456-7890". <b>It must be the advertising ' \
              'account being managed by your manager account.</b>',
            optional: false
          },
          {
            name: 'fields', control_type: 'multiselect', delimiter: ',',
            optional: true, sticky: true,
            pick_list: 'user_list_fields',
            toggle_hint: 'Select from options',
            hint: 'The list of fields to include in the result. All fields will be returned by default.',
            toggle_field: {
              name: 'fields', label: 'Field names', type: 'string',
              control_type: 'text', optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Enter field names separated by comma. Click <a href=' \
                "'https://developers.google.com/adwords/api/docs/appendix/selectorfields#v201809' " \
                "target='_blank'>here</a> for more details."
            }
          },
          {
            name: 'predicates', list_mode: 'static', sticky: true,
            type: :array, optional: true,
            properties: [
              {
                name: 'field', optional: false, control_type: 'select',
                pick_list: 'user_list_fields_query',
                toggle_hint: 'Select from options',
                hint: 'The field to filter on.',
                toggle_field: {
                  name: 'field', label: 'Field name', type: 'string',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: "Enter field name. Click <a href='https://developers.google.com/adwords/api/" \
                    "docs/appendix/selectorfields#v201809' " \
                    "target='_blank'>here</a> for more details."
                }
              },
              {
                name: 'operator', optional: false, control_type: 'select',
                pick_list: 'predicate_operators',
                toggle_hint: 'Select from options',
                hint: 'The operator used to filter on. To prevent' \
                  ' calculation accuracy issues, fields whose data' \
                  ' type is <b>Double</b> can be used only with the' \
                  ' following operators in predicates: <b>LESS_THAN</b>' \
                  ' or <b>GREATER_THAN</b>.',
                toggle_field: {
                  name: 'operator', label: 'Operator', type: 'string',
                  control_type: 'text', toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: EQUALS, NOT_EQUALS, IN, NOT_IN, ' \
                    'GREATER_THAN, GREATER_THAN_EQUALS, LESS_THAN, ' \
                    'LESS_THAN_EQUALS, STARTS_WITH, STARTS_WITH_IGNORE_CASE, ' \
                    'CONTAINS, CONTAINS_IGNORE_CASE, DOES_NOT_CONTAIN, ' \
                    'DOES_NOT_CONTAIN_IGNORE_CASE, CONTAINS_ANY, ' \
                    'CONTAINS_ALL, or CONTAINS_NONE.'
                }
              },
              {
                name: 'value', optional: false,
                hint: 'The value(s) used to filter on. Operators <b>CONTAINS_ALL</b>, ' \
                  '<b>CONTAINS_ANY</b>, <b>CONTAINS_NONE</b>, <b>IN</b> and <b>NOT_IN</b> take multiple ' \
                  'values. <b>Specify them separated by commas, without any spaces<b>.<br>' \
                  'All other operators take a single value.'
              }
            ],
            item_label: 'Predicate', add_item_label: 'Add another predicate',
            empty_list_title: 'Specify predicates',
            empty_list_text: 'Click the button below to add predicates. ' \
              'Predicates are treated as inclusive (AND) conditions.',
            hint: 'Use predicates to filter the user lists. A predicate is ' \
              'comprised of a field, an operator, and values. If a ' \
              'predicate contains an invalid ID, the call will result in an ' \
              'empty response, and not in a failure or an error message.'
          },
          { name: 'ordering', sticky: true, type: 'object', properties: [
            {
              name: 'field', control_type: 'select',
              optional: true, sticky: true,
              pick_list: 'user_list_fields',
              toggle_hint: 'Select from options',
              hint: 'The field to sort the results on.',
              toggle_field: {
                name: 'field', label: 'Field name', type: 'string',
                control_type: 'text', optional: true,
                toggle_hint: 'Use custom value',
                hint: 'Enter field name. Click <a href=' \
                  "'https://developers.google.com/adwords/api/docs/appendix/selectorfields#v201809' " \
                  "target='_blank'>here</a> for more details."
              }
            },
            { name: 'sortOrder', sticky: true, control_type: 'select',
              hint: 'The order to sort the results on.',
              pick_list: [
                %w[Descending DESC],
                %w[Ascending ASC]
              ],
              toggle_hint: 'Select from options',
              toggle_field: {
                name: 'sortOrder', label: 'Sort order', type: 'string', optional: true,
                control_type: 'text', toggle_hint: 'Use custom value',
                hint: 'Allowed values are: DESC, ASC'
              } }
          ] },
          { name: 'paging', sticky: true, type: 'object', properties: [
            { name: 'startIndex', type: 'integer', control_type: 'integer', default: '0',
              hint: 'Index of the first result to return in this page.<br>' \
              'The value must be greater than or equal to 0.<br>' \
              'The default value is 0, which means it will start from the first item.' },
            { name: 'numberResults', label: 'Page size', type: 'integer', control_type: 'integer', default: '100',
              hint: 'Maximum number of results to return in this page. ' \
                'Set this to a reasonable value to limit the number of results returned per page.<br>' \
                'The default value is 100.' }
          ] }
        ]
      },
      execute: lambda { |connection, input|
        client_customer_id = input.delete('client_customer_id')
        response = post('rm/v201809/AdwordsUserListService').
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/rm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": client_customer_id
                         }],
                         'ns1:developerToken': [{
                           "content!": connection['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'query': [{
                         '@xmlns': 'https://adwords.google.com/api/adwords/rm/v201809',
                         'query': [{
                           "content!": call('build_query', input, 'service' => 'AdwordsUserListService')
                         }]
                       }]
                     }]
                   ).
                   headers('clientCustomerId':
                             connection['manager_account_customer_id'],
                           'Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}
        user_lists = response&.dig('queryResponse', 0, 'rval', 0, 'entries')&.
        map do |campaigninfo|
          call('parse_xml_to_hash',
               'xml' => campaigninfo,
               'array_fields' => %w[rules ruleOperands conversionTypes groups items]) || {}
        end

        { user_lists: user_lists }
      },
      output_fields: lambda { |object_definitions|
        [{ name: 'user_lists', type: :array, of: :object,
           properties: object_definitions['user_list_output'] }]
      },
      sample_output: lambda { |connection, _input|
        customer_id = call('retrieve_customer_id',
                           'manager_account_customer_id' =>
                             connection['manager_account_customer_id'],
                           'developer_token' => connection['developer_token'])

        fields = 'AccessReason,AccountUserListStatus,AppId,ClosingReason,ConversionTypes,DataSourceType,' \
        'DataUploadResult,DateSpecificListEndDate,DateSpecificListRule,DateSpecificListStartDate,' \
        'Description,ExpressionListRule,Id,IntegrationCode,IsEligibleForDisplay,IsEligibleForSearch,' \
        'IsReadOnly,ListType,MembershipLifeSpan,Name,PrepopulationStatus,Rules,SeedListSize,' \
        'SeedUserListDescription,SeedUserListId,SeedUserListName,SeedUserListStatus,Size,SizeForSearch,' \
        'SizeRange,SizeRangeForSearch,Status,UploadKeyType'

        { user_lists: call('build_sample_output',
                           'service' => 'AdwordsUserListService',
                           'fields' => fields,
                           'customer_id' => customer_id,
                           'developer_token' => connection['developer_token']) }
      }
    },
    download_advertising_report: {
      title: 'Download advertising report',
      subtitle: 'Download advertising report',
      description: "Download <span class='provider'>advertising " \
        'report</span> from Google Ads',
      help: {
        body: 'This action specifies the details for a report from Google ' \
          'Ads and downloads it. There are many fields for customizing the ' \
          'report and each report type has its own columns to choose from. ' \
          'You can filter the report using the <b>predicates</b> field, ' \
          'specify the date/time range and choose a download format. ' \
          'To pick up data from all dates(ALL_TIME), please select ' \
          '<b>All time</b>. Learn more by clicking the link below.',
        learn_more_text: 'AdWords API: Reporting Basics',
        learn_more_url: 'https://developers.google.com/adwords/api/' \
          'docs/guides/reporting'
      },
      input_fields: lambda { |object_definitions|
        object_definitions['report_definition']
      },
      execute: lambda { |connection, input|
        input['developer_token'] = connection['developer_token']
        report_query = call('build_report_query', input)
        headers = {
          clientCustomerId: input['client_customer_id'],
          skipReportHeader: input['skip_report_header'] || false,
          skipColumnHeader: input['skip_column_header'] || false,
          skipReportSummary: input['skip_report_summary'] || false,
          useRawEnumValues: input['use_raw_enum_values'] || false,
          includeZeroImpressions: input['include_zero_impressions']
        }.compact

        if input['download_report_raw'] == true
          response = post('reportdownload/v201809').
                     payload(__fmt: input['download_format'],
                             __rdquery: report_query).
                     headers(headers).
                     request_format_multipart_form.response_format_raw.
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end
          { downloaded_report: response }
        else
          response = post('reportdownload/v201809').
                     payload(__fmt: 'XML',
                             __rdquery: report_query).
                     headers(headers).
                     request_format_multipart_form.response_format_xml.
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end
          report = call('format_report_output', response)
          call('format_api_output_field_names',
               report&.compact)
        end
      },
      output_fields: lambda { |object_definition|
        object_definition['downloaded_report']
      },
      sample_output: lambda { |_connection, input|
        call('build_download_report_sample_output', input)
      }
    },
    update_campaign: {
      title: 'Update campaign',
      subtitle: 'Update campaign',
      description: "Update <span class='provider'>campaign</span> in " \
        'Google Ads',
      help: {
        body: 'Learn more by clicking the link below.',
        learn_more_text: 'Campaign Service',
        learn_more_url: 'https://developers.google.com/adwords/api/docs/' \
          'reference/v201809/CampaignService'
      },
      input_fields: lambda { |object_definitions|
        object_definitions['campaigns_fields'].
          ignored('servingStatus', 'advertisingChannelType',
                  'advertisingChannelSubType', 'labels',
                  'conversionOptimizerEligibility', 'campaignTrialType',
                  'baseCampaignId').
          required('id')
      },
      execute: lambda do |connection, input|
        customer_id = input.delete('client_customer_id')
        response = post('cm/v201809/CampaignService').
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/cm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": customer_id
                         }],
                         'ns1:developerToken': [{
                           "content!": connection['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'mutate': [{
                         '@xmlns': 'https://adwords.google.com/api/adwords/cm/v201809',
                         'operations': [{
                           'operator': [{
                             "content!": 'SET'
                           }],
                           'operand': call('build_campaign_fields', input)
                         }]
                       }]
                     }]
                   ).
                   headers('clientCustomerId':
                             connection['manager_account_customer_id'],
                           'Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}

        results = response&.dig('mutateResponse', 0, 'rval', 0, 'value')&.
        map do |fieldinfo|
          call('parse_xml_to_hash',
               'xml' => fieldinfo,
               'array_fields' => %w[settings labels parameters]) || {}
        end&.dig(0)

        { results: results }
      end,
      output_fields: lambda do |object_definitions|
        { name: 'results',
          type: 'object',
          properties: object_definitions['campaigns'] }
      end,
      sample_output: lambda do |connection, _input|
        customer_id = call('retrieve_customer_id',
                           'manager_account_customer_id' =>
                             connection['manager_account_customer_id'],
                           'developer_token' => connection['developer_token'])

        fields = 'Id,Name,AdServingOptimizationStatus,Advertising' \
                 'ChannelSubType,AdvertisingChannelType,Amount,AppId,' \
                 'AppVendor,BaseCampaignId,BiddingStrategyGoalType,' \
                 'BiddingStrategyId,BiddingStrategyName,' \
                 'BiddingStrategyType,BudgetId,BudgetName,' \
                 'BudgetReferenceCount,BudgetStatus,CampaignGroupId,' \
                 'CampaignTrialType,DeliveryMethod,Eligible,EndDate,' \
                 'EnhancedCpcEnabled,FinalUrlSuffix,' \
                 'FrequencyCapMaxImpressions,IsBudgetExplicitlyShared,' \
                 'Labels,Level,MaximizeConversionValueTargetRoas,' \
                 'RejectionReasons,SelectiveOptimization,ServingStatus,' \
                 'Settings,StartDate,Status,TargetContentNetwork,' \
                 'TargetCpa,TargetCpaMaxCpcBidCeiling,' \
                 'TargetCpaMaxCpcBidFloor,TargetGoogleSearch,' \
                 'TargetPartnerSearchNetwork,TargetRoas,' \
                 'TargetRoasBidCeiling,TargetRoasBidFloor,' \
                 'TargetSearchNetwork,TargetSpendBidCeiling,' \
                 'TargetSpendSpendTarget,TimeUnit,TrackingUrlTemplate,' \
                 'UrlCustomParameters,VanityPharmaDisplayUrlMode,' \
                 'VanityPharmaText,ViewableCpmEnabled'

        { results: call('build_sample_output',
                        'service' => 'CampaignService',
                        'fields' => fields,
                        'customer_id' => customer_id,
                        'developer_token' => connection['developer_token']) }
      end
    },
    remove_campaign: {
      title: 'Remove campaign',
      subtitle: 'Remove campaign',
      description: "Remove <span class='provider'>campaign</span> in " \
        'Google Ads',
      help: {
        body: 'Learn more by clicking the link below.',
        learn_more_text: 'Campaign Service',
        learn_more_url: 'https://developers.google.com/adwords/api/docs/' \
          'reference/v201809/CampaignService'
      },
      input_fields: lambda { |object_definitions|
        object_definitions['campaigns_fields'].only('id', 'client_customer_id').
          required('id')
      },
      execute: lambda do |connection, input|
        customer_id = input.delete('client_customer_id')
        response = post('cm/v201809/CampaignService').
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/cm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": customer_id
                         }],
                         'ns1:developerToken': [{
                           "content!": connection['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'mutate': [{
                         '@xmlns': 'https://adwords.google.com/api/adwords/cm/v201809',
                         'operations': [{
                           'operator': [{
                             "content!": 'SET'
                           }],
                           'operand': [{
                             'id': [{
                               "content!": input['id']
                             }],
                             'status': [{
                               "content!": 'REMOVED'
                             }]
                           }]
                         }]
                       }]
                     }]
                   ).
                   headers('clientCustomerId':
                             connection['manager_account_customer_id'],
                           'Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}

        results = response&.dig('mutateResponse', 0, 'rval', 0, 'value')&.
        map do |fieldinfo|
          call('parse_xml_to_hash',
               'xml' => fieldinfo,
               'array_fields' => %w[settings labels parameters]) || {}
        end&.dig(0)

        { results: results }
      end,
      output_fields: lambda do |object_definitions|
        { name: 'results',
          type: 'object',
          properties: object_definitions['campaigns'] }
      end,
      sample_output: lambda do |connection, _input|
        customer_id = call('retrieve_customer_id',
                           'manager_account_customer_id' =>
                             connection['manager_account_customer_id'],
                           'developer_token' => connection['developer_token'])

        fields = 'Id,Name,AdServingOptimizationStatus,Advertising' \
                 'ChannelSubType,AdvertisingChannelType,Amount,AppId,' \
                 'AppVendor,BaseCampaignId,BiddingStrategyGoalType,' \
                 'BiddingStrategyId,BiddingStrategyName,' \
                 'BiddingStrategyType,BudgetId,BudgetName,' \
                 'BudgetReferenceCount,BudgetStatus,CampaignGroupId,' \
                 'CampaignTrialType,DeliveryMethod,Eligible,EndDate,' \
                 'EnhancedCpcEnabled,FinalUrlSuffix,' \
                 'FrequencyCapMaxImpressions,IsBudgetExplicitlyShared,' \
                 'Labels,Level,MaximizeConversionValueTargetRoas,' \
                 'RejectionReasons,SelectiveOptimization,ServingStatus,' \
                 'Settings,StartDate,Status,TargetContentNetwork,' \
                 'TargetCpa,TargetCpaMaxCpcBidCeiling,' \
                 'TargetCpaMaxCpcBidFloor,TargetGoogleSearch,' \
                 'TargetPartnerSearchNetwork,TargetRoas,' \
                 'TargetRoasBidCeiling,TargetRoasBidFloor,' \
                 'TargetSearchNetwork,TargetSpendBidCeiling,' \
                 'TargetSpendSpendTarget,TimeUnit,TrackingUrlTemplate,' \
                 'UrlCustomParameters,VanityPharmaDisplayUrlMode,' \
                 'VanityPharmaText,ViewableCpmEnabled'

        { results: call('build_sample_output',
                        'service' => 'CampaignService',
                        'fields' => fields,
                        'customer_id' => customer_id,
                        'developer_token' => connection['developer_token']) }
      end
    },
    create_user_list: {
      title: 'Create user list',
      subtitle: 'Create user list',
      description: "Create <span class='provider'>user list</span> in " \
        'Google Ads',
      help: {
        body: 'Learn more by clicking the link below.',
        learn_more_text: 'User list Service',
        learn_more_url: 'https://developers.google.com/adwords/api/docs/' \
          'reference/v201809/AdwordsUserListService'
      },
      input_fields: lambda { |object_definitions|
        object_definitions['create_user_list']
      },
      execute: lambda do |connection, input|
        customer_id = input.delete('client_customer_id')
        list_type = input.delete('list_type')
        response = post('rm/v201809/AdwordsUserListService').
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/rm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": customer_id
                         }],
                         'ns1:developerToken': [{
                           "content!": connection['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'ns1:mutate': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/rm/v201809',
                         'ns1:operations': [{
                           'ns2:operator': [{
                             "content!": 'ADD',
                             '@xmlns:ns2': 'https://adwords.google.com/api/adwords/cm/v201809',
                           }],
                           'ns1:operand': [call('build_user_list_fields', input)].
                                           concat([{ '@xsi:type': "ns1:" + list_type }]).
                                           inject(:merge)
                         }]
                       }]
                     }]
                   ).
                   headers('clientCustomerId':
                             connection['manager_account_customer_id'],
                           'Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}

        result = response&.dig('mutateResponse', 0, 'rval', 0, 'value')&.
        map do |fieldinfo|
          call('parse_xml_to_hash',
               'xml' => fieldinfo,
               'array_fields' => %w[rules ruleOperands conversionTypes groups items]) || {}
        end&.dig(0)

        { result: result }
      end,
      output_fields: lambda do |object_definitions|
        { name: 'result',
          label: 'User list',
          type: 'object',
          properties: object_definitions['user_list_output'] }
      end,
      sample_output: lambda do |connection, _input|
        customer_id = call('retrieve_customer_id',
                           'manager_account_customer_id' =>
                             connection['manager_account_customer_id'],
                           'developer_token' => connection['developer_token'])

        fields = 'AccessReason,AccountUserListStatus,AppId,ClosingReason,ConversionTypes,DataSourceType,' \
        'DataUploadResult,DateSpecificListEndDate,DateSpecificListRule,DateSpecificListStartDate,' \
        'Description,ExpressionListRule,Id,IntegrationCode,IsEligibleForDisplay,IsEligibleForSearch,' \
        'IsReadOnly,ListType,MembershipLifeSpan,Name,PrepopulationStatus,Rules,SeedListSize,' \
        'SeedUserListDescription,SeedUserListId,SeedUserListName,SeedUserListStatus,Size,SizeForSearch,' \
        'SizeRange,SizeRangeForSearch,Status,UploadKeyType'

        { result: call('build_sample_output',
                       'service' => 'AdwordsUserListService',
                       'fields' => fields,
                       'customer_id' => customer_id,
                       'developer_token' => connection['developer_token']) }
      end
    },
    update_user_list: {
      title: 'Update user list',
      subtitle: 'Update user list',
      description: "Update <span class='provider'>user list</span> in " \
        'Google Ads',
      help: {
        body: 'Learn more by clicking the link below.',
        learn_more_text: 'User list Service',
        learn_more_url: 'https://developers.google.com/adwords/api/docs/' \
          'reference/v201809/AdwordsUserListService'
      },
      input_fields: lambda { |object_definitions|
        object_definitions['update_user_list']
      },
      execute: lambda do |connection, input|
        customer_id = input.delete('client_customer_id')
        list_type = input.delete('list_type')
        response = post('rm/v201809/AdwordsUserListService').
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/rm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": customer_id
                         }],
                         'ns1:developerToken': [{
                           "content!": connection['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'ns1:mutate': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/rm/v201809',
                         'ns1:operations': [{
                           'ns2:operator': [{
                             "content!": 'SET',
                             '@xmlns:ns2': 'https://adwords.google.com/api/adwords/cm/v201809',
                           }],
                           'ns1:operand': [call('build_user_list_fields', input)].
                                           concat([{ '@xsi:type': "ns1:" + list_type }]).
                                           inject(:merge)
                         }]
                       }]
                     }]
                   ).
                   headers('clientCustomerId':
                             connection['manager_account_customer_id'],
                           'Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}

        result = response&.dig('mutateResponse', 0, 'rval', 0, 'value')&.
        map do |fieldinfo|
          call('parse_xml_to_hash',
               'xml' => fieldinfo,
               'array_fields' => %w[rules ruleOperands conversionTypes groups items]) || {}
        end&.dig(0)

        { result: result }
      end,
      output_fields: lambda do |object_definitions|
        { name: 'result',
          label: 'User list',
          type: 'object',
          properties: object_definitions['user_list_output'] }
      end,
      sample_output: lambda do |connection, _input|
        customer_id = call('retrieve_customer_id',
                           'manager_account_customer_id' =>
                             connection['manager_account_customer_id'],
                           'developer_token' => connection['developer_token'])

        fields = 'AccessReason,AccountUserListStatus,AppId,ClosingReason,ConversionTypes,DataSourceType,' \
        'DataUploadResult,DateSpecificListEndDate,DateSpecificListRule,DateSpecificListStartDate,' \
        'Description,ExpressionListRule,Id,IntegrationCode,IsEligibleForDisplay,IsEligibleForSearch,' \
        'IsReadOnly,ListType,MembershipLifeSpan,Name,PrepopulationStatus,Rules,SeedListSize,' \
        'SeedUserListDescription,SeedUserListId,SeedUserListName,SeedUserListStatus,Size,SizeForSearch,' \
        'SizeRange,SizeRangeForSearch,Status,UploadKeyType'

        { result: call('build_sample_output',
                       'service' => 'AdwordsUserListService',
                       'fields' => fields,
                       'customer_id' => customer_id,
                       'developer_token' => connection['developer_token']) }
      end
    },
    add_members_to_user_list: {
      title: 'Add members to user list',
      subtitle: 'Add members to user list',
      description: "Add members to <span class='provider'>user list</span> in " \
        'Google Ads',
      help: {
        body: 'The following types of member identifier are supported:<br><br>
               - Contact info (email, phone number, address)<br>
               - Mobile advertising ID<br>
               - User IDs generated and assigned by advertiser<br><br>
               A list can be uploaded with only one type of data and once uploaded ' \
               'will not accept any other ID types.',
        learn_more_text: 'User list Service',
        learn_more_url: 'https://developers.google.com/adwords/api/docs/' \
          'reference/v201809/AdwordsUserListService'
      },
      input_fields: lambda { |object_definitions|
        object_definitions['add_members_to_user_list']
      },
      execute: lambda do |connection, input|
        customer_id = input.delete('client_customer_id')
        response = post('rm/v201809/AdwordsUserListService').
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/rm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": customer_id
                         }],
                         'ns1:developerToken': [{
                           "content!": connection['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'ns1:mutateMembers': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/rm/v201809',
                         'ns1:operations': [{
                           'ns2:operator': [{
                             "content!": 'ADD',
                             '@xmlns:ns2': 'https://adwords.google.com/api/adwords/cm/v201809',
                           }],
                           'ns1:operand': [call('build_members_fields', input)]
                         }]
                       }]
                     }]
                   ).
                   headers('clientCustomerId':
                             connection['manager_account_customer_id'],
                           'Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}


        result = response&.dig('mutateMembers', 0, 'rval', 0, 'userLists')&.
        map do |fieldinfo|
          call('parse_xml_to_hash',
               'xml' => fieldinfo,
               'array_fields' => %w[rules ruleOperands conversionTypes groups items]) || {}
        end&.dig(0)

        { result: result }
      end,
      output_fields: lambda do |object_definitions|
        { name: 'result',
          label: 'User list',
          type: 'object',
          properties: object_definitions['user_list_output'] }
      end,
      sample_output: lambda do |connection, _input|
        customer_id = call('retrieve_customer_id',
                           'manager_account_customer_id' =>
                             connection['manager_account_customer_id'],
                           'developer_token' => connection['developer_token'])

        fields = 'AccessReason,AccountUserListStatus,AppId,ClosingReason,ConversionTypes,DataSourceType,' \
        'DataUploadResult,DateSpecificListEndDate,DateSpecificListRule,DateSpecificListStartDate,' \
        'Description,ExpressionListRule,Id,IntegrationCode,IsEligibleForDisplay,IsEligibleForSearch,' \
        'IsReadOnly,ListType,MembershipLifeSpan,Name,PrepopulationStatus,Rules,SeedListSize,' \
        'SeedUserListDescription,SeedUserListId,SeedUserListName,SeedUserListStatus,Size,SizeForSearch,' \
        'SizeRange,SizeRangeForSearch,Status,UploadKeyType'

        { result: call('build_sample_output',
                       'service' => 'AdwordsUserListService',
                       'fields' => fields,
                       'customer_id' => customer_id,
                       'developer_token' => connection['developer_token']) }
      end
    },
    add_offline_conversion: {
      title: 'Add offline conversion',
      subtitle: 'Add offline conversion',
      description: "Add <span class='provider'>offline conversion</span> in " \
        'Google Ads',
      help: {
        body: 'Learn more by clicking the link below.',
        learn_more_text: 'Offline conversion feed Service',
        learn_more_url: 'https://developers.google.com/adwords/api/docs/' \
          'reference/v201809/OfflineConversionFeedService'
      },
      input_fields: lambda { |object_definitions|
        object_definitions['add_offline_conversion']
      },
      execute: lambda do |connection, input|
        time_zone = input.delete('timezone')
        customer_id = input.delete('client_customer_id')
        input['conversionTime'] = input['conversionTime'].to_time.strftime('%Y%m%d %H%M%S ') + time_zone
        response = post('cm/v201809/OfflineConversionFeedService').
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/cm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": customer_id
                         }],
                         'ns1:developerToken': [{
                           "content!": connection['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'mutate': [{
                         '@xmlns': 'https://adwords.google.com/api/adwords/cm/v201809',
                         'operations': [{
                           'operator': [{
                             "content!": 'ADD'
                           }],
                           'operand': [call('build_campaign_fields', input)]
                         }]
                       }]
                     }]
                   ).
                   headers('clientCustomerId':
                             connection['manager_account_customer_id'],
                           'Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}

        result = response&.dig('mutateResponse', 0, 'rval', 0, 'value')&.
        map do |fieldinfo|
          call('parse_xml_to_hash',
               'xml' => fieldinfo,
               'array_fields' => []) || {}
        end&.dig(0)

        { result: result }
      end,
      output_fields: lambda do |object_definitions|
        { name: 'result',
          type: 'object',
          properties: object_definitions['add_offline_conversion'] }
      end,
      sample_output: lambda do |connection, _input|
        []
      end
    },
  },

  triggers: {
    new_campaign: {
      title: 'New campaign',
      subtitle: 'Triggers when a new campaign is created in Google Ads',
      help: 'Each new campaign will create a single job.',
      description: "New <span class='provider'>campaign" \
        "</span> in <span class='provider'>Google AdWords</span>",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'client_customer_id',
            hint: 'Customer ID of the target Google Ads account, typically ' \
              'in the form of "123-456-7890". <b>It must be the advertising ' \
              'account being managed by your manager account.</b>',
            optional: false
          },
          {
            name: 'campaign_id',
            hint: 'When you start recipe for the first time, it picks up ' \
              'trigger events from this specified Campaign ID. <b>Leave ' \
              'empty to get events created from the beginning.</b>',
            sticky: true,
            optional: true
          }
        ]
      end,

      poll: lambda do |connection, input, closure|
        offset = closure&.[]('offset') || 0
        page_size = 100
        since = closure&.[]('since') || (input['campaign_id'] || 0)

        fields = 'Id,Name,AdServingOptimizationStatus,Advertising' \
                 'ChannelSubType,AdvertisingChannelType,Amount,AppId,' \
                 'AppVendor,BaseCampaignId,BiddingStrategyGoalType,' \
                 'BiddingStrategyId,BiddingStrategyName,' \
                 'BiddingStrategyType,BudgetId,BudgetName,' \
                 'BudgetReferenceCount,BudgetStatus,CampaignGroupId,' \
                 'CampaignTrialType,DeliveryMethod,Eligible,EndDate,' \
                 'EnhancedCpcEnabled,FinalUrlSuffix,' \
                 'FrequencyCapMaxImpressions,IsBudgetExplicitlyShared,' \
                 'Labels,Level,MaximizeConversionValueTargetRoas,' \
                 'RejectionReasons,SelectiveOptimization,ServingStatus,' \
                 'Settings,StartDate,Status,TargetContentNetwork,' \
                 'TargetCpa,TargetCpaMaxCpcBidCeiling,' \
                 'TargetCpaMaxCpcBidFloor,TargetGoogleSearch,' \
                 'TargetPartnerSearchNetwork,TargetRoas,' \
                 'TargetRoasBidCeiling,TargetRoasBidFloor,' \
                 'TargetSearchNetwork,TargetSpendBidCeiling,' \
                 'TargetSpendSpendTarget,TimeUnit,TrackingUrlTemplate,' \
                 'UrlCustomParameters,VanityPharmaDisplayUrlMode,' \
                 'VanityPharmaText,ViewableCpmEnabled'

        response = post('cm/v201809/CampaignService').
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/cm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": input['client_customer_id']
                         }],
                         'ns1:developerToken': [{
                           "content!": connection['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'query': [{
                         '@xmlns': 'https://adwords.google.com/api/adwords/cm/v201809',
                         'query': [{
                           "content!": "SELECT #{fields}
                                       WHERE Id >= \"#{since}\"
                                       ORDER BY Id ASC
                                       LIMIT #{offset},#{page_size}"
                         }]
                       }]
                     }]
                   ).
                   headers('Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org' \
                              '/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/' \
                              'XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}

        total_campaign =
          response&.dig('queryResponse', 0, 'rval', 0, 'totalNumEntries')&.
          pluck('content!')&.dig(0)&.to_i

        campaigns =
          response&.dig('queryResponse', 0, 'rval', 0, 'entries')&.
          map do |fieldinfo|
            call('parse_xml_to_hash',
                 'xml' => fieldinfo,
                 'array_fields' => %w[settings labels parameters
                                      conversionTypeIds operators bids details
                                      youtubeVideoMediaIds imageMediaIds]) || {}
          end
        campaigns_formatted = call('format_api_output_field_names',
                                   campaigns&.compact)

        more_pages = offset + page_size < total_campaign
        next_updated_since = campaigns.last['id'] unless campaigns.blank?
        closure = if more_pages
                    { 'offset' =>  offset + page_size, 'since' => since }
                  else
                    { 'offset' =>  0, 'since' => next_updated_since }
                  end
        {
          events: campaigns_formatted,
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: ->(campaigns) { campaigns['id'] },

      output_fields: lambda do |object_definitions|
        object_definitions['campaigns']
      end,

      sample_output: lambda do |connection, _input|
        customer_id = call('retrieve_customer_id',
                           'manager_account_customer_id' =>
                             connection['manager_account_customer_id'],
                           'developer_token' => connection['developer_token'])

        fields = 'Id,Name,AdServingOptimizationStatus,Advertising' \
                 'ChannelSubType,AdvertisingChannelType,Amount,AppId,' \
                 'AppVendor,BaseCampaignId,BiddingStrategyGoalType,' \
                 'BiddingStrategyId,BiddingStrategyName,' \
                 'BiddingStrategyType,BudgetId,BudgetName,' \
                 'BudgetReferenceCount,BudgetStatus,CampaignGroupId,' \
                 'CampaignTrialType,DeliveryMethod,Eligible,EndDate,' \
                 'EnhancedCpcEnabled,FinalUrlSuffix,' \
                 'FrequencyCapMaxImpressions,IsBudgetExplicitlyShared,' \
                 'Labels,Level,MaximizeConversionValueTargetRoas,' \
                 'RejectionReasons,SelectiveOptimization,ServingStatus,' \
                 'Settings,StartDate,Status,TargetContentNetwork,' \
                 'TargetCpa,TargetCpaMaxCpcBidCeiling,' \
                 'TargetCpaMaxCpcBidFloor,TargetGoogleSearch,' \
                 'TargetPartnerSearchNetwork,TargetRoas,' \
                 'TargetRoasBidCeiling,TargetRoasBidFloor,' \
                 'TargetSearchNetwork,TargetSpendBidCeiling,' \
                 'TargetSpendSpendTarget,TimeUnit,TrackingUrlTemplate,' \
                 'UrlCustomParameters,VanityPharmaDisplayUrlMode,' \
                 'VanityPharmaText,ViewableCpmEnabled'

        call('build_sample_output',
             'service' => 'CampaignService',
             'fields' => fields,
             'customer_id' => customer_id,
             'developer_token' => connection['developer_token'])
      end
    },

    new_adgroup: {
      title: 'New adgroup',
      subtitle: 'Triggers when a new adgroup is created in Google Ads',
      help: 'Each new adgroup will create a single job.',
      description: "New <span class='provider'>adgroup" \
        "</span> in <span class='provider'>Google AdWords</span>",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'client_customer_id',
            hint: 'Customer ID of the target Google Ads account, typically ' \
              'in the form of "123-456-7890". <b>It must be the advertising ' \
              'account being managed by your manager account.</b>',
            optional: false
          },
          {
            name: 'adgroup_id',
            label: 'AdGroup ID',
            hint: 'When you start recipe for the first time, it picks up ' \
              'trigger events from this specified AdGroup ID. <b>Leave ' \
              'empty to get events created from the beginning.</b>',
            sticky: true,
            optional: true
          }
        ]
      end,

      poll: lambda do |connection, input, closure|
        offset = closure&.[]('offset') || 0
        page_size = 100
        since = closure&.[]('since') || (input['adgroup_id'] || 0)

        fields = 'AdGroupType,AdRotationMode,BaseAdGroupId,BaseCampaignId,' \
          'BiddingStrategyId,BiddingStrategyName,BiddingStrategySource,' \
          'BiddingStrategyType,CampaignId,CampaignName,' \
          'ContentBidCriterionTypeGroup,CpcBid,CpmBid,EnhancedCpcEnabled,' \
          'FinalUrlSuffix,Id,Labels,Name,Settings,Status,TargetCpa,' \
          'TargetCpaBid,TargetCpaBidSource,TargetRoasOverride,' \
          'TrackingUrlTemplate,UrlCustomParameters'

        response = post('cm/v201809/AdGroupService').
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/cm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": input['client_customer_id']
                         }],
                         'ns1:developerToken': [{
                           "content!": connection['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'query': [{
                         '@xmlns': 'https://adwords.google.com/api/adwords/cm/v201809',
                         'query': [{
                           "content!": "SELECT #{fields}
                                       WHERE Id >= \"#{since}\"
                                       ORDER BY Id ASC
                                       LIMIT #{offset},#{page_size}"
                         }]
                       }]
                     }]
                   ).
                   headers('Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org' \
                              '/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/' \
                              'XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}

        total_adgroups =
          response&.dig('queryResponse', 0, 'rval', 0, 'totalNumEntries')&.
          pluck('content!')&.dig(0)&.to_i

        adgroups =
          response&.dig('queryResponse', 0, 'rval', 0, 'entries')&.
          map do |fieldinfo|
            call('parse_xml_to_hash',
                 'xml' => fieldinfo,
                 'array_fields' => %w[settings labels details]) || {}
          end
        adgroups_formatted = call('format_api_output_field_names',
                                  adgroups&.compact)

        more_pages = offset + page_size < total_adgroups
        next_updated_since = adgroups.last['id'] unless adgroups.blank?
        closure = if more_pages
                    { 'offset' =>  offset + page_size, 'since' => since }
                  else
                    { 'offset' =>  0, 'since' => next_updated_since }
                  end
        {
          events: adgroups_formatted,
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: ->(adgroups) { adgroups['id'] },

      output_fields: lambda do |object_definitions|
        object_definitions['adgroups']
      end,

      sample_output: lambda do |connection, _input|
        customer_id = call('retrieve_customer_id',
                           'manager_account_customer_id' =>
                             connection['manager_account_customer_id'],
                           'developer_token' => connection['developer_token'])

        fields = 'AdGroupType,AdRotationMode,BaseAdGroupId,BaseCampaignId,' \
          'BiddingStrategyId,BiddingStrategyName,BiddingStrategySource,' \
          'BiddingStrategyType,CampaignId,CampaignName,' \
          'ContentBidCriterionTypeGroup,CpcBid,CpmBid,EnhancedCpcEnabled,' \
          'FinalUrlSuffix,Id,Labels,Name,Settings,Status,TargetCpa,' \
          'TargetCpaBid,TargetCpaBidSource,TargetRoasOverride,' \
          'TrackingUrlTemplate,UrlCustomParameters'

        call('build_sample_output',
             'service' => 'AdGroupService',
             'fields' => fields,
             'customer_id' => customer_id,
             'developer_token' => connection['developer_token'])
      end
    },

    new_ad: {
      title: 'New ad',
      subtitle: 'Triggers when a new ad is created in Google Ads',
      help: 'Each new ad will create a single job.',
      description: "New <span class='provider'>ad" \
        "</span> in <span class='provider'>Google AdWords</span>",

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'client_customer_id',
            hint: 'Customer ID of the target Google Ads account, typically ' \
              'in the form of "123-456-7890". <b>It must be the advertising ' \
              'account being managed by your manager account.</b>',
            optional: false
          },
          {
            name: 'ad_id',
            label: 'Ad ID',
            hint: 'When you start recipe for the first time, it picks up ' \
              'trigger events from this specified Ad ID. <b>Leave ' \
              'empty to get events created from the beginning.</b>',
            sticky: true,
            optional: true
          }
        ]
      end,

      poll: lambda do |connection, input, closure|
        offset = closure&.[]('offset') || 0
        page_size = 100
        since = closure&.[]('since') || (input['ad_id'] || 0)

        response = post('cm/v201809/AdService').
                   payload(
                     'soapenv:Header': [{
                       'ns1:RequestHeader': [{
                         '@xmlns:ns1': 'https://adwords.google.com/api/adwords/cm/v201809',
                         '@soapenv:actor': 'http://schemas.xmlsoap.org/soap/actor/next',
                         '@soapenv:mustUnderstand': '0',
                         'ns1:clientCustomerId': [{
                           "content!": input['client_customer_id']
                         }],
                         'ns1:developerToken': [{
                           "content!": connection['developer_token']
                         }],
                         'ns1:userAgent': [{
                           "content!": 'Workato'
                         }],
                         'ns1:validateOnly': [{
                           "content!": false
                         }],
                         'ns1:partialFailure': [{
                           "content!": false
                         }]
                       }]
                     }],
                     'soapenv:Body': [{
                       'get': [{
                         '@xmlns': 'https://adwords.google.com/api/adwords/cm/v201809',
                         'serviceSelector': [call('build_ad_fields_xml',
                                                  'offset' => offset,
                                                  'page_size' => page_size,
                                                  'since' => since)]
                       }]
                     }]
                   ).
                   headers('Content-Type': 'text/xml').
                   format_xml('soapenv:Envelope',
                              '@xmlns:soapenv' => 'http://schemas.xmlsoap.org' \
                              '/soap/envelope/',
                              '@xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                              '@xmlns:xsi' => 'http://www.w3.org/2001/' \
                              'XMLSchema-instance',
                              strip_response_namespaces: true).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end&.dig('Envelope', 0, 'Body', 0) || {}

        total_ads =
          response&.dig('getResponse', 0, 'rval', 0, 'totalNumEntries')&.
          pluck('content!')&.dig(0)&.to_i

        ads =
          response&.dig('getResponse', 0, 'rval', 0, 'entries')&.
          map do |fieldinfo|
            call('parse_xml_to_hash',
                 'xml' => fieldinfo,
                 'array_fields' => %w[finalUrls finalMobileUrls
                                      finalAppUrls urlData productImages
                                      productVideoList marketingImages
                                      squareMarketingImages logoImages
                                      landscapeLogoImages headlines
                                      descriptions youTubeVideos
                                      adAttributes templateElements
                                      images videos html5MediaBundles
                                      parameters dimensions urls fields]) || {}
          end
        ads_formatted = call('format_api_output_field_names',
                             ads&.compact)

        more_pages = offset + page_size < total_ads
        next_updated_since = ads.last['id'] unless ads.blank?
        closure = if more_pages
                    { 'offset' =>  offset + page_size, 'since' => since }
                  else
                    { 'offset' =>  0, 'since' => next_updated_since }
                  end
        {
          events: ads_formatted,
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: ->(ads) { ads['id'] },

      output_fields: lambda do |object_definitions|
        object_definitions['ads']
      end,

      sample_output: lambda do |connection, _input|
        customer_id = call('retrieve_customer_id',
                           'manager_account_customer_id' =>
                             connection['manager_account_customer_id'],
                           'developer_token' => connection['developer_token'])

        call('build_sample_output',
             'service' => 'AdService',
             'customer_id' => customer_id,
             'developer_token' => connection['developer_token'])
      end
    }
  },

  pick_lists: {
    account_selector_fields: lambda do
      [
        %w[Account\ labels AccountLabels],
        %w[Can\ manage\ clients? CanManageClients],
        %w[Currency\ code CurrencyCode],
        %w[Customer\ ID CustomerId],
        %w[Date/Timezone DateTimeZone],
        %w[Name Name],
        %w[Test\ account? TestAccount]
      ]
    end,
    report_types: lambda do
      [
        %w[Ad\ Performance\ Report AD_PERFORMANCE_REPORT],
        %w[URL\ Performance\ Report URL_PERFORMANCE_REPORT],
        %w[AdGroup\ Performance\ Report ADGROUP_PERFORMANCE_REPORT],
        %w[Account\ Performance\ Report ACCOUNT_PERFORMANCE_REPORT],
        %w[Geo\ Performance\ Report GEO_PERFORMANCE_REPORT],
        %w[Search\ Query\ Performance\ Report SEARCH_QUERY_PERFORMANCE_REPORT],
        %w[Automatic\ Placements\ Performance\ Report
           AUTOMATIC_PLACEMENTS_PERFORMANCE_REPORT],
        %w[Campaign\ Negative\ Keywords\ Performance\ Report
           CAMPAIGN_NEGATIVE_KEYWORDS_PERFORMANCE_REPORT],
        %w[Campaign\ Negative\ Placements\ Performance\ Report
           CAMPAIGN_NEGATIVE_PLACEMENTS_PERFORMANCE_REPORT],
        %w[Shared\ Set\ Report SHARED_SET_REPORT],
        %w[Campaign\ Shared\ Set\ Report CAMPAIGN_SHARED_SET_REPORT],
        %w[Shared\ Set\ Criteria\ Report SHARED_SET_CRITERIA_REPORT],
        %w[Call\ Metrics\ Call\ Details\ Report
           CALL_METRICS_CALL_DETAILS_REPORT],
        %w[Creative\ Conversion\ Report CREATIVE_CONVERSION_REPORT],
        %w[Keywordless\ Query\ Report KEYWORDLESS_QUERY_REPORT],
        %w[Keywordless\ Category\ Report KEYWORDLESS_CATEGORY_REPORT],
        %w[Criteria\ Performance\ Report CRITERIA_PERFORMANCE_REPORT],
        %w[Click\ Performance\ Report CLICK_PERFORMANCE_REPORT],
        %w[Budget\ Performance\ Report BUDGET_PERFORMANCE_REPORT],
        %w[Bid\ Goal\ Performance\ Report BID_GOAL_PERFORMANCE_REPORT],
        %w[Display\ Keyword\ Performance\ Report
           DISPLAY_KEYWORD_PERFORMANCE_REPORT],
        %w[Placeholder\ Feed\ Item\ Report PLACEHOLDER_FEED_ITEM_REPORT],
        %w[Placement\ Performance\ Report PLACEMENT_PERFORMANCE_REPORT],
        %w[Campaign\ Negative\ Locations\ Report
           CAMPAIGN_NEGATIVE_LOCATIONS_REPORT],
        %w[Gender\ Performance\ Report GENDER_PERFORMANCE_REPORT],
        %w[Campaign\ Location\ Target\ Report
           CAMPAIGN_LOCATION_TARGET_REPORT],
        %w[Campaign\ Ad\ Schedule\ Target\ Report
           CAMPAIGN_AD_SCHEDULE_TARGET_REPORT],
        %w[Audience\ Performance\ Report AUDIENCE_PERFORMANCE_REPORT],
        %w[Display\ Topics\ Performance\ Report
           DISPLAY_TOPICS_PERFORMANCE_REPORT],
        %w[User\ Ad\ Distance\ Report USER_AD_DISTANCE_REPORT],
        %w[Shopping\ Performance\ Report SHOPPING_PERFORMANCE_REPORT],
        %w[Product\ Partition\ Report PRODUCT_PARTITION_REPORT],
        %w[Parental\ Status\ Performance\ Report
           PARENTAL_STATUS_PERFORMANCE_REPORT],
        %w[Placeholder\ Report PLACEHOLDER_REPORT],
        %w[Ad\ Customizers\ Feed\ Item\ Report AD_CUSTOMIZERS_FEED_ITEM_REPORT],
        %w[Label\ Report LABEL_REPORT],
        %w[Final\ URL\ Report FINAL_URL_REPORT],
        %w[Video\ Performance\ Report VIDEO_PERFORMANCE_REPORT],
        %w[Top\ Content\ Performance\ Report TOP_CONTENT_PERFORMANCE_REPORT],
        %w[Campaign\ Criteria\ Report CAMPAIGN_CRITERIA_REPORT],
        %w[Campaign\ Group\ Performance\ Report
           CAMPAIGN_GROUP_PERFORMANCE_REPORT],
        %w[Landing\ Page\ Report LANDING_PAGE_REPORT],
        %w[Marketplace\ Performance\ Report MARKETPLACE_PERFORMANCE_REPORT],
        %w[Campaign\ Performance\ Report CAMPAIGN_PERFORMANCE_REPORT],
        %w[Age\ Range\ Performance\ Report AGE_RANGE_PERFORMANCE_REPORT],
        %w[Keywords\ Performance\ Report KEYWORDS_PERFORMANCE_REPORT],
        %w[Paid\ and\ Organic\ Query\ Report PAID_ORGANIC_QUERY_REPORT]
      ]
    end,
    report_fields: lambda do |connection, report_type:|
      if report_type.present?
        call('build_report_fields',
             'report_type' => report_type,
             'client_customer_id' => connection['manager_account_customer_id'],
             'developer_token' => connection['developer_token'])
      else
        []
      end
    end,
    report_fields_query: lambda do |connection, report_type:|
      if report_type.present?
        call('build_report_fields',
             'report_type' => report_type,
             'client_customer_id' => connection['manager_account_customer_id'],
             'developer_token' => connection['developer_token'])
      else
        []
      end
    end,
    user_list_fields: lambda do
      [
        %w[Access\ reason AccessReason],
        %w[Account\ user\ list\ status AccountUserListStatus],
        %w[App\ ID AppId],
        %w[Closing\ reason ClosingReason],
        %w[Conversion\ types ConversionTypes],
        %w[Data\ source\ type DataSourceType],
        %w[Data\ upload\ result DataUploadResult],
        %w[Date\ specific\ list\ end\ date DateSpecificListEndDate],
        %w[Date\ specific\ list\ rule DateSpecificListRule],
        %w[Date\ specific\ list\ start\ date DateSpecificListStartDate],
        %w[Description Description],
        %w[Expression\ list\ rule ExpressionListRule],
        %w[ID Id],
        %w[Integration\ code IntegrationCode],
        %w[Is\ eligible\ for\ display IsEligibleForDisplay],
        %w[Is\ eligible\ for\ search IsEligibleForSearch],
        %w[Is\ read\ only IsReadOnly],
        %w[List\ type ListType],
        %w[Membership\ life\ span MembershipLifeSpan],
        %w[Name Name],
        %w[Prepopulation\ status PrepopulationStatus],
        %w[Rules Rules],
        %w[Seed\ list\ size SeedListSize],
        %w[Seed\ user\ list\ description SeedUserListDescription],
        %w[Seed\ user\ list\ ID SeedUserListId],
        %w[Seed\ user\ list\ name SeedUserListName],
        %w[Seed\ user\ list\ status SeedUserListStatus],
        %w[Size Size],
        %w[Size\ for\ search SizeForSearch],
        %w[Size\ range SizeRange],
        %w[Size\ range\ for\ search SizeRangeForSearch],
        %w[Status Status],
        %w[Upload\ key\ type UploadKeyType]
      ]
    end,
    user_list_fields_query: lambda do
      [
        %w[Access\ reason AccessReason],
        %w[Account\ user\ list\ status AccountUserListStatus],
        %w[Closing\ reason ClosingReason],
        %w[Data\ source\ type DataSourceType],
        %w[ID Id],
        %w[Integration\ code IntegrationCode],
        %w[Is\ eligible\ for\ display IsEligibleForDisplay],
        %w[Is\ eligible\ for\ search IsEligibleForSearch],
        %w[List\ type ListType],
        %w[Membership\ life\ span MembershipLifeSpan],
        %w[Name Name],
        %w[Seed\ list\ size SeedListSize],
        %w[Seed\ user\ list\ ID SeedUserListId],
        %w[Size Size],
        %w[Size\ for\ search SizeForSearch],
        %w[Status Status]
      ]
    end,
    campaign_fields: lambda do
      [
        %w[ID Id],
        %w[Name Name],
        %w[Ad\ serving\ optimization\ status AdServingOptimizationStatus],
        %w[Advertising\ channel\ sub\ type AdvertisingChannelSubType],
        %w[Advertising\ channel\ type AdvertisingChannelType],
        %w[Amount Amount],
        %w[App\ ID AppId],
        %w[App\ vendor AppVendor],
        %w[Base\ campaign\ ID BaseCampaignId],
        %w[Bidding\ strategy\ goal\ type BiddingStrategyGoalType],
        %w[Bidding\ strategy\ ID BiddingStrategyId],
        %w[Bidding\ strategy\ name BiddingStrategyName],
        %w[Bidding\ strategy\ type BiddingStrategyType],
        %w[Budget\ ID BudgetId],
        %w[Budget\ name BudgetName],
        %w[Budget\ reference\ count BudgetReferenceCount],
        %w[Budget\ status BudgetStatus],
        %w[Campaign\ group\ ID CampaignGroupId],
        %w[Campaign\ trial\ type CampaignTrialType],
        %w[Delivery\ method DeliveryMethod],
        %w[Eligible Eligible],
        %w[End\ date EndDate],
        %w[Enhanced\ CPC\ enabled EnhancedCpcEnabled],
        %w[Final\ URL\ suffix FinalUrlSuffix],
        %w[Frequency\ cap\ max\ impressions FrequencyCapMaxImpressions],
        %w[Is\ budget\ explicitly\ shared IsBudgetExplicitlyShared],
        %w[Labels Labels],
        %w[Level Level],
        %w[Maximize\ conversion\ value\ target\ ROAS MaximizeConversionValueTargetRoas],
        %w[Rejection\ reasons RejectionReasons],
        %w[Selective\ optimization SelectiveOptimization],
        %w[Serving\ status ServingStatus],
        %w[Settings Settings],
        %w[Start\ date StartDate],
        %w[Status Status],
        %w[Target\ content\ network TargetContentNetwork],
        %w[Target\ CPA TargetCpa],
        %w[Target\ CPA\ max\ CPC\ BidCeiling TargetCpaMaxCpcBidCeiling],
        %w[Target\ CPA\ max\ CPC\ bid\ floor TargetCpaMaxCpcBidFloor],
        %w[Target\ Google\ search TargetGoogleSearch],
        %w[Target\ partner\ search\ network TargetPartnerSearchNetwork],
        %w[Target\ ROAS TargetRoas],
        %w[Target\ ROAS\ bid\ ceiling TargetRoasBidCeiling],
        %w[Target\ ROAS\ bid\ floor TargetRoasBidFloor],
        %w[Target\ search\ network TargetSearchNetwork],
        %w[Target\ spend\ bid\ ceiling TargetSpendBidCeiling],
        %w[Target\ spend\ target TargetSpendSpendTarget],
        %w[Time\ unit TimeUnit],
        %w[Tracking\ URL\ template TrackingUrlTemplate],
        %w[URL\ custom\ parameters UrlCustomParameters],
        %w[Vanity\ pharma\ display\ URL\ mode VanityPharmaDisplayUrlMode],
        %w[Vanity\ pharma\ text VanityPharmaText],
        %w[Viewable\ CPM\ enabled ViewableCpmEnabled]
      ]
    end,
    campaign_fields_query: lambda do
      [
        %w[ID Id],
        %w[Name Name],
        %w[Advertising\ channel\ sub\ type AdvertisingChannelSubType],
        %w[Advertising\ channel\ type AdvertisingChannelType],
        %w[Amount Amount],
        %w[App\ ID AppId],
        %w[App\ vendor AppVendor],
        %w[Base\ campaign\ ID BaseCampaignId],
        %w[Bidding\ strategy\ goal\ type BiddingStrategyGoalType],
        %w[Bidding\ strategy\ ID BiddingStrategyId],
        %w[Bidding\ strategy\ name BiddingStrategyName],
        %w[Bidding\ strategy\ type BiddingStrategyType],
        %w[Budget\ ID BudgetId],
        %w[Budget\ reference\ count BudgetReferenceCount],
        %w[Budget\ status BudgetStatus],
        %w[Campaign\ group\ ID CampaignGroupId],
        %w[Campaign\ trial\ type CampaignTrialType],
        %w[End\ date EndDate],
        %w[Enhanced\ CPC\ enabled EnhancedCpcEnabled],
        %w[Final\ URL\ suffix FinalUrlSuffix],
        %w[Frequency\ cap\ max\ impressions FrequencyCapMaxImpressions],
        %w[Labels Labels],
        %w[Level Level],
        %w[Maximize\ conversion\ value\ target\ ROAS MaximizeConversionValueTargetRoas],
        %w[Serving\ status ServingStatus],
        %w[Start\ date StartDate],
        %w[Status Status],
        %w[Target\ content\ network TargetContentNetwork],
        %w[Target\ CPA\ max\ CPC\ BidCeiling TargetCpaMaxCpcBidCeiling],
        %w[Target\ CPA\ max\ CPC\ bid\ floor TargetCpaMaxCpcBidFloor],
        %w[Target\ Google\ search TargetGoogleSearch],
        %w[Target\ partner\ search\ network TargetPartnerSearchNetwork],
        %w[Target\ search\ network TargetSearchNetwork],
        %w[Time\ unit TimeUnit],
        %w[Tracking\ URL\ template TrackingUrlTemplate],
        %w[Vanity\ pharma\ display\ URL\ mode VanityPharmaDisplayUrlMode],
        %w[Vanity\ pharma\ text VanityPharmaText],
        %w[Viewable\ CPM\ enabled ViewableCpmEnabled]
      ]
    end,
    predicate_operators: lambda do
      [
        %w[Equals _eq_],
        %w[Not\ equals !=],
        %w[In IN],
        %w[Not\ in NOT_IN],
        %w[Greater\ than >],
        %w[Greater\ than\ or\ equal\ to >=],
        %w[Less\ than <],
        %w[Less\ than\ or\ equal\ to <=],
        %w[Starts\ with STARTS_WITH],
        %w[Starts\ with\ ignore\ case STARTS_WITH_IGNORE_CASE],
        %w[Contains CONTAINS],
        %w[Contains\ ignore\ case CONTAINS_IGNORE_CASE],
        %w[Does\ not\ contain DOES_NOT_CONTAIN],
        %w[Does\ not\ contain\ ignore\ case DOES_NOT_CONTAIN_IGNORE_CASE],
        %w[Contains\ any CONTAINS_ANY],
        %w[Contains\ all CONTAINS_ALL],
        %w[Contains\ none CONTAINS_NONE]
      ]
    end,
    date_range_types: lambda do
      [
        %w[All\ time ALL_TIME],
        %w[Today TODAY],
        %w[Yesterday YESTERDAY],
        %w[Last\ 7\ days LAST_7_DAYS],
        %w[Last\ week LAST_WEEK],
        %w[Last\ business\ week LAST_BUSINESS_WEEK],
        %w[This\ month THIS_MONTH],
        %w[Last\ month LAST_MONTH],
        %w[Custom\ date CUSTOM_DATE],
        %w[Last\ 14\ days LAST_14_DAYS],
        %w[Last\ 30\ days LAST_30_DAYS],
        %w[This\ week\ Sunday\ until\ today THIS_WEEK_SUN_TODAY],
        %w[This\ week\ Monday\ until\ today THIS_WEEK_MON_TODAY],
        %w[Last\ week\ Sunday\ to\ Saturday LAST_WEEK_SUN_SAT]
      ]
    end,
    downloadable_formats: lambda do
      [
        %w[CSV CSV],
        %w[XML XML],
        %w[TSV TSV],
        %w[CSV\ for\ Excel CSVFOREXCEL],
        %w[Gzipped\ CSV GZIPPED_CSV],
        %w[Gzipped\ XML GZIPPED_XML]
      ]
    end,
    ad_serving_optimization_status: lambda do
      [
        %w[Optimize OPTIMIZE],
        %w[Conversion\ optimize CONVERSION_OPTIMIZE],
        %w[Rotate ROTATE],
        %w[Rotate\ indefinitely ROTATE_INDEFINITELY],
        %w[Unavailable UNAVAILABLE]
      ]
    end,
    advertising_channel_subtype: lambda do
      [
        %w[Search\ mobile\ app SEARCH_MOBILE_APP],
        %w[Display\ mobile\ app DISPLAY_MOBILE_APP],
        %w[Search\ express SEARCH_EXPRESS],
        %w[Display\ express DISPLAY_EXPRESS],
        %w[Universal\ app\ campaign UNIVERSAL_APP_CAMPAIGN],
        %w[Display\ smart\ campaign DISPLAY_SMART_CAMPAIGN],
        %w[Shopping\ goal\ optimized\ ads SHOPPING_GOAL_OPTIMIZED_ADS],
        %w[Display\ Gmail ad DISPLAY_GMAIL_AD]
      ]
    end,
    bidding_strategy_type: lambda do
      [
        %w[Manual\ CPC MANUAL_CPC],
        %w[Manual\ CPM MANUAL_CPM],
        %w[Page\ one\ promoted PAGE_ONE_PROMOTED],
        %w[Target\ spend TARGET_SPEND],
        %w[Target\ CPA TARGET_CPA],
        %w[Target\ ROAS TARGET_ROAS],
        %w[Maximize\ conversions MAXIMIZE_CONVERSIONS],
        %w[Maximize\ conversion\ value MAXIMIZE_CONVERSION_VALUE],
        %w[Target\ outrank\ share TARGET_OUTRANK_SHARE],
        %w[None NONE]
      ]
    end,
    vanity_pharma_text: lambda do
      [
        %w[Prescription\ treatment\ website(English)
           PRESCRIPTION_TREATMENT_WEBSITE_EN],
        %w[Prescription\ treatment\ website(Spanish)
           PRESCRIPTION_TREATMENT_WEBSITE_ES],
        %w[Prescription\ Device\ website(English)
           PRESCRIPTION_DEVICE_WEBSITE_EN],
        %w[Prescription\ Device\ website(Spanish)
           PRESCRIPTION_DEVICE_WEBSITE_ES],
        %w[Medical\ device\ website(English) MEDICAL_DEVICE_WEBSITE_EN],
        %w[Medical\ device\ website(Spanish) MEDICAL_DEVICE_WEBSITE_ES],
        %w[Preventative\ treatment\ website(English)
           PREVENTATIVE_TREATMENT_WEBSITE_EN],
        %w[Preventative\ treatment\ website(Spanish)
           PREVENTATIVE_TREATMENT_WEBSITE_ES],
        %w[Prescription\ contraception\ website(English)
           PRESCRIPTION_CONTRACEPTION_WEBSITE_EN],
        %w[Prescription\ contraception\ website(Spanish)
           PRESCRIPTION_CONTRACEPTION_WEBSITE_ES],
        %w[Prescription\ vaccine\ website(English)
           PRESCRIPTION_VACCINE_WEBSITE_EN],
        %w[Prescription\ vaccine\ website(Spanish)
           PRESCRIPTION_VACCINE_WEBSITE_ES]
      ]
    end,
    bidding_strategy_goal_type: lambda do
      [
        %w[Optimize\ for\ install\ conversion\ volume
           OPTIMIZE_FOR_INSTALL_CONVERSION_VOLUME],
        %w[Optimize\ for\ in\ app\ conversion\ volume
           OPTIMIZE_FOR_IN_APP_CONVERSION_VOLUME],
        %w[Optimize\ for\ total\ conversion\ value
           OPTIMIZE_FOR_TOTAL_CONVERSION_VALUE],
        %w[Optimize\ for\ target\ in\ app\ conversion
           OPTIMIZE_FOR_TARGET_IN_APP_CONVERSION],
        %w[Optimize\ for\ return\ on\ advertising\ spend
           OPTIMIZE_FOR_RETURN_ON_ADVERTISING_SPEND]
      ]
    end,
    settings_type: lambda do
      [
        %w[Dynamic\ search\ ads\ setting DynamicSearchAdsSetting],
        %w[Geo\ target\ type\ setting GeoTargetTypeSetting],
        %w[Universal\ app\ campaign\ setting UniversalAppCampaignSetting],
        %w[Real\ time\ bidding\ setting RealTimeBiddingSetting],
        %w[Shopping\ setting ShoppingSetting],
        %w[Targeting\ setting TargetingSetting],
        %w[Tracking\ setting TrackingSetting]
      ]
    end,
    app_campaign_asset: lambda do
      [
        %w[Combination COMBINATION],
        %w[App\ destination APP_DESTINATION],
        %w[App\ assets APP_ASSETS],
        %w[Description\ 1 DESCRIPTION_1],
        %w[Description\ 2 DESCRIPTION_2],
        %w[Description\ 3 DESCRIPTION_3],
        %w[Description\ 4 DESCRIPTION_4],
        %w[Video VIDEO],
        %w[Image IMAGE]
      ]
    end,
    constraint_type: lambda do
      [
        %w[Country COUNTRY],
        %w[Reseller RESELLER],
        %w[Certificate\ missing\ in\ country CERTIFICATE_MISSING_IN_COUNTRY],
        %w[Certificate\ domain\ mismatch\ in\ country
           CERTIFICATE_DOMAIN_MISMATCH_IN_COUNTRY],
        %w[Certificate\ missing CERTIFICATE_MISSING],
        %w[Certificate\ domain\ mismatch CERTIFICATE_DOMAIN_MISMATCH],
        %w[Unknown UNKNOWN]
      ]
    end,
    criterion_type_group: lambda do
      [
        %w[Keyword KEYWORD],
        %w[User\ interest\ and\ list USER_INTEREST_AND_LIST],
        %w[Vertical VERTICAL],
        %w[Gender GENDER],
        %w[Age\ range AGE_RANGE],
        %w[Placement PLACEMENT],
        %w[Parent PARENT],
        %w[Income\ range INCOME_RANGE],
        %w[None NONE],
        %w[Unknown UNKNOWN]
      ]
    end,
    bidding_scheme_type: lambda do
      [
        %w[Manual\ CPC\ bidding\ scheme ManualCpcBiddingScheme],
        %w[Manual\ CPM\ bidding\ scheme ManualCpmBiddingScheme],
        %w[Page\ one\ promoted\ bidding\ scheme PageOnePromotedBiddingScheme],
        %w[Target\ CPA\ bidding\ scheme TargetCpaBiddingScheme],
        %w[Target\ ROAS\ bidding\ scheme TargetRoasBiddingScheme],
        %w[Target\ spend\ bidding\ scheme TargetSpendBiddingScheme],
        %w[Maximize\ conversion\ value\ bidding\ scheme
           MaximizeConversionValueBiddingScheme],
        %w[Maximize\ conversions\ bidding\ scheme
           MaximizeConversionsBiddingScheme],
        %w[Target\ outrank\ share\ bidding\ scheme
           TargetOutrankShareBiddingScheme]
      ]
    end,
    country_codes: lambda do
      [
        ['Afghanistan', 'AF'],
        ['Aland Islands', 'AX'],
        ['Albania', 'AL'],
        ['Algeria', 'DZ'],
        ['American Samoa', 'AS'],
        ['Andorra', 'AD'],
        ['Angola', 'AO'],
        ['Anguilla', 'AI'],
        ['Antarctica', 'AQ'],
        ['Antigua And Barbuda', 'AG'],
        ['Argentina', 'AR'],
        ['Armenia', 'AM'],
        ['Aruba', 'AW'],
        ['Australia', 'AU'],
        ['Austria', 'AT'],
        ['Azerbaijan', 'AZ'],
        ['Bahamas', 'BS'],
        ['Bahrain', 'BH'],
        ['Bangladesh', 'BD'],
        ['Barbados', 'BB'],
        ['Belarus', 'BY'],
        ['Belgium', 'BE'],
        ['Belize', 'BZ'],
        ['Benin', 'BJ'],
        ['Bermuda', 'BM'],
        ['Bhutan', 'BT'],
        ['Bolivia', 'BO'],
        ['Bosnia And Herzegovina', 'BA'],
        ['Botswana', 'BW'],
        ['Bouvet Island', 'BV'],
        ['Brazil', 'BR'],
        ['British Indian Ocean Territory', 'IO'],
        ['Brunei Darussalam', 'BN'],
        ['Bulgaria', 'BG'],
        ['Burkina Faso', 'BF'],
        ['Burundi', 'BI'],
        ['Cambodia', 'KH'],
        ['Cameroon', 'CM'],
        ['Canada', 'CA'],
        ['Cape Verde', 'CV'],
        ['Cayman Islands', 'KY'],
        ['Central African Republic', 'CF'],
        ['Chad', 'TD'],
        ['Chile', 'CL'],
        ['China', 'CN'],
        ['Christmas Island', 'CX'],
        ['Cocos (Keeling) Islands', 'CC'],
        ['Colombia', 'CO'],
        ['Comoros', 'KM'],
        ['Congo', 'CG'],
        ['Congo, Democratic Republic', 'CD'],
        ['Cook Islands', 'CK'],
        ['Costa Rica', 'CR'],
        ['Cote D\'Ivoire', 'CI'],
        ['Croatia', 'HR'],
        ['Cuba', 'CU'],
        ['Cyprus', 'CY'],
        ['Czech Republic', 'CZ'],
        ['Denmark', 'DK'],
        ['Djibouti', 'DJ'],
        ['Dominica', 'DM'],
        ['Dominican Republic', 'DO'],
        ['Ecuador', 'EC'],
        ['Egypt', 'EG'],
        ['El Salvador', 'SV'],
        ['Equatorial Guinea', 'GQ'],
        ['Eritrea', 'ER'],
        ['Estonia', 'EE'],
        ['Ethiopia', 'ET'],
        ['Falkland Islands (Malvinas)', 'FK'],
        ['Faroe Islands', 'FO'],
        ['Fiji', 'FJ'],
        ['Finland', 'FI'],
        ['France', 'FR'],
        ['French Guiana', 'GF'],
        ['French Polynesia', 'PF'],
        ['French Southern Territories', 'TF'],
        ['Gabon', 'GA'],
        ['Gambia', 'GM'],
        ['Georgia', 'GE'],
        ['Germany', 'DE'],
        ['Ghana', 'GH'],
        ['Gibraltar', 'GI'],
        ['Greece', 'GR'],
        ['Greenland', 'GL'],
        ['Grenada', 'GD'],
        ['Guadeloupe', 'GP'],
        ['Guam', 'GU'],
        ['Guatemala', 'GT'],
        ['Guernsey', 'GG'],
        ['Guinea', 'GN'],
        ['Guinea-Bissau', 'GW'],
        ['Guyana', 'GY'],
        ['Haiti', 'HT'],
        ['Heard Island & Mcdonald Islands', 'HM'],
        ['Holy See (Vatican City State)', 'VA'],
        ['Honduras', 'HN'],
        ['Hong Kong', 'HK'],
        ['Hungary', 'HU'],
        ['Iceland', 'IS'],
        ['India', 'IN'],
        ['Indonesia', 'ID'],
        ['Iran, Islamic Republic Of', 'IR'],
        ['Iraq', 'IQ'],
        ['Ireland', 'IE'],
        ['Isle Of Man', 'IM'],
        ['Israel', 'IL'],
        ['Italy', 'IT'],
        ['Jamaica', 'JM'],
        ['Japan', 'JP'],
        ['Jersey', 'JE'],
        ['Jordan', 'JO'],
        ['Kazakhstan', 'KZ'],
        ['Kenya', 'KE'],
        ['Kiribati', 'KI'],
        ['Korea', 'KR'],
        ['Kuwait', 'KW'],
        ['Kyrgyzstan', 'KG'],
        ['Lao People\'s Democratic Republic', 'LA'],
        ['Latvia', 'LV'],
        ['Lebanon', 'LB'],
        ['Lesotho', 'LS'],
        ['Liberia', 'LR'],
        ['Libyan Arab Jamahiriya', 'LY'],
        ['Liechtenstein', 'LI'],
        ['Lithuania', 'LT'],
        ['Luxembourg', 'LU'],
        ['Macao', 'MO'],
        ['Macedonia', 'MK'],
        ['Madagascar', 'MG'],
        ['Malawi', 'MW'],
        ['Malaysia', 'MY'],
        ['Maldives', 'MV'],
        ['Mali', 'ML'],
        ['Malta', 'MT'],
        ['Marshall Islands', 'MH'],
        ['Martinique', 'MQ'],
        ['Mauritania', 'MR'],
        ['Mauritius', 'MU'],
        ['Mayotte', 'YT'],
        ['Mexico', 'MX'],
        ['Micronesia, Federated States Of', 'FM'],
        ['Moldova', 'MD'],
        ['Monaco', 'MC'],
        ['Mongolia', 'MN'],
        ['Montenegro', 'ME'],
        ['Montserrat', 'MS'],
        ['Morocco', 'MA'],
        ['Mozambique', 'MZ'],
        ['Myanmar', 'MM'],
        ['Namibia', 'NA'],
        ['Nauru', 'NR'],
        ['Nepal', 'NP'],
        ['Netherlands', 'NL'],
        ['Netherlands Antilles', 'AN'],
        ['New Caledonia', 'NC'],
        ['New Zealand', 'NZ'],
        ['Nicaragua', 'NI'],
        ['Niger', 'NE'],
        ['Nigeria', 'NG'],
        ['Niue', 'NU'],
        ['Norfolk Island', 'NF'],
        ['Northern Mariana Islands', 'MP'],
        ['Norway', 'NO'],
        ['Oman', 'OM'],
        ['Pakistan', 'PK'],
        ['Palau', 'PW'],
        ['Palestinian Territory, Occupied', 'PS'],
        ['Panama', 'PA'],
        ['Papua New Guinea', 'PG'],
        ['Paraguay', 'PY'],
        ['Peru', 'PE'],
        ['Philippines', 'PH'],
        ['Pitcairn', 'PN'],
        ['Poland', 'PL'],
        ['Portugal', 'PT'],
        ['Puerto Rico', 'PR'],
        ['Qatar', 'QA'],
        ['Reunion', 'RE'],
        ['Romania', 'RO'],
        ['Russian Federation', 'RU'],
        ['Rwanda', 'RW'],
        ['Saint Barthelemy', 'BL'],
        ['Saint Helena', 'SH'],
        ['Saint Kitts And Nevis', 'KN'],
        ['Saint Lucia', 'LC'],
        ['Saint Martin', 'MF'],
        ['Saint Pierre And Miquelon', 'PM'],
        ['Saint Vincent And Grenadines', 'VC'],
        ['Samoa', 'WS'],
        ['San Marino', 'SM'],
        ['Sao Tome And Principe', 'ST'],
        ['Saudi Arabia', 'SA'],
        ['Senegal', 'SN'],
        ['Serbia', 'RS'],
        ['Seychelles', 'SC'],
        ['Sierra Leone', 'SL'],
        ['Singapore', 'SG'],
        ['Slovakia', 'SK'],
        ['Slovenia', 'SI'],
        ['Solomon Islands', 'SB'],
        ['Somalia', 'SO'],
        ['South Africa', 'ZA'],
        ['South Georgia And Sandwich Isl.', 'GS'],
        ['Spain', 'ES'],
        ['Sri Lanka', 'LK'],
        ['Sudan', 'SD'],
        ['Suriname', 'SR'],
        ['Svalbard And Jan Mayen', 'SJ'],
        ['Swaziland', 'SZ'],
        ['Sweden', 'SE'],
        ['Switzerland', 'CH'],
        ['Syrian Arab Republic', 'SY'],
        ['Taiwan', 'TW'],
        ['Tajikistan', 'TJ'],
        ['Tanzania', 'TZ'],
        ['Thailand', 'TH'],
        ['Timor-Leste', 'TL'],
        ['Togo', 'TG'],
        ['Tokelau', 'TK'],
        ['Tonga', 'TO'],
        ['Trinidad And Tobago', 'TT'],
        ['Tunisia', 'TN'],
        ['Turkey', 'TR'],
        ['Turkmenistan', 'TM'],
        ['Turks And Caicos Islands', 'TC'],
        ['Tuvalu', 'TV'],
        ['Uganda', 'UG'],
        ['Ukraine', 'UA'],
        ['United Arab Emirates', 'AE'],
        ['United Kingdom', 'GB'],
        ['United States', 'US'],
        ['United States Outlying Islands', 'UM'],
        ['Uruguay', 'UY'],
        ['Uzbekistan', 'UZ'],
        ['Vanuatu', 'VU'],
        ['Venezuela', 'VE'],
        ['Viet Nam', 'VN'],
        ['Virgin Islands, British', 'VG'],
        ['Virgin Islands, U.S.', 'VI'],
        ['Wallis And Futuna', 'WF'],
        ['Western Sahara', 'EH'],
        ['Yemen', 'YE'],
        ['Zambia', 'ZM'],
        ['Zimbabwe', 'ZW']
      ]
    end,
    currency_codes: lambda do
      [
        ['Afghan Afghani', 'AFA'],
        ['Aruban Florin', 'AWG'],
        ['Australian Dollars', 'AUD'],
        ['Argentine Pes', 'ARS'],
        ['Azerbaijanian Manat', 'AZN'],
        ['Bahamian Dollar', 'BSD'],
        ['Bangladeshi Taka', 'BDT'],
        ['Barbados Dollar', 'BBD'],
        ['Belarussian Rouble', 'BYR'],
        ['Bolivian Boliviano', 'BOB'],
        ['Brazilian Real', 'BRL'],
        ['British Pounds Sterling', 'GBP'],
        ['Bulgarian Lev', 'BGN'],
        ['Cambodia Riel', 'KHR'],
        ['Canadian Dollars', 'CAD'],
        ['Cayman Islands Dollar', 'KYD'],
        ['Chilean Peso', 'CLP'],
        ['Chinese Renminbi Yuan', 'CNY'],
        ['Colombian Peso', 'COP'],
        ['Costa Rican Colon', 'CRC'],
        ['Croatia Kuna', 'HRK'],
        ['Cypriot Pounds', 'CPY'],
        ['Czech Koruna', 'CZK'],
        ['Danish Krone', 'DKK'],
        ['Dominican Republic Peso', 'DOP'],
        ['East Caribbean Dollar', 'XCD'],
        ['Egyptian Pound', 'EGP'],
        ['Eritrean Nakfa', 'ERN'],
        ['Estonia Kroon', 'EEK'],
        ['Euro', 'EUR'],
        ['Georgian Lari', 'GEL'],
        ['Ghana Cedi', 'GHC'],
        ['Gibraltar Pound', 'GIP'],
        ['Guatemala Quetzal', 'GTQ'],
        ['Honduras Lempira', 'HNL'],
        ['Hong Kong Dollars', 'HKD'],
        ['Hungary Forint', 'HUF'],
        ['Icelandic Krona', 'ISK'],
        ['Indian Rupee', 'INR'],
        ['Indonesia Rupiah', 'IDR'],
        ['Israel Shekel', 'ILS'],
        ['Jamaican Dollar', 'JMD'],
        ['Japanese yen', 'JPY'],
        ['Kazakhstan Tenge', 'KZT'],
        ['Kenyan Shilling', 'KES'],
        ['Kuwaiti Dinar', 'KWD'],
        ['Latvia Lat', 'LVL'],
        ['Lebanese Pound', 'LBP'],
        ['Lithuania Litas', 'LTL'],
        ['Macau Pataca', 'MOP'],
        ['Macedonian Denar', 'MKD'],
        ['Malagascy Ariary', 'MGA'],
        ['Malaysian Ringgit', 'MYR'],
        ['Maltese Lira', 'MTL'],
        ['Marka', 'BAM'],
        ['Mauritius Rupee', 'MUR'],
        ['Mexican Pesos', 'MXN'],
        ['Mozambique Metical', 'MZM'],
        ['Nepalese Rupee', 'NPR'],
        ['Netherlands Antilles Guilder', 'ANG'],
        ['New Taiwanese Dollars', 'TWD'],
        ['New Zealand Dollars', 'NZD'],
        ['Nicaragua Cordoba', 'NIO'],
        ['Nigeria Naira', 'NGN'],
        ['North Korean Won', 'KPW'],
        ['Norwegian Krone', 'NOK'],
        ['Omani Riyal', 'OMR'],
        ['Pakistani Rupee', 'PKR'],
        ['Paraguay Guarani', 'PYG'],
        ['Peru New Sol', 'PEN'],
        ['Philippine Pesos', 'PHP'],
        ['Qatari Riyal', 'QAR'],
        ['Romanian New Leu', 'RON'],
        ['Russian Federation Ruble', 'RUB'],
        ['Saudi Riyal', 'SAR'],
        ['Serbian Dinar', 'CSD'],
        ['Seychelles Rupee', 'SCR'],
        ['Singapore Dollars', 'SGD'],
        ['Slovak Koruna', 'SKK'],
        ['Slovenia Tolar', 'SIT'],
        ['South African Rand', 'ZAR'],
        ['South Korean Won', 'KRW'],
        ['Sri Lankan Rupee', 'LKR'],
        ['Surinam Dollar', 'SRD'],
        ['Swedish Krona', 'SEK'],
        ['Swiss Francs', 'CHF'],
        ['Tanzanian Shilling', 'TZS'],
        ['Thai Baht', 'THB'],
        ['Trinidad and Tobago Dollar', 'TTD'],
        ['Turkish New Lira', 'TRY'],
        ['UAE Dirham', 'AED'],
        ['US Dollars', 'USD'],
        ['Ugandian Shilling', 'UGX'],
        ['Ukraine Hryvna', 'UAH'],
        ['Uruguayan Peso', 'UYU'],
        ['Uzbekistani Som', 'UZS'],
        ['Venezuela Bolivar', 'VEB'],
        ['Vietnam Dong', 'VND'],
        ['Zambian Kwacha', 'AMK'],
        ['Zimbabwe Dollar', 'ZWD']
      ]
    end,
    timezones: lambda do
      [
        %w[Africa/Abidjan Africa/Abidjan],
        %w[Africa/Accra Africa/Accra],
        %w[Africa/Algiers Africa/Algiers],
        %w[Africa/Bissau Africa/Bissau],
        %w[Africa/Cairo Africa/Cairo],
        %w[Africa/Casablanca Africa/Casablanca],
        %w[Africa/Ceuta Africa/Ceuta],
        %w[Africa/El_Aaiun Africa/El_Aaiun],
        %w[Africa/Johannesburg Africa/Johannesburg],
        %w[Africa/Juba Africa/Juba],
        %w[Africa/Khartoum Africa/Khartoum],
        %w[Africa/Lagos Africa/Lagos],
        %w[Africa/Maputo Africa/Maputo],
        %w[Africa/Monrovia Africa/Monrovia],
        %w[Africa/Nairobi Africa/Nairobi],
        %w[Africa/Ndjamena Africa/Ndjamena],
        %w[Africa/Tripoli Africa/Tripoli],
        %w[Africa/Tunis Africa/Tunis],
        %w[Africa/Windhoek Africa/Windhoek],
        %w[America/Adak America/Adak],
        %w[America/Anchorage America/Anchorage],
        %w[America/Araguaina America/Araguaina],
        %w[America/Argentina/Buenos_Aires America/Argentina/Buenos_Aires],
        %w[America/Argentina/Catamarca America/Argentina/Catamarca],
        %w[America/Argentina/Cordoba America/Argentina/Cordoba],
        %w[America/Argentina/Jujuy America/Argentina/Jujuy],
        %w[America/Argentina/La_Rioja America/Argentina/La_Rioja],
        %w[America/Argentina/Mendoza America/Argentina/Mendoza],
        %w[America/Argentina/Rio_Gallegos America/Argentina/Rio_Gallegos],
        %w[America/Argentina/Salta America/Argentina/Salta],
        %w[America/Argentina/San_Juan America/Argentina/San_Juan],
        %w[America/Argentina/San_Luis America/Argentina/San_Luis],
        %w[America/Argentina/Tucuman America/Argentina/Tucuman],
        %w[America/Argentina/Ushuaia America/Argentina/Ushuaia],
        %w[America/Asuncion America/Asuncion],
        %w[America/Atikokan America/Atikokan],
        %w[America/Bahia America/Bahia],
        %w[America/Bahia_Banderas America/Bahia_Banderas],
        %w[America/Barbados America/Barbados],
        %w[America/Belem America/Belem],
        %w[America/Belize America/Belize],
        %w[America/Blanc-Sablon America/Blanc-Sablon],
        %w[America/Boa_Vista America/Boa_Vista],
        %w[America/Bogota America/Bogota],
        %w[America/Boise America/Boise],
        %w[America/Cambridge_Bay America/Cambridge_Bay],
        %w[America/Campo_Grande America/Campo_Grande],
        %w[America/Cancun America/Cancun],
        %w[America/Caracas America/Caracas],
        %w[America/Cayenne America/Cayenne],
        %w[America/Chicago America/Chicago],
        %w[America/Chihuahua America/Chihuahua],
        %w[America/Costa_Rica America/Costa_Rica],
        %w[America/Creston America/Creston],
        %w[America/Cuiaba America/Cuiaba],
        %w[America/Curacao America/Curacao],
        %w[America/Danmarkshavn America/Danmarkshavn],
        %w[America/Dawson America/Dawson],
        %w[America/Dawson_Creek America/Dawson_Creek],
        %w[America/Denver America/Denver],
        %w[America/Detroit America/Detroit],
        %w[America/Edmonton America/Edmonton],
        %w[America/Eirunepe America/Eirunepe],
        %w[America/El_Salvador America/El_Salvador],
        %w[America/Fort_Nelson America/Fort_Nelson],
        %w[America/Fortaleza America/Fortaleza],
        %w[America/Glace_Bay America/Glace_Bay],
        %w[America/Godthab America/Godthab],
        %w[America/Goose_Bay America/Goose_Bay],
        %w[America/Grand_Turk America/Grand_Turk],
        %w[America/Guatemala America/Guatemala],
        %w[America/Guayaquil America/Guayaquil],
        %w[America/Guyana America/Guyana],
        %w[America/Halifax America/Halifax],
        %w[America/Havana America/Havana],
        %w[America/Hermosillo America/Hermosillo],
        %w[America/Indiana/Indianapolis America/Indiana/Indianapolis],
        %w[America/Indiana/Knox America/Indiana/Knox],
        %w[America/Indiana/Marengo America/Indiana/Marengo],
        %w[America/Indiana/Petersburg America/Indiana/Petersburg],
        %w[America/Indiana/Tell_City America/Indiana/Tell_City],
        %w[America/Indiana/Vevay America/Indiana/Vevay],
        %w[America/Indiana/Vincennes America/Indiana/Vincennes],
        %w[America/Indiana/Winamac America/Indiana/Winamac],
        %w[America/Inuvik America/Inuvik],
        %w[America/Iqaluit America/Iqaluit],
        %w[America/Jamaica America/Jamaica],
        %w[America/Juneau America/Juneau],
        %w[America/Kentucky/Louisville America/Kentucky/Louisville],
        %w[America/Kentucky/Monticello America/Kentucky/Monticello],
        %w[America/La_Paz America/La_Paz],
        %w[America/Lima America/Lima],
        %w[America/Los_Angeles America/Los_Angeles],
        %w[America/Maceio America/Maceio],
        %w[America/Managua America/Managua],
        %w[America/Manaus America/Manaus],
        %w[America/Martinique America/Martinique],
        %w[America/Matamoros America/Matamoros],
        %w[America/Mazatlan America/Mazatlan],
        %w[America/Menominee America/Menominee],
        %w[America/Merida America/Merida],
        %w[America/Metlakatla America/Metlakatla],
        %w[America/Mexico_City America/Mexico_City],
        %w[America/Miquelon America/Miquelon],
        %w[America/Moncton America/Moncton],
        %w[America/Monterrey America/Monterrey],
        %w[America/Montevideo America/Montevideo],
        %w[America/Nassau America/Nassau],
        %w[America/New_York America/New_York],
        %w[America/Nipigon America/Nipigon],
        %w[America/Nome America/Nome],
        %w[America/Noronha America/Noronha],
        %w[America/North_Dakota/Beulah America/North_Dakota/Beulah],
        %w[America/North_Dakota/Center America/North_Dakota/Center],
        %w[America/North_Dakota/New_Salem America/North_Dakota/New_Salem],
        %w[America/Ojinaga America/Ojinaga],
        %w[America/Panama America/Panama],
        %w[America/Pangnirtung America/Pangnirtung],
        %w[America/Paramaribo America/Paramaribo],
        %w[America/Phoenix America/Phoenix],
        %w[America/Port_of_Spain America/Port_of_Spain],
        %w[America/Port-au-Prince America/Port-au-Prince],
        %w[America/Porto_Velho America/Porto_Velho],
        %w[America/Puerto_Rico America/Puerto_Rico],
        %w[America/Punta_Arenas America/Punta_Arenas],
        %w[America/Rainy_River America/Rainy_River],
        %w[America/Rankin_Inlet America/Rankin_Inlet],
        %w[America/Recife America/Recife],
        %w[America/Regina America/Regina],
        %w[America/Resolute America/Resolute],
        %w[America/Rio_Branco America/Rio_Branco],
        %w[America/Santarem America/Santarem],
        %w[America/Santiago America/Santiago],
        %w[America/Santo_Domingo America/Santo_Domingo],
        %w[America/Sao_Paulo America/Sao_Paulo],
        %w[America/Scoresbysund America/Scoresbysund],
        %w[America/Sitka America/Sitka],
        %w[America/St_Johns America/St_Johns],
        %w[America/Swift_Current America/Swift_Current],
        %w[America/Tegucigalpa America/Tegucigalpa],
        %w[America/Thule America/Thule],
        %w[America/Thunder_Bay America/Thunder_Bay],
        %w[America/Tijuana America/Tijuana],
        %w[America/Toronto America/Toronto],
        %w[America/Vancouver America/Vancouver],
        %w[America/Whitehorse America/Whitehorse],
        %w[America/Winnipeg America/Winnipeg],
        %w[America/Yakutat America/Yakutat],
        %w[America/Yellowknife America/Yellowknife],
        %w[Antarctica/Casey Antarctica/Casey],
        %w[Antarctica/Davis Antarctica/Davis],
        %w[Antarctica/DumontDUrville Antarctica/DumontDUrville],
        %w[Antarctica/Macquarie Antarctica/Macquarie],
        %w[Antarctica/Mawson Antarctica/Mawson],
        %w[Antarctica/Palmer Antarctica/Palmer],
        %w[Antarctica/Rothera Antarctica/Rothera],
        %w[Antarctica/Syowa Antarctica/Syowa],
        %w[Antarctica/Troll Antarctica/Troll],
        %w[Antarctica/Vostok Antarctica/Vostok],
        %w[Asia/Almaty Asia/Almaty],
        %w[Asia/Amman Asia/Amman],
        %w[Asia/Anadyr Asia/Anadyr],
        %w[Asia/Aqtau Asia/Aqtau],
        %w[Asia/Aqtobe Asia/Aqtobe],
        %w[Asia/Ashgabat Asia/Ashgabat],
        %w[Asia/Atyrau Asia/Atyrau],
        %w[Asia/Baghdad Asia/Baghdad],
        %w[Asia/Baku Asia/Baku],
        %w[Asia/Bangkok Asia/Bangkok],
        %w[Asia/Barnaul Asia/Barnaul],
        %w[Asia/Beirut Asia/Beirut],
        %w[Asia/Bishkek Asia/Bishkek],
        %w[Asia/Brunei Asia/Brunei],
        %w[Asia/Chita Asia/Chita],
        %w[Asia/Choibalsan Asia/Choibalsan],
        %w[Asia/Colombo Asia/Colombo],
        %w[Asia/Damascus Asia/Damascus],
        %w[Asia/Dhaka Asia/Dhaka],
        %w[Asia/Dili Asia/Dili],
        %w[Asia/Dubai Asia/Dubai],
        %w[Asia/Dushanbe Asia/Dushanbe],
        %w[Asia/Famagusta Asia/Famagusta],
        %w[Asia/Gaza Asia/Gaza],
        %w[Asia/Hebron Asia/Hebron],
        %w[Asia/Ho_Chi_Minh Asia/Ho_Chi_Minh],
        %w[Asia/Hong_Kong Asia/Hong_Kong],
        %w[Asia/Hovd Asia/Hovd],
        %w[Asia/Irkutsk Asia/Irkutsk],
        %w[Asia/Jakarta Asia/Jakarta],
        %w[Asia/Jayapura Asia/Jayapura],
        %w[Asia/Jerusalem Asia/Jerusalem],
        %w[Asia/Kabul Asia/Kabul],
        %w[Asia/Kamchatka Asia/Kamchatka],
        %w[Asia/Karachi Asia/Karachi],
        %w[Asia/Kathmandu Asia/Kathmandu],
        %w[Asia/Khandyga Asia/Khandyga],
        %w[Asia/Kolkata Asia/Kolkata],
        %w[Asia/Krasnoyarsk Asia/Krasnoyarsk],
        %w[Asia/Kuala_Lumpur Asia/Kuala_Lumpur],
        %w[Asia/Kuching Asia/Kuching],
        %w[Asia/Macau Asia/Macau],
        %w[Asia/Magadan Asia/Magadan],
        %w[Asia/Makassar Asia/Makassar],
        %w[Asia/Manila Asia/Manila],
        %w[Asia/Novokuznetsk Asia/Novokuznetsk],
        %w[Asia/Novosibirsk Asia/Novosibirsk],
        %w[Asia/Omsk Asia/Omsk],
        %w[Asia/Oral Asia/Oral],
        %w[Asia/Pontianak Asia/Pontianak],
        %w[Asia/Pyongyang Asia/Pyongyang],
        %w[Asia/Qatar Asia/Qatar],
        %w[Asia/Qyzylorda Asia/Qyzylorda],
        %w[Asia/Riyadh Asia/Riyadh],
        %w[Asia/Sakhalin Asia/Sakhalin],
        %w[Asia/Samarkand Asia/Samarkand],
        %w[Asia/Seoul Asia/Seoul],
        %w[Asia/Shanghai Asia/Shanghai],
        %w[Asia/Singapore Asia/Singapore],
        %w[Asia/Srednekolymsk Asia/Srednekolymsk],
        %w[Asia/Taipei Asia/Taipei],
        %w[Asia/Tashkent Asia/Tashkent],
        %w[Asia/Tbilisi Asia/Tbilisi],
        %w[Asia/Tehran Asia/Tehran],
        %w[Asia/Thimphu Asia/Thimphu],
        %w[Asia/Tokyo Asia/Tokyo],
        %w[Asia/Tomsk Asia/Tomsk],
        %w[Asia/Ulaanbaatar Asia/Ulaanbaatar],
        %w[Asia/Urumqi Asia/Urumqi],
        %w[Asia/Ust-Nera Asia/Ust-Nera],
        %w[Asia/Vladivostok Asia/Vladivostok],
        %w[Asia/Yakutsk Asia/Yakutsk],
        %w[Asia/Yangon Asia/Yangon],
        %w[Asia/Yekaterinburg Asia/Yekaterinburg],
        %w[Asia/Yerevan Asia/Yerevan],
        %w[Atlantic/Azores Atlantic/Azores],
        %w[Atlantic/Bermuda Atlantic/Bermuda],
        %w[Atlantic/Canary Atlantic/Canary],
        %w[Atlantic/Cape_Verde Atlantic/Cape_Verde],
        %w[Atlantic/Faroe Atlantic/Faroe],
        %w[Atlantic/Madeira Atlantic/Madeira],
        %w[Atlantic/Reykjavik Atlantic/Reykjavik],
        %w[Atlantic/South_Georgia Atlantic/South_Georgia],
        %w[Atlantic/Stanley Atlantic/Stanley],
        %w[Australia/Adelaide Australia/Adelaide],
        %w[Australia/Brisbane Australia/Brisbane],
        %w[Australia/Broken_Hill Australia/Broken_Hill],
        %w[Australia/Currie Australia/Currie],
        %w[Australia/Darwin Australia/Darwin],
        %w[Australia/Eucla Australia/Eucla],
        %w[Australia/Hobart Australia/Hobart],
        %w[Australia/Lindeman Australia/Lindeman],
        %w[Australia/Lord_Howe Australia/Lord_Howe],
        %w[Australia/Melbourne Australia/Melbourne],
        %w[Australia/Perth Australia/Perth],
        %w[Australia/Sydney Australia/Sydney],
        %w[Europe/Amsterdam Europe/Amsterdam],
        %w[Europe/Andorra Europe/Andorra],
        %w[Europe/Astrakhan Europe/Astrakhan],
        %w[Europe/Athens Europe/Athens],
        %w[Europe/Belgrade Europe/Belgrade],
        %w[Europe/Berlin Europe/Berlin],
        %w[Europe/Brussels Europe/Brussels],
        %w[Europe/Bucharest Europe/Bucharest],
        %w[Europe/Budapest Europe/Budapest],
        %w[Europe/Chisinau Europe/Chisinau],
        %w[Europe/Copenhagen Europe/Copenhagen],
        %w[Europe/Dublin Europe/Dublin],
        %w[Europe/Gibraltar Europe/Gibraltar],
        %w[Europe/Helsinki Europe/Helsinki],
        %w[Europe/Istanbul Europe/Istanbul],
        %w[Europe/Kaliningrad Europe/Kaliningrad],
        %w[Europe/Kiev Europe/Kiev],
        %w[Europe/Kirov Europe/Kirov],
        %w[Europe/Lisbon Europe/Lisbon],
        %w[Europe/London Europe/London],
        %w[Europe/Luxembourg Europe/Luxembourg],
        %w[Europe/Madrid Europe/Madrid],
        %w[Europe/Malta Europe/Malta],
        %w[Europe/Minsk Europe/Minsk],
        %w[Europe/Monaco Europe/Monaco],
        %w[Europe/Moscow Europe/Moscow],
        %w[Asia/Nicosia Asia/Nicosia],
        %w[Europe/Oslo Europe/Oslo],
        %w[Europe/Paris Europe/Paris],
        %w[Europe/Prague Europe/Prague],
        %w[Europe/Riga Europe/Riga],
        %w[Europe/Rome Europe/Rome],
        %w[Europe/Samara Europe/Samara],
        %w[Europe/Saratov Europe/Saratov],
        %w[Europe/Simferopol Europe/Simferopol],
        %w[Europe/Sofia Europe/Sofia],
        %w[Europe/Stockholm Europe/Stockholm],
        %w[Europe/Tallinn Europe/Tallinn],
        %w[Europe/Tirane Europe/Tirane],
        %w[Europe/Ulyanovsk Europe/Ulyanovsk],
        %w[Europe/Uzhgorod Europe/Uzhgorod],
        %w[Europe/Vienna Europe/Vienna],
        %w[Europe/Vilnius Europe/Vilnius],
        %w[Europe/Volgograd Europe/Volgograd],
        %w[Europe/Warsaw Europe/Warsaw],
        %w[Europe/Zaporozhye Europe/Zaporozhye],
        %w[Europe/Zurich Europe/Zurich],
        %w[Indian/Chagos Indian/Chagos],
        %w[Indian/Christmas Indian/Christmas],
        %w[Indian/Cocos Indian/Cocos],
        %w[Indian/Kerguelen Indian/Kerguelen],
        %w[Indian/Mahe Indian/Mahe],
        %w[Indian/Maldives Indian/Maldives],
        %w[Indian/Mauritius Indian/Mauritius],
        %w[Indian/Reunion Indian/Reunion],
        %w[Pacific/Apia Pacific/Apia],
        %w[Pacific/Auckland Pacific/Auckland],
        %w[Pacific/Bougainville Pacific/Bougainville],
        %w[Pacific/Chatham Pacific/Chatham],
        %w[Pacific/Chuuk Pacific/Chuuk],
        %w[Pacific/Easter Pacific/Easter],
        %w[Pacific/Efate Pacific/Efate],
        %w[Pacific/Enderbury Pacific/Enderbury],
        %w[Pacific/Fakaofo Pacific/Fakaofo],
        %w[Pacific/Fiji Pacific/Fiji],
        %w[Pacific/Funafuti Pacific/Funafuti],
        %w[Pacific/Galapagos Pacific/Galapagos],
        %w[Pacific/Gambier Pacific/Gambier],
        %w[Pacific/Guadalcanal Pacific/Guadalcanal],
        %w[Pacific/Guam Pacific/Guam],
        %w[Pacific/Honolulu Pacific/Honolulu],
        %w[Pacific/Kiritimati Pacific/Kiritimati],
        %w[Pacific/Kosrae Pacific/Kosrae],
        %w[Pacific/Kwajalein Pacific/Kwajalein],
        %w[Pacific/Majuro Pacific/Majuro],
        %w[Pacific/Marquesas Pacific/Marquesas],
        %w[Pacific/Nauru Pacific/Nauru],
        %w[Pacific/Niue Pacific/Niue],
        %w[Pacific/Norfolk Pacific/Norfolk],
        %w[Pacific/Noumea Pacific/Noumea],
        %w[Pacific/Pago_Pago Pacific/Pago_Pago],
        %w[Pacific/Palau Pacific/Palau],
        %w[Pacific/Pitcairn Pacific/Pitcairn],
        %w[Pacific/Pohnpei Pacific/Pohnpei],
        %w[Pacific/Port_Moresby Pacific/Port_Moresby],
        %w[Pacific/Rarotonga Pacific/Rarotonga],
        %w[Pacific/Tahiti Pacific/Tahiti],
        %w[Pacific/Tarawa Pacific/Tarawa],
        %w[Pacific/Tongatapu Pacific/Tongatapu],
        %w[Pacific/Wake Pacific/Wake],
        %w[Pacific/Wallis Pacific/Wallis]
      ]
    end,
  }
}
