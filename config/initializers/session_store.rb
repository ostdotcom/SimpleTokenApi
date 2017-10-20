# Be sure to restart your server when you modify this file.
Rails.application.config.middleware.use ActionDispatch::Cookies
Rails.application.config.middleware.use ActionDispatch::Session::CookieStore, key: '_st_session_id', domain: :all, http_only: true, secure: !Rails.env.development?, same_site: :strict

