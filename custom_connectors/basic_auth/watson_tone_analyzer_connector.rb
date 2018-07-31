{
  title: 'Watson Tone Analyzer',

  connection: {
    fields: [
      {
        name: 'username', optional: true,
        hint: 'Your username; leave empty if using API key below'
      },
      {
        name: 'password', control_type: 'password',
        label: 'Password or personal API key'
      }
    ],

    authorization: {
      type: 'basic_auth',

      credentials: ->(connection) {
        user(connection['username'])
        password(connection['password'])
      }
    }
  },
  
  test: ->(connection) {
    post("https://gateway.watsonplatform.net/tone-analyzer-beta/api/v3/tone?version=2016-02-11").
      payload(text: "this is it")
  },

  object_definitions: {
    tone: {
      fields: ->(connection) {
        [
          { name: 'score', type: :decimal },
          { name: 'tone_id' },
          { name: 'tone_name' }
        ]
      }
    }
  },

  actions: {
    analyze_content: {
      input_fields: ->(object_definitions) {
        [
          { name: 'text', optional: false }
        ]
      },

      execute: ->(connection, input) {
        response = post("https://gateway.watsonplatform.net/tone-analyzer-beta/api/v3/tone?version=2016-02-11").
                     payload(text: input['text'])['document_tone']
        
        tones = {}
        response['tone_categories'].each do |cat|
          if ["emotion_tone", "writing_tone", "social_tone"].include?(cat['category_id'])
            tones[cat['category_id']] = cat
          end
        end

        if tones['emotion_tone'].present? && tones['emotion_tone']['tones'].present?
          dominant_emotion_tone = tones['emotion_tone']['tones'].
            sort { |a,b| b['score'] <=> a['score'] }.
            first
        end

        if tones['writing_tone'].present? && tones['writing_tone']['tones'].present?
          dominant_writing_tone = tones['writing_tone']['tones'].
            sort { |a,b| b['score'] <=> a['score'] }.
            first
        end

        if tones['social_tone'].present? && tones['social_tone']['tones'].present?
          dominant_social_tone = tones['social_tone']['tones'].
            sort { |a,b| b['score'] <=> a['score'] }.
            first
        end

        {
          'dominant_emotion_tone': dominant_emotion_tone,
          'emotion_tones': tones['emotion_tone'],
          'dominant_writing_tone': dominant_writing_tone,
          'writing_tones': tones['writing_tone'],
          'dominant_social_tone': dominant_social_tone,
          'social_tones': tones['social_tone'],
        }
      },

      output_fields: ->(object_definitions) {
        [
          {
            name: 'dominant_emotion_tone', type: :object,
            properties: object_definitions['tone']
          },
          {
            name: 'emotion_tones', type: :array,
            of: :object, properties: object_definitions['tone']
          },
          {
            name: 'dominant_writing_tone', type: :object,
            properties: object_definitions['tone']
          },
          {
            name: 'writing_tones', type: :array,
            of: :object, properties: object_definitions['tone']
          },
          {
            name: 'dominant_social_tone', type: :object,
            properties: object_definitions['tone'] },
          {
            name: 'social_tones', type: :array,
            of: :object, properties: object_definitions['tone']
          }
        ]
      }
    }
  }
}
