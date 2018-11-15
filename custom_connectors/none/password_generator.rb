{
  title: 'Password Generator',

  connection: {
    authorization: {},
  },
  object_definitions: {},

  test: ->(connection) {
    true
  },
  actions: {
    generate_password: {
      execute: ->() {
        letters_list = [
          ('!'..'/').to_a + (':'..'@').to_a + ('['..'`').to_a + ('{'..'~').to_a,
          ('0'..'9').to_a,
          ('A'..'Z').to_a,
          ('a'..'z').to_a
        ].sort_by { |n| rand(4) }

        password_size = 8
        req_chars_size = letters_list.size
        other_chars_size = password_size - req_chars_size
        index_list =
          (0...req_chars_size).to_a.sort_by { rand(req_chars_size) } +
           (0...other_chars_size).to_a.map { rand(other_chars_size) }

        password = (0...password_size).to_a.map do |n|
          letters = letters_list[index_list[n]]
          letters[rand(letters.size)]
        end.join
        {
          password: password
        }
      },
      output_fields: ->() {
        [
          { name: 'password' }
        ]
      },
      sample_output: ->() {
        { password: 'P@s19ser' }
      }
    }
  }
}
