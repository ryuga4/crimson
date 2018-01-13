module View exposing (..)

import Html exposing (Html, h2, h3, div, text, ul, li, input, form, button, br, table, tbody, tr, td)
import Html.Attributes exposing (type_, value, placeholder, value)
import Html.Events exposing (onInput, onSubmit, onClick)
import Model exposing (..)
import Regex
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Bootstrap.Button as Button
import MenuView exposing (..)
import GameView exposing (..)

view : Model -> Html Msg
view model =
    case model.state of
        InMenu -> menu model
        InGame -> game model

