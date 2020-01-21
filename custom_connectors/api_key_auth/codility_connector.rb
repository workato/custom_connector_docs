{
  title: 'Codility',

  methods: {
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
    end
  },

  connection: {
    fields: [{
      name: 'token',
      label: 'Access token',
      hint: 'Authorization bearer token of your Integrations ' \
      "application. Log in to Codility and go to the <a  href='https://" \
      "app.codility.com/accounts/integrations/' target='_blank'>Integrations " \
      'section in My Account</a>, then create an Application. Copy the ' \
      'Bearer token and paste here, e.g. Authorization: Bearer ' \
      '<b>ABCDevYwFICjc1nctsr9L</b>.',
      optional: false
    }],

    base_uri: ->(_connection) { 'https://codility.com' },

    authorization: {
      type: 'api_key',

      apply: lambda { |connection|
        headers('Authorization' => "Bearer #{connection['token']}")
      }
    }
  },

  test: ->(_connection) { get('/api/account/user-logins') },

  object_definitions: {
    custom_action_input: {
      fields: lambda do |_connection, config_fields|
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')

        [
          {
            name: 'path',
            optional: false,
            hint: 'Base URI is <b>https://codility.com</b> - path will be ' \
            'appended to this URI. Use absolute URI to override this base URI.'
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
                        properties: input_schema
                          .each { |field| field[:sticky] = true }
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

    add_candidate_input: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'test_id',
            hint: 'Identifier used to identify the the test.'
          },
          {
            name: 'candidates',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'id',
                hint: 'Identifier used to identify the candidate taking the ' \
                'test. It does not have to be unique',
                optional: false
              },
              {
                name: 'redirect_url',
                label: 'Redirect URL',
                hint: 'URL where to redirect (HTTP 302) the candidate after ' \
                'the evaluation is completed',
                control_type: 'url'
              },
              { name: 'first_name', hint: 'Candidates first name' },
              { name: 'last_name', hint: 'Candidates last name' },
              {
                name: 'email',
                hint: 'Candidates email',
                control_type: 'email'
              },
              {
                name: 'additional_data',
                hint: 'Any data in JSON format you want to store with candidate'
              }
            ]
          },
          {
            name: 'rpt_emails',
            label: 'RPT emails',
            hint: 'Provide comma seperated emails, that should receive ' \
            'e-mail reports, e.g. E.g. "raven@example.com",' \
            '"starfire@example.com". If not specified will default to ' \
            'the tests settings. '
          },
          {
            name: 'event_callbacks',
            hint: 'Data passed in event_callbacks can be used to specify ' \
            'endpoints to which Codility will send HTTP POST requests when ' \
            'the specified event occurs.',
            type: 'array',
            of: 'object',
            properties: [
              {
                name: 'event',
                hint: 'Depending on this ' \
                'value the HTTP request will be made either when the test ' \
                'result is available (result), or when similarity status ' \
                'of the session is available (similarity)',
                optional: false,
                control_type: 'select',
                pick_list: 'events',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'event',
                  label: 'Event',
                  hint: 'Depending on this ' \
                  'value the HTTP request will be made either when the test ' \
                  'result is available (result), or when similarity status ' \
                  'of the session is available (similarity). ' \
                  'Allowed values: result, similarity.',
                  toggle_hint: 'Use custom value',
                  control_type: 'text',
                  type: 'string'
                }
              },
              {
                name: 'url',
                control_type: 'url',
                hint: 'URL to which the HTTP POST request will be made ' \
                'with session data',
                optional: false
              }
            ]
          }
        ]
      end
    },

    add_candidate_output: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            name: 'candidates',
            type: 'array',
            of: 'object',
            label: 'Candidates',
            properties: [
              { name: 'id' },
              { name: 'test_link', control_type: 'url' },
              { name: 'session_url', label: 'Session URL', control_type: 'url' }
            ]
          }
        ]
      end
    },

    session: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'url', label: 'URL', control_type: 'url' },
          { name: 'id' },
          { name: 'candidate' },
          { name: 'first_name' },
          { name: 'last_name' },
          { name: 'email', control_type: 'email' },
          {
            name: 'create_date',
            control_type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time'
          },
          {
            name: 'start_date',
            control_type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion',
            type: 'date_time'
          },
          { name: 'campaign_url', control_type: 'url', label: 'Campaign URL' },
          { name: 'similarity' },
          {
            name: 'evaluation',
            type: 'object',
            properties: [
              {
                name: 'result',
                control_type: 'number',
                parse_output: 'float_conversion',
                type: 'number'
              },
              {
                name: 'max_result',
                control_type: 'number',
                parse_output: 'float_conversion',
                type: 'number'
              },
              {
                name: 'tasks',
                type: 'array',
                of: 'object',
                properties: [
                  { name: 'task_name' },
                  {
                    name: 'result',
                    control_type: 'number',
                    parse_output: 'float_conversion',
                    type: 'number'
                  },
                  {
                    name: 'max_result',
                    control_type: 'number',
                    parse_output: 'float_conversion',
                    type: 'number'
                  },
                  { name: 'prg_lang', label: 'Programming language' },
                  { name: 'name' }
                ]
              }
            ]
          },
          { name: 'report_link', control_type: 'url' },
          {
            name: 'pdf_report_url',
            label: 'PDF report URL',
            control_type: 'url'
          },
          { name: 'feedback_link', control_type: 'url' },
          { name: 'cancel_url', label: 'Cancel URL', control_type: 'url' },
          { name: 'test_link', control_type: 'url' },
          {
            name: 'candidate_data',
            type: 'object',
            properties: [
              { name: 'school' },
              { name: 'academic_degree' },
              { name: 'field_of_study' },
              { name: 'programming_experience' },
              { name: 'profile_url', control_type: 'url' },
              { name: 'additional_data' }
            ]
          }
        ]
      end
    },

    test: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'url', label: 'URL', control_type: 'url' },
          { name: 'id' },
          { name: 'name' },
          {
            name: 'create_date',
            control_type: 'date_time',
            type: 'date_time',
            render_input: 'date_time_conversion',
            parse_output: 'date_time_conversion'
          },
          { name: 'is_archived', type: 'boolean' },
          { name: 'public_test_link', control_type: 'url' },
          { name: 'invite_url', label: 'Invite URL', control_type: 'url' },
          { name: 'sessions_url', label: 'Sessions URL', control_type: 'url' }
        ]
      end
    }
  },

  actions: {
    # Custom action for Codility
    custom_action: {
      description: "Custom <span class='provider'>action</span> " \
        "in <span class='provider'>Codility</span>",

      help: {
        body: 'Build your own Codility action with an HTTP request. The ' \
          'request will be authorized with your Codility connection.',
        learn_more_url: 'https://codility.com/api-documentation',
        learn_more_text: 'Codility API Documentation'
      },

      execute: lambda do |_connection, input|
        verb = input['verb']
        error("#{verb} not supported") if %w[get post put delete].exclude?(verb)
        data = input.dig('input', 'data').presence || {}

        case verb
        when 'get'
          response =
            get(input['path'], data)
            .after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end.compact

          if response.is_a?(Array)
            array_name = parse_json(input['output'] || '[]')
                         .dig(0, 'name') || 'array'
            { array_name.to_s => response }
          elsif response.is_a?(Hash)
            response
          else
            error('API response is not a JSON')
          end
        when 'post'
          post(input['path'], data)
            .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.compact
        when 'put'
          put(input['path'], data)
            .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.compact
        when 'delete'
          delete(input['path'], data)
            .after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end.compact
        end
      end,

      config_fields: [{
        name: 'verb',
        label: 'Request type',
        hint: 'Select HTTP method of the request',
        optional: false,
        control_type: 'select',
        pick_list: %w[get post].map { |verb| [verb.upcase, verb] }
      }],

      input_fields: lambda do |object_definitions|
        object_definitions['custom_action_input']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['custom_action_output']
      end
    },

    search_tests: {
      description: "Search <span class='provider'>tests</span> in " \
        "<span class='provider'>Codility</span>",
      help: 'Search will return results that match all your search criteria.',

      execute: lambda do |_connection, input|
        {
          tests: get('/api/tests', input)
            .after_error_response(/.*/) do |_code, body, _header, message|
                   error("#{message}: #{body}")
                 end['results']
        }
      end,

      input_fields: lambda do |_object_definitions|
        [{
          name: 'is_archived',
          sticky: true,
          control_type: 'select',
          pick_list: 'boolean_values',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'is_archived',
            label: 'Is archived',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values: True, False.',
            control_type: 'text',
            type: 'string'
          }
        }]
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'tests',
          type: 'array',
          of: 'object',
          properties: object_definitions['test']
        }]
      end,

      sample_output: lambda do |_connection, _input|
        { tests: get('/api/tests')['results'] }
      end
    },

    get_test_by_id: {
      description: "Get <span class='provider'>test</span> by ID " \
        "in <span class='provider'>Codility</span>",

      execute: lambda do |_connection, input|
        get("/api/tests/#{input['id']}")
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['test'].only('id').required('id')
      end,

      output_fields: ->(object_definitions) { object_definitions['test'] },

      sample_output: lambda do |_connection, _input|
        get('/api/tests').dig('results', 0) || {}
      end
    },

    get_session_by_id: {
      description: "Get <span class='provider'>session</span> by ID " \
        "in <span class='provider'>Codility</span>",

      execute: lambda do |_connection, input|
        get("/api/sessions/#{input['id']}")
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['session'].only('id').required('id')
      end,

      output_fields: ->(object_definitions) { object_definitions['session'] },

      sample_output: lambda do |_connection, _input|
        get('/api/sessions').dig('results', 0) || {}
      end
    },

    add_candidates_to_test: {
      description: "Add <span class='provider'>candidates</span> " \
        "to a test in <span class='provider'>Codility</span>",
      help: 'You can create a test for the candidate.',

      execute: lambda do |_connection, input|
        post("/api/tests/#{input['test_id']}/invite/", input)
          .after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
      end,

      input_fields: lambda do |object_definitions|
        object_definitions['add_candidate_input']
          .required('test_id', 'candidate', 'event_callbacks')
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['add_candidate_output']
      end,

      sample_output: lambda do |_connection, _input|
        {
          candidates: [{
            id: '1',
            test_link: 'https://app.codility.com/test/M6CW57-7EC/',
            session_url: 'https://codility.com/api/sessions/M6CW57-7EC/'
          }]
        }
      end
    }
  },

  triggers: {
    new_test: {
      description: "New <span class='provider'>test</span> in " \
        "<span class='provider'>Codility</span>",

      poll: lambda do |_connection, _input, next_page|
        records = get(next_page || '/api/tests')

        {
          events: records['results'],
          next_poll: (next_page = records['next']).presence,
          can_poll_more: next_page.present?
        }
      end,

      dedup: ->(test) { test['id'] },

      output_fields: ->(object_definitions) { object_definitions['test'] },

      sample_output: lambda do |_connection, _input|
        get('/api/tests').dig('results', 0) || {}
      end
    },

    new_updated_test_status: {
      title: 'New or updated test status',
      description: "New/updated test <span class='provider'>status</span> in " \
        "<span class='provider'>Codility</span>",
      help: 'The event is triggered if the session gets created or ' \
      'a candidate starts taking the test.',

      poll: lambda do |_connection, _input, next_page|
        records = get(next_page || '/api/sessions')

        {
          events: records['results'],
          next_poll: (next_page = records['next']).presence,
          can_poll_more: next_page.present?
        }
      end,

      dedup: ->(session) { "#{session['id']}@#{session['start_date']}" },

      output_fields: ->(object_definitions) { object_definitions['session'] },

      sample_output: lambda do |_connection, _input|
        get('/api/sessions').dig('results', 0) || {}
      end
    }
  },

  pick_lists: {
    boolean_values: ->(_connection) { [%w[Yes True], %w[No False]] },

    events: ->(_connection) { [%w[Result result], %w[Similarity similarity]] }
  }
}
