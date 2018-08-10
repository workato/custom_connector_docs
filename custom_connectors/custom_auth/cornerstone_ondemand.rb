{
  title: "Cornerstone OnDemand",

  connection: {
    fields: [
      {
        name: "corp_name",
        optional: false
      },
      {
        name: "api_key",
        optional: false
      },
      {
        name: "api_secret",
        optional: false,
        control_type: "password"
      },
      {
        name: "user_name",
        optional: false
      },
      {
        name: "alias",
        optional: false
      }
    ],

    # We use a custom authorization scheme:
    # https://docs.workato.com/developing-connectors/sdk/authentication/custom-authentication.html
    authorization: {
      # How to acquire the token:
      # https://docs.workato.com/developing-connectors/sdk/authentication/custom-authentication.html#acquire
      acquire: lambda do |connection|
        # calculate signature
        timestamp = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%3N")
        msg = [
          "POST",
          "x-csod-api-key:#{connection['api_key']}",
          "x-csod-date:#{timestamp}",
          "/services/api/sts/session"
        ].join("\n")
        signature = msg.hmac_sha512(connection["api_secret"].decode_base64).encode_base64

        reply = post("https://#{connection['corp_name']}.csod.com/services/api/sts/session").
                  params(
                    "userName": connection["user_name"],
                    "alias": connection["alias"]
                  ).
                  headers(
                    "x-csod-api-key": connection["api_key"],
                    "x-csod-date": timestamp,
                    "x-csod-signature": signature
                  )
        {
          "session_token": reply.dig("cornerstoneApi", "data", "Session", "Token"),
          "session_secret": reply.dig("cornerstoneApi", "data", "Session", "Secret")
        }
      end,

      # How to know when to re-acquire the token.  Short-hand version of:
      # https://docs.workato.com/developing-connectors/sdk/authentication/custom-authentication.html#refreshon
      refresh_on: 401,

      # How to apply authorization to regular requests:
      # https://docs.workato.com/developing-connectors/sdk/authentication/custom-authentication.html#apply
      apply: lambda do |connection|
        return if connection["session_token"].blank? || connection["session_secret"].blank?

        # calculate the signature
        path = current_url.gsub("https://#{connection['corp_name']}.csod.com", "").gsub(/\?.*$/, "")
        timestamp = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%3N")
        msg = [
          current_verb.to_s.upcase,
          "x-csod-date:#{timestamp}",
          "x-csod-session-token:#{connection['session_token']}",
          path
        ].join("\n")
        signature = msg.hmac_sha512(connection["session_secret"].decode_base64).encode_base64

        # now update the headers
        headers(
          "x-csod-date": timestamp,
          "x-csod-session-token": connection["session_token"],
          "x-csod-signature": signature
        )
      end
    }
  },

  test: lambda do |connection|
    get("https://#{connection['corp_name']}.csod.com//services/api/OrgUnits/OU")
  end,

  actions: {
    get_ous: {
      execute: lambda do |connection, _input|
        get("https://#{connection['corp_name']}.csod.com//services/api/OrgUnits/OU")
      end
    }
  }
}
