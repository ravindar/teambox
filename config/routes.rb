Teambox::Application.routes.draw do

  # If secure_logins is true, constrain matches to ssl requests
  class SSLConstraints
    def self.matches?(request)
      !Teambox.config.secure_logins || request.ssl?
    end
  end

  resources :sites, :only => [:show, :new, :create]

  match '/public' => 'public/projects#index', :as => :public_projects

  namespace :public do
    match ':id' => 'projects#show', :as => :project
    match ':project_id/conversations' => 'conversations#index', :as => :project_conversations
    match ':project_id/conversations/:id' => 'conversations#show', :as => :project_conversation
    match ':project_id/:id' => 'pages#show', :as => :project_page
  end

  match 'api' => 'apidocs#index', :as => :api
  match 'api/concepts' => 'apidocs#concepts', :as => :api_concepts
  match 'api/routes' => 'apidocs#routes', :as => :api_routes
  match 'api/auth' => 'apidocs#auth', :as => :api_auth
  match 'api/changes' => 'apidocs#changes', :as => :api_changes
  match 'api/:model' => 'apidocs#model', :as => :api_model

  resources :sprockets, :only => [:index, :show]

  #Constrain all requests to the ssl constraint
  scope :constraints => SSLConstraints do

    match '/logout' => 'sessions#destroy', :as => :logout
    match '/login' => 'sessions#new', :as => :login
    match '/login/:username' => 'sessions#backdoor', :as => :login_backdoor if Rails.env.cucumber?

    match '/register' => 'users#create', :as => :register
    match '/signup' => 'users#new', :as => :signup

    match '/search' => 'search#index', :as => :search

    match '/guides' => 'guides#index', :as => :guides

    match '/text_styles' => 'users#text_styles', :as => :text_styles
    match '/email_posts_path' => 'users#email_posts', :as => :email_posts
    match '/invite_format' => 'invitations#invite_format', :as => :invite_format
    match '/feeds' => 'users#feeds', :as => :feeds
    match '/calendars' => 'users#calendars', :as => :calendars
    match '/disable_splash' => 'users#disable_splash', :as => :disable_splash
    match '/forgot' => 'reset_passwords#new', :as => :forgot_password
    match '/reset/:reset_code' => 'reset_passwords#reset', :as => :reset_password
    match '/forgetting' => 'reset_passwords#update_after_forgetting', :as => :update_after_forgetting, :method => :put
    match '/reset_password_sent' => 'reset_passwords#sent', :as => :sent_password

    match '/format/:f' => 'sessions#change_format', :as => :change_format

    match '/projects/:project_id/invite/:login' => 'invitations#create', :as => :create_project_invitation, :method => :post

    match '/auth/:provider/callback' => 'auth#callback', :as => :auth_callback
    match '/auth/failure' => 'auth#failure', :as => :auth_failure
    match '/complete_signup' => 'users#complete_signup', :as => :complete_signup
    match '/auth/:provider/unlink' => 'users#unlink_app', :as => :unlink_app

    resources :google_docs do
      get :search, :on => :collection
    end
    
    resources :google_calendars

    #RAILS 3 Useless resource?
    resources :reset_passwords
    resource :session

    resources :organizations do
      member do
        get :projects
        get :external_view
        get :delete
        get :appearance
        put :update_appearance
      end
      resources :memberships do
        member do
          get :change_role
          get :add
          get :remove
        end
      end
      resources :task_list_templates do
        collection do
          put :reorder
        end
      end
    end

    match '/account/settings' => 'users#edit', :as => :account_settings, :sub_action => 'settings'
    match '/account/picture' => 'users#edit', :as => :account_picture, :sub_action => 'picture'
    match '/account/profile' => 'users#edit', :as => :account_profile, :sub_action => 'profile'
    match '/account/linked_accounts' => 'users#edit', :as => :account_linked_accounts, :sub_action => 'linked_accounts'
    match '/account/notifications' => 'users#edit', :as => :account_notifications, :sub_action => 'notifications'
    match '/account/delete' => 'users#edit', :as => :account_delete, :sub_action => 'delete'
    match '/account/destroy' => 'users#destroy', :as => :destroy_user
    match '/account/activity_feed_mode/collapsed' => 'users#change_activities_mode', :as => :collapse_activities, :collapsed => true
    match '/account/activity_feed_mode/expanded' => 'users#change_activities_mode', :as => :expand_activities, :collapsed => false
    match '/account/watch_list' => 'watchers#index', :as => :watch_list
    post  '/account/watch_list/unwatch/:watch_id' => 'watchers#unwatch', :as => :unwatch
    post  '/account/stats/:stat/inc' => 'users#increment_stat'
    post  '/account/badge/:badge/grant' => 'users#grant_badge'
    post  '/account/first_steps/hide' => 'users#hide_first_steps'
    post  '/account/tutorials/hide' => 'users#hide_tutorials'

    resources :teambox_datas, :path => '/datas' do
      member do
        get :download
      end
    end

    resources :users do
      resources :invitations
      member do
        get :confirm_email
        get :unconfirmed_email
        get :contact_importer
      end
      resources :conversations
      resources :task_lists do
        resources :tasks
      end
      match 'activities/users/:id/show_more(.:format)' => 'activities#show_more', :as => :show_more, :method => :get
    end

    match 'activities(.:format)' => 'activities#show', :as => :activities, :method => :get
    match 'activities/:id/show_more(.:format)' => 'activities#show_more', :as => :show_more, :method => :get
    match 'activities/:id/show_thread(.:format)' => 'activities#show_thread', :as => :show_thread, :method => :get

    match 'projects/archived.:format' => 'projects#index', :as => :project_archived, :sub_action => 'archived'

    match 'hooks/:hook_name' => 'hooks#create', :as => :hooks, :via => :post

    resources :projects do
      member do
        post :accept
        post :decline
        put :transfer
        get :join
      end

      match 'time/:year/:month' => 'hours#index', :as => :hours_by_month, :via => :get
      match 'time/by_period' => 'hours#by_period', :as => :hours_by_period, :via => :get
      match 'time' => 'hours#index', :as => :time
      match 'settings' => 'projects#edit', :as => :settings, :sub_action => 'settings'
      match 'picture' => 'projects#edit', :as => :picture, :sub_action => 'picture'
      match 'deletion' => 'projects#edit', :as => :deletion, :sub_action => 'deletion'
      match 'ownership' => 'projects#edit', :as => :ownership, :sub_action => 'ownership'

      resources :invitations do
        member do
          put :accept
          put :decline
          get :resend
        end
      end

      match 'activities(.:format)' => 'activities#show', :as => :activities, :method => :get
      match 'activities/:id/show_more(.:format)' => 'activities#show_more', :as => :show_more, :method => :get
      resources :uploads
      match 'hooks/:hook_name' => 'hooks#create', :as => :hooks, :via => :post

      match 'invite_people' => 'projects#invite_people', :as => :invite_people, :via => :get
      match 'invite_people' => 'projects#send_invites', :as => :send_invites, :via => :post

      resources :tasks do
        member do
          put :reorder
          put :watch
          put :unwatch
        end

        resources :comments
      end

      resources :task_lists do
        collection do
          get :gantt_view
          get :archived
          put :reorder
        end
        member do
          put :archive
          put :unarchive
          put :watch
          put :unwatch
        end

        resources :tasks do
          member do
            put :watch
            put :unwatch
          end

          resources :comments
        end
      end

      match 'contacts' => 'people#contacts', :as => :contacts, :method => :get

      resources :people do
        member do
          get :destroy
        end
      end

      resources :conversations do
        member do
          put :convert_to_task
          put :watch
          put :unwatch
        end

        resources :comments
      end

      resources :pages do
        collection do
          post :resort
        end
        member do
          post :reorder
          put :watch
          put :unwatch
        end
        # In rails 2, we have :pages, :has_many => :task_list ?!
        resources :notes,:dividers,:uploads
      end

      match 'search' => 'search#index', :as => :search

      resources :google_docs do
        collection do
          :search
        end
      end
    end

    namespace :api_v1, :path => 'api/1' do
      resources :projects, :except => [:new, :edit] do
        member do
          put :transfer
        end

        resources :activities, :only => [:index, :show]

        resources :people, :except => [:create, :new, :edit]

        resources :comments, :except => [:new, :create, :edit]

        resources :conversations, :except => [:new, :edit] do
          member do
            put :watch
            put :unwatch
            post :convert_to_task
          end

          resources :comments, :except => [:new, :edit]
        end

        resources :invitations, :except => [:new, :edit, :update] do
          member do
            put :resend
          end
        end

        resources :task_lists, :except => [:new, :edit] do
          member do
            put :archive
            put :unarchive
          end

          resources :tasks, :except => [:new, :edit]
        end

        resources :tasks, :except => [:new, :edit, :create] do
          member do
            put :watch
            put :unwatch
          end

          resources :comments, :except => [:new, :edit]
        end

        resources :uploads, :except => [:new, :edit, :update]

        resources :pages, :except => [:new, :edit] do
          collection do
            put :resort
          end

          member do
            put :reorder
            put :watch
            put :unwatch
          end
        end

        resources :notes, :except => [:new, :edit]

        resources :dividers, :except => [:new, :edit]

        match 'search' => 'search#index', :as => :search
      end

      resources :activities, :only => [:index, :show]

      resources :invitations, :except => [:new, :edit, :update, :create] do
        member do
          put :accept
        end
      end

      resources :users, :only => [:index, :show]

      resources :tasks, :except => [:new, :edit, :create] do
        member do
          put :watch
          put :unwatch
        end
      end

      resources :comments, :except => [:new, :create, :edit]

      resources :conversations, :except => [:new, :edit] do
        member do
          put :watch
          put :unwatch
        end

        resources :comments, :except => [:new, :edit]
      end

      resources :task_lists, :except => [:new, :edit] do
        resources :tasks, :except => [:new, :edit]
      end

      resources :tasks, :except => [:new, :edit, :create] do
        member do
          put :watch
          put :unwatch
        end

        resources :comments, :except => [:new, :edit]
      end

      resources :uploads, :except => [:new, :edit, :update]
      resources :pages, :except => [:new, :edit] do
        collection do
          put :resort
        end
        member do
          put :reorder
          put :watch
          put :unwatch
        end
      end

      resources :notes, :except => [:new, :edit]

      resources :dividers, :except => [:new, :edit]

      resources :organizations, :except => [:new, :edit, :destroy] do
        resources :projects, :except => [:new, :edit] do
          member do
            put :transfer
          end
        end

        resources :memberships, :except => [:new, :edit, :create]
      end
      match 'search' => 'search#index', :as => :search
      match 'account' => 'users#current', :as => :account, :via => :get
    end

    resources :task_lists, :only => [ :index ] do
      collection do
        get :gantt_view
      end
    end

    resources :conversations, :only => [ :create ]

    match 'time/:year/:month' => 'hours#index', :as => :hours_by_month, :via => :get
    match 'time/by_period' => 'hours#by_period', :as => :hours_by_period, :via => :get
    match 'time' => 'hours#index', :as => :time

    match '/my_projects' => 'projects#list', :as => :all_projects

    match 'downloads/:id(/:style)/:filename' => 'uploads#download', :constraints => {:filename => /.*/}, :via => :get

  end

  root :to => 'projects#index'

  if Rails.env.development?
    mount Emailer::Preview => 'mail_view'
  end
  
  if Rails.env.test?
    match '/oauth/dummy_auth' => 'oauth#dummy_auth', :as => :dummy_auth
  end
  
  # Oauth provider
  # Oauth-server
  
  match '/oauth',:controller=>'oauth',:action=>'index', :as => :oauth
  match '/oauth/authorize',:controller=>'oauth',:action=>'authorize', :as => :authorize
  match '/oauth/revoke',:controller=>'oauth',:action=>'revoke', :as => :revoke
  match '/oauth/token',:controller=>'oauth',:action=>'token', :as => :token
  
  resources :oauth_clients do
    collection do
      get :developer
    end
  end
  
  match 'trimmer/:locale/templates.js' => 'trimmer#templates', :as => :trimmer_templates
  match 'trimmer/:locale/translations.js' => 'trimmer#translations', :as => :trimmer_translations
  match 'trimmer/:locale.js' => 'trimmer#resources', :as => :trimmer_resources
end
#== Route Map
# Generated on 07 Jul 2011 17:22
#
#                                    new_site GET    /sites/new(.:format)                                                                      {:controller=>"sites", :action=>"new"}
#                                        site GET    /sites/:id(.:format)                                                                      {:controller=>"sites", :action=>"show"}
#                             public_projects        /public(.:format)                                                                         {:controller=>"public/projects", :action=>"index"}
#                              public_project        /public/:id(.:format)                                                                     {:controller=>"public/projects", :action=>"show"}
#                public_project_conversations        /public/:project_id/conversations(.:format)                                               {:controller=>"public/conversations", :action=>"index"}
#                 public_project_conversation        /public/:project_id/conversations/:id(.:format)                                           {:controller=>"public/conversations", :action=>"show"}
#                         public_project_page        /public/:project_id/:id(.:format)                                                         {:controller=>"public/pages", :action=>"show"}
#                                         api        /api(.:format)                                                                            {:controller=>"apidocs", :action=>"index"}
#                                api_concepts        /api/concepts(.:format)                                                                   {:controller=>"apidocs", :action=>"concepts"}
#                                  api_routes        /api/routes(.:format)                                                                     {:controller=>"apidocs", :action=>"routes"}
#                                    api_auth        /api/auth(.:format)                                                                       {:controller=>"apidocs", :action=>"auth"}
#                                 api_changes        /api/changes(.:format)                                                                    {:controller=>"apidocs", :action=>"changes"}
#                                   api_model        /api/:model(.:format)                                                                     {:controller=>"apidocs", :action=>"model"}
#                                   sprockets GET    /sprockets(.:format)                                                                      {:controller=>"sprockets", :action=>"index"}
#                                    sprocket GET    /sprockets/:id(.:format)                                                                  {:controller=>"sprockets", :action=>"show"}
#                                      logout        /logout(.:format)                                                                         {:controller=>"sessions", :action=>"destroy"}
#                                       login        /login(.:format)                                                                          {:controller=>"sessions", :action=>"new"}
#                                    register        /register(.:format)                                                                       {:controller=>"users", :action=>"create"}
#                                      signup        /signup(.:format)                                                                         {:controller=>"users", :action=>"new"}
#                                      search        /search(.:format)                                                                         {:controller=>"search", :action=>"index"}
#                                      guides        /guides(.:format)                                                                         {:controller=>"guides", :action=>"index"}
#                                 text_styles        /text_styles(.:format)                                                                    {:controller=>"users", :action=>"text_styles"}
#                                 email_posts        /email_posts_path(.:format)                                                               {:controller=>"users", :action=>"email_posts"}
#                               invite_format        /invite_format(.:format)                                                                  {:controller=>"invitations", :action=>"invite_format"}
#                                       feeds        /feeds(.:format)                                                                          {:controller=>"users", :action=>"feeds"}
#                                   calendars        /calendars(.:format)                                                                      {:controller=>"users", :action=>"calendars"}
#                              disable_splash        /disable_splash(.:format)                                                                 {:controller=>"users", :action=>"disable_splash"}
#                             forgot_password        /forgot(.:format)                                                                         {:controller=>"reset_passwords", :action=>"new"}
#                              reset_password        /reset/:reset_code(.:format)                                                              {:controller=>"reset_passwords", :action=>"reset"}
#                     update_after_forgetting        /forgetting(.:format)                                                                     {:method=>:put, :controller=>"reset_passwords", :action=>"update_after_forgetting"}
#                               sent_password        /reset_password_sent(.:format)                                                            {:controller=>"reset_passwords", :action=>"sent"}
#                               change_format        /format/:f(.:format)                                                                      {:controller=>"sessions", :action=>"change_format"}
#                   create_project_invitation        /projects/:project_id/invite/:login(.:format)                                             {:method=>:post, :controller=>"invitations", :action=>"create"}
#                               auth_callback        /auth/:provider/callback(.:format)                                                        {:controller=>"auth", :action=>"callback"}
#                                auth_failure        /auth/failure(.:format)                                                                   {:controller=>"auth", :action=>"failure"}
#                             complete_signup        /complete_signup(.:format)                                                                {:controller=>"users", :action=>"complete_signup"}
#                                  unlink_app        /auth/:provider/unlink(.:format)                                                          {:controller=>"users", :action=>"unlink_app"}
#                          search_google_docs GET    /google_docs/search(.:format)                                                             {:controller=>"google_docs", :action=>"search"}
#                                 google_docs GET    /google_docs(.:format)                                                                    {:controller=>"google_docs", :action=>"index"}
#                                             POST   /google_docs(.:format)                                                                    {:controller=>"google_docs", :action=>"create"}
#                              new_google_doc GET    /google_docs/new(.:format)                                                                {:controller=>"google_docs", :action=>"new"}
#                             edit_google_doc GET    /google_docs/:id/edit(.:format)                                                           {:controller=>"google_docs", :action=>"edit"}
#                                  google_doc GET    /google_docs/:id(.:format)                                                                {:controller=>"google_docs", :action=>"show"}
#                                             PUT    /google_docs/:id(.:format)                                                                {:controller=>"google_docs", :action=>"update"}
#                                             DELETE /google_docs/:id(.:format)                                                                {:controller=>"google_docs", :action=>"destroy"}
#                            google_calendars GET    /google_calendars(.:format)                                                               {:controller=>"google_calendars", :action=>"index"}
#                                             POST   /google_calendars(.:format)                                                               {:controller=>"google_calendars", :action=>"create"}
#                         new_google_calendar GET    /google_calendars/new(.:format)                                                           {:controller=>"google_calendars", :action=>"new"}
#                        edit_google_calendar GET    /google_calendars/:id/edit(.:format)                                                      {:controller=>"google_calendars", :action=>"edit"}
#                             google_calendar GET    /google_calendars/:id(.:format)                                                           {:controller=>"google_calendars", :action=>"show"}
#                                             PUT    /google_calendars/:id(.:format)                                                           {:controller=>"google_calendars", :action=>"update"}
#                                             DELETE /google_calendars/:id(.:format)                                                           {:controller=>"google_calendars", :action=>"destroy"}
#                             reset_passwords GET    /reset_passwords(.:format)                                                                {:controller=>"reset_passwords", :action=>"index"}
#                                             POST   /reset_passwords(.:format)                                                                {:controller=>"reset_passwords", :action=>"create"}
#                          new_reset_password GET    /reset_passwords/new(.:format)                                                            {:controller=>"reset_passwords", :action=>"new"}
#                         edit_reset_password GET    /reset_passwords/:id/edit(.:format)                                                       {:controller=>"reset_passwords", :action=>"edit"}
#                                             GET    /reset_passwords/:id(.:format)                                                            {:controller=>"reset_passwords", :action=>"show"}
#                                             PUT    /reset_passwords/:id(.:format)                                                            {:controller=>"reset_passwords", :action=>"update"}
#                                             DELETE /reset_passwords/:id(.:format)                                                            {:controller=>"reset_passwords", :action=>"destroy"}
#                                     session POST   /session(.:format)                                                                        {:controller=>"sessions", :action=>"create"}
#                                 new_session GET    /session/new(.:format)                                                                    {:controller=>"sessions", :action=>"new"}
#                                edit_session GET    /session/edit(.:format)                                                                   {:controller=>"sessions", :action=>"edit"}
#                                             GET    /session(.:format)                                                                        {:controller=>"sessions", :action=>"show"}
#                                             PUT    /session(.:format)                                                                        {:controller=>"sessions", :action=>"update"}
#                                             DELETE /session(.:format)                                                                        {:controller=>"sessions", :action=>"destroy"}
#                       projects_organization GET    /organizations/:id/projects(.:format)                                                     {:controller=>"organizations", :action=>"projects"}
#                  external_view_organization GET    /organizations/:id/external_view(.:format)                                                {:controller=>"organizations", :action=>"external_view"}
#                         delete_organization GET    /organizations/:id/delete(.:format)                                                       {:controller=>"organizations", :action=>"delete"}
#                     appearance_organization GET    /organizations/:id/appearance(.:format)                                                   {:controller=>"organizations", :action=>"appearance"}
#              update_appearance_organization PUT    /organizations/:id/update_appearance(.:format)                                            {:controller=>"organizations", :action=>"update_appearance"}
#         change_role_organization_membership GET    /organizations/:organization_id/memberships/:id/change_role(.:format)                     {:controller=>"memberships", :action=>"change_role"}
#                 add_organization_membership GET    /organizations/:organization_id/memberships/:id/add(.:format)                             {:controller=>"memberships", :action=>"add"}
#              remove_organization_membership GET    /organizations/:organization_id/memberships/:id/remove(.:format)                          {:controller=>"memberships", :action=>"remove"}
#                    organization_memberships GET    /organizations/:organization_id/memberships(.:format)                                     {:controller=>"memberships", :action=>"index"}
#                                             POST   /organizations/:organization_id/memberships(.:format)                                     {:controller=>"memberships", :action=>"create"}
#                 new_organization_membership GET    /organizations/:organization_id/memberships/new(.:format)                                 {:controller=>"memberships", :action=>"new"}
#                edit_organization_membership GET    /organizations/:organization_id/memberships/:id/edit(.:format)                            {:controller=>"memberships", :action=>"edit"}
#                     organization_membership GET    /organizations/:organization_id/memberships/:id(.:format)                                 {:controller=>"memberships", :action=>"show"}
#                                             PUT    /organizations/:organization_id/memberships/:id(.:format)                                 {:controller=>"memberships", :action=>"update"}
#                                             DELETE /organizations/:organization_id/memberships/:id(.:format)                                 {:controller=>"memberships", :action=>"destroy"}
#    reorder_organization_task_list_templates PUT    /organizations/:organization_id/task_list_templates/reorder(.:format)                     {:controller=>"task_list_templates", :action=>"reorder"}
#            organization_task_list_templates GET    /organizations/:organization_id/task_list_templates(.:format)                             {:controller=>"task_list_templates", :action=>"index"}
#                                             POST   /organizations/:organization_id/task_list_templates(.:format)                             {:controller=>"task_list_templates", :action=>"create"}
#         new_organization_task_list_template GET    /organizations/:organization_id/task_list_templates/new(.:format)                         {:controller=>"task_list_templates", :action=>"new"}
#        edit_organization_task_list_template GET    /organizations/:organization_id/task_list_templates/:id/edit(.:format)                    {:controller=>"task_list_templates", :action=>"edit"}
#             organization_task_list_template GET    /organizations/:organization_id/task_list_templates/:id(.:format)                         {:controller=>"task_list_templates", :action=>"show"}
#                                             PUT    /organizations/:organization_id/task_list_templates/:id(.:format)                         {:controller=>"task_list_templates", :action=>"update"}
#                                             DELETE /organizations/:organization_id/task_list_templates/:id(.:format)                         {:controller=>"task_list_templates", :action=>"destroy"}
#                               organizations GET    /organizations(.:format)                                                                  {:controller=>"organizations", :action=>"index"}
#                                             POST   /organizations(.:format)                                                                  {:controller=>"organizations", :action=>"create"}
#                            new_organization GET    /organizations/new(.:format)                                                              {:controller=>"organizations", :action=>"new"}
#                           edit_organization GET    /organizations/:id/edit(.:format)                                                         {:controller=>"organizations", :action=>"edit"}
#                                organization GET    /organizations/:id(.:format)                                                              {:controller=>"organizations", :action=>"show"}
#                                             PUT    /organizations/:id(.:format)                                                              {:controller=>"organizations", :action=>"update"}
#                                             DELETE /organizations/:id(.:format)                                                              {:controller=>"organizations", :action=>"destroy"}
#                            account_settings        /account/settings(.:format)                                                               {:controller=>"users", :action=>"edit"}
#                             account_picture        /account/picture(.:format)                                                                {:controller=>"users", :action=>"edit"}
#                             account_profile        /account/profile(.:format)                                                                {:controller=>"users", :action=>"edit"}
#                     account_linked_accounts        /account/linked_accounts(.:format)                                                        {:controller=>"users", :action=>"edit"}
#                       account_notifications        /account/notifications(.:format)                                                          {:controller=>"users", :action=>"edit"}
#                              account_delete        /account/delete(.:format)                                                                 {:controller=>"users", :action=>"edit"}
#                                destroy_user        /account/destroy(.:format)                                                                {:controller=>"users", :action=>"destroy"}
#                         collapse_activities        /account/activity_feed_mode/collapsed(.:format)                                           {:controller=>"users", :action=>"change_activities_mode"}
#                           expand_activities        /account/activity_feed_mode/expanded(.:format)                                            {:controller=>"users", :action=>"change_activities_mode"}
#                                  watch_list        /account/watch_list(.:format)                                                             {:controller=>"watchers", :action=>"index"}
#                                     unwatch POST   /account/watch_list/unwatch/:watch_id(.:format)                                           {:controller=>"watchers", :action=>"unwatch"}
#                                             POST   /account/stats/:stat/inc(.:format)                                                        {:controller=>"users", :action=>"increment_stat"}
#                                             POST   /account/badge/:badge/grant(.:format)                                                     {:controller=>"users", :action=>"grant_badge"}
#                    account_first_steps_hide POST   /account/first_steps/hide(.:format)                                                       {:controller=>"users", :action=>"hide_first_steps"}
#                      account_tutorials_hide POST   /account/tutorials/hide(.:format)                                                         {:controller=>"users", :action=>"hide_tutorials"}
#                       download_teambox_data GET    /datas/:id/download(.:format)                                                             {:controller=>"teambox_datas", :action=>"download"}
#                               teambox_datas GET    /datas(.:format)                                                                          {:controller=>"teambox_datas", :action=>"index"}
#                                             POST   /datas(.:format)                                                                          {:controller=>"teambox_datas", :action=>"create"}
#                            new_teambox_data GET    /datas/new(.:format)                                                                      {:controller=>"teambox_datas", :action=>"new"}
#                           edit_teambox_data GET    /datas/:id/edit(.:format)                                                                 {:controller=>"teambox_datas", :action=>"edit"}
#                                teambox_data GET    /datas/:id(.:format)                                                                      {:controller=>"teambox_datas", :action=>"show"}
#                                             PUT    /datas/:id(.:format)                                                                      {:controller=>"teambox_datas", :action=>"update"}
#                                             DELETE /datas/:id(.:format)                                                                      {:controller=>"teambox_datas", :action=>"destroy"}
#                            user_invitations GET    /users/:user_id/invitations(.:format)                                                     {:controller=>"invitations", :action=>"index"}
#                                             POST   /users/:user_id/invitations(.:format)                                                     {:controller=>"invitations", :action=>"create"}
#                         new_user_invitation GET    /users/:user_id/invitations/new(.:format)                                                 {:controller=>"invitations", :action=>"new"}
#                        edit_user_invitation GET    /users/:user_id/invitations/:id/edit(.:format)                                            {:controller=>"invitations", :action=>"edit"}
#                             user_invitation GET    /users/:user_id/invitations/:id(.:format)                                                 {:controller=>"invitations", :action=>"show"}
#                                             PUT    /users/:user_id/invitations/:id(.:format)                                                 {:controller=>"invitations", :action=>"update"}
#                                             DELETE /users/:user_id/invitations/:id(.:format)                                                 {:controller=>"invitations", :action=>"destroy"}
#                          confirm_email_user GET    /users/:id/confirm_email(.:format)                                                        {:controller=>"users", :action=>"confirm_email"}
#                      unconfirmed_email_user GET    /users/:id/unconfirmed_email(.:format)                                                    {:controller=>"users", :action=>"unconfirmed_email"}
#                       contact_importer_user GET    /users/:id/contact_importer(.:format)                                                     {:controller=>"users", :action=>"contact_importer"}
#                          user_conversations GET    /users/:user_id/conversations(.:format)                                                   {:controller=>"conversations", :action=>"index"}
#                                             POST   /users/:user_id/conversations(.:format)                                                   {:controller=>"conversations", :action=>"create"}
#                       new_user_conversation GET    /users/:user_id/conversations/new(.:format)                                               {:controller=>"conversations", :action=>"new"}
#                      edit_user_conversation GET    /users/:user_id/conversations/:id/edit(.:format)                                          {:controller=>"conversations", :action=>"edit"}
#                           user_conversation GET    /users/:user_id/conversations/:id(.:format)                                               {:controller=>"conversations", :action=>"show"}
#                                             PUT    /users/:user_id/conversations/:id(.:format)                                               {:controller=>"conversations", :action=>"update"}
#                                             DELETE /users/:user_id/conversations/:id(.:format)                                               {:controller=>"conversations", :action=>"destroy"}
#                        user_task_list_tasks GET    /users/:user_id/task_lists/:task_list_id/tasks(.:format)                                  {:controller=>"tasks", :action=>"index"}
#                                             POST   /users/:user_id/task_lists/:task_list_id/tasks(.:format)                                  {:controller=>"tasks", :action=>"create"}
#                     new_user_task_list_task GET    /users/:user_id/task_lists/:task_list_id/tasks/new(.:format)                              {:controller=>"tasks", :action=>"new"}
#                    edit_user_task_list_task GET    /users/:user_id/task_lists/:task_list_id/tasks/:id/edit(.:format)                         {:controller=>"tasks", :action=>"edit"}
#                         user_task_list_task GET    /users/:user_id/task_lists/:task_list_id/tasks/:id(.:format)                              {:controller=>"tasks", :action=>"show"}
#                                             PUT    /users/:user_id/task_lists/:task_list_id/tasks/:id(.:format)                              {:controller=>"tasks", :action=>"update"}
#                                             DELETE /users/:user_id/task_lists/:task_list_id/tasks/:id(.:format)                              {:controller=>"tasks", :action=>"destroy"}
#                             user_task_lists GET    /users/:user_id/task_lists(.:format)                                                      {:controller=>"task_lists", :action=>"index"}
#                                             POST   /users/:user_id/task_lists(.:format)                                                      {:controller=>"task_lists", :action=>"create"}
#                          new_user_task_list GET    /users/:user_id/task_lists/new(.:format)                                                  {:controller=>"task_lists", :action=>"new"}
#                         edit_user_task_list GET    /users/:user_id/task_lists/:id/edit(.:format)                                             {:controller=>"task_lists", :action=>"edit"}
#                              user_task_list GET    /users/:user_id/task_lists/:id(.:format)                                                  {:controller=>"task_lists", :action=>"show"}
#                                             PUT    /users/:user_id/task_lists/:id(.:format)                                                  {:controller=>"task_lists", :action=>"update"}
#                                             DELETE /users/:user_id/task_lists/:id(.:format)                                                  {:controller=>"task_lists", :action=>"destroy"}
#                              user_show_more        /users/:user_id/activities/users/:id/show_more(.:format)                                  {:method=>:get, :controller=>"activities", :action=>"show_more"}
#                                       users GET    /users(.:format)                                                                          {:controller=>"users", :action=>"index"}
#                                             POST   /users(.:format)                                                                          {:controller=>"users", :action=>"create"}
#                                    new_user GET    /users/new(.:format)                                                                      {:controller=>"users", :action=>"new"}
#                                   edit_user GET    /users/:id/edit(.:format)                                                                 {:controller=>"users", :action=>"edit"}
#                                        user GET    /users/:id(.:format)                                                                      {:controller=>"users", :action=>"show"}
#                                             PUT    /users/:id(.:format)                                                                      {:controller=>"users", :action=>"update"}
#                                             DELETE /users/:id(.:format)                                                                      {:controller=>"users", :action=>"destroy"}
#                                  activities        /activities(.:format)                                                                     {:method=>:get, :controller=>"activities", :action=>"show"}
#                                   show_more        /activities/:id/show_more(.:format)                                                       {:method=>:get, :controller=>"activities", :action=>"show_more"}
#                                 show_thread        /activities/:id/show_thread(.:format)                                                     {:method=>:get, :controller=>"activities", :action=>"show_thread"}
#                            project_archived        /projects/archived.:format                                                                {:controller=>"projects", :action=>"index"}
#                                       hooks POST   /hooks/:hook_name(.:format)                                                               {:controller=>"hooks", :action=>"create"}
#                              accept_project POST   /projects/:id/accept(.:format)                                                            {:controller=>"projects", :action=>"accept"}
#                             decline_project POST   /projects/:id/decline(.:format)                                                           {:controller=>"projects", :action=>"decline"}
#                            transfer_project PUT    /projects/:id/transfer(.:format)                                                          {:controller=>"projects", :action=>"transfer"}
#                                join_project GET    /projects/:id/join(.:format)                                                              {:controller=>"projects", :action=>"join"}
#                      project_hours_by_month GET    /projects/:project_id/time/:year/:month(.:format)                                         {:controller=>"hours", :action=>"index"}
#                     project_hours_by_period GET    /projects/:project_id/time/by_period(.:format)                                            {:controller=>"hours", :action=>"by_period"}
#                                project_time        /projects/:project_id/time(.:format)                                                      {:controller=>"hours", :action=>"index"}
#                            project_settings        /projects/:project_id/settings(.:format)                                                  {:controller=>"projects", :action=>"edit"}
#                             project_picture        /projects/:project_id/picture(.:format)                                                   {:controller=>"projects", :action=>"edit"}
#                            project_deletion        /projects/:project_id/deletion(.:format)                                                  {:controller=>"projects", :action=>"edit"}
#                           project_ownership        /projects/:project_id/ownership(.:format)                                                 {:controller=>"projects", :action=>"edit"}
#                   accept_project_invitation PUT    /projects/:project_id/invitations/:id/accept(.:format)                                    {:controller=>"invitations", :action=>"accept"}
#                  decline_project_invitation PUT    /projects/:project_id/invitations/:id/decline(.:format)                                   {:controller=>"invitations", :action=>"decline"}
#                   resend_project_invitation GET    /projects/:project_id/invitations/:id/resend(.:format)                                    {:controller=>"invitations", :action=>"resend"}
#                         project_invitations GET    /projects/:project_id/invitations(.:format)                                               {:controller=>"invitations", :action=>"index"}
#                                             POST   /projects/:project_id/invitations(.:format)                                               {:controller=>"invitations", :action=>"create"}
#                      new_project_invitation GET    /projects/:project_id/invitations/new(.:format)                                           {:controller=>"invitations", :action=>"new"}
#                     edit_project_invitation GET    /projects/:project_id/invitations/:id/edit(.:format)                                      {:controller=>"invitations", :action=>"edit"}
#                          project_invitation GET    /projects/:project_id/invitations/:id(.:format)                                           {:controller=>"invitations", :action=>"show"}
#                                             PUT    /projects/:project_id/invitations/:id(.:format)                                           {:controller=>"invitations", :action=>"update"}
#                                             DELETE /projects/:project_id/invitations/:id(.:format)                                           {:controller=>"invitations", :action=>"destroy"}
#                          project_activities        /projects/:project_id/activities(.:format)                                                {:method=>:get, :controller=>"activities", :action=>"show"}
#                           project_show_more        /projects/:project_id/activities/:id/show_more(.:format)                                  {:method=>:get, :controller=>"activities", :action=>"show_more"}
#                             project_uploads GET    /projects/:project_id/uploads(.:format)                                                   {:controller=>"uploads", :action=>"index"}
#                                             POST   /projects/:project_id/uploads(.:format)                                                   {:controller=>"uploads", :action=>"create"}
#                          new_project_upload GET    /projects/:project_id/uploads/new(.:format)                                               {:controller=>"uploads", :action=>"new"}
#                         edit_project_upload GET    /projects/:project_id/uploads/:id/edit(.:format)                                          {:controller=>"uploads", :action=>"edit"}
#                              project_upload GET    /projects/:project_id/uploads/:id(.:format)                                               {:controller=>"uploads", :action=>"show"}
#                                             PUT    /projects/:project_id/uploads/:id(.:format)                                               {:controller=>"uploads", :action=>"update"}
#                                             DELETE /projects/:project_id/uploads/:id(.:format)                                               {:controller=>"uploads", :action=>"destroy"}
#                               project_hooks POST   /projects/:project_id/hooks/:hook_name(.:format)                                          {:controller=>"hooks", :action=>"create"}
#                       project_invite_people GET    /projects/:project_id/invite_people(.:format)                                             {:controller=>"projects", :action=>"invite_people"}
#                        project_send_invites POST   /projects/:project_id/invite_people(.:format)                                             {:controller=>"projects", :action=>"send_invites"}
#                        reorder_project_task PUT    /projects/:project_id/tasks/:id/reorder(.:format)                                         {:controller=>"tasks", :action=>"reorder"}
#                          watch_project_task PUT    /projects/:project_id/tasks/:id/watch(.:format)                                           {:controller=>"tasks", :action=>"watch"}
#                        unwatch_project_task PUT    /projects/:project_id/tasks/:id/unwatch(.:format)                                         {:controller=>"tasks", :action=>"unwatch"}
#                       project_task_comments GET    /projects/:project_id/tasks/:task_id/comments(.:format)                                   {:controller=>"comments", :action=>"index"}
#                                             POST   /projects/:project_id/tasks/:task_id/comments(.:format)                                   {:controller=>"comments", :action=>"create"}
#                    new_project_task_comment GET    /projects/:project_id/tasks/:task_id/comments/new(.:format)                               {:controller=>"comments", :action=>"new"}
#                   edit_project_task_comment GET    /projects/:project_id/tasks/:task_id/comments/:id/edit(.:format)                          {:controller=>"comments", :action=>"edit"}
#                        project_task_comment GET    /projects/:project_id/tasks/:task_id/comments/:id(.:format)                               {:controller=>"comments", :action=>"show"}
#                                             PUT    /projects/:project_id/tasks/:task_id/comments/:id(.:format)                               {:controller=>"comments", :action=>"update"}
#                                             DELETE /projects/:project_id/tasks/:task_id/comments/:id(.:format)                               {:controller=>"comments", :action=>"destroy"}
#                               project_tasks GET    /projects/:project_id/tasks(.:format)                                                     {:controller=>"tasks", :action=>"index"}
#                                             POST   /projects/:project_id/tasks(.:format)                                                     {:controller=>"tasks", :action=>"create"}
#                            new_project_task GET    /projects/:project_id/tasks/new(.:format)                                                 {:controller=>"tasks", :action=>"new"}
#                           edit_project_task GET    /projects/:project_id/tasks/:id/edit(.:format)                                            {:controller=>"tasks", :action=>"edit"}
#                                project_task GET    /projects/:project_id/tasks/:id(.:format)                                                 {:controller=>"tasks", :action=>"show"}
#                                             PUT    /projects/:project_id/tasks/:id(.:format)                                                 {:controller=>"tasks", :action=>"update"}
#                                             DELETE /projects/:project_id/tasks/:id(.:format)                                                 {:controller=>"tasks", :action=>"destroy"}
#               gantt_view_project_task_lists GET    /projects/:project_id/task_lists/gantt_view(.:format)                                     {:controller=>"task_lists", :action=>"gantt_view"}
#                 archived_project_task_lists GET    /projects/:project_id/task_lists/archived(.:format)                                       {:controller=>"task_lists", :action=>"archived"}
#                  reorder_project_task_lists PUT    /projects/:project_id/task_lists/reorder(.:format)                                        {:controller=>"task_lists", :action=>"reorder"}
#                   archive_project_task_list PUT    /projects/:project_id/task_lists/:id/archive(.:format)                                    {:controller=>"task_lists", :action=>"archive"}
#                 unarchive_project_task_list PUT    /projects/:project_id/task_lists/:id/unarchive(.:format)                                  {:controller=>"task_lists", :action=>"unarchive"}
#                     watch_project_task_list PUT    /projects/:project_id/task_lists/:id/watch(.:format)                                      {:controller=>"task_lists", :action=>"watch"}
#                   unwatch_project_task_list PUT    /projects/:project_id/task_lists/:id/unwatch(.:format)                                    {:controller=>"task_lists", :action=>"unwatch"}
#                watch_project_task_list_task PUT    /projects/:project_id/task_lists/:task_list_id/tasks/:id/watch(.:format)                  {:controller=>"tasks", :action=>"watch"}
#              unwatch_project_task_list_task PUT    /projects/:project_id/task_lists/:task_list_id/tasks/:id/unwatch(.:format)                {:controller=>"tasks", :action=>"unwatch"}
#             project_task_list_task_comments GET    /projects/:project_id/task_lists/:task_list_id/tasks/:task_id/comments(.:format)          {:controller=>"comments", :action=>"index"}
#                                             POST   /projects/:project_id/task_lists/:task_list_id/tasks/:task_id/comments(.:format)          {:controller=>"comments", :action=>"create"}
#          new_project_task_list_task_comment GET    /projects/:project_id/task_lists/:task_list_id/tasks/:task_id/comments/new(.:format)      {:controller=>"comments", :action=>"new"}
#         edit_project_task_list_task_comment GET    /projects/:project_id/task_lists/:task_list_id/tasks/:task_id/comments/:id/edit(.:format) {:controller=>"comments", :action=>"edit"}
#              project_task_list_task_comment GET    /projects/:project_id/task_lists/:task_list_id/tasks/:task_id/comments/:id(.:format)      {:controller=>"comments", :action=>"show"}
#                                             PUT    /projects/:project_id/task_lists/:task_list_id/tasks/:task_id/comments/:id(.:format)      {:controller=>"comments", :action=>"update"}
#                                             DELETE /projects/:project_id/task_lists/:task_list_id/tasks/:task_id/comments/:id(.:format)      {:controller=>"comments", :action=>"destroy"}
#                     project_task_list_tasks GET    /projects/:project_id/task_lists/:task_list_id/tasks(.:format)                            {:controller=>"tasks", :action=>"index"}
#                                             POST   /projects/:project_id/task_lists/:task_list_id/tasks(.:format)                            {:controller=>"tasks", :action=>"create"}
#                  new_project_task_list_task GET    /projects/:project_id/task_lists/:task_list_id/tasks/new(.:format)                        {:controller=>"tasks", :action=>"new"}
#                 edit_project_task_list_task GET    /projects/:project_id/task_lists/:task_list_id/tasks/:id/edit(.:format)                   {:controller=>"tasks", :action=>"edit"}
#                      project_task_list_task GET    /projects/:project_id/task_lists/:task_list_id/tasks/:id(.:format)                        {:controller=>"tasks", :action=>"show"}
#                                             PUT    /projects/:project_id/task_lists/:task_list_id/tasks/:id(.:format)                        {:controller=>"tasks", :action=>"update"}
#                                             DELETE /projects/:project_id/task_lists/:task_list_id/tasks/:id(.:format)                        {:controller=>"tasks", :action=>"destroy"}
#                          project_task_lists GET    /projects/:project_id/task_lists(.:format)                                                {:controller=>"task_lists", :action=>"index"}
#                                             POST   /projects/:project_id/task_lists(.:format)                                                {:controller=>"task_lists", :action=>"create"}
#                       new_project_task_list GET    /projects/:project_id/task_lists/new(.:format)                                            {:controller=>"task_lists", :action=>"new"}
#                      edit_project_task_list GET    /projects/:project_id/task_lists/:id/edit(.:format)                                       {:controller=>"task_lists", :action=>"edit"}
#                           project_task_list GET    /projects/:project_id/task_lists/:id(.:format)                                            {:controller=>"task_lists", :action=>"show"}
#                                             PUT    /projects/:project_id/task_lists/:id(.:format)                                            {:controller=>"task_lists", :action=>"update"}
#                                             DELETE /projects/:project_id/task_lists/:id(.:format)                                            {:controller=>"task_lists", :action=>"destroy"}
#                            project_contacts        /projects/:project_id/contacts(.:format)                                                  {:method=>:get, :controller=>"people", :action=>"contacts"}
#                              project_person GET    /projects/:project_id/people/:id(.:format)                                                {:controller=>"people", :action=>"destroy"}
#                              project_people GET    /projects/:project_id/people(.:format)                                                    {:controller=>"people", :action=>"index"}
#                                             POST   /projects/:project_id/people(.:format)                                                    {:controller=>"people", :action=>"create"}
#                          new_project_person GET    /projects/:project_id/people/new(.:format)                                                {:controller=>"people", :action=>"new"}
#                         edit_project_person GET    /projects/:project_id/people/:id/edit(.:format)                                           {:controller=>"people", :action=>"edit"}
#                                             GET    /projects/:project_id/people/:id(.:format)                                                {:controller=>"people", :action=>"show"}
#                                             PUT    /projects/:project_id/people/:id(.:format)                                                {:controller=>"people", :action=>"update"}
#                                             DELETE /projects/:project_id/people/:id(.:format)                                                {:controller=>"people", :action=>"destroy"}
#        convert_to_task_project_conversation PUT    /projects/:project_id/conversations/:id/convert_to_task(.:format)                         {:controller=>"conversations", :action=>"convert_to_task"}
#                  watch_project_conversation PUT    /projects/:project_id/conversations/:id/watch(.:format)                                   {:controller=>"conversations", :action=>"watch"}
#                unwatch_project_conversation PUT    /projects/:project_id/conversations/:id/unwatch(.:format)                                 {:controller=>"conversations", :action=>"unwatch"}
#               project_conversation_comments GET    /projects/:project_id/conversations/:conversation_id/comments(.:format)                   {:controller=>"comments", :action=>"index"}
#                                             POST   /projects/:project_id/conversations/:conversation_id/comments(.:format)                   {:controller=>"comments", :action=>"create"}
#            new_project_conversation_comment GET    /projects/:project_id/conversations/:conversation_id/comments/new(.:format)               {:controller=>"comments", :action=>"new"}
#           edit_project_conversation_comment GET    /projects/:project_id/conversations/:conversation_id/comments/:id/edit(.:format)          {:controller=>"comments", :action=>"edit"}
#                project_conversation_comment GET    /projects/:project_id/conversations/:conversation_id/comments/:id(.:format)               {:controller=>"comments", :action=>"show"}
#                                             PUT    /projects/:project_id/conversations/:conversation_id/comments/:id(.:format)               {:controller=>"comments", :action=>"update"}
#                                             DELETE /projects/:project_id/conversations/:conversation_id/comments/:id(.:format)               {:controller=>"comments", :action=>"destroy"}
#                       project_conversations GET    /projects/:project_id/conversations(.:format)                                             {:controller=>"conversations", :action=>"index"}
#                                             POST   /projects/:project_id/conversations(.:format)                                             {:controller=>"conversations", :action=>"create"}
#                    new_project_conversation GET    /projects/:project_id/conversations/new(.:format)                                         {:controller=>"conversations", :action=>"new"}
#                   edit_project_conversation GET    /projects/:project_id/conversations/:id/edit(.:format)                                    {:controller=>"conversations", :action=>"edit"}
#                        project_conversation GET    /projects/:project_id/conversations/:id(.:format)                                         {:controller=>"conversations", :action=>"show"}
#                                             PUT    /projects/:project_id/conversations/:id(.:format)                                         {:controller=>"conversations", :action=>"update"}
#                                             DELETE /projects/:project_id/conversations/:id(.:format)                                         {:controller=>"conversations", :action=>"destroy"}
#                        resort_project_pages POST   /projects/:project_id/pages/resort(.:format)                                              {:controller=>"pages", :action=>"resort"}
#                        reorder_project_page POST   /projects/:project_id/pages/:id/reorder(.:format)                                         {:controller=>"pages", :action=>"reorder"}
#                          watch_project_page PUT    /projects/:project_id/pages/:id/watch(.:format)                                           {:controller=>"pages", :action=>"watch"}
#                        unwatch_project_page PUT    /projects/:project_id/pages/:id/unwatch(.:format)                                         {:controller=>"pages", :action=>"unwatch"}
#                          project_page_notes GET    /projects/:project_id/pages/:page_id/notes(.:format)                                      {:controller=>"notes", :action=>"index"}
#                                             POST   /projects/:project_id/pages/:page_id/notes(.:format)                                      {:controller=>"notes", :action=>"create"}
#                       new_project_page_note GET    /projects/:project_id/pages/:page_id/notes/new(.:format)                                  {:controller=>"notes", :action=>"new"}
#                      edit_project_page_note GET    /projects/:project_id/pages/:page_id/notes/:id/edit(.:format)                             {:controller=>"notes", :action=>"edit"}
#                           project_page_note GET    /projects/:project_id/pages/:page_id/notes/:id(.:format)                                  {:controller=>"notes", :action=>"show"}
#                                             PUT    /projects/:project_id/pages/:page_id/notes/:id(.:format)                                  {:controller=>"notes", :action=>"update"}
#                                             DELETE /projects/:project_id/pages/:page_id/notes/:id(.:format)                                  {:controller=>"notes", :action=>"destroy"}
#                       project_page_dividers GET    /projects/:project_id/pages/:page_id/dividers(.:format)                                   {:controller=>"dividers", :action=>"index"}
#                                             POST   /projects/:project_id/pages/:page_id/dividers(.:format)                                   {:controller=>"dividers", :action=>"create"}
#                    new_project_page_divider GET    /projects/:project_id/pages/:page_id/dividers/new(.:format)                               {:controller=>"dividers", :action=>"new"}
#                   edit_project_page_divider GET    /projects/:project_id/pages/:page_id/dividers/:id/edit(.:format)                          {:controller=>"dividers", :action=>"edit"}
#                        project_page_divider GET    /projects/:project_id/pages/:page_id/dividers/:id(.:format)                               {:controller=>"dividers", :action=>"show"}
#                                             PUT    /projects/:project_id/pages/:page_id/dividers/:id(.:format)                               {:controller=>"dividers", :action=>"update"}
#                                             DELETE /projects/:project_id/pages/:page_id/dividers/:id(.:format)                               {:controller=>"dividers", :action=>"destroy"}
#                        project_page_uploads GET    /projects/:project_id/pages/:page_id/uploads(.:format)                                    {:controller=>"uploads", :action=>"index"}
#                                             POST   /projects/:project_id/pages/:page_id/uploads(.:format)                                    {:controller=>"uploads", :action=>"create"}
#                     new_project_page_upload GET    /projects/:project_id/pages/:page_id/uploads/new(.:format)                                {:controller=>"uploads", :action=>"new"}
#                    edit_project_page_upload GET    /projects/:project_id/pages/:page_id/uploads/:id/edit(.:format)                           {:controller=>"uploads", :action=>"edit"}
#                         project_page_upload GET    /projects/:project_id/pages/:page_id/uploads/:id(.:format)                                {:controller=>"uploads", :action=>"show"}
#                                             PUT    /projects/:project_id/pages/:page_id/uploads/:id(.:format)                                {:controller=>"uploads", :action=>"update"}
#                                             DELETE /projects/:project_id/pages/:page_id/uploads/:id(.:format)                                {:controller=>"uploads", :action=>"destroy"}
#                               project_pages GET    /projects/:project_id/pages(.:format)                                                     {:controller=>"pages", :action=>"index"}
#                                             POST   /projects/:project_id/pages(.:format)                                                     {:controller=>"pages", :action=>"create"}
#                            new_project_page GET    /projects/:project_id/pages/new(.:format)                                                 {:controller=>"pages", :action=>"new"}
#                           edit_project_page GET    /projects/:project_id/pages/:id/edit(.:format)                                            {:controller=>"pages", :action=>"edit"}
#                                project_page GET    /projects/:project_id/pages/:id(.:format)                                                 {:controller=>"pages", :action=>"show"}
#                                             PUT    /projects/:project_id/pages/:id(.:format)                                                 {:controller=>"pages", :action=>"update"}
#                                             DELETE /projects/:project_id/pages/:id(.:format)                                                 {:controller=>"pages", :action=>"destroy"}
#                              project_search        /projects/:project_id/search(.:format)                                                    {:controller=>"search", :action=>"index"}
#                         project_google_docs GET    /projects/:project_id/google_docs(.:format)                                               {:controller=>"google_docs", :action=>"index"}
#                                             POST   /projects/:project_id/google_docs(.:format)                                               {:controller=>"google_docs", :action=>"create"}
#                      new_project_google_doc GET    /projects/:project_id/google_docs/new(.:format)                                           {:controller=>"google_docs", :action=>"new"}
#                     edit_project_google_doc GET    /projects/:project_id/google_docs/:id/edit(.:format)                                      {:controller=>"google_docs", :action=>"edit"}
#                          project_google_doc GET    /projects/:project_id/google_docs/:id(.:format)                                           {:controller=>"google_docs", :action=>"show"}
#                                             PUT    /projects/:project_id/google_docs/:id(.:format)                                           {:controller=>"google_docs", :action=>"update"}
#                                             DELETE /projects/:project_id/google_docs/:id(.:format)                                           {:controller=>"google_docs", :action=>"destroy"}
#                                    projects GET    /projects(.:format)                                                                       {:controller=>"projects", :action=>"index"}
#                                             POST   /projects(.:format)                                                                       {:controller=>"projects", :action=>"create"}
#                                 new_project GET    /projects/new(.:format)                                                                   {:controller=>"projects", :action=>"new"}
#                                edit_project GET    /projects/:id/edit(.:format)                                                              {:controller=>"projects", :action=>"edit"}
#                                     project GET    /projects/:id(.:format)                                                                   {:controller=>"projects", :action=>"show"}
#                                             PUT    /projects/:id(.:format)                                                                   {:controller=>"projects", :action=>"update"}
#                                             DELETE /projects/:id(.:format)                                                                   {:controller=>"projects", :action=>"destroy"}
#                     transfer_api_v1_project PUT    /api/1/projects/:id/transfer(.:format)                                                    {:controller=>"api_v1/projects", :action=>"transfer"}
#                   api_v1_project_activities GET    /api/1/projects/:project_id/activities(.:format)                                          {:controller=>"api_v1/activities", :action=>"index"}
#                     api_v1_project_activity GET    /api/1/projects/:project_id/activities/:id(.:format)                                      {:controller=>"api_v1/activities", :action=>"show"}
#                       api_v1_project_people GET    /api/1/projects/:project_id/people(.:format)                                              {:controller=>"api_v1/people", :action=>"index"}
#                       api_v1_project_person GET    /api/1/projects/:project_id/people/:id(.:format)                                          {:controller=>"api_v1/people", :action=>"show"}
#                                             PUT    /api/1/projects/:project_id/people/:id(.:format)                                          {:controller=>"api_v1/people", :action=>"update"}
#                                             DELETE /api/1/projects/:project_id/people/:id(.:format)                                          {:controller=>"api_v1/people", :action=>"destroy"}
#                     api_v1_project_comments GET    /api/1/projects/:project_id/comments(.:format)                                            {:controller=>"api_v1/comments", :action=>"index"}
#                      api_v1_project_comment GET    /api/1/projects/:project_id/comments/:id(.:format)                                        {:controller=>"api_v1/comments", :action=>"show"}
#                                             PUT    /api/1/projects/:project_id/comments/:id(.:format)                                        {:controller=>"api_v1/comments", :action=>"update"}
#                                             DELETE /api/1/projects/:project_id/comments/:id(.:format)                                        {:controller=>"api_v1/comments", :action=>"destroy"}
#           watch_api_v1_project_conversation PUT    /api/1/projects/:project_id/conversations/:id/watch(.:format)                             {:controller=>"api_v1/conversations", :action=>"watch"}
#         unwatch_api_v1_project_conversation PUT    /api/1/projects/:project_id/conversations/:id/unwatch(.:format)                           {:controller=>"api_v1/conversations", :action=>"unwatch"}
# convert_to_task_api_v1_project_conversation POST   /api/1/projects/:project_id/conversations/:id/convert_to_task(.:format)                   {:controller=>"api_v1/conversations", :action=>"convert_to_task"}
#        api_v1_project_conversation_comments GET    /api/1/projects/:project_id/conversations/:conversation_id/comments(.:format)             {:controller=>"api_v1/comments", :action=>"index"}
#                                             POST   /api/1/projects/:project_id/conversations/:conversation_id/comments(.:format)             {:controller=>"api_v1/comments", :action=>"create"}
#         api_v1_project_conversation_comment GET    /api/1/projects/:project_id/conversations/:conversation_id/comments/:id(.:format)         {:controller=>"api_v1/comments", :action=>"show"}
#                                             PUT    /api/1/projects/:project_id/conversations/:conversation_id/comments/:id(.:format)         {:controller=>"api_v1/comments", :action=>"update"}
#                                             DELETE /api/1/projects/:project_id/conversations/:conversation_id/comments/:id(.:format)         {:controller=>"api_v1/comments", :action=>"destroy"}
#                api_v1_project_conversations GET    /api/1/projects/:project_id/conversations(.:format)                                       {:controller=>"api_v1/conversations", :action=>"index"}
#                                             POST   /api/1/projects/:project_id/conversations(.:format)                                       {:controller=>"api_v1/conversations", :action=>"create"}
#                 api_v1_project_conversation GET    /api/1/projects/:project_id/conversations/:id(.:format)                                   {:controller=>"api_v1/conversations", :action=>"show"}
#                                             PUT    /api/1/projects/:project_id/conversations/:id(.:format)                                   {:controller=>"api_v1/conversations", :action=>"update"}
#                                             DELETE /api/1/projects/:project_id/conversations/:id(.:format)                                   {:controller=>"api_v1/conversations", :action=>"destroy"}
#            resend_api_v1_project_invitation PUT    /api/1/projects/:project_id/invitations/:id/resend(.:format)                              {:controller=>"api_v1/invitations", :action=>"resend"}
#                  api_v1_project_invitations GET    /api/1/projects/:project_id/invitations(.:format)                                         {:controller=>"api_v1/invitations", :action=>"index"}
#                                             POST   /api/1/projects/:project_id/invitations(.:format)                                         {:controller=>"api_v1/invitations", :action=>"create"}
#                   api_v1_project_invitation GET    /api/1/projects/:project_id/invitations/:id(.:format)                                     {:controller=>"api_v1/invitations", :action=>"show"}
#                                             DELETE /api/1/projects/:project_id/invitations/:id(.:format)                                     {:controller=>"api_v1/invitations", :action=>"destroy"}
#            archive_api_v1_project_task_list PUT    /api/1/projects/:project_id/task_lists/:id/archive(.:format)                              {:controller=>"api_v1/task_lists", :action=>"archive"}
#          unarchive_api_v1_project_task_list PUT    /api/1/projects/:project_id/task_lists/:id/unarchive(.:format)                            {:controller=>"api_v1/task_lists", :action=>"unarchive"}
#              api_v1_project_task_list_tasks GET    /api/1/projects/:project_id/task_lists/:task_list_id/tasks(.:format)                      {:controller=>"api_v1/tasks", :action=>"index"}
#                                             POST   /api/1/projects/:project_id/task_lists/:task_list_id/tasks(.:format)                      {:controller=>"api_v1/tasks", :action=>"create"}
#               api_v1_project_task_list_task GET    /api/1/projects/:project_id/task_lists/:task_list_id/tasks/:id(.:format)                  {:controller=>"api_v1/tasks", :action=>"show"}
#                                             PUT    /api/1/projects/:project_id/task_lists/:task_list_id/tasks/:id(.:format)                  {:controller=>"api_v1/tasks", :action=>"update"}
#                                             DELETE /api/1/projects/:project_id/task_lists/:task_list_id/tasks/:id(.:format)                  {:controller=>"api_v1/tasks", :action=>"destroy"}
#                   api_v1_project_task_lists GET    /api/1/projects/:project_id/task_lists(.:format)                                          {:controller=>"api_v1/task_lists", :action=>"index"}
#                                             POST   /api/1/projects/:project_id/task_lists(.:format)                                          {:controller=>"api_v1/task_lists", :action=>"create"}
#                    api_v1_project_task_list GET    /api/1/projects/:project_id/task_lists/:id(.:format)                                      {:controller=>"api_v1/task_lists", :action=>"show"}
#                                             PUT    /api/1/projects/:project_id/task_lists/:id(.:format)                                      {:controller=>"api_v1/task_lists", :action=>"update"}
#                                             DELETE /api/1/projects/:project_id/task_lists/:id(.:format)                                      {:controller=>"api_v1/task_lists", :action=>"destroy"}
#                   watch_api_v1_project_task PUT    /api/1/projects/:project_id/tasks/:id/watch(.:format)                                     {:controller=>"api_v1/tasks", :action=>"watch"}
#                 unwatch_api_v1_project_task PUT    /api/1/projects/:project_id/tasks/:id/unwatch(.:format)                                   {:controller=>"api_v1/tasks", :action=>"unwatch"}
#                api_v1_project_task_comments GET    /api/1/projects/:project_id/tasks/:task_id/comments(.:format)                             {:controller=>"api_v1/comments", :action=>"index"}
#                                             POST   /api/1/projects/:project_id/tasks/:task_id/comments(.:format)                             {:controller=>"api_v1/comments", :action=>"create"}
#                 api_v1_project_task_comment GET    /api/1/projects/:project_id/tasks/:task_id/comments/:id(.:format)                         {:controller=>"api_v1/comments", :action=>"show"}
#                                             PUT    /api/1/projects/:project_id/tasks/:task_id/comments/:id(.:format)                         {:controller=>"api_v1/comments", :action=>"update"}
#                                             DELETE /api/1/projects/:project_id/tasks/:task_id/comments/:id(.:format)                         {:controller=>"api_v1/comments", :action=>"destroy"}
#                        api_v1_project_tasks GET    /api/1/projects/:project_id/tasks(.:format)                                               {:controller=>"api_v1/tasks", :action=>"index"}
#                         api_v1_project_task GET    /api/1/projects/:project_id/tasks/:id(.:format)                                           {:controller=>"api_v1/tasks", :action=>"show"}
#                                             PUT    /api/1/projects/:project_id/tasks/:id(.:format)                                           {:controller=>"api_v1/tasks", :action=>"update"}
#                                             DELETE /api/1/projects/:project_id/tasks/:id(.:format)                                           {:controller=>"api_v1/tasks", :action=>"destroy"}
#                      api_v1_project_uploads GET    /api/1/projects/:project_id/uploads(.:format)                                             {:controller=>"api_v1/uploads", :action=>"index"}
#                                             POST   /api/1/projects/:project_id/uploads(.:format)                                             {:controller=>"api_v1/uploads", :action=>"create"}
#                       api_v1_project_upload GET    /api/1/projects/:project_id/uploads/:id(.:format)                                         {:controller=>"api_v1/uploads", :action=>"show"}
#                                             DELETE /api/1/projects/:project_id/uploads/:id(.:format)                                         {:controller=>"api_v1/uploads", :action=>"destroy"}
#                 resort_api_v1_project_pages PUT    /api/1/projects/:project_id/pages/resort(.:format)                                        {:controller=>"api_v1/pages", :action=>"resort"}
#                 reorder_api_v1_project_page PUT    /api/1/projects/:project_id/pages/:id/reorder(.:format)                                   {:controller=>"api_v1/pages", :action=>"reorder"}
#                   watch_api_v1_project_page PUT    /api/1/projects/:project_id/pages/:id/watch(.:format)                                     {:controller=>"api_v1/pages", :action=>"watch"}
#                 unwatch_api_v1_project_page PUT    /api/1/projects/:project_id/pages/:id/unwatch(.:format)                                   {:controller=>"api_v1/pages", :action=>"unwatch"}
#                        api_v1_project_pages GET    /api/1/projects/:project_id/pages(.:format)                                               {:controller=>"api_v1/pages", :action=>"index"}
#                                             POST   /api/1/projects/:project_id/pages(.:format)                                               {:controller=>"api_v1/pages", :action=>"create"}
#                         api_v1_project_page GET    /api/1/projects/:project_id/pages/:id(.:format)                                           {:controller=>"api_v1/pages", :action=>"show"}
#                                             PUT    /api/1/projects/:project_id/pages/:id(.:format)                                           {:controller=>"api_v1/pages", :action=>"update"}
#                                             DELETE /api/1/projects/:project_id/pages/:id(.:format)                                           {:controller=>"api_v1/pages", :action=>"destroy"}
#                        api_v1_project_notes GET    /api/1/projects/:project_id/notes(.:format)                                               {:controller=>"api_v1/notes", :action=>"index"}
#                                             POST   /api/1/projects/:project_id/notes(.:format)                                               {:controller=>"api_v1/notes", :action=>"create"}
#                         api_v1_project_note GET    /api/1/projects/:project_id/notes/:id(.:format)                                           {:controller=>"api_v1/notes", :action=>"show"}
#                                             PUT    /api/1/projects/:project_id/notes/:id(.:format)                                           {:controller=>"api_v1/notes", :action=>"update"}
#                                             DELETE /api/1/projects/:project_id/notes/:id(.:format)                                           {:controller=>"api_v1/notes", :action=>"destroy"}
#                     api_v1_project_dividers GET    /api/1/projects/:project_id/dividers(.:format)                                            {:controller=>"api_v1/dividers", :action=>"index"}
#                                             POST   /api/1/projects/:project_id/dividers(.:format)                                            {:controller=>"api_v1/dividers", :action=>"create"}
#                      api_v1_project_divider GET    /api/1/projects/:project_id/dividers/:id(.:format)                                        {:controller=>"api_v1/dividers", :action=>"show"}
#                                             PUT    /api/1/projects/:project_id/dividers/:id(.:format)                                        {:controller=>"api_v1/dividers", :action=>"update"}
#                                             DELETE /api/1/projects/:project_id/dividers/:id(.:format)                                        {:controller=>"api_v1/dividers", :action=>"destroy"}
#                       api_v1_project_search        /api/1/projects/:project_id/search(.:format)                                              {:controller=>"api_v1/search", :action=>"index"}
#                             api_v1_projects GET    /api/1/projects(.:format)                                                                 {:controller=>"api_v1/projects", :action=>"index"}
#                                             POST   /api/1/projects(.:format)                                                                 {:controller=>"api_v1/projects", :action=>"create"}
#                              api_v1_project GET    /api/1/projects/:id(.:format)                                                             {:controller=>"api_v1/projects", :action=>"show"}
#                                             PUT    /api/1/projects/:id(.:format)                                                             {:controller=>"api_v1/projects", :action=>"update"}
#                                             DELETE /api/1/projects/:id(.:format)                                                             {:controller=>"api_v1/projects", :action=>"destroy"}
#                           api_v1_activities GET    /api/1/activities(.:format)                                                               {:controller=>"api_v1/activities", :action=>"index"}
#                             api_v1_activity GET    /api/1/activities/:id(.:format)                                                           {:controller=>"api_v1/activities", :action=>"show"}
#                    accept_api_v1_invitation PUT    /api/1/invitations/:id/accept(.:format)                                                   {:controller=>"api_v1/invitations", :action=>"accept"}
#                          api_v1_invitations GET    /api/1/invitations(.:format)                                                              {:controller=>"api_v1/invitations", :action=>"index"}
#                           api_v1_invitation GET    /api/1/invitations/:id(.:format)                                                          {:controller=>"api_v1/invitations", :action=>"show"}
#                                             DELETE /api/1/invitations/:id(.:format)                                                          {:controller=>"api_v1/invitations", :action=>"destroy"}
#                                api_v1_users GET    /api/1/users(.:format)                                                                    {:controller=>"api_v1/users", :action=>"index"}
#                                 api_v1_user GET    /api/1/users/:id(.:format)                                                                {:controller=>"api_v1/users", :action=>"show"}
#                           watch_api_v1_task PUT    /api/1/tasks/:id/watch(.:format)                                                          {:controller=>"api_v1/tasks", :action=>"watch"}
#                         unwatch_api_v1_task PUT    /api/1/tasks/:id/unwatch(.:format)                                                        {:controller=>"api_v1/tasks", :action=>"unwatch"}
#                                api_v1_tasks GET    /api/1/tasks(.:format)                                                                    {:controller=>"api_v1/tasks", :action=>"index"}
#                                 api_v1_task GET    /api/1/tasks/:id(.:format)                                                                {:controller=>"api_v1/tasks", :action=>"show"}
#                                             PUT    /api/1/tasks/:id(.:format)                                                                {:controller=>"api_v1/tasks", :action=>"update"}
#                                             DELETE /api/1/tasks/:id(.:format)                                                                {:controller=>"api_v1/tasks", :action=>"destroy"}
#                             api_v1_comments GET    /api/1/comments(.:format)                                                                 {:controller=>"api_v1/comments", :action=>"index"}
#                              api_v1_comment GET    /api/1/comments/:id(.:format)                                                             {:controller=>"api_v1/comments", :action=>"show"}
#                                             PUT    /api/1/comments/:id(.:format)                                                             {:controller=>"api_v1/comments", :action=>"update"}
#                                             DELETE /api/1/comments/:id(.:format)                                                             {:controller=>"api_v1/comments", :action=>"destroy"}
#                   watch_api_v1_conversation PUT    /api/1/conversations/:id/watch(.:format)                                                  {:controller=>"api_v1/conversations", :action=>"watch"}
#                 unwatch_api_v1_conversation PUT    /api/1/conversations/:id/unwatch(.:format)                                                {:controller=>"api_v1/conversations", :action=>"unwatch"}
#                api_v1_conversation_comments GET    /api/1/conversations/:conversation_id/comments(.:format)                                  {:controller=>"api_v1/comments", :action=>"index"}
#                                             POST   /api/1/conversations/:conversation_id/comments(.:format)                                  {:controller=>"api_v1/comments", :action=>"create"}
#                 api_v1_conversation_comment GET    /api/1/conversations/:conversation_id/comments/:id(.:format)                              {:controller=>"api_v1/comments", :action=>"show"}
#                                             PUT    /api/1/conversations/:conversation_id/comments/:id(.:format)                              {:controller=>"api_v1/comments", :action=>"update"}
#                                             DELETE /api/1/conversations/:conversation_id/comments/:id(.:format)                              {:controller=>"api_v1/comments", :action=>"destroy"}
#                        api_v1_conversations GET    /api/1/conversations(.:format)                                                            {:controller=>"api_v1/conversations", :action=>"index"}
#                                             POST   /api/1/conversations(.:format)                                                            {:controller=>"api_v1/conversations", :action=>"create"}
#                         api_v1_conversation GET    /api/1/conversations/:id(.:format)                                                        {:controller=>"api_v1/conversations", :action=>"show"}
#                                             PUT    /api/1/conversations/:id(.:format)                                                        {:controller=>"api_v1/conversations", :action=>"update"}
#                                             DELETE /api/1/conversations/:id(.:format)                                                        {:controller=>"api_v1/conversations", :action=>"destroy"}
#                      api_v1_task_list_tasks GET    /api/1/task_lists/:task_list_id/tasks(.:format)                                           {:controller=>"api_v1/tasks", :action=>"index"}
#                                             POST   /api/1/task_lists/:task_list_id/tasks(.:format)                                           {:controller=>"api_v1/tasks", :action=>"create"}
#                       api_v1_task_list_task GET    /api/1/task_lists/:task_list_id/tasks/:id(.:format)                                       {:controller=>"api_v1/tasks", :action=>"show"}
#                                             PUT    /api/1/task_lists/:task_list_id/tasks/:id(.:format)                                       {:controller=>"api_v1/tasks", :action=>"update"}
#                                             DELETE /api/1/task_lists/:task_list_id/tasks/:id(.:format)                                       {:controller=>"api_v1/tasks", :action=>"destroy"}
#                           api_v1_task_lists GET    /api/1/task_lists(.:format)                                                               {:controller=>"api_v1/task_lists", :action=>"index"}
#                                             POST   /api/1/task_lists(.:format)                                                               {:controller=>"api_v1/task_lists", :action=>"create"}
#                            api_v1_task_list GET    /api/1/task_lists/:id(.:format)                                                           {:controller=>"api_v1/task_lists", :action=>"show"}
#                                             PUT    /api/1/task_lists/:id(.:format)                                                           {:controller=>"api_v1/task_lists", :action=>"update"}
#                                             DELETE /api/1/task_lists/:id(.:format)                                                           {:controller=>"api_v1/task_lists", :action=>"destroy"}
#                                             PUT    /api/1/tasks/:id/watch(.:format)                                                          {:controller=>"api_v1/tasks", :action=>"watch"}
#                                             PUT    /api/1/tasks/:id/unwatch(.:format)                                                        {:controller=>"api_v1/tasks", :action=>"unwatch"}
#                        api_v1_task_comments GET    /api/1/tasks/:task_id/comments(.:format)                                                  {:controller=>"api_v1/comments", :action=>"index"}
#                                             POST   /api/1/tasks/:task_id/comments(.:format)                                                  {:controller=>"api_v1/comments", :action=>"create"}
#                         api_v1_task_comment GET    /api/1/tasks/:task_id/comments/:id(.:format)                                              {:controller=>"api_v1/comments", :action=>"show"}
#                                             PUT    /api/1/tasks/:task_id/comments/:id(.:format)                                              {:controller=>"api_v1/comments", :action=>"update"}
#                                             DELETE /api/1/tasks/:task_id/comments/:id(.:format)                                              {:controller=>"api_v1/comments", :action=>"destroy"}
#                                             GET    /api/1/tasks(.:format)                                                                    {:controller=>"api_v1/tasks", :action=>"index"}
#                                             GET    /api/1/tasks/:id(.:format)                                                                {:controller=>"api_v1/tasks", :action=>"show"}
#                                             PUT    /api/1/tasks/:id(.:format)                                                                {:controller=>"api_v1/tasks", :action=>"update"}
#                                             DELETE /api/1/tasks/:id(.:format)                                                                {:controller=>"api_v1/tasks", :action=>"destroy"}
#                              api_v1_uploads GET    /api/1/uploads(.:format)                                                                  {:controller=>"api_v1/uploads", :action=>"index"}
#                                             POST   /api/1/uploads(.:format)                                                                  {:controller=>"api_v1/uploads", :action=>"create"}
#                               api_v1_upload GET    /api/1/uploads/:id(.:format)                                                              {:controller=>"api_v1/uploads", :action=>"show"}
#                                             DELETE /api/1/uploads/:id(.:format)                                                              {:controller=>"api_v1/uploads", :action=>"destroy"}
#                         resort_api_v1_pages PUT    /api/1/pages/resort(.:format)                                                             {:controller=>"api_v1/pages", :action=>"resort"}
#                         reorder_api_v1_page PUT    /api/1/pages/:id/reorder(.:format)                                                        {:controller=>"api_v1/pages", :action=>"reorder"}
#                           watch_api_v1_page PUT    /api/1/pages/:id/watch(.:format)                                                          {:controller=>"api_v1/pages", :action=>"watch"}
#                         unwatch_api_v1_page PUT    /api/1/pages/:id/unwatch(.:format)                                                        {:controller=>"api_v1/pages", :action=>"unwatch"}
#                                api_v1_pages GET    /api/1/pages(.:format)                                                                    {:controller=>"api_v1/pages", :action=>"index"}
#                                             POST   /api/1/pages(.:format)                                                                    {:controller=>"api_v1/pages", :action=>"create"}
#                                 api_v1_page GET    /api/1/pages/:id(.:format)                                                                {:controller=>"api_v1/pages", :action=>"show"}
#                                             PUT    /api/1/pages/:id(.:format)                                                                {:controller=>"api_v1/pages", :action=>"update"}
#                                             DELETE /api/1/pages/:id(.:format)                                                                {:controller=>"api_v1/pages", :action=>"destroy"}
#                                api_v1_notes GET    /api/1/notes(.:format)                                                                    {:controller=>"api_v1/notes", :action=>"index"}
#                                             POST   /api/1/notes(.:format)                                                                    {:controller=>"api_v1/notes", :action=>"create"}
#                                 api_v1_note GET    /api/1/notes/:id(.:format)                                                                {:controller=>"api_v1/notes", :action=>"show"}
#                                             PUT    /api/1/notes/:id(.:format)                                                                {:controller=>"api_v1/notes", :action=>"update"}
#                                             DELETE /api/1/notes/:id(.:format)                                                                {:controller=>"api_v1/notes", :action=>"destroy"}
#                             api_v1_dividers GET    /api/1/dividers(.:format)                                                                 {:controller=>"api_v1/dividers", :action=>"index"}
#                                             POST   /api/1/dividers(.:format)                                                                 {:controller=>"api_v1/dividers", :action=>"create"}
#                              api_v1_divider GET    /api/1/dividers/:id(.:format)                                                             {:controller=>"api_v1/dividers", :action=>"show"}
#                                             PUT    /api/1/dividers/:id(.:format)                                                             {:controller=>"api_v1/dividers", :action=>"update"}
#                                             DELETE /api/1/dividers/:id(.:format)                                                             {:controller=>"api_v1/dividers", :action=>"destroy"}
#        transfer_api_v1_organization_project PUT    /api/1/organizations/:organization_id/projects/:id/transfer(.:format)                     {:controller=>"api_v1/projects", :action=>"transfer"}
#                api_v1_organization_projects GET    /api/1/organizations/:organization_id/projects(.:format)                                  {:controller=>"api_v1/projects", :action=>"index"}
#                                             POST   /api/1/organizations/:organization_id/projects(.:format)                                  {:controller=>"api_v1/projects", :action=>"create"}
#                 api_v1_organization_project GET    /api/1/organizations/:organization_id/projects/:id(.:format)                              {:controller=>"api_v1/projects", :action=>"show"}
#                                             PUT    /api/1/organizations/:organization_id/projects/:id(.:format)                              {:controller=>"api_v1/projects", :action=>"update"}
#                                             DELETE /api/1/organizations/:organization_id/projects/:id(.:format)                              {:controller=>"api_v1/projects", :action=>"destroy"}
#             api_v1_organization_memberships GET    /api/1/organizations/:organization_id/memberships(.:format)                               {:controller=>"api_v1/memberships", :action=>"index"}
#              api_v1_organization_membership GET    /api/1/organizations/:organization_id/memberships/:id(.:format)                           {:controller=>"api_v1/memberships", :action=>"show"}
#                                             PUT    /api/1/organizations/:organization_id/memberships/:id(.:format)                           {:controller=>"api_v1/memberships", :action=>"update"}
#                                             DELETE /api/1/organizations/:organization_id/memberships/:id(.:format)                           {:controller=>"api_v1/memberships", :action=>"destroy"}
#                        api_v1_organizations GET    /api/1/organizations(.:format)                                                            {:controller=>"api_v1/organizations", :action=>"index"}
#                                             POST   /api/1/organizations(.:format)                                                            {:controller=>"api_v1/organizations", :action=>"create"}
#                         api_v1_organization GET    /api/1/organizations/:id(.:format)                                                        {:controller=>"api_v1/organizations", :action=>"show"}
#                                             PUT    /api/1/organizations/:id(.:format)                                                        {:controller=>"api_v1/organizations", :action=>"update"}
#                               api_v1_search        /api/1/search(.:format)                                                                   {:controller=>"api_v1/search", :action=>"index"}
#                              api_v1_account GET    /api/1/account(.:format)                                                                  {:controller=>"api_v1/users", :action=>"current"}
#                       gantt_view_task_lists GET    /task_lists/gantt_view(.:format)                                                          {:controller=>"task_lists", :action=>"gantt_view"}
#                                  task_lists GET    /task_lists(.:format)                                                                     {:controller=>"task_lists", :action=>"index"}
#                               conversations POST   /conversations(.:format)                                                                  {:controller=>"conversations", :action=>"create"}
#                              hours_by_month GET    /time/:year/:month(.:format)                                                              {:controller=>"hours", :action=>"index"}
#                             hours_by_period GET    /time/by_period(.:format)                                                                 {:controller=>"hours", :action=>"by_period"}
#                                        time        /time(.:format)                                                                           {:controller=>"hours", :action=>"index"}
#                                all_projects        /my_projects(.:format)                                                                    {:controller=>"projects", :action=>"list"}
#                                             GET    /downloads/:id(/:style)/:filename(.:format)                                               {:controller=>"uploads", :action=>"download", :filename=>/.*/}
#                                        root        /(.:format)                                                                               {:controller=>"projects", :action=>"index"}
#                                   mail_view        /mail_view                                                                                {:to=>Emailer::Preview, :action=>"mail_view"}
#                                       oauth        /oauth(.:format)                                                                          {:controller=>"oauth", :action=>"index"}
#                                   authorize        /oauth/authorize(.:format)                                                                {:controller=>"oauth", :action=>"authorize"}
#                                      revoke        /oauth/revoke(.:format)                                                                   {:controller=>"oauth", :action=>"revoke"}
#                                       token        /oauth/token(.:format)                                                                    {:controller=>"oauth", :action=>"token"}
#                     developer_oauth_clients GET    /oauth_clients/developer(.:format)                                                        {:controller=>"oauth_clients", :action=>"developer"}
#                               oauth_clients GET    /oauth_clients(.:format)                                                                  {:controller=>"oauth_clients", :action=>"index"}
#                                             POST   /oauth_clients(.:format)                                                                  {:controller=>"oauth_clients", :action=>"create"}
#                            new_oauth_client GET    /oauth_clients/new(.:format)                                                              {:controller=>"oauth_clients", :action=>"new"}
#                           edit_oauth_client GET    /oauth_clients/:id/edit(.:format)                                                         {:controller=>"oauth_clients", :action=>"edit"}
#                                oauth_client GET    /oauth_clients/:id(.:format)                                                              {:controller=>"oauth_clients", :action=>"show"}
#                                             PUT    /oauth_clients/:id(.:format)                                                              {:controller=>"oauth_clients", :action=>"update"}
#                                             DELETE /oauth_clients/:id(.:format)                                                              {:controller=>"oauth_clients", :action=>"destroy"}
#                           trimmer_templates        /trimmer/:locale/templates.js(.:format)                                                   {:controller=>"trimmer", :action=>"templates"}
#                        trimmer_translations        /trimmer/:locale/translations.js(.:format)                                                {:controller=>"trimmer", :action=>"translations"}
#                           trimmer_resources        /trimmer/:locale.js(.:format)                                                             {:controller=>"trimmer", :action=>"resources"}
#                                      jammit        /jammit/:package.:extension(.:format)                                                     {:controller=>"jammit", :action=>"package", :extension=>/.+/}
