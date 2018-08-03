{
  title: 'Close.io',

  connection: {
    fields: [
      {
        name: 'api_key',
        optional: false,
        hint: 'Profile (top right) > Settings > Your API Keys'
      }
    ],

    authorization: {
      type: 'basic_auth',
      
      # close.io uses api key only for authentication. treats apikey as username and password left blank
      # curl -u "{your api_key}:" "https://app.close.io/api/v1/me/"
      credentials: ->(connection) {
        user(connection['api_key'])
        password("")
      }
    }
  },

  object_definitions: {
    lead: {
      fields: ->() {
        [
          { name: 'name' },
          { name: 'display_name' },
          { name: 'id' },
          { name: 'status_id' },
          { name: 'date_updated' },
          { name: 'status_label' },
          { name: 'description' },
          { name: 'html_url' },
          { name: 'created_by' },
          { name: 'organization_id' },
          { name: 'url' },
          { name: 'updated_by' },
          { name: 'created_by_name' },
          { name: 'date_created' },
          { name: 'updated_by_name' }
        ]
      }
    }
  },

  test: ->(connection) {
    get("https://app.close.io/api/v1/me/")
  },

  actions: {
    
    get_lead_by_id: {
      input_fields: ->() {
        [
          { name: "lead_id", optional: false }
        ]
      },
      execute: ->(connection, input) {
        get("https://app.close.io/api/v1/lead/#{input['lead_id']}/")
      },
      output_fields: ->(object_definitions) {
        object_definitions['lead']
      }
    }
  },

  triggers: {

    new_or_updated_lead: {

      type: :paging_desc,

      input_fields: ->() {
        [
          { name: 'since', type: :timestamp,
            hint: 'Defaults to leads created after the recipe is first started' }
        ]
      },

      poll: ->(connection, input, last_updated_since) {
        since = last_updated_since || input['since'] || Time.now
        
        # Close.io currently does not support _order_by parameter for leads, defaults to order by date_update
        results = get("https://app.close.io/api/v1/lead/").
                  params(query: "updated > #{since.to_time.iso8601}",
                         _limit: 5)

        next_updated_since = results['data'].last['date_updated'] unless results['data'].length == 0

        {
          events: results['data'],
          next_page: next_updated_since,
        }
      },

      dedup: ->(lead) {
        lead['id']
      },

      output_fields: ->(object_definitions) {
        object_definitions['lead']
      }
    }
  }
}
