{
  title: 'Hipchat',

  connection: {
    fields: [
      {
        name: 'subdomain',
        control_type: 'subdomain',
        url: '.hipchat.com',
        optional: false,
        hint: 'Enter your subdomain'
      },
      {
        name: 'auth_token',
        control_type: 'password',
        optional: false,
        label: "Access token",
        hint: 'Go to Account Settings->API Access. Enter password and get token'
      },
    ],

    authorization: {
      type: 'auth_token',
      credentials: ->(connection) {
        params(auth_token: connection['auth_token'])
      }
    }
  },

  object_definitions: {

    message: {
      fields: ->() {
        [
          { name: 'id', hint: "ID of the message" },
          { name: 'timestamp' }
        ]
      }
    }
  },

  test: ->(connection) {
    get("https://#{connection['subdomain']}.hipchat.com/v2/room")
  },

  actions: {
    post_message: {

      description: 'Post <span class="provider">Message</span> in <span class="provider">Hipchat</span>',
     
      input_fields: ->() {
        [
          { name: 'message', hint: "Valid length range: 1 - 1000", optional: false, label: "Message" },
          { name: 'room', hint: "Give either Room ID or Room name", optional: false, label: "Room" }
        ]
      },

      execute: ->(connection, input) {
        post("https://#{connection['subdomain']}.hipchat.com/v2/room/#{input['room']}/message",input)
      },

      output_fields: ->(object_definitions) {
        object_definitions['message']
      },

      sample_output: ->(connection) {
        room_id = get("https://#{connection['subdomain']}.hipchat.com/v2/room")['items'].last['id']
        get("https://#{connection['subdomain']}.hipchat.com/v2/room/#{room_id}/history")['items'].first || {}
      }
    },

    reply_to_message: {
      
      description: 'Reply to <span class="provider">Message</span> in <span class="provider">Hipchat</span>',
      
      input_fields: ->() {
        [
          { name: 'parentMessageId', hint: "The ID of the message you are replying to", label: "Message ID", optional: false },
          { name: 'message', hint: "Valid length range: 1 - 1000", optional: false, label: "Message" },
          { name: 'room', hint: "Give either Room ID or Room name", optional: false, label: "Room"}
        ]
      },

      execute: ->(connection, input) {
        post("https://#{connection['subdomain']}.hipchat.com/v2/room/#{input['room']}/reply",input)
      },

      output_fields: ->(object_definitions) {
      }
    }
  }
}
