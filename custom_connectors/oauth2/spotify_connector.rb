{
  title: "Spotify",

  connection: {
    fields: [
      { name: "client_id", control_type: "password", optional: false },
      { name: "client_secret", control_type: "password", optional: false }
    ],

    authorization: {
      type: "oauth2",

      authorization_url: lambda do |connection|
        params = {
          response_type: "code",
          client_id: connection["client_id"],
          redirect_uri: "https://www.workato.com/oauth/callback",
          scope: "user-read-playback-state user-modify-playback-state"
        }.to_param
        "https://accounts.spotify.com/authorize?" + params
      end,

      acquire: lambda do |connection, auth_code|
        response = post("https://accounts.spotify.com/api/token").
                     payload(
                       grant_type: "authorization_code",
                       code: auth_code,
                       redirect_uri: "https://www.workato.com/oauth/callback"
                     ).
                     user(connection["client_id"]).
                     password(connection["client_secret"]).
                     request_format_www_form_urlencoded
        [response, nil, nil]
      end,

      refresh_on: 401,

      refresh: lambda do |connection, refresh_token|
        post("https://accounts.spotify.com/api/token").
          payload(
            grant_type: "refresh_token",
            refresh_token: refresh_token
          ).
          user(connection["client_id"]).
          password(connection["client_secret"]).
          request_format_www_form_urlencoded
      end,

      apply: lambda do |_connection, access_token|
        headers("Authorization": "Bearer #{access_token}")
      end
    }
  },

  object_definitions: {
    device: {
      fields: lambda do
        [
          { name: "id" },
          { name: "name" },
          { name: "type" },
          { name: "volume_percent", type: "integer" },
          { name: "is_active", type: "boolean" },
          { name: "is_restricted", type: "boolean" },
        ]
      end
    },

    album: {
      fields: lambda do
        [
          { name: "id" },
          { name: "name" },
          { name: "album_type" },
          { name: "href", type: "string", control_type: "url" },
          { name: "uri", label: "Spotify URI" },
          { name: "artists", type: "array", of: "object",
            properties: [
              { name: "id" },
              { name: "name" },
              { name: "uri", label: "Spotify URI" },
              { name: "external_urls" },
              { name: "href", type: "string", control_type: "url" }
            ] },
          { name: "images", type: "array", of: "object",
            properties: [
              { name: "url", type: "string", control_type: "url" },
              { name: "height", type: "integer" },
              { name: "width", type: "integer" }
            ] },
          { name: "available_markets", type: "array", properties: [] },
          { name: "external_urls" }
        ]
      end
    },

    artist: {
      fields: lambda do
        [
          { name: "id" },
          { name: "name" },
          { name: "uri", label: "Spotify URI" },
          { name: "external_urls" },
          { name: "href", type: "string", control_type: "url" }
        ]
      end
    },

    playlist: {
      fields: lambda do
        [
          { name: "id" },
          { name: "name" },
          { name: "owner", type: "object", properties: [
            { name: "id" },
            { name: "name" },
            { name: "uri", label: "Spotify URI" },
            { name: "external_urls" },
            { name: "href", type: "string", control_type: "url" }
          ] },
          { name: "uri", label: "Spotify URI" },
          { name: "external_urls" },
          { name: "href", type: "string", control_type: "url" },
          { name: "collaborative", type: "boolean" },
          { name: "public", type: "boolean" },
          { name: "tracks", type: "object", properties: [
            { name: "href", type: "string", control_type: "url" },
            { name: "total", type: "integer" }
          ] }
        ]
      end
    },

    track: {
      fields: lambda do
        [
          { name: "id" },
          { name: "name" },
          { name: "duration_ms", type: "integer",
            hint: "Track length in milliseconds" },
          { name: "disc_number", type: "integer" },
          { name: "track_number", type: "integer" },
          { name: "explicit", type: "boolean" },
          { name: "is_playable", type: "boolean", label: "Playable" },
          { name: "href", type: "string", control_type: "url" },
          { name: "preview_url", type: "string", control_type: "url" },
          { name: "artists", type: "array", of: "object",
            properties: [
              { name: "id" },
              { name: "name" },
              { name: "uri", label: "Spotify URI" },
              { name: "external_urls" },
              { name: "href", type: "string", control_type: "url" }
            ] },
          { name: "uri", label: "Spotify URI" }
        ]
      end
    }
  },

  test: lambda do |_connection|
    get("https://api.spotify.com/v1/me")
  end,

  actions: {
    search_tracks: {
      description: "Search <span class=\"provider\">Tracks</span> in "\
                    "<span class=\"provider\">Spotify</span>",

      hint: "Returns a list of tracks matching the search criteria.",

      input_fields: lambda do
        [
          {
            name: "q",
            label: "Keywords",
            type: "string",
            hint: "",
            optional: false
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get("https://api.spotify.com/v1/search", input).
          params(
            type: "track"
          )["tracks"]
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: "items",
            type: "array",
            of: "object",
            properties: object_definitions["track"]
          }
        ]
      end
    },

    search_playlists: {
      description: "Search <span class=\"provider\">Playlists</span> in "\
                    "<span class=\"provider\">Spotify</span>",

      hint: "Returns a list of public playlists matching the search criteria.",

      input_fields: lambda do
        [
          {
            name: "q",
            label: "Keywords",
            type: "string",
            hint: "",
            optional: false
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get("https://api.spotify.com/v1/search", input).
          params(
            type: "playlist"
          )["playlists"]
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: "items",
            type: "array",
            of: "object",
            properties: object_definitions["playlist"]
          }
        ]
      end
    },

    search_artists: {
      description: "Search <span class=\"provider\">Artists</span> in "\
                    "<span class=\"provider\">Spotify</span>",

      hint: "Returns a list of artists matching the search criteria.",

      input_fields: lambda do
        [
          {
            name: "q",
            label: "Keywords",
            type: "string",
            hint: "",
            optional: false
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get("https://api.spotify.com/v1/search", input).
          params(
            type: "artist"
          )["artists"]
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: "items",
            type: "array",
            of: "object",
            properties: object_definitions["artist"]
          }
        ]
      end
    },

    search_albums: {
      description: "Search <span class=\"provider\">Albums</span> in "\
                    "<span class=\"provider\">Spotify</span>",

      hint: "Returns a list of albums matching the search criteria.",

      input_fields: lambda do
        [
          {
            name: "q",
            label: "Keywords",
            type: "string",
            hint: "",
            optional: false
          }
        ]
      end,

      execute: lambda do |_connection, input|
        get("https://api.spotify.com/v1/search", input).
          params(
            type: "album"
          )["albums"]
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: "items",
            type: "array",
            of: "object",
            properties: object_definitions["album"]
          }
        ]
      end
    },

    get_new_releases: {
      description: "Get list of <span class=\"provider\">New Releases</span> "\
                    "in <span class=\"provider\">Spotify</span>",

      hint: "Returns a list of new releases by a particular country, if "\
            "provided. If omitted, returned items will be relevant to "\
            "all countries.",

      input_fields: lambda do
        [
          {
            name: "country",
            optional: true,
            sticky: true,
            hint: "Use ISO 3166-1 alpha-2 country code format. More information"\
                  "<a href=\"https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2\">"\
                  "here</a>."
          }
        ]
      end,

      execute: lambda do |_connection, input|
        if input["country"].present?
          input["country"] = input["country"].to_country_alpha2
        end
        get("https://api.spotify.com/v1/browse/new-releases", input).
          params(limit: 50)
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["album"]
      end
    },

    get_devices: {
      description: "Get list of <span class=\"provider\">Devices</span> in "\
                    "<span class=\"provider\">Spotify</span>",

      hint: "Returns a list of information about all connected devices.",

      input_fields: lambda do
      end,

      execute: lambda do |_connection, _input|
        get("https://api.spotify.com/v1/me/player/devices").
          params(limit: 50)
      end,

      output_fields: lambda do |object_definitions|
        [
          {
            name: "devices",
            type: "array",
            of: "object",
            properties: object_definitions["device"]
          }
        ]
      end
    },

    start_or_resume_playback: {
      description: "Start or resume <span class=\"provider\">Playback</span> "\
                    "in <span class=\"provider\">Spotify</span>",

      input_fields: lambda do
        [
          {
            name: "play_uri",
            optional: true,
            sticky: true,
            hint: "Spotify URI of the context to play, "\
            "e.g. albums, artists or playlists."
          },
          {
            name: "device_id", label: "Device", optional: true, sticky: true,
            control_type: :select, pick_list: "devices",
            hint: "ID of the device to play on. If blank, playback will "\
                  "commence from last active device."
          }
        ]
      end,

      execute: lambda do |_connection, input|
        if input["play_uri"].present?
          if input["play_uri"].include?("track")
            input["uris"] = [input["play_uri"]]
          else
            input["context_uri"] = input["play_uri"]
          end
        end
        input = input.reject { |k, _v| k == "play_uri" }
        put("https://api.spotify.com/v1/me/player/play", input)
      end,

      output_fields: lambda do
      end
    },

    pause_playback: {
      description: "Pause <span class=\"provider\">Playback</span> in "\
                    "<span class=\"provider\">Spotify</span>",

      input_fields: lambda do
        [
          {
            name: "device_id", label: "Device", optional: true, sticky: true,
            control_type: :select, pick_list: "devices",
            hint: "ID of the device to pause on. If blank, playback will pause"\
                  " on last active device."
          }
        ]
      end,

      execute: lambda do |_connection, input|
        put("https://api.spotify.com/v1/me/player/pause", input)
      end,

      output_fields: lambda do
      end
    },

    skip_track: {
      description: "Skip to <span class=\"provider\">next track</span> in "\
                    "<span class=\"provider\">Spotify</span>",

      input_fields: lambda do
        [
          {
            name: "device_id", label: "Device", optional: true, sticky: true,
            control_type: :select, pick_list: "devices",
            hint: "ID of the device to skip on. If blank, track will be "\
                  "skipped on last active device."
          }
        ]
      end,

      execute: lambda do |_connection, input|
        post("https://api.spotify.com/v1/me/player/next", input)
      end,

      output_fields: lambda do
      end
    },

    rewind_track: {
      description: "Rewind to <span class=\"provider\">previous track</span> "\
                    "in <span class=\"provider\">Spotify</span>",

      hint: "Rewinds to the previous track.",

      input_fields: lambda do
        [
          {
            name: "device_id", label: "Device", optional: true, sticky: true,
            control_type: :select, pick_list: "devices",
            hint: "ID of the device to rewind on. If blank, track will be "\
                  "rewound on last active device."
          }
        ]
      end,

      execute: lambda do |_connection, input|
        post("https://api.spotify.com/v1/me/player/previous", input)
      end,

      output_fields: lambda do
      end
    },
  },

  triggers: {
  },

  pick_lists: {
    devices: lambda do |_connection|
      get("https://api.spotify.com/v1/me/player/devices")["devices"].
        map { |device| [device["name"], device["id"]] }
    end
  }
}
