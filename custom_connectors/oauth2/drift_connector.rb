{
  title: 'Drift',

  connection: {
    fields: [
      {
        name: 'client_id',
        type: 'string',
        hint: 'Create a new app to generate client id and secret. ' \
        "click <a href='https://dev.drift.com/apps' target='_blank'>here</a> to create app.",
        optional: false
      },
      {
        name: 'client_secret',
        control_type: 'password',
        type: 'string',
        hint: 'Create a new app to generate client id and secret. ' \
        "click <a href='https://dev.drift.com/apps' target='_blank'>here</a> to create app.",
        optional: false
      },
      {
        name: 'verification_token',
        control_type: 'password',
        type: 'string',
        hint: 'Use verification token to receive interactive messages, click' \
        "<a href='https://devdocs.drift.com/docs/" \
        "webhook-events-1#section-verification-token' target= '_blank'>here" \
        '</a> to find verification token.',
        optional: true
      }
    ],
    authorization: {
      type: 'oauth2',
      authorization_url: lambda do |connection|
        'https://dev.drift.com/authorize?response_type=code&' \
        "client_id=#{connection['client_id']}" \
      end,
      acquire: lambda do |connection, auth_code, redirect_uri|
        post('https://driftapi.com/oauth2/token').
          payload(client_id: connection['client_id'],
                  client_secret: connection['client_secret'],
                  grant_type: 'authorization_code',
                  code: auth_code,
                  redirect_uri: redirect_uri).
          request_format_www_form_urlencoded
      end,
      refresh: lambda do |connection, refresh_token|
        post('https://driftapi.com/oauth2/token').
          payload(client_id: connection['client_id'],
                  client_secret: connection['client_secret'],
                  grant_type: 'refresh_token',
                  refresh_token: refresh_token).
          request_format_www_form_urlencoded
      end,

      refresh_on: [401, 403],
      apply: lambda do |_connection, access_token|
        headers(Authorization: "Bearer #{access_token}")
      end
    },
    base_uri: lambda {
      'https://driftapi.com'
    }
  },

  test: lambda { |_connection|
    get('/users/list')
  },

  methods: {
    contact_attributes_schema: lambda do |_input|
      attributes =
        get('/contacts/attributes')&.dig('data', 'properties')&.map do |attribute|
          field = {
            name: attribute['name'],
            label: attribute['name'].labelize,
            sticky: true
          }
          case attribute['type']
          when 'BOOLEAN'
            { type: 'boolean', control_type: 'checkbox',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: attribute['name'],
                label: attribute['name'].labelize,
                type: 'string',
                optional: true,
                control_type: 'boolean',
                render_input: 'boolean_conversion',
                parse_output: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false.'
              } }
          when 'DATE'
            { type: 'date' }
          when 'DATETIME'
            { type: 'date_time' }
          when 'NUMERIC'
            { type: 'number' }
          else
            {}
          end&.merge(field)
        end
      attributes.concat(
        [
          { name: '_end_user_version', label: 'End user version', type: 'integer' },
          { name: '_calculated_version', label: 'Calculated version', type: 'integer' },
          { name: 'original_conversation_started_page_title' },
          { name: 'externalId' },
          { name: 'tags', type: 'array', of: 'object',
            properties: [
              { name: 'name',
                hint: 'The display name of the Tag. This is effectively a key for the Tag.' },
              { name: 'color', hint: 'Hexadecimal color for the Tag.' }
            ] },
          { name: 'events', type: 'object' },
          {
            name: 'socialProfiles', type: 'object',
            properties: [
              {
                name: 'indexedAt',
                type: 'date_time'
              },
              {
                name: 'github',
                type: 'object',
                properties: [
                  { name: 'handle' },
                  { name: 'id' },
                  { name: 'avatar' },
                  { name: 'company' },
                  { name: 'blog' },
                  { name: 'followers' },
                  { name: 'following' }
                ]
              },
              {
                name: 'facebook',
                type: 'object',
                properties: [
                  { name: 'handle' }
                ]

              },
              {
                name: 'employment',
                type: 'object',
                properties: [
                  { name: 'domain' },
                  { name: 'name' },
                  { name: 'title' },
                  { name: 'role' },
                  { name: 'seniority' }
                ]
              },
              {
                name: 'linkedin',
                type: 'object',
                properties: [
                  { name: 'handle' }
                ]
              },
              {
                name: 'aboutme',
                type: 'object',
                properties: [
                  { name: 'handle' },
                  { name: 'bio' },
                  { name: 'avatar' }
                ]
              },
              {
                name: 'geo',
                label: 'GEO location',
                type: 'object',
                properties: [
                  { name: 'city' },
                  { name: 'state' },
                  { name: 'stateCode' },
                  { name: 'country' },
                  { name: 'countryCode' },
                  { name: 'lat',
                    label: 'Latitude',
                    type: 'integer' },
                  { name: 'lng',
                    label: 'Longitude',
                    type: 'integer' }
                ]
              },
              {
                name: 'twitter',
                type: 'object',
                properties: [
                  { name: 'handle' },
                  { name: 'id' },
                  { name: 'bio',
                    label: 'Biography' },
                  { name: 'followers' },
                  { name: 'following' },
                  { name: 'statuses' },
                  { name: 'favorites' },
                  { name: 'location' },
                  { name: 'site' },
                  { name: 'avatar' }
                ]
              },
              { name: 'activeAt',
                type: 'date_time' },
              {
                name: 'emailProvider',
                type: 'boolean',
                control_type: 'checkbox',
                label: 'Email provider',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'emailProvider',
                  label: 'Email provider',
                  type: 'boolean',
                  control_type: 'text',
                  hint: 'Allowed values are: true, false',
                  toggle_hint: 'Use custom value'
                }
              },
              {
                name: 'gravatar',
                label: 'Gravatar',
                type: 'object',
                properties: [
                  { name: 'handle' },
                  { name: 'urls' },
                  { name: 'avatar' }
                ]
              },
              {
                name: 'name',
                type: 'object',
                properties: [
                  { name: 'fullName' },
                  { name: 'givenName' },
                  { name: 'familyName' }
                ]
              },
              { name: 'id' },
              {
                control_type: 'email',
                name: 'email'
              },
              {
                name: 'fuzzy',
                label: 'Fuzzy',
                type: 'boolean',
                control_type: 'checkbox',
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'fuzzy',
                  type: 'boolean',
                  optional: true,
                  control_type: 'text',
                  label: 'Fuzzy',
                  toggle_hint: 'Use custom value',
                  hint: 'Allowed values are: true, false'
                }
              },
              {
                name: 'googleplus',
                type: 'object',
                properties: [
                  { name: 'handle' }
                ]
              }
            ]

          }
        ]
      )
    end,

    get_contact_schema: lambda do |_input|
      [
        {
          name: 'id',
          control_type: 'integer',
          type: 'integer',
          label: 'Contact ID',
          optional: false
        },
        {
          name: 'createdAt',
          control_type: 'date_time',
          type: 'date_time'
        },
        {
          name: 'attributes',
          type: 'object',
          properties: call('contact_attributes_schema', '').
            ignored('_end_user_version', '_calculated_version', 'original_conversation_started_page_title')
        }
      ]
    end,

    get_contact_tag_schema: lambda do |_input|
      [
        { name: 'name' },
        { name: 'color' }
      ]
    end,

    get_message_schema: lambda do |_input|
      [
        {
          name: 'id',
          label: 'Message ID',
          type: 'integer',
          control_type: 'number',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          hint: 'A unique identifier for the message.'
        },
        {
          name: 'orgId',
          type: 'integer',
          control_type: 'number',
          label: 'Organization ID',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion'
        },
        {
          name: 'author',
          label: 'Author',
          type: 'object',
          hint: 'An object describing who authored this Message.',
          properties: [
            {
              control_type: 'number',
              parse_output: 'float_conversion',
              type: 'integer',
              name: 'id',
              optional: false
            },
            {
              control_type: 'select',
              name: 'type',
              pick_list: [
                %w[Contact contact],
                %w[User user]
              ],
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'type',
                label: 'Type',
                optional: true,
                type: 'string',
                control_type: 'text',
                hint: 'Allowed values: user, contact',
                toggle_hint: 'Use custom value'
              }
            },
            { name: 'bot', type: 'boolean' }
          ]
        },
        { name: 'body',
          sticky: true,
          hint: 'The text contents of this message.' },
        {
          control_type: 'select',
          label: 'Type',
          name: 'type',
          hint: 'Specifies the type of this message.',
          pick_list: [
            %w[Chat chat],
            ['Private note', 'private_note'],
            ['Private prompt', 'private_prompt'],
            %w[Edit edit]
          ],
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'type',
            type: 'string',
            label: 'Type',
            control_type: 'text',
            hint: 'Allowed values: private_note, private_prompt,' \
              ' chat and edit.',
            toggle_hint: 'Use custom value'
          }
        },
        {
          control_type: 'number',
          label: 'Conversation ID',
          hint: 'The ID field of the conversation this message is a part of.',
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          type: 'integer',
          name: 'conversationId'
        },
        {
          control_type: 'date_time',
          type: 'date_time',
          name: 'createdAt'
        },
        {
          name: 'attachment',
          type: 'array',
          of: 'object',
          label: 'Attachment',
          properties: [
            { name: 'fileName' },
            {
              label: 'MIME type',
              name: 'mimeType'
            },
            {
              control_type: 'url',
              label: 'URL',
              name: 'url'
            }
          ]
        },
        {
          name: 'buttons',
          type: 'array',
          sticky: true,
          of: 'object',
          properties: [
            { name: 'value',
              sticky: true,
              hint: 'For <b>Reply</b> type buttons, value must equal <b>Label</b>. <br> In <b>Compose</b> types, ' \
                "value is what is entered into the User's composer. <br> In <b>Action</b> types, value should be a " \
                'slug that identifies the sort of action intended by the button click; this is interpreted ' \
                'by an App to properly react to a button click.' },
            { name: 'label',
              sticky: true,
              hint: 'For all button types, the <b>Label</b> field is what is actually displayed as a ' \
                'label on the button to the <b>User</b> or <b>Contact</b>.' },
            { control_type: 'select',
              label: 'Type',
              name: 'type',
              sticky: true,
              hint: '<b>Reply</b> type buttons cause the text in the button to be immediately used as a new chat ' \
                'message by the contact when pressed. <b>Reply</b> type buttons are only ever rendered to contacts' \
                '(Users will only see the body of the message.) and are the only type allowed in chat messages. <br> ' \
                "<br> <b>Compose</b> type buttons cause text be added to a user's conversation composer. A user can " \
                'then edit the message before they get sent. They are only allowed in private_prompt Messages. <br> ' \
                '<br> <b>Action</b> type buttons signal a button click to Apps via their webhook. ' \
                'They are only allowed in private prompt messages.',
              pick_list: [
                %w[Reply reply],
                %w[Compose compose],
                %w[Action action]
              ],
              toggle_hint: 'Select from option list',
              toggle_field: {
                name: 'type',
                type: 'string',
                optional: true,
                label: 'Type',
                control_type: 'text',
                hint: 'Allowed values: reply, compose, and action.',
                toggle_hint: 'Use custom value'
              } },
            { control_type: 'select',
              label: 'Style',
              name: 'style',
              sticky: true,
              hint: 'This is only applicable to buttons within <b>private prompt</b> messages. <br> When the value is' \
                ' <b>Primary</b>, the button is rendered as <b>green with white text</b>. <br> When the value is ' \
                "<b>Danger</b>, the button is rendered as <b>red with white text</b>. <br> If style isn't specified, " \
                'a style fitting with the overall design of the Drift UI is used.',
              pick_list: [
                %w[Primary primary],
                %w[Danger danger]
              ],
              toggle_hint: 'Select from option list',
              toggle_field: {
                name: 'style',
                type: 'string',
                optional: true,
                label: 'Style',
                control_type: 'text',
                hint: 'Allowed values: primary and danger.',
                toggle_hint: 'Use custom value'
              } },
            { name: 'reaction',
              type: 'object',
              sticky: true,
              hint: 'A <b>Reaction</b> can be specified to automatically cause a visual change when a button ' \
                'is pressed. <br> If <b>Reaction type</b> is <b>Delete</b>, the message containing the button ' \
                'is (visually) deleted when the button is hit. <br> If <b>Reaction type</b> is <b>Replace</b>, ' \
                'the message is replaced with one containing only a message body set to the value of ' \
                '<b>Reaction message</b>. If the type is replace, <b>Reaction message</b> must be specified.',
              properties: [
                { control_type: 'select',
                  label: 'Type',
                  name: 'type',
                  sticky: true,
                  pick_list: [
                    %w[Replace replace],
                    %w[Delete delete]
                  ],
                  toggle_hint: 'Select from option list',
                  toggle_field: {
                    name: 'type',
                    type: 'string',
                    optional: true,
                    label: 'Type',
                    control_type: 'text',
                    hint: 'Allowed values: replace and delete.',
                    toggle_hint: 'Use custom value'
                  } },
                { name: 'message',
                  sticky: true }
              ] }
          ]
        },
        {
          properties: [
            { label: 'IP adress', name: 'ip' },
            { name: 'userAgent' },
            { name: 'title' },
            { name: 'referrer' },
            { name: 'timezone' },
            {
              properties: [
                { name: 'city' },
                { name: 'region' },
                { name: 'country' },
                { name: 'countryName' },
                { name: 'postalCode' },
                {
                  control_type: 'number',
                  parse_output: 'float_conversion',
                  type: 'number',
                  name: 'latitude'
                },
                {
                  control_type: 'number',
                  parse_output: 'float_conversion',
                  type: 'number',
                  name: 'longitude'
                }
              ],
              type: 'object',
              name: 'location'
            },
            { name: 'locale' }
          ],
          type: 'object',
          name: 'context'
        },
        {
          control_type: 'integer',
          label: 'Edited message ID',
          hint: 'Specifies the ID of the message being edited.',
          sticky: true,
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion',
          type: 'integer',
          name: 'editedMessageId'
        },
        {
          control_type: 'select',
          label: 'Edit type',
          hint: 'Specifies the type of edit to be performed. ' \
            "Click <a href='https://devdocs.drift.com/docs/message-model' target='_blank'>here</a> to learn more.",
          sticky: true,
          name: 'editType',
          pick_list: [
            %w[Delete delete],
            %w[Replace replace],
            ['Replace body', 'replace_body'],
            ['Replace buttons', 'replace_buttons']
          ],
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'type',
            type: 'string',
            label: 'Edit type',
            optional: true,
            control_type: 'string',
            hint: 'Allowed values: delete, replace, replace_body, ' \
              'and replace_buttons.',
            toggle_hint: 'Use custom value'
          }
        },
        {
          name: 'attributes',
          type: 'object',
          properties: [
            { name: 'preMessages', type: 'object', properties: [] },
            { name: 'developer_app_id' }
          ]
        },
        { name: 'userId',
          sticky: true,
          hint: 'If userId not specified, the bot user for the account ' \
            'will be used as the message author.' }
      ]
    end,

    get_conversation_schema: lambda do |_input|
      [
        {
          name: 'id',
          control_type: 'number',
          type: 'integer',
          hint: 'Conversations are uniquely identified by an id, which can be' \
          ' used to check its current state and its messages.'
        },
        {
          name: 'orgId',
          type: 'integer',
          control_type: 'number',
          label: 'Organization ID'
        },
        {
          name: 'participants',
          type: 'array',
          of: 'integer'
        },
        {
          name: 'status',
          control_type: 'select',
          toggle_hint: 'Select from list',
          pick_list: 'status_list',
          toggle_field: {
            name: 'status',
            label: 'Status',
            optional: true,
            control_type: 'string',
            type: 'string',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values: open, closed, pending'
          }
        },
        {
          name: 'contactId',
          type: 'integer',
          control_type: 'number',
          parse_output: 'integer_conversion'
        },
        {
          name: 'createdAt',
          type: 'date_time',
          control_type: 'date_time',
          label: 'Created at',
          render_input: 'integer_conversion',
          parse_output: 'date_time_conversion'
        },
        {
          name: 'updatedAt',
          type: 'date_time',
          control_type: 'date_time',
          render_input: 'integer_conversion',
          parse_output: 'date_time_conversion'
        },
        {
          name: 'inboxId',
          type: 'integer',
          control_type: 'number'
        },
        { name: 'conversationTags', type: 'array', of: 'object',
          properties: [
            { name: 'color' },
            { name: 'name' }
          ] },
        { name: 'relatedPlaybookId',
          label: 'Related playbook ID',
          hint: 'This is the ID of the playbook that initiated the ' \
            'conversation.' }
      ]
    end,

    get_user_schema: lambda do |_input|
      [
        {
          label: 'User ID',
          type: 'integer',
          name: 'id',
          hint: 'The Drift identifier for the user. This is will always be numeric.'
        },
        {
          label: 'Organization ID',
          type: 'integer',
          name: 'orgId',
          optional: false
        },
        { name: 'name', hint: 'The name of the user.', sticky: true },
        { name: 'alias', hint: 'The alias of the user.', sticky: true },
        { name: 'email', control_type: 'email', hint: 'The email address of the user.', sticky: true },
        {
          name: 'availability',
          sticky: true,
          control_type: 'select',
          pick_list: [
            %w[Available AVAILABLE],
            %w[Offline OFFLINE]
          ],
          toggle_hint: 'Select from option list',
          toggle_field: {
            type: 'string',
            name: 'availability',
            label: 'Availability',
            optional: true,
            control_type: 'string',
            hint: 'Allowed values: AVAILABLE, OFFLINE',
            toggle_hint: 'Use custom value'
          }
        },
        { name: 'role', control_type: 'select',
          pick_list: 'roles_list',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'role',
            type: 'string',
            optional: true,
            control_type: 'text',
            label: 'Role',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values: member, admin, and agent. '
          } },
        { name: 'timeZone' },
        { name: 'avatarUrl', sticky: true, hint: 'The URL pointing to the avatar image of the user.' },
        { name: 'phone', control_type: 'phone', label: 'Phone number', sticky: true,
          hint: 'Enter phone number in the form of XXX-XXX-XXXX.' },
        {
          name: 'verified',
          type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'verified',
            type: 'boolean',
            optional: true,
            control_type: 'text',
            label: 'Verified',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values: true, false'
          }
        },
        {
          name: 'bot',
          type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'bot',
            type: 'boolean',
            optional: true,
            label: 'Bot',
            control_type: 'boolean',
            hint: 'Allowed values: true, false',
            toggle_hint: 'Use custom value'
          }
        },
        {
          name: 'createdAt',
          control_type: 'date_time',
          label: 'Created time',
          type: 'date_time'
        },
        {
          name: 'updatedAt',
          label: 'Updated time',
          type: 'date_time',
          control_type: 'date_time'
        }
      ]
    end,

    get_account_schema: lambda do |_input|
      [
        { name: 'ownerId',
          sticky: true,
          hint: 'The ID of the owner in Drift (should be a known user ID).' },
        { name: 'name', label: 'Company name', sticky: true },
        { name: 'domain', sticky: true, label: 'Domain name' },
        { name: 'accountId', sticky: true },
        { name: 'deleted', type: 'boolean', control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'deleted',
            type: 'string',
            optional: true,
            label: 'Deleted',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values: true, false'
          } },
        { name: 'createDateTime', type: 'date_time' },
        { name: 'updateDateTime', type: 'integer' },
        { name: 'targeted', type: 'boolean', control_type: 'checkbox',
          hint: 'Is the account currently targeted.',
          sticky: true,
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'targeted',
            type: 'string',
            optional: true,
            label: 'Targeted',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values: true, false'
          } },
        { name: 'customProperties', type: 'array', of: 'object', sticky: true,
          properties: [
            { name: 'label', sticky: true,
              hint: 'The readable name of the property.' },
            { name: 'name', sticky: true,
              hint: 'The internal name of the property.' },
            { name: 'value', sticky: true,
              hint: 'The value of the property.' },
            { name: 'type', sticky: true,
              control_type: 'select',
              pick_list: 'data_types',
              toggle_hint: 'Select data type',
              toggle_field: {
                name: 'type',
                type: 'Type',
                optional: true,
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values: ' \
                  'STRING, EMAIL, NUMBER, TEAMMEMBER, ENUM, DATE, DATETIME, ' \
                  'LATLON, LAT, LON, PHONE, URL and ENUMARRAY.'
              },
              hint: 'Data type of the property.' }
          ] }
      ]
    end,

    get_playbook_schema: lambda do |_input|
      [
        { name: 'id', type: 'integer', label: 'Playbook ID' },
        { name: 'name' },
        { name: 'orgId', type: 'integer', label: 'Organization ID' },
        { name: 'meta', type: 'object' },
        { name: 'createdAt', type: 'date_time' },
        { name: 'updatedAt', type: 'date_time' },
        { name: 'createdAuthorId', type: 'integer',
          hint: 'ID of the user that created the playbook' },
        { name: 'updatedAuthorId', type: 'integer',
          hint: 'ID of the user that last updated the playbook' },
        { name: 'interactionId', type: 'integer' },
        { name: 'reportType' },
        { name: 'goals', type: 'array', of: 'object', properties: [
          { name: 'id', label: 'Goal ID' },
          { name: 'message' }
        ] }
      ]
    end,

    get_meeting_schema: lambda do |_input|
      [
        { name: 'agentId', type: 'integer' },
        { name: 'orgId', type: 'integer', label: 'Organization identifier' },
        { name: 'status', hint: 'e.g. "ACTIVE", state of the meeting' },
        { name: 'meetingSource',
          hint: 'e.g. "EMAIL_DROP", source of where the meeting was booked' },
        { name: 'schedulerId', type: 'integer' },
        { name: 'eventId' },
        { name: 'slug' },
        { name: 'slotStart', type: 'date_time',
          label: 'Slot start date' },
        { name: 'slotEnd', type: 'date_time',
          label: 'Slot end date' },
        { name: 'updatedAt', type: 'date_time' },
        { name: 'scheduledAt', type: 'date_time' },
        { name: 'meetingType',
          hint: 'e.g. "New Meeting", stating the type of the meeting.' },
        { name: 'conversationId', type: 'integer' },
        { name: 'endUserTimeZone' },
        { name: 'meetingNotes' },
        { name: 'bookedBy', hint: 'Drift identifier for the user if present.' },
        { name: 'eventType' }
      ]
    end,

    get_command_message_schema: lambda do |_input|
      [
        { name: 'orgId', type: 'integer', label: 'Organization ID' },
        { name: 'type' },
        { name: 'Message', type: 'object', properties: call('get_message_schema') }
      ]
    end,

    get_timeline_schema: lambda do |_input|
      [
        { name: 'contactId', type: 'integer', sticky: true,
          hint: 'Either <b>Contact ID</b> or <b>External ID</b> must be present.' },
        { name: 'createdAt', type: 'date_time', sticky: true,
          hint: 'CreatedAt time can be excluded from the request (will default to the time of send).' },
        { name: 'externalId', type: 'integer', sticky: true,
          hint: 'Either <b>Contact ID</b> or <b>External ID</b> must be present.' },
        { name: 'event', sticky: true,
          hint: 'Example: "New External Event from <\your app\>"' },
        { name: 'attributes', type: 'array', of: 'object', properties: [
          { name: 'key' },
          { name: 'value' }
        ] }
      ]
    end,

    convert_input_to_date: lambda do |input|
      date_fields = %w[start_date last_active last_contacted scheduledAt slotStart
                       slotEnd updatedAt indexedAt createdAt createDateTime updateDateTime]
      if input.is_a?(Array)
        input.map do |array_value|
          call('convert_input_to_date', array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call('convert_input_to_date', value)
          if date_fields.include?(key)
            { key => (value.to_i / 1000).to_i.to_time.utc }
          else
            { key => value }
          end
        end.inject(:merge)
      else
        input
      end
    end,

    format_unix_to_utc_time: lambda do |input|
      date_fields = %w[start_date last_active last_contacted scheduledAt slotStart timestamp
                       slotEnd updatedAt indexedAt createdAt createDateTime updateDateTime]
      if input.is_a?(Array)
        input.map do |array_value|
          call('format_unix_to_utc_time', array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call('format_unix_to_utc_time', value)
          if date_fields.include?(key)
            { key => (value.to_i / 1000).to_i.to_time.utc }
          else
            { key => value }
          end
        end.inject(:merge)
      else
        input
      end
    end,

    format_date_time_to_unix: lambda do |input|
      date_fields = %w[start_date last_active last_contacted scheduledAt slotStart slotEnd
                       updatedAt indexedAt createdAt createDateTime updateDateTime]
      if input.is_a?(Array)
        input.map do |array_value|
          call('format_date_time_to_unix', array_value)
        end
      elsif input.is_a?(Hash)
        input.map do |key, value|
          value = call('format_date_time_to_unix', value)
          if date_fields.include?(key)
            { key => value.to_i * 1000 }
          else
            { key => value }
          end
        end.inject(:merge)
      else
        input
      end
    end,

    search_contacts_schema: lambda do |_input|
      [
        { name: 'email', control_type: 'email', sticky: true },
        { name: 'externalID', sticky: true },
        { name: 'limit', type: 'integer', label: 'Page size', sticky: true,
          hint: 'Sets a maximum number of contacts returned.' }
      ]
    end,

    search_conversations_schema: lambda do |_input|
      [
        {
          name: 'statusId',
          type: 'string',
          control_type: 'multiselect',
          pick_list_params: {},
          delimiter: ',',
          label: 'Status',
          sticky: true,
          toggle_hint: 'Select from list',
          pick_list: 'status_id_list',
          toggle_field: {
            name: 'statusId',
            label: 'Status IDs',
            control_type: 'string',
            type: 'string',
            sticky: true,
            toggle_hint: 'Use custom value',
            hint: 'Use comma separated list of statuses. Allowed values: 1 - Open, 2 - Closed, 3 - Pending'
          }
        },
        { name: 'limit', type: 'integer', sticky: true,
          hint: 'Maximum number of conversations to retrieve (maximum=50, default=25).' },
        { name: 'next', type: 'integer', sticky: true, label: 'Offset',
          hint: 'Retrieves open and closed conversations (after the cursor value 50): as' \
          ' in (statusId=1&statusId=2&next=50)' }
      ]
    end,

    search_accounts_schema: lambda do |_input|
      [
        { name: 'size', type: 'integer', label: 'Limit', sticky: true,
          hint: 'Maximum number of accounts to retrieve (maximum=100, default=10).' },
        { name: 'index', type: 'integer', label: 'Offset', sticky: true,
          hint: "Used as a starting index of the query of the accounts in the authenticated Drift user's account." }
      ]
    end,

    search_meetings_schema: lambda do |_input|
      [
        { name: 'min_start_time', type: 'date_time', optional: false,
          label: 'Minimum Start date' },
        { name: 'max_start_time', type: 'date_time', optional: false,
          label: 'Maximum Start date' }
      ]
    end,

    create_contacts_schema: lambda do |_input|
      call('contact_attributes_schema', '').required('email').
        ignored('_end_user_version', '_calculated_version', 'original_conversation_started_page_title',
                'externalId', 'tags', 'events', 'socialProfiles')
    end,

    create_conversations_schema: lambda do |_input|
      [
        { name: 'email',
          hint: 'The email address of the contact.',
          optional: false },
        { name: 'message', type: 'object',
          sticky: true, optional: false,
          properties: call('get_message_schema', '').
            only('userId', 'editType', 'buttons', 'editedMessageId', 'type', 'body').
            required('type').
            concat([{ name: 'attributes',
                      type: 'object',
                      properties: [{ name: 'integrationSource', sticky: true,
                                     hint: 'Example: "Message from facebook"' }] }]) }
      ]
    end,

    create_messages_schema: lambda do |_input|
      call('get_message_schema', '').
        only('userId', 'editType', 'buttons', 'editedMessageId', 'conversationId', 'type', 'body').
        required('type', 'conversationId')
    end,

    create_accounts_schema: lambda do |_input|
      call('get_account_schema', '').
        only('ownerId', 'name', 'domain', 'customProperties', 'targeted').
        required('ownerId')
    end,

    create_timeline_schema: lambda do |_input|
      call('get_timeline_schema', '').ignored('attributes')
    end,

    update_contacts_schema: lambda do |_input|
      call('get_contact_schema', '').
        ignored('createdAt').
        required('id', 'attributes')
    end,

    update_users_schema: lambda do |_input|
      call('get_user_schema', '').required('id').
        only('id', 'name', 'alias', 'email', 'phone', 'locale', 'avatarUrl', 'availability')
    end,

    update_accounts_schema: lambda do |_input|
      call('get_account_schema', '').
        only('ownerId', 'name', 'domain', 'customProperties', 'targeted', 'accountId').
        required('accountId', 'ownerId')
    end,

    make_schema_builder_fields_sticky: lambda do |input|
      input.map do |field|
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

    validate_search_criteria: lambda do |input|
      case input['object_name']
      when 'contacts'
        if input['email'].blank? && input['externalID'].blank?
          error('Provide atleast one search criteria')
        end
      when 'conversations'
        error('Provide statuses') unless input['statusId'].present?
      end
    end,

    format_request_payload: lambda do |input|
      case input['object_name']
      when 'contacts'
        if input['externalID'].present?
          {
            'idType' => 'external',
            'id' => input['externalID'],
            'email' => input['email'],
            'limit' => input['limit']
          }
        else
          {
            'email' => input['email'],
            'limit' => input['limit']
          }
        end
      when 'conversations'
        {
          'limit' => input['limit'],
          'next' => input['next']
        }
      when 'meetings'
        {
          'max_start_time' => input['max_start_time'].to_i * 1000,
          'min_start_time' => input['min_start_time'].to_i * 1000
        }
      else
        input
      end
    end,

    search_object_output: lambda do |input|
      case input[:object_name]
      when 'contacts'
        call('get_contact_schema', '')
      when 'users'
        call('get_user_schema', '')
      when 'accounts'
        call('get_account_schema', '')
      when 'conversations'
        call('get_conversation_schema', '')
      when 'playbooks'
        call('get_playbook_schema', '')
      when 'meetings'
        call('get_meeting_schema', '')
      else
        []
      end
    end,

    search_url: lambda do |input|
      case input['object_name']
      when 'users', 'playbooks'
        "/#{input['object_name']}/list"
      when 'meetings'
        "/users/#{input['object_name']}/org"
      when 'conversations'
        status_id = input['statusId']&.to_s&.split(',')&.smart_join('&statusId=')
        "/#{input['object_name']}/list?statusId=#{status_id}"
      else
        "/#{input['object_name']}"
      end
    end,

    sample_search_record: lambda do |input|
      response = get(call('sample_search_url', input))
      result = if input['object_name'] == 'playbooks'
                 response&.compact
               elsif input['object_name'] == 'accounts'
                 response.dig('data', 'accounts')
               else
                 response['data']
               end
      call('format_unix_to_utc_time', result)
    end,

    sample_search_url: lambda do |input|
      case input['object_name']
      when 'users', 'playbooks'
        "/#{input['object_name']}/list"
      when 'conversations'
        "/#{input['object_name']}/list?limit=1"
      when 'meetings'
        "/users/#{input['object_name']}/org?" \
        'min_start_time=0&max_start_time=15000000000000'
      when 'accounts'
        "/#{input['object_name']}?size=1"
      when 'contacts'
        if input['externalID'].present?
          "/#{input['object_name']}?idType=external&id=#{input['externalID']}" \
          "&limit=1&email=#{input['email']}"
        else
          "/#{input['object_name']}?limit=1&email=#{input['email']}"
        end
      else
        "/#{input['object_name']}"
      end
    end,

    sample_get_record: lambda do |input|
      response = get(call('sample_get_url', input))
      result = case input['object_name']
               when 'accounts'
                 response.dig('data', 'accounts', 0)
               when 'messages', 'new_message', 'new_command_message',
                    'button_clicked'
                 response.dig('data', 'messages', 0)
               when 'conversation_participant_added',
                    'conversation_participant_removed'
                 {
                   conversationId: '1485843811',
                   addedParticipants: '243266',
                   changedAt: '2020-01-07T09:41:23.000+00:00'
                 }
               when 'phone_captured'
                 {
                   conversationId: '1485843811',
                   authorId: '1883929',
                   authorType: 'contact',
                   phoneNumber: '555-444-6666'
                 }
               when 'conversation_inactive'
                 {
                   conversationId: '1485843811',
                   lastUpdated: '2020-01-07T09:41:23.000+00:00'
                 }
               when 'contact_updated'
                 {
                   'endUserId' => '13326063',
                   'timestamp' => '1575264348541',
                   'diff': [
                     {
                       'name' => 'attributes.alias',
                       'previous' => 'null',
                       'updated' => 'nadine'
                     }
                   ]
                 }
               when 'user_availability_updated'
                 {
                   userId: '1894929',
                   updatedAt: '2020-01-07T09:41:23.000+00:00',
                   availability: 'ONLINE'
                 }
               when 'playbook_goal_met'
                 {
                   conversationId: '1485843811',
                   playbookId: '1561966',
                   contactId: '4213856715',
                   goalId: '42fe19bf-b3f4-44c6-b358-1934dc69a614',
                   goalName: 'Goal name',
                   playbookName: 'New welcome message',
                   contactEmail: 'test@test.com'
                 }
               when 'contacts', 'user_unsubscribed', 'contact_identified'
                 {
                   'attributes' => {
                     'email' => 'swebel@drift.com',
                     'name' => 'Stephen Webel',
                     'externalId' => '12341243'
                   },
                   'createdAt' => '1575264348541',
                   'id' => '349999553'
                 }
               when 'timeline'
                 {
                   event: 'test event from workato',
                   externalId: '13326063',
                   createdAt: '2020-01-09T16:00:00.000000+00:00',
                   contactId: '4489629008'
                 }
               when 'meeting_updated', 'new_meeting'
                 [{ eventType: 'canceled/rescheduled',
                    conversationId: '1485843811' }].concat([response.dig('data', 0)]).inject(:merge)
               else
                 response.dig('data', 0)
               end
      call('format_unix_to_utc_time', result)
    end,

    sample_get_url: lambda do |input|
      case input['object_name']
      when 'users'
        "/#{input['object_name']}/list"
      when 'conversations', 'new_conversation'
        '/conversations/list?limit=1'
      when 'accounts'
        "/#{input['object_name']}?size=1"
      when 'meetings', 'new_meeting', 'meeting_updated'
        '/users/meetings/org?' \
        'min_start_time=0&max_start_time=15000000000000'
      when 'messages', 'new_message', 'new_command_message', 'button_clicked'
        conversation_id = call('sample_get_record',
                               'object_name' => 'conversations')&.dig('id')
        "/conversations/#{conversation_id}/messages"
      else
        "/#{input['object_name']}"
      end
    end

  },

  object_definitions: {
    event: {
      fields: lambda { |_connection, config_fields|
        case config_fields['type']
        when 'contact_identified'
          call('get_contact_schema')
        when 'new_message'
          call('get_message_schema')
        when 'new_conversation'
          call('get_conversation_schema')
        when 'conversation_status_updated'
          [
            { name: 'orgId', type: 'integer', label: 'Organization ID' },
            { name: 'conversationId', type: 'integer' },
            { name: 'status' },
            { name: 'changedAt', type: 'integer' }
          ]
        when 'conversation_participant_added'
          [
            { name: 'conversationId', type: 'integer' },
            { name: 'addedParticipants', type: 'array', of: 'integer' },
            { name: 'changedAt', type: 'integer' }
          ]
        when 'conversation_participant_removed'
          [
            { name: 'conversationId', type: 'integer' },
            { name: 'removedParticipants', type: 'array', of: 'integer' },
            { name: 'changedAt', type: 'integer' }
          ]
        when 'button_action'
          [
            { name: 'conversationId', type: 'integer' },
            { name: 'author', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer' }
            ] },
            { name: 'sourceMessageId', type: 'integer' },
            { name: 'button', type: 'object' }
          ]
        when 'playbook_goal_met'
          [
            { name: 'conversationId', type: 'integer' },
            { name: 'playbookId', type: 'integer' },
            { name: 'contactId', type: 'integer' },
            { name: 'goalId' },
            { name: 'goalName' },
            { name: 'playbookName' },
            { name: 'contactEmail' }
          ]
        when 'user_unsubscribe'
          call('get_contact_schema')
        else
          []
        end
      }
    },

    contact: {
      fields: lambda { |_connection, _config|
        call('get_contact_schema')
      }
    },

    contact_tag: {
      fields: lambda { |_connection, _config|
        call('get_contact_tag_schema')
      }
    },

    message: {
      fields: lambda { |_connection, _config|
        call('get_message_schema')
      }
    },

    conversation: {
      fields: lambda { |_connection, _config|
        call('get_conversation_schema')
      }
    },

    user: {
      fields: lambda { |_connection, _config|
        call('get_user_schema')
      }
    },

    message_button: {
      fields: lambda {
        [
          { name: 'label' },
          { name: 'value' },
          { name: 'type', control_type: 'select', pick_list: 'button_types' },
          { name: 'style', control_type: 'select', pick_list: 'button_styles' },
          {
            name: 'reaction', type: 'object',
            optional: true,
            properties: [
              { name: 'type', control_type: 'select',
                pick_list: 'reaction_types' },
              { name: 'message', type: 'string' }
            ]
          }
        ]
      }
    },

    custom_action_input: {
      fields: lambda do |connection, config_fields|
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')

        [
          {
            name: 'path',
            optional: false,
            hint:
              if (host = connection['environment']).present?
                "Base URI is <b>https://#{host}.zuora.com</b> - " \
                  'path will be appended to this URI. Use absolute URI to ' \
                  'override this base URI.'
              end
          },
          (
            if %w[get delete].include?(config_fields['verb'])
              {
                name: 'input',
                type: 'object',
                control_type: 'form-schema-builder',
                sticky: input_schema.blank?,
                label: 'URL parameters',
                add_field_label: 'Add URL parameter',
                properties: [
                  {
                    name: 'schema',
                    extends_schema: true,
                    sticky: input_schema.blank?
                  },
                  (
                    if input_schema.present?
                      {
                        name: 'data',
                        type: 'object',
                        properties: call('make_schema_builder_fields_sticky',
                                         input_schema)
                      }
                    end
                  )
                ].compact
              }
            else
              {
                name: 'input',
                type: 'object',
                properties: [
                  {
                    name: 'schema',
                    extends_schema: true,
                    schema_neutral: true,
                    control_type: 'schema-designer',
                    sample_data_type: 'json_input',
                    sticky: input_schema.blank?,
                    label: 'Request body parameters',
                    add_field_label: 'Add request body parameter'
                  },
                  (
                    if input_schema.present?
                      {
                        name: 'data',
                        type: 'object',
                        properties:
                        input_schema.each { |field| field[:sticky] = true }
                      }
                    end
                  )
                ].compact
              }
            end
          ),
          {
            name: 'output',
            control_type: 'schema-designer',
            sample_data_type: 'json_http',
            extends_schema: true,
            schema_neutral: true,
            sticky: true
          }
        ]
      end
    },

    custom_action_output: {
      fields: lambda do |_connection, config_fields|
        parse_json(config_fields['output'] || '[]')
      end
    },

    get_object: {
      fields: lambda do |_connection, config_fields|
        [{ name: 'id', type: 'integer',
           sticky: true,
           label: "#{config_fields['object_name'] || 'record'} ID" }]
      end
    },

    object_delete: {
      fields: lambda do |_connection, config_fields|
        object_name =
          {
            'contacts' => 'Contact',
            'accounts' => 'Account'
          }[config_fields['object_name']]
        [
          { name: 'id',
            type: 'integer',
            label: "#{object_name || 'Record'} ID",
            optional: false }
        ]
      end
    },

    object_create: {
      fields: lambda do |_connection, config_fields|
        call("create_#{config_fields['object_name']}_schema", '')
      end
    },

    object_update: {
      fields: lambda do |_connection, config_fields|
        call("update_#{config_fields['object_name']}_schema", '')
      end
    },

    object_search: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object_name']
        when 'contacts'
          call('search_contacts_schema', '')
        when 'conversations'
          call('search_conversations_schema', '')
        when 'accounts'
          call('search_accounts_schema', '')
        when 'meetings'
          call('search_meetings_schema', '')
        else
          []
        end
      end
    },

    object_get: {
      fields: lambda do |_connection, config_fields|
        object_name =
          {
            'users' => 'User',
            'conversations' => 'Conversation',
            'contacts' => 'Contact',
            'accounts' => 'Account'
          }[config_fields['object_name']]
        [
          { name: 'id',
            type: 'integer',
            label: "#{object_name || 'Record'} ID",
            optional: false }
        ]
      end
    },

    object_output: {
      fields: lambda do |_connection, config_fields|
        case config_fields['object_name']
        when 'contact_identified', 'contacts', 'user_unsubscribed'
          call('get_contact_schema', '')
        when 'new_message', 'new_command_message', 'messages', 'button_clicked'
          call('get_message_schema', '')
        when 'new_conversation', 'conversations'
          call('get_conversation_schema', '')
        when 'conversation_inactive'
          [
            { name: 'conversationId', type: 'integer' },
            { name: 'lastUpdated', type: 'integer' }
          ]
        when 'conversation_participant_added'
          [
            { name: 'conversationId', type: 'integer' },
            { name: 'addedParticipants', type: 'array', of: 'integer' },
            { name: 'changedAt', type: 'integer' }
          ]
        when 'conversation_participant_removed'
          [
            { name: 'conversationId', type: 'integer' },
            { name: 'removedParticipants', type: 'array', of: 'integer' },
            { name: 'changedAt', type: 'integer' }
          ]
        when 'button_action'
          [
            { name: 'conversationId', type: 'integer' },
            { name: 'author', type: 'object', properties: [
              { name: 'type' },
              { name: 'id', type: 'integer' }
            ] },
            { name: 'sourceMessageId', type: 'integer' },
            { name: 'button', type: 'object' }
          ]
        when 'playbook_goal_met'
          [
            { name: 'conversationId', type: 'integer' },
            { name: 'playbookId', type: 'integer' },
            { name: 'contactId', type: 'integer' },
            { name: 'goalId' },
            { name: 'goalName' },
            { name: 'playbookName' },
            { name: 'contactEmail' }
          ]
        when 'user_unsubscribe', 'contact'
          call('get_contact_schema', '')
        when 'users'
          call('get_user_schema', '')
        when 'accounts'
          call('get_account_schema', '')
        when 'new_meeting'
          call('get_meeting_schema', '').ignored('eventType', 'status', 'meetingSource', 'updatedAt', 'meetingType',
                                                 'endUserTimeZone', 'meetingNotes', 'bookedBy')
        when 'meeting_updated'
          call('get_meeting_schema', '').ignored('status', 'meetingSource', 'updatedAt', 'meetingType',
                                                 'endUserTimeZone', 'meetingNotes', 'bookedBy')
        when 'user_availability_updated'
          [
            { name: 'userId', type: 'integer' },
            { name: 'updatedAt', type: 'integer', hint: 'time of update' },
            { name: 'availability' }
          ]
        when 'phone_captured'
          [
            { name: 'conversationId', type: 'integer' },
            { name: 'authorId', type: 'integer' },
            { name: 'authorType' },
            { name: 'phoneNumber' }
          ]
        when 'contact_updated'
          [
            { name: 'endUserId', type: 'integer' },
            { name: 'timestamp', type: 'date_time' },
            { name: 'orgId', type: 'integer' },
            { name: 'diff', type: 'array', of: 'object',
              properties: [
                { name: 'name' },
                { name: 'previous' },
                { name: 'updated' }
              ] }
          ]
        when 'timeline'
          call('get_timeline_schema', '')
        else
          []
        end
      end
    },

    object_search_output: {
      fields: lambda do |_connection, config_fields|
        [
          { name: 'records', label: config_fields['object_name'].labelize || 'records',
            type: 'array', of: 'object',
            properties: call('search_object_output', config_fields) }
        ]
      end
    }

  },

  actions: {
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
        "in <span class='provider'>Drift</span>",
      help: 'Build your own Drift action with a HTTP request.' \
        " <br> <a href='https://devdocs.drift.com/docs'" \
        " target='_blank'>Drift API Documentation</a> ",

      config_fields: [{
        name: 'verb',
        label: 'Request type',
        hint: 'Select HTTP method of the request',
        optional: false,
        control_type: 'select',
        pick_list: %w[get post put delete].map { |v| [v.upcase, v] }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['custom_action_input']
      end,

      execute: lambda do |_connection, input|
        verb = input['verb']
        if %w[get post put patch delete].exclude?(verb)
          error("#{verb} not supported")
        end
        data = input.dig('input', 'data').presence || {}

        case verb
        when 'get'
          get(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when 'post'
          post(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when 'put'
          put(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when 'delete'
          delete(input['path'], data).
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['custom_action_output']
      end
    },

    search_records: {
      description: lambda do |_input, pick_lists|
        "Search <span class='provider'>#{pick_lists['object_name']&.downcase || 'records'}" \
        "</span> in <span class='provider'>Drift</span>"\
      end,
      help: lambda do |_input, pick_lists|
        help = { 'Contacts' => "Note that email is not a primary identifier, and it's possible that multiple" \
                 ' contacts have the same email - so querying on email returns a list.',
                 'Users' => 'Search will return the full list of users (with the full user model metadata).',
                 'Conversations' => 'Conversations returned will be ordered by their <b>updatedAt</b> time with ' \
                 'the most recently updated at the top of the list. Common conversation updates' \
                 ' include status updates (i.e. closing the conversation) or a post of a ' \
                 'new message to that conversation.',
                 'Accounts' => 'Note: The <b>next</b> field in the output may not always be present. ' \
                 'Once the accounts are exhausted, the <b>next</b> field will be absent' \
                 ' from the response body.',
                 'Bot playbooks' => 'Bot playbooks are currently available on Pro and higher plans.',
                 'Booked meetings' => 'The action returns the booked meetings for an account, across all the Drift ' \
                 'agents, in a given time range up to a max of 1000 meetings per request,' \
                 ' and up to 30 days in the past.' }[pick_lists['object_name']] || ''

        { body: help.present? ? help : '' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          hint: 'Please select the Drift object.',
          pick_list: 'search_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['object_search']
      end,
      execute: lambda do |_connection, input|
        call('validate_search_criteria', input)
        payload = call('format_request_payload', input).compact
        response = get(call('search_url', input), payload.except('object_name')).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end
        result = if input['object_name'] == 'playbooks'
                   response&.compact
                 elsif input['object_name'] == 'accounts'
                   response.dig('data', 'accounts')
                 else
                   response['data']
                 end
        records = call('format_unix_to_utc_time', result) || []
        { records: records }
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_search_output']
      end,
      sample_output: lambda do |_connection, input|
        { records: call('sample_search_record', input) || [] }
      end
    },

    get_record: {
      description: lambda do |_input, pick_lists|
        "Get <span class='provider'>#{pick_lists['object_name']&.
        downcase || 'object'}</span> by ID in <span class='provider'>"\
        'Drift</span>'
      end,
      help: {
        body: 'Retrieve information about a record associated ' \
          'with the given record ID in Drift.'
      },
      config_fields: [
        { name: 'object_name', control_type: 'select',
          hint: 'Please select the Drift object from the list.',
          pick_list: 'get_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['object_get']
      end,
      execute: lambda do |_connection, input|
        response = get("#{input['object_name']}/#{input['id']}").
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end['data']
        call('format_unix_to_utc_time', response)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_output']
      end,
      sample_output: lambda do |_connection, input|
        call('sample_get_record', input) || []
      end
    },

    create_record: {
      description: lambda do |_input, pick_lists|
        "Create <span class='provider'>#{pick_lists['object_name']&.
        downcase || 'record'}</span> in <span class='provider'>"\
        'Drift</span>'
      end,
      help: lambda do |_input, pick_lists|
        help = { 'Contact' => 'When creating a contact, the only field that is required is email. ' \
                 'If the contact is already present, the request will respond with an error.',
                 'Conversation' => 'Note that the <b>Integration source</b> is a special attribute in the ' \
                 'message and will appear in the header of the newly started conversation. ' \
                 "We recommend including this in each request. <br> <br> We'll attempt to find " \
                 'a contact in your account with the provided email, based on first created, and ' \
                 "open up a new conversation in drift with them. If a contact with that email isn't " \
                 'found, then one will be created.',
                 'Account' => 'Note that accounts must have a <b>unique domain</b>. Accounts are split by ' \
                 'domain as a unique identifier - attempting to create an account with an identical domain ' \
                 'will result in an error.',
                 'Message' => 'The message API renders the body as HTML. Tags like &lt;a&gt;, &lt;p&gt;, ' \
                 '&lt;b&gt;, etc. should all work. <br><br> When posting a youtube link in the chat, ' \
                 'you should post the link as an &lt;a&gt; tag. <br> Example body message: ' \
                 "Hey there, check this out <a href='https://www.youtube.com/watch?v=kD30F_tjogs'>here</a> ",
                 'Timeline event' => 'To use an <b>External ID</b> for contact lookup and posting, <b>provide</b> ' \
                 'your <b>External ID</b> value in the payload and leave the <b>Contact ID</b> field <b>empty</b>. ' \
                 'The timeline event should post in the same way if there is a contact match to your ' \
                 'external ID.' }[pick_lists['object_name']] || ''

        { body: help.present? ? help : '' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          hint: 'Please select the Drift object.',
          pick_list: 'create_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['object_create']
      end,
      execute: lambda do |_connection, input|
        object_name = input.delete('object_name')
        url = case object_name
              when 'messages'
                "/conversations/#{input.delete('conversationId')}/messages"
              when 'conversations'
                '/conversations/new'
              when 'timeline'
                "/contacts/#{object_name}"
              when 'accounts'
                '/accounts/create'
              else
                "/#{object_name}"
              end

        payload = case object_name
                  when 'contacts'
                    { attributes: call('format_date_time_to_unix', input) }
                  else
                    call('format_date_time_to_unix', input)
                  end
        response =
          post(url).
          payload(payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end

        case object_name
        when 'conversations'
          result = parse_json(response.to_json)
          call('format_unix_to_utc_time', result)
        else
          call('format_unix_to_utc_time', response['data'])
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_output']
      end,
      sample_output: lambda do |_connection, input|
        call('sample_get_record', input) || []
      end
    },

    update_record: {
      description: lambda do |_input, pick_lists|
        "Update <span class='provider'>#{pick_lists['object_name']&.
        downcase || 'record'}</span> in <span class='provider'>"\
        'Drift</span>'
      end,
      help: lambda do |_input, pick_lists|
        help = { 'Contact' => 'You can update a contact record in Drift by providing the contact ID of ' \
                 'the desired contact in Drift, with the appropriate properties to update in the request.',
                 'Account' => 'While updating or changing the existing type of a field is allowed, ' \
                 'it is not recommended. Drift uses the type of the account field to allow segmentation ' \
                 'and filtering in the Accounts UI of the Drift platform. Using/changing different types ' \
                 'may break this behavior.',
                 'User' => 'Update a user record in Drift by providing the ' \
                 '<b>user ID</b>.' }[pick_lists['object_name']] || ''

        { body: help.present? ? help : '' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          hint: 'Please select the Drift object.',
          pick_list: 'update_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['object_update']
      end,
      execute: lambda do |_connection, input|
        object_name = input.delete('object_name')
        url = case object_name
              when 'accounts'
                "/#{object_name}/update"
              when 'contacts'
                "/#{object_name}/#{input.delete('id')}"
              when 'users'
                "/#{object_name}/update?userId=#{input.delete('id')}"
              end
        payload = call('format_date_time_to_unix', input)
        response =
          patch(url).
          payload(payload).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end['data']
        call('format_unix_to_utc_time', response)
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['object_output']
      end,
      sample_output: lambda do |_connection, input|
        call('sample_get_record', input) || []
      end
    },

    delete_record: {
      subtitle: 'Remove a record',
      description: lambda do |_input, pick_lists|
        "Delete <span class='provider'>#{pick_lists['object_name']&.
        downcase || 'record'}</span> in <span class='provider'>"\
        'Drift</span>'
      end,
      help: lambda do |_input, pick_lists|
        help = { 'Contact' => 'You can update a contact record in Drift by providing the contact ID of ' \
                 'the desired contact in Drift, with the appropriate properties to update in the request.',
                 'Account' => 'Note that deletes are never true deletes from the Drift system. ' \
                 'Deleting an account will hide it from the list view in drift, but you can still ' \
                 'query the account by ID later on. In this case, the account will return in the ' \
                 'response with a <b>deleted: true</b> field.' }[pick_lists['object_name']] || ''

        { body: help.present? ? help : '' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          hint: 'Please select the Drift object.',
          pick_list: 'delete_object_list',
          label: 'Object name',
          optional: false }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['object_delete']
      end,
      execute: lambda do |_connection, input|
        delete("/#{input['object_name']}/#{input['id']}").
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'result' }, { name: 'ok', type: 'boolean' }]
      end,
      sample_output: lambda do |_connection, _input|
        { 'result': 'OK', 'ok': true }
      end
    }
  },

  webhook_keys: lambda { |_params, _headers, payload|
    "#{payload['type']}&#{payload['token']}"
  },

  triggers: {
    new_object: {
      title: 'New object',
      subtitle: 'Triggers when an object created in Drift',
      description: lambda do |_connection, new_object_list|
        "New <span class='provider'>#{new_object_list[:object_name]&.downcase || 'object'} " \
        "</span> in <span class='provider'>Drift</span>"
      end,
      help: lambda do |_connection, new_object_list|
        help = {
          'Contact' => 'Triggers when a contact added their email in chat.',
          'Message' => 'Triggers when a new message was created.',
          'Command message' => 'Triggers when a new command message was received. Currently ' \
          'these begin with a slash <b>/</b> - ex: <b>/msg</b>. This is a filtered, lower access, version of ' \
          '<b>new_message</b>. Recommended if your app only cares about a trigger phrase being sent in chat.',
          'Conversation' => 'Triggers when a new conversation was started. This explicitly looks' \
          ' at conversations not started by bots - i.e. a site visitor interaction with a welcome message.',
          'Conversation participant added' => 'Triggers when participants were added to a conversation.',
          'Meeting' =>
            'Triggers when a meeting was booked by a contact or site visitor with a member of your team -' \
            ' scheduled by the bot or via your calendar schedule page. Requires calendar connection in drift.',
          'Phone' => 'Triggers when a phone number was captured in a conversation.',
          'Button click' => 'Triggers when a button was clicked in a conversation.' \
          ' The payload will include the contact ID.'
        }[new_object_list[:object_name]] || ''

        { body: help.present? ? help : "<b>Configure Drift to send events to Workato.</b>" \
            '<br>To find your static webhook URI, click on Tools &rarr; ' \
            'Connector SDK &rarr; Drift &rarr; Settings then click on <b>Copy static webhook URI</b>.',
          learn_more_url: 'https://devdocs.drift.com/docs/webhook-events-1',
          learn_more_text: 'Drift webhooks documentation' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          pick_list: 'new_object_list',
          hint: 'Please select object from the list',
          label: 'Object name',
          optional: false }
      ],
      webhook_key: lambda { |connection, input|
        "#{input['object_name']}&#{connection['verification_token']}"
      },
      webhook_notification: lambda { |_input, payload|
        object = { 'type' => payload['type'], 'orgId' => payload['orgId'] }.
                 merge(payload['data'])
        date_fields = %w[start_date last_active last_contacted scheduledAt slotStart slotEnd updatedAt
                         indexedAt createdAt createDateTime updateDateTime]
        object.map do |key, value|
          if date_fields.include?(key)
            { key => (value.to_i / 1000).to_i.to_time.utc }
          elsif key == 'attributes'
            val = value.map do |k, v|
              if date_fields.include?(k)
                { k => (v.to_i / 1000).to_i.to_time.utc }
              else
                { k => v }
              end
            end.inject(:merge)
            { key => val }
          else
            { key => value }
          end
        end.inject(:merge)
      },
      dedup: lambda do |_|
        Time.now.to_f
      end,
      output_fields: lambda { |object_definitions|
        [
          { name: 'orgId', type: 'string', label: 'Organization ID' },
          { name: 'type',  type: 'string', label: 'Event type' }
        ].concat(object_definitions['object_output']).compact
      },
      sample_output: lambda do |_connection, input|
        sample_output = [{ orgId: '1351205',
                           type: 'Event' }].
                        concat([call('sample_get_record', input)] || [])
        sample_output.inject(:merge)
      end

    },
    update_object: {
      title: 'Updated/deleted object ',
      subtitle: 'Triggers when an object is updated, removed, unsubscribed in Drift',
      description: lambda do |_connection, new_updated_object_list|
        "Updated/removed <span class='provider'>" \
        "#{new_updated_object_list[:object_name]&.downcase || 'object'} " \
        "</span> in <span class='provider'>Drift</span>"
      end,
      help: lambda do |_connection, new_updated_object_list|
        help = {
          'Conversation status' => 'Triggers when a conversation has not seen activity in the previous 10 minutes.',
          'Meeting' => 'Triggers when a previously booked meeting was either rescheduled or canceled.',
          'Contact' => 'Triggers when a contact record has been updated in Drift.',
          'User availability' => 'Triggers when a drift user\'s availability has been changed.',
          'Conversation participant removed' => 'Triggers when participants were removed from a conversation.',
          'User unsubscribed' => 'Trigger when a user unsubscribed from all emails - this is invoked whenever' \
             ' someone opts out of email communication (either manually, or by the api).',
          'Playbook goal met' =>
            'Trigger will fire whenever a goal is met with a previously identified' \
            ' contact (i.e. a site visitor that provided their email or is known in the' \
            ' Drift UI). The payload will include the contact ID.'
        }[new_updated_object_list[:object_name]] || ''

        { body: help.present? ? help : "<b>Configure Drift to send events to Workato.</b>" \
            '<br>To find your static webhook URI, click on Tools &rarr; ' \
            'Connector SDK &rarr; Drift &rarr; Settings then click on <b>Copy static webhook URI</b>.',
          learn_more_url: 'https://devdocs.drift.com/docs/webhook-events-1',
          learn_more_text: 'Drift webhooks documentation' }
      end,
      config_fields: [
        { name: 'object_name', control_type: 'select',
          pick_list: 'new_updated_object_list',
          hint: 'Please select object from the list',
          label: 'Object name',
          optional: false }
      ],
      webhook_key: lambda { |connection, input|
        "#{input['object_name']}&#{connection['verification_token']}"
      },
      webhook_notification: lambda { |_connection, payload|
        object = { 'type' => payload['type'], 'orgId' => payload['orgId'] }.
                 merge(payload['data'])
        date_fields = %w[start_date last_active last_contacted scheduledAt slotStart lastUpdated
                         timestamp slotEnd updatedAt indexedAt createdAt createDateTime updateDateTime]
        object.map do |key, value|
          if date_fields.include?(key)
            { key => (value.to_i / 1000).to_i.to_time.utc }
          elsif key == 'attributes'
            val = value.map do |k, v|
              if date_fields.include?(k)
                { k => (v.to_i / 1000).to_i.to_time.utc }
              else
                { k => v }
              end
            end.inject(:merge)
            { key => val }
          else
            { key => value }
          end
        end.inject(:merge)
      },
      dedup: lambda do |_|
        Time.now.to_f
      end,
      output_fields: lambda { |object_definitions|
        [
          { name: 'orgId', type: 'string', label: 'Organization ID' },
          { name: 'type',  type: 'string', label: 'Event type' }
        ].concat(object_definitions['object_output']).compact
      },
      sample_output: lambda do |_connection, input|
        sample_output = [{ orgId: '1351205',
                           type: 'Event' }].
                        concat([call('sample_get_record', input)] || [])
        sample_output.inject(:merge)
      end

    }
  },

  pick_lists: {
    new_object_list: lambda do |_connection|
      [
        %w[Contact contact_identified],
        %w[Message new_message],
        %w[Command\ message new_command_message],
        %w[Conversation new_conversation],
        %w[Conversation\ participant\ added conversation_participant_added],
        %w[Meeting new_meeting],
        %w[Phone phone_captured],
        %w[Button\ click button_clicked]
      ]
    end,

    new_updated_object_list: lambda do |_connection|
      [
        %w[Conversation\ status conversation_inactive],
        %w[Meeting meeting_updated],
        %w[Contact contact_updated],
        %w[User\ availability user_availability_updated],
        %w[Conversation\ participant\ removed conversation_participant_removed],
        %w[User\ unsubscribed user_unsubscribed],
        %w[Playbook\ goal\ met playbook_goal_met]
      ]
    end,

    search_object_list: lambda do
      [
        %w[Contacts contacts],
        %w[Users users],
        %w[Conversations conversations],
        %w[Accounts accounts],
        %w[Bot\ playbooks playbooks],
        %w[Booked\ meetings meetings]
      ]
    end,

    get_object_list: lambda do
      [
        %w[Contact contacts],
        %w[User users],
        %w[Conversation conversations],
        %w[Account accounts]
      ]
    end,

    create_object_list: lambda do
      [
        %w[Contact contacts],
        %w[Conversation conversations],
        %w[Message messages],
        %w[Account accounts],
        %w[Timeline\ event timeline]
      ]
    end,

    update_object_list: lambda do
      [
        %w[Contact contacts],
        %w[User users],
        %w[Account accounts]
      ]
    end,

    delete_object_list: lambda do
      [
        %w[Contact contacts],
        %w[Account accounts]
      ]
    end,

    status_list: lambda do
      [
        %w[Open OPEN],
        %w[Closed CLOSED],
        %w[Pending PENDING]
      ]
    end,

    status_id_list: lambda do
      [
        %w[Open 1],
        %w[Closed 2],
        %w[Pending 3]
      ]
    end,

    event_types: lambda do |_connection|
      [
        ['Conversation status updated', 'conversation_status_updated'],
        ['Conversation participant added', 'conversation_participant_added'],
        ['Conversation participant removed',
         'conversation_participant_removed'],
        ['Button action', 'button_action'],
        ['Playbook goal met', 'playbook_goal_met'],
        ['User unsubscribed', 'user_unsubscribe']
      ]
    end,

    message_types: lambda do |_connection|
      [
        %w[Chat chat],
        ['Private note', 'private_note'],
        ['Private prompt', 'private_prompt'],
        %w[Edit edit]
      ]
    end,
    edit_types: lambda do |_input|
      [
        %w[Delete delete],
        %w[Replace replace],
        ['Replace body', 'replace_body'],
        ['Replace buttons', 'replace_buttons']
      ]
    end,
    reaction_types: lambda do |_input|
      [
        %w[Delete delete],
        %w[Replace replace]
      ]
    end,
    button_types: lambda do |_input|
      [
        %w[Reply reply],
        %w[Compose compose],
        %w[Action action]
      ]
    end,
    button_styles: lambda do |_input|
      [
        %w[Primary primary],
        %w[Danger danger]
      ]
    end,
    data_types: lambda do |_input|
      [
        %w[String STRING],
        %w[Email EMAIL],
        %w[Number NUMBER],
        %w[Team\ member TEAMMEMBER],
        %w[Enum ENUM],
        %w[Date DATE],
        %w[Date\ time DATETIME],
        %w[Latitude\ Longitude LATLON],
        %w[Latitude LAT],
        %w[Longitude LON],
        %w[Phone PHONE],
        %w[URL URL],
        %w[Enum\ array ENUMARRAY]
      ]
    end
  }
}
