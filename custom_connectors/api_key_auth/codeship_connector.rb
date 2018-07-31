{
  title: 'Codeship',

  connection: {
    fields: [
      {
        name: 'api_key',
        control_type: 'password',
        label: 'API key',
        optional: false,
        hint: 'Go to My Account->Account settings and get Api key'
      }
    ],

    authorization: {
      type: 'api_key',
      credentials: ->(connection) {
        params(api_key: connection['api_key'])
      }
    }
  },

  object_definitions: {
    build: {
      fields: ->() {
        [
          { name: 'id', hint: "ID of the particular build" },
          { name: 'uuid' },
          { name: 'status' },
          { name: 'project_id', hint: "ID of the particular project"},
          { name: 'branch', hint: "Name of the branch" },
          { name: 'commit_id', hint: "ID of the commited build" },
          { name: 'github_username', hint: "User of the github for particular build" },
          { name: 'message', hint: "Message of your build" },
          { name: 'started_at' },
          { name: 'finished_at' },
        ]
      }
    }
  },

  test: ->(connection) {
    get("https://codeship.com/api/v1/projects")
  },

  actions: {
    list_builds: {

      description: 'List <span class="provider">Builds</span> in <span class="provider">Codeship</span>',

      input_fields: ->() {
        [
          { name: 'project_id', optional: false }
        ]
      },

      execute: ->(connection, input) {
        get("https://codeship.com/api/v1/projects/#{input['project_id']}")
      },

      output_fields: ->(object_definitions) {
        [
          { name:'id' },
          { name:'repository_name' },
          { name:'repository_provider' },
          { name:'uuid' },
          { name: 'builds', type: :array, of: :object, properties: object_definitions['build'] }
        ]
      },

      sample_output: ->(connection) {
        get("https://codeship.com/api/v1/projects")['projects'].first || {}
      },
    },

    restart_build: {

      description: 'Restart <span class="provider">Build</span> in <span class="provider">Codeship</span>',

      input_fields: ->() {
        [
          { name: 'id', optional: false, hint: 'ID of the particular build', label: 'Build ID' }
        ]
      },

      execute: ->(connection, input) {
        post("https://codeship.com/api/v1/builds/#{input['id']}/restart")
      },

      output_fields: ->(object_definitions) {
        object_definitions['build']
      },

      sample_output: ->(connection) {
        get("https://codeship.com/api/v1/projects")['projects'][0]['builds'].first || {}
      }
    }
  }
}
