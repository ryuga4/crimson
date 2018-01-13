module Update exposing (..)
import Platform.Cmd
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE
import Json.Decode as JD exposing (field)
import Model exposing (..)






userParams : Model -> JE.Value
userParams model =
    JE.object [ ( "user_id", JE.string model.typedUserName ) ]

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        JoinRoom name ->
            let

                channel =
                    Phoenix.Channel.init ("rooms:" ++ name)
                    |> Phoenix.Channel.withPayload (userParams model)

                newSocket =
                    model.phxSocket
                        |> Phoenix.Socket.withDebug
                        |> Phoenix.Socket.on "update" ("rooms:" ++ name) UpdateGame

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.join channel newSocket



            in
                ( { model
                | phxSocket = phxSocket
                , roomName = Just name
                , typedRoomName = ""
                , state = InGame
                }
                , Cmd.map PhoenixMsg phxCmd
                )
        JoinMainChannel ->
                    let
                        channel =
                            Phoenix.Channel.init "main"

                        ( phxSocket, phxCmd ) =
                            Phoenix.Socket.join channel model.phxSocket
                    in
                        ( { model | phxSocket = phxSocket }
                        , Cmd.map PhoenixMsg phxCmd
                        )

        LeaveRoom ->
            case model.roomName of
                Nothing ->
                    ( model, Cmd.none )
                Just name ->
                    let
                        newSocket =
                            model.phxSocket
                            |> Phoenix.Socket.withDebug
                            |> Phoenix.Socket.off "update" ("rooms:" ++ name)

                        ( phxSocket, phxCmd ) =
                            Phoenix.Socket.leave ("rooms:" ++ name) newSocket
                    in
                        ( { model
                        | phxSocket = phxSocket
                        , roomName = Nothing
                        , state = InMenu
                        }
                        , Cmd.map PhoenixMsg phxCmd
                        )


        NoOp ->
            ( model, Cmd.none )

        UpdateRooms raw ->
            case JD.decodeValue roomsDecoder raw of
                Ok {rooms} ->
                    ( { model | rooms = rooms }, Cmd.none )
                Err error ->
                    ( model, Cmd.none )

        UpdateGame raw ->
            case JD.decodeValue gameStateDecoder raw of
                Ok state ->
                    ( { model | gameState = Just state, counter = model.counter + 1 }, Cmd.none )
                Err error ->
                    ( model, Cmd.none )

        UpdateTypedRoomName name ->
                    ( { model | typedRoomName = name }, Cmd.none )
        UpdateTypedUserName name ->
                    ( { model | typedUserName = name }, Cmd.none )





roomsDecoder : JD.Decoder Rooms
roomsDecoder =
    JD.map Rooms
        (field "rooms" (JD.list roomDecoder))

roomDecoder : JD.Decoder Room
roomDecoder =
    JD.map2 Room
        (field "name" JD.string)
        (field "members" JD.int)

gameStateDecoder : JD.Decoder GameState
gameStateDecoder =
    JD.map3 GameState
        (field "name" JD.string)
        (field "map" mapDecoder)
        (field "players" (JD.list playerDecoder))

mapDecoder : JD.Decoder Map
mapDecoder =
    JD.map2 Map
        (field "width" JD.int)
        (field "height" JD.int)

playerDecoder : JD.Decoder Player
playerDecoder =
    JD.map4 Player
        (field "name" JD.string)
        (field "x" JD.float)
        (field "y" JD.float)
        (field "hp" JD.int)



subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.phxSocket PhoenixMsg