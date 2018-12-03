{
  title: 'Hubspot (Custom)',

    connection: {
      fields: [
        {
          name: "client_id",
          optional: false
        },
        {
          name: "client_secret",
          optional: false,
          control_type: "password",
        }
      ],       

      authorization: {
        type: 'oauth2',

        authorization_url: lambda do |connection|
         "https://app.hubspot.com/oauth/authorize?client_id=#{connection["client_id"]}&response_type=code&scope=contacts&redirect_uri=https://www.workato.com/oauth/callback"
        end,

        acquire: lambda do |connection, auth_code, redirect_uri|
        response = post("https://api.hubapi.com/oauth/v1/token").
                     payload(client_id: connection["client_id"],
                             client_secret: connection["client_secret"],
                             grant_type: 'authorization_code',
                             code: auth_code,
                             redirect_uri: redirect_uri).
                     request_format_www_form_urlencoded
        [
          {
            access_token: response['access_token'],
            refresh_token: response['refresh_token']
          },
          nil,
          nil
        ]
        end,

        refresh: lambda do |connection, refresh_token|
          post("https://api.hubapi.com/oauth/v1/token").
            payload(client_id: connection["client_id"],
                    client_secret: connection["client_secret"],
                    grant_type: 'refresh_token',
                    refresh_token: refresh_token).
            request_format_www_form_urlencoded
        end,
        
        refresh_on: [401],

        apply: lambda do |connection, access_token|
          headers(Authorization: "Bearer #{access_token}")
        end        
      }
    },

  object_definitions: {

    contact: {
      fields: ->() {
        [
          {
            "control_type": "number",
            "label": "Added at",
            "parse_output": "float_conversion",
            "type": "number",
            "name": "addedAt"
          },
          {
            "control_type": "number",
            "label": "Vid",
            "parse_output": "float_conversion",
            "type": "number",
            "name": "vid"
          },
          {
            "control_type": "number",
            "label": "Canonical vid",
            "parse_output": "float_conversion",
            "type": "number",
            "name": "canonical_vid"
          },
          {
            "control_type": "number",
            "label": "Portal ID",
            "parse_output": "float_conversion",
            "type": "number",
            "name": "portal_id"
          },
          {
            "control_type": "text",
            "label": "Is contact",
            "render_input": {},
            "parse_output": {},
            "toggle_hint": "Select from option list",
            "toggle_field": {
              "label": "Is contact",
              "control_type": "text",
              "toggle_hint": "Use custom value",
              "type": "boolean",
              "name": "is_contact"
            },
            "type": "boolean",
            "name": "is_contact"
          },
          {
            "control_type": "text",
            "label": "Profile token",
            "type": "string",
            "name": "profile_token"
          },
          {
            "control_type": "text",
            "label": "Profile URL",
            "type": "string",
            "name": "profile_url"
          },
          {
            "properties": [
              {
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Value",
                    "type": "string",
                    "name": "value"
                  }
                ],
                "label": "Firstname",
                "type": "object",
                "name": "firstname"
              },
              {
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Value",
                    "type": "string",
                    "name": "value"
                  }
                ],
                "label": "Lastmodifieddate",
                "type": "object",
                "name": "lastmodifieddate"
              },
              {
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Value",
                    "type": "string",
                    "name": "value"
                  }
                ],
                "label": "Company",
                "type": "object",
                "name": "company"
              },
              {
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Value",
                    "type": "string",
                    "name": "value"
                  }
                ],
                "label": "Lastname",
                "type": "object",
                "name": "lastname"
              }
            ],
            "label": "Properties",
            "type": "object",
            "name": "properties"
          },
          {
            "name": "identity_profiles",
            "type": "array",
            "of": "object",
            "label": "Identity profiles",
            "properties": [
              {
                "control_type": "number",
                "label": "Vid",
                "parse_output": "float_conversion",
                "type": "number",
                "name": "vid"
              },
              {
                "control_type": "number",
                "label": "Saved-at-timestamp",
                "parse_output": "float_conversion",
                "type": "number",
                "name": "saved-at-timestamp"
              },
              {
                "control_type": "number",
                "label": "Deleted-changed-timestamp",
                "parse_output": "float_conversion",
                "type": "number",
                "name": "deleted-changed-timestamp"
              },
              {
                "name": "identities",
                "type": "array",
                "of": "object",
                "label": "Identities",
                "properties": [
                  {
                    "control_type": "text",
                    "label": "Type",
                    "type": "string",
                    "name": "type"
                  },
                  {
                    "control_type": "text",
                    "label": "Value",
                    "type": "string",
                    "name": "value"
                  },
                  {
                    "control_type": "number",
                    "label": "Timestamp",
                    "parse_output": "float_conversion",
                    "type": "number",
                    "name": "timestamp"
                  },
                  {
                    "control_type": "text",
                    "label": "Is-primary",
                    "render_input": {},
                    "parse_output": {},
                    "toggle_hint": "Select from option list",
                    "toggle_field": {
                      "label": "Is-primary",
                      "control_type": "text",
                      "toggle_hint": "Use custom value",
                      "type": "boolean",
                      "name": "is-primary"
                    },
                    "type": "boolean",
                    "name": "is-primary"
                  }
                ]
              }
            ]
          }
        ]
      }
    },

  },

  test: ->(connection) {
    get("https://api.hubapi.com/contacts/v1/lists/all/contacts/all")
  },

  actions: {

#     test:{
        
#         execute: lambda do |connection, input|
# 			get("https://api.hubapi.com/contacts/v1/contact/vid/1/profile")
#         end,
      
#         output_fields: lambda do |object_definitions|

#         end
#     },

  },

  triggers: {

    new_or_updated_contact: {
      type: :paging_desc,

      input_fields: lambda do
        [
        	{
            	name: "since",
              	type: "date_time",
              	optional: false
            }  
        ]
      end,

      poll: lambda do |connection, input, page|
        page_size = 100
        if page.present?
          vidOffset = page.split("_").first
		  timeOffset = page.split("_").last
        else
          vidOffset = nil
          timeOffset = nil
        end
        
        params = {
        	  count: page_size,
              timeOffset: timeOffset,
              offset: vidOffset
        }.reject {|k, v|  v.present? == false}

                
        response = get("https://api.hubapi.com/contacts/v1/lists/recently_updated/contacts/recent").
                     params(params)
        
        results = response["contacts"]
        
        contacts = []
        
        results.map {|result|
          	contact = {}
        	result.each {|k, v|
				k = k.gsub("-", "_")
#               	if k == "addedAt"
#                 	v = (v/1000.seconds + "1970-01-01T00:00:00Z".to_time.to_i).to_time + ((v % 1000).to_f/1000.0).seconds #convert epoch
#                 end
                contact[k] = v
            }

          	if contact["addedAt"]/1000 >= input["since"].to_i
            	contacts << contact
            end	
        }
        
		
        next_vidOffset = response["vid-offset"].to_s
        next_timeOffset = response["time-offset"].to_s
        
        if response["has-more"] == false || contacts.size == 0
          next_page = nil
        else
          next_page = next_vidOffset + "_" + next_timeOffset
        end
        {
          events: contacts,
          next_page: next_page
        }
      end,

      document_id: lambda do |response|
        response['vid'] + response['addedAt']
      end,

      sort_by: lambda do |response|
        response['addedAt']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['contact']
      end
  },
  }
}
