{
  title: 'SentinelOne',

  connection: {
    fields: [
      {
        name: 'authentication',
        optional: false,
        control_type: 'select',
        pick_list: [
          %w[Basic basic],
          %w[Api\ key api_key]
        ]
      },
      {
        ngIf: 'input.authentication == "basic"',
        name: 'user_name',
        optional: false
      },
      {
        ngIf: 'input.authentication == "basic"',
        name: 'password',
        control_type: 'password',
        optional: false
      },
      {
        ngIf: 'input.authentication == "api_key"',
        name: 'api_key', label: 'API token',
        control_type: 'password',
        optional: false,
        hint: 'Generate the token from the Management Console. the token' \
        ' is valid for six months. Set a reminder to regenerate the <b>api token</b>' \
        ' before it expires and to update. Check the API documentation for more details.'
      },
      {
        name: 'base_uri',
        optional: false,
        control_type: 'subdomain',
        hint: 'Enter your base URL. e.g. <b>my-mgmt.sentinelone.com<b>'
      }
    ],
    authorization: {
      type: 'custom_auth',

      acquire: lambda do |connection|
        if connection['authentication'] == 'basic'
          payload = { 'username': connection['user_name'],
                      'remember_me': 'true',
                      'password': connection['password'] }
          { token: post("https://#{connection['base_uri']}/web/api/v2.0/users/login").
            payload(payload).after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.dig('data', 'token') }
        end
      end,
      refresh_on: [401, 403],
      apply: lambda do |connection|
        if connection['authentication'] == 'basic'
          headers(Authorization: "Token #{connection['token']}")
        else
          headers(Authorization: "ApiToken #{connection['api_key']}")
        end
      end
    },
    base_uri: lambda do |connection|
      "https://#{connection['base_uri']}"
    end
  },

  test: lambda do |_connection|
    get('/web/api/v2.0/private/user-info')&.
      after_error_response(/.*/) do |_code, body, _header, message|
        error("#{message}: #{body}")
      end
  end,

  methods: {
    custom_input_parser: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call('custom_input_parser', array_value)
        end
      elsif input.is_a?(Hash)
        input.each_with_object({}) do |(key, value), hash|
          if %w[groupIds rangerVersions filteredSiteIds rangerStatuses
                networkInterfaceInet__contains locationIds externalId__contains
                adUserMember__contains networkStatuses domains machineTypes
                adComputerMember__contains agentIds appsVulnerabilityStatuses
                adUserName__contains computerName__contains agentVersions
                adUserQuery__contains adQuery__contains installerTypes
                filteredGroupIds userActionsNeeded uuid__contains osTypes
                userActionsNeeded siteIds uuids accountIds isDecommissioned
                consoleMigrationStatuses ids adComputerName__contains
                scanStatuses externalIp__contains adComputerQuery__contains
                osVersion__contains isUninstalled queryType features states
                networkInterfacePhysical__contains description__contains
                hostname__contains registryKey__contains creator__contains
                scopes ipAddress__contains name__contains values
                scopeName__contains].include?(key)
            hash[key] = if value.include?('true') || value.include?('false')
                          value.split(',').map { |item| item.is_true? }
                        else
                          value.split(',')
                        end
          elsif %w[lastActiveDate__between createdAt__between updatedAt__between
                   threatCreatedAt__between registeredAt__between
                   cpuCount__between].include?(key)
            hash[key] = "#{value['from'].to_i * 1000}-#{value['to'].to_i * 1000}"
          elsif %w[fromDate toDate].include?(key)
            hash[key] = value.utc.iso8601
          elsif value.is_a?(Array) || value.is_a?(Hash)
            hash[key] = call('custom_input_parser', value)
          else
            hash[key] = value
          end
        end
      end
    end,

    custom_output_parser: lambda do |payload|
      if payload.is_a?(Array)
        payload.map do |array_value|
          call('custom_output_parser', array_value)
        end
      elsif payload.is_a?(Hash)
        payload.each_with_object({}) do |(key, value), hash|
          hash[key] = if value.is_a?(Array) || value.is_a?(Hash)
                        call('custom_output_parser', value)
                      else
                        value
                      end
        end
      else
        { 'value': payload }
      end
    end,

    initiate_scan_input: lambda do
      [
        { name: 'computerName', optional: false,
          hint: "e.g. 'My Office Desktop'" },
        { name: 'lastLoggedInUserName__contains',
          optional: false,
          hint: 'Free-text filter by username.'\
                ' Multiple values can be seperated using comma(,).'\
                " e.g. 'admin,johnd1'" },
        { name: 'coreCount__lte', label: 'CPU core count',
          type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'CPU cores (less than or equal)' },
        { name: 'groupIds', label: 'Groups IDs',
          sticky: true,
          hint: 'List of group IDs to filter by.'\
          ' Group IDs must be separated using the comma(,).'\
          " e.g. '225494730938493804,225494730938493915'" },
        { name: 'lastActiveDate__between',
          type: 'object',
          properties: [
            { name: 'from', type: 'date_time', control_type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              optional: false },
            { name: 'to', type: 'date_time', control_type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              optional: false }
          ] },
        { name: 'hasLocalConfiguration', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Agent has a local configuration set',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'hasLocalConfiguration',
            label: 'Has local configuration',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Agent has a local configuration set.' \
                  'Allowed values are: true, false.'
          } },
        { name: 'rangerVersions',
          hint: 'Ranger versions to include(supports multiple values).'\
          ' Ranger versions must be separated using the comma(,).'\
          " e.g. '2.0.0.0,2.1.5.144'" },
        { name: 'filteredSiteIds', label: 'Filtered site IDs', sticky: true,
          hint: 'List of site IDs to filter by.'\
          ' Site IDs must be separated using the comma(,).'\
          " e.g. '225494730938493804,225494730938493915'" },
        { name: 'rangerStatuses',
          hint: 'Statuses of the ranger.'\
          ' Ranger statuses must be separated using the comma(,).'\
          " e.g. 'NotApplicable,Applicable'" },
        { name: 'threatResolved', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Include only agents with atleast one resolved threat.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'threatResolved',
            label: 'Threat resolved',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Include only agents with atleast one resolved threat.'\
            ' Allowed values are: true, false.'
          } },
        { name: 'createdAt__between',
          type: 'object', properties: [
            { name: 'from', type: 'date_time', control_type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              optional: false },
            { name: 'to', type: 'date_time', control_type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              optional: false }
          ] },
        { name: 'isPendingUninstall', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Include only agents with pending uninstall requests',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'isPendingUninstall',
            label: 'Is pending uninstall',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Include only agents with pending uninstall requests.'\
            ' Allowed values are: true, false.'
          } },
        { name: 'activeThreats__gt', type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Include agents with atleast this amount of active threats'\
                ' (greater than)' },
        { name: 'networkInterfaceInet__contains',
          hint: 'Free-text filter by local IP(supports multiple values).'\
          'The IP can separated using the comma(,).'\
          " e.g. '192,10.0.0'" },
        { name: 'locationIds', label: 'Location IDs',
          sticky: true,
          hint: 'Include only agents reporting these locations.'\
          ' location IDs can be separated using the comma(,).'\
          " e.g. '225494730938493804,225494730938493915'" },
        { name: 'threatCreatedAt__gte', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents with threats reported after or at this time'\
                '(greater than or equal).' },
        { name: 'isDecommissioned', control_type: 'multiselect',
          label: 'Is decommissioned',
          pick_list: 'decommissioned',
          pick_list_params: {},
          delimiter: ',',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'isDecommissioned',
            label: 'Is decommissioned',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are true, false'
          } },
        { name: 'externalId__contains',
          hint: 'Free-text filter by external ID (Customer ID).'\
          ' External IDs can seperated using comma(,).'\
          " e.g. 'Performance machine,laptop'" },
        { name: 'adUserMember__contains',
          hint: 'Free-text filter by Active Directory user groups string.'\
                'AD user groups can be seperated using the comma(,). '\
                " e.g. 'DC=sentinelone,John'" },
        { name: 'networkStatuses', sticky: true,
          hint: 'Included network statuses(supports multiple values).'\
                'Multiple values can be seperated using comma(,).'\
                " e.g. 'connected,connecting'" },
        { name: 'coreCount__between',
          hint: "Possible number of CPU cores. e.g. '2-8'" },
        { name: 'adComputerMember__contains',
          hint: 'Free-text filter by Active Directory computer groups string.'\
                ' Multiple values can be seperated using comma(,).'\
                " e.g. 'DC=sentinelone,John'" },
        { name: 'query',
          hint: 'A free-text search term, will match applicable attributes ' },
        { name: 'adUserName__contains',
          hint: 'Free-text filter by Active Directory username string.'\
                ' Multiple values can be separated using comma(,).'\
                " e.g. 'DC=sentinelone,John'" },
        { name: 'computerName__contains',
          hint: 'Free-text filter by computer name(supports multiple values).'\
                ' Computer names can be seperated using comma(,).'\
                " e.g. 'john-office,WIN'" },
        { name: 'threatCreatedAt__between', type: 'object',
          properties: [
            { name: 'from', type: 'date_time', control_type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              optional: false },
            { name: 'to', type: 'date_time', control_type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              optional: false }
          ] },
        { name: 'cpuCount__lte', type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Number of CPUs (less than or equal)' },
        { name: 'mitigationModeSuspicious', type: 'string',
          control_type: 'select', pick_list: 'mitigation_mode_suspicious',
          toggle_hint: 'Select from list',
          hint: 'Mitigation mode policy for suspicious activity'\
                " can be 'detect' or 'protect'",
          toggle_field: {
            name: 'mitigationModeSuspicious',
            label: 'Mitigation mode suspicious',
            optional: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Mitigation mode policy for suspicious activity'\
                  ' can be 'detect' or 'protect'"
          } },
        { name: 'updatedAt__gt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents updated after this timestamp (greater than)' },
        { name: 'totalMemory__gt', type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Memory size (MB, more than)' },
        { name: 'registeredAt__between', type: 'object',
          properties: [
            { name: 'from', type: 'date_time', control_type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              optional: false },
            { name: 'to', type: 'date_time', control_type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              optional: false }
          ] },
        { name: 'networkInterfacePhysical__contains',
          hint: 'Free-text filter by MAC address(supports multiple values).'\
          ' Multiple values can be seperated using comma(,).'\
          " e.g. 'aa:0f,:41:'" },
        { name: 'computerName__like',
          hint: "Match computer name partially. e.g. 'Lab1'" },
        { name: 'totalMemory__lt', type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Memory size (MB, less than)' },
        { name: 'infected', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Include only agents with at least one active threat.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'infected',
            label: 'Infected',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Include only agents with at least one active threat.'\
            ' Allowed values are: true, false.'
          } },
        { name: 'adUserQuery__contains',
          hint: 'Free-text filter by Active Directory computer name or its'\
                ' groups. Multiple values can be seperated using comma(,).'\
                " e.g. 'DC=sentinelone,John'" },
        { name: 'lastActiveDate__lte', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents last active before or at this time'\
                ' (less than or equal)' },
        { name: 'createdAt__gte', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents created after or at this timestamp'\
                ' (greater than or equal)' },
        { name: 'adQuery__contains',
          hint: 'Free-text filter by Active Directory string.'\
                'Multiple values can be seperated using comma(,).'\
                " e.g. 'DC=sentinelone,John'" },
        { name: 'migrationStatus', type: 'string',
          control_type: 'select',
          sticky: true,
          pick_list: 'migration_status',
          hint: "Migration status can be 'N/A', 'Pending', 'Migrated' or 'Failed'",
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'migrationStatus',
            label: 'Migration status',
            optional: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Migration status can be 'N/A',"\
                  " 'Pending', 'Migrated' or 'Failed'"
          } },
        { name: 'appsVulnerabilityStatuses',
          hint: 'Apps vulnerability status in.'\
          ' Multiple values can be seperated using comma(,).'\
          " e.g. 'patch_required,N/A'" },
        { name: 'agentVersions',
          hint: 'Agent versions to include.'\
          'Multiple values can be seperated using comma(,).'\
          " e.g. '2.0.0.0,2.1.5.144'" },
        { name: 'machineTypes', sticky: true,
          hint: 'Included machine types(supports multiple values).'\
          'Multilple values can be seperated using comma(,).'\
          " e.g. 'laptop,desktop'" },
        { name: 'filteredGroupIds', sticky: true,
          hint: 'List of Group IDs to filter by.'\
          'Multiple values can be seperated using comma(,).'\
          " e.g. '225494730938493804,225494730938493915'" },
        { name: 'domains',
          hint: 'Included network domains.'\
                ' Multiple values can be seperated using comma(,).'\
                " e.g. 'mybusiness.net,workgroup'" },
        { name: 'registeredAt__gt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents registered after this time(greater than)' },
        { name: 'threatCreatedAt__gt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents with threats reported after this time(greater than)' },
        { name: 'updatedAt__lte', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents updated before or at this timestamp(less than or equal)' },
        { name: 'registeredAt__lt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents registered before this time(less than)' },
        { name: 'cpuCount__lt', type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Number of CPUs (less than)' },
        { name: 'threatCreatedAt__lte', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents with threats reported before or at this time'\
                '(less than or equal)' },
        { name: 'updatedAt__lt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents updated before this timestamp(less than)' },
        { name: 'totalMemory__lte', type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Memory size (MB, less than or equal)' },
        { name: 'registeredAt__gte', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents registered after or at this time'\
                '(greater than or equal)' },
        { name: 'createdAt__lt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents created before this timestamp (less than)' },
        { name: 'coreCount__gt', label: 'CPU core count gt',
          type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'CPU cores (more than)' },
        { name: 'threatMitigationStatus', type: 'string',
          control_type: 'select', pick_list: 'threat_mitigation_status',
          toggle_hint: 'Select from list',
          hint: 'Include only agents that have threats with this mitigation '\
                "status can be 'active', 'mitigated', 'blocked', 'suspicious', " \
                "'pending' or 'suspicious_resolved'",
          toggle_field: {
            name: 'threatMitigationStatus',
            label: 'Threat mitigation status',
            optional: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Include only agents that have threats with this mitigation ' \
                  "status can be 'active', 'mitigated', 'blocked', 'suspicious'," \
                  " 'pending' or 'suspicious_resolved'"
          } },
        { name: 'userActionsNeeded',
          hint: 'Included pending user actions.'\
                ' Multiple values can be seperated using comma(,).'\
                " e.g. 'reboot_needed,reboot'" },
        { name: 'isActive', type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'isActive',
            label: 'Is active',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Include only active agents. Allowed values are: true, false'
          } },
        { name: 'lastActiveDate__gte', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents last active after or at this time' },
        { name: 'uuid__contains', label: 'UUID contains',
          hint: 'Free-text filter by agent UUID .'\
                ' IDs can be seperated using comma(,).'\
                " e.g. 'e92-01928,e93-12839'" },
        { name: 'totalMemory__gte', type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Memory size (MB, more than or equal)' },
        { name: 'osTypes', sticky: true,
          hint: 'Included OS types. Multiple values can be seperated'\
                ' using comma(,). '\
                " e.g. 'linux,windows'" },
        { name: 'activeThreats', type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Include agents with this amount of active threats' },
        { name: 'threatCreatedAt__lt', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents with threats reported before this time' },
        { name: 'threatCreatedAt__lte', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents created before or at this timestamp' },
        { name: 'updatedAt__between', type: 'object',
          properties: [
            { name: 'from', type: 'date_time', control_type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              optional: false },
            { name: 'to', type: 'date_time', control_type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              optional: false }
          ] },
        { name: 'threatHidden', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Include only agents with at least one hidden threat',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'threatHidden',
            label: 'Threat hidden',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Include only agents with at least one hidden threat.'\
            ' Allowed values are: true, false.'
          } },
        { name: 'coreCount__lt', label: 'CPU core count lt',
          type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'CPU cores (less than)' },
        { name: 'registeredAt__lte', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents registered before or at this time'\
                '(less than or equal)' },
        { name: 'createdAt__gt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents created after this timestamp(greater than)' },
        { name: 'encryptedApplications', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Disk encryption status',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'encryptedApplications',
            label: 'Encrypted applications',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Disk encryption status. Allowed values are: true, false.'
          } },
        { name: 'siteIds',
          hint: 'List of Site IDs to filter by.'\
                ' Site IDs can be separated using comma(,).'\
                " e.g. '225494730938493804,225494730938493915'" },
        { name: 'lastActiveDate__gt', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents last active after this time(greater than)' },
        { name: 'installerTypes',
          hint: 'Include only agents installed with these package types.'\
                ' Multiple values can be seperated using comma(,).'\
                " e.g. '.msi'" },
        { name: 'uuids', label: 'UUIDs',
          hint: 'A list of included UUIDs.'\
                ' Multiple values can be seperated using comma(,).'\
                " e.g. 'ff819e70af13be381993075eb0ce5f2f6de05b11,"\
                "ff819e70af13be381993075eb0ce5f2f6de05c22'" },
        { name: 'updatedAt__gte', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents updated after or at this timestamp'\
                '(greater than or equal)' },
        { name: 'accountIds', label: 'Account IDs',
          hint: 'List of Account IDs to filter by.'\
                ' Account IDs can be seperated using comma(,).'\
                " e.g. '225494730938493804,225494730938493915'" },
        { name: 'cpuCount__between', type: 'object',
          properties: [
            { name: 'from', type: 'date_time', control_type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              optional: false },
            { name: 'to', type: 'date_time', control_type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              optional: false }
          ] },
        { name: 'scanStatus', type: 'string',
          control_type: 'select', pick_list: 'scan_status',
          toggle_hint: 'Select from list',
          hint: "Scan status can be 'none', 'started', 'aborted' or 'finished'",
          toggle_field: {
            name: 'scanStatus',
            label: 'Scan status',
            optional: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Scan status can be 'none', 'started', 'aborted' or 'finished'"
          } },
        { name: 'filterId', sticky: true, hint: "e.g. '225494730938493804'" },
        { name: 'coreCount__gte', label: 'CPU core count gte',
          type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'CPU cores (greater than or equal)' },
        { name: 'isUpToDate', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'isUpToDate',
            label: 'Is upto date',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false.'
          } },
        { name: 'consoleMigrationStatuses',
          hint: 'Migration status in.'\
          ' Multiple values can be separated using comma(,).'\
          " e.g. 'N/A'" },
        { name: 'ids', label: 'IDs',
          hint: 'A list of Agent IDs.'\
          ' Agent IDs can be seperated using comma(,).'\
          " e.g. '225494730938493804,225494730938493915'" },
        { name: 'adComputerName__contains',
          hint: 'Free-text filter by Active Directory computer name string.'\
          ' Multiple values can be seperated using comma(,).'\
          " e.g. 'DC=sentinelone,John'" },
        { name: 'totalMemory__between',
          hint: "Total memory range (GB, inclusive). e.g. '4096-8192'" },
        { name: 'lastActiveDate__lt', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents last active before this time(less than)' },
        { name: 'adQuery',
          hint: 'An Active Directory query string.'\
                " e.g. 'CN=Managers,DC=sentinelone,DC=com'" },
        { name: 'scanStatuses',
          hint: 'Included scan statuses.'\
                ' Multiple values can be seperated using comma(,).'\
                " e.g. 'started,aborted'" },
        { name: 'externalIp__contains',
          hint: 'Free-text filter by visible IP.'\
                ' IPs can be seperated using comma(,).'\
                " e.g. '127.0,205'" },
        { name: 'adComputerQuery__contains',
          hint: 'Free-text filter by Active Directory computer name or its '\
                'groups. Multiple values can be seperated using comma(,).'\
                " e.g. 'DC=sentinelone,John'" },
        { name: 'rangerStatus', type: 'string',
          control_type: 'select', pick_list: 'ranger_status',
          toggle_hint: 'Select from list',
          hint: 'Status of the ranger. Please use rangerStatuses instead can be  ' \
                "'NotApplicable', 'Enabled' or 'Disabled'",
          toggle_field: {
            name: 'rangerStatus',
            label: 'Ranger status',
            optional: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Status of the ranger. Please use rangerStatuses instead can ' \
                  "be 'NotApplicable', 'Enabled' or 'Disabled'"
          } },
        { name: 'threatContentHash',
          hint: 'Include only agents that have at least one threat with this ' \
                "content hash. e.g. 'cf23df2207d99a74fbe169e3eba035e633b65d94'" },
        { name: 'cpuCount__gt', label: 'CPU count gt',
          type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Number of CPUs (greater than)' },
        { name: 'osArch', label: 'OS architecture', type: 'string',
          control_type: 'select', pick_list: 'os_arch_list',
          toggle_hint: 'Select from list',
          hint: "OS architecture can be '32 bit' or '64 bit'",
          toggle_field: {
            name: 'osArch',
            label: 'OS architecture',
            optional: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "OS architecture can be '32 bit' or '64 bit'"
          } },
        { name: 'uuid', label: 'UUID',
          hint: "Agent's universally unique identifier."\
                " e.g. 'ff819e70af13be381993075eb0ce5f2f6de05be2'" },
        { name: 'cpuCount__gte', type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Number of CPUs (greater than or equal)' },
        { name: 'isUninstalled', control_type: 'multiselect',
          label: 'Is uninstalled',
          pick_list: 'is_uninstalled',
          pick_list_params: {},
          delimiter: ',',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'isUninstalled',
            label: 'Is uninstalled',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are true, false'
          } },
        { name: 'osVersion__contains',
          hint: 'Free-text filter by OS full name and version.'\
          ' Multilple values can be seperated using comma(,).'\
          " e.g. 'Service pack 1'" },
        { name: 'mitigationMode', type: 'string',
          control_type: 'select', pick_list: 'mitigation_mode_suspicious',
          toggle_hint: 'Select from list',
          hint: "Agent mitigation mode policy can be 'detect' or 'protect'",
          toggle_field: {
            name: 'mitigationMode',
            label: 'Mitigation mode',
            optional: true,
            type: 'string',
            toggle_hint: 'Use custom value',
            hint: "Agent mitigation mode policy can be 'detect' or 'protect'"
          } },
        {
          name: 'schema_builder',
          extends_schema: true,
          control_type: 'schema-designer',
          label: 'Data fields',
          sticky: true,
          empty_schema_title: 'Describe all fields for your meta fields.',
          optional: true,
          sample_data_type: 'json' # json_input / xml
        }
      ]
    end,

    query_status_get_schema: lambda do
      [
        { name: 'queryId', optional: false,
          hint: 'QueryId obtained when creating a query under'\
          "Create Query. e.g. 'q1xx2xx3'." }
      ]
    end,

    events_get_schema: lambda do
      [
        { name: 'queryId', optional: false,
          hint: 'QueryId obtained when creating a query under'\
          "Create Query. e.g. 'q1xx2xx3'." },
        { name: 'subQuery', sticky: true,
          hint: 'Create a sub query to run on the data that was already pulled' },
        { name: 'sortBy', sticky: true,
          hint: "Events sorted by field. e.g.'createdAt'" },
        { name: 'sortOrder', type: 'string', sticky: true,
          control_type: 'select', pick_list: 'sort_order',
          toggle_hint: 'Select from list',
          hint: 'Event sorting order',
          toggle_field: {
            name: 'sortOrder',
            label: 'Sort order',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Event sorting order. e.g. 'asc'. " \
                  "Allowed values are 'asc' or 'desc'"
          } },
        { name: 'cursor', sticky: true,
          hint: 'Cursor position returned by the last request. '\
                'Should be used instead of skip. cursor currently supports ' \
                'sort by with createdAt, pid, processStartTime' },
        { name: 'limit', type: 'integer', control_type: 'integer',
          default: 500, sticky: 'true', render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Limit number of returned items (1-1000). e.g. 10' },
        { name: 'skip', type: 'integer', control_type: 'integer',
          sticky: true, render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'Skip first number of items (0-1000). For iterating over ' \
                "more than a 1000 items please use 'cursor' instead." }
      ]
    end,

    groups_get_schema: lambda do
      [
        { name: 'group_id', optional: false,
          hint: "e.g. '225494730938493804'" }
      ]
    end,

    query_status_get_output_schema: lambda do
      [
        { name: 'responseState',
          hint: "Response state can be 'PROCESS_RUNNING', 'EVENTS_RUNNING',"\
                " 'FAILED', 'FINISHED', 'RUNNING', 'ERROR',"\
                " 'QUERY_CANCELLED' or 'TIMED_OUT'" },
        { name: 'progressStatus', type: 'integer', control_type: 'integer',
          parse_output: 'integer_conversion',
          hint: 'Query loading status in percentage.' }
      ]
    end,

    events_get_output_schema: lambda do
      [
        { name: 'data', type: 'array', of: 'object',
          properties: [
            { name: 'processUniqueKey' },
            { name: 'parentPid', label: 'Parent PID' },
            { name: 'loginsBaseType' },
            { name: 'tid', lable: 'TID' },
            { name: 'srcIp', label: 'Src IP' },
            { name: 'taskPath' },
            { name: 'agentIsDecommissioned', type: 'boolean',
              control_type: 'checkbox',
              parse_output: 'boolean_conversion' },
            { name: 'agentInfected', type: 'boolean', control_type: 'checkbox',
              parse_output: 'boolean_conversion' },
            { name: 'parentProcessStartTime' },
            { name: 'agentUuid', label: 'Agentt UUID' },
            { name: 'fileSha256' },
            { name: 'agentOs', label: 'Agent OS' },
            { name: 'agentNetworkStatus' },
            { name: 'oldFileSha256' },
            { name: 'user' },
            { name: 'createdAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'processRoot' },
            { name: 'taskName' },
            { name: 'sha256' },
            { name: 'processIsRedirectedCommandProcessor' },
            { name: 'srcPort', type: 'integer', control_type: 'integer',
              parse_output: 'integer_conversion' },
            { name: 'agentName' },
            { name: 'pid', label: 'PID' },
            { name: 'fileId' },
            { name: 'oldFileName' },
            { name: 'processDisplayName' },
            { name: 'objectType' },
            { name: 'networkMethod' },
            { name: 'processName' },
            { name: 'indicatorMetadata' },
            { name: 'parentProcessName' },
            { name: 'registryPath' },
            { name: 'sha1' },
            { name: 'processIsWow64' },
            { name: 'dstIp', label: 'Dst IP' },
            { name: 'trueContext' },
            { name: 'indicatorDescription' },
            { name: 'relatedToThreat' },
            { name: 'agentIsActive', type: 'boolean', control_type: 'checkbox',
              parse_output: 'boolean_conversion' },
            { name: 'signedStatus' },
            { name: 'dnsResponse' },
            { name: 'parentProcessGroupId' },
            { name: 'publisher' },
            { name: 'oldFileSha1' },
            { name: 'processStartTime' },
            { name: 'verifiedStatus' },
            { name: 'direction' },
            { name: 'fileMd5' },
            { name: 'processIsMalicious', type: 'boolean',
              control_type: 'checkbox',
              parse_output: 'boolean_conversion' },
            { name: 'fileSize' },
            { name: 'registryId' },
            { name: 'agentDomain' },
            { name: 'parentProcessUniqueKey' },
            { name: 'agentIp', label: 'Agent IP' },
            { name: 'fileType' },
            { name: 'siteName' },
            { name: 'fileSha1' },
            { name: 'eventType' },
            { name: 'fileFullName' },
            { name: 'agentMachineType' },
            { name: 'agentGroupId' },
            { name: 'loginsUserName' },
            { name: 'networkUrl' },
            { name: 'processIntegrityLevel' },
            { name: 'processGroupId' },
            { name: 'rpid', label: 'Rp ID' },
            { name: 'dstPort', type: 'integer', control_type: 'integer',
              parse_output: 'integer_conversion' },
            { name: 'processSessionId' },
            { name: 'signatureSignedInvalidReason' },
            { name: 'processImagePath' },
            { name: 'connectionStatus' },
            { name: 'indicatorName' },
            { name: 'md5' },
            { name: 'forensicUrl' },
            { name: 'processImageSha1Hash' },
            { name: 'agentVersion' },
            { name: 'parentProcessIsMalicious', type: 'boolean',
              control_type: 'checkbox',
              parse_output: 'boolean_conversion' },
            { name: 'processSubSystem' },
            { name: 'indicatorCategory' },
            { name: 'processCmd' },
            { name: 'dnsRequest' },
            { name: 'processUserName' },
            { name: 'threatStatus' },
            { name: 'id' },
            { name: 'networkSource' },
            { name: 'oldFileMd5' },
            { name: 'agentId', label: 'Agent ID' }
          ] },
        { name: 'pagination', type: 'object', properties: [
          { name: 'nextCursor' },
          { name: 'totalItems', type: 'integer' }
        ] }
      ]
    end,

    groups_search_schema: lambda do
      [
        { name: 'groupIds', label: 'Groups IDs',
          sticky: true,
          hint: 'List of group IDs to filter by.'\
                ' Group IDs must be separated using the comma(,).'\
                " e.g. '225494730938493804,225494730938493915'" },
        { name: 'updatedAt__gt', type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Agents updated after this timestamp (greater than)' },
        { name: 'limit', type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: "Limit number of returned items (1-200). e.g. '10'." },
        { name: 'rank', type: 'integer', control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'The rank sets the priority of a dynamic group'\
                " over others. e.g. '1'." },
        { name: 'updatedAt__lte', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Updated at lesser or equal than.' },
        { name: 'updatedAt__gte', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Updated at greater or equal than.' },
        { name: 'accountIds', label: 'Account IDs',
          hint: 'List of Account IDs to filter by.'\
          ' Account IDs can be seperated using comma(,).'\
          " e.g. '225494730938493804,225494730938493915'" },
        { name: 'registrationToken',
          hint: "e.g. 'eyJ1cmwiOiAiaHR0cHM6Ly9jb25zb2xlLnNlbnRpbmVsb25lLm5ldC" \
          "IsICJzaXRlX2tleSI6ICIwNzhkYjliMWUyOTA1Y2NhIn0='" },
        { name: 'updatedAt__lt', type: 'date_time', control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Updated at lesser than.' },
        { name: 'isDefault', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Is this the default group?',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'isDefault',
            label: 'Is default',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Is this the default group?.'\
                  ' Allowed values are: true or false.'
          } },
        { name: 'query', hint: 'Free text search on fields name' },
        { name: 'type', hint: "Group type. e.g. 'static'." },
        { name: 'name' },
        { name: 'id', hint: "e.g. '225494730938493804'." },
        { name: 'siteIds', label: 'Site IDs', sticky: true,
          hint: 'List of site IDs to filter by.'\
          ' Site IDs must be separated using the comma(,).'\
          " e.g. '225494730938493804,225494730938493915'" }
      ]
    end,

    groups_schema: lambda do
      [
        { name: 'data', type: 'array', of: 'object',
          properties: [
            { name: 'siteId' },
            { name: 'isDefault', type: 'boolean', control_type: 'checkbox',
              parse_output: 'boolean_conversion' },
            { name: 'filterName' },
            { name: 'type' },
            { name: 'creatorId' },
            { name: 'name' },
            { name: 'createdAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'rank', type: 'integer', control_type: 'integer',
              parse_output: 'integer_conversion' },
            { name: 'registrationToken' },
            { name: 'id' },
            { name: 'inherits', type: 'boolean', control_type: 'checkbox',
              parse_output: 'boolean_conversion' },
            { name: 'filterId' },
            { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'totalAgents', type: 'integer', control_type: 'integer',
              parse_output: 'integer_conversion' },
            { name: 'creator' }
          ] }
      ]
    end,

    sites_search_schema: lambda do
      [
        { name: 'expiration', type: 'date_time', sticky: true,
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion' },
        { name: 'limit', type: 'integer', sticky: true,
          control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: "Limit number of returned items (1-1000). e.g. '10'." },
        { name: 'suite', type: 'string', sticky: true,
          control_type: 'select', pick_list: 'suite',
          toggle_hint: 'Select from list',
          hint: 'The suite of product features active for this site.',
          toggle_field: {
            name: 'suite',
            label: 'Suite',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'The suite of product features active for this site.'\
                  "Allowed values are 'Core', 'Control' or 'Complete'"
          } },
        { name: 'totalLicenses', type: 'integer', sticky: true,
          control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion' },
        { name: 'registrationToken', sticky: true,
          hint: "e.g. 'eyJ1cmwiOiAiaHR0cHM6Ly9jb25zb2xlLnNlbnRpbmVsb25lLm5ldC" \
          "IsICJzaXRlX2tleSI6ICIwNzhkYjliMWUyOTA1Y2NhIn0='" },
        { name: 'accountIds', label: 'Account IDs', sticky: true,
          hint: 'List of Account IDs to search for.'\
                ' Account IDs can be seperated using comma(,).'\
                " e.g. '225494730938493804,225494730938493915'" },
        { name: 'availableMoveSites', type: 'boolean', sticky: true,
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Only return sites the user can move agents to',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'availableMoveSites',
            label: 'Available move sites',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Only return sites the user can move agents to.'\
                  ' Allowed values are: true or false.'
          } },
        { name: 'adminOnly', type: 'boolean', sticky: true,
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Show sites the user has Admin privileges to',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'adminOnly',
            label: 'Admin only',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Show sites the user has Admin privileges to.'\
                  ' Allowed values are: true or false.'
          } },
        { name: 'externalId', sticky: true,
          hint: 'Id in a CRM external system' },
        { name: 'accountId', sticky: true },
        { name: 'isDefault', type: 'boolean', sticky: true,
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'isDefault',
            label: 'Is default',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true or false.'
          } },
        { name: 'state', type: 'string', sticky: true,
          control_type: 'select', pick_list: 'state',
          toggle_hint: 'Select from list',
          hint: "Site state. e.g. 'active'",
          toggle_field: {
            name: 'state',
            label: 'State',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Site state can be 'active', 'expired' or 'deleted'."
          } },
        { name: 'siteType', type: 'string', sticky: true,
          control_type: 'select', pick_list: 'site_types',
          toggle_hint: 'Select from list',
          hint: "Site type. e.g. 'Trial'",
          toggle_field: {
            name: 'siteType',
            label: 'Site type',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Site tyoe can be 'trial' or 'paid'."
          } },
        { name: 'features', control_type: 'multiselect',
          label: 'Features',
          pick_list: 'features',
          pick_list_params: {},
          delimiter: ',',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'features',
            label: 'Features',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: "Allowed values are 'firewall-control', 'device-control',"\
                  " 'ioc'. Multiple values can be seperated by comma(,)"
          } },
        { name: 'states',
          hint: 'List of states to filter.'\
                ' Multiple values can be seperated using comma(,)' },
        { name: 'query',
          hint: 'Full text search for fields: name, account_name.' },
        { name: 'activeLicenses', type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion' },
        { name: 'name' },
        { name: 'healthStatus', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'healthStatus',
            label: 'Health status',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: ' Allowed values are: true, false.'
          } },
        { name: 'siteIds',
          hint: 'List of Site IDs to search for.'\
                ' Site IDs can be separated using comma(,).'\
                " e.g. '225494730938493804,225494730938493915'" }
      ]
    end,

    sites_schema: lambda do
      [
        { name: 'data', type: 'object',
          properties: [
            { name: 'allSites', type: 'object',
              properties: [
                { name: 'totalLicenses', type: 'integer',
                  control_type: 'integer', parse_output: 'integer_conversion' },
                { name: 'activeLicenses', type: 'integer',
                  control_type: 'integer', parse_output: 'integer_conversion' }
              ] },
            { name: 'sites', type: 'array', of: 'object',
              properties: [
                { name: 'expiration' },
                { name: 'suite' },
                { name: 'totalLicenses', type: 'integer',
                  control_type: 'integer', parse_output: 'integer_conversion' },
                { name: 'registrationToken' },
                { name: 'accountName' },
                { name: 'unlimitedLicenses', type: 'boolean',
                  control_type: 'checkbox', parse_output: 'boolean_conversion' },
                { name: 'externalId' },
                { name: 'accountId' },
                { name: 'isDefault', type: 'boolean',
                  control_type: 'checkbox', parse_output: 'boolean_conversion' },
                { name: 'unlimitedExpiration', type: 'boolean',
                  control_type: 'checkbox', parse_output: 'boolean_conversion' },
                { name: 'creatorId' },
                { name: 'createdAt', type: 'date_time',
                  control_type: 'date_time',
                  parse_output: 'date_time_conversion' },
                { name: 'state' },
                { name: 'siteType' },
                { name: 'creator' },
                { name: 'activeLicenses', type: 'integer',
                  control_type: 'integer', parse_output: 'integer_conversion' },
                { name: 'name' },
                { name: 'id' },
                { name: 'healthStatus', type: 'boolean',
                  control_type: 'checkbox', parse_output: 'boolean_conversion' },
                { name: 'updatedAt' }
              ] }
          ] }
      ]
    end,

    locations_search_schema: lambda do
      [
        { name: 'groupIds', label: 'Groups IDs', sticky: true,
          hint: 'List of group IDs to filter by.'\
                ' Group IDs must be separated using the comma(,).'\
                " e.g. '225494730938493804,225494730938493915'" },
        { name: 'description__contains', sticky: true,
          hint: 'Free-text filter by description (supports multiple values).'\
                ' Multiple values can be seperated by comma(,). '\
                "e.g. 'out of office'." },
        { name: 'limit', type: 'integer', sticky: true,
          control_type: 'integer',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: "Limit number of returned items (1-1000). e.g. '10'." },
        { name: 'hostname__contains', sticky: true,
          hint: 'Free-text filter by hostname (supports multiple values).'\
                ' Multiple values can be seperated using comma(,).'\
                " e.g. 'sentinelone.com,localhost'" },
        { name: 'registryKey__contains', sticky: true,
          hint: 'Free-text filter by registry key (supports multiple values).'\
                ' Multiple values can be seperated using comma(,). '\
                "e.g. 'systemsoftware,sentinel'" },
        { name: 'creator__contains', sticky: true,
          hint: 'Free-text filter by creator of the location '\
                '(supports multiple values). Multiple values can be seperated'\
                " using comma(,). e.g. 'max,mike'" },
        { name: 'accountIds', label: 'Account IDs',
          hint: 'List of Account IDs to filter by.'\
          ' Account IDs can be seperated using comma(,).'\
          " e.g. '225494730938493804,225494730938493915'" },
        { name: 'scopes', control_type: 'multiselect',
          label: 'Scopes',
          pick_list: 'scopes',
          pick_list_params: {},
          delimiter: ',',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'scopes',
            label: 'Scopes',
            type: :string,
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: "Allowed values are 'group', 'global', 'account'"\
                  " 'site'. Multiple values can be seperated by comma(,)"
          } },
        { name: 'ids', label: 'IDs',
          hint: 'Filter results by location IDs.'\
          ' Location IDs can be seperated using comma(,).'\
          " e.g. '225494730938493804,225494730938493915'" },
        { name: 'ipAddress__contains', sticky: true,
          hint: 'Free-text filter by IP address (supports multiple values).'\
                ' Multiple values can be seperated using comma(,). '\
                "e.g. '29.213.22.17'" },
        { name: 'hasFirewallRules', type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Filter by locations with/without firewall'\
                ' rules associated to them',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'hasFirewallRules',
            label: 'Has firewall rules',
            optional: true,
            type: 'string',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Filter by locations with/without firewall rules ' \
                  'associated to them. Allowed values are: true, false.'
          } },
        { name: 'name__contains',
          hint: 'Free-text filter by location name (supports multiple values).'\
                ' Multiple values can seperated using comma(,).'\
                " e.g. 'office'" },
        { name: 'siteIds',
          hint: 'List of Site IDs to filter by.'\
                ' Site IDs can be separated using comma(,).'\
                " e.g. '225494730938493804,225494730938493915'" },
        { name: 'scopeName__contains',
          hint: 'Free-text filter by scope name (supports multiple values).'\
                ' Multiple values can be seperated using comma(,).'\
                " e.g. 'my_group,my_site'" }
      ]
    end,

    locations_schema: lambda do
      [
        {
          name: 'data', type: 'array', of: 'object',
          properties: [
            { name: 'dnsLookup', type: 'object',
              properties: [
                { name: 'identifiers', type: 'array', of: 'object',
                  properties: [
                    { name: 'ip' },
                    { name: 'host' }
                  ] },
                { name: 'operator' }
              ] },
            { name: 'dnsServers', type: 'object',
              properties: [
                { name: 'identifiers', type: 'array', of: 'object',
                  properties: [
                    { name: 'type' },
                    { name: 'values', type: 'array', of: 'object',
                      properties: [
                        { name: 'value' }
                      ] }
                  ] },
                { name: 'operator' }
              ] },
            { name: 'reportingAgents', type: 'integer',
              control_type: 'integer',
              parse_output: 'integer_conversion' },
            { name: 'networkInterfaces', type: 'object',
              properties: [
                { name: 'enabled', type: 'boolean', control_type: 'checkbox',
                  parse_output: 'boolean_conversion' },
                { name: 'value' }
              ] },
            { name: 'editable', type: 'boolean', control_type: 'checkbox',
              parse_output: 'boolean_conversion' },
            { name: 'activeFirewallRules', type: 'integer',
              control_type: 'integer', parse_output: 'integer_conversion' },
            { name: 'ipAddresses', type: 'object',
              properties: [
                { name: 'identifiers', type: 'array', of: 'object',
                  properties: [
                    { name: 'type' },
                    { name: 'values', type: 'array', of: 'object',
                      properties: [
                        { name: 'value' }
                      ] }
                  ] },
                { name: 'operator' }
              ] },
            { name: 'scope' },
            { name: 'scopeName' },
            { name: 'updaterId' },
            { name: 'description' },
            { name: 'creatorId' },
            { name: 'updater' },
            { name: 'createdAt', type: 'date_time',
              control_type: 'date_time',
              parse_output: 'date_time_conversion' },
            { name: 'scopeId' },
            { name: 'creator' },
            { name: 'name' },
            { name: 'operator' },
            { name: 'id' },
            { name: 'serverConnectivity', type: 'object',
              properties: [
                { name: 'enabled', type: 'boolean', control_type: 'checkbox',
                  parse_output: 'boolean_conversion' },
                { name: 'value' }
              ] },
            { name: 'registryKeys', type: 'object',
              properties: [
                { name: 'key' },
                { name: 'data' },
                { name: 'value' }
              ] },
            { name: 'updatedAt' },
            { name: 'isFallback',
              type: 'boolean',
              control_type: 'checkbox',
              parse_output: 'boolean_conversion' }
          ]
        }
      ]
    end,

    groups_get_output_schema: lambda do
      [
        { name: 'siteId' },
        { name: 'isDefault', type: 'boolean', control_type: 'checkbox',
          parse_output: 'boolean_conversion' },
        { name: 'type' },
        { name: 'creatorId' },
        { name: 'name' },
        { name: 'createdAt', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'rank', type: 'integer', control_type: 'integer',
          parse_output: 'integer_conversion' },
        { name: 'registrationToken' },
        { name: 'id' },
        { name: 'filterId' },
        { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion' },
        { name: 'creator' }
      ]
    end,

    get_query_status_execute: lambda do |input|
      get('/web/api/v2.0/dv/query-status', input)&.
       after_error_response(/.*/) do |_code, body, _header, message|
         error("#{message}: #{body}")
       end&.[]('data')
    end,

    get_events_execute: lambda do |input|
      get('/web/api/v2.0/dv/events', input)&.
       after_error_response(/.*/) do |_code, body, _header, message|
         error("#{message}: #{body}")
       end
    end,

    get_groups_execute: lambda do |input|
      get("/web/api/v2.0/groups/#{input['group_id']}")&.
       after_error_response(/.*/) do |_code, body, _header, message|
         error("#{message}: #{body}")
       end&.[]('data')
    end,

    search_groups_execute: lambda do |input|
      payload = call('custom_input_parser', input)
      get('/web/api/v2.0/groups', payload)&.
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    search_sites_execute: lambda do |input|
      payload = call('custom_input_parser', input)
      get('/web/api/v2.0/sites', payload)&.
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
    end,

    search_locations_execute: lambda do |input|
      payload = call('custom_input_parser', input)
      response = get('/web/api/v2.0/locations', payload)&.
        after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      { data: call('custom_output_parser', response['data']) }
    end,

    query_status_get_sample_output: lambda do
      { 'responseState': 'Failed',
        'progressStatus': 50 }
    end,

    events_get_sample_output: lambda do
      {}
    end,

    groups_sample_output: lambda do
      get('/web/api/v2.0/groups', limit: 1)
    end,

    groups_get_sample_output: lambda do
      get('/web/api/v2.0/groups', limit: 1)&.[]('data')
    end,

    sites_sample_output: lambda do
      get('/web/api/v2.0/sites', limit: 1)
    end,

    locations_sample_output: lambda do
      get('/web/api/v2.0/locations', limit: 1)
    end,

    make_schema_builder_fields_sticky: lambda do |schema|
      schema.map do |field|
        if field['properties'].present?
          field['properties'] = call('make_schema_builder_fields_sticky',
                                     field['properties'])
        end
        field['sticky'] = true

        field
      end
    end,

    # Formats input/output schema to replace any special characters in name,
    # without changing other attributes (method required for custom action)
    format_schema: lambda do |input|
      input&.map do |field|
        if (props = field[:properties])
          field[:properties] = call('format_schema', props)
        elsif (props = field['properties'])
          field['properties'] = call('format_schema', props)
        end
        if (name = field[:name])
          field[:label] = field[:label].presence || name.labelize
          field[:name] = name.
                         gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        elsif (name = field['name'])
          field['label'] = field['label'].presence || name.labelize
          field['name'] = name.
                          gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        end

        field
      end
    end,

    # Formats payload to inject any special characters that previously removed
    format_payload: lambda do |payload|
      if payload.is_a?(Array)
        payload.map do |array_value|
          call('format_payload', array_value)
        end
      elsif payload.is_a?(Hash)
        payload.each_with_object({}) do |(key, value), hash|
          key = key.gsub(/__\w+__/) do |string|
            string.gsub(/__/, '').decode_hex.as_utf8
          end
          if value.is_a?(Array) || value.is_a?(Hash)
            value = call('format_payload', value)
          end
          hash[key] = value
        end
      end
    end,

    # Formats response to replace any special characters with valid strings
    # (method required for custom action)
    format_response: lambda do |response|
      response = response&.compact unless response.is_a?(String) || response
      if response.is_a?(Array)
        response.map do |array_value|
          call('format_response', array_value)
        end
      elsif response.is_a?(Hash)
        response.each_with_object({}) do |(key, value), hash|
          key = key.gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
          if value.is_a?(Array) || value.is_a?(Hash)
            value = call('format_response', value)
          end
          hash[key] = value
        end
      else
        response
      end
    end
  },

  object_definitions: {
    initiate_scan_input: {
      fields: lambda do |_connection, config_fields|
        if config_fields['schema_builder'].present? &&
           parse_json(config_fields['schema_builder']).present?
          call('initiate_scan_input').
            concat([{ name: 'data', type: 'object', properties:
                 parse_json(config_fields['schema_builder']) }])
        else
          call('initiate_scan_input')
        end
      end
    },

    initiate_scan_output: {
      fields: lambda do
        [
          { name: 'affected', type: 'integer', control_type: 'integer',
            parse_output: 'integer_conversion',
            hint: 'Number of entities affected by the requested operation' }
        ]
      end
    },

    create_query_input: {
      fields: lambda do
        [
          { name: 'groupIds', label: 'Groups IDs',
            sticky: true,
            hint: 'List of group IDs to filter by.'\
            ' Group IDs must be separated using the comma(,).'\
            " e.g. '225494730938493804,225494730938493915'" },
          { name: 'query',
            optional: false,
            hint: 'Events matching the query search term will be returned' },
          { name: 'fromDate',
            optional: false, type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' },
          { name: 'toDate',
            optional: false, type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            hint: 'Events created before or at this timestamp' },
          { name: 'accountIds', label: 'Account IDs',
            sticky: true,
            hint: 'List of Account IDs to filter by.'\
                  ' Account IDs can be seperated using comma(,).'\
                  " e.g. '225494730938493804,225494730938493915'" },
          { name: 'tenant',
            sticky: true, type: 'boolean',
            control_type: 'checkbox',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            hint: 'Indicates a tenant scope request',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'tenant',
              label: 'Tenant',
              optional: true,
              type: 'string',
              control_type: 'text',
              render_input: 'boolean_conversion',
              parse_output: 'boolean_conversion',
              toggle_hint: 'Use custom value',
              hint: 'Indicates a tenant scope request.'\
                    ' Allowed values are: true, false.'
            } },
          { name: 'queryType',
            sticky: true,
            hint: 'Query search type. Multiple values can be seperated'\
                  " using comma(,). e.g. 'events,types'" },
          { name: 'siteIds', sticky: true,
            hint: 'List of Site IDs to filter by.'\
            ' Site IDs can be separated using comma(,).'\
            " e.g. '225494730938493804,225494730938493915'" }
        ]
      end
    },

    create_query_output: {
      fields: lambda do
        [
          { name: 'queryId', hint: 'A query unique identifier' }
        ]
      end
    },

    search_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_search_schema")
      end
    },

    search_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_schema")
      end
    },

    move_agents_input: {
      fields: lambda do |_connection|
        [
          { name: 'group_id', optional: false, hint: "e.g. '225494730938493804'" }
        ].concat(call('initiate_scan_input').ignored('data', 'schema_builder')).concat(
          [{ name: 'agentIds', label: 'Agent IDs',
             sticky: true,
             hint: ' List of agent IDs to move to a new group.'\
                   ' Agent IDs must be separated using the comma(,).'\
                   " e.g. '225494730938493804,225494730938493915'" }]
        )
      end
    },

    move_agents_output: {
      fields: lambda do
        [
          { name: 'agentsMoved', type: 'integer', control_type: 'integer',
            parse_output: 'integer_conversion',
            hint: 'Number of agents that moved to the new group.' }
        ]
      end
    },

    get_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_get_schema")
      end
    },

    get_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_get_output_schema")
      end
    },

    custom_action_input: {
      fields: lambda do |connection, config_fields|
        verb = config_fields['verb']
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')
        data_props =
          input_schema.map do |field|
            if config_fields['request_type'] == 'multipart' &&
               field['binary_content'] == 'true'
              field['type'] = 'object'
              field['properties'] = [
                { name: 'file_content', optional: false },
                {
                  name: 'content_type',
                  default: 'text/plain',
                  sticky: true
                },
                { name: 'original_filename', sticky: true }
              ]
            end
            field
          end
        data_props = call('make_schema_builder_fields_sticky', data_props)
        input_data =
          if input_schema.present?
            if input_schema.dig(0, 'type') == 'array' &&
               input_schema.dig(0, 'details', 'fake_array')
              {
                name: 'data',
                type: 'array',
                of: 'object',
                properties: data_props.dig(0, 'properties')
              }
            else
              { name: 'data', type: 'object', properties: data_props }
            end
          end

        [
          {
            name: 'path',
            hint: 'Base URI is <b>' \
            "#{connection['base_uri']}" \
            '</b> - path will be appended to this URI. Use absolute URI to ' \
            'override this base URI.',
            optional: false
          },
          if %w[post put patch].include?(verb)
            {
              name: 'request_type',
              default: 'json',
              sticky: true,
              extends_schema: true,
              control_type: 'select',
              pick_list: [
                ['JSON request body', 'json'],
                ['URL encoded form', 'url_encoded_form'],
                ['Mutipart form', 'multipart'],
                ['Raw request body', 'raw']
              ]
            }
          end,
          {
            name: 'response_type',
            default: 'json',
            sticky: false,
            extends_schema: true,
            control_type: 'select',
            pick_list: [['JSON response', 'json'], ['Raw response', 'raw']]
          },
          if %w[get options delete].include?(verb)
            {
              name: 'input',
              label: 'Request URL parameters',
              sticky: true,
              add_field_label: 'Add URL parameter',
              control_type: 'form-schema-builder',
              type: 'object',
              properties: [
                {
                  name: 'schema',
                  sticky: input_schema.blank?,
                  extends_schema: true
                },
                input_data
              ].compact
            }
          else
            {
              name: 'input',
              label: 'Request body parameters',
              sticky: true,
              type: 'object',
              properties:
                if config_fields['request_type'] == 'raw'
                  [{
                    name: 'data',
                    sticky: true,
                    control_type: 'text-area',
                    type: 'string'
                  }]
                else
                  [
                    {
                      name: 'schema',
                      sticky: input_schema.blank?,
                      extends_schema: true,
                      schema_neutral: true,
                      control_type: 'schema-designer',
                      sample_data_type: 'json_input',
                      custom_properties:
                        if config_fields['request_type'] == 'multipart'
                          [{
                            name: 'binary_content',
                            label: 'File attachment',
                            default: false,
                            optional: true,
                            sticky: true,
                            control_type: 'checkbox',
                            type: 'boolean',
                            render_input: 'boolean_conversion',
                            parse_output: 'boolean_conversion'
                          }]
                        end
                    },
                    input_data
                  ].compact
                end
            }
          end,
          {
            name: 'request_headers',
            sticky: false,
            extends_schema: true,
            control_type: 'key_value',
            empty_list_title: 'Does this HTTP request require headers?',
            empty_list_text: 'Refer to the API documentation and add ' \
            'required headers to this HTTP request',
            item_label: 'Header',
            type: 'array',
            of: 'object',
            properties: [{ name: 'key' }, { name: 'value' }]
          },
          unless config_fields['response_type'] == 'raw'
            {
              name: 'output',
              label: 'Response body',
              sticky: true,
              extends_schema: true,
              schema_neutral: true,
              control_type: 'schema-designer',
              sample_data_type: 'json_input'
            }
          end,
          {
            name: 'response_headers',
            sticky: false,
            extends_schema: true,
            schema_neutral: true,
            control_type: 'schema-designer',
            sample_data_type: 'json_input'
          }
        ].compact
      end
    },

    custom_action_output: {
      fields: lambda do |_connection, config_fields|
        response_body = { name: 'body' }

        [
          if config_fields['response_type'] == 'raw'
            response_body
          elsif (output = config_fields['output'])
            output_schema = call('format_schema', parse_json(output))
            if output_schema.dig(0, 'type') == 'array' &&
               output_schema.dig(0, 'details', 'fake_array')
              response_body[:type] = 'array'
              response_body[:properties] = output_schema.dig(0, 'properties')
            else
              response_body[:type] = 'object'
              response_body[:properties] = output_schema
            end

            response_body
          end,
          if (headers = config_fields['response_headers'])
            header_props = parse_json(headers)&.map do |field|
              if field[:name].present?
                field[:name] = field[:name].gsub(/\W/, '_').downcase
              elsif field['name'].present?
                field['name'] = field['name'].gsub(/\W/, '_').downcase
              end
              field
            end

            { name: 'headers', type: 'object', properties: header_props }
          end
        ].compact
      end
    }

  },

  actions: {
    initiate_scan: {
      title: 'Initiate scan',
      subtitle: 'Initiate scan in SentinelOne',
      description: "Initiate <span class='provider'>scan</span> in "\
      "<span class='provider'>SentinelOne</span>",
      help: 'Use this action to run a Full Disk Scan on Agents that match the' \
      ' filter. Full Disk Scan finds dormant suspicious activity, threats, ' \
      'and compliance violations, that are then mitigated according to the policy.' \
      "To learn more see the <a href='https://support.sentinelone.com/hc/en-us/articles" \
      "/360021865934-Full-Disk-Scan-FAQ' target='_blank'>FAQ</a>",
      input_fields: lambda do |object_definition|
        object_definition['initiate_scan_input']
      end,
      execute: lambda do |_connection, input|
        input['data'] = {} unless input['data'].present?
        payload = { filter: call('custom_input_parser',
                                 input.except('data', 'schema_builder')),
                    data: input['data'] }
        post('/web/api/v2.0/agents/actions/initiate-scan', payload)&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.[]('data')
      end,
      output_fields: lambda do |object_definition|
        object_definition['initiate_scan_output']
      end,
      sample_output: lambda do |_connection, _input|
        { 'affected': 0 }
      end
    },

    disconnect_from_network: {
      title: 'Disconnect machine from network',
      subtitle: 'Disconnect machine from network e.g. Demo123',
      description: "Disconnect <span class='provider'>machine</span> from network in "\
      "<span class='provider'>SentinelOne</span>",
      help: 'Use this action to isolate (quarantine) endpoints from the network,' \
      ' if the endpoints match the filter. The Agent can communicate with the ' \
      'Management, which lets you analyze and mitigate threats. Refer API docs for more details.',
      input_fields: lambda do |object_definition|
        object_definition['initiate_scan_input']
      end,
      execute: lambda do |_connection, input|
        input['data'] = {} unless input['data'].present?
        payload = { filter: call('custom_input_parser',
                                 input.except('data', 'schema_builder')),
                    data: input['data'] }
        post('/web/api/v2.0/agents/actions/disconnect', payload)&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.[]('data')
      end,
      output_fields: lambda do |object_definition|
        object_definition['initiate_scan_output']
      end,
      sample_output: lambda do |_connection, _input|
        { 'affected': 0 }
      end
    },

    create_and_get_queryid: {
      title: 'Create and get query ID',
      subtitle: 'Create query and get query ID',
      description: "Create & get <span class='provider'>query</span> ID in "\
      "<span class='provider'>SentinelOne</span>",
      help: 'Start a Deep Visibility Query and get the queryId. You can use ' \
      'the queryId for other actions, such as Get Events and Get Query Status. ' \
      "For complete query syntax, check this <a href='https://support.sentinelone.com" \
      "/hc/en-us/articles/360011595734' target='_blank'>article</a>",
      input_fields: lambda do |object_definition|
        object_definition['create_query_input']
      end,
      execute: lambda do |_connection, input|
        payload = call('custom_input_parser', input)
        post('/web/api/v2.0/dv/init-query', payload)&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.[]('data')
      end,
      output_fields: lambda do |object_definition|
        object_definition['create_query_output']
      end,
      sample_output: lambda do |_connection, _input|
        { 'queryId': 'q1xx34yyy56' }
      end
    },

    get_object_by_id: {
      title: 'Get object by ID',
      subtitle: 'Get an object in SentinelOne. e.g. events',
      description: lambda do |_connection, get_object_list|
        object_name = {
          'Query status' => 'query status',
          'Events' => 'events',
          'Group' => 'groups'
        }[get_object_list[:object]]
        "Get <span class='provider'>#{object_name || 'an object'}</span> in "\
        "<span class='provider'>SentinelOne</span>"
      end,
      help: lambda do |_connection, get_object_list|
        help = {
          'Events' => 'Get all Deep Visibility events from a queryId. You can use' \
          ' this action to send a sub-query, a new query to run on these events.' \
          " Get the ID from 'init-query'. See 'Create Query and get QueryId'. For " \
          "complete query syntax, click <a href='https://support.sentinelone.com/hc/en-us/" \
          "articles/360011595734' target='_blank'>here</a>."
        }[get_object_list[:object]]
        help
      end,
      config_fields: [
        { name: 'object', optional: false,
          label: 'Object type', control_type: 'select',
          pick_list: 'get_object_list',
          hint: 'Select the object type from list.' }
      ],
      input_fields: lambda do |object_definition|
        object_definition['get_object_input']
      end,
      execute: lambda do |_connection, input|
        object_name = input.delete('object')
        call("get_#{object_name}_execute", input)
      end,
      output_fields: lambda do |object_definition|
        object_definition['get_object_output']
      end,
      sample_output: lambda do |_connection, input|
        call("#{input['object']}_get_sample_output")
      end
    },

    search_objects: {
      title: 'Search objects',
      subtitle: 'Search an objects in SentinelOne. e.g. groups',
      description: lambda do |_connection, search_object_list|
        object_name = {
          'Groups' => 'groups',
          'Sites' => 'sites',
          'Locations' => 'locations'
        }[search_object_list[:object]]
        "Search <span class='provider'>#{object_name || 'an object'}</span> in "\
        "<span class='provider'>SentinelOne</span>"
      end,
      help: lambda do |_connection, search_object_list|
        help = {
          'Groups' => 'Get data of groups that match the filter. Best' \
          ' practice: use as narrow a filter as you can. The data can be' \
          ' quite long for many groups. The response returns the ID of each ' \
          'group, which you can use in other actions.',
          'Sites' => 'List all sites that matches filter options',
          'Locations' => 'Get the locations of Agents in a given scope that match the filter'
        }[search_object_list[:object]]
        help
      end,
      config_fields: [
        { name: 'object', optional: false,
          label: 'Object type', control_type: 'select',
          pick_list: 'search_object_list',
          hint: 'Select the object type from list.' }
      ],
      input_fields: lambda do |object_definition|
        object_definition['search_object_input']
      end,
      execute: lambda do |_connection, input|
        object_name = input.delete('object')
        call("search_#{object_name}_execute", input)
      end,
      output_fields: lambda do |object_definition|
        object_definition['search_object_output']
      end,
      sample_output: lambda do |_connection, input|
        call("#{input['object']}_sample_output")
      end
    },

    move_agents: {
      title: 'Move agents',
      subtitle: 'Move agents in SentinelOne',
      description: "Move <span class='provider'>agent's</span> to new group in "\
      "<span class='provider'>SentinelOne</span>",
      help: 'Move Agents that match the filter to a Group. The Group ID' \
      ' is required and there can be only one. This will move' \
      ' the matched Agents that are in the same Site as the given Group.',
      input_fields: lambda do |object_definition|
        object_definition['move_agents_input']
      end,
      execute: lambda do |_connection, input|
        payload = { filter: call('custom_input_parser',
                                 input.except('group_id')) }
        put("/web/api/v2.0/groups/#{input['group_id']}/move-agents", payload)&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |object_definition|
        object_definition['move_agents_output']
      end,
      sample_output: lambda do |_connection, _input|
        { 'agentsMoved': 0 }
      end
    },

    custom_action: {
      subtitle: 'Build your own SentinelOne action with a HTTP request',

      description: lambda do |object_value, _object_label|
        "<span class='provider'>" \
        "#{object_value[:action_name] || 'Custom action'}</span> in " \
        "<span class='provider'>SentinelOne</span>"
      end,

      help: {
        body: 'Build your own SentinelOne action with a HTTP request. ' \
              'The request will be authorized with your SentinelOne connection.' \
              'Refer the <b>API doc</b> under in your application'
      },

      config_fields: [
        {
          name: 'action_name',
          hint: "Give this action you're building a descriptive name, e.g. " \
          'create record, get record',
          default: 'Custom action',
          optional: false,
          schema_neutral: true
        },
        {
          name: 'verb',
          label: 'Method',
          hint: 'Select HTTP method of the request',
          optional: false,
          control_type: 'select',
          pick_list: %w[get post put options delete].
            map { |verb| [verb.upcase, verb] }
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['custom_action_input']
      end,

      execute: lambda do |_connection, input|
        verb = input['verb']
        if %w[get post put patch options delete].exclude?(verb)
          error("#{verb.upcase} not supported")
        end
        path = input['path']
        data = input.dig('input', 'data') || {}
        if input['request_type'] == 'multipart'
          data = data.each_with_object({}) do |(key, val), hash|
            hash[key] = if val.is_a?(Hash)
                          [val[:file_content],
                           val[:content_type],
                           val[:original_filename]]
                        else
                          val
                        end
          end
        end
        request_headers = input['request_headers']&.
          each_with_object({}) do |item, hash|
          hash[item['key']] = item['value']
        end || {}
        request = case verb
                  when 'get'
                    get(path, data)
                  when 'post'
                    if input['request_type'] == 'raw'
                      post(path).request_body(data)
                    else
                      post(path, data)
                    end
                  when 'put'
                    if input['request_type'] == 'raw'
                      put(path).request_body(data)
                    else
                      put(path, data)
                    end
                  when 'patch'
                    if input['request_type'] == 'raw'
                      patch(path).request_body(data)
                    else
                      patch(path, data)
                    end
                  when 'options'
                    options(path, data)
                  when 'delete'
                    delete(path, data)
                  end.headers(request_headers)
        request = case input['request_type']
                  when 'url_encoded_form'
                    request.request_format_www_form_urlencoded
                  when 'multipart'
                    request.request_format_multipart_form
                  else
                    request
                  end
        response =
          if input['response_type'] == 'raw'
            request.response_format_raw
          else
            request
          end.
          after_error_response(/.*/) do |code, body, headers, message|
            error({ code: code, message: message, body: body, headers: headers }.to_json)
          end

        response.after_response do |_code, res_body, res_headers|
          {
            body: res_body ? call('format_response', res_body) : nil,
            headers: res_headers
          }
        end
      end,

      output_fields: lambda do |object_definition|
        object_definition['custom_action_output']
      end
    }
  },

  pick_lists: {
    decommissioned: lambda do
      [
        ['Active', true],
        ['Decommissioned', false]
      ]
    end,
    mitigation_mode_suspicious: lambda do
      [
        %w[Detect detect],
        %w[Protect protect]
      ]
    end,
    migration_status: lambda do
      %w[N/A Pending Migrated Failed].map { |key| [key, key] }
    end,
    threat_mitigation_status: lambda do
      %w[active mitigated blocked suspicious pending suspicious_resolved]&.
      map { |key| [key.labelize, key] }
    end,
    scan_status: lambda do
      %w[none started aborted finished].map { |key| [key.labelize, key] }
    end,
    ranger_status: lambda do
      %w[NotApplicable Enabled Disabled].map { |key| [key.labelize, key] }
    end,
    os_arch_list: lambda do
      %w[32\ bit 64\ bit].map { |key| [key, key] }
    end,
    is_uninstalled: lambda do
      [
        ['Installed', true],
        ['Uninstalled', false]
      ]
    end,
    get_object_list: lambda do
      %w[query_status events groups].map { |key| [key.labelize, key] }
    end,
    search_object_list: lambda do
      %w[groups sites locations].map { |key| [key.labelize, key] }
    end,
    suite: lambda do
      %w[Core Control Complete].map { |key| [key, key] }
    end,
    state: lambda do
      %w[active expired deleted].map { |key| [key.labelize, key] }
    end,
    site_types: lambda do
      %w[Trial Paid].map { |key| [key, key] }
    end,
    features: lambda do
      %w[firewall-control device-control ioc]. map { |key| [key.labelize, key] }
    end,
    scopes: lambda do
      %w[group global account site]. map { |key| [key.labelize, key] }
    end,
    sort_order: lambda do
      [
        %w[Ascending asc],
        %w[Descending desc]
      ]
    end
  }
}
