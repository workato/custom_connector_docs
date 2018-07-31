{
  title: 'Harvest',

  # HTTP basic auth example.
  connection: {
    fields: [
      {
        name: 'subdomain',
        control_type: 'subdomain',
        url: '.harvestapp.com',
        hint: 'The subdomain found in your Harvest URL'
      },
      {
        name: 'username'
      },
      {
        name: 'password',
        control_type: 'password'
      }
    ],

    authorization: {
      type: 'basic_auth',

      # Basic auth credentials are just the username and password; framework handles adding
      # them to the HTTP requests.
      credentials: ->(connection) {
        user(connection['username'])
        password(connection['password'])
      }
    }
  },

  object_definitions: {
  },

  test: ->(connection) {
    get("https://#{connection['subdomain']}.harvestapp.com/account/who_am_i")
  },

  actions: {
    search_users: {
      # not used
      input_fields: ->(object_definitions) {
      },

      execute: ->(connection, input) {
        # harvest returns an array with each user wrapped in a hash [ { user: {} }, ..]
        # extract the object
        results = get("https://#{connection['subdomain']}.harvestapp.com/people.json", input).map do |row|
          row['user']
        end

        { results: results }
      },
      output_fields: ->(object_definitions) {
        [ 
          { 
            name: 'users',
            type: 'array',
            of: 'object',
            properties: [
              { name: 'id', type: 'integer' },
              { name: 'first_name' },
              { name: 'last_name' },
              { name: 'email' },
              { name: 'telephone' },
              { name: 'department' },
              { name: 'cost_rate' },
              { name: 'is_admin', type: 'boolean' },          
              { name: 'is_active', type: 'boolean' },          
              { name: 'is_contractor', type: 'boolean' },          
              { name: 'has_access_to_all_future_projects', type: 'boolean' },          
              { name: 'created_at', type: 'date_time' },
              { name: 'updated_at', type: 'date_time' },
            ]
          }
      	]
      }
    }
  },
}
