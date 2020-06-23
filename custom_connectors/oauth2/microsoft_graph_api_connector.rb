{
  title: 'Microsoft Graph API',

  connection: {
    fields: [
      {
        name: 'client_id',
        optional: false,
        hint: "Click <a href='https://docs.microsoft.com/en-us/graph/" \
          "auth-register-app-v2?context=graph%2Fapi%2F1.0&view=graph-rest-1.0'" \
          " target='_blank'>here</a> to get client ID and secret."
      },
      {
        name: 'client_secret',
        control_type: 'password',
        optional: false,
        hint: "Click <a href='https://docs.microsoft.com/en-us/graph/" \
          "auth-register-app-v2?context=graph%2Fapi%2F1.0&view=graph-rest-1.0'" \
          " target='_blank'>here</a> to get client ID and secret."
      },
      {
        name: 'api_version',
        label: 'API Version',
        control_type: 'select',
        pick_list: [['Version 1', 'v1.0']],
        optional: false
      },
      { name: 'account_type',
        control_type: 'select',
        optional: false,
        pick_list: [
          %w[Single\ tenant single_tenant],
          %w[Multitenant organizations],
          %w[Active\ directory\ multitenant common]
        ] },
      {
        name: 'tenant_id',
        ngIf: 'input.account_type == "single_tenant"',
        label: 'Tenant ID',
        hint: 'Required for Single tenant. Tenant ID is generated during App registration process '\
          'for Client ID and Client secret. Use the tenant ID from Oauth client app.'
      }
    ],

    authorization: {
      type: 'oauth2',

      authorization_url: lambda do |connection|
        tenant_id = if connection['account_type'].include?('single_tenant')
                      connection['tenant_id']
                    else
                      connection['account_type']
                    end
        params = {
          scope: 'offline_access Files.ReadWrite.All User.Read profile openid',
          response_type: 'code',
          client_id: connection['client_id'],
          response_mode: 'query',
          redirect_uri: 'https://www.workato.com/oauth/callback'
        }.to_param
        "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/authorize?" + params
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        tenant_id = if connection['account_type'].include?('single_tenant')
                      connection['tenant_id']
                    else
                      connection['account_type']
                    end
        post("https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token").
          payload(client_id: connection['client_id'],
                  client_secret: connection['client_secret'],
                  grant_type: 'authorization_code',
                  code: auth_code,
                  redirect_uri: redirect_uri).
          request_format_www_form_urlencoded
      end,

      refresh_on: [401, 403],

      refresh: lambda do |connection, refresh_token|
        tenant_id = if connection['account_type'].include?('single_tenant')
                      connection['tenant_id']
                    else
                      connection['account_type']
                    end
        scopes = 'offline_access Files.ReadWrite.All User.Read profile openid' # User.Read.All
        post("https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token").
          payload(client_id: connection['client_id'],
                  client_secret: connection['client_secret'],
                  grant_type: 'refresh_token',
                  refresh_token: refresh_token,
                  redirect_uri: 'https://www.workato.com/oauth/callback',
                  scope: scopes).
          request_format_www_form_urlencoded
      end,

      apply: lambda do |_connection, access_token|
        headers('Authorization' => "Bearer #{access_token}")
      end
    },

    base_uri: lambda do
      'https://graph.microsoft.com'
    end
  },

  test: lambda do |connection|
    get("#{connection['api_version']}/me")
  end,

  methods: {
    worksheet_output: lambda do |input|
      get("/v1.0/me/drive/items/#{input['file']}/workbook/worksheets" \
          "('#{input['worksheet']}')/usedRange?$select=formulas")['formulas']&.
          first&.map do |name|
            { name: name, label: name }
          end
    end,

    get_input: lambda do |input|
      case input[:object]
      when 'drive'
        [
          { name: 'drive_id', sticky: true, label: 'Drive ID',
            hint: 'Get drive by ID' }
        ]
      when /download_file|driveItem/
        [
          { name: 'drive_id',
            label: 'Drive',
            optional: false,
            control_type: 'select',
            pick_list: 'get_drives',
            change_on_blur: true,
            extends_schema: true,
            toggle_hint: 'Select from list',
            toggle_field: {
              toggle_hint: 'Enter drive ID',
              name: 'drive_id',
              change_on_blur: true,
              extends_schema: true,
              label: 'Drive ID',
              type: 'string',
              control_type: 'text',
              optional: false
            } },
          { name: 'item_id', optional: false, label: 'Item ID',
            hint: 'Get items in a drive.' }
        ]
      when 'folder'
        [
          { name: 'drive_id',
            label: 'Drive',
            optional: false,
            control_type: 'select',
            pick_list: 'get_drives',
            change_on_blur: true,
            extends_schema: true,
            toggle_hint: 'Select from list',
            toggle_field: {
              toggle_hint: 'Enter drive ID',
              name: 'drive_id',
              change_on_blur: true,
              extends_schema: true,
              label: 'Drive ID',
              type: 'string',
              control_type: 'text',
              optional: false
            } },
          { name: 'folder_id',
            label: 'Folder',
            control_type: 'tree',
            tree_options: { selectable_folder: true },
            pick_list: :folders,
            pick_list_params: { drive_id: 'drive_id' },
            optional: false,
            toggle_hint: 'Select folder',
            toggle_field: {
              name: 'folder_id',
              type: 'string',
              control_type: 'text',
              label: 'Folder ID',
              toggle_hint: 'Use folder ID'
            } }
        ]
      when 'site'
        [
          { name: 'site_id',
            label: 'Site',
            control_type: 'tree',
            sticky: true,
            tree_options: { selectable_folder: true },
            pick_list: :sites,
            optional: false,
            hint: 'By default, sites will be picked up from the communication site directory',
            toggle_hint: 'Select site',
            toggle_field: {
              name: 'site_id',
              type: 'string',
              control_type: 'text',
              label: 'Site ID',
              toggle_hint: 'Use site ID',
              hint: 'By default, sites will be picked up from the communication site directory'
            } }
        ]
      when 'list'
        [
          { name: 'site_id',
            label: 'Site',
            control_type: 'tree',
            sticky: true,
            tree_options: { selectable_folder: true },
            pick_list: :sites,
            optional: false,
            hint: 'By default, sites will be picked up from the communication site directory',
            toggle_hint: 'Select site',
            toggle_field: {
              name: 'site_id',
              type: 'string',
              control_type: 'text',
              label: 'Site ID',
              toggle_hint: 'Use site ID',
              hint: 'By default, sites will be picked up from the communication site directory'
            } },
          { name: 'list_id', optional: false }
        ]
      when 'listItem'
        [
          { name: 'site_id',
            label: 'Site',
            control_type: 'tree',
            sticky: true,
            tree_options: { selectable_folder: true },
            pick_list: :sites,
            extends_schema: true,
            optional: false,
            hint: 'By default, sites will be picked up from the communication site directory',
            toggle_hint: 'Select site',
            toggle_field: {
              name: 'site_id',
              type: 'string',
              control_type: 'text',
              label: 'Site ID',
              extends_schema: true,
              toggle_hint: 'Use site ID',
              hint: 'By default, sites will be picked up from the communication site directory'
            } },
          { name: 'list_id', optional: false, extends_schema: true },
          { name: 'item_id', optional: false }
        ]
      when 'user'
        [
          { name: 'user_id', optional: false }
        ]
      when 'licenseDetails'
        [
          { name: 'user_id',
            label: 'User ID',
            sticky: true,
            hint: 'Skip this field to make changes to the owner of the conection' },
          { name: 'addLicenses', type: 'array', of: 'object',
            item_label: 'License',
            add_item_label: 'Add license',
            empty_list_title: 'License list is empty',
            sticky: true,
            properties: [
              { name: 'skuId',
                label: 'SKU ID',
                control_type: 'select',
                pick_list: 'get_licenses',
                sticky: true,
                optional: false,
                toggle_hint: 'Select from list',
                toggle_field: {
                  toggle_hint: 'Enter license SKU ID',
                  name: 'skuId',
                  change_on_blur: true,
                  extends_schema: true,
                  label: 'License SKU ID',
                  type: 'string',
                  control_type: 'text',
                  optional: false
                } },
              { name: 'disabledPlans', label: 'Service disabled plans', optional: false,
                type: 'array', of: 'object',
                item_label: 'Disabled plans',
                add_item_label: 'Add disabled plan',
                empty_list_title: 'Disabled plan list is empty',
                properties: [
                  { name: 'id', optional: false }
                ] }
            ] },
          { name: 'removeLicenses',
            control_type: 'multiselect',
            delimiter: '\n',
            pick_list: 'get_licenses',
            optional: true,
            hint: 'Select one or more licenses to unassign from user',
            toggle_hint: 'Select from list',
            toggle_field: {
              toggle_hint: 'Enter license IDs',
              name: 'removeLicenses',
              change_on_blur: true,
              extends_schema: true,
              label: 'License ID',
              type: 'string',
              control_type: 'text',
              optional: true,
              hint: 'Type in the license SKU IDs, one per line, to remove the ' \
                    'licenses from the user'
            } }
        ]
      when 'workbook_sheets'
        [{ name: 'id', type: :string, control_type: :string, optional: false,
           label: 'Workbook ID' }]
      when 'worksheet_content'
        [
          { name: 'id', type: :string, control_type: :text,
            label: 'Workbook ID', optional: false },
          { name: 'sheet', type: :string, control_type: :text,
            label: 'Sheet Name', optional: false },
          { name: 'address', type: :string, control_type: :text,
            label: 'Address', optional: false }
        ]
      else
        []
      end
    end,

    get_sample_url: lambda do |connection, input|
      case input['object']
      when /list|listItem/
        call(:get_url, connection, 'object' => 'lists')
      when 'site'
        '/v1.0/sites?search='
      when 'driveItem'
        call(:get_url, connection, 'object' => 'driveItems')
      when /licenseDetails|license/
        call(:get_url, connection, 'object' => 'licenses')
      else
        call(:get_url, connection, input)
      end
    end,

    get_search_url: lambda do |connection, input|
      if input['object'] == 'driveItem'
        "#{connection['api_version']}/drives/#{input['drive_id']}/root/search" +
          "(q='{#{input['q']}}')".encode_url
      else
        input['object'] = input['object'].pluralize
        call(:get_url, connection, input)
      end
    end,

    get_update_url: lambda do |connection, input|
      if input['object'] == 'folder'
        input['object'] = 'driveItem'
        input['item_id'] = input['id'] if input['id'].present?
      elsif input['object'] == 'list'
        input['list_id'] = input['id'] if input['id'].present?
      elsif input['object'] == 'listItem'
        input['item_id'] = input['id'] if input['id'].present?
      end
      call(:get_url, connection, input)
    end,

    get_url: lambda do |connection, input|
      connection['api_version'] +
        case input['object']
        when /user|users/
          "/users/#{input['user_id']}"
        when 'driveItem'
          "/drives/#{input['drive_id']}/items/#{input['item_id']}"
        when 'driveItems'
          if input['drive_id'].present?
            "/drives/#{input['drive_id']}/items/#{input['item_id'].presence || 'root'}/children"
          else
            '/me/drive/root/children'
          end
        when 'get_drive'
          "/drives/#{input['drive_id']}"
        when 'get_drive_item'
          "/me/drive/items/#{input['item_id']}"
        when 'download_file'
          "/drives/#{input['drive_id']}/items/#{input['item_id']}/content"
        when 'upload_file'
          "/drives/#{input['drive_id'].presence || 'root'}/items/" \
          "#{input['folder_id'] || 'root'}:/#{input['filename']}:/content"
        when 'folder'
          if input['drive_id'] .present?
            "/drives/#{input['drive_id']}/items/#{input['folder_id'] || 'root'}/children"
          else
            "/me/drive/items/#{input['folder_id'] || 'root'}/children"
          end
        when 'create_sharing_link'
          "/drive/items/#{input['folder_id']}/createLink"
        when 'update_permission'
          "/#{input['object']}/#{input['object_id']}/#{input['item_id']}/#{input['permission_id']}"
        when 'site'
          "/sites/#{input['site_id'].presence || 'root'}"
        when 'list'
          "/sites/#{input['site_id'].presence || 'root'}/lists/#{input['list_id']}"
        when 'lists'
          "/sites/#{input['site_id'].presence || 'root'}/lists/"
        when 'listItem'
          "/sites/#{input['site_id'].presence || 'root'}/lists/"\
          "#{input['list_id']}/items/#{input['item_id']}"
        when 'listItems'
          "/sites/#{input['site_id'].presence || 'root'}/lists/#{input['list_id']}/items"
        when 'licenses'
          input['id'].present? ? "/users/#{input['id']}/licenseDetails" : '/me/licenseDetails'
        when 'licenseDetails'
          if input['user_id'].present?
            "/users/#{input['user_id']}/assignLicense"
          else
            '/me/assignLicense'
          end
        when 'worksheet_content'
          "/me/drive/items/#{input['id']}/workbook/worksheets" \
            "('#{input['sheet']}')/range(address='#{input['address']}')"
        end
    end,

    get_metadata: lambda do |input, is_input|
      all_metadata = get('https://graph.microsoft.com/v1.0/$metadata').response_format_xml&.
        after_error_response do |_code, _body, _header, _messages|
          {}
        end&.dig('edmx:Edmx', 0, 'edmx:DataServices', 0, 'Schema', 0)
      metadata = all_metadata&.[]('EntityType')&.
        each_with_object({}) do |entity, h|
          h[entity['@Name']] = entity
        end
      metadata = all_metadata&.[]('ComplexType')&.
        each_with_object(metadata) do |entity, h|
          h[entity['@Name']] = entity
        end
      if input[:object] == 'folder' || input[:object] == 'file'
        call(:generate_schema,
             { metadata: metadata,
               object: 'driveItem',
               navigation: false }, is_input)&.presence || [{}]
      else
        required_fields = ['accountEnabled'] if input[:object] == 'user'
        call(:generate_schema,
             { metadata: metadata,
               object: input[:object],
               required_fields: required_fields,
               navigation: false }, is_input)&.presence || [{}]
      end
    end,

    get_line_item_schema: lambda do |connection, input|
      if input[:site_id].present? && input[:list_id].present?
        get("#{connection['api_version']}/sites/#{input[:site_id]}/lists/"\
            "#{input[:list_id]}?expand=columns&select=name,id")&.[]('columns')
      else
        []
      end&.
        map do |column|
          if column['readOnly'] == false && column['columnGroup'] != '_Hidden'
            key = column.keys
            if key.include?('boolean')
              { name: column['name'], type: 'boolean',
                control_type: 'checkbox',
                label: column['displayName'],
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                optional: !column['required'],
                hint: column['description'],
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: column['name'], label: column['displayName'],
                  type: 'boolean',
                  control_type: 'text',
                  optional: !column['required'],
                  render_input: 'boolean_conversion',
                  parse_output: 'boolean_conversion',
                  toggle_hint: 'Enter custom value',
                  hint: column['description']
                } }
            elsif key.include?('choice')
              { name: column['name'],
                label: column['displayName'],
                control_type: 'select',
                pick_list: column.dig('choice', 'choices').map { |fields| [fields, fields] },
                optional: !column['required'],
                hint: column['description'],
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: column['name'], label: column['displayName'],
                  type: 'string',
                  control_type: 'text',
                  optional: !column['required'],
                  toggle_hint: 'Enter custom value',
                  hint: column['description']
                } }
            elsif key.include?('dateTime')
              { name: column['name'], label: column['displayName'],
                type: 'date_time',
                control_type: 'date_time',
                render_input: 'date_time_conversion',
                parse_output: 'date_time_conversion',
                optional: !column['required'],
                hint: column['description'] }
            elsif key.include?('number')
              { name: column['name'], label: column['displayName'],
                type: 'number',
                control_type: 'number',
                render_input: 'integer_conversion',
                parse_output: 'integer_conversion',
                optional: !column['required'],
                hint: column['description'] }
            else
              { name: column['name'], label: column['displayName'],
                type: 'string',
                control_type: 'text',
                optional: !column['required'],
                hint: column['description'] }
            end
          end
        end&.compact
    end,

    build_schema: lambda do |metadata, input, optional, navigation, is_input|
      case input['@Type']
      when 'Edm.String'
        { name: input['@Name'], type: 'string', optional: optional }
      when 'Edm.Boolean'
        { name: input['@Name'], type: 'boolean',
          control_type: 'checkbox',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          optional: optional,
          toggle_field: {
            toggle_hint: 'Enter custom value',
            name: input['@Name'],
            label: input['@Name'].labelize,
            type: 'boolean',
            control_type: 'text',
            optional: optional,
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion'
          } }
      when 'Edm.Byte'
        { name: input['@Name'], type: 'integer',
          control_type: 'number', optional: optional }
      when 'Edm.DateTime'
        { name: input['@Name'], type: 'date_time', optional: optional,
          control_type: 'date_time' }
      when 'Edm.Decimal'
        { name: input['@Name'], type: 'number', optional: optional,
          control_type: 'number' }
      when 'Edm.Double'
        { name: input['@Name'], type: 'number', optional: optional,
          control_type: 'number' }
      when 'Edm.Single'
        { name: input['@Name'], type: 'number', optional: optional,
          control_type: 'number' }
      when 'Edm.Guid'
        { name: input['@Name'], type: 'string', optional: optional }
      when 'Edm.Int16'
        { name: input['@Name'], type: 'integer', optional: optional,
          control_type: 'number' }
      when 'Edm.Int32'
        { name: input['@Name'], type: 'integer', optional: optional,
          control_type: 'number' }
      when 'Edm.Int64'
        { name: input['@Name'], type: 'integer', optional: optional,
          control_type: 'number' }
      when 'Edm.SByte'
        { name: input['@Name'], type: 'integer', optional: optional,
          control_type: 'number' }
      when 'Edm.Time'
        { name: input['@Name'], type: 'string', optional: optional }
      when 'Edm.DateTimeOffset'
        { name: input['@Name'], type: 'timestamp', optional: optional,
          control_type: 'date_time' }
      when /^microsoft.graph.*|^graph.*/
        { name: input['@Name'],
          type: 'object',
          optional: optional,
          properties: call('generate_schema',
                           { metadata: metadata,
                             object: input['@Type'].split('.').last,
                             navigation: navigation }, is_input) }
      when /^Collection\(*/
        { name: input['@Name'],
          type: 'array', of: 'object',
          optional: optional,
          item_label: input['@Name'].labelize,
          add_item_label: "Add #{input['@Name'].labelize.downcase}",
          empty_list_title: "input['@Name'].labelize list is empty",
          properties: call('generate_schema',
                           { metadata: metadata,
                             object: input['@Type'].
                             scan(/(?<=Collection\()(.*)(?=\))/).
                             flatten[0].gsub('graph.', ''),
                             navigation: navigation }, is_input) }
      else
        { name: input['@Name'], type: 'string', optional: optional }
      end
    end,

    generate_schema: lambda do |input, is_input|
      schema = []
      if input.dig(:metadata, input[:object], '@BaseType').present?
        schema.concat call('generate_schema',
                           { metadata: input[:metadata],
                             object: input.dig(:metadata, input[:object], '@BaseType')&.
                                     split('.')&.last,
                             navigation: false }, is_input)
      end
      schema.concat(input&.dig(:metadata, input[:object], 'Property')&.map do |o|
        optional = !(input[:required_fields].present? &&
                     input[:required_fields].include?(o['@Name']))
        call(:build_schema, input[:metadata], o, optional, false, is_input)
      end.to_a)
      unless input[:navigation]
        schema.concat(input&.dig(:metadata, input[:object], 'NavigationProperty')&.map do |o|
          optional = !(input[:required_fields].present? &&
                       input[:required_fields].include?(o['@Name']))
          call(:build_schema, input[:metadata], o, optional, true, is_input)
        end.to_a)
      end
      if is_input
        schema.ignored('createdBy', 'createdDateTime', 'eTag', 'lastModifiedBy',
                       'lastModifiedDateTime', 'parentReference', 'size', 'folder',
                       'fileSystemInfo', 'remoteItem', 'file', 'createdByUser', 'subscriptions',
                       'lastModifiedByUser', 'system', 'list', 'drive', 'sharepointIds',
                       'contentType', 'contentTypes', 'analytics', 'driveItem', 'fields', 'audio',
                       'content', 'cTag', 'deleted', 'image', 'location', 'package',
                       'photo', 'publication', 'searchResult', 'shared', 'specialFolder',
                       'video', 'webDavUrl', 'workbook', 'listItem')
      else
        schema
      end
    end,

    make_schema_builder_fields_sticky: lambda do |schema|
      schema.map do |field|
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

    format_schema: lambda do |input|
      input&.map do |field|
        if (props = field[:properties])
          field[:properties] = call('format_schema', props)
        elsif (props = field['properties'])
          field['properties'] = call('format_schema', props)
        end
        if (name = field[:name])
          field[:label] = field[:label].presence || name.labelize
          field[:name] = name.gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        elsif (name = field['name'])
          field['label'] = field['label'].presence || name.labelize
          field['name'] = name.gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        end

        field
      end
    end,

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
          value = call('format_payload', value) if value.is_a?(Array) || value.is_a?(Hash)
          hash[key] = value
        end
      end
    end,

    format_response: lambda do |response|
      response = response&.compact unless response.is_a?(String) || response
      if response.is_a?(Array)
        response.map do |array_value|
          call('format_response', array_value)
        end
      elsif response.is_a?(Hash)
        response.each_with_object({}) do |(key, value), hash|
          key = key.gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
          value = call('format_response', value) if value.is_a?(Array) || value.is_a?(Hash)
          hash[key] = value
        end
      else
        response
      end
    end
  },

  object_definitions: {
    worksheet_output: {
      fields: lambda do |_connection, config_fields|
        call('worksheet_output', config_fields)
      end
    },
    get_object_output: {
      fields: lambda do |_connection, config_fields|
        if config_fields['object'] == 'workbook_sheets'
          [
            { name: 'worksheets', type: 'array', of: 'object',
              properties: [
                { name: 'id', type: :string, control_type: :text },
                { name: 'name', type: :string, control_type: :text },
                { name: 'position', type: :integer, control_type: :number },
                { name: 'visibility', type: :string, control_type: :text }
              ] }
          ]
        elsif config_fields['object'] == 'worksheet_content'
          [
            { name: 'address', type: :string, label: 'Address Range' },
            { name: 'cellCount', type: :integer, label: 'Cell Count' },
            { name: 'columnCount', type: :integer },
            { name: 'columnIndex', type: :integer },
            { name: 'rowCount', type: :integer },
            { name: 'rowIndex', type: :integer },
            { name: 'values', type: :array, of: :array, properties: [] }
          ]
        elsif config_fields['object'] == 'row'
          [
            { name: 'odata_id', type: :string },
            { name: 'address', type: :string },
            { name: 'cellCount', type: :integer },
            { name: 'columnCount', type: :integer },
            { name: 'rowCount', type: :integer },
            { name: 'rowIndex', type: :integer }
          ]
        else
          object = if config_fields['object'] == 'license'
                     'licenseDetails'
                   else
                     config_fields['object']
                   end
          schema = call('get_metadata', { object: object }, false)
          if config_fields['object'] == 'user'
            schema.only('businessPhones', 'displayName', 'givenName', 'id', 'jobTitle',
                        'mail', 'mobilePhone', 'officeLocation', 'preferredLanguage',
                        'surname', 'userPrincipalName')
          else
            schema
          end
        end
      end
    },
    get_object_input: {
      fields:  lambda do |_connection, config_fields|
        call('get_input', object: config_fields['object'])
      end
    },
    get_trigger_input: {
      fields:  lambda do |_connection, _config_fields|
        call('get_input', object: 'folder')
      end
    },
    create_object_input: {
      fields: lambda do |connection, config_fields|
        if config_fields['object'] == 'row'
          call('worksheet_output', config_fields)
        else
          schema = call('get_input', object: config_fields['object']).concat(
            call('get_metadata', { object: config_fields['object'] }, true).
              required('name')
          )
          if config_fields['object'] == 'list'
            schema = schema.ignored('name', 'list_id').required('displayName')
          elsif config_fields['object'] == 'listItem'
            schema = schema.ignored('item_id')
            if config_fields['site_id'].present? && config_fields['list_id'].present?
              schema.concat(
                [
                  { name: 'fields', type: 'object',
                    properties: call(:get_line_item_schema, connection,
                                     site_id: config_fields['site_id'],
                                     list_id: config_fields['list_id']) }
                ]
              )
            end
          elsif config_fields['object'] == 'user'
            schema = schema.only('accountEnabled', 'city', 'country', 'department',
                                 'displayName', 'givenName', 'jobTitle', 'mailNickname',
                                 'passwordPolicies', 'passwordProfile', 'officeLocation',
                                 'postalCode', 'preferredLanguage', 'state', 'streetAddress',
                                 'surname', 'mobilePhone', 'usageLocation', 'userPrincipalName')&.
                     required('displayName', 'userPrincipalName', 'mailNickname', 'passwordProfile')
          end
          schema
        end
      end
    },
    update_object_input: {
      fields: lambda do |connection, config_fields|
        schema = call('get_input', object: config_fields['object'])
        unless config_fields['object'] == 'licenseDetails'
          schema.concat(
            call('get_metadata', { object: config_fields['object'] }, true)
          )
        end
        if config_fields['object'] == 'list'
          schema = schema.ignored('name', 'list_id')
        elsif config_fields['object'] == 'listItem'
          schema = schema.ignored('item_id').concat(
            [
              { name: 'fields', type: 'object', sticky: true,
                properties: call(:get_line_item_schema, connection,
                                 { site_id: config_fields['site_id'],
                                   list_id: config_fields['list_id'] }) }
            ]
          )
        elsif config_fields['object'] == 'user'
          schema = schema.only('user_id', 'accountEnabled', 'city', 'country', 'department',
                               'displayName', 'givenName', 'jobTitle', 'mailNickname',
                               'passwordPolicies', 'passwordProfile', 'officeLocation',
                               'postalCode', 'preferredLanguage', 'state', 'streetAddress',
                               'surname', 'mobilePhone', 'usageLocation', 'userPrincipalName')
        end
        schema
      end
    },
    update_object_output: {
      fields: lambda do |_connection, config_fields|
        if config_fields['object'] == 'user'
          [{ name: 'status' }]
        else
          object = if config_fields['object'] == 'license'
                     'licenseDetails'
                   else
                     config_fields['object']
                   end
          schema = call('get_metadata', { object: object }, false)
          schema
        end
      end
    },
    get_upload_input: {
      fields: lambda do |_connection, _config_fields|
        call('get_input', object: 'folder').concat(
          [
            { name: 'filename', optional: false,
              hint: 'Filename should include the file extension. e.g. my_report.jpg' },
            { name: 'file_content', optional: false },
            { name: 'mimeType', control_type: 'text', optional: true, sticky: true,
              hint: 'MIME type of the object being uploaded. Eg: <b>image/jpeg</b>.'\
                    'Microsoft Graph will automatically detect an appropriate '\
                    'value from uploaded content if no value is provided.' }
          ]
        )
      end
    },
    get_upload_output: {
      fields: lambda do |_connection, _config_fields|
        call('get_metadata', { object: 'driveItem' }, false)
      end
    },
    get_download_output: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'file_contents' }
        ]
      end
    },
    get_download_input: {
      fields: lambda do |_connection, _config_fields|
        call('get_input', object: 'download_file')
      end
    },
    custom_action_input: {
      fields: lambda do |_connection, config_fields|
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

        [
          {
            name: 'path',
            hint: 'Base URI is <b>' \
            'https://graph.microsoft.com' \
            '</b> - path will be appended to this URI. Use absolute URI to '\
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
                if input_schema.present?
                  { name: 'data', type: 'object', properties: data_props }
                end
              ].compact
            }
          else
            {
              name: 'input',
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
                      label: 'Request body parameters',
                      sticky: input_schema.blank?,
                      extends_schema: true,
                      schema_neutral: true,
                      add_field_label: 'Add request body parameter',
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
                            render_input: 'boolean_conversion',
                            parse_output: 'boolean_conversion',
                            control_type: 'checkbox',
                            type: 'boolean'
                          }]
                        end
                    },
                    if input_schema.present?
                      { name: 'data', type: 'object', properties: data_props }
                    end
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
            if output_schema.dig(0, 'type') == 'array'
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
    },
    search_object_input: {
      fields: lambda do |_connection, config_fields|
        schema = if config_fields['object'] == 'license'
                   [
                     { name: 'id', label: 'User ID', sticky: true,
                       hint: "Retrive all user's available licenses" }
                   ]
                 else
                   call(:get_input, object: config_fields['object'])&.
                     only('drive_id', 'site_id', 'list_id')&.concat(
                     if config_fields['object'] == 'driveItem'
                       [
                         {
                           name: 'q', label: 'Query', sticky: true,
                           hint: 'Query values may be matched across several fields including ' \
                                 'filename, metadata, and file content.'
                         }
                       ]
                     else
                       []
                     end
                   )
                 end

        config_fields['object'] == 'list' ? schema.ignored('list_id') : schema
      end
    }
  },

  actions: {
    get_record: {
      description: lambda do |_connection, input|
        "Get <span class='provider'>#{input['object']&.downcase || 'record'}" \
        "</span> using <span class='provider'>Microsoft Graph</span> "
      end,

      help: 'Retrieve the details of any record, e.g. Drive item, via its ' \
      "object ID. Click <a href='https://docs.microsoft.com/en-us/graph/api/" \
      "overview?view=graph-rest-1.0' target='_blank'>here</a> for more details.",

      config_fields: [
        { name: 'object', pick_list: 'get_object', control_type: 'select', optional: false }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions[:get_object_input]
      end,

      execute: lambda do |connection, input|
        if input['object'] == 'workbook_sheets'
          {
            worksheets:
              get("/v1.0/me/drive/items/#{input['id']}/workbook/worksheets")&.[]('value')
          }
        else
          get(call(:get_url, connection, input))&.
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['get_object_output']
      end,

      sample_output: lambda do |connection, input|
        get(call(:get_sample_url, connection, input)).dig('value', 0)
      end
    },

    download_file: {
      description: "Download <span class='provider'>file</span> using " \
        "<span class='provider'>Microsoft Graph</span> ",

      help: 'Downloads the contents of a file via its object ID. ' \
      "Click <a href='https://docs.microsoft.com/en-us/graph/api/" \
      "overview?view=graph-rest-1.0' target='_blank'>here</a> for more details.",

      input_fields: lambda do |object_definitions|
        object_definitions[:get_download_input]
      end,

      execute: lambda do |connection, input|
        url = call(:get_url,
                   connection,
                   { 'object' => 'download_file',
                     'drive_id' => input['drive_id'],
                     'item_id' => input['item_id'] })

        { file_contents: get(url).response_format_raw }
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['get_download_output']
      end,

      sample_output: lambda do |_connection, _input|
        { file_contents: '<file-contents>' }
      end
    },

    upload_file: {
      description: "Upload <span class='provider'>file</span> using " \
        "<span class='provider'>Microsoft Graph</span> ",

      help: 'Upload a file by providing the file contents. '\
        'If a file with the same name already exists in the folder, action ' \
        "will update the file. Click <a href='https://docs.microsoft.com/en-us/graph/api/" \
        "overview?view=graph-rest-1.0' target='_blank'>here</a> for more details.",

      input_fields: lambda do |object_definitions|
        object_definitions[:get_upload_input]
      end,

      execute: lambda do |connection, input|
        url = call(:get_url, connection,
                   { 'object' => 'upload_file',
                     'drive_id' => input['drive_id'],
                     'folder_id' => input['folder_id'],
                     'filename' => input['filename'] })

        put(url, input['file_content']).headers('Content-Type': input['mimeType'])&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['get_upload_output']
      end,

      sample_output: lambda do |connection, input|
        get(call(:get_url, connection, input)).dig('value', 0)
      end
    },

    create_record: {
      description: lambda do |_connection, input|
        if input['object'] == 'Row'
          "Add <span class='provider'>row</span> in " \
            "<span class='provider'>Microsoft Office 365</span> Excel sheet"
        else
          "Create <span class='provider'>#{input['object']&.downcase || 'record'}</span> using " \
            "<span class='provider'>Microsoft Graph</span> "
        end
      end,

      help: 'Create a record, e.g. Drive item. ' \
      "Click <a href='https://docs.microsoft.com/en-us/graph/api/" \
      "overview?view=graph-rest-1.0' target='_blank'>here</a> for more details.",

      config_fields: [
        { name: 'object', pick_list: 'create_object',
          control_type: 'select', optional: false },
        {
          ngIf: 'input.object == "row"',
          name: 'file',
          control_type: 'select',
          pick_list: 'xlsxfiles',
          optional: false,
          hint: 'Select Workbook File'
        },
        {
          ngIf: 'input.object == "row"',
          name: 'worksheet',
          control_type: 'select',
          pick_list: 'worksheets',
          pick_list_params: { workbook_id: 'file' },
          optional: false,
          hint: 'Select Sheet'
        }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['create_object_input'].ignored('id')
      end,

      execute: lambda do |connection, input|
        if input['object'] == 'row'
          address =
            get("/v1.0/me/drive/items/#{input['file']}/workbook/worksheets(" \
              "'#{input['worksheet']}')/usedRange?$select=address,rowCount")
          file = input['file']
          worksheet = input['worksheet']
          input.delete('file')
          input.delete('worksheet')
          rownum = address['rowCount'].to_i + 1
          range = address['address'].split('!').last
          first = range.split(':').first.scan(/([A-Z]+)/).first.first
          last = range.split(':').last.scan(/([A-Z]+)/).first.first
          rangeaddress = first + rownum + ':' + last + rownum

          post("/v1.0/me/drive/items/#{file}/workbook/worksheets/#{worksheet}/" \
            "range(address='#{rangeaddress}')/insert").
            headers(shift: 'Right').
            payload(values: [input.values])

          response = patch("/v1.0/me/drive/items/#{file}/workbook/worksheets/" \
            "#{worksheet}/range(address='#{rangeaddress}')").
                     payload(values: [input.except('object').values])
          response['odata_id'] = response.delete('@odata.id')
          response
        else
          payload = input.except('drive_id', 'folder_id', 'object')
          payload['folder'] = {} if input['object'] == 'folder'
          post(call(:get_url, connection, input), payload)&.
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['get_object_output']
      end,

      sample_output: lambda do |connection, input|
        get(call(:get_sample_url, connection, input)).dig('value', 0)
      end
    },

    update_record: {
      description: lambda do |_connection, input|
        if input['object'].present? && input['object'] == 'licenseDetails'
          "Update <span class='provider'>license details</span> for a user using" \
          "<span class='provider'>Microsoft Graph</span> "
        else
          "Update <span class='provider'>#{input['object']&.downcase || 'record'}</span> using " \
          "<span class='provider'>Microsoft Graph</span> "
        end
      end,

      help: 'Update a record, e.g. list via its object ID. ' \
      "Click <a href='https://docs.microsoft.com/en-us/graph/api/" \
      "overview?view=graph-rest-1.0' target='_blank'>here</a> for more details.",

      config_fields: [
        { name: 'object', pick_list: 'update_object', control_type: 'select', optional: false }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions['update_object_input'].required('id')
      end,

      execute: lambda do |connection, input|
        if input['object'] == 'licenseDetails'
          input['addLicenses'] = input['addLicenses']&.map do |license|
            license['disabledPlans'] = license['disabledPlans']&.pluck('id')
            license
          end || []
          input['removeLicenses'] = input['removeLicenses']&.split("\n") || []

          post(call(:get_update_url, connection, input), input.except('user_id'))&.
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        else
          payload = input.except('drive_id', 'folder_id', 'user_id', 'object')
          patch(call(:get_update_url, connection, input), payload)&.
            after_response do |code, body, _headers|
              code == 204 ? { status: 'Success' } : body
            end&.after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['update_object_output']
      end,

      sample_output: lambda do |connection, input|
        get(call(:get_sample_url, connection, input)).dig('value', 0)
      end
    },

    search_record: {
      description: lambda do |_connection, input|
        "Search <span class='provider'>#{input['object']&.downcase || 'record'}</span> using " \
          "<span class='provider'>Microsoft Graph</span> "
      end,

      help: 'Returns all records that matches your search criteria. ' \
      "Click <a href='https://docs.microsoft.com/en-us/graph/api/" \
      "overview?view=graph-rest-1.0' target='_blank'>here</a> for more details.",

      config_fields: [
        { name: 'object', pick_list: 'search_object', control_type: 'select', optional: false }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions[:search_object_input]
      end,

      execute: lambda do |connection, input|
        get(call(:get_search_url, connection, input))&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'value', type: 'array', of: 'object',
            properties: object_definitions['get_object_output'] }
        ]
      end,

      sample_output: lambda do |connection, input|
        get(call(:get_sample_url, connection, input))
      end
    },

    delete_record: {
      description: lambda do |_connection, input|
        "Delete <span class='provider'>#{input['object']&.downcase || 'record'}</span> using " \
          "<span class='provider'>Microsoft Graph</span> "
      end,

      help: 'Delete record via its object ID. First select the object, then specify ' \
      'the object ID of the record to delete. ' \
      "Click <a href='https://docs.microsoft.com/en-us/graph/api/" \
      "overview?view=graph-rest-1.0' target='_blank'>here</a> for more details.",

      config_fields: [
        { name: 'object', pick_list: 'delete_object', control_type: 'select', optional: false }
      ],

      input_fields: lambda do |object_definitions|
        object_definitions[:get_object_input]
      end,

      execute: lambda do |connection, input|
        delete(call(:get_url, connection, input))&.
          after_error_response do |_code, body, _header, _message|
            error(body)
          end&.after_response do |_code, _body, _headers|
            { status: 'success' }
          end
      end,

      output_fields: lambda do |_object_definitions|
        [{ name: 'status' }]
      end,

      sample_output: lambda do |_connection, _input|
        { status: 'success' }
      end
    },

    custom_action: {
      subtitle: 'Build your own Microsoft Graph action with a HTTP request',

      description: lambda do |object_value, _object_label|
        "<span class='provider'> \
      #{object_value[:action_name] || 'Custom action'}</span> using \
      <span class='provider'>Microsoft Graph</span>"
      end,

      help: {
        body: "Build your own Microsoft Graph action with a HTTP request. \
      The request will be authorized with your Microsoft Graph connection.",
        learn_more_url: 'https://docs.microsoft.com/en-us/graph/api/overview?view=graph-rest-1.0',
        learn_more_text: 'Microsoft Graph API documentation'
      },

      config_fields: [
        {
          name: 'action_name',
          hint: "Give this action you're building a descriptive name, e.g. \
        create record, get record",
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
          pick_list: %w[get post put patch options delete].map { |verb| [verb.upcase, verb] }
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
        request_headers = input['request_headers']
        &.each_with_object({}) do |item, hash|
          hash[item['key']] = item['value']
        end || {}
        request = case verb
                  when 'get'
                    get(path, data)
                  when 'post'
                    post(path)
                  when 'put'
                    put(path)
                  when 'patch'
                    patch(path)
                  when 'options'
                    options(path, data)
                  when 'delete'
                    delete(path, data)
                  end.headers(request_headers)
        request = case input['request_type']
                  when 'url_encoded_form'
                    request.payload(data).request_format_www_form_urlencoded
                  when 'multipart'
                    data = data.each_with_object({}) do |(key, val), hash|
                      hash[key] = if val.is_a?(Hash)
                                    [val[:file_content], val[:content_type],
                                     val[:original_filename]]
                                  else
                                    val
                                  end
                    end
                    request.payload(data).request_format_multipart_form
                  when 'raw'
                    request.request_body(data)
                  else
                    request.payload(data)
                  end
        response = if input['response_type'] == 'raw'
                     request.response_format_raw
                   else
                     request
                   end.after_error_response(/.*/) do |code, body, headers, message|
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

  triggers: {
    new_row_in_sheet: {
      description: "New <span class='provider'>row</span> in <span class=" \
        "'provider'>Microsoft Office 365</span> Excel sheet",

      config_fields: [
        {
          name: 'file',
          control_type: 'select',
          pick_list: 'xlsxfiles',
          optional: false,
          hint: 'Select Workbook File'
        },
        {
          name: 'worksheet',
          control_type: 'select',
          pick_list: 'worksheets',
          pick_list_params: { workbook_id: 'file' },
          optional: false,
          hint: 'Select Sheet'
        }
      ],

      poll: lambda do |_connection, input, last_record_id|
        from_record_id = last_record_id || 2
        address =
          get("/v1.0/me/drive/items/#{input['file']}/workbook/worksheets" \
            "('#{input['worksheet']}')/usedRange?$select=address,formulas," \
            'rowCount')
        output_fields = address['formulas']&.first&.
                          map do |f|
                            f
                          end

        startrow = from_record_id.to_i
        range = address['address'].split('!').last
        endrow = range.split(':').last.scan(/\d+/).first

        firstcolumn = range.split(':').first.scan(/([A-Z]+)/).first.first
        lastcolumn = range.split(':').last.scan(/([A-Z]+)/).first.first
        rangeaddress = firstcolumn + startrow + ':' + lastcolumn + endrow
        endrowint = endrow.to_i
        output = []
        if startrow <= endrowint
          result =
            get("/v1.0/me/drive/items/#{input['file']}/workbook/worksheets" \
              "('#{input['worksheet']}')/range(address='#{rangeaddress}')")
          data = result['values']
          i = 0
          data.map do |item|
            record = { uniqueid: startrow + i }
            (0..(output_fields.length - 1)).each do |index|
              record[output_fields[index]] = item[index]
            end
            output << record
            i = i + 1
          end
          # set last record id
          newaddress = result['address']
          newrange = newaddress.split('!').last if newaddress.present?
          last_record_id = newrange.split(':').last.scan(/\d+/).first if newrange.present?
        end

        # trigger output
        output.to_a

        {
          events: output,
          next_poll:
            output.size > 0 ? last_record_id.to_i + 1 : last_record_id.to_i,
          can_poll_more:  output.size != 0
        }
      end,

      dedup: lambda do |output|
        output['uniqueid']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['worksheet_output']
      end
    }
  },

  pick_lists: {
    get_licenses: lambda do |connection|
      get("#{connection['api_version']}/me/licenseDetails")&.[]('value')&.
        map { |license| [license['skuPartNumber'], license['skuId']] }
    end,

    get_drives: lambda do |connection|
      get("#{connection['api_version']}/me/drives")&.[]('value')&.
        map { |drive| [drive['name'], drive['id']] }
    end,

    get_object: lambda do |_connection|
      %w[driveItem list listItem site user workbook_sheets worksheet_content].
        map { |data| [data.labelize, data] }
    end,

    create_object: lambda do |_connection|
      %w[list listItem folder user row].map { |data| [data.labelize, data] }
    end,

    update_object: lambda do |_connection|
      %w[list listItem folder licenseDetails user].map do |data|
        data == 'folder' ? ['Drive item', data] : [data.labelize, data]
      end
    end,

    search_object: lambda do |_connection|
      %w[driveItem list listItem license user].map { |data| [data.labelize, data] }
    end,

    delete_object: lambda do |_connection|
      %w[driveItem listItem].map { |data| [data.labelize, data] }
    end,

    folders: lambda do |connection, **args|
      parent_folder_id = args[:__parent_id]
      if parent_folder_id.blank?
        [['Root', 'root', nil, true]]
      else
        get("#{connection['api_version']}/drives/#{args[:drive_id]}/items/"\
            "#{args[:__parent_id]}/children")&.[]('value')&.
        map do |item|
          [item['name'], item['id'], nil, true] if item['folder'].present?
        end&.compact
      end
    end,

    sites: lambda do |connection, **args|
      parent_folder_id = args[:__parent_id]
      url = if parent_folder_id.blank?
              "#{connection['api_version']}/sites?search="
            else
              "#{connection['api_version']}/sites/#{parent_folder_id}/sites"
            end
      get(url)&.[]('value')&.map do |item|
        [item['displayName'], item['id'], nil, true]
      end&.compact
    end,

    xlsxfiles: lambda do |_connection|
      get("/v1.0/me/drive/root/search(q='.xlsx')?select=name,id")['value'].
        pluck('name', 'id')
    end,

    worksheets: lambda do |_, workbook_id:|
      get("/v1.0/me/drive/items/#{workbook_id}/workbook/worksheets")['value'].
        map { |sheet| [sheet['name'], sheet['name']] }
    end
  }
}
