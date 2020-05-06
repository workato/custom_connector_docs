{
  title: 'Outreach',

  connection: {
    fields: [
      { name: 'client_id', optional: false, hint: 'To setup an Outreach OAuth application, ' \
        'please contact <b>platform@outreach.io</b> for assistance. For more details, ' \
        "please visit <a href='https://api.outreach.io/api/v2/docs#authentication' " \
        "target='_blank'>Outreach API documentation<a>" },
      { name: 'client_secret', control_type: 'password', optional: false,
        hint: 'To setup an Outreach OAuth application, ' \
        'please contact <b>platform@outreach.io</b> for assistance. For more details, ' \
        "please visit <a href='https://api.outreach.io/api/v2/docs#authentication' " \
        "target='_blank'>Outreach API documentation<a>" }
    ],

    authorization: {
      type: 'oauth2',

      authorization_url: lambda do |connection|
        scopes = ['profile', 'email', 'accounts.all', 'callDispositions.all', 'callPurposes.all',
                  'calls.all', 'events.all', 'mailings.all', 'mailboxes.all', 'personas.all',
                  'prospects.all', 'sequenceStates.all', 'sequenceTemplates.all',
                  'sequenceSteps.all', 'sequences.all', 'templates.read', 'stages.all',
                  'taskPriorities.all', 'users.all', 'tags.all', 'tasks.all',
                  'webhooks.all', 'profiles.all', 'roles.all', 'teams.all'].join(' ')
        params = {
          response_type: 'code',
          scope: scopes,
          client_id: connection['client_id']
        }.to_param
        "https://api.outreach.io/oauth/authorize?#{params}"
      end,

      acquire: lambda do |connection, code|
        response = post('https://api.outreach.io/oauth/token').
                   payload(
                     client_id: connection['client_id'],
                     client_secret: connection['client_secret'],
                     redirect_uri: 'https://www.workato.com/oauth/callback',
                     grant_type: 'authorization_code',
                     code: code
                   ).request_format_www_form_urlencoded
        [
          {
            access_token: response['access_token'],
            refresh_token: response['refresh_token']
          },
          nil,
          nil
        ]
      end,

      refresh_on: [401, 403],

      refresh: lambda do |connection, refresh_token|
        post('https://api.outreach.io/oauth/token').payload(
          grant_type: 'refresh_token',
          client_id: connection['client_id'],
          client_secret: connection['client_secret'],
          refresh_token: refresh_token,
          redirect_uri: 'https://www.workato.com/oauth/callback'
        ).request_format_www_form_urlencoded
      end,

      apply: lambda do |_connection, access_token|
        headers(
          'Authorization': "Bearer #{access_token}",
          'Accept': 'application/vnd.api+json',
          'Content-Type': 'application/vnd.api+json'
        )
      end
    },

    base_uri: lambda do |_connection|
      'https://api.outreach.io'
    end
  },

  test: lambda do |_connection|
    get('/api/v2')
  end,

  methods: {
    account_schema: lambda do |input|
      [
        if input['fields']&.include?('name') || input['fields'] == 'all'
          { name: 'name', label: 'Company name',
            optional: (input['action_type'] != 'create'), sticky: true }
        end,
        if input['fields']&.include?('naturalName') || input['fields'] == 'all'
          { name: 'naturalName', sticky: true,
            hint: 'The natural name of the company (e.g. <b>Acme</b>)' }
        end,

        if input['fields']&.include?('domain') || input['fields'] == 'all'
          { name: 'domain', sticky: true,
            hint: 'The company\'s website domain (e.g. <b>www.acme.com</b>)' }
        end,
        if input['fields']&.include?('description') || input['fields'] == 'all'
          { name: 'description', sticky: true }
        end,
        if input['fields']&.include?('companyType') || input['fields'] == 'all'
          { name: 'companyType', sticky: true, hint: 'A description of the ' \
            'company\'s type (e.g. <b>Public Company</b>)' }
        end,
        if input['fields']&.include?('numberOfEmployees') || input['fields'] == 'all'
          { name: 'numberOfEmployees', sticky: true, type: 'integer', control_type: 'integer',
            render_input: 'integer_conversion', parse_output: 'integer_conversion' }
        end,
        if input['fields']&.include?('industry') || input['fields'] == 'all'
          { name: 'industry', sticky: true, hint: 'e.g. Manufacturing' }
        end,
        if input['fields']&.include?('foundedAt') || input['fields'] == 'all'
          { name: 'foundedAt', label: 'Date founded', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('locality') || input['fields'] == 'all'
          { name: 'locality', hint: 'The company\'s primary geographic ' \
            'region (e.g. <b/>Eastern USA</b>).	' }
        end,
        if input['fields']&.include?('websiteUrl') || input['fields'] == 'all'
          { name: 'websiteUrl', label: 'Website URL', type: 'string', control_type: 'url',
            hint: 'The company\'s website URL (e.g. <b>https://www.acme.com/contact</b>).' }
        end,
        if input['fields']&.include?('linkedInUrl') || input['fields'] == 'all'
          { name: 'linkedInUrl', label: 'LinkedIn URL', type: 'string', control_type: 'url' }
        end,
        if input['fields']&.include?('linkedInEmployees') || input['fields'] == 'all'
          { name: 'linkedInEmployees', label: 'LinkedIn employees', type: 'integer',
            control_type: 'integer', render_input: 'integer_conversion',
            parse_output: 'integer_conversion', hint: 'The number of employees listed on the ' \
            'company\'s LinkedIn URL.' }
        end,
        if input['fields']&.include?('followers') || input['fields'] == 'all'
          { name: 'followers', type: 'integer', control_type: 'integer',
            render_input: 'integer_conversion', parse_output: 'integer_conversion',
            hint: 'The number of followers the company has listed on social media.' }
        end,
        if (input['fields']&.include?('tags') || input['fields'] == 'all') &&
            input['action_type'] == 'output'
          { name: 'tags', type: 'array', of: 'string' }
        else
          { name: 'tags', sticky: true, hint: 'Multiple tags can be ' \
          'applied by providing values separated by comma' }
        end,
        if input['fields']&.include?('customId') || input['fields'] == 'all'
          { name: 'customId', sticky: true, hint: 'A custom ID for the account, ' \
            'often referencing an ID in an external system.' }
        end,
        if input['fields']&.include?('engagementScore') || input['fields'] == 'all'
          { name: 'engagementScore', type: 'number', control_type: 'number',
            hint: 'A custom score given to measure the quality of the account.' }
        end,
        if (input['fields']&.include?('externalSource') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'externalSource', hint: 'The source of the resource\'s ' \
            'creation (e.g. <b>outreach-api<b>)' }
        end,
        if (input['fields']&.include?('createdAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'createdAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('touchedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'touchedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('updatedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'updatedAt', label: 'Date updated', type: 'date_time',
            control_type: 'date_time', render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('named') || input['fields'] == 'all'
          { name: 'named', type: 'boolean', control_type: 'checkbox',
            hint: 'Determines whether this is a <b>named</b> account or not.',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Named',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              type: 'string',
              name: 'named',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('custom1') || input['fields'] == 'all'
          { name: 'custom1' }
        end,
        if input['fields']&.include?('custom2') || input['fields'] == 'all'
          { name: 'custom2' }
        end,
        if input['fields']&.include?('custom3') || input['fields'] == 'all'
          { name: 'custom3' }
        end,
        if input['fields']&.include?('custom4') || input['fields'] == 'all'
          { name: 'custom4' }
        end,
        if input['fields']&.include?('custom5') || input['fields'] == 'all'
          { name: 'custom5' }
        end,
        if input['fields']&.include?('custom6') || input['fields'] == 'all'
          { name: 'custom6' }
        end,
        if input['fields']&.include?('custom7') || input['fields'] == 'all'
          { name: 'custom7' }
        end,
        if input['fields']&.include?('custom8') || input['fields'] == 'all'
          { name: 'custom8' }
        end,
        if input['fields']&.include?('custom9') || input['fields'] == 'all'
          { name: 'custom9' }
        end,
        if input['fields']&.include?('custom10') || input['fields'] == 'all'
          { name: 'custom10' }
        end,
        if input['fields']&.include?('custom11') || input['fields'] == 'all'
          { name: 'custom11' }
        end,
        if input['fields']&.include?('custom12') || input['fields'] == 'all'
          { name: 'custom12' }
        end,
        if input['fields']&.include?('custom13') || input['fields'] == 'all'
          { name: 'custom13' }
        end,
        if input['fields']&.include?('custom14') || input['fields'] == 'all'
          { name: 'custom14' }
        end,
        if input['fields']&.include?('custom15') || input['fields'] == 'all'
          { name: 'custom15' }
        end,
        if input['fields']&.include?('custom16') || input['fields'] == 'all'
          { name: 'custom16' }
        end,
        if input['fields']&.include?('custom17') || input['fields'] == 'all'
          { name: 'custom17' }
        end,
        if input['fields']&.include?('custom18') || input['fields'] == 'all'
          { name: 'custom18' }
        end,
        if input['fields']&.include?('custom19') || input['fields'] == 'all'
          { name: 'custom19' }
        end,
        if input['fields']&.include?('custom20') || input['fields'] == 'all'
          { name: 'custom20' }
        end,
        if input['fields']&.include?('custom21') || input['fields'] == 'all'
          { name: 'custom21' }
        end,
        if input['fields']&.include?('custom22') || input['fields'] == 'all'
          { name: 'custom22' }
        end,
        if input['fields']&.include?('custom23') || input['fields'] == 'all'
          { name: 'custom23' }
        end,
        if input['fields']&.include?('custom24') || input['fields'] == 'all'
          { name: 'custom24' }
        end,
        if input['fields']&.include?('custom25') || input['fields'] == 'all'
          { name: 'custom25' }
        end,
        if input['fields']&.include?('custom26') || input['fields'] == 'all'
          { name: 'custom26' }
        end,
        if input['fields']&.include?('custom27') || input['fields'] == 'all'
          { name: 'custom27' }
        end,
        if input['fields']&.include?('custom28') || input['fields'] == 'all'
          { name: 'custom28' }
        end,
        if input['fields']&.include?('custom29') || input['fields'] == 'all'
          { name: 'custom29' }
        end,
        if input['fields']&.include?('custom30') || input['fields'] == 'all'
          { name: 'custom30' }
        end,
        if input['fields']&.include?('custom31') || input['fields'] == 'all'
          { name: 'custom31' }
        end,
        if input['fields']&.include?('custom32') || input['fields'] == 'all'
          { name: 'custom32' }
        end,
        if input['fields']&.include?('custom33') || input['fields'] == 'all'
          { name: 'custom33' }
        end,
        if input['fields']&.include?('custom34') || input['fields'] == 'all'
          { name: 'custom34' }
        end,
        if input['fields']&.include?('custom35') || input['fields'] == 'all'
          { name: 'custom35' }
        end,
        if input['fields']&.include?('custom36') || input['fields'] == 'all'
          { name: 'custom36' }
        end,
        if input['fields']&.include?('custom37') || input['fields'] == 'all'
          { name: 'custom37' }
        end,
        if input['fields']&.include?('custom38') || input['fields'] == 'all'
          { name: 'custom38' }
        end,
        if input['fields']&.include?('custom39') || input['fields'] == 'all'
          { name: 'custom39' }
        end,
        if input['fields']&.include?('custom40') || input['fields'] == 'all'
          { name: 'custom40' }
        end,
        if input['fields']&.include?('custom41') || input['fields'] == 'all'
          { name: 'custom41' }
        end,
        if input['fields']&.include?('custom42') || input['fields'] == 'all'
          { name: 'custom42' }
        end,
        if input['fields']&.include?('custom43') || input['fields'] == 'all'
          { name: 'custom43' }
        end,
        if input['fields']&.include?('custom44') || input['fields'] == 'all'
          { name: 'custom44' }
        end,
        if input['fields']&.include?('custom45') || input['fields'] == 'all'
          { name: 'custom45' }
        end,
        if input['fields']&.include?('custom46') || input['fields'] == 'all'
          { name: 'custom46' }
        end,
        if input['fields']&.include?('custom47') || input['fields'] == 'all'
          { name: 'custom47' }
        end,
        if input['fields']&.include?('custom48') || input['fields'] == 'all'
          { name: 'custom48' }
        end,
        if input['fields']&.include?('custom49') || input['fields'] == 'all'
          { name: 'custom49' }
        end,
        if input['fields']&.include?('custom50') || input['fields'] == 'all'
          { name: 'custom50' }
        end,
        if input['fields']&.include?('custom51') || input['fields'] == 'all'
          { name: 'custom51' }
        end,
        if input['fields']&.include?('custom52') || input['fields'] == 'all'
          { name: 'custom52' }
        end,
        if input['fields']&.include?('custom53') || input['fields'] == 'all'
          { name: 'custom53' }
        end,
        if input['fields']&.include?('custom54') || input['fields'] == 'all'
          { name: 'custom54' }
        end,
        if input['fields']&.include?('custom55') || input['fields'] == 'all'
          { name: 'custom55' }
        end,
        if input['fields']&.include?('custom56') || input['fields'] == 'all'
          { name: 'custom56' }
        end,
        if input['fields']&.include?('custom57') || input['fields'] == 'all'
          { name: 'custom57' }
        end,
        if input['fields']&.include?('custom58') || input['fields'] == 'all'
          { name: 'custom58' }
        end,
        if input['fields']&.include?('custom59') || input['fields'] == 'all'
          { name: 'custom59' }
        end,
        if input['fields']&.include?('custom60') || input['fields'] == 'all'
          { name: 'custom60' }
        end,
        if input['fields']&.include?('custom61') || input['fields'] == 'all'
          { name: 'custom61' }
        end,
        if input['fields']&.include?('custom62') || input['fields'] == 'all'
          { name: 'custom62' }
        end,
        if input['fields']&.include?('custom63') || input['fields'] == 'all'
          { name: 'custom63' }
        end,
        if input['fields']&.include?('custom64') || input['fields'] == 'all'
          { name: 'custom64' }
        end,
        if input['fields']&.include?('custom65') || input['fields'] == 'all'
          { name: 'custom65' }
        end,
        if input['fields']&.include?('custom66') || input['fields'] == 'all'
          { name: 'custom66' }
        end,
        if input['fields']&.include?('custom67') || input['fields'] == 'all'
          { name: 'custom67' }
        end,
        if input['fields']&.include?('custom68') || input['fields'] == 'all'
          { name: 'custom68' }
        end,
        if input['fields']&.include?('custom69') || input['fields'] == 'all'
          { name: 'custom69' }
        end,
        if input['fields']&.include?('custom70') || input['fields'] == 'all'
          { name: 'custom70' }
        end,
        if input['fields']&.include?('custom71') || input['fields'] == 'all'
          { name: 'custom71' }
        end,
        if input['fields']&.include?('custom72') || input['fields'] == 'all'
          { name: 'custom72' }
        end,
        if input['fields']&.include?('custom73') || input['fields'] == 'all'
          { name: 'custom73' }
        end,
        if input['fields']&.include?('custom74') || input['fields'] == 'all'
          { name: 'custom74' }
        end,
        if input['fields']&.include?('custom75') || input['fields'] == 'all'
          { name: 'custom75' }
        end,
        if input['fields']&.include?('custom76') || input['fields'] == 'all'
          { name: 'custom76' }
        end,
        if input['fields']&.include?('custom77') || input['fields'] == 'all'
          { name: 'custom77' }
        end,
        if input['fields']&.include?('custom78') || input['fields'] == 'all'
          { name: 'custom78' }
        end,
        if input['fields']&.include?('custom79') || input['fields'] == 'all'
          { name: 'custom79' }
        end,
        if input['fields']&.include?('custom80') || input['fields'] == 'all'
          { name: 'custom80' }
        end,
        if input['fields']&.include?('custom81') || input['fields'] == 'all'
          { name: 'custom81' }
        end,
        if input['fields']&.include?('custom82') || input['fields'] == 'all'
          { name: 'custom82' }
        end,
        if input['fields']&.include?('custom83') || input['fields'] == 'all'
          { name: 'custom83' }
        end,
        if input['fields']&.include?('custom84') || input['fields'] == 'all'
          { name: 'custom84' }
        end,
        if input['fields']&.include?('custom85') || input['fields'] == 'all'
          { name: 'custom85' }
        end,
        if input['fields']&.include?('custom86') || input['fields'] == 'all'
          { name: 'custom86' }
        end,
        if input['fields']&.include?('custom87') || input['fields'] == 'all'
          { name: 'custom87' }
        end,
        if input['fields']&.include?('custom88') || input['fields'] == 'all'
          { name: 'custom88' }
        end,
        if input['fields']&.include?('custom89') || input['fields'] == 'all'
          { name: 'custom89' }
        end,
        if input['fields']&.include?('custom90') || input['fields'] == 'all'
          { name: 'custom90' }
        end,
        if input['fields']&.include?('custom91') || input['fields'] == 'all'
          { name: 'custom91' }
        end,
        if input['fields']&.include?('custom92') || input['fields'] == 'all'
          { name: 'custom92' }
        end,
        if input['fields']&.include?('custom93') || input['fields'] == 'all'
          { name: 'custom93' }
        end,
        if input['fields']&.include?('custom94') || input['fields'] == 'all'
          { name: 'custom94' }
        end,
        if input['fields']&.include?('custom95') || input['fields'] == 'all'
          { name: 'custom95' }
        end,
        if input['fields']&.include?('custom96') || input['fields'] == 'all'
          { name: 'custom96' }
        end,
        if input['fields']&.include?('custom97') || input['fields'] == 'all'
          { name: 'custom97' }
        end,
        if input['fields']&.include?('custom98') || input['fields'] == 'all'
          { name: 'custom98' }
        end,
        if input['fields']&.include?('custom99') || input['fields'] == 'all'
          { name: 'custom99' }
        end,
        if input['fields']&.include?('custom100') || input['fields'] == 'all'
          { name: 'custom100' }
        end
      ]&.compact
    end,
    account_relationship: lambda do |_action_type|
      [
        { name: 'creator', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id' }
          ] }
        ] },
        { name: 'owner', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type', default: 'user', hint: 'E.g. user' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'prospects', type: 'object', properties: [
          { name: 'links', type: 'object', properties: [
            { name: 'related', type: 'string', control_type: 'url' }
          ] }
        ] },
        { name: 'tasks', type: 'object', properties: [
          { name: 'links', type: 'object', properties: [
            { name: 'related', type: 'string', control_type: 'url' }
          ] }
        ] },
        { name: 'updater', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id' }
          ] }
        ] }
      ]
    end,
    account_search_schema: lambda do
      [
        { name: 'name', label: 'Company name', sticky: true },
        { name: 'domain', sticky: true,
          hint: 'The company\'s website domain (e.g. <b>www.acme.com</b>)' },
        { name: 'customId', hint: 'A custom ID for the account, often referencing' \
          ' an ID in an external system.' },
        { name: 'engagementScore', type: 'number', control_type: 'number', sticky: true,
          hint: 'A custom score given to measure the quality of the account.' },
        { name: 'touchedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date last touched', type: 'date_time',
            control_type: 'date_time', render_input: 'date_conversion', parse_output: 'date_conversion',
            hint: 'The date and time the account was last touched.' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to'
            } }
        ] },
        { name: 'createdAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date created', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'updatedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date updated', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'named', type: 'boolean', control_type: 'checkbox',
          hint: 'Determines whether this is a <b>named</b> account or not.',
          toggle_hint: 'Select from option list',
          toggle_field: {
            label: 'Named',
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            type: 'string',
            name: 'named',
            hint: 'Allowed values are: <b>true</b>, <b>false</b>'
          } }
      ]
    end,
    call_schema: lambda do |input|
      [
        if input['fields']&.include?('answeredAt') || input['fields'] == 'all'
          { name: 'answeredAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('completedAt') || input['fields'] == 'all'
          { name: 'completedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('createdAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'createdAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('dialedAt') || input['fields'] == 'all'
          { name: 'dialedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('direction') || input['fields'] == 'all'
          { name: 'direction', control_type: 'select', sticky: true,
            pick_list: 'call_direction', hint: "The call direction from the user's point of view",
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'direction',
              label: 'Direction',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inbound</b>, <b>outbound</b>'
            } }
        end,
        if input['fields']&.include?('externalVendor') || input['fields'] == 'all'
          { name: 'externalVendor' }
        end,
        if input['fields']&.include?('from') || input['fields'] == 'all'
          { name: 'from', control_type: 'phone' }
        end,
        if input['fields']&.include?('note') || input['fields'] == 'all'
          { name: 'note' }
        end,
        if input['fields']&.include?('outcome') || input['fields'] == 'all'
          { name: 'outcome', control_type: 'select',
            pick_list: 'outcome_type', hint: 'The call’s outcome',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'outcome',
              label: 'Outcome',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Enter custom value',
              hint: 'Allowed values are: <b>Answered</b>, <b>Not Answered</b>'
            } }
        end,
        if input['fields']&.include?('recordingUrl') || input['fields'] == 'all'
          { name: 'recordingUrl', label: 'Recording URL',
            type: 'string', control_type: 'url' }
        end,
        if input['fields']&.include?('returnedAt') || input['fields'] == 'all'
          { name: 'returnedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('sequenceAction') || input['fields'] == 'all'
          { name: 'sequenceAction', control_type: 'select',
            pick_list: 'sequence_actions', hint: 'The call’s outcome',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'sequenceAction',
              label: 'Sequence action',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Enter custom value',
              hint: 'Allowed values are <b>Advance, Finish, Finish - No Reply, or Finish - Replied</b>'
            } }
        end,
        if input['fields']&.include?('shouldRecordCall') || input['fields'] == 'all'
          { name: 'shouldRecordCall', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'shouldRecordCall',
              label: 'Should record call',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('state') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'state' }
        end,
        if (input['fields']&.include?('stateChangedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'stateChangedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('tags') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'tags', type: 'array', of: 'string' }
        else
          { name: 'tags', hint: 'Multiple tags can be applied by providing values separated by comma' }
        end,
        if input['fields']&.include?('to') || input['fields'] == 'all'
          { name: 'to', hint: 'The phone number that the call was placed to.' }
        end,
        if input['fields']&.include?('uid') || input['fields'] == 'all'
          { name: 'uid', label: 'Outreach voice trace ID' }
        end,
        if (input['fields']&.include?('updatedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('userCallType') || input['fields'] == 'all'
          { name: 'userCallType', control_type: 'select', sticky: true,
            pick_list: 'call_types', toggle_hint: 'Select from list',
            toggle_field: {
              name: 'userCallType',
              label: 'User call type',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Enter custom value',
              hint: 'Allowed values are: <b>bridge</b>, <b>voip</b>'
            } }
        end,
        if (input['fields']&.include?('voicemailRecordingUrl') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'voicemailRecordingUrl', label: 'Voicemail recording URL',
            type: 'string', control_type: 'url' }
        end
      ].compact
    end,
    call_relationship: lambda do |_action_type|
      [
        { name: 'callDisposition', label: 'Call disposition',
          type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] },
        { name: 'callPurpose', label: 'Call purpose',
          type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] },
        { name: 'prospect', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'sequence', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'sequenceState', label: 'Sequence state',
          type: 'object', properties: [
            { name: 'data' }
          ] },
        { name: 'sequenceStep', label: 'Sequence step', type: 'object',
          properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] },
        { name: 'task', type: 'object', properties: [
          { name: 'data' }
        ] },
        { name: 'user', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] }
      ].compact
    end,
    call_search_schema: lambda do
      [
        { name: 'prospect', type: 'object', properties: [
          { name: 'id', label: 'Prospect ID', sticky: true,
            hint: 'Multiple IDs can be applied by providing values separated by comma' }
        ] },
        { name: 'from', control_type: 'phone', sticky: true },
        { name: 'to', control_type: 'phone', sticky: true,
          hint: 'The phone number that the call was placed to.' },
        { name: 'outcome', control_type: 'select', sticky: true,
          pick_list: 'outcome_type', hint: 'The call’s outcome',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'outcome',
            label: 'Outcome',
            type: 'string',
            control_type: 'text',
            optional: true,
            toggle_hint: 'Enter custom value',
            hint: 'Allowed values are: <b>Answered</b>, <b>Not Answered</b>'
          } },
        { name: 'recordingUrl', label: 'Recording URL', control_type: 'url' },
        { name: 'state', hint: 'The call’s current state.' },
        { name: 'userCallType', control_type: 'select', sticky: true,
          pick_list: 'call_types', toggle_hint: 'Select from list',
          toggle_field: {
            name: 'userCallType',
            label: 'User call type',
            type: 'string',
            control_type: 'text',
            optional: true,
            toggle_hint: 'Enter custom value',
            hint: 'Allowed values are: <b>bridge</b>, <b>voip</b>'
          } },
        { name: 'createdAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date created', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'updatedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date updated', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] }
      ]
    end,
    event_schema: lambda do |input|
      [
        if input['fields']&.include?('body') || input['fields'] == 'all'
          { name: 'body' }
        end,
        if (input['fields']&.include?('createdAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'createdAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('eventAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'eventAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('externalUrl') || input['fields'] == 'all'
          { name: 'externalUrl', label: 'External URL', control_type: 'url' }
        end,
        if (input['fields']&.include?('mailingId') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'mailingId', type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('name') || input['fields'] == 'all'
          { name: 'name', label: 'Event name' }
        end,
        if (input['fields']&.include?('requestCity') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'requestCity' }
        end,
        if (input['fields']&.include?('requestDevice') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'requestDevice' }
        end,
        if (input['fields']&.include?('requestHost') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'requestHost' }
        end,
        if (input['fields']&.include?('requestProxied') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'requestProxied', type: 'boolean', control_type: 'checkbox' }
        end,
        if (input['fields']&.include?('requestRegion') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'requestRegion' }
        end
      ]&.compact
    end,
    event_relationship: lambda do |_action_type|
      [
        { name: 'mailing', type: 'object', properties: [
          { name: 'data',  type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'user', type: 'object', properties: [
          { name: 'data', type: 'object',  properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'prospect', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] }
      ].compact
    end,
    event_search_schema: lambda do
      [
        { name: 'name', label: 'Event name', sticky: true },
        { name: 'prospect', type: 'object', properties: [
          { name: 'id', label: 'Prospect ID', sticky: true,
            hint: 'Multiple IDs can be applied by providing values separated by comma' }
        ] },
        { name: 'mailingId', type: 'integer', control_type: 'integer', sticky: true },
        { name: 'createdAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date created', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'eventAt', type: 'object', properties: [
          { name: 'date_value', label: 'Event date', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] }

      ]
    end,
    mailing_schema: lambda do |input|
      [
        if input['fields']&.include?('bodyHtml') || input['fields'] == 'all'
          { name: 'bodyHtml', label: 'Body HTML' }
        end,
        if (input['fields']&.include?('bodyText') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'bodyText', label: 'Body text', type: 'string' }
        end,
        if (input['fields']&.include?('bouncedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'bouncedAt', label: 'Bounced at', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('clickCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'clickCount', label: 'Click count', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('clickedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'clickedAt', label: 'Clicked at', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('createdAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'createdAt', label: 'Created at', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('deliveredAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'deliveredAt', label: 'Delivered at', type: 'date_time',
            control_type: 'date_time', render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('errorBacktrace') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'errorBacktrace' }
        end,
        if (input['fields']&.include?('errorReason') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'errorReason' }
        end,
        if input['fields']&.include?('followUpTaskScheduledAt') ||
           input['fields'] == 'all'
          { name: 'followUpTaskScheduledAt', label: 'Follow up task scheduled at',
            type: 'date_time', control_type: 'date_time', render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('followUpTaskType') ||
           input['fields'] == 'all'
          { name: 'followUpTaskType', label: 'Follow up task type' }
        end,
        if (input['fields']&.include?('mailboxAddress') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'mailboxAddress' }
        end,
        if (input['fields']&.include?('mailingType') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'mailingType' }
        end,
        if (input['fields']&.include?('markedAsSpamAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'markedAsSpamAt', label: 'Marked as spam at', type: 'date_time',
            control_type: 'date_time', render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('messageId') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'messageId', label: 'Message ID', type: 'string' }
        end,
        if (input['fields']&.include?('notifyThreadCondition') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'notifyThreadCondition', label: 'Notify thread condition' }
        end,
        if (input['fields']&.include?('notifyThreadScheduledAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'notifyThreadScheduledAt', label: 'Notify thread scheduled at',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('notifyThreadStatus') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'notifyThreadStatus', label: 'Notify thread status' }
        end,
        if (input['fields']&.include?('openCount') ||
            input['fields'] == 'all') &&  input['action_type'] == 'output'
          { name: 'openCount', label: 'Open count', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('openedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'openedAt', label: 'Opened at', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('overrideSafetySettings') ||
            input['fields'] == 'all') &&  input['action_type'] == 'output'
          { name: 'overrideSafetySettings',
            label: 'Override safety settings',
            type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'overrideSafetySettings',
              label: 'Override safety settings',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('repliedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'repliedAt', label: 'Replied at', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('retryAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'retryAt', label: 'Retry at', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('retryCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'retryCount', label: 'Retry count', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('retryInterval') ||
            input['fields'] == 'all') &&  input['action_type'] == 'output'
          { name: 'retryInterval' }
        end,
        if input['fields']&.include?('scheduledAt') || input['fields'] == 'all'
          { name: 'scheduledAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('state') || input['fields'] == 'all'
          { name: 'state', type: 'string', control_type: 'select',
            pick_list: 'mailing_states', hint: 'The current state of the mailing',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'state',
              label: 'State',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>bounced</b>, <b>delivered</b>, <b>delivering</b>,' \
              '<b>drafted</b>, <b>failed</b>, <b>opened</b>, <b>placeholder</b>, <b>queued</b>,
              <b>replied</b>, <b>scheduled</b>'
            } }
        end,
        if (input['fields']&.include?('stateChangedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'stateChangedAt', label: 'State changed at', type: 'date_time',
            control_type: 'date_time', render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('subject') || input['fields'] == 'all'
          { name: 'subject' }
        end,
        if input['fields']&.include?('trackLinks') || input['fields'] == 'all'
          { name: 'trackLinks', type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'trackLinks',
              label: 'Track links',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('trackOpens') || input['fields'] == 'all'
          { name: 'trackOpens', type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'trackOpens',
              label: 'Track opens',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('unsubscribedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'unsubscribedAt', label: 'Unsubscribed at', type: 'date_time',
            control_type: 'date_time', render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('updatedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'updatedAt', label: 'Updated at', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end
      ]&.compact
    end,
    mailing_relationship: lambda do |action_type|
      [
        if action_type == 'output'
          { name: 'calendar', type: 'object', properties: [
            { name: 'data' }
          ] }
        end,
        { name: 'mailbox', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        if action_type == 'output'
          { name: 'opportunity', type: 'object', properties: [
            { name: 'data' }
          ] }
        end,
        { name: 'prospect', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        if action_type == 'output'
          { name: 'sequence', type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] }
        end,
        if action_type == 'output'
          { name: 'sequenceState', type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] }
        end,
        if action_type == 'output'
          { name: 'sequenceStep', type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] }
        end,
        if action_type == 'output'
          { name: 'task', type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] }
        end,
        if action_type == 'output'
          { name: 'tasks', type: 'object', properties: [
            { name: 'data', type: 'array', of: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] },
            { name: 'links', type: 'object', properties: [
              { name: 'related' }
            ] },
            { name: 'meta', type: 'object', properties: [
              { name: 'count', type: 'integer', control_type: 'integer' }
            ] }
          ] }
        end,
        { name: 'template', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] }
      ].compact
    end,
    mailing_search_schema: lambda do
      [
        { name: 'prospect', type: 'object', properties: [
          { name: 'id', label: 'Prospect ID', sticky: true,
            hint: 'Multiple IDs can be applied by providing values separated by comma' }
        ] },
        { name: 'messageId', hint: 'The MIME content Message-ID of the delivered message.' },
        { name: 'state', type: 'string', control_type: 'select', sticky: true,
          pick_list: 'mailing_states', hint: 'The current state of the mailing',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'state',
            label: 'State',
            type: 'string',
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: <b>bounced</b>, <b>delivered</b>, <b>delivering</b>,' \
            '<b>drafted</b>, <b>failed</b>, <b>opened</b>, <b>placeholder</b>, <b>queued</b>,
            <b>replied</b>, <b>scheduled</b>'
          } },
        { name: 'mailingType', type: 'string', control_type: 'select', sticky: true,
          pick_list: 'mailing_types', hint: 'A description of the type of the emailing',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'mailingType',
            label: 'Mailing type',
            type: 'string',
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: <b>sequence</b>, <b>single</b>, <b>campaign</b>'
          } },
        { name: 'notifyThreadStatus', label: 'Notify thread status',
          type: 'string', control_type: 'select',
          pick_list: 'thread_statuses', hint: 'The status of the bump',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'notifyThreadStatus',
            label: 'Notify thread status',
            type: 'string',
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are <b>pending</b>, <b>sent</b>, <b>skipped</b>'
          } },
        { name: 'bouncedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date bounced', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion', hint: 'The date and time the email was bounced.' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'clickedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'The most recent date and time a link was clicked (if the message is tracking links).' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'deliveredAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date delivered', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'notifyThreadScheduledAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date delivered', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: "The date and time of when this mailing should be bumped to the top of the user's inbox." },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'openedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date opened', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'repliedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date replied', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'retryAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'The date and time the email will rety to send.' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'scheduledAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date scheduled', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'The date and time the email is scheduled to send' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'stateChangedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'The date and time the state last changed.' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'unsubscribedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date unsubscribed', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'createdAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date created', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'updatedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date updated', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] }

      ]
    end,
    mailbox_schema: lambda do |input|
      [
        if input['fields']&.include?('authId') || input['fields'] == 'all'
          { name: 'authId', label: 'Auth ID', type: 'integer', control_type: 'integer',
            hint: 'The auth id associated with the mailbox.' }
        end,
        if (input['fields']&.include?('createdAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'createdAt', control_type: 'date_time', type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('editable') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'editable', label: 'Editable', type: 'boolean' }
        end,
        if input['fields']&.include?('email') || input['fields'] == 'all'
          { name: 'email', control_type: 'email', type: 'string' }
        end,
        if input['fields']&.include?('emailProvider') || input['fields'] == 'all'
          { name: 'emailProvider', control_type: 'text', type: 'string' }
        end,
        if input['fields']&.include?('emailSignature') || input['fields'] == 'all'
          { name: 'emailSignature', control_type: 'text', type: 'string' }
        end,
        if input['fields']&.include?('ewsEndpoint') || input['fields'] == 'all'
          { name: 'ewsEndpoint', label: 'EWS endpoint' }
        end,
        if input['fields']&.include?('ewsSslVerifyMode') || input['fields'] == 'all'
          { name: 'ewsSslVerifyMode', label: 'EWS SSL verify mode' }
        end,
        if input['fields']&.include?('exchangeVersion') || input['fields'] == 'all'
          { name: 'exchangeVersion', label: 'Exchange version' }
        end,
        if input['fields']&.include?('imapHost') || input['fields'] == 'all'
          { name: 'imapHost', label: 'IMAP host' }
        end,
        if input['fields']&.include?('imapPort') || input['fields'] == 'all'
          { name: 'imapPort', label: 'IAMP port' }
        end,
        if input['fields']&.include?('imapSsl') || input['fields'] == 'all'
          { name: 'imapSsl', label: 'IAMP SSL' }
        end,
        if input['fields']&.include?('maxEmailsPerDay') || input['fields'] == 'all'
          { name: 'maxEmailsPerDay', label: 'Max emails per day',
            type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('maxMailingsPerDay') || input['fields'] == 'all'
          { name: 'maxMailingsPerDay', label: 'Max mailings per day',
            control_type: 'integer', type: 'integer' }
        end,
        if input['fields']&.include?('maxMailingsPerWeek') || input['fields'] == 'all'
          { name: 'maxMailingsPerWeek', label: 'Max mailings per week',
            type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('optOutMessage') || input['fields'] == 'all'
          { name: 'optOutMessage', label: 'Opt out message' }
        end,
        if input['fields']&.include?('optOutSignature') || input['fields'] == 'all'
          { name: 'optOutSignature', label: 'Opt out signature' }
        end,
        if input['fields']&.include?('ownerName') || input['fields'] == 'all'
          { name: 'ownerName', label: 'Owner name' }
        end,
        if input['fields']&.include?('prospectEmailExclusions') || input['fields'] == 'all'
          { name: 'prospectEmailExclusions', label: 'Prospect email exclusions' }
        end,
        if (input['fields']&.include?('providerId') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'providerId', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('providerType') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'providerType' }
        end,
        if input['fields']&.include?('sendDisabled') || input['fields'] == 'all'
          { name: 'sendDisabled', type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'sendDisabled',
              label: 'Send disabled',
              control_type: 'text',
              type: 'string',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('sendErroredAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'sendErroredAt' }
        end,
        if input['fields']&.include?('sendMaxRetries') || input['fields'] == 'all'
          { name: 'sendMaxRetries', label: 'Send max retries',
            type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('sendMethod') || input['fields'] == 'all'
          { name: 'sendMethod', control_type: 'email', type: 'string' }
        end,
        if input['fields']&.include?('sendPeriod') || input['fields'] == 'all'
          { name: 'sendPeriod', type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('sendRequiresSync') || input['fields'] == 'all'
          { name: 'sendRequiresSync', label: 'Send requires sync',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'sendRequiresSync',
              label: 'Send requires sync',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('sendSuccessAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'sendSuccessAt', type: 'date_time', control_type: 'date_time' }
        end,
        if input['fields']&.include?('sendThreshold') || input['fields'] == 'all'
          { name: 'sendThreshold', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('sendgridWebhookUrl') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'sendgridWebhookUrl', label: 'Sendgrid webhook URL',
            type: 'string', control_type: 'url' }
        end,
        if input['fields']&.include?('smtpHost') || input['fields'] == 'all'
          { name: 'smtpHost', label: 'SMTP host' }
        end,
        if input['fields']&.include?('smtpPort') || input['fields'] == 'all'
          { name: 'smtpPort', label: 'SMTP port' }
        end,
        if input['fields']&.include?('smtpSsl') || input['fields'] == 'all'
          { name: 'smtpSsl', label: 'SMTP SSL' }
        end,
        if input['fields']&.include?('smtpUsername') || input['fields'] == 'all'
          { name: 'smtpUsername', label: 'SMTP username' }
        end,
        if input['fields']&.include?('syncActiveFrequency') || input['fields'] == 'all'
          { name: 'syncActiveFrequency', label: 'Sync active frequency',
            type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('syncDisabled') || input['fields'] == 'all'
          { name: 'syncDisabled', label: 'Sync disabled',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'syncDisabled',
              label: 'Sync disabled',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('syncErroredAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'syncErroredAt' }
        end,
        if (input['fields']&.include?('syncFinishedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'syncFinishedAt' }
        end,
        if input['fields']&.include?('syncMethod') || input['fields'] == 'all'
          { name: 'syncMethod' }
        end,
        if input['fields']&.include?('syncOutreachFolder') || input['fields'] == 'all'
          { name: 'syncOutreachFolder', label: 'Sync outreach folder' }
        end,
        if input['fields']&.include?('syncPassiveFrequency') || input['fields'] == 'all'
          { name: 'syncPassiveFrequency', label: 'Sync passive frequency',
            type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('syncSuccessAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'syncSuccessAt' }
        end,
        if (input['fields']&.include?('updatedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'updatedAt', type: 'date_time', control_type: 'date_time' }
        end,
        if input['fields']&.include?('userId') || input['fields'] == 'all'
          { name: 'userId', type: 'integer', control_type: 'integer',
            hint: 'The ID of the user associated with this mailbox' }
        end,
        if input['fields']&.include?('username') || input['fields'] == 'all'
          { name: 'username', hint: 'The username of the email account.' }
        end
      ]&.compact
    end,
    mailbox_relationship: lambda do |action_type|
      [
        if action_type == 'output'
          { name: 'creator', type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer' }
            ] }
          ] }
        end,
        if action_type == 'output'
          { name: 'mailAliases', type: 'object', properties: [
            { name: 'links', type: 'object', properties: [
              { name: 'related' }
            ] }
          ] }
        end,
        if action_type == 'output'
          { name: 'mailings', type: 'object', properties: [
            { name: 'links', type: 'object', properties: [
              { name: 'related' }
            ] }
          ] }
        end,
        if action_type == 'output'
          { name: 'updater', type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] }
        end,
        { name: 'user', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] }
      ].compact
    end,
    mailbox_search_schema: lambda do
      [
        { name: 'email', control_type: 'email', optional: true, sticky: true },
        { name: 'userId', type: 'integer', control_type: 'integer', sticky: true,
          hint: 'The ID of the user associated with this mailbox.' },
        { name: 'createdAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date created', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'updatedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date updated', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] }
      ]
    end,
    profile_schema: lambda do |input|
      [
        if input['fields']&.include?('name') || input['fields'] == 'all'
          { name: 'name', hint: 'The name of the profile (e.g. <b>Admin</b>).' }
        end,
        if (input['fields']&.include?('isAdmin') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'isAdmin', type: 'boolean', control_type: 'boolean',
            label: 'Provides admin access' }
        end,
        if (input['fields']&.include?('createdAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'createdAt', label: 'Created at', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('updatedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'updatedAt', label: 'Updated at', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end
      ]&.compact
    end,
    profile_search_schema: lambda do
      [{ name: 'name', label: 'Profile name', sticky: true }]
    end,
    prospect_schema: lambda do |input|
      [
        if input['fields']&.include?('firstName') || input['fields'] == 'all'
          { name: 'firstName', sticky: true, optional: (input['action_type'] != 'create') }
        end,
        if input['fields']&.include?('lastName') || input['fields'] == 'all'
          { name: 'lastName', sticky: true, optional: (input['action_type'] != 'create') }
        end,
        if input['fields']&.include?('middleName') || input['fields'] == 'all'
          { name: 'middleName' }
        end,
        if (input['fields']&.include?('name') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'name' }
        end,
        if input['fields']&.include?('nickname') || input['fields'] == 'all'
          { name: 'nickname' }
        end,
        if input['fields']&.include?('gender') || input['fields'] == 'all'
          { name: 'gender' }
        end,
        if (input['fields']&.include?('emailOptedOut') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'emailOptedOut', type: 'boolean', label: 'Email opted out' }
        end,
        if (input['fields']&.include?('emails') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'emails', type: 'array', of: 'string' }
        else
          { name: 'emails', labels: 'Email address', optional: (input['action_type'] != 'create'),
            hint: 'Multiple emails can be applied by providing values separated by comma' }
        end,
        if input['fields']&.include?('emailsOptStatus') || input['fields'] == 'all'
          { name: 'emailsOptStatus', label: 'Emails opt status', type: 'string',
            control_type: 'select', pick_list: 'opt_statuses',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'emailsOptStatus',
              label: 'Emails opt status',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>opted_in</b>, <b>opted_out</b>, <b>null</b>'
            } }
        end,
        if (input['fields']&.include?('emailsOptedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'emailsOptedAt', label: 'Emails opted at', type: 'date', control_type: 'date',
            render_input: 'date_conversion', parse_output: 'date_conversion' }
        end,
        if (input['fields']&.include?('homePhones') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'homePhones', type: 'array', of: 'string' }
        else
          { name: 'homePhones', hint: 'Multiple phone numbers' \
          ' can be applied by providing values separated by comma' }
        end,
        if (input['fields']&.include?('mobilePhones') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'mobilePhones', type: 'array', of: 'string' }
        else
          { name: 'mobilePhones', hint: 'Multiple phone numbers can' \
          ' be applied by providing values separated by comma' }
        end,
        if (input['fields']&.include?('otherPhones') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'otherPhones', type: 'array', of: 'string' }
        else
          { name: 'otherPhones', hint: 'Multiple phone numbers can' \
            'be applied by providing values separated by comma' }
        end,
        if (input['fields']&.include?('voipPhones') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'voipPhones', label: 'VoIP phones', type: 'array', of: 'string' }
        else
          { name: 'voipPhones', label: 'VoIP phones', hint: 'Multiple phone numbers can ' \
          'be applied by providing values separated by comma' }
        end,
        if (input['fields']&.include?('workPhones') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'workPhones', type: 'array', of: 'string' }
        else
          { name: 'workPhones', sticky: true, hint: 'Multiple phone ' \
          'numbers can be applied by providing values separated by comma' }
        end,
        if input['fields']&.include?('title') || input['fields'] == 'all'
          { name: 'title', label: 'Job title', sticky: true }
        end,
        if input['fields']&.include?('occupation') || input['fields'] == 'all'
          { name: 'occupation', sticky: true }
        end,
        if input['fields']&.include?('jobStartDate') || input['fields'] == 'all'
          { name: 'jobStartDate', label: 'Job start date', type: 'date', control_type: 'date',
            render_input: 'date_conversion', parse_output: 'date_conversion' }
        end,
        if input['fields']&.include?('specialties') || input['fields'] == 'all'
          { name: 'specialties', control_type: 'email', type: 'string' }
        end,
        if input['fields']&.include?('websiteUrl1') || input['fields'] == 'all'
          { name: 'websiteUrl1', label: 'Website URL 1', control_type: 'url' }
        end,
        if input['fields']&.include?('websiteUrl2') || input['fields'] == 'all'
          { name: 'websiteUrl2', label: 'Website URL 2', control_type: 'url' }
        end,
        if input['fields']&.include?('websiteUrl3') || input['fields'] == 'all'
          { name: 'websiteUrl3', label: 'Website URL 3', control_type: 'url' }
        end,
        if input['fields']&.include?('linkedInUrl') || input['fields'] == 'all'
          { name: 'linkedInUrl', label: 'LinkedIn URL', type: 'string', control_type: 'url' }
        end,
        if input['fields']&.include?('linkedInId') || input['fields'] == 'all'
          { name: 'linkedInId', label: 'LinkedIn ID' }
        end,
        if input['fields']&.include?('linkedInConnections') || input['fields'] == 'all'
          { name: 'linkedInConnections', label: 'LinkedIn connections',
            type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('linkedInSlug') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'linkedInSlug', label: 'LinkedIn slug' }
        end,
        if input['fields']&.include?('twitterUrl') || input['fields'] == 'all'
          { name: 'twitterUrl', label: 'Twitter URL', control_type: 'url' }
        end,
        if input['fields']&.include?('twitterUsername') || input['fields'] == 'all'
          { name: 'twitterUsername' }
        end,
        if input['fields']&.include?('githubUrl') || input['fields'] == 'all'
          { name: 'githubUrl', label: 'GitHub URL', control_type: 'url' }
        end,
        if input['fields']&.include?('githubUsername') || input['fields'] == 'all'
          { name: 'githubUsername', label: 'GitHub username' }
        end,
        if input['fields']&.include?('facebookUrl') || input['fields'] == 'all'
          { name: 'facebookUrl', label: 'Facebook URL', control_type: 'url' }
        end,
        if input['fields']&.include?('googlePlusUrl') || input['fields'] == 'all'
          { name: 'googlePlusUrl', label: 'Google+ URL', control_type: 'url' }
        end,
        if input['fields']&.include?('stackOverflowId') || input['fields'] == 'all'
          { name: 'stackOverflowId', label: 'Stack Overflow ID' }
        end,
        if input['fields']&.include?('stackOverflowUrl') || input['fields'] == 'all'
          { name: 'stackOverflowUrl', label: 'Stack Overflow URL', control_type: 'url' }
        end,
        if input['fields']&.include?('quoraUrl') || input['fields'] == 'all'
          { name: 'quoraUrl', label: 'Quora URL', control_type: 'url' }
        end,
        if input['fields']&.include?('angelListUrl') || input['fields'] == 'all'
          { name: 'angelListUrl', label: 'Angel list URL', control_type: 'url' }
        end,
        if input['fields']&.include?('school') || input['fields'] == 'all'
          { name: 'school' }
        end,
        if input['fields']&.include?('degree') || input['fields'] == 'all'
          { name: 'degree', hint: 'The degree(s) the prospect has received.' }
        end,
        if input['fields']&.include?('graduationDate') || input['fields'] == 'all'
          { name: 'graduationDate', type: 'date', control_type: 'date',
            render_input: 'date_conversion', parse_output: 'date_conversion' }
        end,
        if input['fields']&.include?('dateOfBirth') || input['fields'] == 'all'
          { name: 'dateOfBirth', label: 'Date of birth',
            type: 'date', control_type: 'date',
            render_input: 'date_conversion', parse_output: 'date_conversion' }
        end,
        if input['fields']&.include?('addressStreet') || input['fields'] == 'all'
          { name: 'addressStreet', label: 'Address street' }
        end,
        if input['fields']&.include?('addressStreet2') || input['fields'] == 'all'
          { name: 'addressStreet2', label: 'Address street 2' }
        end,
        if input['fields']&.include?('addressCity') || input['fields'] == 'all'
          { name: 'addressCity' }
        end,
        if input['fields']&.include?('addressState') || input['fields'] == 'all'
          { name: 'addressState' }
        end,
        if input['fields']&.include?('region') || input['fields'] == 'all'
          { name: 'region' }
        end,
        if input['fields']&.include?('addressZip') || input['fields'] == 'all'
          { name: 'addressZip' }
        end,
        if input['fields']&.include?('addressCountry') || input['fields'] == 'all'
          { name: 'addressCountry' }
        end,
        if input['fields']&.include?('timeZone') || input['fields'] == 'all'
          { name: 'timeZone' }
        end,
        if (input['fields']&.include?('timeZoneIana') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'timeZoneIana', label: 'IANA timezone' }
        end,
        if (input['fields']&.include?('timeZoneInferred') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'timeZoneInferred', label: 'Inferred timezone' }
        end,
        if input['fields']&.include?('personalNote1') || input['fields'] == 'all'
          { name: 'personalNote1', label: 'Personal note 1' }
        end,
        if input['fields']&.include?('personalNote2') || input['fields'] == 'all'
          { name: 'personalNote2', label: 'Personal note 2' }
        end,
        if input['fields']&.include?('preferredContact') || input['fields'] == 'all'
          { name: 'preferredContact', label: 'Preferred contact' }
        end,
        if input['fields']&.include?('campaignName') || input['fields'] == 'all'
          { name: 'campaignName', hint: 'The name of the campaign the ' \
            'prospect is associated with.' }
        end,
        if input['fields']&.include?('score') || input['fields'] == 'all'
          { name: 'score', type: 'number', control_type: 'number',
            hint: 'A custom score given to measure the quality of the lead.' }
        end,
        if input['fields']&.include?('source') || input['fields'] == 'all'
          { name: 'source' }
        end,
        if input['fields']&.include?('eventName') || input['fields'] == 'all'
          { name: 'eventName', hint: 'The name of the event the prospect was met at.' }
        end,
        if (input['fields']&.include?('tags') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'tags', type: 'array', of: 'string' }
        else
          { name: 'tags', hint: 'Multiple tags can be ' \
          'applied by providing values separated by comma' }
        end,
        if %w[create update].include?(input['action_type'])
          { name: 'owner', label: 'User', control_type: 'select',
            sticky: true, pick_list: 'users',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'owner',
              label: 'User ID',
              type: 'integer',
              control_type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              optional: true,
              toggle_hint: 'Enter user ID',
              hint: 'E.g. 1 or 2'
            } }
        end,
        if %w[create update].include?(input['action_type'])
          { name: 'account', control_type: 'select',
            sticky: true, pick_list: 'accounts',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'account',
              label: 'Account ID',
              type: 'integer',
              control_type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              optional: true,
              toggle_hint: 'Enter account ID',
              hint: 'E.g. 1 or 2'
            } }
        end,
        if input['fields']&.include?('addedAt') || input['fields'] == 'all'
          { name: 'addedAt', type: 'date_time', control_type: 'date_time',
            hint: 'The date and time the prospect was added to any system.	' }
        end,
        if input['fields']&.include?('availableAt') || input['fields'] == 'all'
          { name: 'availableAt', type: 'date_time', control_type: 'date_time',
            hint: 'The date and time the prospect is available to contact again.' }
        end,
        if input['fields']&.include?('custom1') || input['fields'] == 'all'
          { name: 'custom1' }
        end,
        if input['fields']&.include?('custom2') || input['fields'] == 'all'
          { name: 'custom2' }
        end,
        if input['fields']&.include?('custom3') || input['fields'] == 'all'
          { name: 'custom3' }
        end,
        if input['fields']&.include?('custom4') || input['fields'] == 'all'
          { name: 'custom4' }
        end,
        if input['fields']&.include?('custom5') || input['fields'] == 'all'
          { name: 'custom5' }
        end,
        if input['fields']&.include?('custom6') || input['fields'] == 'all'
          { name: 'custom6' }
        end,
        if input['fields']&.include?('custom7') || input['fields'] == 'all'
          { name: 'custom7' }
        end,
        if input['fields']&.include?('custom8') || input['fields'] == 'all'
          { name: 'custom8' }
        end,
        if input['fields']&.include?('custom9') || input['fields'] == 'all'
          { name: 'custom9' }
        end,
        if input['fields']&.include?('custom10') || input['fields'] == 'all'
          { name: 'custom10' }
        end,
        if input['fields']&.include?('custom11') || input['fields'] == 'all'
          { name: 'custom11' }
        end,
        if input['fields']&.include?('custom12') || input['fields'] == 'all'
          { name: 'custom12' }
        end,
        if input['fields']&.include?('custom13') || input['fields'] == 'all'
          { name: 'custom13' }
        end,
        if input['fields']&.include?('custom14') || input['fields'] == 'all'
          { name: 'custom14' }
        end,
        if input['fields']&.include?('custom15') || input['fields'] == 'all'
          { name: 'custom15' }
        end,
        if input['fields']&.include?('custom16') || input['fields'] == 'all'
          { name: 'custom16' }
        end,
        if input['fields']&.include?('custom17') || input['fields'] == 'all'
          { name: 'custom17' }
        end,
        if input['fields']&.include?('custom18') || input['fields'] == 'all'
          { name: 'custom18' }
        end,
        if input['fields']&.include?('custom19') || input['fields'] == 'all'
          { name: 'custom19' }
        end,
        if input['fields']&.include?('custom20') || input['fields'] == 'all'
          { name: 'custom20' }
        end,
        if input['fields']&.include?('custom21') || input['fields'] == 'all'
          { name: 'custom21' }
        end,
        if input['fields']&.include?('custom22') || input['fields'] == 'all'
          { name: 'custom22' }
        end,
        if input['fields']&.include?('custom23') || input['fields'] == 'all'
          { name: 'custom23' }
        end,
        if input['fields']&.include?('custom24') || input['fields'] == 'all'
          { name: 'custom24' }
        end,
        if input['fields']&.include?('custom25') || input['fields'] == 'all'
          { name: 'custom25' }
        end,
        if input['fields']&.include?('custom26') || input['fields'] == 'all'
          { name: 'custom26' }
        end,
        if input['fields']&.include?('custom27') || input['fields'] == 'all'
          { name: 'custom27' }
        end,
        if input['fields']&.include?('custom28') || input['fields'] == 'all'
          { name: 'custom28' }
        end,
        if input['fields']&.include?('custom29') || input['fields'] == 'all'
          { name: 'custom29' }
        end,
        if input['fields']&.include?('custom30') || input['fields'] == 'all'
          { name: 'custom30' }
        end,
        if input['fields']&.include?('custom30') || input['fields'] == 'all'
          { name: 'custom30' }
        end,
        if input['fields']&.include?('custom31') || input['fields'] == 'all'
          { name: 'custom31' }
        end,
        if input['fields']&.include?('custom32') || input['fields'] == 'all'
          { name: 'custom32' }
        end,
        if input['fields']&.include?('custom33') || input['fields'] == 'all'
          { name: 'custom33' }
        end,
        if input['fields']&.include?('custom34') || input['fields'] == 'all'
          { name: 'custom34' }
        end,
        if input['fields']&.include?('custom35') || input['fields'] == 'all'
          { name: 'custom35' }
        end,
        if input['fields']&.include?('custom36') || input['fields'] == 'all'
          { name: 'custom36' }
        end,
        if input['fields']&.include?('custom37') || input['fields'] == 'all'
          { name: 'custom37' }
        end,
        if input['fields']&.include?('custom38') || input['fields'] == 'all'
          { name: 'custom38' }
        end,
        if input['fields']&.include?('custom39') || input['fields'] == 'all'
          { name: 'custom39' }
        end,
        if input['fields']&.include?('custom40') || input['fields'] == 'all'
          { name: 'custom40' }
        end,
        if input['fields']&.include?('custom41') || input['fields'] == 'all'
          { name: 'custom41' }
        end,
        if input['fields']&.include?('custom42') || input['fields'] == 'all'
          { name: 'custom42' }
        end,
        if input['fields']&.include?('custom43') || input['fields'] == 'all'
          { name: 'custom43' }
        end,
        if input['fields']&.include?('custom44') || input['fields'] == 'all'
          { name: 'custom44' }
        end,
        if input['fields']&.include?('custom45') || input['fields'] == 'all'
          { name: 'custom45' }
        end,
        if input['fields']&.include?('custom46') || input['fields'] == 'all'
          { name: 'custom46' }
        end,
        if input['fields']&.include?('custom47') || input['fields'] == 'all'
          { name: 'custom47' }
        end,
        if input['fields']&.include?('custom48') || input['fields'] == 'all'
          { name: 'custom48' }
        end,
        if input['fields']&.include?('custom49') || input['fields'] == 'all'
          { name: 'custom49' }
        end,
        if input['fields']&.include?('custom50') || input['fields'] == 'all'
          { name: 'custom50' }
        end,
        if input['fields']&.include?('custom51') || input['fields'] == 'all'
          { name: 'custom51' }
        end,
        if input['fields']&.include?('custom52') || input['fields'] == 'all'
          { name: 'custom52' }
        end,
        if input['fields']&.include?('custom53') || input['fields'] == 'all'
          { name: 'custom53' }
        end,
        if input['fields']&.include?('custom54') || input['fields'] == 'all'
          { name: 'custom54' }
        end,
        if input['fields']&.include?('custom55') || input['fields'] == 'all'
          { name: 'custom55' }
        end,
        if input['fields']&.include?('custom56') || input['fields'] == 'all'
          { name: 'custom56' }
        end,
        if input['fields']&.include?('custom57') || input['fields'] == 'all'
          { name: 'custom57' }
        end,
        if input['fields']&.include?('custom58') || input['fields'] == 'all'
          { name: 'custom58' }
        end,
        if input['fields']&.include?('custom59') || input['fields'] == 'all'
          { name: 'custom59' }
        end,
        if input['fields']&.include?('custom60') || input['fields'] == 'all'
          { name: 'custom60' }
        end,
        if input['fields']&.include?('custom61') || input['fields'] == 'all'
          { name: 'custom61' }
        end,
        if input['fields']&.include?('custom62') || input['fields'] == 'all'
          { name: 'custom62' }
        end,
        if input['fields']&.include?('custom63') || input['fields'] == 'all'
          { name: 'custom63' }
        end,
        if input['fields']&.include?('custom64') || input['fields'] == 'all'
          { name: 'custom64' }
        end,
        if input['fields']&.include?('custom65') || input['fields'] == 'all'
          { name: 'custom65' }
        end,
        if input['fields']&.include?('custom66') || input['fields'] == 'all'
          { name: 'custom66' }
        end,
        if input['fields']&.include?('custom67') || input['fields'] == 'all'
          { name: 'custom67' }
        end,
        if input['fields']&.include?('custom68') || input['fields'] == 'all'
          { name: 'custom68' }
        end,
        if input['fields']&.include?('custom69') || input['fields'] == 'all'
          { name: 'custom69' }
        end,
        if input['fields']&.include?('custom70') || input['fields'] == 'all'
          { name: 'custom70' }
        end,
        if input['fields']&.include?('custom71') || input['fields'] == 'all'
          { name: 'custom71' }
        end,
        if input['fields']&.include?('custom72') || input['fields'] == 'all'
          { name: 'custom72' }
        end,
        if input['fields']&.include?('custom73') || input['fields'] == 'all'
          { name: 'custom73' }
        end,
        if input['fields']&.include?('custom74') || input['fields'] == 'all'
          { name: 'custom74' }
        end,
        if input['fields']&.include?('custom75') || input['fields'] == 'all'
          { name: 'custom75' }
        end,
        if input['fields']&.include?('custom76') || input['fields'] == 'all'
          { name: 'custom76' }
        end,
        if input['fields']&.include?('custom77') || input['fields'] == 'all'
          { name: 'custom77' }
        end,
        if input['fields']&.include?('custom78') || input['fields'] == 'all'
          { name: 'custom78' }
        end,
        if input['fields']&.include?('custom79') || input['fields'] == 'all'
          { name: 'custom79' }
        end,
        if input['fields']&.include?('custom80') || input['fields'] == 'all'
          { name: 'custom80' }
        end,
        if input['fields']&.include?('custom81') || input['fields'] == 'all'
          { name: 'custom81' }
        end,
        if input['fields']&.include?('custom82') || input['fields'] == 'all'
          { name: 'custom82' }
        end,
        if input['fields']&.include?('custom83') || input['fields'] == 'all'
          { name: 'custom83' }
        end,
        if input['fields']&.include?('custom84') || input['fields'] == 'all'
          { name: 'custom84' }
        end,
        if input['fields']&.include?('custom85') || input['fields'] == 'all'
          { name: 'custom85' }
        end,
        if input['fields']&.include?('custom86') || input['fields'] == 'all'
          { name: 'custom86' }
        end,
        if input['fields']&.include?('custom87') || input['fields'] == 'all'
          { name: 'custom87' }
        end,
        if input['fields']&.include?('custom88') || input['fields'] == 'all'
          { name: 'custom88' }
        end,
        if input['fields']&.include?('custom89') || input['fields'] == 'all'
          { name: 'custom89' }
        end,
        if input['fields']&.include?('custom90') || input['fields'] == 'all'
          { name: 'custom90' }
        end,
        if input['fields']&.include?('custom91') || input['fields'] == 'all'
          { name: 'custom91' }
        end,
        if input['fields']&.include?('custom92') || input['fields'] == 'all'
          { name: 'custom92' }
        end,
        if input['fields']&.include?('custom93') || input['fields'] == 'all'
          { name: 'custom93' }
        end,
        if input['fields']&.include?('custom94') || input['fields'] == 'all'
          { name: 'custom94' }
        end,
        if input['fields']&.include?('custom95') || input['fields'] == 'all'
          { name: 'custom95' }
        end,
        if input['fields']&.include?('custom96') || input['fields'] == 'all'
          { name: 'custom96' }
        end,
        if input['fields']&.include?('custom97') || input['fields'] == 'all'
          { name: 'custom97' }
        end,
        if input['fields']&.include?('custom98') || input['fields'] == 'all'
          { name: 'custom98' }
        end,
        if input['fields']&.include?('custom99') || input['fields'] == 'all'
          { name: 'custom99' }
        end,
        if input['fields']&.include?('custom100') || input['fields'] == 'all'
          { name: 'custom100' }
        end,
        if (input['fields']&.include?('engagedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'engagedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('engagedScore') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'engagedScore', type: 'number', control_type: 'number',
            hint: 'A number representing the quality of the lead, based on the number of the ' \
            'prospect’s opens, clicks and mailing replies' }
        end,
        if (input['fields']&.include?('clickCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'clickCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('externalSource') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'externalSource' }
        end,
        if (input['fields']&.include?('openCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'openCount', type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('optedOut') || input['fields'] == 'all'
          { name: 'optedOut', type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'optedOut',
              label: 'Opted out',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('optedOutAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'optedOutAt', label: 'Opted Out At', type: 'date_time',
            control_type: 'date_time', render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('smsOptStatus') || input['fields'] == 'all'
          { name: 'smsOptStatus', label: 'SMS opt status',
            type: 'string', control_type: 'select', pick_list: 'opt_statuses',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'smsOptStatus',
              label: 'SMS opt status',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>opted_in</b>, <b>opted_out</b>, <b>null</b>'
            } }
        end,
        if (input['fields']&.include?('smsOptedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'smsOptedAt', label: 'SMS opted at', type: 'date_time' }
        end,
        if (input['fields']&.include?('smsOptedOut') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'smsOptedOut', label: 'SMS opted out', type: 'boolean' }
        end,
        if (input['fields']&.include?('replyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'replyCount' }
        end,
        if input['fields']&.include?('externalId') || input['fields'] == 'all'
          { name: 'externalId', label: 'External ID' }
        end,
        if input['fields']&.include?('externalOwner') || input['fields'] == 'all'
          { name: 'externalOwner' }
        end,
        if (input['fields']&.include?('touchedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'touchedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('createdAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'createdAt', type: 'date_time', control_type: 'date_time' }
        end,
        if (input['fields']&.include?('updatedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end
      ]&.compact
    end,
    prospect_relationship: lambda do |_action_type|
      [
        { name: 'account', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id' }
          ] }
        ] },
        { name: 'activeSequenceStates', type: 'object', properties: [
          { name: 'data', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] },
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] },
          { name: 'meta', type: 'object', properties: [
            { name: 'count', type: 'integer' }
          ] }
        ] },
        { name: 'batches', type: 'object', properties: [
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] }
        ] },
        { name: 'calls', type: 'object', properties: [
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] }
        ] },
        { name: 'creator', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] }
        ] },
        { name: 'defaultPluginMapping', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] }
        ] },
        { name: 'emailAddresses', type: 'object', properties: [
          { name: 'data', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] },
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] },
          { name: 'meta', type: 'object', properties: [
            { name: 'count', type: 'integer' }
          ] }
        ] },
        { name: 'favorites', type: 'object', properties: [
          { name: 'data', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] },
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] },
          { name: 'meta', type: 'object', properties: [
            { name: 'count', type: 'integer' }
          ] }
        ] },
        { name: 'mailings', type: 'object', properties: [
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] }
        ] },
        { name: 'opportunities', type: 'object', properties: [
          { name: 'data', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] },
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] },
          { name: 'meta', type: 'object', properties: [
            { name: 'count', type: 'integer' }
          ] }
        ] },
        { name: 'owner', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type', type: 'integer' },
            { name: 'id' }
          ] }
        ] },
        { name: 'persona', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'phoneNumbers', type: 'object', properties: [
          { name: 'data', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] },
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] },
          { name: 'meta', type: 'object', properties: [
            { name: 'count', type: 'integer' }
          ] }
        ] },
        { name: 'sequenceStates', type: 'object', properties: [
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] }
        ] },
        { name: 'stage', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'tasks', type: 'object', properties: [
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] }
        ] },
        { name: 'updater', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] }
      ]
    end,
    prospect_search_schema: lambda do
      [
        { name: 'firstName', sticky: true },
        { name: 'lastName', sticky: true },
        { name: 'title', label: 'Job title', sticky: true },
        { name: 'emails', label: 'Email address', sticky: true,
          hint: 'Multiple emails can be applied by providing values separated by comma' },
        { name: 'engagedScore', type: 'number', control_type: 'number' },
        { name: 'externalSource' },
        { name: 'githubUsername', label: 'GitHub Username' },
        { name: 'stackOverflowId', label: 'Stack Overflow ID' },
        { name: 'linkedInId', label: 'LinkedIn ID' },
        { name: 'linkedInSlug', label: 'LinkedIn slug', sticky: true },
        { name: 'twitterUsername', sticky: true },
        { name: 'engagedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date last engaged', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'touchedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date last touched', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'createdAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date created', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b>',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'updatedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date updated', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] }
      ]
    end,
    sequence_schema: lambda do |input|
      [
        if (input['fields']&.include?('automationPercentage') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'automationPercentage', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('bounceCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'bounceCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('clickCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'clickCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('createdAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'createdAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('deliverCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'deliverCount', type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('name') || input['fields'] == 'all'
          { name: 'name', label: 'Sequence name', optional: (input['action_type'] != 'create') }
        end,
        if input['fields']&.include?('description') || input['fields'] == 'all'
          { name: 'description', sticky: true }
        end,
        if (input['fields']&.include?('tags') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'tags', type: 'array', of: 'string' }
        else
          { name: 'tags', hint: 'Multiple tags can be ' \
          'applied by providing values separated by comma' }
        end,
        if input['action_type'] == 'create'
          { name: 'owner', control_type: 'select',
            sticky: true, pick_list: 'users',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'owner',
              label: 'Owner user ID',
              type: 'integer',
              control_type: 'integer',
              optional: true,
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              toggle_hint: 'Enter user ID',
              hint: 'E.g. 1 or 2'
            } }
        end,
        if input['action_type'] == 'create'
          { name: 'ruleset',  label: 'Ruleset ID', sticky: true,
            type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('durationInDays') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'durationInDays', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('enabled') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'enabled', type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'enabled',
              label: 'Enabled',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('enabledAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'enabledAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('failureCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'failureCount', type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('finishOnReply') || input['fields'] == 'all'
          { name: 'finishOnReply', label: 'Finish on reply', type: 'boolean',
            control_type: 'checkbox', toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'finishOnReply',
              label: 'Finish on reply',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('lastUsedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'lastUsedAt', label: 'Last used at', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('locked') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'locked', type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'locked',
              label: 'Locked',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('lockedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'lockedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('maxActivations') || input['fields'] == 'all'
          { name: 'maxActivations', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('negativeReplyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'negativeReplyCount', label: 'Negative reply count',
            type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('neutralReplyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'neutralReplyCount', label: 'Neutral reply count',
            type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('numContactedProspects') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'numContactedProspects', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('numRepliedProspects') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'numRepliedProspects', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('sequenceStepCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'sequenceStepCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('openCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'openCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('optOutCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'optOutCount', label: 'Opt out count',
            type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('replyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'replyCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('positiveReplyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'positiveReplyCount', label: 'Positive reply count',
            type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('primaryReplyAction') || input['fields'] == 'all'
          { name: 'primaryReplyAction', type: 'string', control_type: 'select',
            pick_list: 'reply_actions', toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'primaryReplyAction',
              label: 'Primary reply action',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>finish</b>, <b>continue</b>, <b>pause</b>'
            } }
        end,
        if input['fields']&.include?('primaryReplyPauseDuration') || input['fields'] == 'all'
          { name: 'primaryReplyPauseDuration', type: 'integer', control_type: 'integer',
            hint: 'The duration in seconds to pause for after a reply from the primary prospect ' \
            'if the primaryReplyAction is <b>pause</b>' }
        end,
        if input['fields']&.include?('secondaryReplyAction') || input['fields'] == 'all'
          { name: 'secondaryReplyAction', type: 'string', control_type: 'select',
            pick_list: 'reply_actions', toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'secondaryReplyAction',
              label: 'Secondary reply action',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>finish</b>, <b>continue</b>, <b>pause<b>'
            } }
        end,
        if input['fields']&.include?('secondaryReplyPauseDuration') || input['fields'] == 'all'
          { name: 'secondaryReplyPauseDuration', type: 'integer', control_type: 'integer',
            hint: 'The duration in seconds to pause for after a reply from the primary prospect ' \
            'if the secondaryReplyAction is <b>pause</b>' }
        end,
        if (input['fields']&.include?('replyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'replyCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('scheduleCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'scheduleCount', type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('scheduleIntervalType') || input['fields'] == 'all'
          { name: 'scheduleIntervalType', type: 'string', control_type: 'select',
            pick_list: 'interval_types', toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'scheduleIntervalType',
              label: 'Schedule interval type',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>calendar</b>, <b>schedule</b>'
            } }
        end,
        if input['fields']&.include?('sequenceType') || input['fields'] == 'all'
          { name: 'sequenceType', type: 'string', control_type: 'select',
            optional: (input['action_type'] != 'create'),
            pick_list: 'sequence_types', toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'sequenceType',
              label: 'Sequence type',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>date</b>, <b>interval</b>'
            } }
        end,
        if input['fields']&.include?('shareType') || input['fields'] == 'all'
          { name: 'shareType', type: 'string',
            control_type: 'select', optional: (input['action_type'] != 'create'),
            pick_list: 'share_types', toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'shareType',
              label: 'Share type',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>private</b>, <b>read_only</b>, <b>shared</b>'
            } }
        end,
        if (input['fields']&.include?('throttleCapacity') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'throttleCapacity', type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('throttleMaxAddsPerDay') || input['fields'] == 'all'
          { name: 'throttleMaxAddsPerDay', label: 'Throttle max adds per day',
            type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('throttlePaused') || input['fields'] == 'all'
          { name: 'throttlePaused', type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'throttlePaused',
              label: 'Throttle paused',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('throttlePausedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'throttlePausedAt', label: 'Throttle paused at',
            type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('transactional') || input['fields'] == 'all'
          { name: 'transactional', sticky: true,
            type: 'boolean', control_type: 'checkbox',
            hint: 'Determines whether prospect opt out preferences are respected.',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'transactional',
              label: 'Transactional',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('updatedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end
      ]&.compact
    end,
    sequence_relationship: lambda do |_action_type|
      [
        { name: 'owner', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] }
        ] },
        { name: 'ruleset', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] }
        ] }
      ]
    end,
    sequence_search_schema: lambda do
      [
        { name: 'name', label: 'Sequence name', sticky: true },
        { name: 'shareType', type: 'string', sticky: true, control_type: 'select',
          pick_list: 'share_types', toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'shareType',
            label: 'Share type',
            type: 'string',
            optional: true,
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: <b>private</b>, <b>read_only</b>, <b>shared</b>'
          } },
        { name: 'clickCount', type: 'integer', control_type: 'integer' },
        { name: 'deliverCount', type: 'integer', control_type: 'integer' },
        { name: 'openCount', type: 'integer', control_type: 'integer' },
        { name: 'replyCount', type: 'integer', control_type: 'integer' },
        { name: 'throttleCapacity', type: 'integer', control_type: 'integer',
          hint: 'The maximum number of associated sequence states per user that can ' \
          'be active at a one time.' },
        { name: 'throttleMaxAddsPerDay', label: 'Throttle max adds per day' },
        { name: 'enabledAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date enabled', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'lastUsedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date last used', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'lockedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date locked', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'createdAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date created', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'updatedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date updated', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] }
      ]
    end,
    sequence_state_schema: lambda do |input|
      [
        if (input['fields']&.include?('bounceCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'bounceCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('clickCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'clickCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('deliverCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'deliverCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('failureCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'failureCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('negativeReplyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'negativeReplyCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('neutralReplyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'neutralReplyCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('openCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'openCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('optOutCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'optOutCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('positiveReplyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'positiveReplyCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('pauseReason') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'pauseReason' }
        end,
        if (input['fields']&.include?('errorReason') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'errorReason' }
        end,
        if (input['fields']&.include?('repliedAt') ||
          input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'repliedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('replyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'replyCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('scheduleCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'scheduleCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('state') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'state' }
        end,
        if (input['fields']&.include?('stateChangedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'stateChangedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('activeAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'activeAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('callCompletedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'callCompletedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('createdAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'createdAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('updatedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end
      ]&.compact
    end,
    sequence_state_relationship: lambda do |action_type|
      [
        if action_type == 'output'
          { name: 'activeStepMailings', type: 'object', properties: [
            { name: 'data', type: 'array', of: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer' }
            ] },
            { name: 'links', type: 'object', properties: [
              { name: 'related' }
            ] },
            { name: 'meta', type: 'object', properties: [
              { name: 'count', type: 'integer' }
            ] }
          ] }
        end,
        if action_type == 'output'
          { name: 'activeStepTasks', type: 'object', properties: [
            { name: 'data', type: 'array', of: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer' }
            ] },
            { name: 'links', type: 'object', properties: [
              { name: 'related' }
            ] },
            { name: 'meta', type: 'object', properties: [
              { name: 'count', type: 'integer' }
            ] }
          ] }
        end,
        if action_type == 'output'
          { name: 'batchItemCreator', type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] }
        end,
        if action_type == 'output'
          { name: 'calls', type: 'object', properties: [
            { name: 'links', type: 'object', properties: [
              { name: 'related' }
            ] }
          ] }
        end,
        if action_type == 'output'
          { name: 'creator', type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] }
        end,
        { name: 'mailbox', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type', default: 'mailbox', optional: false, hint: 'E.g. mailbox' },
            { name: 'id', label: 'Mailbox', control_type: 'select',
              optional: false, pick_list: 'mailboxes',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'id',
                label: 'Mailbox ID',
                type: 'integer',
                control_type: 'integer',
                render_input: 'integer_conversion',
                parse_output: 'integer_conversion',
                toggle_hint: 'Enter mailbox ID',
                hint: 'E.g. 1 or 2'
              } }
          ] }
        ] },
        if action_type == 'output'
          { name: 'mailings', type: 'object', properties: [
            { name: 'links', type: 'object', properties: [
              { name: 'related' }
            ] }
          ] }
        end,
        if action_type == 'output'
          { name: 'opportunity', type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] }
        end,
        { name: 'prospect', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] }
        ] },
        { name: 'sequence', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] }
        ] },
        { name: 'sequenceStateRecipients', type: 'object', properties: [
          { name: 'data', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] }
        ] },
        if action_type == 'output'
          { name: 'sequenceStep', type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] }
        end,
        if action_type == 'output'
          { name: 'tasks', type: 'object', properties: [
            { name: 'links', type: 'object', properties: [
              { name: 'related' }
            ] }
          ] }
        end
      ]&.compact
    end,
    sequence_state_search_schema: lambda do
      [
        { name: 'prospect', type: 'object', properties: [
          { name: 'id', label: 'Prospect ID', sticky: true,
            hint: 'Multiple IDs can be applied by providing values separated by comma' }
        ] },
        { name: 'sequence', type: 'object', properties: [
          { name: 'id', label: 'Sequence name',  sticky: true,
            control_type: 'multiselect', delimiter: ',', pick_list: 'sequences',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'sequence_id',
              label: 'Sequence ID',
              optional: true,
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter custom value',
              hint: 'E.g 1, 2'
            } }
        ] },
        { name: 'sequenceStep', type: 'object', properties: [
          { name: 'id', label: 'Sequence step', control_type: 'multiselect',
            pick_list: 'sequence_steps', delimiter: ',',
            pick_list_params: { sequence_id: 'sequence.sequence_id' },
            hint: 'Limit to only the selected steps in the sequence'
          }
        ] },
        { name: 'state', type: 'string', control_type: 'multiselect', sticky: true,
          pick_list: 'sequence_state_statuses', delimiter: ',' },
        { name: 'mailbox', type: 'object', properties: [
          { name: 'email', label: 'Assigned user email', control_type: 'email',
            type: 'string', sticky: true, toggle_hint: 'Enter email',
            hint: 'Search only for prospects sequenced under this user' }
        ] },
        { name: 'clickCount', type: 'integer', control_type: 'integer',
          hint: 'The total count of clicked mailings from this sequence state' },
        { name: 'deliverCount', type: 'integer', control_type: 'integer',
          hint: 'The total count of delivered mailings from this sequence state' },
        { name: 'openCount', type: 'integer', control_type: 'integer',
          hint: 'The total count of opened mailings from this sequence state.' },
        { name: 'replyCount', type: 'integer', control_type: 'integer',
          hint: 'The total count of replied mailings from this sequence state.' },
        { name: 'pauseReason', hint: 'The reason for the most recent pause.' },
        { name: 'repliedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date replied', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'The date and time the sequence state last had a mailing reply.' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'stateChangedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'The date and time the state last changed.' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'callCompletedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date call completed', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'The date and time the sequence state last had a call completed.' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'createdAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date created', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'updatedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date updated', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] }
      ]
    end,
    task_schema: lambda do |input|
      [
        if input['action_type'] == 'create'
          { name: 'owner', label: 'Task owner', control_type: 'select',
            optional: false, pick_list: 'users',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'owner',
              label: 'Task owner user ID',
              type: 'integer',
              control_type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              toggle_hint: 'Enter task owner user ID',
              hint: 'E.g. 1 or 2'
            } }
        end,
        if input['action_type'] == 'create'
          { name: 'subject', type: 'object', properties: [
            { name: 'type', label: 'Subject type', control_type: 'select',
              optional: false, pick_list: 'task_subjects',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'type',
                label: 'Subject type',
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: <b>account</b>, <b>prospect</b>'
              } },
            { name: 'id', control_type: 'text', optional: false,
              hint: 'Enter the ID of the account or prospect to create the task for.' }
          ] }
        end,
        if input['fields']&.include?('action') || input['fields'] == 'all'
          { name: 'action', type: 'string', control_type: 'select', optional: false,
            pick_list: 'task_actions', hint: 'The action type of the task.',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'action',
              label: 'Action',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>action_item</b>, <b>call</b>, <b>email</b>, <b>in_person</b>'
            } }
        end,
        if input['action_type'] == 'create'
          { name: 'taskPriority', control_type: 'select',
            optional: false, pick_list: 'task_priorities',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'taskPriority',
              label: 'Task priority ID',
              type: 'integer',
              control_type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              toggle_hint: 'Enter task priority ID',
              hint: 'E.g. 1 or 2'
            } }
        end,
        if (input['fields']&.include?('compiledSequenceTemplateHtml') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'compiledSequenceTemplateHtml', type: 'string' }
        end,
        if (input['fields']&.include?('completed') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'completed', control_type: 'checkbox', type: 'boolean' }
        end,
        if (input['fields']&.include?('completedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'completedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('createdAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'createdAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('dueAt') || input['fields'] == 'all'
          { name: 'dueAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('autoskipAt') || input['fields'] == 'all'
          { name: 'autoskipAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'The optional date and time when the task will automatically ' \
            'be skipped. Tasks with an empty autoskip_at will never be autoskipped' }
        end,
        if input['fields']&.include?('note') || input['fields'] == 'all'
          { name: 'note', hint: 'A note for the task.' }
        end,
        if (input['fields']&.include?('scheduledAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'scheduledAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('state') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'state', label: 'Task current state', type: 'string' }
        end,
        if (input['fields']&.include?('stateChangedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'stateChangedAt', label: 'State changed at', type: 'date_time',
            control_type: 'date_time', render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('taskType') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'taskType', label: 'Task type', type: 'string' }
        end,
        if (input['fields']&.include?('updatedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end
      ]&.compact
    end,
    task_relationship: lambda do |_action_type|
      [
        { name: 'account', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'call', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'calls', type: 'object', properties: [
          { name: 'links', type: 'object', properties: [
            { name: 'related', control_type: 'url', type: 'string' }
          ] }
        ] },
        { name: 'completer', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'creator', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'mailing', type: 'object', properties: [
          { name: 'data', type: 'object',  properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'mailings', type: 'object', properties: [
          { name: 'links', type: 'object', properties: [
            { name: 'related',  type: 'string', control_type: 'url' }
          ] }
        ] },
        { name: 'opportunity', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'owner', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] }
        ] },
        { name: 'prospect', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'sequence', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'sequenceState', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'sequenceStep', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'subject', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] }
        ] },
        { name: 'taskPriority', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] }
        ] },
        { name: 'taskTheme', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'template', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] }
      ]
    end,
    task_search_schema: lambda do
      [
        { name: 'prospect', type: 'object', properties: [
          { name: 'id', label: 'Prospect ID', sticky: true,
            hint: 'Multiple IDs can be applied by providing values separated by comma' }
        ] },
        { name: 'state', type: 'string', control_type: 'select', sticky: true,
          pick_list: 'task_states', hint: 'The current state of the task',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'state',
            label: 'State',
            type: 'string',
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: <b>pending</b>, <b>incomplete</b>, <b>complete</b>'
          } },
        { name: 'taskType', type: 'string', control_type: 'select', sticky: true,
          pick_list: 'task_types', hint: 'The current state of the task',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'taskType',
            label: 'Task type',
            type: 'string',
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: <b>follow_up</b>, <b>manual</b>, <b>no_reply</b>, ' \
            '<b>sequence_open</b>, <b>sequence_click</b>, <b>sequence_step_call</b>, ' \
            '<b>sequence_step_email</b>, <b>sequence_step_task</b>, <b>touch</b>'
          } },
        { name: 'dueAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date due', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'scheduledAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date scheduled', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'The date and time the pending task is scheduled for.' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'autoskipAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'The date and time when the task will automatically be skipped.' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'stateChangedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'The date and time the state last changed.' },
          { name: 'operation', label: 'Filter operation', control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'createdAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date created', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'updatedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date updated', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] }
      ]
    end,
    user_schema: lambda do |input|
      [
        if input['fields']&.include?('firstName') || input['fields'] == 'all'
          { name: 'firstName', optional: (input['action_type'] != 'create'), sticky: true }
        end,
        if input['fields']&.include?('lastName') || input['fields'] == 'all'
          { name: 'lastName', optional: (input['action_type'] != 'create'), sticky: true }
        end,
        if (input['fields']&.include?('name') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'name', label: 'Full name' }
        end,
        if input['fields']&.include?('email') || input['fields'] == 'all'
          { name: 'email', control_type: 'email',
            optional: (input['action_type'] != 'create'), sticky: true }
        end,
        if input['fields']&.include?('title') || input['fields'] == 'all'
          { name: 'title', label: 'Job title', sticky: true }
        end,
        if input['action_type'] == 'create'
          { name: 'role', control_type: 'select', sticky: true, pick_list: 'roles',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'role',
              label: 'Role ID',
              type: 'integer',
              control_type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              optional: true,
              toggle_hint: 'Enter role ID',
              hint: 'E.g. 1 or 2'
            } }
        end,
        if input['action_type'] == 'create'
          { name: 'profile', label: 'Profile', control_type: 'select', sticky: true,
            pick_list: 'profiles', toggle_hint: 'Select from list',
            toggle_field: {
              name: 'profile',
              label: 'Profile ID',
              type: 'integer',
              control_type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              optional: true,
              toggle_hint: 'Enter profile ID',
              hint: 'E.g. 1 or 2'
            } }
        end,
        if input['fields']&.include?('activityNotificationsDisabled') || input['fields'] == 'all'
          { name: 'activityNotificationsDisabled', label: 'Activity notifications disabled',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'activityNotificationsDisabled',
              label: 'Activity notifications disabled',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('bounceWarningEmailEnabled') || input['fields'] == 'all'
          { name: 'bounceWarningEmailEnabled', label: 'Bounce warning email enabled',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'bounceWarningEmailEnabled',
              label: 'Bounce warning email enabled',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('bridgePhone') || input['fields'] == 'all'
          { name: 'bridgePhone', control_type: 'phone' }
        end,
        if input['fields']&.include?('bridgePhoneExtension') || input['fields'] == 'all'
          { name: 'bridgePhoneExtension', label: 'Bridge phone extension' }
        end,
        if input['fields']&.include?('controlledTabDefault') || input['fields'] == 'all'
          { name: 'controlledTabDefault', label: 'Controlled tab default',
            hint: "The user's preferred default tab to open when in task flow" }
        end,
        if (input['fields']&.include?('createdAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'createdAt', type: 'date_time', control_type: 'date_time' }
        end,
        if (input['fields']&.include?('currentSignInAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'currentSignInAt', label: 'Current sign in at',
            type: 'date_time', control_type: 'date_time' }
        end,
        if input['fields']&.include?('custom1') || input['fields'] == 'all'
          { name: 'custom1' }
        end,
        if input['fields']&.include?('custom2') || input['fields'] == 'all'
          { name: 'custom2' }
        end,
        if input['fields']&.include?('custom3') || input['fields'] == 'all'
          { name: 'custom3' }
        end,
        if input['fields']&.include?('custom4') || input['fields'] == 'all'
          { name: 'custom4' }
        end,
        if input['fields']&.include?('custom5') || input['fields'] == 'all'
          { name: 'custom5' }
        end,
        if input['fields']&.include?('dailyDigestEmailEnabled') || input['fields'] == 'all'
          { name: 'dailyDigestEmailEnabled', label: 'Daily digest email enabled',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'dailyDigestEmailEnabled',
              label: 'Daily digest email enabled',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('enableVoiceRecordings') || input['fields'] == 'all'
          { name: 'enableVoiceRecordings', label: 'Enable voice recordings',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'enableVoiceRecordings',
              label: 'Enable voice recordings',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('inboundBridgePhone') || input['fields'] == 'all'
          { name: 'inboundBridgePhone', label: 'Inbound bridge phone' }
        end,
        if input['fields']&.include?('inboundBridgePhoneExtension') || input['fields'] == 'all'
          { name: 'inboundBridgePhoneExtension', label: 'Inbound bridge phone extension' }
        end,
        if input['fields']&.include?('inboundPhoneType') || input['fields'] == 'all'
          { name: 'inboundPhoneType', control_type: 'select', pick_list: 'call_types',
            hint: "The user's type of telephone for inbound call",
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'inboundPhoneType',
              label: 'Inbound phone type',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>bridge</b>, <b>voip</b>'
            } }
        end,
        if input['fields']&.include?('inboundCallBehavior') || input['fields'] == 'all'
          { name: 'inboundCallBehavior', label: 'Inbound call behavior', type: 'string',
            control_type: 'select', pick_list: 'call_behaviors', hint: 'The behavior of inbound calls',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'inboundCallBehavior',
              label: 'Inbound call behavior',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are <b>inbound_bridge</b>, <b>inbound_voicemail</b>'
            } }
        end,
        if input['fields']&.include?('inboundVoicemailCustomMessageText') || input['fields'] == 'all'
          { name: 'inboundVoicemailCustomMessageText', label: 'Inbound voicemail custom message text',
            hint: "The message for inbound voicemails (e.g. 'Please leave a " \
            "message and I will get back to you as soon I can')." }
        end,
        if input['fields']&.include?('inboundVoicemailMessageTextVoice') || input['fields'] == 'all'
          { name: 'inboundVoicemailMessageTextVoice', label: 'Inbound voicemail message text voice',
            type: 'string', control_type: 'select',
            pick_list: 'genders',
            hint: 'The gender of the voice that reads the voicemail message',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'inboundVoicemailMessageTextVoice',
              label: 'Inbound voicemail message text voice',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              optional: true,
              hint: 'Allowed values are: <b>man</b>, <b>woman</b>'
            } }
        end,
        if input['fields']&.include?('inboundVoicemailPromptType') || input['fields'] == 'all'
          { name: 'inboundVoicemailPromptType', type: 'string', control_type: 'select',
            pick_list: 'prompt_types', hint: 'The type of inbound voicemail to use',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'inboundVoicemailPromptType',
              label: 'Inbound voicemail prompt type',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>automated</b>, <b>recorded</b>, <b>off</b>'
            } }
        end,
        if input['fields']&.include?('keepBridgePhoneConnected') || input['fields'] == 'all'
          { name: 'keepBridgePhoneConnected', label: 'Keep bridge phone connected',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            hint: "Whether to keep the user's bridge phone connected " \
            'in-between outbound calls.	',
            toggle_field: {
              name: 'keepBridgePhoneConnected',
              label: 'Keep bridge phone connected',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('lastSignInAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'lastSignInAt', label: 'Last sign in at', type: 'date_time',
            control_type: 'date_time', render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('locked') || input['fields'] == 'all'
          { name: 'locked', type: 'boolean', control_type: 'checkbox',
            hint: 'Indicates whether the user is locked out of the application',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'locked',
              label: 'Locked',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('mailboxErrorEmailEnabled') || input['fields'] == 'all'
          { name: 'mailboxErrorEmailEnabled', label: 'Mailbox error email enabled',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'mailboxErrorEmailEnabled',
              label: 'Mailbox error email enabled',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('notificationsEnabled') || input['fields'] == 'all'
          { name: 'notificationsEnabled', label: 'Notifications enabled', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'notificationsEnabled',
              label: 'Notifications enabled',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('passwordExpiresAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'passwordExpiresAt', label: 'Password expires at', type: 'date_time',
            control_type: 'date_time', render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('oceClickToDialEverywhere') || input['fields'] == 'all'
          { name: 'oceClickToDialEverywhere', label: 'Outreach click to dial everywhere',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            hint: 'Indicates if phone calls will launch a call' \
            ' from Outreach (Salesforce, Github, Gmail, LinkedIn, and Twitter)',
            toggle_field: {
              name: 'oceClickToDialEverywhere',
              label: 'Outreach click to dial everywhere',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('oceGmailToolbar') || input['fields'] == 'all'
          { name: 'oceGmailToolbar', label: 'Outreach Gmail toolbar',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            hint: 'Indicates whether the Outreach Gmail toolbar is enabled.',
            toggle_field: {
              name: 'oceGmailToolbar',
              label: 'Outreach Gmail toolbar',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('oceGmailTrackingState') || input['fields'] == 'all'
          { name: 'oceGmailTrackingState', label: 'Outreach Gmail tracking state',
            type: 'boolean', control_type: 'checkbox', toggle_hint: 'Select from option list',
            hint: "The user's current email tracking settings when " \
            'using Outreach Everywhere with GMail.',
            toggle_field: {
              name: 'oceGmailTrackingState',
              label: 'Outreach Gmail tracking state',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('oceSalesforceEmailDecorating') || input['fields'] == 'all'
          { name: 'oceSalesforceEmailDecorating', label: 'Outreach Salesforce email decorating',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            hint: 'Indicates if emails are enabled in Outreach Everywhere with Salesforce.',
            toggle_field: {
              name: 'oceSalesforceEmailDecorating',
              label: 'Outreach Salesforce email decorating',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('oceSalesforcePhoneDecorating') || input['fields'] == 'all'
          { name: 'oceSalesforcePhoneDecorating', label: 'Outreach Salesforce phone decorating',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            hint: 'Indicates if phone calls are enabled in Outreach Everywhere with Salesforce.',
            toggle_field: {
              name: 'oceSalesforcePhoneDecorating',
              label: 'Outreach Salesforce phone decorating',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('oceUniversalTaskFlow') || input['fields'] == 'all'
          { name: 'oceUniversalTaskFlow', label: 'Outreach universal task flow',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            hint: 'Indicates whether Outreach Everywhere  universal task flow is enabled.',
            toggle_field: {
              name: 'oceUniversalTaskFlow',
              label: 'Outreach universal task flow',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('oceWindowMode') || input['fields'] == 'all'
          { name: 'oceWindowMode', label: 'Outreach window mode',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            hint: 'Indicates whether Outreach Everywhere  window mode is enabled.',
            toggle_field: {
              name: 'oceWindowMode',
              label: 'Outreach window mode',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('onboardedAt') || input['fields'] == 'all'
          { name: 'onboardedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('phoneCountryCode') || input['fields'] == 'all'
          { name: 'phoneCountryCode' }
        end,
        if input['fields']&.include?('phoneNumber') || input['fields'] == 'all'
          { name: 'phoneNumber' }
        end,
        if input['fields']&.include?('phoneType') || input['fields'] == 'all'
          { name: 'phoneType', control_type: 'select', pick_list: 'call_types',
            hint: "The user's type of telephone",
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'phoneType',
              label: 'Phone type',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>bridge</b>, <b>voip</b>'
            } }
        end,
        if input['fields']&.include?('preferredVoiceRegion') || input['fields'] == 'all'
          { name: 'preferredVoiceRegion', hint: 'A string that represents ' \
            'Twilio data center used to connect to Twilio.' }
        end,
        if input['fields']&.include?('prefersLocalPresence') || input['fields'] == 'all'
          { name: 'prefersLocalPresence', label: 'Prefers local presence', type: 'boolean',
            control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'prefersLocalPresence',
              label: 'Prefers local presence',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('prospectsViewId') || input['fields'] == 'all'
          { name: 'prospectsViewId', type: 'integer', control_type: 'integer',
            hint: 'The default smart view to load on the prospect index view.' }
        end,
        if input['fields']&.include?('senderNotificationsExcluded') || input['fields'] == 'all'
          { name: 'senderNotificationsExcluded', label: 'Sender notifications excluded',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'senderNotificationsExcluded',
              label: 'Sender notifications excluded',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('skuProspectsIndexPageV2') || input['fields'] == 'all'
          { name: 'skuProspectsIndexPageV2', label: 'SKU prospects index page v2',
            type: 'boolean', control_type: 'checkbox',
            hint: 'Indicates whether the user SKU is enabled. If a' \
            ' user SKU does not exist, it will default to the org SKU value.',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'skuProspectsIndexPageV2',
              label: 'SKU prospects index page v2',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('textingEmailNotifications') || input['fields'] == 'all'
          { name: 'textingEmailNotifications', label: 'Texting email notifications',
            type: 'boolean', control_type: 'checkbox',
            hint: 'Indicates whether to send the user email notifications when a text message is missed.',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'textingEmailNotifications',
              label: 'Texting email notifications',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if input['fields']&.include?('unknownReplyEmailEnabled') || input['fields'] == 'all'
          { name: 'unknownReplyEmailEnabled', label: 'Unknown reply email enabled',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'unknownReplyEmailEnabled',
              label: 'Unknown reply email enabled',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('updatedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'updatedAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if input['fields']&.include?('username') || input['fields'] == 'all'
          { name: 'username', type: 'string', control_type: 'string' }
        end,
        if input['fields']&.include?('weeklyDigestEmailEnabled') || input['fields'] == 'all'
          { name: 'weeklyDigestEmailEnabled', label: 'Weekly digest email enabled',
            type: 'boolean', control_type: 'checkbox',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'weeklyDigestEmailEnabled',
              label: 'Weekly digest email enabled',
              type: 'string',
              control_type: 'text',
              optional: true,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end
      ]&.compact
    end,
    user_relationship: lambda do |_action_type|
      [
        { name: 'calendar', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'contentCategories', type: 'object', properties: [
          { name: 'data', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] },
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] },
          { name: 'meta', type: 'object', properties: [
            { name: 'count', type: 'integer' }
          ] }
        ] },
        { name: 'creator', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'mailbox', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'outboundVoicemails', type: 'object', properties: [
          { name: 'data', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] },
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] },
          { name: 'meta', type: 'object', properties: [
            { name: 'count', type: 'integer' }
          ] }
        ] },
        { name: 'phone', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'phones', type: 'object', properties: [
          { name: 'data', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] },
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] },
          { name: 'meta', type: 'object', properties: [
            { name: 'count', type: 'integer' }
          ] }
        ] },
        { name: 'profile', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'recipients', type: 'object', properties: [
          { name: 'data', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] },
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] },
          { name: 'meta', type: 'object', properties: [
            { name: 'count', type: 'integer' }
          ] }
        ] },
        { name: 'role', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type', default: 'role', hint: 'E.g. role' },
            { name: 'id', label: 'Role', control_type: 'integer', type: 'integer' }
          ] }
        ] },
        { name: 'smsPhone', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'teams', type: 'object', properties: [
          { name: 'data', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] },
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] },
          { name: 'meta', type: 'object', properties: [
            { name: 'count', type: 'integer' }
          ] }
        ] },
        { name: 'updater', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'voicemailPrompts', type: 'object', properties: [
          { name: 'data', type: 'array', of: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] },
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] },
          { name: 'meta', type: 'object', properties: [
            { name: 'count', type: 'integer' }
          ] }
        ] }
      ]
    end,
    user_search_schema: lambda do
      [
        { name: 'email', type: 'string', control_type: 'email', sticky: true },
        { name: 'firstName', sticky: true },
        { name: 'lastName', sticky: true },
        { name: 'username' },
        { name: 'createdAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date created', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'updatedAt', type: 'object', properties: [
          { name: 'date_value', label: 'Date updated', type: 'date_time', control_type: 'date_time',
            sticky: true, render_input: 'date_time_conversion', parse_output: 'date_time_conversion' },
          { name: 'operation', label: 'Filter operation', sticky: true, control_type: 'select',
            pick_list: 'operators', hint: 'Defaults to <b>Greater than or equal to</b> when left blank',
            toggle_hint: 'Select operator',
            toggle_field: {
              name: 'operation',
              type: 'string',
              optional: true,
              control_type: 'text',
              label: 'Filter operation',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>inf</b> - Greater than or equal to, <b>neginf</b> - Less than or equal to '
            } }
        ] },
        { name: 'locked', type: 'boolean', control_type: 'checkbox',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'locked',
            label: 'Locked',
            type: 'string',
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: <b>true</b>, <b>false</b>'
          } }
      ]
    end,
    sequence_step_schema: lambda do |input|
      [
        if input['action_type'] == 'create'
          { name: 'sequence', control_type: 'select',
            optional: false, pick_list: 'sequences',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'id',
              label: 'Sequence ID',
              type: 'integer',
              control_type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              toggle_hint: 'Enter sequence ID',
              hint: 'E.g. 1 or 2'
            } }
        end,
        if input['fields']&.include?('stepType') || input['fields'] == 'all'
          { name: 'stepType', control_type: 'select', optional: (input['action_type'] != 'create'),
            pick_list: 'step_types', toggle_hint: 'Select from list',
            toggle_field: {
              name: 'stepType',
              label: 'Step type',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter custom value',
              hint: 'Allowed values are: <b>auto_email</b>, <b>manual_email' \
              '</b>, <b>call</b> or <b>task</b>.'
            } }
        end,
        if input['fields']&.include?('order') || input['fields'] == 'all'
          { name: 'order', type: 'integer', control_type: 'integer', sticky: true,
            hint: 'The step’s display order within its sequence.' }
        end,
        if input['fields']&.include?('interval') || input['fields'] == 'all'
          { name: 'interval', type: 'integer', control_type: 'integer',
            hint: 'The interval (in minutes) until this still' \
            ' will activate; only applicable to interval-based sequences.' }
        end,
        if input['fields']&.include?('date') || input['fields'] == 'all'
          { name: 'date', type: 'date', control_type: 'date',
            render_input: 'date_conversion', parse_output: 'date_conversion',
            hint: 'The date this step will activate; only applicable to date-based sequences.' }
        end,
        if input['action_type'] == 'create'
          { name: 'taskPriority', control_type: 'select',
            stick: true, pick_list: 'task_priorities',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'taskPriority',
              label: 'Task priority ID',
              type: 'integer',
              control_type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              toggle_hint: 'Enter task priority ID',
              hint: 'E.g. 1 or 2'
            } }
        end,
        if input['action_type'] == 'create'
          { name: 'callPurpose', type: 'integer', label: 'Call purpose ID',
            control_type: 'integer' }
        end,
        if input['fields']&.include?('taskAutoskipDelay') || input['fields'] == 'all'
          { name: 'taskAutoskipDelay', label: 'Task autoskip delay', type: 'integer',
            control_type: 'integer', hint: 'The optional interval (in seconds) from when tasks ' \
            'created by this sequence step are overdue until they are automatically skipped.' }
        end,
        if input['fields']&.include?('taskNote') || input['fields'] == 'all'
          { name: 'taskNote', label: 'Task note', sticky: true,
            hint: 'An optional note to associate with created tasks.	' }
        end,
        if (input['fields']&.include?('displayName') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'displayName' }
        end,
        if (input['fields']&.include?('bounceCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'bounceCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('clickCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'clickCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('deliverCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'deliverCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('failureCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'failureCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('negativeReplyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'negativeReplyCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('neutralReplyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'neutralReplyCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('openCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'openCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('optOutCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'optOutCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('positiveReplyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'positiveReplyCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('replyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'replyCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('scheduleCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'scheduleCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('createdAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'createdAt', type: 'date_time', control_type: 'date_time',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end,
        if (input['fields']&.include?('updatedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'updatedAt', type: 'date_time', control_type: 'text',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end
      ]&.compact
    end,
    sequence_step_relationship: lambda do |_action_type|
      [
        { name: 'callPurpose', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] }
        ] },
        { name: 'calls', type: 'object', properties: [
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] }
        ] },
        { name: 'creator', type: 'object', properties: [
          { name: 'data', type: 'object',  properties: [
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'mailings', type: 'object', properties: [
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] }
        ] },
        { name: 'sequence', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type' },
            { name: 'id', type: 'integer' }
          ] }
        ] },
        { name: 'sequenceTemplates', type: 'object', properties: [
          { name: 'data', type: 'array', of: 'object',
            properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] },
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] },
          { name: 'meta', type: 'object', properties: [
            { name: 'count', type: 'integer', control_type: 'integer' }
          ] }
        ] },
        { name: 'taskPriority', label: 'Task priority', type: 'object',
          properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer' }
            ] }
        ] },
        { name: 'tasks', type: 'object', properties: [
          { name: 'links', type: 'object', properties: [
            { name: 'related' }
          ] }
        ] },
        { name: 'updater', type: 'object', properties: [
          { name: 'data', type: 'object',  properties: [
            { name: 'type' },
            { name: 'id', type: 'integer', control_type: 'integer' }
          ] }
        ] }
      ]
    end,
    sequence_template_schema: lambda do |input|
      [
        if (input['fields']&.include?('bounceCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'bounceCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('clickCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'clickCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('createdAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'createdAt', type: 'date_time', control_type: 'date_time' }
        end,
        if (input['fields']&.include?('deliverCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'deliverCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('enabled') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'enabled', type: 'boolean', control_type: 'text',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'enabled',
              label: 'Enabled',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('enabledAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'enabledAt', type: 'date_time', control_type: 'date_time' }
        end,
        if (input['fields']&.include?('failureCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'failureCount', type: 'integer', control_type: 'integer' }
        end,
        if input['fields']&.include?('isReply') || input['fields'] == 'all'
          { name: 'isReply', type: 'boolean', control_type: 'text', optional: false,
            hint: 'Boolean indicating if the sequence template should be ' \
            'a reply email or a new thread.',
            toggle_hint: 'Select from option list',
            toggle_field: {
              name: 'isReply',
              label: 'Is reply',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are: <b>true</b>, <b>false</b>'
            } }
        end,
        if (input['fields']&.include?('negativeReplyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'negativeReplyCount', label: 'Negative reply count',
            type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('neutralReplyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'neutralReplyCount', label: 'Neutral reply count',
            type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('openCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'openCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('optOutCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'optOutCount', label: 'Opt out count', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('positiveReplyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'positiveReplyCount', label: 'Positive reply count',
            type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('replyCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'replyCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('scheduleCount') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'scheduleCount', type: 'integer', control_type: 'integer' }
        end,
        if (input['fields']&.include?('updatedAt') ||
            input['fields'] == 'all') && input['action_type'] == 'output'
          { name: 'updatedAt', type: 'date_time', control_type: 'text',
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion' }
        end
      ].compact
    end,
    sequence_template_relationship: lambda do |action_type|
      [
        if action_type == 'output'
          { name: 'creator', type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] }
        end,
        { name: 'sequenceStep', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type', default: 'sequenceStep', optional: false, hint: 'E.g. sequenceStep' },
            { name: 'id', type: 'integer', control_type: 'integer', optional: false }
          ] }
        ] },
        { name: 'template', type: 'object', properties: [
          { name: 'data', type: 'object', properties: [
            { name: 'type', default: 'template', optional: false, hint: 'E.g. template' },
            { name: 'id', type: 'integer', control_type: 'integer', optional: false }
          ] }
        ] },
        if action_type == 'output'
          { name: 'updater', type: 'object', properties: [
            { name: 'data', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer', control_type: 'integer' }
            ] }
          ] }
        end
      ].compact
    end,
    sample_record: lambda do |input|
      get("/api/v2/#{input&.pluralize}?page[limit]=1")&.dig('data', 0)
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
    format_schema: lambda do |input|
      input&.map do |field|
        if (props = field[:properties])
          field[:properties] = call('format_schema', props)
        elsif (props = field['properties'])
          field['properties'] = call('format_schema', props)
        end
        if (name = field[:name])
          field[:label] = field[:label].presence || name.labelize
          field[:name] = name
                         .gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        elsif (name = field['name'])
          field['label'] = field['label'].presence || name.labelize
          field['name'] = name
                          .gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        end

        field
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
    search_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        object = (config_fields['object'] == 'sequenceState' ? 'sequence_state' : config_fields['object'])
        [
          { name: 'filter', label: 'Search criteria', type: 'object', sticky: true,
            properties: [
              { name: 'id', label: "#{object&.labelize} ID", sticky: true,
                hint: 'Multiple IDs can be applied by providing values separated by comma' }
            ]&.concat(call("#{object}_search_schema"))&.compact },
          { name: 'fields', control_type: 'multiselect', delimiter: ',',
            extends_schema: true, pick_list: 'field_names', pick_list_params: { object: 'object' },
            hint: 'Select atleast one field to display' },
          { name: 'sort', label: 'Sort by', sticky: true, hint: 'Provide attributes ' \
            "separated by comma to sort objects with. Put <b>'-'</b> before an attribute name to " \
            'sort objects in descending order. <b>(e.g. -firstName)</b>.Please check ' \
            "<a href='https://api.outreach.io/api/v2/docs#filter-sort-and-paginate-collections' " \
            "target='_blank'>Outreach API - Paginate and Sort collections</a> for more details." },
          { name: 'limit', type: 'integer', control_type: 'integer',
            default: '100', hint: 'Number of objects to fetch. Must be ' \
            'an integer between 1 and 1000. Defaults to 100.' }
        ]
      end
    },
    search_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        object = (config_fields['object'] == 'sequenceState' ? 'sequence_state' : config_fields['object'])
        [
          { name: 'id', label: "#{object&.labelize} ID",
            type: 'integer' },
          { name: 'attributes', type: 'object',
            properties: call("#{object}_schema",
                             'action_type' => 'output', 'fields' => config_fields['fields'] || 'all') },
          { name: 'relationships', type: 'object',
            properties: (
              object == 'profile' ? {} : call("#{object}_relationship", 'output')
            ) }
        ]
      end
    },
    get_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        object =
          if config_fields['object'] == 'sequenceStep'
            'sequence_step'
          elsif config_fields['object'] == 'sequenceTemplate'
            'sequence_template'
          else
            config_fields['object']
          end
        [{ name: 'id', type: 'integer', control_type: 'integer',
           label: "#{object&.labelize} ID", optional: false,
           hint: 'Provide the Outreach internal ID of the object you want to retrieve.' }]
      end
    },
    get_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        object =
          if config_fields['object'] == 'sequenceStep'
            'sequence_step'
          elsif config_fields['object'] == 'sequenceTemplate'
            'sequence_template'
          else
            config_fields['object']
          end
        [
          { name: 'id', label: "#{object&.labelize} ID", type: 'integer' },
          { name: 'attributes', type: 'object',
            properties: call("#{object}_schema",
                             'action_type' => 'output', 'fields' => 'all') },
          { name: 'relationships', type: 'object',
            properties: call("#{object}_relationship", 'output') }
        ]
      end
    },
    create_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        object = (config_fields['object'] == 'sequenceStep' ? 'sequence_step' : config_fields['object'])
        call("#{object}_schema", 'action_type' => 'create', 'fields' => 'all')
      end
    },
    create_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        object = (config_fields['object'] == 'sequenceStep' ? 'sequence_step' : config_fields['object'])
        [
          { name: 'id', label: "#{object&.labelize} ID", type: 'integer' },
          { name: 'attributes', type: 'object',
            properties: call("#{object}_schema",
                             'action_type' => 'output', 'fields' => 'all') },
          { name: 'relationships', type: 'object',
            properties: call("#{object}_relationship", 'output') }
        ]
      end
    },
    update_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        [{ name: 'id', label: "#{config_fields['object']&.labelize} ID", type: 'integer',
           control_type: 'integer', optional: false, render_input: 'integer_conversion',
           parse_output: 'integer_conversion' }]&.
          concat(call("#{config_fields['object']}_schema",
                      'action_type' => 'update', 'fields' => 'all'))&.compact
      end
    },
    update_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        [
          { name: 'id', label: "#{config_fields['object']&.labelize} ID", type: 'integer' },
          { name: 'attributes', type: 'object',
            properties: call("#{config_fields['object']}_schema",
                             'action_type' => 'output', 'fields' => 'all') },
          { name: 'relationships', type: 'object',
            properties: call("#{config_fields['object']}_relationship", 'output') }
        ]
      end
    },
    trigger_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        [
          { name: 'id', label: "#{config_fields['object']&.labelize} ID", type: 'integer' },
          { name: 'attributes', type: 'object',
            properties: call("#{config_fields['object']}_schema",
                             'action_type' => 'output', 'fields' => 'all') },
          { name: 'relationships', type: 'object',
            properties: call("#{config_fields['object']}_relationship", 'output') }
        ]
      end
    },
    sequence_state: {
      fields: lambda do |_connection, _config_fields|
        call('sequence_state_schema', 'action_type' => 'output', 'fields' => 'all')
      end
    },
    sequence_state_relationship: {
      fields: ->(_connection, _config_fields) { call('sequence_state_relationship', 'output') }
    },
    sequence_template: {
      fields: lambda do |_connection, _config_fields|
        call('sequence_template_schema', 'action_type' => 'output', 'fields' => 'all')
      end
    },
    sequence_template_relationship: {
      fields: ->(_connection, _config_fields) { call('sequence_template_relationship', 'output') }
    },
    sequence_step: {
      fields: lambda do |_connection, _config_fields|
        call('sequence_step_schema', 'action_type' => 'output', 'fields' => 'all')
      end
    },
    sequence_step_relationship: {
      fields: ->(_connection, _config_fields) { call('sequence_step_relationship', 'output') }
    },
    user: {
      fields: lambda do |_connection, _config_fields|
        call('user_schema', 'action_type' => 'output', 'fields' => 'all')
      end
    },
    user_relationship: {
      fields: ->(_connection, _config_fields) { call('user_relationship', 'output') }
    },
    task: {
      fields: lambda do |_connection, _config_fields|
        call('task_schema', 'action_type' => 'output', 'fields' => 'all')
      end
    },
    task_relationship: {
      fields: ->(_connection, _config_fields) { call('task_relationship', 'output') }
    },
    mailing: {
      fields: lambda do |_connection, _config_fields|
        call('mailing_schema', 'action_type' => 'output', 'fields' => 'all')
      end
    },
    mailing_relationship: {
      fields: ->(_connection, _config_fields) { call('mailing_relationship', 'output') }
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
            'https://api.outreach.io' \
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
                            render_input: 'boolean_conversion',
                            parse_output: 'boolean_conversion',
                            control_type: 'checkbox',
                            type: 'boolean'
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
    search_object: {
      title: 'Search objects',
      subtitle: 'Retrieves a list of objects, e.g prospect, that matches your criteria',
      description: lambda do |_input, pick_lists|
        "Search <span class='provider'>#{pick_lists[:object]&.downcase&.pluralize || 'objects'}" \
        "</span> in <span class='provider'>Outreach</span>"
      end,
      help: lambda do |_input, pick_lists|
        {
          body: "Fetches multiple #{pick_lists[:object]&.downcase} objects. The objects can be " \
          'filtered and sorted according to the specified attributes. By default, this ' \
          'action returns a maximum of 100 rows. Use the pagination section to specify '\
          'the number objects to return. All attributes of the selected object will be returned' \
          ' by default, use <b>fields</b> to select specific attributes to display. Note that not' \
          ' all attributes permit filter and sort criteria. Please check ' \
          "<a href='https://api.outreach.io/api/v2/docs#api-reference' target= '_blank'>" \
          'Outreach API reference</a> for more details.'
        }
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'search_object_list',
          hint: 'Select the Outreach object to search for, then specify at ' \
          'least one field to match.'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['search_object_input']
      end,

      execute: lambda do |_connection, input|
        query_params = input.except('object')&.each_with_object({}) do |(key, val), hash|
          if key == 'fields'
            hash["fields[#{input['object']}]"] =
              val || call("#{input['object']}_schema",
                          'action_type' => 'output', 'fields' => 'all').pluck(:name).smart_join(',')
          elsif key == 'filter'
            val&.each_with_object({}) do |(k, v)|
              if %w[createdAt updatedAt touchedAt eventAt clickedAt bouncedAt deliveredAt repliedAt
                    retryAt openedAt notifyThreadScheduledAt scheduledAt stateChangedAt unsubscribedAt
                    engagedAt enabledAt lockedAt lastUsedAt callCompletedAt dueAt autoskipAt].include?(k)
                if v['operation'] == 'neginf'
                  hash["filter[#{k}]"] = "neginf..#{(v['date_value'])&.to_time&.utc&.iso8601}"
                else
                  hash["filter[#{k}]"] = "#{(v['date_value'])&.to_time&.utc&.iso8601}..inf"
                end
              else
                hash[key] = val
              end
            end
          elsif key == 'limit'
            hash['page[limit]'] = val
          else
            hash[key] = val
          end
        end
        {
          results:
          get("/api/v2/#{input['object']&.pluralize}", query_params).
            after_error_response(/.*/) do |_code, body, _header, message|
              body = parse_json(body).dig('errors', 0)
              error("#{message}: { #{body['title']}: #{body['detail']} }")
            end['data'] || []
        }
      end,

      output_fields: lambda do |object_definition|
        [
          { name: 'results', type: 'array', of: 'object',
            properties: object_definition['search_object_output'] }
        ]
      end,

      sample_output: lambda do |_connection, input|
        { results: call('sample_record', input['object']) || [] }
      end
    },
    get_object: {
      title: 'Get object details by ID',
      subtitle: 'Retrieve details of an object, e.g prospect, via its Outreach ID',
      description: lambda do |_object_value, object_label|
        "Get <span class='provider'>#{object_label[:object]&.downcase ||
        'object'}</span> details in <span class='provider'>Outreach</span>"
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'get_object_list',
          hint: 'Select an Outreach object'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['get_object_input']
      end,

      execute: lambda do |_connection, input|
        get("/api/v2/#{input['object']&.pluralize}/#{input['id']}").
          after_error_response(/.*/) do |_code, body, _header, message|
            body = parse_json(body).dig('errors', 0)
            error("#{message}: { #{body['title']}: #{body['detail']} }")
          end['data'] || {}
      end,

      output_fields: lambda do |object_definition|
        object_definition['get_object_output']
      end,

      sample_output: lambda do |_connection, input|
        call('sample_record', input['object']) || {}
      end
    },
    create_object: {
      title: 'Create object',
      subtitle: 'Create an object, e.g prospect, in Outreach',
      description: lambda do |_input, pick_lists|
        "Create <span class='provider'>#{pick_lists[:object]&.downcase ||
        'object'}</span> in <span class='provider'>Outreach</span>"
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'create_object_list',
          hint: 'Select an Outreach object'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['create_object_input']
      end,

      execute: lambda do |_connection, input|
        attributes = input.except('object', 'role', 'profile', 'owner', 'subject', 'account',
                                  'ruleset', 'taskPriority', 'sequence', 'callPurpose')&.
                           each_with_object({}) do |(key, val), hash|
                             if %w[tags emails homePhones workPhones mobilePhones otherPhones voipPhones].include?(key)
                               hash[key] = val&.split(',')
                             elsif %w[dueAt addedAt autoskipAt].include?(key)
                               hash[key] = val.to_time.utc
                             elsif %w[foundedAt availableAt].include?(key)
                               hash[key] = val.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
                             else
                               hash[key] = val
                             end
                           end

        relationships = input.select do |key|
                          %w[role profile owner ruleset taskPriority sequence callPurpose
                             subject account]&.include?(key)
                        end&.each_with_object({}) do |(key, val), hash|
                          if key == 'subject'
                            hash[key] = { 'data' => { 'type' => val['type'].to_s, 'id' => val['id'].to_s } }
                          else
                            hash[key] = { 'data' => { 'type' => (key == 'owner' ? 'user' : key), 'id' => val.to_i } }
                          end
                        end

        payload = {
          type: input['object'],
          attributes: attributes,
          relationships: relationships
        }

        post("/api/v2/#{input['object']&.pluralize}", data: payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            body = parse_json(body).dig('errors', 0)
            error("#{message}: { #{body['title']}: #{body['detail']} }")
          end['data'] || {}
      end,

      output_fields: lambda do |object_definition|
        object_definition['create_object_output']
      end,

      sample_output: lambda do |_connection, input|
        call('sample_record', input['object']) || {}
      end
    },
    update_object: {
      title: 'Update object',
      subtitle: 'Update an object, e.g prospect, via its Outreach ID',
      description: lambda do |_input, pick_lists|
        "Update <span class='provider'>#{pick_lists[:object]&.downcase ||
        'object'}</span> in <span class='provider'>Outreach</span>"
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'update_object_list',
          hint: 'Select the Outreach object to update'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['update_object_input']
      end,

      execute: lambda do |_connection, input|
        attributes = input.except('object', 'id', 'owner', 'account')&.
          each_with_object({}) do |(key, val), hash|
            if %w[tags emails homePhones workPhones mobilePhones otherPhones voipPhones].include?(key)
              hash[key] = val&.split(',')
            elsif %w[dueAt addedAt].include?(key)
              hash[key] = val.to_time.utc
            elsif key == 'foundedAt'
              hash[key] = val.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
            else
              hash[key] = val
            end
          end

        relationships = input.select { |key| %w[owner account]&.include?(key) }&.
                        each_with_object({}) do |(key, val), hash|
                          hash[key] = { 'data' => { 'type' => (key == 'owner' ? 'user' : key), 'id' => val.to_i } }
                        end

        payload = {
          type: input['object'],
          id: input['id'],
          attributes: attributes,
          relationships: relationships
        }

        patch("/api/v2/#{input['object']&.pluralize}/#{input['id']}", data: payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            body = parse_json(body).dig('errors', 0)
            error("#{message}: { #{body['title']}: #{body['detail']} }")
          end['data'] || {}
      end,

      output_fields: lambda do |object_definition|
        object_definition['update_object_output']
      end,

      sample_output: lambda do |_connection, input|
        call('sample_record', input['object']) || {}
      end
    },
    add_prospect_to_sequence: {
      title: 'Add a prospect to sequence',
      subtitle: 'Add a prospect to sequence in Outreach',
      description: "Add a <span class='provider'>prospect to a sequence</span> " \
      "in <span class='provider'>Outreach</span>",

      input_fields: lambda do |_object_definition|
        [
          { name: 'prospect', label: 'Prospect ID', type: 'integer', control_type: 'integer',
            optional: false },
          { name: 'sequence', control_type: 'select', optional: false, pick_list: 'sequences',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'sequence',
              label: 'Sequence ID',
              type: 'integer',
              control_type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              toggle_hint: 'Enter sequence ID',
              hint: 'E.g. 1 or 2'
            } },
          { name: 'mailbox', label: 'Mailbox', control_type: 'select',
            optional: false, pick_list: 'mailboxes',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'mailbox',
              label: 'Mailbox ID',
              type: 'integer',
              control_type: 'integer',
              render_input: 'integer_conversion',
              parse_output: 'integer_conversion',
              toggle_hint: 'Enter mailbox ID',
              hint: 'E.g. 1 or 2'
            } }
        ]
      end,

      execute: lambda do |_connection, input|
        relationships = input.each_with_object({}) do |(key, val), hash|
          hash[key] = { 'data' => { 'type' => key, 'id' => val.to_i } }
        end

        payload = {
          type: 'sequenceState',
          relationships: relationships
        }
        post('/api/v2/sequenceStates', data: payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            body = parse_json(body).dig('errors', 0)
            error("#{message}: { #{body['title']}: #{body['detail']} }")
          end['data'] || {}
      end,

      output_fields: lambda do |object_definition|
        [
          { name: 'id', label:  'Sequence state ID', type: 'integer' },
          { name: 'attributes', type: 'object',
            properties: object_definition['sequence_state'] },
          { name: 'relationships', type: 'object',
            properties: object_definition['sequence_state_relationship'] }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        call('sample_record', 'sequenceState') || {}
      end
    },
    add_template_to_sequence_step: {
      title: 'Add a template to sequence step',
      subtitle: 'Add a template to a sequence step in Outreach',
      description: "Add a <span class='provider'>template to a sequence step</span> " \
      "in <span class='provider'>Outreach</span>",

      input_fields: lambda do |_object_definition|
        [
          { name: 'template', label: 'Template ID', type: 'integer', control_type: 'integer',
            optional: false, render_input: 'integer_conversion', parse_output: 'integer_conversion' },
          { name: 'sequenceStep', label: 'Sequence step ID', type: 'integer', control_type: 'integer',
            optional: false, render_input: 'integer_conversion', parse_output: 'integer_conversion' }
        ]
      end,

      execute: lambda do |_connection, input|
        relationships = input.each_with_object({}) do |(key, val), hash|
          hash[key] = { 'data' => { 'type' => key, 'id' => val.to_i } }
        end
        payload = {
          type: 'sequenceTemplate',
          relationships: relationships
        }
        post('/api/v2/sequenceTemplates', data: payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            body = parse_json(body).dig('errors', 0)
            error("#{message}: { #{body['title']}: #{body['detail']} }")
          end['data'] || {}
      end,

      output_fields: lambda do |object_definition|
        [
          { name: 'id', label:  'Sequence template ID', type: 'integer' },
          { name: 'attributes', type: 'object',
            properties: object_definition['sequence_template'] },
          { name: 'relationships', type: 'object',
            properties: object_definition['sequence_template_relationship'] }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        call('sample_record', 'sequenceTemplate') || {}
      end
    },
    get_steps_in_sequence: {
      title: 'Get steps in  a sequence',
      subtitle: 'Get steps in  a sequence in Outreach',
      description: "Get <span class='provider'>steps in  a sequence</span> " \
      "in <span class='provider'>Outreach</span>",

      input_fields: lambda do
        [
          { name: 'sequence_id', optional: false, label: 'Sequence',
            control_type: 'select', pick_list: 'sequences',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'sequence_id',
              optional: false,
              label: 'Sequence ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter sequence ID'
            } }
        ]
      end,

      execute: lambda do |_connection, input|
        {
          sequenceSteps:
          get("/api/v2/sequenceSteps?filter[sequence][id]=#{input['sequence_id']}").
            after_error_response(/.*/) do |_code, body, _header, message|
              body = parse_json(body).dig('errors', 0)
              error("#{message}: { #{body['title']}: #{body['detail']} }")
            end['data'] || []
        }
      end,

      output_fields: lambda do |object_definition|
        [
          { name: 'sequenceSteps', type: 'array', of: 'object', properties: [
            { name: 'id', label:  'Sequence step ID', type: 'integer' },
            { name: 'attributes', type: 'object',
              properties: object_definition['sequence_step'] },
            { name: 'relationships', type: 'object',
              properties: object_definition['sequence_step_relationship'] }
          ] }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        { sequenceSteps: call('sample_record', 'sequenceStep') || [] }
      end
    },
    custom_action: {
      subtitle: 'Build your own Outreach action with a HTTP request',

      description: lambda do |object_value, _object_label|
        "<span class='provider'>" \
        "#{object_value[:action_name] || 'Custom action'}</span> in " \
        "<span class='provider'>Outreach</span>"
      end,

      help: {
        body: 'Build your own Outreach action with a HTTP request. ' \
        'The request will be authorized with your Outreach connection.',
        learn_more_url: 'https://api.outreach.io/api/v2/docs',
        learn_more_text: 'Outreach API documentation'
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
          pick_list: %w[get post put patch options delete]
            .map { |verb| [verb.upcase, verb] }
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
        request_headers = input['request_headers']
          &.each_with_object({}) do |item, hash|
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
          end
          .after_error_response(/.*/) do |code, body, headers, message|
            error({ code: code, message: message, body: body, headers: headers }
              .to_json)
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
    new_object: {
      description: lambda do |_input, pick_lists|
        "New <span class='provider'>#{pick_lists[:object]&.downcase || 'object'}" \
        "</span> in <span class='provider'>Outreach</span>"
      end,
      subtitle: 'Triggers when selected Outreach object, e.g prospect, is created',

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'new_object_list',
          hint: 'Select an Outreach object'
        }
      ],
      input_fields: lambda do
        [
          {
            name: 'since', label: 'When first started, this recipe should pick up events from',
            type: 'date_time', control_type: 'date_time',
            optional: true, sticky: true,
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'When starting the recipe for the first time, picks up Outreach ' \
            'objects from the specified date and time. Leave blank to fetch objects ' \
            'created since recipe start. <b>Once the recipe has been run or '\
            'tested, this value cannot be changed</b>'
          }
        ]
      end,

      webhook_subscribe: lambda do |webhook_url, _connection, input, _recipe_id|
        params = {
          type: 'webhook',
          attributes: {
            active: true,
            url: webhook_url,
            resource: input['object'],
            action: 'created'
          }
        }
        post('https://api.outreach.io/api/v2/webhooks').payload(data: params)['data']
      end,

      webhook_notification: ->(_input, payload) { payload['data'] },

      webhook_unsubscribe: lambda do |webhook|
        delete("https://api.outreach.io/api/v2/webhooks/#{webhook['id']}")
      end,

      poll: lambda do |_connection, input, closure|
        if closure.present?
          response = get("https://api.outreach.io/api/v2/#{input['object']&.pluralize}?" + closure.split('?').last)
        else
          params = {
            page: { limit: 100 },
            sort: 'createdAt',
            filter: { createdAt: (input['since'].presence || Time.now).utc.strftime('%Y-%m-%dT%H:%M:%SZ').to_s + '..inf' }
          }
          response = get("https://api.outreach.io/api/v2/#{input['object']&.pluralize}").
                     params(params)
        end

        next_link = response.dig('links', 'next').presence
        { events: response['data'].presence, next_poll: next_link, can_poll_more: next_link.present? }
      end,

      dedup: ->(object) { object['id'] },

      output_fields: ->(object_definitions) { object_definitions['trigger_object_output'] },

      sample_output: ->(_connection, input) { call('sample_record', input['object']) }
    },
    new_or_updated_object: {
      description: lambda do |_input, pick_lists|
        "New/Updated <span class='provider'>#{pick_lists[:object]&.downcase || 'object'}" \
        "</span> in <span class='provider'>Outreach</span>"
      end,
      subtitle: 'Triggers when selected Outreach object, e.g prospect, is created/updated',

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object type',
          control_type: 'select',
          pick_list: 'new_updated_object_list',
          hint: 'Select an Outreach object'
        }
      ],
      input_fields: lambda do
        [{ name: 'since', label: 'When first started, this recipe should pick up events from',
           type: 'date_time', control_type: 'date_time',
           optional: true, sticky: true, render_input: 'date_time_conversion',
           parse_output: 'date_time_conversion',
           hint: 'When starting the recipe for the first time, picks up Outreach ' \
           'objects from the specified date and time. Leave blank to fetch objects ' \
           'created/updated since recipe start. <b>Once the recipe has been run or '\
           'tested, this value cannot be changed</b>' }]
      end,

      webhook_subscribe: lambda do |webhook_url, _connection, input, _recipe_id|
        params = {
          type: 'webhook',
          attributes: {
            active: true,
            url: webhook_url,
            resource: input['object'],
            action: '*'
          }
        }
        post('https://api.outreach.io/api/v2/webhooks').payload(data: params)['data']
      end,

      webhook_notification: ->(_input, payload) { payload['data'] },

      webhook_unsubscribe: lambda do |webhook|
        delete("https://api.outreach.io/api/v2/webhooks/#{webhook['id']}")
      end,

      poll: lambda do |_connection, input, closure|
        if closure.present?
          response = get("https://api.outreach.io/api/v2/#{input['object']&.pluralize}?" + closure.split('?').last)
        else
          params = {
            page: { limit: 100 },
            sort: 'updatedAt',
            filter: { updatedAt: (input['since'].presence || Time.now).utc.strftime('%Y-%m-%dT%H:%M:%SZ').to_s + '..inf' }
          }
          response = get("https://api.outreach.io/api/v2/#{input['object']&.pluralize}").
                     params(params)
        end

        next_link = response.dig('links', 'next').presence
        { events: response['data'].presence, next_poll: next_link, can_poll_more: next_link.present? }
      end,

      dedup: ->(object) { "#{object['id']}@#{object.dig('attributes', 'updatedAt')}" },

      output_fields: ->(object_definitions) { object_definitions['trigger_object_output'] },

      sample_output: ->(_connection, input) { call('sample_record', input['object']) }
    },
    new_mailing_event: {
      description: "New <span class='provider'>mailing event</span> in <span class='provider'>Outreach</span>",
      subtitle: 'Triggers when a mailing event occurs',

      input_fields: lambda do |_object_definition|
        [
          { name: 'since', label: 'When first started, this recipe should pick up events from',
            type: 'date_time', control_type: 'date_time', sticky: true,
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'When starting the recipe for the first time, picks up mailing ' \
            'events from the specified date and time. Leave blank to fetch mailing ' \
            'events created since recipe start. <b>Once the recipe has been run or '\
            'tested, this value cannot be changed</b>' },
          { name: 'action', label: 'Mailing action', optional: false,
            hint: 'Enter required action to trigger mailing respond',
            control_type: 'select', toggle_hint: 'Select from option list',
            pick_list: [
              %w[Delivered delivered],
              %w[Opened opened],
              %w[Replied replied]
            ] }
        ]
      end,

      webhook_subscribe: lambda do |webhook_url, _connection, input, _recipe_id|
        params = {
          type: 'webhook',
          attributes: {
            active: true,
            url: webhook_url,
            resource: 'mailing',
            action: input['action']
          }
        }
        post('https://api.outreach.io/api/v2/webhooks').payload(data: params)['data']
      end,

      webhook_notification: ->(_input, payload) { payload['data'] },

      webhook_unsubscribe: lambda do |webhook|
        delete("https://api.outreach.io/api/v2/webhooks/#{webhook['id']}")
      end,

      output_fields: lambda do |object_definition|
        [
          { name: 'id', label:  'Mailing ID', type: 'integer' },
          { name: 'attributes', type: 'object', properties: object_definition['mailing'] },
          { name: 'relationships', type: 'object', properties: object_definition['mailing_relationship'] }
        ]
      end,

      sample_output: ->(_connection, _input) { call('sample_record', 'mailing') }
    },
    new_or_updated_user: {
      description: "New/Updated <span class='provider'>user</span> in <span class='provider'>Outreach</span>",
      subtitle: 'Triggers when a user is created/updated',

      input_fields: lambda do
        [{ name: 'since', label: 'When first started, this recipe should pick up events from',
           type: 'date_time', control_type: 'date_time', sticky: true,
           render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
           hint: 'When starting the recipe for the first time, picks up Outreach ' \
           'users from the specified date and time. Leave blank to fetch users ' \
           'created/updated since recipe start. <b>Once the recipe has been run or '\
           'tested, this value cannot be changed</b>' }]
      end,

      poll: lambda do |_connection, input, closure|
        if closure.present?
          response = get('https://api.outreach.io/api/v2/users?' + closure.split('?').last)
        else
          params = {
            page: { limit: 100 },
            sort: 'updatedAt',
            filter: { updatedAt: (input['since'].presence || Time.now).utc.strftime('%Y-%m-%dT%H:%M:%SZ').to_s + '..inf' }
          }
          response = get('https://api.outreach.io/api/v2/users').params(params)
        end

        next_link = response.dig('links', 'next').presence
        { events: response['data'].presence, next_poll: next_link, can_poll_more: next_link.present? }
      end,

      dedup: ->(user) { "#{user['id']}@#{user.dig('attributes', 'updatedAt')}" },

      output_fields: lambda do |object_definition|
        [
          { name: 'id', label:  'User ID', type: 'integer' },
          { name: 'attributes', type: 'object', properties: object_definition['user'] },
          { name: 'relationships', type: 'object', properties: object_definition['user_relationship'] }
        ]
      end,

      sample_output: ->(_connection, _input) { call('sample_record', 'user') }
    },
    completed_sequence_task: {
      description: "Completed <span class='provider'>sequence task</span> in <span class='provider'>Outreach</span>",
      subtitle: 'Triggers when a user completes a sequenced task',

      input_fields: lambda do
        [
          { name: 'since', label: 'When first started, this recipe should pick up events from',
            type: 'date_time', control_type: 'date_time', sticky: true,
            render_input: 'date_time_conversion', parse_output: 'date_time_conversion',
            hint: 'When starting the recipe for the first time, picks up Outreach ' \
            'tasks from the specified date and time. Leave blank to fetch tasks ' \
            'created/updated since recipe start. <b>Once the recipe has been run or '\
            'tested, this value cannot be changed</b>' },
          { name: 'sequence_id', optional: false, label: 'Sequence', control_type: 'select',
            pick_list: 'sequences', toggle_hint: 'Select from list', sticky: true,
            toggle_field: {
              name: 'sequence_id',
              label: 'Sequence ID',
              type: 'string',
              control_type: 'text',
              toggle_hint: 'Enter custom value',
              change_on_blur: true
            } },
          { name: 'sequence_step_id', optional: true, label: 'Sequence step',
            control_type: 'multiselect', pick_list: 'sequence_steps', delimiter: ',',
            pick_list_params: { sequence_id: 'sequence_id' }, sticky: true,
            hint: 'Limit to only the selected steps in the sequence. Leave ' \
            'blank to get all completed tasks in a sequence.' }
        ]
      end,

      poll: lambda do |_connection, input, closure|
        if closure.present?
          response = get(closure)
        else
          params = {
            page: { limit: 100 },
            sort: 'updatedAt',
            filter: {
              sequence: { id: input['sequence_id'] },
              updatedAt: (input['since'].presence || Time.now).utc.strftime('%Y-%m-%dT%H:%M:%SZ') + '..inf',
              state: 'complete'
            }
          }
          if input['sequence_step_id'].present?
            params[:filter][:sequenceStep] = { id: input['sequence_step_id'] }
          end
          response = get('https://api.outreach.io/api/v2/tasks').params(params)
        end

        next_link = response.dig('links', 'next').presence
        { events: response['data'].presence, next_poll: next_link, can_poll_more: next_link.present? }
      end,

      dedup: ->(task) { "#{task['id']}@#{task.dig('attributes', 'completedAt')}" },

      output_fields: lambda do |object_definition|
        [
          { name: 'id', label:  'Task ID', type: 'integer' },
          { name: 'attributes', type: 'object', properties: object_definition['task'] },
          { name: 'relationships', type: 'object', properties: object_definition['task_relationship'] }
        ]
      end,

      sample_output: ->(_connection, _input) { call('sample_record', 'task') }
    }
  },

  pick_lists: {
    call_direction: ->(_connection) { %w[inbound outbound].map { |val| [val.labelize, val] } },
    operators: lambda do |_connection|
      [
        %w[Greater\ than\ or\ equal\ to inf],
        %w[Less\ than\ or\ equal\ to neginf]
      ]
    end,
    step_types: lambda do |_connection|
      %w[auto_email manual_email call task].map { |val| [val.labelize, val] }
    end,
    prompt_types: ->(_connection) { %w[automated recorded off].map { |val| [val.labelize, val] } },
    genders: lambda do |_connection|
      [
        %w[Male man],
        %w[Female woman]
      ]
    end,
    call_behaviors: lambda do |_connection|
      %w[inbound_bridge inbound_voicemail].map { |val| [val.labelize, val] }
    end,
    task_types: lambda do |_connection|
      %w[follow_up manual no_reply sequence_open sequence_click
         sequence_step_call sequence_step_email sequence_step_task touch].
        map { |val| [val.labelize, val] }
    end,
    task_states: lambda do |_connection|
      %w[pending incomplete complete].map { |val| [val.labelize, val] }
    end,
    task_subjects: ->(_connection) { %w[prospect account].map { |val| [val.labelize, val] } },
    task_actions: lambda do |_connection|
      %w[action_item call email in_person].map { |val| [val.labelize, val] }
    end,
    share_types: lambda do |_connection|
      %w[private read_only shared].map { |val| [val.labelize, val] }
    end,
    sequence_types: ->(_connection) { %w[date interval].map { |val| [val.labelize, val] } },
    interval_types: ->(_connection) { %w[calendar schedule].map { |val| [val.labelize, val] } },
    reply_actions: ->(_connection) { %w[finish continue pause].map { |val| [val.labelize, val] } },
    opt_statuses: lambda do |_connection|
      %w[opted_in opted_out null].map { |val| [val.labelize, val] }
    end,
    mailing_states: lambda do |_connection|
      %w[bounced delivered delivering drafted failed opened placeholder
         queued replied scheduled].map { |val| [val.labelize, val] }
    end,
    thread_statuses: lambda do |_connection|
      %w[pending sent skipped].map { |val| [val.labelize, val] }
    end,
    mailing_types: lambda do |_connection|
      %w[sequence single campaign].map { |val| [val.labelize, val] }
    end,
    call_types: lambda do |_connection|
      [
        %w[Bridge bridge],
        %w[VoIP voip]
      ]
    end,
    outcome_type: lambda do |_connection|
      [
        %w[Answered Answered],
        %w[Not\ Answered Not\ Answered]
      ]
    end,
    sequence_actions: lambda do |_connection|
      [
        %w[Advance Advance],
        %w[Finish Finish],
        ['Finish No Reply', 'Finish - No Reply'],
        ['Finish - Replied', 'Finish - Replied']
      ]
    end,
    search_object_list: lambda do |_connection|
      %w[account call event mailing mailbox profile prospect sequence
         sequenceState task user].map { |val| [val.labelize, val] }
    end,
    get_object_list: lambda do |_connection|
      %w[account call mailbox prospect sequence sequenceStep
         sequenceTemplate user].map { |val| [val.labelize, val] }
    end,
    create_object_list: lambda do |_connection|
      %w[account prospect sequence sequenceStep task user].map { |val| [val.labelize, val] }
    end,
    update_object_list: lambda do |_connection|
      %w[account prospect user].map { |val| [val.labelize, val] }
    end,
    new_object_list: lambda do |_connection|
      %w[account mailing prospect sequence task].map { |val| [val.labelize, val] }
    end,
    new_updated_object_list: lambda do |_connection|
      %w[account mailing prospect sequence task].map { |val| [val.labelize, val] }
    end,
    field_names: lambda do |_connection, object:|
      {
        'account' =>
          %w[createdAt customId description domain engagementScore externalSource followers foundedAt
             industry linkedInEmployees linkedInUrl locality name named naturalName employees
             numberOfEmployees tags touchedAt updatedAt websiteUrl custom1 custom2 custom3 custom4
             custom5 custom6 custom7 custom8 custom9 custom10 custom11 custom12 custom13 custom14
             custom15 custom16 custom17 custom18 custom19 custom20 custom21 custom22 custom23 custom24
             custom25 custom26 custom27 custom28 custom29 custom30 custom31 custom32 custom33 custom34
             custom35 custom36 custom37 custom38 custom39 custom40 custom41 custom42 custom43 custom44
             custom45 custom46 custom47 custom48 custom49 custom50 custom51 custom52 custom53 custom54
             custom55 custom56 custom57 custom58 custom59 custom60 custom61 custom62 custom63 custom64
             custom65 custom66 custom67 custom68 custom69 custom70 custom71 custom72 custom73 custom74
             custom75 custom76 custom77 custom78 custom79 custom80 custom81 custom82 custom83 custom84
             custom85 custom86 custom87 custom88 custom89 custom90 custom91 custom92 custom93 custom94
             custom95 custom96 custom97 custom98 custom99 custom100].map { |val| [val.labelize, val] },
        'call' =>
          %w[answeredAt completedAt createdAt dialedAt direction externalVendor from note outcome
             recordingUrl returnedAt sequenceAction shouldRecordCall state stateChangedAt tags to
             uid updatedAt userCallType voicemailRecordingUrl].map { |val| [val.labelize, val] },
        'event' =>
          %w[body createdAt eventAt externalUrl mailingId name requestCity requestDevice requestHost
             requestProxied requestRegion].map { |val| [val.labelize, val] },
        'mailing' =>
          %w[bodyHtml bodyText bouncedAt clickCount clickedAt createdAt deliveredAt errorBacktrace
             errorReason followUpTaskScheduledAt followUpTaskType mailboxAddress mailingType
             markedAsSpamAt messageId notifyThreadCondition notifyThreadScheduledAt notifyThreadStatus
             openCount openedAt overrideSafetySettings repliedAt retryAt retryCount retryInterval
             scheduledAt state stateChangedAt subject trackLinks trackOpens unsubscribedAt updatedAt].
            map { |val| [val.labelize, val] },
        'mailbox' =>
          %w[authId createdAt editable email emailProvider emailSignature ewsEndpoint
             ewsSslVerifyMode exchangeVersion imapHost imapPort imapSsl maxEmailsPerDay
             maxMailingsPerDay maxMailingsPerWeek optOutMessage optOutSignature prospectEmailExclusions
             providerId providerType sendDisabled sendErroredAt sendMaxRetries sendMethod sendPeriod
             sendRequiresSync sendSuccessAt sendThreshold sendgridWebhookUrl smtpHost smtpPort
             smtpSsl smtpUsername syncActiveFrequency syncDisabled syncErroredAt syncFinishedAt
             syncMethod syncOutreachFolder syncPassiveFrequency syncSuccessAt updatedAt userId
             username].map { |val| [val.labelize, val] },
        'profile' =>
          %w[createdAt isAdmin name updatedAt].map { |val| [val.labelize, val] },
        'prospect' =>
          %w[createdAt dateOfBirth degree emailOptedOut emails emailsOptStatus emailsOptedAt engagedAt
             engagedScore eventName externalId externalOwner externalSource facebookUrl firstName
             gender githubUrl githubUsername googlePlusUrl graduationDate homePhones jobStartDate
             lastName linkedInConnections linkedInId linkedInSlug linkedInUrl middleName mobilePhones
             name nickname occupation openCount optedOut optedOutAt otherPhones personalNote1
             personalNote2 preferredContact quoraUrl region replyCount school score smsOptStatus
             smsOptedAt smsOptedOut source specialties stackOverflowId stackOverflowUrl tags timeZone
             timeZoneIana timeZoneInferred title touchedAt twitterUrl twitterUsername updatedAt
             voipPhones websiteUrl1 websiteUrl2 websiteUrl3 workPhones custom1 custom2 custom3 custom4
             custom5 custom6 custom7 custom8 custom9 custom10 custom11 custom12 custom13 custom14
             custom15 custom16 custom17 custom18 custom19 custom20 custom21 custom22 custom23 custom24
             custom25 custom26 custom27 custom28 custom29 custom30 custom31 custom32 custom33 custom34
             custom35 custom36 custom37 custom38 custom39 custom40 custom41 custom42 custom43 custom44
             custom45 custom46 custom47 custom48 custom49 custom50 custom51 custom52 custom53 custom54
             custom55 custom56 custom57 custom58 custom59 custom60 custom61 custom62 custom63 custom64
             custom65 custom66 custom67 custom68 custom69 custom70 custom71 custom72 custom73 custom74
             custom75 custom76 custom77 custom78 custom79 custom80 custom81 custom82 custom83 custom84
             custom85 custom86 custom87 custom88 custom89 custom90 custom91 custom92 custom93 custom94
             custom95 custom96 custom97 custom98 custom99 custom100].map { |val| [val.labelize, val] },
        'sequence' =>
          %w[automationPercentage bounceCount clickCount createdAt deliverCount description
             durationInDays enabled enabledAt failureCount finishOnReply lastUsedAt locked lockedAt
             maxActivations name negativeReplyCount neutralReplyCount numContactedProspects
             numRepliedProspects openCount optOutCount positiveReplyCount primaryReplyAction
             primaryReplyPauseDuration replyCount scheduleCount scheduleIntervalType
             secondaryReplyAction secondaryReplyPauseDuration sequenceStepCount sequenceType
             shareType tags throttleCapacity throttleMaxAddsPerDay throttlePaused throttlePausedAt
             transactional updatedAt].map { |val| [val.labelize, val] },
        'sequenceState' =>
          %w[activeAt bounceCount callCompletedAt clickCount createdAt deliverCount errorReason
             failureCount negativeReplyCount neutralReplyCount openCount optOutCount pauseReason
             positiveReplyCount repliedAt replyCount scheduleCount state stateChangedAt].
            map { |val| [val.labelize, val] },
        'task' =>
          %w[action autoskipAt compiledSequenceTemplateHtml completed completedAt createdAt dueAt
             note scheduledAt state stateChangedAt taskType updatedAt].map { |val| [val.labelize, val] },
        'user' =>
          %w[bounceWarningEmailEnabled bridgePhone bridgePhoneExtension controlledTabDefault
             createdAt currentSignInAt custom1 custom2 custom3 custom4 custom5 dailyDigestEmailEnabled
             email enableVoiceRecordings firstName inboundBridgePhone inboundBridgePhoneExtension
             inboundCallBehavior inboundPhoneType inboundVoicemailCustomMessageText
             inboundVoicemailMessageTextVoice inboundVoicemailPromptType keepBridgePhoneConnected
             lastName lastSignInAt locked mailboxErrorEmailEnabled name notificationsEnabled
             oceClickToDialEverywhere oceGmailToolbar oceGmailTrackingState oceSalesforceEmailDecorating
             oceSalesforcePhoneDecorating oceUniversalTaskFlow oceWindowMode onboardedAt passwordExpiresAt
             phoneCountryCode phoneNumber phoneType preferredVoiceRegion prefersLocalPresence
             prospectsViewId senderNotificationsExcluded skuProspectsIndexPageV2 textingEmailNotifications
             title unknownReplyEmailEnabled updatedAt username weeklyDigestEmailEnabled].map { |val| [val.labelize, val] }
      }[object]
    end,
    sequences: lambda do |_connection|
      response = get('/api/v2/sequences').params(page: { limit: 100 })
      items = response['data']
      next_link = response&.dig('links', 'next')
      while next_link.present?
        response = get(next_link)
        next_link = response&.dig('links', 'next')
        response['data'].each do |item|
          items << item
        end
      end

      items&.map do |sequence|
        [sequence.dig('attributes', 'name'), sequence['id'].to_s]
      end
    end,
    sequence_steps: lambda do |_connection, sequence_id:|
      get('/api/v2/sequenceSteps').
        params({ filter: { sequence: { id: sequence_id } } })['data'].
        map { |step| [step.dig('attributes', 'displayName'), step['id'].to_s] }
    end,
    mailboxes: lambda do |_connection|
      get('/api/v2/mailboxes')['data'].map do |mailbox|
        [mailbox.dig('attributes', 'username'), mailbox['id'].to_s]
      end
    end,
    users: lambda do |_connection|
      get('/api/v2/users')['data'].
        reject { |user| user.dig('attributes', 'locked') }.
        map { |user| [user.dig('attributes', 'name'), user['id'].to_s] }
    end,
    accounts: lambda do |_connection|
      get('/api/v2/accounts')['data'].
        map { |account| [account.dig('attributes', 'name'), account['id'].to_s] }
    end,
    roles: lambda do |_connection|
      get('/api/v2/roles')['data'].map do |item|
        [item.dig('attributes', 'name'), item['id'].to_s]
      end
    end,
    profiles: lambda do |_connection|
      get('/api/v2/profiles')['data'].map do |item|
        [item.dig('attributes', 'name'), item['id'].to_s]
      end
    end,
    task_priorities: lambda do |_connection|
      get('/api/v2/taskPriorities')['data'].map do |priority|
        [priority.dig('attributes', 'name'), priority['id'].to_s]
      end
    end,
    sequence_state_statuses: lambda do |_connection|
      %w[pending active paused failed bounced opted_out finished].map { |val| [val.labelize, val] }
    end
  }
}
