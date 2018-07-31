{
  title: 'Clearbit',

  connection: {
    fields: [
      {
        name: 'api_key',
        control_type: 'password',
        hint: 'Can be found here: https://dashboard.clearbit.com/keys'
      }
    ],

    authorization: {
      type: 'basic_auth',
      
      # clearbit uses api key only for authentication. treats api key as username and password left blank
      # curl -u "{your api_key}:" "https://person.clearbit.com/v1/people/email/eeshansim@gmail.com"
      credentials: ->(connection) {
        user(connection['api_key'])
        password("")
      }
    }
  },
  
  test: ->(connection) {
    get("https://person.clearbit.com/v1/people/email/eeshansim@gmail.com")
  },

  object_definitions: {
    person: {
      fields: ->() {
        [
          { name: 'id' },
          { name: 'name', type: :object, properties: [
            { name: 'fullName' },
            { name: 'givenName' },
            { name: 'familyName' }
          ]},
          { name: 'email' },
          { name: 'gender' },
          { name: 'timeZone' },
          { name: 'avatar' },
          { name: 'geo', type: :object, properties: [
            { name: 'city' },
            { name: 'stateCode' },
            { name: 'countryCode' }
          ]},
          { name: 'bio' },
          { name: 'fuzzy', type: :boolean },
          { name: 'site' },
          { name: 'employment', type: :object, properties: [
            { name: 'domain' },
            { name: 'name' },
            { name: 'title' },
            { name: 'role' },
            { name: 'seniority' }
          ]},
          { name: 'facebook', type: :object, properties: [
            { name: 'handle' }
          ]},
          { name: 'linkedin', type: :object, properties: [
            { name: 'handle' }
          ]},
          { name: 'googleplus', type: :object, properties: [
            { name: 'handle' }
          ]},
          { name: 'twitter', type: :object, properties: [
            { name: 'handle' },
            { name: 'id' },
            { name: 'bio' },
            { name: 'followers', type: :integer },
            { name: 'following', type: :integer },
            { name: 'site' }
          ]},
          { name: 'github', type: :object, properties: [
            { name: 'handle' },
            { name: 'company' },
            { name: 'blog' },
            { name: 'followers', type: :integer },
            { name: 'following', type: :integer }
          ]},
          { name: 'angellist', type: :object, properties: [
            { name: 'handle' },
            { name: 'bio' },
            { name: 'blog' },
            { name: 'site' },
            { name: 'followers', type: :integer }
          ]},
          { name: 'aboutme', type: :object, properties: [
            { name: 'handle' },
            { name: 'bio' }
          ]},
          { name: 'gravatar', type: :object, properties: [
            { name: 'handle' },
            { name: 'urls', type: :object, properties: [
              { name: 'value', type: :url },
              { name: 'title' }
            ]}
          ]}
        ]
      }
    },
    company: {
      fields: ->() {
        [
          { name: 'id' },
          { name: 'name' },
          { name: 'legalName' },
          { name: 'domain' },
          { name: 'site', type: :object, properties: [
            { name: 'url' },
            { name: 'title' },
            { name: 'metaDescription' },
            { name: 'metaAuthor' },
          ]},
          { name: 'location' },
          { name: 'geo', type: :object, properties: [
            { name: 'streetNumber' },
            { name: 'streetName' },
            { name: 'subPremise' },
            { name: 'city' },
            { name: 'state' },
            { name: 'stateCode' },
            { name: 'postalCode' },
            { name: 'country' },
            { name: 'countryCode' }
          ]},
          { name: 'timeZone' },
          { name: 'description' },
          { name: 'foundedDate', type: :date },
          { name: 'metrics', type: :object, properties: [
            { name: 'raised', type: :integer },
            { name: 'employees', type: :integer },
            { name: 'googleRank' },
            { name: 'annualRevenue', type: :integer }
          ]},
          { name: 'logo' },
          { name: 'facebook', type: :object, properties: [
            { name: 'handle' }
          ]},
          { name: 'linkedin', type: :object, properties: [
            { name: 'handle' }
          ]},
          { name: 'twitter', type: :object, properties: [
            { name: 'handle' },
            { name: 'id' },
            { name: 'bio' },
            { name: 'followers', type: :integer },
            { name: 'following', type: :integer },
            { name: 'site' }
          ]},
          { name: 'angellist', type: :object, properties: [
            { name: 'id' },
            { name: 'handle' },
            { name: 'description' },
            { name: 'blogUrl' },
            { name: 'followers', type: :integer },
          ]},
          { name: 'crunchbase', type: :object, properties: [
            { name: 'handle' },
          ]},
          { name: 'phone' },
          { name: 'emailProvider', type: :boolean },
        ]
      }
    }
  },

  actions: {
    
    email_lookup: {
      input_fields: ->() {
        [
          { name: 'email', optional: false }  
        ]  
      },
      execute: ->(connection, input) {
        get("https://person.clearbit.com/v2/combined/find?email=#{input['email']}")
      },
      output_fields: ->(object_definitions) {
        [
         { name: 'person', type: :object, properties: object_definitions['person'] },
         { name: 'company', type: :object, properties: object_definitions['company'] }
        ]
      }
    },

    company_lookup: {
      input_fields: ->() {
        [
          { name: 'company_name', optional: false }
        ]
      },      
      execute: ->(connection, input) {
        query = "?page_size=1&limit=1&query=name:#{input['company_name']}"
        { 
          'companies': get("https://company.clearbit.com/v1/companies/search" + query)['results']
        }
      },
      output_fields: ->(object_definitions) {
        [
         { name: 'companies', type: :array, of: :object, properties: object_definitions['company'] }
        ]
      }
    }
  },

  triggers: {}
}
