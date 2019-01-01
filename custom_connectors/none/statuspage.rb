# frozen_string_literal: true

{
  title: 'Statuspage',

  connection: {
    fields: [
      {
        name: 'status_page_url',
        label: 'Statuspage URL',
        optional: false,
        hint: 'For example: <b>https://status.workato.com/</b>'
      }
    ],

    base_uri: lambda { |connection|
      connection['status_page_url']
    },

    authorization: {
      type: 'no_auth'
    }
  },

  object_definitions: {
    incident_update: {
      fields: lambda do |_connection, _config_fields|
        [
          {
            control_type: 'text',
            label: 'Status',
            type: 'string',
            name: 'status'
          },
          {
            control_type: 'text',
            label: 'Body',
            type: 'string',
            name: 'body'
          },
          {
            control_type: 'text',
            label: 'Created at',
            type: 'date_time',
            name: 'created_at'
          },
          {
            control_type: 'text',
            label: 'Wants twitter update',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Wants twitter update',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'wants_twitter_update'
            },
            type: 'boolean',
            name: 'wants_twitter_update'
          },
          {
            control_type: 'text',
            label: 'Twitter updated at',
            type: 'date_time',
            name: 'twitter_updated_at'
          },
          {
            control_type: 'text',
            label: 'Updated at',
            type: 'date_time',
            name: 'updated_at'
          },
          {
            control_type: 'text',
            label: 'Display at',
            type: 'date_time',
            name: 'display_at'
          },
          {
            control_type: 'text',
            label: 'Affected components',
            type: 'string',
            name: 'affected_components'
          },
          {
            control_type: 'text',
            label: 'Custom tweet',
            type: 'string',
            name: 'custom_tweet'
          },
          {
            control_type: 'text',
            label: 'Deliver notifications',
            toggle_hint: 'Select from option list',
            toggle_field: {
              label: 'Deliver notifications',
              control_type: 'text',
              toggle_hint: 'Use custom value',
              type: 'boolean',
              name: 'deliver_notifications'
            },
            type: 'boolean',
            name: 'deliver_notifications'
          },
          {
            control_type: 'text',
            label: 'Tweet ID',
            type: 'string',
            name: 'tweet_id'
          },
          {
            control_type: 'text',
            label: 'ID',
            type: 'string',
            name: 'id'
          },
          {
            control_type: 'text',
            label: 'Incident ID',
            type: 'string',
            name: 'incident_id'
          }
        ]
      end
    }
  },

  test: lambda do |_connection|
    get('history.json')
  end,

  actions: {
    list_incident_updates: {
      description: "List <span class='provider'>incedent updates</span> " \
        "in <span class='provider'>Statuspage</span>",

      execute: lambda do |_connection, _input|
        incedents = get('history.json')['months']&.pluck('incidents')
        incedent_codes = []
        incedents.select { |incedent| incedent&.pluck('code').present? }
                 .each do |incedent|
          incedent_codes.concat(incedent&.pluck('code').presence)
        end
        incident_updates = []
        incedent_codes.each do |incedent|
          incident_updates.concat(get("incidents/#{incedent}.json")
                                    .[]('incident_updates'))
        end

        { incident_updates: incident_updates }
      end,

      output_fields: lambda do |object_definitions|
        [{
          name: 'incident_updates',
          type: 'array',
          of: 'object',
          properties: object_definitions['incident_update']
        }]
      end,

      sample_output: lambda do |_connection, _input|
        incedent_code = get('history.json')['months']
                        &.pluck('incidents')
                        &.select { |incedent| incedent&.pluck('code').present? }
                        &.[](0)&.pluck('code')&.[](0).presence

        incident_updates = if incedent_code
                             get("incidents/#{incedent_code}.json")
                               .[]('incident_updates')
                           end || []

        { incident_updates: incident_updates }
      end
    }
  },

  triggers: {
    new_updated_incident_update: {
      title: 'New/updated incident update',
      description: "New or updated <span class='provider'>incident update" \
        "</span> in <span class='provider'>Statuspage</span>",
      type: 'paging_desc',

      poll: lambda do |_connection, _input, _last_updated_since|
        incedents = get('history.json')['months']&.pluck('incidents')
        incedent_codes = []
        incedents.select { |incedent| incedent&.pluck('code').present? }
                 .each do |incedent|
          incedent_codes.concat(incedent&.pluck('code').presence)
        end
        incident_updates = []
        incedent_codes.each do |incedent|
          incident_updates.concat(get("incidents/#{incedent}.json")
                                    .[]('incident_updates'))
        end

        { events: incident_updates, next_page: nil }
      end,

      document_id: ->(incident_update) { incident_update['id'] },

      sort_by: ->(incident_update) { incident_update['updated_at'] },

      output_fields: lambda do |object_definitions|
        object_definitions['incident_update']
      end,

      sample_output: lambda do |_connection, _input|
        incedent_code = get('history.json')['months']
                        &.pluck('incidents')
                        &.select { |incedent| incedent&.pluck('code').present? }
                        &.[](0)&.pluck('code')&.[](0).presence

        incident_updates = if incedent_code
                             get("incidents/#{incedent_code}.json")
                               .[]('incident_updates')
                           end || []

        { incident_updates: incident_updates }
      end
    }
  }
}
