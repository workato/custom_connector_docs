{
  title: 'Accelo',

  connection: {
    fields: [
      {
        name: 'deployment',
        control_type: 'subdomain',
        url: '.accelo.com',
        optional: false
      }
    ],
    authorization: {
      type: 'oauth2',

      authorization_url: ->(connection) {
        "https://#{connection['deployment']}.api.accelo.com/oauth2/v0/authorize?response_type=code"
      },

      token_url: ->(connection) {
        "https://#{connection['deployment']}.api.accelo.com/oauth2/v0/token"
      },

      client_id: 'ababababab',

      client_secret: 'cdcdcdcdcd',

      credentials: ->(connection, access_token) {
        headers('Authorization': "Bearer #{access_token}")
      }
    }
  },

  object_definitions: {
    company: {
      fields: ->() {
        [
          { name: 'id', type: :integer },
          { name: 'name' },
          { name: 'website' },
          { name: 'standing' },
          { name: 'status' },
          { name: 'phone' },
          { name: 'fax' },
          { name: 'date_created', type: :integer },
          { name: 'date_modified', type: :integer },
          { name: 'comments' }
        ]
      },
    }
  },

  actions: {
    search_company: {
      input_fields: ->(object_definitions) {
        [
          { name: 'company_name' }
        ]
      },

      execute: ->(connection, input) {
        {
          'companies': get("https://#{connection['deployment']}.api.accelo.com/api/v0/companies.json").
                       params(_search: input['company_name'])['response']
        }
      },

      output_fields: ->(object_definitions) {
        [
          {
            name: 'companies',
            type: :array, of: :object,
            properties: object_definitions['company']
          }
        ]
      }
    }
  },

  triggers: {
    new_company: {

      type: :paging_desc,

      input_fields: ->() {
        [
          { name: 'created_after', type: :timestamp, optional: false }
        ]
      },
      poll: ->(connection, input, last_created_since) {
        created_since = (last_created_since || input['created_after'] || Time.now).to_i

        companies = get("https://#{connection['deployment']}.api.accelo.com/api/v0/companies.json").
                   params(_filters: "date_created_after(#{created_since})",
                          _limit: 2,
                          _fields: 'date_created,website,status,phone,fax')['response']

        next_created_since = companies.last['date_created'] unless companies.blank?

        {
          events: companies,
          next_page: next_created_since
        }
      },

      dedup: ->(company) {
        company['id']
      },

      output_fields: ->(object_definitions) {
        object_definitions['company']
      }
    }
  }
}
