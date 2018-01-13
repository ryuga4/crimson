module MenuView exposing (..)

import Html exposing (Html, h2, h3, div, text, ul, li, input, form, button, br, table, tbody, tr, td)
import Html.Attributes exposing (type_, value, placeholder, value)
import Html.Events exposing (onInput, onSubmit, onClick)
import Model exposing (..)
import Regex
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Bootstrap.Button as Button
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row

menu model =
    Grid.container []
    [ input [placeholder "Type room name", onInput UpdateTypedRoomName, value model.typedRoomName] []
    , input [placeholder "Type user name", onInput UpdateTypedUserName] []
    , leaveBtn model
    , rooms model
    ]

leaveBtn model =
    case model.roomName of
        Nothing -> div [] []
        Just name -> button [onClick LeaveRoom] [text <| "Leave room \""++name++"\""]


rooms model =
    let filtered =  model.rooms |> List.filter (\i -> Regex.contains (Regex.regex model.typedRoomName) i.name)
    in if List.isEmpty filtered then
        createRoom model
       else
       div [] (List.map (room model) filtered)

createRoom model =
    div []
    [ h2 [] [text <| "Create room \"" ++ model.typedRoomName ++ "\" and join"]
    , Button.button [Button.primary, Button.attrs [onClick (JoinRoom model.typedRoomName)]] [text "Confirm"]
    ]


room {roomName} room =
    div []
    [ h2 [] [ text <| room.name ++ " - members: " ++ toString room.members ]
    , Button.button [Button.secondary
                    , Button.disabled (roomName /= Nothing)
                    , Button.attrs [onClick (JoinRoom room.name)]] [ text "Join" ]
    ]
