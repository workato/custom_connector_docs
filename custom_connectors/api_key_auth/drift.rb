{
  title: 'Drift',
  connection: {
    fields: [
      {
        name: 'api_token',
        label: 'API token',
        control_type: 'password',
        type: 'string',
        hint: 'Your Drift API token. Create your drift app and retrieve the ' \
        "token <a href='https://dev.drift.com' target='_blank'>here</a>.",
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
      type: 'api_key',
      credentials: lambda { |connection|
        headers(Authorization: "Bearer #{connection['api_token']}")
      }
    },
    base_uri: lambda {
      'https://driftapi.com'
    }
  },
  methods: {
    get_contact_schema: lambda {
      [
        {
          control_type: 'integer',
          label: 'ID',
          parse_output: 'float_conversion',
          type: 'integer',
          name: 'id',
          optional: false
        },
        {
          control_type: 'date_time',
          label: 'Created at',
          parse_output: 'float_conversion',
          type: 'date_time',
          name: 'createdAt',
          optional: false
        },
        {
          properties: [
            {
              control_type: 'number',
              label: 'End user version',
              parse_output: 'float_conversion',
              type: 'number',
              name: '_end_user_version'
            },
            {
              control_type: 'text',
              label: 'Avatar URL',
              type: 'string',
              name: 'avatarUrl'
            },
            {
              control_type: 'number',
              label: 'Calculated version',
              parse_output: 'float_conversion',
              type: 'number',
              name: '_calculated_version'
            },
            {
              control_type: 'text',
              label: 'Employment role',
              type: 'string',
              name: 'employment_role'
            },
            {
              control_type: 'text',
              label: 'Last name',
              type: 'string',
              name: 'last_name'
            },
            {
              control_type: 'text',
              label: 'Linkedin handle',
              type: 'string',
              name: 'linkedin_handle'
            },
            {
              control_type: 'text',
              label: 'Display name',
              type: 'string',
              name: 'display_name'
            },
            {
              name: 'tags',
              type: 'array',
              of: 'object',
              label: 'Tags',
              optional: false,
              properties: [
                { name: 'name' },
                { name: 'color' }
              ]
            },
            {
              control_type: 'text',
              label: 'Employment name',
              type: 'string',
              name: 'employment_name'
            },
            {
              control_type: 'text',
              label: 'Employment title',
              type: 'string',
              name: 'employment_title'
            },
            {
              properties: [
                {
                  control_type: 'text',
                  label: 'Indexed at',
                  render_input: 'date_time_conversion',
                  parse_output: 'date_time_conversion',
                  type: 'date_time',
                  name: 'indexedAt'
                },
                {
                  properties: [
                    {
                      control_type: 'text',
                      label: 'Handle',
                      type: 'string',
                      name: 'handle'
                    },
                    {
                      control_type: 'text',
                      label: 'ID',
                      type: 'string',
                      name: 'id'
                    },
                    {
                      control_type: 'text',
                      label: 'Avatar',
                      type: 'string',
                      name: 'avatar'
                    },
                    {
                      control_type: 'text',
                      label: 'Company',
                      type: 'string',
                      name: 'company'
                    },
                    {
                      control_type: 'text',
                      label: 'Blog',
                      type: 'string',
                      name: 'blog'
                    },
                    {
                      control_type: 'text',
                      label: 'Followers',
                      type: 'string',
                      name: 'followers'
                    },
                    {
                      control_type: 'text',
                      label: 'Following',
                      type: 'string',
                      name: 'following'
                    }
                  ],
                  label: 'Github',
                  type: 'object',
                  name: 'github'
                },
                {
                  properties: [
                    {
                      control_type: 'text',
                      label: 'Handle',
                      type: 'string',
                      name: 'handle'
                    }
                  ],
                  label: 'Facebook',
                  type: 'object',
                  name: 'facebook'
                },
                {
                  control_type: 'text',
                  label: 'Avatar',
                  type: 'string',
                  name: 'avatar'
                },
                {
                  properties: [
                    {
                      control_type: 'text',
                      label: 'Domain',
                      type: 'string',
                      name: 'domain'
                    },
                    {
                      control_type: 'text',
                      label: 'Name',
                      type: 'string',
                      name: 'name'
                    },
                    {
                      control_type: 'text',
                      label: 'Title',
                      type: 'string',
                      name: 'title'
                    },
                    {
                      control_type: 'text',
                      label: 'Role',
                      type: 'string',
                      name: 'role'
                    },
                    {
                      control_type: 'text',
                      label: 'Seniority',
                      type: 'string',
                      name: 'seniority'
                    }
                  ],
                  label: 'Employment',
                  type: 'object',
                  name: 'employment'
                },
                {
                  properties: [
                    {
                      control_type: 'text',
                      label: 'Handle',
                      type: 'string',
                      name: 'handle'
                    }
                  ],
                  label: 'Linkedin',
                  type: 'object',
                  name: 'linkedin'
                },
                {
                  properties: [
                    {
                      control_type: 'text',
                      label: 'Handle',
                      type: 'string',
                      name: 'handle'
                    },
                    {
                      control_type: 'text',
                      label: 'Bio',
                      type: 'string',
                      name: 'bio'
                    },
                    {
                      control_type: 'text',
                      label: 'Avatar',
                      type: 'string',
                      name: 'avatar'
                    }
                  ],
                  label: 'Aboutme',
                  type: 'object',
                  name: 'aboutme'
                },
                {
                  properties: [
                    {
                      control_type: 'text',
                      label: 'City',
                      type: 'string',
                      name: 'city'
                    },
                    {
                      control_type: 'text',
                      label: 'State',
                      type: 'string',
                      name: 'state'
                    },
                    {
                      control_type: 'text',
                      label: 'State code',
                      type: 'string',
                      name: 'stateCode'
                    },
                    {
                      control_type: 'text',
                      label: 'Country',
                      type: 'string',
                      name: 'country'
                    },
                    {
                      control_type: 'text',
                      label: 'Country code',
                      type: 'string',
                      name: 'countryCode'
                    },
                    {
                      control_type: 'text',
                      label: 'Lat',
                      type: 'string',
                      name: 'lat'
                    },
                    {
                      control_type: 'text',
                      label: 'Lng',
                      type: 'string',
                      name: 'lng'
                    }
                  ],
                  label: 'Geo',
                  type: 'object',
                  name: 'geo'
                },
                {
                  properties: [
                    {
                      control_type: 'text',
                      label: 'Handle',
                      type: 'string',
                      name: 'handle'
                    },
                    {
                      control_type: 'text',
                      label: 'ID',
                      type: 'string',
                      name: 'id'
                    },
                    {
                      control_type: 'text',
                      label: 'Bio',
                      type: 'string',
                      name: 'bio'
                    },
                    {
                      control_type: 'text',
                      label: 'Followers',
                      type: 'string',
                      name: 'followers'
                    },
                    {
                      control_type: 'text',
                      label: 'Following',
                      type: 'string',
                      name: 'following'
                    },
                    {
                      control_type: 'text',
                      label: 'Statuses',
                      type: 'string',
                      name: 'statuses'
                    },
                    {
                      control_type: 'text',
                      label: 'Favorites',
                      type: 'string',
                      name: 'favorites'
                    },
                    {
                      control_type: 'text',
                      label: 'Location',
                      type: 'string',
                      name: 'location'
                    },
                    {
                      control_type: 'text',
                      label: 'Site',
                      type: 'string',
                      name: 'site'
                    },
                    {
                      control_type: 'text',
                      label: 'Avatar',
                      type: 'string',
                      name: 'avatar'
                    }
                  ],
                  label: 'Twitter',
                  type: 'object',
                  name: 'twitter'
                },
                {
                  control_type: 'text',
                  label: 'Active at',
                  render_input: 'date_time_conversion',
                  parse_output: 'date_time_conversion',
                  type: 'date_time',
                  name: 'activeAt'
                },
                {
                  control_type: 'checkbox',
                  label: 'Email provider',
                  toggle_hint: 'Select from option list',
                  toggle_field: {
                    label: 'Email provider',
                    control_type: 'text',
                    hint: 'Allowed values are: true, false',
                    toggle_hint: 'Use custom value',
                    type: 'boolean',
                    name: 'emailProvider'
                  },
                  pick_list: [
                    [
                      'True',
                      true
                    ],
                    [
                      'False',
                      false
                    ]
                  ],
                  type: 'boolean',
                  name: 'emailProvider'
                },
                {
                  properties: [
                    {
                      control_type: 'text',
                      label: 'Handle',
                      type: 'string',
                      name: 'handle'
                    },
                    {
                      control_type: 'text',
                      label: 'Urls',
                      type: 'string',
                      name: 'urls'
                    },
                    {
                      control_type: 'text',
                      label: 'Avatar',
                      type: 'string',
                      name: 'avatar'
                    }
                  ],
                  label: 'Gravatar',
                  type: 'object',
                  name: 'gravatar'
                },
                {
                  properties: [
                    {
                      control_type: 'text',
                      label: 'Full name',
                      type: 'string',
                      name: 'fullName'
                    },
                    {
                      control_type: 'text',
                      label: 'Given name',
                      type: 'string',
                      name: 'givenName'
                    },
                    {
                      control_type: 'text',
                      label: 'Family name',
                      type: 'string',
                      name: 'familyName'
                    }
                  ],
                  label: 'Name',
                  type: 'object',
                  name: 'name'
                },
                {
                  control_type: 'text',
                  label: 'ID',
                  type: 'string',
                  name: 'id'
                },
                {
                  control_type: 'email',
                  label: 'Email',
                  type: 'string',
                  name: 'email'
                },
                {
                  name: 'fuzzy',
                  label: 'Fuzzy',
                  type: 'boolean',
                  control_type: 'checkbox',
                  toggle_hint: 'Select from option list',
                  toggle_field: {
                    label: 'Fuzzy',
                    control_type: 'text',
                    toggle_hint: 'Use custom value',
                    type: 'boolean',
                    name: 'fuzzy'
                  }
                },
                {
                  properties: [
                    {
                      control_type: 'text',
                      label: 'Handle',
                      type: 'string',
                      name: 'handle'
                    }
                  ],
                  label: 'Googleplus',
                  type: 'object',
                  name: 'googleplus'
                }
              ],
              label: 'Social profiles',
              type: 'object',
              name: 'socialProfiles'
            },
            {
              control_type: 'text',
              label: 'Name',
              type: 'string',
              name: 'name'
            },
            {
              control_type: 'text',
              label: 'First name',
              type: 'string',
              name: 'first_name'
            },
            {
              control_type: 'email',
              label: 'Email',
              type: 'string',
              name: 'email'
            },
            {
              label: 'Events',
              type: 'object',
              name: 'events'
            },
            {
              control_type: 'date_time',
              label: 'Start date',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion',
              type: 'date_time',
              name: 'start_date',
              optional: false
            }
          ],
          label: 'Attributes',
          type: 'object',
          name: 'attributes'
        }
      ]
    },
    get_contact_tag_schema: lambda {
      [
        {
          control_type: 'text',
          label: 'Name',
          type: 'string',
          name: 'name'
        },
        {
          control_type: 'text',
          label: 'Color',
          type: 'string',
          name: 'color'
        }
      ]
    },
    get_message_schema: lambda {
      [
        {
          control_type: 'integer',
          label: 'ID',
          parse_output: 'float_conversion',
          type: 'integer',
          name: 'id',
          optional: false
        },
        {
          control_type: 'integer',
          label: 'Organization ID',
          parse_output: 'float_conversion',
          type: 'integer',
          name: 'orgId',
          optional: false
        },
        {
          control_type: 'text',
          label: 'Body',
          type: 'string',
          name: 'body'
        },
        {
          properties: [
            {
              control_type: 'select',
              label: 'Type',
              type: 'string',
              name: 'type',
              pick_list: [
                %w[Contact contact],
                %w[User user]
              ],
              toggle_hint: 'Select from option list',
              toggle_field: {
                name: 'type',
                type: 'string',
                control_type: 'string',
                hint: 'Allowed values: user, contact',
                toggle_hint: 'Use custom value'
              }
            },
            {
              control_type: 'integer',
              label: 'ID',
              parse_output: 'float_conversion',
              type: 'integer',
              name: 'id',
              optional: false
            }
          ],
          label: 'Author',
          type: 'object',
          name: 'author'
        },
        {
          control_type: 'select',
          label: 'Type',
          type: 'string',
          name: 'type',
          pick_list: [
            %w[Chat chat],
            ['Private note', 'private_note'],
            ['Private prompt', 'private_prompt'],
            %w[Suggestion suggestion],
            %w[Edit edit]
          ],
          toggle_hint: 'Select from option list',
          toggle_field: {
            name: 'type',
            type: 'string',
            control_type: 'string',
            hint: 'Allowed values: private_note, private_prompt,' \
              ' suggestion, edit',
            toggle_hint: 'Use custom value'
          }
        },
        {
          control_type: 'integer',
          label: 'Conversation ID',
          parse_output: 'integer_conversion',
          type: 'integer',
          name: 'conversationId',
          optional: false
        },
        {
          control_type: 'date_time',
          label: 'Created at',
          render_input: 'date_time_conversion',
          parse_output: 'float_conversion',
          type: 'date_time',
          name: 'createdAt',
          optional: false
        },
        {
          name: 'attachment',
          type: 'array',
          of: 'object',
          label: 'Attachment',
          properties: [
            {
              control_type: 'text',
              label: 'File name',
              type: 'string',
              name: 'fileName'
            },
            {
              control_type: 'text',
              label: 'Mime type',
              type: 'string',
              name: 'mimeType'
            },
            {
              control_type: 'url',
              label: 'URL',
              type: 'string',
              name: 'url'
            }
          ]
        },
        {
          name: 'buttons',
          type: 'array',
          of: 'object',
          label: 'Buttons',
          properties: [
            {
              control_type: 'text',
              label: 'Value',
              type: 'string',
              name: 'value'
            },
            {
              control_type: 'text',
              label: 'Label',
              type: 'string',
              name: 'label'
            },
            {
              control_type: 'text',
              label: 'Type',
              type: 'string',
              name: 'type'
            }
          ]
        },
        {
          properties: [
            {
              control_type: 'text',
              label: 'IP',
              type: 'string',
              name: 'ip'
            },
            {
              control_type: 'text',
              label: 'User agent',
              type: 'string',
              name: 'userAgent'
            }
          ],
          label: 'Context',
          type: 'object',
          name: 'context'
        },
        {
          control_type: 'integer',
          label: 'Edited message ID',
          parse_output: 'integer_conversion',
          type: 'integer',
          name: 'editedMessageId',
          optional: false
        },
        {
          control_type: 'select',
          label: 'Edit type',
          type: 'string',
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
            control_type: 'string',
            hint: 'Allowed values: delete, replace, replace_body,' \
              ' replace_buttons',
            toggle_hint: 'Use custom value'
          }
        }
      ]
    },
    get_conversation_schema: lambda {
      [
        {
          control_type: 'integer',
          label: 'ID',
          parse_output: 'integer_conversion',
          type: 'integer',
          name: 'id'
        },
        {
          control_type: 'integer',
          label: 'Organization ID',
          parse_output: 'integer_conversion',
          name: 'orgId',
          type: 'integer'
        },
        {
          name: 'participants',
          type: 'array',
          of: 'integer',
          label: 'Participants'
        },
        {
          control_type: 'select',
          label: 'Status',
          type: 'string',
          toggle_hint: 'Select from option list',
          pick_list: [
            %w[Open open],
            %w[Closed closed],
            %w[Pending pending]
          ],
          toggle_field: {
            name: 'status',
            control_type: 'string',
            type: 'string',
            hint: 'Allowed values: open, closed, pending',
            toggle_hint: 'Use custom value'
          },
          name: 'status'
        },
        {
          control_type: 'integer',
          label: 'Contact ID',
          parse_output: 'integer_conversion',
          type: 'integer',
          name: 'contactId'
        },
        {
          control_type: 'date_time',
          label: 'Created at',
          render_input: 'date_time_conversion',
          parse_output: 'float_conversion',
          type: 'date_time',
          name: 'createdAt'
        },
        {
          control_type: 'integer',
          label: 'Inbox ID',
          parse_output: 'integer_conversion',
          type: 'integer',
          name: 'inboxId'
        }
      ]
    },
    get_user_schema: lambda {
      [
        {
          control_type: 'integer',
          label: 'ID',
          parse_output: 'integer_conversion',
          type: 'integer',
          name: 'id',
          optional: false
        },
        {
          control_type: 'integer',
          label: 'Organization ID',
          parse_output: 'integer_conversion',
          type: 'integer',
          name: 'orgId',
          optional: false
        },
        {
          control_type: 'text',
          label: 'Name',
          type: 'string',
          name: 'name'
        },
        {
          control_type: 'text',
          label: 'Alias',
          type: 'string',
          name: 'alias'
        },
        {
          control_type: 'text',
          label: 'Email',
          type: 'string',
          name: 'email'
        },
        {
          label: 'Availability',
          type: 'string',
          control_type: 'select',
          pick_list: [
            %w[Available AVAILABLE],
            %w[Offline OFFLINE],
            %w[OnCall ON_CALL]
          ],
          toggle_hint: 'Select from option list',
          toggle_field: {
            label: 'Availability',
            control_type: 'string',
            hint: 'Allowed values: AVAILABLE, OFFLINE, ON_CALL',
            toggle_hint: 'Use custom value',
            type: 'string',
            name: 'availability'
          },
          name: 'availability'
        },
        {
          control_type: 'text',
          label: 'Time zone',
          name: 'timeZone',
          type: 'string'
        },
        {
          control_type: 'text',
          label: 'Avatar URL',
          name: 'avatarUrl',
          type: 'string'
        },
        {
          control_type: 'text',
          label: 'Verified',
          toggle_hint: 'Select from option list',
          toggle_field: {
            label: 'Verified',
            control_type: 'boolean',
            hint: 'Allowed values: true, false',
            toggle_hint: 'Use custom value',
            type: 'boolean',
            name: 'verified'
          },
          pick_list: [
            [
              'True',
              true
            ],
            [
              'False',
              false
            ]
          ],
          type: 'boolean',
          name: 'verified'
        },
        {
          control_type: 'text',
          label: 'Bot',
          toggle_hint: 'Select from option list',
          toggle_field: {
            label: 'Bot',
            control_type: 'boolean',
            hint: 'Allowed values: true, false',
            toggle_hint: 'Use custom value',
            type: 'boolean',
            name: 'bot'
          },
          pick_list: [
            [
              'True',
              true
            ],
            [
              'False',
              false
            ]
          ],
          type: 'boolean',
          name: 'bot'
        },
        {
          control_type: 'date_time',
          label: 'Created at',
          parse_output: 'float_conversion',
          type: 'date_time',
          name: 'createdAt'
        },
        {
          control_type: 'date_time',
          label: 'Updated at',
          parse_output: 'float_conversion',
          type: 'date_time',
          name: 'updatedAt'
        }
      ]
    },
    convert_input_to_date: lambda do |response|
      date_fields = %w[createdAt start_date updatedAt last_contacted]
      response.map do |key, value|
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
    sample_contact: lambda do
      {
        'id': '1402403674',
        'createdAt': '2018-10-30T20:30:09.000+00:00',
        'attributes': {
          '_END_USER_VERSION': 40,
          '_end_user_version': 40,
          '_calculated_version': 40,
          'externalId': '',
          'last_name': 'Simon',
          'display_name': 'Greg Simon',
          'tags': [],
          'last_contacted': '2018-10-30T20:30:09.000+00:00',
          'employment_name': 'My company',
          'socialProfiles': {},
          'name': 'Greg Simon',
          'first_name': 'Greg',
          'email': 'test@test.com',
          'events': {},
          'start_date': '2018-10-30T20:30:09.000+00:00'
        }
      }
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
            { name: 'conversationId', type: 'integer' },
            { name: 'status', type: 'string' },
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
              { name: 'type', type: 'string' },
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
            { name: 'goalId', type: 'string' },
            { name: 'goalName', type: 'string' },
            { name: 'playbookName', type: 'string' },
            { name: 'contactEmail', type: 'string' }
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
          { name: 'label', type: 'string', optional: true },
          { name: 'value', type: 'string', optional: true },
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
    }
  },

  test: lambda { |_connection|
    get('/users/list')
  },

  actions: {
    get_contact_tags: {
      description: "Get <span class='provider'>tags</span> from contact in " \
      "<span class='provider'>Drift</span>",
      help: {
        body: "Uses Retrieving a contact's tags API",
        learn_more_text: "Retrieving a Contact's Tags API",
        learn_more_url: 'https://devdocs.drift.com/docs/' \
        'retrieving-a-contacts-tags'
      },
      input_fields: lambda { |_object_definitions|
        [{ name: 'contact_id', type: 'integer',
           control_type: 'integer', optional: false }]
      },
      output_fields: lambda { |object_definitions|
        [{ name: 'contact_tags', type: 'array',
           properties: object_definitions['contact_tag'] }]
      },
      execute: lambda { |_connection, input|
        { contact_tags:
          get("contacts/#{input['contact_id']}/tags")['data'] || [] }
      },
      sample_output: lambda { |_connection, _input|
        { contact_tags: { 'name': 'HOT LEAD', 'color': 'ff69b4' } }
      }
    },

    search_contacts: {
      description: "Search <span class='provider'>contacts</span> by email" \
        " in <span class='provider'>Drift</span>",
      help: {
        body: 'This action will search contacts by email, return maximum of ' \
        '100 contacts',
        learn_more_url: 'https://devdocs.drift.com/docs/retrieving-contact#' \
        'section-multiple-query-by-email',
        learn_more_text: 'Retrieving Contacts (Query by Email) API'
      },
      input_fields: lambda { |_object_definitions|
        [{ name: 'email', type: 'string',
           control_type: 'text', optional: false }]
      },
      output_fields: lambda { |object_definitions|
        [{ name: 'contacts', type: 'array',
           properties: object_definitions['contact'] }]
      },
      execute: lambda { |_connection, input|
        response = get('contacts').params(
          email: input['email'],
          limit: 100
        )['data']
        contacts = response.map do |contact|
          call('convert_input_to_date', contact)
        end
        { contacts: contacts }
      },
      sample_output: lambda {
        {
          contacts: call('sample_contact')
        }
      }
    },

    get_contact: {
      description: "Get a <span class='provider'>contact</span> by ID in " \
        "<span class='provider'>Drift</span>",
      help: {
        body: 'This action will search contact by ID',
        learn_more_url: 'https://devdocs.drift.com/docs/retrieving-contact#' \
        'section-single-query-by-id',
        learn_more_text: 'Retrieving Contacts (Query by ID) API'
      },
      input_fields: lambda { |_object_defintions|
        [{ name: 'contact_id', type: 'integer',
           control_type: 'integer', optional: false }]
      },
      output_fields: lambda { |object_definitions|
        object_definitions['contact']
      },
      execute: lambda { |_connection, input|
        call('convert_input_to_date',
             get("contacts/#{input['contact_id']}")['data'] || {})
      },
      sample_output: lambda {
        call('sample_contact')
      }
    },
    delete_contact: {
      description: "Delete a <span class='provider'>contact</span> in " \
        "<span class='provider'>Drift</span>",
      help: {
        body: 'Uses Deleting a Contact API',
        learn_more_text: 'Delete a Contact API',
        learn_more_url: 'https://devdocs.drift.com/docs/removing-a-contact'
      },
      input_fields: lambda { |_object_definitions|
        [{ name: 'contact_id', type: 'integer',
           control_type: 'integer', optional: false }]
      },
      output_fields: ->(_object_definitions) { [] },
      execute: lambda { |_connection, input|
        delete("contacts/#{input['contact_id']}")
      }
    },

    get_conversation: {
      description: "Get a <span class='provider'>conversation</span> by ID" \
        " in <span class='provider'>Drift</span>",
      help: {
        body: 'Uses Retrieving a Conversation API',
        learn_more_text: 'Retrieving a Conversation API',
        learn_more_url: 'https://devdocs.drift.com/docs/retrieve-a-conversation'
      },
      input_fields: lambda { |_object_definitions|
        [{ name: 'conversation_id', type: 'integer',
           control_type: 'integer', optional: false }]
      },
      output_fields: lambda { |object_definitions|
        object_definitions['conversation']
      },
      execute: lambda { |_connection, input|
        call('convert_input_to_date',
             get("/conversations/#{input['conversation_id']}")['data'])
      },
      sample_output: lambda {
        {
          'status': 'open',
          'participants': [],
          'contactId': '',
          'createdAt': '2018-11-04T07:53:58.000+00:00',
          'id': '283900395',
          'inboxId': ''
        }
      }
    },

    get_messages: {
      description: "Get <span class='provider'>messages</span> from " \
        "conversation in <span class='provider'>Drift</span>",
      help: {
        body: 'This action will return first 50 messages only. Use the' \
          ' <b>next</b> to handle pagination. <br/>Check more details ',
        learn_more_text: "Retrieving a Conversation's Messages API",
        learn_more_url: 'https://devdocs.drift.com/docs/retrieve-a-conversations-messages'
      },
      input_fields: lambda { |_object_definitions|
        [{ name: 'conversation_id', type: 'integer',
           control_type: 'integer', optional: false }]
      },
      output_fields: lambda { |object_definitions|
        [
          { name: 'messages', type: 'array',
            properties: object_definitions['message'] },
          {
            name: 'pagination', type: 'object',
            properties: [
              { name: 'more', type: 'boolean' },
              { name: 'next', type: 'string' }
            ]
          },
          {
            name: 'errors', type: 'array', of: 'object',
            properties: [
              { name: 'type', type: 'string' },
              { name: 'message', type: 'string' },
              { name: 'param', type: 'string' }
            ]
          }
        ]
      },
      execute: lambda { |_connection, input|
        response = get("/conversations/#{input['conversation_id']}/messages")
        messages = response['data']['messages'].map do |msg|
          call('convert_input_to_date', msg)
        end
        {
          messages: messages,
          pagination:
          response['pagination'].presence ? response['pagination'] : 0
        }
      },
      sample_output: lambda {
        {
          messages:
            {
              'id': '635760549',
              'conversationId': '284978449',
              'body': 'my message',
              'author': {
                'id': '1244074',
                'type': 'user',
                'bot': false
              },
              'type': 'chat',
              'createdAt': '2018-11-04T07:53:58.000+00:00',
              'context': {
                'IP': '',
                'location': {}
              }
            },
          pagination: { 'more': false }
        }
      }
    },

    get_user: {
      description: "Get a <span class='provider'>user</span> in " \
        "<span class='provider'>Drift</span>",
      help: {
        body: 'Uses Retrieving User API',
        learn_more_text: 'Retrieving User API',
        learn_more_url: 'https://devdocs.drift.com/docs/retrieving-user'
      },
      input_fields: lambda { |_object_definitions|
        [{ name: 'id', type: 'integer',
           control_type: 'integer', optional: false }]
      },
      output_fields: lambda { |object_definitions|
        object_definitions['user']
      },
      execute: lambda { |_connection, input|
        call('convert_input_to_date',
             get("/users/#{input['id']}")['data'] || {})
      },
      sample_output: lambda {
        call('convert_input_to_date', get('/users/list')['data'][0] || {})
      }
    },

    update_user: {
      description: "Update a <span class='provider'>user</span> in " \
        "<span class='provider'>Drift</span>",
      help: {
        body: 'Uses Updating a User API',
        learn_more_text: 'Updating a User API',
        learn_more_url: 'https://devdocs.drift.com/docs/updating-users'
      },
      input_fields: lambda do |_object_definitions|
        [
          { name: 'user_id', type: 'integer',
            control_type: 'integer', optional: false },
          { name: 'name', type: 'string', optional: true },
          { name: 'alias', type: 'string', optional: true },
          { name: 'email', type: 'string', optional: true,
            control_type: 'email' },
          { name: 'phone', type: 'string', optional: true },
          { name: 'locale', type: 'string', optional: true },
          { name: 'avatarUrl', type: 'string', optional: true,
            control_type: 'url' },
          {
            name: 'availability',
            type: 'string',
            optional: true,
            control_type: 'select',
            pick_list:
              [
                %w[Available AVAILABLE],
                %w[Offline OFFLINE]
              ],
            toggle_hint: 'Select from option list',
            toggle_field: {
              hint: 'Allowed values: AVAILABLE, OFFLINE',
              toggle_hint: 'Use custom value',
              type: 'string',
              control_type: 'text',
              name: 'availability'
            }
          }
        ]
      end,
      output_fields: lambda { |object_definitions|
        object_definitions['user']
      },
      execute: lambda { |_connection, input|
        call('convert_input_to_date',
             patch("/users/update?userId=#{input.delete('user_id')}").
                payload(input)['data'])
      },
      sample_output: lambda {
        call('convert_input_to_date', get('/users/list')['data'][0] || {})
      }
    },

    list_users: {
      description: "List <span class='provider'>users</span> in " \
        "<span class='provider'>Drift</span>",
      help: {
        body: 'Uses Listing Users API',
        learn_more_text: 'Listing Users API',
        learn_more_url: 'https://devdocs.drift.com/docs/listing-users'
      },
      input_fields: ->(_object_definitions) { [] },
      output_fields: lambda { |object_definitions|
        [{ name: 'users', type: 'array', of: 'object',
           properties: object_definitions['user'] }]
      },
      execute: lambda { |_connection, _input|
        response = get('/users/list')['data']
        users = response.map do |usr|
          call('convert_input_to_date', usr)
        end
        { users: users }
      },
      sample_output: lambda {
        users = call('convert_input_to_date',
                     get('/users/list')['data'][0] || {})
        { users: users }
      }
    },

    create_update_message: {
      description: "Create/update a <span class='provider'>message</span> " \
        "in <span class='provider'>Drift</span>",
      help: {
        body: 'Creates/updates a message in the conversation specified by ' \
          'the given conversation ID',
        learn_more_text: 'Creating a Message API',
        learn_more_url: 'https://devdocs.drift.com/docs/creating-a-message'
      },
      input_fields: lambda { |object_definitions|
        [
          {
            control_type: 'integer',
            label: 'Conversation ID',
            parse_output: 'integer_conversion',
            type: 'integer',
            name: 'conversationId',
            optional: false
          },
          {
            name: 'message',
            type: 'object',
            properties: [
              {
                name: 'type',
                type: 'string',
                hint: 'Specifies the type of the message',
                control_type: 'select',
                pick_list: 'message_types',
                optional: false,
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'type',
                  label: 'Type',
                  type: 'string',
                  control_type: 'string',
                  hint: 'Allowed values: chat, private_note, ' \
                    ' private_prompt, edit',
                  toggle_hint: 'Use custom value',
                  optional: false
                }
              },
              {
                name: 'body',
                type: 'string',
                hint: 'The message body supports basic HTML, no javascript',
                optional: true
              },
              {
                name: 'buttons',
                hint: 'MessageButton objects to include in the message body. ' \
                  'These will show up as clickable buttons in the posted' \
                  ' message.',
                type: 'array',
                of: 'object',
                optional: true,
                properties: object_definitions['message_button']
              },
              {
                name: 'editedMessageId',
                hint: 'Message ID of the message to edit',
                type: 'integer',
                control_type: 'integer',
                parse_output: 'integer_conversion',
                optional: true
              },
              {
                name: 'editType',
                type: 'string',
                hint: 'If specified, the edit type allows you to ' \
                  'mutate/delete existing messages in the conversation by ID',
                control_type: 'select',
                pick_list: 'edit_types',
                optional: true,
                toggle_hint: 'Select from option list',
                toggle_field: {
                  name: 'editType',
                  type: 'string',
                  label: 'Edit type',
                  control_type: 'string',
                  hint: 'Allowed values: delete, replace,' \
                    ' replace_body, replace_buttons',
                  toggle_hint: 'Use custom value',
                  optional: true
                }
              },
              {
                name: 'userId',
                hint: 'If userId not specified, the bot user for the account ' \
                  'will be used as the message author. You can also specify a' \
                  " userId of a known user in the organization's account here",
                type: 'integer',
                control_type: 'integer',
                parse_output: 'integer_conversion',
                optional: true
              }
            ]
          }
        ]
      },

      output_fields: lambda { |object_definitions|
        object_definitions['message']
      },
      execute: lambda { |_connection, input|
        message = post("/conversations/#{input['conversationId']}/messages").
                  payload(
                    type: input['message']['type'],
                    body: input['message']['body'],
                    buttons: input['message']['buttons'],
                    editedMessageId: input['message']['editedMessageId'],
                    editType: input['message']['editType'],
                    userId: input['message']['userId']
                  )['data']
        call('convert_input_to_date', message)
      },
      sample_output: lambda {
        {
          'id': '635760549',
          'conversationId': '284978449',
          'body': 'Sample message',
          'author': {
            'id': '123456',
            'type': 'user',
            'bot': false
          },
          'type': 'chat',
          'createdAt': '2018-10-30T20:30:07.000+00:00'
        }
      }
    },
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
            after_error_response(/[3-9]\d\d/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when 'post'
          post(input['path'], data).
            after_error_response(/[3-9]\d\d/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when 'put'
          put(input['path'], data).
            after_error_response(/[3-9]\d\d/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        when 'delete'
          delete(input['path'], data).
            after_error_response(/[3-9]\d\d/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end
        end
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['custom_action_output']
      end
    }
  },

  webhook_keys: lambda { |_params, _headers, payload|
    "#{payload['type']}&#{payload['token']}"
  },

  triggers: {
    new_event: {
      description: "New <span class='provider'>event</span> in " \
        "<span class='provider'>Drift</span>",
      config_fields: [
        {
          name: 'type',
          label: 'Type',
          control_type: 'select',
          pick_list: 'event_types',
          optional: false,
          toggle_hint: 'Select from option list',
          toggle_field: {
            hint: 'Allowed values: contact_identified, new_message, ' \
            'new_conversation, conversation_status_updated, conversation_' \
            'participant_added, conversation_participant_removed, button_' \
            'action, playbook_goal_met, user_unsubscribe',
            toggle_hint: 'Use custom value',
            type: 'string',
            name: 'type',
            label: 'Type',
            control_type: 'string',
            optional: false
          }
        }
      ],

      webhook_key: lambda { |connection, input|
        "#{input['type']}&#{connection['verification_token']}"
      },

      webhook_notification: lambda { |_connection, payload|
        payload
      },

      dedup: lambda { |event|
        "#{event['data']['id']}@#{event['data']['changedAt']}@#{event['type']}"
      },

      output_fields: lambda { |object_definitions|
        [
          { name: 'data', type: 'object',
            properties: object_definitions['event'] },
          { name: 'type', type: 'string' },
          { name: 'orgId', type: 'string' }
        ]
      },
      sample_output: lambda {
        {
          'orgId': 1,
          'type': 'conversation_status_updated',
          'data': {
            'id': '1234567',
            'conversationId': '1234567',
            'contactid': '1234567',
            'status': 'open',
            'createdAt': '2018-10-30T20:30:07.000+00:00',
            'changedAt': '2018-10-30T20:30:07.000+00:00'
          }
        }
      }
    }
  },

  pick_lists: {
    event_types: lambda { |_connection|
      [
        ['Contact identified', 'contact_identified'],
        ['New message', 'new_message'],
        ['New conversation', 'new_conversation'],
        ['Conversation status updated', 'conversation_status_updated'],
        ['Conversation participant added', 'conversation_participant_added'],
        ['Conversation participant removed',
         'conversation_participant_removed'],
        ['Button action', 'button_action'],
        ['Playbook goal met', 'playbook_goal_met'],
        ['User unsubscribed', 'user_unsubscribe']
      ]
    },
    message_types: lambda { |_connection|
      [
        %w[Chat chat],
        ['Private note', 'private_note'],
        ['Private prompt', 'private_prompt'],
        %w[Edit edit]
      ]
    },
    edit_types: lambda {
      [
        %w[Delete delete],
        %w[Replace replace],
        ['Replace body', 'replace_body'],
        ['Replace buttons', 'replace_buttons']
      ]
    },
    reaction_types: lambda {
      [
        %w[Delete delete],
        %w[Replace replace]
      ]
    },
    button_types: lambda {
      [
        %w[Reply reply],
        %w[Compose compose],
        %w[Action action]
      ]
    },
    button_styles: lambda {
      [
        %w[Primary primary],
        %w[Danger danger]
      ]
    }
  }
}
