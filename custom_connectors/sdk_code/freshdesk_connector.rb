{
  title: 'Freshdesk',

  # HTTP basic auth example.
  connection: {
    fields: [
      {
        name: 'helpdesk',
        control_type: 'subdomain',
        url: '.freshdesk.com',
        hint: 'Your helpdesk name as found in your Freshdesk URL'
      },
      {
        name: 'username',
        optional: true,
        hint: 'Your username; leave empty if using API key below'
      },
      {
        name: 'password',
        control_type: 'password',
        label: 'Password or personal API key'
      }
    ],

    authorization: {
      type: 'basic_auth',

      # Basic auth credentials are just the username and password; framework handles adding
      # them to the HTTP requests.
      credentials: ->(connection) {
        # Freshdesk-specific quirk: If only using API key to authenticate, API expects it as username,
        # but we prefer to store it in 'password' to keep it obscured (control_type: 'password' above).
        if connection['username'].blank?
          user(connection['password'])
        else
          user(connection['username'])
          password(connection['password'])
        end
      }
    }
  },

  object_definitions: {

    user: {

      # Provide a preview user to display in the recipe data tree.
      preview: ->(connection) {
        get("https://#{connection['helpdesk']}.freshdesk.com/api/users.json?page_size=1&wf_order=created_at&wf_order_type=desc")['results'].first
      },

      fields: ->() {
        [
          {
            name: 'id',
            type: :integer
          },
          {
            name: 'name',
          },
          {
            name: 'email'
            # type defaults to string
          },
          {
            name: 'created_at',
            type: :timestamp
          }
        ]
      },
    },

    ticket: {

      fields: ->() {
        [
          {
            name: 'id',
            type: :integer
          },
          {
            name: 'email',
            control_type: 'email'
          },
          {
            name: 'subject'
          },
          {
            name: 'description'
          }
        ]
      }
    }
  },

  test: ->(connection) {
    get("https://#{connection['helpdesk']}.freshdesk.com/agents.json")
  },

  actions: {
    create_user: {
      input_fields: ->(object_definitions) {
        object_definitions['user'].ignored('id', 'created_at').required('email')
      },

      execute: ->(connection, input) {
        # Freshdesk API uses a 'user' envelope around this endpoint's input,
        # and responds in a similar envelope.
        post("https://#{connection['helpdesk']}.freshdesk.com/contacts.json", { user: input } )['user']
      },

      # Output schema.  Same as input above.
      output_fields: ->(object_definitions) {
        # API endpoint just returns the whole object, so we don't need to adapt the object
        # fields definition any further here.
        object_definitions['user']
      }
    },

    search_users: {
      input_fields: ->(object_definitions) {
        # Assuming here that the API only allows searching by these terms.
        object_definitions['user'].only('id', 'email')
      },

      execute: ->(connection, input) {
        {
          'users': get("https://#{connection['helpdesk']}.freshdesk.com/api/users.json", input)['results']
        }
      },

      output_fields: ->(object_definitions) {
        [
          {
            name: 'users',
            type: :array,
            of: :object,
            properties: object_definitions['user']
          }
        ]
      }
    }
  },

  triggers: {

    new_ticket: {

      input_fields: ->() {
        [
          {
            name: 'since',
            type: :timestamp,
            hint: 'Defaults to tickets created after the recipe is first started'
          }
        ]
      },

      poll: ->(connection, input, last_updated_since) {
        updated_since = last_updated_since || input['since'] || Time.now

        tickets = get("https://#{connection['helpdesk']}.freshdesk.com/api/v2/tickets.json").
                  params(order_by: 'updated_at', # Because we can only query by updated_since in this API.
                         order_type: 'asc', # We expect events in ascending order.
                         per_page: 2, # Small page size to help with testing.
                         updated_since: updated_since.to_time.utc.iso8601)

        next_updated_since = tickets.last['updated_at'] unless tickets.blank?

        # Return three items:
        # - The polled objects/events (default: empty/nil if nothing found)
        # - Any data needed for the next poll (default: nil, uses one from previous poll if available)
        # - Flag on whether more objects/events may be immediately available (default: false)
        {
          events: tickets,
          next_poll: next_updated_since,
          # common heuristic when no explicit next_page available in response: full page means maybe more.
          can_poll_more: tickets.length >= 2
        }
      },

      dedup: ->(ticket) {
        ticket['id']
      },

      output_fields: ->(object_definitions) {
        object_definitions['ticket']
      }
    }
  }
}
