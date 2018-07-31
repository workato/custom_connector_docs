{
    title: 'Infobip',
    connection: {
        fields: [
            {
                name: 'api_key',
                control_type: 'password',
                optional: false
            }
        ],
        authorization: {
            type: 'custom_auth',
            credentials: ->(connection) {
              headers(:Authorization => "App #{connection['api_key']}",
                      :'User-Agent' => 'Workato')
            }
        }
    },
    test: ->(connection) {
      get('https://api.infobip.com/sms/1/logs').params(limit: 1)
    },
    object_definitions: {
        send_sms_request: {
            fields: ->() {
              [
                  {name: 'from'},
                  {name: 'to', optional: false, control_type: 'phone'},
                  {name: 'text'}
              ]
            }
        },
        sent_sms_info: {
            fields: ->() {
              [
                  {name: 'to'},
                  {name: 'status', type: :object, properties: [
                      {name: 'groupId', type: :integer},
                      {name: 'groupName'},
                      {name: 'id', type: :integer},
                      {name: 'name'},
                      {name: 'description'}
                  ]},
                  {name: 'smsCount', type: :integer},
                  {name: 'messageId'}
              ]
            }
        },
        received_sms_info: {
            fields: ->() {
              [
                  {name: 'messageId'},
                  {name: 'from'},
                  {name: 'to'},
                  {name: 'text'},
                  {name: 'cleanText'},
                  {name: 'keyword'},
                  {name: 'smsCount', type: :integer},
                  {name: 'receivedAt'}
              ]
            }
        }
    },
    actions: {
        send_sms: {
            input_fields: ->(object_definitions) {
              object_definitions['send_sms_request']
            },
            execute: ->(connection, input) {
              post('https://api.infobip.com/sms/1/text/single', input)['send_sms_request']
            },
            output_fields: ->(object_definitions) {[
                { name: 'messages', type: :array, of: :object, properties: object_definitions['sent_sms_info'] }
            ]}
        }
    },
    triggers: {
        sms_received: {
            poll: ->(connection, input, last_received_at) {
              date_time_format = '%Y-%m-%dT%H:%M:%S.%L+00:00'
              received_since = last_received_at || (Time.now - 5 * 60).utc.strftime(date_time_format)
              query_param = received_since.gsub(':', '%3A').gsub('+', '%2B')

              received_messages = get("https://api.infobip.com/sms/1/inbox/logs?receivedSince=#{query_param}")

              received_sms_info = received_messages['results']
              last_received_at = received_sms_info.length == 0 ? received_since : received_sms_info[0]['receivedAt']
              {
                  events: received_sms_info.reverse,
                  can_poll_more: false,
                  next_poll: last_received_at[0, last_received_at.length-2] + ':' + last_received_at[last_received_at.length-2, 2]
              }
            },
            dedup: ->(received_sms_info) {
              received_sms_info['messageId']
            },
            output_fields: ->(object_definitions) {
                object_definitions['received_sms_info']
            }
        }
    }
}