// This file contains your Data Connector logic
section FHIRTerminologyConnector;

client_id = "snapper";
client_secret = "";
token_uri = "https://ontology.nhs.uk/authorisation/auth/realms/nhs-digital-terminology/protocol/openid-connect/token";
redirect_uri = "https://author.ontology.nhs.uk/author/";
authorize_uri = "https://ontology.nhs.uk/authorisation/auth/realms/nhs-digital-terminology/protocol/openid-connect/auth";

// Login modal window dimensions
windowWidth = 720;
windowHeight = 1024;



[DataSource.Kind="FHIRTerminologyConnector", Publish="FHIRTerminologyConnector.Publish"]
shared FHIRTerminologyConnector.Contents = (url as text) =>
    let
        source = Json.Document(Web.Contents(url))
    in
        source; 

// Data Source Kind description
FHIRTerminologyConnector = [
    TestConnection = (dataSourcePath) => { "FHIRTerminologyConnector.Contents", dataSourcePath },
    Authentication = [
        OAuth = [
            StartLogin=StartLogin,
            FinishLogin=FinishLogin
        ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
FHIRTerminologyConnector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = FHIRTerminologyConnector.Icons,
    SourceTypeImage = FHIRTerminologyConnector.Icons
];

// Helper functions for OAuth2: StartLogin, FinishLogin, Refresh, Logout
StartLogin = (resourceUrl, state, display) =>
    let
        authorizeUrl = authorize_uri & "?" & Uri.BuildQueryString([
            response_type = "code",
            client_id = client_id,  
            redirect_uri = redirect_uri,
            state = state
        ])
    in
        [
            LoginUri = authorizeUrl,
            CallbackUri = redirect_uri,
            WindowHeight = 720,
            WindowWidth = 1024,
            Context = null
        ];

FinishLogin = (context, callbackUri, state) =>
    let
        // parse the full callbackUri, and extract the Query string
        parts = Uri.Parts(callbackUri)[Query],
        // if the query string contains an "error" field, raise an error
        // otherwise call TokenMethod to exchange our code for an access_token
        result = if (Record.HasFields(parts, {"error", "error_description"})) then 
                    error Error.Record(parts[error], parts[error_description], parts)
                 else
                    TokenMethod("authorization_code", "code", parts[code])
    in
        result;

TokenMethod = (grantType, tokenField, code) =>
    let
        queryString = [
            grant_type = "authorization_code",
            redirect_uri = redirect_uri,
            client_id = client_id,
            client_secret = client_secret
        ],
        queryWithCode = Record.AddField(queryString, tokenField, code),

        tokenResponse = Web.Contents(token_uri, [
            Content = Text.ToBinary(Uri.BuildQueryString(queryWithCode)),
            Headers = [
                #"Content-type" = "application/x-www-form-urlencoded",
                #"Accept" = "application/json"
            ],
            ManualStatusHandling = {400} 
        ]),
        body = Json.Document(tokenResponse),
        result = if (Record.HasFields(body, {"error", "error_description"})) then 
                    error Error.Record(body[error], body[error_description], body)
                 else
                    body
    in
        result;

Value.IfNull = (a, b) => if a <> null then a else b;

FHIRTerminologyConnector.Icons = [
    Icon16 = { Extension.Contents("FHIRTerminologyConnector16.png"), Extension.Contents("FHIRTerminologyConnector20.png"), Extension.Contents("FHIRTerminologyConnector24.png"), Extension.Contents("FHIRTerminologyConnector32.png") },
    Icon32 = { Extension.Contents("FHIRTerminologyConnector32.png"), Extension.Contents("FHIRTerminologyConnector40.png"), Extension.Contents("FHIRTerminologyConnector48.png"), Extension.Contents("FHIRTerminologyConnector64.png") }
];
