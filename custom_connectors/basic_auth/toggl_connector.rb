{
  title: 'Toggl',

  connection: {
    fields: [
      {
        name: 'api_token',
        control_type: 'password',
        label: 'Toggl API token',
        hint: 'Available in "My Profile" page'
      }
    ],

    authorization: {
      type: 'basic_auth',
      
      # Toggl API expect the token to be sent as user name and the string 'api_token' as the password
      # curl -u "{your api_token}:api_token" "https://api.track.toggl.com/api/v8/me"
      credentials: ->(connection) {
        user(connection['api_token'])
        password('api_token')
      }
    }
  },
  
  test: ->(connection) {
    get("https://api.track.toggl.com/api/v8/me")
  },

  object_definitions: {
    time_entry: {
      fields: ->() {
        [
          { name:'id', type: :integer },
          { name:'wid', type: :integer },
          { name:'pid' },
          { name:'project_name' },
          { name:'billable', type: :boolean },
          { name:'start', type: :timestamp },
          { name:'stop', type: :timestamp },
          { name:'duration', type: :integer },
          { name:'description' },
          { name:'at', type: :timestamp }  
        ]
      }
    }
  },

  actions: {
    get_time_entries: {
      input_fields: ->(object_definitions) {
        [
          { name: 'date', type: :date, optional: false }
        ]
      },

      execute: ->(connection, input) {
        start_time = input['date'].to_time.beginning_of_day.utc.iso8601
        end_time = (input['date'].to_time + 1.days).beginning_of_day.utc.iso8601
        
        entries = get("https://api.track.toggl.com/api/v8/time_entries").
                  params(start_date: start_time,
                         end_date: end_time)
        
        {
          'entries': entries
        }
      },

      output_fields: ->(object_definitions) {
        [
          { name: 'entries', type: :array, of: :object, properties: object_definitions['time_entry'] }
        ]
      }
    },
    get_project_name: {
      input_fields: ->(object_definitions) {
        [
          { name: 'id', optional: false }
        ]
      },

      execute: ->(connection, input) {
        project = get("https://api.track.toggl.com/api/v8/projects/#{input['id']}")['data']
        {
          'project_name': project['name'],
          'client_id': project['cid']
        }
      },

      output_fields: ->(object_definitions) {
        [
          { name: 'project_name' },
          { name: 'client_id' }
        ]
      }
    },
    get_client_name: {
      input_fields: ->(object_definitions) {
        [
          { name: 'id', optional: false }
        ]
      },

      execute: ->(connection, input) {
        {
          'name': get("https://api.track.toggl.com/api/v8/clients/#{input['id']}")['data']['name']
        }
      },

      output_fields: ->(object_definitions) {
        [
          { name: 'name' }
        ]
      }
    },
    get_daily_report: {
      input_fields: ->(object_definitions) {
        [
          { name: 'date', optional: false },
          { name: 'workspace_id', optional: false },
          { name: 'user', optional: false, hint: 'Name of agent to generate report for. Input "me" for current user' }
        ]
      },

      execute: ->(connection, input) {
        # Toggl API expects ISO8601 format
        start_time = input['date'].to_time.beginning_of_day.utc.iso8601
        end_time = (input['date'].to_time + 1.days).beginning_of_day.utc.iso8601
        
        user = input['user'] == 'me' ? get("https://api.track.toggl.com/api/v8/me")['data']['fullname'] : input['user']
        
        report = get("https://api.track.toggl.com/reports/api/v2/summary").
                 params(since: start_time,
                        until: end_time,
                        user_agent: user,
                        workspace_id: input['workspace_id'])['data']
        
        {
          'report': report
        }
      },

      output_fields: ->(object_definitions) {
        [
          { name: 'report', type: :array, of: :object, properties: [
            { name: 'id' },
            { name: 'title', type: :object, properties: [
              { name: 'project' },
              { name: 'client' }
            ]},
            { name: 'time', type: :integer },
            { name: 'items', type: :array, of: :object, properties: [
              { name: 'title', type: :object, properties: [
                { name: 'time_entry' }
              ]}
            ]}
          ]}
        ]
      }
    },
  },

  triggers: {}
}
