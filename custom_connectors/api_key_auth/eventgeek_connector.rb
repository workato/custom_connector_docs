{
  title: 'EventGeek',

  connection: {
    fields: [
      {
        name: 'environment',
        control_type: 'select',
        label: 'Environment',
        optional: false,
        type: 'string',
        hint: 'Is this connecting to a sandbox account?',
        pick_list: [
          %w[Yes staging],
          %w[No app]
        ]
      },
      {
        name: 'api_key',
        control_type: 'password',
        label: 'API Key', optional: false,
        hint: "API key retrieved from <a href='https://app.eventgeek.com/"\
        "org/integrations/api' target='_blank'>Org Reports & Settings</a> page"
      }
    ],

    authorization: {
      type: 'api_key',

      credentials: lambda do |connection|
        headers('Authorization': "Bearer #{connection['api_key']}")
      end
    },

    base_uri: lambda do |connection|
      "https://#{connection['environment']}.eventgeek.com/api/v1/"
    end
  },

  test: lambda do |_connection|
    get('teams').dig('data', 0)
  end,

  methods: {
    convert_payload: lambda do |input|
      input.each do |key, value|
        input[key] =
          if key.include?('_date')
            # before_date, after_date, etc
            value&.to_time&.utc&.strftime('%Y-%m-%dT%H:%M:%SZ')
          elsif key.include?('_at')
            # Time range fields, eg: created_at, updated_at
            {
              min: value&.to_time&.utc&.strftime('%Y-%m-%dT%H:%M:%SZ'),
              max: now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
            }
          elsif %w[
            statuses types roles venue_names cities _method
            states countries event_ids teams queries
          ].include?(key) || key.include?('_by')
            value.split(',')
          else
            value
          end
      end
    end,

    event_schema: lambda do
      [
        { name: 'id' },
        { name: 'name' },
        {
          name: 'team',
          type: 'object',
          properties: [
            { name: 'id' },
            { name: 'name' }
          ]
        },
        {
          name: 'start_date',
          type: 'date',
          control_type: 'date',
          label: 'Start date',
          render_input: 'date_conversion',
          parse_output: 'date_conversion'
        },
        {
          name: 'end_date',
          type: 'date',
          control_type: 'date',
          label: 'End date',
          render_input: 'date_conversion',
          parse_output: 'date_conversion'
        },
        { name: 'status' },
        { name: 'types',
          type: 'array',
          of: 'object',
          control_type: 'text',
          properties: [
            { name: 'value' }
          ] },
        { name: 'roles',
          type: 'array',
          of: 'object',
          control_type: 'text',
          properties: [
            { name: 'value' }
          ] },
        {
          name: 'website',
          type: 'string',
          control_type: 'url'
        },
        {
          name: 'brief_url',
          type: 'string',
          control_type: 'url',
          label: 'Brief URL'
        },
        {
          name: 'location',
          label: 'Location',
          type: 'object',
          properties: [
            { name: 'name' },
            { name: 'address1' },
            { name: 'address2' },
            { name: 'country' },
            { name: 'city' },
            { name: 'state' },
            { name: 'postal_index' },
            { name: 'lat',
              label: 'Latitude',
              type: 'number',
              control_type: 'number',
              parse_output: 'float_conversion' },
            { name: 'lng',
              label: 'Longitude',
              control_type: 'number',
              parse_output: 'float_conversion',
              type: 'number' }
          ]
        },
        { name: 'virtual_location' },
        { name: 'planned_total',
          label: 'Planned total',
          type: 'integer',
          control_type: 'integer',
          parse_output: 'integer_conversion' },
        { name: 'actual_total',
          label: 'Actual total',
          type: 'integer',
          control_type: 'integer',
          parse_output: 'integer_conversion' },
        { name: 'paid_total',
          label: 'Paid total',
          type: 'integer',
          control_type: 'integer',
          parse_output: 'integer_conversion' },
        {
          name: 'created_at',
          label: 'Created at',
          type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion'
        },
        { name: 'created_by',
          type: 'object',
          properties: [
            { name: 'id' },
            { name: 'first_name' },
            { name: 'last_name' },
            { name: 'email',
              type: 'string',
              label: 'Email',
              control_type: 'email' }
          ] },
        {
          name: 'updated_at',
          label: 'Updated at',
          type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion'
        },
        { name: 'updated_by',
          type: 'object',
          properties: [
            { name: 'id' },
            { name: 'first_name' },
            { name: 'last_name' },
            { name: 'email',
              type: 'string',
              label: 'Email',
              control_type: 'email' }
          ] }
      ]
    end,

    team_schema: lambda do
      [
        { name: 'id', label: 'Team ID' },
        { name: 'name', label: 'Team Name' }
      ]
    end,

    contact_schema: lambda do
      [
        { name: 'id' },
        { name: 'first_name',
          hint: 'First name of the contact' },
        { name: 'last_name',
          hint: 'Last name of the contact' },
        { name: 'email',
          hint: 'Email of the contact' },
        { name: 'company',
          label: 'Company',
          type: 'object',
          hint: 'Company name of the contact',
          properties: [
            { name: 'id' },
            { name: 'name' }
          ] },
        { name: 'title',
          hint: 'Job title of the contact' },
        { name: 'owner',
          label: 'Owner',
          type: 'object',
          hint: 'Org member email who owns the contact',
          properties: [
            { name: 'id' },
            { name: 'first_name' },
            { name: 'last_name' },
            { name: 'email' }
          ] },
        { name: 'website',
          label: 'Website',
          type: 'string',
          control_type: 'url' },
        { name: 'office_phone',
          label: 'Office phone',
          type: 'string',
          control_type: 'phone' },
        { name: 'mobile_phone',
          label: 'Mobile phone',
          type: 'string',
          control_type: 'phone' },
        { name: 'address' },
        { name: 'city' },
        { name: 'state' },
        { name: 'postal_index' },
        { name: 'country' },
        { name: 'twitter',
          hint: 'Twitter profile URL' },
        { name: 'linkedin',
          label: 'LinkedIn',
          hint: 'LinkedIn profile URL' },
        {
          name: 'created_at',
          label: 'Created at',
          type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion'
        },
        { name: 'created_by',
          type: 'object',
          properties: [
            { name: 'id' },
            { name: 'first_name' },
            { name: 'last_name' },
            { name: 'email',
              type: 'string',
              label: 'Email',
              control_type: 'email' }
          ] },
        { name: 'created_method' },
        {
          name: 'updated_at',
          label: 'Updated at',
          type: 'date_time',
          control_type: 'date_time',
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion'
        },
        { name: 'updated_by',
          type: 'object',
          properties: [
            { name: 'id' },
            { name: 'first_name' },
            { name: 'last_name' },
            { name: 'email',
              type: 'string',
              label: 'Email',
              control_type: 'email' }
          ] },
        { name: 'updated_method' }
      ]
    end,

    create_event_schema: lambda do
      call('event_schema').
        only('name', 'website').
        required('name').
        concat(
          [
            {
              name: 'team_id', type: 'string', control_type: 'select',
              pick_list: 'teams',
              label: 'Team',
              optional: false,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'team_id',
                label: 'Team ID',
                optional: false,
                type: 'string', control_type: 'text',
                toggle_hint: 'Use custom value'
              }
            },
            {
              name: 'status', type: 'string', control_type: 'select',
              pick_list: 'event_statuses',
              label: 'Event status',
              optional: false,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'status',
                label: 'Event status',
                type: 'string', control_type: 'text',
                optional: false,
                toggle_hint: 'Use custom value',
                hint: 'Either one of: COMMITTED, CONSIDERING, SKIPPING, ' \
                'CANCELLED, POSTPONED'
              }
            },
            {
              name: 'start_date', type: 'date_time', control_type: 'date_time',
              label: 'Start date',
              optional: true, sticky: true,
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion'
            },
            {
              name: 'end_date', type: 'date_time', control_type: 'date_time',
              optional: true, sticky: true,
              label: 'End date',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion'
            },
            {
              name: 'location',
              optional: true,
              hint: 'A physical location will be assigned to the event, if provided' \
                ' location string matches any physical location in Google Maps. ' \
                'Otherwise provided value will be assigned as a virtual location.'
            },
            { name: 'types', label: 'Event type', optional: true },
            { name: 'roles', label: 'Role in event', optional: true }
          ]
        )
    end,

    create_contact_schema: lambda do
      call('contact_schema').
        only(
          'first_name', 'last_name', 'email', 'title', 'website',
          'office_phone', 'mobile_phone', 'address', 'city', 'state',
          'zip_code', 'country', 'twitter', 'linkedin'
        ).required('first_name', 'last_name', 'email').concat(
          [
            { name: 'owner', hint: 'Org member email who owns the contact' },
            { name: 'company', hint: 'Company name of the contact' }
          ]
        )
    end,

    create_event_contact_schema: lambda do
      [
        {
          name: 'event_id', type: 'string', control_type: 'select',
          label: 'Event',
          pick_list: 'events',
          hint: 'Select the event to retrieve contacts for',
          toggle_hint: 'Select from list',
          optional: false,
          toggle_field: {
            name: 'event_id',
            label: 'Event ID',
            type: 'string', control_type: 'text',
            optional: false,
            toggle_hint: 'Use custom value',
            hint: 'Enter the event ID of the event to retrieve contacts for'
          }
        },
        { name: 'contact_id', optional: false,
          hint: 'ID of the contact to add to this event' }
      ]
    end,

    update_event_schema: lambda do
      call('event_schema').
        only('id', 'name', 'website').
        required('id').
        concat(
          [
            {
              name: 'team_id', type: 'string', control_type: 'select',
              pick_list: 'teams',
              label: 'Team',
              optional: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'team_id',
                label: 'Team ID',
                optional: true,
                type: 'string', control_type: 'text',
                toggle_hint: 'Use custom value'
              }
            },
            {
              name: 'status', type: 'string', control_type: 'select',
              pick_list: 'event_statuses',
              label: 'Event status',
              optional: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'status',
                label: 'Event status',
                type: 'string', control_type: 'text',
                optional: true,
                toggle_hint: 'Use custom value',
                hint: 'Either one of: COMMITTED, CONSIDERING, SKIPPING, ' \
                'CANCELLED, POSTPONED'
              }
            },
            {
              name: 'start_date', type: 'date_time', control_type: 'date_time',
              label: 'Start date',
              optional: true, sticky: true,
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion'
            },
            {
              name: 'end_date', type: 'date_time', control_type: 'date_time',
              optional: true, sticky: true,
              label: 'End date',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion'
            },
            {
              name: 'location',
              optional: true,
              hint: 'A physical location will be assigned to the event, if provided' \
                ' location string matches any physical location in Google Maps. ' \
                'Otherwise provided value will be assigned as a virtual location.'
            },
            { name: 'types', label: 'Event type', optional: true },
            { name: 'roles', label: 'Role in event', optional: true }
          ]
        )
    end,

    update_contact_schema: lambda do
      call('contact_schema').
        only(
          'id', 'first_name', 'last_name', 'email', 'title',
          'website', 'office_phone', 'mobile_phone', 'address', 'city',
          'state', 'zip_code', 'country', 'twitter', 'linkedin'
        ).required('id').concat(
          [
            { name: 'owner', hint: 'Org member email who owns the contact' },
            { name: 'company', hint: 'Company name of the contact' }
          ]
        )
    end,

    search_event_schema: lambda do
      [
        {
          name: 'queries', label: 'Event name',
          optional: true, sticky: true,
          hint: 'Search using a comma separated list of event names. ' \
            'Returns events that contain these values in the event name' \
            'e.g. Event name,Event name 2'
        },
        {
          name: 'before_date', type: 'date_time', control_type: 'date_time',
          optional: true, sticky: true,
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Return events with dates before given value'
        },
        {
          name: 'after_date', type: 'date_time', control_type: 'date_time',
          optional: true, sticky: true,
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Return events with dates after given value'
        },
        {
          name: 'teams', type: 'string', control_type: 'multiselect',
          pick_list: 'teams',
          label: 'Teams',
          toggle_hint: 'Select from list',
          optional: true,
          hint: 'Return events that belong to provided teams',
          toggle_field: {
            name: 'teams', type: 'string', control_type: 'text',
            toggle_hint: 'Use custom value',
            optional: true,
            label: 'Team IDs',
            hint: 'Enter team IDs separated by commas. Return events that ' \
            'belong to provided teams'
          }
        },
        {
          name: 'statuses', type: 'string', control_type: 'select',
          pick_list: 'event_statuses',
          hint: 'Filters events with given statuses',
          label: 'Event status',
          toggle_hint: 'Select from list',
          optional: true,
          toggle_field: {
            name: 'statuses', type: 'string', control_type: 'text',
            toggle_hint: 'Use custom value',
            optional: true,
            label: 'Event status',
            hint: 'Comma separated string of either: COMMITTED, CONSIDERING, ' \
            'SKIPPING, CANCELLED, POSTPONED'
          }
        },
        {
          name: 'page', type: 'integer', control_type: 'integer',
          optional: true,
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion'
        }
      ]
    end,

    search_contact_schema: lambda do
      [
        {
          name: 'queries',
          label: 'Contact name',
          optional: true, sticky: true,
          hint: 'Search using a comma separated list of contact names. ' \
            'Returns contact that contain these values in the contact name' \
            'e.g. Contact name,Contact name 2'
        },
        {
          name: 'created_at', type: 'date_time', control_type: 'date_time',
          label: 'Created before',
          optional: true,
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Return contacts created after this date'
        },
        {
          name: 'updated_at', type: 'date_time', control_type: 'date_time',
          label: 'Updated before',
          optional: true,
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'Return contacts updated after this date'
        },
        {
          name: 'page', type: 'integer', control_type: 'integer',
          optional: true,
          render_input: 'integer_conversion',
          parse_output: 'integer_conversion'
        }
      ]
    end,

    trigger_event_schema: lambda do
      [
        {
          name: 'teams', type: 'string', control_type: 'multiselect',
          pick_list: 'teams',
          label: 'Teams',
          toggle_hint: 'Select from list',
          optional: true,
          hint: 'Return events that belong to provided teams',
          toggle_field: {
            name: 'teams', type: 'string', control_type: 'text',
            toggle_hint: 'Use custom value',
            optional: true,
            label: 'Team IDs',
            hint: 'Enter team IDs separated by commas. Return events that ' \
            'belong to provided teams'
          }
        },
        {
          name: 'statuses', type: 'string', control_type: 'multiselect',
          label: 'Event status',
          optional: true, sticky: true,
          pick_list: 'event_statuses', delimiter: ',',
          hint: 'Retrieve events with given statuses'
        },
        {
          name: 'created_at',
          label: 'When first started, this recipe should pick up events from',
          type: 'date_time',
          control_type: 'date_time',
          optional: true, sticky: true,
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'When you start recipe for the first time, ' \
          'it picks up trigger events from this specified date and time. ' \
          'Leave empty to get records created or updated one hour ago'
        }
      ]
    end,

    trigger_contact_schema: lambda do
      [
        {
          name: 'created_at',
          label: 'When first started, this recipe should pick up events from',
          type: 'date_time',
          control_type: 'date_time',
          optional: true, sticky: true,
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'When you start recipe for the first time, ' \
          'it picks up trigger events from this specified date and time. ' \
          'Leave empty to get records created or updated one hour ago'
        },
        {
          name: 'created_method',
          label: 'Created from',
          type: 'string',
          control_type: 'multiselect',
          optional: true,
          delimiter: ',',
          pick_list: 'contact_methods',
          hint: 'Retrieve contacts created using this method'
        }
      ]
    end,

    trigger_event_contact_schema: lambda do
      [
        {
          name: 'event_id',
          label: 'Event',
          type: 'string', control_type: 'select',
          pick_list: 'events',
          hint: 'Select the event to retrieve contacts for',
          toggle_hint: 'Select from list', optional: false,
          toggle_field: {
            name: 'event_id',
            label: 'Event ID',
            type: 'string', control_type: 'text',
            toggle_hint: 'Use custom value',
            optional: false,
            hint: 'Enter the event ID of the event.'
          }
        },
        {
          name: 'created_at',
          label: 'When first started, this recipe should pick up events from',
          type: 'date_time',
          control_type: 'date_time',
          optional: true, sticky: true,
          render_input: 'date_time_conversion',
          parse_output: 'date_time_conversion',
          hint: 'When you start recipe for the first time, ' \
          'it picks up trigger events from this specified date and time. ' \
          'Leave empty to get records created or updated one hour ago'
        }
      ]
    end
  },

  object_definitions: {
    search_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("search_#{config_fields['object']}_schema")
      end
    },

    search_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        [
          { name: config_fields['object'].pluralize,
            type: 'array', of: 'object',
            properties: call("#{config_fields['object']}_schema") },
          { name: 'current_page', type: 'integer',
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion' },
          { name: 'total_pages', type: 'integer',
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion' },
          { name: 'per_page', type: 'integer',
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion' },
          { name: 'total_entries', type: 'integer',
            render_input: 'integer_conversion',
            parse_output: 'integer_conversion' }
        ]
      end
    },

    get_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        [
          { name: 'id', label: "#{config_fields['object'].capitalize} ID",
            type: 'string', optional: false }
        ]
      end
    },

    get_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_schema")
      end
    },

    create_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("create_#{config_fields['object']}_schema")
      end
    },

    create_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if config_fields['object'] == 'event_contact'
          [{ name: 'status' }]
        else
          call("#{config_fields['object']}_schema")
        end
      end
    },

    update_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("update_#{config_fields['object']}_schema")
      end
    },

    update_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_schema")
      end
    },

    delete_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if config_fields['object'] == 'event_contact'
          [
            {
              name: 'event_id', type: 'string', control_type: 'select',
              label: 'Event',
              pick_list: 'events',
              hint: 'Select the event to retrieve contacts for',
              toggle_hint: 'Select from list',
              optional: false,
              toggle_field: {
                name: 'event_id',
                label: 'Event ID',
                type: 'string', control_type: 'text',
                optional: false,
                toggle_hint: 'Use custom value',
                hint: 'Enter the event ID of the event to retrieve contacts for'
              }
            },
            { name: 'contact_id', optional: false,
              hint: 'ID of the contact to add to this event' }
          ]
        else
          [
            { name: 'id', label: "#{config_fields['object'].capitalize} ID",
              type: 'string', optional: false }
          ]
        end
      end
    },

    delete_object_output: {
      fields: lambda do |_connection, _config_fields|
        [{ name: 'status' }]
      end
    },

    trigger_object_input: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("trigger_#{config_fields['object']}_schema")
      end
    },

    trigger_object_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if config_fields['object'] == 'event_contact'
          [
            { name: 'event_id' } # For easier operations on event contacts
          ].concat(call('contact_schema'))
        else
          call("#{config_fields['object']}_schema")
        end
      end
    }
  },

  actions: {
    search_records: {
      title: 'Search records',
      subtitle: 'Search any records e.g. contacts in EventGeek',
      description: lambda do |_connection, search_object_list|
        "Search <span class='provider'>" \
        "#{search_object_list[:object]&.downcase&.pluralize || 'records'} " \
        "</span> in <span class='provider'>EventGeek</span>"
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object',
          control_type: 'select',
          pick_list: 'search_object_list',
          hint: 'Select the object from list.'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['search_object_input']
      end,

      execute: lambda do |_connection, input|
        object_name = input.delete('object')
        payload = call(:convert_payload, input)
        response = get(object_name.pluralize).payload(payload.compact).request_format_json.
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end
        if object_name == 'event'
          response['data'].each do |event|
            event['types'] = event['types']&.map { |type| { value: type } }
            event['roles'] = event['roles']&.map { |role| { value: role } }
          end
        end

        {
          object_name.pluralize => response['data']
        }.merge(response['pagination'])
      end,
      output_fields: lambda do |object_definition|
        object_definition['search_object_output']
      end,
      sample_output: lambda do |_connection, input|
        response = get(input['object']&.pluralize)
        if input['object'] == 'event'
          response['data'].each do |event|
            event['types'] = event['types']&.map { |type| { value: type } }
            event['roles'] = event['roles']&.map { |role| { value: role } }
          end
        end
        {
          input['object']&.pluralize => response['data']
        }.merge(response['pagination'])
      end
    },

    get_record_by_id: {
      title: 'Get record by ID',
      subtitle: 'Get record by ID e.g. contact in EventGeek',
      description: lambda do |_connection, get_object_list|
        "Get <span class='provider'>" \
        "#{get_object_list[:object]&.downcase || 'record'} by ID</span> in " \
        "<span class='provider'>EventGeek</span>"
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object',
          control_type: 'select',
          pick_list: 'get_object_list',
          hint: 'Select the object from list.'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['get_object_input']
      end,

      execute: lambda do |_connection, input|
        response = get("#{input['object'].pluralize}/#{input['id']}").
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end
        if input['object'] == 'event'
          response['types'] = response['types']&.map { |type| { value: type } }
          response['roles'] = response['roles']&.map { |role| { value: role } }
        end
        response
      end,
      output_fields: lambda do |object_definition|
        object_definition['get_object_output']
      end,
      sample_output: lambda do |_connection, input|
        response = get(input['object']&.pluralize)&.dig('data')&.first
        if input['object'] == 'event'
          response['types'] = response['types']&.map { |type| { value: type } }
          response['roles'] = response['roles']&.map { |role| { value: role } }
        end
        response
      end
    },

    create_record: {
      title: 'Create record',
      subtitle: 'Create record e.g. contact in EventGeek',
      description: lambda do |_connection, create_object_list|
        if create_object_list[:object] == 'Event contact'
          "Add a <span class='provider'>contact to an event" \
          " </span> in <span class='provider'>EventGeek</span>"
        else
          "Create <span class='provider'>" \
          "#{create_object_list[:object]&.downcase || 'record'}</span> in " \
          "<span class='provider'>EventGeek</span>"
        end
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object',
          control_type: 'select',
          pick_list: 'create_object_list',
          hint: 'Select the object from list.'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['create_object_input']
      end,

      execute: lambda do |_connection, input|
        object_name = input.delete('object')
        payload = if object_name == 'event'
                    call(:convert_payload, input)
                  elsif object_name == 'event_contact'
                    input.except('event_id')
                  else
                    input
                  end
        url = if object_name == 'event_contact'
                "events/#{input['event_id']}/contacts"
              else
                object_name.pluralize
              end

        response = post(url).payload(payload).
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end
        if object_name == 'event_contact'
          response&.after_response do |_code, _body, _headers|
            { 'status': 'Success' }
          end
        else
          if input['object'] == 'event'
            response['types'] = response['types']&.map { |type| { value: type } }
            response['roles'] = response['roles']&.map { |role| { value: role } }
          end
          response
        end
      end,
      output_fields: lambda do |object_definition|
        object_definition['create_object_output']
      end,
      sample_output: lambda do |_connection, input|
        if input['object'] == 'event_contact'
          { 'status': 'Success' }
        else
          response = get(input['object']&.pluralize)&.dig('data')&.first
          if input['object'] == 'event'
            response['types'] = response['types']&.map { |type| { value: type } }
            response['roles'] = response['roles']&.map { |role| { value: role } }
          end
          response
        end
      end
    },

    update_record: {
      title: 'Update record',
      subtitle: 'Update record e.g. contact in EventGeek',
      description: lambda do |_connection, update_object_list|
        "Update <span class='provider'>" \
        "#{update_object_list[:object]&.downcase || 'record'}</span> in " \
        "<span class='provider'>EventGeek</span>"
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object',
          control_type: 'select',
          pick_list: 'update_object_list',
          hint: 'Select the object from list.'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['update_object_input']
      end,

      execute: lambda do |_connection, input|
        object_name = input.delete('object')
        payload = if object_name == 'event'
                    call(:convert_payload, input.except('id'))
                  else
                    input.except('id')
                  end
        response = patch("#{object_name.pluralize}/#{input['id']}").payload(payload).
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end
        if object_name == 'event'
          response['types'] = response['types']&.map { |type| { value: type } }
          response['roles'] = response['roles']&.map { |role| { value: role } }
        end
        response
      end,
      output_fields: lambda do |object_definition|
        object_definition['update_object_output']
      end,
      sample_output: lambda do |_connection, input|
        response = get(input['object']&.pluralize)&.dig('data')&.first
        if input['object'] == 'event'
          response['types'] = response['types']&.map { |type| { value: type } }
          response['roles'] = response['roles']&.map { |role| { value: role } }
        end
        response
      end
    },

    delete_record: {
      title: 'Delete record',
      subtitle: 'Delete record e.g. contact in EventGeek',
      description: lambda do |_connection, delete_object_list|
        if delete_object_list[:object] == 'Event contact'
          "Remove a <span class='provider'>contact from an event</span>" \
          " in <span class='provider'>EventGeek</span>"
        else
          "Delete <span class='provider'>" \
          "#{delete_object_list[:object]&.downcase || 'record'}</span> in " \
          "<span class='provider'>EventGeek</span>"
        end
      end,

      config_fields: [
        {
          name: 'object',
          optional: false,
          label: 'Object',
          control_type: 'select',
          pick_list: 'delete_object_list',
          hint: 'Select the object from list.'
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['delete_object_input']
      end,

      execute: lambda do |_connection, input|
        url = if input['object'] == 'event_contact'
                "events/#{input['event_id']}/contacts/#{input['contact_id']}"
              else
                "#{input['object']&.pluralize}/#{input['id']}"
              end

        delete(url)&.after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end&.
        after_response do |_code, _body, _headers|
          { 'status': 'Success' }
        end
      end,
      output_fields: lambda do |object_definition|
        object_definition['delete_object_output']
      end,
      sample_output: lambda do |_connection, _input|
        { 'status': 'Success' }
      end
    }
  },

  triggers: {
    new_record: {
      title: 'New record',
      subtitle: 'Triggers when a record is created. e.g. contact',
      description: lambda do |_input, pick_lists|
        "New <span class='provider'>" \
        "#{pick_lists['object']&.downcase || 'record'}" \
        "</span> in <span class='provider'>EventGeek</span>"
      end,
      help: lambda do |_input, pick_lists|
        "Triggers when a #{pick_lists['object']&.downcase || 'record'} is created."
      end,
      config_fields: [{
        name: 'object',
        optional: false,
        label: 'Object',
        control_type: 'select',
        pick_list: 'trigger_object_list',
        hint: 'Select the object from list.'
      }],
      input_fields: lambda do |object_definition|
        object_definition['trigger_object_input']
      end,

      poll: lambda do |_connection, input, closure|
        closure ||= {}
        object_name = input.delete('object')
        created_at = closure&.[]('created_at') ||
                     (input['created_at'] || 1.hour.ago).to_time.iso8601
        input['created_at'] = created_at
        payload = call(:convert_payload, input)
        payload['page'] = closure['page'] || 1
        url = if object_name == 'event_contact'
                "events/#{input['event_id']}/contacts"
              else
                object_name&.pluralize
              end
        response = get(url).payload(payload.compact).request_format_json.
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end

        if object_name == 'event'
          response['data'].each do |event|
            event['types'] = event['types']&.map { |type| { value: type } }
            event['roles'] = event['roles']&.map { |role| { value: role } }
          end
        end

        more_pages = (response['pagination']['current_page'] < response['pagination']['total_pages'])
        closure = if more_pages
                    { created_at: created_at,
                      page: (payload['page'] + 1) }
                  else
                    { created_at: input['created_at']['max'],
                      page: 1 }
                  end

        records = if object_name == 'event_contact'
                    response['data'].each do |contact|
                      contact['event_id'] = input['event_id']
                    end
                  else
                    response['data']
                  end

        {
          events: records,
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: lambda do |item|
        item['id']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['trigger_object_output']
      end,

      sample_output: lambda do |_connection, input|
        response = get(input['object']&.pluralize)&.dig('data')&.first
        if input['object'] == 'event'
          response['types'] = response['types']&.map { |type| { value: type } }
          response['roles'] = response['roles']&.map { |role| { value: role } }
        end
        response
      end
    },

    new_updated_record: {
      title: 'New/updated record',
      subtitle: 'Triggers when a record is created or updated. e.g. contact',
      description: lambda do |_input, pick_lists|
        "New/updated <span class='provider'>" \
        "#{pick_lists['object']&.downcase || 'record'}" \
        "</span> in <span class='provider'>EventGeek</span>"
      end,
      help: lambda do |_input, pick_lists|
        "Triggers when a #{pick_lists['object']&.downcase || 'record'} is " \
        'created or updated.'
      end,
      config_fields: [{
        name: 'object',
        optional: false,
        label: 'Object',
        control_type: 'select',
        pick_list: 'trigger_object_list',
        hint: 'Select the object from list.'
      }],
      input_fields: lambda do |object_definition|
        object_definition['trigger_object_input']
      end,

      poll: lambda do |_connection, input, closure|
        closure ||= {}
        object_name = input.delete('object')
        updated_at = closure&.[]('updated_at') ||
                     (input['updated_at'] || 1.hour.ago).to_time.iso8601
        input['updated_at'] = updated_at
        payload = call(:convert_payload, input)
        payload['page'] = closure['page'] || 1
        url = if object_name == 'event_contact'
                "events/#{input['event_id']}/contacts"
              else
                object_name&.pluralize
              end
        response = get(url).payload(payload.compact).request_format_json.
                     after_error_response(/.*/) do |_code, body, _header, message|
                       error("#{message}: #{body}")
                     end

        if object_name == 'event'
          response['data'].each do |event|
            event['types'] = event['types']&.map { |type| { value: type } }
            event['roles'] = event['roles']&.map { |role| { value: role } }
          end
        end

        more_pages = (response['pagination']['current_page'] < response['pagination']['total_pages'])
        closure = if more_pages
                    { created_at: updated_at,
                      page: (payload['page'] + 1) }
                  else
                    { created_at: input['updated_at']['max'],
                      page: 1 }
                  end

        records = if object_name == 'event_contact'
                    response['data'].each do |contact|
                      contact['event_id'] = input['event_id']
                    end
                  else
                    response['data']
                  end

        {
          events: records,
          next_poll: closure,
          can_poll_more: more_pages
        }
      end,

      dedup: lambda do |item|
        "#{item['id']}-#{item['updated_at']}"
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['trigger_object_output']
      end,

      sample_output: lambda do |_connection, input|
        response = get(input['object']&.pluralize)&.dig('data')&.first
        if input['object'] == 'event'
          response['types'] = response['types']&.map { |type| { value: type } }
          response['roles'] = response['roles']&.map { |role| { value: role } }
        end
        response
      end
    }
  },

  pick_lists: {
    search_object_list: lambda do |_conneciton|
      [
        %w[Contact contact],
        %w[Event event]
      ]
    end,

    get_object_list: lambda do |_conneciton|
      [
        %w[Contact contact],
        %w[Event event]
      ]
    end,

    create_object_list: lambda do |_conneciton|
      [
        %w[Contact contact],
        %w[Event event],
        %w[Event\ contact event_contact]
      ]
    end,

    update_object_list: lambda do |_conneciton|
      [
        %w[Contact contact],
        %w[Event event]
      ]
    end,

    delete_object_list: lambda do |_conneciton|
      [
        %w[Contact contact],
        %w[Event event],
        %w[Event\ contact event_contact]
      ]
    end,

    trigger_object_list: lambda do |_conneciton|
      [
        %w[Contact contact],
        %w[Event event],
        %w[Event\ contact event_contact]
      ]
    end,

    environments: lambda do
      [
        %w[Production app],
        %w[Development staging]
      ]
    end,

    event_statuses: lambda do
      [
        %w[Committed COMMITTED],
        %w[Skipping SKIPPING],
        %w[Considering CONSIDERING],
        %w[Cancelled CANCELLED],
        %w[Postponed POSTPONED]
      ]
    end,

    teams: lambda do |_connection|
      response = get('teams')
      response['data']&.map do |item|
        [item['name'], item['id']]
      end
    end,

    contact_methods: lambda do
      [
        [
          %w[Scanned SCANNED],
          %w[Import IMPORT],
          %w[Manual MANUAL],
          %w[Registration REGISTRATION],
          %w[API API]
        ]
      ]
    end,

    events: lambda do |_connection|
      response = get('events')
      items = response['data']
      current_page = response['pagination']['current_page']
      total_pages = response['pagination']['total_pages']
      poll_more = (current_page < total_pages)
      while poll_more
        response = get('events').
                     payload(page: (current_page + 1))
        current_page = response['pagination']['current_page']
        total_pages = response['pagination']['total_pages']
        poll_more = (current_page < total_pages)
        response['data'].each do |item|
          items << item
        end
      end

      items&.map do |item|
        [item['name'], item['id']]
      end
    end
  }
}
