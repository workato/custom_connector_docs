{
  title: 'Gender',

  connection: {

    fields: [
      {
        name: 'key',
        hint: 'Your Gender API Private Server Key',
        optional: false
      },
    ],

    authorization: {
      type: 'api_key',

      credentials: ->(connection) {
        params(key: connection['key'])
      }
    }
  },
  
  test: ->(connection) {
    get("https://gender-api.com/get?name=matthew")
  },

  object_definitions: {

    person: {
      fields: ->() {
        [
          { name: 'name' },
          { name: 'gender' },
          { name: 'samples', type: :integer },
          { name: 'accuracy', type: :integer }
        ]
      }
    }
  },

  actions: {

    get_gender: {
      
      input_fields: ->(object_definitions) {
        [
          { name: 'name', optional: false},
          { name: 'country', hint: '2 Letter country code. Click <a href="https://gender-api.com/en/api-docs">here</a> for list.' }
        ]
      },

      execute: ->(connection, input) {
        {
          person: get("https://gender-api.com/get", input)
        }
      },

      output_fields: ->(object_definitions) {
        [
          { name: "person", type: :object,
            properties: object_definitions['person']}
        ]
      }
    }
  }
}
