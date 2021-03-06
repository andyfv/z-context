module Main exposing (main)

import Task
import Url exposing (Url)
import Html 
import Browser.Navigation as Nav
import Browser.Events exposing (onResize)
import Browser exposing (UrlRequest, Document)
import Route.Route as Route exposing (Route)
import Page as Page exposing (view, viewNotFound)
import Header as H
--
import Page.Home as Home
import Page.Mindstorms as Mindstorms
import Page.MindstormArticle as MindstormArticle
import Page.Projects as Projects
import Page.ProjectArticle as ProjectArticle
import Page.About as About



-- MAIN

main : Program () Model Msg
main =
    Browser.application
        { init = init 
        , view = view
        , update = update 
        , subscriptions = subscriptions
        , onUrlRequest =  LinkClicked
        , onUrlChange = UrlChanged
        }


type alias Model =
    { route : Route 
    , page : Page
    , navKey : Nav.Key
    , headerModel : H.Model
    }


type Page 
    = NotFoundPage
    | HomePage Home.Model
    | MindstormsPage Mindstorms.Model
    | MindstormArticlePage MindstormArticle.Model
    | ProjectsPage Projects.Model
    | ProjectArticlePage ProjectArticle.Model
    | AboutPage About.Model


type Msg
    = HomeMsg Home.Msg
    | MindstormsMsg Mindstorms.Msg
    | MindstormArticleMsg MindstormArticle.Msg
    | ProjectsMsg Projects.Msg
    | ProjectArticleMsg ProjectArticle.Msg
    | AboutMsg About.Msg

    -- URL    
    | LinkClicked UrlRequest
    | UrlChanged Url

    -- HEADER
    | HeaderMsg H.Msg



-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    onResize  
        (\_ _ -> HeaderMsg H.ViewportChanged )



-- INIT

init : () -> Url -> Nav.Key -> (Model, Cmd Msg)
init flags url navKey =
    let 
        route = Route.fromUrl url
        (headerModel, headerCmds) = H.init
        model =
            { route = route
            , page = NotFoundPage
            , navKey = navKey
            , headerModel = headerModel
            }
    in
    initCurrentPage (model, Cmd.batch [ Cmd.map HeaderMsg headerCmds ])


initCurrentPage : (Model, Cmd Msg) -> (Model, Cmd Msg)
initCurrentPage (model, existingCmds) =
    let 
        (currentPage, mappedPageCmds) = 
            case model.route of
                Route.NotFound ->
                    ( NotFoundPage, Cmd.none )

                Route.Home ->
                    updateWith HomePage HomeMsg Home.init

                Route.Mindstorms ->
                    updateWith MindstormsPage MindstormsMsg Mindstorms.init

                Route.MindstormArticle articleString ->
                    MindstormArticle.init articleString
                    |> updateWith MindstormArticlePage MindstormArticleMsg

                Route.Projects ->
                    updateWith ProjectsPage ProjectsMsg Projects.init

                Route.ProjectsArticle articleString ->
                    ProjectArticle.init articleString
                    |> updateWith ProjectArticlePage ProjectArticleMsg 

                Route.About ->
                    updateWith AboutPage AboutMsg About.init                    
    in
    ( { model | page = currentPage }
    , Cmd.batch [ existingCmds, mappedPageCmds ]
    )


-- VIEW 

view : Model -> Document Msg
view model =
    let 
        viewPage route content =
            let 
                header = Html.map HeaderMsg (H.view route model.headerModel)
                config = 
                    { route = route
                    , content = content
                    , header = header
                    }
            in
            Page.view config
    in
    case model.page of
        NotFoundPage ->
            viewPage Route.NotFound Page.viewNotFound

        HomePage pageModel ->
            Html.map HomeMsg (Home.view pageModel)
            |> viewPage Route.Home 

        MindstormsPage pageModel -> 
            Html.map MindstormsMsg (Mindstorms.view pageModel)
            |> viewPage Route.Mindstorms 

        MindstormArticlePage pageModel ->
            Html.map MindstormArticleMsg (MindstormArticle.view pageModel)
            |> viewPage Route.Mindstorms 

        ProjectsPage pageModel ->
            Html.map ProjectsMsg (Projects.view pageModel)
            |> viewPage Route.Projects

        ProjectArticlePage pageModel ->
            Html.map ProjectArticleMsg (ProjectArticle.view pageModel)
            |> viewPage Route.Projects 

        AboutPage pageModel ->
            Html.map AboutMsg (About.view pageModel) |> viewPage Route.About 


-- UPDATE

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case ( model.page, msg ) of 
        ( HomePage pageModel, HomeMsg subMsg ) ->
            (Home.update subMsg pageModel)
            |> updateWithModel HomePage HomeMsg model

        ( MindstormsPage pageModel, MindstormsMsg subMsg ) ->
            (Mindstorms.update subMsg pageModel)
            |> updateWithModel MindstormsPage MindstormsMsg model

        ( MindstormArticlePage pageModel, MindstormArticleMsg subMsg ) ->
            (MindstormArticle.update subMsg pageModel)
            |> updateWithModel MindstormArticlePage MindstormArticleMsg model            

        ( ProjectsPage pageModel, ProjectsMsg subMsg ) ->
            (Projects.update subMsg pageModel)
            |> updateWithModel ProjectsPage ProjectsMsg model

        ( ProjectArticlePage pageModel, ProjectArticleMsg subMsg ) ->
            (ProjectArticle.update subMsg pageModel)
            |> updateWithModel ProjectArticlePage ProjectArticleMsg model            

        ( AboutPage pageModel, AboutMsg subMsg ) ->
            (About.update subMsg pageModel)
            |> updateWithModel AboutPage AboutMsg model            


        -- HEADER
        ( _ , HeaderMsg subMsg) ->
            let 
                (headerModel, subCmds) = H.update subMsg model.headerModel
            in
            ( { model | headerModel = headerModel }
            , Cmd.map HeaderMsg subCmds)


        -- URL UPDATES
        ( _ , UrlChanged url ) ->
            initCurrentPage 
                ( { model | route = Route.fromUrl url }, Cmd.none)

        ( _ , LinkClicked urlRequest ) ->
            case urlRequest of 
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl model.navKey (Url.toString url)
                    )

                Browser.External url ->
                    ( model, Nav.load url )

        ( _, _ ) -> 
            ( model, Cmd.none )



updateWith : (subModel -> Page) -> (subMsg -> Msg) -> (subModel, Cmd subMsg) -> (Page, Cmd Msg)
updateWith toModel toMsg (subModel, subCmd) =
    (toModel subModel, Cmd.map toMsg subCmd)



updateWithModel : (subModel -> Page) -> (subMsg -> Msg) -> Model -> (subModel, Cmd subMsg) -> (Model, Cmd Msg)
updateWithModel toModel toMsg model (subModel, subCmd) =
    ( { model | page = toModel subModel }
    , Cmd.map toMsg subCmd
    )