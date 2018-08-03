{
  title: 'Click Time',

  connection: {
    fields: [
      {
        name: 'username',
        optional: true,
        hint: 'Your email used for login'
      },
      {
        name: 'password',
        control_type: 'password',
      }
    ],

    authorization: {
      type: 'basic_auth',

      credentials: ->(connection) {
        user(connection['username'])
        password(connection['password'])
      }
    }
  },

  object_definitions: {
    session: {
      fields: ->() {
        [
          { name: 'CompanyID' },
          { name: 'SecurityLevel' },
          { name: 'Token' },
          { name: 'UserEmail' },
          { name: 'UserID' },
          { name: 'UserName' }
        ]
      }
    }
  },

  test: ->(connection) {
    get("https://app.clicktime.com/api/1.3/session")
  },

  actions: {
    get_user_and_company_id: {
      input_fields: ->() {
      },
      
      execute: -> (connection, input) {
        get("https://app.clicktime.com/api/1.3/session")
      },
      
      output_fields: -> (object_definitions) {
        object_definitions['session']
      }
    }
  },

  triggers: {}
}
