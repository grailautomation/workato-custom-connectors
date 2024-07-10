{
  title: 'Basecamp',
  
  custom_action: true,

  connection: {
    fields: [
      {
        name: 'client_id',
        label: 'Client ID',
        hint: 'You can find your client ID in your OAuth app settings',
        optional: false
      },
      {
        name: 'client_secret',
        label: 'Client Secret',
        hint: 'You can find your client secret in your OAuth app settings',
        optional: false,
        control_type: 'password'
      },
      {
        name: 'account_id',
        label: 'Account ID',
        hint: 'https://3.basecamp.com/XXXXXXX',
        optional: false,
        control_type: 'text'
      }
    ],

    authorization: {
      type: 'oauth2',

      client_id: lambda do |connection|
        connection['client_id']
      end,

      client_secret: lambda do |connection|
        connection['client_secret']
      end,

      authorization_url: lambda do |connection|
        "https://launchpad.37signals.com/authorization/new?type=web_server&client_id=#{connection['client_id']}&redirect_uri=https://www.workato.com/oauth/callback"
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        response = post('https://launchpad.37signals.com/authorization/token').
          payload(
            type: 'web_server',
            code: auth_code,
            client_id: connection['client_id'],
            client_secret: connection['client_secret'],
            redirect_uri: redirect_uri
          ).
          request_format_www_form_urlencoded

        {
          access_token: response["access_token"],
          refresh_token: response["refresh_token"],
          expires_at: Time.now + response["expires_in"].to_i.seconds
        }
      end,

      refresh: lambda do |connection, refresh_token|
        response = post('https://launchpad.37signals.com/authorization/token').
          payload(
            type: 'refresh',
            refresh_token: refresh_token,
            client_id: connection['client_id'],
            client_secret: connection['client_secret']
          ).
          request_format_www_form_urlencoded

        {
          access_token: response["access_token"],
          refresh_token: response["refresh_token"],
          expires_at: Time.now + response["expires_in"].to_i.seconds
        }
      end,

      refresh_on: [401],

      apply: lambda do |_connection, access_token|
        headers('Authorization': "Bearer #{access_token}")
      end
    },

    base_uri: lambda do |connection|
      "https://3.basecampapi.com/#{connection['account_id']}/"
    end
  },

  triggers: {
    new_event: {
      title: 'New Event',
      subtitle: 'Triggers when a new event occurs in Basecamp',
      description: 'Triggers when a specified event happens in Basecamp',

      input_fields: lambda do
        [
          {
            name: 'project_id',
            label: 'Project ID',
            type: 'string',
            optional: false,
            hint: 'ID of the Basecamp project to monitor for events'
          },
          {
            name: 'event_types',
            label: 'Event Types',
            type: 'string',
            control_type: 'text',
            optional: false,
            hint: 'No spaces allowed! Events to monitor (ex: Comment,Client::Approval::Response,Client::Forward,Client::Reply,CloudFile,Document,GoogleDocument,Inbox::Forward,Message,Question,Question::Answer,Schedule::Entry,Todo,Todolist,Upload,Vault)'
          }
        ]
      end,

      webhook_subscribe: lambda do |webhook_url, connection, input, recipe_id|
        response = post("https://3.basecampapi.com/#{connection['account_id']}/buckets/#{input['project_id']}/webhooks.json",
            payload_url: webhook_url)
      end,

      webhook_unsubscribe: lambda do |webhook, connection|
        delete("https://3.basecampapi.com/#{connection['account_id']}/buckets/#{webhook['project_id']}/webhooks/#{webhook['id']}.json")
      end,

      webhook_notification: lambda do |input, payload, extended_input_schema, extended_output_schema, headers, params|
        payload
      end,

      dedup: lambda do |event|
        event['id']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['event']
      end
    }
  },

  actions: {
    get_recordings: {
      title: 'Get Recordings',
      subtitle: 'Get a paginated list of recordings for a given type',
      description: 'Get a paginated list of recordings for a given type of recording from Basecamp',

      input_fields: lambda do
        [
          { name: 'type', label: 'Type', hint: 'Type of recording', control_type: 'select', pick_list: 'recording_types', optional: false },
          { name: 'bucket', label: 'Bucket', hint: 'Single or comma separated list of project IDs. Default: All active projects visible to the current user', optional: true },
          { name: 'status', label: 'Status', hint: 'Options: active, archived, or trashed. Default: active', control_type: 'select', pick_list: 'status_options', optional: true },
          { name: 'sort', label: 'Sort', hint: 'Options: created_at or updated_at. Default: created_at', control_type: 'select', pick_list: 'sort_options', optional: true },
          { name: 'direction', label: 'Direction', hint: 'Options: desc or asc. Default: desc', control_type: 'select', pick_list: 'direction_options', optional: true },
          { name: 'page', label: 'Page', hint: 'Page number for pagination', control_type: 'number', optional: true },
          { name: 'per_page', label: 'Per Page', hint: 'Number of results per page', control_type: 'number', optional: true }
        ]
      end,

      execute: lambda do |connection, input|
        params = {
          type: input['type'],
          bucket: input['bucket'],
          status: input['status'] || 'active',
          sort: input['sort'] || 'created_at',
          direction: input['direction'] || 'desc',
          page: input['page'],
          per_page: input['per_page']
        }.compact

        response = get("https://3.basecampapi.com/#{connection['account_id']}/projects/recordings.json").
                    params(params)

        {
          recordings: response
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'recordings', type: :array, of: :object, properties: object_definitions['recording'] }
        ]
      end
    },
    get_all_projects: {
      title: 'Get All Projects',
      subtitle: 'Retrieve all projects from Basecamp',
      description: 'Get a list of all projects from Basecamp',

      input_fields: lambda do
        []
      end,

      execute: lambda do |connection, _input|
        response = get("https://3.basecampapi.com/#{connection['account_id']}/projects.json")

        {
          projects: response
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'projects', type: :array, of: :object, properties: object_definitions['project'] }
        ]
      end
    },
    get_project: {
      title: 'Get a Project',
      subtitle: 'Retrieve details of a specific project from Basecamp',
      description: 'Get details of a specific project from Basecamp by project ID',

      input_fields: lambda do
        [
          { name: 'project_id', label: 'Project ID', optional: false, type: :integer, hint: 'ID of the project to retrieve' }
        ]
      end,

      execute: lambda do |connection, input|
        response = get("https://3.basecampapi.com/#{connection['account_id']}/projects/#{input['project_id']}.json")

        {
          project: response
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'project', type: :object, properties: object_definitions['project'] }
        ]
      end
    },
    get_card_table: {
      title: 'Get Card Table',
      subtitle: 'Retrieve details of a specific card table from Basecamp',
      description: 'Get details of a specific card table from Basecamp by bucket ID and card table ID',

      input_fields: lambda do
        [
          { name: 'bucket_id', label: 'Bucket ID', optional: false, type: :integer, hint: 'ID of the bucket that contains the card table' },
          { name: 'card_table_id', label: 'Card Table ID', optional: false, type: :integer, hint: 'ID of the card table to retrieve' }
        ]
      end,

      execute: lambda do |connection, input|
        response = get("https://3.basecampapi.com/#{connection['account_id']}/buckets/#{input['bucket_id']}/card_tables/#{input['card_table_id']}.json")

        {
          card_table: response
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'card_table', type: :object, properties: object_definitions['card_table'] }
        ]
      end
    },
    get_card_table_column: {
      title: 'Get Card Table Column',
      subtitle: 'Retrieve details of a specific card table column from Basecamp',
      description: 'Get details of a specific card table column from Basecamp by bucket ID and card table column ID',

      input_fields: lambda do
        [
          { name: 'bucket_id', label: 'Bucket ID', optional: false, type: :integer, hint: 'ID of the bucket that contains the card table column' },
          { name: 'card_table_column_id', label: 'Card Table Column ID', optional: false, type: :integer, hint: 'ID of the card table column to retrieve' }
        ]
      end,

      execute: lambda do |connection, input|
        response = get("https://3.basecampapi.com/#{connection['account_id']}/buckets/#{input['bucket_id']}/card_tables/columns/#{input['card_table_column_id']}.json")

        {
          card_table_column: response
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'card_table_column', type: :object, properties: object_definitions['card_table_column'] }
        ]
      end
    },
    get_cards_in_a_column: {
      title: 'Get Cards in a Column',
      subtitle: 'Retrieve all cards in a specific card table column from Basecamp',
      description: 'Get all cards in a specific card table column from Basecamp by bucket ID and column ID',

      input_fields: lambda do
        [
          { name: 'bucket_id', label: 'Bucket ID', optional: false, type: :integer, hint: 'ID of the bucket that contains the card table column' },
          { name: 'column_id', label: 'Column ID', optional: false, type: :integer, hint: 'ID of the card table column to retrieve cards from' }
        ]
      end,

      execute: lambda do |connection, input|
        response = get("https://3.basecampapi.com/#{connection['account_id']}/buckets/#{input['bucket_id']}/card_tables/lists/#{input['column_id']}/cards.json")

        {
          cards: response
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'cards', type: :array, of: :object, properties: object_definitions['card'] }
        ]
      end
    },
    get_card: {
      title: 'Get a Card',
      subtitle: 'Retrieve details of a specific card from Basecamp',
      description: 'Get details of a specific card from Basecamp by bucket ID and card ID',

      input_fields: lambda do
        [
          { name: 'bucket_id', label: 'Bucket ID', optional: false, type: :integer, hint: 'ID of the bucket that contains the card' },
          { name: 'card_id', label: 'Card ID', optional: false, type: :integer, hint: 'ID of the card to retrieve' }
        ]
      end,

      execute: lambda do |connection, input|
        response = get("https://3.basecampapi.com/#{connection['account_id']}/buckets/#{input['bucket_id']}/card_tables/cards/#{input['card_id']}.json")

        {
          card: response
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'card', type: :object, properties: object_definitions['card'] }
        ]
      end
    },
    get_comments: {
      title: 'Get Comments',
      subtitle: 'Retrieve all comments for a specific recording from Basecamp',
      description: 'Get all comments for a specific recording from Basecamp by bucket ID and recording ID',

      input_fields: lambda do
        [
          { name: 'bucket_id', label: 'Bucket ID', optional: false, type: :integer, hint: 'ID of the bucket that contains the recording' },
          { name: 'recording_id', label: 'Recording ID', optional: false, type: :integer, hint: 'ID of the recording to retrieve comments from' }
        ]
      end,

      execute: lambda do |connection, input|
        response = get("https://3.basecampapi.com/#{connection['account_id']}/buckets/#{input['bucket_id']}/recordings/#{input['recording_id']}/comments.json")

        {
          comments: response
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'comments', type: :array, of: :object, properties: object_definitions['comment'] }
        ]
      end
    },
    create_comment: {
      title: 'Create Comment',
      subtitle: 'Publish a comment in a specific recording from Basecamp',
      description: 'Create a comment in a specific recording from Basecamp by bucket ID and recording ID',

      input_fields: lambda do
        [
          { name: 'bucket_id', label: 'Bucket ID', optional: false, type: :integer, hint: 'ID of the bucket that contains the recording' },
          { name: 'recording_id', label: 'Recording ID', optional: false, type: :integer, hint: 'ID of the recording to post the comment in' },
          { name: 'content', label: 'Content', optional: false, type: :string, hint: 'Content of the comment in allowed HTML format' }
        ]
      end,

      execute: lambda do |connection, input|
        response = post("https://3.basecampapi.com/#{connection['account_id']}/buckets/#{input['bucket_id']}/recordings/#{input['recording_id']}/comments.json").
                  payload(content: input['content']).
                  request_format_json

        {
          comment: response
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'comment', type: :object, properties: object_definitions['comment'] }
        ]
      end
    },
    create_card: {
      title: 'Create Card',
      subtitle: 'Create a card in a specific card table column from Basecamp',
      description: 'Create a card in a specific card table column from Basecamp by bucket ID and column ID',

      input_fields: lambda do
        [
          { name: 'bucket_id', label: 'Bucket ID', optional: false, type: :integer, hint: 'ID of the bucket that contains the card table column' },
          { name: 'column_id', label: 'Column ID', optional: false, type: :integer, hint: 'ID of the card table column to create the card in' },
          { name: 'title', label: 'Title', optional: false, type: :string, hint: 'Title of the card' },
          { name: 'content', label: 'Content', optional: true, type: :string, hint: 'Content of the card in allowed HTML format' },
          { name: 'due_on', label: 'Due On', optional: true, type: :date, hint: 'Due date of the card (ISO 8601 format)' },
          { name: 'notify', label: 'Notify', optional: true, type: :boolean, hint: 'Whether to notify assignees, value true or false. Defaults to false.' }
        ]
      end,

      execute: lambda do |connection, input|
        payload = {
          title: input['title'],
          content: input['content'],
          due_on: input['due_on'],
          notify: input['notify']
        }.compact

        response = post("https://3.basecampapi.com/#{connection['account_id']}/buckets/#{input['bucket_id']}/card_tables/lists/#{input['column_id']}/cards.json").
                  payload(payload).
                  request_format_json

        {
          card: response
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'card', type: :object, properties: object_definitions['card'] }
        ]
      end
    },
    create_attachment: {
      title: 'Create Attachment',
      subtitle: 'Upload a file to Basecamp as an attachment',
      description: 'Upload a file to Basecamp as an attachment by providing the file and its metadata',

      input_fields: lambda do
        [
          { name: 'name', label: 'File Name', optional: false, type: :string, hint: 'Name of the file being uploaded' },
          { name: 'file', label: 'File', optional: false, type: :file, hint: 'The file to be uploaded' }
        ]
      end,

      execute: lambda do |connection, input|
        file = input['file']
        file_name = input['name']

        response = post("https://3.basecampapi.com/#{connection['account_id']}/attachments.json?name=#{file_name}").
                  headers('Content-Type' => file['content_type'], 'Content-Length' => file['size']).
                  request_body(file['content'])

        {
          attachment: response
        }
      end,

      output_fields: lambda do |object_definitions|
        [
          { name: 'attachment', type: :object, properties: object_definitions['attachment'] }
        ]
      end
    },
    update_card: {
  title: 'Update Card',
  subtitle: 'Update a card in Basecamp',
  description: 'Allows changing of the card with an ID in the project with ID.',

  input_fields: lambda do
    [
      { name: 'project_id', label: 'Project ID', optional: false, hint: 'Project ID where the card exists' },
      { name: 'card_id', label: 'Card ID', optional: false, hint: 'ID of the card to update' },
      { name: 'title', label: 'Title', optional: true, hint: 'Title of the card' },
      { name: 'content', label: 'Content', optional: true, hint: 'Content of the card, supports HTML tags as per Rich text guide' },
      { name: 'due_on', label: 'Due Date', type: :date, optional: true, hint: 'Due date of the card in ISO 8601 format' },
      { name: 'assignee_ids', label: 'Assignee IDs', type: :array, of: :integer, optional: true, hint: 'Array of people IDs that will be assigned to this card' }
    ]
  end,

  execute: lambda do |connection, input|
    project_id = input.delete('project_id')
    card_id = input.delete('card_id')

    response = put("https://3.basecampapi.com/#{connection['account_id']}/buckets/#{project_id}/card_tables/cards/#{card_id}.json").
               payload(input).
               request_format_json

    {
      card: response
    }
  end,

  output_fields: lambda do |object_definitions|
    object_definitions['card']
  end,

  sample_output: lambda do |_connection, _input|
    {
      "id": 2,
      "title": "Updated investigation",
      "content": "Detailed description of the card.",
      "due_on": "2023-12-31",
      "assignee_ids": [12345, 67890]
    }
  end
},
    update_comment: {
  title: 'Update Comment',
  subtitle: 'Update a comment in Basecamp',
  description: 'Allows changing the content of a comment with an ID in the project.',

  input_fields: lambda do
    [
      { name: 'project_id', label: 'Project ID', optional: false, hint: 'Project ID where the comment exists' },
      { name: 'comment_id', label: 'Comment ID', optional: false, hint: 'ID of the comment to update' },
      { name: 'content', label: 'Content', optional: false, hint: 'Content of the comment, supports HTML tags', control_type: 'text-area' }
    ]
  end,

  execute: lambda do |connection, input|
    project_id = input.delete('project_id')
    comment_id = input.delete('comment_id')

    response = put("https://3.basecampapi.com/#{connection['account_id']}/buckets/#{project_id}/comments/#{comment_id}.json").
               payload(content: input['content']).
               request_format_json

    {
      comment: response
    }
  end,

  output_fields: lambda do |object_definitions|
    object_definitions['comment']
  end,

  sample_output: lambda do |_connection, _input|
    {
      "id": 2,
      "content": "<div><em>No way!</em> That isn't cool at all.</div>",
      "created_at": "2022-10-30T01:01:58.169Z",
      "updated_at": "2022-10-30T01:01:58.169Z"
    }
  end
},
    move_card: {
  title: 'Move Card',
  subtitle: 'Move a card to a different column in Basecamp',
  description: 'Allows moving of a card to a different column within the same project.',

  input_fields: lambda do
    [
      { name: 'project_id', label: 'Project ID', optional: false, hint: 'Project ID where the card exists' },
      { name: 'card_id', label: 'Card ID', optional: false, hint: 'ID of the card to move' },
      { name: 'column_id', label: 'Column ID', optional: false, hint: 'ID of the destination column' }
    ]
  end,

  execute: lambda do |connection, input|
    project_id = input.delete('project_id')
    card_id = input.delete('card_id')
    column_id = input['column_id']

    post("https://3.basecampapi.com/#{connection['account_id']}/buckets/#{project_id}/card_tables/cards/#{card_id}/moves.json",
         column_id: column_id)

    # Since the API does not return content, we return a success message
    { status: 'success', message: 'Card moved successfully' }
  end,

  output_fields: lambda do
    [
      { name: 'status', label: 'Status' },
      { name: 'message', label: 'Message' }
    ]
  end,

  sample_output: lambda do
    { status: 'success', message: 'Card moved successfully' }
  end
}
},

  pick_lists: {
    recording_types: lambda do
      [
        ['Comment', 'Comment'],
        ['Document', 'Document'],
        ['Message', 'Message'],
        ['Question::Answer', 'Question::Answer'],
        ['Schedule::Entry', 'Schedule::Entry'],
        ['Todo', 'Todo'],
        ['Todolist', 'Todolist'],
        ['Upload', 'Upload'],
        ['Vault', 'Vault']
      ]
    end,
    status_options: lambda do
      [
        ['active', 'active'],
        ['archived', 'archived'],
        ['trashed', 'trashed']
      ]
    end,
    sort_options: lambda do
      [
        ['created_at', 'created_at'],
        ['updated_at', 'updated_at']
      ]
    end,
    direction_options: lambda do
      [
        ['desc', 'desc'],
        ['asc', 'asc']
      ]
    end
  },

  object_definitions: {
    event: {
      fields: lambda do
      [
        { name: 'id', label: 'Event ID', type: :integer },
        { name: 'kind', label: 'Kind of Event', type: :string },
        { name: 'created_at', label: 'Created At', type: :timestamp },
        {
          name: 'details', label: 'Details', type: :object, properties: [
            { name: 'copy_id', label: 'Copy ID', type: :integer }
          ]
        },
        {
          name: 'copy', label: 'Copy', type: :object, properties: [
            { name: 'id', label: 'Copy ID', type: :integer },
            { name: 'url', label: 'URL', type: :string },
            { name: 'app_url', label: 'App URL', type: :string },
            {
              name: 'bucket', label: 'Bucket', type: :object, properties: [
                { name: 'id', label: 'Bucket ID', type: :integer }
              ]
            }
          ]
        },
        {
          name: 'recording', label: 'Recording', type: :object, properties: [
            { name: 'id', label: 'Recording ID', type: :integer },
            { name: 'status', label: 'Status', type: :string },
            { name: 'created_at', label: 'Created At', type: :timestamp },
            { name: 'updated_at', label: 'Updated At', type: :timestamp },
            { name: 'title', label: 'Title', type: :string },
            { name: 'inherits_status', label: 'Inherits Status', type: :boolean },
            { name: 'type', label: 'Type', type: :string },
            { name: 'url', label: 'URL', type: :string },
            { name: 'app_url', label: 'App URL', type: :string },
            { name: 'bookmark_url', label: 'Bookmark URL', type: :string },
            {
              name: 'parent', label: 'Parent', type: :object, properties: [
                { name: 'id', label: 'Parent ID', type: :integer },
                { name: 'title', label: 'Title', type: :string },
                { name: 'type', label: 'Type', type: :string },
                { name: 'url', label: 'URL', type: :string },
                { name: 'app_url', label: 'App URL', type: :string }
              ]
            },
            {
              name: 'bucket', label: 'Bucket', type: :object, properties: [
                { name: 'id', label: 'Bucket ID', type: :integer },
                { name: 'name', label: 'Name', type: :string },
                { name: 'type', label: 'Type', type: :string }
              ]
            },
            {
              name: 'creator', label: 'Creator', type: :object, properties: [
                { name: 'id', label: 'Creator ID', type: :integer },
                { name: 'attachable_sgid', label: 'Attachable SGID', type: :string },
                { name: 'name', label: 'Name', type: :string },
                { name: 'email_address', label: 'Email Address', type: :string },
                { name: 'personable_type', label: 'Personable Type', type: :string },
                { name: 'title', label: 'Title', type: :string },
                { name: 'bio', label: 'Bio', type: :string },
                { name: 'created_at', label: 'Created At', type: :timestamp },
                { name: 'updated_at', label: 'Updated At', type: :timestamp },
                { name: 'admin', label: 'Admin', type: :boolean },
                { name: 'owner', label: 'Owner', type: :boolean },
                { name: 'time_zone', label: 'Time Zone', type: :string },
                { name: 'avatar_url', label: 'Avatar URL', type: :string },
                {
                  name: 'company', label: 'Company', type: :object, properties: [
                    { name: 'id', label: 'Company ID', type: :integer },
                    { name: 'name', label: 'Company Name', type: :string }
                  ]
                }
              ]
            },
            { name: 'content', label: 'Content', type: :string }
          ]
        },
        {
          name: 'creator', label: 'Creator', type: :object, properties: [
            { name: 'id', label: 'Creator ID', type: :integer },
            { name: 'attachable_sgid', label: 'Attachable SGID', type: :string },
            { name: 'name', label: 'Name', type: :string },
            { name: 'email_address', label: 'Email Address', type: :string },
            { name: 'personable_type', label: 'Personable Type', type: :string },
            { name: 'title', label: 'Title', type: :string },
            { name: 'bio', label: 'Bio', type: :string },
            { name: 'created_at', label: 'Created At', type: :timestamp },
            { name: 'updated_at', label: 'Updated At', type: :timestamp },
            { name: 'admin', label: 'Admin', type: :boolean },
            { name: 'owner', label: 'Owner', type: :boolean },
            { name: 'time_zone', label: 'Time Zone', type: :string },
            { name: 'avatar_url', label: 'Avatar URL', type: :string },
            {
              name: 'company', label: 'Company', type: :object, properties: [
                { name: 'id', label: 'Company ID', type: :integer },
                { name: 'name', label: 'Company Name', type: :string }
              ]
            }
          ]
        }
      ]
      end
    },
    project: {
      fields: lambda do
      [
        { name: 'id', label: 'Project ID', type: :integer },
        { name: 'status', label: 'Status', type: :string },
        { name: 'created_at', label: 'Created At', type: :timestamp },
        { name: 'updated_at', label: 'Updated At', type: :timestamp },
        { name: 'name', label: 'Name', type: :string },
        { name: 'description', label: 'Description', type: :string },
        { name: 'purpose', label: 'Purpose', type: :string },
        { name: 'clients_enabled', label: 'Clients Enabled', type: :boolean },
        { name: 'bookmark_url', label: 'Bookmark URL', type: :string },
        { name: 'url', label: 'URL', type: :string },
        { name: 'app_url', label: 'App URL', type: :string },
        { name: 'bookmarked', label: 'Bookmarked', type: :boolean },
        {
          name: 'dock', label: 'Dock', type: :array, of: :object, properties: [
            { name: 'id', label: 'Dock ID', type: :integer },
            { name: 'title', label: 'Title', type: :string },
            { name: 'name', label: 'Name', type: :string },
            { name: 'enabled', label: 'Enabled', type: :boolean },
            { name: 'position', label: 'Position', type: :integer },
            { name: 'url', label: 'URL', type: :string },
            { name: 'app_url', label: 'App URL', type: :string }
          ]
        }
      ]
      end
    },
    card_table: {
      fields: lambda do
        [
          { name: 'id', label: 'Card Table ID', type: :integer },
          { name: 'status', label: 'Status', type: :string },
          { name: 'visible_to_clients', label: 'Visible to Clients', type: :boolean },
          { name: 'created_at', label: 'Created At', type: :timestamp },
          { name: 'updated_at', label: 'Updated At', type: :timestamp },
          { name: 'title', label: 'Title', type: :string },
          { name: 'inherits_status', label: 'Inherits Status', type: :boolean },
          { name: 'type', label: 'Type', type: :string },
          { name: 'url', label: 'URL', type: :string },
          { name: 'app_url', label: 'App URL', type: :string },
          { name: 'bookmark_url', label: 'Bookmark URL', type: :string },
          { name: 'subscription_url', label: 'Subscription URL', type: :string },
          {
            name: 'bucket', label: 'Bucket', type: :object, properties: [
              { name: 'id', label: 'Bucket ID', type: :integer },
              { name: 'name', label: 'Name', type: :string },
              { name: 'type', label: 'Type', type: :string }
            ]
          },
          {
            name: 'creator', label: 'Creator', type: :object, properties: [
              { name: 'id', label: 'Creator ID', type: :integer },
              { name: 'attachable_sgid', label: 'Attachable SGID', type: :string },
              { name: 'name', label: 'Name', type: :string },
              { name: 'email_address', label: 'Email Address', type: :string },
              { name: 'personable_type', label: 'Personable Type', type: :string },
              { name: 'title', label: 'Title', type: :string },
              { name: 'bio', label: 'Bio', type: :string },
              { name: 'location', label: 'Location', type: :string },
              { name: 'created_at', label: 'Created At', type: :timestamp },
              { name: 'updated_at', label: 'Updated At', type: :timestamp },
              { name: 'admin', label: 'Admin', type: :boolean },
              { name: 'owner', label: 'Owner', type: :boolean },
              { name: 'client', label: 'Client', type: :boolean },
              { name: 'employee', label: 'Employee', type: :boolean },
              { name: 'time_zone', label: 'Time Zone', type: :string },
              { name: 'avatar_url', label: 'Avatar URL', type: :string },
              {
                name: 'company', label: 'Company', type: :object, properties: [
                  { name: 'id', label: 'Company ID', type: :integer },
                  { name: 'name', label: 'Company Name', type: :string }
                ]
              },
              { name: 'can_manage_projects', label: 'Can Manage Projects', type: :boolean },
              { name: 'can_manage_people', label: 'Can Manage People', type: :boolean }
            ]
          },
          {
            name: 'subscribers', label: 'Subscribers', type: :array, of: :object, properties: [
              { name: 'id', label: 'Subscriber ID', type: :integer },
              { name: 'attachable_sgid', label: 'Attachable SGID', type: :string },
              { name: 'name', label: 'Name', type: :string },
              { name: 'email_address', label: 'Email Address', type: :string },
              { name: 'personable_type', label: 'Personable Type', type: :string },
              { name: 'title', label: 'Title', type: :string },
              { name: 'bio', label: 'Bio', type: :string },
              { name: 'location', label: 'Location', type: :string },
              { name: 'created_at', label: 'Created At', type: :timestamp },
              { name: 'updated_at', label: 'Updated At', type: :timestamp },
              { name: 'admin', label: 'Admin', type: :boolean },
              { name: 'owner', label: 'Owner', type: :boolean },
              { name: 'client', label: 'Client', type: :boolean },
              { name: 'employee', label: 'Employee', type: :boolean },
              { name: 'time_zone', label: 'Time Zone', type: :string },
              { name: 'avatar_url', label: 'Avatar URL', type: :string },
              {
                name: 'company', label: 'Company', type: :object, properties: [
                  { name: 'id', label: 'Company ID', type: :integer },
                  { name: 'name', label: 'Company Name', type: :string }
                ]
              },
              { name: 'can_manage_projects', label: 'Can Manage Projects', type: :boolean },
              { name: 'can_manage_people', label: 'Can Manage People', type: :boolean }
            ]
          },
          {
            name: 'lists', label: 'Lists', type: :array, of: :object, properties: [
              { name: 'id', label: 'List ID', type: :integer },
              { name: 'status', label: 'Status', type: :string },
              { name: 'visible_to_clients', label: 'Visible to Clients', type: :boolean },
              { name: 'created_at', label: 'Created At', type: :timestamp },
              { name: 'updated_at', label: 'Updated At', type: :timestamp },
              { name: 'title', label: 'Title', type: :string },
              { name: 'inherits_status', label: 'Inherits Status', type: :boolean },
              { name: 'type', label: 'Type', type: :string },
              { name: 'url', label: 'URL', type: :string },
              { name: 'app_url', label: 'App URL', type: :string },
              { name: 'bookmark_url', label: 'Bookmark URL', type: :string },
              {
                name: 'parent', label: 'Parent', type: :object, properties: [
                  { name: 'id', label: 'Parent ID', type: :integer },
                  { name: 'title', label: 'Parent Title', type: :string },
                  { name: 'type', label: 'Parent Type', type: :string },
                  { name: 'url', label: 'Parent URL', type: :string },
                  { name: 'app_url', label: 'Parent App URL', type: :string }
                ]
              },
              {
                name: 'bucket', label: 'Bucket', type: :object, properties: [
                  { name: 'id', label: 'Bucket ID', type: :integer },
                  { name: 'name', label: 'Bucket Name', type: :string },
                  { name: 'type', label: 'Bucket Type', type: :string }
                ]
              },
              {
                name: 'creator', label: 'Creator', type: :object, properties: [
                  { name: 'id', label: 'Creator ID', type: :integer },
                  { name: 'attachable_sgid', label: 'Attachable SGID', type: :string },
                  { name: 'name', label: 'Name', type: :string },
                  { name: 'email_address', label: 'Email Address', type: :string },
                  { name: 'personable_type', label: 'Personable Type', type: :string },
                  { name: 'title', label: 'Title', type: :string },
                  { name: 'bio', label: 'Bio', type: :string },
                  { name: 'location', label: 'Location', type: :string },
                  { name: 'created_at', label: 'Created At', type: :timestamp },
                  { name: 'updated_at', label: 'Updated At', type: :timestamp },
                  { name: 'admin', label: 'Admin', type: :boolean },
                  { name: 'owner', label: 'Owner', type: :boolean },
                  { name: 'client', label: 'Client', type: :boolean },
                  { name: 'employee', label: 'Employee', type: :boolean },
                  { name: 'time_zone', label: 'Time Zone', type: :string },
                  { name: 'avatar_url', label: 'Avatar URL', type: :string },
                  {
                    name: 'company', label: 'Company', type: :object, properties: [
                      { name: 'id', label: 'Company ID', type: :integer },
                      { name: 'name', label: 'Company Name', type: :string }
                    ]
                  },
                  { name: 'can_manage_projects', label: 'Can Manage Projects', type: :boolean },
                  { name: 'can_manage_people', label: 'Can Manage People', type: :boolean }
                ]
              },
              { name: 'description', label: 'Description', type: :string },
              { name: 'subscribers', label: 'Subscribers', type: :array, of: :object },
              { name: 'color', label: 'Color', type: :string },
              { name: 'cards_count', label: 'Cards Count', type: :integer },
              { name: 'comment_count', label: 'Comment Count', type: :integer },
              { name: 'cards_url', label: 'Cards URL', type: :string }
            ]
          }
        ]
      end
    },
    card_table_column: {
      fields: lambda do
        [
          { name: 'id', label: 'Column ID', type: :integer },
          { name: 'status', label: 'Status', type: :string },
          { name: 'visible_to_clients', label: 'Visible to Clients', type: :boolean },
          { name: 'created_at', label: 'Created At', type: :timestamp },
          { name: 'updated_at', label: 'Updated At', type: :timestamp },
          { name: 'title', label: 'Title', type: :string },
          { name: 'inherits_status', label: 'Inherits Status', type: :boolean },
          { name: 'type', label: 'Type', type: :string },
          { name: 'url', label: 'URL', type: :string },
          { name: 'app_url', label: 'App URL', type: :string },
          { name: 'bookmark_url', label: 'Bookmark URL', type: :string },
          {
            name: 'parent', label: 'Parent', type: :object, properties: [
              { name: 'id', label: 'Parent ID', type: :integer },
              { name: 'title', label: 'Parent Title', type: :string },
              { name: 'type', label: 'Parent Type', type: :string },
              { name: 'url', label: 'Parent URL', type: :string },
              { name: 'app_url', label: 'Parent App URL', type: :string }
            ]
          },
          {
            name: 'bucket', label: 'Bucket', type: :object, properties: [
              { name: 'id', label: 'Bucket ID', type: :integer },
              { name: 'name', label: 'Bucket Name', type: :string },
              { name: 'type', label: 'Bucket Type', type: :string }
            ]
          },
          {
            name: 'creator', label: 'Creator', type: :object, properties: [
              { name: 'id', label: 'Creator ID', type: :integer },
              { name: 'attachable_sgid', label: 'Attachable SGID', type: :string },
              { name: 'name', label: 'Name', type: :string },
              { name: 'email_address', label: 'Email Address', type: :string },
              { name: 'personable_type', label: 'Personable Type', type: :string },
              { name: 'title', label: 'Title', type: :string },
              { name: 'bio', label: 'Bio', type: :string },
              { name: 'location', label: 'Location', type: :string },
              { name: 'created_at', label: 'Created At', type: :timestamp },
              { name: 'updated_at', label: 'Updated At', type: :timestamp },
              { name: 'admin', label: 'Admin', type: :boolean },
              { name: 'owner', label: 'Owner', type: :boolean },
              { name: 'client', label: 'Client', type: :boolean },
              { name: 'employee', label: 'Employee', type: :boolean },
              { name: 'time_zone', label: 'Time Zone', type: :string },
              { name: 'avatar_url', label: 'Avatar URL', type: :string },
              {
                name: 'company', label: 'Company', type: :object, properties: [
                  { name: 'id', label: 'Company ID', type: :integer },
                  { name: 'name', label: 'Company Name', type: :string }
                ]
              },
              { name: 'can_manage_projects', label: 'Can Manage Projects', type: :boolean },
              { name: 'can_manage_people', label: 'Can Manage People', type: :boolean }
            ]
          },
          { name: 'description', label: 'Description', type: :string },
          { name: 'subscribers', label: 'Subscribers', type: :array, of: :object },
          { name: 'color', label: 'Color', type: :string },
          { name: 'cards_count', label: 'Cards Count', type: :integer },
          { name: 'comment_count', label: 'Comment Count', type: :integer },
          { name: 'cards_url', label: 'Cards URL', type: :string }
        ]
      end
    },
    card: {
      fields: lambda do
        [
          { name: 'id', label: 'Card ID', type: :integer },
          { name: 'status', label: 'Status', type: :string },
          { name: 'visible_to_clients', label: 'Visible to Clients', type: :boolean },
          { name: 'created_at', label: 'Created At', type: :timestamp },
          { name: 'updated_at', label: 'Updated At', type: :timestamp },
          { name: 'title', label: 'Title', type: :string },
          { name: 'inherits_status', label: 'Inherits Status', type: :boolean },
          { name: 'type', label: 'Type', type: :string },
          { name: 'url', label: 'URL', type: :string },
          { name: 'app_url', label: 'App URL', type: :string },
          { name: 'bookmark_url', label: 'Bookmark URL', type: :string },
          { name: 'subscription_url', label: 'Subscription URL', type: :string },
          { name: 'comments_count', label: 'Comments Count', type: :integer },
          { name: 'comments_url', label: 'Comments URL', type: :string },
          { name: 'position', label: 'Position', type: :integer },
          {
            name: 'parent', label: 'Parent', type: :object, properties: [
              { name: 'id', label: 'Parent ID', type: :integer },
              { name: 'title', label: 'Parent Title', type: :string },
              { name: 'type', label: 'Parent Type', type: :string },
              { name: 'url', label: 'Parent URL', type: :string },
              { name: 'app_url', label: 'Parent App URL', type: :string }
            ]
          },
          {
            name: 'bucket', label: 'Bucket', type: :object, properties: [
              { name: 'id', label: 'Bucket ID', type: :integer },
              { name: 'name', label: 'Bucket Name', type: :string },
              { name: 'type', label: 'Bucket Type', type: :string }
            ]
          },
          {
            name: 'creator', label: 'Creator', type: :object, properties: [
              { name: 'id', label: 'Creator ID', type: :integer },
              { name: 'attachable_sgid', label: 'Attachable SGID', type: :string },
              { name: 'name', label: 'Name', type: :string },
              { name: 'email_address', label: 'Email Address', type: :string },
              { name: 'personable_type', label: 'Personable Type', type: :string },
              { name: 'title', label: 'Title', type: :string },
              { name: 'bio', label: 'Bio', type: :string },
              { name: 'location', label: 'Location', type: :string },
              { name: 'created_at', label: 'Created At', type: :timestamp },
              { name: 'updated_at', label: 'Updated At', type: :timestamp },
              { name: 'admin', label: 'Admin', type: :boolean },
              { name: 'owner', label: 'Owner', type: :boolean },
              { name: 'client', label: 'Client', type: :boolean },
              { name: 'employee', label: 'Employee', type: :boolean },
              { name: 'time_zone', label: 'Time Zone', type: :string },
              { name: 'avatar_url', label: 'Avatar URL', type: :string },
              {
                name: 'company', label: 'Company', type: :object, properties: [
                  { name: 'id', label: 'Company ID', type: :integer },
                  { name: 'name', label: 'Company Name', type: :string }
                ]
              },
              { name: 'can_manage_projects', label: 'Can Manage Projects', type: :boolean },
              { name: 'can_manage_people', label: 'Can Manage People', type: :boolean }
            ]
          },
          { name: 'description', label: 'Description', type: :string },
          { name: 'completed', label: 'Completed', type: :boolean },
          { name: 'content', label: 'Content', type: :string },
          { name: 'due_on', label: 'Due On', type: :date },
          { name: 'assignees', label: 'Assignees', type: :array, of: :object },
          { name: 'completion_subscribers', label: 'Completion Subscribers', type: :array, of: :object },
          { name: 'completion_url', label: 'Completion URL', type: :string },
          { name: 'comment_count', label: 'Comment Count', type: :integer },
          {
            name: 'steps', label: 'Steps', type: :array, of: :object, properties: [
              { name: 'id', label: 'Step ID', type: :integer },
              { name: 'status', label: 'Status', type: :string },
              { name: 'visible_to_clients', label: 'Visible to Clients', type: :boolean },
              { name: 'created_at', label: 'Created At', type: :timestamp },
              { name: 'updated_at', label: 'Updated At', type: :timestamp },
              { name: 'title', label: 'Title', type: :string },
              { name: 'inherits_status', label: 'Inherits Status', type: :boolean },
              { name: 'type', label: 'Type', type: :string },
              { name: 'url', label: 'URL', type: :string },
              { name: 'app_url', label: 'App URL', type: :string },
              { name: 'bookmark_url', label: 'Bookmark URL', type: :string },
              { name: 'position', label: 'Position', type: :integer },
              {
                name: 'parent', label: 'Parent', type: :object, properties: [
                  { name: 'id', label: 'Parent ID', type: :integer },
                  { name: 'title', label: 'Parent Title', type: :string },
                  { name: 'type', label: 'Parent Type', type: :string },
                  { name: 'url', label: 'Parent URL', type: :string },
                  { name: 'app_url', label: 'Parent App URL', type: :string }
                ]
              },
              {
                name: 'bucket', label: 'Bucket', type: :object, properties: [
                  { name: 'id', label: 'Bucket ID', type: :integer },
                  { name: 'name', label: 'Bucket Name', type: :string },
                  { name: 'type', label: 'Bucket Type', type: :string }
                ]
              },
              {
                name: 'creator', label: 'Creator', type: :object, properties: [
                  { name: 'id', label: 'Creator ID', type: :integer },
                  { name: 'attachable_sgid', label: 'Attachable SGID', type: :string },
                  { name: 'name', label: 'Name', type: :string },
                  { name: 'email_address', label: 'Email Address', type: :string },
                  { name: 'personable_type', label: 'Personable Type', type: :string },
                  { name: 'title', label: 'Title', type: :string },
                  { name: 'bio', label: 'Bio', type: :string },
                  { name: 'location', label: 'Location', type: :string },
                  { name: 'created_at', label: 'Created At', type: :timestamp },
                  { name: 'updated_at', label: 'Updated At', type: :timestamp },
                  { name: 'admin', label: 'Admin', type: :boolean },
                  { name: 'owner', label: 'Owner', type: :boolean },
                  { name: 'client', label: 'Client', type: :boolean },
                  { name: 'employee', label: 'Employee', type: :boolean },
                  { name: 'time_zone', label: 'Time Zone', type: :string },
                  { name: 'avatar_url', label: 'Avatar URL', type: :string },
                  {
                    name: 'company', label: 'Company', type: :object, properties: [
                      { name: 'id', label: 'Company ID', type: :integer },
                      { name: 'name', label: 'Company Name', type: :string }
                    ]
                  },
                  { name: 'can_manage_projects', label: 'Can Manage Projects', type: :boolean },
                  { name: 'can_manage_people', label: 'Can Manage People', type: :boolean }
                ]
              },
              { name: 'completed', label: 'Completed', type: :boolean },
              { name: 'due_on', label: 'Due On', type: :date },
              {
                name: 'assignees', label: 'Assignees', type: :array, of: :object, properties: [
                  { name: 'id', label: 'Assignee ID', type: :integer },
                  { name: 'attachable_sgid', label: 'Attachable SGID', type: :string },
                  { name: 'name', label: 'Name', type: :string },
                  { name: 'email_address', label: 'Email Address', type: :string },
                  { name: 'personable_type', label: 'Personable Type', type: :string },
                  { name: 'title', label: 'Title', type: :string },
                  { name: 'bio', label: 'Bio', type: :string },
                  { name: 'location', label: 'Location', type: :string },
                  { name: 'created_at', label: 'Created At', type: :timestamp },
                  { name: 'updated_at', label: 'Updated At', type: :timestamp },
                  { name: 'admin', label: 'Admin', type: :boolean },
                  { name: 'owner', label: 'Owner', type: :boolean },
                  { name: 'client', label: 'Client', type: :boolean },
                  { name: 'employee', label: 'Employee', type: :boolean },
                  { name: 'time_zone', label: 'Time Zone', type: :string },
                  { name: 'avatar_url', label: 'Avatar URL', type: :string },
                  {
                    name: 'company', label: 'Company', type: :object, properties: [
                      { name: 'id', label: 'Company ID', type: :integer },
                      { name: 'name', label: 'Company Name', type: :string }
                    ]
                  },
                  { name: 'can_manage_projects', label: 'Can Manage Projects', type: :boolean },
                  { name: 'can_manage_people', label: 'Can Manage People', type: :boolean }
                ]
              },
              { name: 'completion_url', label: 'Completion URL', type: :string }
            ]
          }
        ]
      end
    },
    comment: {
      fields: lambda do
        [
          { name: 'id', label: 'Comment ID', type: :integer },
          { name: 'status', label: 'Status', type: :string },
          { name: 'visible_to_clients', label: 'Visible to Clients', type: :boolean },
          { name: 'created_at', label: 'Created At', type: :timestamp },
          { name: 'updated_at', label: 'Updated At', type: :timestamp },
          { name: 'title', label: 'Title', type: :string },
          { name: 'inherits_status', label: 'Inherits Status', type: :boolean },
          { name: 'type', label: 'Type', type: :string },
          { name: 'url', label: 'URL', type: :string },
          { name: 'app_url', label: 'App URL', type: :string },
          { name: 'bookmark_url', label: 'Bookmark URL', type: :string },
          {
            name: 'parent', label: 'Parent', type: :object, properties: [
              { name: 'id', label: 'Parent ID', type: :integer },
              { name: 'title', label: 'Parent Title', type: :string },
              { name: 'type', label: 'Parent Type', type: :string },
              { name: 'url', label: 'Parent URL', type: :string },
              { name: 'app_url', label: 'Parent App URL', type: :string }
            ]
          },
          {
            name: 'bucket', label: 'Bucket', type: :object, properties: [
              { name: 'id', label: 'Bucket ID', type: :integer },
              { name: 'name', label: 'Bucket Name', type: :string },
              { name: 'type', label: 'Bucket Type', type: :string }
            ]
          },
          {
            name: 'creator', label: 'Creator', type: :object, properties: [
              { name: 'id', label: 'Creator ID', type: :integer },
              { name: 'attachable_sgid', label: 'Attachable SGID', type: :string },
              { name: 'name', label: 'Name', type: :string },
              { name: 'email_address', label: 'Email Address', type: :string },
              { name: 'personable_type', label: 'Personable Type', type: :string },
              { name: 'title', label: 'Title', type: :string },
              { name: 'bio', label: 'Bio', type: :string },
              { name: 'location', label: 'Location', type: :string },
              { name: 'created_at', label: 'Created At', type: :timestamp },
              { name: 'updated_at', label: 'Updated At', type: :timestamp },
              { name: 'admin', label: 'Admin', type: :boolean },
              { name: 'owner', label: 'Owner', type: :boolean },
              { name: 'client', label: 'Client', type: :boolean },
              { name: 'employee', label: 'Employee', type: :boolean },
              { name: 'time_zone', label: 'Time Zone', type: :string },
              { name: 'avatar_url', label: 'Avatar URL', type: :string },
              {
                name: 'company', label: 'Company', type: :object, properties: [
                  { name: 'id', label: 'Company ID', type: :integer },
                  { name: 'name', label: 'Company Name', type: :string }
                ]
              },
              { name: 'can_manage_projects', label: 'Can Manage Projects', type: :boolean },
              { name: 'can_manage_people', label: 'Can Manage People', type: :boolean }
            ]
          },
          { name: 'content', label: 'Content', type: :string }
        ]
      end
    },
    person: {
      fields: lambda do
        [
          { name: 'id', label: 'Person ID', type: :integer },
          { name: 'attachable_sgid', label: 'Attachable SGID', type: :string },
          { name: 'name', label: 'Name', type: :string },
          { name: 'email_address', label: 'Email Address', type: :string },
          { name: 'personable_type', label: 'Personable Type', type: :string },
          { name: 'title', label: 'Title', type: :string },
          { name: 'bio', label: 'Bio', type: :string },
          { name: 'location', label: 'Location', type: :string },
          { name: 'created_at', label: 'Created At', type: :timestamp },
          { name: 'updated_at', label: 'Updated At', type: :timestamp },
          { name: 'admin', label: 'Admin', type: :boolean },
          { name: 'owner', label: 'Owner', type: :boolean },
          { name: 'client', label: 'Client', type: :boolean },
          { name: 'employee', label: 'Employee', type: :boolean },
          { name: 'time_zone', label: 'Time Zone', type: :string },
          { name: 'avatar_url', label: 'Avatar URL', type: :string },
          { name: 'can_manage_projects', label: 'Can Manage Projects', type: :boolean },
          { name: 'can_manage_people', label: 'Can Manage People', type: :boolean }
        ]
      end
    },
    recording: {
      fields: lambda do
        [
          { name: 'id', label: 'Recording ID', type: :integer },
          { name: 'status', label: 'Status', type: :string },
          { name: 'created_at', label: 'Created At', type: :timestamp },
          { name: 'updated_at', label: 'Updated At', type: :timestamp },
          { name: 'title', label: 'Title', type: :string },
          { name: 'type', label: 'Type', type: :string },
          { name: 'url', label: 'URL', type: :string },
          { name: 'app_url', label: 'App URL', type: :string },
          { name: 'bucket', label: 'Bucket', type: :object, properties: [
            { name: 'id', label: 'Bucket ID', type: :integer },
            { name: 'name', label: 'Bucket Name', type: :string },
            { name: 'type', label: 'Bucket Type', type: :string }
          ]},
          { name: 'creator', label: 'Creator', type: :object, properties: [
            { name: 'id', label: 'Creator ID', type: :integer },
            { name: 'name', label: 'Creator Name', type: :string }
          ]}
        ]
      end
    },
    attachment: {
      fields: lambda do
        [
          { name: 'attachable_sgid', label: 'Attachable SGID', type: :string }
        ]
      end
    }
  }

}