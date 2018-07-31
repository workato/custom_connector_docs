{
  title: 'Cisco Spark',

    connection: {
      authorization: {
        type: 'oauth2',

        authorization_url: ->() {
          scope = [ "spark:messages_write",
                    "spark:rooms_read",
                    "spark:memberships_read",
                    "spark:messages_read",
                    "spark:rooms_write",
                    "spark:people_read",
                    "spark:memberships_write"].join(" ")

          "https://api.ciscospark.com/v1/authorize?response_type=code&scope=#{scope}"
        },

        token_url: ->() {
          "https://api.ciscospark.com/v1/access_token"
        },

        client_id: "YOUR_CISCO_SPARK_CLIENT_ID",

        client_secret: "YOUR_CISCO_SPARK_CLIENT_SECRET",

        credentials: ->(connection, access_token) {
          headers("Authorization": "Bearer #{access_token}")
        }
      }
    },

  object_definitions: {
    message: {
      fields: ->() {
        [
          { name: "id" },
          { name: "roomId" },
          { name: "personId" },
          { name: "personEmail" },
          { name: "created", type: :timestamp }
        ]
      }
    },

    message_detail: {
      fields: ->() {
        [
          { name: "id", optional: false },
          { name: "personId", hint: "The ID of the recipient when sending a private 1 to 1 message" },
          { name: "personEmail", hint: "The email address of the recipient when sendinga private 1:1 message" },
          { name: "roomId", control_type: "select", pick_list: "rooms" },
          { name: "text" },
          { name: "toPersonId" },
          { name: "toPersonEmail" },
          { name: "created", type: :timestamp }
        ]
      }
    },

    room: {
      fields: ->() {
        [
          { name: "id", control_type: 'select', pick_list: 'rooms', label: 'Room', optional: false },
          { name: "title" },
          { name: "type" },
          { name: "isLocked" },
          { name: "lastActivity", type: :timestamp },
          { name: "created", type: :timestamp }
        ]
      }
    },

    person: {
      fields: ->() {
        [
          { name: "id", label: "Person ID", optional: false },
          { name: "displayName" }
        ]
      }
    }
  },

  actions: {
    get_message_details: {
      input_fields: ->(object_definitions) {
        object_definitions['message_detail'].only('id')
      },

      execute: ->(connection,input) {
        get("https://api.ciscospark.com/v1/messages/" + input['id'])
      },

      output_fields: ->(object_definitions) {
        object_definitions['message_detail']
      }
    },

    get_room_details: {
      input_fields: ->(object_definitions) {
        object_definitions['room'].only('id')
      },

      execute: ->(connection,input) {
        get("https://api.ciscospark.com/v1/rooms/" + input['id'])
      },

      output_fields: ->(object_definitions) {
        object_definitions['room']
      }
    },

    get_person_details: {
      input_fields: ->(object_definitions) {
        object_definitions['person'].only('id')
      },

      execute: ->(connection,input) {
        get("https://api.ciscospark.com/v1/people/" + input['id'])
      },

      output_fields: ->(object_definitions) {
        object_definitions['person']
      }
    },

    post_message: {
      input_fields: ->(object_definitions) {
        object_definitions['message_detail'].only('roomId', 'text', 'toPersonEmail', 'toPersonId')
      },

      execute: ->(connection,input) {
        post("https://api.ciscospark.com/v1/messages", input)
      },

      output_fields: ->(object_definitions) {
        object_definitions['message_detail']
      }
    }
  },

  triggers: {
    new_message: {
      type: "paging_desc",

      input_fields: ->(object_definitions) {
        object_definitions['room'].only('id')
      },

      webhook_subscribe: ->(webhook_url, connection, input, flow_id) {
        post('https://api.ciscospark.com/v1/webhooks',
             name: "Workato recipe #{flow_id}",
             targetUrl: webhook_url,
             resource: 'messages',
             event: 'created',
             filter: "roomId=#{input['id']}")
      },

      webhook_notification: ->(input, payload) {
        payload['data']
      },

      webhook_unsubscribe: ->(webhook) {
        delete("https://api.ciscospark.com/v1/webhooks/#{webhook['id']}")
      },

      dedup: ->(message) {
        message['id']
      },

      output_fields: ->(object_definitions) {
        object_definitions['message']
      }
    }
  },

  pick_lists: {
    rooms: ->(connection) {
      get("https://api.ciscospark.com/v1/rooms")['items'].map { |r| [r['title'], r['id']] }
    }
  },
}
