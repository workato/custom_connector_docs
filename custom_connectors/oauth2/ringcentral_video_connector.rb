{
  title: 'RingCentral Video',

  connection: {
    fields: [
      {
        name: 'client_id',
        control_type: 'string',
        optional: false,
        hint: <<-HELP
          Create an app in your <a target='_blank' href='https://developers.ringcentral.com/my-account.html'>Developer portal account</a>
          to obtain your <b>Client ID</b> and <b>Client secret</b>.
          Click <a target='_blank' href='https://developers.ringcentral.com/guide/authentication'>here</a> to learn more.
        HELP
      },
      {
        name: 'client_secret',
        hint: 'The <b>client secret</b> provided by RingCentral after creating your app in the Developer portal.',
        control_type: 'password',
        optional: false
      }
    ],
    authorization: {
      type: 'oauth2',
      authorization_url: lambda do |connection|
        params = {
          response_type: 'code',
          client_id: connection['client_id'],
          redirect_uri: 'https://www.workato.com/oauth/callback'
        }.to_param
        'https://platform.ringcentral.com/restapi/oauth/authorize?' +
          params
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        post('https://platform.ringcentral.com/restapi/oauth/token').
          payload(grant_type: 'authorization_code',
                  client_id: connection['client_id'],
                  client_secret: connection['client_secret'],
                  code: auth_code,
                  redirect_uri: redirect_uri).
          request_format_www_form_urlencoded
      end,
      refresh_on: [401, 403],
      refresh: lambda do |connection, refresh_token|
        encode = "#{connection['client_id']}:#{connection['client_secret']}".encode_base64
        post('https://platform.ringcentral.com/restapi/oauth/token').
          payload(grant_type: 'refresh_token',
                  refresh_token: refresh_token).
          headers('Authorization': "Basic #{encode}").request_format_www_form_urlencoded
      end,
      apply: lambda do |_connection, access_token|
        headers('Authorization' => "Bearer #{access_token}")
      end
    },
    base_uri: lambda do |_connection|
      'https://platform.ringcentral.com'
    end
  },

  test: -> { get('/scim/v2/Users') },

  methods: {
    ### UTILITIES ###
    custom_input_parser: lambda do |input|
      input.each_with_object({}) do |(key, value), hash|
        if key.include?('_2_0_')
          key = "urn:ietf:params:scim:schemas:#{key.gsub('_2_0_', ':2.0:').gsub('_', ':')}"
        end
        hash[key] = value
      end
    end,
    custom_output_parser: lambda do |output|
      if output.is_a?(Array)
        output.map do |arr_value|
          call('custom_output_parser', arr_value)
        end
      else
        if output['schemas'].present?
          output['schemas'] = output['schemas']&.map do |schema|
            { 'value' => schema }
          end
        end
        if output['audioOptions'].present?
          output['audioOptions'] = output['audioOptions']&.map do |audio|
            { 'value' => audio }
          end
        end
        if output['addedPersonIds'].present?
          output['addedPersonIds'] = output['addedPersonIds']&.map do |person|
            { 'value' => person }
          end
        end
        if output['chatIds'].present?
          output['chatIds'] = output['chatIds']&.map do |chat|
            { 'value' => chat }
          end
        end
        output.each_with_object({}) do |(key, value), hash|
          if key.include?('urn:ietf:params:scim:schemas:')
            key = key.gsub('urn:ietf:params:scim:schemas:', '').gsub(/:|\./, '_')
          end
          if value.is_a?(Array) || value.is_a?(Hash)
            value = call('custom_output_parser', value)
          end
          hash[key] = value
        end
      end
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
          if value.is_a?(Array) || value.is_a?(Hash)
            value = call('format_payload', value)
          end
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
          if value.is_a?(Array) || value.is_a?(Hash)
            value = call('format_response', value)
          end
          hash[key] = value
        end
      else
        response
      end
    end,

    ### SAMPLE OUTPUTS ###
    search_sample_output: lambda do |input|
      input['accountId'] = '~'
      input['extensionId'] = '~'
      case input['object']
      when 'posts'
        chat_id = get('/restapi/v1.0/glip/chats?recordCount=1')&.dig('records', 0, 'id')
        call('search_posts_execute', 'chatId' => chat_id)
      when 'notes'
        chat_id = get('/restapi/v1.0/glip/chats?recordCount=1')&.dig('records', 0, 'id')
        call('search_notes_execute', 'chatId' => chat_id)
      when 'tasks'
        chat_id = get('/restapi/v1.0/glip/chats?recordCount=1')&.dig('records', 0, 'id')
        get("/restapi/v1.0/glip/chats/#{chat_id}/tasks?recordCount=1")
      when 'account_meeting_recordings', 'user_meeting_recordings'
        params = {
          meetingStartTimeFrom: '2020-01-01T00:00:00.000Z',
          meetingStartTimeTo: Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
          perPage: 100
        }
        get("/restapi/v1.0/account/#{input.delete('accountId')}/meeting-recordings", params)
      else
        call("search_#{input['object']}_execute", input)
      end
    end,
    get_sample_output: lambda do |input|
      input['accountId'] = '~'
      input['extensionId'] = '~'
      case input['object']
      when 'users', 'user'
        call('search_users_execute', input)&.[]('Resources')&.first
      when 'post'
        chat_id = get('/restapi/v1.0/glip/chats?recordCount=1')&.dig('records', 0, 'id')
        call('search_posts_execute', 'chatId' => chat_id)&.[]('records')&.first
      when 'note'
        chat_id = get('/restapi/v1.0/glip/chats?recordCount=1')&.dig('records', 0, 'id')
        call('search_notes_execute', 'chatId' => chat_id)&.[]('records')&.first
      when 'team'
        call('search_teams_execute', 'recordCount' => 1)&.[]('records')&.first
      when 'team_members'
        { result: 'Successfully added.' }
      when 'calendar_event'
        call('search_calendar_events_execute', 'recordCount' => 1)&.[]('records')&.first
      when 'task'
        chat_id = get('/restapi/v1.0/glip/chats?recordCount=1')&.dig('records', 0, 'id')
        get("/restapi/v1.0/glip/chats/#{chat_id}/tasks?recordCount=1")&.[]('records')&.first
      when 'everyone_chat'
        {
          id: '52342',
          creationTime: '2015-03-31T16:00:00.000Z',
          lastModifiedTime: '2018-07-31T18:00:00.000Z',
          type: 'Everyone',
          name: 'Chat name',
          description: 'Chat description'
        }
      when 'user_call_record'
        call('search_user_call_log_records_execute', input)&.[]('records')&.first
      when 'ringout_call'
        call('ringout_call_sample_output', '')
      when 'call_recording'
        {
          id: '401786818008',
          contentUri: 'https://platform.ringcentral.com/restapi/v1.0/account/401452676008/recording/401786818008/content',
          contentType: 'audio/x-wav',
          duration: 30
        }
      when 'callout_session_status'
        call('callout_sample_output', '')
      else
        object = input['object'].pluralize
        call("search_#{object}_execute", input)&.[]('records')&.first
      end
    end,
    ringout_call_sample_output: lambda do |_input|
      {
        'uri': 'https://platform.ringcentral.com/restapi/v1.0/account/123/extension/123/ring-out/s-123',
        'id': 's-123',
        'status': {
          'callStatus': 'InProgress',
          'callerStatus': 'InProgress',
          'calleeStatus': 'InProgress'
        }
      }
    end,
    send_sms_sample_output: lambda do |_input|
      {
        uri: 'https://platform.ringcentral.com/restapi/v1.0/account/1933605021/extension/1933605021/message-store/1150778182020',
        id: '1150778182020',
        to: [
          {
            phoneNumber: '+16504590478',
            location: 'Half Moon Bay, CA'
          }
        ],
        from: {
          phoneNumber: '+16503766229',
          name: 'Dev partner 8',
          location: 'San Mateo, CA'
        },
        type: 'SMS',
        creationTime: '2020-04-29T11:46:22.000Z',
        readStatus: 'Read',
        priority: 'Normal',
        attachments: [
          {
            id: '1150778182020',
            uri: 'https://platform.ringcentral.com/restapi/v1.0/account/1933605021/extension/1933605021/message-store/1150778182020/content/1150778182020',
            type: 'Text',
            contentType: 'text/plain'
          }
        ],
        direction: 'Outbound',
        availability: 'Alive',
        subject: 'TEST SMS',
        messageStatus: 'Queued',
        smsSendingAttemptsCount: 1,
        conversationId: '6537012962707654000',
        conversation: {
          id: '6537012962707653893',
          uri: 'https://platform.ringcentral.com/restapi/v1.0/conversation/6537012962707653893'
        },
        lastModifiedTime: '2020-04-29T11:46:22.241Z'
      }
    end,
    callout_sample_output: lambda do |_input|
      {
        session: {
          creationTime: '2019-08-19T11:42:21Z',
          id: 's-54a38392c79849dab4a25fe8040edd53',
          origin: {
            type: 'Call'
          },
          parties: [
            {
              direction: 'Outbound',
              from: {
                deviceId: '803469127021',
                extensionId: '297277020',
                name: 'John Smith',
                phoneNumber: '+18885287464'
              },
              id: 'p-54a38392c79849dab4a25fe8040edd53-1',
              muted: false,
              owner: {
                accountId: '37439510',
                extensionId: '297277020'
              },
              standAlone: false,
              status: {
                "code": 'Setup'
              },
              to: {
                phoneNumber: '+79817891689'
              }
            }
          ]
        }
      }
    end,
    reply_with_text_sample_output: lambda do |_input|
      {
        accountId: '1933605021',
        direction: 'Inbound',
        extensionId: '1933605021',
        from: {
          deviceId: '804543271020',
          extensionId: '3342526020',
          name: 'Joshua Aaron Navarro',
          phoneNumber: '120'
        },
        id: 'p-15640f2ae96045cbb03e3bae04a6a874-2',
        muted: false,
        owner: {
          accountId: '1933605021',
          extensionId: '1933605021'
        },
        standAlone: false,
        status: {
          code: 'Setup',
          reason: 'CallReplied'
        },
        to: {
          extensionId: '1933605021',
          name: 'Dev partner 8',
          phoneNumber: '101'
        }
      }
    end,

    ### CREATE METHODS ###
    create_meeting_schema: lambda do |_input|
      timezone_id = get('/restapi/v1.0/dictionary/timezone?page=1&perPage=100')['records'].pluck('name', 'id') || []
      [
        { name: 'accountId', optional: false,
          hint: 'Internal identifier of a RingCentral account or tilde (~) to indicate the extension assigned
          to the account logged-in within the current session' },
        { name: 'extensionId', optional: false,
          hint: 'Internal identifier of an extension or tilde (~) to indicate the extension assigned
          to the account logged-in within the current session' },
        { name: 'topic', sticky: true },
        {
          name: 'meetingType',
          control_type: 'select',
          pick_list: 'meetingType',
          sticky: true,
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'meetingType',
            label: 'Meeting type',
            type: 'string',
            control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: Scheduled, Instant, Recurring'
          }
        },
        { name: 'schedule', type: 'object', sticky: true,
          properties: [
            { name: 'startTime', type: 'date_time', sticky: true,
              parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp' },
            { name: 'durationInMinutes', type: 'integer',
              sticky: true, control_type: 'integer', render_input: :integer_conversion,
              parse_output: :integer_conversion },
            { name: 'timeZone', type: 'object', sticky: true,
              properties: [
                { name: 'id', label: 'Timezone', sticky: true, control_type: 'select',
                  hint: 'Please select the timezone.',
                  pick_list: timezone_id,
                  toggle_hint: 'Select from options',
                  toggle_field: {
                    name: 'id', label: 'Timezone ID', type: 'string', optional: true,
                    control_type: 'text', toggle_hint: 'Use custom value',
                    hint: 'Please enter the internal identifier of a timezone.<br>' \
                    'You can use the <b>Search timezone</b> action to retrieve the Timezone ID.'
                  } }
              ] }
          ] },
        { name: 'password', sticky: true },
        { name: 'host', type: 'object', sticky: true,
          properties: [
            { name: 'uri', label: 'URI', sticky: true, hint: 'Link to the meeting host resource' },
            { name: 'id', sticky: true, hint: 'Internal identifier of an extension which is assigned to be a meeting host' }
          ] },
        {
          name: 'allowJoinBeforeHost',
          control_type: 'checkbox',
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          sticky: true,
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'allowJoinBeforeHost',
            type: 'boolean',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            label: 'Allow join before host',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          }
        },
        {
          name: 'startHostVideo',
          control_type: 'checkbox',
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          sticky: true,
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'startHostVideo',
            type: 'boolean',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            label: 'Start host video',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          }
        },
        {
          name: 'startParticipantsVideo',
          control_type: 'checkbox',
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          sticky: true,
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'startParticipantsVideo',
            type: 'boolean',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            label: 'Start participants video',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          }
        },
        {
          name: 'usePersonalMeetingId',
          control_type: 'checkbox',
          type: 'boolean',
          sticky: true,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'usePersonalMeetingId',
            type: 'boolean',
            control_type: 'text',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            label: 'Use personal meeting ID',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          }
        },
        { name: 'audioOptions', control_type: 'multiselect', delimiter: ',',
          pick_list: 'audioOptions', toggle_hint: 'Select from options',
          toggle_field: {
            name: 'audioOptions',
            toggle_hint: 'Use custom value',
            label: 'Audio options',
            type: 'text',
            control_type: 'text',
            optional: false,
            hint: 'Allowed values: Phone, ComputerAudio. Please enter values separated by commas, without spaces.'
          } },
        { name: 'recurrence', type: 'object',
          properties: [
            {
              name: 'frequency',
              control_type: 'select',
              sticky: true,
              hint: 'Recurrence time frame',
              pick_list: [
                %w[Daily Daily],
                %w[Weekly Weekly],
                %w[Monthly Monthly]
              ],
              toggle_hint: 'Select from list',
              toggle_field:
              {
                name: 'frequency',
                type: 'string',
                control_type: 'text',
                label: 'Frequency',
                toggle_hint: 'Use custom value',
                optional: true,
                hint: 'Allowed values are: Daily, Weekly, Monthly'
              }
            },
            { name: 'interval', type: 'integer', label: 'Interval',
              render_input: :integer_conversion,
              parse_output: :integer_conversion, hint: 'Reccurence interval. ' \
                'The supported ranges are: 1-90 for Daily; 1-12 for Weekly; 1-3 for Monthly' },
            {
              name: 'monthlyByWeek',
              control_type: 'select',
              sticky: true,
              hint: 'Supported together with <b>Weekly by day</b>',
              pick_list: [
                %w[Last Last],
                %w[First First],
                %w[Second Second],
                %w[Third Third],
                %w[Fourth Fourth]
              ],
              toggle_hint: 'Select from list',
              toggle_field:
              {
                name: 'monthlyByWeek',
                type: 'string',
                control_type: 'text',
                label: 'Monthly by week',
                toggle_hint: 'Use custom value',
                optional: true,
                hint: 'Allowed values are: Last, First, Second, Third, Fourth'
              }
            },
            {
              name: 'weeklyByDays',
              control_type: 'multiselect',
              delimiter: ',',
              optional: true,
              sticky: true,
              pick_list: [
                %w[Sunday Sunday],
                %w[Monday Monday],
                %w[Tuesday Tuesday],
                %w[Wednesday Wednesday],
                %w[Thursday Thursday],
                %w[Friday Friday],
                %w[Saturday Saturday]
              ],
              toggle_hint: 'Select from list',
              toggle_field:
              {
                name: 'weeklyByDays',
                type: 'string',
                control_type: 'text',
                label: 'Weekly by days',
                toggle_hint: 'Use custom value',
                optional: true,
                hint: 'Allowed values are: Sunday, Monday, Tuesday, Wednesday,
                Thursday, Friday, Saturday'
              }
            },
            { name: 'monthlyByDay', type: 'integer', sticky: true,
              render_input: :integer_conversion,
              parse_output: :integer_conversion, hint: 'The supported range is 1-31' },
            { name: 'count', type: 'integer', sticky: true,
              render_input: :integer_conversion,
              parse_output: :integer_conversion, hint: 'Number of occurences' },
            { name: 'until', hint: 'Meeting expiration datetime',
              type: 'date_time', sticky: true,
              parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp' }
          ] },
        {
          name: 'autoRecordType',
          control_type: 'select',
          sticky: true,
          pick_list: [
            %w[Local Local],
            %w[Cloud Cloud],
            %w[None None]
          ],
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'autoRecordType',
            type: 'string',
            control_type: 'text',
            label: 'Auto record type',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: Local, Cloud, None'
          }
        }
      ]
    end,
    create_meeting_output_schema: lambda do |_input|
      [
        { name: 'uri', label: 'URI' },
        { name: 'uuid', label: 'UUID' },
        { name: 'id' },
        { name: 'topic' },
        { name: 'meetingType' },
        { name: 'password' },
        { name: 'h323Password', label: 'H323 password' },
        { name: 'status' },
        { name: 'links', type: 'object',
          properties: [
            { name: 'startUri', label: 'Start URI' },
            { name: 'joinUri', label: 'Join URI' }
          ] },
        { name: 'schedule', type: 'object',
          properties: [
            { name: 'startTime', type: 'date_time', control_type: 'date_time',
              parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp' },
            { name: 'durationInMinutes', type: 'integer', render_input: :integer_conversion,
              parse_output: :integer_conversion },
            { name: 'timeZone', type: 'object',
              properties: [
                { name: 'uri', label: 'URI' },
                { name: 'id' },
                { name: 'name' },
                { name: 'description' }
              ] }
          ] },
        { name: 'host', type: 'object',
          properties: [
            { name: 'uri', label: 'URI' },
            { name: 'id' }
          ] },
        { name: 'allowJoinBeforeHost', type: 'boolean', render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion' },
        { name: 'startHostVideo', type: 'boolean', render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion' },
        { name: 'startParticipantsVideo', type: 'boolean', render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion' },
        { name: 'usePersonalMeetingId', type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion' },
        { name: 'audioOptions', type: 'array', of: 'object',
          properties: [
            { name: 'value' }
          ] },
        { name: 'occurrences', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'startTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'durationInMinutes', type: 'integer',
              render_input: :integer_conversion,
              parse_output: :integer_conversion },
            { name: 'status' }
          ] }
      ]
    end,
    create_meeting_execute: lambda do |input|
      input['audioOptions'] = input['audioOptions']&.split(',') || nil
      input['recurrence']['weeklyByDays'] = input['recurrence']['weeklyByDays']&.split(',') || nil
      post("/restapi/v1.0/account/#{input.delete('accountId')}/extension/" \
           "#{input.delete('extensionId')}/meeting", input.compact.except('object'))
    end,

    create_user_schema: lambda do |_input|
      country = get('/restapi/v1.0/dictionary/country?page=1&perPage=300')['records'].pluck('name', 'name') || []
      state = get('/restapi/v1.0/dictionary/state?allCountries=true&countryId=1&page=1&perPage=500&withPhoneNumbers=false')['records'].
              pluck('name', 'name') || []
      [
        { name: 'externalId', hint: 'External unique resource ID defined by provisioning client', sticky: true },
        { name: 'userName', label: 'User name', hint: 'Must be same as work type email address',
          optional: false },
        {
          name: 'active',
          control_type: 'checkbox',
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          sticky: true,
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'active',
            type: 'boolean',
            control_type: 'text',
            label: 'Active',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          }
        },
        { name: 'addresses', type: 'array', of: 'object', list_mode: 'static',
          item_label: 'Address', add_item_label: 'Add addresses tag',
          empty_list_title: 'Specify addresses',
          properties: [
            {
              name: 'type',
              control_type: 'select',
              pick_list: [
                %w[Work work]
              ],
              sticky: true,
              toggle_hint: 'Select from list',
              toggle_field:
              {
                name: 'type',
                type: 'string',
                control_type: 'text',
                label: 'Type',
                optional: true,
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are work'
              }
            },
            { name: 'streetAddress', sticky: true },
            { name: 'locality', sticky: true },
            { name: 'region', sticky: true, control_type: 'select',
              hint: 'Please select the region or state.',
              pick_list: state,
              toggle_hint: 'Select from options',
              toggle_field: {
                name: 'region', label: 'Region', type: 'string', optional: true,
                control_type: 'text', toggle_hint: 'Use custom value',
                hint: 'Please enter the region or state name.'
              } },
            { name: 'country', sticky: true, control_type: 'select',
              pick_list: country,
              extends_schema: true,
              toggle_hint: 'Select from options',
              toggle_field: {
                name: 'country', label: 'Country', type: 'string', optional: true,
                control_type: 'text', toggle_hint: 'Use custom value',
                hint: 'Please enter the country name. ' \
                "Click <a target='_blank' href='https://en.wikipedia.org/wiki/List_of_country-name_etymologies'>here</a> to learn more."
              } },
            { name: 'postalCode', sticky: true }
          ] },
        { name: 'emails', type: 'array', of: 'object', optional: false,
          item_label: 'Email', add_item_label: 'Add emails tag',
          empty_list_title: 'Specify emails',
          properties: [
            {
              name: 'type',
              control_type: 'select',
              pick_list: [
                %w[Work work]
              ],
              optional: false,
              toggle_hint: 'Select from list',
              toggle_field:
              {
                name: 'type',
                type: 'string',
                control_type: 'text',
                label: 'Type',
                toggle_hint: 'Use custom value',
                optional: false,
                hint: 'Allowed values are work'
              }
            },
            { name: 'value', optional: false,
              hint: 'Value should be a valid email, e.g. example@example.com' }
          ] },
        { name: 'name', type: 'object', optional: false,
          properties: [
            { name: 'familyName', optional: false },
            { name: 'givenName', optional: false }
          ] },
        { name: 'phoneNumbers', type: 'array', of: 'object', list_mode: 'static',
          item_label: 'Phone number', add_item_label: 'Add phone numbers tag',
          empty_list_title: 'Specify phone numbers', sticky: true,
          properties: [
            {
              name: 'type',
              sticky: true,
              control_type: 'select',
              pick_list: 'phoneType',
              toggle_hint: 'Select from list',
              toggle_field:
              {
                name: 'type',
                type: 'string',
                control_type: 'text',
                label: 'Type',
                optional: true,
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are work, mobile, or other'
              }
            },
            { name: 'value', sticky: true,
              hint: 'Value should be a valid phone number, e.g. +16504356474' }
          ] },
        { name: 'photos', type: 'array', of: 'object', list_mode: 'static',
          item_label: 'Photo', add_item_label: 'Add photos tag',
          empty_list_title: 'Specify photos',
          sticky: true,
          properties: [
            {
              name: 'type',
              control_type: 'select',
              pick_list: 'photoType',
              sticky: true,
              toggle_hint: 'Select from list',
              toggle_field:
              {
                name: 'type',
                type: 'string',
                control_type: 'text',
                label: 'Type',
                optional: true,
                toggle_hint: 'Use custom value',
                hint: 'Allowed value is Photo'
              }
            },
            { name: 'value', sticky: true,
              hint: 'Value should be a valid URL, e.g. https//:wwww.example.com/test.jpg' }
          ] },
        { name: 'schemas',
          control_type: 'multiselect',
          delimiter: '|',
          pick_list: 'schemasType',
          optional: false,
          hint: 'Select one or more schemas to assign',
          toggle_hint: 'Select from schemas',
          toggle_field: {
            name: 'schemas',
            toggle_hint: 'Use custom value',
            change_on_blur: true,
            label: 'Schemas',
            type: 'text',
            control_type: 'text',
            optional: false,
            hint: 'Allowed values are urn:ietf:params:scim:schemas:core:2.0:User,
            urn:ietf:params:scim:schemas:extension:enterprise:2.0:User'
          } },
        { name: 'extension_enterprise_2_0_User', label: 'Schemas extension enterprise 2.0 User', type: 'object',
          properties: [
            { name: 'department' }
          ] }
      ]
    end,
    create_user_output_schema: lambda do |_input|
      [
        { name: 'schemas', type: 'array', of: 'object',
          properties: [
            { name: 'value' }
          ] },
        { name: 'id' },
        { name: 'externalId' },
        { name: 'meta', type: 'object',
          properties: [
            { name: 'resourceType' },
            { name: 'created', type: 'date_time', control_type: 'date_time',
              render_input: 'render_iso8601_timestamp', parse_output: 'date_time_conversion' },
            { name: 'lastModified', type: 'date_time', control_type: 'date_time',
              render_input: 'render_iso8601_timestamp', parse_output: 'date_time_conversion' },
            { name: 'location' }
          ] },
        { name: 'userName' },
        { name: 'name', type: 'object',
          properties: [
            { name: 'formatted' },
            { name: 'familyName' },
            { name: 'givenName' }
          ] },
        { name: 'active', type: 'boolean', render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion' },
        { name: 'emails', type: 'array', of: 'object',
          properties: [
            { name: 'primary' },
            { name: 'value' },
            { name: 'type' }
          ] },
        { name: 'phoneNumbers', type: 'array', of: 'object',
          properties: [
            { name: 'value' },
            { name: 'type' }
          ] },
        { name: 'photos', type: 'array', of: 'object',
          properties: [
            { name: 'value' },
            { name: 'type' }
          ] },
        { name: 'addresses', type: 'array', of: 'object',
          properties: [
            { name: 'type' },
            { name: 'streetAddress' },
            { name: 'locality' },
            { name: 'region' },
            { name: 'country' },
            { name: 'postalCode' }
          ] },
        { name: 'extension_enterprise_2_0_User', type: 'object',
          properties: [
            { name: 'department' }
          ] }
      ]
    end,
    create_user_execute: lambda do |input|
      input['schemas'] = input['schemas']&.split('|') || nil
      post('/scim/v2/Users', input.compact.except('object'))
    end,

    create_contact_schema: lambda do |_input|
      state = get('/restapi/v1.0/dictionary/state?allCountries=true&countryId=1&page=1&perPage=500&withPhoneNumbers=false')['records'].
              pluck('name', 'name') || []
      [
        { name: 'accountId', optional: false,
          hint: 'Internal identifier of a RingCentral account or tilde (~) to ' \
          'indicate the account logged-in within the current session' },
        { name: 'extensionId', optional: false,
          hint: 'Internal identifier of an extension or tilde (~) to indicate the extension assigned
          to the account logged-in within the current session' },
        { name: 'firstName', hint: 'First name of the contact', sticky: true },
        { name: 'lastName', hint: 'Last name of the contact', sticky: true },
        { name: 'middleName', hint: 'Middle name of the contact', sticky: true },
        { name: 'nickName', label: 'Nickname', hint: 'Nick name of the contact', sticky: true },
        { name: 'company', hint: 'Company name of the contact', sticky: true },
        { name: 'jobTitle', hint: 'Job Title of the contact', sticky: true },
        { name: 'email', hint: 'Email of the contact', sticky: true },
        { name: 'email2', label: 'Email 2', hint: 'Second email of the contact', sticky: true },
        { name: 'email3', label: 'Email 3', hint: 'Third email of the contact', sticky: true },
        { name: 'birthday', type: 'date', hint: 'Date of birth of the contact', sticky: true },
        { name: 'webPage', hint: 'The contact home page URL', sticky: true },
        { name: 'notes', hint: 'Notes for the contact' },
        { name: 'homePhone', hint: 'Home phone number of the contact in e.164 (with "+") format. e.g. +15551234567' },
        { name: 'homePhone2', label: 'Home Phone 2', hint: '2nd home phone number of the contact ' \
          'in e.164 (with "+") format. e.g. +15551234567' },
        { name: 'businessPhone', hint: 'Business phone of the contact in e.164 (with "+") format. e.g. +15551234567' },
        { name: 'businessPhone2', label: 'Business phone 2',
          hint: '2nd business phone of the contact in e.164 (with "+") format. e.g. +15551234567' },
        { name: 'mobilePhone', hint: 'Mobile phone of the contact in e.164 (with "+") format. e.g. +15551234567' },
        { name: 'businessFax', hint: 'Business fax number of the contact in e.164 (with "+") format. e.g. +15551234567' },
        { name: 'companyPhone', hint: 'Company number of the contact in e.164 (with "+") format. e.g. +15551234567' },
        { name: 'assistantPhone', hint: 'Phone number of the contact assistant in e.164 (with "+") format. e.g. +15551234567' },
        { name: 'carPhone', hint: 'Car phone number of the contact in e.164 (with "+") format. e.g. +15551234567' },
        { name: 'otherPhone', hint: 'Other phone number of the contact in e.164 (with "+") format. e.g. +15551234567' },
        { name: 'otherFax', hint: 'Other fax number of the contact in e.164 (with "+") format. e.g. +15551234567' },
        { name: 'callbackPhone', hint: 'Callback phone number of the contact in e.164 (with "+") format. e.g. +15551234567' },
        { name: 'homeAddress', type: 'object',
          properties: [
            { name: 'street', hint: 'Street address' },
            { name: 'city', hint: 'City name' },
            { name: 'state', sticky: true, control_type: 'select',
              hint: 'Please select the province or state.',
              pick_list: state,
              toggle_hint: 'Select from options',
              toggle_field: {
                name: 'state', label: 'State name', type: 'string', optional: true,
                control_type: 'text', toggle_hint: 'Use custom value',
                hint: 'Please enter the province or state name.'
              } },
            { name: 'zip', hint: 'Zip/Postal code' }
          ] },
        { name: 'businessAddress', type: 'object',
          properties: [
            { name: 'street', hint: 'Street address' },
            { name: 'city', hint: 'City name' },
            { name: 'state', sticky: true, control_type: 'select',
              hint: 'Please select the province or state.',
              pick_list: state,
              toggle_hint: 'Select from options',
              toggle_field: {
                name: 'state', label: 'State name', type: 'string', optional: true,
                control_type: 'text', toggle_hint: 'Use custom value',
                hint: 'Please enter the province or state name.'
              } },
            { name: 'zip', hint: 'Zip/Postal code' }
          ] },
        { name: 'otherAddress', type: 'object', label: 'Other address',
          properties: [
            { name: 'street', hint: 'Street address' },
            { name: 'city', hint: 'City name' },
            { name: 'state', sticky: true, control_type: 'select',
              hint: 'Please select the province or state.',
              pick_list: state,
              toggle_hint: 'Select from options',
              toggle_field: {
                name: 'state', label: 'State name', type: 'string', optional: true,
                control_type: 'text', toggle_hint: 'Use custom value',
                hint: 'Please enter the province or state name.'
              } },
            { name: 'zip', hint: 'Zip/Postal code' }
          ] }
      ]
    end,
    create_contact_output_schema: lambda do |_input|
      [
        { name: 'uri' },
        { name: 'availability' },
        { name: 'id', type: 'integer', render_input: :integer_conversion,
          parse_output: :integer_conversion },
        { name: 'firstName' },
        { name: 'lastName' },
        { name: 'middleName' },
        { name: 'nickName' },
        { name: 'company' },
        { name: 'jobTitle' },
        { name: 'email' },
        { name: 'email2', label: 'Email 2' },
        { name: 'email3', label: 'Email 3' },
        { name: 'birthday', type: 'date_time', control_type: 'date_time',
          parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp' },
        { name: 'webPage' },
        { name: 'notes' },
        { name: 'homePhone' },
        { name: 'homePhone2' },
        { name: 'businessPhone' },
        { name: 'businessPhone2' },
        { name: 'mobilePhone' },
        { name: 'businessFax' },
        { name: 'companyPhone' },
        { name: 'assistantPhone' },
        { name: 'carPhone' },
        { name: 'otherPhone' },
        { name: 'otherFax' },
        { name: 'callbackPhone' },
        { name: 'homeAddress', type: 'object',
          properties: [
            { name: 'street' },
            { name: 'city' },
            { name: 'state' },
            { name: 'zip' }
          ] },
        { name: 'businessAddress', type: 'object',
          properties: [
            { name: 'street' },
            { name: 'city' },
            { name: 'state' },
            { name: 'zip' }
          ] },
        { name: 'otherAddress', type: 'object',
          properties: [
            { name: 'street' },
            { name: 'city' },
            { name: 'state' },
            { name: 'zip' }
          ] }
      ]
    end,
    create_contact_execute: lambda do |input|
      post("/restapi/v1.0/account/#{input.delete('accountId')}/extension/" \
           "#{input.delete('extensionId')}/address-book/contact", input.except('object'))
    end,

    create_ringout_call_schema: lambda do |_input|
      calling_code = get('/restapi/v1.0/dictionary/country?page=1&perPage=300')['records'].
                     pluck('name', 'callingCode').group_by { |(_country, code)| code }.
                     map { |code, match| [match.map { |items| items[0] }.join('/'), code] }.
                     map do |countries|
                       if countries.first.include?('Canada')
                         ['Canada/United States', countries.last]
                       elsif countries.first.include?('Bonaire')
                         ['Bonaire/Curacao', countries.last]
                       elsif countries.first.include?('United Kingdom')
                         ['United Kingdom', countries.last]
                       else
                         [countries.first, countries.last]
                       end
                     end || []
      [
        { name: 'accountId', optional: false,
          hint: 'Internal identifier of a RingCentral account or tilde (~) to ' \
          'indicate the account logged-in within the current session' },
        { name: 'extensionId', optional: false,
          hint: 'Internal identifier of an extension or tilde (~) to indicate ' \
          'the extension assigned to the account logged-in within the current session' },
        { name: 'from', type: 'object', optional: false,
          properties: [
            { name: 'phoneNumber', hint: 'Phone number in E.164 format, e.g. +14155552671', optional: false },
            { name: 'forwardingNumberId', hint: 'Internal identifier of a forwarding number', sticky: true }
          ] },
        { name: 'to', type: 'object', optional: false,
          properties: [
            { name: 'phoneNumber', hint: 'Phone number in E.164 format, e.g.+14155552671', optional: false }
          ] },
        { name: 'callerId', type: 'object', label: 'Caller ID', sticky: true,
          properties: [
            { name: 'phoneNumber', hint: 'Phone number in E.164 format, e.g.+14155552671', sticky: true }
          ] },
        {
          name: 'playPrompt',
          control_type: 'checkbox',
          sticky: true,
          type: :boolean,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'The audio prompt that the calling party hears when the call is connected',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'playPrompt',
            type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'text',
            label: 'Play prompt',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          }
        },
        { name: 'country', type: 'object', label: 'Country', sticky: true,
          properties: [
            { name: 'id', label: 'Country name', sticky: true, control_type: 'select',
              pick_list: calling_code,
              toggle_hint: 'Select from options',
              toggle_field: {
                name: 'id', label: 'Country code', type: 'string', optional: true,
                control_type: 'text', toggle_hint: 'Use custom value',
                hint: 'Please enter the dialing plan country identifier. ' \
                "Click <a target='_blank' href='https://en.wikipedia.org/wiki/List_of_country_calling_codes'>here</a> to learn more."
              } }
          ] }
      ]
    end,
    create_ringout_call_output_schema: lambda do |_input|
      [
        { name: 'uri', label: 'URI' },
        { name: 'id' },
        { name: 'status', type: 'object',
          properties: [
            { name: 'callStatus' },
            { name: 'callerStatus' },
            { name: 'calleeStatus' }
          ] }
      ]
    end,
    create_ringout_call_execute: lambda do |input|
      post("/restapi/v1.0/account/#{input.delete('accountId')}/extension/" \
           "#{input.delete('extensionId')}/ring-out", input.except('object'))
    end,

    create_reply_with_text_schema: lambda do |_input|
      [
        { name: 'accountId', optional: false,
          hint: 'Internal identifier of a RingCentral account or tilde (~) to indicate ' \
          'the extension assigned to the account logged-in within the current session' },
        { name: 'telephonySessionId', optional: false, hint: 'Internal identifier of a call session' },
        { name: 'partyId', optional: false, hint: 'Internal identifier of a call party ID' },
        { name: 'replyWithText', hint: 'Text to reply', sticky: true },
        { name: 'replyWithPattern', type: 'object',
          properties: [
            {
              name: 'pattern',
              control_type: 'select',
              sticky: true,
              hint: 'Predefined reply pattern name',
              pick_list: [
                %w[Will\ call\ you\ back WillCallYouBack],
                %w[Call\ me\ back CallMeBack],
                %w[On\ my\ way OnMyWay],
                %w[On\ the\ other\ line OnTheOtherLine],
                %w[Will\ call\ you\ back\ later WillCallYouBackLater],
                %w[Call\ me\ back\ later CallMeBackLater],
                %w[In\ a\ meeting InAMeeting],
                %w[On\ the\ other\ line\ no\ call OnTheOtherLineNoCall]
              ],
              toggle_hint: 'Select from list',
              toggle_field:
              {
                name: 'pattern',
                control_type: 'text',
                type: 'string',
                label: 'Pattern',
                toggle_hint: 'Use custom value',
                optional: true,
                hint: 'Allowed values are: WillCallYouBack, CallMeBack, OnMyWay, OnTheOtherLine,
                       WillCallYouBackLater'
              }
            },
            { name: 'time', type: 'integer', render_input: :integer_conversion,
              parse_output: :integer_conversion, hint: 'Number of time units. Applicable only ' \
              'to <b>Will call you back</b>, <b>Call me back</b> patterns.', sticky: true },
            {
              name: 'timeUnit',
              control_type: 'select',
              sticky: true,
              hint: 'Time unit name',
              pick_list: [
                %w[Minute Minute],
                %w[Hour Hour],
                %w[Day Day]
              ],
              toggle_hint: 'Select from list',
              toggle_field:
              {
                name: 'timeUnit',
                control_type: 'text',
                type: 'string',
                label: 'Time unit',
                toggle_hint: 'Use custom value',
                optional: true,
                hint: 'Allowed values are: Minute, Hour, Day'
              }
            }
          ] }
      ]
    end,
    create_reply_with_text_output_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'status', type: 'object',
          properties: [
            { name: 'code' },
            { name: 'peerId', type: 'object',
              properties: [
                { name: 'sessionId' },
                { name: 'telephonySessionId' },
                { name: 'partyId' }
              ] },
            { name: 'reason' },
            { name: 'description' }
          ] },
        { name: 'muted' },
        { name: 'standAlone' },
        { name: 'park', type: 'object',
          properties: [
            { name: 'id' }
          ] },
        { name: 'from', type: 'object',
          properties: [
            { name: 'phoneNumber' },
            { name: 'name' },
            { name: 'deviceId' },
            { name: 'extensionId' }
          ] },
        { name: 'to', type: 'object',
          properties: [
            { name: 'phoneNumber' },
            { name: 'name' },
            { name: 'deviceId' },
            { name: 'extensionId' }
          ] },
        { name: 'owner', type: 'object',
          properties: [
            { name: 'accountId' },
            { name: 'extensionId' }
          ] },
        { name: 'direction' }
      ]
    end,
    create_reply_with_text_execute: lambda do |input|
      post("/restapi/v1.0/account/#{input.delete('accountId')}/telephony/sessions/" \
           "#{input.delete('telephonySessionId')}/parties/#{input.delete('partyId')}/reply", input.except('object'))
    end,

    create_send_sms_schema: lambda do |_input|
      country_id = get('/restapi/v1.0/dictionary/country?page=1&perPage=300')['records'].pluck('name', 'id') || []
      [
        { name: 'accountId', label: 'Account ID', optional: false,
          hint: 'Internal identifier of a RingCentral account or tilde (~) to indicate the extension assigned
          to the account logged-in within the current session' },
        { name: 'extensionId', label: 'Extension ID', optional: false,
          hint: 'Internal identifier of an extension or tilde (~) to indicate the extension assigned
          to the account logged-in within the current session' },
        { name: 'from', type: 'object', label: 'From', optional: false,
          properties: [
            { name: 'phoneNumber', hint: 'Phone number in E.164 format, e.g. +14155552671',
              sticky: true }
          ] },
        { name: 'to', type: 'array', of: 'object', label: 'To', optional: false,
          properties: [
            { name: 'phoneNumber', hint: 'Phone number in E.164 format, e.g. +14155552671',
              sticky: true }
          ] },
        { name: 'text', optional: false, hint: 'Text of a message. Max length is 1000 symbols ' \
          '(2-byte UTF-16 encoded). If a character is encoded in 4 bytes in UTF-16 it is treated ' \
          'as 2 characters, thus restricting the maximum message length to 500 symbols.' },
        { name: 'country', type: 'object',
          properties: [
            { name: 'id', label: 'Country name', sticky: true, control_type: 'select',
              hint: 'Please select the country name.',
              pick_list: country_id,
              toggle_hint: 'Select from options',
              toggle_field: {
                name: 'id', label: 'Country ID', type: 'string', optional: true,
                control_type: 'text', toggle_hint: 'Use custom value',
                hint: 'Please enter the internal identifier of a country.<br>' \
                'You can use the <b>Search countries</b> action to retrieve the country ID.'
              } }
          ] }
      ]
    end,
    create_send_sms_output_schema: lambda do |_input|
      [
        { name: 'uri' },
        { name: 'id' },
        { name: 'attachments', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'uri' },
            { name: 'contentType' },
            { name: 'type' },
            { name: 'vmDuration', type: 'integer',
              render_input: :integer_conversion,
              parse_output: :integer_conversion },
            { name: 'fileName' },
            { name: 'size', type: 'integer',
              render_input: :integer_conversion,
              parse_output: :integer_conversion },
            { name: 'height', type: 'integer',
              render_input: :integer_conversion,
              parse_output: :integer_conversion },
            { name: 'width', type: 'integer',
              render_input: :integer_conversion,
              parse_output: :integer_conversion }
          ] },
        { name: 'availability' },
        { name: 'conversationId', type: 'integer',
          render_input: :integer_conversion,
          parse_output: :integer_conversion },
        { name: 'conversation', type: 'object',
          properties: [
            { name: 'id' }
          ] },
        { name: 'creationTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'deliveryErrorCode' },
        { name: 'direction' },
        { name: 'faxPageCount', type: 'integer',
          render_input: :integer_conversion,
          parse_output: :integer_conversion },
        { name: 'faxResolution' },
        { name: 'from', type: 'object',
          properties: [
            { name: 'extensionNumber' },
            { name: 'extensionId' },
            { name: 'location' },
            { name: 'name' },
            { name: 'phoneNumber' }
          ] },
        { name: 'lastModifiedTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'messageStatus' },
        { name: 'pgToDepartment', type: 'boolean', render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion' },
        { name: 'priority' },
        { name: 'readStatus' },
        { name: 'smsDeliveryTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'smsSendingAttemptsCount', type: 'integer',
          render_input: :integer_conversion,
          parse_output: :integer_conversion },
        { name: 'subject' },
        { name: 'to', type: 'array', of: 'object',
          properties: [
            { name: 'target' },
            { name: 'extensionNumber' },
            { name: 'extensionId' },
            { name: 'location' },
            { name: 'messageStatus' },
            { name: 'faxErrorCode' },
            { name: 'name' },
            { name: 'phoneNumber' }
          ] },
        { name: 'type' },
        { name: 'vmTranscriptionStatus' },
        { name: 'coverIndex' },
        { name: 'convercoverPageTextsationId' }

      ]
    end,
    create_send_sms_execute: lambda do |input|
      post("/restapi/v1.0/account/#{input.delete('accountId')}/extension/" \
           "#{input.delete('extensionId')}/sms", input.except('object'))
    end,

    create_post_schema: lambda do |_input|
      [
        { name: 'chatId', optional: false, hint: 'Internal identifier of a chat' },
        { name: 'text', optional: false },
        { name: 'attachments', type: 'array', of: 'object',
          properties: [
            { name: 'id', hint: 'Internal identifier of an attachment',
              sticky: true },
            { name: 'type', hint: 'Attachment type', sticky: true }
          ] }
      ]
    end,
    create_post_output_schema: lambda do |_input|
      [
        { name: 'groupId' },
        { name: 'id' },
        { name: 'addedPersonIds', type: 'array', of: 'object', label: 'Added person IDs',
          properties: [
            { name: 'value', label: 'Added person IDs' }
          ] },
        { name: 'type' },
        { name: 'text' },
        { name: 'creatorId' },
        { name: 'creationTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'lastModifiedTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'attachments', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'type' },
            { name: 'fallback' },
            { name: 'intro' },
            { name: 'author', type: 'object',
              properties: [
                { name: 'name' },
                { name: 'uri', label: 'URI' },
                { name: 'iconUri', label: 'Icon URI' }
              ] },
            { name: 'title' },
            { name: 'text' },
            { name: 'imageUri', label: 'Image URI' },
            { name: 'thumbnailUri', label: 'Thumbnail URI' },
            { name: 'fields', type: 'array', of: 'object',
              properties: [
                { name: 'title' },
                { name: 'value' },
                { name: 'style' }
              ] },
            { name: 'footnote', type: 'object',
              properties: [
                { name: 'text' },
                { name: 'time', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
                { name: 'iconUri', label: 'Icon URI' }
              ] },
            { name: 'creatorId' },
            { name: 'startTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'endTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'allDay' },
            { name: 'recurrence ' },
            { name: 'endingCondition' },
            { name: 'endingAfter' },
            { name: 'endingOn' },
            { name: 'color' },
            { name: 'location ' },
            { name: 'description' }
          ] },
        { name: 'mentions', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'name' },
            { name: 'type' }
          ] },
        { name: 'iconEmoji' },
        { name: 'iconUri', label: 'Icon URI' },
        { name: 'title' },
        { name: 'activity' }
      ]
    end,
    create_post_execute: lambda do |input|
      post("/restapi/v1.0/glip/chats/#{input.delete('chatId')}/posts", input.except('object'))
    end,

    create_conversation_schema: lambda do |_input|
      [
        { name: 'members', type: 'array', of: 'object', optional: false,
          properties: [
            { name: 'id', hint: 'Internal identifier of a user', sticky: true },
            { name: 'email', hint: 'Email of a user', sticky: true }
          ] }
      ]
    end,
    create_conversation_output_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'members', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'email' }
          ] },
        { name: 'type' },
        { name: 'text' },
        { name: 'creationTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'lastModifiedTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' }
      ]
    end,
    create_conversation_execute: lambda do |input|
      post('/restapi/v1.0/glip/conversations', input.except('object'))
    end,

    create_note_schema: lambda do |_input|
      [
        { name: 'chatId', hint: 'Internal identifier of a chat to create a note', optional: false },
        { name: 'title', hint: 'Title of a note', optional: false },
        { name: 'body', hint: 'Contents of a note', sticky: true }
      ]
    end,
    create_note_output_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'creator', type:  'object',
          properties: [
            { name: 'id' }
          ] },
        { name: 'lastModifiedBy', type:  'object',
          properties: [
            { name: 'id' }
          ] },
        { name: 'lockedBy', type:  'object',
          properties: [
            { name: 'id' }
          ] },
        { name: 'type' },
        { name: 'status' },
        { name: 'creationTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'lastModifiedTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'title ' },
        { name: 'preview' },
        { name: 'chatIds', type: 'array', of: 'object',
          properties: [
            { name: 'value', label: 'Chat ID' }
          ] }
      ]
    end,
    create_note_execute: lambda do |input|
      post("/restapi/v1.0/glip/chats/#{input.delete('chatId')}/notes", input.except('object'))
    end,

    create_publish_note_schema: lambda do |_input|
      [
        { name: 'noteId', hint: 'Internal identifier of a note to be published', optional: false }
      ]
    end,
    create_publish_note_output_schema: lambda do |_input|
      []
    end,
    create_publish_note_execute: lambda do |input|
      post("/restapi/v1.0/glip/notes/#{input.delete('noteId')}/publish", input.except('object'))
    end,

    create_join_team_schema: lambda do |_input|
      [].concat(call('get_conversation_schema', ''))
    end,
    create_join_team_output_schema: lambda do |_input|
      []
    end,
    create_join_team_execute: lambda do |input|
      post("/restapi/v1.0/glip/teams/#{input.delete('chatId')}/join", input.except('object'))
    end,

    create_leave_team_schema: lambda do |_input|
      [].concat(call('get_conversation_schema', ''))
    end,
    create_leave_team_output_schema: lambda do |_input|
      []
    end,
    create_leave_team_execute: lambda do |input|
      post("/restapi/v1.0/glip/teams/#{input.delete('chatId')}/leave", input.except('object'))
    end,

    create_calendar_event_schema: lambda do |_input|
      [
        { name: 'id', hint: 'Internal identifier of an event' },
        { name: 'creatorId', hint: 'Internal identifier of a person created an event' },
        { name: 'title', hint: 'Event title', optional: false },
        { name: 'startTime', hint: 'Datetime of starting an event', optional: false, type: 'date_time',
          parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp', control_type: 'date_time' },
        { name: 'endTime', hint: 'Datetime of starting an event', optional: false, type: 'date_time',
          parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp', control_type: 'date_time' },
        {
          name: 'allDay',
          control_type: 'checkbox',
          sticky: true,
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Indicates whether event has some specific time slot or lasts for whole day',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'allDay',
            control_type: 'text',
            type: 'boolean',
            label: 'All day',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          }
        },
        {
          name: 'recurrence',
          control_type: 'select',
          sticky: true,
          hint: 'Event recurrence settings. For non-periodic events, the value is ' \
          'None. Must be greater or equal to event duration: 1- Day/Weekday; ' \
          '7 - Week; 28 - Month; 365 - Year',
          pick_list: [
            %w[None None],
            %w[Day Day],
            %w[Weekday All],
            %w[Week Week],
            %w[Month Month],
            %w[Year Year]
          ],
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'recurrence',
            type: 'string',
            control_type: 'text',
            label: 'Recurrence',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: None, Day, Weekday, Week, Month and Year'
          }
        },
        { name: 'endingOn', hint: 'Iterations end datetime for periodic events. Must be specified if <b>Ending condition</b> is <b>Date</b>.',
          type: 'date_time', parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp', control_type: 'date_time' },
        { name: 'endingAfter', type: 'integer',
          render_input: :integer_conversion,
          parse_output: :integer_conversion, hint: 'Count of iterations. ' \
          'For periodic events only. Value range is 1 - 10. ' \
          'Must be specified if <b>Ending condition</b> is <b>Count</b>' },
        { name: 'location', hint: 'Event location' },
        { name: 'description', hint: 'Event details' },
        {
          name: 'endingCondition',
          control_type: 'select',
          sticky: true,
          hint: 'Condition of ending',
          pick_list: [
            %w[None None],
            %w[Count Count],
            %w[Date Date]
          ],
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'endingCondition',
            type: 'string',
            control_type: 'text',
            label: 'Ending condition',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: None, Count, Day'
          }
        },
        {
          name: 'color',
          control_type: 'select',
          sticky: true,
          hint: 'Color of Event title (including its presentation in Calendar)',
          pick_list: [
            %w[Black Black],
            %w[Red Red],
            %w[Orange Orange],
            %w[Yellow Yellow],
            %w[Green Green],
            %w[Blue Blue],
            %w[Purple Purple],
            %w[Magenta Magenta]
          ],
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'color',
            type: 'string',
            control_type: 'text',
            label: 'Color',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: Black, Red, Orange, Yellow, Green, Blue, Purple, Magenta'
          }
        }
      ]
    end,
    create_calendar_event_output_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'type' },
        { name: 'creatorId' },
        { name: 'title' },
        { name: 'startTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'endTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'endingAfter', type: 'integer' },
        { name: 'endingOn' },
        { name: 'recurrence' },
        { name: 'endingCondition' },
        { name: 'color' },
        { name: 'location' },
        { name: 'description' },
        { name: 'allDay', type: 'boolean' }
      ]
    end,
    create_calendar_event_execute: lambda do |input|
      post('/restapi/v1.0/glip/events', input.except('object'))
    end,

    create_task_schema: lambda do |_input|
      [
        { name: 'chatId', hint: 'Internal identifier of a chat', optional: false },
        { name: 'assignees', label: 'Assignees', type: 'array', of: 'object', optional: false,
          properties: [
            { name: 'id', optional: false, hint: 'Assignee ID' }
          ] }
      ].concat(call('update_task_schema', '').ignored('taskId', 'assignees').required('subject'))
    end,
    create_task_output_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'creationTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'lastModifiedTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'type' },
        { name: 'creator', type: 'object',
          properties: [
            { name: 'id' }
          ] },
        { name: 'chatIds', type: 'array', label: 'Chat IDs',
          properties: [
            { name: 'value', label: 'Chat ID' }
          ] },
        { name: 'status' },
        { name: 'subject ' },
        { name: 'assignees', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'status' }
          ] },
        { name: 'completenessCondition' },
        { name: 'completenessPercentage' },
        { name: 'endingCondition' },
        { name: 'startDate', type: 'date', control_type: 'date' },
        { name: 'dueDate', type: 'date', control_type: 'date' },
        { name: 'color ' },
        { name: 'section' },
        { name: 'description' },
        { name: 'recurrence', type: 'object',
          properties: [
            { name: 'schedule' },
            { name: 'endingCondition' },
            { name: 'endingAfter' },
            { name: 'endingOn' }
          ] },
        { name: 'attachments', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'type' },
            { name: 'name' },
            { name: 'contentUri', label: 'Content URI' }
          ] }
      ]
    end,
    create_task_execute: lambda do |input|
      post("/restapi/v1.0/glip/chats/#{input.delete('chatId')}/tasks", input.except('object'))
    end,

    create_callout_schema: lambda do |_input|
      [
        { name: 'accountId', label: 'Account ID', hint: 'Internal identifier of ' \
          'a RingCentral account or tilde (~) to indicate the account logged-in within the current session',
          optional: false },
        { name: 'from', type: 'object', optional: false,
          properties: [
            { name: 'deviceId', hint: 'Internal identifier of a device', sticky: true }
          ] },
        { name: 'to', type: 'object', optional: false,
          properties: [
            { name: 'phoneNumber', hint: 'Phone number in E.164 format, e.g. +10000000000', sticky: true },
            { name: 'extensionNumber', hint: 'Extension number, e.g. 101', sticky: true }
          ] }
      ]
    end,
    create_callout_output_schema: lambda do |_input|
      [
        { name: 'session', type: 'object',
          properties: call('get_callout_session_status_output_schema', '') }
      ]
    end,
    create_callout_execute: lambda do |input|
      post("/restapi/v1.0/account/#{input.delete('accountId')}/telephony/call-out", input.except('object'))
    end,

    create_team_schema: lambda do |_input|
      [
        {
          name: 'public',
          control_type: 'checkbox',
          sticky: true,
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Team access level',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'public',
            control_type: 'text',
            type: 'boolean',
            label: 'Public',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          }
        },
        { name: 'name', optional: false, hint: 'Team name' },
        { name: 'description', sticky: true, hint: 'Team description' },
        { name: 'members', sticky: true, type: 'array', of: 'object', properties: [
          { name: 'id', hint: 'Internal identifier of a user', sticky: true },
          { name: 'email', hint: 'Email address of the user', sticky: true }
        ] }
      ]
    end,
    create_team_output_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'type' },
        { name: 'public', type: 'boolean' },
        { name: 'name' },
        { name: 'description' },
        { name: 'status' },
        { name: 'creationTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'lastModifiedTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' }
      ]
    end,
    create_team_execute: lambda do |input|
      post('/restapi/v1.0/glip/teams', input.except('object'))
    end,

    create_team_members_schema: lambda do |_input|
      [
        { name: 'chatId', label: 'Chat ID', hint: 'Internal identifier of a team to add members to.', optional: false },
        { name: 'members', sticky: true, type: 'array', of: 'object', properties: [
          { name: 'id', hint: 'Internal identifier of a user', sticky: true },
          { name: 'email', hint: 'Email address of the user', sticky: true }
        ] }
      ]
    end,
    create_team_members_output_schema: lambda do |_input|
      [
        { name: 'result' }
      ]
    end,
    create_team_members_execute: lambda do |input|
      post("/restapi/v1.0/glip/teams/#{input.delete('chatId')}/add", input.except('object'))
    end,

    ### SEARCH METHODS ###
    search_meetings_schema: lambda do |_input|
      [
        { name: 'accountId', optional: false,
          hint: 'Internal identifier of a RingCentral account or tilde (~) to indicate the extension assigned
          to the account logged-in within the current session' },
        { name: 'extensionId', optional: false,
          hint: 'Internal identifier of an extension or tilde (~) to indicate the extension assigned
          to the account logged-in within the current session' }
      ]
    end,
    search_meetings_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Meetings', type: 'array', of: 'object',
          properties: call('create_meeting_output_schema', '') }
      ]
    end,
    search_meetings_execute: lambda do |input|
      get("/restapi/v1.0/account/#{input['accountId']}/extension/" \
          "#{input['extensionId']}/meeting", input.except('object'))
    end,

    search_users_schema: lambda do |_input|
      [
        { name: 'filter', label: 'Filter',
          hint: 'Only <b>userName</b> and <b>email</b> fields are supported for filter expressions<br><b>Example: userName eq "partners@workato.com"</b>',
          sticky: true },
        { name: 'startIndex', type: 'integer', render_input: 'integer_conversion',
          parse_output: 'integer_conversion', hint: 'Start index, default is 1.',
          sticky: true },
        { name: 'count', label: 'Page size', type: 'integer', render_input: 'integer_conversion',
          parse_output: 'integer_conversion', sticky: true }
      ]
    end,
    search_users_output_schema: lambda do |_input|
      [
        { name: 'Resources', label: 'Users', type: 'array', of: 'object',
          properties: call('create_user_output_schema', '') }
      ]
    end,
    search_users_execute: lambda do |input|
      get('/scim/Users', input.except('object'))
    end,

    search_contacts_schema: lambda do |_input|
      [
        { name: 'accountId', optional: false,
          hint: 'Internal identifier of a RingCentral account or tilde (~) to indicate the extension assigned
          to the account logged-in within the current session' },
        { name: 'extensionId', optional: false,
          hint: 'Internal identifier of an extension or tilde (~) to indicate the extension assigned
          to the account logged-in within the current session' },
        { name: 'startsWith', sticky: true,
          hint: 'If specified, only contacts whose First
          name or Last name start with the mentioned substring are returned. Case-insensitive' },
        {
          name: 'sortBy',
          control_type: 'select',
          sticky: true,
          hint: 'Sorts results by the specified property',
          pick_list: [
            %w[First\ name FirstName],
            %w[Last\ name LastName],
            %w[Company Company]
          ],
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'Sortby',
            control_type: 'text',
            type: 'string',
            label: 'Sort by',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: FirstName, LastName, Company'
          }
        },
        { name: 'page', type: 'integer', render_input: 'integer_conversion',
          parse_output: 'integer_conversion', sticky: true,
          hint: 'Indicates the page number to retrieve. Only positive number values are accepted' },
        { name: 'perPage', type: 'integer', label: 'Perpage', sticky: true,
          render_input: 'integer_conversion', parse_output: 'integer_conversion', hint: 'Indicates the page size' },
        { name: 'phoneNumber', hint: 'Please enter phone numbers to filter separated by commas, without spaces.' }
      ]
    end,
    search_contacts_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Contacts', type: 'array', of: 'object',
          properties: call('create_contact_output_schema', '') }
      ]
    end,
    search_contacts_execute: lambda do |input|
      input['phoneNumber'] = input['phoneNumber']&.split(',') unless input['phoneNumber'].blank?
      get("/restapi/v1.0/account/#{input.delete('accountId')}/extension/" \
          "#{input.delete('extensionId')}/address-book/contact", input.except('object'))
    end,

    search_user_call_log_records_schema: lambda do |_input|
      [
        { name: 'accountId', optional: false,
          hint: 'Internal identifier of a RingCentral account or tilde (~) to indicate the extension assigned
          to the account logged-in within the current session' },
        { name: 'extensionId', optional: false,
          hint: 'Internal identifier of an extension or tilde (~) to indicate the extension assigned
          to the account logged-in within the current session' },
        { name: 'extensionNumber', hint: 'Extension number of a user. ' \
          'If specified, returns call log for a particular extension only', sticky: true },
        {
          name: 'showBlocked',
          control_type: 'checkbox',
          type: :boolean,
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          sticky: true,
          hint: 'If Yes, then calls from/to blocked numbers are returned',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'showBlocked',
            control_type: 'text',
            type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            label: 'Show blocked',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          }
        },
        { name: 'phoneNumber', label: 'Phone number', hint: 'Phone number of a caller/callee. ' \
          'If specified, returns all calls (both incoming and outcoming) with the phone number specified', sticky: true },
        { name: 'direction',
          control_type: 'multiselect',
          delimiter: '|',
          pick_list: [
            %w[Inbound Inbound],
            %w[Outbound Outbound]
          ],
          optional: true,
          sticky: true,
          hint: 'The direction for the resulting records. If not specified, both inbound and ' \
          'outbound records are returned. Multiple values are accepted.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'direction',
            type: 'string',
            control_type: 'text',
            label: 'Direction',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: Inbound, Outbound'
          } },
        { name: 'sessionId', hint: 'Internal identifier of a session', sticky: true },
        { name: 'type',
          control_type: 'multiselect',
          delimiter: '|',
          hint: 'Call type of a record. It is allowed to specify more than one type. If not specified, ' \
          'all call types are returned. Multiple values are accepted.',
          pick_list: [
            %w[Voice Voice],
            %w[Fax Fax]
          ],
          optional: true,
          sticky: true,
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'type',
            type: 'string',
            control_type: 'text',
            label: 'Type',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: Voice, Fax'
          } },
        { name: 'transport',
          control_type: 'multiselect',
          delimiter: '|',
          hint: 'Call transport type. PSTN specifies that a call leg is initiated from the PSTN ' \
          'network provider; VoIP - from an RC phone. By default this filter is disabled.',
          pick_list: [
            %w[PSTN PSTN],
            %w[VoIP VoIP]
          ],
          optional: true,
          sticky: true,
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'transport',
            type: 'string',
            control_type: 'text',
            label: 'Transport',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: PSTN, VoIP'
          } },
        {
          name: 'view',
          control_type: 'select',
          sticky: true,
          optional: true,
          hint: 'View of call records. The same view parameter specified for FSync will be applied for
          ISync, the view cannot be changed for ISync',
          pick_list: [
            %w[Simple Simple],
            %w[Detailed Detailed]
          ],
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'view',
            type: 'string',
            control_type: 'text',
            label: 'View',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: Simple, Detailed'
          }
        },
        {
          name: 'recordingType',
          control_type: 'select',
          sticky: true,
          optional: true,
          hint: 'Type of a call recording. If not specified, then calls without recordings are also returned.',
          pick_list: [
            %w[Automatic Automatic],
            %w[On\ demand OnDemand],
            %w[All All]
          ],
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'recordingType',
            type: 'string',
            control_type: 'text',
            label: 'Recording type',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: Automatic, OnDemand, All'
          }
        },
        { name: 'dateTo', type: 'date_time', sticky: true,
          parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp',
          hint: 'The end datetime for resulting records. The default value is current time.' },
        { name: 'dateFrom', type: 'date_time', sticky: true,
          parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp',
          hint: 'The start datetime for resulting records. The default value is <b>Date to minus 24 hours</b>.' },
        { name: 'page', type: 'integer', render_input: 'integer_conversion', sticky: true,
          parse_output: 'integer_conversion', hint: 'Indicates the page ' \
          'number to retrieve. Only positive number values are allowed' },
        { name: 'perPage', type: 'integer', render_input: 'integer_conversion', sticky: true,
          parse_output: 'integer_conversion', hint: 'Indicates the page size (number of items)' },
        {
          name: 'showDeleted',
          control_type: 'checkbox',
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          optional: true,
          sticky: true,
          hint: 'If Yes, then deleted calls are returned.',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'showDeleted',
            type: 'boolean',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            control_type: 'text',
            label: 'Show deleted',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          }
        }
      ]
    end,
    search_user_call_log_records_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'User call logs', type: 'array', of: 'object',
          properties: call('get_user_call_record_output_schema', '') }
      ]
    end,
    search_user_call_log_records_execute: lambda do |input|
      if input['direction']
        url = ''
        input.delete('direction')&.split('|')&.each do |name|
          url = url + "&direction=#{name}"
        end
      end

      if input['type']
        urltype = ''
        input.delete('type')&.split('|')&.each do |name|
          urltype = urltype + "&type=#{name}"
        end
      end

      if input['transport']
        urltransport = ''
        input.delete('transport')&.split('|')&.each do |name|
          urltransport = urltransport + "&transport=#{name}"
        end
      end

      get("/restapi/v1.0/account/#{input.delete('accountId')}/extension/" \
          "#{input.delete('extensionId')}/call-log?#{url}#{urltype}" \
          "#{urltransport}", input.except('object'))
    end,

    search_user_active_calls_schema: lambda do |_input|
      call('search_user_call_log_records_schema', '').
        only('accountId', 'extensionId', 'direction', 'view', 'type', 'page', 'perPage')
    end,
    search_user_active_calls_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'User active calls', type: 'array', of: 'object',
          properties: call('get_user_call_record_output_schema', '') }
      ]
    end,
    search_user_active_calls_execute: lambda do |input|
      if input['direction']
        url = ''
        input.delete('direction')&.split('|')&.each do |name|
          url = url + "&direction=#{name}"
        end
      end

      if input['type']
        urltype = ''
        input.delete('type')&.split('|')&.each do |name|
          urltype = urltype + "&type=#{name}"
        end
      end

      get("/restapi/v1.0/account/#{input.delete('accountId')}/extension/" \
          "#{input.delete('extensionId')}/active-calls?#{url}#{urltype}", input.except('object'))
    end,

    search_company_active_calls_schema: lambda do |_input|
      call('search_user_call_log_records_schema', '').
        only('accountId', 'transport', 'direction', 'view', 'type', 'page', 'perPage')
    end,
    search_company_active_calls_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Company active calls', type: 'array', of: 'object',
          properties: call('get_user_call_record_output_schema', '') }
      ]
    end,
    search_company_active_calls_execute: lambda do |input|
      if input['direction']
        url = ''
        input.delete('direction')&.split('|')&.each do |name|
          url = url + "&direction=#{name}"
        end
      end

      if input['type']
        urltype = ''
        input.delete('type')&.split('|')&.each do |name|
          urltype = urltype + "&type=#{name}"
        end
      end

      if input['transport']
        urltransport = ''
        input.delete('transport')&.split('|')&.each do |name|
          urltransport = urltransport + "&transport=#{name}"
        end
      end

      get("/restapi/v1.0/account/#{input.delete('accountId')}/active-calls?#{url}#{urltype}#{urltransport}", input.except('object'))
    end,

    search_company_call_log_records_schema: lambda do |_input|
      call('search_user_call_log_records_schema', '').
        only('accountId', 'extensionNumber', 'phoneNumber', 'direction', 'view', 'type', 'page', 'perPage',
             'withRecording', 'recordingType', 'dateFrom', 'dateTo', 'sessionId')
    end,
    search_company_call_log_records_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Company call logs', type: 'array', of: 'object',
          properties: call('get_user_call_record_output_schema', '') }
      ]
    end,
    search_company_call_log_records_execute: lambda do |input|
      if input['direction']
        url = ''
        input.delete('direction')&.split('|')&.each do |name|
          url = url + "&direction=#{name}"
        end
      end

      if input['type']
        urltype = ''
        input.delete('type')&.split('|')&.each do |name|
          urltype = urltype + "&type=#{name}"
        end
      end

      get("/restapi/v1.0/account/#{input.delete('accountId')}/call-log?#{url}#{urltype}", input.except('object'))
    end,

    search_conversations_schema: lambda do |_input|
      [
        { name: 'recordCount', type: 'integer', control_type: 'integer', render_input: 'integer_conversion', parse_output: 'integer_conversion',
          hint: 'Number of items to be fetched. The maximum value is 250, default is 30.', sticky: true }
      ]
    end,
    search_conversations_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Conversations', type: 'array', of: 'object',
          properties: [
            { name: 'id ' },
            { name: 'type' },
            { name: 'members', type: 'array', of: 'object',
              properties: [
                { name: 'id' },
                { name: 'email' }
              ] },
            { name: 'creationTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'lastModifiedTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' }
          ] }
      ]
    end,
    search_conversations_execute: lambda do |input|
      get('/restapi/v1.0/glip/conversations', input.except('object'))
    end,

    search_teams_schema: lambda do |_input|
      call('search_conversations_schema', '')
    end,
    search_teams_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Teams', type: 'array', of: 'object',
          properties: [
            { name: 'id ' },
            { name: 'name' },
            { name: 'type' },
            { name: 'status' },
            { name: 'description' },
            { name: 'public' },
            { name: 'creationTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'lastModifiedTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' }
          ] }
      ]
    end,
    search_teams_execute: lambda do |input|
      get('/restapi/v1.0/glip/teams', input.except('object'))
    end,

    search_calendar_events_schema: lambda do |_input|
      call('search_conversations_schema', '')
    end,
    search_calendar_events_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Calendar events', type: 'array', of: 'object',
          properties: [
            { name: 'id ' },
            { name: 'type' },
            { name: 'creatorId' },
            { name: 'title' },
            { name: 'startTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'endTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'recurrence' },
            { name: 'endingCondition' },
            { name: 'endingAfter', type: 'integer', control_type: 'integer', parse_output: 'integer_conversion' },
            { name: 'endingOn' },
            { name: 'color' },
            { name: 'location' },
            { name: 'description' },
            { name: 'allDay', type: 'boolean', parse_output: 'boolean_conversion' }
          ] }
      ]
    end,
    search_calendar_events_execute: lambda do |input|
      get('/restapi/v1.0/glip/events', input.except('object'))
    end,

    search_chats_schema: lambda do |_input|
      [
        { name: 'type',
          control_type: 'multiselect',
          delimiter: '|',
          pick_list: [
            %w[Everyone Everyone],
            %w[Group Group],
            %w[Personal Personal],
            %w[Direct Direct],
            %w[Team Team]
          ],
          optional: true,
          sticky: true,
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'type',
            type: 'string',
            control_type: 'text',
            label: 'Type',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: Everyone, Group, Personal, Direct, Team'
          } },
        { name: 'recordCount', type: 'integer', render_input: 'integer_conversion', parse_output: 'integer_conversion',
          hint: 'Number of chats to be fetched. The maximum value is 250, default is 30.', sticky: true }
      ]
    end,
    search_chats_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Chats', type: 'array', of: 'object',
          properties: [
            { name: 'id ' },
            { name: 'type' },
            { name: 'public' },
            { name: 'name' },
            { name: 'description' },
            { name: 'status' },
            { name: 'creationTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'lastModifiedTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'members', type: 'array', of: 'object',
              properties: [
                { name: 'id' }
              ] }
          ] }
      ]
    end,
    search_chats_execute: lambda do |input|
      if input['type']
        url = ''
        input.delete('type')&.split('|')&.each do |name|
          url = url + "&type=#{name}"
        end
      end

      get("/restapi/v1.0/glip/chats?#{url}", input.except('object'))
    end,

    search_tasks_schema: lambda do |_input|
      [
        { name: 'chatId', hint: 'Internal identifier of a chat', optional: false },
        { name: 'creationTimeTo', type: 'date_time', parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp', sticky: true },
        { name: 'creationTimeFrom', type: 'date_time', parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp', sticky: true },
        { name: 'creatorId', label: 'Creator IDs', type: 'array', of: 'object', sticky: true,
          properties: [
            { name: 'creatorId', sticky: true }
          ] },
        { name: 'status',
          control_type: 'multiselect',
          delimiter: ',',
          sticky: true,
          hint: 'Task execution status',
          pick_list: [
            %w[Pending Pending],
            %w[In\ progress InProgress],
            %w[Completed Completed]
          ],
          optional: true,
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'status',
            type: 'string',
            control_type: 'text',
            label: 'Status',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: Pending, InProgress , Completed'
          } },
        {
          name: 'assignmentStatus',
          control_type: 'select',
          hint: 'Task assignment status',
          sticky: true,
          pick_list: [
            %w[Unassigned Unassigned],
            %w[Assigned Assigned]
          ],
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'assignmentStatus',
            type: 'string',
            control_type: 'text',
            label: 'Assignment status',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: Unassigned, Assigned'
          }
        },
        { name: 'assigneeId', label: 'Assignee IDs', type: 'array', of: 'object', sticky: true,
          properties: [
            { name: 'assigneeId', sticky: true }
          ] },
        {
          name: 'assigneeStatus',
          control_type: 'select',
          hint: 'Task assignment status',
          sticky: true,
          pick_list: [
            %w[Pending Pending],
            %w[Completed Completed]
          ],
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'assigneeStatus',
            type: 'string',
            control_type: 'text',
            label: 'Assignee status',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: Pending, Completed'
          }
        },
        { name: 'recordCount', type: 'integer', render_input: 'integer_conversion', parse_output: 'integer_conversion',
          hint: 'Number of records to be returned', sticky: true }
      ]
    end,
    search_tasks_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Tasks', type: 'array', of: 'object',
          properties: call('create_task_output_schema', '') }
      ]
    end,
    search_tasks_execute: lambda do |input|
      input['creatorId'] = input['creatorId']&.pluck('creatorId')&.join(',') unless input['creatorId'].blank?
      input['assigneeId'] = input['assigneeId']&.pluck('assigneeId')&.join(',') unless input['assigneeId'].blank?
      input['creationTimeTo'] = input['creationTimeTo']&.to_time&.utc&.strftime('%Y-%m-%dT%H:%M:%S.%LZ') unless input['creationTimeTo'].blank?
      input['creationTimeFrom'] = input['creationTimeFrom']&.to_time&.utc&.strftime('%Y-%m-%dT%H:%M:%S.%LZ') unless input['creationTimeFrom'].blank?

      get("restapi/v1.0/glip/chats/#{input.delete('chatId')}/tasks", input.compact.except('object'))
    end,

    search_notes_schema: lambda do |_input|
      [
        { name: 'chatId', hint: 'Internal identifier of a chat', optional: false },
        { name: 'creationTimeTo', label: 'Creation time to', type: 'date_time',
          parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp',
          hint: 'The end datetime for resulting records. The default value is the current time', sticky: true },
        { name: 'creationTimeFrom', label: 'Creation time from', type: 'date_time',
          parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp',
          hint: 'The start datetime for resulting records.', sticky: true },
        { name: 'creatorId', hint: 'Internal identifier of the user that created the note', sticky: true },
        { name: 'status',
          control_type: 'select',
          sticky: true,
          hint: 'Status of notes to be fetched. If not specified, all notes are fetched by default.',
          pick_list: [
            %w[Active Active],
            %w[Draft Draft]
          ],
          optional: true,
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'status',
            type: 'string',
            control_type: 'text',
            label: 'Status',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: Active, Draft'
          } },
        { name: 'recordCount', type: 'integer', render_input: 'integer_conversion', parse_output: 'integer_conversion',
          hint: 'Number of records to be returned', sticky: true }
      ]
    end,
    search_notes_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Notes', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'creator', type:  'object',
              properties: [
                { name: 'id' }
              ] },
            { name: 'lastModifiedBy', type:  'object',
              properties: [
                { name: 'id' }
              ] },
            { name: 'type' },
            { name: 'status' },
            { name: 'creationTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'lastModifiedTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'title ' },
            { name: 'preview' },
            { name: 'chatIds', label: 'Chat IDs', type: 'array', of: 'object',
              properties: [
                { name: 'value', label: 'Chat ID' }
              ] }
          ] }
      ]
    end,
    search_notes_execute: lambda do |input|
      input['creationTimeTo'] = input['creationTimeTo']&.to_time&.utc&.strftime('%Y-%m-%dT%H:%M:%S.%LZ') unless input['creationTimeTo'].blank?
      input['creationTimeFrom'] = input['creationTimeFrom']&.to_time&.utc&.strftime('%Y-%m-%dT%H:%M:%S.%LZ') unless input['creationTimeFrom'].blank?

      get("restapi/v1.0/glip/chats/#{input.delete('chatId')}/notes", input.except('object'))
    end,

    search_posts_schema: lambda do |_input|
      [
        { name: 'chatId', hint: 'Internal identifier of a chat', optional: false }
      ].concat(call('search_conversations_schema', ''))
    end,
    search_posts_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Posts', type: 'array', of: 'object',
          properties: [
            { name: 'groupId' },
            { name: 'id' },
            { name: 'addedPersonIds', label: 'Added person IDs', type: 'array', of: 'object',
              properties: [
                { name: 'value', label: 'Added person ID' }
              ] },
            { name: 'type' },
            { name: 'text' },
            { name: 'creatorId' },
            { name: 'creationTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'lastModifiedTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'attachments', type: 'array', of: 'object',
              properties: [
                { name: 'id' },
                { name: 'type' },
                { name: 'fallback' },
                { name: 'intro' },
                { name: 'author', type: 'object',
                  properties: [
                    { name: 'name' },
                    { name: 'uri', label: 'URI' },
                    { name: 'iconUri', label: 'Icon URI' }
                  ] },
                { name: 'title' },
                { name: 'text' },
                { name: 'imageUri', label: 'Image URI' },
                { name: 'thumbnailUri', label: 'Thumbnail URI' },
                { name: 'fields', type: 'array', of: 'object',
                  properties: [
                    { name: 'title' },
                    { name: 'value' },
                    { name: 'style' }
                  ] },
                { name: 'footnote', type: 'object',
                  properties: [
                    { name: 'text' },
                    { name: 'time' },
                    { name: 'iconUri', label: 'Icon URI' }
                  ] },
                { name: 'creatorId' },
                { name: 'startTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
                { name: 'endTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
                { name: 'allDay' },
                { name: 'recurrence' },
                { name: 'endingCondition' },
                { name: 'endingAfter' },
                { name: 'endingOn' },
                { name: 'color' },
                { name: 'location' },
                { name: 'description' }
              ] },
            { name: 'mentions', type: 'array', of: 'object',
              properties: [
                { name: 'id' },
                { name: 'name' },
                { name: 'type' }
              ] },
            { name: 'iconEmoji' },
            { name: 'iconUri', label: 'Icon URI' },
            { name: 'title' },
            { name: 'activity' }
          ] }
      ]
    end,
    search_posts_execute: lambda do |input|
      get("restapi/v1.0/glip/chats/#{input.delete('chatId')}/posts", input.except('object'))
    end,

    search_account_meeting_recordings_schema: lambda do |_input|
      [
        { name: 'meetingId', sticky: true, hint: 'Internal identifier of a meeting. ' \
          'Either <b>Meeting ID</b> or <b>Meeting start time from and to</b> must be specified.' },
        { name: 'accountId', optional: false,
          hint: 'Internal identifier of a RingCentral account or tilde (~) to indicate the extension assigned ' \
          'to the account logged-in within the current session' },
        { name: 'meetingStartTimeFrom', type: 'date_time', sticky: true,
          parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp',
          hint: 'Recordings of meetings started after the time specified will be returned. ' \
          'Either <b>Meeting ID</b> or <b>Meeting start time from and to</b> must be specified.' },
        { name: 'meetingStartTimeTo', type: 'date_time', sticky: true,
          parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp',
          hint: 'Recordings of meetings started before the time specified will be returned. ' \
          'Either <b>Meeting ID</b> or <b>Meeting start time from and to</b> must be specified.' },
        { name: 'page', type: 'integer', sticky: true, render_input: 'integer_conversion',
          parse_output: 'integer_conversion', hint: 'Page number' },
        { name: 'perPage', type: 'integer', sticky: true, render_input: 'integer_conversion',
          parse_output: 'integer_conversion', hint: 'Number of items per page. Maximum value is 300.' }
      ]
    end,
    search_account_meeting_recordings_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Meeting recordings', type: 'array', of: 'object',
          properties: [
            { name: 'meeting', type: 'object',
              properties: [
                { name: 'id' },
                { name: 'topic' },
                { name: 'startTime', type: 'date_time',
                  parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp' }
              ] },
            { name: 'recording', type: 'array', of: 'object',
              properties: [
                { name: 'contentDownloadUri', label: 'Content download URI' },
                { name: 'contentType' },
                { name: 'size' },
                { name: 'status' },
                { name: 'startTime', type: 'date_time',
                  parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp' },
                { name: 'endTime', type: 'date_time',
                  parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp' }
              ] }
          ] }
      ]
    end,
    search_account_meeting_recordings_execute: lambda do |input|
      get("/restapi/v1.0/account/#{input.delete('accountId')}/meeting-recordings", input.except('object'))
    end,

    search_user_meeting_recordings_schema: lambda do |_input|
      [
        { name: 'extensionId', optional: false,
          hint: 'Internal identifier of an extension or tilde (~) to indicate the extension assigned
          to the account logged-in within the current session' }
      ].concat(call('search_account_meeting_recordings_schema', ''))
    end,
    search_user_meeting_recordings_output_schema: lambda do |_input|
      call('search_account_meeting_recordings_output_schema', '')
    end,
    search_user_meeting_recordings_execute: lambda do |input|
      get("/restapi/v1.0/account/#{input.delete('accountId')}/extension/" \
          "#{input.delete('extensionId')}/meeting-recordings", input.except('object'))
    end,

    search_states_schema: lambda do |_input|
      [
        { name: 'allCountries', hint: 'If set to <b>Yes</b>, then states for all countries are ' \
          'returned and <b>Country ID</b> is ignored, even if specified. If the value is empty ' \
          'then the parameter is ignored',
          sticky: true,
          control_type: 'checkbox',
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'allCountries',
            control_type: 'text',
            type: 'boolean',
            label: 'All countries',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          } },
        { name: 'countryId', sticky: true, hint: 'Internal identifier of a country' },
        { name: 'page', sticky: true, hint: 'Indicates the page number to retrieve. Only positive number values are accepted.' },
        { name: 'perPage', hint: 'Indicates the page size (number of items)', sticky: true },
        { name: 'withPhoneNumbers', hint: 'If <b>Yes</b>, the list of states with phone numbers available for buying is returned.',
          sticky: true,
          control_type: 'checkbox',
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'withPhoneNumbers',
            control_type: 'text',
            type: 'boolean',
            label: 'With phone numbers',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          } }
      ]
    end,
    search_states_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'States', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'uri', label: 'URI' },
            { name: 'country', type: 'object', properties: [
              { name: 'id' },
              { name: 'uri', label: 'URI' }
            ] },
            { name: 'isoCode', label: 'ISO code' },
            { name: 'name' }
          ] }
      ]
    end,
    search_states_execute: lambda do |input|
      get('/restapi/v1.0/dictionary/state', input.except('object'))
    end,

    search_countries_schema: lambda do |_input|
      [
        { name: 'loginAllowed', hint: 'Specifies whether login with the phone numbers of this country is enabled or not.',
          sticky: true,
          control_type: 'checkbox',
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'loginAllowed',
            control_type: 'text',
            type: 'boolean',
            label: 'Login allowed',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          } },
        { name: 'signupAllowed', hint: 'Indicates whether signup/billing is allowed for a country. If not specified all countries are returned.',
          sticky: true,
          control_type: 'checkbox',
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'signupAllowed',
            control_type: 'text',
            type: 'boolean',
            label: 'Signup allowed',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          } },
        { name: 'numberSelling', hint: 'Specifies if RingCentral sells phone numbers of this country.',
          sticky: true,
          control_type: 'checkbox',
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'numberSelling',
            control_type: 'text',
            type: 'boolean',
            label: 'Number selling',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          } },
        { name: 'freeSoftphoneLine', hint: 'Specifies if free phone line for softphone is available for a country or not.',
          sticky: true,
          control_type: 'checkbox',
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'freeSoftphoneLine',
            control_type: 'text',
            type: 'boolean',
            label: 'Free softphone line',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          } },
        { name: 'page', sticky: true, hint: 'Indicates the page number to retrieve. Only positive number values are accepted.' },
        { name: 'perPage', hint: 'Indicates the page size (number of items)', sticky: true }
      ]
    end,
    search_countries_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Countries', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'uri', label: 'URI' },
            { name: 'callingCode' },
            { name: 'emergencyCalling', type: 'boolean' },
            { name: 'isoCode', label: 'ISO code' },
            { name: 'name' }
          ].concat(call('search_countries_schema', '').ignored('page', 'perPage')) }
      ]
    end,
    search_countries_execute: lambda do |input|
      get('/restapi/v1.0/dictionary/country', input.except('object'))
    end,

    search_timezones_schema: lambda do |_input|
      [
        { name: 'page', sticky: true, hint: 'Indicates the page number to retrieve. Only positive number values are accepted.' },
        { name: 'perPage', hint: 'Indicates the page size (number of items)', sticky: true }
      ]
    end,
    search_timezones_output_schema: lambda do |_input|
      [
        { name: 'records', label: 'Timezones', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'uri', label: 'URI' },
            { name: 'description' },
            { name: 'name' },
            { name: 'bias' }
          ] }
      ]
    end,
    search_timezones_execute: lambda do |input|
      get('/restapi/v1.0/dictionary/timezone', input.except('object'))
    end,

    ### GET METHODS ###
    get_meeting_schema: lambda do |_input|
      [
        { name: 'meetingId', optional: false }
      ].concat(call('search_meetings_schema', ''))
    end,
    get_meeting_output_schema: lambda do |_input|
      call('create_meeting_output_schema', '')
    end,
    get_meeting_execute: lambda do |input|
      get("/restapi/v1.0/account/#{input['accountId']}/extension/#{input['extensionId']}/meeting/#{input['meetingId']}")
    end,

    get_user_schema: lambda do |_input|
      [
        { name: 'id', optional: false, label: 'User ID' }
      ]
    end,
    get_user_output_schema: lambda do |_input|
      call('create_user_output_schema', '')
    end,
    get_user_execute: lambda do |input|
      get("/scim/v2/Users/#{input['id']}")
    end,

    get_contact_schema: lambda do |_input|
      [
        { name: 'contactId', type: 'integer', optional: false,
          render_input: 'integer_conversion', parse_output: 'integer_conversion' },
        { name: 'accountId', label: 'Account ID', optional: false,
          hint: 'Internal identifier of a RingCentral account or tilde (~) to indicate the extension assigned ' \
          'to the account logged-in within the current session' },
        { name: 'extensionId', label: 'Extension ID', optional: false,
          hint: 'Internal identifier of an extension or tilde (~) to indicate the extension assigned ' \
          'to the account logged-in within the current session' }
      ]
    end,
    get_contact_output_schema: lambda do |_input|
      call('create_contact_output_schema', '')
    end,
    get_contact_execute: lambda do |input|
      get("/restapi/v1.0/account/#{input['accountId']}/extension/#{input['extensionId']}/address-book/contact/#{input['contactId']}")
    end,

    get_user_call_record_schema: lambda do |_input|
      [
        { name: 'callRecordId', optional: false, hint: 'Internal identifier of a call record' }
      ].concat(call('search_user_call_log_records_schema', '').only('extensionId', 'accountId', 'view'))
    end,
    get_user_call_record_output_schema: lambda do |_input|
      [
        { name: 'uri', label: 'URI' },
        { name: 'id' },
        { name: 'sessionId' },
        { name: 'telephonySessionId' },
        { name: 'type' },
        { name: 'direction' },
        { name: 'action' },
        { name: 'result' },
        { name: 'to', type: 'object',
          properties: [
            { name: 'phoneNumber' },
            { name: 'extensionNumber' },
            { name: 'extensionId' },
            { name: 'location' },
            { name: 'name' },
            { name: 'device', type: 'object',
              properties: [
                { name: 'id' },
                { name: 'uri', label: 'URI' }
              ] }
          ] },
        { name: 'from', type: 'object',
          properties: [
            { name: 'phoneNumber' },
            { name: 'extensionNumber' },
            { name: 'extensionId' },
            { name: 'location' },
            { name: 'name' },
            { name: 'device', type: 'object',
              properties: [
                { name: 'id' },
                { name: 'uri', label: 'URI' }
              ] }
          ] },
        { name: 'extension', type: 'object',
          properties: [
            { name: 'id' },
            { name: 'uri', label: 'URI' }
          ] },
        { name: 'transport' },
        { name: 'legs', type: 'array', of: 'object',
          properties: [
            { name: 'action' },
            { name: 'direction' },
            { name: 'billing', type: 'object',
              properties: [
                { name: 'costIncluded' },
                { name: 'costPurchased' }
              ] },
            { name: 'delegate', type: 'object',
              properties: [
                { name: 'id' },
                { name: 'name' }
              ] },
            { name: 'extensionId' },
            { name: 'duration', type: 'integer', render_input: 'integer_conversion', parse_output: 'integer_conversion' },
            { name: 'extension', type: 'object',
              properties: [
                { name: 'id' },
                { name: 'name' }
              ] },
            { name: 'legType' },
            { name: 'startTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
            { name: 'type' },
            { name: 'result' },
            { name: 'reason' },
            { name: 'reasonDescription' },
            { name: 'from', type: 'object',
              properties: [
                { name: 'phoneNumber' },
                { name: 'extensionNumber' },
                { name: 'extensionId' },
                { name: 'location' },
                { name: 'name' },
                { name: 'device', type: 'object',
                  properties: [
                    { name: 'id' },
                    { name: 'uri', label: 'URI' }
                  ] }
              ] },
            { name: 'to', type: 'object',
              properties: [
                { name: 'phoneNumber' },
                { name: 'extensionNumber' },
                { name: 'extensionId' },
                { name: 'location' },
                { name: 'name' },
                { name: 'device', type: 'object',
                  properties: [
                    { name: 'id' },
                    { name: 'uri', label: 'URI' }
                  ] }
              ] },
            { name: 'transport' },
            { name: 'recording', type: 'object',
              properties: [
                { name: 'id' },
                { name: 'uri', label: 'URI' },
                { name: 'type' },
                { name: 'contentUri', label: 'Content URI' }
              ] },
            { name: 'shortRecording', type: 'boolean', render_input: 'boolean_conversion', parse_output: 'boolean_conversion' },
            { name: 'master', type: 'boolean', render_input: 'boolean_conversion', parse_output: 'boolean_conversion' },
            { name: 'message', type: 'object',
              properties: [
                { name: 'id' },
                { name: 'uri', label: 'URI' },
                { name: 'type' }
              ] }
          ] },
        { name: 'billing', type: 'object',
          properties: [
            { name: 'costIncluded', type: 'integer', render_input: 'integer_conversion', parse_output: 'integer_conversion' },
            { name: 'costPurchased', type: 'integer', render_input: 'integer_conversion', parse_output: 'integer_conversion' }
          ] },
        { name: 'startTime', type: 'date_time', parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp' },
        { name: 'deleted', type: 'boolean', render_input: 'boolean_conversion', parse_output: 'boolean_conversion' },
        { name: 'duration', type: 'integer', render_input: 'integer_conversion', parse_output: 'integer_conversion' },
        { name: 'lastModifiedTime', type: 'date_time', parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp' },
        { name: 'recording', type: 'object',
          properties: [
            { name: 'id' },
            { name: 'uri', label: 'URI' },
            { name: 'type' },
            { name: 'contentUri', label: 'Content URI' }
          ] },
        { name: 'shortRecording', type: 'boolean', render_input: 'boolean_conversion', parse_output: 'boolean_conversion' },
        { name: 'action' },
        { name: 'result' },
        { name: 'reason' },
        { name: 'reasonDescription' }
      ]
    end,
    get_user_call_record_execute: lambda do |input|
      get("/restapi/v1.0/account/#{input.delete('accountId')}/extension/#{input.delete('extensionId')}/call-log/#{input.delete('callRecordId')}",
          input.except('object'))
    end,

    get_company_call_log_record_schema: lambda do |_input|
      [
        { name: 'callRecordId', optional: false, hint: 'Internal identifier of a call record' }
      ].concat(call('search_user_call_log_records_schema', '').only('accountId', 'view'))
    end,
    get_company_call_log_record_output_schema: lambda do |_input|
      call('get_user_call_record_output_schema', '')
    end,
    get_company_call_log_record_execute: lambda do |input|
      get("/restapi/v1.0/account/#{input.delete('accountId')}/call-log/#{input.delete('callRecordId')}", input.except('object'))
    end,

    get_call_recording_schema: lambda do |_input|
      [
        { name: 'recordingId', optional: false }
      ].concat(call('search_user_call_log_records_schema', '').only('accountId'))
    end,
    get_call_recording_output_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'contentUri', label: 'Content URI' },
        { name: 'contentType' },
        { name: 'duration', type: 'integer', render_input: 'integer_conversion', parse_output: 'integer_conversion' }
      ]
    end,
    get_call_recording_execute: lambda do |input|
      get("/restapi/v1.0/account/#{input.delete('accountId')}/recording/#{input.delete('recordingId')}")
    end,

    get_call_recordings_data_schema: lambda do |_input|
      [
        { name: 'recordingId', optional: false }
      ].concat(call('search_user_call_log_records_schema', '').only('accountId'))
    end,
    get_call_recordings_data_output_schema: lambda do |_input|
      [
        { name: 'file_contents' }
      ]
    end,
    get_call_recordings_data_execute: lambda do |input|
      response = get("/restapi/v1.0/account/#{input['accountId']}/recording/#{input['recordingId']}/content").
                 response_format_raw
      { file_contents: response }
    end,

    get_post_schema: lambda do |_input|
      call('update_post_schema', '').only('chatId', 'postId')
    end,
    get_post_output_schema: lambda do |_input|
      call('update_post_output_schema', '')
    end,
    get_post_execute: lambda do |input|
      get("/restapi/v1.0/glip/chats/#{input.delete('chatId')}/posts/#{input.delete('postId')}")
    end,

    get_conversation_schema: lambda do |_input|
      [
        { name: 'chatId', optional: false, hint: 'Internal identifier of a conversation.' }
      ]
    end,
    get_conversation_output_schema: lambda do |_input|
      call('create_conversation_output_schema', '')
    end,
    get_conversation_execute: lambda do |input|
      get("/restapi/v1.0/glip/conversations/#{input.delete('chatId')}")
    end,

    get_note_schema: lambda do |_input|
      [
        { name: 'noteId', optional: false, hint: 'Internal identifier of a conversation' }
      ]
    end,
    get_note_output_schema: lambda do |_input|
      [
        { name: 'body' }
      ].concat(call('create_note_output_schema', ''))
    end,
    get_note_execute: lambda do |input|
      get("/restapi/v1.0/glip/notes/#{input.delete('noteId')}")
    end,

    get_chat_schema: lambda do |_input|
      [
        { name: 'chatId', optional: false, hint: 'Internal identifier of a chat' }
      ]
    end,
    get_chat_output_schema: lambda do |_input|
      [
        { name: 'members', type: 'array', of: 'object',
          properties: [
            { name: 'id' }
          ] }
      ].concat(call('create_team_output_schema', ''))
    end,
    get_chat_execute: lambda do |input|
      get("/restapi/v1.0/glip/chats/#{input.delete('chatId')}")
    end,

    get_task_schema: lambda do |_input|
      [
        { name: 'taskId', optional: false, hint: 'Internal identifier of a task' }
      ]
    end,
    get_task_output_schema: lambda do |_input|
      call('create_task_output_schema', '')
    end,
    get_task_execute: lambda do |input|
      get("/restapi/v1.0/glip/tasks/#{input.delete('taskId')}")
    end,

    get_ringout_call_schema: lambda do |_input|
      [
        { name: 'accountId', optional: false,
          hint: 'Internal identifier of a RingCentral account or tilde (~) to ' \
          'indicate the account logged-in within the current session' },
        { name: 'extensionId', optional: false,
          hint: 'Internal identifier of an extension or tilde (~) to indicate ' \
          'the extension assigned to the account logged-in within the current session' },
        { name: 'ringoutId', optional: false, hint: 'Internal identifier of a RingOut call' }
      ]
    end,
    get_ringout_call_output_schema: lambda do |_input|
      call('create_ringout_call_output_schema', '')
    end,
    get_ringout_call_execute: lambda do |input|
      get("/restapi/v1.0/account/#{input.delete('accountId')}/extension/" \
           "#{input.delete('extensionId')}/ring-out/#{input.delete('ringoutId')}")
    end,

    get_team_schema: lambda do |_input|
      [
        { name: 'chatId', optional: false, hint: 'Internal identifier of a team to be returned' }
      ]
    end,
    get_team_output_schema: lambda do |_input|
      call('create_team_output_schema', '')
    end,
    get_team_execute: lambda do |input|
      get("/restapi/v1.0/glip/teams/#{input['chatId']}")
    end,

    get_calendar_event_schema: lambda do |_input|
      [
        { name: 'eventId', optional: false, hint: 'Internal identifier of an event' }
      ]
    end,
    get_calendar_event_output_schema: lambda do |_input|
      call('create_calendar_event_output_schema', '')
    end,
    get_calendar_event_execute: lambda do |input|
      get("/restapi/v1.0/glip/events/#{input['eventId']}")
    end,

    get_callout_session_status_schema: lambda do |_input|
      [
        { name: 'accountId', optional: false,
          hint: 'Internal identifier of a RingCentral account or tilde (~) to ' \
          'indicate the account logged-in within the current session' },
        { name: 'telephonySessionId', optional: false, hint: 'Internal identifier of a call session' }
      ]
    end,
    get_callout_session_status_output_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'origin', type: 'object',
          properties: [
            { name: 'type' }
          ] },
        { name: 'voiceCallToken' },
        { name: 'parties', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'status', type: 'object',
              properties: [
                { name: 'code' },
                { name: 'peerId', type: 'object',
                  properties: [
                    { name: 'sessionId' },
                    { name: 'telephonySessionId ' },
                    { name: 'partyId' }
                  ] },
                { name: 'reason' },
                { name: 'description' }
              ] },
            { name: 'muted' },
            { name: 'standAlone' },
            { name: 'park', type: 'object',
              properties: [
                { name: 'id' }
              ] },
            { name: 'from', type: 'object',
              properties: [
                { name: 'phoneNumber' },
                { name: 'name' },
                { name: 'deviceId' },
                { name: 'extensionId' }
              ] },
            { name: 'to', type: 'object',
              properties: [
                { name: 'phoneNumber' },
                { name: 'name' },
                { name: 'deviceId' },
                { name: 'extensionId' }
              ] },
            { name: 'owner', type: 'object',
              properties: [
                { name: 'accountId' },
                { name: 'extensionId' }
              ] },
            { name: 'direction' },
            { name: 'conferenceRole' },
            { name: 'ringOutRole' },
            { name: 'ringMeRole' },
            { name: 'recordings', type: 'array', of: 'object',
              properties: [
                { name: 'id' },
                { name: 'active' }
              ] }
          ] },
        { name: 'creationTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' }
      ]
    end,
    get_callout_session_status_execute: lambda do |input|
      get("/restapi/v1.0/account/#{input['accountId']}/telephony/sessions/#{input['telephonySessionId']}")
    end,

    ### UPDATE METHODS ###
    update_meeting_schema: lambda do |_input|
      [
        { name: 'meetingId', label: 'Meeting ID', optional: false, hint: 'Internal identifier of a RingCentral meeting' }
      ].concat(call('create_meeting_schema', ''))
    end,
    update_meeting_output_schema: lambda do |_input|
      call('create_meeting_output_schema', '')
    end,
    update_meeting_execute: lambda do |input|
      input['audioOptions'] = input['audioOptions']&.pluck('audioOptions') || nil
      input['recurrence']['weeklyByDays'] = input['recurrence']['weeklyByDays']&.split(',') || nil
      put("/restapi/v1.0/account/#{input.delete('accountId')}/extension/" \
          "#{input.delete('extensionId')}/meeting/" \
          "#{input.delete('meetingId')}", input.compact.except('object'))
    end,

    update_user_schema: lambda do |_input|
      [
        { name: 'userID', optional: false, hint: 'User ID to update' },
        { name: 'id', hint: 'Unique resource ID defined by RingCentral' }
      ].concat(call('create_user_schema', ''))
    end,
    update_user_output_schema: lambda do |_input|
      call('create_user_output_schema', '')
    end,
    update_user_execute: lambda do |input|
      input['schemas'] = input['schemas']&.split('|') || nil
      put("/scim/v2/Users/#{input.delete('userID')}", input.except('object'))
    end,

    update_contact_schema: lambda do |_input|
      [
        { name: 'contactId', type: 'integer', optional: false, control_type: 'integer',
          hint: 'Internal identifier of a contact record in the RingCentral to update' }
      ].concat(call('create_contact_schema', ''))
    end,
    update_contact_output_schema: lambda do |_input|
      call('create_contact_output_schema', '')
    end,
    update_contact_execute: lambda do |input|
      put("/restapi/v1.0/account/#{input.delete('accountId')}/extension/" \
          "#{input.delete('extensionId')}/address-book/contact/" \
          "#{input.delete('contactId')}", input.except('object'))
    end,

    update_post_schema: lambda do |_input|
      [
        { name: 'chatId', label: 'Chat ID',
          optional: false, hint: 'Internal identifier of a chat' },
        { name: 'postId', label: 'Post ID', optional: false,
          hint: 'Internal identifier of a post to be updated' },
        { name: 'text', hint: 'Post text', sticky: true }
      ]
    end,
    update_post_output_schema: lambda do |_input|
      call('create_post_output_schema', '')
    end,
    update_post_execute: lambda do |input|
      patch("/restapi/v1.0/glip/chats/#{input.delete('chatId')}/posts/#{input.delete('postId')}", input.except('object'))
    end,

    update_everyone_chat_schema: lambda do |_input|
      [
        { name: 'name', hint: 'Everyone chat name. Maximum number of characters supported is 250', sticky: true },
        { name: 'description', hint: 'Everyone chat description. Maximum number of characters supported is 1000', sticky: true }
      ]
    end,
    update_everyone_chat_output_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'creationTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'lastModifiedTime', type: 'date_time', control_type: 'date_time', parse_output: 'date_time_conversion' },
        { name: 'type' },
        { name: 'name' },
        { name: 'description' }
      ]
    end,
    update_everyone_chat_execute: lambda do |input|
      patch('/restapi/v1.0/glip/everyone', input.except('object'))
    end,

    update_calendar_event_schema: lambda do |_input|
      [
        { name: 'eventId', optional: false, hint: 'Internal identifier of an event to update' }
      ].concat(call('create_calendar_event_schema', ''))
    end,
    update_calendar_event_output_schema: lambda do |_input|
      call('create_calendar_event_output_schema', '')
    end,
    update_calendar_event_execute: lambda do |input|
      put("/restapi/v1.0/glip/events/#{input.delete('eventId')}", input.except('object'))
    end,

    update_task_schema: lambda do |_input|
      [
        { name: 'taskId', label: 'Task ID', optional: false,
          hint: 'Internal identifier of a task to update' },
        { name: 'subject', label: 'Subject', hint: 'Task name/subject', sticky: true },
        { name: 'assignees', label: 'Assignees', type: 'array', of: 'object', sticky: true,
          properties: [
            { name: 'id', hint: 'Assignee ID' }
          ] },
        {
          name: 'completenessCondition',
          control_type: 'select',
          sticky: true,
          pick_list: [
            %w[Simple Simple],
            %w[AllAssignees AllAssignees],
            %w[Percentage Percentage]
          ],
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'completenessCondition',
            control_type: 'text',
            type: 'string',
            label: 'Completeness condition',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: Simple, AllAssignees, Percentage'
          }
        },
        { name: 'startTime', hint: 'Task start date in UTC time zone.',
          type: 'date_time', sticky: true,
          parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp' },
        { name: 'dueDate', hint: 'Task due date/time in UTC time zone',
          type: 'date_time', sticky: true,
          parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp' },
        {
          name: 'color',
          control_type: 'select',
          sticky: true,
          hint: 'Color of Event title (including its presentation in Calendar)',
          pick_list: [
            %w[Black Black],
            %w[Red Red],
            %w[Orange Orange],
            %w[Yellow Yellow],
            %w[Green Green],
            %w[Blue Blue],
            %w[Purple Purple],
            %w[Magenta Magenta]
          ],
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'color',
            type: 'string',
            control_type: 'text',
            label: 'Color',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: Black, Red, Orange, Yellow, Green, Blue, Purple, Magenta'
          }
        },
        { name: 'section', hint: 'Task section to group', sticky: true },
        { name: 'description', hint: 'Task details', sticky: true },
        { name: 'recurrence', type: 'object', sticky: true,
          properties: [
            {
              name: 'schedule',
              control_type: 'select',
              sticky: true,
              hint: 'Task recurrence settings. For non-periodic tasks the value is None',
              pick_list: [
                %w[None None],
                %w[Day Day],
                %w[Weekday All],
                %w[Week Week],
                %w[Month Month],
                %w[Year Year]
              ],
              toggle_hint: 'Select from list',
              toggle_field:
              {
                name: 'schedule',
                type: 'string',
                control_type: 'text',
                label: 'Schedule',
                toggle_hint: 'Use custom value',
                optional: true,
                hint: 'Allowed values are: None, Day, Weekday, Week, Month, Year'
              }
            },
            {
              name: 'endingCondition',
              control_type: 'select',
              sticky: true,
              hint: 'Task ending condition',
              pick_list: [
                %w[None None],
                %w[Count Count],
                %w[Day Day]
              ],
              toggle_hint: 'Select from list',
              toggle_field:
              {
                name: 'endingCondition',
                type: 'string',
                control_type: 'text',
                label: 'EndingCondition',
                toggle_hint: 'Use custom value',
                optional: true,
                hint: 'Allowed values are: None, Count, Day'
              }
            },
            { name: 'endingAfter', sticky: true, type: 'integer',
              render_input: :integer_conversion,
              parse_output: :integer_conversion, hint: 'Count of iterations of periodic tasks' },
            { name: 'endingOn', sticky: true, hint: 'End date of periodic task',
              type: 'date_time',
              parse_output: 'date_time_conversion', render_input: 'render_iso8601_timestamp' }
          ] },
        { name: 'attachments', label: 'Attachments', type: 'array', of: 'object', sticky: true,
          properties: [
            { name: 'id', hint: 'Internal identifier of a file' }
          ] }
      ]
    end,
    update_task_output_schema: lambda do |_input|
      call('create_task_output_schema', '')
    end,
    update_task_execute: lambda do |input|
      patch("/restapi/v1.0/glip/tasks/#{input.delete('taskId')}", input.except('object'))
    end,

    update_team_schema: lambda do |_input|
      [
        {
          name: 'public',
          control_type: 'checkbox',
          sticky: true,
          type: 'boolean',
          render_input: 'boolean_conversion',
          parse_output: 'boolean_conversion',
          hint: 'Team access level',
          toggle_hint: 'Select from list',
          toggle_field:
          {
            name: 'public',
            control_type: 'text',
            type: 'boolean',
            label: 'Public',
            render_input: 'boolean_conversion',
            parse_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            optional: true,
            hint: 'Allowed values are: true, false'
          }
        },
        { name: 'name', sticky: true, hint: 'Team name' },
        { name: 'description', sticky: true, hint: 'Team description' },
        { name: 'chatId', optional: false, label: 'Chat ID', hint: 'Internal identifier of a team to be updated' }
      ]
    end,
    update_team_output_schema: lambda do |_input|
      call('create_team_output_schema', '')
    end,
    update_team_execute: lambda do |input|
      patch("/restapi/v1.0/glip/teams/#{input.delete('chatId')}", input.except('object'))
    end,

    update_note_schema: lambda do |_input|
      [
        { name: 'noteId', optional: false, hint: 'Internal identifier of a note' },
        { name: 'title', optional: false, hint: 'Title of a note' },
        { name: 'body', hint: 'Contents of a note', control_type: 'text-area', sticky: true }
      ]
    end,
    update_note_output_schema: lambda do |_input|
      call('get_note_output_schema', '')
    end,
    update_note_execute: lambda do |input|
      patch("/restapi/v1.0/glip/notes/#{input.delete('noteId')}", input.except('object'))
    end,

    ### DELETE METHODS ###
    delete_meeting_schema: lambda do |_input|
      call('get_meeting_schema', '')
    end,
    delete_meeting_execute: lambda do |input|
      delete("/restapi/v1.0/account/#{input['accountId']}/extension/#{input['extensionId']}/" \
             "meeting/#{input['meetingId']}")
    end,

    delete_user_schema: lambda do |_input|
      call('get_user_schema', '')
    end,
    delete_user_execute: lambda do |input|
      delete("/scim/v2/Users/#{input['id']}")
    end,

    delete_contact_schema: lambda do |_input|
      call('get_contact_schema', '')
    end,
    delete_contact_execute: lambda do |input|
      delete("/restapi/v1.0/account/#{input['accountId']}/extension/" \
             "#{input['extensionId']}/address-book/contact/#{input['contactId']}")
    end,

    delete_calendar_event_schema: lambda do |_input|
      call('get_calendar_event_schema', '')
    end,
    delete_calendar_event_execute: lambda do |input|
      delete("/restapi/v1.0/glip/events/#{input['eventId']}")
    end,

    delete_task_schema: lambda do |_input|
      call('get_task_schema', '')
    end,
    delete_task_execute: lambda do |input|
      delete("/restapi/v1.0/glip/tasks/#{input['taskId']}")
    end,

    delete_note_schema: lambda do |_input|
      call('get_note_schema', '')
    end,
    delete_note_execute: lambda do |input|
      delete("/restapi/v1.0/glip/notes/#{input['noteId']}")
    end,

    delete_post_schema: lambda do |_input|
      call('update_post_schema', '').only('chatId', 'postId')
    end,
    delete_post_execute: lambda do |input|
      delete("/restapi/v1.0/glip/chats/#{input['chatId']}/posts/#{input['postId']}")
    end,

    delete_team_members_schema: lambda do |_input|
      [
        { name: 'members', optional: false, type: 'array', of: 'object',
          properties: [
            { name: 'id', optional: false }
          ] },
        { name: 'chatId', optional: false, hint: 'Internal identifier of a chat' }
      ]
    end,
    delete_team_members_execute: lambda do |input|
      post("/restapi/v1.0/glip/teams/#{input.delete('chatId')}/remove", input.except('object'))
    end

  },

  object_definitions: {
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
            'https://platform.ringcentral.com' \
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
    },

    create_object_input: {
      fields: lambda do |_connection, config_fields|
        call("create_#{config_fields['object']}_schema", config_fields) || []
      end
    },
    create_object_output: {
      fields: lambda do |_connection, config_fields|
        call("create_#{config_fields['object']}_output_schema", config_fields) || []
      end
    },

    search_object_input: {
      fields: lambda do |_connection, config_fields|
        call("search_#{config_fields['object']}_schema", config_fields) || []
      end
    },
    search_object_output: {
      fields: lambda do |_connection, config_fields|
        call("search_#{config_fields['object']}_output_schema", config_fields) || []
      end
    },

    get_object_input: {
      fields: lambda do |_connection, config_fields|
        call("get_#{config_fields['object']}_schema", config_fields) || []
      end
    },
    get_object_output: {
      fields: lambda do |_connection, config_fields|
        call("get_#{config_fields['object']}_output_schema", config_fields) || []
      end
    },

    update_object_input: {
      fields: lambda do |_connection, config_fields|
        call("update_#{config_fields['object']}_schema", config_fields) || []
      end
    },
    update_object_output: {
      fields: lambda do |_connection, config_fields|
        call("update_#{config_fields['object']}_output_schema", config_fields) || []
      end
    },

    delete_object_input: {
      fields: lambda do |_connection, config_fields|
        call("delete_#{config_fields['object']}_schema", config_fields) || []
      end
    },
    publish_note_input: {
      fields: lambda do |_connection, _config_fields|
        [{ name: 'noteId', hint: 'Internal identifier of a note to be published', optional: false }]
      end
    },
    join_team_input: {
      fields: lambda do |_connection, _config_fields|
        [{ name: 'chatId', hint: 'Internal identifier of a team', optional: false }]
      end
    },

    send_sms_object_input: {
      fields: lambda do |_connection|
        call('create_send_sms_schema', '')
      end
    },
    send_sms_object_output: {
      fields: lambda do |_connection|
        call('create_send_sms_output_schema', '')
      end
    },

    make_ringout_call_object_input: {
      fields: lambda do |_connection|
        call('create_ringout_call_schema', '')
      end
    },
    make_ringout_call_object_output: {
      fields: lambda do |_connection|
        call('create_ringout_call_output_schema', '')
      end
    },

    cancel_ringout_call_object_input: {
      fields: lambda do |_connection|
        call('get_ringout_call_schema', '')
      end
    },

    callout_object_input: {
      fields: lambda do |_connection|
        call('create_callout_schema', '')
      end
    },
    callout_object_output: {
      fields: lambda do |_connection|
        call('create_callout_output_schema', '')
      end
    },

    reply_with_text_object_input: {
      fields: lambda do |_connection|
        call('create_reply_with_text_schema', '')
      end
    },
    reply_with_text_object_output: {
      fields: lambda do |_connection|
        call('create_reply_with_text_output_schema', '')
      end
    }
  },

  actions: {
    create_object: {
      title: 'Create object',
      subtitle: 'Create an object in RingCentral Video',
      description: lambda do |_connection, create_object_list|
        "Create <span class='provider'>#{create_object_list[:object]&.downcase || 'an object'}" \
        "</span> in <span class='provider'>RingCentral Video</span>"
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'Meeting' => 'Creates a new meeting.',
          'User' => 'Creates a new user.',
          'Contact' => 'Creates a personal user contact.',
          'Post' => 'Creates a post within the specified chat.',
          'Conversation' => 'Creates a new conversation or opens the existing one. ' \
          'If the conversation already exists, then its ID will be returned in response. ' \
          'A conversation is an adhoc discussion between a particular set of users, not featuring ' \
          'any specific name or description. If you add a person to the existing conversation, ' \
          'it creates a whole new conversation.',
          'Note' => 'Creates a new note in the specified chat.',
          'Team' => 'Creates a team, and adds a list of people to the team.',
          'Team members' => 'Adds members to the specified team.',
          'Calendar event' => 'Creates a new calendar event.',
          'Task' => 'Creates a task in the specified chat.'
        }[pick_lists['object']] || 'Create an object'

        { body: help.present? ? help : '' }
      end,
      config_fields: [
        {
          name: 'object',
          sticky: true,
          optional: false,
          type: 'string',
          extends_schema: true,
          control_type: 'select',
          pick_list: 'create_object_list',
          toggle_hint: 'Select object type to create',
          hint: 'Please select an item from the list.'
        }
      ],
      input_fields: lambda do |object_definition|
        object_definition['create_object_input']
      end,
      execute: lambda do |_connection, input|
        input = call('custom_input_parser', input)
        object_name = input['object']
        response = if object_name == 'team_members'
                     call("create_#{object_name}_execute", input).
                       after_response do |code, body, _headers|
                         if code == 204
                           { 'result' => 'Successfully added.' }
                         else
                           error(body)
                         end
                       end
                   else
                     call("create_#{object_name}_execute", input).
                       after_error_response(/.*/) do |_code, body, _header, message|
                         error("#{message}: #{body}")
                       end
                   end
        call('custom_output_parser', response)
      end,
      output_fields: lambda do |object_definition|
        object_definition['create_object_output']
      end,
      sample_output: lambda do |_connection, input|
        call('get_sample_output', input)
      end
    },
    search_object: {
      title: 'Search object',
      subtitle: 'Search an object in RingCentral Video',
      description: lambda do |_connection, search_object_list|
        "Search for <span class='provider'>#{search_object_list[:object]&.downcase || 'an object'}" \
        "</span> in <span class='provider'>RingCentral Video</span>"
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'Meetings' => 'Returns a list of meetings for a particular extension. ' \
          'The list of meetings does not include meetings of <b>Instant</b> type.',
          'Users' => 'Returns a list of users. Filters are supported.',
          'Contacts' => 'Returns user personal contacts.',
          'Company call log records' => 'Returns call log records filtered by parameters specified.',
          'User call log records' => 'Returns call log records filtered by parameters specified.',
          'User active calls' => 'Returns records of all extension calls that are in progress, ' \
          'ordered by start time in descending order.',
          'Company active calls' => 'Returns records of all calls that are in progress, ' \
          'ordered by start time in descending order.',
          'Posts' => 'Returns a list of posts from the specified chat.',
          'Conversations' => 'Returns the list of conversations where the user is a member. ' \
          'All records in response are sorted by creation time of a chat in ascending order.',
          'Notes' => 'Returns the list of notes created in the specified chat.',
          'Teams' => 'Returns the list of teams where the user is a member (both archived and active) ' \
          'combined with a list of public teams that can be joined by the current user. ' \
          'All records in response are sorted by creation time of a chat in ascending order.',
          'Calendar events' => 'Returns all calendar events created by the current user.',
          'Tasks' => 'Returns the list of tasks of the specified chat.',
          'Chats' => 'Returns the list of chats where the user is a member and also public teams that can be joined. ' \
          'All records in response are sorted by creation time of a chat in ascending order.',
          'Company meeting recordings' => 'Returns the list of meeting recordings for the current account.',
          'User meeting recordings' => 'Returns the list of meetings recordings for the current user.'
        }[pick_lists['object']] || ''

        { body: help.present? ? help : 'Search an object' }
      end,
      config_fields: [
        {
          name: 'object',
          sticky: true,
          type: 'string',
          optional: false,
          extends_schema: true,
          control_type: 'select',
          pick_list: 'search_object_list',
          toggle_hint: 'Select object type to search',
          hint: 'Please select an object from the list'
        }
      ],
      input_fields: lambda do |object_definition|
        object_definition['search_object_input']
      end,
      execute: lambda do |_connection, input|
        object_name = input['object']
        response = call("search_#{object_name}_execute", input).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end
        call('custom_output_parser', response)
      end,
      output_fields: lambda do |object_definition|
        object_definition['search_object_output']
      end,
      sample_output: lambda do |_connection, input|
        call('search_sample_output', input)
      end
    },
    get_object: {
      title: 'Get object',
      subtitle: 'Get an object in RingCentral Video',
      description: lambda do |_connection, get_object_list|
        "Get <span class='provider'>#{get_object_list[:object]&.downcase || 'an object'}" \
        "</span> in <span class='provider'>RingCentral Video</span>"
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'Meeting' => 'Returns a particular meetings details by ID.',
          'User' => 'Retrieve details of a specific user.',
          'Contact' => 'Retrieve contact details by ID.',
          'Company call log record' => 'Returns individual call log record by ID.',
          'Call recordings data' => 'Returns media content of a call recording.',
          'Call recording' => 'Returns call recordings by ID.',
          'User call record' => 'Returns call log records by ID.',
          'Ringout call' => 'Returns the status of a 2-leg RingOut call.',
          'Post' => 'Returns information about the specified post.',
          'Conversation' => 'Returns information about the specified conversation, ' \
          'including the list of conversation participants. A conversation is an adhoc discussion ' \
          'between a particular set of users, not featuring any specific name or description. ' \
          'If you add a person to the existing conversation, it creates a whole new conversation.',
          'Note' => 'Returns the details of the specified note.',
          'Team' => 'Returns information about the specified team.',
          'Calendar event' => 'Returns the specified calendar event by ID.',
          'Chat' => 'Returns information about a chat by ID.',
          'Task' => 'Returns information about the specified task by ID.',
          'Callout session status' => 'Returns the status of a call session by ID.'
        }[pick_lists['object']] || ''

        { body: help.present? ? help : 'Retrieve an object' }
      end,
      config_fields: [
        {
          name: 'object',
          sticky: true,
          type: 'string',
          optional: false,
          extends_schema: true,
          control_type: 'select',
          pick_list: 'get_object_list',
          toggle_hint: 'Select object type to get',
          hint: 'Please select an object from the list'
        }
      ],
      input_fields: lambda do |object_definition|
        object_definition['get_object_input']
      end,
      execute: lambda do |_connection, input|
        object_name = input['object']
        if object_name == 'call_recordings_data'
          call("get_#{object_name}_execute", input)
        else
          response = call("get_#{object_name}_execute", input).
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end
          call('custom_output_parser', response)
        end
      end,
      output_fields: lambda do |object_definition|
        object_definition['get_object_output']
      end,
      sample_output: lambda do |_connection, input|
        call('get_sample_output', input)
      end
    },
    update_object: {
      title: 'Update object',
      subtitle: 'Update an object in RingCentral Video',
      description: lambda do |_connection, update_object_list|
        "Update <span class='provider'>#{update_object_list[:object]&.downcase || 'an object'}" \
        "</span> in <span class='provider'>RingCentral Video</span>"
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'Meeting' => 'Modifies a particular meeting.',
          'User' => 'Update specific user details.',
          'Contact' => 'Updates personal contact information by contact ID.',
          'Post' => 'Updates a specific post within a chat.',
          'Note' => 'Edits a note. Notes can be edited by any user if posted to a chat the user belongs to.',
          'Team' => 'Updates the name and description of the specified team.',
          'Task' => 'Updates the specified task by ID.',
          'Everyone chat' => 'Updates Everyone chat information.',
          'Calendar event' => 'Updates the specified calendar event'
        }[pick_lists['object']] || ''

        { body: help.present? ? help : 'Update an object' }
      end,
      config_fields: [
        {
          name: 'object',
          sticky: true,
          type: 'string',
          optional: false,
          extends_schema: true,
          control_type: 'select',
          pick_list: 'update_object_list',
          toggle_hint: 'Select object type to update',
          hint: 'Please select an object from the list'
        }
      ],
      input_fields: lambda do |object_definition|
        object_definition['update_object_input']
      end,
      execute: lambda do |_connection, input|
        object_name = input['object']
        response = call("update_#{object_name}_execute", input).
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end
        call('custom_output_parser', response)
      end,
      output_fields: lambda do |object_definition|
        object_definition['update_object_output']
      end,
      sample_output: lambda do |_connection, input|
        call('get_sample_output', input)
      end
    },
    delete_object: {
      title: 'Delete object',
      subtitle: 'Delete an object in RingCentral Video',
      description: lambda do |_connection, delete_object_list|
        "Delete <span class='provider'>#{delete_object_list[:object]&.downcase || 'an object'}" \
        "</span> in <span class='provider'>RingCentral Video</span>"
      end,
      help: lambda do |_input, pick_lists|
        help = {
          'Meeting' => 'Deletes a scheduled meeting.',
          'User' => 'Deletes a specific user by ID.',
          'Contact' => 'Deletes a contact by ID.',
          'Post' => 'Deletes the specified post from the chat.',
          'Note' => 'Deletes the specified note.',
          'Team members' => 'Removes members from the specified team.',
          'Calendar event' => 'Deletes the specified calendar event.'
        }[pick_lists['object']] || ''

        { body: help.present? ? help : 'Delete an object' }
      end,
      config_fields: [
        {
          name: 'object',
          sticky: true,
          type: 'string',
          optional: false,
          extends_schema: true,
          control_type: 'select',
          pick_list: 'delete_object_list',
          toggle_hint: 'Select object type to Delete',
          hint: 'Please select an object from the list'
        }
      ],
      input_fields: lambda do |object_definition|
        object_definition['delete_object_input']
      end,
      execute: lambda do |_connection, input|
        call("delete_#{input['object']}_execute", input).
          after_response do |code, _body, _headers|
            if code == 204
              { result: 'Success' }
            end
          end.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'result' }]
      end,
      sample_output: lambda do |_input|
        { result: 'Success' }
      end
    },
    publish_note_object: {
      title: 'Publish note',
      subtitle: 'Publish a note in RingCentral Video',
      description: lambda do |_connection|
        "Publish <span class='provider'>a note" \
        "</span> in <span class='provider'>RingCentral Video</span>"
      end,
      help: lambda do |_input, _pick_lists|
        { body: 'Publishes a note making it visible to other users.' }
      end,
      input_fields: lambda do |object_definition|
        object_definition['publish_note_input']
      end,
      execute: lambda do |_connection, input|
        post("/restapi/v1.0/glip/notes/#{input['noteId']}/publish").
          after_response do |code, _body, _headers|
            if code == 204
              { result: 'Success' }
            end
          end.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'result' }]
      end,
      sample_output: lambda do |_input|
        { result: 'Success' }
      end
    },
    send_message_object: {
      title: 'Send SMS',
      subtitle: 'Send SMS in RingCentral Video',
      description: lambda do |_connection|
        "<span class='provider'>Send SMS" \
        "</span> in <span class='provider'>RingCentral Video</span>"
      end,
      help: lambda do |_input, _pick_lists|
        { body: 'Creates and sends a new text message. You can send SMS messages simultaneously ' \
          'to different recipients up to 40 requests per minute; this limitation is relevant for ' \
          'all client applications. Sending and receiving SMS is available for Toll-Free Numbers within the USA. ' }
      end,
      input_fields: lambda do |object_definition|
        object_definition['send_sms_object_input']
      end,
      execute: lambda do |_connection, input|
        call('create_send_sms_execute', input).
          after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,
      output_fields: lambda do |object_definition|
        object_definition['send_sms_object_output']
      end,
      sample_output: lambda do |_connection, input|
        call('send_sms_sample_output', input)
      end
    },
    make_ringout_call_object: {
      title: 'Make ringout call',
      subtitle: 'Make ringout call in RingCentral Video',
      description: lambda do |_connection|
        "<span class='provider'>Make ringout call" \
        "</span> in <span class='provider'>RingCentral Video</span>"
      end,
      help: lambda do |_input, _pick_lists|
        { body: 'Makes a 2-leg RingOut call.' }
      end,
      input_fields: lambda do |object_definition|
        object_definition['make_ringout_call_object_input']
      end,
      execute: lambda do |_connection, input|
        call('create_ringout_call_execute', input).
          after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,
      output_fields: lambda do |object_definition|
        object_definition['make_ringout_call_object_output']
      end,
      sample_output: lambda do |_connection, input|
        call('ringout_call_sample_output', input)
      end
    },
    cancel_ringout_call_object: {
      title: 'Cancel ringout call',
      subtitle: 'Cancel ringout call in RingCentral Video',
      description: lambda do |_connection|
        "<span class='provider'>Cancel ringout call" \
        "</span> in <span class='provider'>RingCentral Video</span>"
      end,
      help: lambda do |_input, _pick_lists|
        { body: 'Cancels a 2-leg RingOut call.' }
      end,
      input_fields: lambda do |object_definition|
        object_definition['cancel_ringout_call_object_input']
      end,
      execute: lambda do |_connection, input|
        delete("/restapi/v1.0/account/#{input['accountId']}/extension/#{input['extensionId']}/ring-out/#{input['ringoutId']}").
          after_response do |code, _body, _headers|
            if code == 204
              { result: 'Success' }
            end
          end.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'result' }]
      end,
      sample_output: lambda do |_input|
        { result: 'Success' }
      end
    },
    callout_object: {
      title: 'Make callout',
      subtitle: 'Make callout in RingCentral Video',
      description: lambda do |_connection|
        "<span class='provider'>Make callout" \
        "</span> in <span class='provider'>RingCentral Video</span>"
      end,
      help: lambda do |_input, _pick_lists|
        { body: 'Creates a new outbound call out session.' }
      end,
      input_fields: lambda do |object_definition|
        object_definition['callout_object_input']
      end,
      execute: lambda do |_connection, input|
        call('create_callout_execute', input).
          after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,
      output_fields: lambda do |object_definition|
        object_definition['callout_object_output']
      end,
      sample_output: lambda do |_connection, input|
        call('callout_sample_output', input)
      end
    },
    reply_with_text_object: {
      title: 'Reply with text',
      subtitle: 'Reply with text in RingCentral Video',
      description: lambda do |_connection|
        "<span class='provider'>Reply with text" \
        "</span> in <span class='provider'>RingCentral Video</span>"
      end,
      help: lambda do |_input, _pick_lists|
        { body: 'Replies with text/pattern without picking up a call.' }
      end,
      input_fields: lambda do |object_definition|
        object_definition['reply_with_text_object_input']
      end,
      execute: lambda do |_connection, input|
        call('create_reply_with_text_execute', input).
          after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,
      output_fields: lambda do |object_definition|
        object_definition['reply_with_text_object_output']
      end,
      sample_output: lambda do |_connection, input|
        call('reply_with_text_sample_output', input)
      end
    },
    join_team_object: {
      title: 'Join team',
      subtitle: 'Join a team in RingCentral Video',
      description: lambda do |_connection|
        "Join <span class='provider'>a team" \
        "</span> in <span class='provider'>RingCentral Video</span>"
      end,
      help: lambda do |_input, _pick_lists|
        { body: 'Adds the current user to the specified team.' }
      end,
      input_fields: lambda do |object_definition|
        object_definition['join_team_input']
      end,
      execute: lambda do |_connection, input|
        post("/restapi/v1.0/glip/teams/#{input['chatId']}/join").
          after_response do |code, _body, _headers|
            if code == 204
              { result: 'Success' }
            end
          end.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'result' }]
      end,
      sample_output: lambda do |_input|
        { result: 'Success' }
      end
    },
    leave_team_object: {
      title: 'Leave team',
      subtitle: 'Leave a team in RingCentral Video',
      description: lambda do |_connection|
        "Leave <span class='provider'>a team" \
        "</span> in <span class='provider'>RingCentral Video</span>"
      end,
      help: lambda do |_input, _pick_lists|
        { body: 'Removes the current user from the specified team.' }
      end,
      input_fields: lambda do |object_definition|
        object_definition['join_team_input']
      end,
      execute: lambda do |_connection, input|
        post("/restapi/v1.0/glip/teams/#{input['chatId']}/leave").
          after_response do |code, _body, _headers|
            if code == 204
              { result: 'Success' }
            end
          end.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
      end,
      output_fields: lambda do |_object_definitions|
        [{ name: 'result' }]
      end,
      sample_output: lambda do |_input|
        { result: 'Success' }
      end
    },
    custom_action: {
      subtitle: 'Build your own RingCentral Video action with a HTTP request',

      description: lambda do |object_value, _object_label|
        "<span class='provider'>" \
        "#{object_value[:action_name] || 'Custom action'}</span> in " \
        "<span class='provider'>RingCentral Video</span>"
      end,

      help: {
        body: 'Build your own RingCentral Video action with a HTTP request. ' \
        'The request will be authorized with your RingCentral Video connection.',
        learn_more_url: 'https://developers.ringcentral.com/api-reference/',
        learn_more_text: 'RingCentral Video API documentation'
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
        request_headers = input['request_headers']&.each_with_object({}) do |item, hash|
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

  pick_lists: {
    trigger_objects: lambda do
      [
        %w[Group group]
      ]
    end,
    phoneType: lambda do
      [
        %w[Work work],
        %w[Mobile mobile],
        %w[Other other]
      ]
    end,
    photoType: lambda do
      [
        %w[Photo photo]
      ]
    end,
    emailType: lambda do
      [
        %w[Work work]
      ]
    end,
    audioOptions: lambda do
      [
        %w[Phone Phone],
        %w[ComputerAudio ComputerAudio]
      ]
    end,
    meetingType: lambda do
      [
        %w[Scheduled Scheduled],
        %w[Instant Instant],
        %w[Recurring Recurring]
      ]
    end,
    delete_object_list: lambda do
      [
        %w[Meeting meeting],
        %w[User user],
        %w[Contact contact],
        %w[Post post],
        %w[Note note],
        %w[Team\ members team_members],
        %w[Calendar\ event calendar_event]
      ]
    end,
    update_object_list: lambda do
      [
        %w[Meeting meeting],
        %w[User user],
        %w[Contact contact],
        %w[Post post],
        %w[Note note],
        %w[Team team],
        %w[Task task],
        %w[Everyone\ chat everyone_chat],
        %w[Calendar\ event calendar_event]
      ]
    end,
    search_object_list: lambda do
      [
        %w[Meetings meetings],
        %w[Users users],
        %w[Contacts contacts],
        %w[Posts posts],
        %w[Conversations conversations],
        %w[Notes notes],
        %w[Teams teams],
        %w[Calendar\ events calendar_events],
        %w[Tasks tasks],
        %w[Chats chats],
        %w[User\ call\ log\ records user_call_log_records],
        %w[User\ active\ calls user_active_calls],
        %w[Company\ active\ calls company_active_calls],
        %w[Company\ call\ log\ records company_call_log_records],
        %w[Company\ meeting\ recordings account_meeting_recordings],
        %w[User\ meeting\ recordings user_meeting_recordings],
        %w[States states],
        %w[Countries countries],
        %w[Timezones timezones]
      ]
    end,
    create_object_list: lambda do
      [
        %w[Meeting meeting],
        %w[Contact contact],
        %w[User user],
        %w[Post post],
        %w[Conversation conversation],
        %w[Note note],
        %w[Team team],
        %w[Team\ members team_members],
        %w[Calendar\ event calendar_event],
        %w[Task task]
      ]
    end,
    get_object_list: lambda do
      [
        %w[Meeting meeting],
        %w[User user],
        %w[Contact contact],
        %w[Company\ call\ log\ record company_call_log_record],
        %w[Call\ recordings\ data call_recordings_data],
        %w[Call\ recording call_recording],
        %w[User\ call\ record user_call_record],
        %w[Ringout\ call ringout_call],
        %w[Post post],
        %w[Conversation conversation],
        %w[Note note],
        %w[Team team],
        %w[Calendar\ event calendar_event],
        %w[Chat chat],
        %w[Task task],
        %w[Callout\ session\ status callout_session_status]
      ]
    end,
    schemasType: lambda do
      [
        %w[urn:ietf:params:scim:schemas:core:2.0:User urn:ietf:params:scim:schemas:core:2.0:User],
        %w[urn:ietf:params:scim:schemas:extension:enterprise:2.0:User urn:ietf:params:scim:schemas:extension:enterprise:2.0:User]
      ]
    end
  }
}
