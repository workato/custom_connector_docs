{
  title: 'AMcards.com',
  connection: {
    authorization: {
      type: 'oauth2',

      authorization_url: ->() {
        'https://amcards.com/oauth2/authorize/?response_type=code&scope=read+write'
      },

      token_url: ->() {
        'https://amcards.com/oauth2/access_token/'
      },

      client_id: 'doesThisNeedToBeInRepo?',

      client_secret: 'doesThisNeedToBeInRepo?',

      credentials: ->(connection, access_token) {
        headers('Authorization': "Bearer #{access_token}")
      }
    }
  },

  object_definitions: {
    card: {
      fields: ->() {
        [
          {
            name: 'template_id',
            type: :integer,
            hint: "You must own the template or it must be public in order to use it.",
            control_type: 'select',
            pick_list: 'templates',
            optional: false,
          },
          {
            name: 'message',
            label: 'Message for inside of card',
            control_type: 'text-area',
            hint: "Maximum of 700 characters please! Message will be added to the inside right (vertical) or inside bottom (horizontal) panel of the card. It will be added to the card and not replace an existing message!",
          },
          {
            name: 'send_date',
            type: :date,
            hint: "The card will be scheduled to mail out the next business day if you leave this out.",
          },
          {
            name: 'initiator',
            hint: "This is something that will help you to track who or what triggered this card.",
            optional: false,
          },
          {
            name: 'first_name',
            label: "TO: First Name",
            optional: false,
          },
          {
            name: 'last_name',
            label: "TO: Last Name",
            optional: false,
          },
          {
            name: 'organization',
            hint: "Only use this if the mailing address is for this place. This will be included on envelope.",
            label: "TO: Organization Name",
          },
          {
            name: 'address_line_1',
            label: "TO: Address Line 1",
            optional: false,
          },
          {
            name: 'address_line_2',
            label: "TO: Address Line 2",
          },
          {
            name: 'city',
            label: "TO: City",
            optional: false,
          },
          {
            name: 'state',
            label: "TO: State",
            hint: "Try to use 2 character state codes! ('UT' is better than 'Utah')",
            optional: false,
          },
          {
            name: 'postal_code',
            label: "TO: Postal/Zip Code",
            optional: false,
          },
          {
            name: 'country',
            label: "TO: Country",
            hint: "Try to use 2 character country codes! ('US' is better than 'United States')",
          },
          {
            name: 'return_first_name',
            label: "FROM: First Name",
            optional: false,
          },
          {
            name: 'return_last_name',
            label: "FROM: Last Name",
            optional: false,
          },
          {
            name: 'return_address_line_1',
            label: "FROM: Address Line 1",
            optional: false,
          },
          {
            name: 'return_address_line_2',
            label: "FROM: Address Line 2",
          },
          {
            name: 'return_city',
            label: "FROM: City",
            optional: false,
          },
          {
            name: 'return_state',
            label: "FROM: State",
            hint: "Use 2 character state codes! ('UT' is better than 'Utah')",
            optional: false,
          },
          {
            name: 'return_postal_code',
            label: "FROM: Postal/Zip Code",
            optional: false,
          },
          {
            name: 'return_country',
            label: "FROM: Country",
            default: "US",
            hint: "Use 2 character country codes! ('US' is better than 'United States')",
          },
        ]
      },
    },
  },

  actions: {
    create_card: {
      input_fields: ->(object_definitions) {
        object_definitions['card']
      },

      execute: ->(connection, input) {
        post("https://amcards.com/cards/open-card-form-oa/", input)
      },

      output_fields: ->(object_definitions) {
        object_definitions['card']
      },
    },
  },

  triggers: {
    # None so far...
  },

  pick_lists: {
    templates: ->(connection){
      get("https://amcards.com/.api/v1/template/")['objects'].
      map { |template| [template['name'], template['id']] }
    }
  }
}
