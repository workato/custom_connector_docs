{
  title: 'BambooHR (Custom)',

  connection: {
    fields: [
      {
        name: 'api_key',
        control_type: 'password',
        optional: false,
        hint: 'API Key'
      },
      {
        name: 'organization',
        optional: false,
        hint: 'Your organization name'
      }
    ],

    # Basic auth -  needs API Key as username
    authorization: {
      type: 'basic_auth',

      apply: lambda { |connection|
        user(connection['api_key'])
        headers('Accept' => 'application/json')
      }
    },

    base_uri: ->(_connection) { 'https://api.bamboohr.com' }
  },

  test: lambda { |connection|
    get("/api/gateway.php/#{connection['organization']}/v1/employees/directory")
  },

  object_definitions: {
    # BambooHR TimeOff
    timeoff: {
      fields: lambda { |_connection, _config_fields|
        [
          {
            control_type: 'text',
            label: 'ID',
            type: 'string',
            name: 'id'
          },
          {
            control_type: 'text',
            label: 'Employee ID',
            type: 'string',
            name: 'employeeId'
          },
          {
            properties: [
              {
                control_type: 'text',
                label: 'Last changed',
                type: 'string',
                name: 'lastChanged'
              },
              {
                control_type: 'text',
                label: 'Last changed by user ID',
                type: 'string',
                name: 'lastChangedByUserId'
              },
              {
                control_type: 'text',
                label: 'Status',
                type: 'string',
                name: 'status'
              }
            ],
            label: 'Status',
            type: 'object',
            name: 'status'
          },
          {
            control_type: 'text',
            label: 'Name',
            type: 'string',
            name: 'name'
          },
          {
            control_type: 'text',
            label: 'Start',
            type: 'string',
            name: 'start'
          },
          {
            control_type: 'text',
            label: 'End',
            type: 'string',
            name: 'end'
          },
          {
            control_type: 'text',
            label: 'Created',
            type: 'string',
            name: 'created'
          },
          {
            properties: [
              {
                control_type: 'text',
                label: 'ID',
                type: 'string',
                name: 'id'
              },
              {
                control_type: 'text',
                label: 'Name',
                type: 'string',
                name: 'name'
              },
              {
                control_type: 'text',
                label: 'Icon',
                type: 'string',
                name: 'icon'
              }
            ],
            label: 'Type',
            type: 'object',
            name: 'type'
          },
          {
            properties: [
              {
                control_type: 'text',
                label: 'Unit',
                type: 'string',
                name: 'unit'
              },
              {
                control_type: 'text',
                label: 'Amount',
                type: 'string',
                name: 'amount'
              }
            ],
            label: 'Amount',
            type: 'object',
            name: 'amount'
          },
          {
            properties: [
              {
                control_type: 'text',
                label: 'View',
                render_input: {},
                parse_output: {},
                toggle_hint: 'Select from option list',
                toggle_field: {
                  label: 'View',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'view'
                },
                type: 'boolean',
                name: 'view'
              },
              {
                control_type: 'text',
                label: 'Edit',
                render_input: {},
                parse_output: {},
                toggle_hint: 'Select from option list',
                toggle_field: {
                  label: 'Edit',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'edit'
                },
                type: 'boolean',
                name: 'edit'
              },
              {
                control_type: 'text',
                label: 'Cancel',
                render_input: {},
                parse_output: {},
                toggle_hint: 'Select from option list',
                toggle_field: {
                  label: 'Cancel',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'cancel'
                },
                type: 'boolean',
                name: 'cancel'
              },
              {
                control_type: 'text',
                label: 'Approve',
                render_input: {},
                parse_output: {},
                toggle_hint: 'Select from option list',
                toggle_field: {
                  label: 'Approve',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'approve'
                },
                type: 'boolean',
                name: 'approve'
              },
              {
                control_type: 'text',
                label: 'Deny',
                render_input: {},
                parse_output: {},
                toggle_hint: 'Select from option list',
                toggle_field: {
                  label: 'Deny',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'deny'
                },
                type: 'boolean',
                name: 'deny'
              },
              {
                control_type: 'text',
                label: 'Bypass',
                render_input: {},
                parse_output: {},
                toggle_hint: 'Select from option list',
                toggle_field: {
                  label: 'Bypass',
                  control_type: 'text',
                  toggle_hint: 'Use custom value',
                  type: 'boolean',
                  name: 'bypass'
                },
                type: 'boolean',
                name: 'bypass'
              }
            ],
            label: 'Actions',
            type: 'object',
            name: 'actions'
          },
          {
            properties: [],
            label: 'Dates',
            type: 'object',
            name: 'dates'
          },
          {
            properties: [
              {
                control_type: 'text',
                label: 'Employee',
                type: 'string',
                name: 'employee'
              },
              {
                control_type: 'text',
                label: 'Manager',
                type: 'string',
                name: 'manager'
              }
            ],
            label: 'Notes',
            type: 'object',
            name: 'notes'
          }
        ]
      }
    }
  },

  triggers: {
    new_time_off: {
      description: "New <span class='provider'>time off" \
        "</span> in <span class='provider'>BambooHR</span>",

      input_fields: lambda do |_object_definitions|
        [{
          name: 'since',
          label: 'When first started, this recipe should pick up events from',
          hint: 'When you start recipe for the first time, it picks up ' \
              'trigger events from this specified date and time. Leave ' \
              'empty to get events created one day ago',
          sticky: true,
          optional: true,
          type: 'date'
        }]
      end,

      poll: lambda { |connection, input, start_date|
        start_date = (start_date || input['since'] || 1.day.ago)&.to_date

        {
          events: get('/api/gateway.php' \
            "/#{connection['organization']}/v1/time_off/requests",
                      start: start_date),
          next_poll: now,
          can_poll_more: false
        }
      },

      dedup: ->(timeoff) { timeoff['id'] },

      output_fields: ->(object_definitions) { object_definitions['timeoff'] }
    }
  }
}
