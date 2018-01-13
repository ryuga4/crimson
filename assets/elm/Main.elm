module Main exposing (..)

import Dict
import View exposing (..)
import Update exposing (..)
import Model exposing (..)
import Html exposing (..)

-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }






