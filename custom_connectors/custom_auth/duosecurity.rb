{
  title: 'DoubleClick',

  connection: {
    fields: [
      {
        name: 'client_id',
        hint: 'Get your <b>client ID</b> from Google API Console -> '\
          'Credentials.',
        optional: false
      },
      {
        name: 'client_secret',
        hint: 'Get your <b>client secret</b> from Google API Console -> '\
          'Credentials.',
        optional: false,
        control_type: 'password'
      }
    ],

    authorization: {
      type: 'oauth2',

      authorization_url: lambda do |connection|
        scopes = [
          'https://www.googleapis.com/auth/dfareporting',
          'https://www.googleapis.com/auth/doubleclicksearch',
          'https://www.googleapis.com/auth/dfatrafficking',
          'https://www.googleapis.com/auth/ddmconversions'
        ].join(' ')

        'https://accounts.google.com/o/oauth2/auth?client_id=' \
        "#{connection['client_id']}&response_type=code&scope=#{scopes}" \
        '&access_type=offline&approval_prompt=force&response_type=code'
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        response = post('https://accounts.google.com/o/oauth2/token').
                   payload(client_id: connection['client_id'],
                           client_secret: connection['client_secret'],
                           grant_type: 'authorization_code',
                           code: auth_code,
                           redirect_uri: redirect_uri).
                   request_format_www_form_urlencoded
        [response, nil, nil]
      end,

      refresh: lambda do |connection, refresh_token|
        post('https://accounts.google.com/o/oauth2/token').
          payload(client_id: connection['client_id'],
                  client_secret: connection['client_secret'],
                  grant_type: 'refresh_token',
                  refresh_token: refresh_token).
          request_format_www_form_urlencoded
      end,

      refresh_on: [401],

      detect_on: [/"errors"\:\s*\[/],

      apply: lambda do |_connection, access_token|
        headers(Authorization: "Bearer #{access_token}")
      end
    },

    base_uri: lambda do |_connection|
      'https://www.googleapis.com/dfareporting/v3.3/'
    end
  },

  object_definitions: {
    report: {
      fields: lambda do |_connection|
        [
          { name: 'kind' },
          { name: 'id', type: 'integer', label: 'Report ID' },
          { name: 'etag' },
          { name: 'lastModifiedTime', type: 'integer' },
          { name: 'ownerProfileId', type: 'integer' },
          { name: 'accountId', type: 'integer' },
          { name: 'subAccountId', type: 'integer' },
          { name: 'name', label: 'Report name' },
          { name: 'fileName' },
          { name: 'format' },
          { name: 'type' },
          { name: 'criteria', type: :object, properties: [
            { name: 'dateRange', type: :object, properties: [
              { name: 'kind' },
              { name: 'startDate', type: 'date_time' },
              { name: 'endDate', type: 'date_time' },
              { name: 'relativeDateRange' }
            ] },
            { name: 'dimensions', type: :array, of: :object, properties: [
              { name: 'kind' },
              { name: 'name' },
              { name: 'sortOrder' }
            ] },
            { name: 'metricNames' },
            { name: 'dimensionFilters', type: :array, of: :object,
              properties: [
                { name: 'kind' },
                { name: 'etag' },
                { name: 'dimensionName' },
                { name: 'value' },
                { name: 'id' },
                { name: 'matchType' }
              ] },
            { name: 'activities', type: :object, properties: [
              { name: 'kind' },
              { name: 'filters', type: :array, of: :object, properties: [
                { name: 'kind' },
                { name: 'etag' },
                { name: 'dimensionName' },
                { name: 'value' },
                { name: 'id' },
                { name: 'matchType' }
              ] },
              { name: 'metricNames' }
            ] },
            { name: 'customRichMediaEvents', type: :object, properties: [
              { name: 'kind' },
              { name: 'filteredEventIds', type: :array, of: :object,
                properties: [
                  { name: 'kind' },
                  { name: 'etag' },
                  { name: 'dimensionName' },
                  { name: 'value' },
                  { name: 'id' },
                  { name: 'matchType' }
                ] },
              { name: 'metricNames' }
            ] }
          ] },
          { name: 'pathToConversionCriteria', type: :object, properties: [
            { name: 'dateRange', type: :object, properties: [
              { name: 'kind' },
              { name: 'startDate', type: 'date_time' },
              { name: 'endDate', type: 'date_time' },
              { name: 'relativeDateRange' }
            ] },
            { name: 'floodlightConfigId', type: :object, properties: [
              { name: 'kind' },
              { name: 'etag' },
              { name: 'dimensionName' },
              { name: 'value' },
              { name: 'id' },
              { name: 'matchType' }
            ] },
            { name: 'activityFilters', type: :array, of: :object,
              properties: [
                { name: 'kind' },
                { name: 'etag' },
                { name: 'dimensionName' },
                { name: 'value' },
                { name: 'id' },
                { name: 'matchType' }
              ] },
            { name: 'conversionDimensions', type: :array, of: :object,
              properties: [
                { name: 'kind' },
                { name: 'name' },
                { name: 'sortOrder' }
              ] },
            { name: 'perInteractionDimensions', type: :array, of: :object,
              properties: [
                { name: 'kind' },
                { name: 'name' },
                { name: 'sortOrder' }
              ] },
            { name: 'metricNames' },
            { name: 'customFloodlightVariables', type: :array, of: :object,
              properties: [
                { name: 'kind' },
                { name: 'name' },
                { name: 'sortOrder' }
              ] },
            { name: 'customRichMediaEvents', type: :array, of: :object,
              properties: [
                { name: 'kind' },
                { name: 'etag' },
                { name: 'dimensionName' },
                { name: 'value' },
                { name: 'id' },
                { name: 'matchType' }
              ] },
            { name: 'reportProperties', type: :object, properties: [
              { name: 'clicksLookbackWindow', type: 'integer' },
              { name: 'maximumInteractionGap', type: 'integer' },
              { name: 'maximumClickInteractions', type: 'integer' },
              { name: 'maximumImpressionInteractions', type: 'integer' },
              { name: 'includeAttributedIPConversions', type: 'boolean' },
              { name: 'includeUnattributedIPConversions', type: 'boolean' },
              { name: 'includeUnattributedCookieConversions', type: 'boolean' },
              { name: 'pivotOnInteractionPath', type: 'boolean' }
            ] }
          ] },
          { name: 'reachCriteria', type: :object, properties: [
            { name: 'enableAllDimensionCombinations', type: :boolean },
            { name: 'dateRange', type: :object, properties: [
              { name: 'kind' },
              { name: 'startDate', type: 'date_time' },
              { name: 'endDate', type: 'date_time' },
              { name: 'relativeDateRange' }
            ] },
            { name: 'dimensions', type: :array, of: :object, properties: [
              { name: 'kind' },
              { name: 'name' },
              { name: 'sortOrder' }
            ] },
            { name: 'metricNames' },
            { name: 'reachByFrequencyMetricNames' },
            { name: 'dimensionFilters', type: :array, of: :object,
              properties: [
                { name: 'kind' },
                { name: 'etag' },
                { name: 'dimensionName' },
                { name: 'value' },
                { name: 'id' },
                { name: 'matchType' }
              ] },
            { name: 'activities', type: :object, properties: [
              { name: 'kind' },
              { name: 'filters', type: :array, of: :object, properties: [
                { name: 'kind' },
                { name: 'etag' },
                { name: 'dimensionName' },
                { name: 'value' },
                { name: 'id' },
                { name: 'matchType' }
              ] },
              { name: 'metricNames' }
            ] },
            { name: 'customRichMediaEvents', type: :object, properties: [
              { name: 'kind' },
              { name: 'filteredEventIds', type: :array, of: :object,
                properties: [
                  { name: 'kind' },
                  { name: 'etag' },
                  { name: 'dimensionName' },
                  { name: 'value' },
                  { name: 'id' },
                  { name: 'matchType' }
                ] }
            ] }
          ] },
          { name: 'crossDimensionReachCriteria', type: :object, properties: [
            { name: 'dateRange', type: :object, properties: [
              { name: 'kind' },
              { name: 'startDate', type: 'date_time' },
              { name: 'endDate', type: 'date_time' },
              { name: 'relativeDateRange' }
            ] },
            { name: 'dimension' },
            { name: 'pivoted', type: 'boolean' },
            { name: 'dimensionFilters', type: :array, of: :object,
              properties: [
                { name: 'kind' },
                { name: 'etag' },
                { name: 'dimensionName' },
                { name: 'value' },
                { name: 'id' },
                { name: 'matchType' }
              ] },
            { name: 'breakdown', type: :array, of: :object, properties: [
              { name: 'kind' },
              { name: 'name' },
              { name: 'sortOrder' }
            ] },
            { name: 'metricNames' },
            { name: 'overlapMetricNames' }
          ] },
          { name: 'floodlightCriteria', type: :object, properties: [
            { name: 'dateRange', type: :object, properties: [
              { name: 'kind' },
              { name: 'startDate', type: 'date_time' },
              { name: 'endDate', type: 'date_time' },
              { name: 'relativeDateRange' }
            ] },
            { name: 'floodlightConfigId', type: :object, properties: [
              { name: 'kind' },
              { name: 'etag' },
              { name: 'dimensionName' },
              { name: 'value' },
              { name: 'id' },
              { name: 'matchType' }
            ] },
            { name: 'dimensionFilters', type: :array, of: :object,
              properties: [
                { name: 'kind' },
                { name: 'etag' },
                { name: 'dimensionName' },
                { name: 'value' },
                { name: 'id' },
                { name: 'matchType' }
              ] },
            { name: 'reportProperties', type: :object, properties: [
              { name: 'includeAttributedIPConversions', type: 'boolean' },
              { name: 'includeUnattributedIPConversions', type: 'boolean' },
              { name: 'includeUnattributedCookieConversions', type: 'boolean' }
            ] },
            { name: 'dimensions', type: :array, of: :object, properties: [
              { name: 'kind' },
              { name: 'name' },
              { name: 'sortOrder' }
            ] },
            { name: 'metricNames' },
            { name: 'customRichMediaEvents', type: :array, of: :object,
              properties: [
                { name: 'kind' },
                { name: 'etag' },
                { name: 'dimensionName' },
                { name: 'value' },
                { name: 'id' },
                { name: 'matchType' }
              ] }
          ] },
          { name: 'schedule', type: :object, properties: [
            { name: 'active', type: 'boolean' },
            { name: 'repeats' },
            { name: 'every', type: 'integer' },
            { name: 'repeatsOnWeekDays' },
            { name: 'startDate', type: 'date_time' },
            { name: 'expirationDate', type: 'date_time' },
            { name: 'runsOnDayOfMonth' }
          ] },
          { name: 'delivery', type: :object, properties: [
            { name: 'emailOwner', type: 'boolean' },
            { name: 'emailOwnerDeliveryType' },
            { name: 'message' },
            { name: 'recipients', type: :array, of: :object, properties: [
              { name: 'kind' },
              { name: 'email' },
              { name: 'deliveryType' }
            ] }
          ] }
        ]
      end
    },
    report_file: {
      fields: lambda do |_connection|
        [
          { name: 'kind' },
          { name: 'etag' },
          { name: 'reportId', type: 'integer' },
          { name: 'id', type: 'integer' },
          { name: 'lastModifiedTime', type: 'integer' },
          { name: 'status' },
          { name: 'dateRange', type: :object, properties: [
            { name: 'kind' },
            { name: 'startDate', type: 'date_time' },
            { name: 'endDate', type: 'date_time' },
            { name: 'relativeDateRange' }
          ] },
          { name: 'urls', type: :object, properties: [
            { name: 'browserUrl', label: 'Browser URL' },
            { name: 'apiUrl', label: 'API URL' }
          ] }
        ]
      end
    }
  },

  test: lambda do |_connection|
    get('userprofiles')
  end,

  actions: {
    list_reports: {
      description: "List all <span class='provider'>reports</span> in " \
      'DoubleClick',
      help: {
        body: 'Retrieves a list of reports.',
        learn_more_text: 'List Reports API',
        learn_more_url: 'https://developers.google.com/doubleclick-adver' \
        'tisers/v3.3/reports/list?apix_params=%7B%22profileId%22%3A1%7D'
      },
      input_fields: lambda { |_object_definitions|
        [
          { name: 'profileId', optional: false, type: 'integer',
            control_type: 'integer', hint: 'The DFA user profile ID.' },
          { name: 'scope', control_type: 'select', optional: false,
            pick_list: [%w[ALL ALL], %w[MINE MINE]],
            toggle_hint: 'Select from options',
            hint: 'The scope that defines which results are returned. ',
            toggle_field: {
              name: 'scope',
              label: 'Scope',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter custom value',
              hint: 'Allowed vallues are: "ALL": All reports in account. '\
              '"MINE": My reports. (default)'
            } }
        ]
      },
      execute: lambda { |_connection, input|
        reports = get("userprofiles/#{input['profileId']}/reports?" \
            "scope=#{input['scope']}")['items']
        { reports: reports }
      },
      output_fields: lambda { |object_definitions|
        [
          { name: 'reports', type: :array, of: :object,
            properties: object_definitions['report'] }
        ]
      },
      sample_output: lambda { |_connection, _input|
        { reports: call('sample_report') }
      }
    },
    get_report_by_id: {
      description: "Get <span class='provider'>report</span> by ID in " \
      'DoubleClick',
      help: {
        body: 'Retrieves report details for given profile and report ID.',
        learn_more_text: 'Get Report API',
        learn_more_url: 'https://developers.google.com/doubleclick-' \
        'advertisers/v3.3/reports/get'
      },
      input_fields: lambda { |_object_definitions|
        [
          { name: 'profileId', optional: false, type: 'integer',
            control_type: 'integer', hint: 'The DFA user profile ID.' },
          { name: 'reportId', optional: false, type: 'integer',
            control_type: 'integer', hint: 'The ID of the report.' }
        ]
      },
      execute: lambda { |_connection, input|
        get("userprofiles/#{input['profileId']}/reports/#{input['reportId']}")
      },
      output_fields: lambda { |object_definitions|
        object_definitions['report']
      },
      sample_output: lambda { |_connection, _input|
        call('sample_report')
      }
    },
    list_report_files: {
      description: "List <span class='provider'>report files</span> in " \
      'DoubleClick',
      help: {
        body: 'Returns a list of files for a report ID.',
        learn_more_text: 'List Report files API',
        learn_more_url: 'https://developers.google.com/doubleclick-' \
        'advertisers/v3.3/reports/files/list'
      },
      input_fields: lambda { |_object_definitions|
        [
          { name: 'profileId', optional: false, type: 'integer',
            control_type: 'integer', hint: 'The DFA user profile ID.' },
          { name: 'reportId', optional: false, type: 'integer',
            control_type: 'integer', hint: 'The ID of the report.' }
        ]
      },
      execute: lambda { |_connection, input|
        response = get("userprofiles/#{input['profileId']}/reports/" \
          "#{input['reportId']}/files")
        { kind: response['kind'],
          etag: response['etag'],
          nextPageToken: response['nextPageToken'],
          report_files: response['items'] }
      },
      output_fields: lambda { |object_definitions|
        [
          { name: 'kind' },
          { name: 'etag' },
          { name: 'nextPageToken' },
          { name: 'report_files', type: :array, of: :object,
            properties: object_definitions['report_file'] }
        ]
      },
      sample_output: lambda { |_connection, _input|
        {
          'kind': 'dfareporting#fileList',
          'etag': '\"mD-6LEJOy1ZTRjP0qj4BvgI6FwY/BwsiycFliDsV0dzODs5DSSzdTyU\"',
          'nextPageToken': '',
          'report_files': [
            {
              'kind': 'dfareporting#file',
              'etag': '\"mD-6LEJOy1ZTRjP0qj4BvgI6FwY/MTU2NDY0NTY3NjAwMA\"',
              'reportId': '622792256',
              'id': '2608851427',
              'lastModifiedTime': '1564645676000',
              'status': 'REPORT_AVAILABLE',
              'fileName': 'Doubleclick_Browser_Mobile_Platform',
              'format': 'CSV',
              'dateRange': {
                'kind': 'dfareporting#dateRange',
                'startDate': '2019-07-31',
                'endDate': '2019-07-31'
              },
              'urls': {
                'browserUrl': 'https://www.google.com/analytics/dfa/' \
                'downloadFile?id=622792256:2608851427',
                'apiUrl': 'https://www.googleapis.com/dfareporting/v3.3/' \
                'reports/622792256/files/2608851427?alt=media'
              }
            }
          ]
        }
      }
    },
    download_report_file: {
      description: "Download <span class='provider'>report file</span> " \
      'in DoubleClick',
      help: {
        body: 'Performs a direct download to download the contents of a ' \
        'report file.',
        learn_more_text: 'Download Report files API',
        learn_more_url: 'https://developers.google.com/doubleclick-' \
        'advertisers/guides/download_reports#direct_download'
      },
      input_fields: lambda { |_object_definitions|
        [
          { name: 'fileId', optional: false, type: 'integer',
            control_type: 'integer', hint: 'The ID of the report file.' },
          { name: 'reportId', optional: false, type: 'integer',
            control_type: 'integer', hint: 'The ID of the report.' }
        ]
      },
      execute: lambda { |_connection, input|
        file = get("reports/#{input['reportId']}/files/" \
            		"#{input['fileId']}?alt=media").response_format_raw
        { content: file }
      },
      output_fields: lambda { |_object_definitions|
        [
          { name: 'content' }
        ]
      },
      summarize_output: ['content'],
      sample_output: lambda { |_connection, _input|
        { 'content': 'test' }
      }
    }
  },

  triggers: {
  },
  methods: {
    sample_report: lambda do
      {
        'kind': 'dfareporting#report',
        'id': '622792256',
        'etag': '\"mD-6LEJOy1ZTRjP0qj4BvgI6FwY/MTU2NDYxMDA4NzAwMA\"',
        'lastModifiedTime': '1564610087000',
        'ownerProfileId': '5353087',
        'accountId': '481802',
        'name': 'Doubleclick_Browser_Mobile_Platform',
        'fileName': 'Doubleclick_Browser_Mobile_Platform',
        'format': 'CSV',
        'type': 'STANDARD',
        'criteria': {
          'dateRange': {
            'kind': 'dfareporting#dateRange',
            'relativeDateRange': 'YESTERDAY'
          },
          'dimensions': [
            {
              'kind': 'dfareporting#sortedDimension',
              'name': 'dfa:date'
            }
          ],
          'metricNames': [
            'dfa:impressions',
            'dfa:clicks'
          ],
          'activities': {
            'kind': 'dfareporting#activities',
            'filters': [
              {
                'kind': 'dfareporting#dimensionValue',
                'etag': '\"mD-6LEJOy1ZTRjP0qj4BvgI6FwY/' \
                'lee6nVba2h4PI6U6yjz0z0Feb-M\"',
                'dimensionName': 'dfa:activity',
                'id': '8354964'
              }
            ],
            'metricNames': [
              'dfa:totalConversions'
            ]
          }
        },
        'schedule': {
          'active': true,
          'repeats': 'DAILY',
          'every': 1,
          'startDate': '2019-07-10',
          'expirationDate': '2025-10-08'
        },
        'delivery': {
          'emailOwner': true,
          'emailOwnerDeliveryType': 'ATTACHMENT',
          'recipients': [
            {
              'kind': 'dfareporting#recipient',
              'email': 'workato@sofi.org',
              'deliveryType': 'ATTACHMENT'
            }
          ]
        }
      }
    end
  },
  pick_lists: {
  }
}
