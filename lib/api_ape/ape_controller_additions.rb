module ApiApe

  # This module is automatically included into all controllers.
  module ApeControllerAdditions

    module ClassMethods

      attr_reader :permitted_fields

      # Sets up a before filter which loads and renders the current resource. This performs both
      # load_resource and render_ape and accepts the same arguments. See those methods for details.
      #
      #   class BooksController < ApplicationController
      #     load_and_render_ape
      #   end
      #
      def load_and_render_ape(*args)
        ControllerApe.add_around_filter(self, :load_and_render_ape, *args)
      end

      # Sets up a before filter which loads the model resource into an instance variable.
      # For example, given an ArticlesController it will load the current article into the @article
      # instance variable. It does this by either calling Article.find(params[:id]) or
      # Article.new(params[:article]) depending upon the action. The index action will
      # automatically set @articles to Article.accessible_by(current_ability).
      #
      # If a conditions hash is used in the Ability, the +new+ and +create+ actions will set
      # the initial attributes based on these conditions. This way these actions will satisfy
      # the ability restrictions.
      #
      # Call this method directly on the controller class.
      #
      #   class BooksController < ApplicationController
      #     load_resource
      #   end
      #
      # A resource is not loaded if the instance variable is already set. This makes it easy to override
      # the behavior through a before_filter on certain actions.
      #
      #   class BooksController < ApplicationController
      #     before_filter :find_book_by_permalink, :only => :show
      #     load_resource
      #
      #     private
      #
      #     def find_book_by_permalink
      #       @book = Book.find_by_permalink!(params[:id)
      #     end
      #   end
      #
      # If a name is provided which does not match the controller it assumes it is a parent resource. Child
      # resources can then be loaded through it.
      #
      #   class BooksController < ApplicationController
      #     load_resource :author
      #     load_resource :book, :through => :author
      #   end
      #
      # Here the author resource will be loaded before each action using params[:author_id]. The book resource
      # will then be loaded through the @author instance variable.
      #
      # That first argument is optional and will default to the singular name of the controller.
      # A hash of options (see below) can also be passed to this method to further customize it.
      #
      # See load_and_render_ape to automatically render the resource too.
      #
      # Options:
      # [:+only+]
      #   Only applies before filter to given actions.
      #
      # [:+except+]
      #   Does not apply before filter to given actions.
      #
      # [:+class+]
      #   The class to use for the model (string or constant).
      #
      # [:+instance_name+]
      #   The name of the instance variable to load the resource into.
      #
      # [:+find_by+]
      #   Find using a different attribute other than id. For example.
      #
      #     load_resource :find_by => :permalink # will use find_by_permalink!(params[:id])
      #
      # [:+id_param+]
      #   Find using a param key other than :id. For example:
      #
      #     load_resource :id_param => :url # will use find(params[:url])
      #
      # [:+collection+]
      #   Specify which actions are resource collection actions in addition to :+index+. This
      #   is usually not necessary because it will try to guess depending on if the id param is present.
      #
      #     load_resource :collection => [:sort, :list]
      #
      # [:+new+]
      #   Specify which actions are new resource actions in addition to :+new+ and :+create+.
      #   Pass an action name into here if you would like to build a new resource instead of
      #   fetch one.
      #
      #     load_resource :new => :build
      #
      # [:+prepend+]
      #   Passing +true+ will use prepend_before_filter instead of a normal before_filter.
      #
      def load_resource(*args)
        ControllerApe.add_before_filter(self, :load_resource, *args)
      end

      # Sets up a filter which renders the current resource after the controller action has been executed.
      #
      #   class BooksController < ApplicationController
      #     render_ape
      #   end
      #
      def render_ape(*args)
        ControllerApe.add_around_filter(self, :render_ape, *args)
      end

      # Skip both the loading and rendering behavior of ApiApe for this given controller. This is primarily
      # useful to skip the behavior of a superclass. You can pass :only and :except options to specify which actions
      # to skip the effects on. It will apply to all actions by default.
      #
      #   class ProjectsController < SomeOtherController
      #     skip_load_and_render_ape :only => :index
      #   end
      #
      # You can also pass the resource name as the first argument to skip that resource.
      def skip_load_and_render_ape(*args)
        skip_load_resource(*args)
        skip_render_ape(*args)
      end

      # Skip the loading behavior of ApeApe. This is useful when using +skip_load_and_render_ape+ but want to
      # only do rendering on certain actions. You can pass :only and :except options to specify which actions to
      # skip the effects on. It will apply to all actions by default.
      #
      #   class ProjectsController < ApplicationController
      #     skip_load_and_render_ape
      #     skip_load_resource :only => :index
      #   end
      #
      # You can also pass the resource name as the first argument to skip that resource.
      def skip_load_resource(*args)
        options = args.extract_options!
        name = args.first
        ape_skipper[:load][name] = options
      end

      # Skip the rendering behavior of ApeApe. This is useful when using +skip_load_and_render_ape+ but want to
      # only do loading on certain actions. You can pass :only and :except options to specify which actions to
      # skip the effects on. It will apply to all actions by default.
      #
      #   class ProjectsController < ApplicationController
      #     skip_load_and_render_ape
      #     skip_render_ape :only => :index
      #   end
      #
      # You can also pass the resource name as the first argument to skip that resource.
      def skip_render_ape(*args)
        options = args.extract_options!
        name = args.first
        ape_skipper[:render][name] = options
      end

      def ape_skipper
        @_ape_skipper ||= { render: {}, load: {} }
      end

      def permitted_ape_fields(arr)
        @permitted_fields = arr
      end
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Instance Methods
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def render_ape(obj, *args)
      options = args.extract_options!

      # If we have set global permitted_fields and there were none passed in the options, then use the global ones
      permitted_fields = options[:permitted_fields] || self.class.permitted_fields

      ApeRenderer.new(permitted_fields).render_ape(self, params, obj)
    end

    def self.included(base)
      base.extend ClassMethods
    end

  end
end

if defined? ActionController::Base
  ActionController::Base.class_eval do
    include ApiApe::ApeControllerAdditions
  end
end
