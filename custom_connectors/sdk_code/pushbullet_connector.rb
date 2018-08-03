{
  title: 'Pushbullet',

  connection: {
    authorization: {
      type: 'oauth2',

      authorization_url: ->() {
        'https://www.pushbullet.com/authorize?response_type=code'
      },

      token_url: ->() {
        'https://api.pushbullet.com/oauth2/token'
      },

      client_id: 'abababababab',

      client_secret: 'cdcdcdcdcdcd',

      credentials: ->(connection, access_token) {
        headers('Authorization': "Bearer #{access_token}")
      }
    }
  },

  object_definitions: {
    push: {
      fields: ->() {
        [
          { name: 'active', type: :boolean },
          { name: 'body' },
          { name: 'created' },
          { name: 'direction' },
          { name: 'dismissed', type: :boolean },
          { name: 'iden' },
          { name: 'modified' },
          { name: 'receiver_email' },
          { name: 'receiver_email_normalized' },
          { name: 'receiver_iden' },
          { name: 'sender_email' },
          { name: 'sender_email_normalized' },
          { name: 'sender_iden' },
          { name: 'sender_name' },
          { name: 'title' },
          { name: 'type' },
        ]
      }
    }
  },

  actions: {
    create_a_push: {
      input_fields: ->() {
        [
          { name: 'email', optional: false },
          { name: 'type', type: :select, optional: false, pick_list: [
            ["Note","note"],
            ["Link","link"],
            ["File","file"]
          ]},
          { name: 'title', optional: false },
          { name: 'body', optional: false },
          { name: 'url', hint: 'Required if type set to Link or File' },
          { name: 'file_type', hint: 'Required if type set to File' }
        ]
      },
      execute: ->(connection,input) {
        post("https://api.pushbullet.com/v2/pushes", input)
      },
      output_fields: ->(object_definitions) {
        object_definitions['push']
      }
    }
  },

  triggers: {}
}
