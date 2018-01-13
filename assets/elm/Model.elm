module Model exposing (..)

import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Task
import Json.Encode as JE
import Json.Decode as JD exposing (field)
socketServer : String
socketServer =
    "ws://localhost:4000/socket/websocket"



-- MODEL


type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | JoinRoom String
    | JoinMainChannel
    | UpdateGame JE.Value
    | LeaveRoom
    | NoOp
    | UpdateTypedUserName String
    | UpdateTypedRoomName String
    | UpdateRooms JE.Value


type alias Model =
    { newMessage : String
    , messages : List String
    , phxSocket : Phoenix.Socket.Socket Msg
    , state : State
    , rooms : List Room
    , typedRoomName : String
    , roomName : Maybe String
    , typedUserName : String
    , userName : Maybe String
    , gameState : Maybe GameState
    , counter : Int
    }

type alias Room =
    { name : String
    , members : Int
    }
type alias Rooms = {
    rooms : List Room
    }


type alias Player =
    { name : String
    , x : Float
    , y : Float
    , hp : Int
    }

type alias Map =
    { width : Int
    , height : Int
    }

type alias GameState =
    { name : String
    , map : Map
    , players : List Player
    }





type State
    = InGame
    | InMenu

initPhxSocket : Phoenix.Socket.Socket Msg
initPhxSocket =
    Phoenix.Socket.init socketServer
        |> Phoenix.Socket.withDebug
        |> Phoenix.Socket.on "update_rooms" "main" UpdateRooms




initModel : Model
initModel =
    { newMessage    = ""
    , messages      = []
    , phxSocket     = initPhxSocket
    , state         = InMenu
    , rooms         = []
    , typedRoomName = ""
    , roomName      = Nothing
    , userName      = Nothing
    , typedUserName = ""
    , gameState     = Nothing
    , counter       = 0
    }



init : ( Model, Cmd Msg )
init =
    ( initModel, Task.succeed JoinMainChannel |> Task.perform identity )
